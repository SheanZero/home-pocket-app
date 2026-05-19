---
phase: 15-custom-time-windows-happy-v2-02
plan: 05
subsystem: analytics-ui
tags: [flutter, riverpod, analytics, time-window, i18n, widget-tests]
requires:
  - phase: 15-02
    provides: Freezed TimeWindow value object and inclusive range resolution
  - phase: 15-04
    provides: selectedTimeWindowProvider session state and windowed Analytics provider keys
provides:
  - TimeWindowChip AppBar selector surface for week, month, quarter, year, and custom labels
  - TimeWindowPickerSheet type-row chooser with week/month/quarter/year lists and custom date-range picker
  - Localized SnackBar validation for inverted, future, and over-12-month custom ranges
  - FormatterService short month-day delegate used by presentation widgets
affects: [phase-15, analytics-screen, time-window-selector, i18n]
tech-stack:
  added: []
  patterns: [FormatterService date-label delegation, TimeWindow presentation switch, typed showModalBottomSheet result, test-injected date-range picker seam]
key-files:
  created:
    - lib/features/analytics/presentation/widgets/time_window_chip.dart
    - lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart
    - test/widget/features/analytics/presentation/widgets/time_window_chip_test.dart
    - test/widget/features/analytics/presentation/widgets/time_window_picker_sheet_test.dart
  modified:
    - lib/application/i18n/formatter_service.dart
    - test/unit/infrastructure/i18n/formatters/date_formatter_test.dart
key-decisions:
  - "FormatterService gained a pass-through for the already-existing DateFormatter.formatShortMonthDay method so presentation widgets stay out of infrastructure."
  - "Custom-range tests use a past range relative to 2026-05-19 so D-07 future-date rejection remains true."
  - "TimeWindowPickerSheet uses isScrollControlled modal height to avoid bottom-sheet overflow with the type row and 360px chooser body."
patterns-established:
  - "TimeWindow UI labels compose ARB placeholders with existing FormatterService date methods; no DateFormat usage inside selector widgets."
  - "TimeWindowPickerSheet returns a typed TimeWindow from showModalBottomSheet and commits through selectedTimeWindowProvider only after the modal closes."
requirements-completed: [HAPPY-V2-02]
duration: 12 min
completed: 2026-05-19
---

# Phase 15 Plan 05: Time-Window Selector Surface Summary

**Analytics time-window chip and bottom sheet with localized labels, custom range validation, and focused widget coverage**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-19T13:09:41Z
- **Completed:** 2026-05-19T13:21:52Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added `TimeWindowChip`, reading `selectedTimeWindowProvider` and rendering all five `TimeWindow` variants through ARB placeholders plus `FormatterService`.
- Added `TimeWindowPickerSheet`, with Week / Month / Quarter / Year / Custom type-row navigation, typed list selection, and a `showDateRangePicker` custom flow.
- Added localized SnackBar validation for inverted custom ranges, ranges over 12 calendar months, and future end dates.
- Locked formatter contracts and widget behavior with 38 focused tests across formatter, chip, and sheet files.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: formatter date-label contract tests** - `fdd8d03` (test)
2. **Task 1 GREEN: FormatterService short month-day delegate** - `1c3054b` (feat)
3. **Task 2 RED: TimeWindowChip widget tests** - `52ef455` (test)
4. **Task 2 GREEN: TimeWindowChip implementation** - `4deac59` (feat)
5. **Task 3 RED: TimeWindowPickerSheet widget tests** - `8e51469` (test)
6. **Task 3 GREEN: TimeWindowPickerSheet implementation** - `c5825f7` (feat)

**Plan metadata:** committed after this summary and state tracking update.

## Files Created/Modified

- `lib/application/i18n/formatter_service.dart` - Adds `formatShortMonthDay` pass-through to the existing `DateFormatter` method.
- `lib/features/analytics/presentation/widgets/time_window_chip.dart` - New AppBar selector chip with exhaustive `TimeWindow` label switch and 44px minimum hit target.
- `lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart` - New bottom sheet with type row, preset list bodies, custom date-range picker seam, and localized validation SnackBars.
- `test/unit/infrastructure/i18n/formatters/date_formatter_test.dart` - Adds smoke tests for `formatShortMonthDay` and FormatterService delegation.
- `test/widget/features/analytics/presentation/widgets/time_window_chip_test.dart` - Adds eight chip widget tests for labels, override pattern, touch target, and tap handler.
- `test/widget/features/analytics/presentation/widgets/time_window_picker_sheet_test.dart` - Adds twelve sheet widget tests for type switching, list commit, custom validation, ja quarter parity, and backdrop cancel.

## Decisions Made

