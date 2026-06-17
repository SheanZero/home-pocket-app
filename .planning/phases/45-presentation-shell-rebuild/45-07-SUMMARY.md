---
phase: 45-presentation-shell-rebuild
plan: 07
subsystem: ui
tags: [riverpod, flutter, analytics, refresh, behavior-preservation, transitive-reread, guard-01, phase-gate]

# Dependency graph
requires:
  - phase: 45-presentation-shell-rebuild
    plan: 04
    provides: "thin AnalyticsScreen shell — real RefreshIndicator → _refresh path (registry-derived union, shadowBooksProvider direct invalidate dropped); shell-injected shadowBooksAsync"
  - phase: 45-presentation-shell-rebuild
    plan: 05
    provides: "analytics_card_registry_test — structural (no-pump) union/visibility invariants; this plan adds the live widget-pump counterpart"
provides:
  - "test/widget/features/analytics/presentation/screens/analytics_refresh_group_mode_test.dart — Assumption A1 / D-B3 Option A behavior-preservation test: group-mode pull-to-refresh transitively re-fetches family data (familyHappinessProvider re-reads shadowBooksProvider.future) after the direct invalidate was dropped; solo-mode refresh never touches the family use case (D-B4)"
  - "full-suite phase gate result: flutter analyze 0 issues + flutter test 2925/2925 green (every golden, NO re-baseline) — D-A1 behavior preservation proven across the whole suite"
affects: [46-presentation-shell-content, 47]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Transitive-re-read verification via dependency override (NOT target override): to prove the A1 path, override familyHappinessProvider's DEPS (getFamilyHappinessUseCaseProvider + shadowBooksProvider) instead of overriding familyHappinessProvider itself — overriding the provider directly would short-circuit (mask) the internal `await ref.watch(shadowBooksProvider.future)` re-read that Option A relies on. The mocked use-case call count is the observable A1 signal."
    - "Real RefreshIndicator → _refresh widget-pump (vs Plan 05's synthetic-ctx enumeration): fling the SingleChildScrollView, pumpAndSettle, then verify/verifyNever use-case calls — exercises the live registry-derived invalidation union the user actually triggers."
    - "clearInteractions between initial build and refresh isolates the refresh-driven re-fetch from the build-time fetch, so `.called(greaterThanOrEqualTo(1))` after clear is a clean refresh signal."

key-files:
  created:
    - test/widget/features/analytics/presentation/screens/analytics_refresh_group_mode_test.dart
  modified: []

key-decisions:
  - "Overrode getFamilyHappinessUseCaseProvider + shadowBooksProvider, NOT familyHappinessProvider, so the real familyHappinessProvider builds and its internal shadowBooksProvider.future re-read (the A1 transitive path) is genuinely exercised. The existing analytics_screen_test overrides familyHappinessProvider directly — that harness CANNOT prove A1 (it masks the re-read), which is exactly why this dedicated test was needed."
  - "Use-case call count (verify .called(greaterThanOrEqualTo(1)) after clearInteractions) is the A1 observable: an invalidate of familyHappinessProvider forces a rebuild → re-reads shadowBooksProvider.future → re-invokes GetFamilyHappinessUseCase.execute. Counting the use case is more direct than asserting widget data identity."
  - "Task 2 (existing-screen-test-unchanged + full-suite gate) produced NO code commit — analytics_screen_test.dart has an empty diff (git diff --stat HEAD = empty) and the gate is a verification run, not an edit. Its evidence is folded into this SUMMARY + the final metadata commit."

patterns-established:
  - "To verify a dropped-direct-invalidate still refreshes via a transitive provider re-read, override the transitive provider's dependencies (so it really builds) and assert the downstream use case re-fires — never override the provider under test."

requirements-completed: [REDES-01, GUARD-01]

# Metrics
duration: 11min
completed: 2026-06-17
---

# Phase 45 Plan 07: Assumption A1 verification + full-suite phase gate Summary

**Discharged Assumption A1 / D-B3 Option A against the LIVE `RefreshIndicator → _refresh()` path: a group-mode pull-to-refresh widget test proves the family snapshot still re-fetches via the transitive `familyHappinessProvider → shadowBooksProvider.future` re-read even though Plan 02/04 dropped the direct `shadowBooksProvider` invalidate; a solo-mode test proves the family use case is never touched (D-B4 — hidden, not invalidated). Then ran the full phase gate: `flutter analyze` 0 issues + `flutter test` 2925/2925 green with every golden passing and ZERO re-baseline — D-A1 behavior preservation proven across the whole suite.**

## Performance

- **Duration:** ~11 min
- **Started:** 2026-06-17T06:30Z
- **Completed:** 2026-06-17T06:41Z
- **Tasks:** 2 (Task 1: new test + commit; Task 2: verification-only gate, no edit)
- **Files created:** 1; **Files modified:** 0

## Accomplishments

