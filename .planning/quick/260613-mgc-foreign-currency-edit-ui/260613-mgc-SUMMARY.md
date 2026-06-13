---
phase: quick-260613-mgc
plan: 01
subsystem: accounting/presentation (foreign-currency edit UI)
tags: [multi-currency, edit-ui, ADR-022, CURR-04, golden]
requires:
  - AmountEditBottomSheet (existing keypad sheet)
  - SmartKeyboard (existing keypad widget)
  - convertToJpy / currencyFractionDigitsFor / subunitToUnitFor (currency_conversion.dart, ADR-020 single site)
  - CurrencyLinkedEditFields (ADR-022 D-01 rate + derived-JPY card)
provides:
  - Foreign edit-row headline is tap-to-editable, reusing the existing keypad in currency-aware (major-unit decimal) mode
  - Foreign currency card (rate + derived JPY) reordered above the category/date card, original-amount input row removed
affects:
  - lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart
  - lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart
  - lib/features/accounting/presentation/widgets/transaction_details_form.dart
  - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
  - docs/arch/03-adr/ADR-022_Edit_Semantics.md
tech-stack:
  added: []
  patterns:
    - "Optional currency-aware mode on existing keypad sheet (no new widget): currency!=null -> minor-unit in/out, major-decimal editStr, ISO decimal cap"
    - "Original amount injected via prop + didUpdateWidget sync; in-card amount input removed (one editable field = rate)"
key-files:
  created: []
  modified:
    - lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart
    - lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart
    - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
    - test/features/accounting/presentation/edit_currency_linked_test.dart
    - test/widget/features/accounting/presentation/screens/transaction_edit_screen_amount_test.dart
    - test/golden/currency_linked_edit_fields_golden_test.dart
    - test/golden/goldens/currency_linked_edit_fields_usd.png
    - test/golden/goldens/currency_linked_edit_fields_usd_dark.png
    - docs/arch/03-adr/ADR-022_Edit_Semantics.md
decisions:
  - "D-01's non-tappable foreign headline superseded by user-directed tap-to-edit; single-direction convertToJpy invariant preserved (ADR-022 append note 2026-06-13)"
metrics:
  duration: ~10min
  completed: 2026-06-13
---

# Phase quick-260613-mgc Plan 01: 外币明细编辑交互微调 Summary

Foreign edit-row headline is now tap-to-editable via the existing SmartKeyboard
(new optional currency-aware mode on AmountEditBottomSheet — no new keypad), and
the foreign currency card was reordered above the category/date card with its
in-card original-amount input row removed (card = 汇率 + 日元 only).

## What Was Done

**Task 1 — AmountEditBottomSheet currency-aware mode (commit e95bb5a5):**
Added optional `currency` / `currencySymbol` / `currencyLabel` params (with `.show`
passthrough). When `currency` is null/'JPY' the sheet is byte-identical to the legacy
JPY-integer path (OCR/Voice/edit-JPY unaffected). When non-null: `initialAmount` is
minor units, editStr is seeded as the major-unit decimal string (11290 → "112.90"),
the decimal cap = `currencyFractionDigitsFor(currency)`, the dot is disabled for
0-decimal currencies (JPY/KRW), and `onConfirm` returns the value back in minor units
via `(major × subunitToUnitFor).round()`. Reuses the existing `SmartKeyboard`.

**Task 2 — headline tap-to-edit + card reorder + row removal (commit 248312f4):**
- `transaction_edit_screen.dart`: foreign headline `onTap` opens the currency-aware
  sheet; confirm pushes the new minor-unit amount via the form's imperative
  `updateOriginalAmount(minor)` → single-site `convertToJpy` recompute. JPY-native
  path (`_editAmount`) untouched.
- `transaction_details_form.dart`: added `updateOriginalAmount(int minorUnits)`
  (mirrors `updateRate`'s idempotent recompute); moved `CurrencyLinkedEditFields`
  ahead of `DetailInfoCard` for foreign rows only.
- `currency_linked_edit_fields.dart`: removed the in-card original-amount Row; the
  original amount is now an external prop synced in `didUpdateWidget`; card now has
  exactly one editable field (rate) + the read-only derived JPY row.

**Task 3 — tests updated to new contract + golden re-baseline (commit c36b9c8c):**
- `edit_currency_linked_test.dart`: dropped the two-TextField / `edit_original_amount_field`
  assertions; asserts exactly one editable field (rate); original-amount driven via
  `originalAmount` prop re-pump. D-01/D-02/D-03 (rate→JPY recompute, manual-override
  dialog, >1% toast+undo) assertions kept strong, not weakened.
- `transaction_edit_screen_amount_test.dart`: TEST 3 reversed — foreign headline IS
  tappable → `AmountEditBottomSheet` findsOneWidget (kept USD/$/112.90 + read-only
  18,093 JPY-derived assertions). TEST 5 edits via the headline keypad. TEST 1/2/4
  (JPY-native) unchanged (CURR-04).
- `currency_linked_edit_fields_golden_test.dart`: dropped `$` / `112.90` row
  assertions, asserts the remaining rate + JPY rows; USD light/dark baselines
  re-generated on macOS.

**ADR-022 append note (commit 03a041d7):** Recorded that D-01's non-tappable foreign
headline was superseded by the user-directed tap-to-edit reusing the existing keypad,
with the single-direction conversion invariant (原币 × 汇率 → 日元, JPY read-only,
single `convertToJpy` site) fully preserved. Appended per the ADR append-only rule.

## Deviations from Plan

None — plan executed as written. The reversal of ADR-022 D-01's non-tappable
headline was pre-confirmed by the user (not a deviation). Tasks 1 and 2 were already
committed prior to this executor session; this session completed Task 3 (tests +
golden re-baseline), added the ADR note, and ran the full verification.

## Verification

- `flutter analyze`: **No issues found** (0 issues).
- `flutter test`: **2819/2819 passed** — full suite including architecture tests
  (`hardcoded_cjk_ui_scan` and others not skipped).
- Affected trio (`edit_currency_linked` / `transaction_edit_screen_amount` / golden):
  19/19 passed.
- Golden baselines re-generated on macOS (darwin); CI (non-macOS) uses
  BaselineExistenceGoldenComparator per the golden-ci-platform-gate.

## ADR-022 D-01 Invariant Preservation

The single-direction conversion invariant is intact: original × rate → JPY only,
JPY read-only and never written back, `convertToJpy()` remains the sole conversion
site (ADR-020). The change only moved the original-amount input from the in-card row
to the headline keypad. JPY-native rows are zero-regression (CURR-04). OCR/Voice JPY
sheets keep their integer-mode behavior (default mode unchanged).

## Commits

- `e95bb5a5` feat(260613-mgc): add optional currency-aware mode to AmountEditBottomSheet
- `248312f4` feat(260613-mgc): foreign headline tap-to-edit + card reorder + drop original-amount row
- `c36b9c8c` test(260613-mgc): update edit tests to tap-to-edit contract + re-baseline golden
- `03a041d7` docs(260613-mgc): ADR-022 append note — foreign headline tap-to-editable

## Self-Check: PASSED

- All modified lib + test files exist and are committed.
- All four commits exist in `git log`.
- `flutter analyze` 0 issues; `flutter test` 2819/2819 green.
