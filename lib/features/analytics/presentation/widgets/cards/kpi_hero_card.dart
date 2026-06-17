import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../analytics_card_registry.dart';
import '../../providers/state_analytics.dart';
import '../../providers/state_happiness.dart';
import '../../providers/state_joy_metric_variant.dart';
import '../analytics_card_error_state.dart';
import '../kpi_mini_hero_strip.dart';

/// KPI mini-hero strip card.
///
/// Phase 45: promoted verbatim from the private `_KpiHero` inline in
/// `analytics_screen.dart` (D-A1 byte-faithful move — only the class name lost
/// its leading underscore, the constructor gained `super.key`, and the two
/// error-retry invalidations now draw their provider from the single-source
/// `kpiHeroRefreshTargets` list instead of re-listing literals). Watches two
/// providers (`monthlyReportProvider` + `happinessReportProvider`) with nested
/// `.when` branches; renders `KpiMiniHeroStrip` directly (no `AnalyticsDataCard`
/// shell).
///
/// `kpiHeroRefreshTargets` is the single source (D-B2 / "卡就是契约") for both the
/// registry's `_refresh` union (Plan 03/04) and this card's own error-retry
/// invalidations; its key tuples bind to the Plan-03 [AnalyticsCardContext].
class KpiHeroCard extends ConsumerWidget {
  const KpiHeroCard({
    super.key,
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.currencyCode,
    required this.locale,
    required this.joyMetricVariant,
  });

  final String bookId;
  final DateTime startDate;
  final DateTime endDate;
  final String currencyCode;
  final Locale locale;
  final JoyMetricVariant joyMetricVariant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Single source for the error retries (D-B2): [0] = monthlyReportProvider,
    // [1] = happinessReportProvider — built from the same fields the typed
    // watches below use, so build and refresh keys cannot drift.
    final targets = kpiHeroRefreshTargets(_ctx());

    final monthlyAsync = ref.watch(
      monthlyReportProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        joyMetricVariant: joyMetricVariant,
      ),
    );
    final happinessAsync = ref.watch(
      happinessReportProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        currencyCode: currencyCode,
        joyMetricVariant: joyMetricVariant,
      ),
    );

    return monthlyAsync.when(
      data: (monthly) => happinessAsync.when(
        data: (happiness) => SizedBox(
          height: 120,
          child: KpiMiniHeroStrip(
            monthlyReport: monthly,
            happinessReport: happiness,
            currencyCode: currencyCode,
            locale: locale,
          ),
        ),
        loading: () => const SizedBox(height: 120),
        error: (_, _) => AnalyticsCardErrorState(
          onRetry: () => ref.invalidate(targets[1]),
        ),
      ),
      loading: () => const SizedBox(height: 120),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(targets[0]),
      ),
    );
  }

  /// Builds the minimal [AnalyticsCardContext] this card's targets need.
  /// `trendAnchor`/`isGroupMode` are unused by [kpiHeroRefreshTargets] but
  /// required by the const ctor; derive `trendAnchor` from the same `endDate`.
  AnalyticsCardContext _ctx() => AnalyticsCardContext(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    trendAnchor: DateTime(endDate.year, endDate.month),
    currencyCode: currencyCode,
    joyMetricVariant: joyMetricVariant,
    isGroupMode: false,
    locale: locale,
  );
}

/// Single-source refresh targets for [KpiHeroCard] (D-B2). Returns the exact
/// keyed provider instances the card's `build` watches — the registry union
/// (Plan 03/04) and the card's error-retry both derive from this list.
List<ProviderBase<Object?>> kpiHeroRefreshTargets(AnalyticsCardContext ctx) => [
  monthlyReportProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
  happinessReportProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    currencyCode: ctx.currencyCode,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
];
