import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  test('phase 6 indexed tables expose columns, primary keys, and indices', () {
    final audit = db.auditLogs;
    expect(
      [
        audit.id.name,
        audit.event.name,
        audit.deviceId.name,
        audit.bookId.name,
        audit.transactionId.name,
        audit.details.name,
        audit.timestamp.name,
      ],
      [
        'id',
        'event',
        'device_id',
        'book_id',
        'transaction_id',
        'details',
        'timestamp',
      ],
    );
    expect(audit.primaryKey, contains(audit.id));
    expect(
      audit.customIndices.map((index) => index.name),
      containsAll([
        'idx_audit_logs_event',
        'idx_audit_logs_device_id',
        'idx_audit_logs_timestamp',
      ]),
    );

    final profiles = db.userProfiles;
    expect(
      [
        profiles.id.name,
        profiles.displayName.name,
        profiles.avatarEmoji.name,
        profiles.avatarImagePath.name,
        profiles.createdAt.name,
        profiles.updatedAt.name,
      ],
      [
        'id',
        'display_name',
        'avatar_emoji',
        'avatar_image_path',
        'created_at',
        'updated_at',
      ],
    );
    expect(profiles.primaryKey, contains(profiles.id));
    expect(profiles.customIndices.single.name, 'idx_user_profiles_updated_at');

    final configs = db.categoryLedgerConfigs;
    expect(
      [
        configs.categoryId.name,
        configs.ledgerType.name,
        configs.updatedAt.name,
      ],
      ['category_id', 'ledger_type', 'updated_at'],
    );
    expect(configs.primaryKey, contains(configs.categoryId));
    expect(
      configs.customIndices.map((index) => index.name),
      containsAll([
        'idx_category_ledger_configs_ledger_type',
        'idx_category_ledger_configs_updated_at',
      ]),
    );
  });

  test('v15 app database migration creates phase 6 indices', () async {
    await db.migration.onUpgrade(db.createMigrator(), 14, 15);

    expect(
      await _indexNames(db, 'audit_logs'),
      containsAll([
        'idx_audit_logs_event',
        'idx_audit_logs_device_id',
        'idx_audit_logs_timestamp',
      ]),
    );
    expect(
      await _indexNames(db, 'user_profiles'),
      contains('idx_user_profiles_updated_at'),
    );
    expect(
      await _indexNames(db, 'category_ledger_configs'),
      containsAll([
        'idx_category_ledger_configs_ledger_type',
        'idx_category_ledger_configs_updated_at',
      ]),
    );
  });

  test('legacy v4 database upgrades through cleanup migrations', () async {
    final rawDb = sqlite3.openInMemory();
    _createV4Schema(rawDb);
    rawDb.execute('PRAGMA user_version = 4');

    final migrationDb = AppDatabase(NativeDatabase.opened(rawDb));
    addTearDown(migrationDb.close);

    await migrationDb.customSelect('SELECT 1').get();

    expect(await _hasColumn(migrationDb, 'categories', 'is_archived'), isTrue);
    expect(await _hasColumn(migrationDb, 'categories', 'updated_at'), isTrue);
    expect(
      await _hasTable(migrationDb, 'merchant_category_preferences'),
      isTrue,
    );
    expect(
      await _hasTable(migrationDb, 'category_keyword_preferences'),
      isTrue,
    );
    expect(await _hasTable(migrationDb, 'sync_queue'), isTrue);
    expect(await _hasTable(migrationDb, 'user_profiles'), isTrue);
    expect(await _hasColumn(migrationDb, 'books', 'is_shadow'), isTrue);
    expect(await _hasColumn(migrationDb, 'books', 'group_id'), isTrue);
    expect(await _hasColumn(migrationDb, 'books', 'owner_device_id'), isTrue);
    expect(await _hasColumn(migrationDb, 'books', 'owner_device_name'), isTrue);
  });

  test('legacy v8 database upgrades group and profile columns', () async {
    final rawDb = sqlite3.openInMemory();
    _createV8Schema(rawDb);
    rawDb.execute('PRAGMA user_version = 8');

    final migrationDb = AppDatabase(NativeDatabase.opened(rawDb));
    addTearDown(migrationDb.close);

    await migrationDb.customSelect('SELECT 1').get();

    expect(await _hasColumn(migrationDb, 'groups', 'book_id'), isFalse);
    expect(await _hasColumn(migrationDb, 'groups', 'group_name'), isTrue);
    expect(
      await _hasColumn(migrationDb, 'group_members', 'display_name'),
      isTrue,
    );
    expect(
      await _hasColumn(migrationDb, 'group_members', 'avatar_emoji'),
      isTrue,
    );
    expect(
      await _hasColumn(migrationDb, 'group_members', 'avatar_image_path'),
      isTrue,
    );
    expect(
      await _hasColumn(migrationDb, 'group_members', 'avatar_image_hash'),
      isTrue,
    );
    final displayName = await migrationDb
        .customSelect(
          "SELECT display_name FROM group_members WHERE device_id = 'device-1'",
        )
        .getSingle();
    expect(displayName.data['display_name'], 'Phone');
  });
}

