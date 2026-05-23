---
phase: 19-manual-one-step-keypad-polish
reviewed: 2026-05-23T08:00:00Z
depth: standard
files_reviewed: 24
files_reviewed_list:
  - lib/application/voice/record_category_correction_use_case.dart
  - lib/features/accounting/domain/models/transaction_details_form_config.dart
  - lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart
  - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
  - lib/features/accounting/presentation/screens/ocr_review_screen.dart
  - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
  - lib/features/accounting/presentation/screens/voice_input_screen.dart (lines 340-450)
  - lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart
  - lib/features/accounting/presentation/widgets/detail_info_card.dart
  - lib/features/accounting/presentation/widgets/keyboard_toolbar.dart
  - lib/features/accounting/presentation/widgets/smart_keyboard.dart
  - lib/features/accounting/presentation/widgets/transaction_details_form.dart
  - lib/features/home/presentation/screens/main_shell_screen.dart (lines 120-170)
  - test/integration/features/accounting/manual_save_entry_source_test.dart
  - test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart
  - test/widget/features/accounting/presentation/screens/ocr_review_screen_amount_test.dart
  - test/widget/features/accounting/presentation/screens/transaction_confirm_screen_merchant_learning_test.dart
  - test/widget/features/accounting/presentation/screens/transaction_edit_screen_amount_test.dart
  - test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart
  - test/widget/features/accounting/presentation/widgets/entry_widgets_dark_mode_test.dart (partial)
  - test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart (partial)
  - test/widget/features/accounting/presentation/widgets/smart_keyboard_test.dart
  - test/widget/features/accounting/presentation/widgets/transaction_details_form_update_amount_test.dart (partial)
findings:
  critical: 2
  warning: 3
  info: 3
  total: 8
status: issues_found
---

# Phase 19: Code Review Report

**Reviewed:** 2026-05-23
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Phase 19 collapses the manual two-screen entry flow into `ManualOneStepScreen`, introduces a persistent `SmartKeyboard` with responsive height, `KeyboardToolbar` for soft-keyboard coexistence, and externalizes amount editing from `TransactionDetailsForm`. The overall architecture is sound: FocusNode lifecycle is correct, the P19-W1 save guard works, the merchant-learning hook is correctly restored, and the voice repoint is clean.

Two blockers were found: a decimal-amount sync bug that causes the form to save 0 (or a stale whole-number amount) when the user uses the dot key, and a dark-mode rendering failure in `AmountEditBottomSheet` from hardcoded `Colors.white`. Three warnings cover an `_isSubmitting` latch that permanently disables the save button if `submit()` throws, a soft-assertion pattern in tests that masks failures, and a hardcoded non-token color. Three info items note an unimplemented test stub, a hardcoded fallback string in an unmounted path, and minor code duplication.

---

## Structural Findings (fallow)

No structural pre-pass (`structural_findings` block) was provided for this review.

---

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Decimal dot tap resets form `_amount` to 0 via `int.tryParse` on non-integer strings

**File:** `lib/features/accounting/presentation/screens/manual_one_step_screen.dart:202, 218, 229, 236`
**Confidence:** High

`_onDigit`, `_onDoubleZero`, `_onDot`, and `_onDelete` all call `int.tryParse(_amount) ?? 0` after each keystroke and pass the result to `_formKey.currentState?.updateAmount(parsed)`. `int.tryParse` returns `null` for any string containing a decimal point — including the intermediate states `"123."` or `"123.45"`. The `?? 0` fallback then calls `updateAmount(0)`, resetting the form's internal `_amount` to 0.

**Concrete scenario:**

1. User taps `1`, `2`, `3` → `_amount = "123"` → `form._amount = 123` ✓  
2. User taps `.` → `_amount = "123."` → `int.tryParse("123.") = null` → `updateAmount(0)` → `form._amount = 0` ✗  
3. User taps `4`, `5` → `_amount = "123.45"` → `int.tryParse` still null → `form._amount` stays 0  
4. User taps Save → `submit()` → `createUseCase.execute(amount: 0)` → use case returns error "amount must be greater than 0"  
5. User sees the display showing "¥123.45" but receives a "Failed to save" snackbar — silent data mismatch.

The SC-4 integration test and widget tests avoid this path entirely (only integer amounts are tested), so the bug is not caught by the current test suite.

`AmountEditBottomSheet` handles this correctly by using `double.tryParse(cleaned)` followed by `.round()`, so the fix pattern is already established.

