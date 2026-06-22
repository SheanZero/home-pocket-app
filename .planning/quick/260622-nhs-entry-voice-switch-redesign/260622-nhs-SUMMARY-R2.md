---
task: 260622-nhs
revision: R2
subsystem: accounting / voice entry
status: implemented
human_verify: pending
tags: [voice, manual-entry, tap-modal, auto-fill, reset-restore, i18n, safe-area]
commits:
  - 440afe73  refactor(260622-nhs): voice session → tap-toggle + form snapshot/restore
  - 19ee8f62  feat(260622-nhs): tap voice-record modal above keypad + safe-area + auto-fill
  - d9ad48d9  test(260622-nhs): tap-modal bar/modal/screen + reset-restore coverage
gate:
  analyze: 0
  full_test: 3104/3104 passed
  goldens_rebaselined: 0 (no golden covers these surfaces)
key-files:
  created:
    - lib/features/accounting/presentation/screens/manual_one_step_snapshot.dart
  modified:
    - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart
    - lib/features/accounting/presentation/widgets/hold_to_talk_bar.dart  (VoiceRecordBar)
    - lib/features/accounting/presentation/widgets/voice_listening_overlay.dart  (VoiceListeningModal)
    - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
    - lib/l10n/app_{ja,zh,en}.arb (+ generated)
---

# Quick Task 260622-nhs R2: 语音记录「点击·自动填表弹窗·重置恢复」改版 Summary

Switched the manual-entry voice affordance from R1 hold-to-talk to the FINAL
tap-modal-autofill design (`mocks/entry-voice-auto-modal.html`): a single-tap
「语音记录」 bar **above** the keypad raises a免持 listening modal that
auto-fills the form on every speech-final result; tap-anywhere/scrim exits
keeping the filled content; the lone 「重置·恢复账目」 button restores the
pre-speech snapshot and keeps listening. No 完成/no 取消. D-2 (fill-and-stay,
no auto-save) unchanged. Legacy unrouted `voice_input_screen` hold path left
byte-unchanged with all its tests green.

## What changed (vs R1)

### 1. Session logic — `VoicePttSessionMixin` (commit 440afe73)
- Added a tap-toggled **continuous** session: `startPttTapSession()` /
  `exitPttTapSession()` + a `pttContinuousActive` flag.
- **Auto-fill on each speech-final** while the session is open: `_onResult`
  parses (for satisfaction) then calls the extracted `_fillFormFromText`
  (the prior `stopPttSessionAndCommit` body, verbatim — one shared fill path,
  no parse/merger/foreign/satisfaction fork). The hold path is unchanged (it
  still fills on release only).
- **Re-arm** listening on recognizer self-termination (`onStatus` override) so
  a 30s/3s timeout keeps the modal listening instead of tearing it down.
- `exitPttTapSession` = stop merger + stop speech + final flush-fill + end
  session (content retained). `cancel`/`dispose` clear the continuous flag.
- Added read-only snapshot getters on `TransactionDetailsForm`
  (`currentAmount/Category/ParentCategory/Date/Merchant/Note/Satisfaction` +
  foreign triple) so the host can snapshot/restore without leaking controllers.

### 2. Bar — `VoiceRecordBar` (was `HoldToTalkBar`) (commit 19ee8f62)
- Moved **ABOVE** the SmartKeyboard (R1 had it below = the iOS up-swipe gesture
  zone bug); keypad+bar wrapped in a bottom `SafeArea(top:false)` so they clear
  the home indicator.
- press-and-hold → **single `onTap`**. Label 「语音记录」 (`voiceRecordBar`).
  Line mic `Icons.mic_none` (not filled).

### 3. Modal — `VoiceListeningModal` (was `VoiceListeningOverlay`) (commit 19ee8f62)
- Tap the modal body **or** the scrim = exit (stop + close, keep content, stay).
- Single 「重置·恢复账目」 button (line `Icons.restore`); its tap does NOT bubble
  to the exit handler (own GestureDetector). 完成/取消 removed.
- Content top→bottom: grab → 正在聆听 pulse → transcript → `VoiceWaveform` →
  recording-red rounded line mic (`Icons.mic_none` white) → 「轻点空白处退出」 hint
  directly below the mic → reset button.

