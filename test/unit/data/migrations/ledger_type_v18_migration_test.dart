import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

/// Migration tests for schema v17 → v18 (terminology rename: survival→daily, soul→joy,
/// soul_satisfaction→joy_fullness column rename).
///
/// These tests are intentionally RED until Plan 31-02:
///   - bumps schemaVersion to 18 in AppDatabase
///   - adds the v18 migration block in onUpgrade (if from < 18)
///
/// The `schemaVersion` guard (Test 1) ensures the database is at v18.
/// Once schemaVersion == 18 and the onUpgrade SQL is in place, all assertions
/// should turn GREEN.
///
/// Test approach (raw-sqlite3 in-memory style — preferred over forTesting() because
/// v18 needs precise control of the OLD CHECK constraint):
///   1. Create in-memory sqlite3 Database with the v17 schema via [_createV17Tables].
///   2. Seed pre-migration rows with old vocabulary ('survival', 'soul', soul_satisfaction).
///   3. Run [_runV18MigrationSteps] — three sub-steps that MUST mirror EXACTLY the SQL
///      Plan 02 will place in `onUpgrade`'s `if (from < 18)` block.
///   4. Assert the expected post-migration state.
///
/// The helper [_runV18MigrationSteps] is the contract: it mirrors verbatim the SQL
/// that will live in `onUpgrade` when `from < 18`. Keep the two in lockstep (same
/// sub-step order, same SQL) — see 31-PATTERNS.md §Pattern C.
///
/// Contract covers D-02 (enum-value rewrite + CHECK recreate) and D-16 (soul_satisfaction
/// column renamed to joy_fullness, integer data preserved). T-31-01, T-31-02 threat
/// mitigations are encoded in Tests 3, 4, 6.

// ─── Target schema version ─────────────────────────────────────────────────────

const _targetSchemaVersion = 18; // minimum version including v18 ledger_type migration

// ─── v17 table creation ────────────────────────────────────────────────────────

/// Create the v17-era tables in [db] with the OLD CHECK constraint and
/// soul_satisfaction column — the state a device would be in before upgrading.
void _createV17Tables(Database db) {
  // transactions table with soul_satisfaction column and OLD ledger_type domain
  db.execute('''
    CREATE TABLE transactions (
      id TEXT NOT NULL PRIMARY KEY,
      book_id TEXT NOT NULL,
      device_id TEXT NOT NULL,
      amount INTEGER NOT NULL,
      type TEXT NOT NULL,
      category_id TEXT NOT NULL,
      ledger_type TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      note TEXT,
      photo_hash TEXT,
      merchant TEXT,
      metadata TEXT,
      prev_hash TEXT,
      current_hash TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER,
      is_private INTEGER NOT NULL DEFAULT 0 CHECK ("is_private" IN (0, 1)),
      is_synced INTEGER NOT NULL DEFAULT 0 CHECK ("is_synced" IN (0, 1)),
      is_deleted INTEGER NOT NULL DEFAULT 0 CHECK ("is_deleted" IN (0, 1)),
      soul_satisfaction INTEGER NOT NULL DEFAULT 2,
      entry_source TEXT NOT NULL DEFAULT 'manual'
        CHECK(entry_source IN ('manual', 'voice', 'ocr')),
      CHECK(soul_satisfaction BETWEEN 1 AND 10)
    )
  ''');

  // category_ledger_configs with OLD CHECK(ledger_type IN ('survival','soul'))
  db.execute('''
    CREATE TABLE category_ledger_configs (
      category_id TEXT NOT NULL PRIMARY KEY,
      ledger_type TEXT NOT NULL
        CHECK(ledger_type IN ('survival', 'soul')),
      updated_at INTEGER NOT NULL
    )
  ''');

  // Recreate the two customIndices that the table-recreate sub-step must preserve
  db.execute('''
    CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_ledger_type
    ON category_ledger_configs(ledger_type)
  ''');
  db.execute('''
    CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_updated_at
    ON category_ledger_configs(updated_at)
  ''');
}

// ─── Migration contract ────────────────────────────────────────────────────────

