---
phase: quick-260612-daz
plan: 01
subsystem: family-sync
tags: [shopping-sync, full-sync, privacy-gate, tdd, security]
requirements: [SYNC-01, SYNC-02, SYNC-03]
dependency-graph:
  requires:
    - ShoppingItemSyncMapper (lib/features/shopping_list/domain/models/shopping_item_sync_mapper.dart)
    - ShoppingItemRepository.watchByListType('public') (DAO filters is_deleted = 0)
    - PushSyncUseCase (chunked push, PushSyncSuccess/PushSyncQueued)
  provides:
    - FetchAllShoppingOpsCallback + public-only filter in FullSyncUseCase.execute()
    - Receiver-side listType gate (_isPublicShoppingOp) in ApplySyncOperationsUseCase
    - listType pin (existing.listType) in _handleShoppingUpdate merge
  affects:
    - fullSyncUseCase provider (repository_providers.dart, regenerated .g.dart)
tech-stack:
  added: []
  patterns:
    - "D37-05 per-op skip at receiver boundary (untrusted wire input)"
    - "D37-04 invariant enforced receiver-side via copyWith pin"
    - "D37-06 defense-in-depth: DAO filter + use-case re-filter"
key-files:
  created: []
  modified:
    - lib/application/family_sync/apply_sync_operations_use_case.dart
    - lib/application/family_sync/full_sync_use_case.dart
    - lib/application/family_sync/shopping_item_change_tracker.dart
    - lib/features/family_sync/presentation/providers/repository_providers.dart
    - lib/features/family_sync/presentation/providers/repository_providers.g.dart
    - test/unit/application/family_sync/apply_sync_operations_use_case_test.dart
    - test/unit/application/family_sync/full_sync_use_case_test.dart
    - test/integration/sync/shopping_sync_round_trip_test.dart
decisions:
  - "Receiver gate skips create/update only; delete arm stays ungated (delete ops carry no listType, tombstones are id-addressed)"
  - "Full sync emits create ops only for shopping items — receiver _handleShoppingCreate is idempotent, correct for reconcile"
  - "Shopping ops concatenated with transactions BEFORE empty-check/chunk loop so chunking, vectorClock and syncType 'full' apply uniformly"
metrics:
  duration: ~12 min
  completed: 2026-06-12
  tasks: 3/3
  tests: 138 passing (family_sync unit + integration/sync suites)
---

# Quick Task 260612-daz: Fix Shopping Sync W1 (full-sync reconcile) + W2 (receiver privacy gate) Summary

**One-liner:** Full sync now pushes public shopping items as idempotent create ops, and the receiver drops non-public shopping ops and pins listType on update — closing the v1.6 audit W1 data-loss window and W2 receiver-side privacy hole.

## What Was Done

### Task 1 — W2: receiver-side listType gate + immutability pin (TDD)
- RED commit `ed5ba200`: 4 new tests (private create dropped + batch continues; private update dropped; listType flip rejected; public regression guard). Tests 1-3 failed as expected.
- GREEN commit `215ac544`:
  - `_isPublicShoppingOp` helper gates the create/insert and update arms of `_applyShoppingItemOp` — inbound ops whose `data['listType'] != 'public'` are silently skipped per-op (D37-05 pattern) with a kDebugMode debugPrint. The delete arm is intentionally ungated (delete ops carry no listType).
  - `_handleShoppingUpdate` merge now pins `listType: existing.listType` (D37-04 invariant, receiver side) — the wire can never flip an item public↔private. SC-4 tombstone guard, CR-01 LWW drop, WR-01 unknown-ID return, and D37-01 sortOrder preservation all remain ordered before the merge, untouched.

