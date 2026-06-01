import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../shared/constants/default_categories.dart';
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
  int get schemaVersion => 18;

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
          // CR-01: add the satisfaction column under its ORIGINAL name
          // `soul_satisfaction`, NOT the v18-renamed `joy_fullness`. The
          // unconditional `from < 18` step below runs RENAME COLUMN
          // soul_satisfaction TO joy_fullness; for v1–v3 → v18 upgrades that
          // rename has no source unless this step creates `soul_satisfaction`.
          // A mechanical Phase-31 rename to `transactions.joyFullness` (which
          // generates the column `joy_fullness`) made the from<18 rename crash
          // (no soul_satisfaction; joy_fullness already present). A raw
          // statement reproduces exactly what `addColumn(soulSatisfaction)`
          // emitted historically: INTEGER NOT NULL DEFAULT 2, no table-level
          // CHECK (migrator.addColumn never applied customConstraints).
          await customStatement(
            'ALTER TABLE transactions ADD COLUMN soul_satisfaction INTEGER NOT NULL DEFAULT 2',
          );
        }
        if (from < 5) {
          // Category model v2: add isArchived, updatedAt; create ledger configs
          await migrator.addColumn(categories, categories.isArchived);
          await migrator.addColumn(categories, categories.updatedAt);
          await migrator.createTable(categoryLedgerConfigs);

          // Migrate existing type data to ledger configs.
          // Use 'daily' (the v18-renamed value for the former 'survival' default)
          // because createTable(categoryLedgerConfigs) now creates the v18-era table
          // with CHECK IN('daily','joy'). Historical devices that had 'survival' at
          // v5 reach this code path only in test scenarios; the v18 migration handles
          // real devices upgrading from a v5-v17 database that already had 'survival'.
          await customStatement('''
            INSERT INTO category_ledger_configs (category_id, ledger_type, updated_at)
            SELECT id, 'daily', CAST(strftime('%s', 'now') * 1000 AS INTEGER)
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
            await migrator.addColumn(
              groupMembers,
              groupMembers.avatarImagePath,
            );
            await migrator.addColumn(
              groupMembers,
              groupMembers.avatarImageHash,
            );
            await customStatement(
              "UPDATE group_members SET display_name = device_name WHERE display_name = ''",
            );
          });
        }
        if (from < 14) {
          // v14: Category taxonomy upgrade — remap removed IDs, delete orphans,
          // then upsert the full v14 system category set.
          // Pre-upgrade: ensure category_ledger_configs has the new CHECK
          // IN('daily','joy') before any inserts (devices upgrading from v5-v13
          // may have the old CHECK IN('survival','soul') from before the v18
          // terminology rename; we update it here so v14 inserts succeed).
          // This is a no-op for devices where the table was already created
          // with the new CHECK (i.e., fresh installs on v18+ code).
          await customStatement(
            'DROP INDEX IF EXISTS idx_category_ledger_configs_ledger_type',
          );
          await customStatement(
            'DROP INDEX IF EXISTS idx_category_ledger_configs_updated_at',
          );
          await customStatement(
            'ALTER TABLE category_ledger_configs RENAME TO category_ledger_configs_pre14',
          );
          await migrator.createTable(categoryLedgerConfigs);
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_ledger_type '
            'ON category_ledger_configs (ledger_type)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_updated_at '
            'ON category_ledger_configs (updated_at)',
          );
          await customStatement('''
            INSERT OR IGNORE INTO category_ledger_configs (category_id, ledger_type, updated_at)
            SELECT category_id,
                   CASE ledger_type
                     WHEN 'survival' THEN 'daily'
                     WHEN 'soul'     THEN 'joy'
                     ELSE ledger_type
                   END,
                   updated_at
            FROM category_ledger_configs_pre14
          ''');
          await customStatement('DROP TABLE category_ledger_configs_pre14');
          await transaction(() async {
            const remaps = <String, String>{
              'cat_cash_card': 'cat_other_unclassified',
              'cat_uncategorized': 'cat_other_unclassified',
              'cat_daily_pets': 'cat_pet_other',
              'cat_other_allowance': 'cat_allowance_self',
              'cat_other_advances': 'cat_other_misc',
              'cat_other_business': 'cat_other_misc',
              'cat_other_debt': 'cat_other_misc',
              'cat_food_general': 'cat_food_other',
              'cat_food_breakfast': 'cat_food_dining_out',
              'cat_food_lunch': 'cat_food_dining_out',
              'cat_food_dinner': 'cat_food_dining_out',
              'cat_daily_general': 'cat_daily_other',
              'cat_transport_general': 'cat_transport_other',
              'cat_social_general': 'cat_social_other',
              'cat_utilities_general': 'cat_utilities_other',
              'cat_communication_info': 'cat_communication_other',
              'cat_insurance_general': 'cat_insurance_other',
              'cat_special_general': 'cat_special_other',
              'cat_special_furniture': 'cat_housing_furniture',
              'cat_special_housing': 'cat_housing_renovation',
            };

            // Step 1: remap removed/renamed category IDs in transactions
            for (final entry in remaps.entries) {
              await customStatement(
                'UPDATE transactions SET category_id = ? WHERE category_id = ?',
                [entry.value, entry.key],
              );
            }

            const removedIds = ['cat_cash_card', 'cat_uncategorized'];

            // Step 2: delete orphan ledger configs for removed L1 categories
            for (final id in removedIds) {
              await customStatement(
                'DELETE FROM category_ledger_configs WHERE category_id = ?',
                [id],
              );
            }

            // Step 3: delete removed system category rows
            for (final id in removedIds) {
              await customStatement(
                'DELETE FROM categories WHERE id = ? AND is_system = 1',
                [id],
              );
            }

            // Step 4: upsert all v14 system categories
            final nowMs = DateTime.now().millisecondsSinceEpoch;
            for (final cat in DefaultCategories.all) {
              final parentVal = cat.parentId == null
                  ? 'NULL'
                  : "'${cat.parentId}'";
              final isSystemVal = cat.isSystem ? 1 : 0;
              final isArchivedVal = cat.isArchived ? 1 : 0;
              await customStatement('''
                INSERT OR REPLACE INTO categories
                  (id, name, icon, color, parent_id, level,
                   is_system, is_archived, sort_order, created_at)
                VALUES
                  ('${cat.id}', '${cat.name}', '${cat.icon}', '${cat.color}',
                   $parentVal, ${cat.level},
                   $isSystemVal, $isArchivedVal, ${cat.sortOrder}, $nowMs)
              ''');
            }

            // Step 5: upsert ledger configs for v14 L1 categories.
            // NOTE: Use cfg.ledgerType.name directly ('daily'/'joy' after v18
            // rename). For devices upgrading from v1-v4 to v18, the
            // category_ledger_configs table was created by the from<5 step
            // which already uses the current createTable() definition with
            // CHECK IN('daily','joy'). For devices upgrading from v5-v17,
            // category_ledger_configs already exists with the old CHECK but
            // the v18 migration (below) recreates it with the new CHECK;
            // however for those devices this v14 block runs BEFORE v18, so
            // the old CHECK is still active. We resolve this by observing that
            // for v5-v17 devices this step is a no-op (the ledger configs were
            // already seeded at v5/v14 era). For v1-v4 devices the table was
            // just created by the v5 step with the new CHECK; using the new
            // vocab is correct. Using new vocab throughout is the only safe
            // approach given that createTable() always generates the current schema.
            for (final cfg in DefaultCategories.defaultLedgerConfigs) {
              final ledgerTypeStr = cfg.ledgerType.name;
              await customStatement('''
                INSERT OR REPLACE INTO category_ledger_configs
                  (category_id, ledger_type, updated_at)
                VALUES
                  ('${cfg.categoryId}', '$ledgerTypeStr', $nowMs)
              ''');
            }
          });
        }
        if (from < 15) {
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_audit_logs_event ON audit_logs (event)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_audit_logs_device_id ON audit_logs (device_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs (timestamp)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_user_profiles_updated_at ON user_profiles (updated_at)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_ledger_type ON category_ledger_configs (ledger_type)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_updated_at ON category_ledger_configs (updated_at)',
          );
        }
        if (from < 16) {
          // v16: transactions.joy_fullness default 5 -> 2 (D-02 / D-10
          // unipolar positive scale). No DDL needed: Drift expresses defaults
          // at the companion-class layer, not as SQL DEFAULT constraints.
          // CHECK(joy_fullness BETWEEN 1 AND 10) survives unchanged.
          // Pre-launch project: no backfill required (D-02).
        }
        if (from < 17) {
          // D-01: Phase 17 entry_source column. Column-level inline CHECK and
          // DEFAULT in a single ALTER TABLE statement. The DEFAULT clause
          // backfills pre-existing rows in one operation (D-04, no separate
          // UPDATE). Cannot use migrator.addColumn here because table-level
          // customConstraints are not applied by addColumn to existing rows
          // (RESEARCH Pitfall #1). The table-level entry in customConstraints
          // handles fresh installs; this statement handles migrated v16 rows.
          await customStatement(
            '''ALTER TABLE transactions ADD COLUMN entry_source TEXT NOT NULL '''
            '''DEFAULT 'manual' CHECK(entry_source IN ('manual', 'voice', 'ocr'))''',
          );
        }
        if (from < 18) {
          // D-02 + D-16: terminology rename (survival→daily, soul→joy) and
          // soul_satisfaction column rename to joy_fullness.
          // Three sub-steps, wrapped in a transaction for atomicity (T-31-04).
          // Sub-step ordering is critical (RESEARCH Pitfall 2): category_ledger_configs
          // table-recreate FIRST (old CHECK rejects 'daily'/'joy'), then UPDATE
          // transactions.ledger_type, then RENAME COLUMN.
          await transaction(() async {
            // Sub-step 1: recreate category_ledger_configs with new CHECK IN('daily','joy').
            // SQLite cannot ALTER a CHECK; the old CHECK IN('survival','soul') rejects
            // 'daily'/'joy', so recreate must precede the value INSERT.
            // Drop old indices first — RENAME TABLE keeps index names live, causing
            // CREATE INDEX to fail if IF NOT EXISTS is omitted (Plan 01 deviation fix).
            await customStatement(
              'DROP INDEX IF EXISTS idx_category_ledger_configs_ledger_type',
            );
            await customStatement(
              'DROP INDEX IF EXISTS idx_category_ledger_configs_updated_at',
            );
            await customStatement(
              'ALTER TABLE category_ledger_configs RENAME TO category_ledger_configs_old',
            );
            await migrator.createTable(categoryLedgerConfigs);
            // A5 safeguard: re-issue indices unconditionally in case createTable
            // does not re-apply customIndices (cheap + idempotent).
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_ledger_type '
              'ON category_ledger_configs (ledger_type)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_updated_at '
              'ON category_ledger_configs (updated_at)',
            );
            await customStatement('''
              INSERT INTO category_ledger_configs (category_id, ledger_type, updated_at)
              SELECT category_id,
                     CASE ledger_type
                       WHEN 'survival' THEN 'daily'
                       WHEN 'soul'     THEN 'joy'
                       ELSE ledger_type
                     END,
                     updated_at
              FROM category_ledger_configs_old
            ''');
            await customStatement('DROP TABLE category_ledger_configs_old');

            // Sub-step 2: rewrite transactions.ledger_type values.
            // No CHECK on transactions.ledger_type — plain UPDATE suffices.
            await customStatement(
              "UPDATE transactions SET ledger_type = 'daily' WHERE ledger_type = 'survival'",
            );
            await customStatement(
              "UPDATE transactions SET ledger_type = 'joy' WHERE ledger_type = 'soul'",
            );

            // Sub-step 3: rename soul_satisfaction column to joy_fullness (D-16).
            // SQLite preserves integer data through RENAME COLUMN.
            await customStatement(
              'ALTER TABLE transactions RENAME COLUMN soul_satisfaction TO joy_fullness',
            );
          });
        }
      },
    );
  }
}
