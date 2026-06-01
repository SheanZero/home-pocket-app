import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/analytics_dao.dart';

void main() {
  late AppDatabase db;
  late AnalyticsDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = AnalyticsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedTx({
    required String id,
    String bookId = 'book_history',
    required DateTime timestamp,
    bool isDeleted = false,
  }) {
    return db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            bookId: bookId,
            deviceId: 'device_1',
            amount: 1000,
            type: 'expense',
            categoryId: 'cat_food',
            ledgerType: 'daily',
            timestamp: timestamp,
            currentHash: 'hash_$id',
            createdAt: timestamp,
            isDeleted: Value(isDeleted),
          ),
        );
  }

  group('getEarliestTransactionTimestamp', () {
    test('returns the oldest non-deleted timestamp for the book', () async {
      await seedTx(id: 'newer', timestamp: DateTime(2026, 4, 10));
      await seedTx(id: 'oldest', timestamp: DateTime(2024, 12, 31));
      await seedTx(
        id: 'deleted_older',
        timestamp: DateTime(2023, 1, 1),
        isDeleted: true,
      );
      await seedTx(
        id: 'other_book_older',
        bookId: 'book_other',
        timestamp: DateTime(2022, 1, 1),
      );

      final timestamp = await dao.getEarliestTransactionTimestamp(
        bookId: 'book_history',
      );

      expect(timestamp, DateTime(2024, 12, 31));
    });

    test(
      'returns null when the book has no non-deleted transactions',
      () async {
        await seedTx(
          id: 'deleted',
          timestamp: DateTime(2024, 12, 31),
          isDeleted: true,
        );

        final timestamp = await dao.getEarliestTransactionTimestamp(
          bookId: 'book_history',
        );

        expect(timestamp, isNull);
      },
    );
  });
}
