---
task: 260622-nhs
round: R3
subsystem: accounting / voice push-to-talk entry
tags: [bugfix, tdd, ui, voice, single-page-entry]
human_verify: pending
gate:
  analyze: 0
  test_passed: 3108
  test_failed: 0
  goldens_rebaselined: 0
commits:
  - hash: 6d098fa0
    type: fix
    summary: reset re-arms listening (BUG 2)
  - hash: 0b6d9101
    type: fix
    summary: slim voice bar into keypad + trim bottom inset (BUG 1)
  - hash: 1c858612
    type: refactor
    summary: inline voice panel replaces keypad, no scrim/overlay (BUG 3)
key-files:
  modified:
    - lib/features/accounting/presentation/widgets/hold_to_talk_bar.dart
    - lib/features/accounting/presentation/widgets/voice_listening_overlay.dart
    - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
    - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
    - test/widget/features/accounting/presentation/widgets/hold_to_talk_bar_test.dart
    - test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart
    - test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart
    - test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart
metrics:
  manual_screen_loc: 1012
  manual_screen_loc_before: 1007
---

# Quick Task 260622-nhs R3: Device-tested voice-entry fixes — Summary

Fixed 3 device-found bugs in the single-page tap-to-record voice entry (modifies
R2 in place): the record strip is now a slim 38dp top strip of the keypad with
the doubled bottom inset removed; tapping 「重置」 now guarantees the session keeps
listening; and the listening UI replaced its full-screen scrim overlay with an
inline panel that takes the keypad's footprint (form stays visible, un-dimmed,
auto-filling). D-2 (fill-and-stay, no auto-save) and all external voice behavior
(foreign triple / satisfaction / JPY-native / merger) unchanged.

## What changed

### BUG 1 — slim bar into keypad + trim bottom whitespace (`0b6d9101`)
- `VoiceRecordBar`: 52dp rounded floating card → 38dp flush strip. Removed the
  `margin(16,0,16,8)` and rounded border; light joy tint + single bottom hairline
  so it reads as the keypad's top strip. Mic glyph 20→18.
- `manual_one_step_screen.dart`: removed the R2 `SafeArea(top:false)` wrapping
  `[strip + keypad]`. It doubled SmartKeyboard's own 24dp bottom padding (~+34dp
  on notched devices). The keypad's 24dp alone clears the home indicator →
  pre-R1 spacing restored.

### BUG 2 — reset must keep listening (`6d098fa0`)
- Root cause: `_onVoiceReset` → `resetPttSessionState()` clears buffers but never
  re-arms the recognizer. If the recognizer had self-terminated (pauseFor/done)
  with no re-arm cycle in flight, reset left a dead session.
- Added idempotent `restartPttListening()` to `VoicePttSessionMixin`: starts a
  fresh `startListening` ONLY when `_continuousActive && _isRecording &&
  !pttSpeechService.isListening`. No-op while already listening (no double-start);
  no-op once the session ended.
- `_onVoiceReset` calls it after clearing buffers.

### BUG 3 — voice panel replaces keypad in place (`1c858612`)
- `VoiceListeningModal` (Positioned.fill scrim + bottom-sheet chrome) →
  `VoiceRecordPanel` (inline; no scrim, no overlay, no sheet rounded/shadow).
  Content kept: pulsing 正在聆听 / transcript / VoiceWaveform / recording-red
  `mic_none` / 「轻点空白处退出」 hint / 「重置·恢复账目」 button.
- `manual_one_step_screen.dart`: removed the outer-Stack `if (pttIsRecording)
  VoiceListeningModal(...)`; render `pttIsRecording ? VoiceRecordPanel(...) :
  Column[slim VoiceRecordBar, SmartKeyboard]` inline in the AnimatedSlide. Panel
  occupies the keypad footprint → form above does not reflow; background stays
  un-dimmed and auto-fills live.
- Exit = tap the panel blank area (`onExit`); reset keeps its non-bubbling
  `onTap` (nested GestureDetector wins the gesture arena).

## Deviations from Plan

None — executed exactly as written in FIX-R3.

## TDD gates

Strict RED→GREEN per bug:
- BUG 2: mixin test `restartPttListening` re-arm/idempotent/closed-session (RED:
  method undefined → GREEN).
- BUG 1: `hold_to_talk_bar_test.dart` asserts ≤40dp height + no margin (RED on
  52dp → GREEN).
- BUG 3: rewrote `voice_listening_overlay_test.dart` for `VoiceRecordPanel`
  (no Positioned scrim, tap-exit, non-bubbling reset) + manual-screen test
  asserts panel replaces keypad, keypad returns on exit, reset stays open.

## Automated gate results

- `flutter analyze`: **0 issues**
- `flutter test` (full, incl. architecture tests): **3108 passed / 0 failed**
- Goldens re-baselined: **0** (no golden baseline references VoiceRecordBar,
  the panel, or the keypad bottom zone — verified, and the full run is green).
- palette-only (zero raw hex); Material line icons `Icons.mic_none` /
  `Icons.restore`.
- No ARB changes (panel reuses existing strings) → no gen-l10n needed.
- Podfile untouched. Branch `main`, no worktree.

## On-device recheck (human, PENDING)

1. **Bar slim + integrated** — resident state: the record strip is a short narrow
   top strip of the keypad (not a tall floating card); keypad bottom whitespace
   is normal (not over-padded).
2. **Panel replaces keypad, no scrim** — while recording: the voice panel takes
   the keypad's place in the same footprint; background is NOT dimmed; form above
   stays visible and auto-fills live; no overlay/scrim.
3. **Reset keeps listening** — tap 「重置·恢复账目」: the form rolls back to the
   pre-speech state AND the session keeps listening; speaking again auto-fills.

## Known Stubs

None.

## Self-Check: PASSED

- Commits `6d098fa0`, `0b6d9101`, `1c858612` exist in git log.
- Modified source/test files present on disk.
