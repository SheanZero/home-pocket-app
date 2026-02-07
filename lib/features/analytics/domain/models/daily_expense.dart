import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_expense.freezed.dart';
part 'daily_expense.g.dart';

/// Daily spending amount for trend visualization.
@freezed
abstract class DailyExpense with _$DailyExpense {
  const factory DailyExpense({required DateTime date, required int amount}) =
      _DailyExpense;

  factory DailyExpense.fromJson(Map<String, dynamic> json) =>
      _$DailyExpenseFromJson(json);
}
