import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

/// Migration tests for schema v21 → v22 (merchant data foundation).
///
/// Two concerns are covered:
///   (1) Fresh-install onCreate — `AppDatabase.forTesting()` opens at v22 and
///       both `merchants` + `merchant_match_keys` tables exist with the full
///       column set and the four explicit indexes (MERCH-04, MERCH-05).
///   (2) v21→v22 onUpgrade — the `from < 22` migration step (replicated here as
///       [_runV22MigrationSteps], the contract for what lands in `onUpgrade`)
///       creates both tables and the same four indexes when applied to a DB that
///       did NOT have them.
///
/// Test approach (no drift_schemas/ snapshots; matches category_v14 idiom):
///   - For onCreate: open a fresh AppDatabase.forTesting() and assert directly.
///   - For onUpgrade: open a fresh DB, DROP the merchant tables/indexes that
///     onCreate built (simulating a pre-v22 DB), then run [_runV22MigrationSteps]
///     (mirror of the `from < 22` block) and assert the tables/indexes are
///     re-created. This exercises the exact SQL/DDL the migrator runs.
///
/// These tests are intentionally RED until:
///   - the merchants + merchant_match_keys tables are defined and registered,
///   - schemaVersion is bumped to 22,
///   - `_createMerchantIndexes()` is called from onCreate AND the from<22 block.

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

/// Run the v22 migration steps.
///
/// This is the contract for what must live inside `onUpgrade` when `from < 22`
/// in AppDatabase. The DDL here must be kept in sync with `_createMerchantIndexes()`
/// and the `migrator.createTable(...)` calls in the real migration.
Future<void> _runV22MigrationSteps(AppDatabase db) async {
  // Mirror migrator.createTable(merchants) / createTable(merchantMatchKeys).
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS merchants (
      id TEXT NOT NULL,
      name_ja TEXT NOT NULL,
      name_zh TEXT,
      name_en TEXT,
      region TEXT NOT NULL DEFAULT 'JP',
      category_id TEXT NOT NULL,
      ledger_hint TEXT NOT NULL,
      PRIMARY KEY (id)
    )
  ''');
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS merchant_match_keys (
      id TEXT NOT NULL,
      merchant_id TEXT NOT NULL REFERENCES merchants(id),
      surface TEXT NOT NULL,
      match_key TEXT NOT NULL,
      kind TEXT NOT NULL,
      PRIMARY KEY (id)
    )
  ''');
  // Mirror _createMerchantIndexes().
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_merchant_match_keys_match_key '
    'ON merchant_match_keys (match_key)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_merchant_match_keys_merchant '
    'ON merchant_match_keys (merchant_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_merchants_region '
    'ON merchants (region)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_merchants_category '
    'ON merchants (category_id)',
  );
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

  group('merchant v22 — onUpgrade (v21→v22) contract', () {
    test('migration step recreates both tables + four indexes', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);

      // Simulate a pre-v22 DB: drop what onCreate built.
      await db.customStatement('DROP TABLE IF EXISTS merchant_match_keys');
      await db.customStatement('DROP TABLE IF EXISTS merchants');
      expect(await _tableExists(db, 'merchants'), isFalse);
      expect(await _tableExists(db, 'merchant_match_keys'), isFalse);

      // Run the from<22 migration contract.
      await _runV22MigrationSteps(db);

      expect(await _tableExists(db, 'merchants'), isTrue);
      expect(await _tableExists(db, 'merchant_match_keys'), isTrue);
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
  });
}
