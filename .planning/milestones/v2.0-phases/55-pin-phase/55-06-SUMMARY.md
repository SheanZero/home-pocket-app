---
phase: 55-pin-phase
plan: 06
subsystem: infrastructure/security
status: complete
tags: [app-lock, lifecycle, observer, privacy-mask, relock, tdd]
requires:
  - "SyncLifecycleObserver callback/start/dispose shape (analog)"
provides:
  - "AppLockLifecycleObserver (root WidgetsBindingObserver, callback-driven)"
  - "two-flag guard (_authInProgress + _didPause) for relock + privacy mask"
  - "beginAuth()/endAuth() biometric fence for the lock screen (Plan 09)"
affects:
  - "Plan 11 (main.dart wiring of the observer into the lock gate)"
  - "Plan 09 (lock screen calls beginAuth/endAuth around biometric auth)"
tech-stack:
  patterns:
    - "callback-driven WidgetsBindingObserver (no Riverpod, device-free, unit-testable)"
key-files:
  created:
    - lib/infrastructure/security/app_lock_lifecycle_observer.dart
    - test/infrastructure/security/app_lock_lifecycle_observer_test.dart
  modified: []
decisions:
  - "Relock is gated on _didPause (paused reached), NOT on inactive — Control Center never relocks"
  - "_authInProgress fences the OS biometric sheet so it neither arms nor fires a relock (no loop)"
  - "Observer is self-contained callback-driven; main.dart wiring deferred to Plan 11"
requirements_completed: [LOCK-03, LOCK-04]
metrics:
  duration: ~6 min
  completed: 2026-06-30
  tasks: 2
  files: 2
---

# Phase 55 Plan 06: App-Lock Lifecycle Observer Summary

Built `AppLockLifecycleObserver`, a device-free callback-driven `WidgetsBindingObserver` that drives relock (LOCK-03) and the privacy mask (LOCK-04) using the RESEARCH §2 two-flag guard (`_authInProgress` + `_didPause`), so Control Center masks but never relocks and the OS Face-ID sheet never triggers a relock loop.

## What Was Built

- **`AppLockLifecycleObserver`** (`lib/infrastructure/security/app_lock_lifecycle_observer.dart`):
  - Constructor callbacks: `isLockEffective` (`bool Function()`), `onRelock`, `onMask`, `onUnmask` (`VoidCallback`).
  - Idempotent `start()` / `dispose()` (`_isActive` guard) mirroring `SyncLifecycleObserver`.
  - `beginAuth()` / `endAuth()` set/clear `_authInProgress` around the lock screen's biometric call (Plan 09 fence).
  - `didChangeAppLifecycleState` switch:
    - `inactive` → `onMask()` only when `isLockEffective()`.
    - `paused` → `_didPause = true` only when `!_authInProgress` (real backgrounding).
    - `resumed` → `onUnmask()`, then `onRelock()` iff `_didPause && !_authInProgress && isLockEffective()`, then reset `_didPause = false`.
    - `hidden` / `detached` → no-ops.
- **Unit test** (`test/infrastructure/security/app_lock_lifecycle_observer_test.dart`): 9 tests across the 4 prescribed scenarios (true background, Control Center, biometric fence, lock-disabled) plus hidden/detached no-op and start/dispose idempotency. Drives transitions by calling `didChangeAppLifecycleState` directly with spy counters and a mutable `isLockEffective` closure.

## How It Maps to the Threat Register

- **T-55-12 (Face-ID relock loop, high):** mitigated by `_authInProgress` fence + `_didPause`-gated relock. Grep gates pass (`_authInProgress` 7, `_didPause` 6, `AppLifecycleState.paused` 2); biometric-sheet scenario green.
- **T-55-13 (snapshot leak, high):** `onMask()` fires on `inactive` when `isLockEffective()`. Host paints the opaque mask (Plan 11); residual paint-timing is device QA (Plan 11).
- **T-55-14 (relock on every Control Center pull, medium):** relock gated on `_didPause`, not `inactive`; Control Center scenario asserts `onRelock` not called.

## Verification

- `flutter test test/infrastructure/security/app_lock_lifecycle_observer_test.dart` → 9/9 GREEN.
- `flutter analyze lib/infrastructure/security/app_lock_lifecycle_observer.dart` → No issues found.
- Grep gates: `_authInProgress` ≥1 ✓, `_didPause` ≥1 ✓, `AppLifecycleState.paused` ≥1 ✓.
- Real-device lifecycle (no flicker/loop, Control Center no-relock, snapshot cover) deferred to Plan 11 on-device QA per VALIDATION (cannot be faithfully simulated in `flutter_test`).

## Deviations from Plan

None — plan executed exactly as written (TDD RED → GREEN, no REFACTOR needed).

## TDD Gate Compliance

- RED: `test(55-06)` commit `17a45583` — tests failed (class did not exist).
- GREEN: `feat(55-06)` commit `d97d28dc` — all 9 tests pass.

## Known Stubs

None. The observer is callback-driven by design; `main.dart` wiring is explicitly Plan 11's scope (not a stub — a documented integration boundary).

## Self-Check: PASSED
- FOUND: lib/infrastructure/security/app_lock_lifecycle_observer.dart
- FOUND: test/infrastructure/security/app_lock_lifecycle_observer_test.dart
- FOUND commit: 17a45583 (RED test)
- FOUND commit: d97d28dc (GREEN impl)
