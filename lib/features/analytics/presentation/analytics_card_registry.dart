import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../features/accounting/presentation/providers/repository_providers.dart'
    as accounting_providers;
import '../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import '../domain/models/time_window.dart';
import 'providers/state_analytics.dart';
import 'providers/state_joy_metric_variant.dart';
import 'providers/state_time_window.dart';
import 'widgets/cards/category_donut_card.dart';
import 'widgets/cards/family_insight_data_card.dart';
import 'widgets/cards/joy_calendar_card.dart';
import 'widgets/cards/joy_spend_card.dart';
import 'widgets/cards/satisfaction_histogram_card.dart';
import 'widgets/cards/within_month_trend_card.dart';

/// Snapshot of everything an analytics card needs to (a) be built, (b) decide
/// its visibility, and (c) compute its refresh targets — all derived from the
/// SAME providers the shell's `build` reads, so build-vs-invalidation cannot
/// drift (D-B2 / "卡就是契约").
///
/// Phase 45 contract note: this is the canonical, single-source context for
/// every `widgets/cards/*` card's `<card>RefreshTargets(ctx)` function. Plan 03
/// fills the `List<AnalyticsCardSpec>` registry and the
/// `buildAnalyticsCardContext` helper AROUND this class; do NOT duplicate the
/// context class across card files. This minimal stub exists so the Wave-1 card
/// files (Plan 01) compile independently of Plan 03.
@immutable
class AnalyticsCardContext {
  const AnalyticsCardContext({
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.trendAnchor,
    required this.currencyCode,
    required this.joyMetricVariant,
    required this.isGroupMode,
    required this.locale,
  });

  final String bookId;
  final DateTime startDate;
  final DateTime endDate;

  /// `DateTime(endDate.year, endDate.month)` — the month-anchored key the
  /// 6-month expense-trend provider is keyed on (NOT start/end).
  final DateTime trendAnchor;

  /// `bookByIdProvider.value?.currency ?? 'JPY'`.
  final String currencyCode;

  final JoyMetricVariant joyMetricVariant;
  final bool isGroupMode;
  final Locale locale;
}

/// A single analytics card entry in the [analyticsCardRegistry] — the typed
/// spec that is the SINGLE SOURCE OF TRUTH for both (a) the shell's card render
/// order and (b) the `_refresh` invalidation union (D-B1).
///
/// Spec-list pattern (RESEARCH Pattern 1): each card stays a dumb
/// `ConsumerWidget`; the registry holds closures over [AnalyticsCardContext]:
/// - [build] constructs the card from the ctx.
/// - [refreshTargets] delegates to the per-card `<card>RefreshTargets(ctx)`
///   function from Plans 01/02 (no second list — D-B2).
/// - [isVisible] gates conditional cards (D-B4); defaults to always-true.
///
/// Round-5 B (Phase 46, D-F2): the lineup is a FLAT 5-card narrative flow with
/// NO section headers — the per-spec header-key field + the shell's
/// section-header interleave were removed when the round-5 B order landed
/// (`analytics_screen_section_header` deleted).
@immutable
class AnalyticsCardSpec {
  const AnalyticsCardSpec({
    required this.build,
    required this.refreshTargets,
    this.isVisible = _always,
  });

  /// Builds the card widget from the shared [AnalyticsCardContext].
  final Widget Function(AnalyticsCardContext ctx) build;

  /// The keyed analytics provider instances this card watches — the physical
  /// source of the `_refresh` union (D-B2). MUST contain only analytics
  /// providers (D-B3); never a `home/*` provider.
  final List<ProviderBase<Object?>> Function(AnalyticsCardContext ctx)
  refreshTargets;

  /// Visibility predicate (D-B4). Only the `FamilyInsightDataCard` spec overrides
  /// this with `(ctx) => ctx.isGroupMode`; all others are always-visible.
  final bool Function(AnalyticsCardContext ctx) isVisible;

  static bool _always(AnalyticsCardContext _) => true;
}

/// Builds the canonical [AnalyticsCardContext] ONCE from the same providers the
/// shell's `build` reads (analytics_screen.dart:42–67 verbatim), so Plan 04's
/// shell card map and `_refresh` share one source — no build/invalidation
/// drift (D-A1/D-B2).
AnalyticsCardContext buildAnalyticsCardContext(
  BuildContext context,
  WidgetRef ref, {
  required String bookId,
}) {
  final window = ref.watch(selectedTimeWindowProvider);
  final range = window.range;
  final startDate = range.start;
  final endDate = range.end;
  final trendAnchor = DateTime(endDate.year, endDate.month);
  final currencyCode =
      ref
          .watch(accounting_providers.bookByIdProvider(bookId: bookId))
          .value
          ?.currency ??
      'JPY';
  final joyMetricVariant = ref.watch(selectedJoyMetricVariantProvider);
  final isGroupMode = ref.watch(isGroupModeProvider);
  final locale =
      ref.watch(locale_providers.currentLocaleProvider).value ??
      Localizations.localeOf(context);

  return AnalyticsCardContext(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    trendAnchor: trendAnchor,
    currencyCode: currencyCode,
    joyMetricVariant: joyMetricVariant,
    isGroupMode: isGroupMode,
    locale: locale,
  );
}

