---
phase: 47-i18n-macos-golden-uat
plan: 05
subsystem: testing
tags: [golden, flutter, analytics, fl_chart, adr-019, macos-baseline]

# Dependency graph
requires:
  - phase: 47-i18n-macos-golden-uat
    provides: "WR-01..04 review-fixes, ARB cleanup, anti-toxicity gate (plans 01-04) — the final swept visual state the goldens capture"
  - phase: 46
    provides: "round-5 B analytics surfaces (5 always-visible cards + family_insight + CategoryDrillDownScreen + AnalyticsScreen shell)"
provides:
  - "8 golden test files for the round-5 B analytics surfaces (charts had ZERO golden coverage before — GUARD-04 closed)"
  - "48 macOS-baselined PNG masters under test/golden/goldens/ covering ja/zh/en × light/dark + WR-02 Other slice, joy-calendar inline-expand, per-card empties, group-mode, drill list, and full-page card-order"
  - "Production-AppTheme-wrapped golden harness pattern (palette-regression detectors, not just layout snapshots)"
affects: [analytics-regression-detection, future-analytics-ui-changes, ci-golden-gate]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-card golden harness wraps PRODUCTION AppTheme (theme: AppTheme.light, darkTheme: AppTheme.dark, themeMode) so context.palette resolves real ADR-019 AppPalette — NOT bare ThemeData.light()/dark()"
    - "Count-up TweenAnimationBuilder goldens settled via pumpAndSettle() before expectLater (D-09 settled end-state)"
    - "Full-page scroll-smoke golden uses tester.view.physicalSize tall frame to capture card ORDER in one frame (D-07)"

key-files:
  created:
    - test/golden/within_month_trend_card_golden_test.dart
    - test/golden/category_donut_card_golden_test.dart
    - test/golden/joy_spend_card_golden_test.dart
    - test/golden/joy_calendar_card_golden_test.dart
    - test/golden/satisfaction_histogram_card_golden_test.dart
    - test/golden/family_insight_data_card_golden_test.dart
    - test/golden/category_drill_down_screen_golden_test.dart
    - test/golden/analytics_screen_scroll_smoke_golden_test.dart
    - test/golden/goldens/ (48 PNG masters)
  modified: []

key-decisions:
  - "Wrapped production AppTheme in every golden (not bare ThemeData) so goldens detect ADR-019 palette regressions — critical for the WR-02 neutral 'Other' swatch (palette.textTertiary)"
  - "Overrode satisfactionDistributionProvider + happinessReportProvider directly (not via a fake AnalyticsRepository) — keeps the harness minimal and deterministic"
  - "Drill-screen + scroll-smoke pin the window via a _FixedTimeWindow SelectedTimeWindow subclass (TimeWindow.month 2026-05) so the provider keys are deterministic"
  - "Scoped --update-goldens to ONLY the 8 new test files so no pre-existing baseline was re-rendered (clean diff attribution, GUARD-04)"

patterns-established:
  - "Pattern: production-AppTheme golden wrap for palette fidelity (the 47-UI-SPEC §Theme Fidelity contract)"
  - "Pattern: inline-expand golden — tap a heatmap cell (ValueKey joy_day_N), override the day-keyed provider, pumpAndSettle the AnimatedSize grow, then capture"

requirements-completed: [GUARD-04]

# Metrics
duration: 11min
completed: 2026-06-18
---

# Phase 47 Plan 05: macOS Golden Coverage for Round-5 B Analytics Summary

**8 golden test files + 48 macOS PNG baselines wrapping the production ADR-019 AppTheme — closing GUARD-04's zero-golden gap on the redesigned analytics charts (per-card ja/zh/en × light/dark + WR-02 Other slice, joy-calendar inline-expand, group-mode, drill list, and a full-page card-order smoke).**

## Performance

- **Duration:** ~11 min
- **Started:** 2026-06-18T00:17:19+09:00
- **Completed:** 2026-06-18T00:28+09:00
- **Tasks:** 3
- **Files modified:** 56 (8 test files + 48 PNG masters)

