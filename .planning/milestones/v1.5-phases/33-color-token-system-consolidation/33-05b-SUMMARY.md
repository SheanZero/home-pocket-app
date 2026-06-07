---
phase: 33-color-token-system-consolidation
plan: "05b"
subsystem: presentation/list, presentation/settings
tags: [color-migration, palette, dark-mode, list, settings, Bucket-F]
dependency_graph:
  requires: [33-02]
  provides: [settings-palette, list-palette, calendar-bucket-f, list-dark-mode]
  affects: [33-07]
tech_stack:
  added: []
  patterns: [context.palette access, AppPalette ThemeExtension, palette.dailyText/joyText WCAG]
key_files:
  created: []
  modified:
    - lib/features/list/presentation/widgets/list_transaction_tile.dart
    - lib/features/list/presentation/widgets/list_calendar_header.dart
    - lib/features/list/presentation/screens/list_screen.dart
    - lib/features/list/presentation/widgets/list_empty_state.dart
    - lib/features/list/presentation/widgets/list_sort_filter_bar.dart
    - lib/features/list/presentation/widgets/list_day_group_header.dart
    - lib/features/list/presentation/widgets/list_category_filter_sheet.dart
decisions:
  - "settings_screen.dart required no color changes (no color refs in file — all colors delegated to child widgets)"
  - "Bucket F _weekendColor/_todayColor replaced with palette.info/palette.error per D-07/ADR-018"
  - "_buildDayCell receives AppPalette as explicit param (no BuildContext available in that method)"
  - "member chip in list_transaction_tile uses palette.sharedText (WCAG-compliant) not palette.shared"
  - "const constructors using palette tokens converted to non-const (Dart restriction — palette is runtime value)"
metrics:
  duration_minutes: 30
  tasks_completed: 2
  tasks_total: 2
  files_modified: 7
  completed_date: "2026-06-01"
---

# Phase 33 Plan 05b: settings/ + list/ Palette Migration Summary

Migrated all color references in `lib/features/settings/` (1 file) and `lib/features/list/` (6 widgets + 1 screen = 7 files) from `AppColors.*`/`context.wm*`/`Color(0x...)` literals to `context.palette.*` tokens. Delivers full dark-mode support and Teal Clarity palette to both the transaction list and settings surfaces.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Migrate list_transaction_tile + list_calendar_header (Bucket F + WCAG) | bc37f533 | list_transaction_tile.dart, list_calendar_header.dart |
| 2 | Migrate settings_screen + remaining 5 list/ files | a4ed1173 | list_screen.dart, list_empty_state.dart, list_sort_filter_bar.dart, list_day_group_header.dart, list_category_filter_sheet.dart |

## What Was Built

### Task 1 — list_transaction_tile.dart
- Replaced `app_colors.dart` import with `app_palette.dart`
- Added `final palette = context.palette` in `build()`
- Replaced `AppColors.card`, `AppColors.textSecondary`, `AppColors.joy`, `AppColors.sharedLight`, `AppColors.shared`, `AppColors.textPrimary` with palette equivalents
- Member chip text color updated from `AppColors.shared` to `palette.sharedText` (WCAG-compliant variant; `shared #5B8AC4` passes WCAG AA on `sharedLight #E8EFF7` background)
- Swipe-delete background icon uses `palette.card` (was `const AppColors.card`)

