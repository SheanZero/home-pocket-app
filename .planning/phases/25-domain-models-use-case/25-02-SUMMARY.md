---
phase: 25-domain-models-use-case
plan: "02"
subsystem: list-application
tags:
  - use-case
  - mocktail
  - result-type
  - v1.4
dependency_graph:
  requires:
    - "Phase 25 Plan 01: ListSortConfig + ListFilterState Freezed VOs"
    - "Phase 24: TransactionRepository.findByBookIds / watchByBookIds abstract interface"
    - "Phase 24: DateBoundaries utility (lib/shared/utils/date_boundaries.dart)"
  provides:
    - "lib/application/list/get_list_transactions_use_case.dart (GetListParams + GetListTransactionsUseCase)"
    - "test/unit/application/list/get_list_transactions_use_case_test.dart (Mocktail unit tests, 8 tests)"
  affects:
    - "Phase 26 listTransactionsProvider (calls watch() to drive reactive list — LIST-02)"
tech_stack:
  added: []
  patterns:
    - "Plain const params class (not Freezed) for use case input — mirrors GetTransactionsParams analog"
    - "Dual interface: execute() returns Future<Result<T>> for one-shot queries; watch() returns Stream<T> for reactive queries"
    - "Synchronous ArgumentError throw in watch() for invalid input (D-03: cannot return Result.error from Stream)"
    - "Empty-bookIds guard in execute() returns Result.error before any repo call (SC#3 / T-25-02)"
    - "sortField/sortDirection forwarded explicitly — no reliance on repo default values (RESEARCH Pitfall 2)"
    - "setUpAll with registerFallbackValue for enum types used in mocktail any(named:) matchers"
key_files:
  created:
    - lib/application/list/get_list_transactions_use_case.dart
    - test/unit/application/list/get_list_transactions_use_case_test.dart
  modified: []
key-decisions:
  - "GetListParams is a plain const class (not Freezed) — mirrors the GetTransactionsParams analog to avoid Freezed code-gen overhead for a simple 2-field params bag"
  - "watch() throws ArgumentError synchronously rather than returning a stream with an error event — D-03 decision: callers must validate params before creating stream subscriptions"
  - "searchQuery and memberBookId are NOT forwarded to repo — D-05 decision: text-search belongs to Phase 26 provider in-memory filtering; use case forwards only SQL-able filters to avoid unsafe LIKE queries in the current schema"
  - "mocktail requires setUpAll registerFallbackValue for SortField and SortDirection enums — moved from setUp to setUpAll since these are global registrations"

patterns-established:
  - "Use case _dateRange() helper pattern: derive DateTime bounds from filter.activeDayFilter (dayRange) or selectedYear/selectedMonth (monthRange)"
  - "Explicit sort param forwarding: never rely on repo defaults — always pass sortField/sortDirection explicitly from filter.sortConfig"
  - "Mocktail enum fallback registration: setUpAll registers enum fallbacks alongside DateTime for named params"

requirements-completed:
  - SORT-01
  - SORT-02
  - SORT-03
  - SORT-04

duration: ~20min
completed: 2026-05-29
---

# Phase 25 Plan 02: GetListTransactionsUseCase Summary

**`GetListTransactionsUseCase` with `execute()` (Future+Result) and `watch()` (Stream) methods, `GetListParams` composite parameter class, and 8 Mocktail tests covering SC#3/SC#4 and SORT-01..04 forwarding.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-05-29T08:50:42Z
- **Completed:** 2026-05-29T09:10:00Z
- **Tasks:** 3 (Task 1: use case impl, Task 2: unit tests, Task 3: verification gate)
- **Files created:** 2

## Accomplishments

