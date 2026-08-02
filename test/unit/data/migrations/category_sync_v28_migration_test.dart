import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

Future<Set<String>> _columns(AppDatabase db) async {
  final rows = await db.customSelect('PRAGMA table_info(categories)').get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

void main() {
  test(
    'fresh v28 schema contains independent shared category merge state',
    () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      expect(db.schemaVersion, greaterThanOrEqualTo(28));
      expect(
        await _columns(db),
        containsAll({
          'shared_revision',
          'shared_origin_device_id',
          'shared_is_deleted',
        }),
      );
    },
  );

  test(
    'v27 to v28 backfills custom revision without touching preferences',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'category_sync_v28',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/app.sqlite');
      final staged = AppDatabase(NativeDatabase(file));
      await staged.customStatement('''
      INSERT INTO categories (
        id, name, icon, color, level, is_system, is_archived, sort_order,
        created_at, updated_at
      ) VALUES ('custom', 'Mine', 'icon', '#123456', 1, 0, 1, 17, 100, 200)
    ''');
      await staged.customStatement(
        'ALTER TABLE categories DROP COLUMN shared_is_deleted',
      );
      await staged.customStatement(
        'ALTER TABLE categories DROP COLUMN shared_origin_device_id',
      );
      await staged.customStatement(
        'ALTER TABLE categories DROP COLUMN shared_revision',
      );
      await staged.customStatement('PRAGMA user_version = 27');
      await staged.close();

      final upgraded = AppDatabase(NativeDatabase(file));
      addTearDown(upgraded.close);
      final row = await upgraded.customSelect('''
      SELECT shared_revision, shared_origin_device_id, shared_is_deleted,
             is_archived, sort_order
      FROM categories WHERE id = 'custom'
    ''').getSingle();
      expect(row.read<int>('shared_revision'), 200000000);
      expect(row.read<String>('shared_origin_device_id'), '');
      expect(row.read<bool>('shared_is_deleted'), isFalse);
      expect(row.read<bool>('is_archived'), isTrue);
      expect(row.read<int>('sort_order'), 17);
    },
  );
}
