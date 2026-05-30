import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/list_filter_state.dart';
import '../../domain/models/list_sort_config.dart';
import '../../../accounting/domain/models/transaction.dart';

part 'state_list_filter.g.dart';

/// Holds the complete filter + sort state for the transaction list view.
///
/// Kept alive across IndexedStack tab switches (D-01/D-02, SC#2) so that all
/// filter fields — month, day, sort, search, ledger, category, member — persist
/// when the user navigates away from the List tab and returns. Under IndexedStack
/// widgets are never unmounted, so subscriptions never drop; the keepAlive
/// annotation makes the intent explicit and guards against future refactors.
@Riverpod(keepAlive: true)
class ListFilter extends _$ListFilter {
  @override
  ListFilterState build() => ListFilterState.initial();

  /// Sets the active month and resets the day filter.
  ///
  /// `activeDayFilter` is reset to null because the selected day belongs to
  /// a previous month context — keeping it would filter to a day that may
  /// not exist in the new month.
  void selectMonth(int year, int month) {
    state = state.copyWith(
      selectedYear: year,
      selectedMonth: month,
      activeDayFilter: null,
    );
  }

  /// Sets the active day filter (or clears it when [day] is null).
  void selectDay(DateTime? day) {
    state = state.copyWith(activeDayFilter: day);
  }

  /// Updates the sort configuration.
  void setSort(ListSortConfig sort) {
    state = state.copyWith(sortConfig: sort);
  }

  /// Filters by ledger type (or clears the ledger filter when [type] is null).
  void setLedgerFilter(LedgerType? type) {
    state = state.copyWith(ledgerType: type);
  }

  /// Filters by a single category ID (or clears when [id] is null).
  void setCategoryFilter(String? id) {
    state = state.copyWith(categoryId: id);
  }

  /// Updates the text search query.
  void setSearch(String q) {
    state = state.copyWith(searchQuery: q);
  }

  /// Filters to a specific family member book (or clears when [bookId] is null).
  void setMemberFilter(String? bookId) {
    state = state.copyWith(memberBookId: bookId);
  }

  /// Resets all filter fields to [ListFilterState.initial] values (FILTER-04).
  void clearAll() {
    state = state.clearAll();
  }
}
