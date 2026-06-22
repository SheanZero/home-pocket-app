import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/utils/date_boundaries.dart';
import '../../../../shared/constants/sort_config.dart';
import '../../../accounting/domain/models/category.dart';
import '../../../accounting/domain/models/entry_source.dart';
import '../../../accounting/domain/models/transaction.dart';
import '../../../accounting/presentation/providers/repository_providers.dart';
import '../../domain/models/analytics_aggregate.dart';
import '../../domain/models/category_drill_down.dart';
import '../../domain/models/joy_category_amount.dart';
import '../../domain/models/member_spend_breakdown.dart';
import '../../domain/models/monthly_report.dart';
import '../../domain/models/per_day_joy_count.dart';
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
  // The provider is the ONLY production caller that injects the real clock
  // (D-5): "today" / the carry-forward right edge lives in the use case, never
  // in the chart widget (golden determinism). Use-case tests pass an explicit
  // `now`.
  return useCase.execute(
    bookIds: [bookId],
    monthAnchor: monthAnchor,
    now: DateTime.now(),
    entrySourceFilter: entrySourceFilter,
  );
}

/// STATSUI-DONUT-MEMBER / D2: category breakdown restricted to ONE member's
/// (deviceId) expense transactions over the active window — the donut's 分类
/// dimension WHEN a member filter is active (genuinely-functional global
/// narrowing: pick a member, see their category split).
///
/// Returns a [MemberFilteredCategoryBreakdown] carrying minimal
/// [CategoryBreakdown] rows (categoryId/amount/transactionCount — name/icon/color/
/// percentage are placeholders; `DonutHero` re-resolves the localized name from
/// the id and re-computes percentages off the true total) plus the member's
/// total + entry count for the center figure.
///
/// Reuses `findByBookIds` (both ledgers) over the normalized window, Dart-side
/// filtered to expense rows recorded by [deviceId]. No new DAO/migration (v21).
///
/// D-12 normalized window; auto-dispose; zero `home/*` (GUARD-01).
@riverpod
Future<MemberFilteredCategoryBreakdown> memberFilteredCategoryBreakdown(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  required String deviceId,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual
      : null;
  final start = DateBoundaries.dayRange(startDate).start;
  final end = DateBoundaries.dayRange(endDate).end;
  final txns = await repository.findByBookIds(
    [bookId],
    ledgerType: null,
    categoryId: null,
    startDate: start,
    endDate: end,
    sortField: SortField.timestamp,
    sortDirection: SortDirection.desc,
  );
  // Expense rows recorded by the chosen member only.
  final memberTxns = txns.where(
    (tx) =>
        tx.type == TransactionType.expense &&
        tx.deviceId == deviceId &&
        (entrySourceFilter == null || tx.entrySource == entrySourceFilter),
  );
  // Aggregate by leaf categoryId (DonutHero rolls these up to L1 itself).
  final amountByCat = <String, int>{};
  final countByCat = <String, int>{};
  var total = 0;
  var entryCount = 0;
  for (final tx in memberTxns) {
    amountByCat[tx.categoryId] = (amountByCat[tx.categoryId] ?? 0) + tx.amount;
    countByCat[tx.categoryId] = (countByCat[tx.categoryId] ?? 0) + 1;
    total += tx.amount;
    entryCount += 1;
  }
  final breakdowns = <CategoryBreakdown>[];
  amountByCat.forEach((catId, amount) {
    breakdowns.add(
      CategoryBreakdown(
        categoryId: catId,
        categoryName: catId,
        icon: '',
        color: '',
        amount: amount,
        percentage: total > 0 ? amount / total * 100 : 0,
        transactionCount: countByCat[catId] ?? 0,
      ),
    );
  });
  return MemberFilteredCategoryBreakdown(
    breakdowns: breakdowns,
    total: total,
    entryCount: entryCount,
  );
}

