import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';
import '../../shared/utils/result.dart';
import '../family_sync/shopping_item_change_tracker.dart';
import '../family_sync/sync_engine.dart';

/// Soft-deletes all completed shopping items in a list segment.
///
/// For public lists: reads the current completed items before the bulk delete so
/// per-item tracker delete ops can be emitted — one op per completed item.
/// For private lists: performs the bulk soft-delete only — tracker is NOT called.
///
/// Privacy gate (D37-06): private items never enter the sync pipeline.
/// MGMT-03 (swipe disabled during batch-select) is a presentation-layer concern
/// (Phase 38); the use case itself is unchanged for it.
class ClearCompletedItemsUseCase {
  ClearCompletedItemsUseCase({
    required ShoppingItemRepository shoppingItemRepository,
    this._changeTracker,
    this._syncEngine,
    this._deviceIdResolver,
  }) : _repo = shoppingItemRepository;

  final ShoppingItemRepository _repo;
  final ShoppingItemChangeTracker? _changeTracker;
  final SyncEngine? _syncEngine;
  final Future<String?> Function()? _deviceIdResolver;

  Future<Result<void>> execute(String listType) async {
    // `all` is a presentation segment only. Persisted rows use the concrete
    // `private` / `public` list types, so clearing the merged segment must
    // explicitly cover both or the repository query matches zero rows.
    final targetListTypes = listType == 'all'
        ? const ['private', 'public']
        : [listType];
    final durable = _repo is DurableFamilySyncShoppingItemRepository
        ? _repo
        : null;
    final includesPublic = targetListTypes.contains('public');
    if (durable != null) {
      final originDeviceId = includesPublic
          ? await _deviceIdResolver?.call() ?? ''
          : '';
      for (final targetListType in targetListTypes) {
        await durable.softDeleteAllCompletedWithFamilySyncOutbox(
          targetListType,
          originDeviceId: originDeviceId,
        );
      }
      if (includesPublic) {
        _syncEngine?.onTransactionChanged();
      }
      return Result.success(null);
    }

    for (final targetListType in targetListTypes) {
      if (targetListType == 'public') {
        // Read IDs before bulk-delete so we can emit per-item tracker ops (D37-06, DONE-03)
        final items = await _repo.watchByListType(targetListType).first;
        final completed = items
            .where((i) => i.isCompleted && !i.isDeleted)
            .toList();

        // Bulk soft-delete in one DB write — no N+1 (DONE-03)
        await _repo.softDeleteAllCompleted(targetListType);

        // Emit per-item tombstone ops for sync (one op per completed item — SYNC-01, SC-2)
        for (final item in completed) {
          _changeTracker?.trackDelete(itemId: item.id);
        }
      } else {
        // D37-06: private items never enter sync pipeline — no tracker ops emitted
        await _repo.softDeleteAllCompleted(targetListType);
      }
    }

    // Private-only clears are local database operations.
    if (includesPublic) {
      _syncEngine?.onTransactionChanged();
    }

    return Result.success(null);
  }
}
