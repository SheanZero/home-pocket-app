import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense_trend.freezed.dart';
part 'expense_trend.g.dart';

/// A single month's totals for multi-month trend analysis.
@freezed
abstract class MonthlyTrend with _$MonthlyTrend {
  const factory MonthlyTrend({
    required int year,
    required int month,
    required int totalExpenses,
    required int totalIncome,
  }) = _MonthlyTrend;

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) =>
      _$MonthlyTrendFromJson(json);
}

/// Multi-month expense/income trend data.
@freezed
abstract class ExpenseTrendData with _$ExpenseTrendData {
  const factory ExpenseTrendData({required List<MonthlyTrend> months}) =
      _ExpenseTrendData;

  factory ExpenseTrendData.fromJson(Map<String, dynamic> json) =>
      _$ExpenseTrendDataFromJson(json);
}
