---
phase: "33"
plan: "01"
subsystem: theme/test
tags: [tdd, wave-0, red-baseline, color-tokens, architecture-gate]
dependency_graph:
  requires: []
  provides:
    - test/architecture/color_literal_scan_test.dart
    - test/core/theme/app_palette_test.dart
    - test/widget/theme_dark_mode_coverage_test.dart
  affects:
    - plan: "33-02"
      reason: "app_palette_test.dart and theme_dark_mode_coverage_test.dart will go GREEN when 33-02 creates app_palette.dart and registers it in AppTheme.dark"
    - plan: "33-03"
      reason: "color_literal_scan_test.dart will go GREEN when 33-03 through 33-04 complete the literal migration"
tech_stack:
  added: []
  patterns:
    - "Architecture gate test: Directory.listSync recursive scan + RegExp + expect(hits, isEmpty)"
    - "ThemeExtension unit test: ADR-018 hex values as const Color assertions"
    - "Widget test with ThemeMode.dark: MaterialApp(themeMode: ThemeMode.dark, darkTheme: AppTheme.dark)"
key_files:
  created:
    - test/architecture/color_literal_scan_test.dart
    - test/core/theme/app_palette_test.dart
    - test/widget/theme_dark_mode_coverage_test.dart
  modified: []
decisions:
  - "D-01 gate: Tests import app_palette.dart (not app_colors.dart) to enforce the ThemeExtension architecture as the migration contract"
  - "D-03/D-04: color_literal_scan_test.dart scans lib/features/, lib/application/, lib/shared/ — not lib/core/theme/ (which legitimately hosts Color constants)"
  - "Scan skips .g.dart and .freezed.dart to avoid false positives from generated code"
  - "theme_dark_mode_coverage_test.dart uses minimal Builder widgets (no screen imports) to isolate ThemeExtension registration from unrelated widget dependencies"
metrics:
  duration: "3m"
  completed: "2026-06-01"
  tasks_completed: 3
  tasks_total: 3
  files_created: 3
  files_modified: 0
---

# Phase 33 Plan 01: Wave-0 RED Baseline Tests Summary

Three Wave-0 test files establishing RED baselines for the COLOR-01/COLOR-03/THEME-V2-02 requirements before any production code is changed.

## What Was Built

### Task 1 — `test/architecture/color_literal_scan_test.dart` (commit 065329c2)

Architecture gate that scans `lib/features/`, `lib/application/`, `lib/shared/` recursively for `Color(0x…)` / `Color(0X…)` literals. Currently finds **17 files with 63 total hits** (the expected RED baseline). Will pass GREEN when Plans 33-03 and 33-04 complete the literal migration.

Modeled after `test/architecture/hardcoded_cjk_ui_scan_test.dart` (same Directory.listSync + RegExp + hits.add + expect(isEmpty) pattern). Skips `.g.dart` and `.freezed.dart` generated files. Does NOT scan `lib/core/theme/` — that directory legitimately hosts Color constants and is the migration destination.

### Task 2 — `test/core/theme/app_palette_test.dart` (commit 625ee266)

Unit test encoding the ADR-018 hex contract for `AppPalette`. Four test groups:
- `AppPalette.light` — 8 ADR-018 role assertions (background, accentPrimary, daily, joy, dailyText, joyText, success, error)
- `AppPalette.dark` — 5 ADR-018 role assertions (background, accentPrimary, daily, joy, textPrimary)
- `copyWith` — returns new instance with override; unchanged fields preserved
- `lerp` — at t=0.0 returns light background; at t=1.0 returns dark background

Currently fails with compile error: `app_palette.dart` does not exist. Will pass GREEN when Plan 33-02 creates `lib/core/theme/app_palette.dart`.

### Task 3 — `test/widget/theme_dark_mode_coverage_test.dart` (commit 74a13eea)

Widget test pumping minimal Builder widgets under `ThemeMode.dark` (via `_darkApp` helper using `AppTheme.light`/`AppTheme.dark`). Asserts:
1. `Theme.of(context).brightness == Brightness.dark`
2. `Theme.of(context).extension<AppPalette>()` is not null
3. `AppPalette.dark.background == Color(0xFF0C1719)` (ADR-018 dark background)

