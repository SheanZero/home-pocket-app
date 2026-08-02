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
  test('fresh v32 has the durable group-scoped family sync outbox', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    expect(db.schemaVersion, greaterThanOrEqualTo(32));
    expect(
      await _columns(db, 'family_sync_outbox'),
      containsAll({
        'operation_id',
        'group_id',
        'entity_type',
        'entity_id',
        'revision',
        'operation_json',
        'is_tombstone',
        'attempt_count',
        'last_attempt_at',
        'created_at',
      }),
    );
  });

  test(
    'v31 to v32 creates an empty outbox without touching old data',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'family_sync_outbox_v32',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/app.sqlite');

      final staged = sqlite.sqlite3.open(file.path);
      staged.execute('CREATE TABLE sentinel (value TEXT NOT NULL)');
      staged.execute("INSERT INTO sentinel (value) VALUES ('preserved')");
      staged.execute('PRAGMA user_version = 31');
      staged.dispose();

      final upgraded = AppDatabase(NativeDatabase(file));
      addTearDown(upgraded.close);
      expect(
        (await upgraded.customSelect('SELECT value FROM sentinel').getSingle())
            .read<String>('value'),
        'preserved',
      );
      expect(await _columns(upgraded, 'family_sync_outbox'), isNotEmpty);
      expect(
        await upgraded
            .customSelect('SELECT COUNT(*) AS c FROM family_sync_outbox')
            .getSingle()
            .then((row) => row.read<int>('c')),
        0,
      );
    },
  );
}
