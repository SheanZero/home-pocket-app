---
phase: 13-adr-016-backend-foundation
plan: 06
subsystem: analytics
tags: [recommendation, monthly-joy-target, riverpod, metric-result]
requires:
  - phase: 13-02
    provides: ptvfBaseFor currency bases
  - phase: 13-04
    provides: getSoulRowsForJoyContribution and Joy contribution fold
  - phase: 13-05
    provides: fallback baseline 50
provides:
  - GetMonthlyJoyTargetRecommendationUseCase
  - monthlyJoyTargetRecommendationProvider
  - getMonthlyJoyTargetRecommendationUseCaseProvider
affects: [phase-14, settings, home-hero]
tech-stack:
  added: []
  patterns:
    - MetricResult<int> recommendation use case with sparse-history Empty result
key-files:
  created:
    - lib/application/analytics/get_monthly_joy_target_recommendation_use_case.dart
    - test/unit/application/analytics/get_monthly_joy_target_recommendation_use_case_test.dart
  modified:
    - lib/features/analytics/presentation/providers/state_happiness.dart
    - lib/features/analytics/presentation/providers/state_happiness.g.dart
    - lib/features/analytics/presentation/providers/repository_providers.dart
    - lib/features/analytics/presentation/providers/repository_providers.g.dart
key-decisions:
  - "Recommendation returns Empty when fewer than three past complete months contain soul rows."
  - "Fallback baseline 50 is embedded as a static const for Phase 14 UI consumers."
patterns-established:
  - "Recommendation providers live with existing analytics use case and state_happiness providers."
requirements-completed: [JOYMIG-02]
duration: 29 min
completed: 2026-05-19
---

# Phase 13 Plan 06: Monthly Joy Target Recommendation Summary

**Monthly Joy target recommendation use case computes ceil median of past 3 monthly Joy contribution sums**

## Performance

- **Duration:** 29 min
- **Started:** 2026-05-19T04:56:00Z
- **Completed:** 2026-05-19T05:25:00Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added `GetMonthlyJoyTargetRecommendationUseCase` returning `MetricResult<int>`.
- Covered median, sparse-history Empty, all-zero rows, ceil boundary, CNY base, and year-boundary sampling cases.
- Wired generated Riverpod providers for use case construction and presentation-state access.

## Task Commits

1. **Task 1: Write recommendation use case unit test (RED)** - `ecf4ddd` (test)
2. **Task 2: Implement GetMonthlyJoyTargetRecommendationUseCase (GREEN)** - `4e45ddf` (feat)
3. **Task 3: Wire Riverpod providers + regen** - `5416b1f` (feat)

## Files Created/Modified

- `lib/application/analytics/get_monthly_joy_target_recommendation_use_case.dart` - Recommendation algorithm and fallback baseline constant.
- `test/unit/application/analytics/get_monthly_joy_target_recommendation_use_case_test.dart` - Behavioral test coverage.
- `lib/features/analytics/presentation/providers/state_happiness.dart` - `monthlyJoyTargetRecommendation` provider.
- `lib/features/analytics/presentation/providers/state_happiness.g.dart` - Generated provider output.
- `lib/features/analytics/presentation/providers/repository_providers.dart` - Use case provider.
- `lib/features/analytics/presentation/providers/repository_providers.g.dart` - Generated provider output.

## Decisions Made

None - followed the spike baseline and plan-specified sparse-history behavior.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 14 can consume `monthlyJoyTargetRecommendationProvider`, while Wave 5 can finish the density rip and repair presentation call sites.

---
*Phase: 13-adr-016-backend-foundation*
*Completed: 2026-05-19*
