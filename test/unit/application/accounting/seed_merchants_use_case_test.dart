import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/ledger_hint_deriver.dart';
import 'package:home_pocket/application/accounting/seed_merchants_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/merchant_dao.dart';
import 'package:home_pocket/data/repositories/merchant_repository_impl.dart';
import 'package:home_pocket/infrastructure/ml/merchant_name_normalizer.dart';
import 'package:home_pocket/shared/constants/default_merchants.dart';

/// Expected distinct match-key surfaces for one merchant, after the
/// composite-PK ('${id}__${matchKey}') + INSERT OR IGNORE collapse.
///
/// Surfaces = nameJa (name) + aliases (alias) + non-null nameZh/nameEn (locale),
/// each normalized via [normalizeMerchantKey]; duplicate match keys collapse to
/// one row (matches the seed's stable-PK idempotency contract).
Set<String> _expectedMatchKeysFor(DefaultMerchant m) {
  final surfaces = <String>[
    m.nameJa,
    ...m.aliases,
    if (m.nameZh != null) m.nameZh!,
    if (m.nameEn != null) m.nameEn!,
  ];
  return surfaces.map(normalizeMerchantKey).toSet();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SeedMerchantsUseCase useCase;

  setUp(() {
    db = AppDatabase.forTesting();
    final repo = MerchantRepositoryImpl(dao: MerchantDao(db));
    useCase = SeedMerchantsUseCase(merchantRepository: repo);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> merchantRowCount() async =>
      (await db.select(db.merchants).get()).length;

  Future<int> matchKeyRowCount() async =>
      (await db.select(db.merchantMatchKeys).get()).length;

  group('SeedMerchantsUseCase', () {
    test('seeds merchant rows + expanded match-key rows when db is empty',
        () async {
      final result = await useCase.execute();
      expect(result.isSuccess, isTrue);

      // (1) merchant count == DefaultMerchants.all.length
      expect(await merchantRowCount(), DefaultMerchants.all.length);

      // match-key count == total distinct expanded surfaces (> merchant count)
      final expectedKeyCount = DefaultMerchants.all
          .map((m) => _expectedMatchKeysFor(m).length)
          .fold<int>(0, (a, b) => a + b);
      expect(await matchKeyRowCount(), expectedKeyCount);
      expect(
        expectedKeyCount,
        greaterThan(DefaultMerchants.all.length),
        reason: 'every merchant has at least one name surface plus extras',
      );
    });

    test('every seeded merchant ledger_hint == deriveLedgerHint(categoryId)',
        () async {
      await useCase.execute();

      final rows = await db.select(db.merchants).get();
      final byId = {for (final m in DefaultMerchants.all) m.id: m};
      for (final row in rows) {
        final source = byId[row.id]!;
        expect(
          row.ledgerHint,
          deriveLedgerHint(source.categoryId).name,
          reason: 'ledger_hint must be derived, never hand-authored',
        );
      }
    });

    test('every match_key row == normalizeMerchantKey(surface)', () async {
      await useCase.execute();

      final keys = await db.select(db.merchantMatchKeys).get();
      expect(keys, isNotEmpty);
      for (final k in keys) {
        expect(k.matchKey, normalizeMerchantKey(k.surface));
      }
    });

    test('idempotency — re-seed converges, row counts unchanged', () async {
      await useCase.execute();
      final merchantsAfterFirst = await merchantRowCount();
      final keysAfterFirst = await matchKeyRowCount();

      final secondResult = await useCase.execute();
      expect(secondResult.isSuccess, isTrue);

      expect(await merchantRowCount(), merchantsAfterFirst);
      expect(await matchKeyRowCount(), keysAfterFirst);
    });
  });
}
