import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';

void main() {
  late AppDatabase db;
  late BookDao dao;
  late BookRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = BookDao(db);
    repo = BookRepositoryImpl(dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('BookRepositoryImpl', () {
    test('insert and findById', () async {
      final book = Book(
        id: 'book_001',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: DateTime(2026, 2, 6),
      );

      await repo.insert(book);

      final found = await repo.findById('book_001');
      expect(found, isNotNull);
      expect(found!.name, 'My Book');
      expect(found.currency, 'JPY');
    });

    test('findAll excludes archived by default', () async {
      await repo.insert(
        Book(
          id: 'book_001',
          name: 'Active',
          currency: 'JPY',
          deviceId: 'dev_001',
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      await repo.insert(
        Book(
          id: 'book_002',
          name: 'Archived',
          currency: 'USD',
          deviceId: 'dev_001',
          createdAt: DateTime(2026, 2, 6),
          isArchived: true,
        ),
      );

      final active = await repo.findAll();
      expect(active.length, 1);

      final all = await repo.findAll(includeArchived: true);
      expect(all.length, 2);
    });

    test('update modifies book fields', () async {
      await repo.insert(
        Book(
          id: 'book_001',
          name: 'Old Name',
          currency: 'JPY',
          deviceId: 'dev_001',
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      final book = (await repo.findById('book_001'))!;
      final updated = book.copyWith(name: 'New Name');
      await repo.update(updated);

      final found = await repo.findById('book_001');
      expect(found!.name, 'New Name');
    });

    test('archive sets isArchived flag', () async {
      await repo.insert(
        Book(
          id: 'book_001',
          name: 'Book',
          currency: 'JPY',
          deviceId: 'dev_001',
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      await repo.archive('book_001');

      final book = await repo.findById('book_001');
      expect(book!.isArchived, true);
    });

    test('updateBalances modifies stats', () async {
      await repo.insert(
        Book(
          id: 'book_001',
          name: 'Book',
          currency: 'JPY',
          deviceId: 'dev_001',
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      await repo.updateBalances(
        bookId: 'book_001',
        transactionCount: 42,
        survivalBalance: 100000,
        soulBalance: 50000,
      );

      final book = await repo.findById('book_001');
      expect(book!.transactionCount, 42);
      expect(book.survivalBalance, 100000);
      expect(book.soulBalance, 50000);
    });
  });
}
