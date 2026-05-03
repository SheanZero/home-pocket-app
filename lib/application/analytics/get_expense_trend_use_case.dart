import '../../features/analytics/domain/models/expense_trend.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';

/// Fetches multi-month expense/income trend data.
class GetExpenseTrendUseCase {
  GetExpenseTrendUseCase({required AnalyticsRepository analyticsRepository})
    : _analyticsRepository = analyticsRepository;

  final AnalyticsRepository _analyticsRepository;

  Future<ExpenseTrendData> execute({
    required String bookId,
    required DateTime anchor,
    int monthCount = 6,
  }) async {
    final trends = <MonthlyTrend>[];

    for (int i = monthCount - 1; i >= 0; i--) {
      final date = DateTime(anchor.year, anchor.month - i, 1);
      final year = date.year;
      final month = date.month;

      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final totals = await _analyticsRepository.getMonthlyTotals(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      );

      trends.add(
        MonthlyTrend(
          year: year,
          month: month,
          totalExpenses: totals.totalExpenses,
          totalIncome: totals.totalIncome,
        ),
      );
    }

    return ExpenseTrendData(months: trends);
  }
}
