---
phase: 60-sqlcipher-ios-native-safety-lane
plan: "04"
subsystem: testing
tags: [sqlcipher, ios, lifecycle, scope-correction]
requires:
  - phase: 60-02
    provides: booted-Simulator native safety runner
provides:
  - Current-schema production SQLCipher create/write/cold-reopen proof
  - Removal of unsupported historical fixture/provenance coverage
affects: [60-05, 60-06, 60-07, SEC-03, SEC-04]
tech-stack:
  added: []
  patterns: [production executor current-schema lifecycle]
key-files:
  created:
    - integration_test/sqlcipher_native_assets_lifecycle_test.dart
    - test/architecture/sqlcipher_native_assets_contract_test.dart
  modified:
    - scripts/verify_ios_native_safety_lane.dart
    - test/infrastructure/crypto/database/encrypted_database_native_assets_test.dart
decisions:
  - "Owner scope correction: the app has never been publicly released; historical schema migration proof is not applicable."
  - "Keep production migration code unchanged and prove only current-schema SQLCipher lifecycle safety."
metrics:
  tasks: 2
  commits: 1
status: complete
---

# Phase 60 Plan 04: Current-Schema SQLCipher Lifecycle Summary

The owner’s 2026-08-09 pre-release correction removed the unsupported v23/v35 migration witness lane and replaced it with current-schema production SQLCipher lifecycle evidence.

## Scope Correction

- Removed the immutable historical fixtures, provenance manifest/verifier, fixture assertion helper, and migration-specific host/runtime tests.
- Did not modify `AppDatabase` migration strategy, migration files, or schema version.
- Added a synthetic current-schema journey: production executor creates the encrypted database, verifies SQLCipher 4.17/status/readable schema/integrity/non-plaintext header, writes a sentinel, closes, and verifies it from a fresh `AppDatabase` instance.
- Updated the native safety runner and architecture contract to run the current-schema lifecycle entrypoint.

## Verification

- `dart analyze integration_test/sqlcipher_native_assets_lifecycle_test.dart test/architecture/sqlcipher_native_assets_contract_test.dart test/infrastructure/crypto/database/encrypted_database_native_assets_test.dart test/architecture/ios_minimum_version_contract_test.dart scripts/verify_ios_native_safety_lane.dart`
- `flutter test test/architecture/sqlcipher_native_assets_contract_test.dart test/architecture/ios_minimum_version_contract_test.dart test/infrastructure/crypto/database/encrypted_database_native_assets_test.dart`
- `git diff --check`

## Deferred Verification

- The booted-Simulator lifecycle command was attempted on 2026-08-09 but the existing iOS build failed before test execution with unresolved Flutter linker symbols; CoreSimulator then became unavailable. This correction does not alter native build configuration, so no Simulator `RUNTIME_PASS` is claimed here. The current-schema integration test remains the required runtime entrypoint once the native lane is healthy.

## Task Commit

- `35ad2652` — `test(60-04): replace historical migration lane with lifecycle proof`

## Deviations from Plan

**[Owner scope correction]** The original historical-migration RED lane was removed rather than completed because the app has no released historical population. This is a transparent descoping decision, not a claim that backward compatibility was tested.

## Self-Check: PASSED

- The current-schema lifecycle test and native-safety contract exist.
- The historical fixture, provenance, and migration entrypoints are removed.
