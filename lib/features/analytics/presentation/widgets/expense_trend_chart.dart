import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../application/i18n/formatter_service.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/expense_trend.dart';

/// Line chart showing 6-month expense and income trend.
class ExpenseTrendChart extends StatelessWidget {
  const ExpenseTrendChart({super.key, required this.trendData});

  final ExpenseTrendData trendData;

  @override
  Widget build(BuildContext context) {
    if (trendData.months.isEmpty) {
      return const SizedBox.shrink();
    }

    final allValues = trendData.months
        .expand((m) => [m.totalExpenses, m.totalIncome])
        .toList();
    final maxVal = allValues.isEmpty ? 1000 : allValues.reduce(max);
    final maxY = maxVal > 0 ? maxVal.toDouble() * 1.2 : 1000.0;
    final l10n = S.of(context);
    final locale = Localizations.localeOf(context);
    const formatter = FormatterService();

    final expenseSpots = trendData.months.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalExpenses.toDouble());
    }).toList();

    final incomeSpots = trendData.months.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalIncome.toDouble());
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.analyticsSixMonthTrend,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _LegendDot(color: Colors.red, label: l10n.analyticsExpenses),
                const SizedBox(width: 12),
                _LegendDot(color: Colors.green, label: l10n.analyticsIncome),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  maxY: maxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= trendData.months.length) {
                            return const SizedBox.shrink();
                          }
                          final m = trendData.months[idx];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              l10n.analyticsMonthNumberLabel(m.month),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: maxY / 4,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            formatter.formatCompact(value, locale),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withValues(alpha: 0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: incomeSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
