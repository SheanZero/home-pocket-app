---
phase: 33-color-token-system-consolidation
plan: "02"
subsystem: theme
tags: [color-tokens, ThemeExtension, ADR-018, dark-mode, palette]
dependency_graph:
  requires: [33-01]
  provides: [AppPalette ThemeExtension, context.palette accessor, AppTheme.dark/light registration]
  affects: [lib/core/theme/app_palette.dart, lib/core/theme/app_theme.dart, lib/core/theme/app_text_styles.dart]
tech_stack:
  added: []
  patterns:
    - Flutter ThemeExtension<AppPalette> with static const light/dark instances
    - BuildContext.palette extension for ergonomic access
    - ADR-018 Teal Clarity hex contract encoded as compile-time constants
key_files:
  created:
    - lib/core/theme/app_palette.dart
  modified:
    - lib/core/theme/app_theme.dart
    - lib/core/theme/app_text_styles.dart
decisions:
  - "avatarBorderAlpha is a single brightness-resolved field (not avatarBorderAlphaLight/Dark), enabling call sites to use palette.avatarBorderAlpha with no isDark check"
  - "app_text_styles.dart: replaced AppColors.textPrimary/textSecondary with ADR-018 hex literals (not removed), keeping existing callers working without changes"
  - "app_theme.dart: removed app_colors.dart import entirely (unused after migrating to const Color literals); AppColors shim preserved for feature layer"
  - "comparisonDelta loses its color field; callers apply .copyWith(color: context.palette.success) per D-06"
metrics:
  duration: "6 minutes"
  completed: "2026-06-01"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 2
---

# Phase 33 Plan 02: AppPalette ThemeExtension + Theme Registration Summary

**One-liner:** ADR-018 Teal Clarity palette encoded as `ThemeExtension<AppPalette>` with full light/dark instances, registered in AppTheme, and olive dependency removed from app_text_styles.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create AppPalette ThemeExtension | 4c5c1584 | lib/core/theme/app_palette.dart (new), test files copied to worktree |
| 2 | Register AppPalette in AppTheme + fix app_text_styles.dart | dcd65072 | lib/core/theme/app_theme.dart, lib/core/theme/app_text_styles.dart |

## What Was Built

### Task 1: `lib/core/theme/app_palette.dart` (NEW — 609 lines)

Created `final class AppPalette extends ThemeExtension<AppPalette>` with:

- **57 semantic color fields** covering all ADR-018 roles: backgrounds (5), text (3), borders (4), accent primary (6 + 2 getters), recording (2), ledger daily/joy/shared (9), semantic success/warning/error/info (5), error tints (3), shadows (2), joy card (4), family (1), best-joy strip (5), decorative avatar (4), decorative member (3), alpha overlays (2)
- `static const light` — full ADR-018 Light hex table (Teal Clarity)
- `static const dark` — full ADR-018 Dark hex table
- `copyWith` with all nullable Color? parameters
- `lerp` using `Color.lerp(a, b, t)!` for all 57 fields
- `extension AppPaletteContext on BuildContext { AppPalette get palette => Theme.of(this).extension<AppPalette>()!; }`
- `backgroundWarm` getter aliasing `background`
- `actionGradientStart/End` getters aliasing `fabGradientStart/End`

**Key design decisions:**
- `avatarBorderAlpha` is a SINGLE field (light = `Color(0x80FFFFFF)`, dark = `Color(0x26FFFFFF)`). Plan 33-06 uses `palette.avatarBorderAlpha` with no `isDark` check.
- `avatarGradientStart/Mid/End` are single fields (brightness-resolved). Teal-light family for light, teal-dark family for dark.
- No `olive`/`oliveLight`/`oliveBorder` fields (D-06: olive merged into `success #2FA37A`).
- Recording gradient uses error semantic family (`#E5484D`/`#F0676B`) — red = live/active danger signal.

### Task 2: `lib/core/theme/app_theme.dart` (MODIFIED)

