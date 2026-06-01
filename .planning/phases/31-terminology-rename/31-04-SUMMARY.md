---
phase: 31-terminology-rename
plan: "04"
subsystem: theme/color-symbols
tags: [terminology-rename, AppColors, color-symbols, refactor]

requires:
  - 31-03 (ARB keys renamed; generated S getters use new vocab)

provides:
  - "AppColors light symbols renamed: survival→daily, survivalLight→dailyLight, soul→joy, soulLight→joyLight"
  - "AppColorsDark symbols renamed: soulRoiBg→joyRoiBg, soulRoiBorder→joyRoiBorder (joyFullnessBg/Border already done)"
  - "tagGreen body repointed from soulLight to joyLight (name kept per D-11)"
  - "All ~79 AppColors call sites across 27 lib files + 4 test files updated"
  - "Both qualified-ref and derived-symbol grep gates zero-hit"
  - "ZERO golden pixel delta (D-19 confirmed — pure identifier rename, no value mutation)"

affects:
  - 31-05 (class/file renames build on already-renamed AppColors symbols)
  - Phase 33 (COLOR-03 semantic token system now built on renamed symbols — no churn)

tech-stack:
  added: []
  patterns:
    - "Python in-place string replacement for bulk call-site updates (no backup files — worktree path length constraint)"
    - "Qualified-ref grep gate: AppColors.survival/.soul = 0 files"
    - "Derived-symbol grep gate: soulLight/survivalLight/soulRoiBg/soulRoiBorder = 0 hits"
    - "Bare-token exhaustive sweep on both theme files = 0 hits"

key-files:
  created: []
  modified:
    - lib/core/theme/app_colors.dart
    - lib/core/theme/app_theme_colors.dart
    - lib/features/accounting/presentation/screens/ocr_review_screen.dart
    - lib/features/accounting/presentation/screens/ocr_scanner_screen.dart
    - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
    - lib/features/accounting/presentation/screens/voice_input_screen.dart
    - lib/features/accounting/presentation/widgets/amount_display.dart
    - lib/features/accounting/presentation/widgets/ledger_type_selector.dart
    - lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart
    - lib/features/accounting/presentation/widgets/smart_keyboard.dart
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart
    - lib/features/accounting/presentation/widgets/voice_waveform.dart
    - lib/features/analytics/presentation/widgets/best_joy_story_strip.dart
    - lib/features/analytics/presentation/widgets/category_spend_donut_chart.dart
    - lib/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart
    - lib/features/analytics/presentation/widgets/joy_ledger_thin_sample_fallback.dart
    - lib/features/analytics/presentation/widgets/largest_expense_story_card.dart
    - lib/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart.dart
    - lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart
    - lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart
    - lib/features/analytics/presentation/widgets/total_spending_kpi_tile.dart
    - lib/features/family_sync/presentation/screens/group_choice_screen.dart
    - lib/features/home/presentation/screens/home_screen.dart
    - lib/features/home/presentation/widgets/hero_header.dart
    - lib/features/home/presentation/widgets/home_hero_card.dart
    - lib/features/home/presentation/widgets/home_transaction_tile.dart
    - lib/features/list/presentation/screens/list_screen.dart
    - lib/features/list/presentation/widgets/list_sort_filter_bar.dart
    - lib/features/list/presentation/widgets/list_transaction_tile.dart
    - test/core/theme/app_colors_test.dart
    - test/golden/list_transaction_tile_golden_test.dart
    - test/unit/core/theme/app_colors_test.dart
    - test/widget/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart_test.dart

decisions:
  - "Used Python in-place string replacement instead of Serena rename_symbol — worktree absolute path lengths exceeded macOS filename limit for perl -i backup files; Python replace() is equivalent for these qualified-name patterns"
  - "Test files updated alongside lib/ files to prevent compile failures (AppColors test references renamed symbols)"
  - "Pre-existing deprecated_member_use infos in category_selection_screen.dart (not modified by this plan) left as-is per scope boundary rule"
  - "Cross-surface sweep for broad soul/survival tokens returns 670+ hits — correct; plans 31-05/06 handle LedgerType/class/file renames in later waves"

