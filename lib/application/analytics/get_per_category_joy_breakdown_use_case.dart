import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/analytics/domain/models/metric_result.dart';
import '../../features/analytics/domain/models/per_category_joy_breakdown.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '_time_window_validation.dart';

/// HAPPY-V2-01 / D-07 / D-08 / D-10 — per-category joy satisfaction breakdown.
///
/// Single-book variant. Reads the domain-typed
/// `List<PerCategoryJoyBreakdownItem>` returned by the repository (the DAO
/// row tuple is converted at the impl boundary — the use case never imports
/// `lib/data/`, per CLAUDE.md Pitfall #2 and the layer-purity contract).
///
/// Owns the business rules between data and presentation:
/// - Min-N = 3 filter (D-08): categories with `totalCount < 3` collapse into a
///   single aggregate `Other` carried by [PerCategoryJoyBreakdown.otherCount]
///   and [PerCategoryJoyBreakdown.otherCategoryCount]. D-10: NO averaged
///   satisfaction across heterogeneous low-N categories — Other is plain ints.
/// - Defensive re-sort (D-07): `avg DESC, count DESC, categoryId ASC`. The DAO
///   already orders, but the use case re-sorts so a future DAO refactor cannot
///   silently regress the tie-break contract.
/// - Empty (D-09): only when there is literally no data in window — repo
///   returned `[]` OR every row was low-N and folded with zero counts. A
///   window with only sub-min-N data is still data; the card renders
///   "Other only" rather than the global empty state.
class GetPerCategoryJoyBreakdownUseCase {
  GetPerCategoryJoyBreakdownUseCase({
    required AnalyticsRepository analyticsRepository,
  }) : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  static const int _minN = 3;

  Future<MetricResult<PerCategoryJoyBreakdown>> execute({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    TimeWindowValidation.assertValid(startDate, endDate);

    final items = await _repo.getPerCategoryJoyBreakdown(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );

    return aggregatePerCategoryBreakdown(items);
  }
}

/// Shared partition + sort + Other-rollup for both the single-book and
/// across-books per-category use cases (DRY — both apply the same D-07/D-08/
/// D-09 business rules). Uses [GetPerCategoryJoyBreakdownUseCase] as the
/// canonical source of the min-N constant so the value is defined once.
MetricResult<PerCategoryJoyBreakdown> aggregatePerCategoryBreakdown(
  List<PerCategoryJoyBreakdownItem> items,
) {
  if (items.isEmpty) {
    return const Empty();
  }

  final minN = GetPerCategoryJoyBreakdownUseCase._minN;
  final qualifying = items
      .where((r) => r.totalCount >= minN)
      .toList(growable: false);
  final lowN = items.where((r) => r.totalCount < minN).toList(growable: false);

  // Defensive re-sort by D-07: avg DESC, count DESC, categoryId ASC.
  final sortedQualifying = [...qualifying]
    ..sort((a, b) {
      final byAvg = b.avgSatisfaction.compareTo(a.avgSatisfaction);
      if (byAvg != 0) return byAvg;
      final byCount = b.totalCount.compareTo(a.totalCount);
      if (byCount != 0) return byCount;
      return a.categoryId.compareTo(b.categoryId);
    });

  final otherCount = lowN.fold<int>(0, (acc, r) => acc + r.totalCount);
  final otherCategoryCount = lowN.length;
  final qualifyingSum = sortedQualifying.fold<int>(
    0,
    (acc, r) => acc + r.totalCount,
  );
  final totalCount = qualifyingSum + otherCount;

  if (sortedQualifying.isEmpty && otherCount == 0) {
    return const Empty();
  }

  return Value(
    PerCategoryJoyBreakdown(
      items: sortedQualifying,
      totalCount: totalCount,
      otherCount: otherCount,
      otherCategoryCount: otherCategoryCount,
    ),
    totalCount,
  );
}