### 4. Manual screen wiring (commit 19ee8f62)
- tap bar → snapshot form (`ManualEntrySnapshot.capture`) → `startPttTapSession`.
- exit → `exitPttTapSession` + clear snapshot.
- reset → `snapshot.restoreForm` + `restoreHostAmount` (amount/currency) +
  revert `_lastFillWasVoice` to the snapshot's value + `resetPttSessionState`
  (clears transcript/merger/parse, keeps listening).
- `EntrySource.voice` provenance preserved after a voice fill (R1 flag); a
  reset to a pure-manual snapshot reverts to manual (T-nhs-03).

## i18n
- ARB (ja/zh/en, `flutter gen-l10n`, `git add -f lib/generated/`):
  - `holdToTalkBar` → **`voiceRecordBar`** (语音记录 / 音声で記録 / Voice entry)
  - `releaseToFill` **removed**
  - **+`voiceTapToExit`** (轻点空白处退出 / 空白をタップで終了 / Tap anywhere to exit)
  - **+`voiceResetRestore`** (重置 / リセット / Reset) **+`voiceResetRestoreSub`** (· 恢复账目 / · 入力を元に戻す / · Restore entry)
  - `listeningTitle` retained. No orphan keys (arb_key_parity green).

## Deviations from Plan

### Commit structure (Rule 3 — buildable atomicity)
- PLAN-R2 listed bar (feat) and modal (feat) as two commits. They are tightly
  coupled at the screen-integration boundary (the screen references both the
  renamed `VoiceRecordBar` AND `VoiceListeningModal` in one build), so splitting
  them produces a non-compiling intermediate commit. Merged into one buildable
  `feat` commit (19ee8f62) + the refactor (440afe73) + a `test` commit
  (d9ad48d9). Net 3 atomic, each individually buildable.

### LOC (noted per constraint)
- `manual_one_step_screen.dart` grew 954 → **1007** (+53) for the
  tap/exit/reset handlers. Already over the 800 cap pre-existing (carried from
  R1). Mitigated by extracting `ManualEntrySnapshot` (snapshot capture +
  `restoreForm` + `restoreHostAmount`) into its own 110-LOC file. Not made
  materially worse; the new surface is genuinely new behavior.

### Auto-fixed
- None beyond the above. No bugs/missing-functionality found in scope.

## Known Stubs
None.

## Threat Flags
None — no new network/auth/file/schema surface (reuses the existing speech /
parse / rate / save pipeline; D-2 still never auto-saves).

## Gate Results
- `flutter analyze`: **0 issues**.
- FULL `flutter test`: **3104/3104 passed** (architecture tests included:
  hardcoded_cjk_ui_scan / color_literal_scan / arb_key_parity /
  provider_graph_hygiene).
- Goldens: **0 re-baselined** — no golden test covers the manual screen bar,
  the listening modal, or `VoiceRecordBar`. The only voice golden
  (`voice_input_screen_mic_button_golden_test`) is the unrouted hold screen,
  which is unchanged and stays green.
- Legacy `voice_input_screen` behavior tests: green, zero assertion changes.

## On-device verification checklist (human — PENDING)
Real mic/STT cannot be automated. On a device:
1. Open 添加账目 (manual). Confirm 「语音记录」 bar (line mic) sits **above** the
   keypad and the keypad+bar clear the home indicator (no iOS up-swipe conflict).
2. Tap 「语音记录」 → listening modal rises (免持, no hold needed).
3. Speak one phrase (e.g. 「拿铁 一千二百八 星巴克」) → 金额/分类/商家/日期 **auto-fill**
   live on the page behind the modal (no 完成 tap).
4. Tap blank area of the modal (or the scrim) → modal closes, **filled content
   kept**, page stays (no auto-save). Confirm 记录 still saves.
5. Re-open, speak, then tap 「重置·恢复账目」 → form rolls back to the pre-speech
   state, transcript cleared, modal **stays listening** (can re-speak). Tapping
   重置 must NOT close the modal.
6. Foreign utterance (e.g. 「十美金」) → header pill switches to USD + triple set;
   悦己 utterance → satisfaction estimated; JPY-native path unchanged.
7. App-pause/lock/timeout/text-field-focus still cancel the session.
