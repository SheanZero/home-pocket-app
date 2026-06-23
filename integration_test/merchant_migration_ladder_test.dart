// Encrypted-executor migration ladder — Phase 49 Plan 06 (Crit #4, MERCH-04).
//
// WHY THIS LIVES IN integration_test/ (not test/):
// The host `flutter test` runner links plain libsqlite3, so `createEncryptedExecutor`
// would throw `StateError('SQLCipher not loaded')` (encrypted_database.dart:48-50)
// — or, worse, silently open a PLAINTEXT db and mask a cipher regression (Pitfall #2).
// Only a booted simulator/device loads `sqlcipher_flutter_libs` natives. This test
// therefore runs ONLY on-device and asserts `PRAGMA cipher_version` is NON-EMPTY
// inside the test, proving the schema/seed actually applied on the SQLCipher path.
//
// HOW TO RUN (cannot run in headless CI without a booted simulator):
//   flutter test integration_test/merchant_migration_ladder_test.dart
//
// COVERAGE SPLIT (RESEARCH-recommended):
//   - This integration test proves the SQLCipher path for FRESH v22 and v21→v22
//     (the real v1.8-user upgrade) — the only paths that matter for at-rest
//     encryption of merchant data.
//   - Deep-history v3→v22 / v17→v22 index/column assertions are covered by the
//     host-VM ladder `test/unit/data/migrations/merchant_v22_migration_test.dart`
//     (plain libsqlite3 is adequate there — those assertions are about DDL shape,
//     not the cipher boundary).
//
// ZERO-KNOWLEDGE DISCIPLINE (V7): this test asserts counts / ids / categoryIds and
// the cipher_version string only. It NEVER logs raw merchant names.

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/seed_merchants_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/merchant_dao.dart';
import 'package:home_pocket/data/repositories/merchant_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/database/encrypted_database.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';
import 'package:integration_test/integration_test.dart';

/// The four explicit merchant indexes created by `_createMerchantIndexes()`
/// (app_database.dart) — emitted from BOTH onCreate and the `from < 22` upgrade
/// block (the `drift-customindices-is-decorative` defense, MEMORY.md / CR-01).
const Set<String> _expectedIndexes = {
  'idx_merchant_match_keys_match_key',
  'idx_merchant_match_keys_merchant',
  'idx_merchants_region',
  'idx_merchants_category',
};

/// In-memory [MasterKeyRepository] test double with a FIXED, deterministic key.
///
/// Avoids any dependency on flutter_secure_storage native channels on-device,
/// while exercising the EXACT key-derivation + `createEncryptedExecutor` path
/// used in production (HKDF-SHA256 over the master key — see
/// MasterKeyRepositoryImpl.deriveKey). No second key path is introduced (V6).
class _FixedKeyMasterKeyRepository implements MasterKeyRepository {
  // Deterministic 32-byte master key (NOT a production key — test fixture only).
  static final List<int> _key =
      List<int>.generate(32, (i) => (i * 7 + 13) & 0xFF);

  static const String _hkdfSalt = 'homepocket-v1-2026';
  final Map<String, SecretKey> _cache = {};

  @override
  Future<void> initializeMasterKey() async {}

  @override
  Future<bool> hasMasterKey() async => true;

  @override
  Future<List<int>> getMasterKey() async => _key;

  @override
  Future<SecretKey> deriveKey(String purpose) async {
    if (_cache.containsKey(purpose)) return _cache[purpose]!;
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final derived = await hkdf.deriveKey(
      secretKey: SecretKey(_key),
      info: Uint8List.fromList(purpose.codeUnits),
      nonce: Uint8List.fromList(_hkdfSalt.codeUnits),
    );
    _cache[purpose] = derived;
    return derived;
  }

  @override
  Future<void> clearMasterKey() async {}
}

