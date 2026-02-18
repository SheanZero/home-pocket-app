import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'tables/audit_logs_table.dart';
import 'tables/books_table.dart';
import 'tables/categories_table.dart';
import 'tables/category_ledger_configs_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

/// Main application database.
///
/// Contains all Drift tables for the app.
/// Schema version incremented when tables are added/modified.
@DriftDatabase(tables: [AuditLogs, Books, Categories, CategoryLedgerConfigs, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for testing.
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 5;

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
      },
    );
  }
}
