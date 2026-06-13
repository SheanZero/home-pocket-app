---
phase: 42-entry-ui-display-voice
plan: 08
subsystem: accounting-entry / list-presentation
tags: [currency, keypad, host-wiring, conversion-preview, list-annotation, golden, multi-currency, DISP-01, DISP-02]
requires:
  - "AmountInputController (42-05) — host-owned decimal-input state machine"
  - "CurrencySelectorSheet + recentCurrencyProvider (42-06)"
  - "ConversionPreviewPanel + conversionRateProvider (42-07)"
  - "CreateTransactionParams foreign triple + convertToJpy() single site (Phase 40 / 42-02)"
  - "create_transaction_currency_test SC-5 smoke (42-01, GREEN-on-arrival regression guard)"
provides:
  - "Tappable SmartKeyboard currency key (onCurrencyTap) → opens CurrencySelectorSheet (CURR-01)"
  - "Host-owned currency state + AmountInputController on manual_one_step_screen (CURR-05)"
  - "ConversionPreviewPanel mounted below the amount for foreign currencies only (DISP-01, CURR-04)"
  - "TransactionDetailsForm.updateCurrencyTriple() → triple flows into submit() (SC-5)"
  - "ListTransactionTile.foreignAnnotation pre-formatted prop (DISP-02); JPY byte-identical (CURR-04)"
  - "foreign list-tile golden ({ja,zh,en}×{light,dark}) + JPY byte-identical assertion"
affects:
  - "lib/features/accounting/presentation/ (host + keyboard + form)"
  - "lib/features/list/presentation/ (tile + screen)"
tech-stack:
  added: []
  patterns:
    - "Host delegates keypad input to AmountInputController; mirrors text into _amount + form"
    - "Foreign triple resolved cache-first via the preview's keyed conversionRateProvider (single convertToJpy site → preview == persisted)"
    - "Pure-UI list tile: pre-formatted foreignAnnotation prop computed in list_screen (no fetch in tile)"
    - "JPY-path guards (decimals==0 dot gate, !_isForeign preview/annotation skip) keep CURR-04 byte-identical"
key-files:
  created:
    - "test/golden/list_transaction_tile_foreign_golden_test.dart"
    - "test/golden/goldens/list_transaction_tile_foreign_{ja,zh,en,dark_ja,dark_zh,dark_en}.png"
  modified:
    - "lib/features/accounting/presentation/widgets/smart_keyboard.dart"
    - "lib/features/accounting/presentation/screens/manual_one_step_screen.dart"
    - "lib/features/accounting/presentation/widgets/transaction_details_form.dart"
    - "lib/features/list/presentation/widgets/list_transaction_tile.dart"
    - "lib/features/list/presentation/screens/list_screen.dart"
    - "test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart"
decisions:
  - "Foreign triple is resolved at sync time via ref.read(conversionRateProvider(args).future) — same keyed provider the preview watches, so the persisted JPY equals the previewed JPY (single convertToJpy site, ADR-020)."
  - "Triple withheld (nulls) until a rate resolves OR on RateUnavailable; the save guard already blocks an empty amount, so a partial triple never reaches the use case."
  - "onRateSignal is a documented no-op on the ENTRY screen — fresh entry carries no previousRate/wasManualOverride, so the use case emits no D-02/D-03 signal here; the full ADR-022 dialog/toast UX belongs to the edit host (42-09)."
  - "list annotation renders the stored original MINOR units via NumberFormatter (USD 5000 minor → 'USD 50.00'); the currency's own decimals apply."
metrics:
  duration: "~35 min"
  completed: "2026-06-13"
  tasks: 2
  files: 6
---

# Phase 42 Plan 08: Keypad/Display Integration Summary

Wires the keypad/display wave end-to-end on the manual entry host and the transaction list: the SmartKeyboard currency key is now tappable (CURR-01) and opens `CurrencySelectorSheet`; the host owns an `AmountInputController` + currency state (replacing the inline 4-decimal cap, CURR-05); `ConversionPreviewPanel` mounts below the amount for foreign currencies only (DISP-01, CURR-04); the foreign triple flows into `submit()` so the SC-5 smoke (USD 50 @ 148.30 → amount=7415) persists end-to-end; and foreign list rows show a small `USD 50.00` annotation (DISP-02) while JPY rows stay byte-identical.

## What Was Built

