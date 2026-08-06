import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

Future<Map<String, int>> _primaryKeyColumns(AppDatabase database) async {
  final rows = await database
      .customSelect('PRAGMA table_info(inbound_sync_operations)')
      .get();
  return {
    for (final row in rows)
      if (row.read<int>('pk') > 0)
        row.read<String>('name'): row.read<int>('pk'),
  };
}

void main() {
  test(
    'fresh v34 uses group and operation as the complete primary key',
    () async {
      final database = AppDatabase.forTesting();
      addTearDown(database.close);

      expect(database.schemaVersion, greaterThanOrEqualTo(34));
      expect(await _primaryKeyColumns(database), {
        'group_id': 1,
        'operation_id': 2,
      });
    },
  );

  test('v33 to v34 preserves every inbound ledger field', () async {
    final directory = await Directory.systemTemp.createTemp(
      'inbound_group_namespace_v34_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/app.sqlite');
    final staged = sqlite.sqlite3.open(file.path);
    staged.execute('''
      CREATE TABLE inbound_sync_operations (
        operation_id TEXT NOT NULL PRIMARY KEY,
        group_id TEXT NOT NULL,
        message_id TEXT NOT NULL,
        state TEXT NOT NULL,
        operation_json TEXT,
        error_code TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    staged.execute('''
      INSERT INTO inbound_sync_operations VALUES
        ('op-applied', 'group-a', 'message-a', 'applied', NULL, NULL, 10, 11),
        ('op-quarantine', 'group-b', 'message-b', 'quarantined',
         '{"entityType":"future"}', 'unsupported_entity_type', 20, 21)
    ''');
    staged.execute('PRAGMA user_version = 33');
    staged.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);

    expect(await _primaryKeyColumns(upgraded), {
      'group_id': 1,
      'operation_id': 2,
    });
    final rows = await upgraded.customSelect('''
          SELECT operation_id, group_id, message_id, state, operation_json,
                 error_code, created_at, updated_at
          FROM inbound_sync_operations ORDER BY operation_id
        ''').get();
    expect(rows, hasLength(2));
    expect(rows.first.read<String>('operation_id'), 'op-applied');
    expect(rows.first.read<String>('group_id'), 'group-a');
    expect(rows.first.read<String>('message_id'), 'message-a');
    expect(rows.first.read<String>('state'), 'applied');
    expect(rows.first.readNullable<String>('operation_json'), isNull);
    expect(rows.first.readNullable<String>('error_code'), isNull);
    expect(rows.first.read<int>('created_at'), 10);
    expect(rows.first.read<int>('updated_at'), 11);
    expect(rows.last.read<String>('operation_json'), '{"entityType":"future"}');
    expect(rows.last.read<String>('error_code'), 'unsupported_entity_type');
  });
}
