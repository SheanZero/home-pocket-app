import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/constants/sort_config.dart';

part 'list_sort_config.freezed.dart';

/// Wraps [SortField] and [SortDirection] as an immutable sort configuration
/// for the transaction list view (v1.4 列表功能, SORT-01..04).
///
/// Default: sort by [SortField.updatedAt] descending — the reference default
/// per SORT-02 and Phase 25 D-01.
@freezed
abstract class ListSortConfig with _$ListSortConfig {
  const factory ListSortConfig({
    @Default(SortField.updatedAt) SortField sortField,
    @Default(SortDirection.desc) SortDirection sortDirection,
  }) = _ListSortConfig;

  /// Convenience constant: default sort configuration (updatedAt, desc).
  static const ListSortConfig initial = ListSortConfig();
}
