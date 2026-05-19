---
phase: 11-statistics-surface-for
plan: 04
subsystem: analytics-ui
tags: [widget, kpi, chrome, riverpod, flutter, statsui]

requires:
  - phase: 11-statistics-surface-for
    provides: Plan 11-03 analytics aggregate providers and trilingual ARB keys
provides:
  - TotalSpendingKpiTile with currency formatting and MoM delta rendering
  - JoyHeadlineKpiTile with sealed MetricResult dispatch and safe semantics
  - KpiMiniHeroStrip two-tile composer for Variant delta
  - MonthChipPicker AppBar chip with bounded bottom-sheet selection
  - AnalyticsScreenSectionHeader themed-group chrome
  - AnalyticsCardErrorState localized per-card error shell
affects: [11-statistics-surface-for, analytics-screen, statsui]

tech-stack:
  added: []
  patterns: [leaf Flutter widgets, Riverpod notifier consumption, localized widget tests]

key-files:
  created:
    - lib/features/analytics/presentation/widgets/total_spending_kpi_tile.dart
    - lib/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart
    - lib/features/analytics/presentation/widgets/kpi_mini_hero_strip.dart
    - lib/features/analytics/presentation/widgets/month_chip_picker.dart
    - lib/features/analytics/presentation/widgets/analytics_screen_section_header.dart
    - lib/features/analytics/presentation/widgets/analytics_card_error_state.dart
    - test/widget/features/analytics/presentation/widgets/total_spending_kpi_tile_test.dart
    - test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart
    - test/widget/features/analytics/presentation/widgets/kpi_mini_hero_strip_test.dart
    - test/widget/features/analytics/presentation/widgets/month_chip_picker_test.dart
  modified: []

key-decisions:
  - "MonthChipPicker accepts optional earliestMonth/currentMonth inputs so the leaf widget can enforce a bounded range without DAO access; it falls back to a 12-month window when no caller boundary is provided."
  - "KPI tile tints use existing theme-aware ledger tag backgrounds (context.wmSurvivalTagBg/context.wmSoulTagBg) and existing AppColors accents; no new color tokens were added."

patterns-established:
  - "KPI tiles receive Freezed aggregates directly and do not read DAOs or providers."
  - "Per-card error states render only ARB constants and never receive raw error objects."

requirements-completed: [STATSUI-03, STATSUI-07]

duration: 8min
completed: 2026-05-03
---

# Phase 11 Plan 04: KPI and Chrome Widget Summary

**Variant delta analytics chrome now has reusable KPI tiles, month picking, section headers, and safe per-card error UI.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-03T15:02:17Z
- **Completed:** 2026-05-03T15:10:05Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added the 総支出 KPI tile with `FormatterService.formatCurrency`, `AppTextStyles.amountLarge`, and increased/decreased/null MoM branches.
- Added the 悦己平均 KPI tile with one sealed `switch (report.avgSatisfaction)` dispatch, median coverage caption, Empty rendering, and safe semantic label.
- Added the `KpiMiniHeroStrip` Row composer with equal `Expanded` tiles in 総-left / 悦己-right order.
- Added `MonthChipPicker`, `AnalyticsScreenSectionHeader`, and `AnalyticsCardErrorState`.
- Added four focused widget test files covering KPI behavior and month picker interaction.

## Task Commits

Each TDD gate was committed atomically:

1. **Task 1 RED: KPI mini-hero widget tests** - `ed3b40e` (test)
2. **Task 1 GREEN: KPI mini-hero widgets** - `cc8c524` (feat)
3. **Task 2 RED: Month chip picker tests** - `0af3979` (test)
4. **Task 2 GREEN: analytics chrome widgets** - `bf70556` (feat)

**Plan metadata:** committed separately with this SUMMARY only.

## Files Created/Modified

