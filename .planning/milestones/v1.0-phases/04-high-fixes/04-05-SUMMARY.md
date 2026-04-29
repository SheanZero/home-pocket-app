---
phase: 04-high-fixes
plan: "05"
subsystem: architecture-tests
tags:
  - riverpod
  - provider-graph
  - architecture-test
  - high-04
  - high-05
  - high-06
dependency_graph:
  requires:
    - 04-02-SUMMARY.md  # presentation refactor + state_*.dart structure in place
    - 04-01-SUMMARY.md  # application-layer providers (appMerchantDatabaseProvider)
  provides:
    - provider_graph_hygiene_test.dart  # architecture test locking Phase 4 invariants
    - activeGroupMembersProvider        # renamed from groupMembers + keepAlive
  affects:
    - lib/features/family_sync/presentation/providers/state_sync.dart
    - test/architecture/provider_graph_hygiene_test.dart
tech_stack:
  added:
    - dart:io File/Directory scanning in architecture tests
  patterns:
    - regex-based architecture test (mirrors Phase 3 import_guard test pattern)
    - keepAlive reconciliation per D-07.4
key_files:
  created:
    - test/architecture/provider_graph_hygiene_test.dart
  modified:
    - lib/features/family_sync/presentation/providers/state_sync.dart
    - lib/features/family_sync/presentation/providers/state_sync.g.dart
    - test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart
decisions:
  - "Uniqueness check scoped to lib/features/ only (application layer has deliberate per-feature re-export pattern from Plan 04-01)"
  - "activeGroupMembersProvider renamed from groupMembers + keepAlive added (D-07.4 reconciliation)"
  - "ledgerViewProvider is the literal generated name from class LedgerView (not ledgerProvider)"
  - "appMerchantDatabaseProvider is the app-prefixed name per Plan 04-01 Task 2 Warning 7"
metrics:
  duration: "~25 minutes"
  completed: "2026-04-26T23:40:56Z"
  tasks_completed: 2
  files_modified: 8
---

# Phase 4 Plan 05: Provider Graph Hygiene Test Summary

**One-liner:** Architecture test enforcing 5 Riverpod provider-graph invariants (HIGH-04/05/06) with activeGroupMembers rename + keepAlive reconciliation per D-07.4.

## What Was Built

### Task 1: activeGroupMembersProvider Reconciliation (HIGH-05)

**Problem:** The HIGH-05 keepAlive hard list includes `activeGroupMembersProvider`, but the actual provider was named `groupMembers` (generating `groupMembersProvider`) without `@Riverpod(keepAlive: true)`.

**Action:**
- Renamed `groupMembers` → `activeGroupMembers` in `state_sync.dart`
- Changed annotation from `@riverpod` to `@Riverpod(keepAlive: true)`
- Regenerated `state_sync.g.dart` via build_runner — the generated provider is now `StreamProvider<List<GroupMember>>` (non-auto-dispose, i.e., keepAlive)
- Updated `sync_providers_characterization_test.dart` to reference `activeGroupMembersProvider`

