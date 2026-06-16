import '../../accounting/domain/models/category.dart';
import '../../accounting/domain/models/transaction.dart';
import 'models/monthly_report.dart';

/// Shared, domain-pure L1-category rollup helper (Phase 44, D-11).
///
/// This is the single source-of-truth for rolling category-grain data up to its
/// level-1 (L1) ancestor. It is consumed by BOTH:
///   - the expense-overview donut display transform (OVW-01), via
///     [rollupCategoryBreakdownsToL1] over `MonthlyReport.categoryBreakdowns`; and
///   - the category drill-down summary subtotal/count (Plan 03), via
///     [l1RollupFromTransactions] over the raw `List<Transaction>` the drill use
///     case already holds.
///
/// Both entrypoints route through the SAME [l1AncestorOf] rule, so the donut
/// slice and the drill header are mathematically the same number (no second
/// rollup, no subtotal drift — RESEARCH Pitfall 3).
///
/// Pure in-memory transform only: no DAO, no repository, no provider, no Drift
/// migration (D-10/D-13). Imports only sibling/cross-feature domain models;
/// the Flutter SDK is never imported — this file is domain-pure.

/// Returns the L1 ancestor category id for [categoryId].
///
/// Rule (Category model: `level==1`/`parentId==null` is L1; `level==2` is L2):
///   - a level-1 category rolls up to itself (its own id);
///   - a level-2 category rolls up to its `parentId`;
///   - a null id stays null; an unknown id falls back to itself.
///
/// Defensive and total — never throws.
String? l1AncestorOf(String? categoryId, Map<String, Category> categoryMap) {
  final cat = categoryMap[categoryId];
  if (cat == null) return categoryId;
  return cat.level == 1 ? cat.id : cat.parentId;
}

/// Immutable value type for one rolled-up L1 category bucket.
class L1CategoryRollup {
  const L1CategoryRollup({
    required this.categoryId,
    required this.amount,
    required this.transactionCount,
  });

  /// The L1 category id this bucket aggregates into.
  final String categoryId;

  /// Sum of amounts (minor units) of all transactions/breakdowns in this L1.
  final int amount;

  /// Count of transactions aggregated into this L1.
  final int transactionCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is L1CategoryRollup &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          amount == other.amount &&
          transactionCount == other.transactionCount;

  @override
  int get hashCode => Object.hash(categoryId, amount, transactionCount);

  @override
  String toString() =>
      'L1CategoryRollup(categoryId: $categoryId, amount: $amount, '
      'transactionCount: $transactionCount)';
}

/// Donut path (OVW-01): rolls an L2-grain [breakdowns] list up to L1 buckets.
///
/// Each breakdown is attributed to `l1AncestorOf(breakdown.categoryId)` (falling
/// back to its own id when unknown), amounts and counts are summed per L1, the
/// result is sorted amount-descending and truncated to [topN] (default 10).
/// Empty input yields empty output.
List<L1CategoryRollup> rollupCategoryBreakdownsToL1(
  List<CategoryBreakdown> breakdowns,
  Map<String, Category> categoryMap, {
  int topN = 10,
}) {
  final accumulator = <String, L1CategoryRollup>{};

  for (final breakdown in breakdowns) {
    final l1Id =
        l1AncestorOf(breakdown.categoryId, categoryMap) ?? breakdown.categoryId;
    final existing = accumulator[l1Id];
    accumulator[l1Id] = L1CategoryRollup(
      categoryId: l1Id,
      amount: (existing?.amount ?? 0) + breakdown.amount,
      transactionCount:
          (existing?.transactionCount ?? 0) + breakdown.transactionCount,
    );
  }

  final sorted = accumulator.values.toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  return sorted.length > topN ? sorted.sublist(0, topN) : sorted;
}

/// Drill path (Plan 03): aggregates subtotal/count for ONE L1 directly from raw
/// [transactions].
///
/// Filters [transactions] to those whose `l1AncestorOf(tx.categoryId)` equals
/// [l1CategoryId] — counting BOTH transactions filed directly on the L1 and
/// those filed on an L2 child (Pitfall 2) — then sums their amounts and counts
/// them. A target L1 with no matching transactions returns a zero-valued rollup
/// (never null/error).
L1CategoryRollup l1RollupFromTransactions(
  List<Transaction> transactions,
  Map<String, Category> categoryMap,
  String l1CategoryId,
) {
  var amount = 0;
  var count = 0;

  for (final tx in transactions) {
    if (l1AncestorOf(tx.categoryId, categoryMap) == l1CategoryId) {
      amount += tx.amount;
      count++;
    }
  }

  return L1CategoryRollup(
    categoryId: l1CategoryId,
    amount: amount,
    transactionCount: count,
  );
}
