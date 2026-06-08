---
phase: 37-application-use-cases-sync-integration
verified: 2026-06-08T12:30:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
human_verification_result: "resolved 2026-06-08 by orchestrator — both deferred items were automated CLI checks the verifier subagent could not execute in its environment (why_human cites environment limitation, not human-only UAT). Orchestrator ran them at phase HEAD (post CR-01 fix): `flutter test test/unit/application/shopping_list/ test/unit/application/family_sync/ test/integration/sync/` → 154/154 All tests passed; `flutter analyze lib/` → 2 issues, both pre-existing onReorder deprecation infos in category_selection_screen.dart (carried tech debt, out of Phase 37 scope). Full suite also ran 2386/2386 green earlier in the session."
deferred:
  - truth: "MGMT-03: Swipe-to-delete is disabled while batch-select mode is active"
    addressed_in: "Phase 38"
    evidence: "Phase 38 SC-4: 'swipe-to-delete uses Dismissible and is disabled while batch-select mode is active (MGMT-03)'. Also in REQUIREMENTS.md traceability: MGMT-03 | Phase 38 | Complete."
human_verification:
  - test: "Run flutter test to confirm full suite passes"
    expected: "All tests pass (context note says 2386/2386 green; verify test/unit/application/shopping_list/ and test/integration/sync/shopping_sync_round_trip_test.dart)"
    why_human: "Cannot execute flutter test in this environment; test results are claimed in SUMMARY but not independently observable here"
  - test: "Verify flutter analyze reports 0 issues on modified files"
    expected: "flutter analyze lib/ exits 0 (context note says 0 issues; only pre-existing onReorder deprecation infos in unrelated file)"
    why_human: "Cannot run flutter analyze in this environment"
---

# Phase 37: Application Use Cases + Sync Integration Verification Report

