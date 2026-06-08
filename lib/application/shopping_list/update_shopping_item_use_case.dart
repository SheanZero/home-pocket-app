import '../../features/shopping_list/domain/models/shopping_item.dart';
import '../../features/shopping_list/domain/models/shopping_item_sync_mapper.dart';
import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';
import '../../shared/utils/result.dart';
import '../family_sync/shopping_item_change_tracker.dart';
import '../family_sync/sync_engine.dart';

/// Parameters for updating an existing shopping item.
///
/// ## Pass-through vs coalesce semantics (EDIT-02 contract)
///
/// **Pass-through fields (`note`):** Applied verbatim — null clears the field.
/// **Coalesce fields:** `name`, `ledgerType`, `categoryId`, `tags`, `quantity`,
/// `estimatedPrice` use `?? existing.field` — null means "no change".
///
/// **Immutable fields (D37-04):** `listType` CANNOT be changed after creation.
/// Passing a non-null `listType` that differs from the stored value is a D6/SYNC-03
/// invariant violation — the use case returns Result.error with 'Invariant' in the
/// message (fail-fast, NOT a silent no-op).
class UpdateShoppingItemParams {
  final String itemId;

  /// Immutable after creation (D37-04/D6/SYNC-03). Passing a value different from the
  /// stored listType will return Result.error with 'Invariant' in the message.
  final String? listType;

  final String? name;
  final dynamic ledgerType; // LedgerType? — nullable enum
  final String? categoryId;
  final List<String>? tags;
  final String? note; // pass-through: null clears
  final int? quantity;
  final int? estimatedPrice;

  const UpdateShoppingItemParams({
    required this.itemId,
    this.listType,
    this.name,
    this.ledgerType,
    this.categoryId,
    this.tags,
    this.note,
    this.quantity,
    this.estimatedPrice,
  });
}

/// Updates an existing shopping item in the database.
///
/// Enforces the D37-04 listType immutability invariant (D6/SYNC-03): any attempt
/// to change listType after creation returns Result.error with 'Invariant' in the
/// message. This is a fail-fast check — NOT a silent no-op.
///
/// Enforces the privacy gate (D37-06): only public items are tracked for sync.
/// Private items are updated locally only — tracker is NOT called.
class UpdateShoppingItemUseCase {
  UpdateShoppingItemUseCase({
    required ShoppingItemRepository shoppingItemRepository,
    ShoppingItemChangeTracker? changeTracker, // nullable — D37-06
    SyncEngine? syncEngine, // nullable — fire-and-forget
  }) : _repo = shoppingItemRepository,
       _changeTracker = changeTracker,
       _syncEngine = syncEngine;

  final ShoppingItemRepository _repo;
  final ShoppingItemChangeTracker? _changeTracker;
  final SyncEngine? _syncEngine;

  Future<Result<ShoppingItem>> execute(UpdateShoppingItemParams params) async {
    // 1. Verify item exists (MGMT-02)
    final existing = await _repo.findById(params.itemId);
    if (existing == null) {
      return Result.error('ShoppingItem not found');
    }

    // D37-04: listType is immutable after creation — fail-fast for buggy callers (D6/SYNC-03)
    if (params.listType != null && params.listType != existing.listType) {
      return Result.error(
        'Invariant violation: listType cannot be changed after creation '
        '(D6/SYNC-03). Current: ${existing.listType}, attempted: ${params.listType}',
      );
    }

    // 2. Build updated row via copyWith (immutable pattern — CLAUDE.md Pitfall #4)
    //    Coalesce fields: null param → keep existing value.
    //    Pass-through fields: note applied verbatim (null clears — EDIT-02).
    //    Immutable fields: isCompleted, completedAt, listType, sortOrder, id,
    //    deviceId, addedByBookId, createdAt, isDeleted, isSynced preserved by
    //    copyWith default (D37-04/D6).
    final updated = existing.copyWith(
      name: params.name ?? existing.name,
      ledgerType: params.ledgerType ?? existing.ledgerType,
      categoryId: params.categoryId ?? existing.categoryId,
      tags: params.tags ?? existing.tags,
      note: params.note, // pass-through: null clears (EDIT-02 convention)
      quantity: params.quantity ?? existing.quantity,
      estimatedPrice: params.estimatedPrice ?? existing.estimatedPrice,
      updatedAt: DateTime.now(),
      // isCompleted, completedAt, listType, sortOrder, id, deviceId,
      // addedByBookId, createdAt, isDeleted, isSynced: all preserved by default.
    );

    // 3. Persist (note encryption handled at repo boundary)
    await _repo.update(updated);

    // 4. Privacy gate (D37-06): listType is immutable (D37-04), so existing.listType
    //    is the authoritative source — no need to re-read.
    if (existing.listType == 'public') {
      _changeTracker?.trackUpdate(
        ShoppingItemSyncMapper.toUpdateOperation(updated),
      );
    }

    // 5. Fire-and-forget sync trigger — SyncEngine handles debounce (D-20).
    _syncEngine?.onTransactionChanged();

    return Result.success(updated);
  }
}