/// STATSUI-DONUT-MEMBER / D2: per-member (deviceId) expense breakdown for the
/// donut's 成员 dimension over the active window.
///
/// Returns one [MemberSpendBreakdown] per device (largest→smallest amount).
/// Single-device degrades to one bucket (UI handles graceful degradation).
///
/// D-12: callers MUST pass window-normalized [startDate]/[endDate]. This provider
/// defends the contract by re-normalizing the bounds via [DateBoundaries] before
/// they reach the use case — never accept microsecond-exact instants into the
/// family key (rebuild-storm guard).
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01).
@riverpod
Future<List<MemberSpendBreakdown>> memberSpendBreakdown(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getMemberSpendBreakdownUseCaseProvider);
  // D-15: manualOnly variant filters all AnalyticsScreen cards; HomeHero providers do NOT read this provider.
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual
      : null;
  // D-12 defensive normalization: collapse the window to whole-day closed bounds
  // so two callers with differing sub-day precision share one cache key.
  final start = DateBoundaries.dayRange(startDate).start;
  final end = DateBoundaries.dayRange(endDate).end;
  return useCase.execute(
    bookIds: [bookId],
    startDate: start,
    endDate: end,
    entrySourceFilter: entrySourceFilter,
  );
}

/// 260622-d5i / D3: 悦己 by-member amounts for the drawer's 成员 dimension —
/// joy-ledger only, a strict subset of [memberSpendBreakdown].
///
/// Mirrors [memberSpendBreakdown] EXACTLY (same key tuple, same D-12 day-range
/// normalization, same manualOnly→EntrySource.manual mapping, auto-dispose,
/// zero `home/*`) and reuses the SAME `getMemberSpendBreakdownUseCaseProvider`,
/// with ONE difference: `ledgerType: LedgerType.joy` so only joy-ledger expense
/// rows aggregate per member (a daily-only member yields no bucket).
@riverpod
Future<List<MemberSpendBreakdown>> joyMemberAmounts(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getMemberSpendBreakdownUseCaseProvider);
  // D-15: manualOnly variant filters all AnalyticsScreen cards; HomeHero providers do NOT read this provider.
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual
      : null;
  // D-12 defensive normalization: collapse the window to whole-day closed bounds
  // so two callers with differing sub-day precision share one cache key.
  final start = DateBoundaries.dayRange(startDate).start;
  final end = DateBoundaries.dayRange(endDate).end;
  return useCase.execute(
    bookIds: [bookId],
    startDate: start,
    endDate: end,
    entrySourceFilter: entrySourceFilter,
    ledgerType: LedgerType.joy,
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

/// All categories keyed by id — the {id -> Category} map the donut legend's
/// single-source L1 rollup needs (D-11). Read-only, auto-dispose; reuses the
/// existing accounting `categoryRepository.findAll()` (no new DAO). The SAME
/// `l1AncestorOf` rule the drill use case applies server-side is reapplied here
/// over the donut breakdowns so the legend rows equal the drill subtotals.
@riverpod
Future<Map<String, Category>> analyticsCategoriesMap(Ref ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final categories = await repository.findAll();
  return {for (final cat in categories) cat.id: cat};
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

/// JOY-02 / D-C2: per-L1 joy AMOUNT segments for the 悦己花在哪 stacked bar.
///
/// Returns one [JoyCategoryAmount] per L1 (largest→smallest) — a strict subset of
/// the donut's L1 amounts (single-source L1 rollup via l1AncestorOf, D-11).
///
/// D-12: callers MUST pass window-normalized [startDate]/[endDate]. This provider
/// defends the contract by re-normalizing the bounds via [DateBoundaries] before
/// they reach the use case — never accept microsecond-exact instants into the
/// family key (rebuild-storm guard).
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01).
/// [deviceId] (260622-d5i / D2): optional per-member narrowing, added to the
/// family key. `null` (default) reproduces the pre-d5i cache key/value, so
/// existing watchers that omit it stay byte-identical; a non-null value applies
/// the same `tx.deviceId == deviceId` rule the overall donut's member filter uses.
@riverpod
Future<List<JoyCategoryAmount>> joyCategoryAmounts(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
  String? deviceId,
}) async {
  final useCase = ref.watch(getJoyCategoryAmountsUseCaseProvider);
  // D-15: manualOnly variant filters all AnalyticsScreen cards; HomeHero providers do NOT read this provider.
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual
      : null;
  // D-12 defensive normalization: collapse the window to whole-day closed bounds
  // so two callers with differing sub-day precision share one cache key.
  final start = DateBoundaries.dayRange(startDate).start;
  final end = DateBoundaries.dayRange(endDate).end;
  return useCase.execute(
    bookIds: [bookId],
    startDate: start,
    endDate: end,
    entrySourceFilter: entrySourceFilter,
    deviceId: deviceId,
  );
}

