// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_trend.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MonthlyTrend _$MonthlyTrendFromJson(Map<String, dynamic> json) =>
    _MonthlyTrend(
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      totalExpenses: (json['totalExpenses'] as num).toInt(),
      totalIncome: (json['totalIncome'] as num).toInt(),
    );

Map<String, dynamic> _$MonthlyTrendToJson(_MonthlyTrend instance) =>
    <String, dynamic>{
      'year': instance.year,
      'month': instance.month,
      'totalExpenses': instance.totalExpenses,
      'totalIncome': instance.totalIncome,
    };

_ExpenseTrendData _$ExpenseTrendDataFromJson(Map<String, dynamic> json) =>
    _ExpenseTrendData(
      months: (json['months'] as List<dynamic>)
          .map((e) => MonthlyTrend.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ExpenseTrendDataToJson(_ExpenseTrendData instance) =>
    <String, dynamic>{
      'months': instance.months.map((e) => e.toJson()).toList(),
    };
