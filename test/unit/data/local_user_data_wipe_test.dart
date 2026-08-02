import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

Future<int> _count(AppDatabase db, String table) async {
  final row = await db
      .customSelect('SELECT COUNT(*) AS count FROM "$table"')
      .getSingle();
  return row.read<int>('count');
}

Future<void> _seedEverySensitiveTable(AppDatabase db) async {
  final statements = <String>[
    "INSERT INTO groups (group_id,status,role,group_name,invite_code,group_key,created_at) VALUES ('g','active','owner','family','invite','secret',1)",
    "INSERT INTO group_members (group_id,device_id,public_key,device_name,role,status) VALUES ('g','d','public','phone','owner','confirmed')",
    "INSERT INTO membership_rotation_intents (group_id,request_id,operation,target_device_id,expected_key_epoch,new_key_epoch,group_key,envelopes_json,created_at) VALUES ('g','r','remove','d2',1,2,'rotated-secret','[]',1)",
    "INSERT INTO books (id,name,currency,device_id,created_at) VALUES ('b','book','JPY','d',1)",
    "INSERT INTO categories (id,name,icon,color,level,created_at) VALUES ('c','custom','food','#000000',1,1)",
    "INSERT INTO category_ledger_configs (category_id,ledger_type,updated_at) VALUES ('c','daily',1)",
    "INSERT INTO category_keyword_preferences (keyword,category_id,last_used) VALUES ('secret-word','c',1)",
    "INSERT INTO merchant_category_preferences (merchant_key,preferred_category_id,updated_at) VALUES ('private-merchant','c',1)",
    "INSERT INTO transactions (id,book_id,device_id,amount,type,category_id,ledger_type,timestamp,note,current_hash,created_at,is_private) VALUES ('t','b','d',100,'expense','c','daily',1,'encrypted-note','hash',1,1)",
    "INSERT INTO shopping_items (id,device_id,list_type,name,note,created_at) VALUES ('s','d','private','private item','encrypted-note',1)",
    "INSERT INTO user_profiles (id,display_name,avatar_emoji,avatar_image_path,created_at,updated_at) VALUES ('p','name','fox','/app/avatars/private.jpg',1,1)",
    "INSERT INTO sync_queue (id,group_id,encrypted_payload,vector_clock,operation_count,state,created_at) VALUES ('q','g','cipher','{}',1,'dead_letter',1)",
    "INSERT INTO inbound_sync_operations (group_id,operation_id,message_id,state,operation_json,error_code,created_at,updated_at) VALUES ('g','op','msg','quarantined','{\"private\":true}','bad',1,1)",
    "INSERT INTO family_sync_outbox (operation_id,group_id,entity_type,entity_id,revision,operation_json,created_at) VALUES ('out','g','profile','d',1,'{\"private\":true}',1)",
    "INSERT INTO control_events (event_id,group_id,revision,event_type,occurred_at,processed_at) VALUES ('e','g',1,'member_left',1,1)",
    "INSERT INTO audit_logs (id,event,device_id,details,timestamp) VALUES ('a','dataExport','d','private detail',1)",
  ];
  for (final statement in statements) {
    await db.customStatement(statement);
  }
}

void main() {
  test(
    'schema classification covers every app table and fails closed on additions',
    () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();

      final actual =
          (await db
                  .customSelect(
                    "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
                  )
                  .get())
              .map((row) => row.read<String>('name'))
              .toSet();
      expect(
        AppDatabase.localUserDataTableNames.union(
          AppDatabase.preservedReferenceTableNames,
        ),
        actual,
      );

      await db.customStatement(
        'CREATE TABLE unexpected_sensitive_table (secret TEXT)',
      );
      await expectLater(db.wipeLocalUserData(), throwsStateError);
    },
  );

  test(
    'wipes every sensitive table, preserves reference data, and survives restart',
    () async {
      final temp = await Directory.systemTemp.createTemp('home-pocket-wipe-');
      addTearDown(() => temp.delete(recursive: true));
      final file = File('${temp.path}/app.db');
      var db = AppDatabase(NativeDatabase(file));
      await _seedEverySensitiveTable(db);
      await db.customStatement(
        "INSERT INTO exchange_rates (currency,rate_date,rate,fetched_at,source) VALUES ('USD',1,'150',1,'api')",
      );
      await db.customStatement(
        "INSERT INTO merchants (id,name_ja,region,category_id,ledger_hint) VALUES ('m','店','JP','c','daily')",
      );
      await db.customStatement(
        "INSERT INTO merchant_match_keys (id,merchant_id,surface,match_key,kind) VALUES ('mk','m','店','店','name')",
      );

      await db.wipeLocalUserData();
      final secureDelete = await db
          .customSelect('PRAGMA secure_delete')
          .getSingle();
      expect(secureDelete.read<int>('secure_delete'), 1);
      for (final table in AppDatabase.localUserDataTableNames) {
        expect(await _count(db, table), 0, reason: '$table must be empty');
      }
      for (final table in AppDatabase.preservedReferenceTableNames) {
        expect(
          await _count(db, table),
          1,
          reason: '$table is non-user reference data',
        );
      }

      await db.close();
      db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      for (final table in AppDatabase.localUserDataTableNames) {
        expect(
          await _count(db, table),
          0,
          reason: '$table must remain empty after restart',
        );
      }
    },
  );

  test('a database failure rolls back every table delete atomically', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    await _seedEverySensitiveTable(db);
    await db.customStatement(
      "CREATE TRIGGER fail_category_wipe BEFORE DELETE ON categories BEGIN SELECT RAISE(ABORT, 'injected wipe failure'); END",
    );

    await expectLater(db.wipeLocalUserData(), throwsA(anything));

    expect(await _count(db, 'transactions'), 1);
    expect(await _count(db, 'sync_queue'), 1);
    expect(await _count(db, 'groups'), 1);
    expect(await _count(db, 'categories'), 1);
  });
}
