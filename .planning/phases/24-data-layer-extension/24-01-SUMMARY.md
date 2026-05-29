---
phase: 24-data-layer-extension
plan: "01"
subsystem: shared-utils
tags: [enums, sort, date-boundaries, tdd, pure-dart]
dependency_graph:
  requires: []
  provides:
    - lib/shared/constants/sort_config.dart (SortField + SortDirection enums — consumed by Plan 02 TransactionDao)
    - lib/shared/utils/date_boundaries.dart (monthRange + dayRange — consumed by Plan 02 DAO and Phase 25 use cases)
  affects:
    - lib/data/daos/transaction_dao.dart (Plan 02 will import sort_config.dart)
tech_stack:
  added: []
  patterns:
    - pure Dart enums with no imports (sort_config)
    - abstract final class static utility (date_boundaries) — same pattern as DefaultCategories
    - named record tuples ({DateTime start, DateTime end}) for boundary return values
key_files:
  created:
    - lib/shared/constants/sort_config.dart
    - lib/shared/utils/date_boundaries.dart
    - test/unit/shared/utils/date_boundaries_test.dart
  modified: []
decisions:
  - "Used regular comments (// style) instead of doc comments (/// style) on file-level to avoid dangling_library_doc_comments analyzer info — per-class and per-member doc comments use /// as usual"
  - "DateTime(year, month+1, 0, 23, 59, 59) idiom for month-end confirmed from time_window.dart line 62 as canonical source of truth"
  - "abstract final class pattern for DateBoundaries (no instantiation) — mirrors DefaultCategories and default_categories analog"
metrics:
  duration: "2m 10s"
  completed: "2026-05-29T05:52:26Z"
  tasks_completed: 2
  files_created: 3
  files_modified: 0
requirements: [LIST-02]
---

# Phase 24 Plan 01: Shared Sort + Date Boundary Utilities Summary

Established the two shared pure-Dart utilities that the DAO tier (Plan 02) and domain layer (Phase 25) depend on: `SortField`/`SortDirection` enums for type-safe ORDER BY, and `DateBoundaries` for consolidating the repeated `DateTime(y,m+1,0,23,59,59)` idiom behind a single tested interface.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create SortField + SortDirection enums | 919e055 | lib/shared/constants/sort_config.dart |
| 2 (RED) | Add failing DateBoundaries tests | 90610f0 | test/unit/shared/utils/date_boundaries_test.dart |
| 2 (GREEN) | Implement DateBoundaries utility | 7c4b2f4 | lib/shared/utils/date_boundaries.dart |

## What Was Built

**Task 1 — SortField + SortDirection enums** (`919e055`)

`lib/shared/constants/sort_config.dart` — two plain Dart enums with zero imports:
- `SortField { timestamp, updatedAt, amount }` — compile-time column selection for ORDER BY
- `SortDirection { asc, desc }` — sort order

Placement in `lib/shared/constants/` ensures both the data layer (DAOs) and domain layer (feature models/use cases) can import without triggering `import_guard` violations.

**Task 2 — DateBoundaries utility + tests** (`90610f0` + `7c4b2f4`)

`lib/shared/utils/date_boundaries.dart` — `abstract final class DateBoundaries` with two static methods:
- `monthRange(int year, int month)` → `({DateTime start, DateTime end})` — full calendar month, closed interval
- `dayRange(DateTime day)` → `({DateTime start, DateTime end})` — single calendar day, closed interval

Month-end uses `DateTime(year, month+1, 0, 23, 59, 59)` — Dart normalises day=0 to the last day of the prior month. This is the canonical idiom verified from `time_window.dart` line 62.

D-04 enforced: no `DateTime.utc()` anywhere — local device time only, consistent with `AnalyticsDao.getDailyTotals` local-time calendar grouping.

`test/unit/shared/utils/date_boundaries_test.dart` — 6 boundary cases (SC#3):
1. monthRange May start = DateTime(2026, 5, 1) [00:00:00]
2. monthRange May end = DateTime(2026, 5, 31, 23, 59, 59)
3. monthRange Feb 2026 end.day = 28 (non-leap year)
4. monthRange Dec end.month = 12 and end.day = 31 (year boundary)
5. dayRange start strips time to 00:00:00
6. dayRange end = 23:59:59

## Verification Results

```
flutter analyze lib/shared/constants/sort_config.dart lib/shared/utils/date_boundaries.dart
→ No issues found!

flutter test test/unit/shared/utils/date_boundaries_test.dart --reporter=expanded
→ All tests passed! (6/6)

grep -c "enum SortField" lib/shared/constants/sort_config.dart    → 1
grep -c "enum SortDirection" lib/shared/constants/sort_config.dart → 1
grep -c "abstract final class DateBoundaries" lib/shared/utils/date_boundaries.dart → 1
grep -v '^//' lib/shared/utils/date_boundaries.dart | grep -c "utc" → 0
```

## Deviations from Plan

**1. [Rule 1 - Bug] Fixed dangling_library_doc_comments analyzer info in sort_config.dart**
- **Found during:** Task 1 verification
- **Issue:** Opening `///` doc comment at file level triggered `dangling_library_doc_comments` analyzer info (requires a `library` directive to be valid)
- **Fix:** Converted file-level header from `///` to `//` (regular comments). Per-enum doc comments retained as `///`.
- **Files modified:** `lib/shared/constants/sort_config.dart`
- **Commit:** 919e055 (fixed inline before commit)

## TDD Gate Compliance

RED gate: `90610f0` — `test(24-01): add failing tests for DateBoundaries SC#3 boundary cases`
GREEN gate: `7c4b2f4` — `feat(24-01): implement DateBoundaries utility with monthRange + dayRange`

Both gates present in git log. Plan executed: RED → GREEN.

## Known Stubs

None — pure utility files with no UI components, no data bindings, no placeholder values.

## Threat Flags

No new security surface introduced. Files are pure Dart with no network access, no file I/O, no auth paths, no schema changes. Threat model T-24-01-SC (no package installs) satisfied.

## Self-Check: PASSED

Files exist:
- [x] lib/shared/constants/sort_config.dart
- [x] lib/shared/utils/date_boundaries.dart
- [x] test/unit/shared/utils/date_boundaries_test.dart

Commits exist:
- [x] 919e055 (Task 1 — sort_config.dart)
- [x] 90610f0 (Task 2 RED — test file)
- [x] 7c4b2f4 (Task 2 GREEN — implementation)
