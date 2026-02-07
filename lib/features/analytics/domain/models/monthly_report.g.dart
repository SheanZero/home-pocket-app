// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CategoryBreakdown _$CategoryBreakdownFromJson(Map<String, dynamic> json) =>
    _CategoryBreakdown(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      amount: (json['amount'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
      transactionCount: (json['transactionCount'] as num).toInt(),
      budgetAmount: (json['budgetAmount'] as num?)?.toInt(),
      budgetProgress: (json['budgetProgress'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$CategoryBreakdownToJson(_CategoryBreakdown instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'icon': instance.icon,
      'color': instance.color,
      'amount': instance.amount,
      'percentage': instance.percentage,
      'transactionCount': instance.transactionCount,
      'budgetAmount': instance.budgetAmount,
      'budgetProgress': instance.budgetProgress,
    };

_MonthlyReport _$MonthlyReportFromJson(Map<String, dynamic> json) =>
    _MonthlyReport(
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      totalIncome: (json['totalIncome'] as num).toInt(),
      totalExpenses: (json['totalExpenses'] as num).toInt(),
      savings: (json['savings'] as num).toInt(),
      savingsRate: (json['savingsRate'] as num).toDouble(),
      survivalTotal: (json['survivalTotal'] as num).toInt(),
      soulTotal: (json['soulTotal'] as num).toInt(),
      categoryBreakdowns: (json['categoryBreakdowns'] as List<dynamic>)
          .map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyExpenses: (json['dailyExpenses'] as List<dynamic>)
          .map((e) => DailyExpense.fromJson(e as Map<String, dynamic>))
          .toList(),
      previousMonthComparison: json['previousMonthComparison'] == null
          ? null
          : MonthComparison.fromJson(
              json['previousMonthComparison'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$MonthlyReportToJson(_MonthlyReport instance) =>
    <String, dynamic>{
      'year': instance.year,
      'month': instance.month,
      'totalIncome': instance.totalIncome,
      'totalExpenses': instance.totalExpenses,
      'savings': instance.savings,
      'savingsRate': instance.savingsRate,
      'survivalTotal': instance.survivalTotal,
      'soulTotal': instance.soulTotal,
      'categoryBreakdowns': instance.categoryBreakdowns
          .map((e) => e.toJson())
          .toList(),
      'dailyExpenses': instance.dailyExpenses.map((e) => e.toJson()).toList(),
      'previousMonthComparison': instance.previousMonthComparison?.toJson(),
    };
