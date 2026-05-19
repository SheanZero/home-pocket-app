import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/analytics_aggregate.dart';
import '../../domain/models/expense_trend.dart';
import '../../domain/models/monthly_report.dart';
import 'repository_providers.dart';

part 'state_analytics.g.dart';

/// Monthly report for the selected window.
@riverpod
Future<MonthlyReport> monthlyReport(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final useCase = ref.watch(getMonthlyReportUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
  );
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

/// Satisfaction score distribution for the selected window.
@riverpod
Future<List<SatisfactionScoreBucket>> satisfactionDistribution(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final useCase = ref.watch(getSatisfactionDistributionUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
  );
}
