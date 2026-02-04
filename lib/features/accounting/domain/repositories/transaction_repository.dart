import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

/// Repository interface for transaction data access
///
/// Implementation in Data layer will handle:
/// - Database operations via DAO
/// - Field encryption/decryption
/// - Hash chain management
abstract class TransactionRepository {
  /// Insert new transaction
  Future<void> insert(Transaction transaction);

  /// Update existing transaction
  Future<void> update(Transaction transaction);

  /// Delete transaction (hard delete)
  Future<void> delete(String id);

  /// Soft delete transaction (mark as deleted)
  Future<void> softDelete(String id);

  /// Find transaction by ID
  Future<Transaction?> findById(String id);

  /// Get transactions by book with optional filters
  Future<List<Transaction>> findByBook({
    required String bookId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    LedgerType? ledgerType,
    int limit = 100,
    int offset = 0,
  });

  /// Get latest hash for hash chain
  Future<String?> getLatestHash(String bookId);

  /// Count transactions in book
  Future<int> count(String bookId);

  /// Verify hash chain integrity for a book
  Future<bool> verifyHashChain(String bookId);
}
