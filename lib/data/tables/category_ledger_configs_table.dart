import 'package:drift/drift.dart';

import 'categories_table.dart';

/// Personal ledger type configuration for categories.
@DataClassName('CategoryLedgerConfigRow')
class CategoryLedgerConfigs extends Table {
  // coverage:ignore-start
  // Drift column DSL is consumed by code generation and is not callable at
  // runtime. Generated table classes cover the executable behavior.
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get ledgerType => text().customConstraint(
    "NOT NULL CHECK(ledger_type IN ('survival', 'soul'))",
  )();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {categoryId};
  // coverage:ignore-end

  List<TableIndex> get customIndices => [
    TableIndex(
      name: 'idx_category_ledger_configs_ledger_type',
      columns: {#ledgerType},
    ),
    TableIndex(
      name: 'idx_category_ledger_configs_updated_at',
      columns: {#updatedAt},
    ),
  ];
}
