---
phase: 33-color-token-system-consolidation
plan: "03"
subsystem: theme/presentation
tags: [color-tokens, palette-migration, dark-mode, home, analytics, D-05, D-06]
dependency_graph:
  requires: [33-02]
  provides: [home-palette-clean, analytics-palette-clean]
  affects: [home_hero_card, analytics_screen, all home widgets, all analytics widgets]
tech_stack:
  added: []
  patterns: [context.palette.*, AppPalette param injection, non-const SweepGradient/LinearGradient]
key_files:
  created: []
  modified:
    - lib/features/home/presentation/widgets/home_hero_card.dart
    - lib/features/home/presentation/screens/home_screen.dart
    - lib/features/home/presentation/widgets/family_invite_banner.dart
    - lib/features/home/presentation/widgets/hero_header.dart
    - lib/features/home/presentation/widgets/home_bottom_nav_bar.dart
    - lib/features/home/presentation/widgets/home_transaction_tile.dart
    - lib/features/home/presentation/widgets/section_divider.dart
    - lib/features/home/presentation/widgets/transaction_list_card.dart
    - lib/features/analytics/presentation/widgets/analytics_card_error_state.dart
    - lib/features/analytics/presentation/widgets/analytics_screen_section_header.dart
    - lib/features/analytics/presentation/widgets/best_joy_story_strip.dart
    - lib/features/analytics/presentation/widgets/category_spend_donut_chart.dart
    - lib/features/analytics/presentation/widgets/daily_vs_joy_card.dart
    - lib/features/analytics/presentation/widgets/family_insight_card.dart
    - lib/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart
    - lib/features/analytics/presentation/widgets/joy_ledger_thin_sample_fallback.dart
    - lib/features/analytics/presentation/widgets/joy_metric_variant_chip.dart
    - lib/features/analytics/presentation/widgets/largest_expense_story_card.dart
    - lib/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart.dart
    - lib/features/analytics/presentation/widgets/per_category_breakdown_card.dart
    - lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart
    - lib/features/analytics/presentation/widgets/time_window_chip.dart
    - lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart
    - lib/features/analytics/presentation/widgets/total_spending_kpi_tile.dart
decisions:
  - "D-05: joyTargetProgressColor now accepts AppPalette param and lerps palette.daily → palette.joy (deleted _joyTargetStartColor/_joyTargetEndColor)"
  - "D-06: AppColors.olive/oliveLight → palette.success/successLight confirmed in family_insight_card + hero_header avatar"
  - "WCAG: Joy monetary amounts in home_hero_card and home_screen use palette.joyText (not palette.joy)"
  - "Pattern: methods without BuildContext access (_barGroupFor, _colorFor, _colorForScore, _buildFab) receive AppPalette as explicit parameter"
  - "wmSoulTagBg → palette.joyLight; wmSurvivalTagBg → palette.dailyLight throughout all files"
metrics:
  duration: "~35 minutes"
  completed: "2026-06-01"
  tasks: 2
  files_modified: 24
---

# Phase 33 Plan 03: home/ + analytics/ Color Token Migration Summary

All `AppColors.*` static refs, `context.wm*` getters, and `Color(0x...)` literals in `lib/features/home/` and `lib/features/analytics/` replaced with `context.palette.*` (ADR-018 Teal Clarity tokens via ThemeExtension).

## What Was Built

Full palette migration for the two highest-visibility feature areas:

**home/ (8 files):** `home_hero_card.dart` (D-05 gradient refactor + D-06 olive removal), `home_screen.dart`, `section_divider.dart`, `transaction_list_card.dart`, `home_transaction_tile.dart`, `family_invite_banner.dart`, `home_bottom_nav_bar.dart`, `hero_header.dart`.

**analytics/ (16 files):** All widget files — analytics_card_error_state, analytics_screen_section_header, best_joy_story_strip, category_spend_donut_chart, daily_vs_joy_card, family_insight_card, joy_headline_kpi_tile, joy_ledger_thin_sample_fallback, joy_metric_variant_chip, largest_expense_story_card, monthly_spend_trend_bar_chart, per_category_breakdown_card, satisfaction_distribution_histogram, time_window_chip, time_window_picker_sheet, total_spending_kpi_tile.

**analytics_screen.dart + main_shell_screen.dart:** Confirmed clean — contained no color refs; no changes required.

## Tasks

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Migrate home_hero_card.dart — D-05 + D-06 + context.palette | e21cfb5f | 1 |
| 2 | Migrate analytics/ and home/ remaining widgets + screens | 2839af4a | 23 |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Scope Expansion] All home/ and analytics/ widget files migrated (not just 3 files)**
- **Found during:** Task 2 initial grep check
- **Issue:** Plan frontmatter listed only 3 files in `files_modified`, but the success criteria required grep-zero for ALL of home/ and analytics/ — 21 additional widget files had AppColors/wm* refs
- **Fix:** Migrated all 21 additional files as required by success criteria and plan objective ("Migrate ALL color references in lib/features/home/ and lib/features/analytics/")
- **Files modified:** 23 additional files
- **Commits:** 2839af4a

**2. [Rule 2 - WCAG Constraint] Joy monetary amounts use palette.joyText instead of palette.joy**
- **Found during:** Task 1
- **Issue:** `home_hero_card.dart` colored Best Joy strip amounts with `AppColors.joy` (#F0A81E), which fails WCAG AA 4.5:1 on white card
- **Fix:** Changed to `palette.joyText` (#9A6500) for amount Text widgets; `palette.joy` retained for dot/icon affordance color
- **Files modified:** `home_hero_card.dart`

**3. [Rule 1 - No-context Methods] AppPalette passed as parameter to methods without BuildContext**
- **Found during:** Task 2
- **Issue:** Methods `_barGroupFor`, `_colorFor`, `_colorForScore`, `_buildFab` had no BuildContext access but referenced AppColors
- **Fix:** Added `AppPalette palette` parameter; caller passes `context.palette` from `build()`
- **Files modified:** 4 files

**4. [Rule 1 - const Removal] SweepGradient/LinearGradient const removed where palette fields used**
- **Found during:** Task 1
- **Issue:** `const SweepGradient(colors: [AppColors.x, ...])` blocks palette fields (not compile-time const)
- **Fix:** Removed `const` keyword from gradient/shadow instantiations that reference palette
- **Files modified:** `home_hero_card.dart`, `home_bottom_nav_bar.dart`

## Verification Results

```
grep -rn 'AppColors\.' lib/features/home/ lib/features/analytics/  → 0 hits  PASS
grep -rn 'context\.wm' lib/features/home/ lib/features/analytics/  → 0 hits  PASS
grep -rn 'Color(0x'    lib/features/home/ lib/features/analytics/  → 0 hits  PASS
grep -rn '_joyTargetStartColor\|_joyTargetEndColor' (code only)     → 0 hits  PASS
flutter analyze lib/features/home/ lib/features/analytics/          → 0 issues PASS
```

## Known Stubs

None. All color token substitutions are wired to the live AppPalette ThemeExtension.

## Threat Flags

None. Pure presentation-layer color-constant substitution. No new network endpoints, auth paths, file access, or schema changes.

## Self-Check: PASSED

- [x] `lib/features/home/presentation/widgets/home_hero_card.dart` exists and uses context.palette.*
- [x] Commit e21cfb5f exists: `feat(33-03): migrate home_hero_card.dart to context.palette.*`
- [x] Commit 2839af4a exists: `feat(33-03): migrate all home/ and analytics/ widgets to context.palette.*`
- [x] All grep gates return 0 hits
- [x] flutter analyze returns 0 issues
