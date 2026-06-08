---
phase: 37-application-use-cases-sync-integration
plan: "04"
subsystem: application/shopping-list
tags: [tdd, wave-2, use-cases, privacy-gate, sync, listType-immutability, bulk-delete]
dependency_graph:
  requires:
    - "37-02 (ShoppingItemChangeTracker + ShoppingItemSyncMapper)"
    - "37-03 (sibling wave-2 use cases — conventions matched)"
  provides:
    - UpdateShoppingItemUseCase with D37-04 listType immutability guard (fail-fast Result.error with 'Invariant')
    - ClearCompletedItemsUseCase with per-item tracker ops for public listType (DONE-03, D37-06)
  affects:
    - lib/application/shopping_list/ (2 new files, all 6 use cases now complete)
tech_stack:
  added: []
  patterns:
    - D37-04 fail-fast guard: listType != existing.listType → Result.error('Invariant violation…') before copyWith
    - Freezed copyWith coalesce pattern (null param → keep existing field)
    - watchByListType().first one-shot snapshot read before bulk delete (D37-06, DONE-03)
    - D37-06 privacy gate at use-case boundary: if (listType == 'public') before every tracker call
key_files:
  created:
    - lib/application/shopping_list/update_shopping_item_use_case.dart
    - lib/application/shopping_list/clear_completed_items_use_case.dart
  modified: []
decisions:
  - "D37-04 guard placed BEFORE copyWith — fail-fast, not silent no-op (SC-2, SYNC-03)"
  - "ClearCompleted reads watchByListType().first before bulk delete to capture item IDs for per-item tracker tombstones (D37-06, DONE-03)"
  - "note field pass-through (no coalesce) in UpdateShoppingItemUseCase — null clears the field (EDIT-02 convention from UpdateTransactionUseCase)"
metrics:
  duration_minutes: 4
  completed_date: "2026-06-08"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
---

# Phase 37 Plan 04: UpdateShoppingItemUseCase + ClearCompletedItemsUseCase Summary

Two remaining Wave-2 shopping list use cases implemented — UpdateShoppingItemUseCase with D37-04 listType immutability guard (fail-fast Result.error containing 'Invariant') and ClearCompletedItemsUseCase with per-item tracker delete ops for public lists — turning 9 Wave-0 RED tests GREEN.

## What Was Built

### Task 1: UpdateShoppingItemUseCase (GREEN — 5/5 tests)

`lib/application/shopping_list/update_shopping_item_use_case.dart`

Mirrors `UpdateTransactionUseCase` structure with two critical additions:

1. **D37-04 listType immutability guard (fail-fast)** — placed immediately after `findById`, before any `copyWith`:
   ```dart
   // D37-04: listType is immutable after creation — fail-fast for buggy callers (D6/SYNC-03)
   if (params.listType != null && params.listType != existing.listType) {
     return Result.error(
       'Invariant violation: listType cannot be changed after creation '
       '(D6/SYNC-03). Current: ${existing.listType}, attempted: ${params.listType}',
     );
   }
   ```
   Error message contains 'Invariant' — Wave-0 test assertion `result.error!.contains('Invariant')` passes.

2. **Freezed copyWith coalesce/pass-through pattern**:
   - Coalesce fields: `name`, `ledgerType`, `categoryId`, `tags`, `quantity`, `estimatedPrice` use `?? existing.field`
   - Pass-through: `note` applied verbatim (null clears — EDIT-02 convention)
   - Immutable fields preserved by copyWith default: `isCompleted`, `completedAt`, `listType`, `sortOrder`, `id`, `deviceId`, `addedByBookId`, `createdAt`, `isDeleted`, `isSynced`

3. **D37-06 privacy gate** — `if (existing.listType == 'public')` before `trackUpdate` call. Since `listType` is immutable (D37-04), `existing.listType` is the authoritative source.

