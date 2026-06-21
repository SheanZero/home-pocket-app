import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../domain/models/within_month_cumulative_trend.dart';

/// Within-month per-day-cumulative spend trend chart (round-5 B card #1, D-E1).
///
/// Renders ONE or TWO [LineChartBarData] series over a fl_chart 1.2.0
/// [LineChart] with a left amount axis + horizontal gridlines (from 0), bottom
/// localized day markers spanning the WHOLE displayed month (D-1), a muted-gray
/// dashed 上月 reference (spend side only), and a SINGLE data-anchored endpoint
/// label per drawn line (D-2/D-3/D-4). Colors come from `context.palette`
/// (ADR-019) — never hardcoded hex; labels come from `NumberFormatter` /
/// `DateFormatter` (i18n) — never bare literals.
///
/// CLOCKLESS (D-5): the chart reads NO wall clock. The use case injects
/// "today"/the carry-forward right edge into the series it receives, so the
/// chart renders deterministically from its inputs (golden stability). The
/// comparison day is simply `currentMonth.last.day` (the use case made that the
/// comparison day).
///
/// CROSS-PERIOD GUARD (D-E1, Pitfall 2 — the highest-risk ADR-012 line): the
/// [previousMonth] reference series is OPTIONAL and only ever drawn when a
/// caller passes a non-empty list. The 悦己 (joy) tab passes [previousMonth] as
/// `null`, so a joy chart can NEVER carry a 上月 line — the single-vs-dual
/// distinction is STRUCTURAL, not a runtime flag. Only the spend side
/// (总支出 / 日常) supplies a previous month, and only because it is the
/// recorded ADR-012 §4 carve-out.
///
/// ADR-017: file/widget vocabulary uses 日常/悦己 framing only (no 生存/灵魂).
class WithinMonthCumulativeLineChart extends StatelessWidget {
  const WithinMonthCumulativeLineChart({
    super.key,
    required this.currentMonth,
    required this.seriesColor,
    required this.anchor,
    this.previousMonth,
    this.height = 200,
  });

  /// Current-month running-cumulative points (1..n). Required, drawn as a SOLID
  /// 本月 line.
  final List<CumulativePoint> currentMonth;

  /// Previous-month running-cumulative points — the spend-side 上月 reference,
  /// drawn DASHED. `null`/empty ⇒ no reference line (the joy contract, D-E1).
  final List<CumulativePoint>? previousMonth;

  /// The 本月 line color (ADR-019 palette: `palette.daily` for total/daily,
  /// `palette.joy` for the joy tab). The 上月 reference is a muted neutral gray.
  final Color seriesColor;

  /// The current-month anchor (`DateTime(year, month)`). The whole-month X
  /// extent is `daysInMonth(anchor)` (D-1); endpoint annotation dates are built
  /// as `DateTime(anchor.year, anchor.month, point.day)` — [CumulativePoint.day]
  /// carries no month/year by itself.
  final DateTime anchor;

  final double height;

  /// Plot-area insets used to map a (day, amount) spot to a pixel position for
  /// data-anchored endpoint labels (CONTEXT key_facts). These mirror the axis
  /// `reservedSize` values below.
  static const double _leftReserved = 44;
  static const double _bottomReserved = 22;
  static const double _topPad = 12;

  /// Vertical nudge (px) applied to an endpoint label above/below its point.
  static const double _labelNudge = 14;

  bool get _hasReference =>
      previousMonth != null && previousMonth!.isNotEmpty;

  /// The above/below decision (D-3): the 本月 label sits ABOVE its point when
  /// 本月 ≥ 上月 at the comparison day, BELOW otherwise. The 上月 label uses the
  /// OPPOSITE (negation, D-4). Pure + visible-for-testing.
  static bool labelAbove({
    required int currentEndAmount,
    required int prevAtComparisonAmount,
  }) =>
      currentEndAmount >= prevAtComparisonAmount;

  /// Days in the displayed month, derived from [anchor] (D-1).
  int get _daysInMonth => DateTime(anchor.year, anchor.month + 1, 0).day;

  /// Which day-of-month bottom-axis labels to render: 6 / 12 / 18 / 24 —
  /// multiples of 6, excluding fl_chart's auto min/max edge labels AND the
  /// near-month-end mark so the right edge never crowds (no 28日/30日). Pure +
  /// visible-for-testing.
  static bool showDayAxisLabel(int day, int daysInMonth) =>
      day >= 6 && day % 6 == 0 && day <= daysInMonth - 6;

