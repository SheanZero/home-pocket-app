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
| **Targeted runtime command** | `dart run scripts/verify_ios_native_safety_lane.dart --lane=runtime --runtime-test=<one Phase 60 integration test>` after the fixture provenance verifier where applicable |
| **Full suite command** | Task 60-07-02's six exact commands: analyze, single-concurrency suite, fixture provenance acceptance, full migration/native lane, backup runtime lane, and diff check |
| **Estimated runtime** | Quick: ~120 seconds; full native matrix and Simulator lane: environment-dependent, expected tens of minutes |

---

## Sampling Rate

- **After every task commit:** Run the narrowest requirement-specific command from the map below; run the quick suite after contract/runtime-seam changes.
- **After every plan wave:** Run `flutter analyze` plus all Phase 60 tests that exist by that wave; native graph waves also run their clean-resolution/build command.
- **Before `$gsd-verify-work`:** The full Dart suite, main-tree and isolated resolution proofs, six-mode unsigned iOS build matrix, and every technically runnable Simulator scenario must be green.
- **Max feedback latency:** 180 seconds for normal task checks. Native clean builds and Simulator integration are explicit long-running gates and must report progress/evidence separately.

All seven PLAN estimate blocks remain low-confidence, non-precise raw projections because `estimate-calibration` reports `sample_count: 0`. The revision does not add false precision or inflate those figures.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 60-01-01 | 01 | 1 | SEC-01, SEC-02 | T-60-01, T-60-02 | Exact Native Assets graph and generated iOS-15-floor mutations fail closed through one validator without runtime claims. | architecture/mutation | `flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/ios_minimum_version_contract_test.dart` | ✅ extend both | ⬜ pending |
| 60-01-02 | 01 | 1 | SEC-01, SEC-02 | T-60-01, T-60-02, T-60-03 | ROADMAP/REQUIREMENTS/docs/baseline agree atomically while ADR-002 is byte-preserved. | architecture + contract | `flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/ios_minimum_version_contract_test.dart`<br>`dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk`<br>`git diff --exit-code -- docs/arch/03-adr/ADR-002_Database_Solution.md` | ✅ existing/extend | ⬜ pending |
| 60-02-01 | 02 | 2 | SEC-01, SEC-02, SEC-03 | T-60-04, T-60-05, T-60-06, T-60-07, T-60-08 | One retained-lock Debug Simulator tracer regenerates iOS 15, proves the exact graph, executes real SQLCipher runtime when available, and preserves/redacts host state. | architecture + native tracer | `flutter test test/architecture/ios_minimum_version_contract_test.dart`<br>`dart run scripts/verify_ios_native_safety_lane.dart --lane=tracer --runtime-test=integration_test/sqlcipher_native_assets_migration_test.dart` | ❌ W0 create runner; ✅ extend contract | ⬜ pending |
| 60-02-02 | 02 | 2 | SEC-01, SEC-02, SEC-03 | T-60-04, T-60-05, T-60-06, T-60-07, T-60-08 | Disposable from-zero resolution matches retained locks and all six unsigned builds stay distinct from Simulator runtime evidence. | architecture + native matrix | `flutter test test/architecture/ios_minimum_version_contract_test.dart test/architecture/dependency_compatibility_contract_test.dart`<br>`dart run scripts/verify_ios_native_safety_lane.dart --lane=full --runtime-test=integration_test/sqlcipher_native_assets_migration_test.dart` | W0 60-02-01 runner required | ⬜ pending |
| 60-03-01 | 03 | 2 | SEC-04 | T-60-09 | The owner confirms researched candidate `2cb07b08` or supplies the authoritative full schema-v23 revision before any manifest/worktree/fixture command. | blocking decision | N/A — blocking `checkpoint:decision`; resume only with `confirm-2cb07b08` or `historical-revision: <full commit SHA>` | N/A; checkpoint receipt is W0 prerequisite for 60-03-02 | ⬜ pending |
| 60-03-02 | 03 | 2 | SEC-04 | T-60-09, T-60-10, T-60-11, T-60-12 | Source-before-generation and acceptance verification bind the owner-approved revision, schema 23, exact historical lock/SQLCipher 4.10 config, generation metadata, immutable bytes/SHA/header, and full synthetic sentinel manifest; current-code manufacture fails. | provenance/generation + architecture | Pre-generation: `dart run scripts/verify_sqlcipher_v23_fixture_provenance.dart --mode=source --revision {owner_approved_full_sha} --worktree {validated_detached_worktree}`<br>Acceptance: `dart run scripts/verify_sqlcipher_v23_fixture_provenance.dart --mode=acceptance`<br>`flutter test test/architecture/sqlcipher_historical_fixture_contract_test.dart`<br>`dart format --output=none --set-exit-if-changed scripts/verify_sqlcipher_v23_fixture_provenance.dart integration_test/fixtures/sqlcipher_4_10_v23_fixture.dart test/architecture/sqlcipher_historical_fixture_contract_test.dart`<br>`dart analyze scripts/verify_sqlcipher_v23_fixture_provenance.dart integration_test/fixtures/sqlcipher_4_10_v23_fixture.dart test/architecture/sqlcipher_historical_fixture_contract_test.dart` | ❌ W0 create verifier, manifest, fixture, README record, contract; requires 60-03-01 | ⬜ pending |
| 60-03-03 | 03 | 2 | SEC-04 | T-60-09, T-60-10, T-60-11, T-60-12 | Approval/source/generation/checksum/header/sentinel/asset mutations fail and verification leaves immutable witness artifacts byte-stable. | architecture/mutation | `dart run scripts/verify_sqlcipher_v23_fixture_provenance.dart --mode=acceptance`<br>`flutter test test/architecture/sqlcipher_historical_fixture_contract_test.dart`<br>`git diff --check` | W0 60-03-02 artifacts required; extend contract | ⬜ pending |
| 60-04-01 | 04 | 3 | SEC-03, SEC-04 | T-60-13, T-60-14, T-60-15, T-60-16 | Provenance-verified v35/v23 witnesses use production executor + real `onUpgrade` to v36 with complete SQLCipher/schema/data/integrity assertions. | Simulator integration | `dart run scripts/verify_sqlcipher_v23_fixture_provenance.dart --mode=acceptance`<br>`dart run scripts/verify_ios_native_safety_lane.dart --lane=runtime --runtime-test=integration_test/sqlcipher_native_assets_migration_test.dart` | ❌ W0 create helper; ✅ extend integration test; requires 60-02 and 60-03 | ⬜ pending |
| 60-04-02 | 04 | 3 | SEC-03, SEC-04 | T-60-13, T-60-14, T-60-15, T-60-16 | Each migrated witness writes, closes, cold-reopens through a new instance, and preserves old/new state plus cipher/header/integrity invariants. | Simulator integration + host fixture contract | `dart run scripts/verify_sqlcipher_v23_fixture_provenance.dart --mode=acceptance`<br>`dart run scripts/verify_ios_native_safety_lane.dart --lane=full --runtime-test=integration_test/sqlcipher_native_assets_migration_test.dart`<br>`flutter test test/architecture/sqlcipher_historical_fixture_contract_test.dart` | W0 60-04-01 helper/test required | ⬜ pending |
| 60-05-01 | 05 | 3 | SEC-05 | T-60-17, T-60-18, T-60-20 | Current v2 export → real clear-all → real import/restore → cold reopen → second export stays inside one injected synthetic Simulator root. | Simulator integration tracer | `dart run scripts/verify_ios_native_safety_lane.dart --lane=runtime --runtime-test=integration_test/sqlcipher_backup_recovery_test.dart` | ❌ W0 create sandbox helper and recovery test; requires 60-02 runner | ⬜ pending |
| 60-05-02 | 05 | 3 | SEC-05 | T-60-17, T-60-18, T-60-19, T-60-20 | Exact headerless legacy input uses the same real restore path, remains byte-identical, cold-reopens, and re-exports as current v2. | Simulator integration + crypto unit | `dart run scripts/verify_ios_native_safety_lane.dart --lane=full --runtime-test=integration_test/sqlcipher_backup_recovery_test.dart`<br>`flutter test test/infrastructure/crypto/services/backup_crypto_service_test.dart` | W0 60-05-01 helper/test required | ⬜ pending |
| 60-06-01 | 06 | 4 | SEC-05 | T-60-21, T-60-24, T-60-25 | Wrong password, malformed/unknown/truncated/auth-invalid payloads, hostile KDF/size/schema inputs reject before any sandbox-state or original-byte change. | Simulator fault matrix + crypto unit | `dart run scripts/verify_ios_native_safety_lane.dart --lane=runtime --runtime-test=integration_test/sqlcipher_backup_recovery_test.dart`<br>`flutter test test/infrastructure/crypto/services/backup_crypto_service_test.dart` | ✅ extend 60-05 sandbox/test | ⬜ pending |
| 60-06-02 | 06 | 4 | SEC-05 | T-60-22, T-60-23, T-60-24, T-60-25 | Every restore interruption rolls back/compensates or remains explicitly pending; retry never re-imports and rejected attempts cold-reopen unchanged. | Simulator fault matrix + use-case unit | `dart run scripts/verify_ios_native_safety_lane.dart --lane=full --runtime-test=integration_test/sqlcipher_backup_recovery_test.dart`<br>`flutter test test/unit/application/settings/import_backup_use_case_atomicity_test.dart test/unit/application/settings/restore_backup_use_case_test.dart` | ✅ extend 60-05/60-06 artifacts | ⬜ pending |
| 60-07-01 | 07 | 5 | SEC-06 | T-60-C1, T-60-C9 | Injected logs prove native-library readiness → key readiness → encrypted database factory/executor; native failure and missing-key-with-data stop before unintended downstream construction; schema stays 36. | initializer/infrastructure TDD | `flutter test test/core/initialization/app_initializer_test.dart test/infrastructure/crypto/database/encrypted_database_native_assets_test.dart` | ✅ extend production/tests; no migration artifact | ⬜ pending |
| 60-07-02 | 07 | 5 | SEC-01, SEC-02, SEC-03, SEC-04, SEC-05, SEC-06 | T-60-C1, T-60-C2, T-60-C3, T-60-C4, T-60-C5, T-60-C6, T-60-C7, T-60-C8, T-60-C9 | One exact commit/lock converges graph, fixture provenance, native builds, Simulator runtime, migration, backup atomicity, startup order, redaction, and clean-tree evidence without physical-device claims. | full convergence | `flutter analyze`<br>`flutter test --concurrency=1`<br>`dart run scripts/verify_sqlcipher_v23_fixture_provenance.dart --mode=acceptance`<br>`dart run scripts/verify_ios_native_safety_lane.dart --lane=full --runtime-test=integration_test/sqlcipher_native_assets_migration_test.dart`<br>`dart run scripts/verify_ios_native_safety_lane.dart --lane=runtime --runtime-test=integration_test/sqlcipher_backup_recovery_test.dart`<br>`git diff --check` | ❌ create evidence; ✅ update validation after every prior W0 artifact exists | ⬜ pending |

