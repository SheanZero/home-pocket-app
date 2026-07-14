import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../generated/app_localizations.dart';
import '../../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../settings/presentation/providers/state_locale.dart';
import '../../../domain/models/within_month_cumulative_trend.dart';
import '../../analytics_card_registry.dart';
import '../../providers/state_analytics.dart';
import '../../providers/state_joy_metric_variant.dart';
import '../analytics_card_error_state.dart';
import '../analytics_segmented_control.dart';
import '../within_month_cumulative_line_chart.dart';
import 'analytics_data_card.dart';

/// The ledger tab a within-month trend can show.
///
/// 总支出 / 日常 are SPEND-side tabs that draw 本月 (solid) + 上月 (dashed)
/// dual lines. 悦己 is the JOY tab — it draws a SINGLE 本月 line with ZERO
/// cross-period reference (D-E1, ADR-012 Pitfall 2).
enum _TrendTab { total, daily, joy }

/// Within-month per-day-cumulative spend trend card (round-5 B card #1, D-E1).
///
/// Mirrors `category_donut_card.dart`'s single-source `ConsumerWidget` +
/// `*RefreshTargets` contract: watches exactly ONE provider family
/// ([withinMonthCumulativeTrendProvider], keyed on a MONTH-anchored value, D-12)
/// and routes its error-retry through the single-source
/// [withinMonthTrendRefreshTargets].
///
/// The pill tabs (总支出 / 日常 / 悦己) are local state held by [_TrendBody];
/// switching tabs only changes which ledger series the [LineChart] draws. The
/// 悦己 tab passes the joy current-month series with NO previous-month list, so
/// the joy chart can NEVER carry a 上月 line (cross-period guard is structural).
///
/// Main numbers are static (the only count-up anchors are the donut center +
/// the 悦己 header, D-D2 — owned by 46-05/06). Card淡入 entrance is the
/// screen-level REDES-03 motion (D-D1) applied at the card-wrap layer — no
/// looping/glow/pulse here. ADR-017: 日常/悦己 vocabulary only.
class WithinMonthTrendCard extends ConsumerWidget {
  const WithinMonthTrendCard({
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
    final ctx = _ctx();
    final targets = withinMonthTrendRefreshTargets(ctx);

    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');

    final trendAsync = ref.watch(
      withinMonthCumulativeTrendProvider(
        bookId: bookId,
        anchor: ctx.trendAnchor,
        joyMetricVariant: joyMetricVariant,
      ),
    );

    return trendAsync.when(
      // round-5 r5 / D2: the「支出趋势」section header above this card already
      // labels it and the mock card body carries no separate title (pills sit at
      // the top), so suppress the card's own header to avoid a double title. The
      // frozen _TrendBody / chart internals (D3) are untouched.
      data: (trend) => AnalyticsDataCard(
        showHeader: false,
        title: S.of(context).analyticsCardTitleWithinMonthTrend,
        caption: S.of(context).analyticsCardCaptionWithinMonthTrend,
        child: _TrendBody(
          trend: trend,
          anchor: ctx.trendAnchor,
          locale: locale,
        ),
      ),
      loading: () => const SizedBox(height: 280),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(targets.single),
      ),
    );
  }

