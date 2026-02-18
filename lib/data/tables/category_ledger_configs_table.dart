import 'package:drift/drift.dart';

import 'categories_table.dart';

/// Personal ledger type configuration for categories.
@DataClassName('CategoryLedgerConfigRow')
class CategoryLedgerConfigs extends Table {
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get ledgerType => text()
      .check(ledgerType.isIn(['survival', 'soul']))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {categoryId};
}
