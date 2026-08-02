import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_photo_sync_policy.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_sync_mapper.dart';

Transaction _transaction({
  String? photoHash,
  Map<String, dynamic>? metadata,
  bool isDeleted = false,
}) {
  return Transaction(
    id: 'tx-photo',
    bookId: 'book-local',
    deviceId: 'device-a',
    amount: 1200,
    type: TransactionType.expense,
    categoryId: 'cat-food',
    ledgerType: LedgerType.daily,
    timestamp: DateTime.utc(2026, 8, 1),
    photoHash: photoHash,
    metadata: metadata,
    currentHash: 'chain-hash',
    createdAt: DateTime.utc(2026, 8, 1),
    isDeleted: isDeleted,
    syncRevision: 10,
    syncOriginDeviceId: 'device-a',
  );
}

Map<String, dynamic> _wire(Transaction transaction) {
  return TransactionSyncMapper.toSyncMap(
    transaction,
    sourceBookId: 'book-local',
    sourceBookName: 'Local',
    sourceBookType: 'local',
  );
}

void main() {
  group('transaction receipt photo local-only contract', () {
    test('no-photo bill emits explicit none and otherwise round-trips', () {
      final wire = _wire(_transaction());

      expect(wire[TransactionPhotoSyncPolicy.wireAvailabilityKey], 'none');
      expect(wire, isNot(contains('photoHash')));

      final restored = TransactionSyncMapper.fromSyncMap(
        wire,
        bookId: 'shadow',
        deviceId: 'device-a',
      );
      expect(restored.photoHash, isNull);
      expect(
        TransactionPhotoSyncPolicy.isUnavailableRemotePhoto(restored),
        isFalse,
      );
      expect(restored.amount, 1200);
    });

    test(
      'a local photo emits only local-only availability, never its hash',
      () {
        final wire = _wire(_transaction(photoHash: 'sensitive-content-hash'));

        expect(
          wire[TransactionPhotoSyncPolicy.wireAvailabilityKey],
          'local_only',
        );
        expect(wire, isNot(contains('photoHash')));

        final restored = TransactionSyncMapper.fromSyncMap(
          wire,
          bookId: 'shadow',
          deviceId: 'device-a',
        );
        expect(restored.photoHash, isNull);
        expect(
          TransactionPhotoSyncPolicy.isUnavailableRemotePhoto(restored),
          isTrue,
        );
      },
    );

    test(
      'legacy and attacker media fields are never treated as references',
      () {
        final wire = _wire(_transaction())
          ..['photoHash'] = List.filled(128 * 1024, 'a').join()
          ..['photoMime'] = 'text/html'
          ..['photoByteLength'] = 0x7fffffff
          ..['photoBytesBase64'] = 'not-base64';

        final restored = TransactionSyncMapper.fromSyncMap(
          wire,
          bookId: 'shadow',
          deviceId: 'device-a',
        );

        expect(restored.photoHash, isNull);
        expect(
          TransactionPhotoSyncPolicy.isUnavailableRemotePhoto(restored),
          isTrue,
        );
      },
    );

    test('replace, remove and tombstone have deterministic availability', () {
      expect(
        _wire(
          _transaction(photoHash: 'hash-a'),
        )[TransactionPhotoSyncPolicy.wireAvailabilityKey],
        'local_only',
      );
      expect(
        _wire(
          _transaction(photoHash: 'hash-b'),
        )[TransactionPhotoSyncPolicy.wireAvailabilityKey],
        'local_only',
      );
      expect(
        _wire(_transaction())[TransactionPhotoSyncPolicy.wireAvailabilityKey],
        'none',
      );
      final deleted = _transaction(photoHash: 'hash-b', isDeleted: true);
      expect(
        () => _wire(deleted),
        throwsStateError,
        reason: 'deleted rows must never enter the live bill mapper',
      );
      final tombstone = TransactionSyncMapper.toWithdrawalOperation(deleted);
      expect(
        tombstone['data'] as Map<String, dynamic>,
        isNot(contains(TransactionPhotoSyncPolicy.wireAvailabilityKey)),
      );
    });

    test('a tombstone clears a previously propagated missing-photo marker', () {
      final wire = _wire(_transaction())
        ..['isDeleted'] = true
        ..[TransactionPhotoSyncPolicy.wireAvailabilityKey] = 'local_only';
      final restored = TransactionSyncMapper.fromSyncMap(
        wire,
        bookId: 'shadow',
        deviceId: 'device-a',
      );

      expect(restored.isDeleted, isTrue);
      expect(
        TransactionPhotoSyncPolicy.isUnavailableRemotePhoto(restored),
        isFalse,
      );
    });

    test('remote local-only marker survives a full-sync remap', () {
      final received = TransactionSyncMapper.fromSyncMap(
        _wire(_transaction(photoHash: 'hash-a')),
        bookId: 'shadow',
        deviceId: 'device-a',
      );

      final reconciled = _wire(received);
      expect(
        reconciled[TransactionPhotoSyncPolicy.wireAvailabilityKey],
        'local_only',
      );
      expect(reconciled, isNot(contains('photoHash')));
    });
  });
}
