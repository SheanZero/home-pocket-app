---
phase: quick-260614-dx1
plan: 01
subsystem: accounting / currency display
tags: [fx, formatting, currency, edit-ui]
requires: [currency_conversion.dart]
provides: [formatMinorAsMajor]
affects:
  - lib/shared/utils/currency_conversion.dart
  - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
  - lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart
key_files:
  created: []
  modified:
    - lib/shared/utils/currency_conversion.dart
    - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
    - lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart
    - test/unit/shared/currency_conversion_test.dart
    - test/widget/features/accounting/presentation/screens/transaction_edit_screen_amount_test.dart
decisions:
  - "Trim only an ENTIRELY-zero fraction (12.00 → 12); partial zeros stay (12.50 stays 12.50)"
  - "JPY/0-decimal and null-currency keypad paths left byte-identical — helper only owns the foreign-decimal path"
metrics:
  duration: ~8min
  completed: 2026-06-14
  tasks: 2
  files: 5
---

# Quick Task 260614-dx1: Foreign amount no-trailing-zeros Summary

Whole-number foreign amounts now render without a useless ".00" — "12,211.00 USD"
becomes "12,211 USD" at both the edit-screen headline and the keypad seed — via one
shared `formatMinorAsMajor` helper; fractional and JPY amounts are unaffected.

## What changed

**Task 1 (TDD) — `feat(260614-dx1)` `3860f425`:**
- Added top-level `formatMinorAsMajor(int minorUnits, String currency)` in
  `lib/shared/utils/currency_conversion.dart`, placed next to
  `subunitToUnitFor`/`currencyFractionDigitsFor` and reusing both (no new decimal logic).
- Behavior: `<= 0` → `''`; `decimals == 0` (JPY/KRW) → integer string, unchanged;
  `decimals > 0` → `toStringAsFixed(decimals)` then drop the fractional part ONLY if it
  is entirely zeros (and the now-orphan dot). Partial trailing zeros are preserved.
- Wrote the `formatMinorAsMajor` test group FIRST (RED — "Method not found"), then
  implemented (GREEN).

**Task 2 — `fix(260614-dx1)` `12892744`:**
- `transaction_edit_screen.dart` `_minorToMajorString` is now a thin wrapper delegating
  to `formatMinorAsMajor`; removed the duplicated guard/decimals/subunit/toStringAsFixed block.
  Import narrowed to `show formatMinorAsMajor`.
- `amount_edit_bottom_sheet.dart` `_initialEditStr` currency-aware branch delegates to
  `formatMinorAsMajor(initialAmount, currency!)`; the JPY/null-currency branch is left
  byte-identical (returns the integer string). `_initialEditStr` lost its now-unused
  `(decimals, subunit)` parameters; `currencyFractionDigitsFor`/`subunitToUnitFor` are
  still imported (used elsewhere in `build` for the dot-key gating and onConfirm math).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated TEST 5 assertion that encoded the old ".00" behavior**
- **Found during:** Task 2 (running the relevant widget tests)
- **Issue:** `transaction_edit_screen_amount_test.dart` TEST 5 typed a whole "200" via the
  keypad and asserted the headline read `"200.00"` — exactly the defective behavior this
  task removes. After delegating to `formatMinorAsMajor`, the headline correctly reads
  `"200"`, so the stale assertion failed.
- **Fix:** Changed the assertion to expect `"200"` (findsOneWidget) and added a
  `findsNothing` guard for `"200.00"`. This is not a regression — the test's expectation
  was the bug being fixed, not the code.
- **Files modified:** `test/widget/.../transaction_edit_screen_amount_test.dart`
- **Commit:** `12892744`

The fractional seed assertion (`112.90`) in the same test was intentionally left untouched —
fractional decimals are preserved by design.

## Verification

- `flutter test test/unit/shared/currency_conversion_test.dart` — **31 passed** (5 new
  `formatMinorAsMajor` cases: whole→trimmed, 12.50→kept, 12.05→kept, JPY→unchanged,
  non-positive→'').
- `flutter test` (3 relevant files: bottom-sheet currency + edit-screen amount + currency
  unit) — **42 passed, 0 failed**.
- `flutter analyze` on the 3 modified lib files + modified test — **No issues found** (0).

## Self-Check: PASSED

- `lib/shared/utils/currency_conversion.dart` — FOUND, contains `formatMinorAsMajor`
- `test/unit/shared/currency_conversion_test.dart` — FOUND, contains `formatMinorAsMajor`
- `transaction_edit_screen.dart` — FOUND, `_minorToMajorString` delegates to `formatMinorAsMajor`
- `amount_edit_bottom_sheet.dart` — FOUND, `_initialEditStr` delegates to `formatMinorAsMajor`
- Commit `3860f425` (Task 1) — FOUND
- Commit `12892744` (Task 2) — FOUND

---

## Supplement (260614-dx1 follow-up) — list-tile foreign annotation

**Reported incomplete:** the 列表 tab still showed `$12,211.00` / `$10,004.00` / `kr12.00`. The first pass scoped out the list path (it formats the foreign annotation separately in `list_screen.dart` via `NumberFormatter.formatCurrency`, which always emitted fixed decimals).

**Audit:** `formatMinorAsMajor` (the first-pass helper) produces bare digits with no currency symbol/grouping, so it can't drive the list annotation (which needs `$`/`kr` + grouping). Root cause is `NumberFormatter.formatCurrency` itself. Verified the list foreign annotation is the **only** remaining foreign-amount display (home tiles show no foreign; edit/keypad already fixed).

**Fix (commit `3423d53e`):**
- `NumberFormatter.formatCurrency` gains opt-in `trimWholeFraction` (default `false` → all existing call-sites + goldens byte-identical). When true + currency has >0 decimals + amount is whole → `decimalDigits: 0`.
- `FormatterService.formatCurrency` passes the flag through.
- `list_screen.dart` foreign-annotation site sets `trimWholeFraction: true`.

**Behaviour:** `$12,211.00 → $12,211`, `kr12.00 → kr12`; `kr12.50` keeps `.50`; JPY/0-decimal unchanged; default (no flag) still renders `.00` everywhere else.

**Tests/analyze:** number_formatter + formatter_service unit run **61 passed / 0 failed** (6 new `trimWholeFraction` cases); list foreign golden **7 passed**; `flutter analyze` on 4 changed files **0 issues**.
