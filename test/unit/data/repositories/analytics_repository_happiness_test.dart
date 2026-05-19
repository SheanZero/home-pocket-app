import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/daos/analytics_dao.dart';
import 'package:home_pocket/data/repositories/analytics_repository_impl.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsDao extends Mock implements AnalyticsDao {}

void main() {
  late _MockAnalyticsDao dao;
  late AnalyticsRepositoryImpl repository;

  final startDate = DateTime(2026, 5);
  final endDate = DateTime(2026, 5, 31, 23, 59, 59);

  setUp(() {
    dao = _MockAnalyticsDao();
    repository = AnalyticsRepositoryImpl(dao: dao);
  });

  group('AnalyticsRepositoryImpl happiness delegation', () {
    test('getBestJoyMoment returns the DAO row when present', () async {
      final expected = BestJoyMomentRow(
        transactionId: 'tx-best',
        amount: 3000,
        soulSatisfaction: 10,
        categoryId: 'cat-coffee',
        timestamp: DateTime(2026, 5, 20, 18, 30),
      );
      when(
        () => dao.getBestJoyMoment(
          bookId: 'book-1',
          startDate: startDate,
          endDate: endDate,
        ),
      ).thenAnswer((_) async => expected);

      final result = await repository.getBestJoyMoment(
        bookId: 'book-1',
        startDate: startDate,
        endDate: endDate,
      );

      expect(result, expected);
      verify(
        () => dao.getBestJoyMoment(
          bookId: 'book-1',
          startDate: startDate,
          endDate: endDate,
        ),
      ).called(1);
    });

    test('getBestJoyMoment returns null when DAO returns null', () async {
      when(
        () => dao.getBestJoyMoment(
          bookId: 'book-1',
          startDate: startDate,
          endDate: endDate,
        ),
      ).thenAnswer((_) async => null);

      final result = await repository.getBestJoyMoment(
        bookId: 'book-1',
        startDate: startDate,
        endDate: endDate,
      );

      expect(result, isNull);
      verify(
        () => dao.getBestJoyMoment(
          bookId: 'book-1',
          startDate: startDate,
          endDate: endDate,
        ),
      ).called(1);
    });

    test(
      'getSoulRowsForJoyContribution preserves DAO row order and values',
      () async {
        const rows = [
          SoulRowSample(amount: 500, soulSatisfaction: 6),
          SoulRowSample(amount: 1500, soulSatisfaction: 8),
          SoulRowSample(amount: 3000, soulSatisfaction: 10),
        ];
        when(
          () => dao.getSoulRowsForJoyContribution(
            bookId: 'book-1',
            startDate: startDate,
            endDate: endDate,
          ),
        ).thenAnswer((_) async => rows);

        final result = await repository.getSoulRowsForJoyContribution(
          bookId: 'book-1',
          startDate: startDate,
          endDate: endDate,
        );

        expect(result.length, 3);
        expect(result.map((row) => row.amount), [500, 1500, 3000]);
        expect(result.map((row) => row.soulSatisfaction), [6, 8, 10]);
        verify(
          () => dao.getSoulRowsForJoyContribution(
            bookId: 'book-1',
            startDate: startDate,
            endDate: endDate,
          ),
        ).called(1);
      },
    );

    test(
      'getSoulSatisfactionOverview maps DAO result to domain type',
      () async {
        when(
          () => dao.getSoulSatisfactionOverview(
            bookId: 'book-1',
            startDate: startDate,
            endDate: endDate,
          ),
        ).thenAnswer(
          (_) async =>
              const SatisfactionOverviewResult(avgSatisfaction: 7.5, count: 8),
        );

        final result = await repository.getSoulSatisfactionOverview(
          bookId: 'book-1',
          startDate: startDate,
          endDate: endDate,
        );

        expect(result.avgSatisfaction, 7.5);
        expect(result.count, 8);
        verify(
          () => dao.getSoulSatisfactionOverview(
            bookId: 'book-1',
            startDate: startDate,
            endDate: endDate,
          ),
        ).called(1);
      },
    );

    test(
      'getSatisfactionDistribution maps DAO buckets to domain buckets',
      () async {
        when(
          () => dao.getSatisfactionDistribution(
            bookId: 'book-1',
            startDate: startDate,
            endDate: endDate,
          ),
        ).thenAnswer(
          (_) async => const [
            SatisfactionDistributionResult(score: 6, count: 2),
            SatisfactionDistributionResult(score: 8, count: 3),
            SatisfactionDistributionResult(score: 10, count: 1),
          ],
        );

        final result = await repository.getSatisfactionDistribution(
          bookId: 'book-1',
          startDate: startDate,
          endDate: endDate,
        );

        expect(result.map((bucket) => bucket.score), [6, 8, 10]);
        expect(result.map((bucket) => bucket.count), [2, 3, 1]);
        verify(
          () => dao.getSatisfactionDistribution(
            bookId: 'book-1',
            startDate: startDate,
            endDate: endDate,
          ),
        ).called(1);
      },
    );

    test(
      'getSharedJoyCategoryInsight passes through null and row values',
      () async {
        final bookIds = ['book-1', 'book-2'];

        when(
          () => dao.getSharedJoyCategoryInsight(
            bookIds: bookIds,
            startDate: startDate,
            endDate: endDate,
          ),
        ).thenAnswer((_) async => null);

        final empty = await repository.getSharedJoyCategoryInsight(
          bookIds: bookIds,
          startDate: startDate,
          endDate: endDate,
        );

        expect(empty, isNull);

        when(
          () => dao.getSharedJoyCategoryInsight(
            bookIds: bookIds,
            startDate: startDate,
            endDate: endDate,
          ),
        ).thenAnswer(
          (_) async => const SharedJoyCategoryAggregate(
            categoryId: 'cat-coffee',
            avgSatisfaction: 8.5,
            totalCount: 4,
          ),
        );

        final result = await repository.getSharedJoyCategoryInsight(
          bookIds: bookIds,
          startDate: startDate,
          endDate: endDate,
        );

        expect(result, isNotNull);
        expect(result!.categoryId, 'cat-coffee');
        expect(result.avgSatisfaction, 8.5);
        expect(result.totalCount, 4);
        verify(
          () => dao.getSharedJoyCategoryInsight(
            bookIds: bookIds,
            startDate: startDate,
            endDate: endDate,
          ),
        ).called(2);
      },
    );
  });
}
