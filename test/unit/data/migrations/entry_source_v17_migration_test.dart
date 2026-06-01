import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

const _targetSchemaVersion = 18;

void main() {
  test('AppDatabase schemaVersion includes v17 entry_source migration', () {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    expect(db.schemaVersion, _targetSchemaVersion);
  });

  group('v17 entry_source migration', () {
    late Database rawDb;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      _createV16TransactionsTable(rawDb);
    });

    tearDown(() {
      rawDb.dispose();
    });

    test(
      'backfills existing v16 row with entry_source = manual on migration',
      () {
        _insertV16Row(rawDb, 'tx_pre_v17');
        _runV17MigrationSteps(rawDb);

        final rows = rawDb.select(
          "SELECT entry_source FROM transactions WHERE id = 'tx_pre_v17'",
        );

        expect(rows.first['entry_source'], equals('manual'));
      },
    );

    test('accepts voice after migration', () {
      _runV17MigrationSteps(rawDb);
      _insertV17Row(rawDb, 'tx_voice', 'voice');

      final rows = rawDb.select(
        "SELECT entry_source FROM transactions WHERE id = 'tx_voice'",
      );

      expect(rows.first['entry_source'], equals('voice'));
    });

    test('accepts ocr after migration', () {
      _runV17MigrationSteps(rawDb);
      _insertV17Row(rawDb, 'tx_ocr', 'ocr');

      final rows = rawDb.select(
        "SELECT entry_source FROM transactions WHERE id = 'tx_ocr'",
      );

      expect(rows.first['entry_source'], equals('ocr'));
    });

    test('rejects invalid entry_source after migration', () {
      _runV17MigrationSteps(rawDb);

      expect(
        () => _insertV17Row(rawDb, 'tx_invalid', 'keyboard'),
        throwsA(isA<SqliteException>()),
      );
    });

    test('adds non-null entry_source column with manual default', () {
      _runV17MigrationSteps(rawDb);

      final column = rawDb
          .select('PRAGMA table_info(transactions)')
          .singleWhere((row) => row['name'] == 'entry_source');

      expect(column['notnull'], equals(1));
      expect(column['dflt_value'].toString(), contains('manual'));
    });
  });
}

void _createV16TransactionsTable(Database db) {
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
      CHECK(soul_satisfaction BETWEEN 1 AND 10)
    )
  ''');
}

void _runV17MigrationSteps(Database db) {
  db.execute(
    '''ALTER TABLE transactions ADD COLUMN entry_source TEXT NOT NULL '''
    '''DEFAULT 'manual' CHECK(entry_source IN ('manual', 'voice', 'ocr'))''',
  );
}

void _insertV16Row(Database db, String id) {
  final now = DateTime(2026, 5, 21, 12).millisecondsSinceEpoch;
  db.execute(
    '''
      INSERT INTO transactions (
        id,
        book_id,
        device_id,
        amount,
        type,
        category_id,
        ledger_type,
        timestamp,
        current_hash,
        created_at,
        soul_satisfaction
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      id,
      'book_v16',
      'device_v16',
      1200,
      'expense',
      'cat_joy',
      'soul',
      now,
      'hash_$id',
      now,
      5,
    ],
  );
}

void _insertV17Row(Database db, String id, String entrySource) {
  final now = DateTime(2026, 5, 21, 12).millisecondsSinceEpoch;
  db.execute(
    '''
      INSERT INTO transactions (
        id,
        book_id,
        device_id,
        amount,
        type,
        category_id,
        ledger_type,
        timestamp,
        current_hash,
        created_at,
        soul_satisfaction,
        entry_source
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      id,
      'book_v17',
      'device_v17',
      1200,
      'expense',
      'cat_joy',
      'soul',
      now,
      'hash_$id',
      now,
      5,
      entrySource,
    ],
  );
}
