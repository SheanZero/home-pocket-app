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
    this._changeTracker,
    this._syncEngine,
    this._deviceIdResolver,
  }) : _repo = shoppingItemRepository;

  final ShoppingItemRepository _repo;
  final ShoppingItemChangeTracker? _changeTracker;
  final SyncEngine? _syncEngine;
  final Future<String?> Function()? _deviceIdResolver;

  Future<Result<void>> execute(String itemId) async {
    // 1. Validate input (MGMT-01)
    if (itemId.isEmpty) {
      return Result.error('itemId must not be empty');
    }

    // 2. Verify item exists and is not already tombstoned (MGMT-02, WR-02).
    //    findById returns soft-deleted rows; deleting an already-deleted item
    //    would re-soft-delete and re-emit a redundant trackDelete op.
    final existing = await _repo.findById(itemId);
    if (existing == null || existing.isDeleted) {
      return Result.error('ShoppingItem not found');
    }

    // 3. Soft-delete (tombstone) — NEVER hard-delete; tombstone survives full-sync
    final durable = _repo is DurableFamilySyncShoppingItemRepository
        ? _repo
        : null;
    final originDeviceId = existing.listType == 'public'
        ? await _deviceIdResolver?.call() ?? existing.deviceId
        : existing.deviceId;
    if (durable != null) {
      await durable.softDeleteWithFamilySyncOutbox(
        itemId,
        originDeviceId: originDeviceId,
      );
    } else {
      await _repo.softDelete(itemId);
    }

    // 4. Privacy gate (D37-06): existing.listType is authoritative (D37-04: immutable).
    //    Private items do not enqueue a tracker op.
    if (existing.listType == 'public' && durable == null) {
      _changeTracker?.trackDelete(itemId: itemId);
    }

    // 5. Private tombstones remain local and do not schedule family sync.
    if (existing.listType == 'public') {
      _syncEngine?.onTransactionChanged();
    }

    return Result.success(null);
  }
}
