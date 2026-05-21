---
phase: 15-custom-time-windows-happy-v2-02
plan: "06"
subsystem: analytics-ui
tags:
  - flutter
  - riverpod
  - analytics
  - time-window
  - widget-tests
  - verification
requires:
  - 15-05
provides:
  - analytics-screen-time-window-chip
  - analytics-refresh-windowed-provider-keys
  - home-hero-time-window-isolation-guard
  - retired-delta-ui-regression-tests
affects:
  - lib/features/analytics/presentation/screens/analytics_screen.dart
  - lib/application/analytics/_time_window_validation.dart
  - test/widget/features/analytics/presentation/screens/analytics_screen_test.dart
  - test/widget/features/home/presentation/screens/home_screen_isolation_test.dart
tech_stack:
  added: []
  patterns:
    - Riverpod generated family providers keyed by DateTime windows
    - TimeWindowChip shared analytics window selector
    - Widget-level guardrail tests plus static source assertions
key_files:
  created:
    - test/widget/features/analytics/presentation/screens/analytics_no_delta_ui_test.dart
    - test/widget/features/home/presentation/screens/home_screen_isolation_test.dart
  modified:
    - lib/application/analytics/_time_window_validation.dart
    - lib/features/analytics/presentation/screens/analytics_screen.dart
    - test/unit/application/analytics/time_window_validation_test.dart
    - test/unit/features/analytics/presentation/providers/analytics_providers_characterization_test.dart
    - test/unit/features/analytics/presentation/providers/repository_providers_test.dart
    - test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart
    - test/widget/features/analytics/presentation/screens/analytics_no_delta_ui_test.dart
    - test/widget/features/analytics/presentation/screens/analytics_screen_test.dart
    - test/widget/features/analytics/presentation/widgets/total_spending_kpi_tile_test.dart
    - test/widget/features/home/presentation/screens/home_screen_isolation_test.dart
    - test/widget/features/home/presentation/screens/home_screen_test.dart
  deleted:
    - lib/features/analytics/presentation/widgets/month_chip_picker.dart
    - test/widget/features/analytics/presentation/widgets/month_chip_picker_test.dart
decisions:
  - Plan 06 replaced the AnalyticsScreen month picker with TimeWindowChip and purged MonthChipPicker/selectedMonthProvider symbols.
  - AnalyticsScreen refresh stays scoped to analytics/shadow-book providers keyed by selected TimeWindow ranges and never invalidates HomeHero providers.
  - TimeWindowValidation permits canonical current calendar preset windows while still rejecting arbitrary future custom ranges.
requirements_completed:
  - HAPPY-V2-02
metrics:
  started_at: 2026-05-19T13:25:48Z
  completed_at: 2026-05-19T13:50:14Z
  duration: 24m26s
  tasks_completed: 3
  files_changed: 13
---

# Phase 15 Plan 06: AnalyticsScreen Time-Window Integration Summary

AnalyticsScreen now uses the shared TimeWindow selector end to end, with legacy month-picker and delta UI regressions locked out by widget and static guard tests.

## What Changed

- Replaced the AnalyticsScreen AppBar month picker with `TimeWindowChip(locale: locale, earliestData: earliestMonthAsync.value)`.
- Re-keyed AnalyticsScreen report, trend, family, shadow-book, and refresh paths to selected `TimeWindow` date ranges.
- Deleted the legacy `MonthChipPicker` widget and test.
- Added HomeScreen isolation coverage proving HomeHero remains current-month anchored even when AnalyticsScreen's selected window is a prior year.
- Added AnalyticsScreen no-delta UI coverage across month, year, quarter, week, and custom windows.
- Migrated downstream tests to the Phase 15 windowed provider signatures and retired the stale MoM KPI expectations.

## Task Commits

| Task | Commit | Summary |
| ---- | ------ | ------- |
| 1 | `67f42c3` | Wired AnalyticsScreen to `selectedTimeWindowProvider`/`TimeWindowChip`, re-keyed refresh invalidations, deleted `MonthChipPicker`, and migrated the primary screen test. |
| 2 | `1345d6c` | Added HomeHero isolation and AnalyticsScreen no-delta guardrail tests. |
| 3 | `156fac7` | Completed verification cleanup, migrated stale tests to windowed provider keys, and added refresh coverage. |

## Verification

- `flutter pub run build_runner build --delete-conflicting-outputs` passed; build_runner reported that the option is now ignored.
- `flutter gen-l10n` passed.
- `flutter analyze` passed with 0 issues.
- `flutter test -r expanded` passed: `+1505: All tests passed!`
- `flutter test --coverage -r expanded` passed: `+1506: All tests passed!`
- `dart run scripts/coverage_gate.dart --lcov coverage/lcov.info --threshold 70 lib/application/analytics/_time_window_validation.dart lib/features/analytics/presentation/screens/analytics_screen.dart` passed:
  - `_time_window_validation.dart`: 90.48%
  - `analytics_screen.dart`: 78.02%
- Grep gates passed with no matches for:
  - `MonthChipPicker|selectedMonthProvider|month_chip_picker`
  - `analyticsKpiTotalDeltaIncreased|analyticsKpiTotalDeltaDecreased|analyticsMonthChipPickerTooltip`
  - `state_time_window|selectedTimeWindowProvider` under `lib/features/home/`
  - `_MomDeltaSubLine`
  - `analyticsKpiTotalDelta` under `lib/generated/`
  - `homeMonthlyReport|homeHappiness|homeBestJoy` inside `analytics_screen.dart`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Allowed canonical current calendar windows in validation**
- **Found during:** Task 1
- **Issue:** `TimeWindowValidation.assertValid` rejected the default current month/year because preset calendar windows end in the future relative to today.
- **Fix:** Allowed canonical week/month/quarter/year windows whose range contains `now`, while preserving rejection of arbitrary future custom windows.
- **Files modified:** `lib/application/analytics/_time_window_validation.dart`, `test/unit/application/analytics/time_window_validation_test.dart`
- **Commit:** `67f42c3`

**2. [Rule 3 - Blocking verification] Migrated stale tests to windowed provider contracts**
- **Found during:** Task 3
- **Issue:** Full-suite analysis and tests exposed characterization/widget tests still using retired `(year, month)` provider keys or expecting retired MoM delta UI.
- **Fix:** Updated those tests to use `startDate`/`endDate` keys, locked KPI delta retirement expectations, added library annotations for VM-only file-read tests, and added refresh coverage for AnalyticsScreen invalidation.
- **Files modified:** `test/unit/features/analytics/presentation/providers/*`, `test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart`, `test/widget/features/analytics/presentation/*`, `test/widget/features/home/presentation/screens/*`
- **Commit:** `156fac7`

## Auth Gates

None.

## Known Stubs

None.

## Threat Flags

None.

## Notes

- Coverage commands needed escalated execution because the Flutter SDK cache attempted to update `engine.stamp` outside the writable workspace.
- The deleted `MonthChipPicker` files are intentional and complete the legacy picker purge.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/15-custom-time-windows-happy-v2-02/15-06-SUMMARY.md`.
- Task commits found: `67f42c3`, `1345d6c`, `156fac7`.
- Stub scan found only legitimate test nullable/error assertions; no user-facing stubs were introduced.
