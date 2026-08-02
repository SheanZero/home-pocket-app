import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

/// Migration tests for schema v22 → v23 (index backfill).
///
/// The `customIndices` getter on table classes is decorative — Drift's
/// migrator never consumes it (CR-01, Phase 36). The fix pattern (explicit
/// CREATE INDEX from BOTH onCreate and an onUpgrade step) was only applied to
/// tables added after Phase 36; every older table's declared indices were
/// physically missing on some or all devices. v23 backfills them all.
///
/// Two concerns:
///   (1) Fresh install — every index declared via `TableIndex(name: ...)` in
///       lib/data/tables/*.dart physically exists after onCreate. The
///       declaration list is PARSED FROM SOURCE so a future table whose
///       declared indices are never created fails this test instead of
///       silently repeating CR-01.
///   (2) v22→v23 onUpgrade — the REAL `from < 23` block is driven via the
///       file-backed rewind pattern (mirrors merchant_v22_migration_test):
///       stamp the file at v22 with all declared indices dropped, reopen as
///       AppDatabase, and assert the production migrator recreated them.

/// Parses every declared TableIndex name from the table definition sources.
Set<String> _declaredIndexNames() {
  final dir = Directory('lib/data/tables');
  final pattern = RegExp(r"TableIndex\(\s*name:\s*'([^']+)'");
  final names = <String>{};
  for (final file in dir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    for (final match in pattern.allMatches(file.readAsStringSync())) {
      names.add(match.group(1)!);
    }
  }
  return names;
}

Future<Set<String>> _physicalIndexNames(AppDatabase db) async {
  final rows = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name NOT LIKE 'sqlite_autoindex%'",
      )
      .get();
  return rows.map((r) => r.read<String>('name')).toSet();
}

Future<Set<String>> _columnNames(AppDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

Future<int> _schemaVersion(AppDatabase db) async {
  final row = await db.customSelect('PRAGMA user_version').getSingle();
  return row.read<int>('user_version');
}

void main() {
  test('table sources declare the expected number of indices', () {
    // Sanity floor so a parser regression cannot make the suite pass vacuously.
    expect(_declaredIndexNames().length, greaterThanOrEqualTo(35));
  });

  group('v23 — fresh install (onCreate)', () {
    test('AppDatabase schemaVersion includes v23 index backfill', () {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      expect(db.schemaVersion, greaterThanOrEqualTo(23));
    });

    test('every declared TableIndex physically exists', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final physical = await _physicalIndexNames(db);
      final missing = _declaredIndexNames().difference(physical);
      expect(
        missing,
        isEmpty,
        reason:
            'customIndices is decorative — every declared index must be '
            'emitted explicitly from onCreate (CR-01). Missing: $missing',
      );
    });
  });

  group('legacy v22/v23/v25 → v36 drives the real migration ladder', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('index_v23_migration');
      dbFile = File('${tempDir.path}/app.sqlite');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    for (final sourceVersion in [22, 23, 25]) {
      test(
        'real v$sourceVersion shape preserves data and all indexes',
        () async {
          final declared = _declaredIndexNames();
          await _stageLegacyFixture(dbFile, sourceVersion);

          final upgraded = AppDatabase(NativeDatabase(dbFile));
          addTearDown(upgraded.close);

          expect(await _schemaVersion(upgraded), 36);
          expect(
            await _columnNames(upgraded, 'sync_queue'),
            containsAll({'state', 'next_retry_at'}),
          );
          expect(
            await _physicalIndexNames(upgraded),
            contains('idx_sync_queue_state_retry'),
          );

          final queue = await upgraded.customSelect('''
          SELECT encrypted_payload, retry_count, key_epoch, state,
                 next_retry_at
          FROM sync_queue WHERE id = 'legacy-queue'
        ''').getSingle();
          expect(queue.read<String>('encrypted_payload'), 'legacy-ciphertext');
          expect(queue.read<int>('retry_count'), 4);
          expect(queue.read<String>('state'), 'pending');
          expect(queue.readNullable<int>('next_retry_at'), isNull);
          expect(queue.read<int>('key_epoch'), sourceVersion >= 24 ? 7 : 1);

          final transaction = await upgraded.customSelect('''
          SELECT amount, note FROM transactions WHERE id = 'legacy-tx'
        ''').getSingle();
          expect(transaction.read<int>('amount'), 1234);
          expect(transaction.read<String>('note'), 'preserve-me');

          final physical = await _physicalIndexNames(upgraded);
          final missing = declared.difference(physical);
          expect(
            missing,
            isEmpty,
            reason:
                'v$sourceVersion→v36 must create every declared index. '
                'Missing: $missing',
          );
        },
      );
    }
  });
}

