import 'package:drift/drift.dart';

/// Categories table — two-level transaction categories (L1 / L2).
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  TextColumn get parentId => text()
      .nullable()
      .references(Categories, #id)();
  IntColumn get level => integer().check(level.isIn([1, 2]))();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_categories_parent_id', columns: {#parentId}),
    TableIndex(name: 'idx_categories_level', columns: {#level}),
    TableIndex(name: 'idx_categories_archived', columns: {#isArchived}),
  ];
}