Test results (5/5 GREEN):
- `listType change returns Result.error with 'Invariant' in message (D37-04, SC-2, SYNC-03)` ✓
- `name update succeeds and calls repo.update (ITEM-04)` ✓
- `public update enqueues tracker op (SYNC-01)` → `pendingCount == 1` ✓
- `private update does NOT enqueue tracker op (D37-06)` → `pendingCount == 0` ✓
- `item not found returns Result.error` ✓

### Task 2: ClearCompletedItemsUseCase (GREEN — 4/4 tests)

`lib/application/shopping_list/clear_completed_items_use_case.dart`

Bulk soft-delete with per-item tracker emission for public lists:

1. **Public path** — pre-reads item IDs before bulk delete, then emits one `trackDelete` per completed item:
   ```dart
   // Read IDs before bulk-delete so we can emit per-item tracker ops (D37-06, DONE-03)
   final items = await _repo.watchByListType(listType).first;
   final completed = items.where((i) => i.isCompleted && !i.isDeleted).toList();
   await _repo.softDeleteAllCompleted(listType); // one DB write, no N+1
   for (final item in completed) {
     _changeTracker?.trackDelete(itemId: item.id);
   }
   ```

2. **Private path** — `softDeleteAllCompleted(listType)` only:
   ```dart
   // D37-06: private items never enter sync pipeline — no tracker ops emitted
   await _repo.softDeleteAllCompleted(listType);
   ```

3. **`watchByListType().first`** — one-shot stream snapshot (established Drift pattern for non-persistent reads). Completes after the first emission without holding a subscription open.

Test results (4/4 GREEN):
- `softDeleteAllCompleted called with correct listType (DONE-03, SC-2)` ✓
- `private clearCompleted does NOT enqueue tracker ops (D37-06)` → `pendingCount == 0` ✓
- `public clearCompleted enqueues one tracker op per completed item (SC-2, SYNC-01)` → `pendingCount == 2` ✓
- `private list soft-delete calls repo with private listType` ✓

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. Both files are complete implementations with no placeholders or hardcoded values.

## Threat Flags

None. All files are within the declared trust boundaries.

- T-37-01 (private item leak via Update/ClearCompleted): **mitigated** — both use cases have `if (listType == 'public')` gates; unit tests assert pendingCount==0 for private operations
- T-37-07 (listType changed via UpdateShoppingItemUseCase): **mitigated** — fail-fast guard at line 1 of execute(); error message contains 'Invariant'; test asserts `result.error!.contains('Invariant')` (D37-04, SC-2, SYNC-03)
- T-37-08 (ClearCompleted emits wrong number of tracker ops): **mitigated** — pre-read filters `isCompleted && !isDeleted`; `trackDelete` called once per matching item; test asserts `pendingCount == 2` for exactly 2 completed public items
- T-37-SC (package installs): **accepted** — no new packages

## Self-Check

### Files created:
- [x] `lib/application/shopping_list/update_shopping_item_use_case.dart` — FOUND
- [x] `lib/application/shopping_list/clear_completed_items_use_case.dart` — FOUND

### Commits:
- [x] 6631ae22 — feat(37-04): implement UpdateShoppingItemUseCase with D37-04 listType immutability guard
- [x] d9209099 — feat(37-04): implement ClearCompletedItemsUseCase with bulk soft-delete and per-item tracker ops

### Verification criteria:
- [x] `flutter test update_shopping_item_use_case_test.dart clear_completed_items_use_case_test.dart` exits 0 (9/9 GREEN)
- [x] `flutter analyze lib/application/shopping_list/` — 0 issues (6 files now complete)
- [x] `grep -c 'Invariant' update_shopping_item_use_case.dart` = 4 (≥1 required)
- [x] `grep -c "listType.*==.*'public'" update_shopping_item_use_case.dart` = 1
- [x] `grep -c "softDeleteAllCompleted" clear_completed_items_use_case.dart` = 2

## Self-Check: PASSED
