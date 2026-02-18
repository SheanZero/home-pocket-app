import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../app_database.dart';
import '../daos/category_dao.dart';

/// Concrete implementation of [CategoryRepository].
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({required CategoryDao dao}) : _dao = dao;

  final CategoryDao _dao;

  @override
  Future<void> insert(Category category) async {
    await _dao.insertCategory(
      id: category.id,
      name: category.name,
      icon: category.icon,
      color: category.color,
      parentId: category.parentId,
      level: category.level,
      isSystem: category.isSystem,
      isArchived: category.isArchived,
      sortOrder: category.sortOrder,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
  }

  @override
  Future<void> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
  }) async {
    await _dao.updateCategory(
      id: id,
      name: name,
      icon: icon,
      color: color,
      isArchived: isArchived,
      sortOrder: sortOrder,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Category?> findById(String id) async {
    final row = await _dao.findById(id);
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<List<Category>> findAll() async {
    final rows = await _dao.findAll();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Category>> findActive() async {
    final rows = await _dao.findActive();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Category>> findByLevel(int level) async {
    final rows = await _dao.findByLevel(level);
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Category>> findByParent(String parentId) async {
    final rows = await _dao.findByParent(parentId);
    return rows.map(_toModel).toList();
  }

  @override
  Future<void> deleteAll() => _dao.deleteAll();

  @override
  Future<void> insertBatch(List<Category> categories) async {
    await _dao.insertBatch(
      categories
          .map(
            (c) => CategoryInsertData(
              id: c.id,
              name: c.name,
              icon: c.icon,
              color: c.color,
              parentId: c.parentId,
              level: c.level,
              isSystem: c.isSystem,
              isArchived: c.isArchived,
              sortOrder: c.sortOrder,
              createdAt: c.createdAt,
              updatedAt: c.updatedAt,
            ),
          )
          .toList(),
    );
  }

  Category _toModel(CategoryRow row) {
    return Category(
      id: row.id,
      name: row.name,
      icon: row.icon,
      color: row.color,
      parentId: row.parentId,
      level: row.level,
      isSystem: row.isSystem,
      isArchived: row.isArchived,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