This is the final 15-task map for Plans 60-01 through 60-07: 14 implementation tasks have explicit automated commands and 60-03-01 is the single blocking owner decision. These task IDs are authoritative.

---

## Wave 0 Requirements

- [ ] **60-01-01/02 (Wave 1):** extend the existing dependency/iOS-floor contracts and atomically reconcile readable/machine policy; no new dependency or generated artifact is a prerequisite.
- [ ] **60-02-01 (Wave 2):** create `scripts/verify_ios_native_safety_lane.dart`, including exact main-tree status preservation, retained-lock tracer, generated SwiftPM iOS-15 inspection, destination allowlist, redaction, and CoreSimulator preflight. Task 60-02-02 may expand only after this runner exists.
- [ ] **60-03-01 (Wave 2):** obtain the owner's authoritative revision decision. This checkpoint is a hard precondition; no fixture-generation command is permitted before its receipt.
- [ ] **60-03-02 (Wave 2):** create the provenance verifier, owner-decision/generation manifest, immutable v23 witness, README record, and first checksum/provenance contract. Source mode runs before generation; acceptance mode and the host contract run afterward and never regenerate bytes.
- [ ] **60-03-03 (Wave 2):** add negative controls and byte-stability checks to the created provenance/asset contract.
- [ ] **60-04-01 (Wave 3):** create shared dual-fixture assertions and extend the migration integration test; it requires both the native runner and the accepted/verifier-green v23 manifest/witness.
- [ ] **60-05-01 (Wave 3):** create the injected SQLCipher backup sandbox and recovery integration test with unique database/key/settings/files/journal/sync/backup roots. Task 60-05-02 and all Wave-4 failures extend these artifacts.
- [ ] **60-07-01 (Wave 5):** extend production initialization with the Native Assets readiness injection and extend initializer/executor tests; the schema remains 36 and no migration artifact is created.
- [ ] **60-07-02 (Wave 5):** create one-commit redacted convergence evidence and update this validation file only after every mapped artifact/command is executable and green. CoreSimulator absence keeps SEC-03/04/05 blocked rather than converting compilation into runtime acceptance.

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

