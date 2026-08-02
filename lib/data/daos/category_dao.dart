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
    int sharedRevision = 0,
    String sharedOriginDeviceId = '',
    bool sharedIsDeleted = false,
  }) async {
    assert(level == 1 || level == 2, 'level must be 1 or 2');
    assert(level != 1 || parentId == null, 'L1 must have parentId == null');
    assert(level != 2 || parentId != null, 'L2 must have parentId != null');

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
            isSystem: Value(isSystem),
            isArchived: Value(isArchived),
            sortOrder: Value(sortOrder),
            sharedRevision: Value(sharedRevision),
            sharedOriginDeviceId: Value(sharedOriginDeviceId),
            sharedIsDeleted: Value(sharedIsDeleted),
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
    final changesSharedSemantics =
        name != null || icon != null || color != null;
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        icon: icon != null ? Value(icon) : const Value.absent(),
        color: color != null ? Value(color) : const Value.absent(),
        isArchived: isArchived != null
            ? Value(isArchived)
            : const Value.absent(),
        sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
        sharedRevision: changesSharedSemantics
            ? Value(updatedAt.toUtc().microsecondsSinceEpoch)
            : const Value.absent(),
        sharedOriginDeviceId: changesSharedSemantics
            ? const Value('')
            : const Value.absent(),
        sharedIsDeleted: changesSharedSemantics
            ? const Value(false)
            : const Value.absent(),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  /// Update only the [sortOrder] column for a single row.
  ///
  /// Dedicated hot-path helper for drag-reorder; avoids the many-optional-
  /// field signature of [updateCategory]. Stamps [updatedAt] to now.
  Future<void> updateSortOrder(String id, int sortOrder) async {
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        sortOrder: Value(sortOrder),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Batch-update `sortOrder` for many categories in one atomic transaction.
  ///
  /// Called by [CategoryRepository.updateSortOrders] when the user saves
  /// a drag-reorder. Empty map is a no-op.
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {
    if (idToSortOrder.isEmpty) return;
    await _db.transaction(() async {
      for (final entry in idToSortOrder.entries) {
        await updateSortOrder(entry.key, entry.value);
      }
    });
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

  Future<List<CategoryRow>> findActive() async {
    return (_db.select(_db.categories)
          ..where((t) => t.isArchived.equals(false))
          ..where((t) => t.sharedIsDeleted.equals(false))
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

  Future<void> applySharedSnapshots(List<CategoryRow> incomingRows) async {
    await _db.transaction(() async {
      for (final incoming in incomingRows) {
        final existing = await findById(incoming.id);
        if (existing?.isSystem == true) continue;

        if (incoming.level == 2 &&
            incoming.parentId != null &&
            await findById(incoming.parentId!) == null) {
          // Keep the child renderable even when a buggy/old peer omitted the
          // parent snapshot. The hidden placeholder is replaced by a later
          // authoritative L1 snapshot.
          await _db
              .into(_db.categories)
              .insert(
                CategoriesCompanion.insert(
                  id: incoming.parentId!,
                  name: 'Unknown category',
                  icon: incoming.icon,
                  color: incoming.color,
                  parentId: const Value(null),
                  level: 1,
                  sharedIsDeleted: const Value(true),
                  createdAt: incoming.createdAt,
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }

        if (existing == null) {
          await _db.into(_db.categories).insert(incoming);
          continue;
        }
        if (_compareSharedVersion(incoming, existing) <= 0) continue;

        await (_db.update(
          _db.categories,
        )..where((table) => table.id.equals(incoming.id))).write(
          CategoriesCompanion(
            name: Value(incoming.name),
            icon: Value(incoming.icon),
            color: Value(incoming.color),
            parentId: Value(incoming.parentId),
            level: Value(incoming.level),
            sharedRevision: Value(incoming.sharedRevision),
            sharedOriginDeviceId: Value(incoming.sharedOriginDeviceId),
            sharedIsDeleted: Value(incoming.sharedIsDeleted),
            createdAt: Value(incoming.createdAt),
            updatedAt: Value(incoming.updatedAt),
          ),
        );
      }
    });
  }

  int _compareSharedVersion(CategoryRow left, CategoryRow right) {
    var comparison = left.sharedRevision.compareTo(right.sharedRevision);
    if (comparison != 0) return comparison;
    comparison = (left.sharedIsDeleted ? 1 : 0).compareTo(
      right.sharedIsDeleted ? 1 : 0,
    );
    if (comparison != 0) return comparison;
    comparison = left.sharedOriginDeviceId.compareTo(
      right.sharedOriginDeviceId,
    );
    if (comparison != 0) return comparison;
    return _sharedPayloadKey(left).compareTo(_sharedPayloadKey(right));
  }

  String _sharedPayloadKey(CategoryRow row) => [
    row.name,
    row.icon,
    row.color,
    row.parentId ?? '',
    row.level.toString(),
    row.createdAt.toUtc().toIso8601String(),
    row.updatedAt?.toUtc().toIso8601String() ?? '',
  ].join('\u0000');

  /// Delete all categories (hard delete, for backup restore).
  Future<void> deleteAll() async {
    await _db.delete(_db.categories).go();
  }

  Future<void> insertBatch(List<CategoryInsertData> categories) async {
    for (final cat in categories) {
      assert(cat.level == 1 || cat.level == 2, 'level must be 1 or 2');
      assert(
        cat.level != 1 || cat.parentId == null,
        'L1 "${cat.id}" must have parentId == null',
      );
      assert(
        cat.level != 2 || cat.parentId != null,
        'L2 "${cat.id}" must have parentId != null',
      );
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
            sharedRevision: Value(
              cat.isSystem
                  ? 0
                  : (cat.updatedAt ?? cat.createdAt)
                        .toUtc()
                        .microsecondsSinceEpoch,
            ),
            createdAt: cat.createdAt,
            updatedAt: Value(cat.updatedAt),
          ),
        );
      }
    });
  }
}
