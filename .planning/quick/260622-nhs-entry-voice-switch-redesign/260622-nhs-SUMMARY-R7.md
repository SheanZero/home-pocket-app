---
task: 260622-nhs
fix: R7
title: Voice panel central square dual-state button (drop bottom reset, equal-height two states)
type: refactor
subsystem: accounting / single-page voice input panel
status: complete
human_verify: pending
branch: main
worktree: false
date: 2026-06-22
commits:
  - f1e6cb36 refactor(260622-nhs): voice panel — central square dual-state button, drop bottom reset
  - d4e335d4 chore(260622-nhs): remove 「· 恢复账目」 reset sublabel ARB
key-files:
  modified:
    - lib/features/accounting/presentation/widgets/voice_listening_overlay.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - lib/generated/app_localizations.dart (+ ja/zh/en, regenerated)
    - test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart
    - test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart
gates:
  analyze: 0 issues
  full_test: 3132/3132 passed
  goldens: none affected (no golden test exercises the panel)
  i18n: 3 ARB updated + gen-l10n + git add -f
---

# Quick Task 260622-nhs · FIX R7 Summary — Voice Panel Central Square Dual-State Button

One-liner: The voice panel's bottom 「重置·恢复账目」 button is gone; the central square is now a dual-state button — grey passive line-mic while listening/processing, red recording-gradient reset square (tappable → `onReset`) when stopped — with both states held at equal height so there is no jump on transition. Reset semantics are byte-unchanged.

## What changed

1. **Deleted the bottom reset button** (`voice-panel-reset`) from `VoiceRecordPanel` entirely.
2. **Central square → dual-state** (extracted as `_CentralSquare`), driven by `status`:
   - `listening` / `processing` → grey fill (`backgroundMuted`) + `Icons.mic_none` (`textTertiary`); PASSIVE — no `GestureDetector`, so a tap bubbles to the panel's `onExit`.
   - `stopped` → red recording-gradient fill (`recordingGradientStart/End`) + `Icons.restore` (white); TAPPABLE (`voice-square-reset`) → `onReset`; the tap does NOT bubble to `onExit`.
   - Size 74dp / radius 22 (kept).
3. **Dropped 「· 恢复账目」**: removed `voiceResetRestore` / `voiceResetRestoreSub` usages and deleted the keys from ja/zh/en ARB (no other references), regenerated l10n, force-added `lib/generated/`.
4. **Equal-height two states**: the stopped-only 「点击重置重新录入」 hint uses `Visibility(maintainSize/maintainAnimation/maintainState, visible: stopped)` so the placeholder reserves the same height while listening — 「轻点空白处退出」 aligns at the same vertical position in both states. A widget test asserts `listeningSize.height == stoppedSize.height`.
5. **Everything else unchanged**: status line (● 正在聆听 red / ○ 停止聆听 grey), transcript, waveform, 「轻点空白处退出」 (always), inline-panel-replaces-keypad with no scrim.

## Behavior (unchanged)

- `onReset` semantics identical (host `_onVoiceReset`: restore pre-speech snapshot + clear transcript + `resetPttSessionAndRestart` fresh listen) — now triggered by tapping the RED square in the stopped state.
- The square is NOT tappable while listening/processing (grey, passive). Exit is still 「轻点空白处」.
- No change to `voice_ptt_session_mixin.dart` (PttListenStatus / pttListenStatus) — no logic change needed.

## Deviations from Plan

None — implemented exactly as the FIX-R7 spec.

Note on palette: the mock specifies cool-grey `#EAEDEC`/`#9AA8A0` for the grey square. Per the spec's "reuse existing tokens rather than new raw hex", the implementation reuses `backgroundMuted` + `textTertiary` (the same tokens R6 used for the stopped square) rather than adding a new token. The grey/mic look is preserved; the exact mock hue difference is cosmetic.

## Gate results

- `flutter analyze`: **0 issues**.
- `flutter test` (FULL): **3132/3132 passed** (includes architecture tests — hardcoded CJK UI scan, golden platform gate, provider-graph hygiene, etc.).
- Goldens: **no re-baseline required** — no golden test exercises `VoiceRecordPanel`; the visual change is covered by widget assertions (icon/key/height).
- i18n: 3 ARB updated, `flutter gen-l10n` run, `lib/generated/` force-added (gitignored-yet-tracked).
- `manual_one_step_screen.dart`: untouched (still well under 1012 LOC).

## TDD trail

RED: rewrote `voice_listening_overlay_test.dart` (grey passive mic while listening / red tappable reset when stopped / no bottom button / equal height) → 4 failing. Updated 2 screen tests (reset now via the red square). GREEN: rewrote the panel widget → 9/9 panel + 21/21 screen + full suite green.

## On-device recheck (human, PENDING)

1. **Recording (listening):** central square is grey + mic glyph, NOT tappable; no bottom reset button; tap blank area to exit.
2. **Stopped + equal height:** central square turns red + reset icon, tappable = re-record (restores pre-speech snapshot + re-arms a fresh listen); 「点击重置重新录入」 + 「轻点空白处退出」 shown; panel height is IDENTICAL to the recording state (no jump on transition).

## Self-Check: PASSED

- `voice_listening_overlay.dart` exists, modified — FOUND.
- ARB keys `voiceResetRestore`/`voiceResetRestoreSub` removed from ja/zh/en + generated — FOUND (0 grep matches).
- Commits `f1e6cb36`, `d4e335d4` — FOUND in git log.
