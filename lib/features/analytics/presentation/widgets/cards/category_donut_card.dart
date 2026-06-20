import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../../application/accounting/category_localization_service.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../generated/app_localizations.dart';
import '../../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../accounting/domain/models/category.dart';
import '../../../domain/category_l1_rollup.dart';
import '../../../domain/models/monthly_report.dart';
import '../../analytics_card_registry.dart';
import '../../providers/state_analytics.dart';
import '../../../../settings/presentation/providers/state_locale.dart';
import '../../providers/state_joy_metric_variant.dart';
import '../../screens/category_drill_down_screen.dart';
import '../analytics_card_error_state.dart';
import '../joy_spend_drawer_body.dart';
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

    return monthlyAsync.when(
      data: (monthly) => AnalyticsDataCard(
        title: S.of(context).analyticsCardTitleCategoryDonut,
        caption: S.of(context).analyticsCardCaptionCategoryDonut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DonutHero(
              breakdowns: monthly.categoryBreakdowns,
              total: monthly.totalExpenses,
              // The legend's L1 rollup needs the category map; while it loads,
              // fall back to an empty map (the donut + center total still render).
              categoryMap: categoryMapAsync.value ?? const {},
              bookId: bookId,
            ),
            // round-5 r5 §2b (D2): the 悦己 joybar is nested INSIDE the donut hero
            // behind a connector chip + pink drawer (no longer a top-level card).
            _JoyDrawer(
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

/// Donut chart + count-up center total + tappable L1-rollup legend rows.
class _DonutHero extends ConsumerWidget {
  const _DonutHero({
    required this.breakdowns,
    required this.total,
    required this.categoryMap,
    required this.bookId,
  });

  final List<CategoryBreakdown> breakdowns;
  final int total;
  final Map<String, Category> categoryMap;
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');

    // D-11 single source: roll the L2-grain breakdowns up to <=10 L1 rows,
    // amount-descending. NEVER a second rollup loop.
    final rows = rollupCategoryBreakdownsToL1(
      breakdowns,
      categoryMap,
      topN: 10,
    );

    final donutTotal = rows.fold<int>(0, (sum, r) => sum + r.amount);

    // WR-02 / D-03: when the L1 rollup is truncated to topN (>10 categories had
    // spend), the donut keeps only the top 10 (donutTotal < true total). The
    // residual long-tail is shown as a single neutral, non-tappable "Other"
    // slice/row of (total - donutTotal), so slices + legend percentages
    // reconcile to the TRUE center total (monthly.totalExpenses).
    final otherAmount = total - donutTotal;
    final hasOther = otherAmount > 0;
    // Neutral grey-family swatch (NOT the daily→joy lerp) so "Other" reads as
    // long-tail residue, not an 11th-best category (47-UI-SPEC §WR-02). Palette-
    // resolved — never a hardcoded literal (color_literal_scan guards this).
    final otherColor = palette.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (rows.isNotEmpty)
                PieChart(
                  PieChartData(
                    sections: [
                      for (final entry in rows.asMap().entries)
                        PieChartSectionData(
                          value: entry.value.amount.toDouble(),
                          title: '',
                          color: _colorFor(entry.key, rows.length, palette),
                          radius: 56,
                          // REDES-02 polish: rounded slice ends (fl_chart 1.2.0).
                          cornerRadius: 4,
                        ),
                      // WR-02: neutral long-tail "Other" slice, sorted last.
                      if (hasOther)
                        PieChartSectionData(
                          value: otherAmount.toDouble(),
                          title: '',
                          color: otherColor,
                          radius: 56,
                          cornerRadius: 4,
                        ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 56,
                  ),
                ),
              // D-D2 anchor #1: count-up the center 本月支出 total.
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.analyticsDonutCenterLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: total),
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Text(
                      NumberFormatter.formatCurrency(value, 'JPY', locale),
                      style: AppTextStyles.amountMedium.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 10 L1-rollup legend ROWS — each fully tappable → drill push (D-B1).
        for (final entry in rows.asMap().entries)
          _LegendRow(
            key: ValueKey('donut_legend_row_${entry.value.categoryId}'),
            color: _colorFor(entry.key, rows.length, palette),
            name: CategoryLocalizationService.resolveFromId(
              entry.value.categoryId,
              locale,
            ),
            amount: NumberFormatter.formatCurrency(
              entry.value.amount,
              'JPY',
              locale,
            ),
            // WR-02 reconciliation: percentages divide by the TRUE total (NOT
            // donutTotal), so all rows incl. Other reconcile to the center.
            percent: total > 0
                ? (entry.value.amount / total * 100).round()
                : 0,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CategoryDrillDownScreen(
                  bookId: bookId,
                  l1CategoryId: entry.value.categoryId,
                ),
              ),
            ),
          ),
        // WR-02: the long-tail "Other" legend row — neutral swatch, sorted last,
        // NON-tappable (no L1 ancestor to drill into → null onTap, no chevron).
        if (hasOther)
          _LegendRow(
            key: const ValueKey('donut_legend_row_other'),
            color: otherColor,
            name: l10n.analyticsCategoryDonutOther,
            amount: NumberFormatter.formatCurrency(otherAmount, 'JPY', locale),
            percent: total > 0 ? (otherAmount / total * 100).round() : 0,
            onTap: null,
          ),
      ],
    );
  }

  Color _colorFor(int index, int total, AppPalette palette) {
    if (total <= 1) return palette.daily;
    final t = index / (total - 1);
    return Color.lerp(palette.daily, palette.joy, t)!;
  }
}

