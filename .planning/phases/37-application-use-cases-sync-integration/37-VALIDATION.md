---
phase: 37
slug: application-use-cases-sync-integration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-08
---

# Phase 37 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `37-RESEARCH.md` § Validation Architecture (HIGH confidence, all source-verified).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (dart:test + Flutter test extensions) + Mocktail |
| **Config file** | none separate — pubspec.yaml test config |
| **Quick run command** | `flutter test test/unit/application/shopping_list/ test/unit/application/family_sync/shopping_item_change_tracker_test.dart -x` |
| **Full suite command** | `flutter test test/unit/application/ test/integration/sync/` |
| **Estimated runtime** | ~25 seconds (quick) / ~90 seconds (full application + sync) |

---

## Sampling Rate

- **After every task commit:** `flutter test test/unit/application/shopping_list/ test/unit/application/family_sync/ -x`
- **After every plan wave:** `flutter test test/unit/ test/integration/sync/`
- **Before `/gsd-verify-work`:** Full suite green (`flutter test`) + `flutter analyze` 0 issues
- **Max feedback latency:** ~25 seconds

---

## Per-Task Verification Map

> Plan/Task IDs are TBD until the planner assigns them; the Requirement→Test mapping below is the binding contract the planner must honor. Each `<automated>` verify must point at one of these commands.

| Requirement | SC | Secure Behavior | Test Type | Automated Command | File Exists |
|-------------|----|-----------------|-----------|-------------------|-------------|
| SYNC-02 | SC-1 | Private create → `tracker.pendingCount == 0` (privacy gate) | unit | `flutter test test/unit/application/shopping_list/create_shopping_item_use_case_test.dart -x` | ❌ W0 |
| SYNC-02 | SC-1 | Public create → `tracker.pendingCount == 1` | unit | same file | ❌ W0 |
| ITEM-01 | SC-1 | CreateShoppingItemUseCase inserts via repo (reactive write) | unit | same file | ❌ W0 |
| SYNC-03 / D37-04 | SC-2 | UpdateShoppingItemUseCase rejects `listType` change (documented invariant error) | unit | `flutter test test/unit/application/shopping_list/update_shopping_item_use_case_test.dart -x` | ❌ W0 |
| ITEM-02, ITEM-04 | SC-2 | Update mutates name/price/qty/note; public update emits tracker op | unit | same file | ❌ W0 |
| DONE-03 | SC-2 | ClearCompletedItemsUseCase soft-deletes ALL completed for `listType` regardless of active filter | unit | `flutter test test/unit/application/shopping_list/clear_completed_items_use_case_test.dart -x` | ❌ W0 |
| MGMT-01, MGMT-02 | SC-1 | DeleteShoppingItemUseCase soft-deletes; public delete emits tombstone op | unit | `flutter test test/unit/application/shopping_list/delete_shopping_item_use_case_test.dart -x` | ❌ W0 |
| DONE-01 | SC-1 | ToggleItemCompletedUseCase flips isCompleted + stamps/clears completedAt | unit | `flutter test test/unit/application/shopping_list/toggle_item_completed_use_case_test.dart -x` | ❌ W0 |
| D37-02 | SC-4 | Deliberate un-complete syncs (NOT blocked by sticky-complete; clears completedAt + fresh updatedAt) | unit | same toggle file | ❌ W0 |
| D37-01 | SC-1 | ReorderShoppingItemsUseCase updates local sortOrder only, does NOT call tracker | unit | `flutter test test/unit/application/shopping_list/reorder_shopping_items_use_case_test.dart -x` | ❌ W0 |
| SYNC-01, SYNC-02, SYNC-05 | SC-3 | ShoppingItemChangeTracker internal `listType=='public'` guard rejects private (2nd safety net) | unit | `flutter test test/unit/application/family_sync/shopping_item_change_tracker_test.dart -x` | ❌ W0 |
| SYNC-01 | SC-3 | SyncOrchestrator._executeIncrementalPush flushes + pushes shopping ops | unit | `flutter test test/unit/application/family_sync/phase6_sync_coverage_test.dart -x` | ✏️ modify |
| SYNC-05 / SC4 | SC-4 | Tombstone not resurrected: apply create→delete→update → `isDeleted` stays true | unit | `flutter test test/unit/application/family_sync/apply_sync_operations_use_case_test.dart -x` | ✏️ modify |
| SYNC-05 / D37-02 | SC-4 | Sticky-complete: stale rename (updatedAt < completedAt, isCompleted:false) → completion preserved | unit | same apply file | ✏️ modify |
| D37-05 | SC-3 | Bad shopping op in batch does NOT abort bill/profile/avatar ops (skip-and-continue, shopping branch only) | unit | same apply file | ✏️ modify |
| SYNC-01 | SC-3 | ApplySyncOperationsUseCase constructor + ShoppingItemRepository updated atomically (provider still builds) | unit | `flutter test test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart -x` | ✏️ modify |
| SYNC-06 | SC-5 | Public item from member A appears in member B `watchByListType('public')` without manual refresh | integration | `flutter test test/integration/sync/shopping_sync_round_trip_test.dart -x` | ❌ W0 |
| SYNC-02 | SC-5 | Private item from member A NEVER appears in member B `watchByListType('public')` | integration | same round-trip file | ❌ W0 |

