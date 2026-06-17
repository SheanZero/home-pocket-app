import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/analytics/domain/category_l1_rollup.dart';
import '../../features/analytics/domain/models/joy_category_amount.dart';
import '../../shared/constants/sort_config.dart';

/// Computes per-L1-category JOY amounts for the active window — the segment
/// weights for the 悦己花在哪 horizontal stacked bar (D-C2, Phase 46).
///
/// Why this is new: `PerCategoryJoyBreakdown` carries avg-SATISFACTION + counts,
/// NOT ¥ amounts (Pitfall 5). This use case produces the joy ¥ per L1 so the
/// stacked bar's segments are a verifiable strict subset of the donut's L1
/// amounts.
///
/// Single source (D-11): the rollup routes through the SAME `l1AncestorOf` rule
/// the donut uses (via the locked `l1RollupFromTransactions` helper), so a joy
/// segment can never drift from the donut slice math. There is NO second rollup
/// loop here.
///
/// Reuse-first: ONE `findByBookIds(ledgerType: LedgerType.joy)` window fetch
/// through the existing primitive — no new DAO, no migration (schema stays v21).
/// The book set passed to `findByBookIds` is never widened beyond the
/// caller-supplied `bookIds` (threat T-46-02-01). Transaction contents are never
/// logged (threat T-46-02-02) — only aggregate amount ints are kept.
class GetJoyCategoryAmountsUseCase {
  GetJoyCategoryAmountsUseCase({
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
  }) : _txRepo = transactionRepository,
       _categoryRepo = categoryRepository;

  final TransactionRepository _txRepo;
  final CategoryRepository _categoryRepo;

  Future<List<JoyCategoryAmount>> execute({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    // 1. Joy-ledger window fetch via the existing primitive (Pitfall 5). Pass
    //    only the caller's active books (T-46-02-01).
    final txns = await _txRepo.findByBookIds(
      bookIds,
      ledgerType: LedgerType.joy,
      categoryId: null,
      startDate: startDate,
      endDate: endDate,
      sortField: SortField.timestamp,
      sortDirection: SortDirection.desc,
    );

    // 2. Expense-only gate (mirror drill CR-01) plus the optional manualOnly
    //    entry-source filter — so the joy amount equals the donut's joy-slice
    //    math (findByBookIds has no income/expense or entry-source SQL param).
    final expenseTxns = txns
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              (entrySourceFilter == null ||
                  tx.entrySource == entrySourceFilter),
        )
        .toList();

    // 3. Build the {id -> Category} map for the L1-ancestor lookup.
    final categories = await _categoryRepo.findAll();
    final categoryMap = <String, Category>{};
    for (final cat in categories) {
      categoryMap[cat.id] = cat;
    }

    // 4. Roll up per L1 through the SAME l1AncestorOf rule the donut uses
    //    (D-11). l1RollupFromTransactions is the single source — never a second
    //    rollup loop. First collect the distinct L1 ids present, then ask the
    //    locked helper for each L1's amount over the expense-only joy set.
    final l1Ids = <String>{};
    for (final tx in expenseTxns) {
      final l1 = l1AncestorOf(tx.categoryId, categoryMap) ?? tx.categoryId;
      l1Ids.add(l1);
    }

    final buckets = <JoyCategoryAmount>[];
    for (final l1Id in l1Ids) {
      final rollup = l1RollupFromTransactions(expenseTxns, categoryMap, l1Id);
      if (rollup.amount > 0) {
        buckets.add(
          JoyCategoryAmount(categoryId: l1Id, amount: rollup.amount),
        );
      }
    }

    // 5. Sort amount-descending (largest -> smallest, D-C2 segment order).
    buckets.sort((a, b) => b.amount.compareTo(a.amount));
    return buckets;
  }
}
