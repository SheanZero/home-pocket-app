import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/models/best_joy_moment_row.dart';
import '../../features/analytics/domain/models/ledger_snapshot.dart';
import '../../features/analytics/domain/models/per_category_joy_breakdown.dart';
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
    EntrySource? entrySourceFilter,
  }) async {
    final result = await _dao.getMonthlyTotals(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
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
    EntrySource? entrySourceFilter,
    String type = 'expense',
  }) async {
    final results = await _dao.getCategoryTotals(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
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
    EntrySource? entrySourceFilter,
    String type = 'expense',
  }) async {
    final results = await _dao.getDailyTotals(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
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
    EntrySource? entrySourceFilter,
  }) async {
    final results = await _dao.getLedgerTotals(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
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
  Future<JoyFullnessOverview> getJoyFullnessOverview({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    final result = await _dao.getJoyFullnessOverview(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );

    return JoyFullnessOverview(
      avgSatisfaction: result.avgSatisfaction,
      count: result.count,
    );
  }

  @override
  Future<List<SatisfactionScoreBucket>> getSatisfactionDistribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    final results = await _dao.getSatisfactionDistribution(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );

    return results
        .map(
          (row) => SatisfactionScoreBucket(score: row.score, count: row.count),
        )
        .toList();
  }

  @override
  Future<List<JoyRowSample>> getJoyRowsForJoyContribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    return _dao.getJoyRowsForJoyContribution(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );
  }

  @override
  Future<BestJoyMomentRow?> getBestJoyMoment({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    return _dao.getBestJoyMoment(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );
  }

  @override
  Future<LargestMonthlyExpense?> getLargestMonthlyExpense({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    return _dao.getLargestMonthlyExpense(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );
  }

  @override
  Future<SharedJoyCategoryAggregate?> getSharedJoyCategoryInsight({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    return _dao.getSharedJoyCategoryInsight(
      bookIds: bookIds,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );
  }

  @override
  Future<List<PerCategoryJoyBreakdownItem>> getPerCategoryJoyBreakdown({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    final raws = await _dao.getPerCategoryJoyBreakdown(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );
    return raws
        .map(
          (r) => PerCategoryJoyBreakdownItem(
            categoryId: r.categoryId,
            avgSatisfaction: r.avgSatisfaction,
            totalCount: r.totalCount,
          ),
        )
        .toList();
  }

  @override
  Future<List<PerCategoryJoyBreakdownItem>>
  getPerCategoryJoyBreakdownAcrossBooks({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    final raws = await _dao.getPerCategoryJoyBreakdownAcrossBooks(
      bookIds: bookIds,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );
    return raws
        .map(
          (r) => PerCategoryJoyBreakdownItem(
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
    EntrySource? entrySourceFilter,
  }) {
    return _dao.getLedgerSnapshot(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );
  }

  @override
  Future<List<LedgerSnapshotRow>> getLedgerSnapshotAcrossBooks({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    return _dao.getLedgerSnapshotAcrossBooks(
      bookIds: bookIds,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );
  }
}
