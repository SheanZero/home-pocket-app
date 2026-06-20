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

/// Satisfaction-distribution histogram card. ALWAYS renders.
///
/// Phase 45: promoted verbatim from the private
/// `_SatisfactionHistogramOrFallback` inline in `analytics_screen.dart` (D-A1
/// byte-faithful move — class name de-privatised, `super.key` added, the two
/// error-retry invalidations now draw their provider from the single-source
/// `satisfactionHistogramRefreshTargets` list instead of literals).
///
/// round-5 r5b: the former `report.totalJoyTx < 5 → SizedBox.shrink()` self-hide
/// (D-B5) is REMOVED. It left an orphaned section header (「悦己满足度分布」renders
/// unconditionally in the shell) when joy tx < 5. The card now renders the
/// histogram for ALL data; the empty case (0 rated joy tx) is the
/// `SatisfactionDistributionHistogram` empty state (10 zero-stub bars +「0 笔」).
/// `happinessReportProvider` is still watched (loading/error gating only — its
/// value is discarded), and `satisfactionHistogramRefreshTargets` still returns
/// BOTH providers.
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

    // round-5 r5b / D-B5 REVERSED: the `totalJoyTx < 5` self-hide is GONE — the
    // card ALWAYS renders the histogram. The empty-data case (0 rated joy tx) is
    // handled by SatisfactionDistributionHistogram itself (10 zero-stub bars +
    // 「0 笔」footer). The happinessAsync.when wrapper is kept ONLY to gate on the
    // happiness fetch's loading/error states; its value is intentionally
    // discarded (`_`). Both providers stay watched so the refresh union
    // (satisfactionHistogramRefreshTargets) is unchanged.
    return happinessAsync.when(
      data: (_) => distributionAsync.when(
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
      ),
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
/// (the card watches both; the former now only gates loading/error after the
/// round-5 r5b self-hide removal).
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
