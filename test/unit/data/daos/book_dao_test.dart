import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';

void main() {
  late AppDatabase db;
  late BookDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = BookDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BookDao', () {
    test('insertBook and findById', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertBook(
        id: 'book_001',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      final book = await dao.findById('book_001');
      expect(book, isNotNull);
      expect(book!.name, 'My Book');
      expect(book.currency, 'JPY');
    });

    test('findById returns null for non-existent', () async {
      final book = await dao.findById('no_such_book');
      expect(book, isNull);
    });

    test('findAll returns all non-archived books', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertBook(
        id: 'book_001',
        name: 'Active Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      await dao.insertBook(
        id: 'book_002',
        name: 'Archived Book',
        currency: 'USD',
        deviceId: 'dev_001',
        createdAt: now,
        isArchived: true,
      );

      final active = await dao.findAll(includeArchived: false);
      expect(active.length, 1);
      expect(active.first.name, 'Active Book');

      final all = await dao.findAll(includeArchived: true);
      expect(all.length, 2);
    });

    test('updateBook modifies fields', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertBook(
        id: 'book_001',
        name: 'Old Name',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      await dao.updateBook(
        id: 'book_001',
        name: 'New Name',
        updatedAt: DateTime(2026, 2, 7),
      );

      final book = await dao.findById('book_001');
      expect(book!.name, 'New Name');
      expect(book.updatedAt, isNotNull);
    });

    test('archiveBook sets isArchived flag', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertBook(
        id: 'book_001',
        name: 'Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      await dao.archiveBook('book_001');

      final book = await dao.findById('book_001');
      expect(book!.isArchived, true);
    });

    test('updateBalances modifies stats', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertBook(
        id: 'book_001',
        name: 'Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      await dao.updateBalances(
        bookId: 'book_001',
        transactionCount: 10,
        survivalBalance: 50000,
        soulBalance: 20000,
      );

      final book = await dao.findById('book_001');
      expect(book!.transactionCount, 10);
      expect(book.survivalBalance, 50000);
      expect(book.soulBalance, 20000);
    });
  });
}
