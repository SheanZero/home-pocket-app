import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '_time_window_validation.dart';

/// STATSUI-02 / D-05 — satisfaction score buckets for the selected month.
class GetSatisfactionDistributionUseCase {
  GetSatisfactionDistributionUseCase({
    required AnalyticsRepository analyticsRepository,
  }) : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  Future<List<SatisfactionScoreBucket>> execute({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    TimeWindowValidation.assertValid(startDate, endDate);
    return _repo.getSatisfactionDistribution(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );
  }

  /// Combines score buckets across the active family's separate books.
  Future<List<SatisfactionScoreBucket>> executeAcrossBooks({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    TimeWindowValidation.assertValid(startDate, endDate);
    final distributions = await Future.wait(
      bookIds.toSet().map(
        (bookId) => _repo.getSatisfactionDistribution(
          bookId: bookId,
          startDate: startDate,
          endDate: endDate,
          entrySourceFilter: entrySourceFilter,
        ),
      ),
    );

    final countByScore = <int, int>{};
    for (final distribution in distributions) {
      for (final bucket in distribution) {
        countByScore[bucket.score] =
            (countByScore[bucket.score] ?? 0) + bucket.count;
      }
    }
    return countByScore.entries
        .map(
          (entry) =>
              SatisfactionScoreBucket(score: entry.key, count: entry.value),
        )
        .toList(growable: false)
      ..sort((a, b) => a.score.compareTo(b.score));
  }
}
