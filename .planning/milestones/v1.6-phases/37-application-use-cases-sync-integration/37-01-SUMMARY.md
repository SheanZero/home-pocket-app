---
phase: 37-application-use-cases-sync-integration
plan: "01"
subsystem: application/shopping-list + application/family-sync
tags: [tdd, wave-0, test-scaffolds, shopping-list, sync, privacy-gate]
dependency_graph:
  requires: []
  provides:
    - Wave-0 TDD test scaffolds for 6 shopping list use cases (SC-1..SC-5)
    - Wave-0 ShoppingItemChangeTracker unit test with D37-06 privacy gate group (SC-3)
    - Wave-0 shopping sync round-trip integration test (SC-5, SYNC-06)
    - Constructor site updates for 4 existing test files (RED — compile until Wave 3)
  affects:
    - test/unit/application/shopping_list/ (6 new RED test files)
    - test/unit/application/family_sync/ (1 new + 2 modified)
    - test/unit/features/family_sync/presentation/providers/ (1 modified)
    - test/integration/sync/ (1 new + 1 modified)
tech_stack:
  added: []
  patterns:
    - Wave-0 RED test scaffold pattern (TDD contract before production code)
    - ShoppingItemChangeTracker privacy gate (D37-06 dual enforcement)
    - Nullable tracker injection (constructor optional param)
key_files:
  created:
    - test/unit/application/shopping_list/create_shopping_item_use_case_test.dart
    - test/unit/application/shopping_list/update_shopping_item_use_case_test.dart
    - test/unit/application/shopping_list/delete_shopping_item_use_case_test.dart
    - test/unit/application/shopping_list/toggle_item_completed_use_case_test.dart
    - test/unit/application/shopping_list/reorder_shopping_items_use_case_test.dart
    - test/unit/application/shopping_list/clear_completed_items_use_case_test.dart
    - test/unit/application/family_sync/shopping_item_change_tracker_test.dart
    - test/integration/sync/shopping_sync_round_trip_test.dart
  modified:
    - test/unit/application/family_sync/apply_sync_operations_use_case_test.dart
    - test/unit/application/family_sync/phase6_sync_coverage_test.dart
    - test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart
    - test/integration/sync/bill_sync_round_trip_test.dart
decisions:
  - "Wave-0 test scaffolds intentionally RED — imports reference production classes not yet implemented (Wave 1-3 territory)"
  - "ShoppingItemChangeTracker tests use REAL tracker (not mocked) to assert pendingCount — mirrors transaction_change_tracker_test.dart pattern"
  - "apply_sync_operations_use_case_test.dart new shopping_item group uses mock repo (not real DB) for unit-level isolation; full DB round-trip is in shopping_sync_round_trip_test.dart"
  - "phase6_sync_coverage_test.dart SyncOrchestrator reconstructed in the new shopping-flush test to avoid contaminating existing test state"
  - "sync_providers_characterization_test.dart imports shoppingItemChangeTrackerProvider via show clause — will be RED until Wave 3 adds the provider to state_sync.dart"
metrics:
  duration_minutes: 10
  completed_date: "2026-06-08"
  tasks_completed: 2
  tasks_total: 2
  files_created: 8
  files_modified: 4
---

# Phase 37 Plan 01: Wave-0 TDD Test Scaffolds Summary

Wave-0 test scaffolds created for the full Phase 37 TDD contract — 8 new files + 4 modified construction sites establishing the machine-verifiable RED/GREEN harness for shopping list use cases and sync integration.

## What Was Built

### Task 1: 6 use case unit test scaffolds (RED)

All 6 files live in `test/unit/application/shopping_list/` and import production classes that do not yet exist.

