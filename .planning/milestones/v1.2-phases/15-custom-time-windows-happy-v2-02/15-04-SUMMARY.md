---
phase: 15-custom-time-windows-happy-v2-02
plan: 04
subsystem: analytics-providers
tags: [flutter, riverpod, analytics, time-window, home-hero]
requires:
  - phase: 15-02
    provides: Freezed TimeWindow value object and inclusive range resolution
  - phase: 15-03
    provides: Analytics use cases migrated to validated startDate/endDate windows
provides:
  - SelectedTimeWindow Riverpod session-state provider
  - Analytics provider families keyed by explicit startDate/endDate windows
  - HomeHero provider calls pinned to current-calendar-month ranges
  - Legacy SelectedMonth provider and selectedMonthProvider references removed
affects: [phase-15, analytics-ui, home-hero, riverpod-codegen]
tech-stack:
  added: []
  patterns: [Riverpod generated notifier, date-window provider families, HomeHero month isolation]
key-files:
  created:
    - lib/features/analytics/presentation/providers/state_time_window.dart
    - lib/features/analytics/presentation/providers/state_time_window.g.dart
    - test/unit/features/analytics/presentation/providers/state_time_window_test.dart
  modified:
    - lib/features/analytics/presentation/providers/state_analytics.dart
    - lib/features/analytics/presentation/providers/state_analytics.g.dart
    - lib/features/analytics/presentation/providers/state_happiness.dart
    - lib/features/analytics/presentation/providers/state_happiness.g.dart
    - lib/features/analytics/presentation/screens/analytics_screen.dart
    - lib/features/analytics/presentation/widgets/month_chip_picker.dart
    - lib/features/home/presentation/screens/home_screen.dart
    - lib/features/home/presentation/screens/main_shell_screen.dart
    - lib/features/home/presentation/providers/state_shadow_books.dart
    - lib/features/home/presentation/providers/state_shadow_books.g.dart
    - test/unit/features/analytics/presentation/providers/analytics_providers_characterization_test.dart
key-decisions:
  - "SelectedTimeWindow remains default auto-dispose; MainShellScreen IndexedStack keeps tabs alive."
  - "HomeHero and home sync refresh use DateTime.now()-derived current-month ranges instead of selectedTimeWindowProvider."
  - "Legacy MonthChipPicker now bridges to SelectedTimeWindow month variants until Plan 05/06 replace the month-only UI."
patterns-established:
  - "Windowed Riverpod families take startDate/endDate directly and forward them unchanged to Plan 03 use cases."
  - "Home feature must not import state_time_window.dart or reference selectedTimeWindowProvider."
requirements-completed: [HAPPY-V2-02]
duration: 9 min
completed: 2026-05-19
---

# Phase 15 Plan 04: Provider Window Re-Key Summary

**SelectedTimeWindow session state plus start/end-date provider keys across Analytics and current-month HomeHero callers**

## Performance

- **Duration:** 9 min
- **Started:** 2026-05-19T12:57:02Z
- **Completed:** 2026-05-19T13:06:19Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments

- Added `SelectedTimeWindow` and generated `selectedTimeWindowProvider`, defaulting to the current calendar month.
- Deleted legacy `SelectedMonth` state and re-keyed Analytics/Happiness provider families from `(year, month)` to `(startDate, endDate)`.
- Updated HomeHero and shadow-book aggregation call sites to use current-calendar-month ranges without importing AnalyticsScreen window state.
- Migrated provider characterization tests and added focused `SelectedTimeWindow` unit coverage.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: failing SelectedTimeWindow provider tests** - `b810277` (test)
2. **Task 1 GREEN: SelectedTimeWindow and state_analytics provider re-key** - `1ed2b41` (feat)
3. **Task 2: Re-key state_happiness providers to windows** - `2f45558` (feat)
4. **Task 3: HomeHero current-month range callers and shadow aggregate re-key** - `74f51e6` (feat)

**Plan metadata:** committed after this summary and state tracking update.

## Files Created/Modified

- `lib/features/analytics/presentation/providers/state_time_window.dart` - New session-scoped time-window notifier.
- `lib/features/analytics/presentation/providers/state_time_window.g.dart` - Generated Riverpod provider for `selectedTimeWindowProvider`.
- `lib/features/analytics/presentation/providers/state_analytics.dart` - Removes `SelectedMonth`; re-keys monthly report and satisfaction distribution providers.
- `lib/features/analytics/presentation/providers/state_happiness.dart` - Re-keys four happiness providers and anchors empty family output to `endDate`.
- `lib/features/home/presentation/screens/home_screen.dart` - Passes current-month `startDate`/`endDate` to HomeHero providers.
- `lib/features/home/presentation/screens/main_shell_screen.dart` - Invalidates home providers with current-month ranges after sync/entry flows.
- `lib/features/home/presentation/providers/state_shadow_books.dart` - Re-keys `shadowAggregateProvider` to `startDate`/`endDate`.
- `test/unit/features/analytics/presentation/providers/state_time_window_test.dart` - Adds four SelectedTimeWindow behavior tests.

