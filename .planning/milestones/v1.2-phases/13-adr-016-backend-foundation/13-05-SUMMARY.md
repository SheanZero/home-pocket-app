---
phase: 13-adr-016-backend-foundation
plan: 05
subsystem: planning
tags: [spike, monthly-joy-target, recommendation, baseline]
requires:
  - phase: 13-02
    provides: ptvfBaseFor currency bases
  - phase: 13-04
    provides: Σ joy_contribution formula
provides:
  - 13-SPIKE.md scenario simulation
  - Fallback baseline 50 for recommendation use case
  - Outlier and Settings persistence behavior decisions
affects: [phase-13, phase-14, recommendations, settings]
tech-stack:
  added: []
  patterns: []
key-files:
  created:
    - .planning/phases/13-adr-016-backend-foundation/13-SPIKE.md
  modified: []
key-decisions:
  - "Fallback baseline is 50."
  - "Outlier policy is none; rely on median robustness."
  - "Settings UI should always show both user value and recommendation with reference-only framing."
patterns-established: []
requirements-completed: [JOYMIG-02]
duration: 12 min
completed: 2026-05-19
---

# Phase 13 Plan 05: Monthly Joy Target Spike Summary

**Spike simulation set the monthly Joy target fallback baseline to 50**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-19T04:44:00Z
- **Completed:** 2026-05-19T04:56:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Wrote `13-SPIKE.md` with five representative monthly scenarios and computed cumulative Joy contribution values.
- Decided the fallback baseline as `50`, inside ADR-016's [30, 100] candidate range.
- Documented the no-outlier-trimming policy and the always-show dual display behavior for Phase 14 Settings UI.

## Task Commits

1. **Task 1: Run demo-data simulation and write 13-SPIKE.md** - `73cd6f1` (docs)

## Files Created/Modified

- `.planning/phases/13-adr-016-backend-foundation/13-SPIKE.md` - Spike report with scenarios, baseline, outlier policy, persistence behavior, and source-code anchors.

## Decisions Made

- Fallback baseline: `50`.
- Outlier policy: none; rely on median robustness.
- Recommendation persistence behavior: always-show dual display, reference-only framing.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 13-06 should embed `static const int _fallbackBaseline = 50;` in `GetMonthlyJoyTargetRecommendationUseCase`.

---
*Phase: 13-adr-016-backend-foundation*
*Completed: 2026-05-19*
