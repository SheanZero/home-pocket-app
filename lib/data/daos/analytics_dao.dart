import 'package:drift/drift.dart';

import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/models/best_joy_moment_row.dart';
import '../../features/analytics/domain/models/ledger_snapshot.dart';
import '../app_database.dart';

/// Aggregate query result for monthly totals.
class MonthlyTotalsResult {
  final int totalIncome;
  final int totalExpenses;

  const MonthlyTotalsResult({
    required this.totalIncome,
    required this.totalExpenses,
  });
}

/// Aggregate query result for category totals.
class CategoryTotalResult {
  final String categoryId;
  final int totalAmount;
  final int transactionCount;

  const CategoryTotalResult({
    required this.categoryId,
    required this.totalAmount,
    required this.transactionCount,
  });
}

/// Aggregate query result for daily totals.
class DailyTotalResult {
  final DateTime date;
  final int totalAmount;

  const DailyTotalResult({required this.date, required this.totalAmount});
}

/// Aggregate query result for ledger type totals.
class LedgerTotalResult {
  final String ledgerType;
  final int totalAmount;

  const LedgerTotalResult({
    required this.ledgerType,
    required this.totalAmount,
  });
}

/// Aggregate result for soul satisfaction overview.
class SatisfactionOverviewResult {
  final double avgSatisfaction;
  final int count;

  const SatisfactionOverviewResult({
    required this.avgSatisfaction,
    required this.count,
  });
}

/// Aggregate result for satisfaction score distribution.
class SatisfactionDistributionResult {
  final int score;
  final int count;

  const SatisfactionDistributionResult({
    required this.score,
    required this.count,
  });
}

/// DAO-only transient row tuple for `getPerCategorySoulBreakdown*` queries.
///
/// Repository impl in `lib/data/repositories/analytics_repository_impl.dart`
/// converts each row to the domain `PerCategorySoulBreakdownItem`
/// (see `lib/features/analytics/domain/models/per_category_soul_breakdown.dart`).
/// The `Raw` suffix marks this as a transient data-layer row — DO NOT export
/// across the data → domain boundary. The domain interface MUST return
/// `List<PerCategorySoulBreakdownItem>`, not `List<PerCategorySoulRowRaw>`
/// (CLAUDE.md Pitfall #2 — Domain → Data forbidden, enforced by `import_guard`).
class PerCategorySoulRowRaw {
  final String categoryId;
  final double avgSatisfaction;
  final int totalCount;

  const PerCategorySoulRowRaw({
    required this.categoryId,
    required this.avgSatisfaction,
    required this.totalCount,
  });
}

/// Data access object for analytics aggregate queries.
///
/// Uses database-level SUM/GROUP BY for performance (<2s target).
class AnalyticsDao {
  AnalyticsDao(this._db);

  final AppDatabase _db;

  /// D-01 / HAPPY-05: ledger + lifecycle filter ONLY. NO satisfaction predicate.
  /// Single source of truth: every joy aggregator MUST compose via interpolation.
  static const String _soulExpenseFilter =
      "ledger_type = 'joy' AND type = 'expense' AND is_deleted = 0";

  /// Mirror of [_soulExpenseFilter] for daily ledger.
  ///
  /// Defined as a constant to prevent predicate drift (per RESEARCH
  /// §Established Patterns). NEVER aggregate `joy_fullness` over rows
  /// matching this filter — `transactions.joy_fullness` defaults to `2`
  /// for daily rows (ADR-014 D-10 / Phase 16 D-04 type-system gate).
  static const String _survivalExpenseFilter =
      "ledger_type = 'daily' AND type = 'expense' AND is_deleted = 0";

  /// Earliest non-deleted transaction timestamp for a book.
  Future<DateTime?> getEarliestTransactionTimestamp({
    required String bookId,
  }) async {
    final results = await _db
        .customSelect(
          'SELECT timestamp FROM transactions '
          'WHERE book_id = ? AND is_deleted = 0 '
          'ORDER BY timestamp ASC '
          'LIMIT 1',
          variables: [Variable.withString(bookId)],
        )
        .get();

    if (results.isEmpty) {
      return null;
    }
    return results.first.read<DateTime>('timestamp');
  }

