# Phase 60: SQLCipher & iOS Native Safety Lane - Research

**Researched:** 2026-08-09
**Domain:** Flutter iOS Native Assets, SQLCipher runtime proof, encrypted Drift migration, and sandboxed backup recovery
**Confidence:** HIGH for repository findings; MEDIUM for official upstream documentation.

> **Superseding scope correction — 2026-08-09 owner decision:** The historical migration and legacy-backup research below is retained as historical planning evidence, not an active requirement. The app has never shipped publicly, so no v23/v35 witness, historical `onUpgrade` proof, or headerless backup compatibility may be manufactured or claimed in Phase 60. Active evidence is current-schema SQLCipher lifecycle plus current `.hpb` v2 backup atomicity.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** The sole Phase 60 baseline is Drift 2.34.0, sqlite3 resolved 3.5.1, and SQLCipher Native Assets 4.17.x. The legacy sqlcipher_flutter_libs 0.6.8 + sqlite3 2.9.4 + SQLCipher Pod 4.10.0 lane is historical and must never be restored.
- **D-02:** Do not upgrade Drift or sqlite3 in Phase 60. Native safety proof must remain attributable to the exact current graph and must not introduce analyzer, generator, or schema churn.
- **D-03:** The first plan must atomically correct ROADMAP Phase 60 SC-1, REQUIREMENTS SEC-01, and the compatibility contract wherever they still describe the superseded Flutter-libs lane. Preserve ADR-002's original history and its append-only 2026-08-06 Native Assets update.
- **D-04:** Enforce the graph at three fail-closed layers: source/config prohibitions, resolved dependency/native graph checks, and runtime proof of SQLCipher 4.17.x, cipher_status == 1, readable sqlite_master, and a non-plaintext database header. Reject both legacy Flutter libs, system/plain SQLite, a separate SQLCipher CocoaPod, and the old Podfile -lsqlite3 strip.
- **D-05:** Phase 60 may run on iOS Simulator and compile for a generic iOS device without signing. It must not sign, install, launch, clear, or inspect an app on the physical iPhone; Phase 63 owns those actions under an isolated test identity.
- **D-06:** Clean-build the Runner for Simulator and generic device in Debug, Profile, and Release. Run SQLCipher fixture evidence in every technically runnable simulator configuration and label compile-only configurations honestly; compilation is never runtime acceptance.
- **D-07:** Use two clean-state proofs: retain committed lockfiles for the main-tree clean rebuild, and perform a from-zero dependency resolution in a temporary isolated copy. The isolated result must equal the committed graph and the main tree must retain no unexplained tracked drift.
- **D-08:** Normalize Runner, CocoaPods, SwiftPM, and generated plugin-package deployment floors to iOS 15 through supported source configuration or a reproducible generation mechanism. Never hand-edit ephemeral output. If the iOS 13 generated-package/Firebase iOS 15 mismatch cannot be removed reproducibly, Phase 60 fails closed.
- **D-09:** Cover both a genuine SQLCipher 4.10 schema-v35 fixture and a genuine v2.0 schema-v23 fixture through the real production migration path to the current schema v36.
- **D-10:** Generate the v23 fixture from the historical v2.0 code/schema and then-current SQLCipher configuration. Commit immutable fixture bytes, SHA-256, a reproducible generation record, and synthetic-only sentinel data. Do not manufacture an old schema dynamically with current code.
- **D-11:** The v23 fixture contains cross-domain synthetic sentinels for important tables that existed at that release, including accounting/encrypted fields, category/merchant, shopping, settings, and device/sync state. Verify user_version, tables, indices, defaults, representative values, hashes, and integrity invariants.
- **D-12:** Each historical fixture must execute real onUpgrade, verify schema v36 and old sentinels, write a new sentinel, close, cold-reopen through a new database instance, and re-verify old/new data, SQLCipher identity, integrity, and the non-plaintext header. Historical fixtures are immutable and must not be regenerated to make a regression pass.
- **D-13:** Run export-clear-restore only in a per-test iOS Simulator sandbox with a unique temporary directory, isolated synthetic master key, synthetic data, and injected storage boundaries. Never read the normal app container, real Keychain, user backup directory, or any physical device.
- **D-14:** The supported backup window is current v2 Argon2id/AES-256-GCM plus the existing headerless pre-v2 PBKDF2 format. Unknown versions and unsupported/hostile formats fail explicitly; no heuristic decryption or loose parsing is allowed.
- **D-15:** Decryption, resource-limit, format, schema, and integrity validation complete in staging before one commit point. Wrong password, truncation, hostile KDF parameters, corrupt payloads, or interruption must leave database logical state, keys, settings, attachments, and the original backup file unchanged.
- **D-16:** The success journey invokes the real export, clear-all, import, and restore use cases through injected sandbox database, secure-storage, and filesystem dependencies. Direct DAO/file shortcuts are prohibited. After restore, prove complete logical equivalence, cold reopen, and a second successful export.

