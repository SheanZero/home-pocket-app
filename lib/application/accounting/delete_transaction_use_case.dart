import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../shared/utils/result.dart';
import '../family_sync/sync_engine.dart';
import '../family_sync/transaction_change_tracker.dart';

/// Soft-deletes a transaction by ID.
class DeleteTransactionUseCase {
  DeleteTransactionUseCase({
    required TransactionRepository transactionRepository,
    SyncEngine? syncEngine,
    TransactionChangeTracker? changeTracker,
  }) : _transactionRepo = transactionRepository,
       _syncEngine = syncEngine,
       _changeTracker = changeTracker;

  final TransactionRepository _transactionRepo;
  final SyncEngine? _syncEngine;
  final TransactionChangeTracker? _changeTracker;

  Future<Result<void>> execute(String transactionId) async {
    if (transactionId.isEmpty) {
      return Result.error('transactionId must not be empty');
    }

    final existing = await _transactionRepo.findById(transactionId);
    if (existing == null) {
      return Result.error('Transaction not found');
    }

    await _transactionRepo.softDelete(transactionId);
    _changeTracker?.trackDelete(
      transactionId: transactionId,
      bookId: existing.bookId,
    );
    _syncEngine?.onTransactionChanged();
    return Result.success(null);
  }
}