### Task 1 — list_calendar_header.dart
- **Bucket F resolution (D-07):** Removed `static const _weekendColor = Color(0xFF1565C0)` and `static const _todayColor = Color(0xFFD32F2F)`; replaced with `palette.info` (#2A8FB8 light / #5AA8E0 dark) and `palette.error` (#E5484D light / #F0676B dark) per ADR-018
- `_buildDayCell` receives `AppPalette palette` as first param (context unavailable in that method)
- `_SummaryRow.build()` adds `palette = context.palette`; `const BoxDecoration` converted to non-const for runtime color resolution
- All `AppColors.accentPrimary`, `AppColors.card`, `AppColors.textPrimary/Secondary`, `AppColors.backgroundMuted`, `AppColors.borderDivider` replaced with palette tokens

### Task 2 — list_screen.dart
- Replaced `app_colors.dart` import with `app_palette.dart`
- Added `palette = context.palette` in both `_buildList()` and `_buildTile()`
- Ledger tag colors (`tagBgColor`, `tagTextColor`) resolved via `palette.dailyLight`/`palette.daily`/`palette.joyLight`/`palette.joy` (COLOR-02 compliance)
- `RefreshIndicator.color`, `CircularProgressIndicator.color` → `palette.accentPrimary`
- Error state icon uses `palette.textTertiary`; error text uses `palette.textSecondary`
- Tile divider: `const Divider(color: AppColors.borderList)` → non-const with `palette.borderList`

### Task 2 — list_empty_state.dart
- `AppColors.textTertiary` → `palette.textTertiary` (empty-state icon)
- `AppColors.textSecondary` → `palette.textSecondary` (message text)
- `AppColors.accentPrimary` → `palette.accentPrimary` (action TextButton)

### Task 2 — list_sort_filter_bar.dart
- All 50+ `AppColors.*` refs replaced with `palette.*`
- `_showSortMenu` gets `palette = context.palette` locally (context available as param)
- Sort chip, direction icon, All/日常/ときめき ledger chips, category chip, search field, family member chips, clear chip — all fully themed
- All `const Icon(...)`, `const BorderSide(...)`, `const BoxDecoration(...)` with AppColors removed `const` where palette refs used

### Task 2 — list_day_group_header.dart
- `AppColors.backgroundMuted` → `palette.backgroundMuted` (day group background)
- `AppColors.textSecondary` → `palette.textSecondary` (date text)
- Doc comment updated: `[AppColors.backgroundMuted]` → `[AppPalette.backgroundMuted]`

### Task 2 — list_category_filter_sheet.dart
- `AppColors.background` → `palette.background` (sheet container)
- `AppColors.borderDivider` → `palette.borderDivider` (drag handle, header divider, category dividers, apply-bar border)
- `AppColors.textSecondary` → `palette.textSecondary` (clear button, cancel button)
- `AppColors.accentPrimary` → `palette.accentPrimary` (apply FilledButton)
- `AppColors.card` → `palette.card` (apply button text)
- Three `const Divider`/`const BoxDecoration` constructors made non-const

### Task 2 — settings_screen.dart
- No color references present — all colors delegated to child section widgets
- No changes needed

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] const constructors with runtime palette values**
- **Found during:** Task 1 (list_calendar_header.dart) and Task 2 (list_category_filter_sheet.dart)
- **Issue:** `const BoxDecoration(color: palette.borderDivider)` fails — `palette` is a runtime value, not a compile-time constant
- **Fix:** Removed `const` keyword from affected `BoxDecoration`, `Divider`, and `SizedBox` constructors wherever they referenced `palette.*`
- **Files modified:** list_calendar_header.dart, list_category_filter_sheet.dart

**2. [Note] settings_screen.dart — no changes**
- **Found during:** Task 2 pre-check
- **Observation:** `settings_screen.dart` has no `AppColors.*`, `AppColorsDark.*`, or `Color(0x...)` references; it only composes section widgets
- **Action:** Verified via grep; no import swap needed; settings_screen counted as migrated (zero legacy refs confirmed)

## Verification Results

### COLOR-01 Grep Gates (PASS)
```
grep -rn 'Color(0x' lib/features/settings/ lib/features/list/   → 0 hits
grep -rn 'AppColors\.' lib/features/settings/ lib/features/list/ → 0 hits
grep -rn 'AppColorsDark\.' lib/features/settings/ lib/features/list/ → 0 hits
grep -rn 'context\.wm' lib/features/settings/ lib/features/list/ → 0 hits
```

### flutter analyze (PASS)
```
flutter analyze lib/features/settings/ lib/features/list/
No issues found!
```

## Known Stubs

None. All color tokens route through `context.palette.*` — no placeholder values.

## Threat Flags

None. This plan is a pure Dart presentation-layer color-constant substitution. No new network endpoints, auth paths, file access patterns, or schema changes were introduced.

## Self-Check: PASSED

- [x] list_transaction_tile.dart modified: `git show bc37f533 --name-only` confirms file
- [x] list_calendar_header.dart modified: `git show bc37f533 --name-only` confirms file
- [x] list_screen.dart modified: `git show a4ed1173 --name-only` confirms file
- [x] list_empty_state.dart, list_sort_filter_bar.dart, list_day_group_header.dart, list_category_filter_sheet.dart modified: `git show a4ed1173 --name-only` confirms all 4
- [x] Commits bc37f533, a4ed1173 exist in `git log --oneline -5`
- [x] `flutter analyze lib/features/settings/ lib/features/list/` → No issues found
- [x] All COLOR-01 grep gates return 0
