---
phase: 33-color-token-system-consolidation
plan: "06"
subsystem: profile
tags: [color-tokens, migration, palette, profile, avatar]
dependency_graph:
  requires: [33-02]
  provides: [profile-palette-migration]
  affects: [lib/features/profile/]
tech_stack:
  added: []
  patterns: [context.palette.*, ThemeExtension brightness-resolved tokens]
key_files:
  created: []
  modified:
    - lib/features/profile/presentation/screens/profile_edit_screen.dart
    - lib/features/profile/presentation/screens/avatar_picker_screen.dart
    - lib/features/profile/presentation/screens/profile_onboarding_screen.dart
    - lib/features/profile/presentation/widgets/avatar_display.dart
    - lib/features/profile/presentation/widgets/scattered_emoji_background.dart
    - lib/features/profile/presentation/widgets/profile_section_card.dart
decisions:
  - "D-04: avatarGradientStart/Mid/End teal-family tokens replace coral _lightGradient/_darkGradient"
  - "D-04: avatarBorderAlpha single brightness-resolved field eliminates isDark at call site"
  - "Dark bg #141418 → palette.background #0C1719 per ADR-018 Teal Clarity (intentional)"
  - "D-03: Color(0xFFF0F0F5) in scattered_emoji_background → palette.textPrimary"
metrics:
  duration: ~15min
  completed: 2026-06-01
  tasks_completed: 2
  files_modified: 6
---

# Phase 33 Plan 06: Profile Color Token Migration Summary

Profile feature migrated from inline dark constants and AppColors.* to context.palette.* tokens via ADR-018 Teal Clarity palette.

## What Was Built

Migrated all color references in `lib/features/profile/` from ad-hoc inline dark constants and AppColors.* static refs to the unified `context.palette.*` ThemeExtension token system. Key deletions: 12 Bucket A inline dark constants across 3 profile screens; avatar coral/dark gradient lists replaced by teal-family tokens; all isDark local vars eliminated from profile/.

## Task Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | `8719d142` | Delete Bucket A inline dark constants from 3 profile screens + scattered_emoji_background migration |
| Task 2 | `08fa0aaf` | avatar_display.dart Bucket C/D re-hue + brightness-resolved border token; profile_section_card deviation fix |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] profile_section_card.dart also had AppColors/AppColorsDark references**
- **Found during:** Task 2 grep gate verification
- **Issue:** `profile_section_card.dart` exists in `lib/features/profile/presentation/widgets/` but was not listed in `files_modified` in the plan. It contained `AppColorsDark.card`, `AppColorsDark.borderDefault`, `AppColorsDark.textSecondary`, `AppColorsDark.textTertiary` and an `isDark` local var. The plan's success criteria require `grep -rn 'AppColors\.' lib/features/profile/ returns 0 hits` — this file would have failed that gate.
- **Fix:** Migrated `profile_section_card.dart` to `context.palette.*` (card, borderDefault, textSecondary, textTertiary). Combined into Task 2 commit.
- **Files modified:** `lib/features/profile/presentation/widgets/profile_section_card.dart`
- **Commit:** `08fa0aaf`

**2. [Rule 1 - Bug] avatar_picker_screen: _EmojiGrid selected tile logic simplified**
- **Found during:** Task 1 migration
- **Issue:** Original code: `color: isSelected && !isDark ? Colors.white : tileColor` — this special-cased white for selected tiles in light mode. With palette, `palette.card = Color(0xFFFFFFFF)` in light mode, so `palette.card` achieves the same intent (white in light, card-dark in dark).
- **Fix:** Replaced with `color: isSelected ? palette.card : palette.backgroundMuted` — semantically correct and cleaner.
- **Files modified:** `lib/features/profile/presentation/screens/avatar_picker_screen.dart`
- **Commit:** `8719d142`

## Intentional Visual Changes (Per ADR-018)

- **Dark background:** All 3 profile screens change from `#141418` (near-black) to `palette.background = #0C1719` (teal-dark). This is the correct ADR-018 Teal Clarity dark palette alignment. Phase 34 goldens will re-baseline.
- **Avatar gradient:** `_lightGradient [#FFD4CC, #FEEAE6, #FEF5F4]` (coral) and `_darkGradient [#3D2020, #2D1818, #251518]` (dark coral) replaced by teal-family: light `[#D4EFF1, #E4F6F7, #F0FAFA]` / dark `[#1B3438, #172E31, #13282B]` per D-04.
- **Emoji background color:** `Color(0xFFF0F0F5)` (near-white) → `palette.textPrimary` which is `#E8F2F3` in dark mode (teal-tinted near-white, intent preserved) and `#112025` in light mode (dark text, correct for light backgrounds).

## Verification Results

```
grep -rn 'Color(0x' lib/features/profile/         → 0 hits (EXIT:1)
grep -rn 'AppColors\.' lib/features/profile/       → 0 hits (EXIT:1)
grep -rn '_editDark\|_profileDark\|_onboardingDark' → 0 hits (EXIT:1)
grep -rn 'isDark' lib/features/profile/            → 0 hits (EXIT:1)
flutter analyze lib/features/profile/              → No issues found!
```

## Threat Flags

None. Pure cosmetic color-constant substitution. No new network endpoints, auth paths, file access, or schema changes.

## Self-Check: PASSED

- [x] All 6 files modified exist and are committed
- [x] Task 1 commit `8719d142` exists: `git log --oneline | grep 8719d142`
- [x] Task 2 commit `08fa0aaf` exists: `git log --oneline | grep 08fa0aaf`
- [x] All grep gates return 0 hits
- [x] flutter analyze reports 0 issues
