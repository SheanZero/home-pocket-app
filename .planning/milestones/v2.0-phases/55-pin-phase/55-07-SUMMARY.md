---
phase: 55-pin-phase
plan: 07
subsystem: security
tags: [app-lock, pin, argon2id, biometric, riverpod, tdd]

requires:
  - phase: 55-01
    provides: pin_kdf.derivePinPhc / verifyPin (Argon2id PHC, constant-time)
  - phase: 55-02
    provides: BiometricService (local_auth wrapper, AuthResult union)
  - phase: 55-03
    provides: SettingsRepository.setAppLockEnabled + appLockEnabled/biometricUnlockEnabled toggles
provides:
  - AppLockService — single source of truth for lockEffective (D-01), set/verify PIN (LOCK-06), reauth (D-05), disable
  - appLockServiceProvider (@riverpod) wiring settings repo + secure storage + biometric
affects: [55-09, 55-10, 55-11]

tech-stack:
  added: []
  patterns:
    - "Application-layer plain injectable service mirroring BiometricService (no Riverpod inside)"
    - "PIN secret (PHC) confined to keychain slot; boolean toggles in SharedPreferences"

key-files:
  created:
    - lib/application/security/app_lock_service.dart
    - test/application/security/app_lock_service_test.dart
  modified:
    - lib/infrastructure/security/providers.dart

key-decisions:
  - "lockEffective = appLockEnabled && pinHash!=null is the SINGLE predicate (D-01); no PIN => never lock (T-55-15)"
  - "reauth gates on biometricUnlockEnabled then maps only AuthResultSuccess->true; every non-success falls through to caller PIN entry (D-05)"
  - "disableLock both flips appLockEnabled=false AND deletes the PHC so a stale hash can never re-arm the lock (T-55-16)"

patterns-established:
  - "Pattern 1: AppLockService as the only PIN-operation surface — gate/screen/Settings route through it, never touching pin_kdf or the keychain slot directly"

requirements-completed: [LOCK-01, LOCK-06]

coverage:
  - id: D1
    description: "isLockEffective truth table — lock effective only when appLockEnabled AND a PIN hash exists"
    requirement: "LOCK-01"
    verification:
      - kind: unit
        ref: "test/application/security/app_lock_service_test.dart#isLockEffective truth table"
        status: pass
    human_judgment: false
  - id: D2
    description: "setPin/verifyPin round-trip over real Argon2id pin_kdf (correct PIN passes, wrong PIN fails, no-PIN false)"
    requirement: "LOCK-06"
    verification:
      - kind: unit
        ref: "test/application/security/app_lock_service_test.dart#setPin / verifyPin round-trip"
        status: pass
    human_judgment: false
  - id: D3
    description: "reauth biometric-or-PIN gate (D-05) and disableLock clears stale pinHash (T-55-16)"
    requirement: "LOCK-06"
    verification:
      - kind: unit
        ref: "test/application/security/app_lock_service_test.dart#reauth / disableLock"
        status: pass
    human_judgment: false
  - id: D4
    description: "appLockServiceProvider wired (@riverpod) for the gate, lock screen, and Settings"
    requirement: "LOCK-01"
    verification:
      - kind: automated
        ref: "flutter analyze lib/application/security lib/infrastructure/security/providers.dart — No issues found"
        status: pass
    human_judgment: false

duration: 9min
completed: 2026-06-30
status: complete
---

# Phase 55 Plan 07: AppLockService Summary

**Centralized the app-lock business logic behind one injectable AppLockService so the gate, observer, lock screen, and Settings share a single lockEffective predicate and one PIN-operation surface.**

## Performance

- **Duration:** ~9 min
- **Completed:** 2026-06-30
- **Tasks:** 2
- **Files modified:** 3 (2 created, 1 modified) + regenerated providers.g.dart

## Accomplishments
- `AppLockService` exposes `isLockEffective` (D-01 single source of truth), `setPin`/`verifyPin` over the Plan 01 Argon2id KDF, `reauth` (D-05), `enableLock`, and `disableLock`.
- `disableLock` flips `appLockEnabled=false` AND deletes the keychain PHC, so a stale hash can never silently re-arm the lock (T-55-16).
- `appLockServiceProvider` (`@riverpod`) wires the settings repository, secure storage, and biometric service for downstream consumers (Plans 09/10/11).

## Task Commits

1. **Task 1: AppLockService unit tests (RED)** - `c0a4f20d` (test)
2. **Task 2: Implement AppLockService + provider (GREEN)** - `34ee82c3` (feat)

_TDD gate sequence satisfied: test commit precedes feat commit._

## Files Created/Modified
- `lib/application/security/app_lock_service.dart` - The service: lockEffective predicate, PIN set/verify over pin_kdf, reauth, enable/disable.
- `test/application/security/app_lock_service_test.dart` - 12 unit tests (mocktail fakes; real pin_kdf for the PIN round-trip).
- `lib/infrastructure/security/providers.dart` - Added `appLockServiceProvider` + imports.
- `lib/infrastructure/security/providers.g.dart` - Regenerated.

## Decisions Made
- reauth uses `_biometric.authenticate(reason: ...)` and treats only `AuthResultSuccess` as success; the BiometricService already maps unavailable/lockout/failure to non-success, so no separate availability probe is needed — the `biometricUnlockEnabled` flag is the only pre-gate (avoids an extra `checkAvailability` round trip while still honoring "biometric-if-enabled-else-PIN").

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## Self-Check: PASSED
- FOUND: lib/application/security/app_lock_service.dart
- FOUND: test/application/security/app_lock_service_test.dart
- FOUND commit c0a4f20d (RED test)
- FOUND commit 34ee82c3 (GREEN impl)
- flutter test app_lock_service_test.dart: 12/12 passed
- flutter analyze (touched paths): No issues found
