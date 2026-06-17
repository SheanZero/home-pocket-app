import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../domain/models/within_month_cumulative_trend.dart';

/// Within-month per-day-cumulative spend trend chart (round-5 B card #1, D-E1).
///
/// Renders ONE or TWO [LineChartBarData] series over a fl_chart 1.2.0
/// [LineChart], mirroring the donut chart's fl_chart wiring idiom
/// (`category_spend_donut_chart.dart`) — `SizedBox(height:)` + `context.palette`
/// colors, never hardcoded hex.
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
    this.previousMonth,
    this.height = 220,
  });

  /// Current-month running-cumulative points (1..n). Required, drawn as a SOLID
  /// 本月 line.
  final List<CumulativePoint> currentMonth;

  /// Previous-month running-cumulative points — the spend-side 上月 reference,
  /// drawn DASHED. `null`/empty ⇒ no reference line (the joy contract, D-E1).
  final List<CumulativePoint>? previousMonth;

  /// The 本月 line color (ADR-019 palette: `palette.daily` for total/daily,
  /// `palette.joy` for the joy tab). The 上月 reference is a muted derivative.
  final Color seriesColor;

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
    final maxDay = _maxDay();
    final maxY = _maxY();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: maxDay.toDouble(),
          minY: 0,
          maxY: maxY,
          // Hide superfluous grid/axes per the mock — the line is the signal.
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            // 本月 — solid, stroke-cap round (always present).
            LineChartBarData(
              spots: _spots(currentMonth),
              color: seriesColor,
              barWidth: 2.5,
              isCurved: false,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            // 上月 — dashed reference, ONLY on the spend side (never joy, D-E1).
            if (_hasReference)
              LineChartBarData(
                spots: _spots(previousMonth!),
                color: Color.lerp(seriesColor, palette.card, 0.55),
                barWidth: 1.5,
                isCurved: false,
                dashArray: const [4, 4],
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
          ],
        ),
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
}
