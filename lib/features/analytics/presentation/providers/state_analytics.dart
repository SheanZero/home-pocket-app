import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/analytics_aggregate.dart';
import '../../domain/models/expense_trend.dart';
import '../../domain/models/monthly_report.dart';
import 'repository_providers.dart';

part 'state_analytics.g.dart';

/// Currently selected month for analytics view.
@riverpod
class SelectedMonth extends _$SelectedMonth {
  @override
  DateTime build() => DateTime.now();

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }
}

/// Monthly report for the selected month.
@riverpod
Future<MonthlyReport> monthlyReport(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
}) async {
  final useCase = ref.watch(getMonthlyReportUseCaseProvider);
  return useCase.execute(bookId: bookId, year: year, month: month);
}

/// 6-month expense trend.
@riverpod
Future<ExpenseTrendData> expenseTrend(
  Ref ref, {
  required String bookId,
  required DateTime anchor,
}) async {
  final useCase = ref.watch(getExpenseTrendUseCaseProvider);
  return useCase.execute(bookId: bookId, anchor: anchor);
}

/// Earliest month with a non-deleted transaction in the active book.
@riverpod
Future<DateTime?> earliestTransactionMonth(
  Ref ref, {
  required String bookId,
}) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final timestamp = await repository.getEarliestTransactionTimestamp(
    bookId: bookId,
  );
  if (timestamp == null) {
    return null;
  }
  return DateTime(timestamp.year, timestamp.month);
}

/// Satisfaction score distribution for the selected month.
@riverpod
Future<List<SatisfactionScoreBucket>> satisfactionDistribution(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
}) async {
  final useCase = ref.watch(getSatisfactionDistributionUseCaseProvider);
  return useCase.execute(bookId: bookId, year: year, month: month);
}
