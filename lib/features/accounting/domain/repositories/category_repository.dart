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

  /// Delete all categories (for backup restore).
  Future<void> deleteAll();
}
