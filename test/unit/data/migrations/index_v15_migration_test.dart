import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

const _targetSchemaVersion = 15;

void main() {
  test('AppDatabase schemaVersion is 15', () {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    expect(db.schemaVersion, _targetSchemaVersion);
  });

  group('v15 index migration', () {
    late Database rawDb;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      _createV14Tables(rawDb);
    });

    tearDown(() {
      rawDb.dispose();
    });

    test('creates audit log indices', () {
      _runV15MigrationSteps(rawDb);

      expect(
        _indexNames(rawDb, 'audit_logs'),
        containsAll({
          'idx_audit_logs_event',
          'idx_audit_logs_device_id',
          'idx_audit_logs_timestamp',
        }),
      );
    });

    test('creates user profile indices', () {
      _runV15MigrationSteps(rawDb);

      expect(
        _indexNames(rawDb, 'user_profiles'),
        contains('idx_user_profiles_updated_at'),
      );
    });

    test('creates category ledger config indices', () {
      _runV15MigrationSteps(rawDb);

      expect(
        _indexNames(rawDb, 'category_ledger_configs'),
        containsAll({
          'idx_category_ledger_configs_ledger_type',
          'idx_category_ledger_configs_updated_at',
        }),
      );
    });
  });
}

void _createV14Tables(Database db) {
  db.execute('''
    CREATE TABLE audit_logs (
      id TEXT NOT NULL PRIMARY KEY,
      event TEXT NOT NULL,
      device_id TEXT NOT NULL,
      book_id TEXT,
      transaction_id TEXT,
      details TEXT,
      timestamp INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE user_profiles (
      id TEXT NOT NULL PRIMARY KEY,
      display_name TEXT NOT NULL,
      avatar_emoji TEXT NOT NULL,
      avatar_image_path TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE category_ledger_configs (
      category_id TEXT NOT NULL PRIMARY KEY,
      ledger_type TEXT NOT NULL CHECK(ledger_type IN ('survival', 'soul')),
      updated_at INTEGER NOT NULL
    )
  ''');
}

void _runV15MigrationSteps(Database db) {
  db.execute(
    'CREATE INDEX IF NOT EXISTS idx_audit_logs_event ON audit_logs (event)',
  );
  db.execute(
    'CREATE INDEX IF NOT EXISTS idx_audit_logs_device_id ON audit_logs (device_id)',
  );
  db.execute(
    'CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs (timestamp)',
  );
  db.execute(
    'CREATE INDEX IF NOT EXISTS idx_user_profiles_updated_at ON user_profiles (updated_at)',
  );
  db.execute(
    'CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_ledger_type ON category_ledger_configs (ledger_type)',
  );
  db.execute(
    'CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_updated_at ON category_ledger_configs (updated_at)',
  );
}

Set<String> _indexNames(Database db, String tableName) {
  return db
      .select("PRAGMA index_list('$tableName')")
      .map((row) => row['name'] as String)
      .toSet();
}
