---
phase: 42-entry-ui-display-voice
reviewed: 2026-06-13T04:36:26Z
depth: standard
files_reviewed: 24
files_reviewed_list:
  - lib/application/accounting/create_transaction_use_case.dart
  - lib/application/accounting/update_transaction_use_case.dart
  - lib/application/voice/parse_voice_input_use_case.dart
  - lib/features/accounting/domain/models/voice_parse_result.dart
  - lib/features/accounting/presentation/providers/state_recent_currency.dart
  - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
  - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
  - lib/features/accounting/presentation/screens/voice_input_screen.dart
  - lib/features/accounting/presentation/widgets/amount_input_controller.dart
  - lib/features/accounting/presentation/widgets/change_rate_confirmation_dialog.dart
  - lib/features/accounting/presentation/widgets/conversion_preview_panel.dart
  - lib/features/accounting/presentation/widgets/currency_edit_strings.dart
  - lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart
  - lib/features/accounting/presentation/widgets/currency_selector_sheet.dart
  - lib/features/accounting/presentation/widgets/smart_keyboard.dart
  - lib/features/accounting/presentation/widgets/transaction_details_form.dart
  - lib/features/list/presentation/screens/list_screen.dart
  - lib/features/list/presentation/widgets/list_transaction_tile.dart
  - lib/infrastructure/i18n/formatters/number_formatter.dart
  - lib/infrastructure/voice/chinese_numeral_state_machine.dart
  - lib/infrastructure/voice/japanese_numeral_state_machine.dart
  - lib/infrastructure/voice/numeral_state_machine.dart
  - lib/shared/constants/voice_currency_suffixes.dart
  - lib/shared/utils/currency_conversion.dart
findings:
  critical: 1
  warning: 6
  info: 4
  total: 11
status: resolved
resolution: "CR-01 + 6 warnings fixed (2026-06-13); 4 Info items left as non-defects. Suite 2808/2808 green."
---

# Phase 42: Code Review Report

**Reviewed:** 2026-06-13T04:36:26Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Reviewed the Phase 42 multi-currency entry/display/voice slice. The single-conversion-site invariant (`convertToJpy`) is respected everywhere I could trace — no inline `rate * amount` survived. The edit host is genuinely one-directional (original × rate → JPY), the JPY-native (CURR-04) path is well-guarded, and the use cases correctly route through the shared `validateCurrencyTriple`. Riverpod-3 side-effect discipline (`ref.listen` for the rate signal) is correct in the preview panel.

The headline defect is a **broken voice → foreign-currency save path**: the voice screen detects a foreign currency and pushes only the currency code into the form, never the original amount or applied rate. At submit the form forwards a partial triple, which the create use case rejects — so any spoken foreign-currency utterance fails to save with a raw validation string. This is the central deliverable of VOICE-CUR and is non-functional end-to-end.

Several lower-severity correctness gaps cluster around async races (date-change not in the re-fetch guard), a stale-amount window when a rate becomes unavailable mid-entry, and a contrived-but-real leftmost-wins flaw in the currency-token scanner.

## Narrative Findings (AI reviewer)

### Critical Issues

