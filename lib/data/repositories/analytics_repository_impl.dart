import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../daos/analytics_dao.dart';

/// Bridges analytics domain queries to Drift analytics DAO.
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl({required AnalyticsDao dao}) : _dao = dao;

  final AnalyticsDao _dao;

  @override
  Future<MonthlyTotals> getMonthlyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await _dao.getMonthlyTotals(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );

    return MonthlyTotals(
      totalIncome: result.totalIncome,
      totalExpenses: result.totalExpenses,
    );
  }

  @override
  Future<List<CategoryTotal>> getCategoryTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
  }) async {
    final results = await _dao.getCategoryTotals(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      type: type,
    );

    return results
        .map(
          (row) => CategoryTotal(
            categoryId: row.categoryId,
            totalAmount: row.totalAmount,
            transactionCount: row.transactionCount,
          ),
        )
        .toList();
  }

  @override
  Future<List<DailyTotal>> getDailyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
  }) async {
    final results = await _dao.getDailyTotals(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      type: type,
    );

    return results
        .map((row) => DailyTotal(date: row.date, totalAmount: row.totalAmount))
        .toList();
  }

  @override
  Future<List<LedgerTotal>> getLedgerTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final results = await _dao.getLedgerTotals(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );

    return results
        .map(
          (row) => LedgerTotal(
            ledgerType: row.ledgerType,
            totalAmount: row.totalAmount,
          ),
        )
        .toList();
  }
}
