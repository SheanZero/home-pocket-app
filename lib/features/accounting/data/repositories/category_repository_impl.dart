import 'package:drift/drift.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';

/// Implementation of CategoryRepository
///
/// Handles CRUD operations for categories with:
/// - Simple data access (no encryption needed)
/// - System category protection (prevents deletion)
/// - Idempotent system category seeding
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryDao _categoryDao;

  CategoryRepositoryImpl(this._categoryDao);

  @override
  Future<void> insert(Category category) async {
    await _categoryDao.into(_categoryDao.categories).insert(
          CategoriesCompanion.insert(
            id: category.id,
            name: category.name,
            icon: category.icon,
            color: category.color,
            parentId: Value(category.parentId),
            level: category.level,
            type: category.type.name,
            isSystem: Value(category.isSystem),
            sortOrder: Value(category.sortOrder),
            createdAt: category.createdAt,
          ),
        );
  }

  @override
  Future<void> update(Category category) async {
    await (_categoryDao.update(_categoryDao.categories)
          ..where((t) => t.id.equals(category.id)))
        .write(
      CategoriesCompanion(
        name: Value(category.name),
        icon: Value(category.icon),
        color: Value(category.color),
        parentId: Value(category.parentId),
        level: Value(category.level),
        type: Value(category.type.name),
        isSystem: Value(category.isSystem),
        sortOrder: Value(category.sortOrder),
      ),
    );
  }

  @override
  Future<bool> delete(String id) async {
    // Check if category is system category
    final category = await findById(id);
    if (category == null) return false;
    if (category.isSystem) return false; // Cannot delete system categories

    // Delete category
    final deletedRows = await (_categoryDao.delete(_categoryDao.categories)
          ..where((t) => t.id.equals(id)))
        .go();

    return deletedRows > 0;
  }

  @override
  Future<Category?> findById(String id) async {
    final result = await (_categoryDao.select(_categoryDao.categories)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    return result != null ? _entityToDomain(result) : null;
  }

  @override
  Future<List<Category>> findAll() async {
    final results = await _categoryDao.select(_categoryDao.categories).get();
    return results.map(_entityToDomain).toList();
  }

  @override
  Future<List<Category>> findByLevel(int level) async {
    final allCategories = await findAll();
    return allCategories.where((c) => c.level == level).toList();
  }

  @override
  Future<List<Category>> findByParent(String parentId) async {
    final allCategories = await findAll();
    return allCategories.where((c) => c.parentId == parentId).toList();
  }

  @override
  Future<List<Category>> findByType(TransactionType type) async {
    final allCategories = await findAll();
    return allCategories.where((c) => c.type == type).toList();
  }

  @override
  Future<bool> canDelete(String id) async {
    // Check if category is system category
    final category = await findById(id);
    if (category == null) return false;
    if (category.isSystem) return false;

    // Check if category has transactions
    // For now, we return true (transaction check will be implemented when TransactionRepository is complete)
    // TODO: Implement transaction count check when transaction queries are available
    return true;
  }

  @override
  Future<void> seedSystemCategories() async {
    // Get existing category IDs to check for duplicates
    final existingCategories = await findAll();
    final existingIds = existingCategories.map((c) => c.id).toSet();

    // Filter out categories that already exist (idempotency)
    final categoriesToInsert = Category.systemCategories
        .where((c) => !existingIds.contains(c.id))
        .toList();

    // Insert only new categories
    for (final category in categoriesToInsert) {
      await insert(category);
    }
  }

  /// Convert CategoryEntity to Category domain model
  Category _entityToDomain(CategoryEntity entity) {
    return Category(
      id: entity.id,
      name: entity.name,
      icon: entity.icon,
      color: entity.color,
      parentId: entity.parentId,
      level: entity.level,
      type: entity.type == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      isSystem: entity.isSystem,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
    );
  }
}
