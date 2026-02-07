import 'package:freezed_annotation/freezed_annotation.dart';

import 'daily_expense.dart';
import 'month_comparison.dart';

part 'monthly_report.freezed.dart';
part 'monthly_report.g.dart';

/// Category-level spending breakdown within a monthly report.
@freezed
abstract class CategoryBreakdown with _$CategoryBreakdown {
  const factory CategoryBreakdown({
    required String categoryId,
    required String categoryName,
    required String icon,
    required String color,
    required int amount,
    required double percentage,
    required int transactionCount,
    int? budgetAmount,
    double? budgetProgress,
  }) = _CategoryBreakdown;

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) =>
      _$CategoryBreakdownFromJson(json);
}

/// Complete monthly financial report.
@freezed
abstract class MonthlyReport with _$MonthlyReport {
  const factory MonthlyReport({
    required int year,
    required int month,
    required int totalIncome,
    required int totalExpenses,
    required int savings,
    required double savingsRate,
    required int survivalTotal,
    required int soulTotal,
    required List<CategoryBreakdown> categoryBreakdowns,
    required List<DailyExpense> dailyExpenses,
    MonthComparison? previousMonthComparison,
  }) = _MonthlyReport;

  factory MonthlyReport.fromJson(Map<String, dynamic> json) =>
      _$MonthlyReportFromJson(json);
}
