---
phase: 47-i18n-macos-golden-uat
plan: 02
subsystem: analytics
tags: [dart, riverpod, rollup, refactor, dual-ledger, l1-aggregation]

# Dependency graph
requires:
  - phase: 44-data
    provides: category_l1_rollup.dart (l1AncestorOf single-source L1 rule, D-11)
  - phase: 46-cards
    provides: GetJoyCategoryAmountsUseCase (per-L1 joy amount for 悦己花在哪 stacked bar)
provides:
  - "GetJoyCategoryAmountsUseCase now aggregates per-L1 joy amounts in a single pass (no O(n·k) re-rollup)"
  - "Honest docstring describing the single-pass accumulate"
affects: [analytics, 47-i18n-macos-golden-uat code-review wave]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single-pass map-accumulate keyed by l1AncestorOf (mirrors rollupCategoryBreakdownsToL1 shape) instead of k-pass per-L1 re-rollup"

key-files:
  created: []
  modified:
    - lib/application/analytics/get_joy_category_amounts_use_case.dart

key-decisions:
  - "Single-pass <String,int> accumulator keyed by l1AncestorOf replaces the distinct-L1-set + per-L1 l1RollupFromTransactions loop; D-11 single source preserved (still routes through l1AncestorOf)"
  - "l1RollupFromTransactions import retained (shared category_l1_rollup.dart import still supplies l1AncestorOf) — no unused-import; analyze 0"
  - "Existing unit test left byte-unchanged — it already asserts per-L1 sum (L2→L1 rollup), zero-drop, amount-desc sort, joy-ledger-only, expense-only, subset invariant, and findByBookIds-not-widened; all 6 pass against the single-pass impl"

patterns-established:
  - "Per-L1 amount aggregation: iterate the transaction set ONCE, key by l1AncestorOf(tx.categoryId)??tx.categoryId, sum tx.amount, then drop amount<=0 and sort amount-desc"

requirements-completed: [GUARD-04]

# Metrics
duration: 4min
completed: 2026-06-17
---

# Phase 47 Plan 02: Single-pass per-L1 joy amount aggregation Summary

**`GetJoyCategoryAmountsUseCase` refactored from an O(n·k) k-pass re-rollup to a single-pass map-accumulate keyed by `l1AncestorOf`, with the false "There is NO second rollup loop here" docstring removed — byte-identical per-L1 amounts, D-11 single source intact.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-06-17
- **Completed:** 2026-06-17
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Replaced the two-loop block (build distinct-L1 set, then call `l1RollupFromTransactions` once per L1 — each call re-iterating all transactions) with a single `<String, int>` accumulator iterated once over `expenseTxns`.
- Fixed the docstring that falsely claimed "There is NO second rollup loop here." — it now accurately describes the single-pass accumulate keyed by `l1AncestorOf`.
- D-11 single source preserved: the L1 mapping still routes through `l1AncestorOf(tx.categoryId, categoryMap) ?? tx.categoryId`.
- Per-L1 joy amounts byte-identical to the prior k-pass implementation (verified by the existing 6-case unit test, all green).
- No `findByBookIds` widening; aggregate-only ints retained (no per-tx logging) — threats T-47-02-01 / T-47-02-02 unchanged.

## Task Commits

1. **Task 1: WR-03 — single-pass per-L1 accumulate + honest docstring** - `bb9e4c4f` (refactor)

_Pure refactor: the existing unit test already encoded the contract, so it was left byte-unchanged and serves as the GREEN gate against the new implementation (RED was unnecessary — no behavior change to test-drive)._

## Files Created/Modified
- `lib/application/analytics/get_joy_category_amounts_use_case.dart` - Single-pass accumulate replacing the O(n·k) loop; honest docstring.

## Decisions Made
- **Test left unchanged:** the existing `get_joy_category_amounts_use_case_test.dart` already asserts correct per-L1 summed amounts (incl. L2→L1 rollup), zero-amount-bucket drop, amount-descending sort, joy-ledger-only, expense-only, subset invariant, and `findByBookIds`-exactly-caller-bookIds. Since this is a pure refactor with byte-identical output, no test extension was needed — the suite is the preservation contract.
- **Import retained:** `l1RollupFromTransactions` is no longer called, but it shares the `category_l1_rollup.dart` import with the still-used `l1AncestorOf`, so the import line stays valid (no unused-import; `flutter analyze` reports 0 issues).

## Deviations from Plan

None - plan executed exactly as written.

The plan's action contemplated possibly deleting the `l1RollupFromTransactions` import if it became unused; it did NOT become unused because `l1AncestorOf` is imported from the same file. No import change required (verified by analyze 0).

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Use case is independent of Plan 01's registry/card edits (no file overlap) — ran in parallel-safe wave 1.
- Full-suite gate (incl. `production_logging_privacy_test.dart`) runs at the Plan 06 wave gate, not here.

## Self-Check: PASSED

- FOUND: lib/application/analytics/get_joy_category_amounts_use_case.dart
- FOUND commit: bb9e4c4f
- grep "There is NO second rollup loop here" = 0 (lying docstring removed)
- grep "l1AncestorOf" = 4 (D-11 single source intact)
- grep "for (final l1Id in l1Ids)" = 0 (k-pass loop removed)
- `flutter test ...get_joy_category_amounts_use_case_test.dart` = 6/6 passed
- `flutter analyze ...get_joy_category_amounts_use_case.dart` = No issues found

---
*Phase: 47-i18n-macos-golden-uat*
*Completed: 2026-06-17*