*Status legend: ❌ W0 = test file must be created in Wave 0 · ✏️ modify = extend existing test file*

---

## Wave 0 Requirements

Test files that MUST exist (created or modified) BEFORE implementation — the TDD/Nyquist sampling contract:

**New test files:**
- [ ] `test/unit/application/shopping_list/create_shopping_item_use_case_test.dart` — SC-1 pendingCount privacy gate (ITEM-01, SYNC-02)
- [ ] `test/unit/application/shopping_list/update_shopping_item_use_case_test.dart` — SC-2 listType rejection (ITEM-02, ITEM-04, SYNC-03/D37-04)
- [ ] `test/unit/application/shopping_list/delete_shopping_item_use_case_test.dart` — MGMT-01, MGMT-02
- [ ] `test/unit/application/shopping_list/toggle_item_completed_use_case_test.dart` — DONE-01, D37-02 deliberate un-complete
- [ ] `test/unit/application/shopping_list/reorder_shopping_items_use_case_test.dart` — D37-01 no-tracker-call
- [ ] `test/unit/application/shopping_list/clear_completed_items_use_case_test.dart` — DONE-03, SC-2 soft-delete-all
- [ ] `test/unit/application/family_sync/shopping_item_change_tracker_test.dart` — SC-3 internal privacy guard
- [ ] `test/integration/sync/shopping_sync_round_trip_test.dart` — SC-5 reactive delivery + privacy (SYNC-06)

**Existing files to modify (atomic constructor changes + new cases):**
- [ ] `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart` — add shopping_item cases (SC-3, SC-4); constructor gains ShoppingItemRepository
- [ ] `test/unit/application/family_sync/phase6_sync_coverage_test.dart` — orchestrator setUp gains shopping tracker param (SC-3)
- [ ] `test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart` — constructor verification (SC-3)
- [ ] `test/integration/sync/bill_sync_round_trip_test.dart` — setUp adds ShoppingItemRepository to ApplySyncOperationsUseCase constructor (atomic)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| (none) | — | — | All phase behaviors have automated verification. UI/visual behaviors are Phase 38/39 scope. |

*All Phase 37 behaviors have automated verification — this is a pure application/sync-layer phase with no UI surface.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (8 new files + 4 modifications)
- [ ] No watch-mode flags (`-x` excludes tagged, no `--watch`)
- [ ] Feedback latency < 25s (quick run)
- [ ] `nyquist_compliant: true` set in frontmatter (set by planner after task→test mapping is complete)

**Approval:** pending
