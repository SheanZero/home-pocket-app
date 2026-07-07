import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/analytics_dao.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';

// P2-3: SQL pushdown for the member-filtered category breakdown. The old
// provider pulled all rows via findByBookIds and aggregated in a Dart loop;
// this DAO method must reproduce those numbers exactly — expense-only,
// non-deleted, one member's rows, grouped by leaf category.
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
    String bookId = 'book1',
    String deviceId = 'device_a',
    int amount = 1000,
    String type = 'expense',
    String categoryId = 'cat_food',
    String ledgerType = 'daily',
    String entrySource = 'manual',
    DateTime? timestamp,
    bool isDeleted = false,
  }) {
    final ts = timestamp ?? DateTime(2026, 5, 10, 12);
    return db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            bookId: bookId,
            deviceId: deviceId,
            amount: amount,
            type: type,
            categoryId: categoryId,
            ledgerType: ledgerType,
            timestamp: ts,
            currentHash: 'hash_$id',
            createdAt: ts,
            isDeleted: Value(isDeleted),
            entrySource: Value(entrySource),
          ),
        );
  }

  group('getMemberCategoryTotals', () {
    test(
      'member filter: only the given device\'s non-deleted expense rows, '
      'grouped by leaf category',
      () async {
        // Member A: two categories …
        await seedTx(id: 'a1', categoryId: 'cat_food', amount: 1000);
        await seedTx(id: 'a2', categoryId: 'cat_food', amount: 500);
        await seedTx(id: 'a3', categoryId: 'cat_transport', amount: 2000);
        // … plus an income row and a soft-deleted row that must be excluded.
        await seedTx(
          id: 'a_income',
          categoryId: 'cat_food',
          amount: 9999,
          type: 'income',
        );
        await seedTx(
          id: 'a_deleted',
          categoryId: 'cat_food',
          amount: 8888,
          isDeleted: true,
        );
        // Member B must be excluded when filtering by A.
        await seedTx(id: 'b1', deviceId: 'device_b', amount: 7777);

        final rows = await dao.getMemberCategoryTotals(
          bookId: 'book1',
          startDate: windowStart,
          endDate: windowEnd,
          deviceId: 'device_a',
        );

        final byCat = {for (final r in rows) r.categoryId: r};
        expect(byCat.keys.toSet(), {'cat_food', 'cat_transport'});
        expect(byCat['cat_food']!.totalAmount, 1500); // income + deleted excluded
        expect(byCat['cat_food']!.transactionCount, 2);
        expect(byCat['cat_transport']!.totalAmount, 2000);
        expect(byCat['cat_transport']!.transactionCount, 1);
      },
    );

    test(
      'deviceId = null aggregates across ALL members (clause omitted, never '
      'compared to NULL), still expense-only and non-deleted',
      () async {
        await seedTx(id: 'a1', deviceId: 'device_a', amount: 1000);
        await seedTx(id: 'b1', deviceId: 'device_b', amount: 500);
        await seedTx(
          id: 'income',
          deviceId: 'device_a',
          amount: 9999,
          type: 'income',
        );
        await seedTx(
          id: 'deleted',
          deviceId: 'device_b',
          amount: 8888,
          isDeleted: true,
        );

        final rows = await dao.getMemberCategoryTotals(
          bookId: 'book1',
          startDate: windowStart,
          endDate: windowEnd,
          deviceId: null,
        );

        expect(rows, hasLength(1));
        expect(rows.first.categoryId, 'cat_food');
        expect(rows.first.totalAmount, 1500); // A 1000 + B 500
        expect(rows.first.transactionCount, 2);
      },
    );

    test('entrySource filter narrows to the matching source', () async {
      await seedTx(id: 'm1', amount: 1000, entrySource: 'manual');
      await seedTx(id: 'v1', amount: 500, entrySource: 'voice');

      final rows = await dao.getMemberCategoryTotals(
        bookId: 'book1',
        startDate: windowStart,
        endDate: windowEnd,
        deviceId: 'device_a',
        entrySourceFilter: EntrySource.manual,
      );

      expect(rows, hasLength(1));
      expect(rows.first.totalAmount, 1000); // only the manual row
      expect(rows.first.transactionCount, 1);
    });

    test('rows are ordered by total amount DESC', () async {
      await seedTx(id: 's1', categoryId: 'cat_small', amount: 100);
      await seedTx(id: 'b1', categoryId: 'cat_big', amount: 5000);
      await seedTx(id: 'm1', categoryId: 'cat_mid', amount: 1000);

      final rows = await dao.getMemberCategoryTotals(
        bookId: 'book1',
        startDate: windowStart,
        endDate: windowEnd,
        deviceId: 'device_a',
      );

      expect(rows.map((r) => r.categoryId).toList(), [
        'cat_big',
        'cat_mid',
        'cat_small',
      ]);
    });
  });
}
