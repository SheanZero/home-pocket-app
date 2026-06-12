---
phase: 36
plan: "05"
type: summary
status: complete
subsystem: data/dao
tags: [drift, dao, shopping-list, reactive-stream, soft-delete, tdd-green]
completed_date: "2026-06-07"
duration_minutes: 5

dependency_graph:
  requires:
    - "36-02 (ShoppingItems table + v20 migration)"
  provides:
    - lib/data/daos/shopping_item_dao.dart
  affects:
    - "Plan 06 — ShoppingItemRepositoryImpl now has a DAO to inject"
    - "Plan 36-01 DAO test turns GREEN (3/3)"

tech_stack:
  added: []
  patterns:
    - "Plain class DAO (no @DriftAccessor) — same pattern as TransactionDao"
    - "customSelect with readsFrom: {table} for mandatory reactive stream (v1.4 GAP-2 prevention)"
    - "softDelete via update+write (no physical DELETE — sync tombstone preserved)"
    - "insertOnConflictUpdate for upsert semantics"

key_files:
  created:
    - lib/data/daos/shopping_item_dao.dart
  modified: []

decisions:
  - "Plain class, no @DriftAccessor annotation — matches TransactionDao pattern; DriftAccessor only needed when DAO is wired directly into @DriftDatabase annotation"
  - "watchByListType uses customSelect (not typed query builder) to allow explicit readsFrom: declaration — required for Drift reactive stream to detect table writes"
  - "SQL uses is_deleted = 0 (integer 0, not false — SQLite boolean convention in raw SQL)"

metrics:
  duration_minutes: 5
  tasks_completed: 1
  files_created: 1
  files_modified: 0
---

# Phase 36 Plan 05: ShoppingItemDao Summary

`ShoppingItemDao` implemented with 8 methods. Reactive `watchByListType` stream uses `readsFrom: {_db.shoppingItems}` (mandatory v1.4 GAP-2 prevention) and `ORDER BY is_completed ASC, sort_order ASC, created_at ASC` (DONE-02). Wave-0 DAO test turns GREEN (3/3).

## What Was Built

**`lib/data/daos/shopping_item_dao.dart`** — 8 methods following TransactionDao pattern:

| Method | Description |
|--------|-------------|
| `insert(ShoppingItemsCompanion)` | Plain into().insert() — returns `Future<void>` |
| `update(ShoppingItemsCompanion)` | update()..where(id).write() — returns `Future<void>` |
| `softDelete(String id)` | Writes `isDeleted=true, updatedAt=now` — no physical DELETE |
| `softDeleteAllCompleted(String listType)` | Batch soft-delete: listType + isCompleted=true + isDeleted=false |
| `findById(String id)` | getSingleOrNull() — includes soft-deleted rows |
| `watchByListType(String listType)` | Reactive customSelect with `readsFrom:` + DONE-02 ORDER BY |
| `upsert(ShoppingItemsCompanion)` | insertOnConflictUpdate — INSERT OR REPLACE semantics |
| `reorder(String id, int newSortOrder)` | Writes sortOrder+updatedAt only |

**Key implementation details:**

- `watchByListType` uses `customSelect(sql, variables: [Variable.withString(listType)], readsFrom: {_db.shoppingItems})` — never string interpolation (T-36-09 SQL injection prevention)
- SQL filter: `WHERE list_type = ? AND is_deleted = 0` with `ORDER BY is_completed ASC, sort_order ASC, created_at ASC`
- `.watch().map(rows => rows.map(r => _db.shoppingItems.map(r.data)).toList())` converts `QueryRow` to typed `ShoppingItemRow`
- `softDelete` and `softDeleteAllCompleted` both use `..where()` chaining then `.write()` — not physical DELETE

## Verification Results

| Check | Result |
|-------|--------|
| `flutter test test/unit/data/daos/shopping_item_dao_test.dart` | 3/3 GREEN |
| `grep 'readsFrom.*shoppingItems'` | PASS |
| `grep 'is_completed ASC'` | PASS |
| `grep 'Variable.withString'` | PASS |
| `flutter analyze lib/data/daos/shopping_item_dao.dart` | 0 issues |

Note: `flutter analyze` (full project) shows 8 pre-existing errors in `shopping_item_repository_impl_test.dart` — that test file is in intentional RED state waiting for Plans 03, 04, and 06 to provide the domain models and repository implementation. These are not introduced by this plan.

## Deviations from Plan

None — plan executed exactly as written.

The plan's action section mentions running `flutter pub run build_runner build --delete-conflicting-outputs` after writing the file. Since `ShoppingItemDao` is a plain class (no `@DriftAccessor` annotation), codegen is not required for it. The generated `app_database.g.dart` is already current from Plan 02. Build_runner run was skipped as it produces no new outputs and would only rewrite identical content.

## Known Stubs

None — all 8 methods are fully implemented.

## Threat Flags

None — no new network endpoints, auth paths, or trust boundaries introduced. SQL injection prevention (T-36-09) is implemented via `Variable.withString(listType)` parameterized query (verified by grep). Per-segment isolation (T-36-10) enforced at DAO level via `WHERE list_type = ?` parameterization.

## Self-Check: PASSED

- `lib/data/daos/shopping_item_dao.dart` FOUND ✓
- `grep 'readsFrom.*shoppingItems'` exits 0 ✓
- `grep 'is_completed ASC'` exits 0 ✓
- `grep 'Variable.withString'` exits 0 ✓
- `flutter test test/unit/data/daos/shopping_item_dao_test.dart` — 3/3 GREEN ✓
- `flutter analyze lib/data/daos/shopping_item_dao.dart` — 0 issues ✓
- Commit 80ca99bf FOUND ✓
