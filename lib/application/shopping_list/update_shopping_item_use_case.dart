import '../../features/shopping_list/domain/models/shopping_item.dart';
import '../../features/shopping_list/domain/models/shopping_unit.dart';
import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';
import '../../shared/utils/result.dart';
import '../family_sync/shopping_item_change_tracker.dart';
import '../family_sync/sync_engine.dart';
import 'shopping_item_update_persistence.dart';

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
  final double? quantity;
  final ShoppingUnit? unit;
  final String? customUnit;
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
    this.unit,
    this.customUnit,
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
    Future<String?> Function()? deviceIdResolver,
  }) : _repo = shoppingItemRepository,
       _persistence = ShoppingItemUpdatePersistence(
         shoppingItemRepository: shoppingItemRepository,
         changeTracker: changeTracker,
         syncEngine: syncEngine,
         deviceIdResolver: deviceIdResolver,
       );

  final ShoppingItemRepository _repo;
  final ShoppingItemUpdatePersistence _persistence;

  Future<Result<ShoppingItem>> execute(UpdateShoppingItemParams params) async {
    // 1. Verify item exists and is not already tombstoned (MGMT-02, WR-02).
    //    findById returns soft-deleted rows; updating one would "revive" it with
    //    fresh field values and enqueue an update op the remote SC-4 guard
    //    rejects (and the fresh local updatedAt interacts badly with CR-01 LWW).
    final existing = await _repo.findById(params.itemId);
    if (existing == null || existing.isDeleted) {
      return Result.error('ShoppingItem not found');
    }

    // D37-04: listType is immutable after creation — fail-fast for buggy callers (D6/SYNC-03)
    if (params.listType != null && params.listType != existing.listType) {
      return Result.error(
        'Invariant violation: listType cannot be changed after creation '
        '(D6/SYNC-03). Current: ${existing.listType}, attempted: ${params.listType}',
      );
    }

    final quantity = params.quantity ?? existing.quantity;
    if (!quantity.isFinite || quantity <= 0) {
      return Result.error('quantity must be greater than zero');
    }
    final unit = params.unit ?? existing.unit;
    final customUnit = unit == ShoppingUnit.custom
        ? (params.customUnit ?? existing.customUnit)?.trim()
        : null;
    if (unit == ShoppingUnit.custom &&
        (customUnit == null || customUnit.isEmpty || customUnit.length > 12)) {
      return Result.error('custom unit must contain 1 to 12 characters');
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
      quantity: quantity,
      unit: unit,
      customUnit: customUnit,
      estimatedPrice: params.estimatedPrice ?? existing.estimatedPrice,
      updatedAt: DateTime.now(),
      // isCompleted, completedAt, listType, sortOrder, id, deviceId,
      // addedByBookId, createdAt, isDeleted, isSynced: all preserved by default.
    );

    // 3. Persist (note encryption handled at repo boundary).
    final persisted = await _persistence.persist(updated);

    return Result.success(persisted);
  }
}
