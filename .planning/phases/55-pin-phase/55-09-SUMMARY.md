---
phase: 55-pin-phase
plan: 09
subsystem: applock-presentation
status: complete
tags: [app-lock, biometric, pin, presentation, riverpod]
requirements_completed: [LOCK-05, LOCK-06]
provides:
  - AppLockScreen (two-surface unlock screen, onUnlocked callback)
  - AppLockSurface enum (presentation-local state)
requires:
  - AppLockService.verifyPin (Plan 07)
  - BiometricService.authenticate (Plan 02)
  - FaceIdPanel / PinKeypad / PinDots (Plan 08)
  - app-lock ARB keys (Plan 04)
affects:
  - main.dart gate ladder (Plan 11 wires onUnlocked + onBeginAuth/onEndAuth)
tech_stack:
  patterns:
    - ConsumerStatefulWidget + post-frame biometric auto-trigger
    - switch-expression surface routing (AppLockSurface)
    - context.palette (ADR-019) + S.of(context) i18n
key_files:
  created:
    - lib/features/applock/presentation/screens/app_lock_screen.dart
    - lib/features/applock/presentation/providers/app_lock_providers.dart
    - test/widget/features/applock/app_lock_screen_test.dart
  modified: []
decisions:
  - "Face ID surface auto-triggers biometric on first frame; every non-success AuthResult stays with the ghost passcode escape (no dead end, LOCK-05/T-55-20)"
  - "PIN instant-verifies on the 4th digit with a _verifying guard to prevent double-fire; wrong PIN bumps errorTrigger (PinDots owns the haptic) and clears, zero cooldown (D-12/D-06)"
  - "app_lock_providers.dart holds only the AppLockSurface enum — does NOT redefine appLockServiceProvider/biometricServiceProvider (consumes Plan 07/02)"
  - "Forgot-PIN copy shown in an AlertDialog with a keyed Text for deterministic testing (D-08/LOCK-09)"
metrics:
  duration: ~8 min
  tasks: 2
  files: 3
  completed: 2026-06-30
---

# Phase 55 Plan 09: AppLockScreen (Two-Surface Unlock) Summary

Assembled the user-facing unlock screen for sketch 002 tone B: a Face ID surface that auto-triggers biometric on entry and a PIN surface that instant-verifies on the 4th digit, composing the Plan 08 presentational widgets and driving them with the Plan 07 `AppLockService.verifyPin` + Plan 02 `BiometricService.authenticate`. Unlock is reported only via an `onUnlocked` callback — the screen never navigates or flips a gate flag (Plan 11 owns that).

## What was built

- **`AppLockScreen`** (`ConsumerStatefulWidget`):
  - Props: `required VoidCallback onUnlocked`; optional `onBeginAuth` / `onEndAuth` (the Plan 06 observer fence, wired by Plan 11); optional `bool startOnPinPage` (PIN-only config).
  - **Face ID surface** (default entry): `initState` schedules a post-frame `_runBiometric()`. It fences with `onBeginAuth` → `authenticate(reason: appLockReauthReason)` → `onEndAuth` in `finally`; on `AuthResultSuccess` calls `onUnlocked()`, on **every** other outcome stays on the surface rendering `FaceIdPanel` (retry re-runs the fenced auth; `パスコードを使用` flips to PIN). This consumes the Plan 02 LOCK-10 "all non-success → fallback" mapping so biometric is never a dead end.
  - **PIN surface**: accumulates digits from `PinKeypad`, drives `PinDots.filledCount`; on the 4th digit calls `appLockService.verifyPin(entered)` — match → `onUnlocked()`, mismatch → bump `errorTrigger` (PinDots plays shake + haptic) + clear, NO text, instantly retryable with zero cooldown (D-06). A low-key `忘记 PIN?` opens an `AlertDialog` with the no-recovery explanation (D-08/LOCK-09).
- **`app_lock_providers.dart`**: presentation-local `AppLockSurface { faceId, pin }` enum consumed by the screen. No service/provider redefinition.
- **Widget tests** (6): stay-on-Face-ID + escape, biometric-success unlock, PIN instant-verify success, wrong-PIN shake/clear/no-unlock/retryable, forgot-PIN copy.

## Verification

- `flutter test test/widget/features/applock/app_lock_screen_test.dart` — 6/6 green (was RED before implementation: compile failure, screen absent).
- `flutter test test/widget/features/applock/` — 11/11 green (no regression in Plan 08 widget tests).
- `flutter analyze lib/features/applock` — **No issues found**.
- Acceptance greps on `app_lock_screen.dart`: `onUnlocked`=5 (≥1), `pushReplacement`=0 (==0), `verifyPin`=4 (≥1), `onBeginAuth|beginAuth`=4 (≥1).

## TDD Gate Compliance

- RED gate: `test(...)` commit `973f9108` — failing AppLockScreen widget tests.
- GREEN gate: `feat(...)` commit `d6cd0f19` — implementation passing all 6.
- No REFACTOR commit needed (single unused-import fix folded into GREEN before commit).

## Deviations from Plan

None — plan executed as written. The only auto-fix was removing an unused `package:flutter/services.dart` import flagged by the analyzer (Rule 1, folded into the GREEN commit before it landed; `HapticFeedback` is owned by `PinDots`, not the screen).

## Threat surface

All four registered threats handled in-screen or deferred as planned: T-55-20 (DoS dead-end) mitigated by the always-reachable PIN escape; T-55-22 (info disclosure) mitigated by the no-recovery dialog copy; T-55-23 (relock loop) mitigated by the `onBeginAuth/onEndAuth` fence hooks (Plan 11 supplies the observer callbacks); T-55-21 (brute-force, zero cooldown) accepted by design per Plan 05 sign-off. No new security surface introduced.

## Notes for downstream (Plan 11)

- Wire `AppLockScreen(onUnlocked: _completeUnlock, onBeginAuth: observer.beginAuth, onEndAuth: observer.endAuth)` into the `main.dart` gate ladder AFTER onboarding, BEFORE the shell.
- `_completeUnlock` must `setState(() => _isLocked = false)` — never `pushReplacement` (boot-gate-completion-must-flip-flag).
- Real-device Face ID lifecycle (no relock loop) is the Plan 11 on-device QA item.

## Self-Check: PASSED

- FOUND: lib/features/applock/presentation/screens/app_lock_screen.dart
- FOUND: lib/features/applock/presentation/providers/app_lock_providers.dart
- FOUND: test/widget/features/applock/app_lock_screen_test.dart
- FOUND commit: 973f9108 (RED test)
- FOUND commit: d6cd0f19 (GREEN implementation)
