import '../models/category.dart';

/// Abstract repository interface for category data access.
abstract class CategoryRepository {
  Future<void> insert(Category category);
  Future<void> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
  });
  Future<Category?> findById(String id);
  Future<List<Category>> findAll();
  Future<List<Category>> findActive();
  Future<List<Category>> findByLevel(int level);
  Future<List<Category>> findByParent(String parentId);
  Future<void> insertBatch(List<Category> categories);

  /// Batch-update `sortOrder` for many categories in one transaction.
  ///
  /// Keys are category IDs; values are the new sort index within the row's
  /// group (L1 ids share one index space, each parent's L2 ids share their
  /// own). The implementation MUST execute all writes in a single atomic
  /// transaction — partial saves are unacceptable.
  Future<void> updateSortOrders(Map<String, int> idToSortOrder);

  /// Delete all categories (for backup restore).
  Future<void> deleteAll();
}