Future<void> _stageLegacyFixture(File file, int version) async {
  final staged = AppDatabase(NativeDatabase(file));
  await staged.customSelect('SELECT 1').get();
  await staged.customStatement('PRAGMA foreign_keys = OFF');

  // Tables introduced after v25 must not exist in a real v22/v23/v25 file.
  await staged.customStatement('DROP TABLE IF EXISTS family_sync_outbox');
  await staged.customStatement('DROP TABLE IF EXISTS control_events');
  await staged.customStatement('DROP TABLE IF EXISTS inbound_sync_operations');
  await staged.customStatement(
    'DROP TABLE IF EXISTS membership_rotation_intents',
  );

  await _replaceTransactionsWithLegacyShape(staged, version);
  await _replaceCategoriesWithLegacyShape(staged);
  await _replaceGroupsWithLegacyShape(staged, version);
  await _replaceGroupMembersWithLegacyShape(staged);
  await _replaceSyncQueueWithLegacyShape(staged, version);

  // v23 was the physical index backfill. Recreate the indexes belonging to
  // tables rebuilt above only for v23+ fixtures; v22 deliberately lacks them.
  if (version >= 23) {
    for (final statement in _legacyV23IndexStatements) {
      await staged.customStatement(statement);
    }
  }

  await staged.customStatement('PRAGMA user_version = $version');
  expect(await _schemaVersion(staged), version);
  expect(await _columnNames(staged, 'sync_queue'), isNot(contains('state')));
  expect(
    await _columnNames(staged, 'sync_queue'),
    isNot(contains('next_retry_at')),
  );
  expect(
    await _physicalIndexNames(staged),
    isNot(contains('idx_sync_queue_state_retry')),
  );
  await staged.close();
}

Future<void> _replaceTransactionsWithLegacyShape(
  AppDatabase db,
  int version,
) async {
  await db.customStatement('DROP TABLE transactions');
  final versionColumns = version >= 25
      ? '''
        sync_revision INTEGER NOT NULL DEFAULT 0,
        sync_origin_device_id TEXT NOT NULL DEFAULT '',
      '''
      : '';
  await db.customStatement('''
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
      $versionColumns
      joy_fullness INTEGER NOT NULL DEFAULT 2,
      entry_source TEXT NOT NULL DEFAULT 'manual',
      original_currency TEXT,
      original_amount INTEGER,
      applied_rate TEXT,
      CHECK(joy_fullness BETWEEN 1 AND 10),
      CHECK(entry_source IN ('manual', 'voice', 'ocr'))
    )
  ''');
  final versionValues = version >= 25
      ? 'sync_revision, sync_origin_device_id,'
      : '';
  final insertedVersionValues = version >= 25 ? "250000000, 'device-a'," : '';
  await db.customStatement('''
    INSERT INTO transactions (
      id, book_id, device_id, amount, type, category_id, ledger_type,
      timestamp, note, current_hash, created_at, updated_at,
      $versionValues joy_fullness, entry_source
    ) VALUES (
      'legacy-tx', 'legacy-book', 'device-a', 1234, 'expense',
      'legacy-category', 'daily', 100, 'preserve-me', 'hash', 100, 200,
      $insertedVersionValues 2, 'manual'
    )
  ''');
}

Future<void> _replaceCategoriesWithLegacyShape(AppDatabase db) async {
  await db.customStatement('DROP TABLE categories');
  await db.customStatement('''
    CREATE TABLE categories (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      icon TEXT NOT NULL,
      color TEXT NOT NULL,
      parent_id TEXT,
      level INTEGER NOT NULL CHECK(level IN (1, 2)),
      is_system INTEGER NOT NULL DEFAULT 0,
      is_archived INTEGER NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER
    )
  ''');
  await db.customStatement('''
    INSERT INTO categories (
      id, name, icon, color, level, created_at
    ) VALUES ('legacy-category', 'Legacy', 'tag', '#000000', 1, 100)
  ''');
}

