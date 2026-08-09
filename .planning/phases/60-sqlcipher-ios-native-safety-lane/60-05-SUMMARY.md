---
phase: 60-sqlcipher-ios-native-safety-lane
plan: "05"
subsystem: testing
tags: [sqlcipher, backup, recovery, hpb-v2, integration-test, ios-simulator]
requires:
  - phase: 60-02
    provides: Booted-Simulator SQLCipher native-safety runtime runner
  - phase: 60-04
    provides: Current-schema production SQLCipher lifecycle contract
provides:
  - Isolated current-HPB-v2 backup recovery sandbox using production application use cases
  - Current-v2 export, clear, restore, cold-reopen, and re-export integration contracts
affects: [60-06, 60-07, SEC-05, release-gates]
actuals:
  tokens: 5192
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns:
    - Unique temporary-root composition for destructive SQLCipher backup journeys
    - File-backed synthetic settings and synthetic secure/sync seams without platform storage
key-files:
  created:
    - integration_test/helpers/sqlcipher_backup_sandbox.dart
    - integration_test/sqlcipher_backup_recovery_test.dart
  modified: []
key-decisions:
  - "Recovery coverage accepts only current HPB v2 input and invokes the existing production use cases."
  - "The sandbox never resolves normal app storage, platform Keychain, caller backup paths, or physical devices."
requirements-completed: []
coverage:
  - id: D1
    description: Current HPB v2 real-use-case backup recovery sandbox
    requirement: SEC-05
    verification:
      - kind: integration
        ref: integration_test/sqlcipher_backup_recovery_test.dart
        status: unknown
      - kind: unit
        ref: dart analyze integration_test/helpers/sqlcipher_backup_sandbox.dart integration_test/sqlcipher_backup_recovery_test.dart
        status: pass
    human_judgment: false
  - id: D2
    description: Positive current-HPB-v2 format evidence
    verification:
      - kind: unit
        ref: "flutter test test/infrastructure/crypto/services/backup_crypto_service_test.dart --name 'v2 format .* (encrypt → decrypt round-trips|output carries the HPB magic and version 2 header|two encryptions of the same payload differ)' -r expanded"
        status: pass
    human_judgment: false
metrics:
  duration: 1h 15m
  completed: 2026-08-09
status: complete
---

# Phase 60 Plan 05: Current HPB v2 Recovery Summary

**A unique, synthetic SQLCipher sandbox now drives the production export, clear-all, import, and restore use cases through a current-HPB-v2 recovery lifecycle without touching normal app data.**

## Performance

- **Duration:** 1h 15m
- **Tasks:** 2/2
- **Files created:** 2

## Accomplishments

- Added an isolated temporary-root composition with a production encrypted database executor, real repositories/unit of work/use cases, and injected settings, secure state, owned files, wipe journal, sync state, and backup output.
- Added current-v2 export → clear-all → restore → supported-state equivalence → photo-policy → SQLCipher cold-reopen → re-export coverage.
- Added byte-stability coverage so the original current-v2 input is unchanged by restore and the next production export is v2.

## Task Commits

1. **Task 1: current-v2 recovery journey** - `9944bc36` (RED), `955d675c` (GREEN)
2. **Task 2: current-v2 byte stability** - `b21cbafd` (RED), `32c17ee1` (GREEN)

## Verification

- `dart analyze integration_test/helpers/sqlcipher_backup_sandbox.dart integration_test/sqlcipher_backup_recovery_test.dart` — passed.
- Positive current-v2 crypto cases (round trip, v2 header, fresh salt/nonce) — passed.
- `git diff --check` — passed.
- The native-safety runtime verifier found a booted iPhone Simulator but stopped at Flutter's Xcode build before emitting a test result. No Simulator runtime pass is claimed; the unrun verification is recorded in `.planning/WINDOWS.md`.

## Decisions Made

- The integration journey uses only current HPB v2 input. It adds no legacy/headerless codec, parser fallback, historical-schema witness, or alternate restore path.
- Receipt-photo state is asserted as availability-only: local photo hashes/blobs are not restored, and the restored transaction remains explicitly unavailable remotely.

## Deviations from Plan

### Scope-process correction

- An initial broad run of the pre-existing crypto test file included its legacy/headerless cases. No source was changed and no legacy test was introduced. The verification was immediately rerun as positive current-v2 cases only; all new integration source remains current-v2-only.

## Deferred Verification

- The booted-Simulator runtime command requires a healthy Flutter/Xcode build. It did not reach test execution in this environment, matching the current Phase 60 native runtime limitation. Re-run:
  `dart run scripts/verify_ios_native_safety_lane.dart --lane=runtime --runtime-test=integration_test/sqlcipher_backup_recovery_test.dart`

## Next Phase Readiness

- Plan 60-06 can use this sandbox only for current-v2 failure-atomicity checks; it must not add legacy/headerless success coverage.
- SEC-05 remains flagged and unclassified until the separate complete failure-atomicity matrix is finished.

## Self-Check: PASSED

- Both integration-test artifacts exist and all four TDD commits are present.
- No stub markers, legacy/headerless fallback source, platform secure-storage access, or path-provider access exists in the new test artifacts.
