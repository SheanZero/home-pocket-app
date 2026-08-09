---
phase: 60
slug: sqlcipher-ios-native-safety-lane
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-09
---

# Phase 60 — Validation Strategy

> Per-phase validation contract for SQLCipher Native Assets, encrypted historical migrations, and sandboxed backup recovery.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test + SDK `integration_test` |
| **Config file** | `pubspec.yaml`; existing architecture/unit/infrastructure suites; Wave 0 adds fixture provenance and Simulator sandbox helpers |
| **Quick run command** | `flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/ios_minimum_version_contract_test.dart test/infrastructure/crypto/database/encrypted_database_native_assets_test.dart test/core/initialization/app_initializer_test.dart` |
| **Targeted runtime command** | `flutter test integration_test/sqlcipher_native_assets_migration_test.dart integration_test/sqlcipher_backup_recovery_test.dart -d <booted-ios-simulator-id> -r expanded` |
| **Full suite command** | `flutter analyze && flutter test --concurrency=1` followed by the Phase 60 clean iOS matrix and booted-Simulator runtime lane |
| **Estimated runtime** | Quick: ~120 seconds; full native matrix and Simulator lane: environment-dependent, expected tens of minutes |

---

## Sampling Rate

- **After every task commit:** Run the narrowest requirement-specific command from the map below; run the quick suite after contract/runtime-seam changes.
- **After every plan wave:** Run `flutter analyze` plus all Phase 60 tests that exist by that wave; native graph waves also run their clean-resolution/build command.
- **Before `$gsd-verify-work`:** The full Dart suite, main-tree and isolated resolution proofs, six-mode unsigned iOS build matrix, and every technically runnable Simulator scenario must be green.
- **Max feedback latency:** 180 seconds for normal task checks. Native clean builds and Simulator integration are explicit long-running gates and must report progress/evidence separately.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 60-01-01 | 01 | 1 | SEC-01 | T-60-01 | Stale legacy lane is removed atomically and prohibited alternatives fail closed | architecture/mutation | `flutter test test/architecture/dependency_compatibility_contract_test.dart` | ✅ | ⬜ pending |
| 60-01-02 | 01 | 1 | SEC-01, SEC-02 | T-60-01 | Source, resolved graph, Pod/SwiftPM output, and iOS 15 floor agree | architecture + clean resolution | `flutter test test/architecture/ios_minimum_version_contract_test.dart test/architecture/dependency_compatibility_contract_test.dart` plus Phase 60 resolution runner | ✅ / ❌ W0 runner | ⬜ pending |
| 60-02-01 | 02 | 2 | SEC-02 | T-60-02 | Main-tree and isolated from-zero resolutions reproduce the committed graph without tracked drift | shell/integration | Phase 60 clean-resolution runner in main-tree and disposable copy modes | ❌ W0 | ⬜ pending |
| 60-02-02 | 02 | 2 | SEC-02 | T-60-02 | Debug/Profile/Release build for Simulator and generic device; compile-only evidence is labeled honestly | iOS build matrix | Phase 60 unsigned `xcodebuild`/Flutter matrix runner | ❌ W0 | ⬜ pending |
| 60-03-01 | 03 | 2 | SEC-04 | T-60-03 | Immutable v23 fixture has historical provenance, fixed SHA-256, synthetic sentinels, and no current-code fabrication | fixture contract | Fixture checksum/provenance contract invoked by `sqlcipher_native_assets_migration_test.dart` | ❌ W0 | ⬜ pending |
| 60-04-01 | 04 | 3 | SEC-03, SEC-04 | T-60-03, T-60-04 | Genuine v35 and v23 databases use real `onUpgrade` to v36 and preserve schema/data/integrity | Simulator integration | `flutter test integration_test/sqlcipher_native_assets_migration_test.dart -d <booted-ios-simulator-id> -r expanded` | ✅ (extension required) | ⬜ pending |
| 60-04-02 | 04 | 3 | SEC-03, SEC-04 | T-60-04 | Each fixture accepts a new sentinel, closes, cold-reopens through a new instance, and re-proves SQLCipher identity/header | Simulator integration | Same migration integration command | ✅ (extension required) | ⬜ pending |
| 60-05-01 | 05 | 3 | SEC-05 | T-60-05, T-60-06 | Real use cases round-trip current v2 and headerless legacy backups inside injected synthetic sandbox boundaries | Simulator integration | `flutter test integration_test/sqlcipher_backup_recovery_test.dart -d <booted-ios-simulator-id> -r expanded` | ❌ W0 | ⬜ pending |
| 60-05-02 | 05 | 3 | SEC-05 | T-60-05, T-60-06 | Wrong password, truncation, hostile KDF, corruption, size limits, and interruption leave DB/keys/settings/files/backup unchanged | Simulator integration + fault injection | Same backup recovery integration command | ❌ W0 | ⬜ pending |
| 60-06-01 | 06 | 4 | SEC-06 | T-60-07 | Key/security readiness remains before encrypted DB access; missing keys fail closed without schema bump | unit/infrastructure | `flutter test test/core/initialization/app_initializer_test.dart test/infrastructure/crypto/database/encrypted_database_native_assets_test.dart` | ✅ | ⬜ pending |
| 60-06-02 | 06 | 4 | SEC-01..SEC-06 | T-60-01..T-60-07 | Evidence converges without plaintext fallback, fixture regeneration, sandbox escape, or runtime/compile conflation | full convergence | `flutter analyze && flutter test --concurrency=1` plus clean iOS matrix and booted-Simulator lane | ✅ / ❌ W0 native runners | ⬜ pending |

