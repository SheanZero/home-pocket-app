import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/analytics/domain/models/member_spend_breakdown.dart';
import '../../shared/constants/sort_config.dart';

/// Computes per-MEMBER (deviceId) expense aggregates for the active window — the
/// slice weights for the donut's 成员 dimension (260620-v2m / D2).
///
/// D2: the only per-transaction member identity in this app is the recording
/// device `transactions.deviceId` (no payer field). This use case groups expense
/// rows BY deviceId; single-device / not-in-group degrades to a single bucket.
///
/// Cross-ledger (D2): `ledgerType: null` — the member dimension shows TOTAL spend
/// per member across BOTH the daily and joy ledgers (not a single-ledger view).
///
/// Reuse-first: ONE `findByBookIds` window fetch through the existing primitive —
/// no new DAO, no migration (schema stays v21). The book set passed to
/// `findByBookIds` is never widened beyond the caller-supplied `bookIds` (threat
/// T-v2m-02). Transaction contents are never logged (threat T-v2m-01) — only
/// aggregate amount/count ints are kept.
class GetMemberSpendBreakdownUseCase {
  GetMemberSpendBreakdownUseCase({
    required TransactionRepository transactionRepository,
  }) : _txRepo = transactionRepository;

  final TransactionRepository _txRepo;

  Future<List<MemberSpendBreakdown>> execute({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    // 1. Window fetch via the existing primitive. `ledgerType: null` = both
    //    ledgers (member spend is a cross-ledger total). Pass only the caller's
    //    active books (T-v2m-02).
    final txns = await _txRepo.findByBookIds(
      bookIds,
      ledgerType: null,
      categoryId: null,
      startDate: startDate,
      endDate: endDate,
      sortField: SortField.timestamp,
      sortDirection: SortDirection.desc,
    );

    // 2. Expense-only gate plus the optional manualOnly entry-source filter
    //    (findByBookIds has no income/expense or entry-source SQL param — same
    //    Dart-side gate as get_joy_category_amounts_use_case).
    final expenseTxns = txns.where(
      (tx) =>
          tx.type == TransactionType.expense &&
          (entrySourceFilter == null || tx.entrySource == entrySourceFilter),
    );

    // 3. Single pass: accumulate amount + count per deviceId.
    final amountByDevice = <String, int>{};
    final countByDevice = <String, int>{};
    for (final tx in expenseTxns) {
      amountByDevice[tx.deviceId] = (amountByDevice[tx.deviceId] ?? 0) + tx.amount;
      countByDevice[tx.deviceId] = (countByDevice[tx.deviceId] ?? 0) + 1;
    }

    // 4. Produce amount>0 buckets only (consistent with the joy aggregate).
    final buckets = <MemberSpendBreakdown>[];
    amountByDevice.forEach((deviceId, amount) {
      if (amount > 0) {
        buckets.add(
          MemberSpendBreakdown(
            deviceId: deviceId,
            amount: amount,
            transactionCount: countByDevice[deviceId] ?? 0,
          ),
        );
      }
    });

    // 5. Sort amount-descending (stable, distinguishable slice order).
    buckets.sort((a, b) => b.amount.compareTo(a.amount));
    return buckets;
  }
}
