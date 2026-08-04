import 'package:uuid/uuid.dart';

import '../../features/shopping_list/domain/models/shopping_item.dart';
import '../../features/shopping_list/domain/models/shopping_item_sync_mapper.dart';
import '../../features/shopping_list/domain/models/shopping_unit.dart';
import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';
import '../../features/shopping_list/domain/repositories/shopping_unit_usage_repository.dart';
import '../../shared/utils/result.dart';
import '../family_sync/shopping_item_change_tracker.dart';
import '../family_sync/sync_engine.dart';

/// Parameters for creating a new shopping item.
class CreateShoppingItemParams {
  final String deviceId;
  final String listType; // 'public' | 'private'
  final String name;
  final dynamic ledgerType; // LedgerType? — nullable enum
  final String? categoryId;
  final List<String>? tags;
  final String? note;
  final double? quantity;
  final ShoppingUnit? unit;
  final String? customUnit;
  final int? estimatedPrice;
  final String? addedByBookId;

  const CreateShoppingItemParams({
    required this.deviceId,
    required this.listType,
    required this.name,
    this.ledgerType,
    this.categoryId,
    this.tags,
    this.note,
    this.quantity,
    this.unit,
    this.customUnit,
    this.estimatedPrice,
    this.addedByBookId,
  });
}

/// Creates a new shopping item with optional sync tracking.
///
/// Enforces the privacy gate (D37-06): only public items enter the sync pipeline.
/// Private items are persisted locally only — tracker is NOT called.
class CreateShoppingItemUseCase {
  CreateShoppingItemUseCase({
    required ShoppingItemRepository shoppingItemRepository,
    ShoppingItemChangeTracker? changeTracker, // nullable — D37-06
    SyncEngine? syncEngine, // nullable — fire-and-forget
    Future<String?> Function()? deviceIdResolver,
    ShoppingUnitUsageRepository? unitUsageRepository,
  }) : _repo = shoppingItemRepository,
       _changeTracker = changeTracker,
       _syncEngine = syncEngine,
       _deviceIdResolver = deviceIdResolver,
       _unitUsageRepository = unitUsageRepository;

  final ShoppingItemRepository _repo;
  final ShoppingItemChangeTracker? _changeTracker;
  final SyncEngine? _syncEngine;
  final Future<String?> Function()? _deviceIdResolver;
  final ShoppingUnitUsageRepository? _unitUsageRepository;

  Future<Result<ShoppingItem>> execute(CreateShoppingItemParams params) async {
    // 1. Validate input (ITEM-01)
    if (params.name.trim().isEmpty) {
      return Result.error('name must not be empty');
    }
    final quantity = params.quantity ?? 1.0;
    if (!quantity.isFinite || quantity <= 0) {
      return Result.error('quantity must be greater than zero');
    }
    final unit = params.unit ?? ShoppingUnit.piece;
    final unitSelection = ShoppingUnitSelection(
      unit,
      customLabel: params.customUnit,
    );
    if (!unitSelection.isValid ||
        unitSelection.normalizedCustomLabel.length > 12) {
      return Result.error('custom unit must contain 1 to 12 characters');
    }

    // 2. Build domain object (uuid v4 — shopping items do not need sortable IDs)
    final item = ShoppingItem(
      id: const Uuid().v4(),
      deviceId: params.deviceId,
      listType: params.listType,
      name: params.name.trim(),
      ledgerType: params.ledgerType,
      categoryId: params.categoryId,
      tags: params.tags ?? const [],
      note: params.note,
      quantity: quantity,
      unit: unit,
      customUnit: unit == ShoppingUnit.custom
          ? unitSelection.normalizedCustomLabel
          : null,
      estimatedPrice: params.estimatedPrice,
      addedByBookId: params.addedByBookId,
      createdAt: DateTime.now(),
    );

    // 3. Persist (note encryption handled at repo boundary)
    final durable = _repo is DurableFamilySyncShoppingItemRepository
        ? _repo
        : null;
    final originDeviceId = await _deviceIdResolver?.call() ?? params.deviceId;
    final persisted = durable != null
        ? await durable.insertWithFamilySyncOutbox(
            item,
            originDeviceId: originDeviceId,
          )
        : item;
    if (durable == null) await _repo.insert(item);

    // Suggestions learn from successful local CREATE actions only. Usage is
    // deliberately best-effort: a preference write must never turn an already
    // committed shopping item into a visible save failure.
    try {
      await _unitUsageRepository?.record(
        ShoppingUnitSelection(
          persisted.unit,
          customLabel: persisted.customUnit,
        ),
        DateTime.now(),
      );
    } catch (_) {
      // No logging: a custom label is user-authored data.
    }

    // 4. Privacy gate (D37-06): ONLY public items enter the sync pipeline.
    //    Private items stay local — tracker is not called.
    if (item.listType == 'public' && durable == null) {
      _changeTracker?.trackCreate(
        ShoppingItemSyncMapper.toCreateOperation(item),
      );
    }

    // 5. Fire-and-forget sync trigger — SyncEngine handles debounce and validity.
    _syncEngine?.onTransactionChanged();

    return Result.success(persisted);
  }
}
