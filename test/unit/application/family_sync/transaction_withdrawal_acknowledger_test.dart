import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/transaction_withdrawal_acknowledger.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/sync_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _FakeTransaction extends Fake implements Transaction {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeTransaction()));

  test(
    'exact successful revision settles withdrawal without revision bump',
    () async {
      final repository = _MockTransactionRepository();
      final pending = _transaction(revision: 10);
      when(() => repository.findById('tx-1')).thenAnswer((_) async => pending);
      when(() => repository.update(any())).thenAnswer((_) async {});
      final acknowledger = TransactionWithdrawalAcknowledger(
        transactionRepository: repository,
      );

      await acknowledger.markDelivered(const [
        SyncWithdrawalReceipt(entityId: 'tx-1', revision: 10),
      ]);

      final updated =
          verify(() => repository.update(captureAny())).captured.single
              as Transaction;
      expect(updated.familySyncVisibility, FamilySyncVisibility.withdrawn);
      expect(updated.syncRevision, 10);
    },
  );

  test(
    'delayed older receipt cannot settle a newer withdrawal revision',
    () async {
      final repository = _MockTransactionRepository();
      when(
        () => repository.findById('tx-1'),
      ).thenAnswer((_) async => _transaction(revision: 11));
      final acknowledger = TransactionWithdrawalAcknowledger(
        transactionRepository: repository,
      );

      await acknowledger.markDelivered(const [
        SyncWithdrawalReceipt(entityId: 'tx-1', revision: 10),
      ]);

      verifyNever(() => repository.update(any()));
    },
  );
}

Transaction _transaction({required int revision}) => Transaction(
  id: 'tx-1',
  bookId: 'book-1',
  deviceId: 'device-a',
  amount: 100,
  type: TransactionType.expense,
  categoryId: 'cat',
  ledgerType: LedgerType.daily,
  timestamp: DateTime.utc(2026, 8, 1),
  currentHash: 'hash',
  createdAt: DateTime.utc(2026, 8, 1),
  isPrivate: true,
  syncRevision: revision,
  syncOriginDeviceId: 'device-a',
  familySyncVisibility: FamilySyncVisibility.withdrawalPending,
  familySharedRevision: 9,
);
