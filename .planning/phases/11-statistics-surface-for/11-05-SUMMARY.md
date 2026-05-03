---
phase: 11-statistics-surface-for
plan: 05
subsystem: ui
tags: [analytics, charts, fl_chart, statsui, widget]

requires:
  - phase: 11-statistics-surface-for
    provides: Plan 11-03 application use cases, providers, ARB keys, and DailyJoyPerYenPoint model
provides:
  - MonthlySpendTrendBarChart for 6-month total-spending trend
  - JoyTrendLineChart with baseline-anchored gap segmentation
  - CategorySpendDonutChart with top-N plus Other grouping
  - SatisfactionDistributionHistogram with all-10 score normalization and bar-5 annotation
affects: [11-statistics-surface-for, analytics-screen, charts, statsui]

tech-stack:
  added: []
  patterns: [pure StatelessWidget chart inputs, fl_chart introspection tests]

key-files:
  created:
    - lib/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart.dart
    - lib/features/analytics/presentation/widgets/joy_trend_line_chart.dart
    - lib/features/analytics/presentation/widgets/category_spend_donut_chart.dart
    - lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart
    - test/widget/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart_test.dart
    - test/widget/features/analytics/presentation/widgets/joy_trend_line_chart_test.dart
    - test/widget/features/analytics/presentation/widgets/category_spend_donut_chart_test.dart
    - test/widget/features/analytics/presentation/widgets/satisfaction_distribution_histogram_test.dart
    - .planning/phases/11-statistics-surface-for/11-05-SUMMARY.md
  modified: []

key-decisions:
  - "JoyTrendLineChart models missing days as gaps by splitting points into multiple LineChartBarData segments."
  - "SatisfactionDistributionHistogram renders score 5 annotation as a stable caption fallback instead of relying on unavailable fl_chart bar-label API."

patterns-established:
  - "Chart widgets consume aggregate/model inputs only; no provider or DAO reads inside widgets."
  - "Widget tests introspect fl_chart data objects for behavioral contracts that are hard to assert visually."

requirements-completed: [STATSUI-01, STATSUI-02, STATSUI-06]

duration: 54min
completed: 2026-05-03
---

# Phase 11 Plan 05: Analytics Chart Widgets Summary

**Variant δ now has four pure chart widgets for time and distribution analytics: spending bars, Joy/¥ segmented line, category donut, and satisfaction histogram.**

## Performance

- **Duration:** 54 min
- **Started:** 2026-05-03T15:01:00Z
- **Completed:** 2026-05-03T15:55:00Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Added `MonthlySpendTrendBarChart` with selected-month survival highlight and compact Y-axis labels.
- Added `JoyTrendLineChart` with `minY: 0`, multi-segment gap rendering, currency-aware Joy/¥ labels, and neutral semantics.
- Added `CategorySpendDonutChart` with top-N slices plus localized Other grouping.
- Added `SatisfactionDistributionHistogram` with all 10 score bars, 1px stubs for missing scores, bar-5 annotation, ordinal color caption, and neutral semantics.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: time chart widget tests** - `f40b873` (test)
2. **Task 1 GREEN: time-series chart widgets** - `ef0ac25` (feat)
3. **Task 2: distribution chart widgets and tests** - `61c6543` (feat)

**Plan metadata:** committed separately with this SUMMARY/tracking update.

## Files Created/Modified

- `lib/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart.dart` - 6-month spending BarChart.
- `lib/features/analytics/presentation/widgets/joy_trend_line_chart.dart` - Joy/¥ MTD LineChart with gap segmentation.
- `lib/features/analytics/presentation/widgets/category_spend_donut_chart.dart` - Category spending donut with top-N plus Other.
- `lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart` - 1-10 satisfaction histogram.
- `test/widget/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart_test.dart` - Bar count, highlight, compact-label coverage.
- `test/widget/features/analytics/presentation/widgets/joy_trend_line_chart_test.dart` - Empty, baseline, segmentation, formatter, semantic coverage.
- `test/widget/features/analytics/presentation/widgets/category_spend_donut_chart_test.dart` - Donut and legend coverage.
- `test/widget/features/analytics/presentation/widgets/satisfaction_distribution_histogram_test.dart` - Normalization, annotation/caption, semantic coverage.

## Decisions Made

- Used `Color.lerp` from `AppColors.survival` to `AppColors.soul`/`accentPrimary` for chart palettes instead of inline literals.
- Rendered histogram score-5 annotation as a stable caption under the chart because `fl_chart` 0.69 does not provide a direct per-rod label API matching the plan assumption.
- Kept Empty JoyTrendLineChart rendering as a fixed-height placeholder; the joint thin-sample fallback is owned by Plan 11-06.

## Deviations from Plan

Plan 11-05's initial worker stalled after a RED commit and partial Task 1 edits. The orchestrator shut it down, verified its partial work, committed the recovered Task 1 implementation, then completed Task 2 inline.

**Total deviations:** 1 process recovery, 1 chart-label API fallback.
**Impact on plan:** No requirement scope was dropped.

## Issues Encountered

- Flutter commands continued to print the known pub advisory decode warning, but tests/analyzer completed successfully.
- The first donut test expected a standalone `Other` text node; the actual legend contract is `Other 10%`, so the assertion was corrected to `textContaining('Other')`.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. The chart widgets do not render merchant/note strings and the histogram semantic labels use neutral factual wording only.

## Verification

- `flutter test test/widget/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart_test.dart test/widget/features/analytics/presentation/widgets/joy_trend_line_chart_test.dart` passed with 8 tests.
- `flutter test test/widget/features/analytics/presentation/widgets/category_spend_donut_chart_test.dart test/widget/features/analytics/presentation/widgets/satisfaction_distribution_histogram_test.dart` passed with 5 tests.
- Full Plan 11-05 widget test command passed with 13 tests.
- `flutter analyze` over the 4 chart widgets and 4 chart tests reported `No issues found`.
- `rg "Color\\(0x|['\"]JPY['\"]|差|悪い|bad|不好|低|不満|sad"` over the 4 chart widgets found no matches.

## Next Phase Readiness

Plan 11-07 can compose these widgets into the Variant δ AnalyticsScreen after Plan 11-04 and Plan 11-06 widgets are available.

## Self-Check: PASSED

- Found all 4 chart widget files.
- Found all 4 chart widget test files.
- Found task commits `f40b873`, `ef0ac25`, and `61c6543`.
- Tests and analyzer scope passed.

---
*Phase: 11-statistics-surface-for*
*Completed: 2026-05-03*
