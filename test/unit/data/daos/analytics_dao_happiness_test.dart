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

  group('_joyOnly filter / daily rows excluded', () {
    test('overview counts only active joy expenses', () async {
      await seedTx(id: 'joy_1', amount: 1000, joyFullness: 4);
      await seedTx(id: 'joy_2', amount: 2000, joyFullness: 8);
      await seedTx(
        id: 'daily_1',
        amount: 3000,
        ledgerType: 'daily',
        joyFullness: 10,
      );
      await seedTx(
        id: 'daily_2',
        amount: 4000,
        ledgerType: 'daily',
        joyFullness: 10,
      );
      await seedTx(
        id: 'deleted_joy',
        amount: 5000,
        isDeleted: true,
        joyFullness: 10,
      );

      final result = await dao.getJoyFullnessOverview(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(result.count, 2);
      expect(result.avgSatisfaction, 6);
    });
  });

  group('row-wise PTVF query', () {
    test('returns row-wise amount and satisfaction tuples', () async {
      await seedTx(id: 'row_1', amount: 1000, joyFullness: 4);
      await seedTx(id: 'row_2', amount: 2500, joyFullness: 8);
      await seedTx(id: 'row_3', amount: 700, joyFullness: 10);

      final rows = await dao.getJoyRowsForJoyContribution(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(rows, hasLength(3));
      expect(
        rows.map((row) => '${row.amount}:${row.joyFullness}'),
        unorderedEquals(['1000:4', '2500:8', '700:10']),
      );
    });
  });

  group('best joy ordering', () {
    test(
      'uses satisfaction DESC then amount DESC tiebreak then timestamp DESC',
      () async {
        await seedTx(
          id: 'trip_sat_8',
          amount: 10000,
          joyFullness: 8,
          timestamp: DateTime(2026, 5, 10, 10),
        );
        await seedTx(
          id: 'candy_sat_10',
          amount: 500,
          joyFullness: 10,
          timestamp: DateTime(2026, 5, 11, 10),
        );
        await seedTx(
          id: 'concert_sat_10_old',
          amount: 3000,
          joyFullness: 10,
          timestamp: DateTime(2026, 5, 12, 9),
        );
        await seedTx(
          id: 'concert_sat_10_new',
          amount: 3000,
          joyFullness: 10,
          timestamp: DateTime(2026, 5, 12, 12),
        );

        final best = await dao.getBestJoyMoment(
          bookId: 'book_joy',
          startDate: windowStart,
          endDate: windowEnd,
        );

        expect(best, isNotNull);
        expect(best!.transactionId, 'concert_sat_10_new');
        expect(best.amount, 3000);
        expect(best.joyFullness, 10);
      },
    );

    test('returns null when no joy rows exist in the window', () async {
      final best = await dao.getBestJoyMoment(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(best, isNull);
    });

    test('excludes daily rows from best joy selection', () async {
      await seedTx(
        id: 'huge_daily',
        amount: 1000000,
        ledgerType: 'daily',
        joyFullness: 10,
      );
      await seedTx(id: 'modest_joy', amount: 2000, joyFullness: 8);

      final best = await dao.getBestJoyMoment(
        bookId: 'book_joy',
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(best, isNotNull);
      expect(best!.transactionId, 'modest_joy');
    });
  });

  group('FAMILY-02 shared joy category insight', () {
    test('uses min-N=3 guard before average satisfaction ordering', () async {
      for (var i = 0; i < 5; i += 1) {
        await seedTx(
          id: 'qualified_$i',
          bookId: i.isEven ? 'book_joy' : 'book_partner',
          categoryId: 'cat_qualified',
          joyFullness: 8,
        );
      }
      for (var i = 0; i < 2; i += 1) {
        await seedTx(
          id: 'too_small_$i',
          bookId: i.isEven ? 'book_joy' : 'book_partner',
          categoryId: 'cat_too_small',
          joyFullness: 10,
        );
      }

      final insight = await dao.getSharedJoyCategoryInsight(
        bookIds: ['book_joy', 'book_partner'],
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(insight, isNotNull);
      expect(insight!.categoryId, 'cat_qualified');
      expect(insight.avgSatisfaction, 8);
      expect(insight.totalCount, 5);
    });

    test('returns null when no category meets min-N=3', () async {
      for (final categoryId in ['cat_a', 'cat_b', 'cat_c']) {
        for (var i = 0; i < 2; i += 1) {
          await seedTx(
            id: '${categoryId}_$i',
            categoryId: categoryId,
            joyFullness: 9,
          );
        }
      }

      final insight = await dao.getSharedJoyCategoryInsight(
        bookIds: ['book_joy'],
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(insight, isNull);
    });

    test('ties by count then category_id ascending', () async {
      for (var i = 0; i < 5; i += 1) {
        await seedTx(
          id: 'count_winner_$i',
          categoryId: 'cat_b_count_wins',
          joyFullness: 8,
        );
      }
      for (var i = 0; i < 4; i += 1) {
        await seedTx(
          id: 'count_loser_$i',
          categoryId: 'cat_a_count_loses',
          joyFullness: 8,
        );
      }

      final countWinner = await dao.getSharedJoyCategoryInsight(
        bookIds: ['book_joy'],
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(countWinner, isNotNull);
      expect(countWinner!.categoryId, 'cat_b_count_wins');

      await db.delete(db.transactions).go();

      for (final categoryId in ['cat_b', 'cat_a']) {
        for (var i = 0; i < 3; i += 1) {
          await seedTx(
            id: '${categoryId}_tie_$i',
            categoryId: categoryId,
            joyFullness: 8,
          );
        }
      }

      final lexicalWinner = await dao.getSharedJoyCategoryInsight(
        bookIds: ['book_joy'],
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(lexicalWinner, isNotNull);
      expect(lexicalWinner!.categoryId, 'cat_a');
    });
  });
}
