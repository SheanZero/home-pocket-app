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
  /// SQL ORDER (DONE-02 + quick-260609-pmc-06):
  /// - active items first (`is_completed ASC`);
  /// - ACTIVE group ordered by explicit `sort_order ASC`, then `created_at ASC`;
  /// - COMPLETED group ordered by `completed_at DESC` (most recently completed
  ///   first), `created_at DESC` as a fallback for legacy null `completed_at`.
  /// The `CASE WHEN is_completed = 0 THEN …` wrappers null-out the sort_order /
  /// created_at keys for completed rows so they fall through to `completed_at`.
  ///
  /// [listType] is bound via [Variable.withString] — never string-interpolated
  /// into the SQL string (T-36-09 SQL injection prevention).
  Stream<List<ShoppingItemRow>> watchByListType(String listType) {
    return _db
        .customSelect(
          'SELECT * FROM shopping_items '
          'WHERE list_type = ? AND is_deleted = 0 '
          'ORDER BY is_completed ASC, '
          'CASE WHEN is_completed = 0 THEN sort_order END ASC, '
          'CASE WHEN is_completed = 0 THEN created_at END ASC, '
          'completed_at DESC, created_at DESC',
          variables: [Variable.withString(listType)],
          readsFrom: {_db.shoppingItems},
        )
        .watch()
        .map(
          (rows) =>
              rows.map((r) => _db.shoppingItems.map(r.data)).toList(),
        );
  }

  /// Reactive stream of ALL non-deleted items, regardless of `list_type`.
  ///
  /// Backs the "全部" (All) view, which merges private + public items into a
  /// single list. Same ordering contract as [watchByListType]; same MANDATORY
  /// `readsFrom: {_db.shoppingItems}` so the stream re-emits on table writes.
  Stream<List<ShoppingItemRow>> watchAll() {
    return _db
        .customSelect(
          'SELECT * FROM shopping_items '
          'WHERE is_deleted = 0 '
          'ORDER BY is_completed ASC, '
          'CASE WHEN is_completed = 0 THEN sort_order END ASC, '
          'CASE WHEN is_completed = 0 THEN created_at END ASC, '
          'completed_at DESC, created_at DESC',
          variables: const [],
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
  /// unchanged.
  Future<void> reorder(String id, int newSortOrder) async {
    await (_db.update(_db.shoppingItems)..where((t) => t.id.equals(id))).write(
      ShoppingItemsCompanion(
        sortOrder: Value(newSortOrder),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Re-sequence a set of items to a contiguous `sort_order` = 0..N-1 matching
  /// the order of [orderedIds].
  ///
  /// Writing a contiguous sequence (rather than a single row) is what keeps
  /// drag-to-reorder and the move-to-top/bottom buttons correct: a lone
  /// `sort_order` write leaves the column non-contiguous, so the next operation
  /// computes a position that collides with — or sits the wrong side of —
  /// another item's stale value (quick-260609-pmc-04: "drag to top lands second").
  ///
  /// Runs as a single batch so the list never observes a half-applied order.
  /// Only `sort_order` and `updated_at` are written.
  Future<void> reorderBatch(List<String> orderedIds) async {
    if (orderedIds.isEmpty) return;
    final now = DateTime.now();
    await _db.batch((batch) {
      for (var i = 0; i < orderedIds.length; i++) {
        batch.update(
          _db.shoppingItems,
          ShoppingItemsCompanion(
            sortOrder: Value(i),
            updatedAt: Value(now),
          ),
          where: (t) => t.id.equals(orderedIds[i]),
        );
      }
    });
  }
}
