---
phase: 59-controlled-platform-plugin-cohorts
plan: "05"
subsystem: biometric-app-lock
tags: [flutter, local_auth, biometrics, app-lock, pin-fallback, safe-hold]
requires:
  - phase: 59-04
    provides: Fail-closed candidate-or-hold evidence ledger and redacted native-evidence pattern
provides:
  - Exact local_auth 3.0.2 hold contract with official-source, policy, declaration, lock, and native-evidence gates
  - Biometric-only app-lock adapter that keeps app-PIN fallback reachable when availability probing fails
  - Redacted native acceptance ledger that excludes Phase 63 wired-iPhone UAT as candidate evidence
affects: [59-06, 59-07, 60-sqlcipher-ios-native-safety-lane, 63-isolated-wired-iphone-acceptance]
tech-stack:
  added: []
  patterns: [fail-closed local_auth selection, exhaustive native-boundary PIN fallback, redacted safe-identity evidence hold]
key-files:
  created: [.planning/phases/59-controlled-platform-plugin-cohorts/59-05-SUMMARY.md]
  modified: [docs/testing/STABLE_BASELINE.json, docs/testing/DEPENDENCY_COMPATIBILITY.md, scripts/dependency_compatibility.dart, test/architecture/dependency_compatibility_contract_test.dart, lib/infrastructure/security/biometric_service.dart, test/infrastructure/security/biometric_service_test.dart, .planning/phases/59-controlled-platform-plugin-cohorts/59-PLUGIN-ACCEPTANCE.md]
decisions:
  - "Keep local_auth exactly at 3.0.2: the official candidate is current, but no safe non-production supported-iPhone Face ID/app-PIN matrix is attributable."
  - "Treat availability probing as part of the native authentication boundary so PlatformException and unknown failures cannot bypass the app-PIN fallback."
  - "Do not accept OS device-passcode authentication or use Phase 63 wired-iPhone UAT as local_auth candidate evidence."
requirements-completed: [PLUG-01, PLUG-04]
metrics:
  duration: 13min
  completed: 2026-08-09
status: complete
actuals:
  tokens: 7629
  tasks: 2
  commits: 5
coverage:
  - id: D1
    description: local_auth selection fails closed on missing official evidence, secure-option proof, declaration/lock drift, incomplete PIN-fallback evidence, and acceptance without Face ID/app-PIN observations.
    requirement: PLUG-04
    verification:
      - kind: unit
        ref: "flutter test test/architecture/dependency_compatibility_contract_test.dart --plain-name 'PLUG-04 biometric'"
        status: pass
    human_judgment: false
  - id: D2
    description: The app-lock adapter forwards biometric-only secure options and routes unsupported, unenrolled, false, lockout, platform, unknown, and availability-probe errors to recoverable outcomes.
    requirement: PLUG-04
    verification:
      - kind: unit
        ref: "flutter test test/infrastructure/security/biometric_service_test.dart"
        status: pass
    human_judgment: false
  - id: D3
    description: Native local_auth acceptance remains an explicit safe-identity hold rather than a simulated or Phase-63-derived pass.
    requirement: PLUG-04
    verification:
      - kind: other
        ref: "dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk"
        status: pass
    human_judgment: true
    rationale: "A real Face ID success and failure-to-app-PIN observation on the exact safe native build is intentionally unavailable."
---

# Phase 59 Plan 05: Biometric App-Lock Hold Summary

**A fail-closed local_auth 3.0.2 hold preserves biometric-only app-lock policy and routes every native adapter failure, including availability probes, back to the app PIN.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-08-09T00:54:00Z
- **Completed:** 2026-08-09T01:07:01Z
- **Tasks:** 2/2
- **Files modified:** 7

## Accomplishments

