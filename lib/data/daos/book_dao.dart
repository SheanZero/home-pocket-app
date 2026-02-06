import 'package:drift/drift.dart';

import '../app_database.dart';

/// Data access object for the Books table.
class BookDao {
  BookDao(this._db);

  final AppDatabase _db;

  Future<void> insertBook({
    required String id,
    required String name,
    required String currency,
    required String deviceId,
    required DateTime createdAt,
    bool isArchived = false,
  }) async {
    await _db
        .into(_db.books)
        .insert(
          BooksCompanion.insert(
            id: id,
            name: name,
            currency: currency,
            deviceId: deviceId,
            createdAt: createdAt,
            isArchived: Value(isArchived),
          ),
        );
  }

  Future<BookRow?> findById(String id) async {
    return (_db.select(
      _db.books,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<BookRow>> findAll({bool includeArchived = false}) async {
    final query = _db.select(_db.books);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  Future<void> updateBook({
    required String id,
    String? name,
    String? currency,
    bool? isArchived,
    DateTime? updatedAt,
  }) async {
    await (_db.update(_db.books)..where((t) => t.id.equals(id))).write(
      BooksCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        currency: currency != null ? Value(currency) : const Value.absent(),
        isArchived: isArchived != null
            ? Value(isArchived)
            : const Value.absent(),
        updatedAt: updatedAt != null ? Value(updatedAt) : const Value.absent(),
      ),
    );
  }

  Future<void> archiveBook(String id) async {
    await updateBook(id: id, isArchived: true, updatedAt: DateTime.now());
  }

  Future<void> updateBalances({
    required String bookId,
    required int transactionCount,
    required int survivalBalance,
    required int soulBalance,
  }) async {
    await (_db.update(_db.books)..where((t) => t.id.equals(bookId))).write(
      BooksCompanion(
        transactionCount: Value(transactionCount),
        survivalBalance: Value(survivalBalance),
        soulBalance: Value(soulBalance),
      ),
    );
  }
}
