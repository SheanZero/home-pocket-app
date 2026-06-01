---
phase: 33-color-token-system-consolidation
plan: "05a"
subsystem: family_sync
tags: [color-tokens, palette-migration, ADR-018, dark-mode, family-sync, Bucket-B, Bucket-C]
dependency_graph:
  requires: [33-02]
  provides: [family_sync color migration complete, Bucket B coral→teal, Bucket C purple→teal-family memberGradient*]
  affects:
    - lib/features/family_sync/presentation/screens/create_group_screen.dart
    - lib/features/family_sync/presentation/screens/member_approval_screen.dart
    - lib/features/family_sync/presentation/screens/join_group_screen.dart
    - lib/features/family_sync/presentation/screens/confirm_join_screen.dart
    - lib/features/family_sync/presentation/screens/group_choice_screen.dart
    - lib/features/family_sync/presentation/screens/group_management_screen.dart
    - lib/features/family_sync/presentation/screens/waiting_approval_screen.dart
    - lib/features/family_sync/presentation/widgets/member_list_tile.dart
tech_stack:
  added: []
  patterns:
    - context.palette.* replacing all AppColors.* and Color(0x...) literals
    - palette.fabGradientEnd/fabGradientStart teal gradient replacing coral (0xFFE85A4F/0xFFF08070)
    - palette.memberGradientA/B/C teal-family replacing purple presets (0xFFE8D5F5/0xFFF3EAF9/0xFFFAF5FD)
    - palette.surfaceScrimMedium/Light replacing pure-black alpha overlays
    - Non-const TextStyle/Icon widgets (const removed where palette color needed)
key_files:
  created: []
  modified:
    - lib/features/family_sync/presentation/screens/create_group_screen.dart
    - lib/features/family_sync/presentation/screens/member_approval_screen.dart
    - lib/features/family_sync/presentation/screens/join_group_screen.dart
    - lib/features/family_sync/presentation/screens/confirm_join_screen.dart
    - lib/features/family_sync/presentation/screens/group_choice_screen.dart
    - lib/features/family_sync/presentation/screens/group_management_screen.dart
    - lib/features/family_sync/presentation/screens/waiting_approval_screen.dart
    - lib/features/family_sync/presentation/widgets/member_list_tile.dart
decisions:
  - "D-03/D-04: Bucket C purple member gradient replaced by palette.memberGradientA/B/C (teal-light family per ADR-018)"
  - "D-04: Color(0x0A000000) mapped to palette.surfaceScrimMedium; Color(0x14000000) mapped to palette.surfaceScrimLight (both are identity-neutral alpha overlays kept as named tokens)"
  - "group_choice_screen _greenGradient [0xFFD4E8CC, 0xFFF0F8EC] replaced by [palette.successLight, palette.card] per plan Task 2 Step 4 (D-04 re-hue green tint to teal-family)"
  - "group_choice_screen Color(0xFFFEF5F4) iconBackgroundColor replaced by palette.accentPrimaryLight (closest teal-light analog)"
  - "const removed from TextStyle/Icon widgets referencing palette colors (context.palette is not const-compatible)"
  - "No isDark ternaries introduced anywhere — all 8 files now get full dark support for free via ThemeExtension"
metrics:
  duration: "12 minutes"
  completed: "2026-06-01"
  tasks_completed: 2
  files_modified: 8
  color_literals_replaced: 31
---

# Phase 33 Plan 05a: Family Sync Color Token Migration Summary

Migration of all color references in `lib/features/family_sync/` (7 screens + 1 widget) from legacy `AppColors.*` static constants and hardcoded `Color(0x...)` literals to `context.palette.*` ThemeExtension tokens, replacing the 4-screen coral gradient copy-paste (Bucket B) with teal palette tokens and re-huing the purple member gradient presets (Bucket C) to teal-family `memberGradient*` tokens (D-04).

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Migrate 4 Bucket B screens (coral gradient replacement) | 4e8b3d8c | create_group, member_approval, join_group, confirm_join |
| 2 | Migrate group_choice, group_management, waiting_approval + member_list_tile | f9c79504 | 4 files |

## What Was Built

### Bucket B — Coral Gradient Replacement (4 screens)

All 4 screens that shared the coral gradient copy-paste pattern now use teal tokens:

- `Color(0xFFE85A4F)` → `palette.fabGradientEnd` (teal `#0E9AA7` light / `#3FC2CE` dark)
- `Color(0xFFF08070)` → `palette.fabGradientStart` (teal `#2BB6C2` light / `#4FCDD9` dark)
- `Color(0x28E85A4F)` → `palette.actionShadow` (teal-alpha shadow)
- `Color(0x0A000000)` → `palette.surfaceScrimMedium` (named identity-neutral token)
- `Color(0x14000000)` → `palette.surfaceScrimLight` (named identity-neutral token)

### Bucket C — Member Gradient Re-hue (member_approval, join_group, group_choice, member_list_tile)

Purple presets replaced by teal-light family:

- `Color(0xFFE8D5F5)` → `palette.memberGradientA` (`#D4EEF4` light / `#1B3438` dark)
- `Color(0xFFF3EAF9)` → `palette.memberGradientB` (`#E5F5F7` light / `#172E31` dark)
- `Color(0xFFFAF5FD)` → `palette.memberGradientC` (`#F0F9FA` light / `#13282B` dark)

### Additional Bucket F (group_choice_screen)

- `_greenGradient [0xFFD4E8CC, 0xFFF0F8EC]` → `[palette.successLight, palette.card]`
- `Color(0xFFFEF5F4)` iconBackgroundColor → `palette.accentPrimaryLight`
- `AppColors.dailyLight` → `palette.dailyLight`
- `AppColors.daily` → `palette.daily`

### All AppColors.* References

Every `AppColors.background`, `AppColors.textPrimary`, `AppColors.accentPrimary`, etc. across all 8 files replaced with `palette.*` equivalents.

## Deviations from Plan

None — plan executed exactly as written.

The `_purpleGradient` and `_greenGradient` top-level `const` declarations were removed; gradient colors are now inlined in `build()` via `context.palette`. This is exactly as planned (plan says "If _greenGradient is a static const field, remove it and use the palette values inline in build()").

## Known Stubs

None. All replacements wire to real palette tokens with both light and dark values in `AppPalette.light` and `AppPalette.dark`.

## Self-Check: PASSED

- All 8 files exist at expected paths: PASSED
- Task commits 4e8b3d8c and f9c79504 exist: PASSED
- `grep -rn 'Color(0x' lib/features/family_sync/` returns 0 hits: PASSED
- `grep -rn 'AppColors\.' lib/features/family_sync/` returns 0 hits: PASSED
- `grep -rn 'context\.wm' lib/features/family_sync/` returns 0 hits: PASSED
- `flutter analyze lib/features/family_sync/` returns 0 issues: PASSED
