import 'package:drift/drift.dart';

import '../../shared/constants/sort_config.dart';
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
    bool isSynced = false,
    int joyFullness = 2,
    required String entrySource,
    String? originalCurrency,
    int? originalAmount,
    String? appliedRate,
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
            isSynced: Value(isSynced),
            joyFullness: Value(joyFullness),
            entrySource: Value(entrySource),
            // Phase 42 multi-currency triple (P40 columns; null = JPY-native).
            originalCurrency: Value(originalCurrency),
            originalAmount: Value(originalAmount),
            appliedRate: Value(appliedRate),
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

  /// Update an existing transaction row in place.
  Future<void> updateTransaction({
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
    bool isSynced = false,
    int joyFullness = 2,
    String? entrySource,
    DateTime? updatedAt,
    String? originalCurrency,
    int? originalAmount,
    String? appliedRate,
  }) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        bookId: Value(bookId),
        deviceId: Value(deviceId),
        amount: Value(amount),
        type: Value(type),
        categoryId: Value(categoryId),
        ledgerType: Value(ledgerType),
        timestamp: Value(timestamp),
        currentHash: Value(currentHash),
        createdAt: Value(createdAt),
        note: Value(note),
        photoHash: Value(photoHash),
        merchant: Value(merchant),
        metadata: Value(metadata),
        prevHash: Value(prevHash),
        isPrivate: Value(isPrivate),
        isSynced: Value(isSynced),
        joyFullness: Value(joyFullness),
        entrySource: entrySource != null
            ? Value(entrySource)
            : const Value.absent(),
        // Phase 42 multi-currency triple (P40 columns; null = JPY-native).
        originalCurrency: Value(originalCurrency),
        originalAmount: Value(originalAmount),
        appliedRate: Value(appliedRate),
        updatedAt: Value(updatedAt ?? DateTime.now()),
        isDeleted: const Value(false),
      ),
    );
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
    await (_db.delete(
      _db.transactions,
    )..where((t) => t.bookId.equals(bookId))).go();
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

  // ── Private helper: build ORDER BY clause string ────────────────────────

  String _orderByClause(SortField sortField, SortDirection sortDirection) {
    final direction =
        sortDirection == SortDirection.asc ? 'ASC' : 'DESC';
    final col = switch (sortField) {
      SortField.timestamp => 'timestamp',
      SortField.amount => 'amount',
    };
    return '$col $direction, id DESC';
  }

  /// Query transactions spanning multiple books in a single SQL call.
  ///
  /// Guards:
  /// - [bookIds] empty → returns `[]` immediately (no SQL executed).
  /// - Excludes soft-deleted rows (`is_deleted = 0`).
  /// - [startDate]..[endDate] are inclusive timestamp bounds.
  ///
  /// Optional filters: [ledgerType], [categoryId].
  /// Default ORDER BY: [SortField.timestamp] DESC, id DESC.
  ///
  /// D-02: No default limit applied — all matching rows for the date range
  /// are returned. Pagination is deferred to v1.5.
  ///
  /// Security: [bookIds] values are passed as SQLite bound parameters
  /// (`Variable.withString`). ORDER BY column name is derived from the
  /// [SortField] enum via a compile-time switch — user input never reaches
  /// the ORDER BY clause (T-24-02-01, T-24-02-02).
  Future<List<TransactionRow>> findByBookIds(
    List<String> bookIds, {
    required DateTime startDate,
    required DateTime endDate,
    String? ledgerType,
    String? categoryId,
    SortField sortField = SortField.timestamp,
    SortDirection sortDirection = SortDirection.desc,
  }) async {
    if (bookIds.isEmpty) return const [];

    final placeholders = List.filled(bookIds.length, '?').join(', ');
    final ledgerClause =
        ledgerType != null ? ' AND ledger_type = ?' : '';
    final categoryClause =
        categoryId != null ? ' AND category_id = ?' : '';
    final orderBy = _orderByClause(sortField, sortDirection);

    final results = await _db
        .customSelect(
          'SELECT * FROM transactions '
          'WHERE book_id IN ($placeholders) '
          'AND is_deleted = 0 '
          'AND timestamp >= ? AND timestamp <= ?'
          '$ledgerClause$categoryClause '
          'ORDER BY $orderBy',
          variables: [
            ...bookIds.map(Variable.withString),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (ledgerType != null) Variable.withString(ledgerType),
            if (categoryId != null) Variable.withString(categoryId),
          ],
        )
        .get();

    return results.map((row) => _db.transactions.map(row.data)).toList();
  }

  /// Reactive stream of transactions spanning multiple books.
  ///
  /// Guards:
  /// - [bookIds] empty → returns `Stream.empty()` immediately.
  /// - Excludes soft-deleted rows (`is_deleted = 0`).
  ///
  /// The `readsFrom: {_db.transactions}` annotation is **mandatory** —
  /// without it Drift cannot detect table mutations and the stream will
  /// not emit after writes (SC#2 reactivity requirement, D-03).
  ///
  /// All filters are bound in SQL; the provider layer stays thin.
  Stream<List<TransactionRow>> watchByBookIds(
    List<String> bookIds, {
    required DateTime startDate,
    required DateTime endDate,
    String? ledgerType,
    String? categoryId,
    SortField sortField = SortField.timestamp,
    SortDirection sortDirection = SortDirection.desc,
  }) {
    if (bookIds.isEmpty) return const Stream.empty();

    final placeholders = List.filled(bookIds.length, '?').join(', ');
    final ledgerClause =
        ledgerType != null ? ' AND ledger_type = ?' : '';
    final categoryClause =
        categoryId != null ? ' AND category_id = ?' : '';
    final orderBy = _orderByClause(sortField, sortDirection);

    return _db
        .customSelect(
          'SELECT * FROM transactions '
          'WHERE book_id IN ($placeholders) '
          'AND is_deleted = 0 '
          'AND timestamp >= ? AND timestamp <= ?'
          '$ledgerClause$categoryClause '
          'ORDER BY $orderBy',
          variables: [
            ...bookIds.map(Variable.withString),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (ledgerType != null) Variable.withString(ledgerType),
            if (categoryId != null) Variable.withString(categoryId),
          ],
          readsFrom: {_db.transactions},
        )
        .watch()
        .map(
          (rows) => rows.map((row) => _db.transactions.map(row.data)).toList(),
        );
  }
}
