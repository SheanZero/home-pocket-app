import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../shared/utils/result.dart';

/// Soft-deletes a transaction by ID.
class DeleteTransactionUseCase {
  DeleteTransactionUseCase({
    required TransactionRepository transactionRepository,
  }) : _transactionRepo = transactionRepository;

  final TransactionRepository _transactionRepo;

  Future<Result<void>> execute(String transactionId) async {
    if (transactionId.isEmpty) {
      return Result.error('transactionId must not be empty');
    }

    final existing = await _transactionRepo.findById(transactionId);
    if (existing == null) {
      return Result.error('Transaction not found');
    }

    await _transactionRepo.softDelete(transactionId);
    return Result.success(null);
  }
}
