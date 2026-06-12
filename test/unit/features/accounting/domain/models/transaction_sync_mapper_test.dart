import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_sync_mapper.dart';

void main() {
  group('TransactionSyncMapper', () {
    final sampleTransaction = Transaction(
      id: 'tx-123',
      bookId: 'book-1',
      deviceId: 'device-a',
      amount: 1500,
      type: TransactionType.expense,
      categoryId: 'cat-food',
      ledgerType: LedgerType.daily,
      timestamp: DateTime.utc(2026, 3, 15, 10, 30),
      currentHash: 'hash-abc',
      createdAt: DateTime.utc(2026, 3, 15, 10, 30),
      note: 'Lunch',
      merchant: 'Cafe',
      joyFullness: 7,
    );

    test('toSyncMap excludes bookId, hash chain, and deviceId', () {
      final map = TransactionSyncMapper.toSyncMap(
        sampleTransaction,
        sourceBookId: 'book-1',
        sourceBookName: 'Main Book',
        sourceBookType: 'remote_book:book-1',
      );

      expect(map['id'], 'tx-123');
      expect(map['amount'], 1500);
      expect(map['type'], 'expense');
      expect(map['categoryId'], 'cat-food');
      expect(map['ledgerType'], 'daily');
      expect(map['note'], 'Lunch');
      expect(map['merchant'], 'Cafe');
      expect(map['joyFullness'], 7);
      expect(map['entrySource'], 'manual');
      expect(map['metadata'], {
        'sourceBookId': 'book-1',
        'sourceBookName': 'Main Book',
        'sourceBookType': 'remote_book:book-1',
      });
      expect(map['timestamp'], isNotNull);
      expect(map['createdAt'], isNotNull);

      expect(map.containsKey('bookId'), false);
      expect(map.containsKey('deviceId'), false);
      expect(map.containsKey('currentHash'), false);
      expect(map.containsKey('prevHash'), false);
      expect(map.containsKey('isSynced'), false);
      expect(map.containsKey('isDeleted'), false);
    });

    test('fromSyncMap creates synced transaction with metadata', () {
      final map = TransactionSyncMapper.toSyncMap(
        sampleTransaction,
        sourceBookId: 'book-1',
        sourceBookName: 'Main Book',
        sourceBookType: 'remote_book:book-1',
      );

      final restored = TransactionSyncMapper.fromSyncMap(
        map,
        bookId: 'shadow-book-1',
        deviceId: 'partner-device',
      );

      expect(restored.id, 'tx-123');
      expect(restored.bookId, 'shadow-book-1');
      expect(restored.deviceId, 'partner-device');
      expect(restored.amount, 1500);
      expect(restored.type, TransactionType.expense);
      expect(restored.ledgerType, LedgerType.daily);
      expect(restored.note, 'Lunch');
      expect(restored.isSynced, true);
      expect(restored.currentHash, '');
      expect(restored.metadata?['sourceBookId'], 'book-1');
    });

    test('toSyncMap encodes entrySource as enum name (voice)', () {
      final map = TransactionSyncMapper.toSyncMap(
        sampleTransaction.copyWith(entrySource: EntrySource.voice),
        sourceBookId: 'book-1',
        sourceBookName: 'Main Book',
        sourceBookType: 'remote_book:book-1',
      );

      expect(map['entrySource'], 'voice');
    });

    test('round-trip preserves entrySource across all 3 values', () {
      for (final entrySource in EntrySource.values) {
        final map = TransactionSyncMapper.toSyncMap(
          sampleTransaction.copyWith(entrySource: entrySource),
          sourceBookId: 'book-1',
          sourceBookName: 'Main Book',
          sourceBookType: 'remote_book:book-1',
        );

        final restored = TransactionSyncMapper.fromSyncMap(
          map,
          bookId: 'shadow-book-1',
          deviceId: 'partner-device',
        );

        expect(restored.entrySource, entrySource);
      }
    });

    test('fromSyncMap defaults missing joyFullness to 2', () {
      final map = TransactionSyncMapper.toSyncMap(
        sampleTransaction,
        sourceBookId: 'book-1',
        sourceBookName: 'Main Book',
        sourceBookType: 'remote_book:book-1',
      )..remove('joyFullness');

      final restored = TransactionSyncMapper.fromSyncMap(
        map,
        bookId: 'shadow-book-1',
        deviceId: 'partner-device',
      );

      expect(restored.joyFullness, 2);
    });

    test(
      'fromSyncMap defaults missing entrySource to manual (D-09 fallback)',
      () {
        final map = TransactionSyncMapper.toSyncMap(
          sampleTransaction.copyWith(entrySource: EntrySource.voice),
          sourceBookId: 'book-1',
          sourceBookName: 'Main Book',
          sourceBookType: 'remote_book:book-1',
        )..remove('entrySource');

        final restored = TransactionSyncMapper.fromSyncMap(
          map,
          bookId: 'shadow-book-1',
          deviceId: 'partner-device',
        );

        expect(restored.entrySource, EntrySource.manual);
      },
    );

    test('fromSyncMap throws on invalid entrySource value', () {
      final map = TransactionSyncMapper.toSyncMap(
        sampleTransaction,
        sourceBookId: 'book-1',
        sourceBookName: 'Main Book',
        sourceBookType: 'remote_book:book-1',
      )..['entrySource'] = 'keyboard';

      expect(
        () => TransactionSyncMapper.fromSyncMap(
          map,
          bookId: 'shadow-book-1',
          deviceId: 'partner-device',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toCreateOperation wraps sync payload', () {
      final op = TransactionSyncMapper.toCreateOperation(
        sampleTransaction,
        sourceBookId: 'book-1',
        sourceBookName: 'Main Book',
        sourceBookType: 'remote_book:book-1',
      );

      expect(op['op'], 'create');
      expect(op['entityType'], 'bill');
      expect(op['entityId'], 'tx-123');
      expect(op['data'], isA<Map<String, dynamic>>());
      expect(op['timestamp'], isNotNull);
    });

    // STORE-03: backward-compat and round-trip tests.
    // RED in Wave 0 because Transaction does not yet have
    // originalCurrency / originalAmount / appliedRate fields.
    // These fields are added in Wave 1 (Plan 40-02).
    group('STORE-03 backward-compat and round-trip', () {
      test(
          'fromSyncMap with v1.6 payload (no currency fields) → '
          'originalCurrency null, originalAmount null, appliedRate null, '
          'no exception',
          () {
        // A v1.6 sync payload lacks the three new currency fields entirely.
        final payload = TransactionSyncMapper.toSyncMap(
          sampleTransaction,
          sourceBookId: 'book-1',
          sourceBookName: 'Main Book',
          sourceBookType: 'remote_book:book-1',
        );
        // Simulate v1.6 peer: remove the three new keys if they were present.
        payload.remove('originalCurrency');
        payload.remove('originalAmount');
        payload.remove('appliedRate');

        final transaction = TransactionSyncMapper.fromSyncMap(
          payload,
          bookId: 'shadow-book-1',
          deviceId: 'partner-device',
        );

        // RED: Transaction.originalCurrency does not exist yet.
        expect(transaction.originalCurrency, isNull);
        expect(transaction.originalAmount, isNull);
        expect(transaction.appliedRate, isNull);
      });

      test(
          'fromSyncMap with v1.7 payload containing all three fields → '
          'all three fields preserved',
          () {
        // A v1.7 sync payload includes the three new currency fields.
        final payload = <String, dynamic>{
          'id': 'tx-456',
          'amount': 7465,
          'type': 'expense',
          'categoryId': 'cat-food',
          'ledgerType': 'daily',
          'timestamp': DateTime.utc(2026, 6, 12).toIso8601String(),
          'createdAt': DateTime.utc(2026, 6, 12).toIso8601String(),
          'joyFullness': 5,
          'entrySource': 'manual',
          'isPrivate': false,
          'metadata': {
            'sourceBookId': 'book-1',
            'sourceBookName': 'Main Book',
            'sourceBookType': 'remote_book:book-1',
          },
          // v1.7 new fields
          'originalCurrency': 'USD',
          'originalAmount': 5000,
          'appliedRate': '149.30',
        };

        final transaction = TransactionSyncMapper.fromSyncMap(
          payload,
          bookId: 'shadow-book-1',
          deviceId: 'partner-device',
        );

        // RED: Transaction.originalCurrency/originalAmount/appliedRate do not exist.
        expect(transaction.originalCurrency, equals('USD'));
        expect(transaction.originalAmount, equals(5000));
        expect(transaction.appliedRate, equals('149.30'));
      });

      test(
          'toSyncMap omits currency keys when all three are null '
          '(JPY-native row)',
          () {
        // A JPY-native transaction has all three currency fields null.
        // toSyncMap must NOT emit these keys so v1.6 peers can parse the payload.
        final jpyTransaction = sampleTransaction.copyWith(
          originalCurrency: null,
          originalAmount: null,
          appliedRate: null,
        );

        final map = TransactionSyncMapper.toSyncMap(
          jpyTransaction,
          sourceBookId: 'book-1',
          sourceBookName: 'Main Book',
          sourceBookType: 'remote_book:book-1',
        );

        // RED: Transaction.originalCurrency does not exist yet.
        expect(map.containsKey('originalCurrency'), isFalse);
        expect(map.containsKey('originalAmount'), isFalse);
        expect(map.containsKey('appliedRate'), isFalse);
      });

      test(
          'toSyncMap includes all three currency keys when non-null '
          '(foreign-currency row)',
          () {
        // A foreign-currency transaction has all three fields non-null.
        final usdTransaction = sampleTransaction.copyWith(
          originalCurrency: 'USD',
          originalAmount: 5000,
          appliedRate: '149.30',
        );

        final map = TransactionSyncMapper.toSyncMap(
          usdTransaction,
          sourceBookId: 'book-1',
          sourceBookName: 'Main Book',
          sourceBookType: 'remote_book:book-1',
        );

        // RED: Transaction.originalCurrency does not exist yet.
        expect(map['originalCurrency'], equals('USD'));
        expect(map['originalAmount'], equals(5000));
        expect(map['appliedRate'], equals('149.30'));
      });

      test(
          "round-trip: Transaction with originalCurrency='USD', "
          "originalAmount=5000, appliedRate='149.30' → "
          'toSyncMap → fromSyncMap preserves all three values',
          () {
        // RED: Transaction.originalCurrency/originalAmount/appliedRate do not exist.
        final usdTransaction = sampleTransaction.copyWith(
          originalCurrency: 'USD',
          originalAmount: 5000,
          appliedRate: '149.30',
        );

        final map = TransactionSyncMapper.toSyncMap(
          usdTransaction,
          sourceBookId: 'book-1',
          sourceBookName: 'Main Book',
          sourceBookType: 'remote_book:book-1',
        );

        final restored = TransactionSyncMapper.fromSyncMap(
          map,
          bookId: 'shadow-book-1',
          deviceId: 'partner-device',
        );

        expect(restored.originalCurrency, equals('USD'));
        expect(restored.originalAmount, equals(5000));
        expect(restored.appliedRate, equals('149.30'));
      });
    });
  });
}
