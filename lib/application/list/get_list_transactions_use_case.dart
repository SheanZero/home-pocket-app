import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/list/domain/models/list_filter_state.dart';
import '../../shared/utils/date_boundaries.dart';
import '../../shared/utils/result.dart';

/// Parameters for querying transactions across multiple books.
///
/// Composed value object (D-04) that holds the book IDs and the complete
/// filter/sort state. NOT Freezed — mirrors [GetTransactionsParams] as a
/// plain const class.
class GetListParams {
  final List<String> bookIds;
  final ListFilterState filter;

  const GetListParams({required this.bookIds, required this.filter});
}

/// Fetches and watches transactions spanning multiple books with filter/sort.
///
/// Encapsulates all filter→query translation:
/// - ledgerType, categoryId forwarded to repo (SQL-able filters)
/// - date range derived from selectedYear/selectedMonth/activeDayFilter via
///   [DateBoundaries] (D-04)
/// - sortField/sortDirection forwarded explicitly from filter.sortConfig
///   (no reliance on repo default values — RESEARCH Pitfall 2)
/// - searchQuery and memberBookId are NOT forwarded (D-05: text-search
///   matching belongs to the Phase 26 provider; use case forwards only
///   SQL-able filters)
///
/// Phase 26 [listTransactionsProvider] will call [watch] to drive the
/// reactive list (LIST-02).
class GetListTransactionsUseCase {
  GetListTransactionsUseCase({
    required TransactionRepository transactionRepository,
  }) : _repo = transactionRepository;

  final TransactionRepository _repo;

  /// Fetches transactions for the given [params].
  ///
  /// Returns [Result.error] if [params.bookIds] is empty — no repo call is
  /// made in that case (SC#3 / T-25-02).
  Future<Result<List<Transaction>>> execute(GetListParams params) async {
    if (params.bookIds.isEmpty) {
      return Result.error('bookIds must not be empty');
    }

    final dateRange = _dateRange(params.filter);

    final txs = await _repo.findByBookIds(
      params.bookIds,
      ledgerType: params.filter.ledgerType,
      // categoryId: null — multi-category filtering is Dart-side in
      // listTransactionsProvider via filter.categoryIds.contains (D-01 / A3).
      categoryId: null,
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
      sortField: params.filter.sortConfig.sortField,
      sortDirection: params.filter.sortConfig.sortDirection,
    );

    return Result.success(txs);
  }

  /// Watches transactions for the given [params] as a reactive stream.
  ///
  /// Throws [ArgumentError] synchronously when [params.bookIds] is empty
  /// (D-03: watch() cannot return [Result.error], so it throws instead).
  Stream<List<Transaction>> watch(GetListParams params) {
    if (params.bookIds.isEmpty) {
      throw ArgumentError('bookIds must not be empty');
    }

    final dateRange = _dateRange(params.filter);

    return _repo.watchByBookIds(
      params.bookIds,
      ledgerType: params.filter.ledgerType,
      // categoryId: null — multi-category filtering is Dart-side in
      // listTransactionsProvider via filter.categoryIds.contains (D-01 / A3).
      categoryId: null,
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
      sortField: params.filter.sortConfig.sortField,
      sortDirection: params.filter.sortConfig.sortDirection,
    );
  }

  /// Derives the date range from the filter state.
  ///
  /// When [filter.activeDayFilter] is non-null, returns the closed interval
  /// for that single calendar day via [DateBoundaries.dayRange].
  /// Otherwise, returns the full calendar month interval via
  /// [DateBoundaries.monthRange] (D-04).
  ({DateTime startDate, DateTime endDate}) _dateRange(ListFilterState filter) {
    if (filter.activeDayFilter != null) {
      final r = DateBoundaries.dayRange(filter.activeDayFilter!);
      return (startDate: r.start, endDate: r.end);
    } else {
      final r = DateBoundaries.monthRange(
        filter.selectedYear,
        filter.selectedMonth,
      );
      return (startDate: r.start, endDate: r.end);
    }
  }
}
