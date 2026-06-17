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
import 'providers/state_ledger_snapshot.dart';
import 'providers/state_time_window.dart';
import 'widgets/cards/best_joy_card.dart';
import 'widgets/cards/category_donut_card.dart';
import 'widgets/cards/family_insight_data_card.dart';
import 'widgets/cards/kpi_hero_card.dart';
import 'widgets/cards/largest_expense_card.dart';
import 'widgets/cards/satisfaction_histogram_card.dart';
import 'widgets/cards/total_six_month_card.dart';
import 'widgets/daily_vs_joy_card.dart';
import 'widgets/per_category_breakdown_card.dart';

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
/// - [sectionHeaderKey] lets Plan 04's shell interleave the section headers
///   1:1 with today's render order.
@immutable
class AnalyticsCardSpec {
  const AnalyticsCardSpec({
    required this.build,
    required this.refreshTargets,
    this.isVisible = _always,
    this.sectionHeaderKey,
  });

  /// Builds the card widget from the shared [AnalyticsCardContext].
  final Widget Function(AnalyticsCardContext ctx) build;

  /// The keyed analytics provider instances this card watches — the physical
  /// source of the `_refresh` union (D-B2). MUST contain only analytics
  /// providers (D-B3); never a `home/*` provider.
  final List<ProviderBase<Object?>> Function(AnalyticsCardContext ctx)
  refreshTargets;

  /// Visibility predicate (D-B4). Only the two family specs override this with
  /// `(ctx) => ctx.isGroupMode`; all others are always-visible.
  final bool Function(AnalyticsCardContext ctx) isVisible;

