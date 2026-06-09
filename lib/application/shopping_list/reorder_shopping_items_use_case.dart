import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';
import '../../shared/utils/result.dart';

/// Updates the sort order of a shopping item.
///
/// D37-01: sortOrder is local-per-device — NOT synced.
/// This use case has no ShoppingItemChangeTracker and no SyncEngine —
/// reorder is strictly local-only and must not enter the sync pipeline.
class ReorderShoppingItemsUseCase {
  ReorderShoppingItemsUseCase({
    required ShoppingItemRepository shoppingItemRepository,
  }) : _repo = shoppingItemRepository;
  // No changeTracker, no syncEngine — reorder is local-per-device (D37-01)

  final ShoppingItemRepository _repo;

  Future<Result<void>> execute(String itemId, int newSortOrder) async {
    if (itemId.isEmpty) {
      return Result.error('itemId must not be empty');
    }
    // D37-01: sortOrder is local-per-device — NOT synced; no tracker or SyncEngine call
    await _repo.reorder(itemId, newSortOrder);
    return Result.success(null);
  }

  /// Persist a full ordering of active items as a contiguous sort sequence.
  ///
  /// [orderedActiveIds] is the desired top-to-bottom order. The repository
  /// writes `sort_order` = 0..N-1, so drag-to-reorder and the move-to-top/bottom
  /// buttons all stay correct regardless of prior values (quick-260609-pmc-04).
  ///
  /// D37-01: sortOrder is local-per-device — NOT synced.
  Future<Result<void>> applyOrder(List<String> orderedActiveIds) async {
    if (orderedActiveIds.any((id) => id.isEmpty)) {
      return Result.error('orderedActiveIds must not contain empty ids');
    }
    await _repo.reorderBatch(orderedActiveIds);
    return Result.success(null);
  }
}
