import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  group('Transaction Model', () {
    test('should create transaction with required fields', () {
      final transaction = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000, // ¥100.00
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 4, 10, 30),
        currentHash: 'hash_placeholder',
        createdAt: DateTime(2026, 2, 4, 10, 30),
      );

      expect(transaction.id, 'tx_001');
      expect(transaction.amount, 10000);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.ledgerType, LedgerType.survival);
    });

    test('should accept externally calculated hash', () {
      final transaction = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        currentHash: 'externally_calculated_hash',
        prevHash: 'prev_hash',
      );

      expect(transaction.currentHash, 'externally_calculated_hash');
      expect(transaction.prevHash, 'prev_hash');
    });

    test('should support optional fields', () {
      final transaction = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
        note: 'Lunch at restaurant',
        merchant: 'Family Mart',
      );

      expect(transaction.note, 'Lunch at restaurant');
      expect(transaction.merchant, 'Family Mart');
    });

    test('should generate UUID for new transactions', () {
      final tx1 = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        currentHash: 'hash_1',
      );

      final tx2 = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 20000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        currentHash: 'hash_2',
      );

      expect(tx1.id, isNot(tx2.id));
      expect(tx1.id.length, greaterThan(20)); // UUID format
    });
  });
}
