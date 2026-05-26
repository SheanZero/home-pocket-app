---
phase: quick-260526-inb
plan: 01
status: incomplete  # Task 3 (checkpoint:human-verify, blocking) pending on-device human verification — by design, not a failure
type: execute
wave: 1
depends_on: []
requirements_completed:
  - INB-IME-01  # 完成/IME-done restores SmartKeyboard (code wired; pending device confirmation)
  - INB-IME-02  # KeyboardToolbar background flat-white edge-to-edge (code wired; pending device confirmation)
  - INB-IME-03  # 完成 button has a visible frame (code wired; pending device confirmation)
dependency_graph:
  requires:
    - lib/features/accounting/presentation/screens/manual_one_step_screen.dart  # focus state machine (unchanged, relied on)
    - lib/core/theme/app_colors.dart                                            # AppColors.card / borderDefault / textPrimary (no new tokens)
    - lib/generated/app_localizations.dart                                      # S.of(context).keyboardToolbarDone (existing ARB key)
  provides:
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart  # merchant + note TextFields with IME-done/unfocus wiring
    - lib/features/accounting/presentation/widgets/keyboard_toolbar.dart          # flat-white accessory bar with outlined 完成 button
  affects:
    - voice_input_screen.dart, transaction_edit_screen.dart, ocr_review_screen.dart  # transitively pick up the TextField focus fix (same shared form widget); no other change
tech_stack:
  added: []
  patterns:
    - "TextField.onSubmitted + onTapOutside → FocusScope.of(context).unfocus() (idiomatic Flutter IME-dismiss)"
    - "Outlined ghost button = Padding(h12 v6) → DecoratedBox(card + 1px border + 10dp radius) → Material(transparent) → InkWell (reuses existing layout envelope, no new widget extraction)"
key_files:
  created: []
  modified:
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart  # +4 lines (3 props on merchant TextField, 1 prop on note TextField)
    - lib/features/accounting/presentation/widgets/keyboard_toolbar.dart          # +30 / -11 lines (elevation 0, outlined 完成 button)
decisions:
  - "Root cause for Issue 1: TextFields lacked textInputAction; iOS rendered Return instead of Done and pressing it did not drop focus, so ManualOneStepScreen._handleFocusChange (FocusNode listener) never fired and SmartKeyboard stayed hidden. Fix is upstream (TextField props), not downstream (focus listener) — minimum-blast-radius patch."
  - "Note TextField intentionally omits textInputAction.done — multiline newline insertion via Return is required iOS/Android behavior; users dismiss the note IME via toolbar 完成 or onTapOutside instead."
  - "KeyboardToolbar dark-pill perception was caused by Material.elevation: 8 shadow against the IME's gray background. Dropping to elevation 0 + keeping the hairline top BorderSide preserves the IME ↔ toolbar separation without the shadow halo."
  - "Outlined 完成 inlined into KeyboardToolbar, not extracted to a shared OutlinedToolbarButton. Scope was surgical; extract if a second caller appears."
  - "No new color tokens, no new ARB keys — reused AppColors.card / borderDefault / textPrimary and existing keyboardToolbarDone string."
metrics:
  duration: ~2 min (executor wall-clock)
  completed: 2026-05-26
  tasks_completed: 2 of 3 (Task 3 blocking human-verify, by design)
  files_modified: 2
---

# Quick Task 260526-inb: IME-dismiss + KeyboardToolbar Visual Fix Summary

Fixed three defects on ManualOneStepScreen reported in screenshots 260526-inb-2/3/4 via surgical edits to two widget files — TextField IME-done/unfocus wiring on `TransactionDetailsForm`, and `elevation: 8 → 0` + outlined-ghost-button frame on `KeyboardToolbar`'s 完成 button.

## Before/After Diff Summary

### `transaction_details_form.dart` (+4 lines, no deletions)

**Merchant TextField (`ValueKey('merchant-textfield')`, around line 530):**
- Added `textInputAction: TextInputAction.done`
- Added `onSubmitted: (_) => FocusScope.of(context).unfocus()`
- Added `onTapOutside: (_) => FocusScope.of(context).unfocus()`
- `InputDecoration` untouched. Prop order preserved.

**Note TextField (`ValueKey('note-textfield')`, around line 611):**
- Added `onTapOutside: (_) => FocusScope.of(context).unfocus()` (only)
- Deliberately **did NOT** add `textInputAction: TextInputAction.done` — multiline newline insertion on Return must be preserved. Users dismiss the note IME via the toolbar 完成 button or by tapping outside.

### `keyboard_toolbar.dart` (+30 / -11 lines)

