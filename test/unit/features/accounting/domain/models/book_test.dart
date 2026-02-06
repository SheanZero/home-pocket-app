import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';

void main() {
  group('Book', () {
    test('creates with required fields and defaults', () {
      final now = DateTime(2026, 2, 6);
      final book = Book(
        id: 'book_001',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      expect(book.id, 'book_001');
      expect(book.name, 'My Book');
      expect(book.currency, 'JPY');
      expect(book.isArchived, false);
      expect(book.transactionCount, 0);
      expect(book.survivalBalance, 0);
      expect(book.soulBalance, 0);
      expect(book.updatedAt, isNull);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime(2026, 2, 6, 10, 30);
      final book = Book(
        id: 'book_001',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
        transactionCount: 5,
        survivalBalance: 50000,
        soulBalance: 20000,
      );

      final json = book.toJson();
      final restored = Book.fromJson(json);

      expect(restored, book);
    });

    test('copyWith creates new instance', () {
      final now = DateTime(2026, 2, 6);
      final book = Book(
        id: 'book_001',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      final updated = book.copyWith(name: 'Family Book', isArchived: true);

      expect(updated.name, 'Family Book');
      expect(updated.isArchived, true);
      expect(updated.id, 'book_001');
    });

    test('equality works for identical data', () {
      final now = DateTime(2026, 2, 6);
      final b1 = Book(
        id: 'book_001',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );
      final b2 = Book(
        id: 'book_001',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      expect(b1, b2);
      expect(b1.hashCode, b2.hashCode);
    });
  });
}
