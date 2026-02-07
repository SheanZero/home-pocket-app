import 'package:freezed_annotation/freezed_annotation.dart';

part 'month_comparison.freezed.dart';
part 'month_comparison.g.dart';

/// Month-over-month comparison data.
@freezed
abstract class MonthComparison with _$MonthComparison {
  const factory MonthComparison({
    required int previousMonth,
    required int previousYear,
    required int previousIncome,
    required int previousExpenses,
    required double incomeChange,
    required double expenseChange,
  }) = _MonthComparison;

  factory MonthComparison.fromJson(Map<String, dynamic> json) =>
      _$MonthComparisonFromJson(json);
}
