import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/merchant_category_preference_dao.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late AppDatabase db;
  late MerchantCategoryPreferenceDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = MerchantCategoryPreferenceDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MerchantCategoryPreferenceDao', () {
    test('upsert and findByMerchantKey', () async {
      final now = DateTime(2026, 2, 22, 10, 0);

      await dao.upsert(
        merchantKey: 'seven',
        preferredCategoryId: 'cat_food_groceries',
        lastOverrideCategoryId: null,
        overrideStreak: 0,
        updatedAt: now,
      );

      final row = await dao.findByMerchantKey('seven');
      expect(row, isNotNull);
      expect(row!.merchantKey, 'seven');
      expect(row.preferredCategoryId, 'cat_food_groceries');
      expect(row.lastOverrideCategoryId, isNull);
      expect(row.overrideStreak, 0);
    });

    test('upsert overwrites existing row', () async {
      final now = DateTime(2026, 2, 22, 10, 0);

      await dao.upsert(
        merchantKey: 'seven',
        preferredCategoryId: 'cat_food_groceries',
        lastOverrideCategoryId: null,
        overrideStreak: 0,
        updatedAt: now,
      );

      await dao.upsert(
        merchantKey: 'seven',
        preferredCategoryId: 'cat_food_dining_out',
        lastOverrideCategoryId: 'cat_food_dining_out',
        overrideStreak: 1,
        updatedAt: now.add(const Duration(minutes: 1)),
      );

      final row = await dao.findByMerchantKey('seven');
      expect(row, isNotNull);
      expect(row!.preferredCategoryId, 'cat_food_dining_out');
      expect(row.lastOverrideCategoryId, 'cat_food_dining_out');
      expect(row.overrideStreak, 1);
    });

    test(
      'schema migration from v5 creates merchant_category_preferences table',
      () async {
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
        final rawDb = sqlite.sqlite3.openInMemory();
        rawDb.execute('PRAGMA foreign_keys = OFF');

        rawDb.execute('''
        CREATE TABLE audit_logs (
          id TEXT PRIMARY KEY,
          event TEXT NOT NULL,
          device_id TEXT NOT NULL,
          book_id TEXT,
          transaction_id TEXT,
          details TEXT,
          timestamp INTEGER NOT NULL
        );
      ''');
        rawDb.execute('''
        CREATE TABLE books (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          currency TEXT NOT NULL,
          device_id TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER,
          is_archived INTEGER NOT NULL DEFAULT 0,
          transaction_count INTEGER NOT NULL DEFAULT 0,
          survival_balance INTEGER NOT NULL DEFAULT 0,
          soul_balance INTEGER NOT NULL DEFAULT 0
        );
      ''');
        rawDb.execute('''
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT NOT NULL,
          color TEXT NOT NULL,
          parent_id TEXT,
          level INTEGER NOT NULL,
          is_system INTEGER NOT NULL DEFAULT 0,
          is_archived INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER
        );
      ''');
        rawDb.execute('''
        CREATE TABLE category_ledger_configs (
          category_id TEXT PRIMARY KEY,
          ledger_type TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
        rawDb.execute('''
        CREATE TABLE transactions (
          id TEXT PRIMARY KEY,
          book_id TEXT NOT NULL,
          device_id TEXT NOT NULL,
          amount INTEGER NOT NULL,
          type TEXT NOT NULL,
          category_id TEXT NOT NULL,
          ledger_type TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          note TEXT,
          photo_hash TEXT,
          merchant TEXT,
          metadata TEXT,
          prev_hash TEXT,
          current_hash TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER,
          is_private INTEGER NOT NULL DEFAULT 0,
          is_synced INTEGER NOT NULL DEFAULT 0,
          is_deleted INTEGER NOT NULL DEFAULT 0,
          soul_satisfaction INTEGER NOT NULL DEFAULT 5
        );
      ''');
        rawDb.execute('PRAGMA user_version = 5');

        final migrationDb = AppDatabase(NativeDatabase.opened(rawDb));
        try {
          await migrationDb
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='merchant_category_preferences'",
              )
              .get();

          final table = await migrationDb
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='merchant_category_preferences'",
              )
              .getSingleOrNull();

          expect(table, isNotNull);
          expect(table!.data['name'], 'merchant_category_preferences');
        } finally {
          await migrationDb.close();
          driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
        }
      },
    );
  });
}
