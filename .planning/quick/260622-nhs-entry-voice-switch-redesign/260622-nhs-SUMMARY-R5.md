---
task: 260622-nhs
round: R5
subsystem: accounting/voice
title: "Continuous-session onError — swallow transient no-match, recover bar, sync status"
tags: [voice, speech-recognition, ios, error-handling, ptt, continuous-session]
human_verify: pending
requires:
  - 260622-nhs R4 (continuous tap session, _listenStatus / _restarting / PttListenStatus)
provides:
  - VoicePttSessionMixin.onError override (transient swallow + fatal recover)
  - bar-recovery after fatal error (re-initialize speech service)
  - _listenStatus synced to stopped on every error path
affects:
  - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
key-files:
  created: []
  modified:
    - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
    - test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart
decisions:
  - "iOS error_no_match is permanent:true → cannot use `permanent` to classify fatal vs transient in continuous mode; use an error-code whitelist (_transientSilenceErrors)."
  - "Fatal-error bar recovery = re-initialize the speech service after teardown (not 'never flip isInitialized'), so the bar is both clickable AND backed by a live recognizer."
  - "Transient re-arm reuses R4's _restarting serialization guard (same double-start/假死 hazard as reset-restart)."
metrics:
  commits: 2
  files_changed: 2
  tests_added: 7
  analyze_issues: 0
  full_test: "3123/3123"
  completed: 2026-06-22
---

# 260622-nhs R5: Continuous-session onError / status fix Summary

Fixed two same-source device bugs in the continuous (hands-free tap) voice
session: (BUG 1) iOS reports `error_no_match` as `permanent: true`, and because
`VoicePttSessionMixin` did not override `onError`, the base handler ran — toasting
「未识别到语音内容」 and flipping `isInitialized=false`, which locked the
「语音记录」 bar after the first silent moment; (BUG 2) the error/stop paths never
updated `_listenStatus`, so the panel stayed on 「正在聆听」 after the recognizer
had stopped. R5 overrides `onError` to swallow silence-class errors (re-arming
listening) and to tear down + recover the bar on fatal errors, syncing
`_listenStatus` on every path.

## What changed

- **`onError` override in `VoicePttSessionMixin`:**
  - **Hold path** (`!_continuousActive`) → `super.onError(...)` unchanged (legacy
    toast + permanent `isInitialized` flip; `voice_input_screen` tests untouched).
  - **Continuous + transient silence** (`error_no_match` / `error_speech_timeout`)
    → no toast, no `isInitialized` flip, no teardown; keep `_isRecording=true` and
    `_listenStatus=listening`; re-arm via the `_restarting`-serialized
    `_reArmAfterTransientError()`.
  - **Continuous + fatal** (permission/audio/client/network) → clean teardown
    (`_continuousActive`/`_isRecording`/`_restarting` cleared,
    `_listenStatus=stopped`), toast, then `_recoverBarAfterFatalError()`
    re-`initialize`s the service so the bar guard
    (`pttServiceInitialized && !pttIsRecording`) passes for the next tap.
- **BUG 2:** `_listenStatus` is written on every error path (→ `stopped` on fatal,
  kept `listening` on a swallowed transient) so the panel never sticks on 正在聆听.
- **Tests:** fake speech service gains `initializeCount` + `emitError()`; 7 new R5
  tests cover transient-swallow, fatal-teardown+recover, hold-path-legacy, and the
  status-sync.

## iOS error classification — confirmed

`speech_recognition_service.dart` passes `error.permanent` straight through, and
the project's prior device reports establish that iOS sends `error_no_match` with
`permanent: true` on a silence timeout. The hypothesis held — no deviation from
the FIX-R5 root cause. The fix therefore classifies by error CODE
(`_transientSilenceErrors`), not by the `permanent` flag, since `permanent` is an
unreliable fatal/transient discriminator on iOS.

## Deviations from Plan

None — implemented exactly per FIX-R5. One inline compile fix during GREEN:
added the missing `import '../widgets/voice_error_toast.dart';` so the override
could call `showVoiceRecognitionErrorToast` (not a behavior deviation).

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | `1f309a9b` | fix(260622-nhs): continuous-session onError — swallow transient no-match, recover bar |
| 2 | `a44e7b0d` | fix(260622-nhs): sync listen status to stopped on error/stop |

## Automated gate

- `flutter analyze` (full): **0 issues**.
- `flutter test` (full, incl. macOS goldens + architecture tests): **3123 passed, 0 failed**.
- ptt mixin suite: **21/21** (14 prior R1–R4 + 7 new R5).
- Goldens: **no re-baseline needed** — the change is session-lifecycle logic; the
  panel's status colours are driven by the same `PttListenStatus` enum R4 already
  baselined (`stopped` → grey reuses the existing golden state). Full suite green
  confirms zero golden drift.
- palette-only: untouched (no colour literals added; status colours come from
  `AppPalette` via the panel). Podfile untouched. `manual_one_step_screen.dart`
  unchanged (LOC not grown).

## On-device recheck (human, PENDING)

1. **First-entry no-lock:** Tap 「语音记录」 and stay silent past the timeout →
   it must NOT toast 「未识别到语音内容」 and must NOT lock the bar; the bar stays
   tappable and the continuous session auto-continues listening through the silence.
2. **Status correct after stop:** After recording stops (exit / fatal), the panel
   shows 「停止聆听」 / 「正在解析…」 as appropriate — never stuck on 「正在聆听」.

## Self-Check: PASSED

- Modified files exist: `voice_ptt_session_mixin.dart`, `voice_ptt_session_mixin_test.dart` — FOUND.
- Commits present in history: `1f309a9b`, `a44e7b0d` — FOUND.