**Outer Material wrapper:**
- `elevation: 8 → elevation: 0` (drops the drop-shadow halo that read as a dark-gray pill against the IME's gray background; hairline top `BorderSide(borderDefault)` already provides IME ↔ toolbar separation)
- `color: isDark ? AppColorsDark.card : AppColors.card` — unchanged

**Left `Expanded` (完成 button) — full replacement:**
- Old: bare `InkWell(onTap: onDone, child: Center(child: Text(..., color: textSecondary)))`
- New: `Padding(EdgeInsets.symmetric(horizontal: 12, vertical: 6))` envelope (matches the right 记录 pill's inset for paired-control height) → `DecoratedBox(BoxDecoration(color: card, border: Border.all(color: borderDefault, width: 1), borderRadius: BorderRadius.circular(10)))` → `Material(color: Colors.transparent)` → `InkWell(onTap: onDone, borderRadius: BorderRadius.circular(10), child: Center(child: Text(..., color: textPrimary, fontWeight: w600)))`
- Text color upgraded from `textSecondary` → `textPrimary` for acceptable contrast on white fill
- Dark-mode variants (`AppColorsDark.card`, `AppColorsDark.borderDefault`, `AppColorsDark.textPrimary`) selected via the existing `isDark` flag

**Untouched (per plan):**
- Right `Expanded` (记录 gradient pill) — gradient, radius, `onSave` handler unchanged
- Outer `Container.height: 44`
- Top hairline `BorderSide`
- `Row` structure

## Root Cause (Issue 1)

`TextField` without `textInputAction` set causes iOS to render "Return" instead of "Done" on the soft keyboard, and pressing it does not always drop focus. Without focus loss, `ManualOneStepScreen._handleFocusChange` (registered as a listener on `_merchantFocus` / `_noteFocus`) never fires, so `_isTextFieldFocused` stays `true`, so `_showSmartKeypad = _amountFocused && !_isTextFieldFocused` stays `false`, so the SmartKeyboard `AnimatedSlide` stays off-screen — producing the ~40% blank gray gap the user reported. The downstream state machine was correct; the upstream input contract was missing. Patch is one prop trio on the merchant field + a defensive `onTapOutside` on both.

## `flutter analyze` Results

| File | Result |
|---|---|
| `transaction_details_form.dart` | **0 issues** (1.2s) |
| `keyboard_toolbar.dart`         | **0 issues** (0.7s) |

## `flutter test` Results

| Suite | Result |
|---|---|
| `test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart` | **10/10 passed** (run after both Task 1 and Task 2 edits — no test changes) |
| `test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` (regression — 6 baselines: ja/zh/en × light/dark) | **6/6 passed** (SmartKeyboard untouched; goldens unmodified — Plan §<golden_tests> contract honored) |

## Commits

| Task | Hash | Message |
|---|---|---|
| 1 | `f29a6ef` | fix(260526-inb): wire IME-done/unfocus on merchant + note TextFields to restore SmartKeyboard |
| 2 | `c57fda6` | fix(260526-inb): flatten KeyboardToolbar to elevation 0 and add outlined frame to 完成 button |

## Task 3 — Awaiting Human Verification on Device

Task 3 is a `checkpoint:human-verify` (blocking) gate. The code-level fixes are in; what cannot be automated is the on-device visual + behavioral confirmation. The plan's `how-to-verify` block, condensed:

> Run the app on a real device or simulator (`cd /Users/xinz/Development/home-pocket-app && flutter pub get && flutter run`). From the home screen, tap the FAB to reach 添加账目 (ManualOneStepScreen). **(A) Issue 1 — IME dismissal restores keypad:** tap 商家, confirm IME shows Done/✓/完成/完了, tap it → expected: IME closes AND number keypad slides back up with no blank gap; repeat via toolbar 完成; on 备注 confirm Return inserts a newline (multiline preserved) but toolbar 完成 and onTapOutside both close the IME and restore the keypad. **(B) Issue 2 — toolbar is flat white:** with the IME open, the strip between IME and screen body must be solid white with a hairline top border, no dark-gray rounded corners at the edges, no drop-shadow halo. **(C) Issue 3 — 完成 has a visible frame:** the 完成 button on the left must read as a button — white fill, light-gray outlined border, rounded corners, same vertical envelope as the 记录 pill on the right. **(D) Regression:** check voice-entry tab in the same modal behaves identically (we did not touch it); switch to dark mode — 完成 outline still visible; switch locale ja → en → zh — 完成 label resolves correctly. **(E) Golden + full quality gate:** `flutter test test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` (already passed in this run), `flutter analyze` 0 issues, `flutter test` all pass. Type "approved" once A/B/C/D/E all pass; if anything fails, describe what was seen and on which screen.

## Deferred Items

None. Scope was honored exactly — two files touched, three issues addressed, no SmartKeyboard / ManualOneStepScreen / sibling-screen edits, no new color tokens, no new ARB keys, no widget extraction.

## Self-Check: PASSED

- File `lib/features/accounting/presentation/widgets/transaction_details_form.dart` exists
- File `lib/features/accounting/presentation/widgets/keyboard_toolbar.dart` exists
- Commit `f29a6ef` (Task 1) present in `git log`
- Commit `c57fda6` (Task 2) present in `git log`
- `flutter analyze` 0 issues on both modified files
- `manual_one_step_screen_test.dart` 10/10 pass
- `smart_keyboard_golden_test.dart` 6/6 pass (SmartKeyboard untouched; goldens NOT regenerated)