  /// The previous-month point with the latest `day <= comparisonDay` — 上月 now
  /// spans the whole month, so `.last` is month-end, NOT the comparison day
  /// (CONTEXT key_facts). Returns null when there is no such point.
  CumulativePoint? _prevAtComparison(int comparisonDay) {
    CumulativePoint? found;
    for (final p in previousMonth!) {
      if (p.day <= comparisonDay) {
        found = p;
      } else {
        break;
      }
    }
    return found;
  }

  @override
  Widget build(BuildContext context) {
    if (currentMonth.isEmpty) {
      // Empty-safe placeholder — keeps the card height stable, no throw.
      return SizedBox(height: height);
    }

    final palette = context.palette;
    final locale = Localizations.localeOf(context);
    final daysInMonth = _daysInMonth;
    final maxY = _maxY();
    final yStep = _niceYStep(maxY);
    // Round the axis ceiling up to a whole number of steps so the top gridline
    // and the top tick coincide (no clipped top label).
    var axisMaxY = (maxY / yStep).ceil() * yStep;
    // Headroom guarantee (Part1② / 参考图 #6): the 本月 endpoint label is FORCE-
    // anchored ABOVE its marker. When the data max lands in the top ~20% of the
    // axis there is no room above the point, so the label would clip the top and
    // flip below (the exact 「数字位置不对」 bug). Add one more gridline step so
    // the endpoint always clears the top edge with its label above it.
    if (_dataMax() > axisMaxY * 0.8) {
      axisMaxY += yStep;
    }

    const minX = 1.0;
    final maxX = daysInMonth.toDouble();

    final lastPoint = currentMonth.last;
    final lastSpot = FlSpot(
      lastPoint.day.toDouble(),
      lastPoint.cumulativeAmount.toDouble(),
    );

    // Comparison day = the current line's endpoint day (the use case made this
    // = today/month-end). No clock read here (D-5). The 本月 label is now
    // force-anchored above its endpoint (Part1②), so the 本月/上月 comparison no
    // longer drives the 本月 side; [labelAbove] is retained as a pure helper and
    // still unit-tested (Test 12) for the documented comparison semantic.
    final comparisonDay = lastPoint.day;
    final prevPoint = _hasReference ? _prevAtComparison(comparisonDay) : null;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final plotW = constraints.maxWidth - _leftReserved;
          final plotH = constraints.maxHeight - _bottomReserved - _topPad;

          double px(num day) =>
              _leftReserved + (day - minX) / (maxX - minX) * plotW;
          double py(num amount) =>
              _topPad +
              (1 - (amount - 0) / (axisMaxY - 0)) * plotH;

          final overlays = <Widget>[];

          // Part1② (参考图 #6「应在标注终点 marker 的正上方」): the 本月 label is
          // FORCE-anchored directly ABOVE the endpoint marker (horizontally
          // centered on `px(lastPoint.day)`), regardless of the 本月/上月
          // comparison. `_positionedLabel` still falls back to BELOW only when
          // the above position would clip the top edge (端点贴顶). The 上月 label
          // keeps the opposite-position comparison rule (D-4) so the two labels
          // don't collide.
          const currentLabelAbove = true;
          overlays.add(
            _positionedLabel(
              context: context,
              constraints: constraints,
              x: px(lastPoint.day),
              y: py(lastPoint.cumulativeAmount),
              above: currentLabelAbove,
              child: WithinMonthEndpointAnnotation(
                date: DateTime(anchor.year, anchor.month, lastPoint.day),
                amount: lastPoint.cumulativeAmount,
                locale: locale,
                color: seriesColor,
                isCurrent: true,
                above: currentLabelAbove,
              ),
            ),
          );

          // 上月 endpoint label (spend side only) — anchored at its
          // comparison-day point, placed OPPOSITE to the (now force-above) 本月
          // label (D-4) so it never overlaps. Since 本月 is pinned ABOVE, the
          // 上月 reference is pinned BELOW.
          if (prevPoint != null) {
            const prevAbove = !currentLabelAbove;
            overlays.add(
              _positionedLabel(
                context: context,
                constraints: constraints,
                x: px(prevPoint.day),
                y: py(prevPoint.cumulativeAmount),
                above: prevAbove,
                child: WithinMonthEndpointAnnotation(
                  // 上月 date is the PREVIOUS month at the comparison day.
                  date: DateTime(
                    anchor.year,
                    anchor.month - 1,
                    prevPoint.day,
                  ),
                  amount: prevPoint.cumulativeAmount,
                  locale: locale,
                  color: palette.textTertiary,
                  isCurrent: false,
                  above: prevAbove,
                ),
              ),
            );
          }

          return Stack(
            children: [
              LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: 0,
                  maxY: axisMaxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yStep,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: palette.backgroundDivider,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: _leftReserved,
                        interval: yStep,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            NumberFormatter.formatCompact(value, locale),
                            style: AppTextStyles.legendLabel.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: _bottomReserved,
                        interval: 6,
                        getTitlesWidget: (value, meta) {
                          final day = value.round();
                          // Sparse markers at 6/12/18/24; drop fl_chart's auto
                          // min/max edge labels and the near-month-end mark so
                          // the right edge never crowds (no 28日/30日).
                          if (!showDayAxisLabel(day, daysInMonth)) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              DateFormatter.formatDayOfMonthAxis(day, locale),
                              style: AppTextStyles.legendLabel.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    // 本月 — softened CURVE (Part1①: 角度不要太锐化), stroke-cap
                    // round, endpoint dot at the last spot only (no start dot —
                    // D-2). `preventCurveOverShooting` keeps the smoothed curve
                    // from dipping below the 0 baseline / overshooting points.
                    LineChartBarData(
                      spots: _spots(currentMonth),
                      color: seriesColor,
                      barWidth: 2.5,
                      isCurved: true,
                      curveSmoothness: 0.22,
                      preventCurveOverShooting: true,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        checkToShowDot: (spot, bar) => spot == lastSpot,
                        getDotPainter: (spot, pct, bar, idx) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: seriesColor,
                          strokeWidth: 1.5,
                          strokeColor: palette.card,
                        ),
                      ),
                      // Part1③ (参考图 #8): below-line gradient shadow — series
                      // colour → transparent (top→bottom). Colour is driven by
                      // the passed `seriesColor` (ADR-019 palette, D1) — never a
                      // hardcoded hex. Only the 本月 line fills (上月 stays
                      // unfilled below) to avoid a muddy double fill.
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            seriesColor.withValues(alpha: 0.18),
                            seriesColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                    // 上月 — dashed muted-GRAY reference, ONLY on the spend side
                    // (never joy, D-E1). Same softened curve so both lines read
                    // visually consistent; no below-line fill.
                    if (_hasReference)
                      LineChartBarData(
                        spots: _spots(previousMonth!),
                        color: palette.textTertiary,
                        barWidth: 2,
                        isCurved: true,
                        curveSmoothness: 0.22,
                        preventCurveOverShooting: true,
                        dashArray: const [4, 4],
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                  ],
                ),
              ),
              ...overlays,
            ],
          );
        },
      ),
    );
  }

  /// Positions an endpoint label near a plot pixel, nudged above/below, clamped
  /// so it never overflows the card. The label is roughly [_labelW] × [_labelH].
  // Wide enough that a 2-line endpoint label (date + ¥amount, incl. 7-digit
  // JPY) fits the fixed-width box without wrapping; used for both centering and
  // the on-card clamp.
  static const double _labelW = 92;
  static const double _labelH = 30;

  Widget _positionedLabel({
    required BuildContext context,
    required BoxConstraints constraints,
    required double x,
    required double y,
    required bool above,
    required Widget child,
  }) {
    final maxLeft = constraints.maxWidth - _labelW;
    final maxTop = constraints.maxHeight - _labelH;

    double topFor(bool a) => a ? y - _labelNudge - _labelH : y + _labelNudge;

    // The 本月 label (above==true) is FORCE-anchored ABOVE its marker (Part1②,
    // 参考图 #6). The axis now carries a headroom guarantee (see `axisMaxY`) so
    // the above position clears the top edge; in the rare residual case where it
    // still would clip, PIN it to the top edge (top:0) and keep it above the
    // point — never flip below. The 上月 reference (above==false) still flips UP
    // only when a below position would overflow the bottom edge.
    var top = topFor(above);
    if (above && top < 0) {
      top = 0;
    } else if (!above && top > maxTop) {
      top = topFor(true);
    }

    // Horizontally center the label exactly ON the point: a fixed [_labelW]-wide
    // box whose Column centers its text, so the centering no longer depends on
    // the text's intrinsic width (fixes the left-bias when the content was
    // narrower than _labelW). Clamp the box so it stays on-card near the edges.
    var left = x - _labelW / 2;
    left = left.clamp(0.0, maxLeft < 0 ? 0.0 : maxLeft);
    top = top.clamp(0.0, maxTop < 0 ? 0.0 : maxTop);

    return Positioned(left: left, top: top, width: _labelW, child: child);
  }

  List<FlSpot> _spots(List<CumulativePoint> points) => [
    for (final p in points)
      FlSpot(p.day.toDouble(), p.cumulativeAmount.toDouble()),
  ];

  /// Raw maximum cumulative amount across 本月 (and 上月 when present), with NO
  /// headroom inflation. Drives the endpoint-label top-clearance check.
  int _dataMax() {
    var maxAmount = 0;
    for (final p in currentMonth) {
      if (p.cumulativeAmount > maxAmount) maxAmount = p.cumulativeAmount;
    }
    if (_hasReference) {
      for (final p in previousMonth!) {
        if (p.cumulativeAmount > maxAmount) maxAmount = p.cumulativeAmount;
      }
    }
    return maxAmount;
  }

  double _maxY() {
    final maxAmount = _dataMax();
    // A little headroom so the line never clips the top edge.
    return maxAmount == 0 ? 1 : maxAmount * 1.1;
  }

  /// A "nice" round gridline step yielding ~3–4 horizontal lines from 0.
  /// fl_chart asserts `horizontalInterval > 0`, so this is always positive.
  double _niceYStep(double maxY) {
    if (maxY <= 0) return 1;
    // Aim for ~4 intervals, then round the raw step up to a 1/2/5 × 10^n value.
    final rawStep = maxY / 4;
    final magnitude = _pow10((rawStep).floorLog10());
    final normalized = rawStep / magnitude;
    final double niceNormalized;
    if (normalized <= 1) {
      niceNormalized = 1;
    } else if (normalized <= 2) {
      niceNormalized = 2;
    } else if (normalized <= 5) {
      niceNormalized = 5;
    } else {
      niceNormalized = 10;
    }
    return niceNormalized * magnitude;
  }

  double _pow10(int exp) {
    var result = 1.0;
    if (exp >= 0) {
      for (var i = 0; i < exp; i++) {
        result *= 10;
      }
    } else {
      for (var i = 0; i < -exp; i++) {
        result /= 10;
      }
    }
    return result;
  }
}

