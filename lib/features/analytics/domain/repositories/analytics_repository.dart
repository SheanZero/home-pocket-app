import '../../../accounting/domain/models/entry_source.dart';
import '../models/analytics_aggregate.dart';
import '../models/best_joy_moment_row.dart';
import '../models/ledger_snapshot.dart';
import '../models/per_category_soul_breakdown.dart';

/// Abstract repository for analytics aggregate queries.
abstract class AnalyticsRepository {
  Future<DateTime?> getEarliestTransactionTimestamp({required String bookId});

  Future<MonthlyTotals> getMonthlyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  });

  Future<List<CategoryTotal>> getCategoryTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
    String type = 'expense',
  });

  Future<List<DailyTotal>> getDailyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
    String type = 'expense',
  });

  Future<List<LedgerTotal>> getLedgerTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  });

  /// HAPPY-01 / D-03 — average soul satisfaction + sample count over MTD.
  Future<SoulSatisfactionOverview> getSoulSatisfactionOverview({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  });

  /// HAPPY-03 / D-05 — distribution of soul satisfaction scores 1-10.
  Future<List<SatisfactionScoreBucket>> getSatisfactionDistribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  });

  /// ADR-016 §2 — row-wise tuples for Dart-layer Joy contribution fold.
  Future<List<SoulRowSample>> getSoulRowsForJoyContribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  });

  /// HAPPY-04 / D-06 — argmax soul tx by sat DESC, amount DESC, timestamp DESC.
  Future<BestJoyMomentRow?> getBestJoyMoment({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  });

  /// FAMILY-02 / D-08 — category argmax across books with min-N=3 guard.
  Future<SharedJoyCategoryAggregate?> getSharedJoyCategoryInsight({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  });

  /// STATSUI-06 / D-15 — largest expense across TOTAL ledger.
  Future<LargestMonthlyExpense?> getLargestMonthlyExpense({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  });

  /// HAPPY-V2-01 / D-07 — per-category soul satisfaction aggregate (returns
  /// ALL categories as domain items; use case applies min-N=3 + Other rollup).
  /// Returns domain [PerCategorySoulBreakdownItem]; the data-layer transient
  /// row tuple (a `(categoryId, avgSatisfaction, totalCount)` triple defined
  /// inside the analytics DAO) is converted at the impl boundary in the
  /// concrete repository (CLAUDE.md Pitfall #2 — Domain MUST NOT import the
  /// DAO row type).
  Future<List<PerCategorySoulBreakdownItem>> getPerCategorySoulBreakdown({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  });

  /// HAPPY-V2-01 / D-16, D-17 — family-aggregate variant using
  /// `book_id IN (...)` (NEVER per-member group per ADR-012 §6). Returns
  /// domain [PerCategorySoulBreakdownItem]s pooled across all member books.
  Future<List<PerCategorySoulBreakdownItem>>
  getPerCategorySoulBreakdownAcrossBooks({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  });

  /// STATSUI-V2-01 / D-01..D-04 — per-ledger `(count, total spend)` snapshot
  /// for the engagement-axis surface. [LedgerSnapshotRow] is a domain-layer
  /// thin row class (see `lib/features/analytics/domain/models/ledger_snapshot.dart`).
  Future<List<LedgerSnapshotRow>> getLedgerSnapshot({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  });

  /// STATSUI-V2-01 / D-18 — family-aggregate ledger snapshot via
  /// `book_id IN (...)` (NEVER per-member group per ADR-012 §6).
  Future<List<LedgerSnapshotRow>> getLedgerSnapshotAcrossBooks({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  });
}
