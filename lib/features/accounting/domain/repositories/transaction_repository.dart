import '../models/transaction.dart';
import '../../../../shared/constants/sort_config.dart';

/// Abstract repository interface for transaction data access.
abstract class TransactionRepository {
  Future<void> insert(Transaction transaction);
  Future<Transaction?> findById(String id);
  Future<List<Transaction>> findByBookId(
    String bookId, {
    LedgerType? ledgerType,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int limit,
    int offset,
  });
  Future<void> update(Transaction transaction);
  Future<void> softDelete(String id);
  Future<String?> getLatestHash(String bookId);
  Future<int> countByBookId(String bookId);

  /// Get all transactions for a book (unpaginated, for backup).
  Future<List<Transaction>> findAllByBook(String bookId);

  /// Delete all transactions for a book (for backup restore).
  Future<void> deleteAllByBook(String bookId);

  /// Query transactions spanning multiple books in a single call.
  ///
  /// Excludes soft-deleted rows. [startDate]..[endDate] are inclusive bounds.
  /// D-02: No limit applied — all matching rows for the date range are returned.
  Future<List<Transaction>> findByBookIds(
    List<String> bookIds, {
    LedgerType? ledgerType,
    String? categoryId,
    required DateTime startDate,
    required DateTime endDate,
    SortField sortField,
    SortDirection sortDirection,
  });

  /// Reactive stream of transactions spanning multiple books.
  ///
  /// Emits a new list whenever the underlying transactions table changes.
  /// Excludes soft-deleted rows.
  Stream<List<Transaction>> watchByBookIds(
    List<String> bookIds, {
    LedgerType? ledgerType,
    String? categoryId,
    required DateTime startDate,
    required DateTime endDate,
    SortField sortField,
    SortDirection sortDirection,
  });
}
