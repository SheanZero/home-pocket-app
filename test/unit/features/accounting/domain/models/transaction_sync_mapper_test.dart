import 'package:flutter_test/flutter_test.dart';
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
      ledgerType: LedgerType.survival,
      timestamp: DateTime.utc(2026, 3, 15, 10, 30),
      currentHash: 'hash-abc',
      createdAt: DateTime.utc(2026, 3, 15, 10, 30),
      note: 'Lunch',
      merchant: 'Cafe',
      soulSatisfaction: 7,
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
      expect(map['ledgerType'], 'survival');
      expect(map['note'], 'Lunch');
      expect(map['merchant'], 'Cafe');
      expect(map['soulSatisfaction'], 7);
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
      expect(restored.ledgerType, LedgerType.survival);
      expect(restored.note, 'Lunch');
      expect(restored.isSynced, true);
      expect(restored.currentHash, '');
      expect(restored.metadata?['sourceBookId'], 'book-1');
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