- `create_shopping_item_use_case_test.dart` — SC-1 privacy gate: private create → pendingCount==0; public create → pendingCount==1; empty name validation (ITEM-01)
- `update_shopping_item_use_case_test.dart` — SC-2 listType immutability: returns `Result.error` containing 'Invariant' on `listType` change attempt (D37-04, SYNC-03); name update calls repo.update; public/private tracker gating
- `delete_shopping_item_use_case_test.dart` — MGMT-01/02: softDelete called; public delete enqueues tombstone tracker op; private delete skips tracker; missing itemId returns error
- `toggle_item_completed_use_case_test.dart` — DONE-01 toggle complete; D37-02 deliberate un-complete clears `completedAt` to null + fresh `updatedAt` so sticky-complete guard does not fire
- `reorder_shopping_items_use_case_test.dart` — D37-01: repo.reorder called; no tracker involvement (local-per-device only); no ShoppingItemChangeTracker constructor param
- `clear_completed_items_use_case_test.dart` — DONE-03: bulk softDeleteAllCompleted; private clear → pendingCount==0; public clear with 2 completed items → pendingCount==2 (per-item tracker ops)

### Task 2: Change tracker test + integration scaffold + 4 construction site updates (RED)

**New files:**
- `shopping_item_change_tracker_test.dart` — Mirrors `transaction_change_tracker_test.dart` structure; adds `privacy gate (D37-06 second safety net)` group: trackCreate with 'private' → pendingCount==0; 'public' → pendingCount==1; trackUpdate with private ignored; trackDelete always enqueues (caller is gate)
- `shopping_sync_round_trip_test.dart` — SC-5 integration: public item from member A appears in watchByListType('public') stream (SYNC-06); private item NEVER appears in public stream (SYNC-02); tombstone not resurrected by stale remote update (SC-4)

**Modified files (4 construction site atomic updates):**
- `apply_sync_operations_use_case_test.dart` — Added `shoppingItemRepository: mockShoppingItemRepository` param + 3 new `shopping_item branch` tests: D37-05 fault isolation (bad shopping op doesn't abort bill ops), SC-4 tombstone behavior, SC-4 sticky-complete merge
- `phase6_sync_coverage_test.dart` — Added `shoppingChangeTracker: ShoppingItemChangeTracker()` to SyncOrchestrator constructor + new `incrementalPush flushes and pushes shopping ops` test (SC-3, SYNC-01)
- `sync_providers_characterization_test.dart` — Added `shoppingItemRepositoryProvider` mock override + `shoppingItemChangeTrackerProvider` construction tests (SC-3 keepAlive)
- `bill_sync_round_trip_test.dart` — Added `shoppingItemRepository: mockShoppingItemRepository` named param at construction site (atomic with other 3 sites)

## Deviations from Plan

None — plan executed exactly as written. All 4 modified files compile as RED until Wave 3 implements the constructor changes.

## Known Stubs

None. These are test files only. No production code was created or stubbed.

## Threat Flags

None. This plan creates only test files. No new production surface introduced.

## Self-Check

### Files created:
- [x] `test/unit/application/shopping_list/create_shopping_item_use_case_test.dart` — FOUND
- [x] `test/unit/application/shopping_list/update_shopping_item_use_case_test.dart` — FOUND
- [x] `test/unit/application/shopping_list/delete_shopping_item_use_case_test.dart` — FOUND
- [x] `test/unit/application/shopping_list/toggle_item_completed_use_case_test.dart` — FOUND
- [x] `test/unit/application/shopping_list/reorder_shopping_items_use_case_test.dart` — FOUND
- [x] `test/unit/application/shopping_list/clear_completed_items_use_case_test.dart` — FOUND
- [x] `test/unit/application/family_sync/shopping_item_change_tracker_test.dart` — FOUND
- [x] `test/integration/sync/shopping_sync_round_trip_test.dart` — FOUND

### Commits:
- [x] d653f3dd — test(37-01): add Wave-0 use case unit test scaffolds (6 RED files)
- [x] 68095c33 — test(37-01): add change tracker test + integration scaffold; modify 4 existing construction sites

### Verification criteria:
- [x] `ls test/unit/application/shopping_list/*.dart | wc -l` = 6
- [x] `ls shopping_item_change_tracker_test.dart` exists
- [x] `ls shopping_sync_round_trip_test.dart` exists
- [x] `grep -c 'shoppingItemRepository' bill_sync_round_trip_test.dart` = 1
- [x] `grep -c 'shoppingChangeTracker' phase6_sync_coverage_test.dart` = 3
- [x] `grep -c 'pendingCount' create_shopping_item_use_case_test.dart` = 2

## Self-Check: PASSED