#### CR-01: Voice-detected foreign currency produces a partial triple that fails to save

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:372-375` (with `lib/features/accounting/presentation/widgets/transaction_details_form.dart:300-304`, `888-891`)

**Issue:** On voice commit, when a foreign currency is detected the screen calls:

```dart
final detectedCurrency = data.detectedCurrency;
if (detectedCurrency != null && detectedCurrency.isNotEmpty) {
  state.updateCurrency(detectedCurrency);
}
```

`updateCurrency` sets only `_originalCurrency`:

```dart
void updateCurrency(String currency) {
  if (!mounted) return;
  if (currency == _originalCurrency) return;
  setState(() => _originalCurrency = currency);
}
```

Nothing in the voice (`.new`) path ever sets `_originalAmount` or `_appliedRate`:
- The `CurrencyLinkedEditFields` edit host that would let the user enter/derive them is gated on `_isEditMode` (`transaction_details_form.dart:888`), so it never renders during voice/manual entry.
- There is no rate-fetch wiring in the voice flow analogous to `manual_one_step_screen._pushForeignTriple`.

At `submit()` the `.new` branch forwards `originalCurrency: <USD>, originalAmount: null, appliedRate: null`. `validateCurrencyTriple` (`currency_conversion.dart:161-174`) sees `hasAny && !hasAll` and returns `CurrencyTripleResult.invalid('partial foreign-currency data: ...')`, so `CreateTransactionUseCase.execute` returns `Result.error(...)` (`create_transaction_use_case.dart:106-108`).

**Net effect:** Saying "五十美元 / 五十ドル" detects USD, but the save fails and the user sees the internal English string `"partial foreign-currency data: all three of originalCurrency, originalAmount, appliedRate must be non-null together"` via `showErrorFeedback`. The VOICE-CUR feature is non-functional end-to-end, and the surfaced message is an un-localized internal contract string (also an i18n violation).

**Fix:** The voice path must either (a) drive the same rate-fetch + `updateAmount`/`updateCurrencyTriple` pipeline that the manual screen uses once a foreign currency is detected (resolving the original amount from the merged voice amount in minor units and the rate from `appGetExchangeRateUseCaseProvider`), or (b) if the full triple cannot be resolved at commit time, NOT call `updateCurrency` and instead leave the row JPY-native / route the user into a foreign-entry affordance. Do not leave `_originalCurrency` set without the other two. Minimal correct shape:

```dart
// after detecting currency in _stopRecordingAndCommit:
if (detectedCurrency != null && detectedCurrency.isNotEmpty && amount > 0) {
  final minorUnits = amount * subunitToUnitFor(detectedCurrency); // amount is whole units from voice
  final withSignal = await ref.read(appGetExchangeRateUseCaseProvider)
      .execute(GetExchangeRateParams(currency: detectedCurrency, date: data.parsedDate ?? DateTime.now()));
  final rate = _extractRate(withSignal.result);
  if (rate != null) {
    final jpy = convertToJpy(
      originalMinorUnits: minorUnits,
      appliedRate: rate,
      subunitToUnit: subunitToUnitFor(detectedCurrency),
    );
    state.updateAmount(jpy);
    state.updateCurrencyTriple(
      originalCurrency: detectedCurrency,
      originalAmount: minorUnits,
      appliedRate: rate,
    );
  }
  // else: leave JPY-native, do NOT set a partial triple.
}
```

Add an integration test that asserts a foreign-currency voice utterance persists a row whose `amount == convertToJpy(...)` and whose triple is complete — the current suite clearly has no such assertion or this would be red.

---

### Warnings

#### WR-01: Date-change during `_pushForeignTriple` await persists a rate for the wrong date

**File:** `lib/features/accounting/presentation/screens/manual_one_step_screen.dart:322-352`

**Issue:** The post-await staleness guard checks currency and amount but not the date:

```dart
final withSignal = await ref.read(conversionRateProvider(args).future);
if (!mounted || currency != _currency || minorUnits != _originalMinorUnits) {
  return;
}
```

The fetch `args` captures `date = _selectedDate` at call time. If the user changes the date (via the form's date picker) while the rate fetch is in flight, the resolved `rate` is for the OLD date, but it is pushed as the persisted `appliedRate` for a transaction whose `timestamp` is now the NEW date. The stored triple's rate then disagrees with the transaction date (and with what the preview — which re-keys on the new date — will show). Because the triple is excluded from the hash chain (ADR-021), this divergence is undetectable post-persist.

**Fix:** Capture `date` alongside `currency`/`minorUnits` and include it in the bail check:

```dart
final date = _selectedDate;
...
if (!mounted || currency != _currency ||
    minorUnits != _originalMinorUnits || date != _selectedDate) {
  return;
}
```

#### WR-02: Stale JPY amount can persist as a native row when the rate becomes unavailable mid-entry

**File:** `lib/features/accounting/presentation/screens/manual_one_step_screen.dart:330-340`

**Issue:** When the rate resolves to `RateUnavailable` (`rate == null`), the code clears the triple but does NOT reset the form amount:

```dart
if (rate == null) {
  _formKey.currentState?.updateCurrencyTriple(
    originalCurrency: null, originalAmount: null, appliedRate: null,
  );
  return; // <-- _amount in the form is left at its previous value
}
```

If a prior push had succeeded (form `_amount` = some JPY value) and a subsequent re-resolution (e.g. amount change, or date change → weekend with no rate) returns `RateUnavailable`, the form keeps the previous JPY `_amount` while the triple is nulled. The save guard (`_trySave`) only validates the controller's foreign amount string (non-empty), not the resolved JPY. A Save in that window persists a **JPY-native row with a stale converted amount** that no longer corresponds to any rate. The preview shows the mandatory-rate prompt, so the UI and the persisted value disagree.

**Fix:** In the `rate == null` branch, also zero the form amount so the create use case rejects the save (amount <= 0) rather than persisting a stale figure:

```dart
if (rate == null) {
  _formKey.currentState?.updateAmount(0);
  _formKey.currentState?.updateCurrencyTriple(originalCurrency: null, ...);
  return;
}
```

#### WR-03: `detectCurrencyToken` leftmost-wins is unsound when a shorter token precedes a longer one

**File:** `lib/infrastructure/voice/numeral_state_machine.dart:109-126`

**Issue:** The scan chooses the token with the smallest `indexOf`, relying on the documented assumption that "a longer token that contains a shorter one always starts at an index ≤ the shorter token's index." That holds only when the shorter token appears *as a substring of* the longer one. It fails when the shorter token occurs **independently and earlier** than an unrelated longer token. Example (zh): `"元宝店买了美元"` — `元` (bare yuan) is found at index 0, `美元` (USD) at index 4. Leftmost-wins returns `元`, mis-classifying a USD utterance as bare-yuan (→ CNY in zh). Similarly any sentence where a bare `元`/`块`/`ドル` precedes an explicit foreign token loses the foreign classification.

**Fix:** Resolve by (start index, then descending token length) and prefer explicit-foreign tokens, or scan position-by-position taking the longest match at each index (mirroring the `_extractKeyword` regex which already uses longest-first alternation). At minimum, prefer a token present in `tokenToIso` over a bare-native token when both match.

#### WR-04: `_extractKeyword` amount-strip regex makes the currency suffix optional, leaving stray digits/markers

**File:** `lib/application/voice/parse_voice_input_use_case.dart:197-204`

**Issue:** The amount-removal pattern ends the suffix group with `?`:

```dart
RegExp(r'[¥￥]?\s*[\d,]+\.?\d*\s*(?:' + VoiceCurrencySuffixes.regexAlternation + r')?')
```

With the suffix optional, the regex matches the longest digit run regardless of suffix, but currency markers that are NOT adjacent to the number (or multi-token utterances) can leave residue. More concretely, `[\d,]+\.?\d*` will also strip bare numbers that are part of the category keyword (e.g. a店名 containing a digit), and because the alternation is built from `all` joined by `|` without anchoring, a stray standalone suffix char (e.g. a `元` not attached to a number) survives into the keyword. The WR-07 centralization comment claims parity with the merchant stripper, but the optional-suffix form does not guarantee the suffix is consumed. This degrades category resolution rather than corrupting persisted data, hence Warning.

**Fix:** Anchor the number+suffix removal so the suffix is consumed when present, and run a second explicit pass that removes any standalone `VoiceCurrencySuffixes.all` token left behind (the merchant-name extractor reportedly already does this — share that pass). Add a unit test for `"5块钱 拉面"` and `"五十美元 咖啡"` asserting the keyword is exactly the category word.

#### WR-05: `CurrencyLinkedEditFields` amount field edits raw minor units with no decimal affordance

**File:** `lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart:116`, `154-158`, `258-263`

**Issue:** The original-amount editor seeds and parses **minor units** directly:

```dart
_amountController = TextEditingController(text: _originalAmount.toString()); // e.g. "5000" for $50.00
...
void _onAmountChanged(String raw) {
  final parsed = int.tryParse(raw.trim());
  setState(() => _originalAmount = parsed ?? -1);
  ...
}
```

with `keyboardType: numberWithOptions(decimal: false)`. For a USD row the user sees and must edit "5000" to mean $50.00. This is internally consistent with `convertToJpy` (which divides by `subunitToUnit`), so it is not a conversion bug — but it is a real usability defect: a user editing "5000" to "60" intends $60 yet enters 60 *cents* (¥-equivalent ~0), and there is no decimal point or major-unit display to disambiguate. The entry screen, by contrast, exposes major-unit decimal input via `AmountInputController`. The two surfaces interpret the same field differently.

**Fix:** Display and accept the major-unit value (with the currency's decimal cap, reusing `AmountInputController.truncateToDecimals` / `currencyFractionDigitsFor`) and convert to minor units before storing `_originalAmount`, matching the entry path. At minimum, surface the minor-unit semantics with a unit label so the user is not silently off by `subunitToUnit`.

#### WR-06: `_onAmountChanged` maps empty/invalid input to sentinel `-1`, conflating "cleared" with "invalid"

**File:** `lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart:154-158`, `131-139`

**Issue:**

```dart
void _onAmountChanged(String raw) {
  final parsed = int.tryParse(raw.trim());
  setState(() => _originalAmount = parsed ?? -1);
  _notify();
}
```

A momentarily-empty field (user clearing to retype) sets `_originalAmount = -1`. `_deriveJpy` then returns null (`if (_originalAmount < 0) return null`) and `_notify` short-circuits (`if (jpy == null) return`), so `onChanged` is **not** fired — the host's `_originalAmount`/`_amount` retain their last good values while the widget's internal `_originalAmount` is `-1`. If the user navigates away / taps Save at that instant, the host persists the last-good amount even though the visible field is empty — a silent desync between what's shown and what's saved. There is also no inline error for the amount field (only the rate has `_rateError`), so an empty amount renders the JPY row as `—` with no explanation.

**Fix:** Track an explicit `_amountError` (empty / non-positive), surface it on the amount `TextField` like the rate field, and gate Save on a valid amount. Avoid the `-1` sentinel — use a nullable `int?` so "cleared" is distinguishable from "0/invalid".

---

### Info

#### IN-01: `_onCurrencyTap` calls `setState` immediately after `showModalBottomSheet`, not after it closes

**File:** `lib/features/accounting/presentation/screens/manual_one_step_screen.dart:386-397`

**Issue:** `showModalBottomSheet` returns a Future that is not awaited; `if (mounted) setState(() => _amountFocused = true)` runs synchronously right after the sheet is *shown*. The intent (reclaim amount focus after the sheet dismisses) is not what the code does — focus is reclaimed before the user picks. It happens to be harmless because selection also re-syncs focus, but the comment placement is misleading.

**Fix:** Either drop the redundant post-show `setState` or `await` the sheet and set focus in the continuation.

#### IN-02: `manual_one_step_screen` imports `dart:math` but the only use is one `math.max`

**File:** `lib/features/accounting/presentation/screens/manual_one_step_screen.dart:1`, `531`

**Issue:** Minor — fine as-is, just flagging that `math` is used solely for `math.max(viewInsetsBottom, 32.0)`, which `num.clamp`/a local helper could replace. No action required.

#### IN-03: `voice_parse_result` exposes both `categoryMatch.categoryId` and `merchantCategoryId`; consumers pick ad hoc

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart:339-340`