### the agent's Discretion

- Choose the exact command ordering, temporary-copy mechanism, fixture naming, and test-file decomposition while preserving the locked evidence boundaries above.
- Choose a supported, reproducible source mechanism for the generated Swift package's iOS 15 floor; an ad hoc edit to generated/ephemeral files is not permitted.
- Select additional synthetic sentinel rows when needed to exercise real migration branches without introducing production or personal data.

### Deferred Ideas (OUT OF SCOPE)

- Android Gradle/Kotlin/toolchain and emulator proof remain Phase 61.
- Final all-platform automated release convergence remains Phase 62.
- Signed install, physical-iPhone SQLCipher runtime, production-like app journeys, and device performance remain Phase 63 under an isolated Bundle ID.
- Any future Drift/analyzer cohort or SQLCipher packaging replacement requires its own compatible graph and equivalent evidence; Phase 60 keeps the current exact graph.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| SEC-01 | Correct stale Flutter-libs wording and prohibit legacy/plaintext alternatives. | Extend source/lock/Pod contract and mutation tests. |
| SEC-02 | Clean-resolution and iOS build proof. | Main-tree and isolated-copy proofs plus generated SwiftPM iOS 15 contract. |
| SEC-03 | Encrypted initial open/cold reopen. | Existing production-executor fixture pattern. |
| SEC-04 | Genuine historic encrypted schemas reach v36 through real onUpgrade. | Retain v35 and create a committed v23 witness. |
| SEC-05 | Current and legacy backup recovery is atomic. | New Simulator-only real-use-case sandbox journey. |
| SEC-06 | Key-before-DB and missing-key fail-closed order stays unchanged. | Existing initializer and native executor tests. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Work on main, inspect git status -sb before edits, and preserve unrelated changes. [VERIFIED: AGENTS.md:17-24]
- Preserve Clean Architecture: native crypto in lib/infrastructure/, DB/repositories in lib/data/, orchestration in lib/application/. [VERIFIED: AGENTS.md:29-55]
- Use sqlite3 Native Assets with hooks.user_defines.sqlite3.source: sqlcipher; never re-add legacy Flutter libraries; startup must verify SQLCipher 4.17.x, status, schema readability, and non-plaintext header. [VERIFIED: AGENTS.md:120-126]
- Preserve key/security readiness before encrypted DB access; AppInitializer.initialize() finishes before runApp(). [VERIFIED: AGENTS.md:128-132]
- Do not log sensitive financial data, keys, tokens, recovery material, or sync payloads. [VERIFIED: AGENTS.md:121-122]
- Use TDD and retain clean analysis/targeted tests/full suite. [VERIFIED: AGENTS.md:177-202]
- Never hand-edit generated output; never restore the old Podfile linker strip. [VERIFIED: AGENTS.md:63-75; AGENTS.md:203-228]

## Summary

Phase 60 is a proof lane, not an upgrade lane. The live baseline declares drift 2.34.0, sqlite3 ^3.3.1, selects source: sqlcipher, and resolves sqlite3 3.5.1. [VERIFIED: pubspec.yaml:70-74; pubspec.yaml:128-131; pubspec.lock:1403-1410] The existing validator rejects legacy Flutter libraries, requires the hook, rejects a SQLCipher CocoaPod, and rejects the obsolete linker strip. [VERIFIED: scripts/dependency_compatibility.dart:342-369; scripts/dependency_compatibility.dart:466-503]

The runtime seam is already correct: the production executor verifies SQLCipher 4.17.x, cipher_status == 1, readable sqlite_master, and rejects the plaintext SQLite header. Quote: final _requiredSqlCipherVersion = RegExp(r'^4\.17\.\d+(?:\s|$)'); and throw StateError('Refusing to open a plaintext SQLite database');. [VERIFIED: lib/infrastructure/crypto/database/encrypted_database.dart:30-30; lib/infrastructure/crypto/database/encrypted_database.dart:70-114] Extend this seam; do not create an alternate database opener.