**Fix:**
```dart
// In each digit handler, replace int.tryParse with double.tryParse + round:
final parsed = (double.tryParse(_amount) ?? 0.0).round();
_formKey.currentState?.updateAmount(parsed);
```
Apply to lines 202, 218, 229, 236.

---

### CR-02: `AmountEditBottomSheet` hardcodes `Colors.white` — dark mode renders white sheet on dark background

**File:** `lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart:134`
**Confidence:** High

`AmountEditBottomSheet.build` uses `color: Colors.white` for the sheet's `Container` decoration and `color: const Color(0xFFD0D8E0)` for the drag handle. There is no dark-mode branch (`isDark` check). When the app is in dark mode, the bottom sheet renders a white background against the dark Scaffold, breaking the dark mode visual contract. The `SmartKeyboard` _inside_ the sheet does correctly adapt (reads `Theme.of(context).brightness`), but the container itself does not.

`AppColors.card = Color(0xFFFFFFFF)` (light) and `AppColorsDark.card = Color(0xFF252836)` (dark) are the correct tokens to use. The drag-handle color `0xFFD0D8E0` is not in the `AppColors` token set and should be replaced with `AppColors.borderDefault` / `AppColorsDark.borderDefault`.

**Fix:**
```dart
// In AmountEditBottomSheet.build:
final isDark = Theme.of(context).brightness == Brightness.dark;

// Container decoration:
color: isDark ? AppColorsDark.card : AppColors.card,

// Drag handle:
color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault,
```

---

## Warnings

### WR-01: `ManualOneStepScreen._isSubmitting` permanently latches to `true` if `submit()` throws

**File:** `lib/features/accounting/presentation/screens/manual_one_step_screen.dart:274-297`
**Confidence:** Medium

`_save()` sets `_isSubmitting = true`, then `await _formKey.currentState!.submit()`. If `submit()` throws (e.g., the merchant-learning `recordSelection()` call propagates an unexpected exception), the `setState(() => _isSubmitting = false)` line on line 279 is never reached. The `_isSubmitting` flag stays `true` permanently, leaving the SmartKeyboard Save and KeyboardToolbar Save both permanently disabled until the user closes and reopens the screen.

`TransactionDetailsForm.submit()` has a `try/finally` that resets `form._isSubmitting` — but that does not reset the HOST's `_isSubmitting` in `ManualOneStepScreen`.

The same pattern exists in `OcrReviewScreen` (line 74-77) and `TransactionEditScreen` (line 55-58) but those are Phase 18 code not in Phase 19 scope.

**Fix:**
```dart
Future<void> _save() async {
  if (_isSubmitting) return;
  setState(() => _isSubmitting = true);
  try {
    final result = await _formKey.currentState!.submit();
    if (!mounted) return;
    result.when(
      success: (_) { /* ... */ },
      validationError: (msg) { /* ... */ },
      persistError: (msg) { /* ... */ },
    );
  } finally {
    if (mounted) setState(() => _isSubmitting = false);
  }
}
```

---

### WR-02: Soft test assertions silently mask failures in integration and regression tests

**Files:**  
- `test/integration/features/accounting/manual_save_entry_source_test.dart:190-205` (digit taps)  
- `test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart:308, 360, 466` (Next and Record taps)  
- `test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart:344` (digit tap)

**Confidence:** High

Multiple test bodies guard widget interactions with `if (finder.evaluate().isNotEmpty) { ... }`. When the button or widget is not found, the tap is silently skipped. In the integration test, skipping the digit tap means `amount = 0` is sent to the use case, which rejects it with an error, and `rows = []` — the subsequent `expect(rows.first.entrySource, 'manual')` would then throw a `StateError` on `.first`, making the error confusing and untraceable to the real root cause. In the voice regression test, skipping the Record tap means the save never happens, the DB row is absent, and the error message points to the wrong assertion.

The pattern should use hard `expect(finder, findsOneWidget)` assertions before tapping to fail clearly at the point of absence.

**Fix:**
```dart
// Replace:
if (recordFinder.evaluate().isNotEmpty) {
  await tester.tap(recordFinder.first);
  await tester.pumpAndSettle();
}

// With:
expect(recordFinder, findsOneWidget,
    reason: 'SmartKeyboard Record button must be visible');
await tester.tap(recordFinder);
await tester.pumpAndSettle();
```
Apply to all three test files.

---

### WR-03: Drag-handle color `0xFFD0D8E0` is a hardcoded magic value absent from the AppColors token set

**File:** `lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart:146`
**Confidence:** High

