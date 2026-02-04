import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

/// Repository interface for category data access
abstract class CategoryRepository {
  /// Insert new category
  Future<void> insert(Category category);

  /// Update existing category
  Future<void> update(Category category);

  /// Delete category (only if not system category)
  Future<bool> delete(String id);

  /// Find category by ID
  Future<Category?> findById(String id);

  /// Get all categories
  Future<List<Category>> findAll();

  /// Get categories by level (1, 2, or 3)
  Future<List<Category>> findByLevel(int level);

  /// Get categories by parent ID
  Future<List<Category>> findByParent(String parentId);

  /// Get categories by type (expense/income)
  Future<List<Category>> findByType(TransactionType type);

  /// Check if category can be deleted
  Future<bool> canDelete(String id);

  /// Seed system categories
  Future<void> seedSystemCategories();
}
