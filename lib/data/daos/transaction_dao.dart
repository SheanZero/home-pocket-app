import 'package:drift/drift.dart';

import '../app_database.dart';

/// Data access object for the Transactions table.
class TransactionDao {
  TransactionDao(this._db);

  final AppDatabase _db;

  Future<void> insertTransaction({
    required String id,
    required String bookId,
    required String deviceId,
    required int amount,
    required String type,
    required String categoryId,
    required String ledgerType,
    required DateTime timestamp,
    required String currentHash,
    required DateTime createdAt,
    String? note,
    String? photoHash,
    String? merchant,
    String? metadata,
    String? prevHash,
    bool isPrivate = false,
  }) async {
    await _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            bookId: bookId,
            deviceId: deviceId,
            amount: amount,
            type: type,
            categoryId: categoryId,
            ledgerType: ledgerType,
            timestamp: timestamp,
            currentHash: currentHash,
            createdAt: createdAt,
            note: Value(note),
            photoHash: Value(photoHash),
            merchant: Value(merchant),
            metadata: Value(metadata),
            prevHash: Value(prevHash),
            isPrivate: Value(isPrivate),
          ),
        );
  }

  Future<TransactionRow?> findById(String id) async {
    return (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Query transactions for a book with optional filters.
  /// Soft-deleted transactions are excluded. Ordered newest-first.
  Future<List<TransactionRow>> findByBookId(
    String bookId, {
    String? ledgerType,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    final query = _db.select(_db.transactions)
      ..where((t) => t.bookId.equals(bookId))
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([
        (t) => OrderingTerm.desc(t.timestamp),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(limit, offset: offset);

    if (ledgerType != null) {
      query.where((t) => t.ledgerType.equals(ledgerType));
    }
    if (categoryId != null) {
      query.where((t) => t.categoryId.equals(categoryId));
    }
    if (startDate != null) {
      query.where((t) => t.timestamp.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((t) => t.timestamp.isSmallerOrEqualValue(endDate));
    }

    return query.get();
  }

  /// Get the hash of the most recent transaction in a book.
  Future<String?> getLatestHash(String bookId) async {
    final query = _db.select(_db.transactions)
      ..where((t) => t.bookId.equals(bookId))
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([
        (t) => OrderingTerm.desc(t.timestamp),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result?.currentHash;
  }

  /// Soft-delete a transaction.
  Future<void> softDelete(String id) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get all non-deleted transactions in a book (unpaginated, for backup).
  Future<List<TransactionRow>> findAllByBook(String bookId) async {
    final query = _db.select(_db.transactions)
      ..where((t) => t.bookId.equals(bookId))
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]);
    return query.get();
  }

  /// Delete all transactions for a book (hard delete, for backup restore).
  Future<void> deleteAllByBook(String bookId) async {
    await (_db.delete(_db.transactions)
          ..where((t) => t.bookId.equals(bookId)))
        .go();
  }

  /// Count non-deleted transactions in a book.
  Future<int> countByBookId(String bookId) async {
    final countExp = _db.transactions.id.count();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([countExp])
      ..where(_db.transactions.bookId.equals(bookId))
      ..where(_db.transactions.isDeleted.equals(false));

    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }
}
