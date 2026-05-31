---
phase: 28-transaction-tile-sort-filter-bar
plan: "02"
subsystem: list-feature-tests
tags: [wave-0, test-stubs, tdd, red-green, filter-state, hash-chain, day-grouping]
dependency_graph:
  requires: [28-01]
  provides: [wave-0-test-stubs]
  affects: [28-03, 28-04, 28-05, 28-06]
tech_stack:
  added: []
  patterns: [ProviderContainer.test, UncontrolledProviderScope, fail-stub-pattern]
key_files:
  created:
    - test/unit/features/list/list_filter_notifier_test.dart
    - test/unit/features/list/delete_hash_chain_integrity_test.dart
    - test/unit/features/list/list_grouping_test.dart
    - test/widget/features/list/list_transaction_tile_test.dart
    - test/widget/features/list/list_sort_filter_bar_test.dart
    - test/widget/features/list/list_category_filter_sheet_test.dart
    - test/widget/features/list/list_empty_state_test.dart
  modified: []
decisions:
  - "list_filter_notifier stubs are GREEN (not RED) because 28-01 already implemented setCategories/toggleCategory; this is the correct outcome — stubs validate the contract already delivered"
  - "ignore_for_file pragmas used for unused imports in structural stub files to achieve 0 analyzer issues while preserving contract documentation"
  - "delete_hash_chain_integrity_test.dart uses fail() stub body to stay RED; container.expect(isNotNull) prevents unused-variable warnings on the ProviderContainer"
metrics:
  duration: "~10 minutes"
  completed_date: "2026-05-30"
  task_count: 2
  file_count: 7
---

# Phase 28 Plan 02: Wave 0 Test Stubs Summary

**One-liner:** 7 Wave 0 test stub files establishing TDD contracts for D-01 mutators, ROW-02 hash-chain SC#3, buildFlatList day-grouping, and 4 widget acceptance paths (ROW-01/02, SORT/FILTER bar, category sheet tristate, empty state icons).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Unit test stubs: list_filter_notifier, delete_hash_chain_integrity, list_grouping | 28169d2 | 3 new unit test files |
| 2 | Widget test stubs: tile, sort/filter bar, category sheet, empty state | cac1b11 | 4 new widget test files |

## Outcome

All 7 Wave 0 test stub files created with correct import structure, scaffolding, and at least one test per requirement group.

### File Inventory

| File | Coverage | State |
|------|----------|-------|
| `test/unit/features/list/list_filter_notifier_test.dart` | D-01 setCategories, toggleCategory, clearAll, immutability (5 tests) | GREEN — 28-01 already implemented API |
| `test/unit/features/list/delete_hash_chain_integrity_test.dart` | ROW-02 SC#3 soft-delete + hash-chain verifyChain | RED — fail() stub |
| `test/unit/features/list/list_grouping_test.dart` | buildFlatList asc/desc day-grouping (2 tests) | RED — 28-03 creates list_day_group_header.dart |
| `test/widget/features/list/list_transaction_tile_test.dart` | ROW-01 tap nav + ROW-02 swipe confirm dialog | RED — 28-03 creates ListTransactionTile |
| `test/widget/features/list/list_sort_filter_bar_test.dart` | SC#4 sort label + FILTER-02 ledger chip + FILTER-04 clear chip | RED — 28-05 creates ListSortFilterBar |
| `test/widget/features/list/list_category_filter_sheet_test.dart` | Apply/setCategories + D-02 L1 cascade + B2 tristate | RED — 28-04 creates CategoryFilterSheet |
| `test/widget/features/list/list_empty_state_test.dart` | B3 receipt_long_outlined (no filter) + search_off_outlined + TextButton (filter active) | RED — 28-04 creates ListEmptyState |

### Analyzer Results

- `flutter analyze test/unit/features/list/` — **0 issues**
- `flutter analyze test/widget/features/list/` — **0 issues**

### Test Execution

- `flutter test test/unit/features/list/list_filter_notifier_test.dart` — **+5: All tests passed** (GREEN, 28-01 shipped)
- `delete_hash_chain_integrity_test.dart` — RED (fail stub)
- `list_grouping_test.dart` — RED (fail stubs, TODO: 28-03)
- Widget stubs — RED (fail stubs, TODO: 28-03/04/05)

## Nyquist Continuity Satisfied

The 3 previously-uncovered consecutive implementation tasks now each have a behavioral test stub:
- 28-03 T2 (buildFlatList) → `list_grouping_test.dart` (asc/desc stubs)
- 28-04 T1 (CategoryFilterSheet) → `list_category_filter_sheet_test.dart` (tristate + L1 cascade)
- 28-04 T2 (ListEmptyState) → `list_empty_state_test.dart` (both icon paths)

No 3 consecutive implementation tasks are without a behavioral test stub (B3 satisfied).

## Deviations from Plan

None — plan executed exactly as written.

Note: `list_filter_notifier_test.dart` tests are GREEN (not RED) because Plan 28-01 had already implemented `setCategories`/`toggleCategory` on the `ListFilter` notifier before this plan ran. The context header (`important_context`) confirms 28-01 completed with these mutators live. The stubs correctly validate the already-delivered contract.

## Known Stubs

All 7 files are intentional stubs. The stub pattern is `fail('implement in 28-0X')` — each failing test documents the widget/function that must be implemented in the specified future wave plan. No stub prevents the plan's own goal (establishing test structure) from being achieved.

## Threat Flags

None — test-only files, no production code paths, no new trust boundaries.

## Self-Check: PASSED

All 7 files exist at expected paths; commits 28169d2 and cac1b11 verified in git log.