### Task 1 — Tappable currency key + host wiring (commit `92235d01`)
- **SmartKeyboard:** `_CurrencyKey` converted from a display-only `Container` to `Material`+`InkWell` (mirrors `_DigitKey`/`_ActionKey`), with a new nullable `onCurrencyTap` prop. `ValueKey('smart_keyboard_currency_key')` and the `max(48, …)` height floor preserved. Null `onCurrencyTap` keeps legacy display-only behavior for callers that don't switch currency.
- **manual_one_step_screen:** the inline `_onDigit/_onDot/_onDoubleZero/_onDelete` (hardcoded 4-decimal cap) now delegate to a host-owned `AmountInputController(decimals: currencyFractionDigitsFor(_currency))`; each handler mutates the controller then mirrors `text` into `_amount` and the form via `_syncAmountToForm`. The `_formKey.currentState?.updateAmount(...)` sync (host-owns-amount / form-syncs, D-14) is preserved.
  - **Currency key tap** → `showModalBottomSheet(CurrencySelectorSheet, onSelect:)`. On select: update `_currency`, push to `recentCurrencyProvider` (CURR-03), `_controller.onCurrencyChange(newDecimals)` truncates the amount (D-08), and `onDot:` passes null to SmartKeyboard when `decimals==0` (D-06).
  - **ConversionPreviewPanel** mounted below `AmountDisplay` ONLY when `_isForeign && _originalMinorUnits > 0` (CURR-04 — never built/fetched for JPY).
  - **Triple plumbing:** `_pushForeignTriple()` reads the rate cache-first from the preview's keyed `conversionRateProvider(args).future`, runs the single-site `convertToJpy()`, pushes the JPY via `updateAmount` and the triple via the new `updateCurrencyTriple` — so the persisted JPY equals the previewed JPY (ADR-020).
- **TransactionDetailsForm:** new `updateCurrencyTriple({originalCurrency, originalAmount, appliedRate})` setter (idempotent); `submit()`'s `.new` branch forwards the triple into `CreateTransactionParams`. JPY clears the triple → native JPY persist path byte-identical.

### Task 2 — Foreign-row list annotation (commit `eb7765b6`)
- **ListTransactionTile:** new nullable `foreignAnnotation` prop (pre-formatted, pure-UI contract). Foreign rows render a small `USD 50.00` (`AppTextStyles.labelMedium` / `palette.textSecondary`) under the JPY amount in a `Column`; JPY/domestic rows keep the bare amount `Text` (no `Column` wrapper) → byte-identical (CURR-04).
- **list_screen:** computes the annotation via `NumberFormatter.formatCurrency(originalAmount / subunitToUnitFor(code), code, locale)` ONLY for foreign rows (`originalCurrency != null && != 'JPY' && originalAmount != null`); null for JPY/domestic. The tile never fetches/formats (T-42-21).
- **Golden:** new `list_transaction_tile_foreign_golden_test.dart` — foreign row {ja,zh,en}×{light,dark} (6 macOS baselines) PLUS a JPY-row test that reuses the EXISTING `list_transaction_tile_ja.png` baseline to prove the JPY path stays byte-identical (no rebaseline).

## How to Verify

```bash
flutter test test/application/accounting/create_transaction_currency_test.dart   # SC-5 → 2 pass
flutter test test/golden/list_transaction_tile_foreign_golden_test.dart          # 7 pass (6 foreign + 1 JPY byte-identical)
flutter test test/golden/                                                         # full golden suite 147 pass (no JPY rebaseline)
flutter test test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart   # host regression 24 pass
flutter analyze lib/features/accounting/presentation/{widgets/smart_keyboard.dart,screens/manual_one_step_screen.dart,widgets/transaction_details_form.dart} \
                lib/features/list/presentation/{widgets/list_transaction_tile.dart,screens/list_screen.dart}   # 0 issues
```

## Must-Haves Verification

- ✅ Currency key opens `CurrencySelectorSheet` without leaving the screen (CURR-01).
- ✅ Host owns `AmountInputController` + currency state; selecting a currency truncates per D-08, gates the dot per D-06, feeds `recentCurrencyProvider` (CURR-03/05).
- ✅ `ConversionPreviewPanel` mounts below the amount only when `currency != 'JPY'` (DISP-01, CURR-04).
- ✅ Foreign list rows show `USD 50.00` via a pre-formatted prop; JPY rows byte-identical (DISP-02, CURR-04).
- ✅ SC-5 integration smoke GREEN: USD 50 @ 148.30 → amount=7415, originalCurrency='USD' (triple flows through `submit()`).

