import 'package:drift/drift.dart';

/// Transactions table — core financial records with hash chain integrity.
@DataClassName('TransactionRow')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get deviceId => text()();
  IntColumn get amount => integer()();
  TextColumn get type => text()();
  TextColumn get categoryId => text()();
  TextColumn get ledgerType => text()();
  DateTimeColumn get timestamp => dateTime()();

  // Optional fields
  TextColumn get note => text().nullable()();
  TextColumn get photoHash => text().nullable()();
  TextColumn get merchant => text().nullable()();
  TextColumn get metadata => text().nullable()();

  // Hash chain
  TextColumn get prevHash => text().nullable()();
  TextColumn get currentHash => text()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  // Flags
  BoolColumn get isPrivate => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  // Soul ledger satisfaction (1-10, default 5)
  IntColumn get soulSatisfaction => integer().withDefault(const Constant(5))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK(soul_satisfaction BETWEEN 1 AND 10)',
  ];

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_tx_book_id', columns: {#bookId}),
    TableIndex(name: 'idx_tx_category_id', columns: {#categoryId}),
    TableIndex(name: 'idx_tx_timestamp', columns: {#timestamp}),
    TableIndex(name: 'idx_tx_ledger_type', columns: {#ledgerType}),
    TableIndex(name: 'idx_tx_book_timestamp', columns: {#bookId, #timestamp}),
    TableIndex(name: 'idx_tx_book_deleted', columns: {#bookId, #isDeleted}),
  ];
}
