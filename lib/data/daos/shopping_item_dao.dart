import 'package:drift/drift.dart';

import '../app_database.dart';

/// Data access object for the ShoppingItems table.
///
/// All higher layers (repository, use cases) access shopping items exclusively
/// through this DAO. The [watchByListType] reactive stream uses `readsFrom:`
/// to guarantee Drift detects table mutations and re-emits — preventing the
/// v1.4 GAP-2 dead-stream regression (DONE-02/SYNC-06).
class ShoppingItemDao {
  ShoppingItemDao(this._db);

  final AppDatabase _db;

  /// Insert a new shopping item row.
  Future<void> insert(ShoppingItemsCompanion item) async {
    await _db.into(_db.shoppingItems).insert(item);
  }

  /// Update an existing shopping item row (matched by id).
  Future<void> update(ShoppingItemsCompanion item) async {
    await (_db.update(_db.shoppingItems)
          ..where((t) => t.id.equals(item.id.value)))
        .write(item);
  }

  /// Soft-delete a shopping item by id.
  ///
  /// Sets `is_deleted = 1` and `updated_at = now`. The row is retained in the
  /// database for sync tombstone purposes — no physical DELETE is performed.
  Future<void> softDelete(String id) async {
    await (_db.update(_db.shoppingItems)..where((t) => t.id.equals(id))).write(
      ShoppingItemsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Soft-delete all completed items of the given [listType] in one operation.
  ///
  /// Targets rows where `list_type = listType AND is_completed = 1 AND is_deleted = 0`.
  Future<void> softDeleteAllCompleted(String listType) async {
    await (_db.update(_db.shoppingItems)
          ..where((t) => t.listType.equals(listType))
          ..where((t) => t.isCompleted.equals(true))
          ..where((t) => t.isDeleted.equals(false)))
        .write(
      ShoppingItemsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Return a single row by id, or null if not found (includes soft-deleted rows).
  Future<ShoppingItemRow?> findById(String id) async {
    return (_db.select(_db.shoppingItems)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Reactive stream of active (non-deleted) items for [listType].
  ///
  /// **MANDATORY: `readsFrom: {_db.shoppingItems}`** — without this declaration
  /// Drift cannot observe table writes and the stream will never re-emit after
  /// insert/update/delete operations (v1.4 GAP-2 lesson; DONE-02/SYNC-06).
  ///
  /// SQL ORDER: `is_completed ASC, sort_order ASC, created_at ASC` (DONE-02):
  /// active items come before completed items; within each group, items are
  /// ordered by their explicit sort position, then by insertion time as
  /// a stable tiebreaker.
  ///
  /// [listType] is bound via [Variable.withString] — never string-interpolated
  /// into the SQL string (T-36-09 SQL injection prevention).
  Stream<List<ShoppingItemRow>> watchByListType(String listType) {
    return _db
        .customSelect(
          'SELECT * FROM shopping_items '
          'WHERE list_type = ? AND is_deleted = 0 '
          'ORDER BY is_completed ASC, sort_order ASC, created_at ASC',
          variables: [Variable.withString(listType)],
          readsFrom: {_db.shoppingItems},
        )
        .watch()
        .map(
          (rows) =>
              rows.map((r) => _db.shoppingItems.map(r.data)).toList(),
        );
  }

  /// Insert or update a row by primary key conflict.
  ///
  /// Uses Drift's built-in `insertOnConflictUpdate` which performs an
  /// `INSERT OR REPLACE` under the hood, replacing all columns on conflict.
  Future<void> upsert(ShoppingItemsCompanion item) async {
    await _db.into(_db.shoppingItems).insertOnConflictUpdate(item);
  }

  /// Update the sort position of a single item.
  ///
  /// Only `sort_order` and `updated_at` are written — all other columns remain
  /// unchanged. Used by the drag-to-reorder gesture in the UI layer.
  Future<void> reorder(String id, int newSortOrder) async {
    await (_db.update(_db.shoppingItems)..where((t) => t.id.equals(id))).write(
      ShoppingItemsCompanion(
        sortOrder: Value(newSortOrder),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
