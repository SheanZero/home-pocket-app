import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../../generated/app_localizations.dart';
import '../../analytics_card_registry.dart';
import '../../providers/state_analytics.dart';
import '../../providers/state_joy_metric_variant.dart';
import '../analytics_card_error_state.dart';
import '../donut_hero.dart';
import '../joy_spend_drawer.dart';
import 'analytics_data_card.dart';

/// Category-spend donut HERO card (round-5 B card #2, Phase 46).
///
/// Rebuilt from the Phase-45 verbatim move: the legend is now 10 L1-rollup rows
/// (via the single-source `rollupCategoryBreakdownsToL1` helper, D-11), each
/// row is fully tappable to `Navigator.push` the read-only
/// [CategoryDrillDownScreen] for that L1 (D-B1 — the ROW, never a pie slice),
/// and the donut center "本月支出" total animates with a `TweenAnimationBuilder`
/// count-up (~480ms, D-D2 anchor #1).
///
/// Still watches `monthlyReportProvider` with the SAME key tuple (the shell
/// `.toSet()` dedupes the shared instance), and `categoryDonutRefreshTargets`
/// remains the single source (D-B2) for the registry `_refresh` union and this
/// card's error-retry. Adds a read of `analyticsCategoriesMapProvider` for the
/// {id -> Category} map the L1 rollup needs.
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
    final categoryMapAsync = ref.watch(analyticsCategoriesMapProvider);
    // round-5 r5 §1d: joy-aware donut colours. `JoyCategoryAmount.categoryId` is
    // ALREADY L1 (confirmed) — build the L1-id set directly, no rollup. The same
    // provider key the nested `JoySpendDrawer` watches → Riverpod dedupes.
    final joyAmountsAsync = ref.watch(
      joyCategoryAmountsProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        joyMetricVariant: joyMetricVariant,
      ),
    );
    final joyL1Ids = <String>{
      for (final a in joyAmountsAsync.value ?? const []) a.categoryId,
    };

    return monthlyAsync.when(
      data: (monthly) => AnalyticsDataCard(
        title: S.of(context).analyticsCardTitleCategoryDonut,
        caption: S.of(context).analyticsCardCaptionCategoryDonut,
        // round-5 r5 §1a: drop the in-card 「分类支出」 title/caption — the section
        // header already labels it (same handling as the trend card).
        showHeader: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DonutHero(
              breakdowns: monthly.categoryBreakdowns,
              total: monthly.totalExpenses,
              // §1b: hero-top + center third line need the total entry count and
              // the display-anchor month.
              entryCount: monthly.categoryBreakdowns.fold<int>(
                0,
                (s, b) => s + b.transactionCount,
              ),
              month: monthly.month,
              joyL1Ids: joyL1Ids,
              // The legend's L1 rollup needs the category map; while it loads,
              // fall back to an empty map (the donut + center total still render).
              categoryMap: categoryMapAsync.value ?? const {},
              bookId: bookId,
            ),
            // round-5 r5 §2b (D2): the 悦己 joybar is nested INSIDE the donut hero
            // behind a connector chip + pink drawer (no longer a top-level card).
            JoySpendDrawer(
              bookId: bookId,
              startDate: startDate,
              endDate: endDate,
              joyMetricVariant: joyMetricVariant,
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 280),
      // `targets` now folds in joyCategoryAmountsProvider (Pitfall-3); the donut's
      // own error branch owns the monthlyReport target — invalidate `.first`.
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(targets.first),
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
    joyMetricVariant: joyMetricVariant,
    isGroupMode: false,
    locale: const Locale('ja'),
  );
}

/// Single-source refresh targets for [CategoryDonutCard] (D-B2). Returns BOTH
/// the donut's `monthlyReportProvider` AND the nested joy drawer's
/// `joyCategoryAmountsProvider`, keyed on book/start/end/variant.
///
/// Pitfall-3 / GUARD-01: round-5 r5 (260620-lfp / D2) nests the 悦己 joybar inside
/// this card and de-registers the standalone `JoySpendCard`. Folding
/// `joyCategoryAmountsProvider` in here keeps the pull-to-refresh union
/// invalidating the drawer (the registry derives the union from
/// `expand(refreshTargets)`). `[0]` is the donut's own target (its error branch
/// invalidates `targets.first`); `[1]` is the drawer's (the `_JoyDrawer` error
/// branch invalidates `joyCategoryAmountsProvider` itself). Both are analytics
/// providers — the registry stays home-free.
List<ProviderBase<Object?>> categoryDonutRefreshTargets(
  AnalyticsCardContext ctx,
) => [
  monthlyReportProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
  joyCategoryAmountsProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
];


