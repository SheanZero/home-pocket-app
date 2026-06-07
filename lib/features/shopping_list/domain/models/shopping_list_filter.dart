import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../accounting/domain/models/transaction.dart';

part 'shopping_list_filter.freezed.dart';

/// Immutable filter state for the shopping list view.
///
/// - [listType]: current segment ('public' | 'private')
/// - [ledgerType]: null = show all ledger types
/// - [statusFilter]: 'all' | 'active' (completed items always visible in their section)
/// - [searchQuery]: text search token
///
/// No Drift imports — pure domain type.
@freezed
abstract class ShoppingListFilter with _$ShoppingListFilter {
  const factory ShoppingListFilter({
    @Default('private') String listType,
    LedgerType? ledgerType,
    @Default('all') String statusFilter,
    @Default('') String searchQuery,
  }) = _ShoppingListFilter;

  /// Creates a filter state with all defaults (private list, no filters).
  factory ShoppingListFilter.initial() => const ShoppingListFilter();
}
