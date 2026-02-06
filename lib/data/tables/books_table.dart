import 'package:drift/drift.dart';

/// Books table — represents accounting ledger books.
@DataClassName('BookRow')
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  TextColumn get deviceId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  // Denormalized stats
  IntColumn get transactionCount => integer().withDefault(const Constant(0))();
  IntColumn get survivalBalance => integer().withDefault(const Constant(0))();
  IntColumn get soulBalance => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_books_device_id', columns: {#deviceId}),
    TableIndex(name: 'idx_books_archived', columns: {#isArchived}),
  ];
}