- Rechecked the official `local_auth` package and changelog: `3.0.2` remains the exact production-stable candidate and selected declaration/lock resolution, but native evidence is incomplete so the decision remains a hold.
- Added machine-checked mutations for absent official evidence, accepted-without-Face-ID/PIN observations, device-passcode policy drift, missing secure options, residual exception fallback evidence, and local_auth declaration/lock drift.
- Moved the availability probe into `BiometricService.authenticate`'s guarded native boundary, so `PlatformException` and unknown errors there now return `AuthResult.fallbackToPIN` rather than escaping.
- Recorded only redacted `UNAVAILABLE` native rows; the future Phase 63 wired-iPhone UAT is explicitly not candidate-selection evidence.

## Task Commits

1. **Task 1: Refresh local_auth evidence and reject passcode-policy drift** — `93905c37` (RED), `46ac1cf1` (GREEN)
2. **Task 2: Evaluate local_auth through the app-lock adapter and record native evidence or hold** — `b720e2cd` (RED), `7bf682f0` (GREEN), `af27c770` (evidence ledger)

## Verification

- `flutter test test/architecture/dependency_compatibility_contract_test.dart --plain-name 'PLUG-04 biometric'` — passed (5 tests).
- `flutter test test/infrastructure/security/biometric_service_test.dart test/architecture/dependency_compatibility_contract_test.dart` — passed (101 tests).
- `flutter analyze lib/infrastructure/security/biometric_service.dart test/infrastructure/security/biometric_service_test.dart` — passed (0 issues).
- `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` — passed (0 errors, 0 warnings).
- Full `flutter analyze` ran but reports 289 existing informational `prefer_initializing_formals` diagnostics outside this plan's files; this pre-existing repository condition is tracked in `deferred-items.md` and was not changed.

## Decisions Made

- Retain `local_auth` exactly at `3.0.2`; the official candidate is current but cannot be accepted without the complete supported-build and safe-identity Face ID/app-PIN evidence matrix.
- Preserve `biometricOnly: true`, `sensitiveTransaction: true`, and `persistAcrossBackgrounding: true`; the OS device passcode must never satisfy the app's separate PIN-protected lock.
- Every native exception path includes availability probing. Unsupported, unenrolled, false, temporary lockout, biometric lockout, `LocalAuthException`, `PlatformException`, and unknown errors retain a reachable app-PIN route.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Availability-probe errors bypassed the existing app-PIN fallback guard**

- **Found during:** Task 2
- **Issue:** `checkAvailability()` ran before the guarded authenticate call, so a platform or unknown exception could escape instead of returning a recoverable app-PIN result.
- **Fix:** Moved the availability probe inside the exhaustive native-boundary `try` block and added both regression cases.
- **Files modified:** `lib/infrastructure/security/biometric_service.dart`, `test/infrastructure/security/biometric_service_test.dart`
- **Verification:** Targeted biometric suite passed, including platform and unknown availability-error fallback cases.
- **Commit:** `7bf682f0`

**Total deviations:** 1 auto-fixed (Rule 1 bug).
**Impact:** The correction is limited to the app-lock trust boundary and closes a potential fallback dead end without changing authentication factors, persistence, routes, or package selection.

## Issues Encountered

- The full analyzer reports 289 pre-existing informational diagnostics in unrelated files. Scoped analysis of the changed biometric files is clean; the existing condition remains recorded in the phase deferred-items ledger.

## Known Holds

- Native local_auth acceptance is `UNAVAILABLE`: no safe non-production supported-iPhone identity and no Phase-59-attributable native build can provide the required redacted Face ID success, failure/lockout, and app-PIN fallback matrix.
- This is an exact `3.0.2` hold, not a pass. OS device-passcode fallback remains prohibited, and Phase 63 wired-iPhone UAT cannot close this decision.

## Next Phase Readiness

The compatibility contract and adapter now fail closed. Any future candidate selection must preserve the exact secure options and exhaustive fallback behavior, then attach the complete safe native evidence matrix without production identity or credential data.

## Self-Check: PASSED

- All seven planned source, test, policy, and ledger files exist.
- Commits `93905c37`, `46ac1cf1`, `b720e2cd`, `7bf682f0`, and `af27c770` exist in repository history.
