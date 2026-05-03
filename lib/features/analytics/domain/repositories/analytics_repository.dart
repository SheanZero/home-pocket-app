import '../models/analytics_aggregate.dart';
import '../models/best_joy_moment_row.dart';

/// Abstract repository for analytics aggregate queries.
abstract class AnalyticsRepository {
  Future<DateTime?> getEarliestTransactionTimestamp({required String bookId});

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

  /// HAPPY-01 / D-03 — average soul satisfaction + sample count over MTD.
  Future<SoulSatisfactionOverview> getSoulSatisfactionOverview({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// HAPPY-03 / D-05 — distribution of soul satisfaction scores 1-10.
  Future<List<SatisfactionScoreBucket>> getSatisfactionDistribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// HAPPY-02 / D-04 — row-wise (amount, sat) tuples for Dart-layer PTVF fold.
  Future<List<SoulRowSample>> getSoulRowsForPtvf({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// STATSUI-01 / D-05 — row-wise daily tuples for Dart-layer PTVF fold.
  Future<List<DailySoulRowSampleWithDay>> getDailySoulRowsForPtvf({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// HAPPY-04 / D-06 — argmax soul tx by sat DESC, amount DESC, timestamp DESC.
  Future<BestJoyMomentRow?> getBestJoyMoment({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// FAMILY-02 / D-08 — category argmax across books with min-N=3 guard.
  Future<SharedJoyCategoryAggregate?> getSharedJoyCategoryInsight({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// STATSUI-06 / D-15 — largest expense across TOTAL ledger.
  Future<LargestMonthlyExpense?> getLargestMonthlyExpense({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
