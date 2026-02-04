import 'dart:convert';
import 'package:drift/drift.dart';

@DataClassName('TransactionEntity')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get deviceId => text()();
  IntColumn get amount => integer()();
  TextColumn get type => text()(); // 'expense', 'income', 'transfer'
  TextColumn get categoryId => text()();
  TextColumn get ledgerType => text()(); // 'survival', 'soul'
  DateTimeColumn get timestamp => dateTime()();

  // Optional fields
  TextColumn get note => text().nullable()(); // Encrypted
  TextColumn get photoHash => text().nullable()();
  TextColumn get merchant => text().nullable()();
  TextColumn get metadata => text().map(const JsonConverter()).nullable()();

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

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<TableIndex> get customIndices => [
        // Index for querying transactions by book (most common query)
        TableIndex(name: 'idx_transactions_book_id', columns: {#bookId}),

        // Index for querying by timestamp (for date-based filtering)
        TableIndex(name: 'idx_transactions_timestamp', columns: {#timestamp}),

        // Compound index for book + timestamp (optimizes list views)
        TableIndex(
          name: 'idx_transactions_book_timestamp',
          columns: {#bookId, #timestamp},
        ),

        // Index for category-based filtering
        TableIndex(name: 'idx_transactions_category', columns: {#categoryId}),
      ];
}

/// JSON converter for metadata field
class JsonConverter extends TypeConverter<Map<String, dynamic>, String> {
  const JsonConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    return json.decode(fromDb) as Map<String, dynamic>;
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return json.encode(value);
  }
}