/// Run the v18 migration steps on [rawDb].
///
/// **CONTRACT:** This function MUST mirror EXACTLY the SQL that Plan 31-02
/// places inside `onUpgrade`'s `if (from < 18)` block in app_database.dart.
/// Three sub-steps, in this order (RESEARCH Pitfall 2 — ordering is critical):
///
///   1. Table-recreate category_ledger_configs with new CHECK(ledger_type IN ('daily','joy'))
///      (old CHECK rejects 'daily'/'joy', so recreate MUST come first).
///   2. UPDATE transactions.ledger_type: 'survival'→'daily', 'soul'→'joy'.
///   3. ALTER TABLE transactions RENAME COLUMN soul_satisfaction TO joy_fullness (D-16).
///
/// All three sub-steps are wrapped in a single transaction for atomicity.
void _runV18MigrationSteps(Database db) {
  db.execute('BEGIN');
  try {
    // Sub-step 1: recreate category_ledger_configs with widened CHECK
    // Drop old indices first (they survive RENAME and would conflict with new CREATE INDEX)
    db.execute('DROP INDEX IF EXISTS idx_category_ledger_configs_ledger_type');
    db.execute('DROP INDEX IF EXISTS idx_category_ledger_configs_updated_at');
    db.execute(
      'ALTER TABLE category_ledger_configs RENAME TO category_ledger_configs_old',
    );
    db.execute('''
      CREATE TABLE category_ledger_configs (
        category_id TEXT NOT NULL PRIMARY KEY,
        ledger_type TEXT NOT NULL
          CHECK(ledger_type IN ('daily', 'joy')),
        updated_at INTEGER NOT NULL
      )
    ''');
    db.execute('''
      CREATE INDEX idx_category_ledger_configs_ledger_type
      ON category_ledger_configs(ledger_type)
    ''');
    db.execute('''
      CREATE INDEX idx_category_ledger_configs_updated_at
      ON category_ledger_configs(updated_at)
    ''');
    db.execute('''
      INSERT INTO category_ledger_configs (category_id, ledger_type, updated_at)
      SELECT category_id,
             CASE ledger_type
               WHEN 'survival' THEN 'daily'
               WHEN 'soul'     THEN 'joy'
               ELSE ledger_type
             END,
             updated_at
      FROM category_ledger_configs_old
    ''');
    db.execute('DROP TABLE category_ledger_configs_old');

    // Sub-step 2: rewrite transactions.ledger_type values
    db.execute(
      "UPDATE transactions SET ledger_type = 'daily' WHERE ledger_type = 'survival'",
    );
    db.execute(
      "UPDATE transactions SET ledger_type = 'joy' WHERE ledger_type = 'soul'",
    );

    // Sub-step 3: rename soul_satisfaction column to joy_fullness (D-16)
    db.execute(
      'ALTER TABLE transactions RENAME COLUMN soul_satisfaction TO joy_fullness',
    );

    db.execute('COMMIT');
  } catch (e) {
    db.execute('ROLLBACK');
    rethrow;
  }
}

// ─── Row insertion helpers ─────────────────────────────────────────────────────

