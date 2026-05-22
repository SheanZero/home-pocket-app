---
phase: 18-shared-details-form-foundation
plan: "02"
subsystem: accounting/family-sync
tags:
  - use-case
  - update
  - sync
  - riverpod
  - tdd
dependency_graph:
  requires:
    - "17-03 (TransactionRepository.update + TransactionSyncMapper.toUpdateOperation already wired)"
    - "17-02 (entrySource on Transaction model; SC-3 contract established)"
  provides:
    - "UpdateTransactionUseCase.execute() — consumes in Plan 04 (form submit edit path)"
    - "updateTransactionUseCaseProvider — Riverpod provider for edit-mode form widget"
    - "TransactionChangeTracker.trackUpdate() — sync push lane for edit operations"
  affects:
    - "Plan 04 (TransactionDetailsForm.submit() edit branch reads updateTransactionUseCaseProvider)"
    - "Plan 08 (DAO integration test exercises UpdateTransactionUseCase round-trip for SC-3)"
tech_stack:
  added:
    - "UpdateTransactionUseCase (lib/application/accounting/)"
    - "UpdateTransactionParams (lib/application/accounting/)"
    - "TransactionChangeTracker.trackUpdate method"
    - "updateTransactionUseCaseProvider (@riverpod, single source of truth)"
  patterns:
    - "params class + execute() -> Future<Result<T>> (mirrors CreateTransactionUseCase shape)"
    - "seed.copyWith() for immutable update (CLAUDE.md Pitfall #4)"
    - "pass-through vs coalesce semantics (EDIT-02 contract)"
    - "track-then-trigger pattern (D-20, mirrors CreateTransactionUseCase lines 169-180)"
key_files:
  created:
    - lib/application/accounting/update_transaction_use_case.dart
    - test/unit/application/accounting/update_transaction_use_case_test.dart
    - test/unit/application/family_sync/transaction_change_tracker_test.dart
  modified:
    - lib/application/family_sync/transaction_change_tracker.dart
    - lib/features/accounting/presentation/providers/repository_providers.dart
    - lib/features/accounting/presentation/providers/repository_providers.g.dart
decisions:
  - "Pass-through semantics for note/merchant: params.note and params.merchant applied verbatim to copyWith (no ?? coalesce). null = user cleared the field. Enforces EDIT-02 ('user can modify any editable field') and B1 fix."
  - "Coalesce semantics for amount/categoryId/timestamp/ledgerType/soulSatisfaction: null param = form did not override, keep seed value."
  - "Hash chain frozen on edit (D-08): UpdateTransactionUseCase deliberately excludes HashChainService dependency. prevHash/currentHash flow through copyWith default."
  - "entrySource preserved via copyWith default (SC-3): no entrySource argument in copyWith call."
  - "trackUpdate shares _pendingOps with trackCreate/trackDelete (D-20): single queue, no new state."
  - "updateTransactionUseCaseProvider placed after createTransactionUseCaseProvider, before getTransactionsUseCase (single source of truth, CLAUDE.md Pitfall #10)."
metrics:
  duration_seconds: 568
  completed_date: "2026-05-22"
  tasks_completed: 3
  files_changed: 6
---

# Phase 18 Plan 02: UpdateTransactionUseCase + trackUpdate + Provider Wiring Summary

UpdateTransactionUseCase with pass-through note/merchant semantics, frozen hash chain, and sync push via trackUpdate; provider exposed as single source of truth via @riverpod.

## What Was Built

### Task 1: UpdateTransactionUseCase + UpdateTransactionParams

Created `lib/application/accounting/update_transaction_use_case.dart` with:

- `UpdateTransactionParams` — seed Transaction + 7 mutable override fields (amount, categoryId, timestamp, note, merchant, ledgerType, soulSatisfaction). Dartdoc documents the pass-through/coalesce contract.
- `UpdateTransactionUseCase` — minimal constructor (transactionRepository required, syncEngine and changeTracker optional). No HashChainService, no CategoryRepository, no DeviceIdentityRepository (D-08, D-07: seed supplies them).
- `execute()` method:
  - Validates amount (> 0 if provided) and categoryId (non-empty if provided)
  - Builds `updated` via `seed.copyWith(...)` with:
    - **Pass-through**: `note: params.note` and `merchant: params.merchant` (no `??` — null clears the field, EDIT-02/B1)
    - **Coalesce**: `amount: params.amount ?? params.seed.amount` etc. for the five non-clearable fields
    - `updatedAt: DateTime.now()` stamped (D-07)
    - `entrySource`, `id`, `bookId`, `deviceId`, `prevHash`, `currentHash`, `createdAt` preserved via copyWith default (D-07/D-08/SC-3)
  - Calls `_transactionRepo.update(updated)` — repo impl handles note encryption
  - Calls `_changeTracker?.trackUpdate(TransactionSyncMapper.toUpdateOperation(...))` then `_syncEngine?.onTransactionChanged()` (D-20)
  - Returns `Result.success(updated)` or `Result.error(message)` — no try/catch (exceptions propagate)

19 unit tests covering: happy path, updatedAt stamp, entrySource preservation (all 3 literals), hash chain frozen, immutable fields preserved, pass-through clear semantics, coalesce keep semantics, validation errors.

