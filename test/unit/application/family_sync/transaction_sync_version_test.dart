import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/transaction_sync_version.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

Transaction _transaction({
  required int amount,
  int revision = 100,
  String origin = 'device-a',
  bool isDeleted = false,
}) {
  return Transaction(
    id: 'tx-1',
    bookId: 'book-1',
    deviceId: origin,
    amount: amount,
    type: TransactionType.expense,
    categoryId: 'cat-1',
    ledgerType: LedgerType.daily,
    timestamp: DateTime.utc(2026, 7, 1),
    currentHash: 'hash',
    createdAt: DateTime.utc(2026, 7, 1),
    syncRevision: revision,
    syncOriginDeviceId: origin,
    isDeleted: isDeleted,
  );
}

void main() {
  test('content digest resolves malformed same-writer same-revision ties', () {
    final first = _transaction(amount: 100);
    final second = _transaction(amount: 200);

    final comparison = TransactionSyncVersion.fromTransaction(
      first,
    ).compareTo(TransactionSyncVersion.fromTransaction(second));
    expect(comparison, isNot(0));

    final winnerForward = comparison > 0 ? first : second;
    final reverseComparison = TransactionSyncVersion.fromTransaction(
      second,
    ).compareTo(TransactionSyncVersion.fromTransaction(first));
    final winnerReverse = reverseComparison > 0 ? second : first;
    expect(winnerForward, winnerReverse);
  });

  test('same revision tombstone wins before writer or content tie-break', () {
    final live = _transaction(amount: 900, origin: 'device-z');
    final tombstone = _transaction(
      amount: 100,
      origin: 'device-a',
      isDeleted: true,
    );

    expect(
      TransactionSyncVersion.fromTransaction(
        tombstone,
      ).compareTo(TransactionSyncVersion.fromTransaction(live)),
      greaterThan(0),
    );
  });

  test('next revision is monotonic when wall clock moves backwards', () {
    final current = _transaction(amount: 100, revision: 500);

    expect(
      nextSyncRevision(
        current,
        DateTime.fromMicrosecondsSinceEpoch(100, isUtc: true),
      ),
      501,
    );
  });

  test(
    'replacing one local photo hash with another does not change sync state',
    () {
      final first = _transaction(amount: 100).copyWith(photoHash: 'hash-a');
      final replacement = first.copyWith(photoHash: 'hash-b');

      expect(
        transactionSyncContentTag(first),
        transactionSyncContentTag(replacement),
      );
    },
  );
}