  /// Optional section-header key (one of the three `analyticsGroupHeader*`
  /// l10n keys) the shell renders ABOVE this card. `null` = no header (the
  /// KPI hero sits above all section headers).
  final String? sectionHeaderKey;

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

/// Single-source, GROUP-AWARE refresh targets for [DailyVsJoyCard] (D-B2 /
/// D-A1).
///
/// The single `DailyVsJoyCard` watches `dailyVsJoySnapshotProvider`
/// unconditionally AND `dailyVsJoySnapshotFamilyProvider` ONLY when
/// `isGroupMode` (daily_vs_joy_card.dart:50-69). To preserve today's
/// pull-to-refresh behavior (analytics_screen.dart:314 invalidates the family
/// snapshot under group mode), this collection mirrors that conditional watch:
/// the family snapshot is included ONLY behind `if (ctx.isGroupMode)`.
///
/// The DailyVsJoy spec itself stays ALWAYS-VISIBLE (the card always renders);
/// only the family snapshot invalidation is gated. The family
/// `PerCategoryBreakdownCard` covers a DIFFERENT provider
/// (`perCategoryJoyBreakdownFamilyProvider`) — omitting the family snapshot
/// here would be a behavior-preservation defect goldens cannot catch.
List<ProviderBase<Object?>> dailyVsJoyRefreshTargets(
  AnalyticsCardContext ctx,
) => [
  dailyVsJoySnapshotProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
  if (ctx.isGroupMode)
    dailyVsJoySnapshotFamilyProvider(
      startDate: ctx.startDate,
      endDate: ctx.endDate,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
];

/// Single-source refresh targets for the solo/you-scope [PerCategoryBreakdownCard]
/// (D-B2). The card watches `perCategoryJoyBreakdownProvider` for both the
/// `solo` and `you` scopes (only the `family` scope reads the family provider).
List<ProviderBase<Object?>> perCategorySoloRefreshTargets(
  AnalyticsCardContext ctx,
) => [
  perCategoryJoyBreakdownProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
];

/// Single-source refresh targets for the family-scope [PerCategoryBreakdownCard]
/// (D-B2). Reads `perCategoryJoyBreakdownFamilyProvider` (no `bookId` — the
/// provider derives book ids from shadow books internally). This spec is
/// `isVisible: (ctx) => ctx.isGroupMode` (D-B4), so the family provider only
/// ever enters the union in group mode.
List<ProviderBase<Object?>> perCategoryFamilyRefreshTargets(
  AnalyticsCardContext ctx,
) => [
  perCategoryJoyBreakdownFamilyProvider(
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
];

/// The ordered card registry — the SINGLE SOURCE OF TRUTH for both the shell's
/// render order (declaration order == render order, D-B1) and the `_refresh`
/// invalidation union (`registry.where(isVisible).expand(refreshTargets)`).
///
/// Order reproduces analytics_screen.dart:94–206 1:1, including the two
/// group-only specs (2nd `PerCategoryBreakdownCard(scope: family)` +
/// `FamilyInsightDataCard`), both gated by `isVisible: (ctx) => ctx.isGroupMode`
/// (D-B4). No drill/route artifact is added (D-C1/D-C2 deferred to Phase 46).
final List<AnalyticsCardSpec> analyticsCardRegistry = <AnalyticsCardSpec>[
  // 1. KPI mini-hero — sits ABOVE all section headers (no sectionHeaderKey).
  AnalyticsCardSpec(
    build: (ctx) => KpiHeroCard(
      bookId: ctx.bookId,
      startDate: ctx.startDate,
      endDate: ctx.endDate,
      currencyCode: ctx.currencyCode,
      locale: ctx.locale,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
    refreshTargets: kpiHeroRefreshTargets,
  ),
  // 2. Time group — 6-month total expense trend.
  AnalyticsCardSpec(
    sectionHeaderKey: 'analyticsGroupHeaderTime',
    build: (ctx) => TotalSixMonthCard(
      bookId: ctx.bookId,
      anchor: ctx.trendAnchor,
      locale: ctx.locale,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
    refreshTargets: totalSixMonthRefreshTargets,
  ),
  // 3. Distribution group — category-spend donut.
  AnalyticsCardSpec(
    sectionHeaderKey: 'analyticsGroupHeaderDistribution',
    build: (ctx) => CategoryDonutCard(
      bookId: ctx.bookId,
      startDate: ctx.startDate,
      endDate: ctx.endDate,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
    refreshTargets: categoryDonutRefreshTargets,
  ),
  // 4. Distribution — Daily-vs-Joy ledger snapshot. ALWAYS visible; its
  //    refreshTargets are GROUP-AWARE (family snapshot only under group mode).
  AnalyticsCardSpec(
    build: (ctx) => DailyVsJoyCard(
      bookId: ctx.bookId,
      startDate: ctx.startDate,
      endDate: ctx.endDate,
      currencyCode: ctx.currencyCode,
      locale: ctx.locale,
      isGroupMode: ctx.isGroupMode,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
    refreshTargets: dailyVsJoyRefreshTargets,
  ),
  // 5. Distribution — satisfaction histogram (async self-hide is in-card, D-B5).
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
  // 6. Distribution — per-category breakdown (you in group mode, solo otherwise).
  AnalyticsCardSpec(
    build: (ctx) => PerCategoryBreakdownCard(
      bookId: ctx.bookId,
      startDate: ctx.startDate,
      endDate: ctx.endDate,
      locale: ctx.locale,
      scope: ctx.isGroupMode ? PerCategoryScope.you : PerCategoryScope.solo,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
    refreshTargets: perCategorySoloRefreshTargets,
  ),
  // 7. Distribution — 2nd per-category breakdown (family scope). GROUP-ONLY (D-B4).
  AnalyticsCardSpec(
    build: (ctx) => PerCategoryBreakdownCard(
      bookId: ctx.bookId,
      startDate: ctx.startDate,
      endDate: ctx.endDate,
      locale: ctx.locale,
      scope: PerCategoryScope.family,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
    refreshTargets: perCategoryFamilyRefreshTargets,
    isVisible: (ctx) => ctx.isGroupMode,
  ),
  // 8. Stories group — largest single expense.
  AnalyticsCardSpec(
    sectionHeaderKey: 'analyticsGroupHeaderStories',
    build: (ctx) => LargestExpenseCard(
      bookId: ctx.bookId,
      startDate: ctx.startDate,
      endDate: ctx.endDate,
      currencyCode: ctx.currencyCode,
      locale: ctx.locale,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
    refreshTargets: largestExpenseRefreshTargets,
  ),
  // 9. Stories — best joy moment.
  AnalyticsCardSpec(
    build: (ctx) => BestJoyCard(
      bookId: ctx.bookId,
      startDate: ctx.startDate,
      endDate: ctx.endDate,
      currencyCode: ctx.currencyCode,
      locale: ctx.locale,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
    refreshTargets: bestJoyRefreshTargets,
  ),
  // 10. Stories — family-aggregate insight. GROUP-ONLY (D-B4).
  //     The card's `shadowBooksAsync` is a DISPLAY-ONLY home-feature read; the
  //     registry must not import the home provider (D-B3 file-wide gate), so
  //     this build passes a null placeholder and Plan 04's shell injects the
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
