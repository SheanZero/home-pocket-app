// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BudgetProgress _$BudgetProgressFromJson(Map<String, dynamic> json) =>
    _BudgetProgress(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      budgetAmount: (json['budgetAmount'] as num).toInt(),
      spentAmount: (json['spentAmount'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
      status: $enumDecode(_$BudgetStatusEnumMap, json['status']),
      remainingAmount: (json['remainingAmount'] as num).toInt(),
    );

Map<String, dynamic> _$BudgetProgressToJson(_BudgetProgress instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'icon': instance.icon,
      'color': instance.color,
      'budgetAmount': instance.budgetAmount,
      'spentAmount': instance.spentAmount,
      'percentage': instance.percentage,
      'status': _$BudgetStatusEnumMap[instance.status]!,
      'remainingAmount': instance.remainingAmount,
    };

const _$BudgetStatusEnumMap = {
  BudgetStatus.safe: 'safe',
  BudgetStatus.warning: 'warning',
  BudgetStatus.exceeded: 'exceeded',
};
