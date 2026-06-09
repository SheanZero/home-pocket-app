// No Drift imports. Domain-owned interface — data layer satisfies it via ShoppingItemRepositoryImpl.
import '../models/shopping_item.dart';

/// Abstract repository interface for shopping item data access.
///
/// Implemented by [ShoppingItemRepositoryImpl] in `lib/data/repositories/`.
/// All method signatures are pure Dart — no Drift or Flutter types.
abstract class ShoppingItemRepository {
  Future<void> insert(ShoppingItem item);
  Future<void> update(ShoppingItem item);
  Future<void> softDelete(String id);
  Future<void> softDeleteAllCompleted(String listType);
  Future<ShoppingItem?> findById(String id);
  Stream<List<ShoppingItem>> watchByListType(String listType);

  /// Reactive stream of ALL non-deleted items regardless of list type
  /// (backs the "全部" / All view, merging private + public).
  Stream<List<ShoppingItem>> watchAll();
  Future<void> upsert(ShoppingItem item);
  Future<void> reorder(String id, int newSortOrder);

  /// Re-sequence the given items to a contiguous sort order (index 0..N-1)
  /// matching [orderedIds]. Used by drag-to-reorder and move-to-top/bottom so
  /// the persisted order never goes non-contiguous (quick-260609-pmc-04).
  Future<void> reorderBatch(List<String> orderedIds);
}
