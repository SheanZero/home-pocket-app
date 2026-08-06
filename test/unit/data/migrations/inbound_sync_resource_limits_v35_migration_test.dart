import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('fresh v35 exposes retryability and persisted payload bytes', () async {
    final database = AppDatabase.forTesting();
    addTearDown(database.close);

    expect(database.schemaVersion, greaterThanOrEqualTo(35));
    final columns = await database
        .customSelect('PRAGMA table_info(inbound_sync_operations)')
        .get();
    expect(
      columns.map((row) => row.read<String>('name')),
      containsAll(['retryable', 'payload_bytes']),
    );
  });

  test('v34 to v35 preserves rows and backfills payload metadata', () async {
    final directory = await Directory.systemTemp.createTemp(
      'inbound_resource_limits_v35_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/app.sqlite');
    final staged = sqlite.sqlite3.open(file.path);
    staged.execute('''
      CREATE TABLE inbound_sync_operations (
        group_id TEXT NOT NULL,
        operation_id TEXT NOT NULL,
        message_id TEXT NOT NULL,
        state TEXT NOT NULL,
        operation_json TEXT,
        error_code TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (group_id, operation_id)
      )
    ''');
    staged.execute('''
      INSERT INTO inbound_sync_operations VALUES
        ('group-a', 'applied', 'message-a', 'applied', NULL, NULL, 10, 11),
        ('group-a', 'retryable', 'message-b', 'quarantined',
         '{"entityType":"future"}', 'unsupported_entity_type', 20, 21),
        ('group-a', 'corrupt', 'message-c', 'quarantined',
         NULL, 'invalid_operation_payload', 30, 31)
    ''');
    staged.execute('PRAGMA user_version = 34');
    staged.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    final rows = await upgraded.customSelect('''
      SELECT operation_id, retryable, payload_bytes, created_at, updated_at
      FROM inbound_sync_operations ORDER BY operation_id
    ''').get();

    expect(rows, hasLength(3));
    expect(rows[0].read<String>('operation_id'), 'applied');
    expect(rows[0].read<int>('payload_bytes'), 0);
    expect(rows[1].read<String>('operation_id'), 'corrupt');
    expect(rows[1].read<int>('retryable'), 0);
    expect(rows[2].read<String>('operation_id'), 'retryable');
    expect(rows[2].read<int>('retryable'), 1);
    expect(rows[2].read<int>('payload_bytes'), greaterThan(0));
    expect(rows[2].read<int>('created_at'), 20);
    expect(rows[2].read<int>('updated_at'), 21);
  });
}
