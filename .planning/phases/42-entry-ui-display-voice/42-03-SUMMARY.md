---
phase: 42-entry-ui-display-voice
plan: 03
subsystem: application/accounting
tags: [multi-currency, edit, hash-chain, adr-020, adr-021, disp-03, disp-04]
requires:
  - "CreateTransactionParams currency triple (Phase 40)"
  - "convertToJpy / subunitToUnitFor / validateAppliedRate (currency_conversion.dart)"
  - "Transaction.copyWith currency fields (Phase 40)"
provides:
  - "UpdateTransactionParams.{originalCurrency,originalAmount,appliedRate}"
  - "UpdateTransactionUseCase.execute() foreign-row JPY recompute (no rehash)"
  - "validateCurrencyTriple() shared validator (currency_conversion.dart)"
affects:
  - "lib/application/accounting/update_transaction_use_case.dart"
  - "lib/application/accounting/create_transaction_use_case.dart"
  - "lib/shared/utils/currency_conversion.dart"
tech-stack:
  added: []
  patterns:
    - "Single shared validate+convert site for the currency triple (no inline duplication)"
    - "Coalesce-from-seed (EDIT-02) for omitted currency fields"
key-files:
  created: []
  modified:
    - "lib/application/accounting/update_transaction_use_case.dart"
    - "lib/application/accounting/create_transaction_use_case.dart"
    - "lib/shared/utils/currency_conversion.dart"
decisions:
  - "Extracted partial-triple + rate + ISO-4217 validation into shared validateCurrencyTriple() in currency_conversion.dart; CreateTransactionUseCase refactored to reuse it (removes ~50 lines of inline duplication, CLAUDE.md many-small-files)"
  - "For a foreign row, recomputed JPY amount OVERRIDES any explicit amount param — the triple is the source of truth (mirrors Create's amount↔triple consistency invariant)"
  - "No rehash on currency edit — copyWith preserves prevHash/currentHash by default (ADR-021); zero hash-chain code touched"
metrics:
  duration: "~4min"
  completed: "2026-06-13"
  tasks: 1
  files: 3
---

# Phase 42 Plan 03: Currency Triple in UpdateTransactionUseCase Summary

Extended `UpdateTransactionParams`/`UpdateTransactionUseCase` with the foreign-currency triple so edited foreign rows recompute their JPY `amount` via the single-site `convertToJpy()` (ADR-020) without ever rehashing the chain (ADR-021), via a shared validator reused by `CreateTransactionUseCase`.

## What Was Built

- **`UpdateTransactionParams`** gains three nullable fields — `originalCurrency` (String?), `originalAmount` (int? minor units), `appliedRate` (String?) — mirroring `CreateTransactionParams`. Coalesce semantics (EDIT-02): omitted params keep the seed's existing currency provenance; they are never nulled out.
- **`UpdateTransactionUseCase.execute()`** now coalesces the triple from the seed, runs the shared validator, and — for a foreign row — derives the persisted `amount` from `convertToJpy(originalMinorUnits, appliedRate, subunitToUnitFor(currency))`. For a native (JPY) row it falls back to the normal `amount` coalesce. `prevHash`/`currentHash` flow through `copyWith` unchanged → **no rehash** on a currency edit.
- **`validateCurrencyTriple()`** new shared helper in `currency_conversion.dart` (the single conversion/validation home). Enforces, in order: partial-triple invariant (all three or none), `validateAppliedRate` (ADR-020 D-05), `originalAmount > 0`, and ISO-4217 3-letter shape. Returns a `CurrencyTripleResult` carrying either an error message or the canonical converted JPY amount.
- **`CreateTransactionUseCase`** refactored to call `validateCurrencyTriple()` instead of its inline ~50-line block (removed the now-dead `_iso4217` field), keeping only the amount↔triple consistency check. Both use cases now share one validation/conversion path — they cannot drift.

## Hard Invariants Verified

- Recompute is via the single-site `convertToJpy()` (ADR-020 `.round()`) — never inline `double.parse(rate) * amount`.
- Currency fields excluded from the hash chain (ADR-021): the no-rehash test asserts `prevHash`/`currentHash` stay frozen on a currency-only edit. Zero hash-chain code touched.
- Mirrors the existing `CreateTransactionParams`/`CreateTransactionUseCase` triple shape — no new shape invented.
- Application-layer-only change; data layer and rate service (P40/P41) untouched.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Extend UpdateTransactionParams + execute() with currency triple (no rehash) | b6002f7c | update_transaction_use_case.dart, create_transaction_use_case.dart, currency_conversion.dart |

## Verification

- `update_transaction_currency_test.dart` — GREEN (3/3): appliedRate edit → 7500 JPY; originalAmount edit → 14830 JPY; currency-only edit leaves prevHash/currentHash frozen.
- `create_transaction_currency_test.dart` — GREEN (2/2), unaffected by the Create refactor.
- `test/unit/application/accounting/{create,update}_transaction_use_case_test.dart` + `test/integration/entry_path_stamping_test.dart` — GREEN (56/56 across the run) — Create refactor caused no regression.
- `test/unit/shared/currency_conversion_test.dart` — GREEN, `convertToJpy` byte-unchanged.
- `flutter analyze` on the 3 touched files — 0 issues.
- `dart format` applied to the 3 touched files only (repo not globally format-clean per project memory).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed now-unused `_iso4217` field from CreateTransactionUseCase**
- **Found during:** Task 1 (after routing Create's validation through the shared `validateCurrencyTriple`)
- **Issue:** The static `_iso4217` regex became dead code once the inline triple validation moved to the shared helper; leaving it would be an analyzer `unused_field` warning (CLAUDE.md zero-warnings rule).
- **Fix:** Deleted the field from `create_transaction_use_case.dart`. The ISO-4217 check now lives once in `currency_conversion.dart`.
- **Commit:** b6002f7c

### Design choice (within plan latitude)

The plan's `<action>` said "extract to a shared validator if it avoids duplication, per CLAUDE.md many-small-files." Chose to extract `validateCurrencyTriple()` (returning a `CurrencyTripleResult` union) rather than duplicate the ~50-line block in the Update path. This removed the duplication in both directions and keeps the partial-triple/rate/ISO validation at the same single site as `convertToJpy`.

## Known Stubs

None.

## Self-Check: PASSED

- `lib/application/accounting/update_transaction_use_case.dart` — FOUND
- commit `b6002f7c` — FOUND
