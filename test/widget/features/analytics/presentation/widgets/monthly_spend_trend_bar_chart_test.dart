import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_colors.dart';
import 'package:home_pocket/features/analytics/domain/models/expense_trend.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  ExpenseTrendData sixMonthTrend() {
    return const ExpenseTrendData(
      months: [
        MonthlyTrend(
          year: 2025,
          month: 12,
          totalExpenses: 320000,
          totalIncome: 0,
        ),
        MonthlyTrend(
          year: 2026,
          month: 1,
          totalExpenses: 410000,
          totalIncome: 0,
        ),
        MonthlyTrend(
          year: 2026,
          month: 2,
          totalExpenses: 380000,
          totalIncome: 0,
        ),
        MonthlyTrend(
          year: 2026,
          month: 3,
          totalExpenses: 520000,
          totalIncome: 0,
        ),
        MonthlyTrend(
          year: 2026,
          month: 4,
          totalExpenses: 600000,
          totalIncome: 0,
        ),
        MonthlyTrend(
          year: 2026,
          month: 5,
          totalExpenses: 1200000,
          totalIncome: 0,
        ),
      ],
    );
  }

  testWidgets('renders 6 bars when ExpenseTrendData has 6 months', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        MonthlySpendTrendBarChart(
          trendData: sixMonthTrend(),
          selectedYear: 2026,
          selectedMonth: 5,
          locale: const Locale('ja'),
        ),
        locale: const Locale('ja'),
      ),
    );

    final chart = tester.widget<BarChart>(find.byType(BarChart));

    expect(chart.data.barGroups, hasLength(6));
  });

  testWidgets('current month bar uses heavier accent', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        MonthlySpendTrendBarChart(
          trendData: sixMonthTrend(),
          selectedYear: 2026,
          selectedMonth: 5,
          locale: const Locale('ja'),
        ),
        locale: const Locale('ja'),
      ),
    );

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    final currentRod = chart.data.barGroups[5].barRods.single;
    final previousRod = chart.data.barGroups[4].barRods.single;

    expect(currentRod.color, AppColors.survival);
    expect(
      currentRod.borderSide.width,
      greaterThan(previousRod.borderSide.width),
    );
  });

  testWidgets('Y-axis labels use formatCompact', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        MonthlySpendTrendBarChart(
          trendData: sixMonthTrend(),
          selectedYear: 2026,
          selectedMonth: 5,
          locale: const Locale('ja'),
        ),
        locale: const Locale('ja'),
      ),
    );

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    final leftTitles = chart.data.titlesData.leftTitles.sideTitles
        .getTitlesWidget(
          1200000,
          TitleMeta(
            min: 0,
            max: 1200000,
            parentAxisSize: 200,
            axisPosition: 0,
            appliedInterval: 300000,
            sideTitles: const SideTitles(showTitles: true),
            formattedValue: '1200000',
            axisSide: AxisSide.left,
            rotationQuarterTurns: 0,
          ),
        );

    expect(leftTitles, isA<Text>());
    expect((leftTitles as Text).data, isNot('1200000'));
    expect(leftTitles.data, contains('120'));
  });
}
