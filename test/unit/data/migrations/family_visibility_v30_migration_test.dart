import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

Future<Set<String>> _columns(AppDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

void main() {
  test(
    'fresh v30 persists visibility and offline withdrawal receipts',
    () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);

      expect(db.schemaVersion, greaterThanOrEqualTo(30));
      expect(
        await _columns(db, 'transactions'),
        containsAll({'family_sync_visibility', 'family_shared_revision'}),
      );
      expect(await _columns(db, 'sync_queue'), contains('withdrawal_receipts'));
    },
  );

  test('v29 migration keeps public shared and private fail-closed', () async {
    final directory = await Directory.systemTemp.createTemp(
      'family_visibility_v30',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/app.sqlite');

    final staged = sqlite.sqlite3.open(file.path);
    staged.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY NOT NULL,
        is_private INTEGER NOT NULL DEFAULT 0,
        sync_revision INTEGER NOT NULL DEFAULT 0
      )
    ''');
    staged.execute('''
      CREATE TABLE sync_queue (id TEXT PRIMARY KEY NOT NULL)
    ''');
    staged.execute('''
      INSERT INTO transactions (id, is_private, sync_revision) VALUES
        ('public', 0, 41),
        ('private', 1, 42)
    ''');
    staged.execute('PRAGMA user_version = 29');
    staged.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    final rows = await upgraded.customSelect('''
      SELECT id, family_sync_visibility, family_shared_revision
      FROM transactions ORDER BY id
    ''').get();

    final private = rows.firstWhere(
      (row) => row.read<String>('id') == 'private',
    );
    final public = rows.firstWhere((row) => row.read<String>('id') == 'public');
    expect(private.read<String>('family_sync_visibility'), 'localOnly');
    expect(private.read<int>('family_shared_revision'), 0);
    expect(public.read<String>('family_sync_visibility'), 'shared');
    expect(public.read<int>('family_shared_revision'), 41);
  });
}
