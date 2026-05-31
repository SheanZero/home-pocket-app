---
phase: 260531-oqn-ui
plan: 01
subsystem: list-screen
tags: [ui-polish, calendar, settings, list-tile, sort]
type: quick-task
status: complete
dependency_graph:
  requires: []
  provides:
    - ListScreen Scaffold+AppBar with month navigation
    - CalendarHeaderWidget weekStartDay + Saturday blue + empty-cell alignment
    - WeekStartDay persisted setting in AppSettings
    - SortField enum with timestamp+amount only (updatedAt removed)
    - ListTransactionTile rebuilt layout
  affects:
    - lib/features/list/presentation/screens/list_screen.dart
    - lib/features/list/presentation/widgets/list_calendar_header.dart
    - lib/features/list/presentation/widgets/list_transaction_tile.dart
    - lib/features/list/presentation/widgets/list_sort_filter_bar.dart
    - lib/features/settings/domain/models/app_settings.dart
    - lib/features/settings/presentation/widgets/appearance_section.dart
    - lib/data/repositories/settings_repository_impl.dart
    - lib/shared/constants/sort_config.dart
tech_stack:
  added: []
  patterns:
    - Static L1 icon map in ListScreen._resolveL1IconForCategory
    - WeekStartDay enum + SharedPreferences persistence following _getThemeMode() pattern
    - CalendarHeaderWidget reads appSettingsProvider for weekStartDay
key_files:
  created: []
  modified:
    - lib/features/list/presentation/screens/list_screen.dart
    - lib/features/list/presentation/widgets/list_calendar_header.dart
    - lib/features/list/presentation/widgets/list_transaction_tile.dart
    - lib/features/list/presentation/widgets/list_sort_filter_bar.dart
    - lib/features/list/domain/models/list_sort_config.dart
    - lib/features/settings/domain/models/app_settings.dart
    - lib/features/settings/domain/repositories/settings_repository.dart
    - lib/data/repositories/settings_repository_impl.dart
    - lib/features/settings/presentation/widgets/appearance_section.dart
    - lib/shared/constants/sort_config.dart
    - lib/data/daos/transaction_dao.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
decisions:
  - Saturday numeral color is Color(0xFF1565C0) (Material Blue 800) — explicitly specified requirement
  - SortField default changed from updatedAt to timestamp (timestamp-desc)
  - ListTransactionTile removes formattedTime; adds l1Icon + merchant parameters
  - appSettingsProvider override added to all tests that pump CalendarHeaderWidget
  - list_screen_refresh_test drag changed to SingleChildScrollView descendant of RefreshIndicator (Scaffold layout change)
metrics:
  duration: ~90 minutes
  completed_date: "2026-05-31"
  tasks: 4
  files_modified: 22
---

# Phase 260531-oqn Plan 01: 日历列表页UI调整 Summary

List/Calendar screen UI polish delivering six targeted changes: Material AppBar with month navigation, empty-cell vertical alignment placeholder, persisted weekStartDay setting with Saturday blue + Sunday black numerals, removal of updatedAt from sort options, and rebuilt ListTransactionTile with L1 icon + L2 name layout.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | ListScreen AppBar + empty-cell placeholder | b0926be3 | list_screen.dart, list_calendar_header.dart, list_transaction_tile.dart |
| 2 | Week-start setting + weekend colors | 6efd1de9 | app_settings.dart, appearance_section.dart, list_calendar_header.dart, ARBs |
| 3 | Remove updatedAt sort option | 8b75cd91 | sort_config.dart, list_sort_config.dart, transaction_dao.dart |
| 3b | Test fixes for updatedAt removal | 002ac6b3 | 4 test files |
| 4 | Tile goldens re-baselined | 09faf694 | list_transaction_tile_{ja,zh,en}.png |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] list_screen_refresh_test.dart drag approach broken by Scaffold wrapping**
- **Found during:** Task 1 verification
- **Issue:** After adding Scaffold+AppBar to ListScreen, dragging `find.byType(RefreshIndicator)` no longer reached the scrollable widget inside it. The drag hit the wrong RenderObject, causing calendarDailyTotalsProvider to not get re-fetched in test 3 (actual: 1 call, expected: >1).
- **Fix:** Changed drag target to `find.descendant(of: RefreshIndicator, matching: SingleChildScrollView)` which is the actual scrollable inside the RefreshIndicator; also removed outer Scaffold wrapper from `_pumpScreen` since ListScreen now provides its own.
- **Files modified:** test/widget/features/list/list_screen_refresh_test.dart
- **Commit:** b0926be3

**2. [Rule 1 - Bug] SortField.updatedAt references in tests caused compile-time failures**
- **Found during:** Task 3 full test run (4 test files failed to load)
- **Issue:** Removing `SortField.updatedAt` from the enum broke 4 test files that referenced it (registerFallbackValue calls and explicit sort field assertions).
- **Fix:** Updated all 4 test files: replaced `SortField.updatedAt` with `SortField.timestamp`, updated test descriptions, updated the sort field assertion in get_list_transactions_use_case_test to expect `timestamp` instead of `updatedAt`.
- **Files modified:** 4 test files in test/unit/ and test/widget/
- **Commit:** 002ac6b3

**3. [Rule 2 - Missing functionality] appSettingsProvider override needed in all CalendarHeaderWidget tests**
- **Found during:** Task 2 implementation
- **Issue:** CalendarHeaderWidget now watches appSettingsProvider for weekStartDay. All tests that pump CalendarHeaderWidget would fail without an override for settingsRepositoryProvider.
- **Fix:** Added `appSettingsProvider.overrideWith(...)` with default monday to all 3 affected test fixtures.
- **Files modified:** 3 golden/widget test files
- **Commit:** 6efd1de9

## Verification Results

- **build_runner:** 0 errors
- **flutter gen-l10n:** 0 errors
- **flutter analyze lib/:** 2 pre-existing `info` issues in `category_selection_screen.dart` (deprecated `onReorder`, pre-existing on main branch); 0 issues in all new/modified files
- **flutter test:** 2238 tests ALL PASS
- **Golden tests:** All 43 golden tests pass (re-baselined: list_calendar_header x3, list_sort_filter_bar x3, list_transaction_tile x3)

## Known Stubs

None — all behavior is fully implemented.

## Threat Flags

No new security-relevant surface. T-oqn-01 (SharedPreferences WeekStartDay parsing) mitigated: `_getWeekStartDay()` uses `firstWhere(... orElse: () => WeekStartDay.monday)`.

## Self-Check: PASSED

- list_screen.dart: FOUND (Scaffold+AppBar with month nav)
- list_calendar_header.dart: FOUND (weekStartDay + blue Saturday + empty-cell SizedBox)
- app_settings.dart: FOUND (WeekStartDay enum + field)
- sort_config.dart: FOUND (timestamp + amount only, no updatedAt)
- list_transaction_tile.dart: FOUND (l1Icon + merchant + no formattedTime)
- All commits: b0926be3, 6efd1de9, 8b75cd91, 09faf694, 002ac6b3 found in git log
