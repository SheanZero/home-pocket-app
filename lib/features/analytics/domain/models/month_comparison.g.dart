// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'month_comparison.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MonthComparison _$MonthComparisonFromJson(Map<String, dynamic> json) =>
    _MonthComparison(
      previousMonth: (json['previousMonth'] as num).toInt(),
      previousYear: (json['previousYear'] as num).toInt(),
      previousIncome: (json['previousIncome'] as num).toInt(),
      previousExpenses: (json['previousExpenses'] as num).toInt(),
      incomeChange: (json['incomeChange'] as num).toDouble(),
      expenseChange: (json['expenseChange'] as num).toDouble(),
    );

Map<String, dynamic> _$MonthComparisonToJson(_MonthComparison instance) =>
    <String, dynamic>{
      'previousMonth': instance.previousMonth,
      'previousYear': instance.previousYear,
      'previousIncome': instance.previousIncome,
      'previousExpenses': instance.previousExpenses,
      'incomeChange': instance.incomeChange,
      'expenseChange': instance.expenseChange,
    };
