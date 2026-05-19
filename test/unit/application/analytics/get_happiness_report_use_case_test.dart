import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_happiness_report_use_case.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:home_pocket/features/analytics/domain/models/happiness_report.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late _MockAnalyticsRepository repository;
  late GetHappinessReportUseCase useCase;

  final startDate = DateTime(2026, 5);
  final endDate = DateTime(2026, 5, 31, 23, 59, 59);

  setUp(() {
    repository = _MockAnalyticsRepository();
    useCase = GetHappinessReportUseCase(analyticsRepository: repository);
  });

  void stubReportInputs({
    required SoulSatisfactionOverview overview,
    required List<SatisfactionScoreBucket> distribution,
    required List<SoulRowSample> ptvfRows,
    BestJoyMomentRow? bestJoyMoment,
  }) {
    when(
      () => repository.getSoulSatisfactionOverview(
        bookId: 'book-1',
        startDate: startDate,
        endDate: endDate,
      ),
    ).thenAnswer((_) async => overview);
    when(
      () => repository.getSatisfactionDistribution(
        bookId: 'book-1',
        startDate: startDate,
        endDate: endDate,
      ),
    ).thenAnswer((_) async => distribution);
    when(
      () => repository.getSoulRowsForJoyContribution(
        bookId: 'book-1',
        startDate: startDate,
        endDate: endDate,
      ),
    ).thenAnswer((_) async => ptvfRows);
    when(
      () => repository.getBestJoyMoment(
        bookId: 'book-1',
        startDate: startDate,
        endDate: endDate,
      ),
    ).thenAnswer((_) async => bestJoyMoment);
  }

  Future<Value<T>> valueMetric<T>(MetricResult<T> result) async {
    expect(result, isA<Value<T>>());
    return result as Value<T>;
  }

  Future<Empty<T>> emptyMetric<T>(MetricResult<T> result) async {
    expect(result, isA<Empty<T>>());
    return result as Empty<T>;
  }

  Future<HappinessReport> execute({String currencyCode = 'JPY'}) {
    return useCase.execute(
      bookId: 'book-1',
      year: 2026,
      month: 5,
      currencyCode: currencyCode,
    );
  }

  group('empty (n=0)', () {
    test('overview count zero returns Empty() for all five metrics', () async {
      stubReportInputs(
        overview: const SoulSatisfactionOverview(avgSatisfaction: 0, count: 0),
        distribution: const [],
        ptvfRows: const [],
      );

      final report = await execute();

      expect(report.totalSoulTx, 0);
      await emptyMetric<double>(report.avgSatisfaction);
      await emptyMetric<double>(report.joyContribution);
      await emptyMetric<double>(report.medianSatisfaction);
      await emptyMetric<int>(report.highlightsCount);
      await emptyMetric<BestJoyMomentRow>(report.topJoy);
    });
  });

  group('Avg Satisfaction (HAPPY-01)', () {
    test('overview average and count become Value sample', () async {
      stubReportInputs(
        overview: const SoulSatisfactionOverview(
          avgSatisfaction: 8.5,
          count: 4,
        ),
        distribution: const [SatisfactionScoreBucket(score: 8, count: 4)],
        ptvfRows: const [SoulRowSample(amount: 1000, soulSatisfaction: 8)],
      );

      final report = await execute();
      final avg = await valueMetric<double>(report.avgSatisfaction);

      expect(avg.data, 8.5);
      expect(avg.sampleSize, 4);
    });
  });

  group('Joy contribution (ADR-016 / HAPPY-02)', () {
    test('single JPY row uses alpha 0.88 and base 500', () async {
      stubReportInputs(
        overview: const SoulSatisfactionOverview(avgSatisfaction: 8, count: 1),
        distribution: const [SatisfactionScoreBucket(score: 8, count: 1)],
        ptvfRows: const [SoulRowSample(amount: 3000, soulSatisfaction: 8)],
      );

      final report = await execute();
      final joy = await valueMetric<double>(report.joyContribution);

      final expected = 8 * math.pow(3000 / 500, 0.88);
      expect(joy.data, closeTo(expected, 0.0001));
      expect(joy.sampleSize, 1);
    });

    test(
      'mixed JPY rows sum contribution without amount denominator',
      () async {
        stubReportInputs(
          overview: const SoulSatisfactionOverview(
            avgSatisfaction: 8,
            count: 2,
          ),
          distribution: const [
            SatisfactionScoreBucket(score: 6, count: 1),
            SatisfactionScoreBucket(score: 10, count: 1),
          ],
          ptvfRows: const [
            SoulRowSample(amount: 10000, soulSatisfaction: 10),
            SoulRowSample(amount: 500, soulSatisfaction: 6),
          ],
        );

        final report = await execute();
        final joy = await valueMetric<double>(report.joyContribution);

        final expected =
            10 * math.pow(10000 / 500, 0.88) + 6 * math.pow(500 / 500, 0.88);
        expect(joy.data, closeTo(expected, 0.0001));
      },
    );

    test(
      'all post-migration default sat 2 rows compute non-zero contribution',
      () async {
        stubReportInputs(
          overview: const SoulSatisfactionOverview(
            avgSatisfaction: 2,
            count: 2,
          ),
          distribution: const [SatisfactionScoreBucket(score: 2, count: 2)],
          ptvfRows: const [
            SoulRowSample(amount: 1000, soulSatisfaction: 2),
            SoulRowSample(amount: 2000, soulSatisfaction: 2),
          ],
        );

        final report = await execute();
        final joy = await valueMetric<double>(report.joyContribution);

        expect(joy.data, isNonZero);
        expect(joy.data.isNaN, isFalse);
      },
    );

    test(
      'all sat 10 rows keep high-amount row dominant under alpha less than 1',
      () async {
        stubReportInputs(
          overview: const SoulSatisfactionOverview(
            avgSatisfaction: 10,
            count: 2,
          ),
          distribution: const [SatisfactionScoreBucket(score: 10, count: 2)],
          ptvfRows: const [
            SoulRowSample(amount: 500, soulSatisfaction: 10),
            SoulRowSample(amount: 10000, soulSatisfaction: 10),
          ],
        );

        final report = await execute();
        final joy = await valueMetric<double>(report.joyContribution);
        final highAmountContribution = 10 * math.pow(10000 / 500, 0.88);
        final lowAmountContribution = 10 * math.pow(500 / 500, 0.88);

        expect(highAmountContribution, greaterThan(lowAmountContribution));
        expect(
          joy.data,
          closeTo(highAmountContribution + lowAmountContribution, 0.0001),
        );
      },
    );

    test(
      'JPY and CNY bases produce contributions with base ratio direction',
      () async {
        stubReportInputs(
          overview: const SoulSatisfactionOverview(
            avgSatisfaction: 8,
            count: 1,
          ),
          distribution: const [SatisfactionScoreBucket(score: 8, count: 1)],
          ptvfRows: const [SoulRowSample(amount: 1000, soulSatisfaction: 8)],
        );

        final jpy = await execute(currencyCode: 'JPY');
        final cny = await execute(currencyCode: 'CNY');
        final jpyJoy = await valueMetric<double>(jpy.joyContribution);
        final cnyJoy = await valueMetric<double>(cny.joyContribution);

        expect(cnyJoy.data, greaterThan(jpyJoy.data));
        expect(
          cnyJoy.data / jpyJoy.data,
          closeTo(math.pow(500 / 25, 0.88), 0.0001),
        );
      },
    );

    test('EUR falls back to JPY base without throwing', () async {
      stubReportInputs(
        overview: const SoulSatisfactionOverview(avgSatisfaction: 7, count: 1),
        distribution: const [SatisfactionScoreBucket(score: 7, count: 1)],
        ptvfRows: const [SoulRowSample(amount: 1000, soulSatisfaction: 7)],
      );

      final jpy = await execute(currencyCode: 'JPY');
      final eur = await execute(currencyCode: 'EUR');
      final jpyJoy = await valueMetric<double>(jpy.joyContribution);
      final eurJoy = await valueMetric<double>(eur.joyContribution);

      expect(eurJoy.data, closeTo(jpyJoy.data, 0.0001));
    });

    test('uses repository-filtered PTVF soul rows only', () async {
      stubReportInputs(
        overview: const SoulSatisfactionOverview(avgSatisfaction: 8, count: 1),
        distribution: const [SatisfactionScoreBucket(score: 8, count: 1)],
        // Survival rows are excluded upstream by the DAO/repository contract.
        ptvfRows: const [SoulRowSample(amount: 3000, soulSatisfaction: 8)],
      );

      final report = await execute();
      final joy = await valueMetric<double>(report.joyContribution);
      final expected = 8 * math.pow(3000 / 500, 0.88);

      expect(joy.data, closeTo(expected, 0.0001));
      verify(
        () => repository.getSoulRowsForJoyContribution(
          bookId: 'book-1',
          startDate: startDate,
          endDate: endDate,
        ),
      ).called(1);
    });
  });

  group('Highlights count (HAPPY-03 / D-05)', () {
    test('counts all satisfaction buckets at sat six or higher', () async {
      stubReportInputs(
        overview: const SoulSatisfactionOverview(avgSatisfaction: 6, count: 7),
        distribution: const [
          SatisfactionScoreBucket(score: 2, count: 3),
          SatisfactionScoreBucket(score: 6, count: 2),
          SatisfactionScoreBucket(score: 8, count: 1),
          SatisfactionScoreBucket(score: 10, count: 1),
        ],
        ptvfRows: const [SoulRowSample(amount: 1000, soulSatisfaction: 6)],
      );

      final report = await execute();
      final highlights = await valueMetric<int>(report.highlightsCount);

      expect(highlights.data, 4);
      expect(highlights.sampleSize, 7);
    });

    test(
      'all satisfaction buckets at sat five or lower produce zero value',
      () async {
        stubReportInputs(
          overview: const SoulSatisfactionOverview(
            avgSatisfaction: 3,
            count: 4,
          ),
          distribution: const [
            SatisfactionScoreBucket(score: 2, count: 2),
            SatisfactionScoreBucket(score: 4, count: 1),
            SatisfactionScoreBucket(score: 5, count: 1),
          ],
          ptvfRows: const [SoulRowSample(amount: 1000, soulSatisfaction: 2)],
        );

        final report = await execute();
        final highlights = await valueMetric<int>(report.highlightsCount);

        expect(highlights.data, 0);
        expect(highlights.sampleSize, 4);
      },
    );
  });

  group('Median (D-15)', () {
    test(
      'odd distribution count walks cumulative buckets to median score',
      () async {
        stubReportInputs(
          overview: const SoulSatisfactionOverview(
            avgSatisfaction: 5.2,
            count: 5,
          ),
          distribution: const [
            SatisfactionScoreBucket(score: 2, count: 2),
            SatisfactionScoreBucket(score: 6, count: 2),
            SatisfactionScoreBucket(score: 10, count: 1),
          ],
          ptvfRows: const [SoulRowSample(amount: 1000, soulSatisfaction: 6)],
        );

        final report = await execute();
        final median = await valueMetric<double>(report.medianSatisfaction);

        expect(median.data, 6);
      },
    );

    test(
      'even distribution count averages lower and upper median scores',
      () async {
        stubReportInputs(
          overview: const SoulSatisfactionOverview(
            avgSatisfaction: 4,
            count: 4,
          ),
          distribution: const [
            SatisfactionScoreBucket(score: 2, count: 2),
            SatisfactionScoreBucket(score: 6, count: 2),
          ],
          ptvfRows: const [SoulRowSample(amount: 1000, soulSatisfaction: 6)],
        );

        final report = await execute();
        final median = await valueMetric<double>(report.medianSatisfaction);

        expect(median.data, 4);
      },
    );
  });

  group('Top Joy (HAPPY-04)', () {
    test(
      'null best joy row returns Empty even when overview has count',
      () async {
        stubReportInputs(
          overview: const SoulSatisfactionOverview(
            avgSatisfaction: 7,
            count: 2,
          ),
          distribution: const [SatisfactionScoreBucket(score: 7, count: 2)],
          ptvfRows: const [SoulRowSample(amount: 1000, soulSatisfaction: 7)],
        );

        final report = await execute();

        await emptyMetric<BestJoyMomentRow>(report.topJoy);
      },
    );

    test('best joy row becomes Value when overview has count', () async {
      final row = BestJoyMomentRow(
        transactionId: 'tx-best',
        amount: 3000,
        soulSatisfaction: 10,
        categoryId: 'cat-book',
        timestamp: DateTime(2026, 5, 20, 12),
      );
      stubReportInputs(
        overview: const SoulSatisfactionOverview(avgSatisfaction: 10, count: 1),
        distribution: const [SatisfactionScoreBucket(score: 10, count: 1)],
        ptvfRows: const [SoulRowSample(amount: 3000, soulSatisfaction: 10)],
        bestJoyMoment: row,
      );

      final report = await execute();
      final topJoy = await valueMetric<BestJoyMomentRow>(report.topJoy);

      expect(topJoy.data, row);
      expect(topJoy.sampleSize, 1);
    });
  });

  group('sample size alignment (D-16)', () {
    test('every Value sampleSize equals overview count', () async {
      final row = BestJoyMomentRow(
        transactionId: 'tx-best',
        amount: 3000,
        soulSatisfaction: 10,
        categoryId: 'cat-book',
        timestamp: DateTime(2026, 5, 20, 12),
      );
      stubReportInputs(
        overview: const SoulSatisfactionOverview(
          avgSatisfaction: 8.5,
          count: 4,
        ),
        distribution: const [
          SatisfactionScoreBucket(score: 6, count: 2),
          SatisfactionScoreBucket(score: 8, count: 1),
          SatisfactionScoreBucket(score: 10, count: 1),
        ],
        ptvfRows: const [
          SoulRowSample(amount: 1000, soulSatisfaction: 6),
          SoulRowSample(amount: 2000, soulSatisfaction: 8),
          SoulRowSample(amount: 3000, soulSatisfaction: 10),
        ],
        bestJoyMoment: row,
      );

      final report = await execute();

      expect((report.avgSatisfaction as Value<double>).sampleSize, 4);
      expect((report.joyContribution as Value<double>).sampleSize, 4);
      expect((report.medianSatisfaction as Value<double>).sampleSize, 4);
      expect((report.highlightsCount as Value<int>).sampleSize, 4);
      expect((report.topJoy as Value<BestJoyMomentRow>).sampleSize, 4);
    });
  });
}
