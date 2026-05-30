import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../accounting/domain/models/transaction.dart';
import 'list_sort_config.dart';

part 'list_filter_state.freezed.dart';

/// Immutable value object holding the complete filter + sort state for the
/// transaction list view (v1.4 列表功能, D-01).
///
/// All 7 fields are built here upfront to align with Phase 26 SC#1
/// (`listFilterStateProvider` consumes this type directly):
/// - [selectedYear] + [selectedMonth]: calendar month anchor for date filtering
/// - [activeDayFilter]: non-null = filter to a single calendar day; null = full month
/// - [sortConfig]: embedded [ListSortConfig] — single source of truth for sort state
/// - [ledgerType]: optional filter to Survival or Soul ledger
/// - [categoryIds]: multi-select category filter (D-01 Phase 28; empty = no filter)
/// - [searchQuery]: text search token (matched in Phase 26 provider in-memory; D-05)
/// - [memberBookId]: family member book filter (consumed in Phase 29; D-01 forward field)
@freezed
abstract class ListFilterState with _$ListFilterState {
  const ListFilterState._();

  const factory ListFilterState({
    required int selectedYear,
    required int selectedMonth,
    DateTime? activeDayFilter,
    @Default(ListSortConfig()) ListSortConfig sortConfig,
    LedgerType? ledgerType,
    @Default(<String>{}) Set<String> categoryIds,
    @Default('') String searchQuery,
    String? memberBookId,
  }) = _ListFilterState;

  /// Creates a filter state anchored to the current calendar month with all
  /// filters cleared. Used as the initial state and by [clearAll].
  factory ListFilterState.initial() => ListFilterState(
        selectedYear: DateTime.now().year,
        selectedMonth: DateTime.now().month,
      );

  /// Resets all filters to [ListFilterState.initial] — clears day filter,
  /// sort config, ledger type, category, search query, and member book filter,
  /// re-anchoring to the current calendar month.
  ListFilterState clearAll() => ListFilterState.initial();
}