## Decisions Made

- Kept HomeHero structurally independent from AnalyticsScreen selection by computing month bounds inline in home files.
- Updated `MonthChipPicker` to write `TimeWindow.month(...)` as a compatibility bridge, avoiding any surviving `selectedMonthProvider` references before the selector UI replacement lands.
- Updated `MainShellScreen` even though it was outside the plan's `files_modified` list, because home analysis would otherwise fail on stale provider invalidation keys.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed stale selectedMonth consumers outside provider files**
- **Found during:** Task 1 acceptance criteria
- **Issue:** `analytics_screen.dart` and `month_chip_picker.dart` still referenced `selectedMonthProvider`, causing the required legacy-purge grep to fail after `SelectedMonth` deletion.
- **Fix:** Switched both consumers to `selectedTimeWindowProvider`; month-only UI writes `TimeWindow.month(...)` until the full selector lands.
- **Files modified:** `lib/features/analytics/presentation/screens/analytics_screen.dart`, `lib/features/analytics/presentation/widgets/month_chip_picker.dart`
- **Verification:** `! rg -n 'selectedMonthProvider|class SelectedMonth' lib/`
- **Committed in:** `1ed2b41`

**2. [Rule 3 - Blocking] Updated Home shell invalidation keys**
- **Found during:** Task 3 home analysis
- **Issue:** `MainShellScreen` invalidated home providers using stale `(year, month)` keys after the provider families were re-keyed.
- **Fix:** Added current-month range construction in both sync-completion and entry-return refresh paths.
- **Files modified:** `lib/features/home/presentation/screens/main_shell_screen.dart`
- **Verification:** `flutter analyze lib/features/home/`
- **Committed in:** `74f51e6`

---

**Total deviations:** 2 auto-fixed (2 blocking).
**Impact on plan:** No behavior scope expansion; both fixes were required to keep the provider graph coherent after deleting the legacy month provider.

## Known Stubs

- `lib/features/home/presentation/screens/home_screen.dart:232` - Pre-existing `TODO` for future GroupBar wiring; unrelated to time-window provider migration.
- `lib/features/home/presentation/screens/home_screen.dart:261` - Pre-existing `TODO` for full transaction-list navigation; unrelated to time-window provider migration.

## Issues Encountered

- `build_runner` continues to warn that `--delete-conflicting-outputs` is ignored by the current toolchain; generation still completed cleanly.
- `state_time_window_test.dart` emits the existing Drift multiple-database debug warning from `createTestProviderScope()`, but all four provider tests pass.

## Verification

- RED confirmed: `flutter test test/unit/features/analytics/presentation/providers/state_time_window_test.dart` failed before implementation because `state_time_window.dart` did not exist.
- `flutter pub run build_runner build --delete-conflicting-outputs` completed successfully.
- `flutter analyze lib/features/analytics/presentation/providers/ lib/features/home/` reported `No issues found!`.
- `flutter test test/unit/features/analytics/presentation/providers/state_time_window_test.dart test/unit/features/analytics/presentation/providers/analytics_providers_characterization_test.dart` passed 7 tests.
- `! rg -n 'selectedMonthProvider|class SelectedMonth' lib/` passed.
- `! rg -n 'state_time_window|selectedTimeWindowProvider' lib/features/home/` passed.
- `! rg -n 'required int year' lib/features/analytics/presentation/providers/state_analytics.dart lib/features/analytics/presentation/providers/state_happiness.dart` passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 05 can replace the month-only chip UI with the full week/month/quarter/year/custom selector on top of `selectedTimeWindowProvider`. Plan 06 can complete AnalyticsScreen card wiring and add the HomeHero isolation locking test.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/15-custom-time-windows-happy-v2-02/15-04-SUMMARY.md`.
- All four plan commits were found in `git log --all`: `b810277`, `1ed2b41`, `2f45558`, `74f51e6`.
- Final verification commands passed and the working tree had only this new summary before state tracking updates.

---
*Phase: 15-custom-time-windows-happy-v2-02*
*Completed: 2026-05-19*
