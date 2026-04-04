import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'tables/audit_logs_table.dart';
import 'tables/books_table.dart';
import 'tables/categories_table.dart';
import 'tables/category_keyword_preferences_table.dart';
import 'tables/category_ledger_configs_table.dart';
import 'tables/group_members_table.dart';
import 'tables/groups_table.dart';
import 'tables/merchant_category_preferences_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/transactions_table.dart';
import 'tables/user_profiles_table.dart';

part 'app_database.g.dart';

/// Main application database.
///
/// Contains all Drift tables for the app.
/// Schema version incremented when tables are added/modified.
@DriftDatabase(
  tables: [
    AuditLogs,
    Books,
    Categories,
    CategoryKeywordPreferences,
    CategoryLedgerConfigs,
    GroupMembers,
    Groups,
    MerchantCategoryPreferences,
    SyncQueue,
    Transactions,
    UserProfiles,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for testing.
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 3) {
          // Legacy: budgetAmount column was removed in v5, but older schemas
          // still need this migration step to reach v3.
          await customStatement(
            'ALTER TABLE categories ADD COLUMN budget_amount INTEGER',
          );
        }
        if (from < 4) {
          await migrator.addColumn(transactions, transactions.soulSatisfaction);
        }
        if (from < 5) {
          // Category model v2: add isArchived, updatedAt; create ledger configs
          await migrator.addColumn(categories, categories.isArchived);
          await migrator.addColumn(categories, categories.updatedAt);
          await migrator.createTable(categoryLedgerConfigs);

          // Migrate existing type data to ledger configs
          await customStatement('''
            INSERT INTO category_ledger_configs (category_id, ledger_type, updated_at)
            SELECT id, 'survival', CAST(strftime('%s', 'now') * 1000 AS INTEGER)
            FROM categories WHERE level = 1 AND type IS NOT NULL
          ''');

          // Fix L1/L2 parentId consistency
          await customStatement('''
            UPDATE categories SET parent_id = NULL
            WHERE level = 1 AND parent_id IS NOT NULL
          ''');
          await customStatement('''
            UPDATE categories SET is_archived = 1
            WHERE level = 2 AND parent_id IS NULL
          ''');
        }
        if (from < 6) {
          await migrator.createTable(merchantCategoryPreferences);
        }
        if (from < 7) {
          await migrator.createTable(categoryKeywordPreferences);
          await migrator.createTable(syncQueue);
        }
        if (from >= 7 && from < 8) {
          await migrator.createTable(groups);
          await migrator.createTable(groupMembers);

          await customStatement(
            'ALTER TABLE sync_queue RENAME TO sync_queue_old',
          );
          await migrator.createTable(syncQueue);
          await customStatement('''
            INSERT INTO sync_queue (
              id,
              group_id,
              encrypted_payload,
              vector_clock,
              operation_count,
              retry_count,
              created_at
            )
            SELECT
              id,
              pair_id,
              encrypted_payload,
              vector_clock,
              operation_count,
              retry_count,
              created_at
            FROM sync_queue_old
          ''');
          await customStatement('DROP TABLE sync_queue_old');
        }
        if (from < 9) {
          await customStatement('DROP TABLE IF EXISTS paired_devices');
        }
        if (from >= 8 && from < 10) {
          // Only drop book_id from groups if table was created in v8
          // (fresh installs from < 8 create groups without book_id)
          await customStatement('ALTER TABLE groups DROP COLUMN book_id');
          await customStatement('DROP INDEX IF EXISTS idx_groups_book_id');
        }
        if (from < 11) {
          await migrator.addColumn(books, books.isShadow);
          await migrator.addColumn(books, books.groupId);
          await migrator.addColumn(books, books.ownerDeviceId);
          await migrator.addColumn(books, books.ownerDeviceName);
        }
        if (from < 12) {
          await migrator.createTable(userProfiles);
        }
        if (from >= 8 && from < 13) {
          // Groups/GroupMembers tables were introduced in v8; only add columns
          // when upgrading from a schema that already contains them.
          await transaction(() async {
            await migrator.addColumn(groups, groups.groupName);
            await migrator.addColumn(groupMembers, groupMembers.displayName);
            await migrator.addColumn(groupMembers, groupMembers.avatarEmoji);
            await migrator.addColumn(groupMembers, groupMembers.avatarImagePath);
            await migrator.addColumn(groupMembers, groupMembers.avatarImageHash);
            await customStatement(
              "UPDATE group_members SET display_name = device_name WHERE display_name = ''",
            );
          });
        }
      },
    );
  }
}
