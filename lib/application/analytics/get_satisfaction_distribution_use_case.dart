import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';

/// STATSUI-02 / D-05 — satisfaction score buckets for the selected month.
class GetSatisfactionDistributionUseCase {
  GetSatisfactionDistributionUseCase({
    required AnalyticsRepository analyticsRepository,
  }) : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  Future<List<SatisfactionScoreBucket>> execute({
    required String bookId,
    required int year,
    required int month,
  }) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    return _repo.getSatisfactionDistribution(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
