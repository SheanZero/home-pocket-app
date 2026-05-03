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

/// Satisfaction score distribution for the selected month.
@riverpod
Future<List<SatisfactionScoreBucket>> satisfactionDistribution(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
}) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final range = _monthRange(year, month);
  return repository.getSatisfactionDistribution(
    bookId: bookId,
    startDate: range.start,
    endDate: range.end,
  );
}

({DateTime start, DateTime end}) _monthRange(int year, int month) {
  return (
    start: DateTime(year, month),
    end: DateTime(year, month + 1).subtract(const Duration(microseconds: 1)),
  );
}
