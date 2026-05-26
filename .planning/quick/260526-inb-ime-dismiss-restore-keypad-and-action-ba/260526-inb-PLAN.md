---
phase: quick-260526-inb
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/accounting/presentation/widgets/transaction_details_form.dart
  - lib/features/accounting/presentation/widgets/keyboard_toolbar.dart
autonomous: false
requirements:
  - INB-IME-01  # 完成/IME-done restores SmartKeyboard
  - INB-IME-02  # KeyboardToolbar background flat-white edge-to-edge
  - INB-IME-03  # 完成 button has a visible frame

must_haves:
  truths:
    - "Tapping the toolbar's 完成 button dismisses the IME and restores the number keypad (no blank gap)."
    - "Tapping the system IME's ✓ / done / return key dismisses the IME and restores the number keypad."
    - "While the IME is open, the toolbar that frames the IME's candidate-words strip and hosts 完成/记录 is flat white (no dark-gray pill, no rounded outer corners)."
    - "The 完成 button reads as a tappable button — visible outlined frame, matched height to 记录."
    - "Existing manual_one_step_screen widget tests still pass; SmartKeyboard golden tests remain at parity (we are not changing SmartKeyboard rendering)."
  artifacts:
    - path: lib/features/accounting/presentation/widgets/transaction_details_form.dart
      provides: "Merchant + note TextFields with textInputAction.done and unfocus-on-submit wiring"
      contains: "textInputAction: TextInputAction.done"
    - path: lib/features/accounting/presentation/widgets/keyboard_toolbar.dart
      provides: "White-background accessory bar with outlined 完成 button matched to 记录 pill height"
  key_links:
    - from: "TextField.onSubmitted (merchant + note)"
      to: "FocusScope.of(context).unfocus()"
      via: "callback wired in transaction_details_form.dart"
      pattern: "onSubmitted:.*unfocus"
    - from: "_handleFocusChange in ManualOneStepScreen"
      to: "_isTextFieldFocused = false → _showSmartKeypad = true → AnimatedSlide(offset 0)"
      via: "FocusNode listener already exists"
      pattern: "no code change — relies on focus drop firing"
---

<objective>
Fix three defects on `ManualOneStepScreen` (添加账目) reported in screenshots 260526-inb-2/3/4:

1. **[BEHAVIOR]** When the system IME is dismissed via the toolbar's `完成` button OR via the IME's own ✓/done key, the screen must restore the custom number keypad (SmartKeyboard) — not leave a ~40% blank gray rectangle at the bottom.
2. **[VISUAL]** The IME accessory bar that hosts `完成 / 记录` must have a flat-white background with no rounded outer corners and no dark-gray pill, so it visually continues the white candidate-strip area above it.
3. **[VISUAL]** The `完成` button must have a visible frame (outlined ghost button) so it reads as a tappable control alongside the coral-pill `记录` button.

Scope is **surgical** — two files touched, no widget extraction, no refactor of `TransactionDetailsForm`, no changes to other entry hosts (voice / OCR / edit).

Purpose: Restore the v1.3 IME ⇄ keypad transition contract and tighten the accessory-bar visual to match the rest of the white surface.
Output: Updated `transaction_details_form.dart` (focus-drop wiring) + updated `keyboard_toolbar.dart` (white surface + outlined `完成`).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@CLAUDE.md
@.planning/STATE.md

# Read these before editing — they explain the focus state machine and visual tokens.
@lib/features/accounting/presentation/screens/manual_one_step_screen.dart
@lib/features/accounting/presentation/widgets/keyboard_toolbar.dart
@lib/features/accounting/presentation/widgets/smart_keyboard.dart
@lib/core/theme/app_colors.dart

<interfaces>
<!-- Existing focus state machine in ManualOneStepScreen (DO NOT MODIFY the screen) -->

From lib/features/accounting/presentation/screens/manual_one_step_screen.dart (lines 92, 169–179):

```dart
// D-05: SmartKeyboard slides off-screen when any TextField is focused.
bool get _showSmartKeypad => _amountFocused && !_isTextFieldFocused;

void _handleFocusChange() {
  final hasTextFocus = _merchantFocus.hasFocus || _noteFocus.hasFocus;
  if (hasTextFocus == _isTextFieldFocused) return;
  setState(() {
    _isTextFieldFocused = hasTextFocus;
    if (hasTextFocus) _amountFocused = false;
  });
}
```

