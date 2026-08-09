# Phase 60: SQLCipher & iOS Native Safety Lane - Context

**Gathered:** 2026-08-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove that Happy Pocket's current iOS native dependency path preserves encrypted local financial data across clean dependency resolution, database open/reopen, historical schema migration, and encrypted backup recovery. Phase 60 owns the exact Drift/sqlite3/SQLCipher Native Assets graph, SwiftPM/CocoaPods/Xcode build consistency, synthetic encrypted fixtures, and simulator runtime evidence. It does not own Android toolchain work, production Bundle ID installation, signed physical-device runtime acceptance, or product changes.

</domain>

<decisions>
## Implementation Decisions

### Native Graph Authority
- **D-01:** The sole Phase 60 baseline is Drift `2.34.0`, sqlite3 resolved `3.5.1`, and SQLCipher Native Assets `4.17.x`. The legacy `sqlcipher_flutter_libs 0.6.8 + sqlite3 2.9.4 + SQLCipher Pod 4.10.0` lane is historical and must never be restored.
- **D-02:** Do not upgrade Drift or sqlite3 in Phase 60. Native safety proof must remain attributable to the exact current graph and must not introduce analyzer, generator, or schema churn.
- **D-03:** The first plan must atomically correct ROADMAP Phase 60 SC-1, REQUIREMENTS SEC-01, and the compatibility contract wherever they still describe the superseded Flutter-libs lane. Preserve ADR-002's original history and its append-only 2026-08-06 Native Assets update.
- **D-04:** Enforce the graph at three fail-closed layers: source/config prohibitions, resolved dependency/native graph checks, and runtime proof of SQLCipher `4.17.x`, `cipher_status == 1`, readable `sqlite_master`, and a non-plaintext database header. Reject both legacy Flutter libs, system/plain SQLite, a separate SQLCipher CocoaPod, and the old Podfile `-lsqlite3` strip.

### iOS Build Acceptance Boundary
- **D-05:** Phase 60 may run on iOS Simulator and compile for a generic iOS device without signing. It must not sign, install, launch, clear, or inspect an app on the physical iPhone; Phase 63 owns those actions under an isolated test identity.
- **D-06:** Clean-build the Runner for Simulator and generic device in Debug, Profile, and Release. Run SQLCipher fixture evidence in every technically runnable simulator configuration and label compile-only configurations honestly; compilation is never runtime acceptance.
- **D-07:** Use two clean-state proofs: retain committed lockfiles for the main-tree clean rebuild, and perform a from-zero dependency resolution in a temporary isolated copy. The isolated result must equal the committed graph and the main tree must retain no unexplained tracked drift.
- **D-08:** Normalize Runner, CocoaPods, SwiftPM, and generated plugin-package deployment floors to iOS 15 through supported source configuration or a reproducible generation mechanism. Never hand-edit ephemeral output. If the iOS 13 generated-package/Firebase iOS 15 mismatch cannot be removed reproducibly, Phase 60 fails closed.

### Migration Fixture Support Window
- **D-09:** Cover both a genuine SQLCipher 4.10 schema-v35 fixture and a genuine v2.0 schema-v23 fixture through the real production migration path to the current schema v36.
- **D-10:** Generate the v23 fixture from the historical v2.0 code/schema and then-current SQLCipher configuration. Commit immutable fixture bytes, SHA-256, a reproducible generation record, and synthetic-only sentinel data. Do not manufacture an old schema dynamically with current code.
- **D-11:** The v23 fixture contains cross-domain synthetic sentinels for important tables that existed at that release, including accounting/encrypted fields, category/merchant, shopping, settings, and device/sync state. Verify `user_version`, tables, indices, defaults, representative values, hashes, and integrity invariants.
- **D-12:** Each historical fixture must execute real `onUpgrade`, verify schema v36 and old sentinels, write a new sentinel, close, cold-reopen through a new database instance, and re-verify old/new data, SQLCipher identity, integrity, and the non-plaintext header. Historical fixtures are immutable and must not be regenerated to make a regression pass.