### Task 2 — W1: FullSyncUseCase shopping support + provider wiring + tracker comment (TDD)
- RED commit `24674b19`: rewrote full_sync_use_case_test.dart with the new required `fetchAllShoppingOps` constructor param (compile break at RED, as planned) and 6 tests covering combined push, defensive private filter, shopping-only push, chunking/queued regression, and empty-both early exit.
- GREEN commit `a8f26bad`:
  - `full_sync_use_case.dart`: added `FetchAllShoppingOpsCallback` typedef + required constructor param; defensive `data.listType == 'public'` filter; `[...transactions, ...publicShoppingOps]` concatenated BEFORE the empty-check and chunk loop; debugPrints report both counts plus dropped non-public count.
  - `repository_providers.dart`: `fullSyncUseCase` provider wires `fetchAllShoppingOps` via `shoppingItemRepositoryProvider` → `watchByListType('public').first` → `ShoppingItemSyncMapper.toCreateOperation`. `.g.dart` regenerated via build_runner (riverpod source hash).
  - `shopping_item_change_tracker.dart`: class doc corrected — loss window is a hard kill inside the 10s debounce (onAppPaused flushes via incrementalPush); reconcile happens at the next FULL SYNC (pairing-time initialSync), NOT "on next launch". `grep -c "next launch"` returns 0.

### Task 3 — Integration round trip + quality gates
- Commit `29f2d6f0`:
  - W1 round trip: seeds one public + one private item, builds ops exactly as the provider does, asserts payload contains only the public id, applies against a fresh second `AppDatabase.forTesting` receiver — public exists post-apply, private does not.
  - W2 end-to-end: inbound private create never persisted; private update with newer updatedAt against a persisted public item leaves it unchanged (gate fires before LWW would accept it).
  - Updated a stale comment in the pre-existing private-stream test (private items are now dropped before any DB write, with the DAO WHERE clause as second layer).
  - `dart format` applied ONLY to the 7 plan-touched Dart files; `flutter analyze` → 0 issues; `flutter test test/unit/application/family_sync/ test/integration/sync/` → 138/138 green.

## Commits

| Hash | Type | Description |
|------|------|-------------|
| ed5ba200 | test | RED: receiver gate + pin failing tests |
| 215ac544 | fix | GREEN: receiver-side listType gate + pin (W2) |
| 24674b19 | test | RED: full-sync shopping ops failing tests |
| a8f26bad | feat | GREEN: full sync pushes public shopping items (W1) + provider wiring + tracker doc |
| 29f2d6f0 | test | Integration round trip + format on touched files |

## Deviations from Plan

None - plan executed exactly as written. (One micro-adjustment within scope: updated a now-stale comment in the pre-existing `private item NEVER appears` integration test to reflect the new two-layer gate — the file is in the plan's files_modified list.)

## Threat Register Outcomes

| Threat ID | Disposition | Result |
|-----------|-------------|--------|
| T-q260612-01 | mitigate | DONE — `_isPublicShoppingOp` drops non-public create/update ops |
| T-q260612-02 | mitigate | DONE — `listType: existing.listType` pin in update merge |
| T-q260612-03 | mitigate | DONE — provider fetches public-only + use-case re-filter; tests assert private exclusion |
| T-q260612-04 | accept | unchanged (out of scope per plan) |

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes; all changes harden existing trust boundaries.

## TDD Gate Compliance

- Task 1: RED `ed5ba200` (test) → GREEN `215ac544` (fix). Compliant.
- Task 2: RED `24674b19` (test) → GREEN `a8f26bad` (feat). Compliant.
- Task 3: integration tests written against already-green implementation (verification task per plan).

## Verification Results

- `flutter analyze` → No issues found
- `flutter test test/unit/application/family_sync/ test/integration/sync/` → 138/138 passed
- `git diff --stat <base>..HEAD` → exactly the 8 frontmatter files
- `grep fetchAllShoppingOps full_sync_use_case.dart` → present (lines 22, 25, 29)
- `grep "listType: existing.listType" apply_sync_operations_use_case.dart` → present (line 285)
- `grep -c "next launch" shopping_item_change_tracker.dart` → 0

## Self-Check: PASSED
