import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_progress.freezed.dart';
part 'budget_progress.g.dart';

/// Budget consumption status thresholds.
enum BudgetStatus {
  /// Below 80% of budget.
  safe,

  /// 80-99% of budget.
  warning,

  /// 100%+ of budget (exceeded).
  exceeded,
}

/// Budget tracking for a single category.
@freezed
abstract class BudgetProgress with _$BudgetProgress {
  const factory BudgetProgress({
    required String categoryId,
    required String categoryName,
    required String icon,
    required String color,
    required int budgetAmount,
    required int spentAmount,
    required double percentage,
    required BudgetStatus status,
    required int remainingAmount,
  }) = _BudgetProgress;

  factory BudgetProgress.fromJson(Map<String, dynamic> json) =>
      _$BudgetProgressFromJson(json);
}
