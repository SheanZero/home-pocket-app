import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

/// Migration tests for schema v21 → v22 (merchant data foundation).
///
/// Two concerns are covered:
///   (1) Fresh-install onCreate — `AppDatabase.forTesting()` opens at v22 and
///       both `merchants` + `merchant_match_keys` tables exist with the full
///       column set and the four explicit indexes (MERCH-04, MERCH-05).
///   (2) v21→v22 onUpgrade — the REAL `from < 22` block inside
///       `AppDatabase.migration` is driven on the host VM (WR-01). We open a
///       file-backed `NativeDatabase` at v22, simulate a pre-v22 DB by dropping
///       what onCreate built and rewinding `user_version` to 21, close it, then
///       reopen the SAME file as `AppDatabase` (schemaVersion 22). Drift's
///       migrator sees 21 < 22 and runs the genuine production `from < 22`
///       branch — `migrator.createTable` + `_createMerchantIndexes()`. This is
///       the host-VM mirror of the encrypted ladder's STAGE A/B (minus the
///       SQLCipher boundary, which is covered on-device in
///       integration_test/merchant_migration_ladder_test.dart).
///
/// No hand-written DDL mirror is used: if the real migrator's table/index set
/// ever drifts, this test fails instead of staying falsely green (WR-01).

const Set<String> _expectedIndexes = {
  'idx_merchants_region',
  'idx_merchants_category',
  'idx_merchant_match_keys_match_key',
  'idx_merchant_match_keys_merchant',
};

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

Future<Set<String>> _columnNames(AppDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.map((r) => r.read<String>('name')).toSet();
}

Future<bool> _tableExists(AppDatabase db, String table) async {
  final rows = await db
      .customSelect(
        'SELECT name FROM sqlite_master '
        "WHERE type = 'table' AND name = ?",
        variables: [Variable<String>(table)],
      )
      .get();
  return rows.isNotEmpty;
}

