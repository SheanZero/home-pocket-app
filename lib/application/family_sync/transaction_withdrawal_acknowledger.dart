import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/family_sync/domain/repositories/sync_repository.dart';

/// Settles local withdrawal obligations only after a relay-accepted push.
/// Matching both entity id and revision prevents a delayed queue ACK from
/// settling a newer private/public transition.
class TransactionWithdrawalAcknowledger {
  TransactionWithdrawalAcknowledger({
    required TransactionRepository transactionRepository,
  }) : _transactionRepository = transactionRepository;

  final TransactionRepository _transactionRepository;

  Future<void> markDelivered(List<SyncWithdrawalReceipt> receipts) async {
    for (final receipt in receipts) {
      final transaction = await _transactionRepository.findById(
        receipt.entityId,
      );
      if (transaction == null ||
          transaction.familySyncVisibility !=
              FamilySyncVisibility.withdrawalPending ||
          transaction.syncRevision != receipt.revision) {
        continue;
      }
      await _transactionRepository.update(
        transaction.copyWith(
          // Local-only state change: do not advance the family revision.
          familySyncVisibility: FamilySyncVisibility.withdrawn,
        ),
      );
    }
  }
}
