---
phase: 37-application-use-cases-sync-integration
plan: "06"
subsystem: test/integration/sync
tags: [integration, wave-4, reactive-delivery, sync-round-trip, phase-gate]
dependency_graph:
  requires:
    - "37-05 (ApplySyncOperationsUseCase shopping_item branch + SyncOrchestrator wiring)"
    - "37-04 (ShoppingItemRepository.upsert/softDelete/findById/watchByListType APIs)"
    - "37-02 (ShoppingItemSyncMapper.fromSyncMap)"
  provides:
    - shopping_sync_round_trip_test.dart (4 tests, SC-5 end-to-end proof, SYNC-06)
    - Phase 37 gate: all 13 requirements have passing test evidence
  affects:
    - test/integration/sync/shopping_sync_round_trip_test.dart (implemented from scaffold)
tech_stack:
  added: []
  patterns:
    - skip(1) reactive stream pattern: skips Drift initial-state emission, captures post-write re-emission without ref.invalidate (v1.4 GAP-2 lesson)
    - .timeout(5s) guard on reactive future to prevent indefinite hang
    - kShoppingItemEntityType constant throughout test (not inline strings)
    - ISO 8601 DateTime encoding for T0/T1 sticky-complete ordering
key_files:
  created: []
  modified:
    - test/integration/sync/shopping_sync_round_trip_test.dart
decisions:
  - "skip(1) pattern chosen over .where((items) => items.isNotEmpty).first to correctly model the GAP-2 lesson: we skip the initial empty snapshot emission and wait for the post-write re-emission that Drift's readsFrom delivers"
  - "sticky-complete test uses explicit DateTime(2026, 6, 8, 10, 0) / DateTime(2026, 6, 8, 9, 0) for T1/T0 to guarantee deterministic ordering without clock skew"
metrics:
  duration_minutes: 5
  completed_date: "2026-06-08"
  tasks_completed: 2
  tasks_total: 2
  files_created: 0
  files_modified: 1
---

# Phase 37 Plan 06: Shopping Sync Round Trip Test (Wave 4 Final) Summary

Final wave of Phase 37 — shopping_sync_round_trip_test.dart implemented to fully-passing GREEN state. SC-5 proof complete: public item from simulated remote member appears in `watchByListType('public')` stream WITHOUT `ref.invalidate` (reactive via Drift `.watch()` readsFrom). Phase gate confirms all 13 requirements covered (531/531 tests pass, 0 analyzer errors in project source).

## What Was Built

### Task 1: shopping_sync_round_trip_test.dart (4 tests, GREEN)

`test/integration/sync/shopping_sync_round_trip_test.dart`

The scaffold from Wave 0 (37-01) had 3 tests; this plan completed all 4 required tests and fixed the reactive delivery test that was failing with `Expected: true, Actual: <false>`.

**Root cause of original failure:** Drift's `.watch()` stream emits an initial snapshot immediately when subscribed. The scaffold used `.first` which captured this initial empty emission before the write, resolving to `[]`. Fixed by using `.skip(1).first` to skip the initial state and wait for the post-write re-emission.

**Test 1: Public item reactive delivery (SYNC-06, SC-5)**
- Subscribe with `.skip(1).first.timeout(5s)` BEFORE applying sync op
- Apply create op for `item-1` (listType='public') via `applyOps.execute`
- `await streamFuture` resolves with `[item-1]` — Drift's `readsFrom: {_db.shoppingItems}` fires after upsert
- Assertion: `items.any((i) => i.id == 'item-1')` is TRUE
- Proof that NO `ref.invalidate` is needed — reactive delivery via Drift `.watch()` alone

**Test 2: Private item isolation (SYNC-02, SC-5)**
- Apply create op for `private-item-1` (listType='private') — it IS written to DB
- Call `watchByListType('public').first` — SQL `WHERE list_type = 'public'` excludes it
- Assertion: `items.any((i) => i.id == 'private-item-1')` is FALSE
- The DAO-level SQL filter is the production gate; private items from remote members never appear in the public stream

**Test 3: Tombstone not resurrected (SC-4)**
- Apply create → delete → stale update for `item-tombstone`
- `findById('item-tombstone')` returns the row with `isDeleted: true`
- The `_handleShoppingUpdate` first-check `if (existing.isDeleted) return` prevents resurrection

**Test 4: Sticky-complete merge (D-03, SC-4)**
- T1 = `DateTime(2026, 6, 8, 10, 0)` (completion time, newer)
- T0 = `DateTime(2026, 6, 8, 9, 0)` (stale update time, older)
- Apply create with `isCompleted=true, completedAt=T1`
- Apply stale update with `updatedAt=T0 (< T1)`, `isCompleted=false`
- `findById('item-sticky').isCompleted` is TRUE — D37-02 sticky-complete guard preserved completion
- Guard: `existing.completedAt.isAfter(incomingUpdatedAt)` → `T1.isAfter(T0)` = true → preserve

### Task 2: Phase Gate — All 13 Requirements Covered

