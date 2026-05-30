---
phase: 28-transaction-tile-sort-filter-bar
plan: "04"
subsystem: list-widgets
tags: [category-filter, empty-state, riverpod, flutter-widgets, tristate-checkbox]
dependency_graph:
  requires:
    - "28-01"  # listFilterProvider.setCategories mutator
    - "28-02"  # listFilterProvider.categoryIds field
  provides:
    - "CategoryFilterSheet widget (L1/L2 multi-select bottom sheet)"
    - "ListEmptyState widget (two-path empty state)"
  affects:
    - "28-05"  # ListSortFilterBar opens CategoryFilterSheet
    - "28-06"  # ListScreen uses ListEmptyState
tech_stack:
  added: []
  patterns:
    - "ConsumerStatefulWidget with local Set<String> selection state"
    - "Tristate Checkbox (none/partial/all L1SelectState enum)"
    - "ProviderScope override pattern for async providers in widget tests"
key_files:
  created:
    - lib/features/list/presentation/widgets/list_category_filter_sheet.dart
    - lib/features/list/presentation/widgets/list_empty_state.dart
  modified:
    - test/widget/features/list/list_category_filter_sheet_test.dart
    - test/widget/features/list/list_empty_state_test.dart
decisions:
  - "Use ProviderScope (not UncontrolledProviderScope) in CategoryFilterSheet tests to avoid pending-timer issues from currentLocaleProvider async retries"
  - "Override currentLocaleProvider in tests alongside categoryRepositoryProvider to prevent async retry timers"
metrics:
  duration: "~30 minutes"
  completed: "2026-05-30"
  tasks_completed: 2
  tasks_total: 2
  files_created: 4
---

# Phase 28 Plan 04: CategoryFilterSheet + ListEmptyState Summary

**One-liner:** L1/L2 multi-select category filter bottom sheet with tristate checkboxes (C-05) and two-path empty state widget with receipt/search-off icons (C-06).

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Build CategoryFilterSheet — L1/L2 multi-select bottom sheet with tristate (C-05) | 0ef7913 | list_category_filter_sheet.dart, list_category_filter_sheet_test.dart |
| 2 | Build ListEmptyState structural placeholder (C-06) | e902376 | list_empty_state.dart, list_empty_state_test.dart |

## What Was Built

### CategoryFilterSheet (C-05)

`ConsumerStatefulWidget` with `required Set<String> initialSelected`. Local `_localSelected` state isolated from `listFilterProvider` until Apply is tapped.

Key implementation:
- `_loadCategories()` copies exact pattern from `category_selection_screen.dart` — `findActive()` → split L1/L2 by level, sort by `sortOrder`
- `_L1SelectState` enum (`none`, `partial`, `all`) for tristate logic
- `_l1State(String l1Id)` checks children count vs selected count
- `_toggleL1(String l1Id)` selects all children if state != `all`, deselects all otherwise
- Tristate Checkbox: `tristate: s == _L1SelectState.partial`, `value: s == partial ? null : (s == all)`
- Apply button: `ref.read(listFilterProvider.notifier).setCategories(Set<String>.unmodifiable(_localSelected))` then `Navigator.pop`
- Cancel button: `Navigator.pop` without touching provider
- Uses `categoryRepositoryProvider` from accounting (show import, no duplicate local provider file)

UI structure per C-05 spec:
- Container 65% viewport height, `BorderRadius.vertical(top: Radius.circular(16))`
- Drag handle: `Container(width: 40, height: 4, color: AppColors.borderDivider)`
- Header row with title + clear TextButton
- L1 rows: 48dp min with tristate Checkbox + emoji + name (`AppTextStyles.titleSmall`)
- L2 rows: indented 40dp with Checkbox + name (`AppTextStyles.bodyMedium`)
- Apply bar: 56dp height, FilledButton with `AppColors.accentPrimary` background

### ListEmptyState (C-06)

`ConsumerWidget` with `required bool isFilterActive`. Two distinct code paths:

1. `isFilterActive == false`: `Icons.receipt_long_outlined` (48dp, `AppColors.textTertiary`) + placeholder text, **no action button**
2. `isFilterActive == true`: `Icons.search_off_outlined` (48dp, `AppColors.textTertiary`) + placeholder text + `TextButton` calling `clearAll()`

## Test Results

Both test suites GREEN:

```
flutter test test/widget/features/list/list_category_filter_sheet_test.dart
  ✓ Apply button calls setCategories with _localSelected
  ✓ D-02: L1 tap cascades to all its L2 children
  ✓ tristate: L1 renders partial when some L2 selected, all when all L2 selected, none when none selected

flutter test test/widget/features/list/list_empty_state_test.dart
  ✓ isFilterActive: false — shows receipt_long_outlined icon, no clearAll button
  ✓ isFilterActive: true — shows search_off_outlined icon and clearAll TextButton
```

## Verification Results

- `flutter analyze lib/features/list/presentation/widgets/` — **0 issues**
- `list_category_filter_sheet.dart` contains `_l1State`, `tristate`, `setCategories`, `categoryRepositoryProvider`
- `list_category_filter_sheet.dart` does NOT have a local `repository_providers.dart` (uses `show` import from accounting)
- `list_empty_state.dart` contains `receipt_long_outlined` and `search_off_outlined` in two separate code paths
- No hardcoded hex colors in either file (`grep 'Color(0xFF'` returns 0)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test infrastructure: pending-timer from currentLocaleProvider async retries**
- **Found during:** Task 1 test execution
- **Issue:** `ProviderElement.triggerRetry` scheduled a background timer after `currentLocaleProvider` failed (it depends on `settingsRepositoryProvider` → `appDatabaseProvider`). Using `UncontrolledProviderScope` with only `categoryRepositoryProvider` override left the locale provider in error state, triggering a retry timer that outlived the widget tree.
- **Fix:** Switched tests from `UncontrolledProviderScope` + `ProviderContainer.test()` to `ProviderScope` (tied to widget lifecycle) with both `categoryRepositoryProvider.overrideWithValue(...)` AND `currentLocaleProvider.overrideWith((_) async => const Locale('ja'))` overrides.
- **Files modified:** `test/widget/features/list/list_category_filter_sheet_test.dart`
- **Commit:** 0ef7913

## Known Stubs

| File | Stub | Reason |
|------|------|--------|
| `list_category_filter_sheet.dart` | Header text `'カテゴリで絞り込む'` and `'クリア'` hardcoded Japanese | Phase 30 will replace with `S.of(context)` ARB keys per plan spec |
| `list_category_filter_sheet.dart` | Apply button text `'適用'` / `'キャンセル'` hardcoded | Phase 30 will replace with ARB keys |
| `list_empty_state.dart` | Placeholder text `'絞り込み条件に...'` and `'この月の...'` hardcoded | Phase 30 will replace with ARB keys `listEmptyFiltered`, `listEmptyMonth`, `listEmptyFilteredClear` per plan spec |

These stubs are **intentional** per the plan — Plan 28-04 explicitly states "Phase 30 will replace placeholder strings with S.of(context) ARB keys."

## Threat Surface Scan

No new trust boundaries introduced. CategoryFilterSheet reads existing `categoryRepositoryProvider` (no new data path). ListEmptyState is display-only with no data access.

## Self-Check: PASSED

- [x] `lib/features/list/presentation/widgets/list_category_filter_sheet.dart` — FOUND
- [x] `lib/features/list/presentation/widgets/list_empty_state.dart` — FOUND
- [x] Commit `0ef7913` — FOUND (feat(28-04): CategoryFilterSheet)
- [x] Commit `e902376` — FOUND (feat(28-04): ListEmptyState)
