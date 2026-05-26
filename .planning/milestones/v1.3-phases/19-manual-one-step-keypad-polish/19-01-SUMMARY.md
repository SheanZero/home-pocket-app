---
phase: 19-manual-one-step-keypad-polish
plan: "01"
subsystem: accounting-form
tags: [arb, localization, refactor, tdd, focusnode, valuekey]
dependency_graph:
  requires: []
  provides:
    - keyboardToolbarDone ARB key (en/ja/zh) consumed by KeyboardToolbar (Plan 03)
    - AmountEditBottomSheet widget consumed by Plan 04 (TransactionEditScreen + OcrReviewScreen host spillover)
    - TransactionDetailsFormState.updateAmount(int) consumed by Plan 03 (ManualOneStepScreen)
    - TransactionDetailsFormConfig.$new.merchantFocusNode + noteFocusNode consumed by Plan 03
    - ValueKey markers (category-chip, date-chip, merchant-textfield, note-textfield) consumed by Plan 03 + downstream tests
  affects:
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart (amount externalized)
    - lib/features/accounting/domain/models/transaction_details_form_config.dart (extended $new factory)
    - lib/features/accounting/presentation/widgets/detail_info_card.dart (added key field to DetailInfoRow)
tech_stack:
  added: []
  patterns:
    - Freezed sealed union extended with optional non-serializable fields (FocusNode)
    - TDD RED/GREEN cycle with Mocktail mocks and createLocalizedWidget harness
    - ValueKey marker pattern for testability (P19-W2 / VALIDATION.md SC-1)
    - FocusNode injection via Freezed config.maybeWhen (P19-W3)
key_files:
  created:
    - lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart
    - test/widget/features/accounting/presentation/widgets/transaction_details_form_update_amount_test.dart
  modified:
    - lib/l10n/app_en.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_en.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart
    - lib/features/accounting/domain/models/transaction_details_form_config.dart
    - lib/features/accounting/domain/models/transaction_details_form_config.freezed.dart
    - lib/features/accounting/presentation/widgets/detail_info_card.dart
decisions:
  - "Removed _editAmount() entirely from form; extracted logic to AmountEditBottomSheet (host-agnostic)"
  - "Added Key? key field to DetailInfoRow data class + forwarded to _DetailInfoCardRow for P19-W2 ValueKey markers"
  - "Used positional placeholder names (p1..p11) in maybeWhen lambdas to satisfy unnecessary_underscores linter rule"
  - "TEST 3 rewritten from rebuild-count approach to submit-outcome + captured-verify approach (Builder doesn't rebuild in test harness)"
  - "AmountEditBottomSheet uses actionLabel: per P19-B2 fix; analyze error on that file is intentional until Plan 02 renames SmartKeyboard parameter"
metrics:
  duration_minutes: 45
  completed_date: "2026-05-23"
  tasks_completed: 3
  files_modified: 12
---

# Phase 19 Plan 01: ARB Key + AmountEditBottomSheet + Form Refactor Summary

One-liner: Added keyboardToolbarDone ARB key, extracted AmountEditBottomSheet, refactored TransactionDetailsForm to externalize amount with updateAmount(int), ValueKey markers, and FocusNode wiring.

## Tasks Completed

### Task 1: Add keyboardToolbarDone ARB key (en/ja/zh) + regenerate S delegate

**ARB key added across all three locales:**

| Locale | File | Value |
|--------|------|-------|
| en | `lib/l10n/app_en.arb` | `"keyboardToolbarDone": "Done"` |
| ja | `lib/l10n/app_ja.arb` | `"keyboardToolbarDone": "完了"` |
| zh | `lib/l10n/app_zh.arb` | `"keyboardToolbarDone": "完成"` |

Each ARB entry includes `@keyboardToolbarDone` metadata with `"description": "Soft-keyboard accessory toolbar dismiss button (Phase 19)"`. Keys placed adjacent to existing `record` key block for reviewer locality.