/// JOY-01 / D-C1: per-day joy COUNT (笔数) for the active month — the 小确幸
/// calendar heatmap depth.
///
/// Returns one [PerDayJoyCount] per day that has joy spend (count, NOT sum —
/// Pitfall 3) within the month derived from [anchor].
///
/// D-12: keyed on a MONTH-anchored [anchor] (DateTime(year, month)). The provider
/// re-anchors to month precision and derives the month's whole-day window, so a
/// microsecond-exact key never explodes the family cache.
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01).
@riverpod
Future<List<PerDayJoyCount>> perDayJoyCounts(
  Ref ref, {
  required String bookId,
  required DateTime anchor,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getPerDayJoyCountsUseCaseProvider);
  // D-15: manualOnly variant filters all AnalyticsScreen cards; HomeHero providers do NOT read this provider.
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual
      : null;
  // D-12 defensive normalization: collapse to the calendar month, then to
  // whole-day closed bounds for the month.
  final monthStart = DateTime(anchor.year, anchor.month, 1);
  final monthEnd = DateTime(anchor.year, anchor.month + 1, 0, 23, 59, 59);
  return useCase.execute(
    bookIds: [bookId],
    startDate: monthStart,
    endDate: monthEnd,
    entrySourceFilter: entrySourceFilter,
  );
}

/// D-C1: the joy transactions for ONE tapped calendar day — the 小确幸 calendar
/// heatmap's INLINE day expansion.
///
/// Reuses the existing `findByBookIds(ledgerType: joy)` primitive over the single
/// tapped day's whole-day window (NOT a wider book set, T-46-05-01); keeps the
/// `perDayJoyCounts` model count-only (D-C1) by reading the day's rows here on
/// demand rather than widening the count model. Returns EXPENSE joy rows only,
/// time-descending, with the optional manualOnly entry-source filter applied —
/// the same gate the count path uses (Pitfall: findByBookIds has no
/// income/expense or entry-source SQL param).
///
/// D-12: keyed on a DAY-anchored [day] (re-normalized to whole-day closed bounds
/// here) so two callers with differing sub-day precision share one cache key.
///
/// Auto-dispose (the @riverpod default — D-14) and reads / invalidates ZERO
/// `home/*` providers (GUARD-01). Renders the active book's own joy rows only;
/// never logs tx contents (T-46-05-02).
@riverpod
Future<List<Transaction>> joyDayTransactions(
  Ref ref, {
  required String bookId,
  required DateTime day,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final repository = ref.watch(transactionRepositoryProvider);
  // D-15: manualOnly variant filters all AnalyticsScreen cards; HomeHero
  // providers do NOT read this provider.
  final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
      ? EntrySource.manual
      : null;
  // D-12 defensive normalization: collapse to the tapped day's whole-day bounds.
  final dayRange = DateBoundaries.dayRange(day);
  final txns = await repository.findByBookIds(
    [bookId],
    ledgerType: LedgerType.joy,
    categoryId: null,
    startDate: dayRange.start,
    endDate: dayRange.end,
    sortField: SortField.timestamp,
    sortDirection: SortDirection.desc,
  );
  return txns
      .where(
        (tx) =>
            tx.type == TransactionType.expense &&
            (entrySourceFilter == null || tx.entrySource == entrySourceFilter),
      )
      .toList();
}