The critical unresolved native defect is reproducibility: Podfile/Runner are iOS 15 but the generated Swift package currently says .iOS("13.0"). [VERIFIED: ios/Podfile:1-1; ios/Runner.xcodeproj/project.pbxproj:490-490; ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift:9-13] Flutter’s own integration test proves a clean build derives that package target from the project minimum, so the plan must prove clean regeneration, not patch Package.swift. [VERIFIED: /Users/xinz/flutter/packages/flutter_tools/test/integration.shard/swift_package_manager_test.dart:604-666]

**Primary recommendation:** Correct stale contracts first; then prove a clean iOS graph, add immutable v23 plus existing v35 encrypted fixtures, run their real migration/reopen path on Simulator, and add a sandboxed real-use-case backup recovery test.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| SQLCipher selection/native graph | Build/native tooling | iOS project | Pub hook selects native assets; Xcode/SwiftPM/CocoaPods package/link them. [VERIFIED: pubspec.yaml:128-131; ios/Runner.xcodeproj/project.pbxproj:945-955] |
| Encryption identity/header gate | Infrastructure | Database | The production executor keys and verifies before Drift opens the file. [VERIFIED: lib/infrastructure/crypto/database/encrypted_database.dart:40-114] |
| Schema upgrade | Database | Infrastructure | AppDatabase migration delegates to ordered migration rungs. [VERIFIED: lib/data/app_database.dart:164-182; lib/data/app_database_migrations.dart:20-60] |
| Fixture runtime evidence | iOS Simulator harness | Database | Must use production executor/database in an isolated root. [VERIFIED: integration_test/sqlcipher_native_assets_migration_test.dart:61-131] |
| Backup recovery | Application | Database / Infrastructure | Existing use cases own snapshot, crypto, atomicity, sync barrier, and wipe state. [VERIFIED: lib/application/settings/export_backup_use_case.dart:51-140; lib/application/settings/import_backup_use_case.dart:50-116; lib/application/settings/restore_backup_use_case.dart:25-175; lib/application/settings/clear_all_data_use_case.dart:24-129] |

## Standard Stack

| Component | Locked value | Use |
|---|---:|---|
| Drift | 2.34.0 | Production MigrationStrategy; do not upgrade. [VERIFIED: pubspec.yaml:70-74; pubspec.lock:300-307; 60-CONTEXT.md:17-18] |
| sqlite3 Native Assets | 3.5.1 resolved | iOS SQLCipher hook. [VERIFIED: pubspec.lock:1403-1410] |
| SQLCipher | 4.17.x runtime | Engine required by the executor. [VERIFIED: lib/infrastructure/crypto/database/encrypted_database.dart:30-97] |
| Flutter SwiftPM + CocoaPods fallback | Flutter 3.44.8 baseline | Native plugin resolution. [VERIFIED: docs/testing/STABLE_BASELINE.json:14-25] |