| Requirement | SC | Test Evidence |
|-------------|----|----|
| ITEM-01 | SC-1 | `create_shopping_item_use_case_test.dart` — insert called, empty name rejected |
| ITEM-02 | SC-2 | `update_shopping_item_use_case_test.dart` — name/price/qty mutated |
| ITEM-04 | SC-2 | `update_shopping_item_use_case_test.dart` — listType change rejected (D37-04) |
| DONE-01 | SC-1 | `toggle_item_completed_use_case_test.dart` — flip + stamp/clear completedAt |
| DONE-03 | SC-2 | `clear_completed_items_use_case_test.dart` — soft-deletes ALL completed |
| MGMT-01 | SC-1 | `delete_shopping_item_use_case_test.dart` — soft-delete + tombstone tracker op |
| MGMT-02 | SC-1 | `delete_shopping_item_use_case_test.dart` — private delete no tracker op |
| MGMT-03 | SC-1 | `reorder_shopping_items_use_case_test.dart` — no tracker call (D37-01) |
| SYNC-01 | SC-3 | `phase6_sync_coverage_test.dart` — orchestrator flushes + pushes shopping ops |
| SYNC-02 | SC-3/5 | `create_shopping_item_use_case_test.dart` (SC-3) + `shopping_sync_round_trip_test.dart` (SC-5) |
| SYNC-03 | SC-2 | `update_shopping_item_use_case_test.dart` — listType immutable (D6/D37-04) |
| SYNC-05 | SC-4 | `apply_sync_operations_use_case_test.dart` — tombstone + sticky-complete (unit) |
| SYNC-06 | SC-5 | `shopping_sync_round_trip_test.dart` — reactive delivery without ref.invalidate |

Full suite: **531/531 tests pass**. `flutter analyze lib/` — **0 errors** (2 pre-existing INFO deprecation warnings in `category_selection_screen.dart`, out of scope).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reactive stream test used `.first` instead of `.skip(1).first`**
- **Found during:** Task 1 test run — first test failed with `Expected: true, Actual: <false>`
- **Issue:** The scaffold's `.first` captured Drift's initial empty-state emission before the write happened. The plan's comment "`.first` future completes on the next emission after subscription" was incorrect for Drift's behavior (initial snapshot always emits immediately).
- **Fix:** Changed to `.skip(1).first.timeout(const Duration(seconds: 5))` to skip the initial empty snapshot and wait for the post-write re-emission
- **Files modified:** `test/integration/sync/shopping_sync_round_trip_test.dart`
- **Commit:** 1b991f0d

**2. [Rule 2 - Missing critical functionality] 4th test (sticky-complete) was absent from scaffold**
- **Found during:** Task 1 implementation — the plan requires 4 tests; scaffold had only 3
- **Issue:** The sticky-complete merge test (D-03, SC-4) was listed in the plan's `<behavior>` section but not present in the Wave-0 scaffold
- **Fix:** Implemented the 4th test with deterministic T0/T1 ordering (explicit DateTime values)
- **Files modified:** `test/integration/sync/shopping_sync_round_trip_test.dart`
- **Commit:** 1b991f0d

## Known Stubs

None. The test file is fully implemented with no placeholders.

## Threat Flags

None. This plan creates integration tests only — no new network endpoints, auth paths, or trust boundary crossings.

- T-37-01 (private item leaks into public stream): **verified mitigated** — Test 2 asserts private item never appears in `watchByListType('public')` using real Drift DB + real SQL filter
- T-37-03 (tombstone resurrection): **verified mitigated** — Test 3 asserts `isDeleted=true` after delete→update sequence using real repo
- T-37-04 (stale rename un-checks completed): **verified mitigated** — Test 4 asserts `isCompleted=true` after stale update with T0 < T1
- T-37-SC (package installs): **accepted** — zero new packages

## Self-Check

### Files modified:
- [x] `test/integration/sync/shopping_sync_round_trip_test.dart` — FOUND

### Commits:
- [x] 1b991f0d — test(37-06): implement shopping_sync_round_trip_test.dart GREEN (SC-5, SYNC-06)

### Verification criteria:
- [x] `flutter test test/integration/sync/shopping_sync_round_trip_test.dart` — 4/4 GREEN
- [x] `grep -c 'watchByListType' shopping_sync_round_trip_test.dart` = 5 (≥2 required)
- [x] `grep -c 'isDeleted' shopping_sync_round_trip_test.dart` = 1 (≥1 required)
- [x] `grep -c 'isCompleted' shopping_sync_round_trip_test.dart` = 10 (≥1 required)
- [x] `flutter test test/unit/application/ test/integration/sync/` — 531/531 GREEN
- [x] `flutter analyze lib/` — 0 errors (2 pre-existing INFO out of scope)
- [x] All 13 Phase 37 requirement IDs (ITEM-01/02/04, DONE-01/03, MGMT-01/02/03, SYNC-01/02/03/05/06) have passing tests

## Self-Check: PASSED
