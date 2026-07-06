---
phase: quick-260706-kax
plan: 01
subsystem: voice-entry
status: complete
requirements: [VRESET-01, VRESET-02, VRESET-03]
tags: [voice, ptt, reset, hit-test, bugfix]
dependency-graph:
  requires: []
  provides:
    - "resetPttSessionAndRestart dead-session recovery + reentrancy guard"
    - "voiceTapResetToRerecord caption as a reset hit-target"
  affects:
    - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
    - lib/features/accounting/presentation/widgets/voice_listening_overlay.dart
key-files:
  created: []
  modified:
    - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
    - lib/features/accounting/presentation/widgets/voice_listening_overlay.dart
    - test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart
    - test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart
decisions:
  - "Reset entry guard is the _restarting reentrancy fence, NOT _continuousActive — the reset button honors 重新录入 regardless of how the previous session died"
  - "Caption nesting is load-bearing: Transform outermost (skips own bounds check → visual-position taps land), GestureDetector inside Visibility (maintainSize IgnorePointer keeps it inert while listening)"
  - "Failed re-init rolls state back to stopped (no optimistic listening flip); finally clears _restarting so a later tap retries"
metrics:
  duration: ~25min
  completed: 2026-07-06
  tasks: 3
  tests-added: 4
---

# Quick Task 260706-kax: Fix Voice Reset Button Dead-Session No-Op Summary

**One-liner:** Dead-session voice reset now revives listening (guard on `_restarting` not `_continuousActive`), is reentrancy-safe, and the 「点击重置重新录入」 caption is a real reset hit-target via Transform-outermost re-nesting.

## Root Cause

- **BUG 1 (primary):** `resetPttSessionAndRestart()` early-returned on `!_continuousActive`. The `onError` fatal branch sets `_continuousActive=false` + `_listenStatus=stopped` while the host panel stays open, so every tap on the red reset square silently no-oped.
- **BUG 2:** `_restarting` was set inside the function but never checked at entry — a reentrant call in the cancel→start window double-started the recognizer (the exact plugin hang the function's own doc describes for the onStatus path).
- **BUG 3:** the caption was painted 34px above its layout box via `Transform.translate` nested INSIDE `Visibility(maintainSize)`; the Visibility proxy boxes bounds-check the un-shifted layout box, so a tap at the visual position missed entirely and fell through to the panel-root opaque `onExit` (accidental panel exit).

## What Changed

### Task 1 — Mixin (`voice_ptt_session_mixin.dart`)
- Entry guard: `!_continuousActive || !mounted` → `_restarting || !mounted`; `_restarting = true` remains the first statement after the guard, before any await, so a synchronous second call sees it (VRESET-02).
- `_continuousActive = true` restored in the buffer-clear `onPttSessionChanged` block, BEFORE `startListening`, so the recovered session's `_onResult` continuous-branch auto-fill works (VRESET-01).
- Belt-and-braces: if `!pttSpeechService.isAvailable` before the fresh start, `initialize(onStatus:, onError:)` first (idempotent — the fatal path's async `_recoverBarAfterFatalError` may not have completed). On failure: roll back to `_continuousActive=false / _isRecording=false / stopped` and return without starting; `finally` still clears `_restarting` so a later tap retries.
- Doc comment updated (dead-session revival + reentrancy fence rationale).
- Caller inventory grep-confirmed: definition + single call site (`manual_one_step_screen.dart:350` `_onVoiceReset`) only.

### Task 2 — Widget (`voice_listening_overlay.dart`)
- Caption subtree re-nested `Visibility → Transform → Padding → Text` ⇒ `Transform.translate(0,-34) → Visibility(isStopped, maintainSize/Animation/State) → GestureDetector(opaque, ValueKey('voice-reset-caption'), onTap: onReset) → Padding(bottom:8) → Text`.
- Transform outermost: `RenderTransform.hitTest` skips its own size check and inverse-maps the tap into child layout coordinates — visual-position taps land (VRESET-03).
- GestureDetector inside the Visibility: `maintainSize` keeps an `IgnorePointer(ignoring: !visible)`, so listening-state taps at that spot still fall through to the panel exit, byte-identical to before.
- Layout box and paint output unchanged — zero golden impact (verified: full suite green including all goldens).

### Test fake hardening (`CapturingSpeechService`)
- `isAvailable` field-backed (`available`, default true) + mutable `initializeResult` (default true) returned by `initialize` — defaults preserve behavior for all 24 pre-existing mixin tests.

## Test Evidence

| Gate | Result |
|------|--------|
| RED (Task 1) | 3 new tests failed exactly as predicted (guard no-op / startCount 3 / no re-init branch); 24 pre-existing green |
| GREEN (Task 1) | scoped mixin suite 27/27, exit 0 |
| RED (Task 2) | VRESET-03 failed (resets 0, visual tap missed); 13 pre-existing green |
| GREEN (Task 2) | overlay suite 14/14, exit 0 (incl. listening fall-through + equal-height invariants) |
| `flutter analyze` | 0 issues |
| FULL `flutter test` | **3570/3570 passed, exit 0** — no golden re-baseline |

## Commits

| Hash | Type | Description |
|------|------|-------------|
| `28f70d77` | test | failing VRESET tests for dead-session voice reset (RED, Task 1) |
| `f04e2cf7` | fix | voice reset revives dead session + reentrancy guard (GREEN, Task 1) |
| `0c66d520` | test | failing VRESET-03 caption hit-target test (RED, Task 2) |
| `c6aae5ff` | fix | make 点击重置重新录入 caption a reset hit-target (GREEN, Task 2) |

## Deviations from Plan

None - plan executed exactly as written. (The plan's "3 new tests" for Task 1 includes the belt-and-braces sub-case as Phase B within the third test, as specified.)

## Known Stubs

None.

## Threat Flags

None — no new trust-boundary surface; T-kax-01 (self-DoS double-start) mitigated by the `_restarting` entry guard as planned.

## Self-Check: PASSED

- All 4 modified files exist on disk.
- All 4 commit hashes present in `git log`.
- Working tree clean (code); `.planning` artifacts left for the orchestrator docs commit.
