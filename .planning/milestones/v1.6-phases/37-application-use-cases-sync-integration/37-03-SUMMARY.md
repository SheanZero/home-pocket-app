---
phase: 37-application-use-cases-sync-integration
plan: "03"
subsystem: application/shopping-list
tags: [tdd, wave-2, use-cases, privacy-gate, sync, completedAt, local-only-reorder]
dependency_graph:
  requires:
    - "37-02 (ShoppingItemChangeTracker + ShoppingItemSyncMapper)"
  provides:
    - CreateShoppingItemUseCase with D37-06 privacy gate and ITEM-01 validation
    - DeleteShoppingItemUseCase with soft-delete tombstone and D37-06 privacy gate
    - ToggleItemCompletedUseCase with D-03 completedAt stamp and D37-02 un-complete clear
    - ReorderShoppingItemsUseCase — local-per-device only (D37-01, no tracker/SyncEngine)
  affects:
    - lib/application/shopping_list/ (4 new files)
    - test/unit/application/shopping_list/delete_shopping_item_use_case_test.dart (bug fix)
tech_stack:
  added: []
  patterns:
    - CreateTransactionUseCase mirror pattern (uuid v4, nullable tracker/syncEngine injection)
    - DeleteTransactionUseCase exact pattern + D37-06 listType gate addition
    - Freezed copyWith(completedAt: null) — null != freezed sentinel, so null is set correctly
    - D37-06 privacy gate: `if (item.listType == 'public')` before every tracker call
    - D37-01 local-only: ReorderShoppingItemsUseCase has no tracker or SyncEngine fields
key_files:
  created:
    - lib/application/shopping_list/create_shopping_item_use_case.dart
    - lib/application/shopping_list/delete_shopping_item_use_case.dart
    - lib/application/shopping_list/toggle_item_completed_use_case.dart
    - lib/application/shopping_list/reorder_shopping_items_use_case.dart
  modified:
    - test/unit/application/shopping_list/delete_shopping_item_use_case_test.dart (Rule 1 bug fix)
decisions:
  - "CreateShoppingItemParams defined inline in create_shopping_item_use_case.dart (includes deviceId field the test requires, not in domain ShoppingItemParams)"
  - "Freezed copyWith(completedAt: null) sets field to null because null != freezed sentinel — verified in shopping_item.freezed.dart lines 787-790"
  - "delete_shopping_item_use_case_test.dart: moved any() stub before specific stubs so mocktail lastWhere picks specific matchers over wildcard"
metrics:
  duration_minutes: 6
  completed_date: "2026-06-08"
  tasks_completed: 2
  tasks_total: 2
  files_created: 4
  files_modified: 1
---

# Phase 37 Plan 03: Create / Delete / Toggle / Reorder Shopping Item Use Cases Summary

Four shopping list use cases implemented — privacy gate enforcement (D37-06) for Create/Delete/Toggle, D-03 sticky-complete timestamp + D37-02 deliberate un-complete semantics for Toggle, and local-only sort order update for Reorder (D37-01, no tracker/SyncEngine) — turning 18 Wave-0 RED tests GREEN.

## What Was Built

### Task 1: CreateShoppingItemUseCase + DeleteShoppingItemUseCase (GREEN)

**`lib/application/shopping_list/create_shopping_item_use_case.dart`**

- `CreateShoppingItemParams` defined inline (includes `deviceId` — required by test, absent from domain `ShoppingItemParams`)
- Input validation: `params.name.trim().isEmpty` → `Result.error` (ITEM-01)
- Builds `ShoppingItem` with `const Uuid().v4()` id, sets all fields from params; defaults `tags ?? const []`, `quantity ?? 1`
- Calls `await _repo.insert(item)`
- Privacy gate (D37-06): `if (item.listType == 'public')` → calls `_changeTracker?.trackCreate(ShoppingItemSyncMapper.toCreateOperation(item))`
- Fire-and-forget: `_syncEngine?.onTransactionChanged()`
- 5/5 tests GREEN — private: pendingCount==0; public: pendingCount==1; empty name: error

**`lib/application/shopping_list/delete_shopping_item_use_case.dart`**

- Validates `itemId.isEmpty` → `Result.error`
- Calls `findById(itemId)` → `Result.error` if null (MGMT-02)
- Calls `await _repo.softDelete(itemId)` — never hard-delete; tombstone survives full-sync
- Privacy gate (D37-06): `if (existing.listType == 'public')` → calls `_changeTracker?.trackDelete(itemId: itemId)`
- Fire-and-forget: `_syncEngine?.onTransactionChanged()`
- 5/5 tests GREEN

### Task 2: ToggleItemCompletedUseCase + ReorderShoppingItemsUseCase (GREEN)

**`lib/application/shopping_list/toggle_item_completed_use_case.dart`**