**Issue:** `final categoryId = data.categoryMatch?.categoryId ?? data.merchantCategoryId;` re-derives precedence that `ParseVoiceInputUseCase` already resolved into `categoryMatch` (the merchant branch sets `categoryMatch` from the normalized merchant id). The fallback to `merchantCategoryId` is effectively dead when a merchant matched (categoryMatch is already populated) and confusing otherwise. Not a bug, but the redundant fallback invites drift.

**Fix:** Consume `categoryMatch?.categoryId` alone (the use case guarantees it for both branches) and drop the `?? merchantCategoryId` tail, or document why both are needed.

#### IN-04: `list_screen` hardcodes `currencyCode = 'JPY'` with a TODO-style comment but no follow-up marker

**File:** `lib/features/list/presentation/screens/list_screen.dart:41-42`

**Issue:** `// Phase 29: resolve currencyCode from bookByIdProvider` then `const currencyCode = 'JPY';`. The display amount and calendar header are always formatted as JPY. For Phase 42 this is correct (the stored `amount` is always JPY; the foreign original is shown via `foreignAnnotation`), so this is not a defect — but the comment reads like an unfinished task without a tracked marker.

**Fix:** Either remove the stale "resolve from bookByIdProvider" comment (the JPY-amount invariant is intentional) or convert it to a tracked TODO so it is not mistaken for a bug.

