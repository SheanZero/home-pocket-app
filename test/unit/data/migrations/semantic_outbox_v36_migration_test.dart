import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'v36 persists semantic merge versions for shopping and profile',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      expect(database.schemaVersion, greaterThanOrEqualTo(36));
      final shoppingColumns = await database
          .customSelect('PRAGMA table_info(shopping_items)')
          .get();
      final profileColumns = await database
          .customSelect('PRAGMA table_info(user_profiles)')
          .get();

      expect(
        shoppingColumns.map((row) => row.read<String>('name')),
        containsAll(<String>['sync_revision', 'sync_origin_device_id']),
      );
      expect(
        profileColumns.map((row) => row.read<String>('name')),
        containsAll(<String>['sync_revision', 'sync_origin_device_id']),
      );
    },
  );

  test(
    'v35 to v36 preserves semantic rows and backfills stable versions',
    () async {
      final directory = await Directory.systemTemp.createTemp('semantic_v36');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/app.sqlite');
      final staged = sqlite.sqlite3.open(file.path);
      staged.execute('''
        CREATE TABLE shopping_items (
          id TEXT NOT NULL PRIMARY KEY, device_id TEXT NOT NULL,
          list_type TEXT NOT NULL, name TEXT NOT NULL, ledger_type TEXT,
          category_id TEXT, tags TEXT, note TEXT, quantity INTEGER NOT NULL,
          estimated_price INTEGER, completed_at INTEGER,
          is_completed INTEGER NOT NULL, sort_order INTEGER NOT NULL,
          is_synced INTEGER NOT NULL, is_deleted INTEGER NOT NULL,
          added_by_book_id TEXT, created_at INTEGER NOT NULL, updated_at INTEGER
        )
      ''');
      staged.execute('''
        INSERT INTO shopping_items VALUES (
          'public-a', 'device-a', 'public', 'milk', NULL, NULL, NULL, NULL,
          1, NULL, NULL, 0, 0, 0, 0, NULL, 100, 200
        )
      ''');
      staged.execute('''
        CREATE TABLE user_profiles (
          id TEXT NOT NULL PRIMARY KEY, display_name TEXT NOT NULL,
          avatar_emoji TEXT NOT NULL, avatar_image_path TEXT,
          created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
        )
      ''');
      staged.execute('''
        INSERT INTO user_profiles VALUES
          ('profile-a', 'Alice', '🐱', NULL, 100, 300)
      ''');
      staged.execute('PRAGMA user_version = 35');
      staged.close();

      final upgraded = AppDatabase(NativeDatabase(file));
      addTearDown(upgraded.close);
      final shopping = await upgraded.customSelect('''
        SELECT name, sync_revision, sync_origin_device_id
        FROM shopping_items WHERE id = 'public-a'
      ''').getSingle();
      final profile = await upgraded.customSelect('''
        SELECT display_name, sync_revision FROM user_profiles
        WHERE id = 'profile-a'
      ''').getSingle();

      expect(shopping.read<String>('name'), 'milk');
      expect(shopping.read<int>('sync_revision'), 200000);
      expect(shopping.read<String>('sync_origin_device_id'), 'device-a');
      expect(profile.read<String>('display_name'), 'Alice');
      expect(profile.read<int>('sync_revision'), 300000);
    },
  );
}
