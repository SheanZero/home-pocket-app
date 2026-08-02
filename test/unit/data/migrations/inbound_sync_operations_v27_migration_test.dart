import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

Future<Set<String>> _columns(AppDatabase db) async {
  final rows = await db
      .customSelect('PRAGMA table_info(inbound_sync_operations)')
      .get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

Future<Set<String>> _indices(AppDatabase db) async {
  final rows = await db
      .customSelect('PRAGMA index_list(inbound_sync_operations)')
      .get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

void main() {
  const expectedColumns = {
    'operation_id',
    'group_id',
    'message_id',
    'state',
    'operation_json',
    'error_code',
    'created_at',
    'updated_at',
  };

  test('fresh v27 schema has applied ledger and quarantine indices', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    expect(db.schemaVersion, greaterThanOrEqualTo(27));
    expect(await _columns(db), containsAll(expectedColumns));
    expect(
      await _indices(db),
      containsAll({'idx_inbound_sync_state_updated', 'idx_inbound_sync_group'}),
    );
  });

  test('real v26 to v27 migration creates empty inbound ledger', () async {
    final directory = await Directory.systemTemp.createTemp('inbound_sync_v27');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/app.sqlite');

    final staged = AppDatabase(NativeDatabase(file));
    await staged.customStatement('DROP TABLE inbound_sync_operations');
    await staged.customStatement('PRAGMA user_version = 26');
    await staged.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);

    expect(await _columns(upgraded), containsAll(expectedColumns));
    final count = await upgraded
        .customSelect('SELECT COUNT(*) AS count FROM inbound_sync_operations')
        .getSingle();
    expect(count.read<int>('count'), 0);
  });
}
