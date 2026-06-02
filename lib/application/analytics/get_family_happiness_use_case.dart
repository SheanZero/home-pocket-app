import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/models/family_happiness.dart';
import '../../features/analytics/domain/models/metric_result.dart';
import '../../features/analytics/domain/models/shared_joy_insight.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '_time_window_validation.dart';

/// Family happiness aggregate use case (FAMILY-01 + FAMILY-02 + group median).
///
/// Per D-09, callers pass `groupBookIds`; presentation owns shadow-book
/// resolution and this use case stays free of provider or member metadata.
///
/// Type-system contract (D-07 / D-08 / T-9-04): no per-member fields, ever.
class GetFamilyHappinessUseCase {
  GetFamilyHappinessUseCase({required AnalyticsRepository analyticsRepository})
    : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  /// D-05 / D-07: family highlights threshold sat >= 6.
  static const int _highlightsThreshold = 6;

  Future<FamilyHappiness> execute({
    required List<String> groupBookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    TimeWindowValidation.assertValid(startDate, endDate);

    // D-09 + D-16: empty short-circuit with no repository calls.
    if (groupBookIds.isEmpty) {
      return FamilyHappiness(
        year: endDate.year,
        month: endDate.month,
        totalGroupJoyTx: 0,
        familyHighlightsSum: const Empty(),
        sharedJoyInsight: const Empty(),
        medianSatisfaction: const Empty(),
      );
    }

    final overviews = await Future.wait(
      groupBookIds.map(
        (id) => _repo.getJoyFullnessOverview(
          bookId: id,
          startDate: startDate,
          endDate: endDate,
          entrySourceFilter: entrySourceFilter,
        ),
      ),
    );
    final distributions = await Future.wait(
      groupBookIds.map(
        (id) => _repo.getSatisfactionDistribution(
          bookId: id,
          startDate: startDate,
          endDate: endDate,
          entrySourceFilter: entrySourceFilter,
        ),
      ),
    );
    final sharedJoyAgg = await _repo.getSharedJoyCategoryInsight(
      bookIds: groupBookIds,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );

    final totalGroupJoyTx = overviews.fold<int>(
      0,
      (sum, overview) => sum + overview.count,
    );

    // D-16 family alignment: zero group sample means all main metrics Empty.
    if (totalGroupJoyTx == 0) {
      return FamilyHappiness(
        year: endDate.year,
        month: endDate.month,
        totalGroupJoyTx: 0,
        familyHighlightsSum: const Empty(),
        sharedJoyInsight: const Empty(),
        medianSatisfaction: const Empty(),
      );
    }

    final highlightsSum = _aggregateHighlights(distributions);
    final groupMedian = _computeMedianFromDistribution(
      _combineDistributions(distributions),
    );
    final MetricResult<SharedJoyInsight> sharedJoyResult = sharedJoyAgg == null
        ? const Empty()
        : Value(
            SharedJoyInsight(
              categoryId: sharedJoyAgg.categoryId,
              avgSatisfaction: sharedJoyAgg.avgSatisfaction,
              totalCount: sharedJoyAgg.totalCount,
            ),
            totalGroupJoyTx,
          );

    return FamilyHappiness(
      year: endDate.year,
      month: endDate.month,
      totalGroupJoyTx: totalGroupJoyTx,
      familyHighlightsSum: Value(highlightsSum, totalGroupJoyTx),
      sharedJoyInsight: sharedJoyResult,
      medianSatisfaction: Value(groupMedian, totalGroupJoyTx),
    );
  }

  /// D-07: aggregate count of sat>=6 across all books as one int.
  int _aggregateHighlights(List<List<SatisfactionScoreBucket>> distributions) {
    var count = 0;
    for (final distribution in distributions) {
      for (final bucket in distribution) {
        if (bucket.score >= _highlightsThreshold) {
          count += bucket.count;
        }
      }
    }
    return count;
  }

  List<SatisfactionScoreBucket> _combineDistributions(
    List<List<SatisfactionScoreBucket>> distributions,
  ) {
    final combined = <int, int>{};
    for (final distribution in distributions) {
      for (final bucket in distribution) {
        combined[bucket.score] = (combined[bucket.score] ?? 0) + bucket.count;
      }
    }

    final scores = combined.keys.toList()..sort();
    return [
      for (final score in scores)
        SatisfactionScoreBucket(score: score, count: combined[score]!),
    ];
  }

  /// Same distribution-walk algorithm as the personal happiness use case.
  double _computeMedianFromDistribution(List<SatisfactionScoreBucket> dist) {
    final total = dist.fold<int>(0, (sum, bucket) => sum + bucket.count);
    if (total == 0) {
      return 0;
    }

    final isEven = total % 2 == 0;
    final midIndex = total ~/ 2;
    var cumulative = 0;
    int? lower;

    for (final bucket in dist) {
      cumulative += bucket.count;
      if (lower == null && cumulative > (isEven ? midIndex - 1 : midIndex)) {
        lower = bucket.score;
      }
      if (cumulative > midIndex) {
        return isEven ? (lower! + bucket.score) / 2.0 : bucket.score.toDouble();
      }
    }

    return 0;
  }
}