/// Assert SQLCipher is the active backend — NON-EMPTY `PRAGMA cipher_version`.
/// On plain libsqlite3 this is empty (and `_setupEncryption` would have thrown
/// before we ever got here). This is the Pitfall #2 / T-49-03 gate.
Future<void> _assertCipherActive(AppDatabase db) async {
  final rows = await db.customSelect('PRAGMA cipher_version').get();
  expect(rows, isNotEmpty,
      reason: 'PRAGMA cipher_version empty — SQLCipher NOT loaded (plain '
          'libsqlite3). Encrypted ladder is invalid on this backend.');
  final version = rows.first.data.values.first;
  expect(version, isNotNull);
  expect(version.toString(), isNotEmpty);
}

Future<Set<String>> _indexNames(AppDatabase db, String table) async {
  final rows = await db
      .customSelect(
        'SELECT name FROM sqlite_master '
        "WHERE type = 'index' AND tbl_name = ?",
        variables: [Variable<String>(table)],
      )
      .get();
  return rows.map((r) => r.read<String>('name')).toSet();
}

/// Open the production encrypted executor + AppDatabase against the on-disk
/// (documents-dir) encrypted file. `inMemory: false` is REQUIRED for the
/// reopen-and-upgrade case — `NativeDatabase.memory()` does not persist across
/// two executor instances (49-PATTERNS reopen note).
Future<AppDatabase> _openEncrypted(MasterKeyRepository keyRepo) async {
  final executor = await createEncryptedExecutor(keyRepo, inMemory: false);
  return AppDatabase(executor);
}