### Task 1 — Assumption A1 group-mode refresh + D-B4 solo guard (commit `642c0950`)
- Created `test/widget/features/analytics/presentation/screens/analytics_refresh_group_mode_test.dart` (2 `testWidgets`, both green).
- **Group mode (A1):** pumps the real `AnalyticsScreen` in group mode, clears the family use-case interactions after the initial build, flings the `SingleChildScrollView` to trigger the real `RefreshIndicator.onRefresh → _refresh`, then `verify(() => familyHappinessUseCase.execute(...)).called(greaterThanOrEqualTo(1))`. The invalidate of `familyHappinessProvider` transitively re-reads `shadowBooksProvider.future` (state_happiness.dart:118) and re-invokes the use case — **A1 confirmed; the direct invalidate stays dropped without losing the refresh.**
- **Solo mode (D-B4):** pumps in solo mode, asserts `verifyNever` on the family use case both at build (family spec hidden via `isVisible: ctx.isGroupMode`) and after refresh (`where(isVisible)` filters the spec out of the union BEFORE `expand(refreshTargets)`).
- Critically, the test overrides `getFamilyHappinessUseCaseProvider` + `shadowBooksProvider` (the family provider's DEPS) and leaves `familyHappinessProvider` REAL — overriding the provider directly (as the existing screen test does) would mask the transitive re-read and make the test vacuous.

### Task 2 — existing screen test unchanged + full-suite phase gate
- `analytics_screen_test.dart` passes with **zero assertion edits** (`git diff --stat HEAD` on the file = empty).
- `flutter analyze` (whole project) → **No issues found! (0 issues).**
- `flutter test` (full suite) → **2925/2925 green** — including every golden (no re-baseline), `home_screen_isolation_test`, `anti_toxicity_phase16/17`, `analytics_no_delta_ui`, `domain_import_rules`, `provider_graph_hygiene`, the Plan-05 `analytics_card_registry_test`, and the new `analytics_refresh_group_mode_test`.
- No golden baseline file was modified by this phase (tree-preserving extraction held byte-faithful).

## Task Commits

1. **Task 1: Assumption A1 group-mode refresh transitive re-read + D-B4 solo guard** — `642c0950` (test)

Task 2 produced no code commit (verification-only; existing screen test unchanged). _(Plan metadata commit follows this SUMMARY.)_

## Files Created

- `test/widget/features/analytics/presentation/screens/analytics_refresh_group_mode_test.dart` — 2 `testWidgets`: group-mode A1 transitive re-read + solo-mode D-B4 guard, plus a `_FakeAnalyticsRepository` and the non-family provider overrides mirrored from `analytics_screen_test.dart`.

## Decisions Made

- **Dependency-override over target-override** for A1: see Tech tracking. This is the load-bearing design choice — it is the only way to exercise the transitive `shadowBooksProvider.future` re-read; overriding `familyHappinessProvider` directly (the existing harness) provably masks it.
- **Use-case call count as the A1 observable:** counting `GetFamilyHappinessUseCase.execute` after `clearInteractions` is a direct, unambiguous signal of the re-fetch; asserting widget-data identity would be indirect and noisier.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `state_ledger_snapshot` import; removed two unused imports**
- **Found during:** Task 1 (first compile + analyze runs).
- **Issue:** The `perCategoryJoyBreakdown*` / `dailyVsJoySnapshot*` providers live in `state_ledger_snapshot.dart`, not `state_happiness.dart` — first compile failed with `Method not found` for all four. After fixing, `flutter analyze` flagged two now-unused imports (`flutter_riverpod.dart`, `family_happiness.dart`).
- **Fix:** Added the `state_ledger_snapshot.dart` import; removed the two unused imports.
- **Files modified:** `test/widget/features/analytics/presentation/screens/analytics_refresh_group_mode_test.dart`.
- **Commit:** `642c0950`.

No behavioral deviations. A1 held TRUE (group-mode refresh re-fetches family data), so no remediation (restore direct invalidate / Option B) was needed — Option A is confirmed correct.

## A1 Verification Outcome (the plan's central question)

**A1 is TRUE.** Dropping the direct `shadowBooksProvider` invalidate (Plan 02/04, D-B3 Option A) does NOT break group-mode family refresh: invalidating `familyHappinessProvider` rebuilds it, which re-reads `shadowBooksProvider.future` and re-invokes `GetFamilyHappinessUseCase.execute`. Today's behavior is preserved. No Option B fallback required.

## Threat Surface

No new threat surface — test-only plan, zero production code.
- **T-45-04 (stale-data, A1 false):** mitigated — Task 1 directly asserts the family use case re-fires after pull-to-refresh; A1 confirmed TRUE, so no stale-family-data risk.
- **T-45-11 (test-masking):** mitigated — `analytics_screen_test.dart` assertions were NOT edited (empty diff); the full suite + every golden green with zero re-baseline is the objective proof.
- **T-45-SC (package installs):** none — all test deps already present.

## Known Stubs

None. The test wires real providers (family path) + direct overrides (non-family) — no placeholder data flows to assertions.

## Verification

- `flutter test test/widget/features/analytics/presentation/screens/analytics_refresh_group_mode_test.dart` → **2/2 green** (`All tests passed!`).
- `flutter analyze` (whole project) → **No issues found! (0 issues).**
- `flutter test` (full suite) → **2925/2925 green** (`All tests passed!`) — every golden green, no re-baseline; home_screen_isolation, anti_toxicity_phase16/17, analytics_no_delta_ui, domain_import_rules, provider_graph_hygiene, analytics_card_registry_test, analytics_refresh_group_mode_test all included.
- `git diff --stat HEAD -- test/.../analytics_screen_test.dart` → empty (unchanged).
- `git status --short` → clean (only the new test file committed).

## Self-Check: PASSED

- FOUND: `test/widget/features/analytics/presentation/screens/analytics_refresh_group_mode_test.dart`
- FOUND: commit `642c0950` in git log.

## Next Phase Readiness

- Phase 45 is behavior-preservation-complete: shell rebuilt (Plan 04), structural invariant guarded (Plan 05), and the one live-path subtlety (A1 transitive re-read) discharged here. Phase ready for `/gsd-verify-work`.
- Phase 46 (round-5 B IA reorder + new cards + drill-down route) builds on a registry whose refresh semantics are now test-locked; Phase 47 owns golden re-baseline.
- No blockers.

---
*Phase: 45-presentation-shell-rebuild*
*Completed: 2026-06-17*
