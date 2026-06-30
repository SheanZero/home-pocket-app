---
phase: 55-pin-phase
plan: 02
subsystem: security
tags: [biometric, local_auth, error-handling, app-lock]
status: complete
requires:
  - local_auth 3.0.1 (LocalAuthException / LocalAuthExceptionCode)
provides:
  - BiometricService.authenticate never ejects user; every biometric error -> PIN fallback (LOCK-05, LOCK-10)
affects:
  - lib/infrastructure/security/biometric_service.dart
  - test/infrastructure/security/biometric_service_test.dart
tech-stack:
  added: []
  patterns:
    - "catch LocalAuthException + switch on LocalAuthExceptionCode with reachable wildcard"
    - "belt-and-suspenders residual nets (on PlatformException + catch(_)) -> fallbackToPIN"
key-files:
  created: []
  modified:
    - lib/infrastructure/security/biometric_service.dart
    - test/infrastructure/security/biometric_service_test.dart
decisions:
  - "Lockout codes (temporaryLockout/biometricLockout) named explicitly and routed to fallbackToPIN, NOT the legacy lockedOut() dead end — PIN is the recovering 'other auth' (T-55-06)"
  - "Collapsed the per-code switch to (named lockout codes) + reachable wildcard to satisfy CLAUDE.md 0-analyzer-warnings (full 14-case enumeration triggers unreachable_switch_case); test still drives all 14 codes"
  - "auth_result.dart left structurally intact (6 variants retained for telemetry per RESEARCH Open Question 1)"
metrics:
  duration: ~3 min
  completed: 2026-06-30
  tasks: 2
  files: 2
requirements: [LOCK-05, LOCK-10]
---

# Phase 55 Plan 02: BiometricService LocalAuthException Fix Summary

Rewrote `BiometricService`'s dead `on PlatformException` string-code handler (which never matched local_auth 3.0.1 and ejected the user on every biometric error) to `catch LocalAuthException` and route all 14 `LocalAuthExceptionCode` values — plus residual safety nets — to PIN fallback, so no biometric error can ever lock the user out of their own data (LOCK-05/LOCK-10).

## What Was Built

### Task 1 — Regression test pinning the LocalAuthException contract (RED)
- Replaced the legacy string-code error tests (`PlatformException(code: 'LockedOut') -> lockedOut()`) with an iteration over all 14 `LocalAuthExceptionCode` values, each asserting `AuthResult.fallbackToPIN()`.
- Added two residual-net tests: a stray `PlatformException` and a generic `Exception` both must resolve to `fallbackToPIN`, never an uncaught throw.
- Retained all still-valid `checkAvailability`, success/failed-count, and `resetFailedAttempts` tests.
- Confirmed RED: 16 failing against the legacy handler (`grep -c LocalAuthException` = 20).
- Commit: `51095881`

### Task 2 — Rewrite error handling for local_auth 3.x (GREEN)
- Replaced `on PlatformException catch (e) => _handlePlatformException(e)` with `on LocalAuthException catch (e)` switching on `e.code`.
- The two lockout codes (`temporaryLockout`, `biometricLockout`) are named explicitly and routed to `fallbackToPIN` (previously dead-ended at `lockedOut()` — the T-55-06 bug); a reachable wildcard `_ => fallbackToPIN` covers all remaining current codes and any future non-breaking enum additions.
- Belt-and-suspenders: residual `on PlatformException catch (_)` and final `catch (_)` both return `fallbackToPIN`.
- Deleted the dead `_handlePlatformException`; kept `persistAcrossBackgrounding: true` and the OS-level `_failedAttempts` biometric counter (distinct from PIN counting, no D-06 conflict).
- Confirmed GREEN: all 29 tests pass; `flutter analyze` 0 issues on both files.
- Commit: `c5c3a710`

## Verification

| Check | Result |
|-------|--------|
| `flutter test biometric_service_test.dart` | 29 passed |
| `flutter analyze` (both files) | No issues found |
| `grep -c 'on LocalAuthException'` | 1 |
| `grep -c 'LocalAuthExceptionCode'` | 3 (≥1) |
| wildcard `_ =>` present | yes (reachable) |
| `grep -c '_handlePlatformException'` | 0 (dead handler removed) |
| `grep -c 'persistAcrossBackgrounding'` | 1 (retained) |

Real-device Face ID/Touch ID error lifecycle (no eject/loop on cancel) is deferred to Plan 11's on-device QA — not automatable here.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Blocking analyzer warning] Collapsed exhaustive 14-case switch to named-lockout-codes + reachable wildcard**
- **Found during:** Task 2
- **Issue:** The plan's literal instruction (enumerate all 14 `LocalAuthExceptionCode` cases AND a wildcard `_ =>`) makes the switch statically exhaustive, so the analyzer flags the wildcard as `unreachable_switch_case`. CLAUDE.md mandates 0 analyzer warnings with no `// ignore:`, which takes precedence over the plan.
- **Fix:** Kept the two semantically-critical lockout codes named explicitly (the LOCK-10/T-55-06 fix that was previously dead-ended) and let a *reachable* wildcard cover the remaining current codes plus future non-breaking enum additions. Behavior is identical — every code → `fallbackToPIN` — and the Task 1 test still drives and asserts all 14 codes individually, so coverage is unchanged. All acceptance greps still pass (`on LocalAuthException` ≥1, `LocalAuthExceptionCode` ≥1, wildcard present, `_handlePlatformException` = 0, `persistAcrossBackgrounding` ≥1).
- **Files modified:** lib/infrastructure/security/biometric_service.dart
- **Commit:** c5c3a710

## Threat Mitigations Applied

- **T-55-05 / T-55-06 (DoS — user locked out of own data):** mitigated. Every `LocalAuthException` code, both lockout codes, a wildcard, and two residual catch nets all route to `fallbackToPIN`. No biometric error path can eject the user.

## Notes

- `AuthResult.lockedOut()` and `AuthResult.error()` factories are now unproduced by `BiometricService` but intentionally retained in the union (no other consumers; kept for telemetry per RESEARCH Open Question 1). `auth_result.dart` was left untouched.

## Self-Check: PASSED
- Files verified present: biometric_service.dart, biometric_service_test.dart, 55-02-SUMMARY.md
- Commits verified: 51095881 (RED), c5c3a710 (GREEN)
