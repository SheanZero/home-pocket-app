import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/analytics/domain/models/best_joy_moment_row.dart';
import '../../features/analytics/domain/models/metric_result.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '_time_window_validation.dart';

/// HAPPY-04 / D-06 / D-17: standalone Top Joy use case.
///
/// Returns Empty when no soul tx exists in the window OR (defensively) when
/// the argmax query returns null. Returns Value(row, totalSoulTx) otherwise.
/// Phase 10 UI inspects `topJoy.data.soulSatisfaction <= 2` for the
/// "all neutral / go rate one" CTA — Phase 9 does not encode that logic.
class GetBestJoyMomentUseCase {
  GetBestJoyMomentUseCase({required AnalyticsRepository analyticsRepository})
    : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  Future<MetricResult<BestJoyMomentRow>> execute({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    TimeWindowValidation.assertValid(startDate, endDate);

    final overview = await _repo.getSoulSatisfactionOverview(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );

    if (overview.count == 0) return const Empty();

    final row = await _repo.getBestJoyMoment(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );

    if (row == null) return const Empty();
    return Value(row, overview.count);
  }
}
