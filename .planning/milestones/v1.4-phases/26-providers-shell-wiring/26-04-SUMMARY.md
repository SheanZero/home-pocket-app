---
phase: 26-providers-shell-wiring
plan: "04"
subsystem: ui
tags: [flutter, riverpod, consumer-widget, async-value, indexed-stack]

requires:
  - phase: 26-03
    provides: listTransactionsProvider(bookId) — AsyncNotifier returning List<TaggedTransaction>

provides:
  - ListScreen ConsumerWidget loading scaffold (AsyncValue.when with CircularProgressIndicator)
  - MainShellScreen List tab wired — ListScreen replaces Center(child: Text(listTab)) placeholder
  - ref.invalidate(listTransactionsProvider) hooked into sync listener + FAB-return callback (D-03 forward-wiring)

affects: [26-providers-shell-wiring, Phase 28 transaction tiles, Phase 29 list assembly]

tech-stack:
  added: []
  patterns:
    - "AsyncValue.when loading scaffold: show CircularProgressIndicator for both loading + data states; data branch marked for Phase 28 replacement"
    - "D-03 forward-wiring: ref.invalidate added to sync listener and FAB callback before Phase 28 data rendering ships"

key-files:
  created:
    - lib/features/list/presentation/screens/list_screen.dart
  modified:
    - lib/features/home/presentation/screens/main_shell_screen.dart

key-decisions:
  - "data branch in ListScreen shows CircularProgressIndicator (same as loading) — Phase 28 comment marks replacement point; avoids incomplete tile rendering this phase"
  - "ref.invalidate(listTransactionsProvider) added to both sync listener and FAB callback as D-03 forward-wiring; no user-visible effect this phase but prevents returning to shell in Phase 28"

patterns-established:
  - "LoadingScaffold pattern: ConsumerWidget + AsyncValue.when with loading/error/data all handled; data deferred to next phase via comment"

requirements-completed:
  - FILTER-01
  - FILTER-02
  - FILTER-03
  - FILTER-04

duration: 12min
completed: 2026-05-30
---

# Phase 26 Plan 04: Shell Wiring Summary

**ListScreen ConsumerWidget loading scaffold wired into MainShellScreen IndexedStack — List tab now shows CircularProgressIndicator instead of text placeholder, with listTransactionsProvider invalidation hooked into sync listener and FAB-return callback (D-03)**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-05-30T00:30:00Z
- **Completed:** 2026-05-30T00:42:00Z
- **Tasks:** 2 (of 3; Task 3 is a human-verify checkpoint, not executed by this agent)
- **Files modified:** 2

## Accomplishments

- Created `lib/features/list/presentation/screens/list_screen.dart` — ConsumerWidget consuming `listTransactionsProvider(bookId: bookId)` with `AsyncValue.when` returning `CircularProgressIndicator` for loading and data states, `Text(e.toString())` for error
- Replaced `Center(child: Text(S.of(context).listTab))` placeholder at `main_shell_screen.dart:111` with `ListScreen(bookId: bookId)` inside the IndexedStack
- Added `ref.invalidate(listTransactionsProvider(bookId: bookId))` to sync listener (inside `wasSyncing && nowDone` block) — D-03 forward-wiring
- Added `ref.invalidate(listTransactionsProvider(bookId: bookId))` to FAB-return callback — D-03 forward-wiring
- All 37 list unit tests pass (list_filter_notifier, list_transactions_provider); `flutter analyze` reports zero new issues over 4-issue baseline

## Task Commits

Each task was committed atomically:

1. **Task 1: ListScreen loading scaffold** - `0b1293f` (feat)
2. **Task 2: main_shell_screen.dart wiring + invalidation** - `3f92e0b` (feat)

## Files Created/Modified

- `lib/features/list/presentation/screens/list_screen.dart` — New ConsumerWidget with AsyncValue.when; loading scaffold for List tab
- `lib/features/home/presentation/screens/main_shell_screen.dart` — Added list imports, replaced placeholder, added 2x invalidation hooks

## Decisions Made

- `data` branch in `ListScreen.build()` returns `CircularProgressIndicator` (same as loading state) — this avoids rendering incomplete tile UI and is clearly marked with `// Phase 28: replace data branch with ListView of TaggedTransaction tiles` for the next wave to pick up
- Both sync listener and FAB callback receive `ref.invalidate(listTransactionsProvider(bookId: bookId))` as D-03 forward-wiring — no user-visible effect this phase since `ListScreen` only shows a loading indicator, but the hooks are required so Phase 28 doesn't need to return to `main_shell_screen.dart`

## Deviations from Plan

None — plan executed exactly as written. All four targeted changes (2 imports, 1 placeholder replacement, 2 invalidation hooks) applied without restructuring surrounding code.

## Issues Encountered

`flutter test test/unit/features/list/ --no-pub` crashed with `StateError: Bad state: No element` — a known Flutter tooling issue with `--no-pub` in certain worktree environments. Tests pass cleanly without that flag (37/37 pass).

## Known Stubs

- `ListScreen.build()` data branch returns `CircularProgressIndicator` — intentional scaffold; Phase 28 will replace with `ListView` of `TaggedTransaction` tiles. This is by design (D-09: pure loading this phase) and does not prevent the plan's goal (List tab reachable + shows loading state).

## Threat Flags

None — no new network endpoints, auth paths, or schema changes. `Text(e.toString())` in error branch may show exception message; this is accepted per T-26-04-LE in the plan's threat model.

## Self-Check

- `lib/features/list/presentation/screens/list_screen.dart` — FOUND
- `lib/features/home/presentation/screens/main_shell_screen.dart` — FOUND (modified)
- Commit `0b1293f` — FOUND
- Commit `3f92e0b` — FOUND
- `grep -c 'ref.invalidate(listTransactionsProvider' lib/features/home/presentation/screens/main_shell_screen.dart` returns 2 — VERIFIED
- `grep -c 'ListScreen(bookId' lib/features/home/presentation/screens/main_shell_screen.dart` returns 1 — VERIFIED
- `flutter test test/unit/features/list/` exits 0 (37/37 pass) — VERIFIED
- `flutter analyze --no-pub` zero new issues — VERIFIED

## Self-Check: PASSED

## Next Phase Readiness

- Phase 26 is complete: all 4 plans shipped
  - Plan 01: `TaggedTransaction` + `MemberTag` Freezed VOs
  - Plan 02: `listFilterProvider` (keepAlive) + `getListTransactionsUseCaseProvider`
  - Plan 03: `listTransactionsProvider` with locale-aware text search + 9 unit tests
  - Plan 04: `ListScreen` scaffold + `MainShellScreen` wiring (this plan)
- FILTER-01/02/03/04 requirements encoded in provider logic and covered by automated tests
- Human checkpoint (Task 3) awaits verification: run app, navigate to List tab, confirm CircularProgressIndicator visible, no crash on tab switch
- Phase 27 (Calendar Header + Month Summary) can proceed once human checkpoint is cleared

---
*Phase: 26-providers-shell-wiring*
*Completed: 2026-05-30*
