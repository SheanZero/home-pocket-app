import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../../generated/app_localizations.dart';
import '../../analytics_card_registry.dart';
import '../../providers/state_analytics.dart';
import '../../providers/state_happiness.dart';
import '../../providers/state_joy_metric_variant.dart';
import '../analytics_card_error_state.dart';
import '../satisfaction_distribution_histogram.dart';
import 'analytics_data_card.dart';

/// Satisfaction-distribution histogram card with an async self-hide.
///
/// Phase 45: promoted verbatim from the private
/// `_SatisfactionHistogramOrFallback` inline in `analytics_screen.dart` (D-A1
/// byte-faithful move — class name de-privatised, `super.key` added, the two
/// error-retry invalidations now draw their provider from the single-source
/// `satisfactionHistogramRefreshTargets` list instead of literals).
///
/// D-B5: the `report.totalJoyTx < 5 → SizedBox.shrink()` self-hide stays INSIDE
/// the `happinessAsync.when` data branch — it depends on FETCHED data, not on
/// the [AnalyticsCardContext], so it is NOT a registry visibility predicate. The
/// registry sets this card's `isVisible` to always-true (Plan 03), and
/// `satisfactionHistogramRefreshTargets` always returns BOTH providers
/// regardless of the self-hide.
class SatisfactionHistogramCard extends ConsumerWidget {
  const SatisfactionHistogramCard({
    super.key,
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.joyMetricVariant,
  });

  final String bookId;
  final DateTime startDate;
  final DateTime endDate;
  final JoyMetricVariant joyMetricVariant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Single source for the error retries (D-B2): [0] = happinessReportProvider,
    // [1] = satisfactionDistributionProvider.
    final targets = satisfactionHistogramRefreshTargets(_ctx());

    final happinessAsync = ref.watch(
      happinessReportProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        // JPY-only is a v1 data-layer truth (WR-01 / D-02); happinessReportProvider
        // still requires a currency key, so feed it the literal — not a dropped field.
        currencyCode: 'JPY',
        joyMetricVariant: joyMetricVariant,
      ),
    );
    final distributionAsync = ref.watch(
      satisfactionDistributionProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        joyMetricVariant: joyMetricVariant,
      ),
    );

    return happinessAsync.when(
      data: (report) {
        if (report.totalJoyTx < 5) {
          return const SizedBox.shrink();
        }
        return distributionAsync.when(
          // round-5 r5 / §3: the card title is suppressed — the section header
          // 「悦己满足度分布」already labels it and the mock body has no in-card
          // title. title/caption stay set (still required) but are not rendered.
          data: (buckets) => AnalyticsDataCard(
            showHeader: false,
            title: S.of(context).analyticsCardTitleSatisfactionHistogram,
            caption: S.of(context).analyticsCardCaptionHistogram,
            child: SatisfactionDistributionHistogram(buckets: buckets),
          ),
          loading: () => const SizedBox(height: 260),
          error: (_, _) => AnalyticsCardErrorState(
            onRetry: () => ref.invalidate(targets[1]),
          ),
        );
      },
      loading: () => const SizedBox(height: 260),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(targets[0]),
      ),
    );
  }

  /// Minimal [AnalyticsCardContext] for this card's two targets. `trendAnchor`
  /// is derived from `endDate`; `isGroupMode` is unused by the targets.
  AnalyticsCardContext _ctx() => AnalyticsCardContext(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    trendAnchor: DateTime(endDate.year, endDate.month),
    joyMetricVariant: joyMetricVariant,
    isGroupMode: false,
    locale: const Locale('ja'),
  );
}

/// Single-source refresh targets for [SatisfactionHistogramCard] (D-B2). ALWAYS
/// returns both `happinessReportProvider` and `satisfactionDistributionProvider`
/// regardless of the in-card `totalJoyTx < 5` self-hide (D-B5).
List<ProviderBase<Object?>> satisfactionHistogramRefreshTargets(
  AnalyticsCardContext ctx,
) => [
  happinessReportProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    // JPY-only literal (WR-01 / D-02) — happinessReportProvider keeps its required
    // currency key; only the AnalyticsCardContext.currencyCode plumbing was removed.
    currencyCode: 'JPY',
    joyMetricVariant: ctx.joyMetricVariant,
  ),
  satisfactionDistributionProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
];