/// A single L1 legend row. By default fully tappable (D-B1 — the ROW is the
/// affordance, not the pie slice). Shows the swatch + category name + ¥ amount +
/// %.
///
/// WR-02: when [onTap] is null (the "Other" long-tail rollup), the row renders
/// non-interactive — no `InkWell`, no chevron — because there is no single L1 to
/// drill into.
class _LegendRow extends StatelessWidget {
  const _LegendRow({
    super.key,
    required this.color,
    required this.name,
    required this.amount,
    required this.percent,
    required this.onTap,
  });

  final Color color;
  final String name;
  final String amount;
  final int percent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tappable = onTap != null;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodyMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: AppTextStyles.amountSmall.copyWith(
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$percent%',
              textAlign: TextAlign.end,
              style: AppTextStyles.caption.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
          if (tappable)
            Icon(Icons.chevron_right, size: 18, color: palette.textSecondary)
          else
            // Keep the trailing width consistent with tappable rows.
            const SizedBox(width: 18),
        ],
      ),
    );
    if (!tappable) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// The nested 悦己 joybar drawer (round-5 r5 mock §2b, D2). Watches
/// [joyCategoryAmountsProvider] with the SAME key tuple the de-registered
/// `JoySpendCard` used, and renders a connector chip («▾ 把悦己这一块放大看看»)
/// followed by a pink-bordered drawer: drawer-top (data-derived ¥ total +
/// category count) + subtitle + the shared [JoySpendDrawerBody] (count-up header
/// + joybar + legend) + neutral caption.
///
/// The drawer's own error branch invalidates `joyCategoryAmountsProvider`
/// (the donut's error branch owns the monthlyReport target). Pink chrome resolves
/// via `Color.lerp(palette.joy, palette.joyLight, …)` — NO 裸hex (RESEARCH A5).
/// ADR-012-neutral: just where joy spend went, no ranking/target/cross-period.
class _JoyDrawer extends ConsumerWidget {
  const _JoyDrawer({
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
    final palette = context.palette;
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');

    final amountsAsync = ref.watch(
      joyCategoryAmountsProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        joyMetricVariant: joyMetricVariant,
      ),
    );

    return amountsAsync.when(
      data: (amounts) {
        final total = amounts.fold<int>(0, (sum, a) => sum + a.amount);
        // Pink drawer border, derived (no joyBorder token exists) — RESEARCH A5.
        final drawerBorderColor = Color.lerp(
          palette.joy,
          palette.joyLight,
          0.55,
        )!;

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connector: dashed stem + pink chip.
              _JoyConnector(
                label: l10n.analyticsJoyDrawerConnector,
                stemColor: drawerBorderColor,
                chipBg: palette.joyLight,
                chipBorder: drawerBorderColor,
                chipText: palette.joyText,
              ),
              const SizedBox(height: 10),
              // The pink-bordered drawer card.
              Container(
                decoration: BoxDecoration(
                  color: palette.card,
                  border: Border.all(color: drawerBorderColor),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.analyticsJoyDrawerTitle(
                              NumberFormatter.formatCurrency(
                                total,
                                'JPY',
                                locale,
                              ),
                            ),
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: palette.joyText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.analyticsJoyDrawerCount(amounts.length),
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            color: palette.joyText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.analyticsJoyDrawerSubtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 13),
                    JoySpendDrawerBody(amounts: amounts),
                    const SizedBox(height: 12),
                    Text(
                      l10n.analyticsJoyDrawerCaption,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: palette.textTertiary,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 120),
      error: (_, _) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: AnalyticsCardErrorState(
          onRetry: () => ref.invalidate(
            joyCategoryAmountsProvider(
              bookId: bookId,
              startDate: startDate,
              endDate: endDate,
              joyMetricVariant: joyMetricVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// The connector between the donut hero and the joy drawer: a centered dashed
/// vertical stem + a pink pill chip with a ▾ arrow (round-5 r5 mock `.joy-connector`).
class _JoyConnector extends StatelessWidget {
  const _JoyConnector({
    required this.label,
    required this.stemColor,
    required this.chipBg,
    required this.chipBorder,
    required this.chipText,
  });

  final String label;
  final Color stemColor;
  final Color chipBg;
  final Color chipBorder;
  final Color chipText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dashed 2px stem (three short dashes).
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: SizedBox(
              width: 2,
              height: 4,
              child: DecoratedBox(decoration: BoxDecoration(color: stemColor)),
            ),
          ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
          decoration: BoxDecoration(
            color: chipBg,
            border: Border.all(color: chipBorder),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.keyboard_arrow_down, size: 14, color: chipText),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: chipText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
