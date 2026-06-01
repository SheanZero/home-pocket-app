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
  });
}