Future<List<String>> _indexNames(AppDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA index_list($table)').get();
  return [
    for (final row in rows)
      if (row.data['name'] case final String name) name,
  ];
}

Future<bool> _hasTable(AppDatabase db, String table) async {
  final row = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
        variables: [Variable(table)],
      )
      .getSingleOrNull();
  return row != null;
}

Future<bool> _hasColumn(AppDatabase db, String table, String column) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.any((row) => row.data['name'] == column);
}

void _createV4Schema(Database db) {
  db.execute('''
    CREATE TABLE books (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      currency TEXT NOT NULL,
      device_id TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER,
      is_archived INTEGER NOT NULL DEFAULT 0,
      transaction_count INTEGER NOT NULL DEFAULT 0,
      survival_balance INTEGER NOT NULL DEFAULT 0,
      soul_balance INTEGER NOT NULL DEFAULT 0
    )
  ''');
  db.execute('''
    CREATE TABLE categories (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      icon TEXT NOT NULL,
      color TEXT NOT NULL,
      parent_id TEXT,
      level INTEGER NOT NULL,
      type TEXT,
      is_system INTEGER NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      budget_amount INTEGER
    )
  ''');
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
      is_private INTEGER NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      soul_satisfaction INTEGER NOT NULL DEFAULT 5
    )
  ''');
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
    CREATE TABLE paired_devices (
      id TEXT NOT NULL PRIMARY KEY
    )
  ''');
}

void _createV8Schema(Database db) {
  _createV4Schema(db);
  db.execute(
    'ALTER TABLE categories ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0',
  );
  db.execute('ALTER TABLE categories ADD COLUMN updated_at INTEGER');
  db.execute('''
    CREATE TABLE category_ledger_configs (
      category_id TEXT NOT NULL PRIMARY KEY,
      ledger_type TEXT NOT NULL CHECK(ledger_type IN ('survival', 'soul')),
      updated_at INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE merchant_category_preferences (
      id TEXT NOT NULL PRIMARY KEY,
      merchant_hash TEXT NOT NULL,
      category_id TEXT NOT NULL,
      confidence REAL NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE category_keyword_preferences (
      id TEXT NOT NULL PRIMARY KEY,
      keyword TEXT NOT NULL,
      category_id TEXT NOT NULL,
      confidence REAL NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE sync_queue (
      id TEXT NOT NULL PRIMARY KEY,
      group_id TEXT NOT NULL,
      encrypted_payload TEXT NOT NULL,
      vector_clock TEXT NOT NULL,
      operation_count INTEGER NOT NULL,
      retry_count INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE groups (
      group_id TEXT NOT NULL PRIMARY KEY,
      status TEXT NOT NULL,
      role TEXT NOT NULL,
      book_id TEXT,
      invite_code TEXT,
      invite_expires_at INTEGER,
      group_key TEXT,
      created_at INTEGER NOT NULL,
      confirmed_at INTEGER,
      last_sync_at INTEGER
    )
  ''');
  db.execute('''
    CREATE TABLE group_members (
      group_id TEXT NOT NULL,
      device_id TEXT NOT NULL,
      public_key TEXT NOT NULL,
      device_name TEXT NOT NULL,
      role TEXT NOT NULL,
      status TEXT NOT NULL,
      PRIMARY KEY (group_id, device_id)
    )
  ''');
  db.execute('''
    INSERT INTO group_members (
      group_id, device_id, public_key, device_name, role, status
    ) VALUES (
      'group-1', 'device-1', 'public-key', 'Phone', 'owner', 'active'
    )
  ''');
}
