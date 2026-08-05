# Resolve transaction display duplicates

**Date:** 2026-08-06
**Time:** 04:18
**Task type:** Refactor
**Status:** Complete
**Related modules:** List, Analytics category drill-down, Home

---

## Task summary

Resolved HP-12 by centralizing transaction primary-amount and foreign-currency
annotation formatting while keeping every existing row presentation unchanged.

## Completed work

- Added a model-independent transaction-display amount helper that delegates to
  the project `NumberFormatter` and preserves foreign minor-unit conversion.
- Updated List, category drill-down, and Home to use the shared formatted
  amounts.
- Extracted the shared personal ledger badge and merchant detail from List and
  Home, resolving the corresponding structural clone without changing its UI.
- Added focused unit coverage for JPY/null annotations, case-insensitive JPY,
  ja/zh/en locales, USD/CNY/EUR/GBP fractions, and trimmed whole values.

## Validation

- `flutter test` for the new unit test and the three related widget test files
- Relevant List, category drill-down, and Home golden suites, without baseline updates
- ARB parity and hardcoded-CJK architecture tests
- `flutter analyze`
- Duplicate scan: RD-007 and RD-015 no longer reported; no new open clone
- `git diff --check`

## Git commit

Commit recorded with the HP-12 / RD-007 / RD-015 refactor.