### Backup Destructive-Test Isolation
- **D-13:** Run export-clear-restore only in a per-test iOS Simulator sandbox with a unique temporary directory, isolated synthetic master key, synthetic data, and injected storage boundaries. Never read the normal app container, real Keychain, user backup directory, or any physical device.
- **D-14:** The supported backup window is current v2 Argon2id/AES-256-GCM plus the existing headerless pre-v2 PBKDF2 format. Unknown versions and unsupported/hostile formats fail explicitly; no heuristic decryption or loose parsing is allowed.
- **D-15:** Decryption, resource-limit, format, schema, and integrity validation complete in staging before one commit point. Wrong password, truncation, hostile KDF parameters, corrupt payloads, or interruption must leave database logical state, keys, settings, attachments, and the original backup file unchanged.
- **D-16:** The success journey invokes the real export, clear-all, import, and restore use cases through injected sandbox database, secure-storage, and filesystem dependencies. Direct DAO/file shortcuts are prohibited. After restore, prove complete logical equivalence, cold reopen, and a second successful export.

### the agent's Discretion
- Choose the exact command ordering, temporary-copy mechanism, fixture naming, and test-file decomposition while preserving the locked evidence boundaries above.
- Choose a supported, reproducible source mechanism for the generated Swift package's iOS 15 floor; an ad hoc edit to generated/ephemeral files is not permitted.
- Select additional synthetic sentinel rows when needed to exercise real migration branches without introducing production or personal data.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and Locked Requirements
- `AGENTS.md` — current SQLCipher Native Assets, iOS build, key ordering, testing, and repository safety rules.
- `.planning/ROADMAP.md` — Phase 60 boundary and SEC-01..06 success criteria; its legacy SC-1 wording must be reconciled under D-03.
- `.planning/REQUIREMENTS.md` — SEC-01 through SEC-06 and the explicit out-of-scope production/device restrictions.
- `.planning/PROJECT.md` — v2.1 milestone goal, security posture, and isolated-iPhone ownership boundary.
- `.planning/phases/58-flutter-analyzer-code-generation-lane/58-CONTEXT.md` — exact Dart/Drift/analyzer boundary and D-10 deferral of native work to Phase 60.
- `.planning/phases/59-controlled-platform-plugin-cohorts/59-VERIFICATION.md` — held plugin graph and key-before-database evidence consumed by this phase.
- `.planning/phases/59-controlled-platform-plugin-cohorts/59-SECURITY.md` — final Phase 59 threat dispositions and accepted artifact-validator risk.

### Native Storage Policy
- `docs/arch/03-adr/ADR-002_Database_Solution.md` §Update 2026-08-06 — authoritative append-only decision selecting sqlite3 Native Assets + SQLCipher 4.17.
- `docs/testing/STABLE_BASELINE.json` — exact selected encrypted-storage lane, prohibitions, tracked-input digests, and Phase 60 exit condition.
- `docs/testing/DEPENDENCY_COMPATIBILITY.md` — human-readable encrypted-storage and iOS dependency-manager compatibility contract.
- `pubspec.yaml` — sqlite3 declaration and `hooks.user_defines.sqlite3.source: sqlcipher` selection.
- `pubspec.lock` — exact Drift/sqlite3 resolved graph.
- `ios/Podfile` — iOS 15 CocoaPods policy without the legacy linker strip.
- `ios/Podfile.lock` — resolved CocoaPods graph without a separate SQLCipher pod.
- `ios/Runner.xcodeproj/project.pbxproj` — Runner configurations and generated SwiftPM package integration.

