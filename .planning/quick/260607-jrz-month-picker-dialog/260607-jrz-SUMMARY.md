---
phase: quick-260607-jrz
plan: 01
subsystem: home/presentation
tags: [ui, home, month-picker, i18n, palette]
requires:
  - homeSelectedMonthProvider (HomeSelectedMonth.selectMonth)
  - ARB homeMonthLabel / analyticsTimeWindowChipLabelYear (pre-existing)
  - AppPalette (context.palette) tokens
provides:
  - showMonthPickerDialog() centered month-grid picker
  - HeroHeader onMonthTap tap-to-open API
affects:
  - lib/features/home/presentation/widgets/hero_header.dart
  - lib/features/home/presentation/screens/home_screen.dart
tech-stack:
  added: []
  patterns: [showDialog-returning-record, pure-ui-widget-returns-selection]
key-files:
  created:
    - lib/features/home/presentation/widgets/month_picker_dialog.dart
    - test/widget/features/home/presentation/widgets/month_picker_dialog_test.dart
  modified:
    - lib/features/home/presentation/widgets/hero_header.dart
    - lib/features/home/presentation/screens/home_screen.dart
    - test/widget/features/home/presentation/widgets/hero_header_test.dart
    - test/features/home/presentation/widgets/home_header_test.dart
decisions:
  - "Reused existing ARB keys (homeMonthLabel, analyticsTimeWindowChipLabelYear) — no gen-l10n needed"
  - "Dialog is a pure UI widget that returns (year, month); provider write stays in home_screen"
  - "Future months + future-year next arrow disabled via onPressed/onTap null"
metrics:
  duration: ~15m
  completed: 2026-06-07
---

# Quick Task 260607-jrz: 首页月份选择改为弹窗式月份网格 Summary

Replaced the home header's left/right month-step chevrons with a tap-to-open
centered month-grid picker dialog (`‹ YYYY年 ›` year nav + 3×4 month grid),
honoring the locked CONTEXT.md decisions (箭头去留 / 未来月份处理 / 视觉主题 / i18n).

## What Changed

- **New `month_picker_dialog.dart`** — `showMonthPickerDialog(context, {selectedYear, selectedMonth})`
  wraps `showDialog` with a centered rounded card (`backgroundColor: palette.background`,
  `RoundedRectangleBorder(16)`). Internals: a private `StatefulWidget` holds the displayed year.
  Year nav row uses `Icons.chevron_left` (always enabled, decrements year) + localized year title
  (`analyticsTimeWindowChipLabelYear`, accentPrimary) + `Icons.chevron_right` (disabled when
  `displayYear >= now.year`, tinted textTertiary). A `GridView.count(crossAxisCount: 3)` renders
  12 cells via `homeMonthLabel(month)`. Selected cell → neutral pill (`backgroundMuted`);
  future cell (`displayYear == now.year && month > now.month`) → greyed `textTertiary`, non-tappable;
  enabled tap pops `(year, month)`.
- **`hero_header.dart`** — removed `onPrevMonth`/`onNextMonth`/`showNextChevron` and the two chevron
  IconButtons + Transform.translate + SizedBox placeholder. Added required `onMonthTap`. Month label
  + `Icons.keyboard_arrow_down` now wrapped in one `InkWell` tap target. Kept label style
  (headlineSmall, w500, textPrimary) and the rest (Spacer, mode badge, settings) unchanged.
- **`home_screen.dart`** — `onMonthTap` opens the dialog and, on a non-null result (guarded by
  `context.mounted`), calls `homeSelectedMonthProvider.notifier.selectMonth(picked.year, picked.month)`.
  Removed the now-unused `now`/`isCurrentMonth` locals (the inner "view all" handler keeps its own).
- **Header tests** — both `hero_header_test.dart` and `home_header_test.dart` updated to the new API:
  chevron-navigation tests deleted; new assertions that no `chevron_left/right` render, that
  `keyboard_arrow_down` is present, and that tapping the label fires `onMonthTap`. Kept
  year/month/settings/badge tests.

## Verification

- **TDD (Task 1):** wrote 6 dialog widget tests FIRST → confirmed RED (widget/method missing) →
  implemented → GREEN (6/6). Covers: 12 cells render, future-month disabled in current year,
  prev arrow always present + next arrow disabled at current year, enabled tap pops + closes,
  returned record value, prev-year decrement re-enables next arrow.
- `flutter analyze` on all 4 touched lib/test files: **0 issues**. Whole-project analyze: 4 issues,
  all pre-existing and out of scope (firebase build artifact + 2 documented `onReorder` deprecations
  in `category_selection_screen.dart`, recorded in STATE.md as 遗留).
- `flutter test test/widget/features/home/ test/features/home/`: **112/112 passed** (incl. the new
  dialog test + rewired header tests).
- No-hardcoded-hex grep on `month_picker_dialog.dart` + `hero_header.dart`: **0** matches.
- No remaining references to `onPrevMonth`/`onNextMonth`/`showNextChevron` anywhere in lib/ or test/.
- No golden masters affected (no hero_header goldens exist; `home_hero_card_*` unaffected).

## Deviations from Plan

None — plan executed exactly as written. The plan anticipated unused-local removal in home_screen;
done. `analyticsTimeWindowChipLabelYear` takes a `String year` (passed `displayYear.toString()`),
matching the generated signature.

## Commits

- `80b16179` feat(260607-jrz): add month-grid picker dialog
- `15d11f73` feat(260607-jrz): rewire home header to tap-to-open month picker
- `99debfc6` test(260607-jrz): update header tests for tap-to-open month picker API

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: lib/features/home/presentation/widgets/month_picker_dialog.dart
- FOUND: test/widget/features/home/presentation/widgets/month_picker_dialog_test.dart
- FOUND commit: 80b16179, 15d11f73, 99debfc6