Key insight: `_handleFocusChange` is wired as a listener on `_merchantFocus` and `_noteFocus` (lines 100–101). It fires whenever EITHER FocusNode's `.hasFocus` flips. SmartKeyboard restoration is automatic IF — and only if — the FocusNode actually loses focus. The bug is that the system IME's ✓ key does not currently cause focus loss because the TextFields lack `textInputAction` / `onSubmitted`.

<!-- Existing ARB strings — DO NOT add new keys -->

```
keyboardToolbarDone: zh=完成 / ja=完了 / en=Done  (app_zh.arb:909, app_ja.arb:909, app_en.arb:909)
record:              zh=记录 / ja=記録 / en=Record (already used by SmartKeyboard action button)
```

Both strings already exist — reuse `S.of(context).keyboardToolbarDone` for the outlined 完成 button.

<!-- Theme tokens to reuse for the visual fixes -->

From lib/core/theme/app_colors.dart:
```dart
AppColors.card             // 0xFFFFFFFF — pure white, use as toolbar background
AppColors.borderDefault    // 0xFFEFEFEF — card strokes, use as 完成 outline
AppColors.textPrimary      // 0xFF1E2432
AppColorsDark.card         // 0xFF252836 — dark-mode toolbar background
AppColorsDark.borderDefault
```

The existing `KeyboardToolbar` already uses `AppColors.card` as its background — but the *inner* gradient pill for 记录 has `borderRadius: BorderRadius.circular(10)` AND lives inside `Padding(horizontal: 12, vertical: 6)`. This creates the "pill island floating inside a wider bar" look. The user is not complaining about the pill — they want the **outer** look to be flat-white with no dark-gray rounded area. Looking at the screenshot more carefully: the dark-gray rounded pill the user describes is most likely the IME's own background bleeding through transparent edges. Make the toolbar **opaque white** with elevation 0 and a hairline top border (already there) — and ensure no padding/margin lets the IME's gray show.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Wire IME-done → unfocus on merchant and note TextFields (fixes Issue 1)</name>
  <files>lib/features/accounting/presentation/widgets/transaction_details_form.dart</files>

  <behavior>
    - Tapping the system IME's ✓ / Return / Done key while editing 商家 drops focus on _merchantFocus → _handleFocusChange in ManualOneStepScreen fires → _isTextFieldFocused = false → SmartKeyboard slides back up.
    - Same flow for the 备注 TextField via _noteFocus.
    - Tapping anywhere outside the TextField (e.g., on the scrollview body or AmountDisplay) also drops focus (defensive — onTapOutside).
    - No visual change to either TextField's container, padding, or hint.
  </behavior>

  <action>
On the merchant TextField (currently around line 530, keyed `ValueKey('merchant-textfield')`), add the following props alongside the existing `focusNode:` / `controller:` / `decoration:` properties — DO NOT re-order existing props, DO NOT touch the `InputDecoration`:

- `textInputAction: TextInputAction.done`
- `onSubmitted: (_) => FocusScope.of(context).unfocus()`
- `onTapOutside: (_) => FocusScope.of(context).unfocus()`

On the note TextField (currently around line 611, keyed `ValueKey('note-textfield')`), the field has `maxLines: null, expands: true` (multiline). The IME's Return key on a multiline field normally inserts a newline — that is correct iOS/Android behavior and we MUST NOT break it. Do the following:

- DO NOT add `textInputAction: TextInputAction.done` on the note field (would break newline insertion).
- DO add `onTapOutside: (_) => FocusScope.of(context).unfocus()` — this lets the user tap outside the note to dismiss the IME and restore the keypad. Combined with the `KeyboardToolbar.onDone` button (already wired in ManualOneStepScreen line 456), this gives users two unambiguous ways to dismiss the IME from the note field. The IME's ✓/Return staying as newline-insert in 备注 is correct, documented behavior — no fix needed there.

The root cause is documented: without `textInputAction` set, iOS may show "Return" instead of "Done" and pressing it does not always drop focus; Android keyboards behave inconsistently. This change makes the merchant field's IME show "Done" / "完了" / "完成" universally and guarantees unfocus on submit.

