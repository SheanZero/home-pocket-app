import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../infrastructure/sync/sync_trigger_service.dart';
import '../../shared/utils/result.dart';

/// Soft-deletes a transaction by ID.
class DeleteTransactionUseCase {
  DeleteTransactionUseCase({
    required TransactionRepository transactionRepository,
    SyncTriggerService? syncTriggerService,
  }) : _transactionRepo = transactionRepository,
       _syncTriggerService = syncTriggerService;

  final TransactionRepository _transactionRepo;
  final SyncTriggerService? _syncTriggerService;

  Future<Result<void>> execute(String transactionId) async {
    if (transactionId.isEmpty) {
      return Result.error('transactionId must not be empty');
    }

    final existing = await _transactionRepo.findById(transactionId);
    if (existing == null) {
      return Result.error('Transaction not found');
    }

    await _transactionRepo.softDelete(transactionId);
    try {
      await _syncTriggerService?.onTransactionDeleted(transactionId);
    } catch (_) {
      // Keep local deletion successful even if sync enqueue fails.
    }
    return Result.success(null);
  }
}
