import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../shared/constants/default_categories.dart';
import 'tables/audit_logs_table.dart';
import 'tables/books_table.dart';
import 'tables/categories_table.dart';
import 'tables/category_keyword_preferences_table.dart';
import 'tables/category_ledger_configs_table.dart';
import 'tables/control_events_table.dart';
import 'tables/exchange_rates_table.dart';
import 'tables/family_sync_outbox_table.dart';
import 'tables/group_members_table.dart';
import 'tables/groups_table.dart';
import 'tables/inbound_sync_operations_table.dart';
import 'tables/merchant_category_preferences_table.dart';
import 'tables/merchant_match_keys_table.dart';
import 'tables/merchants_table.dart';
import 'tables/shopping_items_table.dart';
import 'tables/shopping_unit_usages_table.dart';
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
    ControlEvents,
    ExchangeRates,
    FamilySyncOutbox,
    GroupMembers,
    Groups,
    InboundSyncOperations,
    MerchantCategoryPreferences,
    MerchantMatchKeys,
    Merchants,
    ShoppingItems,
    ShoppingUnitUsages,
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
  int get schemaVersion => 36;

  /// Tables containing user, household, security-audit, or sync state.
  ///
  /// Keep this classification exhaustive. [wipeLocalUserData] compares it
  /// against sqlite_master and fails closed when a future schema table has not
  /// been deliberately classified.
  static const Set<String> localUserDataTableNames = {
    'audit_logs',
    'books',
    'categories',
    'category_keyword_preferences',
    'category_ledger_configs',
    'control_events',
    'family_sync_outbox',
    'group_members',
    'groups',
    'inbound_sync_operations',
    'membership_rotation_intents',
    'merchant_category_preferences',
    'shopping_items',
    'shopping_unit_usages',
    'sync_queue',
    'transactions',
    'user_profiles',
  };

  /// Re-downloadable or bundled reference data that contains no user or
  /// household identity. These rows remain so the open database stays usable
  /// after a local wipe; categories are intentionally not in this set because
  /// that table mixes system and user-created rows and is re-seeded afterward.
  static const Set<String> preservedReferenceTableNames = {
    'exchange_rates',
    'merchant_match_keys',
    'merchants',
  };

  /// Atomically deletes every row classified as local user data.
  ///
  /// This deliberately retains the SQLCipher database and its installation
  /// master key. Dropping that key while the live encrypted database file
  /// remains would make the next launch unrecoverable. Identity, family keys,
  /// records, learned preferences, audit data, and all sync recovery state are
  /// erased here; app-owned files and secure-storage identity are separate,
  /// restart-safe stages in ClearAllDataUseCase.
  Future<void> wipeLocalUserData() async {
    // Deleted plaintext must not remain recoverable from free database pages
    // while the installation master key is intentionally retained.
    await customStatement('PRAGMA secure_delete = ON');
    await transaction(() async {
      final rows = await customSelect(
        'SELECT name FROM sqlite_master '
        'WHERE type = \'table\' AND name NOT LIKE \'sqlite_%\'',
      ).get();
      final actual = rows.map((row) => row.read<String>('name')).toSet();
      final classified = {
        ...localUserDataTableNames,
        ...preservedReferenceTableNames,
      };
      final unknown = actual.difference(classified);
      final missing = classified.difference(actual);
      if (unknown.isNotEmpty || missing.isNotEmpty) {
        throw StateError(
          'Local-data wipe schema classification mismatch: '
          'unknown=${unknown.toList()..sort()}, '
          'missing=${missing.toList()..sort()}',
        );
      }

      // Dependents first. The complete sequence is one Drift transaction, so
      // any constraint, storage, or injected failure rolls back every delete.
      for (final table in const [
        'family_sync_outbox',
        'inbound_sync_operations',
        'control_events',
        'sync_queue',
        'membership_rotation_intents',
        'group_members',
        'shopping_unit_usages',
        'shopping_items',
        'transactions',
        'category_keyword_preferences',
        'merchant_category_preferences',
        'category_ledger_configs',
        'audit_logs',
        'user_profiles',
        'books',
        'categories',
        'groups',
      ]) {
        await customStatement('DELETE FROM "$table"');
      }
    });
    // Remove committed pre-wipe pages from a WAL sidecar before reporting
    // success. A checkpoint failure is surfaced; the whole wipe remains safe
    // to retry because all deletion statements are idempotent.
    await customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) async {
        await migrator.createAll();
        await _createMembershipRotationIntentsTable();
        // createAll() does not emit the customIndices getter (not a real Drift
        // API), so EVERY declared index must be created explicitly on fresh
        // installs (CR-01 Phase 36; extended to all tables in v23).
        await _createAllDeclaredIndexes();
      },
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
        if (from < 8) {
          // P1-4 seam fix: groups/group_members creation used to sit inside
          // the `from >= 7 && from < 8` block below, so a v≤6 database
          // upgrading past v8 never got the two tables. createTable emits
          // CREATE TABLE IF NOT EXISTS, so this is idempotent for v7 devices
          // that take both branches.
          await migrator.createTable(groups);
          await migrator.createTable(groupMembers);
        }
        if (from >= 7 && from < 8) {
          // v7-only: rebuild sync_queue from its v7 pair_id shape. A v≤6
          // database gets the current group_id shape directly from the
          // from<7 createTable above, so this rename/copy must not run there
          // (the SELECT below reads the v7-only pair_id column).
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
        if (from < 19) {
          // 260603-ti2: promote cat_food_dining_out to first sub-category of cat_food.
          // sortOrder: dining_out 2→1, groceries 1→2.
          // Only touches system categories (is_system=1); user-created categories unaffected.
          await customStatement(
            "UPDATE categories SET sort_order = 1 WHERE id = 'cat_food_dining_out' AND is_system = 1",
          );
          await customStatement(
            "UPDATE categories SET sort_order = 2 WHERE id = 'cat_food_groceries' AND is_system = 1",
          );
        }
        if (from < 20) {
          // Phase 36: shopping list — create the shopping_items table (v19→v20).
          // createTable emits the table DDL including customConstraints. The
          // customIndices getter is NOT consumed by Drift's migrator, so each
          // index must be created explicitly (mirrors every other table here).
          await migrator.createTable(shoppingItems);
          await _createShoppingItemIndexes();
        }
        if (from < 21) {
          // Phase 40: multi-currency — create exchange_rates table and add three
          // nullable foreign-currency provenance columns to transactions (STORE-01/02).
          //
          // CRITICAL: applied_rate is TEXT (TextColumn per D-04 / ADR-020). No DEFAULT
          // clause. No NOT NULL constraint. Nullable columns without DEFAULT must use
          // customStatement, not migrator.addColumn.
          await migrator.createTable(exchangeRates);
          await _createExchangeRateIndexes();
          await customStatement(
            'ALTER TABLE transactions ADD COLUMN original_currency TEXT',
          );
          await customStatement(
            'ALTER TABLE transactions ADD COLUMN original_amount INTEGER',
          );
          await customStatement(
            'ALTER TABLE transactions ADD COLUMN applied_rate TEXT',
          );
        }
        if (from < 22) {
          // Phase 49: merchant data foundation — create the merchants and
          // merchant_match_keys tables (MERCH-04/05). createTable emits the
          // table DDL; the customIndices getter is NOT consumed by Drift's
          // migrator, so the indexes must be created explicitly via the shared
          // merchant-index helper below (mirrors every other table here).
          await migrator.createTable(merchants);
          await migrator.createTable(merchantMatchKeys);
          await _createMerchantIndexes();
        }
        if (from < 23) {
          // v23: index backfill (quality report P1-1). The customIndices
          // getter is decorative, and only tables added after the CR-01
          // lesson (Phase 36) got explicit CREATE INDEX calls — 19 declared
          // indices were never created anywhere, and the audit_logs /
          // user_profiles / category_ledger_configs indices existed only on
          // upgraded devices (from<15), never on fresh installs. Backfill
          // every declared index; IF NOT EXISTS makes this idempotent for
          // whichever subset a given device already has.
          // The retry-recovery index belongs to v26 because its state and
          // next_retry_at columns do not exist in a real v8-v22 database yet.
          // Excluding it here keeps the v23 backfill schema-correct; the v26
          // rung creates it immediately after adding both columns.
          await _createAllDeclaredIndexes(includeSyncQueueRecoveryIndex: false);
        }
        if (from < 24) {
          // F-05: bind encrypted group data and offline queue entries to an
          // explicit key generation. Existing data predates rotation and is
          // therefore epoch 1. Some seam tests (and historical repair paths)
          // stamp the current table shape with an older user_version, so guard
          // each ALTER independently instead of assuming both columns are
          // absent.
          await transaction(() async {
            if (!await _tableHasColumn('groups', 'key_epoch')) {
              await migrator.addColumn(groups, groups.keyEpoch);
            }
            if (!await _tableHasColumn('sync_queue', 'key_epoch')) {
              await migrator.addColumn(syncQueue, syncQueue.keyEpoch);
            }
          });
        }
        if (from < 25) {
          // F-06: persist the bill reconciliation version. Historical rows
          // use their last mutation time as the initial Lamport value, while
          // device_id supplies the deterministic writer tie-breaker.
          await transaction(() async {
            if (!await _tableHasColumn('transactions', 'sync_revision')) {
              await migrator.addColumn(transactions, transactions.syncRevision);
            }
            if (!await _tableHasColumn(
              'transactions',
              'sync_origin_device_id',
            )) {
              await migrator.addColumn(
                transactions,
                transactions.syncOriginDeviceId,
              );
            }
            final revisionTimestamp =
                await _tableHasColumn('transactions', 'updated_at')
                ? 'COALESCE(updated_at, created_at)'
                : 'created_at';
            await customStatement('''
              UPDATE transactions
              SET sync_revision = $revisionTimestamp * 1000000
              WHERE sync_revision = 0
            ''');
            await customStatement('''
              UPDATE transactions
              SET sync_origin_device_id = device_id
              WHERE sync_origin_device_id = ''
            ''');
          });
        }
        if (from < 26) {
          // F-15: outbound sync failures must remain durable. Existing queued
          // envelopes are safe to retry and therefore start in `pending`.
          await transaction(() async {
            if (!await _tableHasColumn('sync_queue', 'state')) {
              await migrator.addColumn(syncQueue, syncQueue.state);
            }
            if (!await _tableHasColumn('sync_queue', 'last_error_code')) {
              await migrator.addColumn(syncQueue, syncQueue.lastErrorCode);
            }
            if (!await _tableHasColumn('sync_queue', 'next_retry_at')) {
              await migrator.addColumn(syncQueue, syncQueue.nextRetryAt);
            }
            if (!await _tableHasColumn('sync_queue', 'failed_at')) {
              await migrator.addColumn(syncQueue, syncQueue.failedAt);
            }
            await _createSyncQueueRecoveryIndex();
          });
        }
        if (from < 27) {
          // F-16: persist inbound operation idempotency and deterministic
          // quarantine before relay ACK. The table contains decrypted JSON only
          // inside the SQLCipher database; UI/logs expose safe error codes.
          await migrator.createTable(inboundSyncOperations);
          await _createInboundSyncOperationIndexes();
        }
        if (from < 28) {
          // F-20: custom category shared semantics use an independent version
          // and tombstone. Personal is_archived/sort_order/ledger config stay
          // local and therefore need no migration/backfill.
          await transaction(() async {
            if (!await _tableHasColumn('categories', 'shared_revision')) {
              await migrator.addColumn(categories, categories.sharedRevision);
            }
            if (!await _tableHasColumn(
              'categories',
              'shared_origin_device_id',
            )) {
              await migrator.addColumn(
                categories,
                categories.sharedOriginDeviceId,
              );
            }
            if (!await _tableHasColumn('categories', 'shared_is_deleted')) {
              await migrator.addColumn(categories, categories.sharedIsDeleted);
            }
            await customStatement('''
              UPDATE categories
              SET shared_revision = COALESCE(updated_at, created_at) * 1000000
              WHERE is_system = 0 AND shared_revision = 0
            ''');
          });
        }
        if (from < 29) {
          await transaction(() async {
            if (!await _tableHasColumn('groups', 'control_revision')) {
              await migrator.addColumn(groups, groups.controlRevision);
            }
            if (!await _tableHasColumn('groups', 'control_updated_at')) {
              await migrator.addColumn(groups, groups.controlUpdatedAt);
            }
            if (!await _tableHasColumn('groups', 'control_snapshot_digest')) {
              await migrator.addColumn(groups, groups.controlSnapshotDigest);
            }
            if (!await _tableHasColumn('group_members', 'joined_at')) {
              await migrator.addColumn(groupMembers, groupMembers.joinedAt);
            }
            if (!await _tableHasColumn('group_members', 'confirmed_at')) {
              await migrator.addColumn(groupMembers, groupMembers.confirmedAt);
            }
            if (!await _tableHasColumn('group_members', 'removed_at')) {
              await migrator.addColumn(groupMembers, groupMembers.removedAt);
            }
            if (!await _tableHasColumn('group_members', 'removal_reason')) {
              await migrator.addColumn(
                groupMembers,
                groupMembers.removalReason,
              );
            }
            await migrator.createTable(controlEvents);
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_control_events_group_revision '
              'ON control_events (group_id, revision)',
            );
          });
        }
        if (from < 30) {
          // F23: persist family visibility independently of the current
          // is_private flag, plus durable receipts for offline withdrawals.
          // Historical public rows retain their old full-sync semantics;
          // historical private rows fail closed as local-only.
          await transaction(() async {
            if (!await _tableHasColumn(
              'transactions',
              'family_sync_visibility',
            )) {
              await migrator.addColumn(
                transactions,
                transactions.familySyncVisibility,
              );
            }
            if (!await _tableHasColumn(
              'transactions',
              'family_shared_revision',
            )) {
              await migrator.addColumn(
                transactions,
                transactions.familySharedRevision,
              );
            }
            if (!await _tableHasColumn('sync_queue', 'withdrawal_receipts')) {
              await migrator.addColumn(syncQueue, syncQueue.withdrawalReceipts);
            }
            final privateColumn = await _tableHasColumn(
              'transactions',
              'is_private',
            );
            final privateExpression = privateColumn ? 'is_private' : '0';
            await customStatement('''
              UPDATE transactions
              SET family_sync_visibility = CASE
                    WHEN $privateExpression = 1 THEN 'localOnly'
                    ELSE 'shared'
                  END,
                  family_shared_revision = CASE
                    WHEN $privateExpression = 1 THEN 0
                    ELSE sync_revision
                  END
            ''');
          });
        }
        if (from < 31) {
          // C1: encrypted local write-ahead intent for membership rotations.
          // The next group key and per-device envelopes must survive process
          // death and ambiguous HTTP outcomes before any server mutation.
          await _createMembershipRotationIntentsTable();
        }
        if (from < 32) {
          // C3: transaction mutations and their pending family operations now
          // share one SQLCipher transaction. Historical rows are intentionally
          // not backfilled: when there is no active group, the existing initial
          // full sync remains the source for sharing public history.
          await migrator.createTable(familySyncOutbox);
          await _createFamilySyncOutboxIndexes();
        }
        if (from < 33) {
          // W2: profile identity and avatar content merge independently using
          // persisted revision/origin/digest tuples. Existing server basics
          // remain revision-zero fallbacks; a legacy verified avatar hash is
          // retained as its deterministic content identity.
          if (await _tableExists('group_members')) {
            await transaction(() async {
              if (!await _tableHasColumn('group_members', 'profile_revision')) {
                await migrator.addColumn(
                  groupMembers,
                  groupMembers.profileRevision,
                );
              }
              if (!await _tableHasColumn(
                'group_members',
                'profile_origin_device_id',
              )) {
                await migrator.addColumn(
                  groupMembers,
                  groupMembers.profileOriginDeviceId,
                );
              }
              if (!await _tableHasColumn('group_members', 'profile_digest')) {
                await migrator.addColumn(
                  groupMembers,
                  groupMembers.profileDigest,
                );
              }
              if (!await _tableHasColumn('group_members', 'avatar_revision')) {
                await migrator.addColumn(
                  groupMembers,
                  groupMembers.avatarRevision,
                );
              }
              if (!await _tableHasColumn(
                'group_members',
                'avatar_origin_device_id',
              )) {
                await migrator.addColumn(
                  groupMembers,
                  groupMembers.avatarOriginDeviceId,
                );
              }
              if (!await _tableHasColumn(
                'group_members',
                'avatar_content_hash',
              )) {
                await migrator.addColumn(
                  groupMembers,
                  groupMembers.avatarContentHash,
                );
                if (await _tableHasColumn(
                  'group_members',
                  'avatar_image_hash',
                )) {
                  await customStatement('''
                  UPDATE group_members
                  SET avatar_content_hash = COALESCE(avatar_image_hash, '')
                ''');
                }
              }
              if (await _tableHasColumn('group_members', 'display_name') &&
                  await _tableHasColumn('group_members', 'avatar_emoji') &&
                  await _tableHasColumn('group_members', 'device_id')) {
                final legacyMembers = await customSelect('''
                SELECT group_id, device_id, display_name, avatar_emoji
                FROM group_members
                WHERE profile_digest = ''
              ''').get();
                for (final member in legacyMembers) {
                  final deviceId = member.read<String>('device_id');
                  final profileDigest = sha256
                      .convert(
                        utf8.encode(
                          jsonEncode([
                            member.read<String>('display_name'),
                            member.read<String>('avatar_emoji'),
                          ]),
                        ),
                      )
                      .toString();
                  await customStatement(
                    '''UPDATE group_members
                     SET profile_origin_device_id = ?, profile_digest = ?,
                         avatar_origin_device_id = CASE
                           WHEN avatar_origin_device_id = '' THEN ?
                           ELSE avatar_origin_device_id
                         END
                     WHERE group_id = ? AND device_id = ?''',
                    [
                      deviceId,
                      profileDigest,
                      deviceId,
                      member.read<String>('group_id'),
                      deviceId,
                    ],
                  );
                }
              }
            });
          }
        }
        if (from < 34 && await _tableExists('inbound_sync_operations')) {
          // W3: operation ids are only unique inside one authoritative family.
          // Rebuild instead of ALTER so existing rows retain every recovery
          // field while the complete primary key becomes (group, operation).
          await transaction(() async {
            await customStatement('''
              CREATE TABLE inbound_sync_operations_v34 (
                group_id TEXT NOT NULL,
                operation_id TEXT NOT NULL,
                message_id TEXT NOT NULL,
                state TEXT NOT NULL,
                operation_json TEXT,
                error_code TEXT,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                PRIMARY KEY (group_id, operation_id)
              )
            ''');
            await customStatement('''
              INSERT INTO inbound_sync_operations_v34 (
                group_id, operation_id, message_id, state, operation_json,
                error_code, created_at, updated_at
              )
              SELECT group_id, operation_id, message_id, state,
                     operation_json, error_code, created_at, updated_at
              FROM inbound_sync_operations
            ''');
            await customStatement('DROP TABLE inbound_sync_operations');
            await customStatement(
              'ALTER TABLE inbound_sync_operations_v34 '
              'RENAME TO inbound_sync_operations',
            );
            await _createInboundSyncOperationIndexes();
          });
        }
        if (from < 35 && await _tableExists('inbound_sync_operations')) {
          // W4: bound decrypted quarantine storage without altering the
          // crash-before-ACK applied ledger. Existing complete payloads remain
          // retryable and receive their exact persisted UTF-8 byte count;
          // corrupt quarantine rows without payload fail closed.
          await transaction(() async {
            if (!await _tableHasColumn(
              'inbound_sync_operations',
              'retryable',
            )) {
              await migrator.addColumn(
                inboundSyncOperations,
                inboundSyncOperations.retryable,
              );
            }
            if (!await _tableHasColumn(
              'inbound_sync_operations',
              'payload_bytes',
            )) {
              await migrator.addColumn(
                inboundSyncOperations,
                inboundSyncOperations.payloadBytes,
              );
            }
            await customStatement('''
              UPDATE inbound_sync_operations
              SET retryable = CASE
                    WHEN state = 'quarantined' AND operation_json IS NULL
                      THEN 0
                    ELSE retryable
                  END,
                  payload_bytes = CASE
                    WHEN operation_json IS NULL THEN 0
                    ELSE length(CAST(operation_json AS BLOB))
                  END
            ''');
          });
        }
        if (from < 36) {
          // P0-01: semantic sources must retain their merge version across
          // restart and key rotation. The columns are deliberately added to
          // the business rows; the existing generic outbox schema already
          // stores the complete operation snapshot.
          await transaction(() async {
            if (await _tableExists('shopping_items')) {
              if (!await _tableHasColumn('shopping_items', 'sync_revision')) {
                await migrator.addColumn(
                  shoppingItems,
                  shoppingItems.syncRevision,
                );
              }
              if (!await _tableHasColumn(
                'shopping_items',
                'sync_origin_device_id',
              )) {
                await migrator.addColumn(
                  shoppingItems,
                  shoppingItems.syncOriginDeviceId,
                );
              }
              await customStatement('''
                UPDATE shopping_items
                SET sync_revision = CASE
                      WHEN list_type = 'public' THEN
                        COALESCE(updated_at, created_at, 0) * 1000
                      ELSE 0
                    END,
                    sync_origin_device_id = CASE
                      WHEN list_type = 'public' THEN device_id
                      ELSE ''
                    END
                WHERE sync_revision = 0
              ''');
            }
            if (await _tableExists('user_profiles')) {
              if (!await _tableHasColumn('user_profiles', 'sync_revision')) {
                await migrator.addColumn(
                  userProfiles,
                  userProfiles.syncRevision,
                );
              }
              if (!await _tableHasColumn(
                'user_profiles',
                'sync_origin_device_id',
              )) {
                await migrator.addColumn(
                  userProfiles,
                  userProfiles.syncOriginDeviceId,
                );
              }
              await customStatement('''
                UPDATE user_profiles
                SET sync_revision = updated_at * 1000
                WHERE sync_revision = 0
              ''');
            }
          });
        }
      },
    );
  }

  Future<bool> _tableHasColumn(String tableName, String columnName) async {
    final columns = await customSelect('PRAGMA table_info("$tableName")').get();
    return columns.any((row) => row.read<String>('name') == columnName);
  }

  Future<bool> _tableExists(String tableName) async {
    final row = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
      variables: [Variable<String>(tableName)],
    ).getSingleOrNull();
    return row != null;
  }

  Future<void> _createMembershipRotationIntentsTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS membership_rotation_intents (
        group_id TEXT NOT NULL PRIMARY KEY,
        request_id TEXT NOT NULL,
        operation TEXT NOT NULL
          CHECK (operation IN ('remove', 'leave', 'complete_leave')),
        target_device_id TEXT NOT NULL,
        expected_key_epoch INTEGER NOT NULL CHECK (expected_key_epoch >= 1),
        new_key_epoch INTEGER NOT NULL CHECK (new_key_epoch = expected_key_epoch + 1),
        group_key TEXT,
        envelopes_json TEXT NOT NULL DEFAULT '[]',
        created_at INTEGER NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups(group_id) ON DELETE CASCADE
      )
    ''');
  }

  /// Creates EVERY index declared via a `customIndices` getter across all
  /// tables. Drift's migrator does not consume that getter, so this is the
  /// single physical source of truth — called from onCreate (fresh installs)
  /// and the v23 backfill step. The v23 caller excludes indexes whose columns
  /// belong to later schema rungs; those rungs create them after their columns.
  /// All statements are idempotent (IF NOT EXISTS). Guarded by
  /// test/unit/data/migrations/index_v23_migration_test.dart, which parses
  /// the declarations from source and fails on any index missing here.
  Future<void> _createAllDeclaredIndexes({
    bool includeSyncQueueRecoveryIndex = true,
  }) async {
    await _createLegacyTableIndexes(
      includeSyncQueueRecoveryIndex: includeSyncQueueRecoveryIndex,
    );
    await _createShoppingItemIndexes();
    await _createShoppingUnitUsageIndexes();
    await _createExchangeRateIndexes();
    await _createMerchantIndexes();
    await _createInboundSyncOperationIndexes();
    await _createControlEventIndexes();
    await _createFamilySyncOutboxIndexes();
  }

  Future<void> _createFamilySyncOutboxIndexes() async {
    // `_createAllDeclaredIndexes` also runs at the historical v23 rung, before
    // a pre-v23 upgrade has reached the v32 table-creation step.
    if (!await _tableHasColumn('family_sync_outbox', 'group_id')) return;
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_family_sync_outbox_group_created '
      'ON family_sync_outbox (group_id, created_at)',
    );
  }

  /// Indices for the pre-Phase-36 tables that never had explicit CREATE
  /// INDEX calls (transactions, books, categories, groups, group_members,
  /// sync_queue, preference tables) plus the from<15 trio that was missing
  /// from the onCreate path (audit_logs, user_profiles,
  /// category_ledger_configs).
  Future<void> _createLegacyTableIndexes({
    required bool includeSyncQueueRecoveryIndex,
  }) async {
    // transactions — hottest table: list, calendar and analytics queries all
    // filter on book_id/timestamp/ledger_type.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tx_book_id ON transactions (book_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tx_category_id '
      'ON transactions (category_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tx_timestamp ON transactions (timestamp)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tx_ledger_type '
      'ON transactions (ledger_type)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tx_book_timestamp '
      'ON transactions (book_id, timestamp)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tx_book_deleted '
      'ON transactions (book_id, is_deleted)',
    );
    // books
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_books_device_id ON books (device_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_books_archived ON books (is_archived)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_books_group_id ON books (group_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_books_is_shadow ON books (is_shadow)',
    );
    // categories
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_categories_parent_id '
      'ON categories (parent_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_categories_level ON categories (level)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_categories_archived '
      'ON categories (is_archived)',
    );
    // groups / group_members
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_groups_status ON groups (status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_group_members_group_id '
      'ON group_members (group_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_group_members_status '
      'ON group_members (status)',
    );
    // sync_queue
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_created '
      'ON sync_queue (created_at)',
    );
    if (includeSyncQueueRecoveryIndex) {
      await _createSyncQueueRecoveryIndex();
    }
    // preference tables
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_keyword_prefs_keyword '
      'ON category_keyword_preferences (keyword)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_merchant_pref_updated_at '
      'ON merchant_category_preferences (updated_at)',
    );
    // from<15 trio — previously upgrade-path-only, missing on fresh installs.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_event ON audit_logs (event)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_device_id '
      'ON audit_logs (device_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp '
      'ON audit_logs (timestamp)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_user_profiles_updated_at '
      'ON user_profiles (updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_ledger_type '
      'ON category_ledger_configs (ledger_type)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_updated_at '
      'ON category_ledger_configs (updated_at)',
    );
  }

  Future<void> _createSyncQueueRecoveryIndex() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_state_retry '
      'ON sync_queue (state, next_retry_at)',
    );
  }

  Future<void> _createInboundSyncOperationIndexes() async {
    // `_createAllDeclaredIndexes` also runs mid-ladder for pre-v23 upgrades,
    // before the v27 table exists. The dedicated from<27 step calls this again
    // after createTable, so skipping here is safe and keeps old ladders valid.
    if (!await _tableHasColumn('inbound_sync_operations', 'operation_id')) {
      return;
    }
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_inbound_sync_state_updated '
      'ON inbound_sync_operations (group_id, state, updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_inbound_sync_group '
      'ON inbound_sync_operations (group_id)',
    );
  }

  Future<void> _createControlEventIndexes() async {
    if (!await _tableHasColumn('control_events', 'event_id')) return;
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_control_events_group_revision '
      'ON control_events (group_id, revision)',
    );
  }

  /// Creates the shopping_items indices declared on [ShoppingItems.customIndices].
  ///
  /// Drift's migrator does not consume the `customIndices` getter, so these must
  /// be emitted by hand from both the onCreate (fresh install) and onUpgrade
  /// (v19→v20) paths. Kept in one place so the two paths cannot drift apart.
  Future<void> _createShoppingItemIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shopping_list_type '
      'ON shopping_items (list_type)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shopping_list_deleted '
      'ON shopping_items (list_type, is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shopping_completed '
      'ON shopping_items (is_completed)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shopping_sort_order '
      'ON shopping_items (sort_order)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shopping_added_by_book '
      'ON shopping_items (added_by_book_id)',
    );
  }

  Future<void> _createShoppingUnitUsageIndexes() async {
    // This table is part of the current fresh-install schema only. The guard
    // keeps historical migration test ladders valid without introducing a
    // pre-launch compatibility migration.
    if (!await _tableExists('shopping_unit_usages')) return;
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shopping_unit_usage_rank '
      'ON shopping_unit_usages (use_count, last_used_at)',
    );
  }

  /// Creates the exchange_rates index declared on [ExchangeRates.customIndices].
  ///
  /// Drift's migrator does not consume the `customIndices` getter, so this index
  /// must be created explicitly from both the onCreate (fresh install) and onUpgrade
  /// (v20→v21) paths. Mirrors the _createShoppingItemIndexes pattern (CR-01 lesson).
  Future<void> _createExchangeRateIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_exchange_rates_currency_date '
      'ON exchange_rates (currency, rate_date)',
    );
  }

  /// Creates the merchant indexes declared on [Merchants.customIndices] and
  /// [MerchantMatchKeys.customIndices].
  ///
  /// Drift's migrator does not consume the `customIndices` getter, so these must
  /// be emitted by hand from both the onCreate (fresh install) and the from<22
  /// onUpgrade paths. Kept in one place so the two paths cannot drift apart.
  ///
  /// NOTE: idx_merchant_match_keys_match_key is intentionally NON-UNIQUE — two
  /// merchants may legally share a match_key (RESEARCH #6). Do not add UNIQUE.
  Future<void> _createMerchantIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_merchant_match_keys_match_key '
      'ON merchant_match_keys (match_key)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_merchant_match_keys_merchant '
      'ON merchant_match_keys (merchant_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_merchants_region '
      'ON merchants (region)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_merchants_category '
      'ON merchants (category_id)',
    );
  }
}
