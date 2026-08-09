---
phase: 60-sqlcipher-ios-native-safety-lane
verified: 2026-08-09T12:27:34Z
status: gaps_found
score: 4/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Retained lockfiles and a disposable from-zero resolution produce the same clean iOS graph, iOS 15 floors, and all required unsigned compile-only builds."
    status: failed
    reason: "The required full native lane stops during supported Flutter iOS package generation with undefined Flutter symbols, before disposable resolution and the complete build matrix can finish."
    artifacts:
      - path: "scripts/verify_ios_native_safety_lane.dart"
        issue: "The runner is substantive and fail-closed, but its full execution is BLOCKED by the native linker failure."
      - path: "ios/Runner/AppDelegate.swift"
        issue: "The Flutter implicit-engine symbols referenced here are identified by the native review as unresolved at link time."
    missing:
      - "Repair the Flutter/Xcode/native-asset linkage through the supported Flutter generation path."
      - "Rerun the full lane and capture matching retained/from-zero graph and unsigned build records."
  - truth: "An encrypted database returns a non-empty PRAGMA cipher_version on initial open and after close/reopen, and its sentinel data remains readable on iOS."
    status: failed
    reason: "The production-executor current-schema lifecycle integration test exists and passes on the host, but its booted-Simulator lane is BLOCKED before test launch by the same undefined Flutter-symbol linker failure."
    artifacts:
      - path: "integration_test/sqlcipher_native_assets_lifecycle_test.dart"
        issue: "Runtime behavior is implemented and wired, but there is no attributable iOS RUNTIME_PASS."
    missing:
      - "A booted-Simulator RUNTIME_PASS from the checked-in lifecycle entrypoint after native linkage is repaired."
---

# Phase 60: SQLCipher & iOS Native Safety Lane Verification Report

**Phase Goal:** Current-schema local financial data remains encrypted, readable, cold-reopenable, and recoverable through the clean iOS native dependency path.
**Verified:** 2026-08-09T12:27:34Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The exact Drift 2.34.0 / sqlite3 3.5.1 / SQLCipher Native Assets 4.17.x graph is selected and prohibited legacy/plaintext substitutions are rejected. | ✓ VERIFIED | `pubspec.yaml` selects `hooks.user_defines.sqlite3.source: sqlcipher`; `pubspec.lock` resolves Drift 2.34.0 and sqlite3 3.5.1. `scripts/dependency_compatibility.dart` rejects retired libraries, SQLCipher Pod, linker strip, and bad floor mutations. Targeted tests passed. |
| 2 | Clean retained/from-zero native resolution, iOS 15 generated floors, and the required compile-only build matrix complete without conflating compile with runtime. | ✗ FAILED | The runner implements each stage, but `60-NATIVE-SAFETY-EVIDENCE.md` and `60-VALIDATION.md` record the full lane as BLOCKED at Flutter-symbol linkage before the disposable resolution/build matrix completes. |
| 3 | The production encrypted executor opens the current schema, writes a sentinel, closes, and cold-reopens it on iOS. | ✗ FAILED | `integration_test/sqlcipher_native_assets_lifecycle_test.dart` performs this exact journey through `createDeviceTestEncryptedExecutor` and `AppDatabase`; the actual booted-Simulator command is BLOCKED before launch. Host test success is not iOS runtime proof. |
| 4 | Historical released-schema migration is not claimed or manufactured because there is no released population; production migration code remains unchanged. | ✓ VERIFIED | Owner decision is recorded in ROADMAP/REQUIREMENTS/VALIDATION; Phase 60 removed historical fixtures and `git diff 35ad2652^..HEAD -- lib/data/app_database.dart lib/data/app_database_migrations.dart` is empty. |
| 5 | Test-only current HPB v2 export, clear, restore, hostile-input rejection, and recovery atomicity preserve the isolated sandbox. | ✓ VERIFIED | The booted-Simulator Debug HPB-v2 runner is recorded as `RUNTIME_PASS`; source wires the real export, clear, import, and restore use cases. Current targeted crypto and atomicity tests passed. |
| 6 | Native readiness precedes key/database work; missing keys remain fail-closed and no upgrade-only schema bump occurs. | ✓ VERIFIED | `AppInitializer` awaits `ensureNativeLibrary` before constructing its provider container; `createEncryptedExecutor` rejects absent keys. Targeted tests exercise order/failure paths and schemaVersion remains 36. |

