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
/// localized day markers, a muted-gray dashed 上月 reference (spend side only),
/// and 本月 start/current endpoint annotations. Colors come from
/// `context.palette` (ADR-019) — never hardcoded hex; labels come from
/// `NumberFormatter` / `DateFormatter` (i18n) — never bare literals.
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
    this.height = 244,
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

  /// The current-month anchor (`DateTime(year, month)`). Endpoint annotation
  /// dates are built as `DateTime(anchor.year, anchor.month, point.day)` —
  /// [CumulativePoint.day] carries no month/year by itself.
  final DateTime anchor;

  final double height;

  bool get _hasReference =>
      previousMonth != null && previousMonth!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (currentMonth.isEmpty) {
      // Empty-safe placeholder — keeps the card height stable, no throw.
      return SizedBox(height: height);
    }

    final palette = context.palette;
    final locale = Localizations.localeOf(context);
    final maxDay = _maxDay();
    final maxY = _maxY();
    final yStep = _niceYStep(maxY);
    // Round the axis ceiling up to a whole number of steps so the top gridline
    // and the top tick coincide (no clipped top label).
    final axisMaxY = (maxY / yStep).ceil() * yStep;

    final firstPoint = currentMonth.first;
    final lastPoint = currentMonth.last;
    final firstSpot = FlSpot(
      firstPoint.day.toDouble(),
      firstPoint.cumulativeAmount.toDouble(),
    );
    final lastSpot = FlSpot(
      lastPoint.day.toDouble(),
      lastPoint.cumulativeAmount.toDouble(),
    );

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          LineChart(
            LineChartData(
              minX: 1,
              maxX: maxDay.toDouble(),
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
                    reservedSize: 44,
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
                    reservedSize: 22,
                    interval: 7,
                    getTitlesWidget: (value, meta) {
                      final day = value.round();
                      // Skip the auto-emitted edge label past maxX to avoid
                      // clutter; show only sparse ~weekly markers.
                      if (day < 1 || day > maxDay) {
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
                // 本月 — solid, stroke-cap round, endpoint dots (always present).
                LineChartBarData(
                  spots: _spots(currentMonth),
                  color: seriesColor,
                  barWidth: 2.5,
                  isCurved: false,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, bar) =>
                        spot == firstSpot || spot == lastSpot,
                    getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                      radius: 3,
                      color: seriesColor,
                      strokeWidth: 1.5,
                      strokeColor: palette.card,
                    ),
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
                // 上月 — dashed muted-GRAY reference, ONLY on the spend side
                // (never joy, D-E1).
                if (_hasReference)
                  LineChartBarData(
                    spots: _spots(previousMonth!),
                    color: palette.textTertiary,
                    barWidth: 2,
                    isCurved: false,
                    dashArray: const [4, 4],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
              ],
            ),
          ),
          // 本月 start + current endpoint annotations (date + amount). Only the
          // 本月 line is annotated (not 上月, not every point) — Feature 4.
          Positioned(
            left: 48,
            top: 4,
            child: _EndpointAnnotation(
              point: firstPoint,
              anchor: anchor,
              locale: locale,
              color: seriesColor,
              alignEnd: false,
            ),
          ),
          Positioned(
            right: 4,
            bottom: 26,
            child: _EndpointAnnotation(
              point: lastPoint,
              anchor: anchor,
              locale: locale,
              color: seriesColor,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _spots(List<CumulativePoint> points) => [
    for (final p in points)
      FlSpot(p.day.toDouble(), p.cumulativeAmount.toDouble()),
  ];

  int _maxDay() {
    var maxDay = 1;
    for (final p in currentMonth) {
      if (p.day > maxDay) maxDay = p.day;
    }
    if (_hasReference) {
      for (final p in previousMonth!) {
        if (p.day > maxDay) maxDay = p.day;
      }
    }
    return maxDay;
  }

  double _maxY() {
    var maxAmount = 0;
    for (final p in currentMonth) {
      if (p.cumulativeAmount > maxAmount) maxAmount = p.cumulativeAmount;
    }
    if (_hasReference) {
      for (final p in previousMonth!) {
        if (p.cumulativeAmount > maxAmount) maxAmount = p.cumulativeAmount;
      }
    }
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

/// A small date + amount label rendered at a 本月 endpoint (Feature 4).
class _EndpointAnnotation extends StatelessWidget {
  const _EndpointAnnotation({
    required this.point,
    required this.anchor,
    required this.locale,
    required this.color,
    required this.alignEnd,
  });

  final CumulativePoint point;
  final DateTime anchor;
  final Locale locale;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final date = DateTime(anchor.year, anchor.month, point.day);
    final dateLabel = DateFormatter.formatShortMonthDay(date, locale);
    final amountLabel = NumberFormatter.formatCurrency(
      point.cumulativeAmount,
      'JPY',
      locale,
    );
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}