## Accomplishments
- Authored 6 per-card golden harnesses (within_month_trend, category_donut, joy_spend, joy_calendar, satisfaction_histogram, family_insight) each wrapping the PRODUCTION AppTheme so `context.palette` resolves real ADR-019 colors
- Authored the read-only CategoryDrillDownScreen golden (D-08①) and the full-page AnalyticsScreen scroll-smoke golden verifying the round-5 B card ORDER (D-07)
- Captured every required special state: WR-02 >10-L1 "Other" slice, joy-calendar inline `_InlineDayPanel` expand (D-08②), per-card empties/self-hide, group-mode family aggregate (D-08③)
- Count-up anchors (donut center total + 悦己 header) settled via `pumpAndSettle()` to their `IntTween.end` before capture (D-09)
- 48 deterministic macOS baselines generated and pass pixel-exact on re-run without `--update-goldens`

## Task Commits

Each task was committed atomically:

1. **Task 1: Author 6 per-card golden tests (5 always-visible cards + family_insight)** - `5323cf20` (test)
2. **Task 2: Author CategoryDrillDownScreen + AnalyticsScreen scroll-smoke goldens** - `3414e79f` (test)
3. **Task 3: Baseline 48 macOS golden masters + commit PNGs** - `2c35ec6d` (test)

## Files Created/Modified
- `test/golden/within_month_trend_card_golden_test.dart` - ja/zh/en × light/dark + empty (7 masters)
- `test/golden/category_donut_card_golden_test.dart` - + WR-02 >10-L1 Other slice (light ja, dark en) + empty (9 masters)
- `test/golden/joy_spend_card_golden_test.dart` - ja/zh/en × light/dark + empty; count-up header settled (7 masters)
- `test/golden/joy_calendar_card_golden_test.dart` - collapsed ja/zh/en × light/dark + inline-expand light ja (7 masters)
- `test/golden/satisfaction_histogram_card_golden_test.dart` - value (totalJoyTx≥5) ja/zh/en × light/dark + thin-sample self-hide (7 masters)
- `test/golden/family_insight_data_card_golden_test.dart` - group-mode ja/zh/en × light/dark (6 masters)
- `test/golden/category_drill_down_screen_golden_test.dart` - read-only list ja/zh/en light + ja dark (4 masters)
- `test/golden/analytics_screen_scroll_smoke_golden_test.dart` - full-page card-order, ja/light, 390×2600 (1 master)
- `test/golden/goldens/*.png` - 48 macOS PNG baselines

## Decisions Made
- Production AppTheme wrap (not bare ThemeData) — the only way the goldens validate ADR-019 palette, not just layout (47-UI-SPEC §Theme Fidelity)
- Direct provider overrides for satisfaction (happinessReportProvider + satisfactionDistributionProvider) rather than a fake AnalyticsRepository — minimal, deterministic
- `_FixedTimeWindow` SelectedTimeWindow subclass pins the window for the drill + smoke goldens so the categoryDrillDown/card provider keys are exact
- Scoped `--update-goldens` to the 8 new files only — no library change enters the diff (GUARD-04 attribution)

## Deviations from Plan

None - plan executed exactly as written.

The only adjustment was cosmetic: an unused `package:flutter_riverpod/misc.dart` import (the planned analog imports it for `Override`, but `Override` resolves from `flutter_riverpod.dart`) was removed from all 6 Task-1 files to keep `flutter analyze` at 0 — a lint cleanup within the authored files, not a behavior change.

## Issues Encountered
None. All 48 baselines generated cleanly and matched pixel-exact on the verification re-run. The joy-calendar inline-expand golden correctly drove the tap → AnimatedSize grow → settled capture; the scroll-smoke golden's tall 390×2600 frame captured all five cards in declaration order.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- GUARD-04 golden coverage is complete; the round-5 B analytics charts now have regression baselines.
- Wave gate (Plan 06) should run the FULL `flutter test` suite (including the global golden platform gate and the architecture scans) — scoped runs miss cross-cutting tests.
- Off-macOS CI reduces these goldens to baseline-existence via `flutter_test_config.dart`; never re-baseline on ubuntu.

## Self-Check: PASSED

- 8 golden test files exist (verified on disk)
- 48 PNG masters tracked under test/golden/goldens/ (git ls-files)
- 3 task commits present (5323cf20, 3414e79f, 2c35ec6d)
- `flutter analyze` on all 8 files: 0 issues
- All 8 golden tests pass pixel-exact against their own baselines (re-run without --update-goldens)

---
*Phase: 47-i18n-macos-golden-uat*
*Completed: 2026-06-18*