- `lib/features/analytics/presentation/widgets/total_spending_kpi_tile.dart` - 総支出 KPI with amount formatting and MoM delta sub-line.
- `lib/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart` - 悦己平均 KPI with mean, median, coverage, Empty state, and safe semantics.
- `lib/features/analytics/presentation/widgets/kpi_mini_hero_strip.dart` - horizontal two-tile composer.
- `lib/features/analytics/presentation/widgets/month_chip_picker.dart` - AppBar chip and bottom-sheet month selection via `selectedMonthProvider.notifier.setMonth`.
- `lib/features/analytics/presentation/widgets/analytics_screen_section_header.dart` - `━ {label} ━` section chrome using the allowed `#374151` exception.
- `lib/features/analytics/presentation/widgets/analytics_card_error_state.dart` - localized retryable card error shell.
- `test/widget/features/analytics/presentation/widgets/total_spending_kpi_tile_test.dart` - amount, delta, null-subline, and typography coverage.
- `test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart` - Empty/Value, median coverage, and semantic label coverage.
- `test/widget/features/analytics/presentation/widgets/kpi_mini_hero_strip_test.dart` - ordering and equal weighting coverage.
- `test/widget/features/analytics/presentation/widgets/month_chip_picker_test.dart` - label, sheet, selection, and touch target coverage.

## Decisions Made

- Used `context.wmSurvivalTagBg` and `context.wmSoulTagBg` for ledger-tinted KPI backgrounds instead of adding new color tokens.
- Gave `MonthChipPicker` optional month-boundary constructor inputs so Plan 11-07 can pass an earliest transaction month later without this leaf widget crossing into data access.
- Kept directory-wide analyzer out of verification because concurrent Plan 11-05/11-06 work left unowned chart/story files in the same widget directory.

## Deviations from Plan

None - plan executed within the owned file set. The `MonthChipPicker` optional month-boundary parameters follow the plan's no-DAO leaf-widget constraint while preserving bounded picker behavior.

## Issues Encountered

- `flutter test` and `flutter analyze` printed existing pub advisory decode warnings: `FormatException: advisoriesUpdated must be a String`. Test/analyzer exits were green.
- The worktree had concurrent unowned Plan 11-05/11-06 files present during verification; they were not staged or edited.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. The picker fallback range is intentional behavior for callers that do not supply an earliest transaction month.

## Threat Flags

None. The new widgets introduce no network endpoints, auth paths, file access, storage, schema changes, or new trust boundaries.

## Security Notes

- T-Information-1: `AnalyticsCardErrorState` does not accept raw errors and contains no `error.toString()` call.
- T-Information-2: `JoyHeadlineKpiTile` semantics include only KPI label, value, and sample-size coverage; no transaction, merchant, category, or note strings flow into the label.

## Verification

- RED Task 1: `flutter test test/widget/features/analytics/presentation/widgets/total_spending_kpi_tile_test.dart test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart test/widget/features/analytics/presentation/widgets/kpi_mini_hero_strip_test.dart` failed because the KPI widget files did not exist.
- GREEN Task 1: same three widget tests passed with 11 tests.
- RED Task 2: `flutter test test/widget/features/analytics/presentation/widgets/month_chip_picker_test.dart` failed because `month_chip_picker.dart` did not exist.
- GREEN Task 2: `flutter test test/widget/features/analytics/presentation/widgets/month_chip_picker_test.dart` passed with 4 tests.
- Plan-level tests: `flutter test test/widget/features/analytics/presentation/widgets/total_spending_kpi_tile_test.dart test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart test/widget/features/analytics/presentation/widgets/kpi_mini_hero_strip_test.dart test/widget/features/analytics/presentation/widgets/month_chip_picker_test.dart` passed with 15 tests.
- Analyzer: `flutter analyze` over the six owned widget files and four owned test files reported `No issues found!`.
- Greps: no `Color(0xFF...)` literals exist in owned widget files except `AnalyticsScreenSectionHeader`'s allowed `Color(0xFF374151)` chrome; no `error.toString()` calls; no hardcoded `'JPY'` literals in widget code.

## Shared Tracking

Per Wave 2 orchestration instructions, this executor did not edit `.planning/STATE.md`, `.planning/ROADMAP.md`, or `.planning/REQUIREMENTS.md`.

## Next Phase Readiness

Plan 11-07 can compose these leaf widgets into `AnalyticsScreen` and pass selected-month data, currency code, locale, KPI aggregate inputs, retry callbacks, and optional month range boundaries.

## Self-Check: PASSED

- Found `.planning/phases/11-statistics-surface-for/11-04-SUMMARY.md`.
- Found all six owned widget files.
- Found all four owned widget test files.
- Found task commits `ed3b40e`, `cc8c524`, `0af3979`, and `bf70556`.
- Confirmed no `.planning/STATE.md`, `.planning/ROADMAP.md`, or `.planning/REQUIREMENTS.md` edits were made by this plan.

---
*Phase: 11-statistics-surface-for*
*Completed: 2026-05-03*
