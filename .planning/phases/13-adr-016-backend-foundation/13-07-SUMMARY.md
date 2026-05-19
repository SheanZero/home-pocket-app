---
phase: 13-adr-016-backend-foundation
plan: 07
subsystem: analytics
tags: [density-removal, joy-contribution, home-hero, analytics-screen, goldens]
requires:
  - phase: 13-04
    provides: HappinessReport.joyContribution and cumulative fold
  - phase: 13-06
    provides: monthly Joy target recommendation providers
provides:
  - density code path deletion
  - AnalyticsScreen histogram gate rewired to totalSoulTx
  - HomeHero cumulative Joy contribution call sites
affects: [phase-14, analytics, home-hero]
tech-stack:
  added: []
  patterns:
    - "Deleted daily-density providers and UI instead of keeping compatibility shims."
    - "HomeHero ARB keys intentionally remain pre-Phase-14 names while backend field/formatter references move to cumulative Joy."
key-files:
  deleted:
    - lib/application/analytics/get_daily_joy_per_yen_use_case.dart
    - lib/features/analytics/domain/models/daily_joy_per_yen_point.dart
    - lib/features/analytics/domain/models/daily_joy_per_yen_point.freezed.dart
    - lib/features/analytics/presentation/widgets/joy_trend_line_chart.dart
    - test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart
    - test/unit/data/daos/analytics_dao_daily_joy_test.dart
    - test/widget/features/analytics/presentation/widgets/joy_trend_line_chart_test.dart
  modified:
    - lib/features/analytics/presentation/screens/analytics_screen.dart
    - lib/features/analytics/presentation/providers/state_happiness.dart
    - lib/features/analytics/presentation/providers/state_happiness.g.dart
    - lib/features/analytics/presentation/providers/repository_providers.dart
    - lib/features/analytics/presentation/providers/repository_providers.g.dart
    - lib/features/home/presentation/widgets/home_hero_card.dart
    - test/golden/goldens/home_hero_card_all_neutral_cta_ja.png
    - test/golden/goldens/home_hero_card_single_light_ja.png
    - test/golden/goldens/home_hero_card_thin_sample_ja.png
key-decisions:
  - "Removed the Analytics Joy trend section entirely; no placeholder or compatibility widget remains."
  - "Preserved HomeHero's Phase-13 visual shim and old ARB key names for Phase 14 reconciliation."
patterns-established:
  - "D-10 grep gates are the close criteria for retired density identifiers."
requirements-completed: [JOYMIG-05]
duration: 57 min
completed: 2026-05-19
---

# Phase 13 Plan 07: Density Rip Summary

**Daily density surfaces and providers were removed; HomeHero and AnalyticsScreen now consume cumulative Joy contribution**

## Performance

- **Completed:** 2026-05-19
- **Tasks:** 4
- **Files modified/deleted:** 15

## Accomplishments

- Deleted the daily Joy/yen use case, model, chart widget, providers, generated references, and obsolete tests.
- Removed the AnalyticsScreen Joy trend section and rewired the satisfaction histogram n<5 gate to `happinessReportProvider(...).totalSoulTx`.
- Migrated HomeHero call sites from `joyPerYen` / `formatJoyDensity` to `joyContribution` / `formatJoyCumulative`.
- Updated the three affected HomeHero goldens after inspecting the diff and confirming it reflected the intended cumulative Joy display.

## Task Commits

1. **Task 1: Delete daily-density files + providers + regen** - `a6d0f9c` (refactor)
2. **Task 2: AnalyticsScreen surgery** - `3c8d35c` (refactor)
3. **Task 3: HomeHero minimal migration** - `d026560` (refactor)
4. **Task 4: Update HomeHero goldens** - `749792a` (test)

## Verification

- `flutter pub run build_runner build --delete-conflicting-outputs` - passed; wrote 0 outputs.
- `flutter analyze` - passed with 0 issues.
- `flutter test` - passed (`+1413`, all tests passed).
- `flutter test test/golden/home_hero_card_golden_test.dart` - passed after updating expected goldens.
- `rg "joyPerYen|joyDensity|formatJoyDensity|_computePtvfDensity|JoyTrendLineChart|dailyJoyPerYenProvider|joy_density_formatter|_TooltipKey\\.joyPerYen" lib test -g "*.dart"` - no hits.
- `rg "density" lib -g "*.dart"` - no hits.

## Deviations from Plan

- Removed two additional obsolete density tests that referenced the deleted DAO/widget surfaces:
  - `test/unit/data/daos/analytics_dao_daily_joy_test.dart`
  - `test/widget/features/analytics/presentation/widgets/joy_trend_line_chart_test.dart`
- Updated HomeHero goldens because the intended formatter/field swap changed the rendered metric output.

## Issues Encountered

- The first full `flutter test` run failed only on the three HomeHero goldens. The diffs were inspected, accepted as expected Phase 13 output changes, and the goldens were regenerated.

## User Setup Required

None.

## Next Phase Readiness

Phase 13 is complete. Phase 14 can now build the frontend ring target behavior, Settings UI, Analytics redesign, and ARB reconciliation on top of the cumulative Joy backend.

---
*Phase: 13-adr-016-backend-foundation*
*Completed: 2026-05-19*
