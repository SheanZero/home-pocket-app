---
phase: 44-data-use-case-additions-reuse-first
plan: 02
subsystem: analytics
tags: [analytics, trend, dual-ledger, reuse-first, TREND-01]
requires:
  - "AnalyticsRepository.getLedgerTotals (existing primitive, migration-free)"
  - "AnalyticsRepository.getMonthlyTotals (existing)"
  - "MonthlyTrend / ExpenseTrendData (Freezed model)"
provides:
  - "MonthlyTrend.dailyTotal (required int) + MonthlyTrend.joyTotal (required int)"
  - "GetExpenseTrendUseCase fills per-month daily/joy split from getLedgerTotals with zero-defaults"
affects:
  - "Phase 45/46 trend card — ONE trend provider family can now drive 总支出 / 日常 / 悦己 tabs"
tech-stack:
  added: []
  patterns:
    - "Reuse-first: second existing-primitive call per month inside the existing 6-month loop (no new DAO/migration)"
    - "Zero-default ledger extraction copied from get_monthly_report_use_case.dart (Pitfall 1)"
key-files:
  created: []
  modified:
    - "lib/features/analytics/domain/models/expense_trend.dart"
    - "lib/features/analytics/domain/models/expense_trend.freezed.dart (regenerated)"
    - "lib/features/analytics/domain/models/expense_trend.g.dart (regenerated)"
    - "lib/application/analytics/get_expense_trend_use_case.dart"
    - "test/unit/features/analytics/domain/models/expense_trend_test.dart"
    - "test/unit/application/analytics/get_expense_trend_use_case_test.dart"
decisions:
  - "TREND-01 implemented as extend-in-place (D-07/D-08): two model fields + one per-month getLedgerTotals call, NOT a new query/family/DAO"
  - "In-loop getLedgerTotals chosen over a new getMonthlyLedgerTotals repo method (planner discretion per D-08/RESEARCH Flag C — both migration-free; in-loop adds zero repo surface and mirrors existing structure)"
  - "No joy cross-period delta computed/exposed in the data layer (D-09); schema stays v21 (D-13)"
metrics:
  duration: ~12 min
  completed: 2026-06-16
---

# Phase 44 Plan 02: Expense-Trend Per-Ledger Split Summary

Extended the existing spending-trend path so `MonthlyTrend` carries `dailyTotal` + `joyTotal` and `GetExpenseTrendUseCase`'s 6-month loop fills them from the existing `getLedgerTotals` primitive — enabling ONE trend provider family to drive all three tabs (总支出 / 日常 / 悦己) with no new DAO, no migration, and no joy cross-period delta.

## What Was Built

- **`MonthlyTrend` (Freezed):** added `required int dailyTotal` and `required int joyTotal` after `totalIncome`, mirroring `MonthlyReport`'s `daily`/`joy` naming (ADR-017). `fromJson`/`toJson` regenerated via build_runner; round-trip verified in the model test. No income/savings/delta fields.
- **`GetExpenseTrendUseCase`:** inside the existing per-month loop, added a `getLedgerTotals` call using the SAME `(startDate, endDate, entrySourceFilter)` window as `getMonthlyTotals` (RESEARCH Flag C — never derive across query boundaries). Pre-initialized `dailyTotal = 0; joyTotal = 0;` and filled from `ledgerType == 'daily'` / `'joy'` rows (Pitfall 1 zero-default — `getLedgerTotals` omits zero-spend ledger rows). Constructed `MonthlyTrend` with the two new fields. No joy delta, no new DAO/migration.
- **Tests:** model test asserts the two new fields round-trip; use-case test gains a per-ledger split assertion plus a dedicated daily-only-month case asserting `joyTotal == 0` (and an empty-month both-zero case).

## How It Works

For each of the N months, the use case now issues two existing-primitive calls over the identical month window: `getMonthlyTotals` (unchanged — fills `totalExpenses`/`totalIncome`) and `getLedgerTotals` (fills the per-ledger split). Because `getLedgerTotals` returns no row for a ledger with zero spend, both `dailyTotal` and `joyTotal` are pre-initialized to 0 and only overwritten when a matching row is present. The joy side is a neutral rolling line: the data layer computes zero cross-period delta (ADR-012 §4; the expense-side 本月vs上月 framing is a Phase 46 + pre-Phase-45 ADR-012 amendment, not this phase).

## Deviations from Plan

None - plan executed exactly as written. No auto-fixes (Rules 1-3) were required; both tasks passed verification on first GREEN. No checkpoints, no auth gates, no architectural changes.

## Tests

- `flutter test test/unit/features/analytics/domain/models/expense_trend_test.dart` → 5/5 green.
- `flutter test test/unit/application/analytics/get_expense_trend_use_case_test.dart` → 11/11 green (incl. `joyTotal == 0` daily-only-month zero-default and empty-month both-zero).
- `flutter analyze` on all four changed files → 0 issues.

## Acceptance Criteria Verification

- `grep -c dailyTotal expense_trend.dart` = 1, `grep -c joyTotal` = 1; delta-family grep = 0 (D-09).
- `expense_trend.g.dart` references `dailyTotal` (2×) — build_runner ran.
- `grep -c getLedgerTotals get_expense_trend_use_case.dart` = 2 (call + import-resolved usage); delta/vsLastMonth grep = 0.
- `lib/data/app_database.dart` still `schemaVersion => 21`; zero `lib/data/` files modified (D-13).

## TDD Gate Compliance

Each task followed RED (test edited to require new fields/behavior) → GREEN (implementation) → verify. Per-task commits use `feat(44-02): ...` (behavior-adding); the failing-RED-then-passing-GREEN sequence was confirmed locally (model test failed to compile pre-field-add; use-case test referenced `dailyTotal`/`joyTotal` before the loop change). Both feat commits carry passing tests.

## Self-Check: PASSED

- FOUND: lib/features/analytics/domain/models/expense_trend.dart (dailyTotal/joyTotal present)
- FOUND: lib/application/analytics/get_expense_trend_use_case.dart (getLedgerTotals present)
- FOUND commit d1b3cb48 (Task 1)
- FOUND commit 2bceb32b (Task 2)
