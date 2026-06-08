import '../../features/shopping_list/domain/models/shopping_item.dart';
import '../../features/shopping_list/domain/models/shopping_item_sync_mapper.dart';
import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';
import '../../shared/utils/result.dart';
import '../family_sync/shopping_item_change_tracker.dart';
import '../family_sync/sync_engine.dart';

/// Toggles the completed state of a shopping item.
///
/// Mark completed: stamps [completedAt] = now (D-03 sticky-complete timestamp).
/// Deliberate un-complete (D37-02): clears [completedAt] to null so the
/// sticky-complete guard does NOT fire on remote devices (guard condition:
/// `existing.completedAt != null && existing.completedAt!.isAfter(incomingUpdatedAt)`).
///
/// Enforces the privacy gate (D37-06): only public items enqueue a tracker op.
class ToggleItemCompletedUseCase {
  ToggleItemCompletedUseCase({
    required ShoppingItemRepository shoppingItemRepository,
    ShoppingItemChangeTracker? changeTracker, // nullable — D37-06
    SyncEngine? syncEngine, // nullable — fire-and-forget
  }) : _repo = shoppingItemRepository,
       _changeTracker = changeTracker,
       _syncEngine = syncEngine;

  final ShoppingItemRepository _repo;
  final ShoppingItemChangeTracker? _changeTracker;
  final SyncEngine? _syncEngine;

  Future<Result<ShoppingItem>> execute(String itemId) async {
    // 1. Fetch existing item
    final existing = await _repo.findById(itemId);
    if (existing == null) {
      return Result.error('ShoppingItem not found');
    }

    final now = DateTime.now();
    final ShoppingItem updated;

    if (existing.isCompleted) {
      // Deliberate un-complete (D37-02): clear completedAt to null so the
      // sticky-complete guard does NOT fire on remote devices.
      // completedAt=null signals an intentional un-check, not a stale edit.
      updated = existing.copyWith(
        isCompleted: false,
        completedAt: null, // Freezed: null != freezed sentinel → sets field to null
        updatedAt: now,
      );
    } else {
      // Mark completed (DONE-01, D-03): stamp completedAt for sticky-complete.
      updated = existing.copyWith(
        isCompleted: true,
        completedAt: now,
        updatedAt: now,
      );
    }

    // 2. Persist
    await _repo.update(updated);

    // 3. Privacy gate (D37-06): existing.listType is authoritative (D37-04: immutable).
    if (existing.listType == 'public') {
      _changeTracker?.trackUpdate(
        ShoppingItemSyncMapper.toUpdateOperation(updated),
      );
    }

    // 4. Fire-and-forget sync trigger
    _syncEngine?.onTransactionChanged();

    return Result.success(updated);
  }
}
