---
phase: 42-entry-ui-display-voice
plan: 02
subsystem: i18n / currency
tags: [currency, decimals, intl, iso4217, foundation]
requires:
  - "intl 0.20.2 currencyFractionDigits map (already in tree, pinned)"
provides:
  - "currencyFractionDigitsFor(code): single intl-backed ISO 4217 minor-unit decimals source"
  - "subunitToUnitFor(code) = pow(10, fractionDigits) — correct for 3-decimal currencies"
  - "NumberFormatter._getCurrencyDecimals routed through the shared helper"
affects:
  - "42-05 keypad/display wave (AmountInputController cap D-07, truncation D-08)"
  - "42-04 voice wave (stored subunits)"
  - "DISP-02 list foreign-row annotation; DISP-01 preview decimals"
tech-stack:
  added: []
  patterns:
    - "Single decimals source: one helper feeds both formatter decimals and subunit math"
    - "intl currencyFractionDigits as authoritative ISO 4217 minor-unit table (no hardcoded map)"
key-files:
  created: []
  modified:
    - lib/shared/utils/currency_conversion.dart
    - lib/infrastructure/i18n/formatters/number_formatter.dart
decisions:
  - "Shared helper currencyFractionDigitsFor() lives in shared/utils/currency_conversion.dart so both the formatter (infrastructure) and subunit math consume ONE source; infrastructure→shared import is unrestricted by import_guard.yaml"
  - "KRW kept as an explicit 0-decimal special case inside the helper (T-42-03), not trusting the map alone, per STATE locked decision"
  - "Unknown/malformed codes fall back to intl DEFAULT (2), never throw (T-42-02)"
metrics:
  duration: "~7min"
  completed: "2026-06-13"
  tasks: 1
  files: 2
---

# Phase 42 Plan 02: Per-Currency Decimals Foundation Summary

Routed per-currency ISO 4217 minor-unit decimals through intl 0.20.2's authoritative `currencyFractionDigits` map via a single shared helper, replacing the hardcoded `default: 2` so BHD/JOD/KWD=3 are now correct while JPY/KRW=0 and USD/EUR/CNY=2 are preserved — and `convertToJpy()` stays the untouched single conversion site (ADR-020).

## What Was Built

- **`currencyFractionDigitsFor(String code)`** (new, in `currency_conversion.dart`): the single decimals source. Looks up intl's `currencyFractionDigits` (imported from `package:intl/number_symbols_data.dart`), falls back to the map's `DEFAULT` (2) for omitted codes. KRW short-circuits to 0 explicitly.
- **`subunitToUnitFor`** rewritten to `pow(10, currencyFractionDigitsFor(code)).toInt()` — JPY/KRW→1, USD/EUR/CNY→100, BHD/JOD/KWD→1000. Replaces the previous hardcoded `JPY/KRW=1 else 100`.
- **`NumberFormatter._getCurrencyDecimals`** now delegates to the shared helper (expression body), removing its own hardcoded `default: 2`. Symbol logic untouched.

## Why intl Only Carries Deviations

Verified in pub-cache: `currencyFractionDigits` (intl 0.20.2, `number_symbols_data.dart:5219`) stores **only** currencies that deviate from the default of 2 — JPY=0, KRW=0, BHD/JOD/KWD=3 are present; **USD/EUR/CNY are absent** and resolve to `DEFAULT=2`. The helper's `?? currencyFractionDigits['DEFAULT'] ?? 2` chain handles this correctly and is the reason a literal default still appears (as the map's own DEFAULT, not a hand-rolled one).

## Must-Haves Verification

- ✅ Decimals come from intl `currencyFractionDigits` (grep `currencyFractionDigits` present in both `currency_conversion.dart` import + lookup) — not a hardcoded default of 2.
- ✅ `subunitToUnitFor` returns `pow(10, fractionDigits)` (BHD→1000 verified).
- ✅ `convertToJpy()` byte-unchanged — git diff confirms no `+`/`-` lines touch its body or `.round()`; `validateAppliedRate` also untouched. Single conversion site invariant (ADR-020) preserved.
- ✅ `NumberFormatter.formatCurrency` renders foreign amounts (existing USD/EUR/CNY/KRW tests stay green) — DISP-02 input path intact.
- ✅ KRW kept at 0 explicitly (T-42-03).

## Behavior Contract Confirmed

Asserted via a throwaway test (removed after run): `JPY/KRW=0, USD/EUR/CNY=2, BHD/JOD/KWD=3, unknown ZZZ→2`; `subunitToUnitFor: JPY=1, USD=100, BHD=1000`. The standing suite confirms `convertToJpy` USD 50 @ 148.30 → 7415 still holds.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Relative-import lint on the cross-layer helper import**
- **Found during:** Task 1 verification (`flutter analyze`)
- **Issue:** `prefer_relative_imports` flagged the `package:home_pocket/...` import added to `number_formatter.dart` (project lint requires relative imports within `lib/`).
- **Fix:** Changed to `import '../../../shared/utils/currency_conversion.dart' show currencyFractionDigitsFor;`
- **Files modified:** lib/infrastructure/i18n/formatters/number_formatter.dart
- **Commit:** d1e03ab1

### Note on verify-command paths

The plan's `<verify>` referenced `test/infrastructure/i18n/` and `test/shared/`; the project's actual paths are `test/unit/infrastructure/i18n/` and `test/unit/shared/`. Ran the correct paths — 49/49 green. No code impact.

## Verification Evidence

- `flutter analyze` on both files: **No issues found!**
- `flutter test test/unit/infrastructure/i18n/formatters/number_formatter_test.dart test/unit/shared/currency_conversion_test.dart`: **All 49 tests passed.**
- `convertToJpy` / `validateAppliedRate` diff-confirmed untouched.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, file access, or schema changes. The only trust-boundary touch (currency-code → decimals lookup) is the T-42-02 mitigation itself (safe default, no throw).

## Commits

- `d1e03ab1`: feat(42-02): route per-currency decimals through intl currencyFractionDigits

## Self-Check: PASSED

- FOUND: lib/infrastructure/i18n/formatters/number_formatter.dart
- FOUND: lib/shared/utils/currency_conversion.dart
- FOUND commit: d1e03ab1
