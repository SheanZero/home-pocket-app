import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/shared/utils/result.dart';

/// Use case for deleting a transaction
///
/// Handles:
/// - Transaction validation (exists)
/// - Hard delete from repository
/// - Error handling
class DeleteTransactionUseCase {
  DeleteTransactionUseCase({
    required this.transactionRepository,
  });
  final TransactionRepository transactionRepository;

  /// Execute the use case
  ///
  /// Returns Result<bool> with true on success or error message.
  Future<Result<bool>> execute({
    required String transactionId,
  }) async {
    try {
      // 1. Verify transaction exists
      final existingTransaction =
          await transactionRepository.findById(transactionId);

      if (existingTransaction == null) {
        return Result.error('Transaction not found: $transactionId');
      }

      // 2. Delete transaction
      await transactionRepository.delete(transactionId);

      return const Result.success(true);
    } catch (e) {
      return Result.error('Failed to delete transaction: ${e.toString()}');
    }
  }
}
