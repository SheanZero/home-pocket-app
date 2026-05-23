---
phase: 19-manual-one-step-keypad-polish
fixed_at: 2026-05-23T10:30:00Z
review_path: .planning/phases/19-manual-one-step-keypad-polish/19-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 8
skipped: 0
status: all_fixed
---

# Phase 19: Code Review Fix Report

**Fixed at:** 2026-05-23
**Source review:** `.planning/phases/19-manual-one-step-keypad-polish/19-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 8 (2 Critical + 3 Warning + 3 Info)
- Fixed: 8
- Skipped: 0

## Fixed Issues

### CR-01: Decimal dot tap resets form `_amount` to 0 via `int.tryParse` on non-integer strings

**Files modified:** `lib/features/accounting/presentation/screens/manual_one_step_screen.dart`, `test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart`
**Commit:** `07a9f7d`
**Applied fix:** Replaced all four `int.tryParse(_amount) ?? 0` calls in `_onDigit`, `_onDoubleZero`, `_onDot`, and `_onDelete` with `(double.tryParse(_amount) ?? 0.0).round()`. Added CR-01 regression test that types "1", "2", "3", "." and asserts `updateAmount(123)` is called (not 0). Test passes.

### CR-02: `AmountEditBottomSheet` hardcodes `Colors.white` — dark mode renders white sheet on dark background

**Files modified:** `lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart`, `test/widget/features/accounting/presentation/widgets/entry_widgets_dark_mode_test.dart`
**Commit:** `52d389d`
**Applied fix:** Added `app_colors.dart` import. Added `isDark` flag via `Theme.of(context).brightness == Brightness.dark`. Sheet container now uses `isDark ? AppColorsDark.card : AppColors.card`. Drag handle now uses `isDark ? AppColorsDark.borderDefault : AppColors.borderDefault`. Also fixes WR-03 as a side-effect. Added two CR-02 regression tests asserting dark and light color tokens respectively — both pass.

### WR-01: `ManualOneStepScreen._isSubmitting` permanently latches to `true` if `submit()` throws

**Files modified:** `lib/features/accounting/presentation/screens/manual_one_step_screen.dart`, `test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart`
**Commit:** `4e9c378`
**Applied fix:** Wrapped the `submit()` call and `result.when()` block in `try/finally`. The `finally` block calls `if (mounted) setState(() => _isSubmitting = false)` unconditionally. Added WR-01 regression test that triggers a persist error result and verifies the save button can be tapped a second time (use case called twice total). Test passes.

### WR-02: Soft test assertions silently mask failures in integration and regression tests

**Files modified:** `test/integration/features/accounting/manual_save_entry_source_test.dart`, `test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart`, `test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart`
**Commit:** `bdc3a8c`
**Applied fix:** Replaced all `if (finder.evaluate().isNotEmpty) { await tester.tap(...) }` soft guards with `expect(finder, findsOneWidget, reason: ...)` followed by unconditional `await tester.tap(finder)`. Applied to: digit taps in manual_save_entry_source_test.dart, Next button tap and two Record button taps in voice_to_manual_one_step_screen_test.dart, and digit tap in manual_one_step_screen_test.dart P19-W1 test. All affected tests pass.

### WR-03: Drag-handle color `0xFFD0D8E0` is a hardcoded magic value absent from the AppColors token set

**Files modified:** `lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart`
**Commit:** `52d389d` (resolved as side-effect of CR-02)
**Applied fix:** The drag handle color is now driven by `AppColorsDark.borderDefault` / `AppColors.borderDefault` via the same `isDark` branch added for CR-02.

### IN-01: Soul celebration TEST 4 stub defined but not implemented in `voice_to_manual_one_step_screen_test.dart`

**Files modified:** `test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart`
**Commit:** `22673ad`
**Applied fix:** Added `SoulCelebrationOverlay` import and wired up a 4th `testWidgets` block (TEST 4) that pumps a soul-category voice save and asserts `find.byType(SoulCelebrationOverlay)` finds one widget. Uses the existing `_soulParentCategory` and `_soulCategory` fixtures that were previously orphaned. Test passes.

### IN-02: Hardcoded English fallback strings `'Save failed'` and `'Update failed'` in unmounted path

**Files modified:** `lib/features/accounting/presentation/widgets/transaction_details_form.dart`
**Commit:** `5ee08c9`
**Applied fix:** Replaced `'Save failed'` and `'Update failed'` in the `if (!mounted)` branches with `'INTERNAL_UNMOUNTED'` sentinel string. Added explanatory comments noting these code paths are unreachable in normal operation (host's `!mounted` guard prevents UI display). Analyzer passes.

### IN-03: `_computeSmartKeypadHeight` omits SmartKeyboard internal padding

**Files modified:** `lib/features/accounting/presentation/screens/manual_one_step_screen.dart`
**Commit:** `19fd5e5`
**Applied fix:** Added `const keyboardPaddingVertical = 12.0 + 24.0` (matching SmartKeyboard's `EdgeInsets.fromLTRB(12, 12, 12, 24)`) and included it in the return value so `scrollPaddingBottom` matches the actual rendered keyboard height. Added explanatory comment. Analyzer passes.

Note: The IN-03 finding also mentioned replacing `p1..p11` positional placeholders — this was addressed separately as IN-03 (maybeWhen) in commit `bfd6426`. See below.

### IN-03 (maybeWhen): Positional placeholders in `maybeWhen` FocusNode destructure

**Files modified:** `lib/features/accounting/presentation/widgets/transaction_details_form.dart`
**Commit:** `bfd6426`
**Applied fix:** Replaced anonymous `p1..p11` placeholders in both `maybeWhen` calls (for merchant and note FocusNode extraction) with the proper semantic parameter names from `TransactionDetailsFormConfig.$new`: `bookId`, `initialAmount`, `initialCategory`, `initialParentCategory`, `initialMerchant`, `initialSatisfaction`, `initialDate`, `entrySource`, `voiceKeyword`, `merchantFocusNode`, `noteFocusNode`. This makes future parameter reorders fail loudly at compile time.

---

## Regression Test Results

All success-criteria tests pass after fixes:

| Test file | Result |
|---|---|
| `transaction_details_form_update_amount_test.dart` | pass |
| `manual_one_step_screen_test.dart` (10 tests including CR-01, WR-01 new) | pass |
| `ocr_review_screen_amount_test.dart` | pass |
| `transaction_edit_screen_amount_test.dart` | pass |
| `manual_save_entry_source_test.dart` | pass |
| `voice_to_manual_one_step_screen_test.dart` (4 tests including TEST 4 new) | pass |
| `entry_widgets_dark_mode_test.dart` (6 tests including CR-02 dark/light new) | pass |

Total: 26 tests, all passed.

---

_Fixed: 2026-05-23_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
