---
quick_id: 260531-se5
phase: quick
plan: 260531-se5
subsystem: list-presentation
tags: [list, sort, flat-list, date-prefix, UI]
completed: 2026-05-31T11:42:37Z
duration_minutes: 15
commits:
  - ae85734e
files_modified:
  - lib/features/list/presentation/screens/list_screen.dart
  - lib/features/list/presentation/widgets/list_transaction_tile.dart
  - test/golden/list_transaction_tile_golden_test.dart
  - test/widget/features/list/list_transaction_tile_test.dart
---

# Quick Task 260531-se5: Flat Amount-Sort List + Date-Prefixed Tile Title

**One-liner:** Flat globally-sorted ListView for amount-sort mode with per-tile "M月d日 category" date prefix via DateFormatter, timestamp-sort grouped path unchanged.

## What Was Built

When `filter.sortConfig.sortField == SortField.amount`:
- `list_screen.dart` now renders a plain `ListView.builder` directly over the already-sorted `List<TaggedTransaction>` — `buildFlatList` is **not** called, so no `DayHeaderItem` rows are injected and no per-day grouping occurs
- Each tile receives `showDate: true`, producing a title of the form `5月31日 餐飲` (ja/zh) or `May 31 Dining` (en) via `DateFormatter.formatShortMonthDay`
- Divider logic in `_buildTile` uses `nextItem != null` (i.e. always show except last row) instead of `nextItem is TransactionRowItem`

When `filter.sortConfig.sortField == SortField.timestamp` (default):
- Existing `buildFlatList` grouped-by-day path is **completely unchanged** — day headers appear, tile title = L2 category only

## Changes

### `lib/features/list/presentation/screens/list_screen.dart`
- Added `import '../../../../shared/constants/sort_config.dart'` for `SortField`
- In `_buildList` data branch: conditional on `sortField` — amount branch builds flat ListView, timestamp branch uses existing buildFlatList path
- `_buildTile` signature: `List<dynamic> items` (was `List<ListItem>`), added `{bool showDate = false}` named param
- Passes `locale: locale, showDate: showDate` to `ListTransactionTile`
- Divider: `showDate ? nextItem != null : nextItem is TransactionRowItem`

### `lib/features/list/presentation/widgets/list_transaction_tile.dart`
- Added `import '../../../../infrastructure/i18n/formatters/date_formatter.dart'`
- Added `required this.locale` and `this.showDate = false` constructor params
- Title `Text` now evaluates `showDate` — when true uses `DateFormatter.formatShortMonthDay(taggedTx.transaction.timestamp, locale)` prefix

### Test fixes (Rule 2 — missing required argument)
- `test/golden/list_transaction_tile_golden_test.dart`: added `locale: const Locale('ja')`
- `test/widget/features/list/list_transaction_tile_test.dart`: added `locale: const Locale('ja')`

## Verification

- **flutter analyze (final line):** `4 issues found. (ran in 16.9s)` — all 4 are pre-existing third-party issues (firebase_messaging build artifact warning + 2 info items in build/, 2 deprecated `onReorder` info in `category_selection_screen.dart`); 0 issues in any file modified by this task
- **dart format:** 0 diff after formatting (3 files were formatted during implementation, then re-verified clean)
- **flutter test:** 2238/2238 passed (same count as pre-task baseline)

## Commit

`ae85734e` — feat(260531-se5): flat amount-sort list with date-prefixed tile title

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing required argument] Added locale param to test call sites**
- **Found during:** Task 3 (flutter analyze full project)
- **Issue:** `ListTransactionTile` gained `required this.locale`; two existing test files had no `locale:` argument, causing 2 analyzer errors
- **Fix:** Added `locale: const Locale('ja')` to `ListTransactionTile(...)` in both test files; no test logic changed
- **Files modified:** `test/golden/list_transaction_tile_golden_test.dart`, `test/widget/features/list/list_transaction_tile_test.dart`
- **Commit:** ae85734e (same commit)

None — plan executed as designed, with the above required test fix.

## Threat Surface Scan

No new network endpoints, auth paths, file access, or schema changes introduced. All changes are pure presentation-layer Dart — no trust boundary modifications.

## Self-Check

- [x] `lib/features/list/presentation/screens/list_screen.dart` exists and contains `SortField.amount`
- [x] `lib/features/list/presentation/widgets/list_transaction_tile.dart` exists and contains `showDate`, `DateFormatter.formatShortMonthDay`, `locale`
- [x] Commit `ae85734e` exists in git log
- [x] 2238 tests pass
- [x] 0 new analyzer issues introduced

## Self-Check: PASSED
