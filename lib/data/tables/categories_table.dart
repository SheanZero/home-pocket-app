import 'package:drift/drift.dart';

/// Categories table — hierarchical transaction categories (3 levels).
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  TextColumn get parentId => text().nullable()();
  IntColumn get level => integer()();
  TextColumn get type => text()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_categories_parent_id', columns: {#parentId}),
    TableIndex(name: 'idx_categories_level', columns: {#level}),
    TableIndex(name: 'idx_categories_type', columns: {#type}),
  ];
}
