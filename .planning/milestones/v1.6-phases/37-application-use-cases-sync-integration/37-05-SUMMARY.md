---
phase: 37-application-use-cases-sync-integration
plan: "05"
subsystem: application/family-sync + features/family-sync/providers + features/shopping-list/providers
tags: [tdd, wave-3, integration, atomic, tombstone, sticky-complete, sync-pipeline]
dependency_graph:
  requires:
    - "37-03 (ShoppingItemChangeTracker + ShoppingItemSyncMapper)"
    - "37-04 (use-case APIs — upsert, softDelete, findById signatures)"
  provides:
    - ApplySyncOperationsUseCase.shopping_item branch (tombstone + sticky-complete guards, SC-4)
    - SyncOrchestrator._executeIncrementalPush shopping flush+push block (SC-3, SYNC-01)
    - shoppingItemChangeTrackerProvider (keepAlive: true) in state_sync.dart
    - applySyncOperationsUseCase wired with shoppingItemRepository
    - shoppingItemRepositoryProvider (NEW file — lib/features/shopping_list/presentation/providers/)
  affects:
    - lib/application/family_sync/apply_sync_operations_use_case.dart (modified)
    - lib/application/family_sync/sync_orchestrator.dart (modified)
    - lib/features/family_sync/presentation/providers/state_sync.dart (modified)
    - lib/features/family_sync/presentation/providers/state_sync.g.dart (regenerated)
    - lib/features/family_sync/presentation/providers/repository_providers.dart (modified)
    - lib/features/shopping_list/presentation/providers/repository_providers.dart (created)
    - lib/features/shopping_list/presentation/providers/repository_providers.g.dart (generated)
    - test/unit/application/family_sync/apply_sync_operations_use_case_test.dart (bug fix)
tech_stack:
  added: []
  patterns:
    - D37-05 fault isolation: only shopping_item branch has try/catch in execute() switch
    - SC-4 tombstone-first: isDeleted check before any field merge in _handleShoppingUpdate
    - SC-4/D-03 sticky-complete: completedAt.isAfter(incomingUpdatedAt) guard preserves completion
    - ShoppingItemChangeTracker flush mirrors TransactionChangeTracker flush pattern
    - Riverpod keepAlive: ShoppingItemChangeTracker provider mirrors TransactionChangeTracker provider
key_files:
  created:
    - lib/features/shopping_list/presentation/providers/repository_providers.dart
    - lib/features/shopping_list/presentation/providers/repository_providers.g.dart
  modified:
    - lib/application/family_sync/apply_sync_operations_use_case.dart
    - lib/application/family_sync/sync_orchestrator.dart
    - lib/features/family_sync/presentation/providers/state_sync.dart
    - lib/features/family_sync/presentation/providers/state_sync.g.dart
    - lib/features/family_sync/presentation/providers/repository_providers.dart
    - test/unit/application/family_sync/apply_sync_operations_use_case_test.dart
decisions:
  - "D37-05 try/catch wraps ONLY the shopping_item case in execute(); bill/profile/avatar cases are intentionally unchanged — fault isolation must not change existing entity semantics"
  - "tombstone check (if existing.isDeleted return) placed FIRST in _handleShoppingUpdate, before incomingUpdatedAt parse and before sticky-complete merge"
  - "shoppingItemRepositoryProvider created in lib/features/shopping_list/presentation/providers/ (new directory) — mirrors accounting pattern; uses app_accounting.appFieldEncryptionServiceProvider"
  - "_FakeShoppingItem + setUpAll registerFallbackValue added to apply_sync_operations_use_case_test.dart — mocktail requires registered fallback for any() matcher on custom types"
metrics:
  duration_minutes: 10
  completed_date: "2026-06-08"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 6
---

# Phase 37 Plan 05: Sync Integration Layer (Wave 3 Atomic) Summary

Wave-3 integration plan executed atomically — ApplySyncOperationsUseCase gains the shopping_item branch (tombstone + sticky-complete guards), SyncOrchestrator gains the shopping flush+push block, and all 6 construction sites across 4 production files and 4 test files updated together. Build is fully GREEN after this plan (compilation error from Wave 0 RED tests resolved).

