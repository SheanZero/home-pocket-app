import '../../features/shopping_list/domain/models/shopping_item.dart';
import '../../features/shopping_list/domain/models/shopping_item_sync_mapper.dart';
import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';
import '../family_sync/shopping_item_change_tracker.dart';
import '../family_sync/sync_engine.dart';

/// Persists an already-built shopping-item update and schedules public sync.
///
/// Durable repositories atomically write the normalized row and public outbox
/// operation. Legacy repositories retain the tracker path until migrated.
class ShoppingItemUpdatePersistence {
  ShoppingItemUpdatePersistence({
    required ShoppingItemRepository shoppingItemRepository,
    this._changeTracker,
    this._syncEngine,
    this._deviceIdResolver,
  }) : _repo = shoppingItemRepository;

  final ShoppingItemRepository _repo;
  final ShoppingItemChangeTracker? _changeTracker;
  final SyncEngine? _syncEngine;
  final Future<String?> Function()? _deviceIdResolver;

  Future<ShoppingItem> persist(ShoppingItem item) async {
    final durable = _repo is DurableFamilySyncShoppingItemRepository
        ? _repo
        : null;
    final ShoppingItem persisted;
    if (durable != null) {
      // Private shopping items are local-only. Do not couple their database
      // update to secure-storage identity or any family-sync prerequisite.
      final originDeviceId = item.listType == 'public'
          ? await _deviceIdResolver?.call() ?? item.deviceId
          : item.deviceId;
      persisted = await durable.updateWithFamilySyncOutbox(
        item,
        originDeviceId: originDeviceId,
      );
    } else {
      persisted = item;
    }

    if (durable == null) {
      await _repo.update(item);
      if (item.listType == 'public') {
        _changeTracker?.trackUpdate(
          ShoppingItemSyncMapper.toUpdateOperation(item),
        );
      }
    }

    if (item.listType == 'public') {
      _syncEngine?.onTransactionChanged();
    }

    return persisted;
  }
}
