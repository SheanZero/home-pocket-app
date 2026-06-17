import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/analytics/domain/models/per_day_joy_count.dart';
import '../../shared/constants/sort_config.dart';

/// Computes per-day JOY COUNT (笔数) for the active month — the 小确幸 calendar
/// heatmap depth (D-C1, Phase 46).
///
/// Why this is new: the existing AnalyticsDao daily-totals SQL path has no
/// ledger filter and returns SUM, not COUNT (Pitfall 3). The calendar color depth
/// is `f(当天悦己笔数)` — a count, not an amount — so this path groups the
/// joy-ledger rows by local calendar day and counts them.
///
/// CHOSEN PATH (RATIONALE — round-5 B / D-C1): a Dart group-over
/// `findByBookIds(ledgerType: LedgerType.joy)` rather than a new SQL
/// ledger+COUNT DAO variant. Reasons: (1) ZERO DAO surface change /
/// zero migration (schema stays v21); (2) the count grain (笔数) is naturally
/// available from the row list; (3) it does NOT cross the DRILL-01 scope lock —
/// per-day-joy is ambient calendar texture, a different concern from the one
/// allowed category drill path (RESEARCH Flag 2 verdict). It deliberately does
/// NOT reuse the unfiltered daily-totals SQL aggregate.
///
/// Reuse-first: ONE `findByBookIds` window fetch through the existing primitive.
/// The book set is never widened beyond the caller-supplied `bookIds` (threat
/// T-46-02-01). Transaction contents are never logged (threat T-46-02-02) — only
/// per-day count ints are kept.
class GetPerDayJoyCountsUseCase {
  GetPerDayJoyCountsUseCase({
    required TransactionRepository transactionRepository,
  }) : _txRepo = transactionRepository;

  final TransactionRepository _txRepo;

  Future<List<PerDayJoyCount>> execute({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    // 1. Joy-ledger window fetch via the existing primitive (NOT the unfiltered
    //    daily-totals SQL aggregate — Pitfall 3). Pass only the caller's active
    //    books (T-46-02-01).
    final txns = await _txRepo.findByBookIds(
      bookIds,
      ledgerType: LedgerType.joy,
      categoryId: null,
      startDate: startDate,
      endDate: endDate,
      sortField: SortField.timestamp,
      sortDirection: SortDirection.asc,
    );

    // 2. Expense-only gate plus the optional manualOnly entry-source filter.
    final expenseTxns = txns.where(
      (tx) =>
          tx.type == TransactionType.expense &&
          (entrySourceFilter == null || tx.entrySource == entrySourceFilter),
    );

    // 3. Group by LOCAL calendar day (DateTime(y, m, d) of the local timestamp,
    //    mirroring the DAO's DATE(...localtime) day grain) and COUNT.
    final perDay = <DateTime, int>{};
    for (final tx in expenseTxns) {
      final ts = tx.timestamp;
      final day = DateTime(ts.year, ts.month, ts.day);
      perDay[day] = (perDay[day] ?? 0) + 1;
    }

    final result = perDay.entries
        .map((e) => PerDayJoyCount(date: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }
}
