import '../models/analytics_aggregate.dart';

/// Abstract repository for analytics aggregate queries.
abstract class AnalyticsRepository {
  Future<MonthlyTotals> getMonthlyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<CategoryTotal>> getCategoryTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
  });

  Future<List<DailyTotal>> getDailyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
  });

  Future<List<LedgerTotal>> getLedgerTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