- Added `import 'app_palette.dart'`
- Added `extensions: const [AppPalette.light]` to `ThemeData.light`
- Added `extensions: const [AppPalette.dark]` to `ThemeData.dark`
- Updated `colorSchemeSeed` to `const Color(0xFF0E9AA7)` (teal, both light+dark — M3 uses brightness to drive color scheme)
- Updated `scaffoldBackgroundColor`, `appBarTheme`, `cardTheme` to ADR-018 const Color hex literals
- Removed `import 'app_colors.dart'` (no longer needed — direct hex literals used; AppColors shim kept for feature layer files in Plans 33-03 through 33-06)

### Task 3: `lib/core/theme/app_text_styles.dart` (MODIFIED)

- Removed `import 'app_colors.dart'`
- Replaced all `AppColors.textPrimary` refs with `const Color(0xFF112025)` (ADR-018 light textPrimary)
- Replaced all `AppColors.textSecondary` refs with `const Color(0xFF5A7176)` (ADR-018 light textSecondary)
- Removed `color: AppColors.olive` from `comparisonDelta` (D-06); callers apply `.copyWith(color: context.palette.success)`
- Added inline constants `_textPrimary` and `_textSecondary` for DRY

## Verification Results

- `flutter analyze lib/core/theme/` — **0 issues** (PASS)
- `flutter test test/core/theme/app_palette_test.dart` — **17/17 GREEN** (ADR-018 hex contract)
- `flutter test test/widget/theme_dark_mode_coverage_test.dart` — **3/3 GREEN** (ThemeExtension resolution under dark)
- `grep -n 'AppColors' lib/core/theme/app_text_styles.dart` — **0 hits** (PASS)
- `grep 'extensions:.*AppPalette' lib/core/theme/app_theme.dart` — **2 hits** (light + dark) (PASS)
- `AppPalette.dark.background == Color(0xFF0C1719)` — verified by test (PASS)
- `AppPalette.light.avatarBorderAlpha == Color(0x80FFFFFF)` — encoded in static const (PASS)
- `AppPalette.dark.avatarBorderAlpha == Color(0x26FFFFFF)` — encoded in static const (PASS)

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

**Note on app_text_styles.dart approach:** The plan offered two options for `AppColors.textPrimary` refs: "hardcoded hex" or "remove color entirely". Chose hardcoded hex (`const Color(0xFF112025)`) to preserve existing callers without any changes. Private constants `_textPrimary` and `_textSecondary` keep the file DRY. The `comparisonDelta` style's `color` field was removed entirely per the plan's explicit instruction.

**Note on test files:** Wave-0 test files (`app_palette_test.dart`, `theme_dark_mode_coverage_test.dart`) were committed to the main repo by Plan 33-01 but not present in this worktree's branch (worktree was based on pre-33-01 commit). The files were copied from the main repo into this worktree for local test verification. They appear as new files in this worktree's commit (4c5c1584) and will be de-duplicated during merge (git will see them as already present on main from 33-01's commit).

## Known Stubs

None — all color fields are fully specified with exact ADR-018 hex values. No placeholders.

The pre-existing TODO on line 180 of `app_text_styles.dart` ("Remove after all screens are migrated to Wa-Modern") is a pre-existing tracked cleanup item, not introduced by this plan.

## Threat Flags

None — this plan introduces only compile-time color constant changes. No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries.

## Self-Check: PASSED

- [x] `lib/core/theme/app_palette.dart` exists (FOUND)
- [x] `lib/core/theme/app_theme.dart` exists (FOUND)  
- [x] `lib/core/theme/app_text_styles.dart` exists (FOUND)
- [x] Commit `4c5c1584` exists (Task 1 — AppPalette creation)
- [x] Commit `dcd65072` exists (Task 2 — AppTheme registration + app_text_styles fix)
- [x] `app_palette_test.dart`: 17/17 GREEN
- [x] `theme_dark_mode_coverage_test.dart`: 3/3 GREEN
- [x] `flutter analyze lib/core/theme/`: 0 issues
- [x] `app_text_styles.dart`: 0 AppColors references
- [x] AppColors/AppColorsDark shim (`app_colors.dart`) unchanged
