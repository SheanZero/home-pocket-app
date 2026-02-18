import 'package:drift/drift.dart';

import '../app_database.dart';

/// Parameter object for batch category insertion.
class CategoryInsertData {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String? parentId;
  final int level;
  final bool isSystem;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CategoryInsertData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.parentId,
    required this.level,
    this.isSystem = false,
    this.isArchived = false,
    this.sortOrder = 0,
    required this.createdAt,
    this.updatedAt,
  });
}

/// Data access object for the Categories table.
class CategoryDao {
  CategoryDao(this._db);

  final AppDatabase _db;

  Future<void> insertCategory({
    required String id,
    required String name,
    required String icon,
    required String color,
    String? parentId,
    required int level,
    bool isSystem = false,
    bool isArchived = false,
    int sortOrder = 0,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) async {
    assert(level == 1 || level == 2, 'level must be 1 or 2');
    assert(level != 1 || parentId == null, 'L1 must have parentId == null');
    assert(level != 2 || parentId != null, 'L2 must have parentId != null');

    await _db.into(_db.categories).insert(
      CategoriesCompanion.insert(
        id: id,
        name: name,
        icon: icon,
        color: color,
        parentId: Value(parentId),
        level: level,
        isSystem: Value(isSystem),
        isArchived: Value(isArchived),
        sortOrder: Value(sortOrder),
        createdAt: createdAt,
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
    required DateTime updatedAt,
  }) async {
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        icon: icon != null ? Value(icon) : const Value.absent(),
        color: color != null ? Value(color) : const Value.absent(),
        isArchived:
            isArchived != null ? Value(isArchived) : const Value.absent(),
        sortOrder:
            sortOrder != null ? Value(sortOrder) : const Value.absent(),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<CategoryRow?> findById(String id) async {
    return (_db.select(_db.categories)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<CategoryRow>> findAll() async {
    return (_db.select(_db.categories)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<List<CategoryRow>> findActive() async {
    return (_db.select(_db.categories)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<List<CategoryRow>> findByLevel(int level) async {
    return (_db.select(_db.categories)
          ..where((t) => t.level.equals(level))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<List<CategoryRow>> findByParent(String parentId) async {
    return (_db.select(_db.categories)
          ..where((t) => t.parentId.equals(parentId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Delete all categories (hard delete, for backup restore).
  Future<void> deleteAll() async {
    await _db.delete(_db.categories).go();
  }

  Future<void> insertBatch(List<CategoryInsertData> categories) async {
    for (final cat in categories) {
      assert(cat.level == 1 || cat.level == 2, 'level must be 1 or 2');
      assert(cat.level != 1 || cat.parentId == null,
          'L1 "${cat.id}" must have parentId == null');
      assert(cat.level != 2 || cat.parentId != null,
          'L2 "${cat.id}" must have parentId != null');
    }

    await _db.batch((batch) {
      for (final cat in categories) {
        batch.insert(
          _db.categories,
          CategoriesCompanion.insert(
            id: cat.id,
            name: cat.name,
            icon: cat.icon,
            color: cat.color,
            parentId: Value(cat.parentId),
            level: cat.level,
            isSystem: Value(cat.isSystem),
            isArchived: Value(cat.isArchived),
            sortOrder: Value(cat.sortOrder),
            createdAt: cat.createdAt,
            updatedAt: Value(cat.updatedAt),
          ),
        );
      }
    });
  }
}