- [ ] The final task set is exactly 60-01-01 through 60-07-02 (15 rows): 14 implementation tasks have the exact `<automated>` commands above and 60-03-01 is the sole blocking decision exemption
- [ ] 60-03-01 records the owner's authoritative full historical revision; 60-03-02 source verification passes before any fixture generation
- [ ] The fixture provenance acceptance command passes in 60-03-02, 60-03-03, both 60-04 tasks, and final 60-07-02 convergence without changing fixture/manifest/README bytes
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification
- [ ] Wave 0 ownership above covers every missing verifier, manifest, fixture, contract, harness, runner, native-readiness seam, and runtime preflight with its real creating task and dependency
- [ ] No watch-mode flags
- [ ] Normal task feedback latency is under 180 seconds; native long-running gates report separate progress
- [ ] Main tree has no unexplained tracked drift after isolated resolution/build evidence
- [ ] Runtime and compile-only evidence are explicitly separated
- [ ] 60-07-01 call logs prove native readiness → key readiness → database construction on success, and native/key failures stop before unintended downstream calls with schemaVersion 36 unchanged
- [ ] 60-07-02 evidence cites one exact commit/lock, every SEC-01..SEC-06 result, every T-60-C1..C9 mitigation, the six unresolved flagged assumptions, clean-tree equality, redaction, and the absence of physical-device actions
- [ ] `nyquist_compliant: true` and `wave_0_complete: true` are set only after the listed infrastructure exists and all mappings are executable

**Approval:** pending
