import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/analytics/domain/category_l1_rollup.dart';
import '../../features/analytics/domain/models/category_drill_down.dart';
import '../../shared/constants/sort_config.dart';

/// Reads one L1-category drill-down for the active analytics window (DRILL-01).
///
/// Tapping an L1 category flat-lists ALL its transactions for the window —
/// including transactions filed directly on the L1 AND on any of its L2 children
/// (Pitfall 2). The summary subtotal/count come from Plan 01's locked
/// `l1RollupFromTransactions` (the SAME `l1AncestorOf` rule the OVW-01 donut
/// uses), so the drill header can never drift from the donut slice (D-11).
///
/// Reuse-first (D-01/D-04/D-05/D-06): the window fetch goes through the EXISTING
/// `TransactionRepository.findByBookIds` primitive with `categoryId: null`; the
/// L1 filter is Dart-side. No new DAO, no per-category DAO read method, no new
/// index, no migration. The book set passed to `findByBookIds` is never widened
/// beyond the caller-supplied `bookIds` (threat T-44-03-03). Transaction
/// contents are never logged (threat T-44-03-01).
class GetCategoryDrillDownUseCase {
  GetCategoryDrillDownUseCase({
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
  }) : _txRepo = transactionRepository,
       _categoryRepo = categoryRepository;

  final TransactionRepository _txRepo;
  final CategoryRepository _categoryRepo;

  Future<CategoryDrillDown> execute({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    required String l1CategoryId,
  }) async {
    // 1. Window fetch via the existing primitive — no SQL-side category filter
    //    (D-05). Pass only the caller's active books (T-44-03-03).
    final txns = await _txRepo.findByBookIds(
      bookIds,
      startDate: startDate,
      endDate: endDate,
      categoryId: null,
      sortField: SortField.timestamp,
      sortDirection: SortDirection.desc,
    );

    // 2. Build the {id -> Category} map for the L1-ancestor lookup.
    final categories = await _categoryRepo.findAll();
    final categoryMap = <String, Category>{};
    for (final cat in categories) {
      categoryMap[cat.id] = cat;
    }

    // 3. Dart-side L1 filter — reuse Plan 01's l1AncestorOf (do NOT re-derive
    //    the level rule; Pitfall 2 is handled inside the helper).
    final filtered = txns
        .where((tx) => l1AncestorOf(tx.categoryId, categoryMap) == l1CategoryId)
        .toList();

    // 4. Subtotal/count from Plan 01's shared rollup — the single source-of-
    //    truth (D-11). Passing the unfiltered fetched txns is correct because
    //    l1RollupFromTransactions applies the same l1AncestorOf internally.
    final rollup = l1RollupFromTransactions(txns, categoryMap, l1CategoryId);

    // 5. Descriptive average per window-day (never a target — D-03).
    final dayCount = _inclusiveDayCount(startDate, endDate);
    final avgPerDay = dayCount > 0 ? rollup.amount ~/ dayCount : null;

    return CategoryDrillDown(
      transactions: filtered,
      subtotal: rollup.amount,
      count: rollup.transactionCount,
      avgPerDay: avgPerDay,
    );
  }

  /// Number of calendar days the [startDate]..[endDate] window spans, inclusive.
  int _inclusiveDayCount(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays + 1;
  }
}