  /// Get total income and expenses for a given month.
  Future<MonthlyTotalsResult> getMonthlyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    final entrySourceClause = entrySourceFilter != null
        ? ' AND entry_source = ?'
        : '';
    final results = await _db
        .customSelect(
          'SELECT type, SUM(amount) as total FROM transactions '
          'WHERE book_id = ? AND is_deleted = 0 '
          'AND timestamp >= ? AND timestamp <= ?'
          '$entrySourceClause '
          'GROUP BY type',
          variables: [
            Variable.withString(bookId),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (entrySourceFilter != null)
              Variable.withString(entrySourceFilter.name),
          ],
        )
        .get();

    int totalIncome = 0;
    int totalExpenses = 0;

    for (final row in results) {
      final type = row.read<String>('type');
      final total = row.read<int>('total');
      if (type == 'income') {
        totalIncome = total;
      } else if (type == 'expense') {
        totalExpenses = total;
      }
    }

    return MonthlyTotalsResult(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
    );
  }

  /// Get spending totals grouped by category for a date range.
  Future<List<CategoryTotalResult>> getCategoryTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
    String type = 'expense',
  }) async {
    final entrySourceClause = entrySourceFilter != null
        ? ' AND entry_source = ?'
        : '';
    final results = await _db
        .customSelect(
          'SELECT category_id, SUM(amount) as total, COUNT(*) as tx_count '
          'FROM transactions '
          'WHERE book_id = ? AND is_deleted = 0 AND type = ? '
          'AND timestamp >= ? AND timestamp <= ?'
          '$entrySourceClause '
          'GROUP BY category_id '
          'ORDER BY total DESC',
          variables: [
            Variable.withString(bookId),
            Variable.withString(type),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (entrySourceFilter != null)
              Variable.withString(entrySourceFilter.name),
          ],
        )
        .get();

    return results
        .map(
          (row) => CategoryTotalResult(
            categoryId: row.read<String>('category_id'),
            totalAmount: row.read<int>('total'),
            transactionCount: row.read<int>('tx_count'),
          ),
        )
        .toList();
  }

  /// Get daily expense totals for a given month.
  Future<List<DailyTotalResult>> getDailyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
    String type = 'expense',
  }) async {
    final entrySourceClause = entrySourceFilter != null
        ? ' AND entry_source = ?'
        : '';
    final results = await _db
        .customSelect(
          'SELECT DATE(timestamp, \'unixepoch\', \'localtime\') as day, SUM(amount) as total '
          'FROM transactions '
          'WHERE book_id = ? AND is_deleted = 0 AND type = ? '
          'AND timestamp >= ? AND timestamp <= ?'
          '$entrySourceClause '
          'GROUP BY day '
          'ORDER BY day ASC',
          variables: [
            Variable.withString(bookId),
            Variable.withString(type),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (entrySourceFilter != null)
              Variable.withString(entrySourceFilter.name),
          ],
        )
        .get();

    return results
        .map(
          (row) => DailyTotalResult(
            date: DateTime.parse(row.read<String>('day')),
            totalAmount: row.read<int>('total'),
          ),
        )
        .toList();
  }

  /// Get totals grouped by ledger type for a date range.
  Future<List<LedgerTotalResult>> getLedgerTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    final entrySourceClause = entrySourceFilter != null
        ? ' AND entry_source = ?'
        : '';
    final results = await _db
        .customSelect(
          'SELECT ledger_type, SUM(amount) as total FROM transactions '
          'WHERE book_id = ? AND is_deleted = 0 AND type = \'expense\' '
          'AND timestamp >= ? AND timestamp <= ?'
          '$entrySourceClause '
          'GROUP BY ledger_type',
          variables: [
            Variable.withString(bookId),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (entrySourceFilter != null)
              Variable.withString(entrySourceFilter.name),
          ],
        )
        .get();

    return results
        .map(
          (row) => LedgerTotalResult(
            ledgerType: row.read<String>('ledger_type'),
            totalAmount: row.read<int>('total'),
          ),
        )
        .toList();
  }

  /// Get average satisfaction and count for soul transactions in a date range.
  Future<SatisfactionOverviewResult> getSoulSatisfactionOverview({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    final entrySourceClause = entrySourceFilter != null
        ? ' AND entry_source = ?'
        : '';
    final results = await _db
        .customSelect(
          'SELECT AVG(joy_fullness) as avg_sat, COUNT(*) as cnt '
          'FROM transactions '
          'WHERE book_id = ? AND $_soulExpenseFilter '
          'AND timestamp >= ? AND timestamp <= ?'
          '$entrySourceClause',
          variables: [
            Variable.withString(bookId),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (entrySourceFilter != null)
              Variable.withString(entrySourceFilter.name),
          ],
        )
        .get();

    if (results.isEmpty) {
      return const SatisfactionOverviewResult(avgSatisfaction: 0, count: 0);
    }

    final row = results.first;
    return SatisfactionOverviewResult(
      avgSatisfaction: (row.read<double?>('avg_sat') ?? 0),
      count: row.read<int>('cnt'),
    );
  }

  /// Get satisfaction score distribution for soul transactions.
  Future<List<SatisfactionDistributionResult>> getSatisfactionDistribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    final entrySourceClause = entrySourceFilter != null
        ? ' AND entry_source = ?'
        : '';
    final results = await _db
        .customSelect(
          'SELECT joy_fullness as score, COUNT(*) as cnt '
          'FROM transactions '
          'WHERE book_id = ? AND $_soulExpenseFilter '
          'AND timestamp >= ? AND timestamp <= ?'
          '$entrySourceClause '
          'GROUP BY joy_fullness '
          'ORDER BY joy_fullness ASC',
          variables: [
            Variable.withString(bookId),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (entrySourceFilter != null)
              Variable.withString(entrySourceFilter.name),
          ],
        )
        .get();

    return results
        .map(
          (row) => SatisfactionDistributionResult(
            score: row.read<int>('score'),
            count: row.read<int>('cnt'),
          ),
        )
        .toList();
  }

  /// STATSUI-06 / D-15: largest expense across total ledger.
  Future<LargestMonthlyExpense?> getLargestMonthlyExpense({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    final entrySourceClause = entrySourceFilter != null
        ? ' AND entry_source = ?'
        : '';
    final results = await _db
        .customSelect(
          'SELECT id, amount, category_id, timestamp '
          'FROM transactions '
          'WHERE book_id = ? AND is_deleted = 0 AND type = ? '
          'AND timestamp >= ? AND timestamp <= ?'
          '$entrySourceClause '
          'ORDER BY amount DESC, timestamp DESC '
          'LIMIT 1',
          variables: [
            Variable.withString(bookId),
            Variable.withString('expense'),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (entrySourceFilter != null)
              Variable.withString(entrySourceFilter.name),
          ],
        )
        .get();

    if (results.isEmpty) return null;

    final row = results.first;
    return LargestMonthlyExpense(
      transactionId: row.read<String>('id'),
      amount: row.read<int>('amount'),
      categoryId: row.read<String>('category_id'),
      timestamp: row.read<DateTime>('timestamp'),
    );
  }

  /// HAPPY-04 / D-06: pure sat-sort argmax, amount DESC tiebreak, no JPY 500 floor.
  /// Returns null when no soul tx exists in the window.
  Future<BestJoyMomentRow?> getBestJoyMoment({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    final entrySourceClause = entrySourceFilter != null
        ? ' AND entry_source = ?'
        : '';
    final results = await _db
        .customSelect(
          'SELECT id, amount, joy_fullness, category_id, timestamp '
          'FROM transactions '
          'WHERE book_id = ? AND $_soulExpenseFilter '
          'AND timestamp >= ? AND timestamp <= ?'
          '$entrySourceClause '
          'ORDER BY joy_fullness DESC, amount DESC, timestamp DESC '
          'LIMIT 1',
          variables: [
            Variable.withString(bookId),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (entrySourceFilter != null)
              Variable.withString(entrySourceFilter.name),
          ],
        )
        .get();

    if (results.isEmpty) return null;

    final row = results.first;
    return BestJoyMomentRow(
      transactionId: row.read<String>('id'),
      amount: row.read<int>('amount'),
      joyFullness: row.read<int>('joy_fullness'),
      categoryId: row.read<String>('category_id'),
      timestamp: row.read<DateTime>('timestamp'),
    );
  }

  /// ADR-016 §2: row-wise (amount, sat) pull for Dart-layer Joy contribution.
  /// Performance trade-off accepted vs SUM/GROUP BY (D-04, ADR-013); typical
  /// monthly soul tx count 10-100 per book: negligible row volume.
  Future<List<SoulRowSample>> getSoulRowsForJoyContribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    final entrySourceClause = entrySourceFilter != null
        ? ' AND entry_source = ?'
        : '';
    final results = await _db
        .customSelect(
          'SELECT amount, joy_fullness '
          'FROM transactions '
          'WHERE book_id = ? AND $_soulExpenseFilter '
          'AND timestamp >= ? AND timestamp <= ?'
          '$entrySourceClause',
          variables: [
            Variable.withString(bookId),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (entrySourceFilter != null)
              Variable.withString(entrySourceFilter.name),
          ],
        )
        .get();

    return results
        .map(
          (row) => SoulRowSample(
            amount: row.read<int>('amount'),
            joyFullness: row.read<int>('joy_fullness'),
          ),
        )
        .toList();
  }

  /// FAMILY-02 / D-08: category argmax across multiple books with min-N=3 guard.
  /// Tie-break: AVG DESC -> COUNT DESC -> category_id ASC.
  /// Returns null when bookIds empty OR no category meets min-N=3.
  Future<SharedJoyCategoryAggregate?> getSharedJoyCategoryInsight({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    if (bookIds.isEmpty) return null;

    final entrySourceClause = entrySourceFilter != null
        ? ' AND entry_source = ?'
        : '';
    final placeholders = List.filled(bookIds.length, '?').join(', ');
    final results = await _db
        .customSelect(
          'SELECT category_id, AVG(joy_fullness) as avg_sat, COUNT(*) as cnt '
          'FROM transactions '
          'WHERE book_id IN ($placeholders) AND $_soulExpenseFilter '
          'AND timestamp >= ? AND timestamp <= ?'
          '$entrySourceClause '
          'GROUP BY category_id '
          'HAVING COUNT(*) >= 3 '
          'ORDER BY avg_sat DESC, cnt DESC, category_id ASC '
          'LIMIT 1',
          variables: [
            ...bookIds.map(Variable.withString),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (entrySourceFilter != null)
              Variable.withString(entrySourceFilter.name),
          ],
        )
        .get();

    if (results.isEmpty) return null;

    final row = results.first;
    return SharedJoyCategoryAggregate(
      categoryId: row.read<String>('category_id'),
      avgSatisfaction: row.read<double>('avg_sat'),
      totalCount: row.read<int>('cnt'),
    );
  }

  /// HAPPY-V2-01 / D-07: per-category soul satisfaction aggregate for one book.
  ///
  /// Returns ALL categories (NO HAVING) sorted by `avg_sat DESC, cnt DESC,
  /// category_id ASC`. Low-N rows (count < 3) are intentionally included so
  /// the use case can fold them into the Other row (D-08 / D-10) — applying
  /// min-N at the DAO layer would hide categories the Other-row count needs.
  ///
  /// Mirrors [getSharedJoyCategoryInsight] (analytics_dao.dart line 410-444)
  /// minus `HAVING COUNT(*) >= 3` and `LIMIT 1`.
  ///
  /// Returns the DAO-only row type [PerCategorySoulRowRaw]; the repository
  /// impl converts to the domain `PerCategorySoulBreakdownItem` at the layer
  /// boundary (CLAUDE.md Pitfall #2).
  Future<List<PerCategorySoulRowRaw>> getPerCategorySoulBreakdown({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    final entrySourceClause = entrySourceFilter != null
        ? ' AND entry_source = ?'
        : '';
    final results = await _db
        .customSelect(
          'SELECT category_id, AVG(joy_fullness) as avg_sat, COUNT(*) as cnt '
          'FROM transactions '
          'WHERE book_id = ? AND $_soulExpenseFilter '
          'AND timestamp >= ? AND timestamp <= ?'
          '$entrySourceClause '
          'GROUP BY category_id '
          'ORDER BY avg_sat DESC, cnt DESC, category_id ASC',
          variables: [
            Variable.withString(bookId),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (entrySourceFilter != null)
              Variable.withString(entrySourceFilter.name),
          ],
        )
        .get();

    return results
        .map(
          (row) => PerCategorySoulRowRaw(
            categoryId: row.read<String>('category_id'),
            avgSatisfaction: row.read<double>('avg_sat'),
            totalCount: row.read<int>('cnt'),
          ),
        )
        .toList();
  }

  /// HAPPY-V2-01 / D-16, D-17: family-aggregate variant of
  /// [getPerCategorySoulBreakdown] using `book_id IN (...)`.
  ///
  /// NEVER groups by `book_id` per ADR-012 §6 — rows are pooled across all
  /// member books and only grouped by `category_id`. Empty `bookIds`
  /// short-circuits to `const []` (no DB call).
  Future<List<PerCategorySoulRowRaw>> getPerCategorySoulBreakdownAcrossBooks({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    if (bookIds.isEmpty) return const [];

    final entrySourceClause = entrySourceFilter != null
        ? ' AND entry_source = ?'
        : '';
    final placeholders = List.filled(bookIds.length, '?').join(', ');
    final results = await _db
        .customSelect(
          'SELECT category_id, AVG(joy_fullness) as avg_sat, COUNT(*) as cnt '
          'FROM transactions '
          'WHERE book_id IN ($placeholders) AND $_soulExpenseFilter '
          'AND timestamp >= ? AND timestamp <= ?'
          '$entrySourceClause '
          'GROUP BY category_id '
          'ORDER BY avg_sat DESC, cnt DESC, category_id ASC',
          variables: [
            ...bookIds.map(Variable.withString),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (entrySourceFilter != null)
              Variable.withString(entrySourceFilter.name),
          ],
        )
        .get();

    return results
        .map(
          (row) => PerCategorySoulRowRaw(
            categoryId: row.read<String>('category_id'),
            avgSatisfaction: row.read<double>('avg_sat'),
            totalCount: row.read<int>('cnt'),
          ),
        )
        .toList();
  }

  /// STATSUI-V2-01 / D-01..D-04: per-ledger `(count, total spend)` snapshot.
  ///
  /// Mirrors [getLedgerTotals] (analytics_dao.dart line 214-241) but adds
  /// `COUNT(*)` so the use case can build [SoulLedgerSnapshot] +
  /// [SurvivalLedgerSnapshot] from one DB round-trip (per RESEARCH A5).
  ///
  /// Does NOT aggregate `joy_fullness` — survival rows default-2 would
  /// poison the aggregate (D-04 anti-toxicity reverse pattern). The Soul
  /// column's `avgSatisfaction` is computed separately via
  /// [getSoulSatisfactionOverview].
  ///
  /// Returns the domain [LedgerSnapshotRow] (Data → Domain import allowed).
  Future<List<LedgerSnapshotRow>> getLedgerSnapshot({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    final entrySourceClause = entrySourceFilter != null
        ? ' AND entry_source = ?'
        : '';
    final results = await _db
        .customSelect(
          'SELECT ledger_type, SUM(amount) as total, COUNT(*) as cnt '
          'FROM transactions '
          'WHERE book_id = ? '
          'AND ($_soulExpenseFilter OR $_survivalExpenseFilter) '
          'AND timestamp >= ? AND timestamp <= ?'
          '$entrySourceClause '
          'GROUP BY ledger_type',
          variables: [
            Variable.withString(bookId),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (entrySourceFilter != null)
              Variable.withString(entrySourceFilter.name),
          ],
        )
        .get();

    return results
        .map(
          (row) => LedgerSnapshotRow(
            ledgerType: row.read<String>('ledger_type'),
            totalAmount: row.read<int>('total'),
            entryCount: row.read<int>('cnt'),
          ),
        )
        .toList();
  }

  /// STATSUI-V2-01 / D-18: family-aggregate variant of [getLedgerSnapshot]
  /// using `book_id IN (...)`.
  ///
  /// NEVER groups by `book_id` per ADR-012 §6 — rows are pooled across all
  /// member books and only grouped by `ledger_type`. Empty `bookIds`
  /// short-circuits to `const []` (no DB call).
  Future<List<LedgerSnapshotRow>> getLedgerSnapshotAcrossBooks({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    if (bookIds.isEmpty) return const [];

    final entrySourceClause = entrySourceFilter != null
        ? ' AND entry_source = ?'
        : '';
    final placeholders = List.filled(bookIds.length, '?').join(', ');
    final results = await _db
        .customSelect(
          'SELECT ledger_type, SUM(amount) as total, COUNT(*) as cnt '
          'FROM transactions '
          'WHERE book_id IN ($placeholders) '
          'AND ($_soulExpenseFilter OR $_survivalExpenseFilter) '
          'AND timestamp >= ? AND timestamp <= ?'
          '$entrySourceClause '
          'GROUP BY ledger_type',
          variables: [
            ...bookIds.map(Variable.withString),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
            if (entrySourceFilter != null)
              Variable.withString(entrySourceFilter.name),
          ],
        )
        .get();

    return results
        .map(
          (row) => LedgerSnapshotRow(
            ledgerType: row.read<String>('ledger_type'),
            totalAmount: row.read<int>('total'),
            entryCount: row.read<int>('cnt'),
          ),
        )
        .toList();
  }
}