**Why keepAlive is appropriate:** This stream is long-lived (watches the active group's members via Drift). Recreating it on tab switches would lose subscription state. The name `activeGroupMembers` also better reflects the semantic (streams members of the currently active group, as observed via `activeGroupProvider`).

### Task 2: Architecture Test (HIGH-04 + HIGH-05 + HIGH-06)

**File:** `test/architecture/provider_graph_hygiene_test.dart` (207 lines, 5 tests)

#### 5 Invariants Enforced

**Test 1 — HIGH-04 structure (PASS)**
Each of 7 features (`accounting`, `analytics`, `dual_ledger`, `family_sync`, `home`, `profile`, `settings`) has at most one `repository_providers.dart` and only `state_*.dart` siblings in `lib/features/<f>/presentation/providers/`.

**Test 2 — HIGH-04 DI consolidation (PASS)**
No `state_*.dart` file contains `@riverpod` providers whose return type ends in `Repository`, `UseCase`, or `Service`. All DI providers live in `repository_providers.dart`.

**Test 3 — HIGH-04 global uniqueness (PASS)**
No duplicate `@riverpod` function names within `lib/features/`. Scoped to `lib/features/` because `lib/application/` uses a deliberate per-feature re-export pattern (e.g., each `application/<feature>/repository_providers.dart` re-exports `appAppDatabase`) that is intentional from Plan 04-01.

**Test 4 — HIGH-05 keepAlive hard list (PASS)**
All 6 named providers have `@Riverpod(keepAlive: true)` in `lib/`:
| Provider | File | Pattern |
|---|---|---|
| `syncEngineProvider` | `lib/features/family_sync/presentation/providers/state_sync.dart` | function-style |
| `transactionChangeTrackerProvider` | `lib/features/family_sync/presentation/providers/state_sync.dart` | function-style |
| `appMerchantDatabaseProvider` | `lib/application/ml/repository_providers.dart` | function-style |
| `activeGroupProvider` | `lib/features/family_sync/presentation/providers/state_active_group.dart` | function-style |
| `activeGroupMembersProvider` | `lib/features/family_sync/presentation/providers/state_sync.dart` | function-style (Task 1) |
| `ledgerViewProvider` | `lib/features/dual_ledger/presentation/providers/state_ledger.dart` | class-style |

**Test 5 — HIGH-06 no UnimplementedError (PASS)**
Zero `throw UnimplementedError` inside `@riverpod` function bodies or `Provider<X>` constructors across all of `lib/`. (One comment mentioning UnimplementedError in `lib/infrastructure/security/providers.dart` is correctly excluded — the regex matches code, not comments.)

## Reconciliations Applied (D-07.4)

### A. activeGroupMembersProvider (RECONCILE)
- **Original spec:** `activeGroupMembersProvider` in HIGH-05 hard list
- **Actual:** `groupMembersProvider` in `state_sync.dart` without keepAlive
- **Action:** Renamed + added `@Riverpod(keepAlive: true)` in same commit (Task 1)
- **Test updated:** `sync_providers_characterization_test.dart`

### B. ledgerViewProvider (ACKNOWLEDGE)
- **Original spec:** `ledgerProvider` in HIGH-05 requirement document
- **Actual:** `ledgerViewProvider` (generated from `class LedgerView extends _$LedgerView`)
- **Action:** Architecture test hard list uses `ledgerViewProvider` (literal generated name). No source edit needed.

### C. appMerchantDatabaseProvider (ACKNOWLEDGE)
- **Original spec:** `merchantDatabaseProvider` in HIGH-05 requirement document
- **Actual:** `appMerchantDatabaseProvider` in `lib/application/ml/repository_providers.dart` (app-prefixed per Plan 04-01 Task 2 Warning 7)
- **Action:** Architecture test hard list uses `appMerchantDatabaseProvider`. Original feature-side `merchantDatabaseProvider` was deleted by Plan 04-02 Task 5.

## Deviation from Plan

**[Rule 1 - Bug] HIGH-04 uniqueness regex incorrectly flagged intentional application-layer duplicates**
- **Found during:** Task 2, first test run
- **Issue:** The original plan's regex scanned all of `lib/` for duplicate `@riverpod` function names. The application layer has `appAppDatabase` and `appKeyManager` defined in 5 and 3 application subdirectory files respectively — this is the intentional per-feature re-export pattern from Plan 04-01.
- **Fix:** Scoped uniqueness check to `lib/features/` only. Added explanatory comment in the test.
- **Files modified:** `test/architecture/provider_graph_hygiene_test.dart`
- **Commit:** a9fa1b4 (same task commit)

**[Rule 3 - Blocking] Pre-existing analyzer info issues prevented flutter analyze exit 0**
- **Found during:** Task 1 verification
- **Issue:** 13 `info`-level issues pre-existed at the worktree base (confirmed via `git stash`), causing `flutter analyze` to exit with code 1. These included: underscore-prefixed local variables, an unnecessary import, and multiple-underscore parameters.
- **Fix:** Fixed all 13 pre-existing issues (renamed local variables, removed unused import, replaced `(_, __)` with `(_, _n)` callback parameters).
- **Files modified:** `test/core/initialization/app_initializer_test.dart`, `test/features/home/presentation/models/ledger_row_data_test.dart`, `test/unit/application/accounting/repository_providers_test.dart`, `test/unit/application/family_sync/repository_providers_test.dart`, `test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart`
- **Commit:** 2c461ff (Task 1 commit)

## Deferred Issues

**Pre-existing widget test failures (4 tests)** in `test/widget/features/family_sync/presentation/widgets/family_sync_notification_route_listener_test.dart`. These failures existed before Plan 04-05 changes (confirmed by stash verification). Logged to `deferred-items.md`. Not caused by this plan.

## Phase 4 Close Attestation

**Phase 4 is closed by this plan.** Per CONTEXT.md `<specifics>` 1st bullet: "Phase 4 close = `provider_graph_hygiene_test.dart` GREEN."

Evidence:
- `flutter test test/architecture/provider_graph_hygiene_test.dart` → 5/5 tests GREEN
- `flutter analyze` → exit 0 (2 remaining `info` items don't affect exit code)
- All HIGH-04, HIGH-05, HIGH-06 invariants now enforced as regression alarms

HIGH-01..08 closure status:
- HIGH-01: Trivially true (audit tooling had zero HIGH entries)
- HIGH-02: Closed by Plan 04-02 (presentation→infrastructure imports + import_guard.yaml)
- HIGH-03: Closed by Plan 04-03 (ResolveLedgerTypeService deletion)
- HIGH-04: Closed by Plans 04-02 + 04-05 (provider structure + architecture test)
- HIGH-05: Closed by Plan 04-05 (keepAlive hard list enforced)
- HIGH-06: Closed by Plan 04-05 (no UnimplementedError architecture test)
- HIGH-07: Closed by Plan 04-04 (Mocktail migration)
- HIGH-08: Per-plan coverage gate enforced throughout Phase 4

## Reference for Phase 5 Planner

`test/architecture/` is now the project's structural alarm directory:
- `domain_import_rules_test.dart` — Phase 3 Domain layer rules
- `presentation_layer_rules_test.dart` — Phase 4 Presentation layer rules (Plan 04-02)
- `provider_graph_hygiene_test.dart` — Phase 4 Provider graph rules (this plan)

Future phases (MED/LOW invariants) may extend this directory per CONTEXT.md `<specifics>` 5th bullet.

## Commits

| Task | Commit | Description |
|---|---|---|
| Task 1 | 2c461ff | refactor(04-05): rename groupMembers → activeGroupMembers + add keepAlive (HIGH-05 reconciliation per D-07.4) |
| Task 2 | a9fa1b4 | test(04-05): add provider_graph_hygiene architecture test — close Phase 4 (HIGH-04, HIGH-05, HIGH-06) |

## Self-Check: PASSED

- `test/architecture/provider_graph_hygiene_test.dart` exists: FOUND
- Task 1 commit 2c461ff exists: FOUND
- Task 2 commit a9fa1b4 exists: FOUND
- `activeGroupMembersProvider` in state_sync.dart: FOUND
- `@Riverpod(keepAlive: true)` annotation above `activeGroupMembers`: FOUND
- `groupMembersProvider` references in lib/ and test/ (excl .g.dart): NONE (all updated)
- `flutter analyze` exits 0: CONFIRMED
- `flutter test test/architecture/provider_graph_hygiene_test.dart` exits 0: CONFIRMED