---

_Reviewed: 2026-06-13T04:36:26Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

---

## Resolution (2026-06-13, user-approved)

All findings were independently re-verified against the code by the orchestrator before fixing.
**CR-01 + all 6 Warnings are FIXED**; full suite **2808/2808** green, `flutter analyze` 0 issues (+22 new tests).

| ID | Status | Fix commit | Note |
|----|--------|-----------|------|
| CR-01 | ✅ Fixed | `f1e3b1ea` | Voice foreign save wired (`_pushVoiceForeignTriple` mirrors manual; complete triple or JPY-native fallback; localized) |
| WR-01 | ✅ Fixed | `428b4d15` | `date` added to `foreignPushIsStale()` bail check |
| WR-02 | ✅ Fixed | `428b4d15` | `updateAmount(0)` on RateUnavailable → stale-JPY save rejected |
| WR-03 | ✅ Fixed | `41facf9a` | Explicit-foreign token preferred over earlier bare-native token |
| WR-04 | ✅ Fixed | `7a38657b` | Second pass strips standalone suffix residue from keyword |
| WR-05 | ✅ Fixed | `7e822993` | Edit host edits major-unit amount w/ decimal cap (reuses `AmountInputController`) |
| WR-06 | ✅ Fixed | `7e822993` | `int?` instead of `-1` sentinel; inline amount error; Save gated (no silent desync) |

**Info items (IN-01..04): deliberately NOT changed.** Per the reviewer's own notes these are non-defects
or cosmetic (IN-01 harmless focus timing, IN-02 lone `dart:math` use, IN-03 redundant-but-correct
category fallback, IN-04 stale comment on an intentional JPY-amount invariant). Left for optional future cleanup.