  /// Minimal [AnalyticsCardContext] for this card's single target. `trendAnchor`
  /// is month-anchored from `endDate` (D-12); `isGroupMode`/`locale` are unused
  /// by the targets.
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

/// Single-source refresh targets for [WithinMonthTrendCard] (D-B2) — exactly the
/// `categoryDonutRefreshTargets` shape, keyed on the MONTH-anchored
/// `ctx.trendAnchor` (D-12). The shell `_refresh` union and this card's
/// error-retry both draw from this one list.
List<ProviderBase<Object?>> withinMonthTrendRefreshTargets(
  AnalyticsCardContext ctx,
) => [
  withinMonthCumulativeTrendProvider(
    bookId: ctx.bookId,
    anchor: ctx.trendAnchor,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
];

/// Pill-tab selector + the line chart for the active ledger. Local state lives
/// here so a tab switch never re-watches the provider (D-12 — only the rendered
/// series changes).
class _TrendBody extends StatefulWidget {
  const _TrendBody({
    required this.trend,
    required this.anchor,
    required this.locale,
  });

  final WithinMonthCumulativeTrend trend;

  /// Current-month anchor, threaded to the chart for endpoint annotation dates.
  final DateTime anchor;

  /// Locale for formatting the insight-strip amount.
  final Locale locale;

  @override
  State<_TrendBody> createState() => _TrendBodyState();
}

class _TrendBodyState extends State<_TrendBody> {
  _TrendTab _tab = _TrendTab.total;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);
    final trend = widget.trend;

    // Resolve the active ledger's series. The joy tab gets a SOLID current
    // series and NO previous-month list — there is no previousMonthJoy field on
    // the model by construction (D-E1), so a joy 上月 line is unrepresentable.
    final List<CumulativePoint> current;
    final List<CumulativePoint>? previous;
    final Color color;
    switch (_tab) {
      case _TrendTab.total:
        current = trend.currentMonthTotal;
        previous = trend.previousMonthTotal;
        color = palette.daily;
      case _TrendTab.daily:
        current = trend.currentMonthDaily;
        previous = trend.previousMonthDaily;
        color = palette.daily;
      case _TrendTab.joy:
        current = trend.currentMonthJoy;
        previous = null; // D-E1: zero cross-period on the joy side.
        color = palette.joy;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnalyticsSegmentedControl<_TrendTab>(
          selected: _tab,
          onChanged: (tab) => setState(() => _tab = tab),
          segments: [
            AnalyticsSegment(
              value: _TrendTab.total,
              label: l10n.analyticsKpiTotalLabel,
              optionKey: const ValueKey('trend_tab_total'),
            ),
            AnalyticsSegment(
              value: _TrendTab.daily,
              label: l10n.daily,
              tone: SegmentTone.daily,
              optionKey: const ValueKey('trend_tab_daily'),
            ),
            AnalyticsSegment(
              value: _TrendTab.joy,
              label: l10n.joy,
              tone: SegmentTone.joy,
              optionKey: const ValueKey('trend_tab_joy'),
            ),
          ],
        ),
        // v15 `.analytics-insight` banner between the segmented control and the
        // plot (260714 / task #2). Descriptive delta vs last month — never a
        // target (ADR-012). The joy tab has no previous by design → amount only.
        const SizedBox(height: 10),
        _buildInsight(context, l10n, palette, current, previous),
        const SizedBox(height: 12),
        WithinMonthCumulativeLineChart(
          // Re-key per tab so the chart rebuilds cleanly on a ledger switch.
          key: ValueKey('trend_chart_${_tab.name}'),
          currentMonth: current,
          previousMonth: previous,
          seriesColor: color,
          anchor: widget.anchor,
        ),
        const SizedBox(height: 8),
        // 上月 reference legend only on the spend side (never the joy tab).
        if (previous != null && previous.isNotEmpty)
          Row(
            children: [
              _LegendSwatch(color: color, dashed: false),
              const SizedBox(width: 6),
              Text(
                l10n.analyticsTrendSeriesThisMonth,
                style: AppTextStyles.caption.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              // Matches the chart's 上月 line color exactly (muted gray).
              _LegendSwatch(color: palette.textTertiary, dashed: true),
              const SizedBox(width: 6),
              Text(
                l10n.analyticsTrendSeriesLastMonth,
                style: AppTextStyles.caption.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// The `.analytics-insight` banner: one line of descriptive copy (this-month
  /// amount + optional signed delta vs last month) tinted by the active ledger
  /// (daily-soft for total/daily, joy-soft for joy). Delta is DESCRIPTIVE, never
  /// a target (ADR-012); the joy tab shows the amount only (no cross-period).
  Widget _buildInsight(
    BuildContext context,
    S l10n,
    AppPalette palette,
    List<CumulativePoint> current,
    List<CumulativePoint>? previous,
  ) {
    final bool isJoy = _tab == _TrendTab.joy;
    final bool isTotal = _tab == _TrendTab.total;
    final int curLast = current.isEmpty ? 0 : current.last.cumulativeAmount;
    final int prevLast = (previous == null || previous.isEmpty)
        ? 0
        : previous.last.cumulativeAmount;
    final String amountStr = NumberFormatter.formatCurrency(
      curLast,
      'JPY',
      widget.locale,
    );

    final String text;
    if (isJoy) {
      text = l10n.analyticsTrendInsightJoy(amountStr);
    } else if (prevLast <= 0) {
      // No previous-month reference → drop the "先月より…" clause.
      text = isTotal
          ? l10n.analyticsTrendInsightTotal(amountStr)
          : l10n.analyticsTrendInsightDaily(amountStr);
    } else {
      final int pct = ((curLast - prevLast).abs() / prevLast * 100).round();
      if (pct == 0) {
        // |delta| ≈ 0 → 同水準.
        text = isTotal
            ? l10n.analyticsTrendInsightTotalSame(amountStr)
            : l10n.analyticsTrendInsightDailySame(amountStr);
      } else {
        final String direction = curLast < prevLast ? 'less' : 'more';
        text = isTotal
            ? l10n.analyticsTrendInsightTotalDelta(amountStr, pct, direction)
            : l10n.analyticsTrendInsightDailyDelta(amountStr, pct, direction);
      }
    }

    final IconData icon;
    if (isJoy) {
      icon = Icons.favorite_border;
    } else if (prevLast <= 0 || curLast == prevLast) {
      icon = Icons.trending_flat;
    } else if (curLast < prevLast) {
      icon = Icons.trending_down;
    } else {
      icon = Icons.trending_up;
    }

    final Color bg = isJoy ? palette.joyLight : palette.dailyLight;
    final Color fg = isJoy ? palette.joyText : palette.dailyText;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: fg,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 3,
      child: dashed
          ? Row(
              children: [
                _Dash(color: color),
                const SizedBox(width: 2),
                _Dash(color: color),
                const SizedBox(width: 2),
                _Dash(color: color),
              ],
            )
          : DecoratedBox(decoration: BoxDecoration(color: color)),
    );
  }
}

class _Dash extends StatelessWidget {
  const _Dash({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(decoration: BoxDecoration(color: color)),
    );
  }
}
