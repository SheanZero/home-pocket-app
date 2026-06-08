import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../accounting/domain/models/transaction.dart';
import '../../domain/models/shopping_list_filter.dart';

part 'state_shopping_filter.g.dart';

/// Holds the current segment ('public' | 'private') for the shopping list.
///
/// Kept alive across IndexedStack tab switches (D38, SC2) so that the
/// selected segment persists when the user navigates away and returns.
/// On segment switch, [ShoppingFilter.resetForNewSegment] is called to
/// reset filter state (D5/FILT-02 — filter shared across both segments
/// but resets on switch).
@Riverpod(keepAlive: true)
class ListType extends _$ListType {
  @override
  String build() => 'private'; // Default to private list (T-38-02-01)

  /// Switches the active list segment and resets the filter state (D5/SC2).
  ///
  /// Resetting the filter ensures that stale ledger/category/status filters
  /// from the previous segment do not bleed into the newly selected segment.
  void setListType(String type) {
    state = type;
    ref.read(shoppingFilterProvider.notifier).resetForNewSegment();
  }
}

/// Holds the filter state for the shopping list view.
///
/// Kept alive across IndexedStack tab switches (SC2) so that filter selections
/// persist when the user navigates away from the shopping tab and returns.
/// [resetForNewSegment] is called automatically when the list type switches (D5).
@Riverpod(keepAlive: true)
class ShoppingFilter extends _$ShoppingFilter {
  @override
  ShoppingListFilter build() => ShoppingListFilter.initial();

  /// Filters by ledger type (or clears the ledger filter when [type] is null).
  void setLedgerFilter(LedgerType? type) {
    state = state.copyWith(ledgerType: type);
  }

  /// Filters by status ('all' | 'active').
  ///
  /// 'all' — show both active and completed items.
  /// 'active' — show only active (non-completed) items.
  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  /// Replaces the category filter with a new Set of leaf category IDs.
  /// An empty set clears the category filter (pass-all behaviour).
  void setCategoryIds(Set<String> ids) {
    state = state.copyWith(categoryIds: ids);
  }

  /// Resets all filter fields to [ShoppingListFilter.initial] values.
  void clearAll() {
    state = ShoppingListFilter.initial();
  }

  /// Resets filter to initial when the list type segment is switched (D5/FILT-02).
  ///
  /// Called automatically by [ListType.setListType] — not intended for direct
  /// use by widgets.
  void resetForNewSegment() {
    state = ShoppingListFilter.initial();
  }
}
