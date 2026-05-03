---
phase: 10-homepage-soulfullnesscard-redesign
plan: 08b
subsystem: home/presentation
tags: [cleanup, dead-code-removal, regression-guard]

# Dependency graph
requires:
  - phase: 10-homepage-soulfullnesscard-redesign
    provides: 10-08a wiring (HomeHeroCard now owns the data the deleted helpers used to compute)
provides:
  - 3 dead-code helpers physically removed from home_screen.dart
  - Regression test (Plan 10-03) un-skipped — CI now enforces the deletion
  - home_screen.dart shrunk to 330 lines (target < 350) — net reduction visible
affects: [home-screen, ledger-row-data model (now unused — to be deleted by Plan 10-09)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-stage refactor: 10-08a wires the new widget (helpers go unused), 10-08b deletes the helpers + un-skips the regression test atomically"

key-files:
  created: []
  modified:
    - lib/features/home/presentation/screens/home_screen.dart
    - test/widget/features/home/presentation/screens/home_screen_helpers_removed_test.dart

key-decisions:
  - "Atomic delete + un-skip in a single commit so CI fails immediately if any helper is reintroduced"

patterns-established:
  - "Dead-code regression guard: when removing a helper, un-skip the deletion-assertion test in the same commit so it can never silently regress"

requirements-completed: []

# Metrics
duration: ~10min (executor stalled before commit; orchestrator finalized)
completed: 2026-05-03
---

# Phase 10 Plan 08b: Dead-Code Cleanup + Regression Guard Activation

**3 dead helpers removed, 2 unused imports purged, regression test un-skipped. home_screen.dart 435 → 330 lines.**

## Performance

- **Duration:** ~10 min (executor work + orchestrator-driven finalization)
- **Completed:** 2026-05-03
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments
- Deleted `_buildLedgerRows`, `_computeSatisfaction`, `_computeHappinessROI` from `home_screen.dart`
- Removed `import '../models/ledger_row_data.dart'` and `import '../../../../features/analytics/domain/models/monthly_report.dart'` (now unused after helper deletion)
- Removed `// TODO(plan-10-08b): delete this helper` and `// ignore: unused_element` markers added by Plan 10-08a
- Un-skipped `home_screen_helpers_removed_test.dart` (`skip: 'pending Plan 10-08 helper deletion'` removed) — regression guard now active in CI
- File size: 435 → 330 lines (target < 350) — 105-line net reduction

## Task Commits

1. **Task 8b.1: Delete dead helpers + un-skip regression test** — orchestrator-finalized commit (executor stalled at watchdog timeout 600s before commit phase; work was complete and correct on disk, finalized atomically)

## Files Modified
- `lib/features/home/presentation/screens/home_screen.dart` — 105 deletions, 0 insertions
- `test/widget/features/home/presentation/screens/home_screen_helpers_removed_test.dart` — `skip:` argument removed (1 line changed)

## Decisions Made
- **Single atomic commit:** Deletion of helpers and un-skipping the regression test landed together, so any reintroduction immediately fails CI rather than silently waiting for someone to remember to un-skip.

## Deviations from Plan
- **Executor watchdog timeout (orchestrator finalization).** The executor agent completed all on-disk work (105-line deletion + test un-skip) but stalled at the 600s stream-watchdog timeout before committing or writing SUMMARY.md. Orchestrator verified the diff matched the plan's intent verbatim, ran `flutter analyze` and the regression test (both pass), then committed and authored this SUMMARY.md. No content changes vs. what the executor produced.

## Issues Encountered
- Executor agent stalled. Mitigation: orchestrator finalized the commit and SUMMARY based on the agent's already-correct on-disk changes.

## Verification

- `grep -c "_computeHappinessROI\|_computeSatisfaction\|_buildLedgerRows" lib/features/home/presentation/screens/home_screen.dart` = **0** ✓
- `grep -c "ledger_row_data\|monthly_report" lib/features/home/presentation/screens/home_screen.dart` = **0** ✓ (imports removed)
- `wc -l lib/features/home/presentation/screens/home_screen.dart` = **330** (< 350 target) ✓
- `flutter analyze lib/features/home/` = **No issues found** ✓
- `flutter test home_screen_helpers_removed_test.dart` = **+1 passed** (regression guard active) ✓

## Next Phase Readiness
- `LedgerRowData` model is now unused everywhere → Plan 10-09 can safely delete it.
- The 3 obsolete widgets (SoulFullnessCard, MonthOverviewCard, LedgerComparisonSection) likewise have no remaining consumers in home_screen.dart → Plan 10-09 can delete the widget files + their tests.

## Self-Check: PASSED

```
$ git log --oneline -1
<commit-hash> refactor(10-08b): delete dead helpers + un-skip regression test
```

---
*Phase: 10-homepage-soulfullnesscard-redesign*
*Completed: 2026-05-03*
