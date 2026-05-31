---
phase: 29
plan: "01"
subsystem: list-feature-tests
tags: [test-scaffold, wave-0, tdd-red, FAM-01, FAM-02, FAM-03, FAM-04, LIST-04]
dependency_graph:
  requires: []
  provides: [wave-0-test-scaffolds-29]
  affects: [test/widget/features/list/, test/unit/features/list/]
tech_stack:
  added: []
  patterns: [ProviderContainer.test(), waitForFirstValue, _FixedListFilter, overrideWith-shadow-books]
key_files:
  created:
    - test/widget/features/list/list_screen_refresh_test.dart
    - test/widget/features/list/list_sort_filter_bar_member_test.dart
  modified:
    - test/unit/features/list/presentation/providers/list_transactions_provider_test.dart
    - test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart
    - test/widget/features/list/list_transaction_tile_test.dart
decisions:
  - "Used _FixedListFilter pattern (from existing list_transactions_provider_test.dart) across all new test files for deterministic filter-state injection"
  - "Extended _makeContainer in list_transactions_provider_test.dart with isGroupMode and shadows params — no breaking change to existing call sites"
  - "Extended _makeContainer in calendar_totals_provider_test.dart with the same pattern for consistency"
  - "Solo-mode absence tests in list_sort_filter_bar_member_test.dart pass immediately (GREEN before implementation)"
metrics:
  duration: "~6 minutes"
  completed: "2026-05-30"
  tasks_completed: 2
  files_changed: 5
---

# Phase 29 Plan 01: Wave 0 Test Scaffolds Summary

Wave 0 test scaffolds for all Phase 29 behaviors (LIST-04, FAM-01..FAM-04). Two new widget test files plus 15 new test cases appended to three existing test files. All Phase 29 behavioral assertions compile cleanly and are RED (implementation not yet landed). Pre-existing list test suite remains fully green.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Create list_screen_refresh_test.dart and list_sort_filter_bar_member_test.dart | dd385703 | 2 new files |
| 2 | Add Phase 29 test cases to three existing test files | fee45eb9 | 3 modified files |

## What Was Built

### Task 1: Two new Wave 0 widget test files

**`test/widget/features/list/list_screen_refresh_test.dart`** (LIST-04):
- 3 tests: `RefreshIndicator` present in ListScreen; pull-to-refresh invalidates `listTransactionsProvider`; pull-to-refresh invalidates `calendarDailyTotalsProvider`
- All 3 RED (expected): `RefreshIndicator` not yet in `list_screen.dart`
- Pump helper: `ProviderScope` + `ListScreen(bookId: 'book1')` with mocked use case and analytics repo

**`test/widget/features/list/list_sort_filter_bar_member_test.dart`** (FAM-03/FAM-04):
- 7 tests: Mine-only chip visible in group mode; Mine-only absent in solo mode; member chip per `shadowBooksProvider`; tap member chip sets `memberBookId`; tap Mine-only sets own bookId; `anyFilterActive` includes `memberBookId`; member chips absent in solo mode
- 2 GREEN immediately (solo-mode absence tests): `isGroupMode=false` naturally renders no family chips
- 5 RED (expected): family segment not yet in `list_sort_filter_bar.dart`

### Task 2: Extensions to three existing test files

**`list_transactions_provider_test.dart`** — group `"Phase 29: family-mode FAM-01/02/03/04"` (6 new tests):
- FAM-01: group mode bookIds includes own + shadow
- FAM-02: shadow rows get `memberTag != null`
- FAM-02/D-01: own rows get `memberTag == null`
- FAM-03: member filter narrows SQL to shadow book
- FAM-04: Mine-only = own bookId narrowing
- D-04: solo mode all memberTags null

**`calendar_totals_provider_test.dart`** — group `"Phase 29: family calendar D-06"` (3 new tests):
- FAM-01/D-06: group mode sums per-book day totals
- D-04: solo mode own-book only
- Pitfall 3/D-06: calendar isolated from `memberBookId` filter

**`list_transaction_tile_test.dart`** — group `"Phase 29: member attribution chip FAM-02"` (3 new tests):
- FAM-02/CC-1: member chip renders when `memberTag != null`
- FAM-02/SC#3: member chip absent when `memberTag == null`
- FAM-02/CC-1: member chip truncates at `maxWidth: 72` with `TextOverflow.ellipsis`

## Verification Results

```
flutter analyze lib/features/list/ test/widget/features/list/ test/unit/features/list/ --no-pub
→ No issues found!
```

```
flutter test test/unit/features/list/ test/widget/features/list/ --no-pub
→ Some tests failed.
  Failing: all Phase 29 behavioral assertions (15 new RED tests)
  Passing: all pre-existing tests (23 passing)
```

## Deviations from Plan

None — plan executed exactly as written.

- Extended `_makeTransaction` in `list_transactions_provider_test.dart` to accept a `bookId` parameter (was always `'book1'`); this was necessary for group-mode tests involving shadow-book rows but is a backward-compatible change (default remains `'book1'`).
- Extended `_makeContainer` in both provider test files to accept `isGroupMode` and `shadows` params with defaults that preserve existing test behavior.

## Known Stubs

None introduced by this plan. All new code is test scaffolds only — no production code changed.

## Threat Flags

None. Plan introduced no new network/auth/storage surface — test scaffolds only.

## Self-Check

- [x] `test/widget/features/list/list_screen_refresh_test.dart` exists — FOUND
- [x] `test/widget/features/list/list_sort_filter_bar_member_test.dart` exists — FOUND
- [x] Commit `dd385703` exists — FOUND
- [x] Commit `fee45eb9` exists — FOUND
- [x] `flutter analyze ... --no-pub` = 0 issues — PASSED

## Self-Check: PASSED
