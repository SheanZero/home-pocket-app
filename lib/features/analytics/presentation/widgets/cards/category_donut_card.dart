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
        child: _DonutHero(
          breakdowns: monthly.categoryBreakdowns,
          total: monthly.totalExpenses,
          // The legend's L1 rollup needs the category map; while it loads, fall
          // back to an empty map (the donut + center total still render).
          categoryMap: categoryMapAsync.value ?? const {},
          bookId: bookId,
        ),
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
    joyMetricVariant: joyMetricVariant,
    isGroupMode: false,
    locale: const Locale('ja'),
  );
}

/// Single-source refresh targets for [CategoryDonutCard] (D-B2). Watches the
/// `monthlyReportProvider` keyed on book/start/end/variant.
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
