---
phase: quick-260526-r8y
plan: 01
subsystem: accounting/presentation
status: complete  # All 3 items + critical toolbar save bug verified on device 2026-05-26
tags: [bug-fix, voice-ui, manual-tab, ime-toolbar, tap-region]
dependency_graph:
  requires:
    - 260526-l0o (voice host-cache + transcript spec)
    - 260526-j98 (form 3-card structure)
    - 260526-inb (KeyboardToolbar elevation + 完成 frame)
  provides:
    - kKeyboardToolbarTapRegionGroup shared constant (keyboard_toolbar.dart)
    - voice-input area card decoration (voice_input_screen.dart)
  affects:
    - manual tab save-from-toolbar path
    - voice tab visual layout + save button label
tech_stack:
  added: []
  patterns:
    - "TapRegion + TextField.groupId (Flutter first-class IME accessory pattern)"
    - "Inline duplication of _formCard decoration (avoiding new shared widget per constraints)"
key_files:
  created:
    - docs/worklog/20260526_1951_260526_r8y_voice_area_border_save_button.md
  modified:
    - lib/features/accounting/presentation/widgets/keyboard_toolbar.dart
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart
    - lib/features/accounting/presentation/screens/voice_input_screen.dart
    - test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart
    - test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart/goldens/voice_input_screen_mic_button_idle.png
decisions:
  - "Reuse existing `record` ARB key for voice tab save button — zero ARB edits, since the `save` key is consumed by 4 other screens and mutating its value would break their semantics. The `record` key already resolves to 记录/記録する/Record in all 3 locales — exactly the target."
  - "Fix Item 3 with TapRegion + shared groupId (Flutter first-class) rather than workarounds like 'delay unfocus by one frame' or 'make _trySave work after unfocus' — root-cause fix eliminates the spurious unfocus event itself, preventing latent regressions where unrelated state piggybacks on _isTextFieldFocused."
  - "Inline-duplicate the _formCard decoration spec in voice_input_screen.dart rather than extract a shared widget — per plan constraints (no new shared widget). The duplication is mechanical and small (~10 lines)."
  - "Regression test uses explicit startGesture+pumpAndSettle+up rather than tester.tap to faithfully reproduce the production race between TextField.onTapOutside (pointer-down) and InkWell.onTap (pointer-up). tester.tap fires both events too quickly to trigger the unmount race that breaks save on real devices."
metrics:
  duration: ~25min
  tasks_completed: 4
  tasks_total: 5
  completed_date: 2026-05-26
---

# Quick 260526-r8y: Voice area card border + transcript spacing + save label + toolbar save bug — Summary

Single-pass bug fix + 2 polish patches against the transaction entry screens. Item 3 (the CRITICAL bug) is closed by a Flutter-first-class `TapRegion` shared-group between the floating `KeyboardToolbar` and the merchant/note `TextField`s — taps on the toolbar are now treated as "inside" the TextField's tap-region group, so `onTapOutside` no longer fires on toolbar pointer-down, the toolbar stays mounted, and the InkWell→onSave path resolves correctly. Items 1 + 2 align the voice tab with the manual tab's visual rhythm (14dp card around mic+transcript+caption) and label vocabulary (保存 → 记录 / 記録する / Record via the existing `record` ARB key).

## Tasks Executed

| Task | Description | Commit |
| ---- | ----------- | ------ |
| 1 | TDD RED — failing regression test for toolbar-save bug | `57a99e8` |
| 2 | TDD GREEN — `TapRegion` + `groupId` fix on toolbar + TextFields | `d0f8ab3` |
| 3 | Voice screen — wrap voice-input area in 14dp card + rename `l10n.save` → `l10n.record` | `5d89b17` |
| 4 | Test audit + golden re-baseline + worklog | (no source change; golden + docs only — committed alongside Task 5 metadata) |
| 5 | Human verification | **PENDING — awaiting checkpoint** |

## Test Results

