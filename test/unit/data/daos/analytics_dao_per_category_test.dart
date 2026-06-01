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
    String ledgerType = 'joy',
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

  group('getPerCategoryJoyBreakdown (single book)', () {
    test('returns row type PerCategoryJoyRowRaw', () async {
      await seedTx(id: 'joy_1', categoryId: 'cat_a', joyFullness: 8);

      final rows = await dao.getPerCategoryJoyBreakdown(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(rows, isA<List<PerCategoryJoyRowRaw>>());
      expect(rows, hasLength(1));
      expect(rows.first.categoryId, 'cat_a');
      expect(rows.first.avgSatisfaction, 8.0);
      expect(rows.first.totalCount, 1);
    });

    test('excludes daily rows (joy-only filter)', () async {
      await seedTx(id: 'joy_a', categoryId: 'cat_a', joyFullness: 8);
      await seedTx(
        id: 'daily_a',
        categoryId: 'cat_a',
        ledgerType: 'daily',
        joyFullness: 10,
      );

      final rows = await dao.getPerCategoryJoyBreakdown(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(rows, hasLength(1));
      expect(rows.first.avgSatisfaction, 8.0);
      expect(rows.first.totalCount, 1);
    });

    test('excludes income rows (type=expense filter)', () async {
      await seedTx(id: 'joy_a', categoryId: 'cat_a', joyFullness: 8);
      await seedTx(
        id: 'income_a',
        categoryId: 'cat_a',
        type: 'income',
        joyFullness: 10,
      );

      final rows = await dao.getPerCategoryJoyBreakdown(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(rows, hasLength(1));
      expect(rows.first.totalCount, 1);
    });

    test('excludes soft-deleted rows', () async {
      await seedTx(id: 'joy_a', categoryId: 'cat_a', joyFullness: 8);
      await seedTx(
        id: 'deleted_a',
        categoryId: 'cat_a',
        isDeleted: true,
        joyFullness: 10,
      );

      final rows = await dao.getPerCategoryJoyBreakdown(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(rows, hasLength(1));
      expect(rows.first.totalCount, 1);
    });

    test('respects window boundaries (timestamp >= start AND <= end)', () async {
      // Inside window — included
      await seedTx(
        id: 'inside_start',
        categoryId: 'cat_a',
        timestamp: windowStart,
        joyFullness: 5,
      );
      await seedTx(
        id: 'inside_end',
        categoryId: 'cat_a',
        timestamp: windowEnd,
        joyFullness: 5,
      );
      // Outside window — excluded
      await seedTx(
        id: 'before_start',
        categoryId: 'cat_a',
        timestamp: DateTime(2026, 4, 30, 23, 59, 59),
        joyFullness: 10,
      );
      await seedTx(
        id: 'after_end',
        categoryId: 'cat_a',
        timestamp: DateTime(2026, 6, 1),
        joyFullness: 10,
      );

      final rows = await dao.getPerCategoryJoyBreakdown(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(rows, hasLength(1));
      expect(rows.first.totalCount, 2);
      expect(rows.first.avgSatisfaction, 5.0);
    });

    test(
      'sort: AVG DESC, COUNT DESC, categoryId ASC — and NO HAVING (low-N included)',
      () async {
        // cat_a: avgSat=8.0, count=3
        for (var i = 0; i < 3; i += 1) {
          await seedTx(
            id: 'cat_a_$i',
            categoryId: 'cat_a',
            joyFullness: 8,
          );
        }
        // cat_b: avgSat=6.0, count=2
        for (var i = 0; i < 2; i += 1) {
          await seedTx(
            id: 'cat_b_$i',
            categoryId: 'cat_b',
            joyFullness: 6,
          );
        }
        // cat_c: avgSat=9.5, count=1 (low-N — MUST still appear; no HAVING)
        await seedTx(id: 'cat_c_0', categoryId: 'cat_c', joyFullness: 9);
        // Need avgSat=9.5 → two rows of 9 + 10
        await db.delete(db.transactions).go();
        for (var i = 0; i < 3; i += 1) {
          await seedTx(
            id: 'a_$i',
            categoryId: 'cat_a',
            joyFullness: 8,
          );
        }
        for (var i = 0; i < 2; i += 1) {
          await seedTx(
            id: 'b_$i',
            categoryId: 'cat_b',
            joyFullness: 6,
          );
        }
        await seedTx(id: 'c_only', categoryId: 'cat_c', joyFullness: 9);

        final rows = await dao.getPerCategoryJoyBreakdown(
          bookId: 'book_joy',
          startDate: windowStart,
          endDate: windowEnd,
        );

        expect(rows, hasLength(3));
        // cat_c (avgSat=9.0, count=1) > cat_a (8.0, 3) > cat_b (6.0, 2)
        expect(rows[0].categoryId, 'cat_c');
        expect(rows[0].avgSatisfaction, 9.0);
        expect(rows[0].totalCount, 1);
        expect(rows[1].categoryId, 'cat_a');
        expect(rows[1].avgSatisfaction, 8.0);
        expect(rows[1].totalCount, 3);
        expect(rows[2].categoryId, 'cat_b');
        expect(rows[2].avgSatisfaction, 6.0);
        expect(rows[2].totalCount, 2);
      },
    );

    test('tie-break on AVG: COUNT DESC wins', () async {
      // cat_a: avgSat=7.0, count=5
      for (var i = 0; i < 5; i += 1) {
        await seedTx(id: 'a_$i', categoryId: 'cat_a', joyFullness: 7);
      }
      // cat_b: avgSat=7.0, count=3
      for (var i = 0; i < 3; i += 1) {
        await seedTx(id: 'b_$i', categoryId: 'cat_b', joyFullness: 7);
      }

      final rows = await dao.getPerCategoryJoyBreakdown(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(rows, hasLength(2));
      expect(rows[0].categoryId, 'cat_a'); // count=5 wins
      expect(rows[0].totalCount, 5);
      expect(rows[1].categoryId, 'cat_b');
      expect(rows[1].totalCount, 3);
    });

    test('tie-break on AVG + COUNT: categoryId ASC wins', () async {
      // Both: avgSat=7.0, count=5 → categoryId ASC ('cat_a' < 'cat_b')
      for (var i = 0; i < 5; i += 1) {
        await seedTx(id: 'b_$i', categoryId: 'cat_b', joyFullness: 7);
      }
      for (var i = 0; i < 5; i += 1) {
        await seedTx(id: 'a_$i', categoryId: 'cat_a', joyFullness: 7);
      }

      final rows = await dao.getPerCategoryJoyBreakdown(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(rows, hasLength(2));
      expect(rows[0].categoryId, 'cat_a'); // lexical ASC
      expect(rows[1].categoryId, 'cat_b');
    });

    test('empty window → empty list (not null)', () async {
      final rows = await dao.getPerCategoryJoyBreakdown(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(rows, isNotNull);
      expect(rows, isEmpty);
    });
  });

  group('getPerCategoryJoyBreakdownAcrossBooks (family pool)', () {
    test(
      'pools rows across books WITHOUT GROUP BY book_id (one row per category)',
      () async {
        // bookA: cat_a count=2, avg=8
        await seedTx(
          id: 'a1',
          bookId: 'book_a',
          categoryId: 'cat_a',
          joyFullness: 8,
        );
        await seedTx(
          id: 'a2',
          bookId: 'book_a',
          categoryId: 'cat_a',
          joyFullness: 8,
        );
        // bookB: cat_a count=2, avg=8
        await seedTx(
          id: 'b1',
          bookId: 'book_b',
          categoryId: 'cat_a',
          joyFullness: 8,
        );
        await seedTx(
          id: 'b2',
          bookId: 'book_b',
          categoryId: 'cat_a',
          joyFullness: 8,
        );

        final rows = await dao.getPerCategoryJoyBreakdownAcrossBooks(
          bookIds: ['book_a', 'book_b'],
          startDate: windowStart,
          endDate: windowEnd,
        );

        // Pooled — ONE row for cat_a with count=4 (never two book_id rows)
        expect(rows, hasLength(1));
        expect(rows.first.categoryId, 'cat_a');
        expect(rows.first.totalCount, 4);
        expect(rows.first.avgSatisfaction, 8.0);
      },
    );

    test('empty bookIds → empty list, no DB call', () async {
      // Seed data that would otherwise match — verify NOT returned
      await seedTx(id: 'joy_a', categoryId: 'cat_a', joyFullness: 8);

      final rows = await dao.getPerCategoryJoyBreakdownAcrossBooks(
        bookIds: const [],
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(rows, isEmpty);
    });
  });
}
