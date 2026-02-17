import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/daily_expense.dart';
import 'package:home_pocket/features/analytics/domain/models/month_comparison.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';

void main() {
  group('CategoryBreakdown', () {
    test('creates with required fields', () {
      const breakdown = CategoryBreakdown(
        categoryId: 'cat_food',
        categoryName: 'Food',
        icon: '🍕',
        color: '#FF0000',
        amount: 50000,
        percentage: 33.3,
        transactionCount: 15,
      );

      expect(breakdown.categoryId, 'cat_food');
      expect(breakdown.categoryName, 'Food');
      expect(breakdown.amount, 50000);
      expect(breakdown.percentage, 33.3);
      expect(breakdown.transactionCount, 15);
      expect(breakdown.budgetAmount, isNull);
      expect(breakdown.budgetProgress, isNull);
    });

    test('creates with optional budget fields', () {
      const breakdown = CategoryBreakdown(
        categoryId: 'cat_food',
        categoryName: 'Food',
        icon: '🍕',
        color: '#FF0000',
        amount: 50000,
        percentage: 33.3,
        transactionCount: 15,
        budgetAmount: 80000,
        budgetProgress: 62.5,
      );

      expect(breakdown.budgetAmount, 80000);
      expect(breakdown.budgetProgress, 62.5);
    });

    test('toJson and fromJson roundtrip', () {
      const original = CategoryBreakdown(
        categoryId: 'cat_food',
        categoryName: 'Food',
        icon: '🍕',
        color: '#FF0000',
        amount: 50000,
        percentage: 33.3,
        transactionCount: 15,
      );

      final json = original.toJson();
      final restored = CategoryBreakdown.fromJson(json);
      expect(restored, original);
    });
  });

  group('MonthlyReport', () {
    test('creates with all fields', () {
      final report = MonthlyReport(
        year: 2026,
        month: 2,
        totalIncome: 300000,
        totalExpenses: 200000,
        savings: 100000,
        savingsRate: 33.3,
        survivalTotal: 150000,
        soulTotal: 50000,
        categoryBreakdowns: const [],
        dailyExpenses: const [],
      );

      expect(report.year, 2026);
      expect(report.month, 2);
      expect(report.totalIncome, 300000);
      expect(report.totalExpenses, 200000);
      expect(report.savings, 100000);
      expect(report.savingsRate, 33.3);
      expect(report.survivalTotal, 150000);
      expect(report.soulTotal, 50000);
      expect(report.previousMonthComparison, isNull);
    });

    test('supports month comparison', () {
      final report = MonthlyReport(
        year: 2026,
        month: 2,
        totalIncome: 300000,
        totalExpenses: 200000,
        savings: 100000,
        savingsRate: 33.3,
        survivalTotal: 150000,
        soulTotal: 50000,
        categoryBreakdowns: const [],
        dailyExpenses: const [],
        previousMonthComparison: const MonthComparison(
          previousMonth: 1,
          previousYear: 2026,
          previousIncome: 280000,
          previousExpenses: 180000,
          incomeChange: 7.1,
          expenseChange: 11.1,
        ),
      );

      expect(report.previousMonthComparison, isNotNull);
      expect(report.previousMonthComparison!.incomeChange, 7.1);
    });

    test('copyWith creates new instance', () {
      final report = MonthlyReport(
        year: 2026,
        month: 2,
        totalIncome: 300000,
        totalExpenses: 200000,
        savings: 100000,
        savingsRate: 33.3,
        survivalTotal: 150000,
        soulTotal: 50000,
        categoryBreakdowns: const [],
        dailyExpenses: const [],
      );

      final updated = report.copyWith(totalIncome: 350000);
      expect(updated.totalIncome, 350000);
      expect(updated.totalExpenses, 200000); // Unchanged
      expect(report.totalIncome, 300000); // Original unchanged
    });
  });

  group('DailyExpense', () {
    test('creates with required fields', () {
      final expense = DailyExpense(date: DateTime(2026, 2, 1), amount: 5000);

      expect(expense.date, DateTime(2026, 2, 1));
      expect(expense.amount, 5000);
    });

    test('toJson and fromJson roundtrip', () {
      final original = DailyExpense(date: DateTime(2026, 2, 1), amount: 5000);

      final json = original.toJson();
      final restored = DailyExpense.fromJson(json);
      expect(restored, original);
    });
  });

  group('MonthComparison', () {
    test('creates with required fields', () {
      const comparison = MonthComparison(
        previousMonth: 1,
        previousYear: 2026,
        previousIncome: 280000,
        previousExpenses: 180000,
        incomeChange: 7.1,
        expenseChange: -5.5,
      );

      expect(comparison.previousMonth, 1);
      expect(comparison.previousYear, 2026);
      expect(comparison.incomeChange, 7.1);
      expect(comparison.expenseChange, -5.5);
    });
  });
}