- `GetListTransactionsUseCase` implements the dual `execute()`/`watch()` interface defined in D-03, with empty-bookIds guard (SC#3 / T-25-02), explicit sort forwarding (SORT-01..04), and `_dateRange()` helper deriving bounds from `activeDayFilter` or `selectedYear/selectedMonth`
- 8 Mocktail unit tests pass: empty-guard + verifyNever (SC#3), default updatedAt/desc forwarding (SORT-02), SortField.timestamp (SORT-01), SortField.amount (SORT-03), SortDirection.asc (SORT-04), Freezed copyWith immutability with `identical()` (SC#4), watch() ArgumentError sync throw (D-03), watch() valid stream from repo
- Full test suite: 2104 passing, 12 pre-existing failures (golden pixel drift from v1.3 polish, stale `// ignore:` in voice_input_screen_test.dart — none caused by this plan)

## Task Commits

1. **Task 1: Create GetListTransactionsUseCase + GetListParams** - `764f44e` (feat)
2. **Task 2: Write Mocktail unit tests for SC#3 + SC#4 + SORT-01..04** - `a36bf33` (test)
3. **Task 3: Full suite gate** - (no new files; verification only, covered by plan metadata commit)

## Files Created/Modified

- `lib/application/list/get_list_transactions_use_case.dart` — `GetListParams` plain const class + `GetListTransactionsUseCase` with `execute()`, `watch()`, and `_dateRange()` private helper
- `test/unit/application/list/get_list_transactions_use_case_test.dart` — 8 Mocktail tests with `_MockTransactionRepository`, `makeTransaction` helper, `setUpAll` enum fallback registration

## Decisions Made

- `GetListParams` is a plain const class, not Freezed — mirrors the `GetTransactionsParams` analog; a 2-field params bag has no need for Freezed code-gen overhead
- `watch()` throws `ArgumentError` synchronously rather than emitting a stream error event — D-03 decision; callers must validate params before subscribing to avoid stream error handling complexity
- `searchQuery` and `memberBookId` NOT forwarded to repo — D-05 decision; text-search is Phase 26 provider responsibility; forwarding them would require unsafe LIKE queries not supported by the current Phase 24 abstract interface
- `registerFallbackValue` for `SortField` and `SortDirection` enums moved to `setUpAll` — Mocktail requires global registration once per test session, not per test

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Mocktail enum fallbacks required setUpAll, not setUp**

- **Found during:** Task 2 (running unit tests)
- **Issue:** First test run failed because `any(named: 'sortField')` and `any(named: 'sortDirection')` in `when()` stubs threw `MissingFakeError` — Mocktail requires `registerFallbackValue` for all non-nullable types used in `any()` matchers. The plan's context didn't mention enum fallbacks (only `DateTime` was cited from the accounting analog, which only used `any(named: 'startDate')` / `any(named: 'endDate')`).
- **Fix:** Added `setUpAll` block with `registerFallbackValue(SortField.updatedAt)` and `registerFallbackValue(SortDirection.desc)` alongside the existing `DateTime(2026)` registration.
- **Files modified:** `test/unit/application/list/get_list_transactions_use_case_test.dart`
- **Committed in:** `a36bf33` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Auto-fix necessary for test correctness. No scope creep.

## Issues Encountered

- Flutter crash `Bad state: No element` when running `flutter test` from within the worktree directory (native assets issue in Flutter 3.44.0 worktree context). Resolved by using `flutter --suppress-analytics test` which bypassed the native assets compilation step. This is a Flutter tooling issue specific to the worktree isolation context, not a code issue.

## Known Stubs

None. Both files are complete production-quality code with no placeholder values.

## Threat Flags

None. Pure domain orchestrator — accepts pre-validated `ListFilterState` and `List<String> bookIds`, performs DateTime arithmetic via `DateBoundaries`, and delegates to the repository. No new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check

- lib/application/list/get_list_transactions_use_case.dart: FOUND
- test/unit/application/list/get_list_transactions_use_case_test.dart: FOUND
- Commit 764f44e: FOUND (Task 1 - use case)
- Commit a36bf33: FOUND (Task 2 - tests)
- flutter analyze lib/features/list/ lib/application/list/ --no-pub: No issues found
- flutter test test/unit/application/list/ --no-pub: 8/8 passing
- grep throwsArgumentError: 1 occurrence
- grep verifyNever: 1 occurrence
- grep SortField.timestamp: 5 occurrences
- grep SortField.amount: 5 occurrences
- grep SortDirection.asc: 3 occurrences
- grep identical: 1 occurrence

## Self-Check: PASSED

## Next Phase Readiness

- Phase 26 `listTransactionsProvider` can now call `useCase.watch(GetListParams(bookIds: bookIds, filter: filter))` to drive the reactive list (LIST-02)
- `GetListParams` + `GetListTransactionsUseCase` are both exported from `lib/application/list/get_list_transactions_use_case.dart`
- No blockers for Phase 26
