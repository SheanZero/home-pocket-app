import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/analytics_dao.dart';

void main() {
  late AppDatabase db;
  late AnalyticsDao dao;

  final windowStart = DateTime(2026, 5);
  final windowEnd = DateTime(2026, 5, 31, 23, 59, 59);

  setUp(() {
    db = AppDatabase.forTesting();
    dao = AnalyticsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedTx({
    required String id,
    String bookId = 'book_total',
    int amount = 1000,
    String type = 'expense',
    String categoryId = 'cat_food',
    String ledgerType = 'soul',
    DateTime? timestamp,
    bool isDeleted = false,
    int joyFullness = 6,
  }) {
    final effectiveTimestamp = timestamp ?? DateTime(2026, 5, 10, 12);
    return db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            bookId: bookId,
            deviceId: 'device_1',
            amount: amount,
            type: type,
            categoryId: categoryId,
            ledgerType: ledgerType,
            timestamp: effectiveTimestamp,
            currentHash: 'hash_$id',
            createdAt: effectiveTimestamp,
            isDeleted: Value(isDeleted),
            joyFullness: Value(joyFullness),
          ),
        );
  }

  group('getLargestMonthlyExpense', () {
    test(
      'uses total-ledger expense ordering by amount then latest timestamp',
      () async {
        await seedTx(
          id: 'large_soul_old',
          amount: 8000,
          categoryId: 'cat_hobby',
          ledgerType: 'soul',
          timestamp: DateTime(2026, 5, 15, 8),
        );
        await seedTx(
          id: 'large_survival_new',
          amount: 8000,
          categoryId: 'cat_rent',
          ledgerType: 'survival',
          timestamp: DateTime(2026, 5, 15, 20),
        );
        await seedTx(
          id: 'smaller_survival',
          amount: 7000,
          ledgerType: 'survival',
        );

        final largest = await dao.getLargestMonthlyExpense(
          bookId: 'book_total',
          startDate: windowStart,
          endDate: windowEnd,
        );

        expect(largest, isNotNull);
        expect(largest!.transactionId, 'large_survival_new');
        expect(largest.amount, 8000);
        expect(largest.categoryId, 'cat_rent');
        expect(largest.timestamp, DateTime(2026, 5, 15, 20));
      },
    );

    test(
      'filters income, deleted, other-book, and out-of-window rows',
      () async {
        await seedTx(id: 'included', amount: 3000);
        await seedTx(id: 'income', amount: 9000, type: 'income');
        await seedTx(id: 'deleted', amount: 10000, isDeleted: true);
        await seedTx(id: 'other_book', bookId: 'book_other', amount: 11000);
        await seedTx(
          id: 'june',
          amount: 12000,
          timestamp: DateTime(2026, 6, 1),
        );

        final largest = await dao.getLargestMonthlyExpense(
          bookId: 'book_total',
          startDate: windowStart,
          endDate: windowEnd,
        );

        expect(largest, isNotNull);
        expect(largest!.transactionId, 'included');
        expect(largest.amount, 3000);
      },
    );

    test('returns null when the month has no expenses', () async {
      final largest = await dao.getLargestMonthlyExpense(
        bookId: 'book_total',
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(largest, isNull);
    });
  });
}
