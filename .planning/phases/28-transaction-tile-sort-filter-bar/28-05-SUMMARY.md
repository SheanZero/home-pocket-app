---
phase: 28-transaction-tile-sort-filter-bar
plan: "05"
subsystem: list-feature
tags: [widget, sort, filter, chip-bar, riverpod, tdd-green]
dependency_graph:
  requires:
    - 28-03  # listFilterProvider with setSort/setLedgerFilter/setCategories/clearAll mutators
    - 28-04  # CategoryFilterSheet, ListTransactionTile, ListDayGroupHeader
  provides:
    - lib/features/list/presentation/widgets/list_sort_filter_bar.dart
  affects:
    - lib/features/list/presentation/screens/list_screen.dart  # consumer of ListSortFilterBar
tech_stack:
  added: []
  patterns:
    - ConsumerStatefulWidget with TextEditingController + local _searchExpanded bool
    - showMenu<SortField> positioned via RenderBox.localToGlobal + RelativeRect
    - AnimatedContainer expand/collapse pattern for inline search field
    - ProviderScope + currentLocaleProvider.overrideWith in widget tests (prevents async retry timers)
key_files:
  created:
    - lib/features/list/presentation/widgets/list_sort_filter_bar.dart
  modified:
    - test/widget/features/list/list_sort_filter_bar_test.dart
decisions:
  - "_L10n helper class used instead of S.of(context) to provide locale-aware strings in non-build methods without passing BuildContext; Japanese values match ARB keys added in 28-01"
  - "ProviderScope + currentLocaleProvider.overrideWith pattern adopted for tests (matches CategoryFilterSheet test precedent, avoids pending-timer failures from async settings chain)"
metrics:
  duration_minutes: 7
  completed: "2026-05-30T12:07:51Z"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 2
---

# Phase 28 Plan 05: ListSortFilterBar Summary

Build the ListSortFilterBar pinned chip bar (C-03) — a ConsumerStatefulWidget wiring sort field selection, direction toggle, three mutually-exclusive ledger chips, a category-count chip opening CategoryFilterSheet, an expandable search field, and a conditional clear chip. All interactions route through the existing listFilterProvider mutators. Turn the Wave 0 RED stubs GREEN.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Build ListSortFilterBar + turn bar tests GREEN | 1cefd25 | list_sort_filter_bar.dart (new), list_sort_filter_bar_test.dart (updated) |

## Verification Results

- `flutter test test/widget/features/list/list_sort_filter_bar_test.dart` → **3/3 PASS**
  - SC#4: sort chip label `更新日時` found, generic `Sort` absent ✓
  - FILTER-02: tap `生存` → `ledgerType == LedgerType.survival` ✓
  - FILTER-04: clear chip absent initially, appears after `setLedgerFilter(soul)` ✓
- `flutter analyze lib/features/list/presentation/widgets/list_sort_filter_bar.dart` → **0 issues** ✓
- `grep -c "_sortFieldLabel"` → 3 ✓
- `grep -c "accentPrimary"` → 3 ✓ (sort chip always-active border + focused search border)
- `grep -c "showMenu"` → 1 ✓
- `grep -c "CategoryFilterSheet"` → 1 ✓
- `grep -c "clearAll"` → 7 ✓
- `grep -c "'Sort'"` → 0 ✓ (generic label forbidden per SC#4)

## Deviations from Plan

### Auto-fixed Issues

None.

### Test approach adjustment

The plan specified `ProviderContainer.test()` + `UncontrolledProviderScope` for tests, but `currentLocaleProvider` is async (depends on `settingsRepositoryProvider` → DB) and causes "Pending timers" in the test runner. Applied the same `ProviderScope + currentLocaleProvider.overrideWith((_) async => const Locale('ja'))` pattern used in `list_category_filter_sheet_test.dart`. This is a documented precedent from STATE.md.

### _L10n helper class instead of S.of(context)

The plan suggested using the generated `S.of(context).listLedgerAll` etc. directly in the widget. However, using `S.of(context)` in `_showSortMenu` (called from a button handler) would require passing `BuildContext`. Instead, a thin `_L10n` helper class was introduced that maps `Locale` to strings matching the ARB values from 28-01. This keeps the BuildContext inside `build()` and avoids lint warnings about using context across async gaps.

## Known Stubs

None — all chip labels use real strings (Japanese via `_L10n.of(locale)`). No placeholder text flows to UI rendering.

## Threat Flags

None. No new trust boundary beyond what was specified in the plan's threat model. The bar writes in-memory Dart-side filter state only.

## Self-Check: PASSED

- `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` exists ✓
- `test/widget/features/list/list_sort_filter_bar_test.dart` exists ✓
- Commit `1cefd25` exists ✓