## Threat Mitigations (from plan threat_model)

| Threat ID | Disposition | How addressed |
|-----------|-------------|---------------|
| T-42-19 (JPY path regressing) | mitigate | Preview + annotation guarded on `!_isForeign`; dot gated off for JPY; the foreign golden's CURR-04 test asserts the JPY row matches the existing baseline byte-for-byte (no rebaseline); full golden suite (147) stays green. |
| T-42-20 (triple not flowing → wrong amount) | mitigate | SC-5 test GREEN; the host pushes the triple via `updateCurrencyTriple` and the form forwards it into `CreateTransactionParams`. |
| T-42-21 (annotation computed inside tile) | mitigate | Annotation is a pre-formatted prop computed in `list_screen`; the tile does no fetch/format. |
| T-42-SC (pub installs) | accept | No package installed. |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Behavior-change test update] CR-01 host test assumed an always-present dot key**
- **Found during:** Task 1 regression run (`manual_one_step_screen_test.dart`).
- **Issue:** The CR-01 regression test taps a `.` key on the default JPY screen and asserts `amount=123`. This plan is the FIRST to wire `onDot:null` for JPY (decimals==0) into the host (the 42-05 dot-gating only added the SmartKeyboard branch; the host wiring was deferred to 42-08). With JPY the dot cell now renders a disabled blank tile and `find.text('.')` finds nothing — the test failed at `expect(dotFinder, findsOneWidget)`.
- **Fix:** Updated the test to reflect the new correct behavior — assert the dot is gated off (`find.text('.')` is `findsNothing`, `smart_keyboard_dot_disabled` tile present) instead of tapping it. The regression intent (Record submits `amount=123`, not 0) is preserved; the `int.tryParse("123.") = 0` hazard the test guarded against is now structurally impossible on the JPY path. No assertion weakened.
- **Files modified:** `test/widget/.../manual_one_step_screen_test.dart`.
- **Commit:** `a7eb1f19`.

### Scope-bounded interpretation

**onSignal is a documented no-op on the entry screen.** The plan says "feed `onSignal` callback". On the FRESH-entry screen there is no `previousRate`/`wasManualOverride` (the panel's args omit both — the two inputs that gate ADR-022 D-02/D-03 signal emission), so the use case never emits a signal here. Rather than introduce the full dialog/toast UX (which is the edit host's scope, 42-09) — and a new ARB key + `gen-l10n` it would require — the callback is a documented no-op that keeps the panel's `ref.listen` sink non-null. This is a boundary clarification, not a scope cut: no signal can fire on this screen to be dropped.

## Known Stubs

None. The host is fully wired: the currency key opens the live selector, the preview consumes the live P41 use case, and the triple flows to the live create use case. The `onSignal` no-op is the documented 42-09 boundary (no signal fires on the entry screen), not a placeholder.

## Threat Flags

None. No new network endpoints, auth paths, file access, or schema changes were introduced — only presentation wiring over already-shipped use cases.

## Commits

- `92235d01`: feat(42-08) — tappable currency key + host wiring (controller, selector, preview, triple)
- `eb7765b6`: feat(42-08) — foreign-row list annotation (DISP-02); JPY byte-identical
- `a7eb1f19`: fix(42-08) — update CR-01 host test for JPY dot-gating (D-06)

## Self-Check: PASSED

- FOUND: lib/features/accounting/presentation/widgets/smart_keyboard.dart
- FOUND: lib/features/accounting/presentation/screens/manual_one_step_screen.dart
- FOUND: lib/features/accounting/presentation/widgets/transaction_details_form.dart
- FOUND: lib/features/list/presentation/widgets/list_transaction_tile.dart
- FOUND: lib/features/list/presentation/screens/list_screen.dart
- FOUND: test/golden/list_transaction_tile_foreign_golden_test.dart (+ 6 foreign baselines)
- FOUND commit: 92235d01 (Task 1)
- FOUND commit: eb7765b6 (Task 2)
- FOUND commit: a7eb1f19 (CR-01 test fix)
- SC-5 create_transaction_currency_test: GREEN; foreign golden suite: GREEN; JPY goldens: unchanged (no rebaseline).
