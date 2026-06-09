import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/accounting/repository_providers.dart'
    as app_accounting;
import '../../../../application/shopping_list/clear_completed_items_use_case.dart';
import '../../../../application/shopping_list/create_shopping_item_use_case.dart';
import '../../../../application/shopping_list/delete_shopping_item_use_case.dart';
import '../../../../application/shopping_list/reorder_shopping_items_use_case.dart';
import '../../../../application/shopping_list/toggle_item_completed_use_case.dart';
import '../../../../application/shopping_list/update_shopping_item_use_case.dart';
import '../../../../data/daos/shopping_item_dao.dart';
import '../../../../data/repositories/shopping_item_repository_impl.dart';
import '../../../family_sync/presentation/providers/state_sync.dart'
    show shoppingItemChangeTrackerProvider, syncEngineProvider;
import '../../domain/models/shopping_item.dart';
import '../../domain/repositories/shopping_item_repository.dart';
import 'state_shopping_filter.dart';

part 'repository_providers.g.dart';

/// ShoppingItemRepository provider.
///
/// Uses [ShoppingItemRepositoryImpl] wired with the application-layer database
/// and field encryption service.
@riverpod
ShoppingItemRepository shoppingItemRepository(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  final dao = ShoppingItemDao(database);
  final encryptionService = ref.watch(
    app_accounting.appFieldEncryptionServiceProvider,
  );
  return ShoppingItemRepositoryImpl(
    dao: dao,
    encryptionService: encryptionService,
  );
}

/// [CreateShoppingItemUseCase] provider wired with repo + sync deps.
///
/// Privacy gate (D37-06): only public items enter the sync pipeline;
/// the use case enforces this internally.
@riverpod
CreateShoppingItemUseCase createShoppingItemUseCase(Ref ref) =>
    CreateShoppingItemUseCase(
      shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider),
      changeTracker: ref.watch(shoppingItemChangeTrackerProvider),
      syncEngine: ref.watch(syncEngineProvider),
    );

/// [ToggleItemCompletedUseCase] provider wired with repo + sync deps.
@riverpod
ToggleItemCompletedUseCase toggleItemCompletedUseCase(Ref ref) =>
    ToggleItemCompletedUseCase(
      shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider),
      changeTracker: ref.watch(shoppingItemChangeTrackerProvider),
      syncEngine: ref.watch(syncEngineProvider),
    );

/// [DeleteShoppingItemUseCase] provider wired with repo + sync deps.
@riverpod
DeleteShoppingItemUseCase deleteShoppingItemUseCase(Ref ref) =>
    DeleteShoppingItemUseCase(
      shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider),
      changeTracker: ref.watch(shoppingItemChangeTrackerProvider),
      syncEngine: ref.watch(syncEngineProvider),
    );

/// [UpdateShoppingItemUseCase] provider wired with repo + sync deps.
@riverpod
UpdateShoppingItemUseCase updateShoppingItemUseCase(Ref ref) =>
    UpdateShoppingItemUseCase(
      shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider),
      changeTracker: ref.watch(shoppingItemChangeTrackerProvider),
      syncEngine: ref.watch(syncEngineProvider),
    );

/// [ReorderShoppingItemsUseCase] provider — repo only, no sync deps.
///
/// D37-01: sortOrder is local-per-device — NOT synced. This use case
/// intentionally has no changeTracker and no syncEngine.
@riverpod
ReorderShoppingItemsUseCase reorderShoppingItemsUseCase(Ref ref) =>
    ReorderShoppingItemsUseCase(
      shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider),
    );

/// [ClearCompletedItemsUseCase] provider wired with repo + sync deps.
@riverpod
ClearCompletedItemsUseCase clearCompletedItemsUseCase(Ref ref) =>
    ClearCompletedItemsUseCase(
      shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider),
      changeTracker: ref.watch(shoppingItemChangeTrackerProvider),
      syncEngine: ref.watch(syncEngineProvider),
    );

/// Derived stream of filtered shopping items for the current segment.
///
/// Watches both [listTypeProvider] and [shoppingFilterProvider] so any
/// filter chip change triggers a re-emission.
///
/// Implementation note (D38-04 / Pitfall 5): the DAO returns ALL non-deleted
/// items for a given listType. Ledger, category, and status filtering is done
/// client-side here — NOT in SQL — to keep the reactive stream simple and avoid
/// extra DAO variants. The privacy gate (public/private separation) is enforced
/// at the DAO level via [watchByListType]; the client-side filter is cosmetic.
///
/// NEVER call ref.invalidate on this provider — reactivity comes from the
/// Drift stream emitting on DB writes (SC-5, reactive delivery).
@riverpod
Stream<List<ShoppingItem>> filteredShoppingItems(Ref ref) {
  final filter = ref.watch(shoppingFilterProvider);
  final listType = ref.watch(listTypeProvider);
  final repository = ref.watch(shoppingItemRepositoryProvider);
  // 'all' (全部) merges private + public; otherwise scope to one list type.
  final source = listType == 'all'
      ? repository.watchAll()
      : repository.watchByListType(listType);
  return source
      .map(
        (items) =>
            items.where((item) {
              // Ledger filter
              if (filter.ledgerType != null &&
                  item.ledgerType != filter.ledgerType) {
                return false;
              }
              // Category filter
              if (filter.categoryIds.isNotEmpty &&
                  !filter.categoryIds.contains(item.categoryId)) {
                return false;
              }
              // Status filter: 'active' hides completed items
              if (filter.statusFilter == 'active' && item.isCompleted) {
                return false;
              }
              return true;
            }).toList(),
      );
}
