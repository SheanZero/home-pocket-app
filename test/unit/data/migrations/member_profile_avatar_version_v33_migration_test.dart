import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

Future<Set<String>> _columns(AppDatabase db) async {
  final rows = await db.customSelect('PRAGMA table_info(group_members)').get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

void main() {
  test('fresh v33 persists independent profile and avatar versions', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    expect(db.schemaVersion, greaterThanOrEqualTo(33));
    expect(
      await _columns(db),
      containsAll({
        'profile_revision',
        'profile_origin_device_id',
        'profile_digest',
        'avatar_revision',
        'avatar_origin_device_id',
        'avatar_content_hash',
      }),
    );
  });

  test('v32 to v33 backfills deterministic revision-zero state', () async {
    final directory = await Directory.systemTemp.createTemp(
      'member_versions_v33',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/app.sqlite');

    final staged = sqlite.sqlite3.open(file.path);
    staged.execute('''
      CREATE TABLE group_members (
        group_id TEXT NOT NULL,
        device_id TEXT NOT NULL,
        display_name TEXT NOT NULL DEFAULT '',
        avatar_emoji TEXT NOT NULL DEFAULT '🏠',
        avatar_image_hash TEXT,
        PRIMARY KEY (group_id, device_id)
      )
    ''');
    staged.execute('''
      INSERT INTO group_members (
        group_id, device_id, display_name, avatar_emoji, avatar_image_hash
      ) VALUES ('group-a', 'device-a', 'Alice', '🌱', 'legacy-hash')
    ''');
    staged.execute('PRAGMA user_version = 32');
    staged.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    final row = await upgraded.customSelect('''
      SELECT profile_revision, profile_origin_device_id, profile_digest,
             avatar_revision, avatar_origin_device_id, avatar_content_hash
      FROM group_members
    ''').getSingle();
    expect(row.read<int>('profile_revision'), 0);
    expect(row.read<String>('profile_origin_device_id'), 'device-a');
    expect(
      row.read<String>('profile_digest'),
      sha256.convert(utf8.encode(jsonEncode(['Alice', '🌱']))).toString(),
    );
    expect(row.read<int>('avatar_revision'), 0);
    expect(row.read<String>('avatar_origin_device_id'), 'device-a');
    expect(row.read<String>('avatar_content_hash'), 'legacy-hash');
  });
}
