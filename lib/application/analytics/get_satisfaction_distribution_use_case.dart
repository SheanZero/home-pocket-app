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
  }) {
    TimeWindowValidation.assertValid(startDate, endDate);
    return _repo.getSatisfactionDistribution(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
