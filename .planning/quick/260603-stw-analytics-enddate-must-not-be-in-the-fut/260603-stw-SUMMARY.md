---
phase: 260603-stw
plan: "01"
subsystem: home/list UI — month navigation guard
tags: [bug-fix, ux, analytics, riverpod, flutter]
status: complete
dependency_graph:
  requires: []
  provides: [BUG-STW fix — future-month navigation blocked at UI + notifier level]
  affects:
    - lib/features/home/presentation/widgets/hero_header.dart
    - lib/features/home/presentation/screens/home_screen.dart
    - lib/features/home/presentation/providers/state_home.dart
    - lib/features/list/presentation/screens/list_screen.dart
tech_stack:
  added: []
  patterns:
    - collection-if in Flutter widget Row/actions for conditional chevron render
    - belt-and-suspenders: UI hide + notifier clamp guard
key_files:
  created: []
  modified:
    - lib/features/home/presentation/widgets/hero_header.dart
    - lib/features/home/presentation/screens/home_screen.dart
    - lib/features/home/presentation/providers/state_home.dart
    - lib/features/list/presentation/screens/list_screen.dart
    - test/features/home/presentation/widgets/home_header_test.dart
    - test/widget/features/home/presentation/widgets/hero_header_test.dart
    - test/widget/features/list/list_screen_refresh_test.dart
decisions:
  - SizedBox(28×28) placeholder in HeroHeader Row (not null/empty) preserves layout stability — same minWidth as the IconButton BoxConstraints
  - Collection-if `if (!isCurrentMonth) IconButton(...)` in AppBar actions is idiomatic; no SizedBox needed since AppBar actions shrinks-to-fit
  - nextMonth() clamp is belt-and-suspenders: UI chevron hide is the primary guard; clamp protects programmatic callers (deep-link, tests)
metrics:
  duration: "~15min"
  completed: "2026-06-03"
  tasks_completed: 3
  files_changed: 7
---

# Phase 260603-stw Plan 01: 未来月份越界修复（隐藏向右箭头）Summary

Fix the "endDate must not be in the future" analytics crash by preventing forward month navigation when already on the current month. Applied via `showNextChevron: bool` on HeroHeader (home dashboard) and a collection-if guard in ListScreen AppBar; belt-and-suspenders clamp in HomeSelectedMonth.nextMonth() prevents programmatic bypasses.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | 18e62888 | feat(260603-stw): add showNextChevron to HeroHeader + clamp nextMonth() |
| Task 2 | c0cc3786 | feat(260603-stw): hide ListScreen AppBar right chevron when on current month |

## What Was Built

### Task 1 — HeroHeader showNextChevron + notifier clamp

**`lib/features/home/presentation/widgets/hero_header.dart`**
- Added required `bool showNextChevron` parameter to `HeroHeader` constructor
- In the build Row, replaced unconditional right `IconButton` with conditional:
  `if (showNextChevron) IconButton(...) else SizedBox(width: 28, height: 28)`
  The `SizedBox` matches the existing `BoxConstraints(minWidth: 28)` to preserve layout stability.

**`lib/features/home/presentation/screens/home_screen.dart`**
- After reading `selectedMonth`, derives `isCurrentMonth = year == now.year && month == now.month`
- Passes `showNextChevron: !isCurrentMonth` to `HeroHeader`

**`lib/features/home/presentation/providers/state_home.dart`**
- Added clamp guard in `nextMonth()`: returns early when `state.year == now.year && state.month == now.month`

**Tests updated:**
- `test/features/home/presentation/widgets/home_header_test.dart` — all 7 existing calls updated to `showNextChevron: true` (month 3 = past); new test: "HomeHeader hides right chevron when showNextChevron is false"
- `test/widget/features/home/presentation/widgets/hero_header_test.dart` — helper parameterized with `showNextChevron`; new test: "right chevron absent when showNextChevron is false"

### Task 2 — ListScreen AppBar right chevron guard

**`lib/features/list/presentation/screens/list_screen.dart`**
- Derives `isCurrentMonth` after `filter = ref.watch(listFilterProvider)`
- Uses `if (!isCurrentMonth) IconButton(...)` collection-if in `AppBar actions:`

**Tests added:**
- `test/widget/features/list/list_screen_refresh_test.dart` — `_pumpScreen` parameterized with `year`/`month`; two new tests: "right chevron absent when on current month" and "right chevron present when on a past month"

### Task 3 — Full suite verification
- `flutter analyze lib/ test/` — 2 pre-existing `onReorder` deprecation infos in `category_selection_screen.dart` (not touched by this task); 0 new issues
- `flutter test` — **2303/2303 pass** (4 new tests added vs. 2299 baseline)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None. Changes are purely UI-layer hide + notifier clamp guard. No new network endpoints or trust boundaries introduced.

## Self-Check: PASSED

- [x] `lib/features/home/presentation/widgets/hero_header.dart` — file contains "showNextChevron"
- [x] `lib/features/home/presentation/screens/home_screen.dart` — file contains "isCurrentMonth"
- [x] `lib/features/home/presentation/providers/state_home.dart` — file contains "clamp"
- [x] `lib/features/list/presentation/screens/list_screen.dart` — file contains "isCurrentMonth"
- [x] Commit 18e62888 exists
- [x] Commit c0cc3786 exists
- [x] 2303/2303 tests pass
- [x] 0 new analyzer issues