### Task 2: TransactionChangeTracker.trackUpdate

Extended `lib/application/family_sync/transaction_change_tracker.dart` with:

```dart
void trackUpdate(Map<String, dynamic> operation) {
  _pendingOps.add(operation);
}
```

Inserted between trackCreate and trackDelete. Identical body to trackCreate. No new state — `_pendingOps` count went from 6 to 7 references (trackCreate + trackUpdate + trackDelete adds + flush reads/clears). 5 unit tests covering accumulation, shared queue, flush semantics.

### Task 3: updateTransactionUseCaseProvider via @riverpod

Modified `lib/features/accounting/presentation/providers/repository_providers.dart`:

- Added import for `update_transaction_use_case.dart`
- Added provider block after `createTransactionUseCaseProvider`:

```dart
@riverpod
UpdateTransactionUseCase updateTransactionUseCase(Ref ref) {
  return UpdateTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    syncEngine: ref.watch(syncEngineProvider),
    changeTracker: ref.watch(transactionChangeTrackerProvider),
  );
}
```

Ran `flutter pub run build_runner build --delete-conflicting-outputs` — generator emitted `updateTransactionUseCaseProvider` in `repository_providers.g.dart`. No categoryRepository, deviceIdentityRepository, or hashChainService (D-08).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Task 2 implemented before Task 1 test could go GREEN**

- **Found during:** Task 1 test run (RED phase)
- **Issue:** `UpdateTransactionUseCase` referenced `_changeTracker?.trackUpdate(...)` which didn't exist yet on `TransactionChangeTracker`. The compilation error blocked Task 1's GREEN run.
- **Fix:** Implemented Task 2 (trackUpdate) before running Task 1's GREEN phase. Logical commit order preserved: Task 2 test + impl → Task 1 test + impl.
- **Impact:** None — both tasks were planned; execution order was adjusted.

**2. [Rule 1 - Bug] Doc comment HTML-in-angle-brackets lint warning**

- **Found during:** Task 1 analyzer run
- **Issue:** Dartdoc comment used `Future<Result<Transaction>>` literal which the analyzer flagged as `unintended_html_in_doc_comment`.
- **Fix:** Reworded to "execute(params) returning `Future<Result<Transaction>>`" and moved angle-bracket text to a backtick context.
- **Files modified:** lib/application/accounting/update_transaction_use_case.dart

**3. [Deviation] Worktree path isolation**

- **Found during:** Initial test runs
- **Issue:** Write tool calls initially landed in the main repo (`/Users/xinz/Development/home-pocket-app/`) instead of the worktree. Detected via `git -C <worktree> status`.
- **Fix:** Recreated all files using absolute paths rooted at the worktree path.

## Invariants Verified

| Invariant | Criterion | Verified |
|-----------|-----------|---------|
| D-07: updatedAt stamped | `updatedAt: DateTime.now()` in copyWith | Test passes |
| D-08: hash chain frozen | No hashChainService reference; prevHash/currentHash unchanged | Test passes |
| SC-3: entrySource preserved | copyWith has no entrySource argument; all 3 literals tested | Test passes |
| D-20: sync push wired | trackUpdate + onTransactionChanged called on success | Code inspected |
| EDIT-02/B1: note pass-through | `note: params.note` (no `??`); clears from 'old note' to null | Test passes |
| EDIT-02/B1: merchant pass-through | `merchant: params.merchant` (no `??`); clears to null | Test passes |
| CLAUDE.md Pitfall #4: immutability | seed.copyWith used, not in-place mutation | Code + test |
| CLAUDE.md Pitfall #10: single source | One updateTransactionUseCase provider only | Verified |
| CLAUDE.md Pitfall #3: regenerate | build_runner run; .g.dart committed | Done |

## Threat Flag Assessment

No new threat surface introduced beyond what was already modeled in the plan's threat register:

- T-18-02-02 (note encryption): Use case does NOT pre-encrypt. Plaintext note flows to `TransactionRepositoryImpl.update()` which calls `_encryptionService.encryptField(transaction.note!)`.
- T-18-02-03 (sync payload): `toUpdateOperation` uses the same `toSyncMap` path as `toCreateOperation`. No new plaintext surface.
- T-18-02-05 (entrySource): Confirmed by test iterating `EntrySource.values`.

## Known Stubs

None — this plan is pure application-layer logic with no UI rendering.

## Self-Check: PASSED

Files exist in worktree:
- lib/application/accounting/update_transaction_use_case.dart — FOUND
- lib/application/family_sync/transaction_change_tracker.dart (trackUpdate added) — FOUND
- lib/features/accounting/presentation/providers/repository_providers.dart (provider added) — FOUND
- lib/features/accounting/presentation/providers/repository_providers.g.dart (updateTransactionUseCaseProvider) — FOUND
- test/unit/application/accounting/update_transaction_use_case_test.dart — FOUND
- test/unit/application/family_sync/transaction_change_tracker_test.dart — FOUND

Commits on worktree-agent-a7f5357cf2988665b:
- 59da092 — feat(18-02): extend TransactionChangeTracker with trackUpdate
- 1d4889d — feat(18-02): add UpdateTransactionUseCase + UpdateTransactionParams
- 8dbfcae — feat(18-02): expose updateTransactionUseCaseProvider via @riverpod
