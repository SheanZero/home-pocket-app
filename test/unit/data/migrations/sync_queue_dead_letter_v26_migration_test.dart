import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

Future<Set<String>> _columns(AppDatabase db) async {
  final rows = await db.customSelect('PRAGMA table_info(sync_queue)').get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

void main() {
  const stateColumns = {
    'state',
    'last_error_code',
    'next_retry_at',
    'failed_at',
  };

  test('fresh v26 schema includes durable retry state', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    expect(db.schemaVersion, greaterThanOrEqualTo(26));
    expect(await _columns(db), containsAll(stateColumns));
  });

  test('real v25 to v26 migration keeps queued envelopes pending', () async {
    final directory = await Directory.systemTemp.createTemp(
      'sync_queue_dead_letter_v26',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/app.sqlite');

    final staged = AppDatabase(NativeDatabase(file));
    await staged.customStatement('''
      INSERT INTO sync_queue (
        id, group_id, encrypted_payload, key_epoch, vector_clock,
        operation_count, retry_count, created_at
      ) VALUES ('queue-1', 'group-1', 'ciphertext', 6, '{}', 1, 4, 1)
    ''');
    await staged.customStatement('DROP INDEX idx_sync_queue_state_retry');
    for (final column in stateColumns) {
      await staged.customStatement(
        'ALTER TABLE sync_queue DROP COLUMN $column',
      );
    }
    await staged.customStatement('PRAGMA user_version = 25');
    await staged.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    final row = await upgraded.customSelect('''
      SELECT state, last_error_code, next_retry_at, failed_at, key_epoch
      FROM sync_queue WHERE id = 'queue-1'
    ''').getSingle();

    expect(row.read<String>('state'), 'pending');
    expect(row.readNullable<String>('last_error_code'), isNull);
    expect(row.readNullable<int>('next_retry_at'), isNull);
    expect(row.readNullable<int>('failed_at'), isNull);
    expect(row.read<int>('key_epoch'), 6);
  });
}