**Score:** 4/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/dependency_compatibility.dart` | Exact Native Assets graph and rejection contract | ✓ VERIFIED | Substantive validator; architecture mutation tests passed. |
| `scripts/verify_ios_native_safety_lane.dart` | Clean-resolution, compile-only, and runtime evidence runner | ⚠️ BLOCKED | Substantive and wired to both allowed integration tests, but the full lifecycle lane fails at native linkage. |
| `integration_test/sqlcipher_native_assets_lifecycle_test.dart` | Current-schema SQLCipher write/cold-reopen lifecycle | ⚠️ BLOCKED | Production executor/AppDatabase flow is substantive; no iOS runtime execution completed. |
| `integration_test/helpers/sqlcipher_backup_sandbox.dart` | Isolated production-use-case recovery composition | ✓ VERIFIED | Creates unique temporary roots and composes real export/clear/import/restore use cases with injected boundaries. |
| `integration_test/sqlcipher_backup_recovery_test.dart` | Current-v2 recovery and failure-atomicity journey | ✓ VERIFIED | Booted-Simulator Debug evidence is `RUNTIME_PASS`; hostile and fault matrix is covered by targeted tests. |
| `lib/core/initialization/app_initializer.dart` and `lib/infrastructure/crypto/database/encrypted_database.dart` | Native → key → encrypted-database order | ✓ VERIFIED | Native readiness is injected from `main.dart`; tests prove native failure and missing-key short circuits. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `pubspec.yaml` / locks / iOS config | `scripts/dependency_compatibility.dart` | Baseline validator and mutation suite | ✓ WIRED | Current graph and negative cases are directly parsed and tested. |
| Native-safety runner | Current-schema lifecycle test | Allowlisted `--runtime-test` passed to `flutter test -d <booted simulator>` | ⚠️ BLOCKED | The runner invokes the entrypoint, but iOS package generation/linking fails before it can execute. |
| Lifecycle test | Production executor → `AppDatabase` | `createDeviceTestEncryptedExecutor` delegates to `createEncryptedExecutor` | ✓ WIRED | The test creates, writes, closes, and reconstructs `AppDatabase` over one encrypted file. |
| Backup sandbox | Export/Clear/Import/Restore use cases | Direct production use-case construction with injected sandbox dependencies | ✓ WIRED | No DAO/file-copy recovery shortcut found. |
| `main.dart` | `AppInitializer` → encrypted database | Injected `ensureNativeLibrary` then normal factory | ✓ WIRED | Call-order tests prove the failure boundaries. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Current-schema lifecycle test | Encrypted DB file and audit-log sentinel | Unique temp file → production executor → `AppDatabase` → `audit_logs` | Yes on host; iOS execution blocked before launch | ⚠️ BLOCKED_RUNTIME |
| HPB-v2 recovery test | Backup-supported snapshot and encrypted `.hpb` bytes | Synthetic root → real use cases → SQLCipher DB/settings/sync/owned-file boundaries | Yes; booted Simulator Debug record exits 0 | ✓ FLOWING |
| Initializer | Readiness/key/database sequence | `main.dart` injects native probe; initializer obtains master key then database factory | Yes; dedicated call-order tests pass | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Graph mutations, iOS floor, SQLCipher host lifecycle, startup ordering, v2 crypto, and restore atomicity | `flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/ios_minimum_version_contract_test.dart test/architecture/sqlcipher_native_assets_contract_test.dart test/core/initialization/app_initializer_test.dart test/infrastructure/crypto/database/encrypted_database_native_assets_test.dart test/infrastructure/crypto/services/backup_crypto_service_test.dart test/unit/application/settings/import_backup_use_case_atomicity_test.dart test/unit/application/settings/restore_backup_use_case_test.dart -r expanded` | 143 tests passed | ✓ PASS |
| Dependency baseline CLI | `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | Not run to completion: Flutter attempted to update `/Users/xinz/flutter/bin/cache`, which the verification sandbox disallows. Existing architecture tests exercise the validator. | ? SKIP |
| Current-schema iOS lifecycle | Recorded exact full-lane command in `60-NATIVE-SAFETY-EVIDENCE.md` | BLOCKED before test launch by unresolved Flutter symbols; compilation was not substituted. | ✗ FAIL |
| Current HPB-v2 recovery | Recorded runtime-lane command in `60-NATIVE-SAFETY-EVIDENCE.md` | Booted Simulator Debug, exit 0, identifier redacted. | ✓ PASS |