- Added a `FormatterService.formatShortMonthDay` delegate despite the plan describing it as pre-existing, because selector widgets must not import infrastructure formatters directly.
- Kept English short-date labels aligned with existing `DateFormatter` behavior (`May 11`, `Mar 15`) rather than inventing slash-form labels in presentation code.
- Used `isScrollControlled: true` on the modal bottom sheet after tests exposed a default-height overflow.
- Adjusted the custom valid-range test away from the plan's `2026-07-20` example because the execution date is 2026-05-19 and D-07 correctly treats that end date as future.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added missing FormatterService short month-day delegate**
- **Found during:** Task 1 (formatter smoke tests)
- **Issue:** The plan assumed `FormatterService.formatShortMonthDay` already existed, but only `DateFormatter.formatShortMonthDay` existed. Without the service delegate, new presentation widgets would need to import infrastructure directly or duplicate formatting logic.
- **Fix:** Added a minimal pass-through method to `FormatterService`.
- **Files modified:** `lib/application/i18n/formatter_service.dart`
- **Verification:** `flutter test test/unit/infrastructure/i18n/formatters/date_formatter_test.dart`; `flutter analyze lib/infrastructure/i18n/formatters/date_formatter.dart lib/application/i18n/formatter_service.dart`
- **Committed in:** `1c3054b`

**2. [Rule 3 - Blocking] Added sheet entry point during chip implementation**
- **Found during:** Task 2 (TimeWindowChip implementation)
- **Issue:** `TimeWindowChip` must call `TimeWindowPickerSheet.show`, so the chip could not compile in isolation without the sheet file.
- **Fix:** Added the public sheet entry point in the Task 2 commit, then replaced it with the full bottom-sheet implementation in Task 3.
- **Files modified:** `lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart`
- **Verification:** `flutter test test/widget/features/analytics/presentation/widgets/time_window_chip_test.dart`; final sheet tests passed after Task 3.
- **Committed in:** `4deac59`, completed in `c5825f7`

**3. [Rule 1 - Bug] Fixed bottom-sheet height overflow**
- **Found during:** Task 3 widget verification
- **Issue:** Flutter's default bottom-sheet height constrained the type row plus chooser body to half the viewport, causing RenderFlex overflow in tests.
- **Fix:** Set `isScrollControlled: true` on `showModalBottomSheet<TimeWindow>`.
- **Files modified:** `lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart`
- **Verification:** `flutter test test/widget/features/analytics/presentation/widgets/time_window_picker_sheet_test.dart`
- **Committed in:** `c5825f7`

---

**Total deviations:** 3 auto-fixed (1 missing critical, 1 blocking, 1 bug).
**Impact on plan:** No feature scope expansion. The fixes were required to preserve architecture boundaries, keep task commits buildable, and avoid selector layout overflow.

## Known Stubs

None - no intentional stubs remain in created or modified files. The null checks in the sheet and tests are real control flow, not placeholder data.

## Issues Encountered

- Running Flutter analyzer in parallel with Flutter tests triggered the normal Flutter startup lock; the queued command completed successfully after the first Flutter command released the lock.
- The real `DateTimeRange` constructor asserts `start <= end`, so the inverted-range test uses a test-only subclass with a valid super-constructor range and an overridden `start` getter to exercise the defensive branch.

## Verification

- `flutter analyze lib/features/analytics/presentation/widgets/time_window_chip.dart lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart` - passed, 0 issues.
- `flutter analyze lib/infrastructure/i18n/formatters/date_formatter.dart lib/application/i18n/formatter_service.dart` - passed, 0 issues.
- `flutter test test/unit/infrastructure/i18n/formatters/date_formatter_test.dart test/widget/features/analytics/presentation/widgets/time_window_chip_test.dart test/widget/features/analytics/presentation/widgets/time_window_picker_sheet_test.dart` - passed, 38 tests.
- `grep -rn 'DateFormat(' lib/features/analytics/presentation/widgets/time_window_chip.dart lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart` - returned 0 matches.
- `grep -rn 'formatYear\|formatQuarter' lib/infrastructure/i18n/formatters/date_formatter.dart lib/application/i18n/formatter_service.dart` - returned 0 matches.
- `grep -n 'vs\|delta\|compare' lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart | grep -v '^.*//.*'` - returned 0 matches.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 06 can wire `TimeWindowChip` into `AnalyticsScreen`, remove `MonthChipPicker`, and re-key refresh/integration tests around the active time window. The selector widget and sheet are isolated and covered, with localized ja quarter rendering and custom-range validation already locked.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/15-custom-time-windows-happy-v2-02/15-05-SUMMARY.md`.
- All six plan commits were found in `git log --all`: `fdd8d03`, `1c3054b`, `52ef455`, `4deac59`, `8e51469`, `c5825f7`.
- Final verification commands passed and no generated/runtime files were left untracked.

---
*Phase: 15-custom-time-windows-happy-v2-02*
*Completed: 2026-05-19*
