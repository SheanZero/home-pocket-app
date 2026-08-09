---
phase: 60-sqlcipher-ios-native-safety-lane
plan: "06"
subsystem: backup-recovery-safety
tags: [sqlcipher, backup, hpb-v2, atomicity, fault-injection, ios-simulator]
requires:
  - phase: 60-05
    provides: Isolated current-HPB-v2 backup recovery sandbox
provides:
  - Current-v2 hostile-input rejection matrix with digest-only full-state equivalence
  - Constructor-bound restore interruption matrix with retry/no-reimport assertions
affects: [60-07, SEC-05, release-gates]
tech-stack:
  added: []
  patterns:
    - Current-v2-only format gate before KDF work
    - Isolated full-state snapshot components rendered as digests only
    - One-shot callbacks injected through existing restore/import constructor seams
key-files:
  created: []
  modified:
    - integration_test/helpers/sqlcipher_backup_sandbox.dart
    - integration_test/sqlcipher_backup_recovery_test.dart
    - lib/infrastructure/crypto/services/backup_crypto_service.dart
    - test/infrastructure/crypto/services/backup_crypto_service_test.dart
    - test/unit/application/settings/import_backup_use_case_atomicity_test.dart
    - test/unit/application/settings/import_backup_use_case_test.dart
decisions:
  - "Only HPB v2 is accepted; headerless/non-v2 payloads fail before password KDF work."
  - "Fault injection stays in the isolated test composition and uses already-exposed constructor callbacks, never production test branches."
metrics:
  duration: 28m 11s
  completed: 2026-08-09
status: complete
actuals:
  tokens: 10154
  tasks: 2
  commits: 5
---

# Phase 60 Plan 06: Current-v2 Atomic Recovery Summary

**Current HPB v2 recovery now rejects hostile/non-v2 input before mutation and proves transaction, settings, and sync-boundary failures cannot silently produce a partial restore.**

## Accomplishments

- Added a table-driven hostile matrix for wrong password; header/body/MAC truncation; unknown/non-v2/magic rejection; Argon2id memory/iteration/parallelism bounds; authentication corruption; gzip/JSON/schema/transaction rejection; and encrypted/decompressed budget limits.
- Expanded the synthetic-only snapshot with database logical data, schema, integrity, settings, secure and sync state, owned-file digest, and original backup digest. Failure diagnostics name only the changed component.
- Added transaction-commit, post-persist settings, sync-suspension, cleanup, and resume fault sessions through existing `ImportBackupUseCase` and `RestoreBackupUseCase` callback seams. Cleanup/resume retries prove the import runs once.
- Changed the current pre-release backup policy to reject headerless/non-v2 payloads before KDF work, and converted the existing atomicity fixture writer to HPB v2.
- Corrected the remaining mock-based import fixture writer after the post-merge suite exposed its retired headerless PBKDF2 encoding; all fixtures now use `BackupCryptoService.encrypt` and current HPB v2 bytes.

## Task Commits

1. **Task 1: hostile format and resource rejection** — `2e90af48` (RED), `cc4da749` (GREEN)
2. **Task 2: interruption compensation and retry safety** — `ebd71ee2` (RED), `ea589634` (GREEN)

## Verification

- `dart analyze integration_test/helpers/sqlcipher_backup_sandbox.dart integration_test/sqlcipher_backup_recovery_test.dart lib/infrastructure/crypto/services/backup_crypto_service.dart test/infrastructure/crypto/services/backup_crypto_service_test.dart test/unit/application/settings/import_backup_use_case_atomicity_test.dart test/unit/application/settings/restore_backup_use_case_test.dart` — passed with 0 issues.
- `flutter test test/infrastructure/crypto/services/backup_crypto_service_test.dart test/unit/application/settings/import_backup_use_case_atomicity_test.dart test/unit/application/settings/restore_backup_use_case_test.dart` — passed (24 tests).
- Post-merge: `flutter test test/unit/application/settings/import_backup_use_case_test.dart test/infrastructure/crypto/services/backup_crypto_service_test.dart test/unit/application/settings/import_backup_use_case_atomicity_test.dart test/unit/application/settings/restore_backup_use_case_test.dart` — passed (33 tests).
- Post-merge: `flutter analyze` — passed with 0 issues.
- `git diff --check` — passed.
- Source scan found no legacy/headerless success path, platform secure-storage/path-provider access, or sensitive test logging in the Plan 60-06 artifacts.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Critical functionality] Rejected headerless/non-v2 backups before KDF work**
- **Found during:** Task 1
- **Issue:** `BackupCryptoService` still auto-detected and decrypted headerless legacy payloads, contradicting the pre-release current-v2-only recovery boundary.
- **Fix:** Require the HPB v2 magic/header before format parsing and remove the legacy success test path.
- **Files modified:** `lib/infrastructure/crypto/services/backup_crypto_service.dart`, `test/infrastructure/crypto/services/backup_crypto_service_test.dart`
- **Commit:** `cc4da749`

**2. [Rule 3 - Blocking issue] Converted an existing atomicity fixture writer to HPB v2**
- **Found during:** Task 2 verification
- **Issue:** Existing import-atomicity tests generated headerless bytes and could no longer reach the production atomicity seams after the required v2-only gate.
- **Fix:** Reused `BackupCryptoService.encrypt` to produce current HPB v2 fixture bytes; no legacy encoder or success coverage remains.
- **Files modified:** `test/unit/application/settings/import_backup_use_case_atomicity_test.dart`
- **Commit:** `ea589634`

**3. [Rule 1 - Regression] Converted the remaining mock-based import fixture writer to HPB v2**
- **Found during:** Post-merge full-suite verification
- **Issue:** Nine tests in `import_backup_use_case_test.dart` still generated headerless PBKDF2 bytes and no longer reached the import behavior under the required v2-only gate.
- **Fix:** Replaced its test-only encoder with `BackupCryptoService.encrypt`, removed obsolete imports and historical-format wording, and asserted the current explicit non-v2 header rejection.
- **Files modified:** `test/unit/application/settings/import_backup_use_case_test.dart`
- **Commit:** `133447a2`

## Deferred Verification

- The booted-Simulator runtime verifier was not run because this environment has not emitted an actual integration-test result for the Phase 60 lane. No Simulator runtime pass is claimed. Re-run when the native lane can produce an attributable result:
  `dart run scripts/verify_ios_native_safety_lane.dart --lane=full --runtime-test=integration_test/sqlcipher_backup_recovery_test.dart`

## Known Stubs

None.

## Self-Check: PASSED

- All six scoped artifacts exist and all five task commits are present in Git history.
- No stubs, legacy/headerless fallback parser, platform secure-storage access, path-provider access, or sensitive logging were introduced in the Plan 60-06 artifacts.