/// Reset merchant state on the persistent encrypted file so each scenario starts
/// from a known-empty merchant spine. `createEncryptedExecutor` writes to a
/// fixed documents-dir path that is NOT exposed for file-level deletion, so
/// isolation is achieved at the SQL layer (drop merchant content) rather than by
/// unlinking the db file. The cipher boundary is unaffected — the same encrypted
/// file is reused, which is exactly the at-rest condition we want to prove.
Future<void> _resetMerchantState(AppDatabase db) async {
  await db.customStatement('DELETE FROM merchant_match_keys');
  await db.customStatement('DELETE FROM merchants');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Real L2 category id set — every merchant.categoryId must resolve to one of
  // these (D-04 silent-null gate, on the live encrypted DB).
  final l2Ids = DefaultCategories.all
      .where((c) => c.level == 2)
      .map((c) => c.id)
      .toSet();

  setUpAll(() async {
    // Load SQLCipher natives for the current platform (Android override / iOS).
    await ensureNativeLibrary();
  });

  group('encrypted ladder — FRESH v22 (onCreate under SQLCipher)', () {
    late MasterKeyRepository keyRepo;
    late AppDatabase db;

    setUp(() async {
      keyRepo = _FixedKeyMasterKeyRepository();
      db = await _openEncrypted(keyRepo);
      // Drop merchant content so the seed count-guard runs even if a prior run
      // left rows in the persistent encrypted file (SQL-layer isolation).
      await _resetMerchantState(db);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('cipher_version non-empty (SQLCipher loaded, not plain)',
        (tester) async {
      await _assertCipherActive(db);
    });

    testWidgets('schemaVersion is 22 on the encrypted executor',
        (tester) async {
      expect(db.schemaVersion, equals(22));
    });

    testWidgets('merchant indexes exist + PRAGMA index_list non-empty',
        (tester) async {
      final all = <String>{
        ...await _indexNames(db, 'merchants'),
        ...await _indexNames(db, 'merchant_match_keys'),
      };
      expect(all, containsAll(_expectedIndexes));

      final merchantsIdx =
          await db.customSelect('PRAGMA index_list(merchants)').get();
      final matchKeysIdx =
          await db.customSelect('PRAGMA index_list(merchant_match_keys)').get();
      expect(merchantsIdx, isNotEmpty);
      expect(matchKeysIdx, isNotEmpty);
    });

    testWidgets('seed populates merchants + every categoryId resolves to L2',
        (tester) async {
      // Drive the production seed use case against the encrypted DB.
      final repo = MerchantRepositoryImpl(dao: MerchantDao(db));
      final result = await SeedMerchantsUseCase(merchantRepository: repo)
          .execute();
      expect(result.isSuccess, isTrue);

      final merchants = await repo.findAll();
      expect(merchants, isNotEmpty,
          reason: 'seed produced no merchant rows on the encrypted DB');

      // Every categoryId must be a real L2 id (count assertion only — V7).
      final orphanCount =
          merchants.where((m) => !l2Ids.contains(m.categoryId)).length;
      expect(orphanCount, equals(0),
          reason: 'merchant rows reference a non-L2 categoryId on the '
              'encrypted DB');

      // cipher still active after the seed transaction.
      await _assertCipherActive(db);
    });

    testWidgets('re-seed converges (idempotent, row counts unchanged)',
        (tester) async {
      final repo = MerchantRepositoryImpl(dao: MerchantDao(db));
      final seed = SeedMerchantsUseCase(merchantRepository: repo);
      await seed.execute();
      final firstCount = (await repo.findAll()).length;
      await seed.execute();
      final secondCount = (await repo.findAll()).length;
      expect(secondCount, equals(firstCount));
    });
  });

  group('encrypted ladder — v21→v22 (onUpgrade under SQLCipher)', () {
    testWidgets(
        'onUpgrade fires under SQLCipher: tables + 4 indexes built, '
        'cipher_version non-empty', (tester) async {
      final keyRepo = _FixedKeyMasterKeyRepository();

      // STAGE A — stamp an encrypted DB at v21 (the real v1.8-user state):
      // open at v22, then simulate a pre-v22 DB by dropping what onCreate built
      // for merchants and rewinding user_version to 21. This is the same
      // "drop what onCreate built" technique as the host-VM ladder, but here on
      // the ENCRYPTED executor so the rewound file is genuinely SQLCipher at v21.
      final staged = await _openEncrypted(keyRepo);
      await _assertCipherActive(staged);
      await staged.customStatement('DROP TABLE IF EXISTS merchant_match_keys');
      await staged.customStatement('DROP TABLE IF EXISTS merchants');
      await staged.customStatement('PRAGMA user_version = 21');
      await staged.close();

      // STAGE B — reopen as AppDatabase (schemaVersion 22) on the SAME encrypted
      // file → Drift's migrator sees user_version 21 < 22 and runs the
      // `from < 22` onUpgrade step under SQLCipher.
      final upgraded = await _openEncrypted(keyRepo);
      addTearDown(upgraded.close);

      await _assertCipherActive(upgraded);

      // Tables rebuilt by onUpgrade.
      final tables = await upgraded
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name IN ('merchants', 'merchant_match_keys')",
          )
          .get();
      expect(tables.map((r) => r.read<String>('name')).toSet(),
          containsAll(<String>{'merchants', 'merchant_match_keys'}));

      // All four explicit indexes recreated by `_createMerchantIndexes()` in the
      // upgrade path (decorative-customIndices defense).
      final all = <String>{
        ...await _indexNames(upgraded, 'merchants'),
        ...await _indexNames(upgraded, 'merchant_match_keys'),
      };
      expect(all, containsAll(_expectedIndexes));

      final merchantsIdx =
          await upgraded.customSelect('PRAGMA index_list(merchants)').get();
      expect(merchantsIdx, isNotEmpty);

      // Post-upgrade the seed can populate the migrated encrypted DB.
      final repo = MerchantRepositoryImpl(dao: MerchantDao(upgraded));
      final result =
          await SeedMerchantsUseCase(merchantRepository: repo).execute();
      expect(result.isSuccess, isTrue);
      final merchants = await repo.findAll();
      expect(merchants, isNotEmpty);
      final orphanCount =
          merchants.where((m) => !l2Ids.contains(m.categoryId)).length;
      expect(orphanCount, equals(0));
    });
  });
}