Task and plan IDs are provisional seeds. The planner may renumber them but must preserve every requirement, threat, secure behavior, and command mapping.

---

## Wave 0 Requirements

- [ ] A clean native-resolution/build-matrix runner that protects the main tree and can reproduce the committed graph in a disposable from-zero copy.
- [ ] A reproducible generated SwiftPM iOS-15 contract; no hand-edited ephemeral manifest.
- [ ] An immutable SQLCipher 4.10 schema-v23 fixture generated from the accepted historical revision, with fixed SHA-256, synthetic-only sentinel specification, and provenance record.
- [ ] Shared dual-fixture assertions for checksum, `user_version`, tables, indices, defaults, representative values, integrity, SQLCipher identity/status/header, new write, close, and cold reopen.
- [ ] `integration_test/helpers/sqlcipher_backup_sandbox.dart` or an equivalent injected boundary harness for database, secure storage, files, journal, sync, and synthetic master key.
- [ ] `integration_test/sqlcipher_backup_recovery_test.dart` covering current v2 and headerless legacy success plus atomic failure snapshots.
- [ ] CoreSimulator preflight that blocks runtime acceptance when no booted Simulator is available; it must never downgrade runtime requirements to compile-only evidence.

---

## Fixture and Evidence Contract

- Verify immutable fixture SHA-256 before copying bytes into a unique temporary location. Never rewrite or regenerate a witness to make a regression pass.
- Open fixtures only through the production encrypted executor and `AppDatabase` migration path. A test-only SQL driver or hand-authored current-code v23 schema does not count.
- For both v35 and v23: assert initial metadata/sentinels, real upgrade to v36, SQLCipher 4.17.x, `cipher_status == 1`, readable `sqlite_master`, non-plaintext header, integrity, new write, close, new-instance cold reopen, and old/new sentinel survival.
- Record Simulator runtime evidence separately from generic Simulator/device compilation. Compilation never satisfies SEC-03, SEC-04, or SEC-05.
- Redact keys, passwords, financial values, absolute sandbox paths, and device identifiers from logs/evidence.

---

## Atomic Failure Snapshot

Before each wrong-password, truncation, hostile-KDF, corrupt-payload, resource-limit, or interruption case, snapshot only the synthetic sandbox state:

- database logical rows and schema version;
- isolated key/secure-storage/settings state;
- attachment and app-owned sandbox files;
- recovery journal and sync-barrier state;
- original backup bytes and digest.

The negative path passes only when every snapshot remains equivalent after the explicit rejection. The test must never inspect or mutate the normal app container, real Keychain, user backup directory, or physical device.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Booted-Simulator availability and runtime lane execution | SEC-03, SEC-04, SEC-05 | CoreSimulatorService was unavailable in the research sandbox; there is no valid compile-only substitute | On a host with a bootable iOS Simulator, record the selected runtime/configuration, run both Phase 60 integration tests in every technically runnable configuration, and retain redacted pass/fail evidence. |

Generic-device builds are unsigned compile-only checks. Physical-device signing, installation, launch, clear, or inspection is prohibited in Phase 60 and deferred to Phase 63.

---

## Failure Diagnostics

| Symptom | Diagnose | Required response |
|---------|----------|-------------------|
| SQLCipher version/status/header rejection | Hook selection, lockfile/native graph, runtime executor output | Fail closed; do not re-add legacy Flutter libraries, a separate SQLCipher Pod, or system SQLite. |
| Generated Swift package still targets iOS 13 | Supported source settings, clean generation, Xcode/Flutter diagnostics | Do not patch generated output; repair reproducible source configuration or block the phase. |
| Historical migration fails | Fixture SHA/provenance, first failing migration rung, schema/sentinel diff | Preserve immutable fixture bytes; fix the production migration. |
| Backup negative test mutates sandbox | Staging boundary, transaction/compensation, recovery journal, sync barrier | Treat as atomicity failure and locate the first changed snapshot component. |
| Simulator unavailable | `simctl`/CoreSimulator preflight | Mark SEC-03/04/05 runtime validation blocked; do not report compilation as acceptance. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or explicit Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification
- [ ] Wave 0 covers every missing fixture, harness, runner, and runtime preflight
- [ ] No watch-mode flags
- [ ] Normal task feedback latency is under 180 seconds; native long-running gates report separate progress
- [ ] Main tree has no unexplained tracked drift after isolated resolution/build evidence
- [ ] Runtime and compile-only evidence are explicitly separated
- [ ] `nyquist_compliant: true` and `wave_0_complete: true` are set only after the listed infrastructure exists and all mappings are executable

**Approval:** pending
