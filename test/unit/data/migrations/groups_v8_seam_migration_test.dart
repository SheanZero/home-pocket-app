import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Regression test for the v≤6 → v8 migration seam (quality report P1-4).
///
/// `createTable(groups)` / `createTable(groupMembers)` were guarded by
/// `from >= 7 && from < 8`, so a database created at v≤6 and upgraded later
/// never got the two tables — any group query would then fail at runtime.
/// (The sync_queue pair_id→group_id rebuild in the same block legitimately
/// needs the `from >= 7` guard: only a v7 database has the pair_id shape.)
///
/// This drives the REAL migration chain: a minimal hand-built v6 schema is
/// stamped into a file with user_version=6, then the file is reopened as
/// AppDatabase so Drift runs the genuine onUpgrade(6 → current) path
/// end-to-end.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('groups_v8_seam');
    dbFile = File('${tempDir.path}/app.sqlite');

    final raw = sqlite.sqlite3.open(dbFile.path);
    _createV6Schema(raw);
    raw.execute('PRAGMA user_version = 6');
    raw.dispose();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('upgrading a v6 database creates groups and group_members', () async {
    final db = AppDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);

    expect(await _tableExists(db, 'groups'), isTrue);
    expect(await _tableExists(db, 'group_members'), isTrue);

    // The v7-only sync_queue rebuild must have been skipped: from<7 already
    // created sync_queue in its current group_id shape.
    final syncCols = await _columnNames(db, 'sync_queue');
    expect(syncCols, contains('group_id'));
    expect(syncCols, isNot(contains('pair_id')));

    // The whole chain (v6 → current) must have completed: spot-check late
    // migrations landed on the same database.
    expect(await _tableExists(db, 'merchants'), isTrue);
    final txCols = await _columnNames(db, 'transactions');
    expect(txCols, containsAll(<String>['joy_fullness', 'entry_source']));
  });
}

Future<bool> _tableExists(AppDatabase db, String table) async {
  final rows = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
        variables: [Variable<String>(table)],
      )
      .get();
  return rows.isNotEmpty;
}

Future<Set<String>> _columnNames(AppDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.map((r) => r.read<String>('name')).toSet();
}

/// Minimal v6 schema — only the tables/columns the v6→current migration
/// steps read or alter. Tables first created by later migrations
/// (sync_queue, category_keyword_preferences, groups, user_profiles,
/// shopping_items, exchange_rates, merchants, ...) are deliberately absent.
void _createV6Schema(sqlite.Database db) {
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
    CREATE TABLE books (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      currency TEXT NOT NULL,
      device_id TEXT NOT NULL,
      is_archived INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
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
      is_archived INTEGER NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER
    )
  ''');
  db.execute('''
    CREATE TABLE category_ledger_configs (
      category_id TEXT NOT NULL PRIMARY KEY,
      ledger_type TEXT NOT NULL CHECK(ledger_type IN ('survival', 'soul')),
      updated_at INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE merchant_category_preferences (
      merchant_key TEXT NOT NULL PRIMARY KEY,
      preferred_category_id TEXT NOT NULL,
      last_override_category_id TEXT,
      override_streak INTEGER NOT NULL DEFAULT 0,
      updated_at INTEGER NOT NULL
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
      metadata TEXT,
      current_hash TEXT NOT NULL,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      soul_satisfaction INTEGER NOT NULL DEFAULT 2
    )
  ''');
}