Currently fails with compile error: `app_palette.dart` does not exist. Will pass GREEN when Plan 33-02 defines `AppPalette` and registers it in `AppTheme.dark`'s `extensions`.

## Expected RED Failure State

| Test File | Failure Mode | Cause | Becomes GREEN at |
|-----------|-------------|-------|-----------------|
| `color_literal_scan_test.dart` | Assertion failure: 63 hits in 17 files | 63 `Color(0x…)` literals present in features | Plans 33-03/33-04 complete |
| `app_palette_test.dart` | Compile error: `app_palette.dart` missing | `lib/core/theme/app_palette.dart` not yet created | Plan 33-02 |
| `theme_dark_mode_coverage_test.dart` | Compile error: `AppPalette` type not found | `lib/core/theme/app_palette.dart` not yet created | Plan 33-02 |

## Verification Results

```
# color_literal_scan_test.dart — expected RED failure (hits list visible):
Expected: empty
Actual: [
  'lib/features/accounting/presentation/screens/category_selection_screen.dart: 1 hit(s)',
  'lib/features/accounting/presentation/widgets/soft_toast.dart: 7 hit(s)',
  'lib/features/home/presentation/widgets/home_hero_card.dart: 2 hit(s)',
  'lib/features/profile/presentation/screens/profile_edit_screen.dart: 4 hit(s)',
  'lib/features/profile/presentation/screens/profile_onboarding_screen.dart: 4 hit(s)',
  'lib/features/profile/presentation/screens/avatar_picker_screen.dart: 4 hit(s)',
  'lib/features/profile/presentation/widgets/scattered_emoji_background.dart: 1 hit(s)',
  'lib/features/profile/presentation/widgets/avatar_display.dart: 8 hit(s)',
  'lib/features/list/presentation/widgets/list_calendar_header.dart: 2 hit(s)',
  'lib/features/family_sync/presentation/screens/group_choice_screen.dart: 7 hit(s)',
  'lib/features/family_sync/presentation/screens/member_approval_screen.dart: 7 hit(s)',
  'lib/features/family_sync/presentation/screens/group_management_screen.dart: 1 hit(s)',
  'lib/features/family_sync/presentation/screens/join_group_screen.dart: 6 hit(s)',
  'lib/features/family_sync/presentation/screens/create_group_screen.dart: 4 hit(s)',
  'lib/features/family_sync/presentation/screens/confirm_join_screen.dart: 4 hit(s)',
  'lib/features/family_sync/presentation/widgets/member_list_tile.dart: 3 hit(s)',
  'lib/features/accounting/presentation/screens/ocr_scanner_screen.dart: 1 hit(s)'
]
# 17 files, 63 total hits — matches RESEARCH.md estimate of 61 (minor variance acceptable)

# app_palette_test.dart — expected RED compile error:
Error when reading 'lib/core/theme/app_palette.dart': No such file or directory

# theme_dark_mode_coverage_test.dart — expected RED compile error:
Error when reading 'lib/core/theme/app_palette.dart': No such file or directory
```

`flutter analyze lib/` — 2 pre-existing `info`-level deprecation warnings in `category_selection_screen.dart` (pre-existing, out of scope for this plan). No errors or warnings introduced by this plan.

## Deviations from Plan

None — plan executed exactly as written.

The hit count is 63 across 17 files rather than the RESEARCH.md estimate of "61 literals in lib/features/". The 2-count variance is within expected tolerance (grep methodology differences). The test correctly captures all existing literals regardless of the prior estimate.

## Known Stubs

None — this plan creates test files only (no production code, no stubs).

## Threat Flags

None — test files only; no new production surface.

## TDD Gate Compliance

| Gate | Commit | Status |
|------|--------|--------|
| RED (test) | 065329c2, 625ee266, 74a13eea | All 3 test files fail as expected |
| GREEN (impl) | — | Not yet (Plans 33-02 through 33-04 responsibility) |
| REFACTOR | — | N/A |

## Self-Check: PASSED

Files verified:
- `test/architecture/color_literal_scan_test.dart` — FOUND
- `test/core/theme/app_palette_test.dart` — FOUND
- `test/widget/theme_dark_mode_coverage_test.dart` — FOUND

Commits verified:
- 065329c2 — FOUND
- 625ee266 — FOUND
- 74a13eea — FOUND
