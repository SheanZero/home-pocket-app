import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/models/best_joy_moment_row.dart';
import '../../features/analytics/domain/models/ledger_snapshot.dart';
import '../../features/analytics/domain/models/per_category_soul_breakdown.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../daos/analytics_dao.dart';

/// Bridges analytics domain queries to Drift analytics DAO.
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl({required AnalyticsDao dao}) : _dao = dao;

  final AnalyticsDao _dao;

  @override
  Future<DateTime?> getEarliestTransactionTimestamp({required String bookId}) {
    return _dao.getEarliestTransactionTimestamp(bookId: bookId);
  }

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

  @override
  Future<SoulSatisfactionOverview> getSoulSatisfactionOverview({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await _dao.getSoulSatisfactionOverview(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );

    return SoulSatisfactionOverview(
      avgSatisfaction: result.avgSatisfaction,
      count: result.count,
    );
  }

  @override
  Future<List<SatisfactionScoreBucket>> getSatisfactionDistribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final results = await _dao.getSatisfactionDistribution(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );

    return results
        .map(
          (row) => SatisfactionScoreBucket(score: row.score, count: row.count),
        )
        .toList();
  }

  @override
  Future<List<SoulRowSample>> getSoulRowsForJoyContribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _dao.getSoulRowsForJoyContribution(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<BestJoyMomentRow?> getBestJoyMoment({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _dao.getBestJoyMoment(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<LargestMonthlyExpense?> getLargestMonthlyExpense({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _dao.getLargestMonthlyExpense(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<SharedJoyCategoryAggregate?> getSharedJoyCategoryInsight({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _dao.getSharedJoyCategoryInsight(
      bookIds: bookIds,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<PerCategorySoulBreakdownItem>> getPerCategorySoulBreakdown({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final raws = await _dao.getPerCategorySoulBreakdown(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );
    return raws
        .map(
          (r) => PerCategorySoulBreakdownItem(
            categoryId: r.categoryId,
            avgSatisfaction: r.avgSatisfaction,
            totalCount: r.totalCount,
          ),
        )
        .toList();
  }

  @override
  Future<List<PerCategorySoulBreakdownItem>>
  getPerCategorySoulBreakdownAcrossBooks({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final raws = await _dao.getPerCategorySoulBreakdownAcrossBooks(
      bookIds: bookIds,
      startDate: startDate,
      endDate: endDate,
    );
    return raws
        .map(
          (r) => PerCategorySoulBreakdownItem(
            categoryId: r.categoryId,
            avgSatisfaction: r.avgSatisfaction,
            totalCount: r.totalCount,
          ),
        )
        .toList();
  }

  @override
  Future<List<LedgerSnapshotRow>> getLedgerSnapshot({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _dao.getLedgerSnapshot(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<LedgerSnapshotRow>> getLedgerSnapshotAcrossBooks({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _dao.getLedgerSnapshotAcrossBooks(
      bookIds: bookIds,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
