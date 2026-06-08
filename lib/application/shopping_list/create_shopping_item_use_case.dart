import 'package:uuid/uuid.dart';

import '../../features/shopping_list/domain/models/shopping_item.dart';
import '../../features/shopping_list/domain/models/shopping_item_sync_mapper.dart';
import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';
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
  final int? quantity;
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
  }) : _repo = shoppingItemRepository,
       _changeTracker = changeTracker,
       _syncEngine = syncEngine;

  final ShoppingItemRepository _repo;
  final ShoppingItemChangeTracker? _changeTracker;
  final SyncEngine? _syncEngine;

  Future<Result<ShoppingItem>> execute(CreateShoppingItemParams params) async {
    // 1. Validate input (ITEM-01)
    if (params.name.trim().isEmpty) {
      return Result.error('name must not be empty');
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
      quantity: params.quantity ?? 1,
      estimatedPrice: params.estimatedPrice,
      addedByBookId: params.addedByBookId,
      createdAt: DateTime.now(),
    );

    // 3. Persist (note encryption handled at repo boundary)
    await _repo.insert(item);

    // 4. Privacy gate (D37-06): ONLY public items enter the sync pipeline.
    //    Private items stay local — tracker is not called.
    if (item.listType == 'public') {
      _changeTracker?.trackCreate(
        ShoppingItemSyncMapper.toCreateOperation(item),
      );
    }

    // 5. Fire-and-forget sync trigger — SyncEngine handles debounce and validity.
    _syncEngine?.onTransactionChanged();

    return Result.success(item);
  }
}
