import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/analytics/domain/models/within_month_cumulative_trend.dart';
import '../../shared/constants/sort_config.dart';

/// Computes the within-month per-day-cumulative expense trend for the active
/// book (round-5 B / D-E1, Phase 46).
///
/// For the current month and the previous month, this produces per-ledger
/// running-cumulative spend points (one per day that has spend), so the trend
/// card can draw a 本月 line + a 上月 reference line on the spend side. The joy
/// side carries ONLY the current month — there is no previous-month joy series
/// (D-E1, ADR-012 zero joy cross-period — Pitfall 2). The model has no
/// `previousMonthJoy` field, so a previous-month joy line is unrepresentable.
///
/// Reuse-first (RESEARCH Flag 1): a SINGLE 2-month window fetch goes through the
/// existing `TransactionRepository.findByBookIds` primitive — no new DAO, no
/// migration (schema stays v21). All per-day / per-ledger / per-month shaping is
/// a pure Dart transform. The book set passed to `findByBookIds` is never
/// widened beyond the caller-supplied `bookIds` (threat T-46-01-01). Transaction
/// contents are never logged (threat T-46-01-02) — only aggregate ints are kept.
class GetWithinMonthCumulativeUseCase {
  GetWithinMonthCumulativeUseCase({
    required TransactionRepository transactionRepository,
  }) : _txRepo = transactionRepository;

  final TransactionRepository _txRepo;

  Future<WithinMonthCumulativeTrend> execute({
    required List<String> bookIds,
    required DateTime monthAnchor,
    EntrySource? entrySourceFilter,
  }) async {
    // 2-month window: first day of the previous month .. last day of the
    // current month. DateTime(year, month + 1, 0) yields the last day of
    // `month`; the 23:59:59 upper bound keeps end-of-day rows inclusive.
    final currentYear = monthAnchor.year;
    final currentMonth = monthAnchor.month;
    final windowStart = DateTime(currentYear, currentMonth - 1, 1);
    final windowEnd = DateTime(currentYear, currentMonth + 1, 0, 23, 59, 59);

    // Single reuse-first fetch — pass ONLY the caller's books (T-46-01-01).
    final txns = await _txRepo.findByBookIds(
      bookIds,
      startDate: windowStart,
      endDate: windowEnd,
      categoryId: null,
      sortField: SortField.timestamp,
      sortDirection: SortDirection.asc,
    );

    // Expense-only gate so the trend matches the expense-only overview (CR-01).
    // Optional entry-source filter supports the manualOnly joy variant; the
    // transaction repository has no entry-source SQL param, so filter in Dart.
    final expense = txns
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              (entrySourceFilter == null ||
                  tx.entrySource == entrySourceFilter),
        )
        .toList();

    final previousMonth = DateTime(currentYear, currentMonth - 1, 1);

    // Current-month series: total + daily + joy.
    final currentMonthTotal = _cumulative(
      expense,
      year: currentYear,
      month: currentMonth,
    );
    final currentMonthDaily = _cumulative(
      expense,
      year: currentYear,
      month: currentMonth,
      ledgerType: LedgerType.daily,
    );
    final currentMonthJoy = _cumulative(
      expense,
      year: currentYear,
      month: currentMonth,
      ledgerType: LedgerType.joy,
    );

    // Previous-month series: total + daily ONLY (no joy — D-E1, Pitfall 2).
    final previousMonthTotal = _cumulative(
      expense,
      year: previousMonth.year,
      month: previousMonth.month,
    );
    final previousMonthDaily = _cumulative(
      expense,
      year: previousMonth.year,
      month: previousMonth.month,
      ledgerType: LedgerType.daily,
    );

    return WithinMonthCumulativeTrend(
      currentMonthTotal: currentMonthTotal,
      currentMonthDaily: currentMonthDaily,
      currentMonthJoy: currentMonthJoy,
      previousMonthTotal: previousMonthTotal,
      previousMonthDaily: previousMonthDaily,
    );
  }

  /// Builds the per-day running-cumulative points for one calendar [month]
  /// (optionally restricted to a single [ledgerType]). The cumulative is scoped
  /// to the month — it starts at the month's first spend day and never carries
  /// across the month boundary. Days with no spend are omitted; the running
  /// total persists to the next spend day (a no-spend day keeps the prior
  /// cumulative — no reset).
  List<CumulativePoint> _cumulative(
    List<Transaction> expense, {
    required int year,
    required int month,
    LedgerType? ledgerType,
  }) {
    // Sum per day-of-month within this calendar month (and optional ledger).
    final perDay = <int, int>{};
    for (final tx in expense) {
      if (tx.timestamp.year != year || tx.timestamp.month != month) {
        continue;
      }
      if (ledgerType != null && tx.ledgerType != ledgerType) {
        continue;
      }
      final day = tx.timestamp.day;
      perDay[day] = (perDay[day] ?? 0) + tx.amount;
    }

    if (perDay.isEmpty) {
      return const [];
    }

    final days = perDay.keys.toList()..sort();
    final points = <CumulativePoint>[];
    int running = 0;
    for (final day in days) {
      running += perDay[day]!;
      points.add(CumulativePoint(day: day, cumulativeAmount: running));
    }
    return points;
  }
}