## What Was Built

### Task 1: ApplySyncOperationsUseCase — shopping_item branch (GREEN)

`lib/application/family_sync/apply_sync_operations_use_case.dart`

**Constructor change:** Added `required ShoppingItemRepository shoppingItemRepository` param (4 construction sites updated atomically — 2 production files in this task, 2 test files already modified in Wave 0 now compile GREEN).

**`execute()` switch change (D37-05 fault isolation):**
- Added `case 'shopping_item':` wrapped in try/catch
- catch(e, st): `debugPrint` then `continue;` — skips bad shopping op, never aborts bill/profile/avatar ops
- Existing `'bill'`, `'profile'`, `'avatar'` cases: UNCHANGED (no try/catch added)

**`_applyShoppingItemOp`:** Routes create/insert/delete/update to helpers. delete calls `_shoppingItemRepository.softDelete(entityId)` (tombstone, never hard-delete).

**`_handleShoppingCreate`:** Idempotent — `findById(entityId) != null → return`. Calls `ShoppingItemSyncMapper.fromSyncMap + upsert`.

**`_handleShoppingUpdate`:** Three-step safety contract:
1. `existing == null` → upsert as new (analog `_handleUpdate` create-if-missing)
2. `existing.isDeleted` → `return` FIRST (SC-4 tombstone wins, before any field merge)
3. Sticky-complete merge: `existing.completedAt != null && existing.completedAt!.isAfter(incomingUpdatedAt)` → `copyWith(isCompleted: true, completedAt: existing.completedAt)` preserves local completion against stale remote renames

Tests: 11/11 GREEN (9 existing bill + 3 new shopping_item group tests) + 8/8 bill round-trip integration tests GREEN.

### Task 2: SyncOrchestrator + state_sync.dart + repository_providers.dart (GREEN)

**`lib/application/family_sync/sync_orchestrator.dart`**
- Added `required ShoppingItemChangeTracker shoppingChangeTracker` param
- Added `final ShoppingItemChangeTracker _shoppingChangeTracker;` field
- `_executeIncrementalPush`: inserted shopping flush+push block AFTER txnOps block, BEFORE profileOps block (SC-3, SYNC-01):
  ```dart
  final shoppingOps = _shoppingChangeTracker.flush();
  if (shoppingOps.isNotEmpty) {
    await _pushSync.execute(operations: shoppingOps, vectorClock: const {});
  }
  ```

**`lib/features/family_sync/presentation/providers/state_sync.dart`**
- Added `@Riverpod(keepAlive: true)` `shoppingItemChangeTrackerProvider` (mirrors `transactionChangeTrackerProvider`)
- `syncOrchestrator` provider: added `shoppingChangeTracker: ref.watch(shoppingItemChangeTrackerProvider)` param

**`lib/features/family_sync/presentation/providers/repository_providers.dart`**
- `applySyncOperationsUseCaseProvider`: added `shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider)`

**`lib/features/shopping_list/presentation/providers/repository_providers.dart` (NEW)**
- Created new file with `shoppingItemRepositoryProvider` wired to `ShoppingItemRepositoryImpl(dao, encryptionService)`
- Uses `app_accounting.appAppDatabaseProvider` and `app_accounting.appFieldEncryptionServiceProvider`

**build_runner:** Ran to regenerate `state_sync.g.dart` (new provider) and `shopping_list/.../repository_providers.g.dart` (new file).

Tests: 30/30 GREEN (phase6_sync_coverage_test + sync_providers_characterization_test).

Full suite: 164/164 GREEN (unit/application/family_sync/ + unit/features/family_sync/ + integration/sync/bill_sync_round_trip_test.dart).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Missing `registerFallbackValue` for ShoppingItem in apply_sync_operations_use_case_test.dart**
- **Found during:** Task 1 test run (2 of 3 shopping_item tests failed with mocktail error)
- **Issue:** `when(() => mockShoppingItemRepository.upsert(any())).thenAnswer(...)` — mocktail's `any()` matcher requires a fallback value registered for `ShoppingItem` type. The test file did not have `setUpAll(() { registerFallbackValue(_FakeShoppingItem()); })`
- **Fix:** Added `class _FakeShoppingItem extends Fake implements ShoppingItem {}` and `setUpAll(() { registerFallbackValue(_FakeShoppingItem()); })` to the test file
- **Files modified:** `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart`
- **Commit:** 301198a9