Official sqlite3 documentation says native hooks bundle SQLite, include iOS device/simulator support, and support SQLCipher options; its v3 changelog says to drop sqlcipher_flutter_libs and sqlite3_flutter_libs. [CITED: https://pub.dev/packages/sqlite3] [CITED: https://pub.dev/packages/sqlite3/changelog] Flutter documents SwiftPM default-from-3.44 and CocoaPods fallback. [CITED: https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers]

**Installation:** None; this phase must not install or upgrade application dependencies. [VERIFIED: 60-CONTEXT.md:17-18]

## Package Legitimacy Audit

No new external package is installed, so the package-legitimacy gate is not applicable. The plan consumes the existing locked graph only. [VERIFIED: 60-CONTEXT.md:17-18; pubspec.lock:300-307; pubspec.lock:1403-1410]

## Architecture Patterns

### System Architecture Diagram

    pubspec hook + locks + Podfile + Runner project
                         |
                         v
             clean Flutter / SwiftPM / CocoaPods generation
                         |
          +--------------+-----------------+
          |                                |
          v                                v
generic device build                  booted iOS Simulator
Debug/Profile/Release                 immutable v35 + v23 fixtures
compile-only evidence                         |
          |                                   v
          +----------------------> production executor -> AppDatabase.onUpgrade
                                              |
                                              v
                           identity/status/schema/header -> cold reopen
                                              |
                                              v
                              sandboxed export -> clear -> restore -> export

### Recommended Project Structure

    integration_test/
    ├── fixtures/
    │   ├── sqlcipher_4_10_v35_fixture.dart       # existing witness
    │   ├── sqlcipher_4_10_v23_fixture.dart       # new immutable witness
    │   └── README.md                              # provenance/SHA record
    ├── helpers/
    │   ├── device_test_crypto.dart                # existing synthetic key helper
    │   └── sqlcipher_backup_sandbox.dart          # new injected-only harness
    ├── sqlcipher_native_assets_migration_test.dart # extend for both fixtures
    └── sqlcipher_backup_recovery_test.dart         # real-use-case test

### Pattern 1: Immutable encrypted historical witnesses

Decode committed fixture bytes, verify SHA-256 before copying to a unique temporary file, open only through createDeviceTestEncryptedExecutor, then migrate/write/close/new-instance-reopen. The v35 test already does this. [VERIFIED: integration_test/sqlcipher_native_assets_migration_test.dart:62-131]

The source-defined values are ^4.17.x and schemaVersion => 36. [VERIFIED: lib/infrastructure/crypto/database/encrypted_database.dart:30-30; lib/data/app_database.dart:64-65]

### Pattern 2: Full production-use-case sandbox

Compose real ExportBackupUseCase, ClearAllDataUseCase, ImportBackupUseCase, and RestoreBackupUseCase with sandbox DB/files/journal/secure-storage/sync dependencies. The existing device journey directly calls transactionRepository.deleteAllByBook, so it is not sufficient for D-16. [VERIFIED: integration_test/device_critical_journey_test.dart:245-269]

### Anti-Patterns to Avoid

- Current-code v23 recreation: index_v23_migration_test.dart dynamically drops/recreates shapes on a plain current database. Keep it as unit coverage, but it is not historic encrypted-fixture proof. [VERIFIED: test/unit/data/migrations/index_v23_migration_test.dart:103-193]
- Ephemeral Swift manifest patch: generated Package.swift says Generated file. Do not edit. [VERIFIED: ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift:1-5]
- Direct DAO/file clear: it bypasses journal, owned-file cleaner, secure storage, and sync barrier. [VERIFIED: lib/application/settings/clear_all_data_use_case.dart:70-129]
- Compile equals runtime: forbidden by D-06. [VERIFIED: 60-CONTEXT.md:23-25]

## Don't Hand-Roll

| Problem | Use instead | Why |
|---|---|---|
| Native SQLCipher loading | sqlite3 hook + existing executor | Native Assets is locked; legacy packages are prohibited. [VERIFIED: pubspec.yaml:128-131; scripts/dependency_compatibility.dart:342-369] |
| Historic migration | Immutable old encrypted DBs through AppDatabase migration | Real runner executes every ordered rung. [VERIFIED: lib/data/app_database.dart:164-182; lib/data/app_database_migrations.dart:56-60] |
| Backup parser/crypto | BackupCryptoService | It selects v2/headerless legacy and bounds hostile KDF input. [VERIFIED: lib/infrastructure/crypto/services/backup_crypto_service.dart:60-160; lib/infrastructure/crypto/services/backup_crypto_service.dart:170-189] |
| Atomic recovery | Existing export/import/restore/clear use cases | They own snapshot, transaction, compensation, sync barrier, and journal behavior. [VERIFIED: lib/application/settings/export_backup_use_case.dart:51-140; lib/application/settings/import_backup_use_case.dart:152-276; lib/application/settings/restore_backup_use_case.dart:87-175] |

## Code Examples

### Fixture acceptance shape

Use the existing production-facing shape, expanded to each immutable fixture; do not introduce a test-only SQL driver or migration loop. The source-defined values are `^4\\.17\\.\\d+(?:\\s|$)` and `schemaVersion => 36`. Quote: `final _requiredSqlCipherVersion = RegExp(r'^4\\.17\\.\\d+(?:\\s|$)');` and `int get schemaVersion => 36;`. [VERIFIED: lib/infrastructure/crypto/database/encrypted_database.dart:30-30; lib/data/app_database.dart:64-65]

    verifyFixtureSha(fixtureBytes, expectedSha);
    copyIntoUniqueSandbox(fixtureBytes);
    final db = await openWithProductionExecutor(sandboxFile);
    expect(await db.schemaVersion, 36);
    await assertOldSyntheticSentinels(db);
    await writeNewSyntheticSentinel(db);
    await db.close();
    await coldReopenAndVerifyOldAndNewSentinels(sandboxFile);

The example is a test skeleton, not an API proposal. Its required behavior comes from the current v35 integration flow: fixture checksum, production executor, migration, write, close, and reopen. [VERIFIED: integration_test/sqlcipher_native_assets_migration_test.dart:62-131]

## State of the Art

| Historical approach | Current locked approach | Impact |
|---|---|---|
| `sqlcipher_flutter_libs` / `sqlite3_flutter_libs` and a separate SQLCipher CocoaPod | `sqlite3` Native Assets selected by `hooks.user_defines.sqlite3.source: sqlcipher` | Native resolution is validated as one locked graph; the old packages/Pod must remain prohibited. [VERIFIED: pubspec.yaml:128-131; scripts/dependency_compatibility.dart:342-369] |
| Hand-edit generated iOS dependency output | Source configuration plus clean regeneration | The generated local Swift package must reproduce the iOS 15 deployment floor or fail closed. [VERIFIED: ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift:1-13; 60-CONTEXT.md:26-27] |

## Common Pitfalls

1. **Text-only D-03 correction:** Update stale ROADMAP/REQUIREMENTS/compatibility wording and executable validator/mutation tests together. Existing validator lacks a post-generation artifact-floor check. [VERIFIED: scripts/dependency_compatibility.dart:342-369; scripts/dependency_compatibility.dart:466-503]

2. **iOS-13 generated package:** Clean generation must assert 15.0 in SwiftPM output and dependent package/build diagnostics; never edit ephemeral output. [VERIFIED: ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift:9-13; /Users/xinz/flutter/packages/flutter_tools/test/integration.shard/swift_package_manager_test.dart:624-666]

3. **Wrong v23 provenance:** Commit 2cb07b08 is schema v23 and resolves historical sqlcipher_flutter_libs 0.6.8 / sqlite3 2.9.4; use an isolated checkout only to generate a committed witness, never to restore the app graph. [VERIFIED: git commit 2cb07b08; 2cb07b08:lib/data/app_database.dart:51-54; 2cb07b08:pubspec.lock:1444-1462]

4. **Sandbox escape:** Inject file/database/secure-storage/journal boundaries. Existing helper routes a synthetic key through production executor setup. [VERIFIED: integration_test/helpers/device_test_crypto.dart:8-61; test/unit/application/settings/clear_all_data_comprehensive_test.dart:90-105]

5. **Unsupported receipt restoration:** Backup strips photoHash and receipt blobs are not shipped. Assert backup-supported logical equivalence and photo availability; failure tests assert sandbox owned files stay unchanged. [VERIFIED: lib/features/accounting/domain/models/transaction_photo_sync_policy.dart:3-9; lib/features/accounting/domain/models/transaction_photo_sync_policy.dart:64-82; lib/infrastructure/storage/app_owned_user_files_cleaner.dart:7-19]

## Likely Files and Plan Decomposition

| Plan | Likely files | Dependency / acceptance |
|---|---|---|
| 60-01 Atomic contract correction | planning ROADMAP/REQUIREMENTS, compatibility docs/baseline, validator and architecture tests | First; correct stale SEC-01/SC-1 and preserve ADR history. |
| 60-02 Clean iOS graph | New narrow runner/contract test; possibly device-e2e workflow | Main clean rebuild + disposable from-zero copy; assert 15.0 post-generation and retain no unexplained drift. |
| 60-03 Immutable v23 fixture | New DB/Dart embedding/provenance under integration_test/fixtures | Generate only in isolated historical checkout; commit SHA/synthetic sentinel spec. |
| 60-04 Dual fixture migration | Existing SQLCipher integration test plus fixture helper | Both v35/v23 use production path through v36, write, cold reopen. |
| 60-05 Backup sandbox | New Simulator integration harness/test | Real use cases only; test v2/headerless legacy success plus all atomic failures. |
| 60-06 Convergence | Test/workflow/evidence docs as needed | Static/runtime/generic-device unsigned/analyze/full-suite gates. |

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|
| A1 | Commit 2cb07b08 is the intended v2.0 schema-v23 source. It is definitely v23/legacy-SQLCipher, but wording is ambiguous because later v2.0 tag is schema v36. | Fixture plan | Wrong historical witness. [ASSUMED] |
| A2 | A post-generation generic xcodebuild matrix is the best form for Debug/Profile/Release simulator/device unsigned compilation. | Validation | Command flags may need Xcode-specific adjustment. [ASSUMED] |

## Open Questions

1. **Which exact revision does D-10 mean by v2.0 schema-v23?**
   - 2cb07b08 is schema v23; v2.0 tag is dated 2026-08-05. [VERIFIED: git commit 2cb07b08; git tag v2.0]
   - Recommendation: record 2cb07b08 unless the owner identifies a different released v23 source.

2. **Can a Simulator boot in the execution environment?**
   - Xcode 26.2, CocoaPods 1.16.2, Swift 6.2.3 are available, but this session simctl could not connect to CoreSimulatorService and Flutter cache update was sandbox-denied. [VERIFIED: local environment probe, 2026-08-09]
   - Recommendation: preflight xcrun simctl list devices available outside this sandbox. Without it, SEC-03/04/05 runtime evidence is blocked, never compile-only passed.

## Environment Availability

| Dependency | Required by | Available | Version / fallback |
|---|---|---:|---|
| Xcode/xcodebuild | iOS builds | yes | Xcode 26.2 / none |
| CocoaPods | native resolution | yes | 1.16.2 / none |
| Swift | SwiftPM | yes | 6.2.3 / none |
| Flutter | generation/tests | partial | present; sandbox blocked engine-cache write; use normal execution environment |
| CoreSimulatorService | runtime proof | no this session | no fallback; generic builds are compile-only |

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | Flutter test plus SDK integration_test. [VERIFIED: pubspec.yaml:91-98] |
| Quick command | flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/ios_minimum_version_contract_test.dart test/infrastructure/crypto/database/encrypted_database_native_assets_test.dart test/core/initialization/app_initializer_test.dart |
| Fixture runtime | flutter test integration_test/sqlcipher_native_assets_migration_test.dart -d booted-ios-simulator-id -r expanded |
| Full suite | flutter test --concurrency=1 if default concurrency is unstable. [VERIFIED: AGENTS.md:194-200] |

### Phase Requirements to Test Map

| Req | Test type | Command / gap |
|---|---|---|
| SEC-01 | Architecture mutation | Existing dependency contract test; extend stale-text, hook, lock, Pod, strip, and artifact-floor mutations. |
| SEC-02 | Shell + contract | New clean-resolution/build matrix runner; Wave 0. |
| SEC-03 | Simulator integration | Extend existing fixture integration test. |
| SEC-04 | Simulator integration | Existing v35 plus new immutable v23; Wave 0 fixture. |
| SEC-05 | Simulator integration + units | New sqlcipher_backup_recovery_test.dart; Wave 0. |
| SEC-06 | Unit | Existing initializer/executor tests. |

### Fixture and Evidence Rules

- **Compile-only:** Generic Simulator/device Debug/Profile/Release build results include destination/mode/lock metadata and never satisfy runtime encryption acceptance. [VERIFIED: 60-CONTEXT.md:23-25]
- **Runtime:** Run every technically runnable fixture and backup scenario on a booted Simulator; redact paths, keys, passwords, financial values, and UDIDs. [VERIFIED: AGENTS.md:121-122]
- **Fixture integrity:** Verify SHA before copying to temp; then user_version, tables, indices/defaults, sentinels, PRAGMA integrity_check, cipher identity/status/schema, and non-plaintext header. Existing v35 SHA is 58d6f6f1f40e636323e13d40cf013cd9e541a8eb892f60b507cd898e2328c004. [VERIFIED: integration_test/sqlcipher_native_assets_migration_test.dart:12-31; integration_test/sqlcipher_native_assets_migration_test.dart:68-73]
- **Atomic failures:** Snapshot sandbox DB/logical rows, settings, synthetic key/storage state, owned files, and original backup bytes before wrong-password/truncation/KDF/size/corruption/interruption tests. [VERIFIED: lib/application/settings/import_backup_use_case.dart:54-115; lib/application/settings/import_backup_use_case.dart:152-276]

### Failure Diagnostics

| Symptom | Diagnose | Action |
|---|---|---|
| Required SQLCipher unavailable | hook/lock/native graph | Fail closed; do not re-add legacy packages. [VERIFIED: lib/infrastructure/crypto/database/encrypted_database.dart:80-86] |
| Wrong cipher status/plain header | executor + first 16 bytes | Treat as system/plain SQLite fallback. [VERIFIED: lib/infrastructure/crypto/database/encrypted_database.dart:88-114] |
| SwiftPM iOS-13 mismatch | clean regeneration + pbxproj + Package.swift | No ephemeral patch; supported config or block. [VERIFIED: ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift:1-13] |
| Migration fails | fixture SHA/provenance, first rung, schema/sentinel | Never regenerate fixture to pass. [VERIFIED: 60-CONTEXT.md:28-32] |
| Import mutates sandbox on failure | compare pre/post snapshot | Locate staging/transaction/compensation/journal breach. [VERIFIED: lib/application/settings/import_backup_use_case.dart:152-276] |

### Wave 0 Gaps

- [ ] Clean native-resolution/build-matrix runner with main-tree protection and isolated-copy proof.
- [ ] Reproducible generated SwiftPM iOS-15 contract.
- [ ] Immutable v23 fixture, checksum, provenance, and sentinel specification.
- [ ] Dual-fixture runtime integration assertions.
- [ ] Real-use-case backup sandbox and full-state snapshot helper.

## Security Domain

| ASVS category | Applies | Control |
|---|---|---|
| V5 Input Validation | Yes | Bounded encrypted/decompressed data and strict KDF/version handling before writes. [VERIFIED: lib/application/settings/import_backup_use_case.dart:54-115; lib/infrastructure/crypto/services/backup_crypto_service.dart:60-160] |
| V6 Cryptography | Yes | Existing SQLCipher and backup crypto service; no custom crypto/fallback. [VERIFIED: lib/infrastructure/crypto/database/encrypted_database.dart:70-98; lib/infrastructure/crypto/services/backup_crypto_service.dart:24-58] |
| V8 Data Protection | Yes | Runtime/header gates, immutable synthetic fixtures, sandbox-only destructive tests. [VERIFIED: lib/infrastructure/crypto/database/encrypted_database.dart:76-114; 60-CONTEXT.md:34-38] |

| Threat | STRIDE | Mitigation |
|---|---|---|
| System/plain SQLite fallback | Tampering/disclosure | Version, status, schema, and header gates. [VERIFIED: lib/infrastructure/crypto/database/encrypted_database.dart:76-114] |
| Dependency regression | Tampering | Source/lock/Pod checks plus clean-resolve graph evidence. [VERIFIED: scripts/dependency_compatibility.dart:342-369; scripts/dependency_compatibility.dart:474-503] |
| Hostile backup | DoS/tampering | Resource/KDF bounds, transaction, compensation, sync barrier. [VERIFIED: lib/application/settings/import_backup_use_case.dart:54-115; lib/application/settings/import_backup_use_case.dart:152-276] |
| Test touches real data | Disclosure/tampering | Synthetic key, unique temp root, injected stores, no physical device. [VERIFIED: integration_test/helpers/device_test_crypto.dart:8-61; 60-CONTEXT.md:34-38] |

## Sources

### Primary (HIGH confidence)

- Repository sources cited inline: manifests/locks, iOS project, executor, migration runner, initializer, backup use cases, fixtures/tests.
- Flutter SDK source cited inline: /Users/xinz/flutter/packages/flutter_tools/test/integration.shard/swift_package_manager_test.dart.

### Secondary (MEDIUM confidence)

- [sqlite3 documentation](https://pub.dev/packages/sqlite3) — Native Assets/iOS/SQLCipher.
- [sqlite3 changelog](https://pub.dev/packages/sqlite3/changelog) — v3 legacy-package migration.
- [Flutter SwiftPM guide](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers) — SwiftPM default/fallback.
- [Drift migrations](https://drift.simonbinder.eu/migrations/) and [migration testing](https://drift.simonbinder.eu/migrations/tests/) — migration test guidance.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — locked values and manifests/locks inspected.
- Architecture: HIGH — production executor, migration, initializer, and backup paths inspected.
- Pitfalls: HIGH — generated iOS-13 manifest, current rewind pattern, direct clear bypass, and attachment scope inspected.

**Research date:** 2026-08-09
**Valid until:** 2026-09-08 for repository findings; re-run clean native resolution immediately before execution.
