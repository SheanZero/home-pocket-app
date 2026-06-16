import '../../features/accounting/domain/models/entry_source.dart';
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
    EntrySource? entrySourceFilter,
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
        entrySourceFilter: entrySourceFilter,
      );

      // Per-ledger split via the existing primitive, using the SAME
      // (startDate, endDate, entrySourceFilter) window as getMonthlyTotals
      // (RESEARCH Flag C — never derive one across query boundaries).
      final ledgerTotals = await _analyticsRepository.getLedgerTotals(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        entrySourceFilter: entrySourceFilter,
      );

      // Zero-default pre-initialization: getLedgerTotals omits zero-spend
      // ledger rows, so a daily-only (or joy-only) month must still yield 0
      // for the absent ledger (Pitfall 1).
      int dailyTotal = 0;
      int joyTotal = 0;
      for (final lt in ledgerTotals) {
        if (lt.ledgerType == 'daily') {
          dailyTotal = lt.totalAmount;
        } else if (lt.ledgerType == 'joy') {
          joyTotal = lt.totalAmount;
        }
      }

      trends.add(
        MonthlyTrend(
          year: year,
          month: month,
          totalExpenses: totals.totalExpenses,
          totalIncome: totals.totalIncome,
          dailyTotal: dailyTotal,
          joyTotal: joyTotal,
        ),
      );
    }

    return ExpenseTrendData(months: trends);
  }
}