/// The one shell-level, non-card refresh target: the AppBar's
/// `TimeWindowChip` reads `earliestTransactionMonthProvider` (NOT owned by any
/// card). It is an analytics provider, so the union ⊆ analytics still holds
/// (D-B3).
List<ProviderBase<Object?>> shellRefreshTargets(AnalyticsCardContext ctx) => [
  earliestTransactionMonthProvider(bookId: ctx.bookId),
];

/// The ordered card registry — the SINGLE SOURCE OF TRUTH for both the shell's
/// render order (declaration order == render order, D-B1) and the `_refresh`
/// invalidation union (`registry.where(isVisible).expand(refreshTargets)`).
///
/// Round-5 B flat lineup (Phase 46, D-F2) — a 5-card narrative flow with NO
/// section headers:
///   1. within_month_trend (支出趋势)
///   2. category_donut (支出分类圆环 hero, rebuilt 46-06)
///   3. joy_spend (悦己花在哪 R-1 stacked bar)
///   4. joy_calendar (小确幸日历 R-2 heatmap)
///   5. satisfaction_histogram (悦己满足度分布, rebuilt 46-06)
///   6. [family_insight] — GROUP-ONLY conditional card (D-F1), appended after
///      the 5 always-visible cards, gated by `isVisible: (ctx) => ctx.isGroupMode`.
///
/// The Variant-δ Time/Distribution/Stories section headers + the dead cards
/// (kpi_hero, total_six_month, daily_vs_joy/per_category de-registered,
/// largest_expense, best_joy) were removed in Phase 46 (D-A3/D-F2). The
/// `daily_vs_joy_card`/`per_category_breakdown_card` widget files are RETAINED
/// (they keep their own tests) but no longer appear in this lineup.
final List<AnalyticsCardSpec> analyticsCardRegistry = <AnalyticsCardSpec>[
  // 1. 支出趋势 — within-month per-day-cumulative spend LineChart (round-5 B
  //    card #1, D-E1). Spend tabs draw 本月 solid + 上月 dashed; the 悦己 tab is a
  //    structurally-single 本月 line (zero cross-period).
  AnalyticsCardSpec(
    build: (ctx) => WithinMonthTrendCard(
      bookId: ctx.bookId,
      startDate: ctx.startDate,
      endDate: ctx.endDate,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
    refreshTargets: withinMonthTrendRefreshTargets,
  ),
  // 2. 支出分类圆环 hero — donut with 10 tappable L1-rollup legend rows → drill
  //    (round-5 B card #2, rebuilt 46-06).
  AnalyticsCardSpec(
    build: (ctx) => CategoryDonutCard(
      bookId: ctx.bookId,
      startDate: ctx.startDate,
      endDate: ctx.endDate,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
    refreshTargets: categoryDonutRefreshTargets,
  ),
  // 3. 悦己花在哪 — custom Row+Flexible stacked bar (R-1, round-5 B card #3, D-C2).
  AnalyticsCardSpec(
    build: (ctx) => JoySpendCard(
      bookId: ctx.bookId,
      startDate: ctx.startDate,
      endDate: ctx.endDate,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
    refreshTargets: joySpendRefreshTargets,
  ),
  // 4. 小确幸日历 — custom GridView heatmap with inline day expand (R-2, round-5 B
  //    card #4, D-C1).
  AnalyticsCardSpec(
    build: (ctx) => JoyCalendarCard(
      bookId: ctx.bookId,
      startDate: ctx.startDate,
      endDate: ctx.endDate,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
    refreshTargets: joyCalendarRefreshTargets,
  ),
  // 5. 悦己满足度分布 — histogram (round-5 B card #5; native fl_chart rod label,
  //    rebuilt 46-06). Async self-hide is in-card (D-B5).
  AnalyticsCardSpec(
    build: (ctx) => SatisfactionHistogramCard(
      bookId: ctx.bookId,
      startDate: ctx.startDate,
      endDate: ctx.endDate,
      currencyCode: ctx.currencyCode,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
    refreshTargets: satisfactionHistogramRefreshTargets,
  ),
  // 6. Family-aggregate insight. GROUP-ONLY (D-F1/D-B4).
  //     The card's `shadowBooksAsync` is a DISPLAY-ONLY home-feature read; the
  //     registry must not import the home provider (D-B3 file-wide gate), so
  //     this build passes a null placeholder and the shell injects the
  //     real shell-resolved `shadowBooksAsync` when it constructs this card
  //     (the shell already imports the home provider for display; reading it for
  //     display is NOT an invalidation target and never enters the union).
  AnalyticsCardSpec(
    build: (ctx) => FamilyInsightDataCard(
      startDate: ctx.startDate,
      endDate: ctx.endDate,
      isGroupMode: ctx.isGroupMode,
      shadowBooksAsync: const AsyncValue<List<Object>?>.data(null),
      locale: ctx.locale,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
    refreshTargets: familyInsightRefreshTargets,
    isVisible: (ctx) => ctx.isGroupMode,
  ),
];
