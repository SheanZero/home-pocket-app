---
phase: 34-golden-re-baseline-verification
plan: "01"
subsystem: testing
tags: [flutter, golden-tests, dark-mode, ThemeMode, AppPalette]

requires:
  - phase: 33-color-token-system-consolidation
    provides: ThemeExtension<AppPalette> token system + app-wide dark-mode rollout

provides:
  - 7 light-only golden test files upgraded with ThemeMode-parameterized _wrap() and dark variant testWidgets blocks
  - 27 new dark golden stubs ready for first-run PNG generation in Plan 34-02
  - list_transaction_tile dark variants use AppPalette.dark.* constructor params (Pitfall 4 fix)
  - list_calendar_header dark variants preserve _FixedListFilter() determinism override (Pitfall 2 preserved)
  - 2 orphaned PNG masters (summary_cards_en/ja.png) deleted

affects:
  - 34-02 (golden re-baseline run — depends on these dark stubs)
  - any future plan touching golden test files

tech-stack:
  added: []
  patterns:
    - "ThemeMode-parameterized _wrap(): add ThemeMode themeMode = ThemeMode.light param, add darkTheme: ThemeData.dark() + themeMode: themeMode to MaterialApp"
    - "Dark variant naming: {widget}_dark_{locale}.png (matching daily_vs_joy_card_dark_ja.png convention)"
    - "Tile dark fixture: pass AppPalette.dark.* constructor params for direct-injected colors (bypasses context.palette)"

key-files:
  created: []
  modified:
    - test/golden/list_day_group_header_golden_test.dart
    - test/golden/amount_display_golden_test.dart
    - test/golden/list_sort_filter_bar_golden_test.dart
    - test/golden/list_category_filter_sheet_golden_test.dart
    - test/golden/list_empty_state_golden_test.dart
    - test/golden/list_calendar_header_golden_test.dart
    - test/golden/list_transaction_tile_golden_test.dart
  deleted:
    - test/golden/goldens/summary_cards_en.png
    - test/golden/goldens/summary_cards_ja.png

key-decisions:
  - "ThemeMode.dark used explicitly (not ThemeMode.system) per Pitfall 4 / D-01 anti-pattern"
  - "list_transaction_tile _wrap() refactored to accept optional tagBgColor/tagTextColor/categoryColor params so dark variants can inject AppPalette.dark.* values without duplicating the entire _wrap body"
  - "list_empty_state dark variant added inline in the for-loop (single ThemeMode.dark reference generates 9 dark test stubs: 3 variants x 3 locales)"

patterns-established:
  - "Dark golden wrapper: always provide both theme: ThemeData.light() AND darkTheme: ThemeData.dark() alongside themeMode: themeMode"
  - "Tile golden fixture: for widgets accepting explicit Color params, dark variant must inject AppPalette.dark.* values"

requirements-completed:
  - COLOR-04

duration: 20min
completed: 2026-06-01
---

# Phase 34 Plan 01: Dark-Mode Golden Test Infrastructure Summary

**27 new dark golden stubs added to all 7 light-only golden test files via ThemeMode-parameterized _wrap(), with Pitfall 2/4 fixes and 2 orphaned PNGs deleted**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-06-01T13:12:00Z
- **Completed:** 2026-06-01T13:32:33Z
- **Tasks:** 2
- **Files modified:** 7 test files + 2 PNG deletions

## Accomplishments

- All 7 light-only golden test files now accept `ThemeMode` parameter in `_wrap()` with `darkTheme: ThemeData.dark()` + `themeMode: themeMode` in `MaterialApp`
- 27 new dark testWidgets blocks added: 3 (list_day_group_header) + 3 (amount_display) + 3 (list_sort_filter_bar) + 3 (list_category_filter_sheet) + 3 (list_calendar_header) + 3 (list_transaction_tile) + 9 (list_empty_state)
- `list_calendar_header` dark variants preserve `_FixedListFilter()` determinism override (Pitfall 2 guard)
- `list_transaction_tile` dark variants use `AppPalette.dark.dailyLight` / `AppPalette.dark.daily` for fixture color params (Pitfall 4 fix)
- Deleted `summary_cards_en.png` and `summary_cards_ja.png` orphaned PNGs (no test exists to regenerate them)
- `flutter analyze test/golden/` returns 0 issues

## Task Commits

1. **Task 1: Add ThemeMode param and dark testWidgets to 5 simpler golden test files** - `53e6bb1c` (feat)
2. **Task 2: Add dark variants to list_calendar_header and list_transaction_tile + delete orphans** - `9aee1bb0` (feat)

## Files Created/Modified

- `test/golden/list_day_group_header_golden_test.dart` - Added ThemeMode param to _wrap(); 3 dark testWidgets (en/ja/zh)
- `test/golden/amount_display_golden_test.dart` - Added ThemeMode param to _wrap(); 3 dark testWidgets (jpy/usd/cny); also added explicit theme: ThemeData.light() (was missing)
- `test/golden/list_sort_filter_bar_golden_test.dart` - Added ThemeMode param to _wrap(); 3 dark testWidgets (en/ja/zh)
- `test/golden/list_category_filter_sheet_golden_test.dart` - Added ThemeMode param to _wrap(); 3 dark testWidgets (en/ja/zh)
- `test/golden/list_empty_state_golden_test.dart` - Added ThemeMode param to _wrap(); 9 dark testWidgets via for-loop (3 variants × 3 locales)
- `test/golden/list_calendar_header_golden_test.dart` - Added ThemeMode param to _wrap(); 3 dark testWidgets preserving _FixedListFilter() override
- `test/golden/list_transaction_tile_golden_test.dart` - Refactored _wrap() to accept optional color params; 3 dark testWidgets using AppPalette.dark.*
- `test/golden/goldens/summary_cards_en.png` - DELETED (orphaned — no test exists)
- `test/golden/goldens/summary_cards_ja.png` - DELETED (orphaned — no test exists)

## Decisions Made

- `list_transaction_tile` `_wrap()` refactored to accept optional `tagBgColor`/`tagTextColor`/`categoryColor` params with `AppPalette.light.*` defaults — allows dark variants to pass `AppPalette.dark.*` without duplicating the entire wrapper body (Pitfall 4)
- Dark golden naming convention: `{widget}_dark_{locale}.png` (consistent with `daily_vs_joy_card_dark_ja.png` project convention)
- `ThemeMode.dark` used explicitly everywhere — never `ThemeMode.system` (non-deterministic on CI)

## Deviations from Plan

None — plan executed exactly as written. All 7 files edited with ThemeMode param + dark variants. _FixedListFilter preserved. AppPalette.dark.* used in tile dark variants. Orphans deleted. flutter analyze 0 issues.

## Known Stubs

All 27 new `matchesGoldenFile(...)` calls reference PNG paths that do not yet exist on disk. This is **intentional** — these are test stubs awaiting first-run generation in Plan 34-02 (`--update-goldens`). The golden comparator will fail these tests until Plan 34-02 runs and creates the master PNGs.

## Threat Flags

None — this plan edits only `test/golden/*.dart` (golden test files) and deletes 2 orphaned PNG masters. No production code, network, auth, user input, or persistence changes.

## Issues Encountered

None.

## Next Phase Readiness

- Plan 34-02 can now proceed with the full re-baseline (`flutter test --update-goldens`)
- The 7 files each have functioning dark testWidgets stubs; first `--update-goldens` run will generate 27 new dark PNG masters
- `flutter analyze test/golden/` is 0 issues baseline for Plan 34-02

---
*Phase: 34-golden-re-baseline-verification*
*Completed: 2026-06-01*