extension on double {
  /// floor(log10(this)) for positive values, computed without dart:math import.
  int floorLog10() {
    var value = this;
    var exp = 0;
    if (value >= 1) {
      while (value >= 10) {
        value /= 10;
        exp++;
      }
    } else {
      while (value < 1) {
        value *= 10;
        exp--;
      }
    }
    return exp;
  }
}

/// A small date + amount label rendered at a line's endpoint (D-2/D-3/D-4).
///
/// Visible-for-testing: [isCurrent] distinguishes the 本月 (true) from the 上月
/// (false) label; [above] records the placement so tests can assert the
/// opposite-position rule without pixel math.
class WithinMonthEndpointAnnotation extends StatelessWidget {
  const WithinMonthEndpointAnnotation({
    super.key,
    required this.date,
    required this.amount,
    required this.locale,
    required this.color,
    required this.isCurrent,
    required this.above,
  });

  final DateTime date;
  final int amount;
  final Locale locale;
  final Color color;

  /// True for the 本月 label, false for the 上月 reference label.
  final bool isCurrent;

  /// True when this label is placed ABOVE its point (else below). Records the
  /// comparison/opposite decision for tests.
  final bool above;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormatter.formatShortMonthDay(date, locale);
    final amountLabel = NumberFormatter.formatCurrency(amount, 'JPY', locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dateLabel,
          style: AppTextStyles.legendLabel.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
        Text(
          amountLabel,
          style: AppTextStyles.amountSmall.copyWith(
            fontSize: 10,
            color: color,
          ),
        ),
      ],
    );
  }
}
