import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../../generated/app_localizations.dart';
import '../../analytics_card_registry.dart';
import '../../providers/state_analytics.dart';
import '../../providers/state_joy_metric_variant.dart';
import '../analytics_card_error_state.dart';
import '../monthly_spend_trend_bar_chart.dart';
import 'analytics_data_card.dart';

/// 6-month total expense-trend card.
///
/// Phase 45: promoted verbatim from the private `_TotalSixMonthCard` inline in
/// `analytics_screen.dart` (D-A1 byte-faithful move — class name de-privatised,
/// `super.key` added, error-retry now invalidates the single-source
/// `totalSixMonthRefreshTargets` element instead of a literal). Watches
/// `expenseTrendProvider` keyed on `anchor` (NOT start/end) and renders the
/// trend bar chart inside the shared [AnalyticsDataCard] shell.
///
/// `totalSixMonthRefreshTargets` is the single source (D-B2) for the registry
/// `_refresh` union (Plan 03/04) and this card's error-retry; its key tuple
/// binds to the Plan-03 [AnalyticsCardContext] (`trendAnchor`).
class TotalSixMonthCard extends ConsumerWidget {
  const TotalSixMonthCard({
    super.key,
    required this.bookId,
    required this.anchor,
    required this.locale,
    required this.joyMetricVariant,
  });

  final String bookId;
  final DateTime anchor;
  final Locale locale;
  final JoyMetricVariant joyMetricVariant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targets = totalSixMonthRefreshTargets(_ctx());

    final trendAsync = ref.watch(
      expenseTrendProvider(
        bookId: bookId,
        anchor: anchor,
        joyMetricVariant: joyMetricVariant,
      ),
    );
    return trendAsync.when(
      data: (trend) => AnalyticsDataCard(
        title: S.of(context).analyticsCardTitleTotalSixMonth,
        caption: S.of(context).analyticsCardCaptionTotalSixMonth,
        child: MonthlySpendTrendBarChart(
          trendData: trend,
          selectedYear: anchor.year,
          selectedMonth: anchor.month,
          locale: locale,
        ),
      ),
      loading: () => const SizedBox(height: 260),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(targets.single),
      ),
    );
  }

  /// Minimal [AnalyticsCardContext] for this card's single target. `anchor`
  /// maps to `trendAnchor`; the date/group fields are unused by the targets.
  AnalyticsCardContext _ctx() => AnalyticsCardContext(
    bookId: bookId,
    startDate: anchor,
    endDate: anchor,
    trendAnchor: anchor,
    currencyCode: 'JPY',
    joyMetricVariant: joyMetricVariant,
    isGroupMode: false,
    locale: locale,
  );
}

/// Single-source refresh targets for [TotalSixMonthCard] (D-B2). Keyed on
/// `trendAnchor` (NOT start/end — RESEARCH Pitfall 2), matching the watched
/// `expenseTrendProvider`.
List<ProviderBase<Object?>> totalSixMonthRefreshTargets(
  AnalyticsCardContext ctx,
) => [
  expenseTrendProvider(
    bookId: ctx.bookId,
    anchor: ctx.trendAnchor,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
];
