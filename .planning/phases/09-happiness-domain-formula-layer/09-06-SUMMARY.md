---
phase: 09-happiness-domain-formula-layer
plan: 06
subsystem: use-case
tags: [analytics, happiness, happy-04, top-joy, tdd, metric-result]

requires:
  - phase: 09-happiness-domain-formula-layer
    provides: Plan 09-02 MetricResult and BestJoyMomentRow contracts; Plan 09-04 AnalyticsRepository happiness methods
provides:
  - Standalone GetBestJoyMomentUseCase returning MetricResult<BestJoyMomentRow>
  - TDD coverage for empty, defensive null-row, value, and sample-size alignment paths
affects: [phase-10-homepage, top-joy-story-card, happiness-use-cases]

tech-stack:
  added: []
  patterns:
    - "Use cases are constructor-injected, repository-backed classes with a single execute() method."
    - "Top Joy returns Value whenever totalSoulTx > 0 and the repository supplies a row; Phase 10 owns neutral-state CTA logic."

key-files:
  created:
    - lib/application/analytics/get_best_joy_moment_use_case.dart
    - test/unit/application/analytics/get_best_joy_moment_use_case_test.dart
  modified: []

key-decisions:
  - "Kept HAPPY-04 contract simple per D-17: no all-neutral special case in Phase 9."
  - "Used overview.count as the Value sampleSize so Top Joy aligns with the shared personal-metric empty trigger."

patterns-established:
  - "Best Joy use case gates the argmax repository call behind getSoulSatisfactionOverview count > 0."
  - "Mocktail verifyNever pins the short-circuit behavior for empty months."

requirements-completed: [HAPPY-04]

duration: 4min
completed: 2026-05-02
---

# Phase 09 Plan 06: Best Joy Use Case Summary

**Standalone Top Joy use case with D-17 empty/value semantics and Mocktail coverage for the repository short-circuit.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-02T01:17:04Z
- **Completed:** 2026-05-02T01:20:38Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Added `GetBestJoyMomentUseCase` with one `execute()` method returning `MetricResult<BestJoyMomentRow>`.
- Implemented the `overview.count == 0` short-circuit before calling `getBestJoyMoment`.
- Added four tests covering empty overview, defensive null row, happy-path value data, and sample-size alignment.

## Task Commits

1. **Task 1 RED: Best Joy use case tests** - `8d3de22` (test)
2. **Task 1 GREEN: Best Joy use case implementation** - `cf7e267` (feat)

## Files Created/Modified

- `lib/application/analytics/get_best_joy_moment_use_case.dart` - Standalone HAPPY-04 use case using `AnalyticsRepository`.
- `test/unit/application/analytics/get_best_joy_moment_use_case_test.dart` - Mocktail tests for the use case contract.

## Decisions Made

- Followed D-17 exactly: Phase 9 returns `Value(row, overview.count)` when a row exists and does not encode the future UI CTA for neutral-only data.
- Trusted DAO/repository ordering for the argmax row; the use case does not re-sort or reinterpret `BestJoyMomentRow`.

## Verification

- RED: `flutter test test/unit/application/analytics/get_best_joy_moment_use_case_test.dart` failed because `get_best_joy_moment_use_case.dart` did not exist.
- GREEN: `flutter test test/unit/application/analytics/get_best_joy_moment_use_case_test.dart` passed: 4 tests.
- `flutter analyze lib/application/analytics/get_best_joy_moment_use_case.dart` passed with 0 issues.
- `flutter analyze lib/application/analytics/get_best_joy_moment_use_case.dart test/unit/application/analytics/get_best_joy_moment_use_case_test.dart` passed with 0 issues.
- Final `flutter analyze` passed with 0 issues after parallel in-progress files from other plans were committed.
- Acceptance greps passed for `MetricResult<BestJoyMomentRow>`, both `Empty()` branches, `Value(row, overview.count)`, 4 tests, and `verifyNever`.

## Full Analyzer Note

An initial `flutter analyze` attempt failed on concurrent parallel-plan files outside 09-06:

- `test/unit/application/analytics/get_happiness_report_use_case_test.dart` imports missing `get_happiness_report_use_case.dart`.
- Earlier during the same shared-worktree window, `test/unit/application/analytics/get_family_happiness_use_case_test.dart` was also present as another parallel RED test.

The focused 09-06 analyzer gate passed throughout. After those parallel files were completed by their owning plans, final full `flutter analyze` passed with 0 issues.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

- Full-worktree analysis was temporarily blocked by other parallel executors' in-progress RED/GREEN files. A final retry passed after those files were completed.

## Known Stubs

None. Stub scan found no TODO/FIXME/placeholder or hardcoded empty UI-data stubs in the created files; `row == null` is the planned defensive branch, not a stub.

## Threat Flags

None. This plan added a repository-backed application use case only; no new endpoint, auth path, file access pattern, schema change, or unplanned trust boundary was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 10 can consume `GetBestJoyMomentUseCase` for story-card-only Top Joy queries. The result contract is stable: `Empty` for no soul rows or defensive null argmax, otherwise `Value(BestJoyMomentRow, overview.count)`.

## Self-Check: PASSED

- Created use case file exists on disk.
- Created test file exists on disk.
- RED commit `8d3de22` exists in git history.
- GREEN commit `cf7e267` exists in git history.
- `.planning/STATE.md` and `.planning/ROADMAP.md` were not modified.

---
*Phase: 09-happiness-domain-formula-layer*
*Completed: 2026-05-02*
