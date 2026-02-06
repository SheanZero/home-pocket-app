import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  group('TransactionType', () {
    test('has expense, income, and transfer values', () {
      expect(TransactionType.values.length, 3);
      expect(TransactionType.expense, isNotNull);
      expect(TransactionType.income, isNotNull);
      expect(TransactionType.transfer, isNotNull);
    });
  });

  group('LedgerType', () {
    test('has survival and soul values', () {
      expect(LedgerType.values.length, 2);
      expect(LedgerType.survival, isNotNull);
      expect(LedgerType.soul, isNotNull);
    });
  });

  group('Transaction', () {
    test('creates with required fields', () {
      final now = DateTime(2026, 2, 6, 10, 30);
      final tx = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: now,
        currentHash: 'abc123',
        createdAt: now,
      );

      expect(tx.id, 'tx_001');
      expect(tx.amount, 10000);
      expect(tx.type, TransactionType.expense);
      expect(tx.ledgerType, LedgerType.survival);
      expect(tx.isPrivate, false);
      expect(tx.isSynced, false);
      expect(tx.isDeleted, false);
      expect(tx.note, isNull);
      expect(tx.prevHash, isNull);
    });

    test('copyWith creates new instance with updated fields', () {
      final now = DateTime(2026, 2, 6);
      final tx = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: now,
        currentHash: 'hash1',
        createdAt: now,
      );

      final updated = tx.copyWith(amount: 20000, note: 'lunch');

      expect(updated.amount, 20000);
      expect(updated.note, 'lunch');
      expect(updated.id, 'tx_001');
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime(2026, 2, 6, 10, 30);
      final tx = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: now,
        currentHash: 'hash1',
        createdAt: now,
      );

      final json = tx.toJson();
      final restored = Transaction.fromJson(json);

      expect(restored, tx);
    });

    test('equality works for identical data', () {
      final now = DateTime(2026, 2, 6);
      final tx1 = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 100,
        type: TransactionType.expense,
        categoryId: 'cat_1',
        ledgerType: LedgerType.survival,
        timestamp: now,
        currentHash: 'h1',
        createdAt: now,
      );
      final tx2 = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 100,
        type: TransactionType.expense,
        categoryId: 'cat_1',
        ledgerType: LedgerType.survival,
        timestamp: now,
        currentHash: 'h1',
        createdAt: now,
      );

      expect(tx1, tx2);
      expect(tx1.hashCode, tx2.hashCode);
    });
  });
}