- `findById(itemId)` → `Result.error` if null
- Un-complete path (D37-02): `copyWith(isCompleted: false, completedAt: null, updatedAt: now)` — `null` != Freezed `freezed` sentinel, so `completedAt` is correctly set to null. This ensures the sticky-complete guard on remote devices does NOT fire (guard condition: `existing.completedAt != null && existing.completedAt!.isAfter(incomingUpdatedAt)`)
- Complete path (D-03): `copyWith(isCompleted: true, completedAt: now, updatedAt: now)` — stamps `completedAt` for sticky-complete semantics
- Privacy gate (D37-06): `if (existing.listType == 'public')` → tracker.trackUpdate
- 4/4 tests GREEN — mark-complete: completedAt non-null; un-complete: completedAt is null AND updatedAt is non-null; public toggle: pendingCount==1

**`lib/application/shopping_list/reorder_shopping_items_use_case.dart`**

- Constructor: `required ShoppingItemRepository` only — NO `changeTracker`, NO `syncEngine`
- Validates `itemId.isEmpty` → `Result.error`
- Calls `await _repo.reorder(itemId, newSortOrder)` only
- Inline comment: `// D37-01: sortOrder is local-per-device — NOT synced; no tracker or SyncEngine call`
- 4/4 tests GREEN

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed mocktail stub ordering in delete_shopping_item_use_case_test.dart**

- **Found during:** Task 1 verification run (5 create tests GREEN; 2 delete tests FAIL)
- **Issue:** `when(() => repo.findById(any()))` was registered LAST (after specific `'item-pub'` and `'item-priv'` stubs). Mocktail's `_responses.lastWhere()` iterates from last-registered first, so `any()` matched all calls including specific item IDs — `findById('item-pub')` incorrectly returned `null`.
- **Fix:** Moved `when(() => repo.findById(any()))` registration to be FIRST in `setUp`, so specific stubs registered after it win via `lastWhere`.
- **Files modified:** `test/unit/application/shopping_list/delete_shopping_item_use_case_test.dart` (1 line moved)
- **Commit:** 1c554c43

**2. [Rule 2 - Missing critical functionality] CreateShoppingItemParams defined inline**

- **Found during:** Task 1 implementation
- **Issue:** Test imports `CreateShoppingItemParams` with `deviceId` field from `create_shopping_item_use_case.dart`, but the domain `ShoppingItemParams` class has no `deviceId`. The plan said to accept `ShoppingItemParams params` but the test uses `CreateShoppingItemParams`.
- **Fix:** Defined `CreateShoppingItemParams` as a plain Dart class inside `create_shopping_item_use_case.dart` (same file, analogous to `CreateTransactionParams` pattern in `create_transaction_use_case.dart`).
- **Files modified:** `lib/application/shopping_list/create_shopping_item_use_case.dart`

## Known Stubs

None. All 4 files are complete implementations with no placeholders or hardcoded values.

## Threat Flags

None. All files are within the declared trust boundaries. Privacy gates (D37-06) are enforced:
- T-37-01 (private item leak via tracker): **mitigated** — all Create/Delete/Toggle use cases have `if (listType == 'public')` gates; unit tests assert pendingCount==0 for private operations
- T-37-05 (stale edit inadvertently un-checks completed item): **mitigated** — Toggle stamps completedAt on complete (D-03), clears to null on deliberate un-complete (D37-02); sticky-complete merge in apply handler (Plan 37-05) uses this timestamp
- T-37-06 (sortOrder synced via Delete/Toggle): **accepted** — Delete/Toggle do not serialize sortOrder; Reorder has no tracker at all (D37-01)
- T-37-SC (package installs): **accepted** — no new packages; uuid was already a project dependency

## Self-Check

### Files created:
- [x] `lib/application/shopping_list/create_shopping_item_use_case.dart` — FOUND
- [x] `lib/application/shopping_list/delete_shopping_item_use_case.dart` — FOUND
- [x] `lib/application/shopping_list/toggle_item_completed_use_case.dart` — FOUND
- [x] `lib/application/shopping_list/reorder_shopping_items_use_case.dart` — FOUND

### Commits:
- [x] 1c554c43 — feat(37-03): implement CreateShoppingItemUseCase and DeleteShoppingItemUseCase
- [x] 4adb2f0d — feat(37-03): implement ToggleItemCompletedUseCase and ReorderShoppingItemsUseCase

### Verification criteria:
- [x] `flutter test` on all 4 test files exits 0 — 18/18 GREEN
- [x] `flutter analyze lib/application/shopping_list/` — 0 issues (4 files)
- [x] `grep -c "if.*listType.*==.*'public'" create_shopping_item_use_case.dart` = 1 (D37-06)
- [x] `grep -c "trackDelete\|trackCreate\|trackUpdate" reorder_shopping_items_use_case.dart` = 0 (D37-01)
- [x] `grep -c "completedAt.*null" toggle_item_completed_use_case.dart` = 5 (D37-02)

## Self-Check: PASSED
