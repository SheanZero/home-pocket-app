import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/accounting/domain/models/transaction_sync_mapper.dart';
import '../../features/accounting/domain/models/transaction_family_sync_policy.dart';
import '../../shared/utils/result.dart';
import '../family_sync/sync_engine.dart';
import '../family_sync/category_reference_sync_service.dart';
import '../family_sync/transaction_change_tracker.dart';
import '../family_sync/transaction_sync_version.dart';

/// Soft-deletes a transaction by ID.
class DeleteTransactionUseCase {
  DeleteTransactionUseCase({
    required TransactionRepository transactionRepository,
    SyncEngine? syncEngine,
    TransactionChangeTracker? changeTracker,
    CategoryReferenceSyncService? categoryReferenceSyncService,
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

    final now = DateTime.now();
    final logicalRevision = nextSyncRevision(existing, now);
    final nextRevision = logicalRevision > existing.familySharedRevision
        ? logicalRevision
        : existing.familySharedRevision + 1;
    final tombstone = existing.copyWith(
      isDeleted: true,
      updatedAt: now,
      syncRevision: nextRevision,
      syncOriginDeviceId: existing.deviceId,
      familySyncVisibility: TransactionFamilySyncPolicy.visibilityForDelete(
        existing,
      ),
    );
    Map<String, dynamic>? syncOperation;
    if (TransactionFamilySyncPolicy.shouldSendWithdrawal(tombstone)) {
      syncOperation = TransactionSyncMapper.toDeleteOperation(
        tombstone,
        sourceBookId: existing.bookId,
        sourceBookName: existing.bookId,
        sourceBookType: 'remote_book:${existing.bookId}',
      );
    }
    final durableRepository =
        _transactionRepo is DurableFamilySyncTransactionRepository
        ? _transactionRepo as DurableFamilySyncTransactionRepository
        : null;
    final usesDurableOutbox = durableRepository != null;
    final outboxEnqueued = durableRepository != null
        ? await durableRepository.updateWithFamilySyncOutbox(
            tombstone,
            operation: syncOperation,
          )
        : await _updateLegacy(tombstone);
    if (syncOperation != null && !usesDurableOutbox) {
      _changeTracker?.trackDelete(
        transactionId: transactionId,
        bookId: existing.bookId,
        operation: syncOperation,
      );
    }
    if (syncOperation != null && (outboxEnqueued || !usesDurableOutbox)) {
      _syncEngine?.onTransactionChanged();
    }
    return Result.success(null);
  }

  Future<bool> _updateLegacy(Transaction transaction) async {
    await _transactionRepo.update(transaction);
    return false;
  }
}
