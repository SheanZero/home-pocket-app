// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailyExpense _$DailyExpenseFromJson(Map<String, dynamic> json) =>
    _DailyExpense(
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toInt(),
    );

Map<String, dynamic> _$DailyExpenseToJson(_DailyExpense instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'amount': instance.amount,
    };