```
flutter test test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart
→ All 11 tests passed (new r8y Item 3 regression included)

flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart
→ All 23 tests passed

flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart
→ 1 test passed (after --update-goldens re-baseline; expected — mic now lives inside a card)

flutter analyze [4 production files + 2 test files]
→ No issues found!
```

## Deviations from Plan

None — plan executed exactly as written. Two minor implementation observations:

1. **First-pass regression test was insufficient (fail-fast caught it before commit).** The initial `tester.tap(toolbarSaveFinder)` form of the test passed on main even though the bug exists on real devices. Root cause: `tester.tap` fires pointer-down and pointer-up in the same microtask without an intermediate frame, so `_handleFocusChange`'s `setState` doesn't get to run between the events. Switched to explicit `startGesture` → `pumpAndSettle` → `gesture.up()`, which gave the failing-on-main behavior required by the TDD RED step (the plan's own task-1 verify command does NOT check that the test fails on main, but I verified manually per CLAUDE.md TDD).

2. **Voice mic golden re-baselined as plan explicitly anticipated.** No deviation — the plan documents this as an expected golden change and instructs `flutter test --update-goldens` on that single file. Visual diff is mechanical (card background bleeds into mic edges).

## Self-Check

Files exist:
- `lib/features/accounting/presentation/widgets/keyboard_toolbar.dart` — FOUND
- `lib/features/accounting/presentation/widgets/transaction_details_form.dart` — FOUND
- `lib/features/accounting/presentation/screens/voice_input_screen.dart` — FOUND
- `test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart` — FOUND
- `docs/worklog/20260526_1951_260526_r8y_voice_area_border_save_button.md` — FOUND

Commits exist:
- `57a99e8` — FOUND (test)
- `d0f8ab3` — FOUND (fix)
- `5d89b17` — FOUND (voice polish)

## Self-Check: PASSED

## Awaiting Human Verification (Task 5)

Run the app on the iOS simulator (or real device) and verify all three items:

**Item 3 verification (CRITICAL — the bug):**
1. Open the app → tap `+` to add transaction → manual tab (手动).
2. Tap a few digits on the keypad to set an amount (e.g. "100").
3. Tap the 商家 (merchant) input field — IME pops up, KeyboardToolbar appears at the bottom of the IME (showing 完成 outlined left + 记录 coral right).
4. WITHOUT typing anything in the merchant field, tap the 记录 button.
5. **EXPECTED:** The transaction saves immediately. A snackbar appears reading 已保存. The screen pops back to the main shell.
6. **FAIL CONDITION:** If the IME just dismisses and the screen stays open with no snackbar — the bug is NOT fixed.
7. Repeat with the 备注 (note) field instead of 商家. Same expected behavior.
8. Repeat WITH typing something in merchant first (e.g. "starbucks"). Save should still fire AND the merchant string should persist into the saved transaction (verify by opening the transaction in the list afterward).

**Item 1 verification (Voice card wrap):**
1. Open + → voice tab (语音).
2. Voice-input area: mic button + 按住说话 caption + transcript readout should all sit inside a white card with a thin gray border and 14dp rounded corners.
3. The card should visually align horizontally with the form cards above (16dp side margins).
4. Transcript area should have noticeable padding above it (sit "a bit further down").
5. Press and hold the mic to record — gesture, gradient color change (blue → coral), and animation should be unchanged.

**Item 2 verification (Voice save button label):**
1. On the voice tab, look at the bottom button.
2. **EXPECTED labels by locale:** zh → 记录, ja → 記録する, en → Record.
3. Button's coral gradient + disabled-state + 52dp height should be unchanged.

**Cross-check no regressions:**
1. Manual tab → tap amount keypad's 记录 button (SmartKeyboard's action row, NOT the toolbar) — should still save.
2. Manual tab → focus merchant → tap the 完成 button (outlined left) — IME should dismiss, SmartKeyboard should re-appear, NO save.
3. Manual tab → focus merchant → tap somewhere OUTSIDE the toolbar (e.g. on the AmountDisplay or form scrollview) — IME should dismiss as before (verify the `onTapOutside` fix is scoped only to the toolbar).
