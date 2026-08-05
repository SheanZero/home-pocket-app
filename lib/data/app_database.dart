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
part 'app_database_migrations.dart';

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
        await _DatabaseMigrationRunner(
          database: this,
          migrator: migrator,
          sourceVersion: from,
        ).run(from: from, to: to);
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
    await _createIndexes(const [
      'CREATE INDEX IF NOT EXISTS idx_tx_book_id ON transactions (book_id)',
      'CREATE INDEX IF NOT EXISTS idx_tx_category_id ON transactions (category_id)',
      'CREATE INDEX IF NOT EXISTS idx_tx_timestamp ON transactions (timestamp)',
      'CREATE INDEX IF NOT EXISTS idx_tx_ledger_type ON transactions (ledger_type)',
      'CREATE INDEX IF NOT EXISTS idx_tx_book_timestamp ON transactions (book_id, timestamp)',
      'CREATE INDEX IF NOT EXISTS idx_tx_book_deleted ON transactions (book_id, is_deleted)',
      'CREATE INDEX IF NOT EXISTS idx_books_device_id ON books (device_id)',
      'CREATE INDEX IF NOT EXISTS idx_books_archived ON books (is_archived)',
      'CREATE INDEX IF NOT EXISTS idx_books_group_id ON books (group_id)',
      'CREATE INDEX IF NOT EXISTS idx_books_is_shadow ON books (is_shadow)',
      'CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories (parent_id)',
      'CREATE INDEX IF NOT EXISTS idx_categories_level ON categories (level)',
      'CREATE INDEX IF NOT EXISTS idx_categories_archived ON categories (is_archived)',
      'CREATE INDEX IF NOT EXISTS idx_groups_status ON groups (status)',
      'CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members (group_id)',
      'CREATE INDEX IF NOT EXISTS idx_group_members_status ON group_members (status)',
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_created ON sync_queue (created_at)',
      'CREATE INDEX IF NOT EXISTS idx_keyword_prefs_keyword ON category_keyword_preferences (keyword)',
      'CREATE INDEX IF NOT EXISTS idx_merchant_pref_updated_at ON merchant_category_preferences (updated_at)',
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_event ON audit_logs (event)',
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_device_id ON audit_logs (device_id)',
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs (timestamp)',
      'CREATE INDEX IF NOT EXISTS idx_user_profiles_updated_at ON user_profiles (updated_at)',
      'CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_ledger_type ON category_ledger_configs (ledger_type)',
      'CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_updated_at ON category_ledger_configs (updated_at)',
    ]);
    if (includeSyncQueueRecoveryIndex) {
      await _createSyncQueueRecoveryIndex();
    }
  }

  Future<void> _createIndexes(Iterable<String> statements) async {
    for (final statement in statements) {
      await customStatement(statement);
    }
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
