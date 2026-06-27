---
phase: 260627-v0w
plan: 01
subsystem: settings/app-root
tags: [riverpod, data-reset, invalidation, refresh, bugfix]
status: complete
requires:
  - existing invalidateTransactionDependents pattern
  - HomePocketApp bootstrap (_HomePocketAppState)
provides:
  - dataResetSignalProvider (global reset signal)
  - invalidateAllDataProviders(WidgetRef) (whole-family invalidation helper)
  - app-root re-bootstrap routine (refresh without restart)
affects:
  - lib/main.dart
  - lib/features/settings/presentation/widgets/data_management_section.dart
tech-stack:
  added: []
  patterns:
    - "global side-effect signal via @riverpod Notifier + ref.listen (not ref.watch)"
    - "plain top-level WidgetRef helper mirroring invalidate_transaction_dependents.dart"
key-files:
  created:
    - lib/core/state/data_reset_signal.dart
    - lib/core/state/data_reset_signal.g.dart
    - lib/shared/utils/invalidate_all_data_providers.dart
    - test/unit/shared/utils/invalidate_all_data_providers_test.dart
    - test/widget/features/settings/data_reset_refresh_test.dart
  modified:
    - lib/main.dart
    - lib/features/settings/presentation/widgets/data_management_section.dart
decisions:
  - "App-root re-bootstrap + centralized invalidation (not per-widget invalidate) — fixes BOTH the dangling captured bookId AND the unreleased provider caches in one DRY routine"
  - "seedAll stubbed no-op in the integration test; real ensureDefaultBook runs so the one-default-book/new-id invariant is genuinely exercised without crypto/shared-prefs/asset infra"
metrics:
  duration: ~30m
  completed: 2026-06-27
  tasks: 3
  files: 7
---

# Quick Task 260627-v0w: Refresh Home/List/Analytics after clear-all & import (no restart) Summary

Deleting all data (or importing a backup) in Settings left Home / List / Analytics showing stale data until the app was restarted. Root cause was two independent bugs: (1) the active `bookId` is captured once at boot in `_HomePocketAppState` and threaded down as a constructor param — after a wipe it dangled at a deleted book row, and the IndexedStack tab shell keeps all tabs permanently mounted so their one-shot FutureProviders never re-fetched; (2) no Riverpod provider was ever invalidated. Fixed with a single global reset signal that drives an app-root re-bootstrap (fresh default book → recompute bookId → invalidate every data family → rebuild shell), funnelling both destructive Settings actions through one DRY routine.

## What was built

- **`DataResetSignal` notifier (`dataResetSignalProvider`)** — `lib/core/state/data_reset_signal.dart`. A `@riverpod` monotonic counter with `fire()`; cross-cutting so it lives under `core/state/`.
- **`invalidateAllDataProviders(WidgetRef)`** — `lib/shared/utils/invalidate_all_data_providers.dart`. Full-wipe sibling of `invalidateTransactionDependents`. Invalidates every data-bearing family (Home/List/Shadow, all 12 Analytics families, all 5 Happiness families, `bookByIdProvider`, `appSettingsProvider`, `currentLocaleProvider`) by family handle so all keyed slices are discarded.
- **App-root re-bootstrap** — `lib/main.dart`. Extracted shared `_seedAndEnsureDefaultBook()` (DRY; `_initialize()` delegates to it). New `_reinitializeAfterDataReset()` shows the spinner, re-seeds + ensures a fresh default book → new bookId, calls `invalidateAllDataProviders(ref)`, `setState`s the new bookId. `build()` wires `ref.listen(dataResetSignalProvider, ...)` (side-effect → `ref.listen`, never `ref.watch`). Sync engine is intentionally NOT re-initialized (already registered at first boot).
- **One-line fire sites** — `data_management_section.dart`. Clear-all and import success branches each call `ref.read(dataResetSignalProvider.notifier).fire();`. No per-provider invalidation duplicated here.

## Tasks

1. **Centralized reset infrastructure** (commit `b57a2605`) — signal + helper + unit test (RED→GREEN). Unit test asserts re-execution of a representative provider from each group (home/list, analytics, settings) after invalidation.
2. **Wire app-root re-bootstrap + fire sites** (commit `cc907e17`) — refactor + listen + two one-line fires.
3. **Integration test + full gate** (commit `fb6c4632`) — drives the real `HomePocketApp` on an in-memory DB; asserts: post-clear exactly one default book with a NEW id, threaded bookId follows it (no dangling), stale book-A `bookByIdProvider` cache released, today family empty; import path → imported book becomes active with no duplicate default book and bookId re-pointed.

## Provider-list verification

All 25 enumerated provider names were grep/Read-verified against the live codebase before importing. `largestMonthlyExpenseProvider` is generated from `largestMonthlyExpense` in `state_happiness.dart` (the literal-name grep missed the function-derived provider; confirmed present). No corrections or additions were needed — the planner's list was accurate.

## Deviations from Plan

None — plan executed exactly as written (TDD where marked; pragmatic harness chosen for Task 3 as the plan explicitly permitted, simulating the wipe/import at the repository level to avoid crypto/shared-prefs/asset infra while still running the real `ensureDefaultBook`).

## Threat mitigations

- **T-v0w-01** (half-wiped DB): the shared re-bootstrap runs count-guarded seed + `ensureDefaultBook` after every wipe; the integration test asserts exactly one default book post-reset.
- **T-v0w-02** (double-fire): `ref.listen` callback guards `mounted`; the re-bootstrap is idempotent.

## Verification

- `flutter pub run build_runner build --delete-conflicting-outputs` → clean, no stale generated files.
- `flutter analyze` → No issues found.
- `flutter test` (FULL suite, not scope-limited) → 3358 tests, all passed (architecture + golden tests included; no golden/platform-AA failures).

## Self-Check: PASSED

- Created files all exist on disk (data_reset_signal.dart/.g.dart, invalidate_all_data_providers.dart, both tests).
- Commits exist: `b57a2605`, `cc907e17`, `fb6c4632`.