**Phase Goal:** Every shopping list mutation is mediated by a use case that enforces the private-item privacy contract, and public items sync bidirectionally through the existing family_sync pipeline with reactive delivery and tombstone safety
**Verified:** 2026-06-08T12:30:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (Mapped to ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | Six use cases exist; private create → pendingCount==0; public create → pendingCount==1 | VERIFIED | All 6 files confirmed in `lib/application/shopping_list/`; `create_shopping_item_use_case_test.dart` lines 41-66 assert both pendingCount values against real ShoppingItemChangeTracker (not mocked) |
| SC-2 | UpdateShoppingItemUseCase rejects listType change with 'Invariant'; ClearCompletedItemsUseCase soft-deletes all completed per listType | VERIFIED | `update_shopping_item_use_case.dart:77-82` has `if (params.listType != null && params.listType != existing.listType) return Result.error('Invariant violation...')`. Test at `update_shopping_item_use_case_test.dart:59-70` asserts `result.error contains 'Invariant'`. `clear_completed_items_use_case.dart:28-44` calls `_repo.softDeleteAllCompleted(listType)` |
| SC-3 | ShoppingItemChangeTracker with public guard; SyncOrchestrator push block; ApplySyncOperationsUseCase 'shopping_item' branch; atomic constructor update | VERIFIED | Tracker at `shopping_item_change_tracker.dart:35,45` checks `data?['listType'] != 'public'`. Orchestrator flush at `sync_orchestrator.dart:167-174`. Switch case at `apply_sync_operations_use_case.dart:50-61`. All 4 construction sites confirmed: `repository_providers.dart:134`, `state_sync.dart:49`, `bill_sync_round_trip_test.dart`, `apply_sync_operations_use_case_test.dart:63`, `phase6_sync_coverage_test.dart` |
| SC-4 | Tombstone not resurrected by subsequent remote update (create→delete→update path) | VERIFIED | `apply_sync_operations_use_case.dart:225-227`: `if (existing.isDeleted) return;` placed FIRST before field merging. Integration test at `shopping_sync_round_trip_test.dart:153-211` exercises create→delete→update and asserts `item!.isDeleted == true`. CR-01 fix (commit 4eb5d763) adds `sortOrder: existing.sortOrder` to preserve local ordering |
| SC-5 | Reactive integration test: public item appears in watchByListType without ref.invalidate; private item never appears | VERIFIED | `shopping_sync_round_trip_test.dart:77-150` subscribes to `.skip(1).first.timeout(5s)` BEFORE applying op, then applies, then awaits — no ref.invalidate. Private item test asserts `items.any((i) => i.id == 'private-item-1') == false`. Drift `watchByListType` uses `readsFrom: {_db.shoppingItems}` confirmed at `shopping_item_dao.dart:83` |

**Score:** 5/5 truths verified

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | MGMT-03: Swipe-to-delete disabled during batch-select mode (gesture gate UI) | Phase 38 | Phase 38 SC-4: "swipe-to-delete uses Dismissible and is disabled while batch-select mode is active (MGMT-03)"; REQUIREMENTS.md traceability table maps `MGMT-03 (gesture gate UI)` to Phase 38 |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/application/shopping_list/create_shopping_item_use_case.dart` | Item creation with privacy gate | VERIFIED | 92 lines; privacy gate at line 81; ITEM-01 validation at line 56 |
| `lib/application/shopping_list/update_shopping_item_use_case.dart` | D37-04 listType immutability guard | VERIFIED | 119 lines; D37-04 guard at line 77-82; 'Invariant' in error message |
| `lib/application/shopping_list/delete_shopping_item_use_case.dart` | Soft-delete with privacy gate | VERIFIED | 49 lines; softDelete at line 36; privacy gate at line 40 |
| `lib/application/shopping_list/toggle_item_completed_use_case.dart` | completedAt stamp/clear (D-03, D37-02) | VERIFIED | 72 lines; completedAt: null on un-complete at line 45; stamp on complete at line 51 |
| `lib/application/shopping_list/reorder_shopping_items_use_case.dart` | Local-only, no tracker (D37-01) | VERIFIED | 25 lines; no ShoppingItemChangeTracker or SyncEngine import; D37-01 comment at line 21 |
| `lib/application/shopping_list/clear_completed_items_use_case.dart` | Bulk soft-delete with per-item tracker ops | VERIFIED | 52 lines; pre-read items before delete at line 31; per-item trackDelete at line 40 |
| `lib/application/family_sync/shopping_item_change_tracker.dart` | In-memory tracker with D37-06 privacy guard | VERIFIED | 77 lines; listType!='public' guard in trackCreate (line 35) and trackUpdate (line 45); `kShoppingItemEntityType` defined once at line 7 |
| `lib/features/shopping_list/domain/models/shopping_item_sync_mapper.dart` | Wire op builders; sortOrder excluded | VERIFIED | 121 lines; sortOrder absent from toSyncMap with D37-01 comment at line 18+38; kShoppingItemEntityType imported (not redefined) |
| `lib/application/family_sync/apply_sync_operations_use_case.dart` | shopping_item branch with tombstone+sticky-complete | VERIFIED | `case 'shopping_item':` at line 50; D37-05 try/catch at lines 52-61; `_applyShoppingItemOp` at line 175; `_handleShoppingUpdate` at line 213; tombstone guard at line 227; CR-01 fix: `sortOrder: existing.sortOrder` at line 241 |
| `lib/application/family_sync/sync_orchestrator.dart` | Shopping flush block in _executeIncrementalPush | VERIFIED | `_shoppingChangeTracker.flush()` at line 167; push block at lines 168-174 |
| `lib/features/family_sync/presentation/providers/state_sync.dart` | shoppingItemChangeTrackerProvider (keepAlive) + SyncOrchestrator wired | VERIFIED | `shoppingItemChangeTrackerProvider` at line 27 with `@Riverpod(keepAlive: true)`; `shoppingChangeTracker: ref.watch(shoppingItemChangeTrackerProvider)` at line 49 |
| `lib/features/family_sync/presentation/providers/repository_providers.dart` | applySyncOperationsUseCaseProvider with shoppingItemRepository | VERIFIED | `shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider)` at line 134 |
| `test/integration/sync/shopping_sync_round_trip_test.dart` | SC-5 reactive delivery + privacy + tombstone + sticky-complete | VERIFIED | 276 lines; 4 tests; reactive via Drift .skip(1).first.timeout(5s); no ref.invalidate |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `create_shopping_item_use_case.dart` | `shopping_item_change_tracker.dart` | `listType=='public'` gate → `_changeTracker?.trackCreate(...)` | WIRED | Lines 81-85; gate is FIRST, then tracker called |
| `update_shopping_item_use_case.dart` | `shopping_item_change_tracker.dart` | `existing.listType=='public'` → `_changeTracker?.trackUpdate(...)` | WIRED | Lines 108-111; gate uses existing.listType (immutable) |
| `delete_shopping_item_use_case.dart` | `shopping_item_change_tracker.dart` | `existing.listType=='public'` → `_changeTracker?.trackDelete(itemId:)` | WIRED | Lines 40-42 |
| `toggle_item_completed_use_case.dart` | `shopping_item_change_tracker.dart` | `existing.listType=='public'` → `_changeTracker?.trackUpdate(...)` | WIRED | Lines 61-64 |
| `clear_completed_items_use_case.dart` | `shopping_item_change_tracker.dart` | `listType=='public'` → per-item `_changeTracker?.trackDelete(...)` | WIRED | Lines 29-41 |
| `sync_orchestrator.dart` | `shopping_item_change_tracker.dart` | `_shoppingChangeTracker.flush()` → `_pushSync.execute(...)` | WIRED | Lines 167-174 |
| `apply_sync_operations_use_case.dart` | `shopping_item_repository.dart` | `_shoppingItemRepository.upsert(item)` in _handleShoppingCreate/_handleShoppingUpdate | WIRED | Lines 210, 221, 254 |
| `state_sync.dart` | `shopping_item_change_tracker.dart` | `shoppingItemChangeTrackerProvider` → `SyncOrchestrator(shoppingChangeTracker: ...)` | WIRED | Lines 27-29, 49 |
| `repository_providers.dart` | `shopping_item_repository.dart` | `applySyncOperationsUseCaseProvider(shoppingItemRepository: ref.watch(...))` | WIRED | Line 134 |
| `shopping_sync_round_trip_test.dart` | `apply_sync_operations_use_case.dart` | `applyOps.execute([op]) → upsert → watchByListType fires` | WIRED | Test uses real ShoppingItemRepositoryImpl (not mocked) with real Drift DB |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `shopping_sync_round_trip_test.dart` | `items` from `watchByListType('public').first` | `ApplySyncOperationsUseCase.execute([op])` → `ShoppingItemRepositoryImpl.upsert` → `ShoppingItemDao.upsert` → Drift reactive stream | Yes — real in-memory Drift DB (`AppDatabase.forTesting()`), real DAO upsert triggers `readsFrom:` re-emission | FLOWING |
| `shopping_item_change_tracker.dart` | `_pendingOps` | `trackCreate`/`trackUpdate`/`trackDelete` calls from use cases | Yes — in-memory accumulation; flushed by `SyncOrchestrator._executeIncrementalPush` | FLOWING |

### Behavioral Spot-Checks

Step 7b: SKIPPED — flutter test and flutter analyze cannot be run in this verification environment. These are routed to human verification.

### Probe Execution

No probe scripts declared in PLAN.md files. No `scripts/*/tests/probe-*.sh` found for this phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| ITEM-01 | 37-03 | User can add item; name required | SATISFIED | `create_shopping_item_use_case.dart:56-58`; test asserts `Result.error` on empty name |
| ITEM-02 | 37-03, 37-04 | Optional fields (ledger, category, tags, note, quantity, estimatedPrice) | SATISFIED | `CreateShoppingItemParams` and `UpdateShoppingItemParams` accept all optional fields; `UpdateShoppingItemUseCase` coalesces them with copyWith. Form UI is Phase 38 scope |
| ITEM-04 | 37-04 | User can edit any existing item | SATISFIED | `UpdateShoppingItemUseCase` fetches existing, applies coalesce update, persists; test `name update succeeds` at line 73 |
| DONE-01 | 37-03 | Toggle completed state | SATISFIED | `ToggleItemCompletedUseCase` stamps `completedAt`/`isCompleted`; D37-02 clears `completedAt` on un-complete; UI animation is Phase 38 scope |
| DONE-03 | 37-04 | Clear all completed | SATISFIED | `ClearCompletedItemsUseCase.softDeleteAllCompleted(listType)`; confirmation dialog is Phase 38 scope |
| MGMT-01 | 37-03 | Swipe-to-delete (use-case logic) | SATISFIED | `DeleteShoppingItemUseCase` calls `softDelete`; UI swipe widget is Phase 38 scope |
| MGMT-02 | 37-03 | Not found returns error | SATISFIED | `DeleteShoppingItemUseCase:31-33`; test at delete test line 79 |
| MGMT-03 | 37-04 | Swipe disabled during batch-select (use-case layer) | DEFERRED | Phase 38 SC-4 covers gesture gate UI. Phase 37 acknowledges this explicitly in `clear_completed_items_use_case.dart:13`. No Phase 37 use-case behavior to implement for this — it is entirely a presentation-layer concern |
| SYNC-01 | 37-02, 37-03, 37-04, 37-05 | Public items sync via family_sync pipeline | SATISFIED | Tracker enqueues public ops; SyncOrchestrator flushes them; integration test verifies public item appears in stream |
| SYNC-02 | 37-02, 37-03 | Private items NEVER enter sync pipeline | SATISFIED | Primary gate in all use cases (`if (item.listType == 'public')`); secondary gate in tracker (`data?['listType'] != 'public'`); integration test verifies private item absent from public stream |
| SYNC-03 | 37-04 | listType immutable after creation | SATISFIED | `UpdateShoppingItemUseCase` returns `Result.error` with 'Invariant' on listType change attempt; test asserts this |
| SYNC-05 | 37-05 | Sticky-complete + tombstone safety | SATISFIED | `_handleShoppingUpdate`: tombstone check at line 227; sticky-complete merge at lines 244-250; integration tests for both paths |
| SYNC-06 | 37-05, 37-06 | Reactive delivery via Drift .watch() readsFrom | SATISFIED | `ShoppingItemDao.watchByListType` uses `readsFrom: {_db.shoppingItems}`; integration test uses `.skip(1).first` without ref.invalidate |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `sync_orchestrator.dart` | 191 | `pushedCount: txnOps.length` — omits shoppingOps.length and profileOps.length (WR-02 from review) | WARNING | Diagnostic/telemetry only; does not affect correctness or sync behavior; tracked as advisory in 37-REVIEW.md |
| `create_shopping_item_use_case.dart` | 15 | `final dynamic ledgerType;` — should be `LedgerType?` (IN-01 from review) | INFO | Type safety advisory; no runtime failure since enum `.name` is guarded by `?.`; tracked in 37-REVIEW.md |
| `shopping_item_sync_mapper.dart` | 77 | `List<String>.from(jsonDecode(rawTags) as List)` — no try/catch on jsonDecode (WR-05 from review) | WARNING | Malformed tag payload throws FormatException; caught by D37-05 try/catch in execute() so per-op skip works; tracked in 37-REVIEW.md |

No `TBD`, `FIXME`, or `XXX` debt markers found in any Phase 37 production files.

**Advisory note (CR-02 from review):** The `_handleShoppingUpdate` unknown-ID path (line 218-222 in apply_sync_operations_use_case.dart) creates a live row when an update arrives for an ID not yet in the database. The code review flagged this as a BLOCKER for a tombstone resurrection edge case (out-of-order: update arrives before delete). Per context notes, this was accepted as "consistent with the existing transaction `_handleUpdate` pattern" (which has identical behavior at lines 157-159). The Phase 37 ROADMAP SC-4 specifies "after the deletion" — the specific tested path (create→delete→update) correctly exercises the `existing.isDeleted` guard and passes. The CR-02 edge case (delete op not yet received) is an out-of-order delivery scenario that ROADMAP SC-4 does not require testing. This is consistent with CR-02 acceptance.

### Human Verification Required

**These are the only items requiring human action before the phase can be considered complete:**

#### 1. Full Test Suite Pass

**Test:** Run `flutter test test/unit/application/shopping_list/ test/unit/application/family_sync/shopping_item_change_tracker_test.dart test/integration/sync/shopping_sync_round_trip_test.dart -x`
**Expected:** All tests pass GREEN; no compilation errors; the following specific assertions confirmed passing: private create → pendingCount==0; public create → pendingCount==1; listType change → contains 'Invariant'; completedAt==null on un-complete; public item in watchByListType stream; private item absent from watchByListType stream; tombstone not resurrected; sticky-complete preserved
**Why human:** Cannot execute `flutter test` in this verification environment; test results claimed in SUMMARY (2386/2386) but not independently run here

#### 2. Flutter Analyze

**Test:** Run `flutter analyze lib/application/shopping_list/ lib/application/family_sync/shopping_item_change_tracker.dart lib/application/family_sync/apply_sync_operations_use_case.dart lib/application/family_sync/sync_orchestrator.dart lib/features/family_sync/presentation/providers/state_sync.dart lib/features/family_sync/presentation/providers/repository_providers.dart lib/features/shopping_list/domain/models/shopping_item_sync_mapper.dart`
**Expected:** 0 issues (context note confirms this; only pre-existing onReorder deprecation infos in unrelated `category_selection_screen.dart` exist)
**Why human:** Cannot run flutter analyze in this verification environment

---

## Gaps Summary

No blocking gaps. All 5 ROADMAP success criteria are verified in the codebase. MGMT-03 is a known deferred item (Phase 38). Advisory findings from the code review (WR-01 through WR-05, IN-01 through IN-03, CR-02) are tracked in 37-REVIEW.md and do not block the phase goal.

The phase goal — "Every shopping list mutation is mediated by a use case that enforces the private-item privacy contract, and public items sync bidirectionally through the existing family_sync pipeline with reactive delivery and tombstone safety" — is satisfied in the production code. Two human-verification items (test suite pass + analyzer) remain as the only outstanding actions.

---

_Verified: 2026-06-08T12:30:00Z_
_Verifier: Claude (gsd-verifier)_