### Probe Execution

No `scripts/*/tests/probe-*.sh` probe exists for this phase. The native runner is an evidence-producing build/runtime workflow, not a conventional probe; it was not rerun because it regenerates native artifacts and the requested verification must not modify source or tracking state. Its actual recorded lifecycle result is BLOCKED and is treated as the controlling evidence.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SEC-01 | 60-01, 60-02, 60-07 | Exact graph and prohibited alternatives | ✓ SATISFIED | Source/lock values, hook, Pod/linker checks, and mutation tests pass. |
| SEC-02 | 60-01, 60-02, 60-07 | Reproducible clean native graph, floors, and compile/runtime separation | ✗ BLOCKED | Runner code exists, but the full lane cannot finish after the Flutter linker failure. |
| SEC-03 | 60-02, 60-04, 60-07 | Initial encrypted open and close/reopen current-schema lifecycle | ✗ BLOCKED | Required Simulator lifecycle did not launch. |
| SEC-04 | 60-03, 60-04 | Historical migration | ✓ SATISFIED (N.A.) | Explicit owner descoping; no historical population exists and migration code is unchanged. |
| SEC-05 | 60-05, 60-06, 60-07 | Current v2 recovery and failure atomicity | ✓ SATISFIED | RUNTIME_PASS plus current-v2 crypto/atomicity tests and real-use-case wiring. |
| SEC-06 | 60-07 | Native/key/database ordering and fail-closed startup | ✓ SATISFIED | Dedicated order and negative-path regressions pass; schema is still 36. |

No requirement is orphaned: all SEC-01 through SEC-06 IDs appear in Phase 60 plans. The `[x]` / `Complete` labels for SEC-02 and SEC-03 in `.planning/REQUIREMENTS.md` conflict with the final evidence, validation, and review records: both are still BLOCKED and must not be treated as complete.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `test/core/initialization/app_initializer_test.dart` | runtime output | Drift reports repeated test-database construction warnings during the targeted suite | ℹ️ Info | The suite passes; this is test-harness noise, not evidence that the production current-schema lifecycle works on iOS. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in surviving Phase-60 source artifacts. `return null` matches in existing provider code were examined as ordinary nullable control flow, not rendering/output stubs.

### Gaps Summary

Phase 60 does not achieve its goal. The code and host tests establish the intended SQLCipher, recovery, and initialization paths, and HPB-v2 recovery has attributable booted-Simulator evidence. But the clean iOS native dependency path fails before the required current-schema lifecycle test can launch. This one Flutter/Xcode linkage defect blocks both the full native convergence truth and the iOS encrypted open/reopen truth.

The gap is not deferred: Phases 61–63 cover Android, final release convergence, and isolated wired-iPhone acceptance; none specifically repairs or replaces this prerequisite iOS Simulator lifecycle gate. Repair the native linkage and rerun the checked-in full lifecycle command. Do not substitute generic compilation, host tests, the HPB-v2 runtime pass, a historical fixture, or a physical-device run.

---

_Verified: 2026-08-09T12:27:34Z_
_Verifier: the agent (gsd-verifier)_
