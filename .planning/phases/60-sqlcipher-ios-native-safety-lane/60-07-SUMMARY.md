---
phase: 60
plan: "07"
subsystem: SQLCipher iOS native safety and startup initialization
tags: [sqlcipher, native-assets, ios, startup, backup, validation]
requires:
  - 60-06
provides:
  - Native-library-before-key-before-database startup guard
  - Current-schema/current-HPB-v2 convergence evidence
affects:
  - lib/core/initialization/app_initializer.dart
  - scripts/verify_ios_native_safety_lane.dart
  - Phase 60 validation gate
tech_stack:
  added: []
  patterns: [injected-native-readiness, fail-closed-startup, compile-runtime-evidence-separation]
key_files:
  created:
    - .planning/phases/60-sqlcipher-ios-native-safety-lane/60-NATIVE-SAFETY-EVIDENCE.md
  modified:
    - lib/core/initialization/app_initializer.dart
    - lib/infrastructure/crypto/database/encrypted_database.dart
    - integration_test/helpers/sqlcipher_backup_sandbox.dart
    - scripts/verify_ios_native_safety_lane.dart
    - .planning/phases/60-sqlcipher-ios-native-safety-lane/60-VALIDATION.md
decisions:
  - Native Assets readiness is injected and awaited before provider, key, or database construction.
  - Current HPB-v2 runtime success is recorded separately from the blocked current-schema lifecycle lane.
  - Historical schema fixtures and legacy backup success remain N.A. for the unpublished app.
metrics:
  duration: 23m
  completed: 2026-08-09
actuals:
  tokens: 12406
  tasks: 2
  commits: 6
status: complete
---

# Phase 60 Plan 07: Native Startup and Convergence Summary

Native readiness now fails closed before key or encrypted-database work, while the evidence ledger records HPB-v2 Simulator recovery success and the independently blocked current-schema lifecycle gate without conflating compilation with runtime.

## Completed Tasks

1. **60-07-01 — Native readiness startup ordering**
   - Added a Native Assets version/readiness probe at the SQLCipher boundary and injected it into `AppInitializer` before creating the provider container or reading keys.
   - Added call-order and fail-closed regressions for successful startup, native readiness failure, and missing-key-with-encrypted-data behavior; schema remains 36.
   - TDD commits: `b6118068` (RED) and `86494525` (GREEN).

2. **60-07-02 — Current-scope convergence evidence**
   - Replaced stale historical fixture/migration/legacy-backup executable rows with current-schema/current-HPB-v2 verification rows.
   - Recorded redacted exact-state evidence, including the HPB-v2 booted-Simulator `RUNTIME_PASS` and the pre-launch lifecycle blocker.
   - Commit: `36dfa698`.

## Verification

- PASS — targeted SEC-06 regressions: 28 tests.
- PASS — targeted Phase 60 architecture, startup, crypto, and restore suite: 152 tests.
- PASS — `flutter analyze`: 0 issues.
- PASS — `flutter test --concurrency=1 -r expanded`: 4,592 tests, 12 skipped.
- PASS — current HPB-v2 booted-Simulator recovery lane: `RUNTIME_PASS`.
- PASS — `git diff --check` before the evidence commit.
- BLOCKED — current-schema lifecycle runner stopped before launch at an Xcode linker failure for undefined Flutter symbols. This remains a native runtime hold; no generic build result is represented as lifecycle success.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Normalized restored photo-availability metadata**
   - **Found during:** Task 60-07-02 native HPB-v2 recovery run.
   - **Issue:** Restored supported-state comparison retained an internal photo-availability metadata key even though the canonical wire field already represented that state.
   - **Fix:** Compare canonical transactions and remove the internal key before supported-state equivalence.
   - **Files modified:** `integration_test/helpers/sqlcipher_backup_sandbox.dart`
   - **Commit:** `1b21f4d4`

2. **[Rule 1 - Bug] Exposed native graph mismatch evidence**
   - **Found during:** Task 60-07-02 disposable native resolution diagnostics.
   - **Issue:** A graph mismatch stopped the runner without enough redacted information to distinguish retained and disposable inputs.
   - **Fix:** Emit redacted retained/disposable graph digests and an explicit blocked record before failing closed.
   - **Files modified:** `scripts/verify_ios_native_safety_lane.dart`
   - **Commit:** `746099ef`

### Deferred Issue

The pre-existing Flutter/Xcode undefined-symbol linker failure prevents current-schema lifecycle launch. It is outside this task’s startup/evidence scope and is retained as a BLOCKED runtime gate in the validation and evidence records.

## Known Stubs

None.

## Threat Flags

None. The task added no network endpoint, auth path, file-access boundary, or schema change.

## Decisions Made

- Keep native readiness as an injected SQLCipher-boundary callback so it is mechanically ordered before any key/database work.
- Preserve runtime/compile labels: only the booted-Simulator HPB-v2 lane is a runtime pass; the lifecycle linker failure blocks SEC-03.
- Keep SEC-04 N.A. and reject non-v2 backups; no historical fixture or compatibility lane is reintroduced.

## Self-Check: PASSED

Verified the listed production/evidence files and all five task commits before metadata updates.
