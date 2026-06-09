import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../accounting/domain/models/transaction.dart';
import '../../domain/models/shopping_list_filter.dart';

part 'state_shopping_filter.g.dart';

/// Holds the current shopping-list view segment.
///
/// Values: 'all' (全部 — merges private + public) | 'private' (个人 — private only).
/// Default is 'all'. The toggle is only shown in group mode; when solo, the view
/// stays 'all' (which is identical to private since no shared items exist).
///
/// Kept alive across IndexedStack tab switches (D38, SC2) so that the
/// selected segment persists when the user navigates away and returns.
/// On segment switch, [ShoppingFilter.resetForNewSegment] is called to
/// reset filter state (D5/FILT-02 — filter shared across both segments
/// but resets on switch).
@Riverpod(keepAlive: true)
class ListType extends _$ListType {
  // Default to the merged All view (全部).
  @override
  String build() => 'all';

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
/// [setPrivateFilter] toggles the 私有 filter chip (G8Z) — always visible
/// regardless of group membership.
@Riverpod(keepAlive: true)
class ShoppingFilter extends _$ShoppingFilter {
  @override
  ShoppingListFilter build() => ShoppingListFilter.initial();

  /// Filters by ledger type (or clears the ledger filter when [type] is null).
  void setLedgerFilter(LedgerType? type) {
    state = state.copyWith(ledgerType: type);
  }

  /// Activates or deactivates the private-only view (私有 chip — G8Z).
  ///
  /// When [isPrivate] is true, [filteredShoppingItems] routes to
  /// `watchByListType('private')` regardless of the [listTypeProvider] value.
  void setPrivateFilter(bool isPrivate) {
    state = state.copyWith(showPrivateOnly: isPrivate);
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
