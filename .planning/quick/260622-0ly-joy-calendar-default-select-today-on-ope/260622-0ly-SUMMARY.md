---
phase: quick-260622-0ly
plan: 01
subsystem: analytics / joy-calendar
status: complete
tags: [analytics, joy-calendar, presentation, default-select]
requires:
  - _JoyCalendarBodyState (lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart)
  - perDayJoyCountsProvider / joyDayTransactionsProvider (state_analytics.dart)
provides:
  - _defaultSelectedDay() + initState + didUpdateWidget on _JoyCalendarBodyState
  - deterministic widget tests for default-select-today behavior
affects:
  - lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart
  - test/widget/features/analytics/presentation/widgets/cards/joy_calendar_card_test.dart
tech_stack:
  added: []
  patterns:
    - "initState/didUpdateWidget anchor-driven default selection (single _selectedDay state drives both ring highlight + inline expand)"
    - "deterministic (non-golden) widget tests comparing only y/m/d to avoid clock races"
key_files:
  created: []
  modified:
    - lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart
    - test/widget/features/analytics/presentation/widgets/cards/joy_calendar_card_test.dart
decisions:
  - "Reuse single _selectedDay state: assigning a default == 'highlight + expand', no state split needed"
  - "_defaultSelectedDay returns null off the current month → all May-2026-pinned goldens stay byte-identical (zero re-baseline)"
  - "didUpdateWidget only recomputes when anchor year/month changes; same-month data refresh preserves user's manual tap"
  - "Tests are deterministic (not goldens) and endDate-driven (anchor derived in-card) — compare y/m/d only to avoid millisecond clock races"
metrics:
  duration: ~6 min
  completed: 2026-06-22
  tasks: 2
  files: 2
---

# Quick 260622-0ly: 小确幸日历打开时默认选中今天 Summary

打开统计页时，小确幸日历（JoyCalendar）在查看当前月份时自动高亮今天的格子并自动展开今天的「小确幸」内联明细面板（无记录则显示空状态文案）；翻到其它月份不自动选中且清空旧选中；同月内数据刷新保留用户手动点击的那天。

## What Was Built

### Task 1 — `_JoyCalendarBodyState` 默认选中今天 (commit `3eabc907`)
Added three pieces to `_JoyCalendarBodyState`, leaving `build` / `onDayTap` / the heatmap / the inline panel untouched:

- **`_defaultSelectedDay()`** — reads `DateTime.now()` and `widget.anchor`; returns `DateTime(now.year, now.month, now.day)` (y/m/d only) iff today falls in the anchor's month, else `null`.
- **`initState()`** — `super.initState()` then `_selectedDay = _defaultSelectedDay()` (auto-select today on open when viewing the current month).
- **`didUpdateWidget()`** — when `anchor` year **or** month changed, `setState(() => _selectedDay = _defaultSelectedDay())` (page to current month → select today; page away → clear). Same-month anchor (pull-to-refresh, counts change but anchor unchanged) → no setState, preserving the manual selection.

Single `_selectedDay` state already drives both the heatmap ring highlight and the inline `AnimatedSize` panel, so assigning a default value is equivalent to the user tapping today.

### Task 2 — 决定论 widget 测试 (commit `1811a22f`)
Added a `group('default-select-today', ...)` with two deterministic (non-golden) cases plus a `_currentMonthSubject()` helper:

- **Case A** — `endDate` in the current month so the card-derived anchor == current month; overrides keyed on the current month / today. Asserts the inline panel `joy_calendar_inline_panel` is `findsOneWidget` (auto-expanded, no tap) and `heatmap.selectedDay` y/m/d == `DateTime.now()` y/m/d (y/m/d only — avoids millisecond clock race between the test's and the widget's `DateTime.now()`).
- **Case B** — reuses the existing `_subject()` (window pinned to May 2026); asserts the inline panel is `findsNothing` and `heatmap.selectedDay == null` (today ∉ May 2026 → `_defaultSelectedDay()` returns null → behavior identical to before).

## Verification

- `flutter analyze` → **No issues found.**
- FULL `flutter test` → **All tests passed!** 3083/3083 (includes architecture tests hardcoded_cjk_ui_scan / color_literal_scan, all goldens, coverage gate).
- `git status` golden check → **zero `test/**/*.png` changes** — no golden re-baseline (as predicted: every existing golden's window is pinned to May 2026, today is never in May 2026, so `_defaultSelectedDay()` returns null there → visuals byte-identical).
- Exactly 2 source files changed across both atomic commits.

## Deviations from Plan

None — plan executed exactly as written.

Note: the Task 1 `<verify>` automated one-liner reports a false negative because the `flutter analyze <file>` output banner contains the Swift-Package-Manager deprecation text ("This will become an error in a future version…"), which the `grep -ci 'error\|warning'` counter picks up. The file itself analyzes clean ("No issues found!"), all three required grep markers (`_defaultSelectedDay` / `void initState` / `didUpdateWidget`) are present, and the authoritative full `flutter analyze` is "No issues found." Done criteria met.

## Authentication Gates

None.

## Known Stubs

None.

## Commits

- `3eabc907` feat(260622-0ly): 小确幸日历打开时默认选中今天
- `1811a22f` test(260622-0ly): 小确幸日历默认选中今天的决定论 widget 测试

## Self-Check: PASSED

- FOUND: lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart (contains `_defaultSelectedDay` / `initState` / `didUpdateWidget`)
- FOUND: test/widget/features/analytics/presentation/widgets/cards/joy_calendar_card_test.dart (contains `default-select-today` group)
- FOUND commit: 3eabc907
- FOUND commit: 1811a22f
