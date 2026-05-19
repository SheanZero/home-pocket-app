import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_text_styles.dart';
import 'package:home_pocket/features/analytics/domain/models/month_comparison.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/total_spending_kpi_tile.dart';

import '../../../../../helpers/test_localizations.dart';

MonthlyReport _monthlyReport({double? expenseChange}) {
  return MonthlyReport(
    year: 2026,
    month: 5,
    totalIncome: 0,
    totalExpenses: 41200,
    savings: 0,
    savingsRate: 0,
    survivalTotal: 30000,
    soulTotal: 11200,
    categoryBreakdowns: const [],
    dailyExpenses: const [],
    previousMonthComparison: expenseChange == null
        ? null
        : MonthComparison(
            previousMonth: 4,
            previousYear: 2026,
            previousIncome: 0,
            previousExpenses: 38000,
            incomeChange: 0,
            expenseChange: expenseChange,
          ),
  );
}

Widget _buildSubject(MonthlyReport report) {
  return createLocalizedWidget(
    Scaffold(
      body: TotalSpendingKpiTile(
        report: report,
        currencyCode: 'JPY',
        locale: const Locale('ja'),
      ),
    ),
    locale: const Locale('ja'),
  );
}

void main() {
  group('TotalSpendingKpiTile', () {
    testWidgets('renders 総支出 label + amount with tabular figures', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(_monthlyReport()));
      await tester.pumpAndSettle();

      expect(find.text('支出合計'), findsOneWidget);
      expect(find.text('¥41,200'), findsOneWidget);
    });

    testWidgets('omits increased delta even when comparison data exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(_monthlyReport(expenseChange: 8.5)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('MoM'), findsNothing);
      expect(find.text('↑'), findsNothing);
    });

    testWidgets('omits decreased delta even when comparison data exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(_monthlyReport(expenseChange: -8.5)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('MoM'), findsNothing);
      expect(find.text('↓'), findsNothing);
    });

    testWidgets('omits sub-line when previousMonthComparison is null', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(_monthlyReport()));
      await tester.pumpAndSettle();

      expect(find.textContaining('MoM'), findsNothing);
    });

    testWidgets('uses AppTextStyles.amountLarge for primary value', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(_monthlyReport()));
      await tester.pumpAndSettle();

      final amountText = tester.widget<Text>(find.text('¥41,200'));
      expect(amountText.style?.fontSize, AppTextStyles.amountLarge.fontSize);
      expect(
        amountText.style?.fontFeatures,
        AppTextStyles.amountLarge.fontFeatures,
      );
    });
  });
}
