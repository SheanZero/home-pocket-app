import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_family_sync_policy.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_sync_mapper.dart';

void main() {
  group('TransactionFamilySyncPolicy', () {
    test('new private transaction is local-only and produces no operation', () {
      final transaction = _transaction(
        isPrivate: true,
        familySyncVisibility: FamilySyncVisibility.localOnly,
      );

      expect(
        TransactionSyncMapper.toFullSyncOperation(
          transaction,
          sourceBookId: 'book-1',
          sourceBookName: 'Book',
          sourceBookType: 'remote_book:book-1',
        ),
        isNull,
      );
    });

    test('public live payload omits every local privacy bookkeeping field', () {
      final transaction = _transaction(
        familySyncVisibility: FamilySyncVisibility.shared,
        familySharedRevision: 9,
      );

      final operation = TransactionSyncMapper.toCreateOperation(
        transaction,
        sourceBookId: 'book-1',
        sourceBookName: 'Book',
        sourceBookType: 'remote_book:book-1',
      );
      final data = operation['data']! as Map<String, dynamic>;

      expect(data, isNot(contains('isPrivate')));
      expect(data, isNot(contains('familySyncVisibility')));
      expect(data, isNot(contains('familySharedRevision')));
      expect(
        TransactionFamilySyncPolicy.isSafeOutboundOperation(operation),
        isTrue,
      );
    });

    test('withdrawal is a stable versioned tombstone with no bill fields', () {
      final private = _transaction(
        isPrivate: true,
        syncRevision: 10,
        familySyncVisibility: FamilySyncVisibility.withdrawalPending,
        familySharedRevision: 9,
      );

      final operation = TransactionSyncMapper.toWithdrawalOperation(private);

      expect(operation['op'], 'delete');
      expect(operation['entityId'], private.id);
      expect(operation['revision'], 10);
      expect(operation['originDeviceId'], private.deviceId);
      expect(operation['data'], {
        'isDeleted': true,
        'syncRevision': 10,
        'syncOriginDeviceId': private.deviceId,
      });
      expect(
        TransactionFamilySyncPolicy.isSafeOutboundOperation(operation),
        isTrue,
      );
      expect(operation.toString(), isNot(contains(private.note)));
      expect(operation.toString(), isNot(contains(private.merchant)));
      expect(operation.toString(), isNot(contains(private.categoryId)));
    });

    test(
      'private or local-only inbound state is rejected deterministically',
      () {
        expect(
          TransactionFamilySyncPolicy.inboundViolation({'isPrivate': true}),
          'private_bill_payload',
        );
        expect(
          TransactionFamilySyncPolicy.inboundViolation({'isPrivate': 'true'}),
          'private_bill_payload',
        );
        expect(
          TransactionFamilySyncPolicy.inboundViolation({
            'isPrivate': false,
            'familySyncVisibility': 'shared',
          }),
          'private_bill_payload',
        );
        expect(
          TransactionFamilySyncPolicy.inboundViolation({'isPrivate': false}),
          isNull,
        );
        expect(TransactionFamilySyncPolicy.inboundViolation({}), isNull);
      },
    );

    test('full sync emits only live shared state or pending withdrawal', () {
      final shared = _transaction(
        familySyncVisibility: FamilySyncVisibility.shared,
      );
      final pending = _transaction(
        isPrivate: true,
        familySyncVisibility: FamilySyncVisibility.withdrawalPending,
      );
      final withdrawn = _transaction(
        isPrivate: true,
        familySyncVisibility: FamilySyncVisibility.withdrawn,
      );

      final live = TransactionSyncMapper.toFullSyncOperation(
        shared,
        sourceBookId: 'book-1',
        sourceBookName: 'Book',
        sourceBookType: 'remote_book:book-1',
      );
      final withdrawal = TransactionSyncMapper.toFullSyncOperation(
        pending,
        sourceBookId: 'book-1',
        sourceBookName: 'Book',
        sourceBookType: 'remote_book:book-1',
      );
      final settled = TransactionSyncMapper.toFullSyncOperation(
        withdrawn,
        sourceBookId: 'book-1',
        sourceBookName: 'Book',
        sourceBookType: 'remote_book:book-1',
      );

      expect(live?['op'], 'reconcile');
      expect(withdrawal?['op'], 'delete');
      expect(withdrawal.toString(), isNot(contains('private note')));
      expect(settled, isNull);
    });
  });
}

Transaction _transaction({
  bool isPrivate = false,
  bool isDeleted = false,
  int syncRevision = 9,
  FamilySyncVisibility familySyncVisibility = FamilySyncVisibility.localOnly,
  int familySharedRevision = 0,
}) {
  return Transaction(
    id: 'tx-1',
    bookId: 'book-1',
    deviceId: 'device-a',
    amount: 1200,
    type: TransactionType.expense,
    categoryId: 'private-category',
    ledgerType: LedgerType.daily,
    timestamp: DateTime.utc(2026, 8, 1),
    note: 'private note',
    merchant: 'private merchant',
    metadata: const {'private': 'metadata'},
    currentHash: 'hash',
    createdAt: DateTime.utc(2026, 8, 1),
    isPrivate: isPrivate,
    isDeleted: isDeleted,
    syncRevision: syncRevision,
    syncOriginDeviceId: 'device-a',
    familySyncVisibility: familySyncVisibility,
    familySharedRevision: familySharedRevision,
    entrySource: EntrySource.manual,
  );
}
