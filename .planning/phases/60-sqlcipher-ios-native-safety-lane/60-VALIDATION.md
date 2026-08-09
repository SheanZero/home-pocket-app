---
phase: 60
slug: sqlcipher-ios-native-safety-lane
status: runtime_pending
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-09
updated: 2026-08-09
---

# Phase 60 — Validation Strategy

> Executable validation contract for the locked Native Assets graph, current-schema lifecycle, current HPB v2 recovery, and native-before-key-before-database startup. Runtime and compilation evidence are never interchangeable.

## Scope

- There is no released application population. SEC-04 (historical released-schema migration) is **N.A.** No v23/v35 fixture, provenance, migration, headerless-success, or multi-format compatibility command is executable in this phase.
- Backup acceptance is current HPB v2 only; non-v2 inputs must reject.
- Notification services are not a runtime dependency in this MVP.
- No physical-device signing, installation, launch, clear, or inspection is permitted. No external API integration or schema-push pattern applies.

## Test Infrastructure

| Property | Current contract |
| --- | --- |
| Framework | Flutter test and SDK `integration_test` |
| Quick check | `flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/ios_minimum_version_contract_test.dart test/architecture/sqlcipher_native_assets_contract_test.dart test/core/initialization/app_initializer_test.dart test/infrastructure/crypto/database/encrypted_database_native_assets_test.dart` |
| Native runner | Compile: `dart run scripts/verify_ios_native_safety_lane.dart --lane=compile`; runtime: `dart run scripts/verify_ios_native_safety_lane.dart --lane=runtime --runtime-test=<current Phase 60 test>` |
| Full check | `flutter analyze`, `flutter test --concurrency=1`, the current-schema lifecycle lane, HPB-v2 lane, and `git diff --check` |
| Evidence rule | Retained/from-zero resolution and generic Simulator builds are `COMPILE_ONLY`; a booted-Simulator integration result is the only runtime proof. |

## Executable Verification Map

| Task ID | Requirement | Current secure behavior | Automated evidence | Result / disposition |
| --- | --- | --- | --- | --- |
| 60-01-01/02 | SEC-01, SEC-02 | Locked Drift/sqlite3 Native Assets graph, iOS 15 generated floor, and prohibited alternatives fail closed. | Dependency/iOS-floor architecture contracts and dependency compatibility verifier. | PASS in prior-plan evidence; the unresolved deterministic probes remain flagged. |
| 60-02-01/02 | SEC-01, SEC-02, SEC-03 | Runner preserves the main tree, distinguishes retained/disposable graph checks and generic builds from runtime, and redacts host details. | `verify_ios_native_safety_lane.dart --lane=full --runtime-test=integration_test/sqlcipher_native_assets_lifecycle_test.dart` | BLOCKED in 60-07: supported Flutter iOS package generation reaches an Xcode linker failure for Flutter symbols before attributable lifecycle runtime. |
| 60-04-01/02 | SEC-03 | Current schema opens through the production encrypted executor, writes, closes, cold-reopens, and verifies cipher/header/integrity state. | `verify_ios_native_safety_lane.dart --lane=full --runtime-test=integration_test/sqlcipher_native_assets_lifecycle_test.dart` | BLOCKED at the same pre-runtime Flutter-symbol linker failure; compilation is not accepted as lifecycle proof. |
| 60-05-01 | SEC-05 | Current HPB v2 export, clear, restore, cold reopen, and re-export execute only in the injected synthetic Simulator sandbox. | `verify_ios_native_safety_lane.dart --lane=runtime --runtime-test=integration_test/sqlcipher_backup_recovery_test.dart` | RUNTIME_PASS (booted Simulator, Debug; identifier redacted). |
| 60-05-02 | SEC-05 | Only HPB v2 is accepted; headerless/legacy/multi-format success is out of scope and non-v2 inputs reject. | `flutter test test/infrastructure/crypto/services/backup_crypto_service_test.dart` plus the current-v2 runtime lane. | PASS in the targeted 60-07 suite; current-v2 runtime RUNTIME_PASS. |
| 60-06-01/02 | SEC-05 | Wrong password, malformed, hostile, interrupted, and invalid recovery inputs preserve the synthetic sandbox atomically. | `flutter test test/infrastructure/crypto/services/backup_crypto_service_test.dart test/unit/application/settings/import_backup_use_case_atomicity_test.dart test/unit/application/settings/restore_backup_use_case_test.dart` plus HPB-v2 runtime lane. | PASS in targeted 60-07 suite; runtime success is recorded separately above. |
| 60-07-01 | SEC-06 | Native readiness completes before provider/key/database work; native and missing-key failures stop downstream construction; schema stays 36. | `flutter test test/core/initialization/app_initializer_test.dart test/infrastructure/crypto/database/encrypted_database_native_assets_test.dart` | PASS: 28 tests, plus scoped analyzer and no migration/schema diff. |
| 60-07-02 | SEC-01, SEC-02, SEC-03, SEC-05, SEC-06 | Convergence records only attributable, redacted graph/build/runtime/test evidence at one source state. | Commands and outcomes in `60-NATIVE-SAFETY-EVIDENCE.md`. | BLOCKED because SEC-03 runtime cannot start; SEC-04 is N.A., not a missing migration gate. |
| 60-08-01/02 | SEC-02, SEC-03 | The locked AppDelegate launch lifecycle and Runner Swift-package linkage survive clean Flutter/Xcode generation. | `ios_native_linkage_contract_test.dart` plus a clean unsigned Debug Simulator build. | PASS: the historical undefined-symbol failure did not reproduce after clean regeneration; linkage contracts and the clean build pass. Runtime remains separate. |
| 60-09-01/02 | SEC-02 | A compile-only command validates the retained and disposable exact graph, generated iOS 15 floor, and the six unsigned Runner configuration/destination intersections without calling runtime. | `dart run scripts/verify_ios_native_safety_lane.dart --lane=compile` at source `570064236eead5e9bdbd8567f8c866bf9d48aa99`. | PASS: both graphs select Drift 2.34.0 / sqlite3 3.5.1 / SQLCipher 4.17.x with matching digest; both floors are iOS 15+; six `COMPILE_ONLY` records exit 0; `runtime_test` is null and no runtime record exists. |

