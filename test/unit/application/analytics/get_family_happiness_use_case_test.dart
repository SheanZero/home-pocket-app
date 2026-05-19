import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_family_happiness_use_case.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/shared_joy_insight.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late _MockAnalyticsRepository repository;
  late GetFamilyHappinessUseCase useCase;

  final startDate = DateTime(2026, 4);
  final endDate = DateTime(2026, 4, 30, 23, 59, 59);

  setUp(() {
    repository = _MockAnalyticsRepository();
    useCase = GetFamilyHappinessUseCase(analyticsRepository: repository);
  });

  void stubOverview(String bookId, int count, {double avg = 0}) {
    when(
      () => repository.getSoulSatisfactionOverview(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
    ).thenAnswer(
      (_) async => SoulSatisfactionOverview(avgSatisfaction: avg, count: count),
    );
  }

  void stubDistribution(String bookId, List<SatisfactionScoreBucket> buckets) {
    when(
      () => repository.getSatisfactionDistribution(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
    ).thenAnswer((_) async => buckets);
  }

  void stubSharedJoy(
    List<String> bookIds,
    SharedJoyCategoryAggregate? aggregate,
  ) {
    when(
      () => repository.getSharedJoyCategoryInsight(
        bookIds: bookIds,
        startDate: startDate,
        endDate: endDate,
      ),
    ).thenAnswer((_) async => aggregate);
  }

  group('empty short-circuit', () {
    test(
      'empty bookIds returns all Empty metrics without repo calls',
      () async {
        final report = await useCase.execute(
          groupBookIds: const [],
          startDate: startDate,
          endDate: endDate,
        );

        expect(report.year, endDate.year);
        expect(report.month, endDate.month);
        expect(report.totalGroupSoulTx, 0);
        expect(report.familyHighlightsSum, isA<Empty<int>>());
        expect(report.sharedJoyInsight, isA<Empty<SharedJoyInsight>>());
        expect(report.medianSatisfaction, isA<Empty<double>>());
        verifyNever(
          () => repository.getSoulSatisfactionOverview(
            bookId: any(named: 'bookId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        );
        verifyNever(
          () => repository.getSatisfactionDistribution(
            bookId: any(named: 'bookId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        );
        verifyNever(
          () => repository.getSharedJoyCategoryInsight(
            bookIds: any(named: 'bookIds'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        );
      },
    );

    test('all zero-count overviews returns all Empty metrics', () async {
      final groupBookIds = ['b1', 'b2'];
      stubOverview('b1', 0);
      stubOverview('b2', 0);
      stubDistribution('b1', const []);
      stubDistribution('b2', const []);
      stubSharedJoy(groupBookIds, null);

      final report = await useCase.execute(
        groupBookIds: groupBookIds,
        startDate: startDate,
        endDate: endDate,
      );

      expect(report.totalGroupSoulTx, 0);
      expect(report.familyHighlightsSum, isA<Empty<int>>());
      expect(report.sharedJoyInsight, isA<Empty<SharedJoyInsight>>());
      expect(report.medianSatisfaction, isA<Empty<double>>());
    });
  });

  group('fan-out', () {
    test(
      'queries each book once and shared joy once with all bookIds',
      () async {
        final groupBookIds = ['b1', 'b2'];
        stubOverview('b1', 3, avg: 7);
        stubOverview('b2', 5, avg: 8);
        stubDistribution('b1', const [
          SatisfactionScoreBucket(score: 6, count: 3),
        ]);
        stubDistribution('b2', const [
          SatisfactionScoreBucket(score: 8, count: 5),
        ]);
        stubSharedJoy(
          groupBookIds,
          const SharedJoyCategoryAggregate(
            categoryId: 'cafe',
            avgSatisfaction: 8.2,
            totalCount: 4,
          ),
        );

        final report = await useCase.execute(
          groupBookIds: groupBookIds,
          startDate: startDate,
          endDate: endDate,
        );

        expect(report.totalGroupSoulTx, 8);
        verify(
          () => repository.getSoulSatisfactionOverview(
            bookId: 'b1',
            startDate: startDate,
            endDate: endDate,
          ),
        ).called(1);
        verify(
          () => repository.getSoulSatisfactionOverview(
            bookId: 'b2',
            startDate: startDate,
            endDate: endDate,
          ),
        ).called(1);
        verify(
          () => repository.getSatisfactionDistribution(
            bookId: 'b1',
            startDate: startDate,
            endDate: endDate,
          ),
        ).called(1);
        verify(
          () => repository.getSatisfactionDistribution(
            bookId: 'b2',
            startDate: startDate,
            endDate: endDate,
          ),
        ).called(1);
        verify(
          () => repository.getSharedJoyCategoryInsight(
            bookIds: groupBookIds,
            startDate: startDate,
            endDate: endDate,
          ),
        ).called(1);
      },
    );
  });

  group('FAMILY-01 highlights sum', () {
    test('aggregates sat >= 6 counts across all books as one int', () async {
      final groupBookIds = ['b1', 'b2'];
      stubOverview('b1', 4, avg: 7);
      stubOverview('b2', 4, avg: 6);
      stubDistribution('b1', const [
        SatisfactionScoreBucket(score: 6, count: 2),
        SatisfactionScoreBucket(score: 8, count: 1),
      ]);
      stubDistribution('b2', const [
        SatisfactionScoreBucket(score: 2, count: 3),
        SatisfactionScoreBucket(score: 10, count: 1),
      ]);
      stubSharedJoy(groupBookIds, null);

      final report = await useCase.execute(
        groupBookIds: groupBookIds,
        startDate: startDate,
        endDate: endDate,
      );

      final highlights = report.familyHighlightsSum as Value<int>;
      expect(highlights.data, 4);
      expect(highlights.sampleSize, 8);
    });

    test(
      'returns Value(0) when no highlight rows exist but sample is nonzero',
      () async {
        final groupBookIds = ['b1', 'b2'];
        stubOverview('b1', 3, avg: 2);
        stubOverview('b2', 5, avg: 4);
        stubDistribution('b1', const [
          SatisfactionScoreBucket(score: 2, count: 3),
        ]);
        stubDistribution('b2', const [
          SatisfactionScoreBucket(score: 4, count: 5),
        ]);
        stubSharedJoy(groupBookIds, null);

        final report = await useCase.execute(
          groupBookIds: groupBookIds,
          startDate: startDate,
          endDate: endDate,
        );

        final highlights = report.familyHighlightsSum as Value<int>;
        expect(highlights.data, 0);
        expect(highlights.sampleSize, 8);
      },
    );
  });

  group('FAMILY-02 shared joy insight', () {
    test(
      'wraps the cross-book shared joy category aggregate as a 3-tuple',
      () async {
        final groupBookIds = ['b1', 'b2'];
        stubOverview('b1', 3, avg: 7);
        stubOverview('b2', 5, avg: 8);
        stubDistribution('b1', const [
          SatisfactionScoreBucket(score: 6, count: 3),
        ]);
        stubDistribution('b2', const [
          SatisfactionScoreBucket(score: 8, count: 5),
        ]);
        stubSharedJoy(
          groupBookIds,
          const SharedJoyCategoryAggregate(
            categoryId: 'cafe',
            avgSatisfaction: 8.4,
            totalCount: 5,
          ),
        );

        final report = await useCase.execute(
          groupBookIds: groupBookIds,
          startDate: startDate,
          endDate: endDate,
        );

        final sharedJoy = report.sharedJoyInsight as Value<SharedJoyInsight>;
        expect(sharedJoy.sampleSize, 8);
        expect(sharedJoy.data.categoryId, 'cafe');
        expect(sharedJoy.data.avgSatisfaction, 8.4);
        expect(sharedJoy.data.totalCount, 5);
      },
    );

    test('returns Empty shared joy when no category reaches min-N=3', () async {
      final groupBookIds = ['b1', 'b2'];
      stubOverview('b1', 3, avg: 7);
      stubOverview('b2', 5, avg: 8);
      stubDistribution('b1', const [
        SatisfactionScoreBucket(score: 6, count: 3),
      ]);
      stubDistribution('b2', const [
        SatisfactionScoreBucket(score: 8, count: 5),
      ]);
      stubSharedJoy(groupBookIds, null);

      final report = await useCase.execute(
        groupBookIds: groupBookIds,
        startDate: startDate,
        endDate: endDate,
      );

      expect(report.sharedJoyInsight, isA<Empty<SharedJoyInsight>>());
      expect(report.familyHighlightsSum, isA<Value<int>>());
      expect(report.medianSatisfaction, isA<Value<double>>());
    });
  });

  group('group median', () {
    test('computes median from the combined group distribution', () async {
      final groupBookIds = ['b1', 'b2'];
      stubOverview('b1', 3, avg: 6);
      stubOverview('b2', 5, avg: 8);
      stubDistribution('b1', const [
        SatisfactionScoreBucket(score: 6, count: 3),
      ]);
      stubDistribution('b2', const [
        SatisfactionScoreBucket(score: 8, count: 4),
        SatisfactionScoreBucket(score: 10, count: 1),
      ]);
      stubSharedJoy(groupBookIds, null);

      final report = await useCase.execute(
        groupBookIds: groupBookIds,
        startDate: startDate,
        endDate: endDate,
      );

      final median = report.medianSatisfaction as Value<double>;
      expect(median.data, 8);
      expect(median.sampleSize, 8);
    });
  });

  group('anti-leaderboard contract', () {
    test('contract: no per-member fields in family return types '
        '(anti-leaderboard)', () {
      const filesToScan = [
        'lib/features/analytics/domain/models/family_happiness.dart',
        'lib/features/analytics/domain/models/shared_joy_insight.dart',
        'lib/application/analytics/get_family_happiness_use_case.dart',
      ];
      final forbiddenPatterns = [
        RegExp(r'Map<\s*\w*MemberId\w*\s*,'),
        RegExp(r'Map<\s*String\s*,\s*(int|double|String)\s*>'),
        RegExp(r'\bmemberId\s*[:;]'),
        RegExp(r'\bdeviceId\s*[:;]'),
        RegExp(r'\bmemberDisplayName\s*[:;]'),
      ];

      for (final path in filesToScan) {
        final contents = File(path).readAsStringSync();
        for (final pattern in forbiddenPatterns) {
          expect(
            pattern.hasMatch(contents),
            isFalse,
            reason:
                '$path contains forbidden family leaderboard pattern '
                '$pattern',
          );
        }
      }
    });
  });

  group('time window validation', () {
    test('throws ArgumentError when start > end', () async {
      expect(
        () => useCase.execute(
          groupBookIds: const ['book-1'],
          startDate: DateTime(2026, 5, 31),
          endDate: DateTime(2026, 5),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when range exceeds 12 months', () async {
      expect(
        () => useCase.execute(
          groupBookIds: const ['book-1'],
          startDate: DateTime(2024, 5),
          endDate: DateTime(2025, 6),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when endDate is in the future', () async {
      expect(
        () => useCase.execute(
          groupBookIds: const ['book-1'],
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 2)),
        ),
        throwsArgumentError,
      );
    });
  });
}