void _insertV17Tx(
  Database db,
  String id, {
  String ledgerType = 'survival',
  int soulSatisfaction = 5,
}) {
  final now = DateTime(2026, 6, 1).millisecondsSinceEpoch;
  db.execute(
    '''
    INSERT INTO transactions (
      id, book_id, device_id, amount, type, category_id, ledger_type,
      timestamp, current_hash, created_at,
      is_private, is_synced, is_deleted,
      soul_satisfaction, entry_source
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      id,
      'book_v17',
      'device_v17',
      1000,
      'expense',
      'cat_food',
      ledgerType,
      now,
      'hash_$id',
      now,
      0,
      0,
      0,
      soulSatisfaction,
      'manual',
    ],
  );
}

void _insertV17Config(Database db, String categoryId, String ledgerType) {
  final now = DateTime(2026, 6, 1).millisecondsSinceEpoch;
  db.execute(
    '''
    INSERT INTO category_ledger_configs (category_id, ledger_type, updated_at)
    VALUES (?, ?, ?)
    ''',
    [categoryId, ledgerType, now],
  );
}

void _insertPostMigrationConfig(
  Database db,
  String categoryId,
  String ledgerType,
) {
  final now = DateTime(2026, 6, 1).millisecondsSinceEpoch;
  db.execute(
    '''
    INSERT INTO category_ledger_configs (category_id, ledger_type, updated_at)
    VALUES (?, ?, ?)
    ''',
    [categoryId, ledgerType, now],
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // Test 1: schemaVersion guard — RED until Plan 31-02 bumps schemaVersion to 18
  test(
    'AppDatabase schemaVersion includes v18 ledger_type migration (D-02, D-16)',
    () {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      expect(
        db.schemaVersion,
        greaterThanOrEqualTo(_targetSchemaVersion),
        reason:
            'schemaVersion must be 18 once app_database.dart bumps the version '
            'and adds the if (from < 18) migration block',
      );
    },
  );

  group('v18 ledger_type migration — raw-sqlite3 contract tests', () {
    late Database rawDb;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      _createV17Tables(rawDb);
    });

    tearDown(() {
      rawDb.dispose();
    });

    // Test 2: transactions.ledger_type value rewrite (D-02)
    test(
      'rewrites transactions.ledger_type: survival→daily, soul→joy (D-02)',
      () {
        _insertV17Tx(rawDb, 'tx_survival', ledgerType: 'survival');
        _insertV17Tx(rawDb, 'tx_soul', ledgerType: 'soul');
        _runV18MigrationSteps(rawDb);

        final rows = rawDb.select(
          'SELECT id, ledger_type FROM transactions ORDER BY id',
        );
        final byId = {
          for (final r in rows) r['id'] as String: r['ledger_type'] as String,
        };

        expect(
          byId['tx_survival'],
          equals('daily'),
          reason:
              "'survival' must be rewritten to 'daily' by the v18 migration",
        );
        expect(
          byId['tx_soul'],
          equals('joy'),
          reason: "'soul' must be rewritten to 'joy' by the v18 migration",
        );
      },
    );

    // Test 3: configs CHECK recreate — new vocab accepted, old vocab rejected (D-02)
    // T-31-01 mitigation
    test(
      'category_ledger_configs accepts daily/joy and rejects survival/soul after CHECK recreate (D-02)',
      () {
        _runV18MigrationSteps(rawDb);

        // New vocabulary must be accepted without exception
        expect(
          () => _insertPostMigrationConfig(rawDb, 'cat_new_joy', 'joy'),
          returnsNormally,
          reason: "'joy' must be accepted by the recreated CHECK constraint",
        );
        expect(
          () => _insertPostMigrationConfig(rawDb, 'cat_new_daily', 'daily'),
          returnsNormally,
          reason: "'daily' must be accepted by the recreated CHECK constraint",
        );

        // Old vocabulary must be rejected — the CHECK widened from IN('survival','soul')
        // to IN('daily','joy'), so old values no longer satisfy the constraint
        expect(
          () => _insertPostMigrationConfig(rawDb, 'cat_bad_soul', 'soul'),
          throwsA(isA<SqliteException>()),
          reason:
              "'soul' must be REJECTED after the CHECK-recreate widens to IN('daily','joy')",
        );
        expect(
          () =>
              _insertPostMigrationConfig(rawDb, 'cat_bad_survival', 'survival'),
          throwsA(isA<SqliteException>()),
          reason:
              "'survival' must be REJECTED after the CHECK-recreate widens to IN('daily','joy')",
        );
      },
    );

    // Test 4: configs value rewrite + index preservation (D-02, A5 safeguard)
    // T-31-02 mitigation
    test(
      'category_ledger_configs rows rewired survival→daily, soul→joy; indices preserved (T-31-02 A5)',
      () {
        _insertV17Config(rawDb, 'cat_food', 'survival');
        _insertV17Config(rawDb, 'cat_hobby', 'soul');
        _runV18MigrationSteps(rawDb);

        final rows = rawDb.select(
          'SELECT category_id, ledger_type FROM category_ledger_configs ORDER BY category_id',
        );
        final byId = {
          for (final r in rows)
            r['category_id'] as String: r['ledger_type'] as String,
        };

        expect(
          byId['cat_food'],
          equals('daily'),
          reason: "config row 'survival' must become 'daily' after migration",
        );
        expect(
          byId['cat_hobby'],
          equals('joy'),
          reason: "config row 'soul' must become 'joy' after migration",
        );

        // A5 safeguard: both customIndices must still exist after the table recreate
        final indices = rawDb
            .select('PRAGMA index_list(category_ledger_configs)')
            .map((r) => r['name'] as String)
            .toSet();

        expect(
          indices,
          contains('idx_category_ledger_configs_ledger_type'),
          reason:
              'idx_category_ledger_configs_ledger_type must be recreated by the migration',
        );
        expect(
          indices,
          contains('idx_category_ledger_configs_updated_at'),
          reason:
              'idx_category_ledger_configs_updated_at must be recreated by the migration',
        );
      },
    );

    // Test 5: soul_satisfaction column rename to joy_fullness (D-16), data preserved
    test(
      'renames soul_satisfaction to joy_fullness with integer data preserved (D-16)',
      () {
        _insertV17Tx(rawDb, 'tx_sat', soulSatisfaction: 7);
        _runV18MigrationSteps(rawDb);

        // PRAGMA table_info must show joy_fullness and NOT soul_satisfaction
        final columns = rawDb
            .select('PRAGMA table_info(transactions)')
            .map((r) => r['name'] as String)
            .toList();

        expect(
          columns,
          contains('joy_fullness'),
          reason: 'Column must be renamed to joy_fullness after migration',
        );
        expect(
          columns,
          isNot(contains('soul_satisfaction')),
          reason:
              'Old column name soul_satisfaction must not exist after migration',
        );

        // Value must be preserved through the rename
        final result = rawDb.select(
          "SELECT joy_fullness FROM transactions WHERE id = 'tx_sat'",
        );
        expect(
          result.first['joy_fullness'],
          equals(7),
          reason:
              'soul_satisfaction value 7 must be readable as joy_fullness after rename',
        );
      },
    );

    // Test 6: row-count invariant — no rows added or dropped (T-31-01 mitigate)
    test(
      'row-count invariant: COUNT(*) unchanged in both tables after migration',
      () {
        // Seed N transactions (mix of survival + soul)
        _insertV17Tx(
          rawDb,
          'tx_rc_1',
          ledgerType: 'survival',
          soulSatisfaction: 3,
        );
        _insertV17Tx(rawDb, 'tx_rc_2', ledgerType: 'soul', soulSatisfaction: 8);
        _insertV17Tx(
          rawDb,
          'tx_rc_3',
          ledgerType: 'survival',
          soulSatisfaction: 2,
        );
        _insertV17Tx(rawDb, 'tx_rc_4', ledgerType: 'soul', soulSatisfaction: 5);
        _insertV17Tx(
          rawDb,
          'tx_rc_5',
          ledgerType: 'survival',
          soulSatisfaction: 1,
        );

        // Seed M category_ledger_configs (mix of survival + soul)
        _insertV17Config(rawDb, 'cat_rc_a', 'survival');
        _insertV17Config(rawDb, 'cat_rc_b', 'soul');
        _insertV17Config(rawDb, 'cat_rc_c', 'survival');

        final txBefore =
            rawDb.select('SELECT COUNT(*) AS c FROM transactions').first['c']
                as int;
        final cfgBefore =
            rawDb
                    .select('SELECT COUNT(*) AS c FROM category_ledger_configs')
                    .first['c']
                as int;

        _runV18MigrationSteps(rawDb);

        final txAfter =
            rawDb.select('SELECT COUNT(*) AS c FROM transactions').first['c']
                as int;
        final cfgAfter =
            rawDb
                    .select('SELECT COUNT(*) AS c FROM category_ledger_configs')
                    .first['c']
                as int;

        expect(
          txAfter,
          equals(txBefore),
          reason:
              'Migration must not add or remove transaction rows — only rewrite ledger_type values',
        );
        expect(
          cfgAfter,
          equals(cfgBefore),
          reason:
              'Migration must not add or remove category_ledger_configs rows — only rewrite + CHECK-recreate',
        );
      },
    );
  });

  // ─── CR-01 regression: v1–v3 → v18 satisfaction-column chain ────────────────
  //
  // The satisfaction column is ADDED at the onUpgrade `from < 4` step and
  // RENAMED (soul_satisfaction → joy_fullness) at the unconditional `from < 18`
  // step. For databases created at v1–v3, BOTH steps run in one upgrade. The
  // from<4 step MUST add the column under its original name `soul_satisfaction`
  // so the from<18 RENAME has a source to rename. A Phase-31 mechanical rename
  // of the from<4 step to `transactions.joyFullness` (column `joy_fullness`)
  // broke this: the rename then found no `soul_satisfaction` and an already
  // existing `joy_fullness`, crashing onUpgrade for every v1–v3 → v18 upgrade.
  //
  // CONTRACT: these tests mirror the satisfaction-column SQL in
  // app_database.dart's onUpgrade (from<4 ADD COLUMN, from<18 RENAME COLUMN).
  // Keep them in lockstep with that file.
  group('CR-01 — v1–v3 → v18 satisfaction-column rename chain', () {
    late Database rawDb;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      _createV3TransactionsTable(rawDb);
    });

    tearDown(() {
      rawDb.dispose();
    });

    test(
      'from<4 adds soul_satisfaction so the from<18 rename composes without crashing',
      () {
        // Seed a v3 row (no satisfaction column yet).
        _insertV3Tx(rawDb, 'tx_v3', ledgerType: 'survival');

        // from<4 step (app_database.dart): ADD COLUMN soul_satisfaction.
        rawDb.execute(
          'ALTER TABLE transactions ADD COLUMN soul_satisfaction INTEGER NOT NULL DEFAULT 2',
        );
        // from<18 step (app_database.dart): RENAME COLUMN soul_satisfaction -> joy_fullness.
        expect(
          () => rawDb.execute(
            'ALTER TABLE transactions RENAME COLUMN soul_satisfaction TO joy_fullness',
          ),
          returnsNormally,
          reason:
              'The from<4 column name must be soul_satisfaction so the from<18 '
              'rename has a source (CR-01).',
        );

        final columns = rawDb
            .select('PRAGMA table_info(transactions)')
            .map((r) => r['name'] as String)
            .toList();
        expect(columns, contains('joy_fullness'));
        expect(columns, isNot(contains('soul_satisfaction')));

        // Backfilled default preserved through the rename.
        final value = rawDb
            .select("SELECT joy_fullness FROM transactions WHERE id = 'tx_v3'")
            .first['joy_fullness'];
        expect(value, equals(2));
      },
    );

    test(
      'TRAP: adding the column as joy_fullness at from<4 makes the from<18 rename crash',
      () {
        // This documents the exact CR-01 regression. If the from<4 step ever
        // emits `joy_fullness` again, the from<18 rename below cannot find
        // `soul_satisfaction` (and `joy_fullness` already exists) → SQLite throws.
        rawDb.execute(
          'ALTER TABLE transactions ADD COLUMN joy_fullness INTEGER NOT NULL DEFAULT 2',
        );
        expect(
          () => rawDb.execute(
            'ALTER TABLE transactions RENAME COLUMN soul_satisfaction TO joy_fullness',
          ),
          throwsA(isA<SqliteException>()),
          reason:
              'No soul_satisfaction to rename and joy_fullness already present — '
              'this is the onUpgrade crash CR-01 guards against.',
        );
      },
    );
  });
}

// ─── CR-01 helpers ──────────────────────────────────────────────────────────

/// Create a v3-era transactions table: BEFORE soul_satisfaction (added at the
/// onUpgrade `from < 4` step) and BEFORE entry_source (added at `from < 17`)
/// existed. This is the on-disk state of a database originally created at v1–v3.
void _createV3TransactionsTable(Database db) {
  db.execute('''
    CREATE TABLE transactions (
      id TEXT NOT NULL PRIMARY KEY,
      book_id TEXT NOT NULL,
      device_id TEXT NOT NULL,
      amount INTEGER NOT NULL,
      type TEXT NOT NULL,
      category_id TEXT NOT NULL,
      ledger_type TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      note TEXT,
      photo_hash TEXT,
      merchant TEXT,
      metadata TEXT,
      prev_hash TEXT,
      current_hash TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER,
      is_private INTEGER NOT NULL DEFAULT 0 CHECK ("is_private" IN (0, 1)),
      is_synced INTEGER NOT NULL DEFAULT 0 CHECK ("is_synced" IN (0, 1)),
      is_deleted INTEGER NOT NULL DEFAULT 0 CHECK ("is_deleted" IN (0, 1))
    )
  ''');
}

void _insertV3Tx(
  Database db,
  String id, {
  String ledgerType = 'survival',
}) {
  final now = DateTime(2026, 6, 1).millisecondsSinceEpoch;
  db.execute(
    '''
    INSERT INTO transactions (
      id, book_id, device_id, amount, type, category_id, ledger_type,
      timestamp, current_hash, created_at,
      is_private, is_synced, is_deleted
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      id,
      'book_v3',
      'device_v3',
      1000,
      'expense',
      'cat_food',
      ledgerType,
      now,
      'hash_$id',
      now,
      0,
      0,
      0,
    ],
  );
}
