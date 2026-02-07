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
  final String type;
  final bool isSystem;
  final int sortOrder;
  final int? budgetAmount;
  final DateTime createdAt;

  const CategoryInsertData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.parentId,
    required this.level,
    required this.type,
    this.isSystem = false,
    this.sortOrder = 0,
    this.budgetAmount,
    required this.createdAt,
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
    required String type,
    bool isSystem = false,
    int sortOrder = 0,
    int? budgetAmount,
    required DateTime createdAt,
  }) async {
    await _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            name: name,
            icon: icon,
            color: color,
            parentId: Value(parentId),
            level: level,
            type: type,
            isSystem: Value(isSystem),
            sortOrder: Value(sortOrder),
            budgetAmount: Value(budgetAmount),
            createdAt: createdAt,
          ),
        );
  }

  Future<CategoryRow?> findById(String id) async {
    return (_db.select(
      _db.categories,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<CategoryRow>> findAll() async {
    return (_db.select(
      _db.categories,
    )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
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

  Future<List<CategoryRow>> findByType(String type) async {
    return (_db.select(_db.categories)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Find categories that have a non-null budget amount.
  Future<List<CategoryRow>> findWithBudget() async {
    return (_db.select(_db.categories)
          ..where((t) => t.budgetAmount.isNotNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Delete all categories (hard delete, for backup restore).
  Future<void> deleteAll() async {
    await _db.delete(_db.categories).go();
  }

  Future<void> insertBatch(List<CategoryInsertData> categories) async {
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
            type: cat.type,
            isSystem: Value(cat.isSystem),
            sortOrder: Value(cat.sortOrder),
            budgetAmount: Value(cat.budgetAmount),
            createdAt: cat.createdAt,
          ),
        );
      }
    });
  }
}
