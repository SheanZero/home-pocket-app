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
    String bookId = 'book_joy',
    int amount = 1000,
    String type = 'expense',
    String categoryId = 'cat_joy',
    String ledgerType = 'soul',
    DateTime? timestamp,
    bool isDeleted = false,
    int soulSatisfaction = 6,
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
            soulSatisfaction: Value(soulSatisfaction),
          ),
        );
  }

  group('getDailySoulRowsForPtvf', () {
    test(
      'returns soul expense amount and satisfaction rows grouped by day',
      () async {
        await seedTx(
          id: 'day_10_a',
          amount: 1200,
          soulSatisfaction: 4,
          timestamp: DateTime(2026, 5, 10, 8),
        );
        await seedTx(
          id: 'day_10_b',
          amount: 800,
          soulSatisfaction: 8,
          timestamp: DateTime(2026, 5, 10, 20),
        );
        await seedTx(
          id: 'day_11',
          amount: 5000,
          soulSatisfaction: 10,
          timestamp: DateTime(2026, 5, 11, 12),
        );

        final rows = await dao.getDailySoulRowsForPtvf(
          bookId: 'book_joy',
          startDate: windowStart,
          endDate: windowEnd,
        );

        expect(rows, hasLength(3));
        expect(rows.map((row) => row.day), [
          DateTime(2026, 5, 10),
          DateTime(2026, 5, 10),
          DateTime(2026, 5, 11),
        ]);
        expect(rows.map((row) => row.amount), [1200, 800, 5000]);
        expect(rows.map((row) => row.soulSatisfaction), [4, 8, 10]);
      },
    );

    test(
      'excludes survival, income, deleted, other-book, and out-of-window rows',
      () async {
        await seedTx(id: 'included', amount: 2200, soulSatisfaction: 7);
        await seedTx(
          id: 'survival',
          amount: 5000,
          ledgerType: 'survival',
          soulSatisfaction: 10,
        );
        await seedTx(id: 'income', amount: 6000, type: 'income');
        await seedTx(id: 'deleted', amount: 7000, isDeleted: true);
        await seedTx(id: 'other_book', bookId: 'book_other', amount: 8000);
        await seedTx(
          id: 'april',
          amount: 9000,
          timestamp: DateTime(2026, 4, 30, 23, 59),
        );

        final rows = await dao.getDailySoulRowsForPtvf(
          bookId: 'book_joy',
          startDate: windowStart,
          endDate: windowEnd,
        );

        expect(rows, hasLength(1));
        expect(rows.single.amount, 2200);
        expect(rows.single.soulSatisfaction, 7);
      },
    );
  });
}
