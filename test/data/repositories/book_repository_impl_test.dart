import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:matcher/matcher.dart' as matcher;

void main() {
  late AppDatabase database;
  late BookDao bookDao;
  late BookRepositoryImpl repository;

  setUp(() async {
    // Create in-memory database
    database = AppDatabase(NativeDatabase.memory());
    bookDao = BookDao(database);
    repository = BookRepositoryImpl(bookDao);
  });

  tearDown(() async {
    await database.close();
  });

  group('BookRepositoryImpl - CRUD', () {
    test('should insert and find book by ID', () async {
      // Arrange
      final book = Book(
        id: 'book_test_1',
        name: 'Test Book',
        currency: 'JPY',
        deviceId: 'device_1',
        createdAt: DateTime(2026, 1, 1),
      );

      // Act
      await repository.insert(book);
      final result = await repository.findById('book_test_1');

      // Assert
      expect(result, matcher.isNotNull);
      expect(result!.id, 'book_test_1');
      expect(result.name, 'Test Book');
      expect(result.currency, 'JPY');
      expect(result.deviceId, 'device_1');
      expect(result.isArchived, false);
      expect(result.transactionCount, 0);
      expect(result.survivalBalance, 0);
      expect(result.soulBalance, 0);
    });

    test('should find all books', () async {
      // Arrange
      final book1 = Book(
        id: 'book_1',
        name: 'Book 1',
        currency: 'JPY',
        deviceId: 'device_1',
        createdAt: DateTime(2026, 1, 1),
      );

      final book2 = Book(
        id: 'book_2',
        name: 'Book 2',
        currency: 'USD',
        deviceId: 'device_1',
        createdAt: DateTime(2026, 1, 2),
      );

      // Act
      await repository.insert(book1);
      await repository.insert(book2);
      final result = await repository.findAll();

      // Assert
      expect(result.length, 2);
      expect(result[0].id, 'book_1');
      expect(result[1].id, 'book_2');
    });

    test('should find only active books', () async {
      // Arrange
      final activeBook = Book(
        id: 'book_active',
        name: 'Active Book',
        currency: 'JPY',
        deviceId: 'device_1',
        createdAt: DateTime(2026, 1, 1),
      );

      final archivedBook = Book(
        id: 'book_archived',
        name: 'Archived Book',
        currency: 'JPY',
        deviceId: 'device_1',
        createdAt: DateTime(2026, 1, 2),
        isArchived: true,
      );

      // Act
      await repository.insert(activeBook);
      await repository.insert(archivedBook);
      final result = await repository.findActive();

      // Assert
      expect(result.length, 1);
      expect(result[0].id, 'book_active');
      expect(result[0].isArchived, false);
    });

    test('should archive book', () async {
      // Arrange
      final book = Book(
        id: 'book_to_archive',
        name: 'Book to Archive',
        currency: 'JPY',
        deviceId: 'device_1',
        createdAt: DateTime(2026, 1, 1),
      );

      // Act
      await repository.insert(book);
      await repository.archive('book_to_archive');
      final result = await repository.findById('book_to_archive');
      final activeBooks = await repository.findActive();

      // Assert
      expect(result, matcher.isNotNull);
      expect(result!.isArchived, true);
      expect(result.updatedAt, matcher.isNotNull); // updatedAt should be set
      expect(activeBooks.length, 0); // Should not appear in active books
    });

    test('should find books by device', () async {
      // Arrange
      final book1 = Book(
        id: 'book_device1',
        name: 'Device 1 Book',
        currency: 'JPY',
        deviceId: 'device_1',
        createdAt: DateTime(2026, 1, 1),
      );

      final book2 = Book(
        id: 'book_device2',
        name: 'Device 2 Book',
        currency: 'JPY',
        deviceId: 'device_2',
        createdAt: DateTime(2026, 1, 2),
      );

      // Act
      await repository.insert(book1);
      await repository.insert(book2);
      final result = await repository.findByDevice('device_1');

      // Assert
      expect(result.length, 1);
      expect(result[0].id, 'book_device1');
      expect(result[0].deviceId, 'device_1');
    });

    test('should update book', () async {
      // Arrange
      final book = Book(
        id: 'book_to_update',
        name: 'Original Name',
        currency: 'JPY',
        deviceId: 'device_1',
        createdAt: DateTime(2026, 1, 1),
      );

      // Act
      await repository.insert(book);
      final updatedBook = book.copyWith(
        name: 'Updated Name',
        currency: 'USD',
      );
      await repository.update(updatedBook);
      final result = await repository.findById('book_to_update');

      // Assert
      expect(result, matcher.isNotNull);
      expect(result!.name, 'Updated Name');
      expect(result.currency, 'USD');
      expect(result.updatedAt, matcher.isNotNull); // updatedAt should be set
    });

    test('should delete book', () async {
      // Arrange
      final book = Book(
        id: 'book_to_delete',
        name: 'Book to Delete',
        currency: 'JPY',
        deviceId: 'device_1',
        createdAt: DateTime(2026, 1, 1),
      );

      // Act
      await repository.insert(book);
      await repository.delete('book_to_delete');
      final result = await repository.findById('book_to_delete');

      // Assert
      expect(result, matcher.isNull);
    });
  });

  group('BookRepositoryImpl - statistics', () {
    test('should update statistics', () async {
      // Arrange
      final book = Book(
        id: 'book_stats',
        name: 'Book with Stats',
        currency: 'JPY',
        deviceId: 'device_1',
        createdAt: DateTime(2026, 1, 1),
      );

      // Act
      await repository.insert(book);
      await repository.updateStatistics(
        bookId: 'book_stats',
        transactionCount: 10,
        survivalBalance: 50000,
        soulBalance: 30000,
      );
      final result = await repository.findById('book_stats');

      // Assert
      expect(result, matcher.isNotNull);
      expect(result!.transactionCount, 10);
      expect(result.survivalBalance, 50000);
      expect(result.soulBalance, 30000);
      expect(result.totalBalance, 80000); // 50000 + 30000
      expect(result.updatedAt, matcher.isNotNull); // updatedAt should be set
    });
  });
}
