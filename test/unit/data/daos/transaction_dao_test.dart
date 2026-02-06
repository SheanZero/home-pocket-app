import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';

void main() {
  late AppDatabase db;
  late TransactionDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = TransactionDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionDao', () {
    test('insertTransaction and findById', () async {
      final now = DateTime(2026, 2, 6, 10, 0);

      await dao.insertTransaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 10000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: now,
        currentHash: 'hash_abc',
        createdAt: now,
      );

      final tx = await dao.findById('tx_001');
      expect(tx, isNotNull);
      expect(tx!.amount, 10000);
      expect(tx.type, 'expense');
    });

    test(
      'findByBookId returns transactions ordered by timestamp desc',
      () async {
        final t1 = DateTime(2026, 2, 5, 10, 0);
        final t2 = DateTime(2026, 2, 6, 10, 0);

        await dao.insertTransaction(
          id: 'tx_001',
          bookId: 'book_001',
          deviceId: 'dev_001',
          amount: 1000,
          type: 'expense',
          categoryId: 'cat_food',
          ledgerType: 'survival',
          timestamp: t1,
          currentHash: 'h1',
          createdAt: t1,
        );

        await dao.insertTransaction(
          id: 'tx_002',
          bookId: 'book_001',
          deviceId: 'dev_001',
          amount: 2000,
          type: 'income',
          categoryId: 'cat_salary',
          ledgerType: 'survival',
          timestamp: t2,
          currentHash: 'h2',
          createdAt: t2,
        );

        final results = await dao.findByBookId('book_001');
        expect(results.length, 2);
        expect(results.first.id, 'tx_002');
      },
    );

    test('findByBookId excludes soft-deleted', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertTransaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 1000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: now,
        currentHash: 'h1',
        createdAt: now,
      );

      await dao.softDelete('tx_001');

      final results = await dao.findByBookId('book_001');
      expect(results.length, 0);
    });

    test('findByBookId with filters', () async {
      final t1 = DateTime(2026, 2, 1);
      final t2 = DateTime(2026, 2, 15);

      await dao.insertTransaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 1000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: t1,
        currentHash: 'h1',
        createdAt: t1,
      );

      await dao.insertTransaction(
        id: 'tx_002',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 2000,
        type: 'expense',
        categoryId: 'cat_transport',
        ledgerType: 'soul',
        timestamp: t2,
        currentHash: 'h2',
        createdAt: t2,
      );

      // Filter by ledger type
      final soul = await dao.findByBookId('book_001', ledgerType: 'soul');
      expect(soul.length, 1);
      expect(soul.first.id, 'tx_002');

      // Filter by date range
      final feb = await dao.findByBookId(
        'book_001',
        startDate: DateTime(2026, 2, 10),
        endDate: DateTime(2026, 2, 20),
      );
      expect(feb.length, 1);
      expect(feb.first.id, 'tx_002');
    });

    test('findByBookId supports pagination', () async {
      final now = DateTime(2026, 2, 6);

      for (int i = 0; i < 5; i++) {
        await dao.insertTransaction(
          id: 'tx_00$i',
          bookId: 'book_001',
          deviceId: 'dev_001',
          amount: (i + 1) * 1000,
          type: 'expense',
          categoryId: 'cat_food',
          ledgerType: 'survival',
          timestamp: now.add(Duration(hours: i)),
          currentHash: 'h$i',
          createdAt: now,
        );
      }

      final page1 = await dao.findByBookId('book_001', limit: 2, offset: 0);
      expect(page1.length, 2);

      final page2 = await dao.findByBookId('book_001', limit: 2, offset: 2);
      expect(page2.length, 2);

      final page3 = await dao.findByBookId('book_001', limit: 2, offset: 4);
      expect(page3.length, 1);
    });

    test('getLatestHash returns most recent transaction hash', () async {
      final t1 = DateTime(2026, 2, 5);
      final t2 = DateTime(2026, 2, 6);

      await dao.insertTransaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 1000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: t1,
        currentHash: 'first_hash',
        createdAt: t1,
      );

      await dao.insertTransaction(
        id: 'tx_002',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 2000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: t2,
        currentHash: 'latest_hash',
        createdAt: t2,
        prevHash: 'first_hash',
      );

      final hash = await dao.getLatestHash('book_001');
      expect(hash, 'latest_hash');
    });

    test('getLatestHash returns null for empty book', () async {
      final hash = await dao.getLatestHash('no_book');
      expect(hash, isNull);
    });

    test('countByBookId counts non-deleted transactions', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertTransaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 1000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: now,
        currentHash: 'h1',
        createdAt: now,
      );

      await dao.insertTransaction(
        id: 'tx_002',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 2000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: now,
        currentHash: 'h2',
        createdAt: now,
      );

      await dao.softDelete('tx_002');

      final count = await dao.countByBookId('book_001');
      expect(count, 1);
    });
  });
}
