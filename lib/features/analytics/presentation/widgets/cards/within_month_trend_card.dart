import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../generated/app_localizations.dart';
import '../../../domain/models/within_month_cumulative_trend.dart';
import '../../analytics_card_registry.dart';
import '../../providers/state_analytics.dart';
import '../../providers/state_joy_metric_variant.dart';
import '../analytics_card_error_state.dart';
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

    final trendAsync = ref.watch(
      withinMonthCumulativeTrendProvider(
        bookId: bookId,
        anchor: ctx.trendAnchor,
        joyMetricVariant: joyMetricVariant,
      ),
    );

    return trendAsync.when(
      data: (trend) => AnalyticsDataCard(
        title: S.of(context).analyticsCardTitleWithinMonthTrend,
        caption: S.of(context).analyticsCardCaptionWithinMonthTrend,
        child: _TrendBody(trend: trend),
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
  const _TrendBody({required this.trend});

  final WithinMonthCumulativeTrend trend;

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
        _PillTabs(
          active: _tab,
          onChanged: (tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: 12),
        WithinMonthCumulativeLineChart(
          // Re-key per tab so the chart rebuilds cleanly on a ledger switch.
          key: ValueKey('trend_chart_${_tab.name}'),
          currentMonth: current,
          previousMonth: previous,
          seriesColor: color,
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
              _LegendSwatch(
                color: Color.lerp(color, palette.card, 0.55)!,
                dashed: true,
              ),
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
}

/// The 总支出 / 日常 / 悦己 pill-tab strip.
class _PillTabs extends StatelessWidget {
  const _PillTabs({required this.active, required this.onChanged});

  final _TrendTab active;
  final ValueChanged<_TrendTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Wrap(
      spacing: 8,
      children: [
        _Pill(
          key: const ValueKey('trend_tab_total'),
          label: l10n.analyticsKpiTotalLabel,
          selected: active == _TrendTab.total,
          onTap: () => onChanged(_TrendTab.total),
        ),
        _Pill(
          key: const ValueKey('trend_tab_daily'),
          label: l10n.daily,
          selected: active == _TrendTab.daily,
          onTap: () => onChanged(_TrendTab.daily),
        ),
        _Pill(
          key: const ValueKey('trend_tab_joy'),
          label: l10n.joy,
          selected: active == _TrendTab.joy,
          onTap: () => onChanged(_TrendTab.joy),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bg = selected ? palette.daily : palette.card;
    final fg = selected ? palette.card : palette.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.daily, width: 1),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: fg,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
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
