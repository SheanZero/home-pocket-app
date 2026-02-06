import '../models/transaction.dart';

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
}
