import 'package:drift/drift.dart';

/// Local-only aggregate of units chosen when creating shopping items.
///
/// It is deliberately not synced: suggestions reflect the habits of the
/// person using this device and must not leak custom labels into family sync.
@DataClassName('ShoppingUnitUsageRow')
class ShoppingUnitUsages extends Table {
  TextColumn get usageKey => text()();
  TextColumn get unitId => text()();
  TextColumn get customUnit => text().nullable()();
  IntColumn get useCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get lastUsedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {usageKey};

  @override
  List<String> get customConstraints => [
    'CHECK(use_count > 0)',
    "CHECK(unit_id IN ('piece', 'gram', 'kilogram', 'milliliter', 'liter', 'bag', 'bottle', 'pack', 'custom'))",
    "CHECK(unit_id != 'custom' OR (custom_unit IS NOT NULL AND length(trim(custom_unit)) BETWEEN 1 AND 12))",
  ];

  List<TableIndex> get customIndices => [
    TableIndex(
      name: 'idx_shopping_unit_usage_rank',
      columns: {#useCount, #lastUsedAt},
    ),
  ];
}