### Runtime, Migration, and Backup Evidence
- `lib/infrastructure/crypto/database/encrypted_database.dart` — SQLCipher runtime identity, keyed-status, schema-readability, and file-header gates.
- `lib/data/app_database.dart` — schema v36 and production migration strategy.
- `lib/core/initialization/app_initializer.dart` — native-library/key readiness before database construction and fail-closed startup.
- `integration_test/sqlcipher_native_assets_migration_test.dart` — genuine SQLCipher 4.10 v35 migration, write, and cold-reopen pattern.
- `integration_test/fixtures/sqlcipher_4_10_v35_fixture.dart` — immutable embedded v35 fixture bytes.
- `integration_test/fixtures/README.md` — fixture provenance and generation record pattern.
- `lib/infrastructure/crypto/services/backup_crypto_service.dart` — v2 Argon2id/AES-GCM and pre-v2 PBKDF2 format detection/resource limits.
- `lib/application/settings/export_backup_use_case.dart` — production backup export path.
- `lib/application/settings/import_backup_use_case.dart` — production decrypt, decompress, validate, and import path.
- `lib/application/settings/restore_backup_use_case.dart` — production restore orchestration and rollback boundary.
- `test/infrastructure/crypto/services/backup_crypto_service_test.dart` — current/legacy format, wrong-password, hostile-header, and truncation patterns.
- `scripts/dependency_compatibility.dart` — fail-closed dependency/native contract.
- `test/architecture/dependency_compatibility_contract_test.dart` — positive and negative graph mutations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `encrypted_database.dart` already checks `cipher_version`, `cipher_status`, readable schema, and encrypted file identity; extend its evidence rather than creating a second database opener.
- `sqlcipher_native_assets_migration_test.dart` and its committed v35 fixture already establish genuine encrypted-fixture provenance, migration, write, close, and cold-reopen patterns.
- `BackupCryptoService` already supports the current v2 header and legacy headerless format with hostile KDF bounds.
- Existing export/import/restore/clear-all use cases provide the production journey that the isolated simulator harness must exercise.
- The stable baseline validator and dependency contract mutation tests already reject prohibited SQLite packages and native-graph drift.

### Established Patterns
- Security-critical incompatibility fails closed; an evidence-backed hold is valid, while plaintext fallback or a partial native graph is never valid.
- Generated registrants and SwiftPM ephemeral files are regenerated, never hand-edited.
- App initialization establishes native-library and key readiness before opening Drift.
- Fixtures contain only deterministic synthetic data, fixed checksums, and reproducible provenance.
- Native compile evidence, simulator runtime evidence, and physical-device evidence are distinct and cannot substitute for one another.

### Integration Points
- `pubspec.yaml`, `pubspec.lock`, `ios/Podfile`, `ios/Podfile.lock`, and the Xcode project jointly define the selected native graph.
- `AppInitializer` and `encrypted_database.dart` form the key/native/database fail-closed boundary.
- `AppDatabase.migration` is the only accepted historical schema upgrade path.
- Backup crypto and settings use cases form the end-to-end `.hpb` export/clear/restore path.
- Phase 62 consumes the exact final lockfile and automated gates; Phase 63 consumes only signed, isolated physical-iPhone runtime acceptance.

</code_context>

<specifics>
## Specific Ideas

- Treat the legacy 0.6.8/2.9.4/Pod 4.10 ROADMAP wording as stale planning data, not permission to downgrade the code.
- Keep compile-only results visibly separate from runtime encryption evidence.
- Prove reproducibility twice: locked clean rebuild in the main tree and from-zero resolution in a disposable copy.
- Historical database fixtures are immutable compatibility witnesses; current code must adapt or fail rather than rewriting the witness.
- Backup failure atomicity covers all persisted sandbox state, not only transaction rows.

</specifics>

<deferred>
## Deferred Ideas

- Android Gradle/Kotlin/toolchain and emulator proof remain Phase 61.
- Final all-platform automated release convergence remains Phase 62.
- Signed install, physical-iPhone SQLCipher runtime, production-like app journeys, and device performance remain Phase 63 under an isolated Bundle ID.
- Any future Drift/analyzer cohort or SQLCipher packaging replacement requires its own compatible graph and equivalent evidence; Phase 60 keeps the current exact graph.

</deferred>

---

*Phase: 60-sqlcipher-ios-native-safety-lane*
*Context gathered: 2026-08-09*