Do NOT modify ManualOneStepScreen — the existing FocusNode listener (`_handleFocusChange`) already handles the state transition once focus drops.
  </action>

  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app &amp;&amp; flutter analyze lib/features/accounting/presentation/widgets/transaction_details_form.dart &amp;&amp; flutter test test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart</automated>
    <human-check>
      Run `flutter run` on a device or simulator. On the 添加账目 screen:
      1. Tap 商家 → IME opens, the toolbar shows 完成/记录, and the IME's bottom-right key shows "Done" (en) / "完了" (ja) / "完成" (zh).
      2. Tap the IME's Done key → IME closes AND the number keypad slides back up. No blank gray gap.
      3. Tap the toolbar's 完成 → same result.
      4. Tap 备注 → IME opens. Type a line, press Return → newline inserts (multiline behavior preserved). Tap the toolbar's 完成 → IME closes, keypad restored.
      5. Tap 备注 → tap anywhere outside the field (e.g., on the amount display or the scrollview body) → IME closes, keypad restored.
    </human-check>
  </verify>

  <done>
    - Both TextFields have the props described above.
    - `flutter analyze` reports 0 issues for the file.
    - manual_one_step_screen_test.dart passes unchanged.
    - On-device manual test confirms IME ✓/Done and onTapOutside both restore the keypad with no blank gap.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Flatten KeyboardToolbar to white edge-to-edge; outline 完成 button (fixes Issue 2 + Issue 3)</name>
  <files>lib/features/accounting/presentation/widgets/keyboard_toolbar.dart</files>

  <behavior>
    - When the IME is open, the strip between the IME (above) and the screen content (below) renders as flat white (light) / AppColorsDark.card (dark) with a hairline top border and NO rounded outer corners — no dark-gray pill effect on the left or right edges.
    - The 完成 button on the left renders as an outlined ghost button: white fill, 1px border (AppColors.borderDefault / AppColorsDark.borderDefault), 10dp rounded corners, same vertical inset as the 记录 pill so the two read as a paired control.
    - The 记录 gradient pill on the right is unchanged in color, gradient, corner radius, and tap behavior.
    - Toolbar height stays 44dp (does not jostle the IME).
    - All strings stay sourced from ARB via `S.of(context).keyboardToolbarDone` and `S.of(context).record`.
  </behavior>

  <action>
The current widget already uses `Material(color: AppColors.card, elevation: 8)` as the outer wrapper — that is the right white background. The dark-gray pill the user perceives is caused by:
  (a) `Material.elevation: 8` casting a visible shadow that, combined with the IME's gray background above, makes the toolbar look like a floating pill with darker edges.
  (b) The 完成 side being naked text (no fill, no border), so the eye reads only the 记录 pill as the bar's content and the surrounding area as "framing."

Make the following edits to `KeyboardToolbar.build`:

1. **Drop the elevation shadow** — change `elevation: 8` to `elevation: 0` on the outer `Material`. The hairline top `BorderSide(color: ...borderDefault)` already in the inner `Container.decoration` provides separation from the IME without the shadow that reads as a dark pill. Keep `color: isDark ? AppColorsDark.card : AppColors.card` unchanged.

2. **Outline the 完成 button** — replace the bare `InkWell(child: Center(child: Text(...)))` for the left Expanded (currently lines 49–64) with:
   - The same `Expanded` wrapper, but with an inner `Padding(EdgeInsets.symmetric(horizontal: 12, vertical: 6))` to match the right side's inset (so both controls have the same visual height inside the 44dp bar).
   - Inside the padding, a `DecoratedBox` with `BoxDecoration(color: AppColors.card / AppColorsDark.card, border: Border.all(color: ...borderDefault, width: 1), borderRadius: BorderRadius.circular(10))` to mirror the 记录 pill's radius.
   - Inside the DecoratedBox, a `Material(color: Colors.transparent) → InkWell(onTap: onDone, borderRadius: BorderRadius.circular(10), child: Center(child: Text(S.of(context).keyboardToolbarDone, style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary, fontWeight: FontWeight.w600))))`.
   - Note the text color upgrade from `textSecondary` → `textPrimary` so the outlined button has acceptable contrast on white.

3. **Do NOT change anything inside the right Expanded** (the 记录 gradient pill). It is correct.

4. **Do NOT change the outer `Container` height (44)**, the top border, or the `Row` structure.

5. **Do NOT introduce a new color or text style** — reuse `AppColors.card`, `AppColors.borderDefault`, `AppColors.textPrimary`, `AppTextStyles.bodyMedium`. No magic hex.

