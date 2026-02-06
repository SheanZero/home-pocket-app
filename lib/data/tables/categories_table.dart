import 'package:drift/drift.dart';

@DataClassName('CategoryEntity')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  TextColumn get parentId => text().nullable()();
  IntColumn get level => integer()(); // 1, 2, or 3
  TextColumn get type => text()(); // 'expense', 'income'
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  List<TableIndex> get customIndices => [
        // Index for querying by transaction type
        const TableIndex(name: 'idx_categories_type', columns: {#type}),

        // Index for system vs custom categories
        const TableIndex(
            name: 'idx_categories_is_system', columns: {#isSystem}),
      ];
}
