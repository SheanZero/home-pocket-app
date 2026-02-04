import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';

void main() {
  group('Book Model', () {
    test('should create book with required fields', () {
      final book = Book.create(
        name: 'My Book',
        currency: 'CNY',
        deviceId: 'device_001',
      );

      expect(book.id, isNotEmpty);
      expect(book.name, 'My Book');
      expect(book.currency, 'CNY');
      expect(book.deviceId, 'device_001');
      expect(book.isArchived, isFalse);
    });

    test('should have default statistics', () {
      final book = Book.create(
        name: 'Test Book',
        currency: 'USD',
        deviceId: 'device_001',
      );

      expect(book.transactionCount, 0);
      expect(book.survivalBalance, 0);
      expect(book.soulBalance, 0);
    });

    test('should update balances immutably', () {
      final book = Book.create(
        name: 'Test Book',
        currency: 'CNY',
        deviceId: 'device_001',
      );

      final updatedBook = book.copyWith(
        survivalBalance: 50000,
        soulBalance: 10000,
        transactionCount: 10,
      );

      // Original unchanged
      expect(book.survivalBalance, 0);
      expect(book.soulBalance, 0);
      expect(book.transactionCount, 0);

      // Updated has new values
      expect(updatedBook.survivalBalance, 50000);
      expect(updatedBook.soulBalance, 10000);
      expect(updatedBook.transactionCount, 10);
    });

    test('should calculate total balance', () {
      final book = Book.create(
        name: 'Test Book',
        currency: 'CNY',
        deviceId: 'device_001',
      ).copyWith(
        survivalBalance: 50000,  // ¥500.00
        soulBalance: 10000,      // ¥100.00
      );

      expect(book.totalBalance, 60000);  // ¥600.00
    });

    test('should generate unique IDs', () {
      final book1 = Book.create(
        name: 'Book 1',
        currency: 'CNY',
        deviceId: 'device_001',
      );

      final book2 = Book.create(
        name: 'Book 2',
        currency: 'CNY',
        deviceId: 'device_001',
      );

      expect(book1.id, isNot(book2.id));
      expect(book1.id.length, greaterThan(20)); // UUID format
    });
  });
}
