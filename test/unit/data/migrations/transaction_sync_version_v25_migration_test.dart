import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

Future<Set<String>> _columns(AppDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

void main() {
  test('fresh v25 schema includes transaction sync version columns', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    expect(db.schemaVersion, greaterThanOrEqualTo(25));
    expect(await _columns(db, 'transactions'), contains('sync_revision'));
    expect(
      await _columns(db, 'transactions'),
      contains('sync_origin_device_id'),
    );
  });

  test('real v24 to v25 migration backfills deterministic versions', () async {
    final directory = await Directory.systemTemp.createTemp(
      'transaction_sync_version_v25',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/app.sqlite');

    final staged = AppDatabase(NativeDatabase(file));
    await staged.customStatement('''
      INSERT INTO books (
        id, name, currency, device_id, created_at
      ) VALUES ('book-1', 'Main', 'JPY', 'device-a', 100)
    ''');
    await staged.customStatement('''
      INSERT INTO transactions (
        id, book_id, device_id, amount, type, category_id, ledger_type,
        timestamp, current_hash, created_at, updated_at, entry_source
      ) VALUES (
        'tx-1', 'book-1', 'device-a', 100, 'expense', 'cat-1', 'daily',
        100, 'hash', 100, 200, 'manual'
      )
    ''');
    await staged.customStatement(
      'ALTER TABLE transactions DROP COLUMN sync_origin_device_id',
    );
    await staged.customStatement(
      'ALTER TABLE transactions DROP COLUMN sync_revision',
    );
    await staged.customStatement('PRAGMA user_version = 24');
    await staged.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    final row = await upgraded.customSelect('''
      SELECT sync_revision, sync_origin_device_id
      FROM transactions WHERE id = 'tx-1'
    ''').getSingle();

    expect(row.read<int>('sync_revision'), 200000000);
    expect(row.read<String>('sync_origin_device_id'), 'device-a');
  });
}