metrics:
  duration: ~15min
  started: "2026-06-01T02:44:00Z"
  completed: "2026-06-01T02:59:17Z"
  tasks: 2
  files_changed: 33
---

# Phase 31 Plan 04: AppColors Ledger Symbol Rename Summary

Pure identifier rename — AppColors light + dark ledger color symbols renamed from survival/soul vocabulary to daily/joy vocabulary (D-11), zero pixel delta confirmed (D-19).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Rename AppColors + AppColorsDark symbols, repoint tagGreen + theme getter bodies + fix all comments + update all call sites | d37205e4 | 33 files (2 theme + 27 lib + 4 test) |
| 2 | Build-green gate — analyzer, custom_lint, generated-diff, exhaustive sweep, full suite zero golden delta | (gate only — no new files) | — |

## Verification Results

### AppColors Symbol Acceptance Criteria

- Qualified-ref grep zero-hit: `grep -rl 'AppColors\.survival\|AppColors\.soul' lib/` = **0 files**
- Derived-symbol grep zero-hit: `grep -rn '\b(soulLight|survivalLight|soulRoiBg|soulRoiBorder)\b' lib/` = **0 hits**
- Bare-token exhaustive sweep on both theme files: `grep -c 'soul\|survival' app_colors.dart app_theme_colors.dart` = **0 in both**
- New light symbols: `daily`, `dailyLight`, `joy`, `joyLight` defined at correct lines in app_colors.dart
- New dark symbols: `joyFullnessBg`, `joyFullnessBorder`, `joyRoiBg`, `joyRoiBorder` defined in AppColorsDark
- tagGreen: retained at line 46 with body `= joyLight` (not soulLight)
- doc-comment: `AppColors.daily` (was `AppColors.survival`)

### Build Gate Results

- `flutter analyze --no-fatal-infos` = 4 pre-existing issues (Firebase build package + 2 infos in category_selection_screen.dart not modified by this plan)
- `dart run custom_lint --no-fatal-infos` = **0 issues**
- `git diff --exit-code lib/generated lib/**/*.g.dart` = **clean** (no generated file changes)
- `flutter test` = **2244/2244 passed; 0 golden pixel failures (D-19 confirmed)**

## Deviations from Plan

### Auto-applied technique change

**[Rule 3 - Blocking Issue] Python replace() used instead of perl -i for bulk substitution**
- **Found during:** Task 1 bulk substitution
- **Issue:** Perl `-i` in-place edit creates backup files by appending the backup suffix to the filename; the worktree's absolute path is ~105 chars + the filename, causing "File name too long" errors on macOS (APFS max 255 chars) for the perl backup file
- **Fix:** Used Python's `str.replace()` with a script file — same ordered substitution (survivalLight before survival; soulLight before soul), no backup files
- **Files modified:** Same 27 lib + 4 test files as planned
- **Commit:** d37205e4

### Pre-existing analyzer infos (out of scope)

Two `deprecated_member_use` infos in `lib/features/accounting/presentation/screens/category_selection_screen.dart` (lines 386, 502). This file was NOT modified by this plan and these infos pre-exist. Per scope boundary rule, not fixed here.

## Known Stubs

None. This is a pure identifier rename — no data flows, no UI rendering stubs.

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Pure Dart symbol rename within theme layer.

## Self-Check: PASSED

- FOUND: lib/core/theme/app_colors.dart
- FOUND: lib/core/theme/app_theme_colors.dart
- FOUND: .planning/phases/31-terminology-rename/31-04-SUMMARY.md
- FOUND commit: d37205e4
- PASSED: 0 AppColors.survival/.soul references in lib/ or test/
- tagGreen = joyLight (correctly repointed)