**2. [Rule 2 - Missing critical functionality] Created shoppingItemRepositoryProvider in new directory**
- **Found during:** Task 2 implementation (sync_providers_characterization_test.dart imports it from `lib/features/shopping_list/presentation/providers/repository_providers.dart` which did not exist)
- **Issue:** The provider file was missing — needed to create `lib/features/shopping_list/presentation/providers/` directory and `repository_providers.dart` with the provider
- **Fix:** Created directory and file with `@riverpod ShoppingItemRepository shoppingItemRepository(Ref ref)` using `ShoppingItemRepositoryImpl`
- **Files created:** `lib/features/shopping_list/presentation/providers/repository_providers.dart`, `.g.dart`
- **Commit:** 1e4202b1

## Known Stubs

None. All implementations are fully wired with no placeholders.

## Threat Flags

None. This plan wires an existing domain layer to the sync pipeline — no new network endpoints, auth paths, or trust boundary crossings introduced.

- T-37-03 (tombstone resurrection): **mitigated** — `if (existing.isDeleted) return` is first check in `_handleShoppingUpdate`
- T-37-04 (stale rename un-checks completed item): **mitigated** — sticky-complete merge guard preserves `isCompleted: true` when `existing.completedAt.isAfter(incomingUpdatedAt)`
- T-37-05 (bill loop aborted by bad shopping op): **mitigated** — ONLY `shopping_item` branch has try/catch; unit test confirms bill op after bad shopping op is applied
- T-37-06 (note ciphertext logged): **mitigated** — `upsert` calls pass plaintext to repo; repo encrypts at write boundary; no logging of note or exceptions in apply handler
- T-37-SC (npm/pip/cargo installs): **accepted** — zero new packages

## Self-Check

### Files created:
- [x] `lib/features/shopping_list/presentation/providers/repository_providers.dart` — FOUND
- [x] `lib/features/shopping_list/presentation/providers/repository_providers.g.dart` — FOUND

### Files modified:
- [x] `lib/application/family_sync/apply_sync_operations_use_case.dart` — FOUND
- [x] `lib/application/family_sync/sync_orchestrator.dart` — FOUND
- [x] `lib/features/family_sync/presentation/providers/state_sync.dart` — FOUND
- [x] `lib/features/family_sync/presentation/providers/state_sync.g.dart` — FOUND (regenerated)
- [x] `lib/features/family_sync/presentation/providers/repository_providers.dart` — FOUND
- [x] `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart` — FOUND

### Commits:
- [x] 301198a9 — feat(37-05): add shopping_item branch to ApplySyncOperationsUseCase (SC-3, SC-4)
- [x] 1e4202b1 — feat(37-05): wire SyncOrchestrator + state_sync + repository_providers (SC-3, atomic)

### Verification criteria:
- [x] `grep -c 'case .shopping_item' apply_sync_operations_use_case.dart` = 1
- [x] `grep -c "existing.isDeleted.*return\|if.*isDeleted" apply_sync_operations_use_case.dart` = 1
- [x] `grep -c "_shoppingChangeTracker.flush" sync_orchestrator.dart` = 1
- [x] `grep -c "shoppingItemChangeTrackerProvider" state_sync.dart` = 1
- [x] `grep -c "shoppingItemRepository" repository_providers.dart` = 2
- [x] `flutter test test/unit/application/family_sync/ test/unit/features/family_sync/ test/integration/sync/bill_sync_round_trip_test.dart` — 164/164 GREEN
- [x] `flutter analyze lib/` — 0 new issues (2 pre-existing info on category_selection_screen.dart, out of scope)

## Self-Check: PASSED
