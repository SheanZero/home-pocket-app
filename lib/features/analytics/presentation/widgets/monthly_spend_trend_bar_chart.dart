import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/expense_trend.dart';

/// STATSUI-06: 6-month total spending trend for the 時間 group.
class MonthlySpendTrendBarChart extends StatelessWidget {
  const MonthlySpendTrendBarChart({
    super.key,
    required this.trendData,
    required this.selectedYear,
    required this.selectedMonth,
    required this.locale,
  });

  final ExpenseTrendData trendData;
  final int selectedYear;
  final int selectedMonth;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final months = trendData.months;
    if (months.isEmpty) {
      return const SizedBox.shrink();
    }

    final palette = context.palette;
    final l10n = S.of(context);
    const formatter = FormatterService();
    final maxAmount = months.map((month) => month.totalExpenses).reduce(max);
    final chartMaxY = maxAmount > 0 ? maxAmount * 1.15 : 1.0;
    final interval = chartMaxY / 4;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: chartMaxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= months.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.analyticsMonthNumberLabel(months[index].month),
                      style: AppTextStyles.caption.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    formatter.formatCompact(value, locale),
                    style: AppTextStyles.amountSmall.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (final entry in months.asMap().entries)
              _barGroupFor(entry.key, entry.value, palette),
          ],
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = months[group.x];
                return BarTooltipItem(
                  '${month.year}/${month.month}\n'
                  '${formatter.formatCompact(month.totalExpenses, locale)}',
                  AppTextStyles.amountSmall.copyWith(color: palette.card),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  BarChartGroupData _barGroupFor(int index, MonthlyTrend month, AppPalette palette) {
    final isCurrent =
        month.year == selectedYear && month.month == selectedMonth;

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: month.totalExpenses.toDouble(),
          color: isCurrent
              ? palette.daily
              : palette.daily.withValues(alpha: 0.30),
          borderSide: BorderSide(
            color: palette.daily,
            width: isCurrent ? 2 : 1,
          ),
          width: 18,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
}