## Requirement and Threat Disposition

| Requirement | Evidence disposition | Threat mitigation status |
| --- | --- | --- |
| SEC-01 | Exact graph and contract evidence pass; the deterministic retained/from-zero probe is complete. | T-60-C1 PASS. |
| SEC-02 | Retained/from-zero graph convergence, generated iOS 15 floors, and all six unsigned compile-only Xcode builds pass. | T-60-C2, T-60-C7, and T-60-C8 PASS. |
| SEC-03 | Current-schema lifecycle is the required truth and is isolated to plan 60-10. | T-60-C3 PENDING; no compile-only substitution. |
| SEC-04 | N.A. — no released population exists. | No historical-fixture threat lane is applicable. |
| SEC-05 | Current HPB v2 runtime recovery and atomicity tests pass. | T-60-C4, T-60-C5, and T-60-C6 PASS. |
| SEC-06 | Startup ordering and fail-closed regressions pass with schema 36 unchanged. | T-60-C9 PASS. |

The SEC-01/SEC-02 deterministic native graph and compile probes are now verified. SEC-03 remains explicitly pending plan 60-10. SEC-04 is N.A. by the owner’s no-released-population decision; it is not silently resolved.

## Current Runtime Evidence Rules

- Runtime lanes use only `integration_test/sqlcipher_native_assets_lifecycle_test.dart` and `integration_test/sqlcipher_backup_recovery_test.dart`.
- A missing, unsupported, or pre-launch-failing Simulator lane is `NOT_RUN`, `INCOMPLETE`, or `BLOCKED`; it is never PASS.
- Generic Simulator/package generation is unsigned `COMPILE_ONLY`. The Runner Profile/Release Simulator Xcode configurations compile with Flutter artifact preparation forced to its supported Debug Simulator mode; these records are neither Profile/Release runtime nor AOT proof. Profile/Release integration runtime remains `NOT_RUN`.
- Evidence redacts simulator identifiers, absolute paths, keys, credentials, passwords, financial content, recovery/sync payloads, and synthetic fixture values.

## Failure Diagnostics

| Symptom | Required response |
| --- | --- |
| SQLCipher version/status/header rejection | Fail closed; do not restore legacy Flutter libraries, a separate SQLCipher Pod, or system SQLite. |
| Generated native build links undefined Flutter symbols | Fail the affected native gate, retain diagnostics, and repair source-controlled linkage only. The historical 60-07 symptom did not reproduce after plan 60-08 clean regeneration. |
| Current HPB-v2 negative input changes sandbox state | Treat as atomicity failure; inspect staging, compensation, journal, and sync-barrier boundaries. |
| Simulator unavailable or unsupported | Mark only the affected runtime row BLOCKED/NOT_RUN; retain generic compilation as a separately labeled record. |

## Validation Sign-Off

- [x] Stale executable rows have been replaced with current-schema/current-HPB-v2 commands only.
- [x] SEC-04 is recorded as N.A.; no historical fixture or migration lane was run.
- [x] Runtime and compile-only records are explicitly separate.
- [x] SEC-06 ordering/fail-closed regression gate passes with schemaVersion 36 unchanged.
- [x] HPB-v2 Simulator recovery has attributable redacted runtime evidence.
- [x] SEC-02 retained/from-zero graph, generated iOS 15 floors, and six-build compile-only evidence pass without a runtime claim.
- [ ] Current-schema lifecycle runtime awaits the isolated plan 60-10 booted-Simulator run.
- [ ] `nyquist_compliant` and `wave_0_complete` stay false until the remaining active native lifecycle/build gates are green.

**Approval:** SEC-02 compile convergence approved; SEC-03 remains pending plan 60-10 runtime evidence.
