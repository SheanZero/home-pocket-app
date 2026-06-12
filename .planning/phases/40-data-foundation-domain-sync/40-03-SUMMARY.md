---
phase: 40-data-foundation-domain-sync
plan: 03
subsystem: i18n
tags: [i18n, currency, number-formatter, golden-tests]
requirements-completed: [STORE-05]
dependency-graph:
  requires:
    - phase: 40-02
      provides: "Wave 1 schema/domain groundwork (wave ordering dependency)"
  provides:
    - "NumberFormatter full currency-symbol disambiguation table (CNY→CN¥, KRW→₩ 0-dec, HKD/AUD/CAD/TWD/SGD, ISO fallback)"
    - "Re-baselined CNY golden images showing CN¥"
  affects:
    - "Phase 42 UI work (currency display now disambiguated; no second re-baseline needed)"
tech-stack:
  added: []
  patterns:
    - "Currency symbol disambiguation via explicit switch table with ISO-code fallback (D-06/D-07)"
key-files:
  created: []
  modified:
    - lib/infrastructure/i18n/formatters/number_formatter.dart
    - test/unit/infrastructure/i18n/formatters/number_formatter_test.dart
    - test/golden/amount_display_golden_test.dart
    - test/golden/goldens/amount_display_cny.png
    - test/golden/goldens/amount_display_cny_dark.png
key-decisions:
  - "CNY renders as 'CN¥' across all locales to disambiguate from JPY '¥' (D-06)"
  - "Unrecognized currency codes fall back to the ISO code itself as prefix (D-07)"
  - "KRW added with '₩' symbol and 0 decimal places alongside JPY (D-08)"
duration: 9m (including human-verify checkpoint turnaround)
completed: 2026-06-12
---

# Phase 40 Plan 03: Currency Symbol Disambiguation Summary

**One-liner:** Fixed the CNY/JPY `¥` collision in NumberFormatter with a full D-06/D-07/D-08 disambiguation table (CN¥, ₩ 0-decimals, HK$/A$/C$/NT$/S$, ISO fallback) and re-baselined the CNY golden images on macOS.

## What Was Built

- **`NumberFormatter._getCurrencySymbol`** — broke the JPY/CNY shared fall-through. Separate cases now: JPY→`¥`, CNY→`CN¥`, KRW→`₩`, USD→`$`, EUR→`€`, GBP→`£`, HKD→`HK$`, AUD→`A$`, CAD→`C$`, TWD→`NT$`, SGD→`S$`, default→ISO code (D-07 fallback).
- **`NumberFormatter._getCurrencyDecimals`** — KRW added as a 0-decimal case alongside JPY (D-08).
- **Unit tests** — CNY assertion changed from `¥` to `CN¥`; new tests for KRW (₩ + no `.00`), HKD/AUD/CAD/TWD/SGD, ISO fallback (XYZ), and a JPY regression guard. 23/23 green.
- **Golden test** — both CNY cases in `amount_display_golden_test.dart` now pass `currencySymbol: 'CN¥'`; `amount_display_cny.png` and `amount_display_cny_dark.png` re-baselined on macOS via `--update-goldens` and visually approved by the user ("goldens approved"). 6/6 golden tests green.

## Task Commits

| Task | Name | Commit | Type |
|------|------|--------|------|
| 1 | NumberFormatter disambiguation table + unit tests (TDD: RED confirmed, then GREEN) | ff540887 | feat |
| 2 | amount_display_golden_test.dart CNY expectations → CN¥ | 77a0e2c5 | fix |
| 3 | Re-baseline CNY golden PNGs (post human-verify checkpoint) | 6c03773e | test |

## TDD Gate Compliance

Task 1 was `tdd="true"`. RED phase confirmed: updated test assertions failed against the old implementation (7 failures observed) before the formatter change. GREEN: all 23 tests pass after the switch-table fix. RED and GREEN landed in a single commit (ff540887) rather than separate `test(...)`/`feat(...)` commits — the RED state was verified by test run but not committed separately.

## Verification Results

- `flutter test test/unit/infrastructure/i18n/formatters/number_formatter_test.dart` — 23/23 pass
- `flutter test test/golden/amount_display_golden_test.dart` — 6/6 pass (after re-baseline)
- `flutter test test/unit/infrastructure/i18n/` — 57/57 pass (no regressions)
- `flutter analyze` on the 3 modified source/test files — 0 issues
- `grep 'CN¥' test/golden/amount_display_golden_test.dart | wc -l` → 4 (≥2 required)
- JPY still renders `¥` (regression guard passes)

## Deviations from Plan

None - plan executed exactly as written.

## Pre-existing Issues (Out of Scope)

Repo-wide `flutter analyze` reports 39 errors, ALL in three test files from commit 207e46b4 (plan 40-01's intentional Wave 0 RED stubs: `test/unit/data/daos/exchange_rate_dao_test.dart`, `test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart`, `test/unit/shared/currency_conversion_test.dart`). These reference symbols (`ExchangeRateDao`, `convertToJpy`, `originalCurrency`/`originalAmount`/`appliedRate`) implemented by sibling wave-2 plans running in parallel worktrees. Pre-existing at this worktree's base commit (3f5a2a35); not touched by this plan.

## Checkpoint Log

- Task 3 `checkpoint:human-verify` (blocking) — golden re-baseline on macOS. Orchestrator ran `--update-goldens` in this worktree; user visually confirmed CN¥ rendering and replied "goldens approved". Resumed and committed the PNGs.

## Known Stubs

None — no stub patterns introduced by this plan.

## Threat Flags

None — no new trust-boundary surface beyond the plan's threat model (T-40-04/T-40-05 both accepted dispositions; currencyCode remains app-internal in Phase 40).

## Self-Check: PASSED

All 6 modified/created files exist on disk; all 3 task commits (ff540887, 77a0e2c5, 6c03773e) verified in git log. This SUMMARY is committed as the final docs commit on the same branch.
