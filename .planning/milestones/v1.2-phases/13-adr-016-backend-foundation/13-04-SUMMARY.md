---
phase: 13-adr-016-backend-foundation
plan: 04
subsystem: analytics
tags: [joy-contribution, happiness-report, dao, ptvf]
requires:
  - phase: 13-02
    provides: formatJoyCumulative and ptvfBaseFor in joy_cumulative_formatter.dart
provides:
  - HappinessReport.joyContribution model field
  - Σ joy_contribution fold in GetHappinessReportUseCase
  - getSoulRowsForJoyContribution DAO/repository query surface
affects: [phase-13, phase-14, phase-17, analytics, home-hero]
tech-stack:
  added: []
  patterns:
    - Dart-layer PTVF contribution fold without amount denominator
key-files:
  created: []
  modified:
    - lib/features/analytics/domain/models/happiness_report.dart
    - lib/features/analytics/domain/models/happiness_report.freezed.dart
    - lib/application/analytics/get_happiness_report_use_case.dart
    - lib/data/daos/analytics_dao.dart
    - lib/features/analytics/domain/repositories/analytics_repository.dart
    - lib/data/repositories/analytics_repository_impl.dart
    - test/unit/application/analytics/get_happiness_report_use_case_test.dart
    - test/unit/features/analytics/domain/models/happiness_report_test.dart
    - test/helpers/happiness_test_fixtures.dart
key-decisions:
  - "HappinessReport keeps MetricResult<double> precision and exposes joyContribution instead of joyPerYen."
  - "The core fold sums soul_satisfaction * pow(amount/base, 0.88) directly with no Σamount denominator."
patterns-established:
  - "Repository query names now describe Joy contribution rather than PTVF density."
requirements-completed: [JOYMIG-02, JOYMIG-05]
duration: 31 min
completed: 2026-05-19
---

# Phase 13 Plan 04: Backend Joy Contribution Migration Summary

**Happiness backend now returns cumulative Joy contribution instead of Joy/yen density**

## Performance

- **Duration:** 31 min
- **Started:** 2026-05-19T04:13:00Z
- **Completed:** 2026-05-19T04:44:00Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments

- Renamed `HappinessReport.joyPerYen` to `joyContribution` and regenerated Freezed output.
- Rewrote `GetHappinessReportUseCase` to compute `Σ(soul_satisfaction * pow(amount/base, 0.88))` without dividing by total amount.
- Renamed the row query surface to `getSoulRowsForJoyContribution` and removed the backend daily PTVF row query.

## Task Commits

1. **Task 1: Rename HappinessReport.joyPerYen -> joyContribution + regen + fixture update** - `9cc1a02` (refactor)
2. **Task 2: Rewrite GetHappinessReportUseCase fold to Σ joy_contribution + DAO call rename** - `b392c5e` (refactor)
3. **Task 3: Rename DAO method + delete getDailySoulRowsForPtvf + mirror through repository** - `6f4bcd1` (refactor)

## Files Created/Modified

- `lib/features/analytics/domain/models/happiness_report.dart` - Renamed cumulative Joy metric field.
- `lib/features/analytics/domain/models/happiness_report.freezed.dart` - Regenerated model output.
- `lib/application/analytics/get_happiness_report_use_case.dart` - Cumulative Joy contribution fold.
- `lib/data/daos/analytics_dao.dart` - Renamed monthly row query and removed daily query.
- `lib/features/analytics/domain/repositories/analytics_repository.dart` - Renamed repository contract.
- `lib/data/repositories/analytics_repository_impl.dart` - Renamed DAO delegation.
- `test/unit/application/analytics/get_happiness_report_use_case_test.dart` - Updated cumulative formula assertions.
- `test/unit/features/analytics/domain/models/happiness_report_test.dart` - Updated model construction.
- `test/helpers/happiness_test_fixtures.dart` - Updated fixture magnitudes and field names.
- `test/unit/data/daos/analytics_dao_happiness_test.dart` - Updated renamed DAO query usage.
- `test/unit/data/repositories/analytics_repository_happiness_test.dart` - Updated renamed repository query usage.
- `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart` - Updated test mock method name for the renamed repository API.

## Decisions Made

None - followed the plan's recommended `joyContribution` field name and `MetricResult<double>` type.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Updated backend DAO/repository tests for renamed query**
- **Found during:** Task 3
- **Issue:** The plan listed backend source files but the existing DAO/repository tests also referenced `getSoulRowsForPtvf`.
- **Fix:** Updated those tests to `getSoulRowsForJoyContribution` so the targeted backend test suite stays coherent.
- **Files modified:** `test/unit/data/daos/analytics_dao_happiness_test.dart`, `test/unit/data/repositories/analytics_repository_happiness_test.dart`
- **Verification:** `flutter test test/unit/data/repositories/analytics_repository_happiness_test.dart test/unit/data/daos/analytics_dao_happiness_test.dart`
- **Committed in:** `6f4bcd1`

**Total deviations:** 1 auto-fixed (missing critical test update).
**Impact on plan:** No scope expansion beyond the rename surface; test coverage now matches the new API.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 3 can run the baseline spike using the live `_computeJoyContribution` formula and `ptvfBaseFor` map. Wave 5 still needs to repair remaining presentation references to `joyPerYen` and remove the daily-density feature.

---
*Phase: 13-adr-016-backend-foundation*
*Completed: 2026-05-19*
