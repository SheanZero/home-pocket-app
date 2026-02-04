import 'package:drift/drift.dart';

@DataClassName('BookEntity')
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  TextColumn get deviceId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  // Statistics
  IntColumn get transactionCount => integer().withDefault(const Constant(0))();
  IntColumn get survivalBalance => integer().withDefault(const Constant(0))();
  IntColumn get soulBalance => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<TableIndex> get customIndices => [
        // Index for finding active books
        TableIndex(name: 'idx_books_archived', columns: {#isArchived}),

        // Index for book name search
        TableIndex(name: 'idx_books_name', columns: {#name}),
      ];
}
