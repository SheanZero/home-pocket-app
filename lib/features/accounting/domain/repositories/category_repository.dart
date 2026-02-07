import '../models/category.dart';
import '../models/transaction.dart';

/// Abstract repository interface for category data access.
abstract class CategoryRepository {
  Future<void> insert(Category category);
  Future<Category?> findById(String id);
  Future<List<Category>> findAll();
  Future<List<Category>> findByLevel(int level);
  Future<List<Category>> findByParent(String parentId);
  Future<List<Category>> findByType(TransactionType type);
  Future<List<Category>> findWithBudget();
  Future<void> insertBatch(List<Category> categories);

  /// Delete all categories (for backup restore).
  Future<void> deleteAll();
}