Future<void> _replaceGroupsWithLegacyShape(AppDatabase db, int version) async {
  await db.customStatement('DROP TABLE groups');
  final epochColumn = version >= 24
      ? 'key_epoch INTEGER NOT NULL DEFAULT 1,'
      : '';
  await db.customStatement('''
    CREATE TABLE groups (
      group_id TEXT NOT NULL PRIMARY KEY,
      status TEXT NOT NULL,
      role TEXT NOT NULL,
      group_name TEXT NOT NULL DEFAULT '',
      invite_code TEXT,
      invite_expires_at INTEGER,
      group_key TEXT,
      $epochColumn
      created_at INTEGER NOT NULL,
      confirmed_at INTEGER,
      last_sync_at INTEGER
    )
  ''');
  final epochName = version >= 24 ? ', key_epoch' : '';
  final epochValue = version >= 24 ? ', 7' : '';
  await db.customStatement('''
    INSERT INTO groups (
      group_id, status, role, group_name, created_at$epochName
    ) VALUES ('legacy-group', 'active', 'owner', 'Legacy Family', 100$epochValue)
  ''');
}

Future<void> _replaceGroupMembersWithLegacyShape(AppDatabase db) async {
  await db.customStatement('DROP TABLE group_members');
  await db.customStatement('''
    CREATE TABLE group_members (
      group_id TEXT NOT NULL,
      device_id TEXT NOT NULL,
      public_key TEXT NOT NULL,
      device_name TEXT NOT NULL,
      role TEXT NOT NULL,
      status TEXT NOT NULL,
      display_name TEXT NOT NULL DEFAULT '',
      avatar_emoji TEXT NOT NULL DEFAULT '🏠',
      avatar_image_path TEXT,
      avatar_image_hash TEXT,
      PRIMARY KEY (group_id, device_id)
    )
  ''');
  await db.customStatement('''
    INSERT INTO group_members (
      group_id, device_id, public_key, device_name, role, status,
      display_name, avatar_emoji
    ) VALUES (
      'legacy-group', 'device-a', 'public-key', 'Phone', 'owner', 'active',
      'Alice', '🌱'
    )
  ''');
}

Future<void> _replaceSyncQueueWithLegacyShape(
  AppDatabase db,
  int version,
) async {
  await db.customStatement('DROP TABLE sync_queue');
  final epochColumn = version >= 24
      ? 'key_epoch INTEGER NOT NULL DEFAULT 1,'
      : '';
  await db.customStatement('''
    CREATE TABLE sync_queue (
      id TEXT NOT NULL PRIMARY KEY,
      group_id TEXT NOT NULL,
      encrypted_payload TEXT NOT NULL,
      $epochColumn
      vector_clock TEXT NOT NULL,
      operation_count INTEGER NOT NULL,
      retry_count INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
    )
  ''');
  final epochName = version >= 24 ? ', key_epoch' : '';
  final epochValue = version >= 24 ? ', 7' : '';
  await db.customStatement('''
    INSERT INTO sync_queue (
      id, group_id, encrypted_payload, vector_clock,
      operation_count, retry_count, created_at$epochName
    ) VALUES (
      'legacy-queue', 'legacy-group', 'legacy-ciphertext', '{}',
      2, 4, 100$epochValue
    )
  ''');
}

const _legacyV23IndexStatements = [
  'CREATE INDEX idx_tx_book_id ON transactions (book_id)',
  'CREATE INDEX idx_tx_category_id ON transactions (category_id)',
  'CREATE INDEX idx_tx_timestamp ON transactions (timestamp)',
  'CREATE INDEX idx_tx_ledger_type ON transactions (ledger_type)',
  'CREATE INDEX idx_tx_book_timestamp ON transactions (book_id, timestamp)',
  'CREATE INDEX idx_tx_book_deleted ON transactions (book_id, is_deleted)',
  'CREATE INDEX idx_categories_parent_id ON categories (parent_id)',
  'CREATE INDEX idx_categories_level ON categories (level)',
  'CREATE INDEX idx_categories_archived ON categories (is_archived)',
  'CREATE INDEX idx_groups_status ON groups (status)',
  'CREATE INDEX idx_group_members_group_id ON group_members (group_id)',
  'CREATE INDEX idx_group_members_status ON group_members (status)',
  'CREATE INDEX idx_sync_queue_created ON sync_queue (created_at)',
];
