import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../../generated/app_localizations.dart';
import '../../analytics_card_registry.dart';
import '../../providers/state_analytics.dart';
import '../../providers/state_joy_metric_variant.dart';
import '../analytics_card_error_state.dart';
import '../category_spend_donut_chart.dart';
import 'analytics_data_card.dart';

/// Category-spend donut card.
///
/// Phase 45: promoted verbatim from the private `_CategoryDonutCard` inline in
/// `analytics_screen.dart` (D-A1 byte-faithful move — class name de-privatised,
/// `super.key` added, error-retry now invalidates the single-source
/// `categoryDonutRefreshTargets` element instead of a literal). Watches
/// `monthlyReportProvider` with the SAME key tuple as [KpiHeroCard]'s
/// monthlyReport — Plan 04's `.toSet()` dedupes the shared instance.
///
/// `categoryDonutRefreshTargets` is the single source (D-B2) for the registry
/// `_refresh` union (Plan 03/04) and this card's error-retry; its key tuple
/// binds to the Plan-03 [AnalyticsCardContext].
class CategoryDonutCard extends ConsumerWidget {
  const CategoryDonutCard({
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
    final targets = categoryDonutRefreshTargets(_ctx());

    final monthlyAsync = ref.watch(
      monthlyReportProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        joyMetricVariant: joyMetricVariant,
      ),
    );
    return monthlyAsync.when(
      data: (monthly) => AnalyticsDataCard(
        title: S.of(context).analyticsCardTitleCategoryDonut,
        caption: S.of(context).analyticsCardCaptionCategoryDonut,
        child: CategorySpendDonutChart(breakdowns: monthly.categoryBreakdowns),
      ),
      loading: () => const SizedBox(height: 280),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(targets.single),
      ),
    );
  }

  /// Minimal [AnalyticsCardContext] for this card's single target. `trendAnchor`
  /// is derived from `endDate`; `isGroupMode` is unused by the targets.
  AnalyticsCardContext _ctx() => AnalyticsCardContext(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    trendAnchor: DateTime(endDate.year, endDate.month),
    currencyCode: 'JPY',
    joyMetricVariant: joyMetricVariant,
    isGroupMode: false,
    locale: const Locale('ja'),
  );
}

/// Single-source refresh targets for [CategoryDonutCard] (D-B2). SAME key tuple
/// as [KpiHeroCard]'s monthlyReport — the shell union dedupes via `.toSet()`.
List<ProviderBase<Object?>> categoryDonutRefreshTargets(
  AnalyticsCardContext ctx,
) => [
  monthlyReportProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
];
