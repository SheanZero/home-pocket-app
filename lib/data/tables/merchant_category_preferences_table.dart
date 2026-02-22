import 'package:drift/drift.dart';

@DataClassName('MerchantCategoryPreferenceRow')
class MerchantCategoryPreferences extends Table {
  TextColumn get merchantKey => text()();
  TextColumn get preferredCategoryId => text()();
  TextColumn get lastOverrideCategoryId => text().nullable()();
  IntColumn get overrideStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {merchantKey};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_merchant_pref_updated_at', columns: {#updatedAt}),
  ];
}
