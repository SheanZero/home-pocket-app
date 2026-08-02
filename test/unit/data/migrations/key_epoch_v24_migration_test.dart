import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

Future<Set<String>> _columns(AppDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

void main() {
  test('fresh schema includes group and queue key epochs', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    expect(db.schemaVersion, greaterThanOrEqualTo(24));
    expect(await _columns(db, 'groups'), contains('key_epoch'));
    expect(await _columns(db, 'sync_queue'), contains('key_epoch'));
  });

  test(
    'real v23 to v24 migration adds epoch 1 defaults to existing rows',
    () async {
      final directory = await Directory.systemTemp.createTemp('key_epoch_v24');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/app.sqlite');

      final staged = AppDatabase(NativeDatabase(file));
      await staged.customStatement('''
      INSERT INTO groups (
        group_id, status, role, group_name, created_at
      ) VALUES ('group-1', 'active', 'owner', 'Family', 1)
    ''');
      await staged.customStatement('''
      INSERT INTO sync_queue (
        id, group_id, encrypted_payload, vector_clock,
        operation_count, retry_count, created_at
      ) VALUES ('queue-1', 'group-1', 'ciphertext', '{}', 1, 0, 1)
    ''');
      await staged.customStatement(
        'ALTER TABLE sync_queue DROP COLUMN key_epoch',
      );
      await staged.customStatement('ALTER TABLE groups DROP COLUMN key_epoch');
      await staged.customStatement('PRAGMA user_version = 23');
      await staged.close();

      final upgraded = AppDatabase(NativeDatabase(file));
      addTearDown(upgraded.close);

      final groupEpoch = await upgraded
          .customSelect(
            "SELECT key_epoch FROM groups WHERE group_id = 'group-1'",
          )
          .getSingle();
      final queueEpoch = await upgraded
          .customSelect(
            'SELECT key_epoch FROM sync_queue WHERE id = \'queue-1\'',
          )
          .getSingle();
      expect(groupEpoch.read<int>('key_epoch'), 1);
      expect(queueEpoch.read<int>('key_epoch'), 1);
    },
  );
}
