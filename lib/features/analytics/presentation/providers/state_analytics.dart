import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/utils/date_boundaries.dart';
import '../../../accounting/domain/models/entry_source.dart';
import '../../domain/models/analytics_aggregate.dart';
import '../../domain/models/category_drill_down.dart';
import '../../domain/models/expense_trend.dart';
import '../../domain/models/monthly_report.dart';
import 'repository_providers.dart';
import 'state_joy_metric_variant.dart';

part 'state_analytics.g.dart';

/// Monthly report for the selected window.
@riverpod
Future<MonthlyReport> monthlyReport(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getMonthlyReportUseCaseProvider);
  // D-15: manualOnly variant filters all AnalyticsScreen cards; HomeHero providers do NOT read this provider.
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual
      : null;
  return useCase.execute(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    entrySourceFilter: entrySourceFilter,
  );
}

/// 6-month expense trend.
@riverpod
Future<ExpenseTrendData> expenseTrend(
  Ref ref, {
  required String bookId,
  required DateTime anchor,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getExpenseTrendUseCaseProvider);
  // D-15: manualOnly variant filters all AnalyticsScreen cards; HomeHero providers do NOT read this provider.
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual
      : null;
  return useCase.execute(
    bookId: bookId,
    anchor: anchor,
    entrySourceFilter: entrySourceFilter,
  );
}

/// DRILL-01 / D-11, D-12, D-14, GUARD-01: drill-down for one tapped L1 category
/// over the active analytics window.
///
/// Flat-lists all transactions in [l1CategoryId] (including every L2 child) for
/// the window, with a neutral subtotal/count summary sourced from Plan 01's
/// shared rollup (so the header == the donut slice).
///
/// D-12: callers MUST pass window-normalized [startDate]/[endDate] (the analytics
/// shell already holds a normalized TimeWindow). Raw `DateTime.now()` microseconds
/// would explode the family key and cause a rebuild storm. This provider defends
/// the contract by re-normalizing the bounds via [DateBoundaries] before they
/// reach the use case — never accept microsecond-exact instants into the key.
///
/// Auto-dispose (the @riverpod default here, never kept alive — D-14) and reads
/// / invalidates ZERO `home/*` providers (GUARD-01, structurally locked by
/// home_screen_isolation_test.dart).
@riverpod
Future<CategoryDrillDown> categoryDrillDown(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  required String l1CategoryId,
}) async {
  final useCase = ref.watch(getCategoryDrillDownUseCaseProvider);
  // D-12 defensive normalization: collapse the window to whole-day closed
  // bounds so two callers with differing sub-day precision share one cache key.
  final start = DateBoundaries.dayRange(startDate).start;
  final end = DateBoundaries.dayRange(endDate).end;
  return useCase.execute(
    bookIds: [bookId],
    startDate: start,
    endDate: end,
    l1CategoryId: l1CategoryId,
  );
}

/// Earliest month with a non-deleted transaction in the active book.
@riverpod
Future<DateTime?> earliestTransactionMonth(
  Ref ref, {
  required String bookId,
}) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final timestamp = await repository.getEarliestTransactionTimestamp(
    bookId: bookId,
  );
  if (timestamp == null) {
    return null;
  }
  return DateTime(timestamp.year, timestamp.month);
}

/// Satisfaction score distribution for the selected window.
@riverpod
Future<List<SatisfactionScoreBucket>> satisfactionDistribution(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getSatisfactionDistributionUseCaseProvider);
  // D-15: manualOnly variant filters all AnalyticsScreen cards; HomeHero providers do NOT read this provider.
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual
      : null;
  return useCase.execute(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    entrySourceFilter: entrySourceFilter,
  );
}