The drag handle color `const Color(0xFFD0D8E0)` does not correspond to any named constant in `AppColors` or `AppColorsDark`. This makes future theme changes invisible to this widget (the color won't update when the design system adjusts border or divider tokens). The closest canonical token is `AppColors.borderDefault = Color(0xFFEFEFEF)`. This is also covered by CR-02 (dark mode) — fixing CR-02 by using the token resolves this warning as a side-effect.

**Fix:**
```dart
// Use the canonical token:
color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault,
```

---

## Info

### IN-01: Soul celebration TEST 4 stub defined but not implemented in `voice_to_manual_one_step_screen_test.dart`

**File:** `test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart:159`
**Confidence:** High

The file header docstring says "4. Soul celebration overlay appears for soul-ledger voice saves (Phase 18 D-15)" and soul fixture data (`_soulParentCategory`, `_soulCategory`) is defined at lines 159-181 specifically for "TEST 4". However, only three `testWidgets` blocks exist. TEST 3 asserts `entry_source=voice` and `ledger_type=soul` for a soul save, but does NOT assert that `SoulCelebrationOverlay` appears. The promised TEST 4 asserting `find.byType(SoulCelebrationOverlay)` was never written.

This leaves the D-15 celebration invariant for voice-path soul saves untested in Phase 19. The invariant IS tested in `transaction_details_form_test.dart` at the form level, but the end-to-end voice-push path has a coverage gap.

**Fix:** Add a fourth `testWidgets` block that taps Record after a soul voice save and asserts `find.byType(SoulCelebrationOverlay)` appears in the widget tree (same pattern as `transaction_details_form_test.dart` line 361-363).

---

### IN-02: Hardcoded English fallback strings `'Save failed'` and `'Update failed'` in unmounted path

**File:** `lib/features/accounting/presentation/widgets/transaction_details_form.dart:336, 390`
**Confidence:** High

When `!mounted` is true inside the `$new` and `edit` branches of `submit()`, the code returns `const TransactionDetailsFormResult.persistError('Save failed')` and `'Update failed'` — hardcoded English strings. This violates the project's i18n rule (all user-facing text via `S.of(context)`). In practice these strings are unreachable in normal operation (if the widget is disposed, the host's `_save()` also has a `if (!mounted) return` guard before calling `result.when(...)`), but they remain in the public API of `TransactionDetailsFormResult`.

**Fix:** Either remove the unmounted branch entirely (the host already guards this) or use a constant non-user-facing sentinel:
```dart
// Option A: remove (host's !mounted guard already handles this):
// Delete the `if (!mounted) { return const TransactionDetailsFormResult... }` block
// and rely solely on the host's mounted check.

// Option B: use a non-i18n-dependent internal constant:
return const TransactionDetailsFormResult.persistError('INTERNAL_UNMOUNTED');
```

---

### IN-03: `_computeSmartKeypadHeight` in ManualOneStepScreen and `build()` in SmartKeyboard independently recompute the same responsive formula

**File:** `lib/features/accounting/presentation/screens/manual_one_step_screen.dart:306-313` and `lib/features/accounting/presentation/widgets/smart_keyboard.dart:57-59`
**Confidence:** Medium

Both `ManualOneStepScreen._computeSmartKeypadHeight` and `SmartKeyboard.build` compute the responsive key height from `mq.size.height * 0.40 - mq.padding.bottom - (4 * 12.0)`. The host-side computation drives `scrollPaddingBottom`; the keyboard-side drives actual key height. If either formula drifts (e.g., row gap changes from 12 to 14dp, or the percentage changes from 40% to 42%), only one side is updated, creating a scrollPaddingBottom mismatch where the last few pixels of form content may slide behind the keyboard.

Note: the current `scrollPaddingBottom` computation also omits the SmartKeyboard's internal `padding: EdgeInsets.fromLTRB(12, 12, 12, 24)` (36dp vertical total), meaning the bottom padding of the scroll view is underestimated by ~36dp when the SmartKeyboard is hidden and the soft keyboard is up (the soft keyboard path uses `viewInsetsBottom` via `math.max`, which is correct in that case — the 36dp issue only matters if the SmartKeyboard is the bounding element, but since it occupies real column space, the Expanded scroll view already gets the remaining space and the padding is largely redundant).

**Fix:** Extract the height constant into a shared `kSmartKeyboardRowGap = 12.0` constant and a static helper, or pass `keypadHeight` from a layout notification so both sides use a single source of truth.

---

_Reviewed: 2026-05-23_  
_Reviewer: Claude (gsd-code-reviewer)_  
_Depth: standard_
