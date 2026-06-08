import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';
import '../../shared/utils/result.dart';
import '../family_sync/shopping_item_change_tracker.dart';
import '../family_sync/sync_engine.dart';

/// Soft-deletes a shopping item (tombstone) with optional sync tracking.
///
/// Enforces the privacy gate (D37-06): only public items enqueue a tombstone op.
/// Private items are soft-deleted locally only — tracker is NOT called.
class DeleteShoppingItemUseCase {
  DeleteShoppingItemUseCase({
    required ShoppingItemRepository shoppingItemRepository,
    ShoppingItemChangeTracker? changeTracker, // nullable — D37-06
    SyncEngine? syncEngine, // nullable — fire-and-forget
  }) : _repo = shoppingItemRepository,
       _changeTracker = changeTracker,
       _syncEngine = syncEngine;

  final ShoppingItemRepository _repo;
  final ShoppingItemChangeTracker? _changeTracker;
  final SyncEngine? _syncEngine;

  Future<Result<void>> execute(String itemId) async {
    // 1. Validate input (MGMT-01)
    if (itemId.isEmpty) {
      return Result.error('itemId must not be empty');
    }

    // 2. Verify item exists (MGMT-02)
    final existing = await _repo.findById(itemId);
    if (existing == null) {
      return Result.error('ShoppingItem not found');
    }

    // 3. Soft-delete (tombstone) — NEVER hard-delete; tombstone survives full-sync
    await _repo.softDelete(itemId);

    // 4. Privacy gate (D37-06): existing.listType is authoritative (D37-04: immutable).
    //    Private items do not enqueue a tracker op.
    if (existing.listType == 'public') {
      _changeTracker?.trackDelete(itemId: itemId);
    }

    // 5. Fire-and-forget sync trigger
    _syncEngine?.onTransactionChanged();

    return Result.success(null);
  }
}
