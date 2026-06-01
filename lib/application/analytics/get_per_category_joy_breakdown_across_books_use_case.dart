import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/analytics/domain/models/metric_result.dart';
import '../../features/analytics/domain/models/per_category_joy_breakdown.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '_time_window_validation.dart';
import 'get_per_category_joy_breakdown_use_case.dart'
    show aggregatePerCategoryBreakdown;

/// HAPPY-V2-01 / D-16 / D-17 — family-aggregate per-category joy breakdown.
///
/// Group-mode variant: pools all member books with `book_id IN (...)` at the
/// repository layer (NEVER per-member group per ADR-012 §6). Applies the same
/// min-N/Other rollup and D-07 sort as the single-book use case via the shared
/// [aggregatePerCategoryBreakdown] helper.
///
/// D-16 + D-20 defense in depth: an empty `groupBookIds` list short-circuits
/// to `Empty()` and never calls the repository — the provider layer (Plan 06)
/// enforces this gate too, but the use case is the last line of defense
/// against malformed input.
class GetPerCategoryJoyBreakdownAcrossBooksUseCase {
  GetPerCategoryJoyBreakdownAcrossBooksUseCase({
    required AnalyticsRepository analyticsRepository,
  }) : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  Future<MetricResult<PerCategoryJoyBreakdown>> execute({
    required List<String> groupBookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    TimeWindowValidation.assertValid(startDate, endDate);

    if (groupBookIds.isEmpty) {
      return const Empty();
    }

    final items = await _repo.getPerCategoryJoyBreakdownAcrossBooks(
      bookIds: groupBookIds,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );

    return aggregatePerCategoryBreakdown(items);
  }
}
