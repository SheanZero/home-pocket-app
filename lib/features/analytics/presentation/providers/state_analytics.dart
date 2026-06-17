import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/utils/date_boundaries.dart';
import '../../../accounting/domain/models/entry_source.dart';
import '../../domain/models/analytics_aggregate.dart';
import '../../domain/models/category_drill_down.dart';
import '../../domain/models/monthly_report.dart';
import '../../domain/models/within_month_cumulative_trend.dart';
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

/// OVW-02 / D-E1: within-month per-day-cumulative spend trend.
///
/// Drives round-5 B's spend-trend LineChart: per-ledger (total/daily/joy)
/// running cumulative within the current month, plus a previous-month reference
/// line for the spend side (total/daily). The joy side is current-month-only —
/// there is no previous-month joy series (D-E1, ADR-012 zero joy cross-period).
/// Replaces the deleted 6-month `expenseTrend` provider (D-E2).
///
/// D-12: keyed on a MONTH-anchored [anchor] (DateTime(year, month)), NOT raw
/// instants — the use case derives the 2-month window from the month, so a
/// microsecond-exact key would explode the family cache. The shell normalizes
/// the anchor (see analytics_card_registry.dart trendAnchor) before it reaches
/// here; this provider defends the contract by re-anchoring to month precision.
///
/// Auto-dispose (the @riverpod default, never kept alive — D-14) and reads /
/// invalidates ZERO `home/*` providers (GUARD-01).
@riverpod
Future<WithinMonthCumulativeTrend> withinMonthCumulativeTrend(
  Ref ref, {
  required String bookId,
  required DateTime anchor,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getWithinMonthCumulativeUseCaseProvider);
  // D-15: manualOnly variant filters all AnalyticsScreen cards; HomeHero providers do NOT read this provider.
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual
      : null;
  // D-12 defensive normalization: collapse to month precision so two callers
  // with differing sub-day/day precision share one cache key.
  final monthAnchor = DateTime(anchor.year, anchor.month);
  return useCase.execute(
    bookIds: [bookId],
    monthAnchor: monthAnchor,
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