void main() {
  group('merchant v22 — fresh install (onCreate)', () {
    test('AppDatabase schemaVersion is 22', () {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      expect(db.schemaVersion, equals(22));
    });

    test('merchants table exists with all columns', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      expect(await _tableExists(db, 'merchants'), isTrue);
      final cols = await _columnNames(db, 'merchants');
      expect(
        cols,
        containsAll(<String>[
          'id',
          'name_ja',
          'name_zh',
          'name_en',
          'region',
          'category_id',
          'ledger_hint',
        ]),
      );
    });

    test('merchant_match_keys table exists with all columns', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      expect(await _tableExists(db, 'merchant_match_keys'), isTrue);
      final cols = await _columnNames(db, 'merchant_match_keys');
      expect(
        cols,
        containsAll(<String>[
          'id',
          'merchant_id',
          'surface',
          'match_key',
          'kind',
        ]),
      );
    });

    test('PRAGMA index_list is non-empty for both tables', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final merchantsIdx =
          await db.customSelect('PRAGMA index_list(merchants)').get();
      final matchKeysIdx =
          await db.customSelect('PRAGMA index_list(merchant_match_keys)').get();
      expect(merchantsIdx, isNotEmpty);
      expect(matchKeysIdx, isNotEmpty);
    });

    test('all four explicit indexes exist on fresh install', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final all = <String>{
        ...await _indexNames(db, 'merchants'),
        ...await _indexNames(db, 'merchant_match_keys'),
      };
      expect(all, containsAll(_expectedIndexes));
    });

    test('merchant_match_keys.match_key index is NON-UNIQUE', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      // PRAGMA index_list: column "unique" is 0 for non-unique indexes.
      final rows =
          await db.customSelect('PRAGMA index_list(merchant_match_keys)').get();
      final matchKeyRow = rows.firstWhere(
        (r) => r.read<String>('name') == 'idx_merchant_match_keys_match_key',
      );
      expect(matchKeyRow.read<int>('unique'), equals(0));
    });

    test('two rows may share a match_key (non-unique enforced)', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      await db.customStatement('''
        INSERT INTO merchants (id, name_ja, region, category_id, ledger_hint)
        VALUES ('mer_a', 'A', 'JP', 'cat_food_other', 'daily')
      ''');
      await db.customStatement('''
        INSERT INTO merchants (id, name_ja, region, category_id, ledger_hint)
        VALUES ('mer_b', 'B', 'JP', 'cat_food_other', 'daily')
      ''');
      await db.customStatement('''
        INSERT INTO merchant_match_keys (id, merchant_id, surface, match_key, kind)
        VALUES ('mk_a', 'mer_a', 'X', 'shared', 'name')
      ''');
      // Must NOT throw — match_key index is non-unique.
      await db.customStatement('''
        INSERT INTO merchant_match_keys (id, merchant_id, surface, match_key, kind)
        VALUES ('mk_b', 'mer_b', 'X', 'shared', 'name')
      ''');
      final rows = await db
          .customSelect(
            "SELECT COUNT(*) AS c FROM merchant_match_keys WHERE match_key = 'shared'",
          )
          .getSingle();
      expect(rows.read<int>('c'), equals(2));
    });

    test('region defaults to JP when omitted on insert', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      await db.customStatement('''
        INSERT INTO merchants (id, name_ja, category_id, ledger_hint)
        VALUES ('mer_def', 'D', 'cat_food_other', 'daily')
      ''');
      final row = await db
          .customSelect(
            "SELECT region FROM merchants WHERE id = 'mer_def'",
          )
          .getSingle();
      expect(row.read<String>('region'), equals('JP'));
    });
  });

  group('merchant v22 — onUpgrade (v21→v22) drives the REAL migrator', () {
    // File-backed so the DB persists across the close/reopen that is required to
    // make Drift's migrator fire (an in-memory DB does not survive two executor
    // instances — 49-PATTERNS reopen note). Mirrors the encrypted ladder STAGE
    // A/B, minus the SQLCipher boundary.
    late Directory tempDir;
    late File dbFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('merchant_v22_migration');
      dbFile = File('${tempDir.path}/app.sqlite');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
        'real from<22 onUpgrade block recreates both tables + four indexes',
        () async {
      // STAGE A — stamp the file at v21: open at v22 (onCreate builds
      // everything), drop what onCreate built for merchants, and rewind
      // user_version to 21 so the next open looks like a genuine pre-v22 DB.
      final staged = AppDatabase(NativeDatabase(dbFile));
      await staged.customStatement('DROP TABLE IF EXISTS merchant_match_keys');
      await staged.customStatement('DROP TABLE IF EXISTS merchants');
      await staged.customStatement('PRAGMA user_version = 21');
      expect(await _tableExists(staged, 'merchants'), isFalse);
      expect(await _tableExists(staged, 'merchant_match_keys'), isFalse);
      await staged.close();

      // STAGE B — reopen the SAME file as AppDatabase (schemaVersion 22). Drift
      // sees user_version 21 < 22 and runs the production `from < 22` branch:
      // migrator.createTable(merchants/merchantMatchKeys) + _createMerchantIndexes().
      final upgraded = AppDatabase(NativeDatabase(dbFile));
      addTearDown(upgraded.close);

      // Force the migrator to run by issuing a query (lazy-open).
      expect(await _tableExists(upgraded, 'merchants'), isTrue);
      expect(await _tableExists(upgraded, 'merchant_match_keys'), isTrue);

      // Columns come from the REAL Drift table definitions (no hand DDL).
      final merchantCols = await _columnNames(upgraded, 'merchants');
      expect(
        merchantCols,
        containsAll(<String>[
          'id',
          'name_ja',
          'name_zh',
          'name_en',
          'region',
          'category_id',
          'ledger_hint',
        ]),
      );
      final keyCols = await _columnNames(upgraded, 'merchant_match_keys');
      expect(
        keyCols,
        containsAll(<String>['id', 'merchant_id', 'surface', 'match_key', 'kind']),
      );

      final all = <String>{
        ...await _indexNames(upgraded, 'merchants'),
        ...await _indexNames(upgraded, 'merchant_match_keys'),
      };
      expect(all, containsAll(_expectedIndexes));

      final merchantsIdx =
          await upgraded.customSelect('PRAGMA index_list(merchants)').get();
      final matchKeysIdx = await upgraded
          .customSelect('PRAGMA index_list(merchant_match_keys)')
          .get();
      expect(merchantsIdx, isNotEmpty);
      expect(matchKeysIdx, isNotEmpty);
    });
  });
}