Re-read the file after edits to confirm: outer Material has elevation 0, both Expanded children share the `Padding(horizontal: 12, vertical: 6)` envelope, the 完成 button has a visible 1px border, and the 44dp height is preserved.
  </action>

  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app &amp;&amp; flutter analyze lib/features/accounting/presentation/widgets/keyboard_toolbar.dart &amp;&amp; flutter test test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart</automated>
    <human-check>
      Run `flutter run`. On the 添加账目 screen, tap 商家 to bring up the IME. Verify:
      1. The strip between the IME and the screen body is solid white with a thin top border. No dark-gray rounded corners on the left/right edges. No drop-shadow halo.
      2. The 完成 button on the left has a visible outlined frame (white fill, light gray border, rounded corners) — matches the height of the 记录 pill on the right.
      3. The 记录 pill on the right is unchanged in color and shape.
      4. Tapping 完成 still dismisses the IME (re-verifies Task 1's contract still holds).
      5. Switch system theme to dark mode — toolbar still readable, 完成 outline still visible.
    </human-check>
  </verify>

  <done>
    - KeyboardToolbar renders edge-to-edge white with elevation 0 and no perceived dark pill.
    - 完成 button has a 1px outlined frame, same height envelope as 记录.
    - 完成 onTap still calls `onDone` (regression-free).
    - `flutter analyze` reports 0 issues.
    - manual_one_step_screen_test.dart still passes (it asserts widget presence and onTap behavior, not pixel layout).
    - Manual visual verification matches Issue 2 and Issue 3 acceptance.
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 3: End-to-end visual + behavioral verification on device</name>
  <what-built>
    Issues 1, 2, and 3 fixed on ManualOneStepScreen via surgical edits to two widget files (transaction_details_form.dart, keyboard_toolbar.dart). No SmartKeyboard, no ManualOneStepScreen, no other entry hosts were modified.
  </what-built>
  <how-to-verify>
    Run the app on a real device or simulator (NOT just widget tests — these are visual/behavioral defects):

    Pre-flight:
      cd /Users/xinz/Development/home-pocket-app
      flutter pub get
      flutter run

    From the home screen, tap the FAB to reach 添加账目 (ManualOneStepScreen).

    A. Issue 1 — IME dismissal restores keypad
       1. Confirm: number keypad is visible by default, amount field shows "0".
       2. Tap 商家. IME opens. Toolbar shows 完成 / 记录. Keypad slides off-screen.
       3. Tap the IME's Done/✓/Return key. EXPECTED: IME closes AND keypad slides back up. FAIL: any blank gray area remains.
       4. Tap 商家 again. This time tap the toolbar's 完成. EXPECTED: same — IME closes, keypad restored.
       5. Tap 备注. IME opens. Type "test". Tap Return. EXPECTED: newline inserts inside the note (do NOT close IME — multiline behavior preserved).
       6. Tap toolbar 完成. EXPECTED: IME closes, keypad restored.
       7. Tap 备注. Tap anywhere outside the field (e.g., on the amount). EXPECTED: IME closes, keypad restored.

    B. Issue 2 — toolbar background is flat white
       1. With IME open (from any tap on 商家 or 备注), look at the strip between the IME and the screen body.
       2. EXPECTED: solid white, hairline top border, no dark-gray rounded corners at the edges, no drop-shadow halo. FAIL: any dark-gray pill effect or rounded outer corners.

    C. Issue 3 — 完成 has a visible frame
       1. With IME open, look at the 完成 button on the left of the toolbar.
       2. EXPECTED: clearly a button — white fill, light-gray outlined border, rounded corners, same vertical envelope as the 记录 pill on the right. FAIL: still looks like plain text.

    D. Regression — neighboring screens unaffected
       1. Navigate to voice entry tab from the same modal. IME and SmartKeyboard there should behave identically to before this change (we did not touch them — quick sanity check only).
       2. Switch theme to dark. ManualOneStepScreen toolbar still readable; 完成 outline still visible.
       3. Switch locale ja → en → zh on the toolbar's 完成 label. Confirm strings come from ARB (en="Done", ja="完了", zh="完成").

    E. Golden tests
       1. cd /Users/xinz/Development/home-pocket-app
       2. flutter test test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart
       3. EXPECTED: all 6 baselines pass (SmartKeyboard itself was not modified).
       4. If any FAIL — STOP and report. Do NOT auto-update goldens.

    F. Full quality gate
       1. flutter analyze    → MUST be 0 issues
       2. flutter test       → MUST pass entirely
  </how-to-verify>
  <resume-signal>Type "approved" once all of A/B/C/D/E/F pass. If anything fails, describe what you saw and on which screen.</resume-signal>
</task>

</tasks>

<verification>
Phase-wide checks (Task 3 covers these in detail):

- `flutter analyze` — 0 issues
- `flutter test` — all pass (Manual one-step screen tests, SmartKeyboard tests, SmartKeyboard golden tests)
- On-device: tapping IME-done or toolbar-done on the merchant field restores the keypad with no blank gap
- On-device: KeyboardToolbar appears flat-white edge-to-edge with no dark-gray pill
- On-device: 完成 button has a visible outlined frame
- i18n: 完成 label resolves correctly in en/ja/zh
- No new color tokens, no new ARB keys, no new shared widgets
</verification>

<success_criteria>
1. Both TextFields (merchant + note) drop focus appropriately on IME-done or onTapOutside → SmartKeyboard restoration is automatic and visible.
2. `KeyboardToolbar` renders as flat white edge-to-edge (`elevation: 0`, no drop shadow), and the 完成 button has a visible outlined frame matched in height to the 记录 pill.
3. `manual_one_step_screen_test.dart` still passes without modification (test asserts widget presence + tap behavior; we didn't change either).
4. `smart_keyboard_golden_test.dart` still passes — SmartKeyboard itself is untouched.
5. `flutter analyze` reports 0 issues across the two modified files.
6. No new ARB keys added; existing `keyboardToolbarDone` is reused.
7. Worklog entry created at `docs/worklog/YYYYMMDD_HHMM_fix_ime_dismiss_and_toolbar_visual.md` per project rule.
</success_criteria>

<golden_tests>
- **Will be re-baselined?** No. The SmartKeyboard widget itself is unchanged — its 6 goldens (`smart_keyboard_{en,ja,zh}_{light,dark}.png` in `test/widget/features/accounting/presentation/widgets/goldens/`) should continue to pass without modification.
- **If they fail unexpectedly:** STOP and surface to the human at the Task 3 checkpoint. Do NOT silently run `flutter test --update-goldens`. A failure here means we accidentally changed SmartKeyboard, which is out of scope.
- **KeyboardToolbar goldens:** None exist for this widget. We are not adding any in this quick fix (scope is surgical). The visual change is verified manually at the Task 3 checkpoint.
</golden_tests>

<out_of_scope>
DO NOT touch in this plan:
- `lib/features/accounting/presentation/widgets/smart_keyboard.dart` — SmartKeyboard rendering and goldens are stable; the visual change is in the toolbar only.
- `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` — focus state machine is correct; we are fixing the upstream cause (TextField IME action) and the downstream visual (toolbar).
- `lib/features/accounting/presentation/screens/voice_input_screen.dart`, `transaction_edit_screen.dart`, `ocr_review_screen.dart` — other entry hosts. They share `TransactionDetailsForm` so they BENEFIT from Task 1's TextField focus fix automatically, but no per-screen changes here.
- `lib/core/shell/main_shell.dart` (or wherever MainShell lives) — not involved.
- The system IME itself, its candidate-words strip, and its key glyphs — not under our control.
- `TransactionDetailsForm`'s overall structure, sections, padding, dividers, or any field other than the two TextFields' new props.
- ARB files — no new strings needed; `keyboardToolbarDone` already exists in all three locales.
- New shared widgets — DO NOT extract a reusable `OutlinedToolbarButton`. The outlined 完成 lives inside KeyboardToolbar as inline code; if it's needed elsewhere later, extract then, not now.
- Color theme — DO NOT add new colors. Reuse `AppColors.card`, `AppColors.borderDefault`, `AppColors.textPrimary`.
</out_of_scope>

<output>
Create `.planning/quick/260526-inb-ime-dismiss-restore-keypad-and-action-ba/260526-inb-SUMMARY.md` when done, capturing:
- What was changed (two files, three issues)
- The root cause for Issue 1 (missing `textInputAction` / `onSubmitted` on TextFields)
- Confirmation that SmartKeyboard goldens passed unmodified
- Commit hash
- Any deferred items (none expected)

Also create the project worklog entry: `docs/worklog/YYYYMMDD_HHMM_fix_ime_dismiss_and_toolbar_visual.md` per `.claude/rules/worklog.md`.
</output>
