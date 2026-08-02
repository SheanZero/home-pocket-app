import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

Future<Set<String>> columns(AppDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

void main() {
  test(
    'fresh v29 contains control revision, lifecycle and event ledger',
    () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      expect(db.schemaVersion, greaterThanOrEqualTo(29));
      expect(
        await columns(db, 'groups'),
        containsAll({
          'control_revision',
          'control_updated_at',
          'control_snapshot_digest',
        }),
      );
      expect(
        await columns(db, 'group_members'),
        containsAll({
          'joined_at',
          'confirmed_at',
          'removed_at',
          'removal_reason',
        }),
      );
      expect(await columns(db, 'control_events'), contains('event_id'));
    },
  );

  test(
    'v28 to v29 preserves group and initializes safe legacy revision',
    () async {
      final directory = await Directory.systemTemp.createTemp('control_v29');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/app.sqlite');
      final staged = AppDatabase(NativeDatabase(file));
      await staged
          .into(staged.groups)
          .insert(
            GroupsCompanion.insert(
              groupId: 'legacy',
              status: 'active',
              role: 'owner',
              groupName: const Value('Legacy'),
              createdAt: 1,
            ),
          );
      await staged.customStatement(
        'ALTER TABLE groups DROP COLUMN control_snapshot_digest',
      );
      await staged.customStatement(
        'ALTER TABLE groups DROP COLUMN control_updated_at',
      );
      await staged.customStatement(
        'ALTER TABLE groups DROP COLUMN control_revision',
      );
      await staged.customStatement(
        'ALTER TABLE group_members DROP COLUMN removal_reason',
      );
      await staged.customStatement(
        'ALTER TABLE group_members DROP COLUMN removed_at',
      );
      await staged.customStatement(
        'ALTER TABLE group_members DROP COLUMN confirmed_at',
      );
      await staged.customStatement(
        'ALTER TABLE group_members DROP COLUMN joined_at',
      );
      await staged.customStatement('DROP TABLE control_events');
      await staged.customStatement('PRAGMA user_version = 28');
      await staged.close();

      final upgraded = AppDatabase(NativeDatabase(file));
      addTearDown(upgraded.close);
      final row = await upgraded
          .customSelect(
            "SELECT control_revision, control_snapshot_digest FROM groups WHERE group_id = 'legacy'",
          )
          .getSingle();
      expect(row.read<int>('control_revision'), 0);
      expect(row.read<String>('control_snapshot_digest'), '');
    },
  );
}
