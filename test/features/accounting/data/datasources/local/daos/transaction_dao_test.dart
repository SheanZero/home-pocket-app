import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  late TransactionDao dao;
  late AppDatabase db;

  setUp(() async {
    // Create in-memory database for testing
    db = AppDatabase(NativeDatabase.memory());
    dao = db.transactionDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionDao', () {
    test('should insert transaction', () async {
      final transaction = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
      );

      await dao.insertTransaction(transaction);

      final result = await dao.getTransactionById(transaction.id);
      expect(result, isNotNull);
      expect(result!.id, transaction.id);
      expect(result.amount, 10000);
    });

    test('should get transactions by book', () async {
      final tx1 = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
      );

      final tx2 = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 5000,
        type: TransactionType.expense,
        categoryId: 'cat_transport',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
      );

      await dao.insertTransaction(tx1);
      await dao.insertTransaction(tx2);

      final results = await dao.getTransactionsByBook('book_001');
      expect(results.length, 2);
    });

    test('should filter by date range', () async {
      final oldTx = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
        timestamp: DateTime(2026, 1, 1),
      );

      final newTx = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 5000,
        type: TransactionType.expense,
        categoryId: 'cat_transport',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
        timestamp: DateTime(2026, 2, 1),
      );

      await dao.insertTransaction(oldTx);
      await dao.insertTransaction(newTx);

      final results = await dao.getTransactionsByBook(
        'book_001',
        startDate: DateTime(2026, 1, 15),
      );

      expect(results.length, 1);
      expect(results.first.id, newTx.id);
    });

    test('should update transaction', () async {
      final transaction = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
      );

      await dao.insertTransaction(transaction);

      final updated = transaction.copyWith(
        note: 'Updated note',
        updatedAt: DateTime.now(),
      );

      await dao.updateTransaction(updated);

      final result = await dao.getTransactionById(transaction.id);
      expect(result!.note, 'Updated note');
      expect(result.updatedAt, isNotNull);
    });

    test('should delete transaction', () async {
      final transaction = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
      );

      await dao.insertTransaction(transaction);
      await dao.deleteTransaction(transaction.id);

      final result = await dao.getTransactionById(transaction.id);
      expect(result, isNull);
    });

    test('should get latest hash for hash chain', () async {
      final tx1 = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
      );

      await dao.insertTransaction(tx1);

      final latestHash = await dao.getLatestHash('book_001');
      expect(latestHash, tx1.currentHash);
    });
  });
}