`flutter gen-l10n` ran successfully (exit 0, no warnings). Generated files updated:
- `lib/generated/app_localizations.dart`: adds abstract `String get keyboardToolbarDone;`
- `lib/generated/app_localizations_en.dart`: returns `'Done'`
- `lib/generated/app_localizations_ja.dart`: returns `'完了'`
- `lib/generated/app_localizations_zh.dart`: returns `'完成'`

**ARB parity test result:** `flutter test test/architecture/arb_key_parity_test.dart` — 2/2 tests passed (P19-B4).

**Commit:** `1ab9b56` — `feat(19-01): add keyboardToolbarDone ARB key in en/ja/zh + regen S delegate`

---

### Task 2: Extract AmountEditBottomSheet shared widget

**New file:** `lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart`

**Public surface:**
- `class AmountEditBottomSheet extends StatelessWidget`
- Constructor: `AmountEditBottomSheet({required int initialAmount, required ValueChanged<int> onConfirm})`
- Static method: `static Future<void> show(BuildContext context, {required int initialAmount, required ValueChanged<int> onConfirm})`

**Implementation details:**
- Uses `StatefulBuilder` for `editStr` local state (verbatim transplant from `_editAmount()` lines 191-238 of the old form)
- Preserves all five handlers: `onDigit` (decimal-cap), `onDoubleZero` (zero-cap), `onDot`, `onDelete`, `onClear`
- `onNext` strips trailing dot, gates on `parsed > 0`, calls `Navigator.pop` then `onConfirm`
- Layout: drag-handle Container (36×4, #D0D8E0, radius 2) → `AmountDisplay` → `SmartKeyboard`
- **P19-B2 fix:** uses `actionLabel: S.of(context).record` (POST-rename API) — not `nextLabel:`. This causes a single analyze error on this file until Plan 02 renames the SmartKeyboard parameter; acceptable per wave-1/wave-2 sequencing (Plan 02 `depends_on: ['19-01']`).
- Zero references to `TransactionDetailsForm` (host-agnostic, verified by grep count == 0)

**Commit:** `1b59372` — `feat(19-01): extract AmountEditBottomSheet shared widget (POST-rename actionLabel: API)`

---

### Task 3: Refactor TransactionDetailsForm + Freezed config + Tests

**TDD RED commit:** `3e4e2b2` — 6 failing tests added before implementation

**TDD GREEN commit:** `3a46932` — implementation makes all 6 tests pass

#### (A) Freezed config extension (P19-W3)

`lib/features/accounting/domain/models/transaction_details_form_config.dart`:
- Added `import 'package:flutter/widgets.dart'` for `FocusNode`
- Added two optional fields to `$new` factory only: `FocusNode? merchantFocusNode` and `FocusNode? noteFocusNode`
- `.edit` factory unchanged (edit hosts use modal sheets, no persistent-keypad focus state)
- `transaction_details_form_config.freezed.dart` regenerated by `build_runner build --delete-conflicting-outputs`

#### (B) Form widget refactor (transaction_details_form.dart)

**Removals:**
- Import `../widgets/amount_display.dart` — deleted (line 34 in original)
- Import `../widgets/smart_keyboard.dart` — deleted (line 38 in original)
- Entire `_editAmount()` method — deleted (lines 182-286 in original, ~105 lines)
- Amount `DetailInfoRow` block (icon: `Icons.payments_outlined`) — deleted from `DetailInfoCard.rows`
- Orphaned `_formatAmount(int, Locale)` helper — deleted

**Additions:**
- `void updateAmount(int amount)` public method on `TransactionDetailsFormState`:
  ```dart
  void updateAmount(int amount) {
    if (!mounted) return;
    if (amount == _amount) return;  // Pattern S-1 idempotency
    setState(() => _amount = amount);
  }
  ```
- Updated all `.when($new: ...)` / `.maybeWhen($new: ...)` lambdas to accept new 11-parameter signature (was 9)
- `key: const ValueKey('category-chip')` on category `DetailInfoRow` (P19-W2)
- `key: const ValueKey('date-chip')` on date `DetailInfoRow` (P19-W2)
- `key: const ValueKey('merchant-textfield')` on merchant `TextField` (P19-W2)
- `key: const ValueKey('note-textfield')` on note `TextField` (P19-W2)
- `focusNode: widget.config.maybeWhen($new: (..., merchantFocusNode, ...) => merchantFocusNode, orElse: () => null)` on merchant TextField (P19-W3)
- `focusNode: widget.config.maybeWhen($new: (..., noteFocusNode) => noteFocusNode, orElse: () => null)` on note TextField (P19-W3)

**DetailInfoCard change:**
- Added `Key? key` field to `DetailInfoRow` data class with doc comment citing P19-W2
- `_DetailInfoCardRow` updated to `const _DetailInfoCardRow({super.key, ...})` to forward the key

#### (C) Test file created

`test/widget/features/accounting/presentation/widgets/transaction_details_form_update_amount_test.dart`

| Test | Description | Status |
|------|-------------|--------|
| TEST 1 | updateAmount(0) + submit returns non-success (category null guard fires first) | PASS |
| TEST 2 | updateAmount(1500) + submit calls create use case with amount == 1500 | PASS |
| TEST 3 | updateAmount(500) twice is idempotent — second call is no-op | PASS |
| TEST 4 | AmountDisplay removed from form internal rendering (D-14 regression) | PASS |
| TEST 5 | ValueKey markers on category-chip/date-chip/merchant-textfield/note-textfield (P19-W2) | PASS |
| TEST 6 | FocusNode from $new config.merchantFocusNode wired to merchant TextField (P19-W3) | PASS |

All 6 tests pass. All existing smoke tests and form tests (13 total) continue passing.

---

## Overall Verification

| Check | Result |
|-------|--------|
| `flutter gen-l10n` exits 0, no warnings | PASS |
| `flutter test test/architecture/arb_key_parity_test.dart` passes | PASS |
| `flutter analyze transaction_details_form.dart, config.dart, detail_info_card.dart` | 0 issues |
| `flutter analyze amount_edit_bottom_sheet.dart` | 1 error (actionLabel: not yet in SmartKeyboard — intentional P19-B2) |
| `flutter test transaction_details_form_update_amount_test.dart` | 6/6 PASS |
| `flutter pub run build_runner build --delete-conflicting-outputs` exits 0 | PASS |
| `git diff pubspec.yaml pubspec.lock` — empty | PASS (D-12: zero new pub deps) |
| ARB parity grep check: `keyboardToolbarDone` count 2 in each ARB | PASS |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `Result.ok` does not exist — correct API is `Result.success`**
- **Found during:** Task 3 (test execution)
- **Issue:** Test used `Result.ok(...)` following a mental model from other Result libraries
- **Fix:** Changed to `Result.success(...)` matching `lib/shared/utils/result.dart` factory name
- **Files modified:** `transaction_details_form_update_amount_test.dart`
- **Commit:** `3a46932`

**2. [Rule 1 - Bug] `$new` string interpolation in test description string**
- **Found during:** Task 3 build_runner run (json_serializable error)
- **Issue:** `'TEST 6: FocusNode from $new config...'` — Dart interpolated `$new` as keyword
- **Fix:** Changed to raw string `r'TEST 6: FocusNode from $new config...'`
- **Files modified:** `transaction_details_form_update_amount_test.dart`
- **Commit:** `3a46932`

**3. [Rule 1 - Bug] TEST 3 idempotency test used Builder-above-form to count rebuilds**
- **Found during:** Task 3 test run (TEST 3 failed with "Expected: > 1, Actual: 1")
- **Issue:** `Builder` widget placed above `TransactionDetailsForm` doesn't rebuild when the form calls `setState` — the form is a separate widget subtree
- **Fix:** Rewrote TEST 3 to use submit-outcome + verify-capture approach: proves state is correctly updated to 500 after two calls, and use case is called exactly once
- **Files modified:** `transaction_details_form_update_amount_test.dart`
- **Commit:** `3a46932`

**4. [Rule 2 - Missing critical functionality] `DetailInfoRow` data class needed `Key? key` field**
- **Found during:** Task 3 implementation (P19-W2 ValueKey markers)
- **Issue:** `DetailInfoRow` is a data class without a `key` field; cannot attach ValueKey for test-findability without modifying the class
- **Fix:** Added `Key? key` field to `DetailInfoRow` with doc comment; forwarded to `_DetailInfoCardRow({super.key, ...})`; updated the for-loop instantiation: `_DetailInfoCardRow(key: rows[index].key, ...)`
- **Files modified:** `lib/features/accounting/presentation/widgets/detail_info_card.dart`
- **Commit:** `3a46932`

**5. [Rule 1 - Bug] Dart linter flagged `__` (double underscore) as unnecessary_underscores**
- **Found during:** Task 3 analyze (info-level warnings would have failed CI)
- **Issue:** Using `_, __, p10, p11` pattern for ignored parameters in `.when/$new` lambdas triggered `unnecessary_underscores` linter
- **Fix:** Changed all ignored parameters to named positional placeholders (`p1..p11`)
- **Files modified:** `lib/features/accounting/presentation/widgets/transaction_details_form.dart`
- **Commit:** `3a46932`

### Intentional Deviations (P19-B2 by design)

The `AmountEditBottomSheet` uses `actionLabel:` which is the POST-rename SmartKeyboard API that does not yet exist in `smart_keyboard.dart`. This causes a single analyze error on `amount_edit_bottom_sheet.dart`. This is intentional per the plan's P19-B2 fix: Plan 02 (`depends_on: ['19-01']`) will add `actionLabel:` parameter to SmartKeyboard in Wave 2, resolving the error when both commits land together.

## Known Stubs

None — all plan deliverables are fully wired with real behavior. No placeholder data flows to UI rendering.

## Threat Flags

No new security-relevant surface introduced. This plan only:
- Adds UI-safe string literals to ARB files (T-19-01-02: accepted)
- Adds a well-typed `int` parameter path to the form's internal state (T-19-01-01: accepted, validated by use case)
- Adds FocusNode injection (T-19-01-04: mitigated, host manages lifecycle)

## Hand-off to Downstream Plans

| Plan | Consumes from this plan |
|------|------------------------|
| **Plan 02** (SmartKeyboard refactor, Wave 2) | Depends on `amount_edit_bottom_sheet.dart` landing first (P19-B2); Plan 02 adds `actionLabel:` param to SmartKeyboard, resolving the analyze error in the sheet file |
| **Plan 03** (ManualOneStepScreen, Wave 2) | `updateAmount(int)` on `TransactionDetailsFormState`; `merchantFocusNode`/`noteFocusNode` fields on `$new` config; `keyboardToolbarDone` ARB key for `KeyboardToolbar` widget |
| **Plan 04** (Phase-18 host spillover, Wave 2) | `AmountEditBottomSheet.show(...)` for `TransactionEditScreen` + `OcrReviewScreen` amount-tap-to-sheet |

## Commit Log

| Commit | Type | Task | Description |
|--------|------|------|-------------|
| `1ab9b56` | feat | Task 1 | ARB key addition + gen-l10n regeneration |
| `1b59372` | feat | Task 2 | AmountEditBottomSheet extraction |
| `3e4e2b2` | test | Task 3 RED | Failing tests before implementation |
| `3a46932` | feat | Task 3 GREEN | Form refactor + Freezed extension + all tests pass |

## Self-Check: PASSED

- `1ab9b56` exists in git log: verified
- `1b59372` exists in git log: verified
- `3e4e2b2` exists in git log: verified
- `3a46932` exists in git log: verified
- `lib/l10n/app_en.arb` contains `keyboardToolbarDone`: verified
- `lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart` exists: verified
- `lib/features/accounting/presentation/widgets/transaction_details_form.dart` contains `updateAmount`: verified
- `lib/features/accounting/domain/models/transaction_details_form_config.dart` contains `merchantFocusNode`: verified
- `lib/features/accounting/domain/models/transaction_details_form_config.freezed.dart` contains `merchantFocusNode`: verified
- 6/6 new tests pass, 13/13 existing tests pass: verified
