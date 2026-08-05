# Project Research Summary

**Project:** Happy Pocket (ハピポケ家族家計簿)
**Domain:** Local-first, privacy-first Flutter family accounting app; v2.1 dependency and native toolchain modernization
**Researched:** 2026-08-05
**Confidence:** MEDIUM

## Executive Summary

v2.1 must deliver a **reproducible, production-stable compatibility window**, not an empty `pub outdated` report. The shipped Flutter app has encrypted local financial data, historical Drift migrations, Argon2id/AES backup recovery, app lock, sync, and native integrations; version work is successful only when the exact resolved graph, generated source, native toolchains, and evidence all agree. Upgrade by coherent lanes with a committed lockfile and executable compatibility contract—never by blanket major upgrades or `dependency_overrides`.

The execution-date baseline is Flutter stable **3.44.8** (Dart 3.12.2, confirmed from the refreshed official Stable checkout on 2026-08-05), with **AGP 9.0.1 + Gradle 9.1 + JDK 17 + API 36** as the Android migration candidate. Preserve the known-good encrypted iOS lane exactly: `sqlcipher_flutter_libs 0.6.8` + `sqlite3 2.9.4` + SQLCipher CocoaPod 4.10.0, the Podfile system-`sqlite3` strip, and SwiftPM-for-supported-plugins/CocoaPods-for-SQLCipher split. Do not adopt `sqlcipher_flutter_libs 0.7.0+eol`, `sqlite3_flutter_libs`, or system SQLite.

The decisive risks are silent loss of SQLCipher linkage, data/keychain loss during testing, partial analyzer/codegen upgrades that disable the Clean Architecture import gate, and native artifacts that differ from test artifacts. Mitigate them with clean regeneration, fail-closed contracts, signed Android release + emulator proof, and an **isolated Bundle ID** wired-iPhone UAT. This milestone has one available physical target—a wired iPhone; Android physical-device UAT is explicitly unavailable/out of scope and must never be claimed.

## Key Findings

### Recommended Stack and Explicit Holds

| Lane | v2.1 decision | Rationale / non-negotiable condition |
|---|---|---|
| Flutter / Dart | Upgrade to Flutter stable **3.44.8** / Dart **3.12.2** and raise app SDK lower bound to `^3.12.0` | Confirmed from the official Stable checkout on 2026-08-05; do not choose scheduled, beta, RC, or dev releases. |
| Android native toolchain | Candidate: **AGP 9.0.1, Gradle 9.1, JDK 17, API 36** | Migrate as one lane to AGP built-in Kotlin/new DSL; remove legacy KGP/false flags only after every plugin builds. |
| SQLCipher native storage | **Hold:** `sqlcipher_flutter_libs 0.6.8` + `sqlite3 2.9.4` + Pod 4.10.0 | Last proven functional encrypted path. Preserve `ensureNativeLibrary()` order and Podfile `-lsqlite3` removal. |
| Analyzer / architecture lint | **Hold analyzer 8.x** | `import_guard_custom_lint 1.0.0` requires `<9`; solve this blocker before an analyzer-9+/Riverpod-generator modernization. No override or disabled architecture gate. |
| Riverpod / Drift / JSON / builders | Defer as coordinated solver lanes | Do not partially bump runtime, annotations, generators, lints, analyzer, builder, or `drift_dev`; each changes generated source contracts. |
| Freezed | Candidate low-risk patch: `freezed 3.2.5`; annotation stays 3.1.0 | Regenerate and verify in the selected analyzer-8 graph; no pre-release Freezed 4. |
| File/share/metadata | **Hold group:** file_picker 11.0.3, share_plus 12.0.2, package_info_plus 9.0.1, win32 5.15.0 | Partial major moves can change `.hpb` import or sharing behavior; file_picker 12 is pre-release. |
| Speech | Candidate `speech_to_text` 7.4.0 in an isolated adapter lane | Requires ja/zh/en parsing and platform permission/recognition proof; otherwise retain 7.3.0. |
| iOS | Xcode 26.6 stable; iOS floor remains 15.0; Swift 5 remains | Keep generated SwiftPM enabled; keep CocoaPods 1.16.2 locked and use `pod install`, not bulk `pod update`. |

### Core Deliverable Capabilities

The roadmap must cover these release-gating capabilities, not new product features:

- Production-stable baseline, reviewed `pubspec.lock`, version decision record, and a compatibility contract that rejects forbidden/partial lanes.
- Clean reproducible l10n and code generation with no stale generated `lib/` diff; analysis, custom lint/import boundaries, architecture tests, full tests, coverage, and release preflight stay blocking.
- Native encryption proof: non-empty `PRAGMA cipher_version` on the iPhone after initial open **and reopen**, historical encrypted schema migration, and preserved data/index/default invariants.
- Encrypted `.hpb` backup export → test-only destructive clear → password restore, including legacy-format/error-path coverage.
- Existing app-lock, manual accounting persistence, and encrypted sync queue/core delivery compatibility after cold relaunch.
- Signed Android release AAB/APK and Android-emulator integration validation; no Android physical device claim.
- Isolated wired-iPhone installation and profile/release-compatible performance evidence, with a distinct Bundle ID, container, keychain access group, notification configuration, test keys, and synthetic data.

### Architecture Approach

Do not redesign Clean Architecture. Keep build/dependency declarations at the composition boundary; SQLCipher/native loading in infrastructure; existing data/domain/presentation boundaries intact. A compatibility window owns source constraints, lockfile, generated artifacts, native project state, and evidence as one reviewable unit. Every exceptional pin co-evolves with `docs/testing/DEPENDENCY_COMPATIBILITY.md`, `scripts/dependency_compatibility.dart`, and its contract test.

Major boundaries:

1. **SDK/solver and generator boundary** — one Flutter/Dart-resolved graph; generated files are regenerated, never hand-edited.
2. **Secure native database boundary** — `ensureNativeLibrary()` before initialization/DB access, SQLCipher pragma proof, Podfile safeguard, migration ladder, and backup restore.
3. **Android build boundary** — AGP/wrapper/Kotlin/DSL/SDK/plugins migrate atomically; release signing remains enforced.
4. **iOS dependency and UAT boundary** — SwiftPM plus narrow SQLCipher Pods exception; an additive test identity protects the production app/container/keychain.
5. **Release evidence boundary** — `release_preflight.sh`, clean registrants, emulator/simulator prerequisites, then exact-artifact iPhone UAT.

### Critical Pitfalls

1. **System SQLite wins iOS symbol resolution.** Preserve the Podfile post-install `-lsqlite3` strip and require non-empty `cipher_version`; a successful host test is not encryption proof.
2. **EOL packages masquerade as upgrades.** Reject `sqlcipher_flutter_libs 0.7.0+eol` and `sqlite3_flutter_libs`; never fall back to plaintext/system SQLite.
3. **Partial codegen/analyzer updates remove lint protection.** `import_guard_custom_lint` blocks analyzer 9+; resolve/replace it first, then upgrade the whole affected lane and regenerate.
4. **AGP 9 is migrated halfway.** Do not remove KGP or legacy flags until plugin/app compilation, signed release packaging, and emulator E2E pass; otherwise keep a documented AGP-8 recovery point.
5. **The UAT app touches production data.** A distinct UAT Bundle ID/App ID/profile/keychain/container is mandatory; run destructive backup/restore only against deterministic test data.
6. **Migration/backup appears green but encrypted data is lost.** Preserve historical fixture and restore-atomicity tests; never mint a new master key when an encrypted DB already exists.

## Implications for Roadmap

Suggested sequential phases are **57–63**. Keep each phase as a green, revertible compatibility window and record the SHA/evidence before advancing.

### Phase 57: Baseline, Official Stable Decision, and Contract

**Rationale:** All later work depends on a single resolved baseline; version claims made on 2026-08-05 may have changed by execution.

**Delivers:** Recorded Flutter/Dart/Xcode/CocoaPods/Java/Gradle/SDK and dependency baseline; confirmed official Flutter 3.44.8 / Dart 3.12.2 Stable identity; allow/hold matrix; updated machine-checked compatibility contract and lockfile policy.

**Must avoid:** no blanket updater, no overrides, no SQLCipher EOL/system-SQLite resolution, and no unexplained hold.

### Phase 58: Flutter/Dart and Codegen/Analyzer Decision

**Rationale:** Flutter pins Dart and constrains Pub; code generation must be coherent before native/package cohorts consume its lockfile.

**Delivers:** Flutter 3.44.8/Dart ^3.12 baseline confirmed at execution; clean resolve; Freezed patch only if resolver-safe; generated artifacts/l10n/analysis/custom-lint/architecture gates green. Explicitly either (a) completes an import-guard-compatible analyzer upgrade or (b) records the analyzer-8/Riverpod/Drift/JSON/build-runner holds as accepted compatibility debt.

**Dependency:** The `import_guard_custom_lint <9` blocker must be solved before any analyzer-9+ or modern Riverpod generator lane. It is a prerequisite, not an override opportunity.

### Phase 59: Isolated Flutter/Plugin Cohorts

**Rationale:** Plugin changes require narrow causal attribution after the base solver is reproducible.

**Delivers:** Only resolver-safe cohorts, principally the speech adapter 7.3.0→7.4.0 if tests/permissions validate it; preserve file/share/metadata group unless a complete stable lane is proven. Firebase/messaging/notifications remain held if already current.

**Must avoid:** moving one package in the file/share/win32 group; accepting a beta; treating build success as microphone, share-sheet, APNs/FCM, or cold-start proof.

### Phase 60: Encrypted Native DB and iOS Dependency Resolution

**Rationale:** It establishes the privacy-critical native graph and must precede release gates/UAT.

**Delivers:** Clean SwiftPM/Pods regeneration, locked SQLCipher 0.6.8/sqlite3 2.9.4/Pod 4.10.0 lane, preserved linker safeguard, simulator/native encrypted reopen plus migration/backup test preparation.

**Must avoid:** a cosmetic SQLCipher upgrade, `pod update`, removing the system-SQLite strip, schema bumps not required by an app data change, or any plaintext fallback.

### Phase 61: Android AGP 9 Toolchain Migration

**Rationale:** Android host tooling is an atomic graph and can be rolled back independently to the last AGP-8 green point.

**Delivers:** AGP 9.0.1, Gradle 9.1, JDK 17, API 36 candidate validation; built-in Kotlin/new DSL migration; KGP and temporary opt-out flag removal only when compatible; debug build, signed release package, signing contract, and emulator E2E.

**Must avoid:** SDK/min-support-floor drift, debug signing as release proof, or claiming Android physical-device validation.

### Phase 62: Automated Release-Gate Hardening

**Rationale:** The final candidate must be produced by the exact reproducible process used for release, not cached native artifacts.

**Delivers:** CI exact SDK/lockfile enforcement; dependency contract, generation clean diff, analyze/custom lint/architecture tests, full suite/coverage, release preflight, Android release+emulator and iOS simulator gates; future-channel probe remains warning-only.

**Must avoid:** hand-editing plugin registrants, shipping `integration_test` registrants, suppressing signing failures, or converting `baseline_required` performance results into passes.

### Phase 63: Isolated Wired-iPhone Acceptance and Final Lock

**Rationale:** Only the connected iPhone proves signed-device SQLCipher linkage, Keychain/Face ID lifecycle, and representative performance. It must validate the candidate CI actually produced.

**Delivers:** Additive UAT scheme/configuration with a distinct Bundle ID/App ID/profile; redacted signed-device UAT record; final decision manifest/lock.

**Must avoid:** production app installation/overwrite, production keys/data/backups, sensitive logs, simulator substitution, and treating an unavailable sync environment as pass.

### Phase Ordering Rationale

`57 baseline → 58 SDK/solver → (59 constrained cohorts + 60 encrypted iOS lane) → 61 Android → 62 release gates → 63 wired-iPhone lock`.

This order fixes the resolver before plugin/native artifacts, proves encrypted persistence before platform release claims, and runs physical UAT last against the actual final lockfile. Keep 59 and 60 logically separate; if parallelized during planning, they cannot merge until the selected Flutter/Dart lockfile is identical and all joint gates pass.

### Research Flags

**Needs deeper planning research:**

- **58:** import-guard/custom-lint replacement or upgrade path; it is the hard analyzer<9 blocker and must preserve enforcement, not merely solve Pub.
- **60:** any proposed SQLCipher/sqlite3/Pod/SwiftPM change; current recommendation is hold, and a replacement needs official maintained-packaging evidence plus physical-device proof.
- **61:** AGP 9 built-in Kotlin/new DSL plugin-fleet compatibility under the exact chosen Flutter stable.
- **63:** separate Bundle ID/App ID, entitlements, Firebase/notification configuration, provisioning, and whether a production-identity in-place upgrade test is additionally required. Isolated identity alone does not prove production Keychain continuity.

**Standard/reuse-first planning:**

- **57 and 62:** repository has the compatibility script, CI workflows, release preflight, and contract tests to extend.
- **59 speech/file cohorts:** only after a standard clean solve; defer rather than research/force a non-essential upgrade.

## Release Blockers and Acceptance Matrix

| Gate | Required evidence | Cannot be substituted by |
|---|---|---|
| Stable/version decision | Official-source recheck; reviewed manifest, lockfile, exact command output, no unapproved beta/RC/override | A scheduled release date or `pub outdated` |
| Dependency/security contract | `dependency_compatibility.dart` and tests pass; no `sqlite3_flutter_libs`, no 0.7.0+eol; preserved known-good encrypted lane | Resolver success alone |
| Generation and architecture | clean `pub get`, l10n, build_runner; no generated `lib/` diff; analyze, custom lint/import guard, architecture tests, full suite/coverage | Manually edited generated code |
| Encryption and migration | non-empty `PRAGMA cipher_version` after open/reopen; historical fixture→current migration, schema/index/data assertions | Host VM test or a successful unencrypted DB open |
| Backup and lock | `.hpb` export/clear/restore exact sentinel; wrong-password/limits; PIN and Face ID/fallback/lifecycle evidence | Widget tests alone |
| Core/sync | manual daily/joy transaction persists over restart; encrypted queue/outbox settles without E2EE weakening | New feature work or unredacted payload logs |
| Android | signed release AAB/APK, signing contract, emulator integration test | Android debug build or Android physical-device claim |
| iPhone identity | distinct test Bundle ID/container/keychain/notification config; production install remains untouched | RunnerTests unit-test ID or changing production ID |
| Wired iPhone | exact signed artifact; install/start/reopen/migrate/backup/lock/core/sync-smoke record; profile/release benchmark metadata | Simulator, debug mode, or warm-cache observations |

## Scope Boundaries

**In scope:** stable-tooling/dependency decisions, generated output, native build integration, preservation of existing behavior, automated gates, Android release+emulator proof, and one isolated wired-iPhone acceptance.

**Out of scope:** product/UI features, beta/RC/dev adoption, Android physical-device UAT, iPad coverage, store submission/legal-content changes, production support/sponsor URLs, and SQLCipher architecture replacement without a separately approved ADR and evidence.

## Confidence Assessment

| Area | Confidence | Notes |
|---|---|---|
| Stack | MEDIUM | Versions and migration requirements use official primary sources; exact compatibility is still resolver/device dependent. SQLCipher and analyzer holds are HIGH-confidence project constraints. |
| Features / acceptance | HIGH | Existing scripts, CI, integration tests, migration/backup/lock harnesses, and stated device availability were directly observed. |
| Architecture | HIGH | Repository boundaries and fail-closed contracts are directly evidenced; recommended phase sequence is MEDIUM inference. |
| Pitfalls | MEDIUM | Official platform/SQLCipher guidance plus direct project safeguards; final failure modes require native-device validation. |

**Overall confidence:** MEDIUM. The recommended holds are stronger than speculative upgrade targets: preserving security and architecture enforcement is mandatory even if it means some apparent latest versions remain deferred.

### Conflicts and Uncertainties to Resolve During Planning

- **Flutter freshness:** 3.44.8 is the official Stable tag confirmed and installed on 2026-08-05; future refreshes must still use official Flutter sources and a documented GA-only decision.
- **Analyzer/Riverpod conflict:** latest Riverpod/codegen candidates conflict with the current analyzer-8 import guard. Do not put their upgrades into requirements as guaranteed delivery until the lint solution is researched and proven.
- **SQLCipher replacement:** none is authorized by current evidence. The v2.1 default is retention of 0.6.8/2.9.4/Pod 4.10.0, not migration to sqlite3 3.x.
- **AGP 9 candidate:** AGP 9.0.1/Gradle 9.1/API 36 is recommended, but delivery is conditional on the selected Flutter stable and all plugins completing built-in Kotlin/new DSL migration. A documented AGP-8 hold is preferable to a partial migration.
- **iPhone evidence scope:** an isolated app identity protects user data but proves clean-install compatibility, not production-identity/keychain in-place upgrade continuity; release owner must decide whether the latter becomes an added gate.
- **Performance:** existing tools may return `baseline_required`; that is not a pass. Define the same-device baseline and cold-start procedure before Phase 63.

## Direct Requirements and Roadmap Recommendations

- Make requirements explicitly binary: every changed lane must either ship with the above evidence or be **held with rationale**. “Latest version” is not independently a requirement.
- Include a hard requirement that the analyzer/import-boundary gate remains active; a resolver that disables it fails the milestone.
- Include all nine acceptance-matrix rows as release gates, with an explicit “Android physical device: unavailable/out of scope, not verified” result.
- Require the UAT Bundle ID/identity assertion before any device install. Do not reuse the RunnerTests Bundle ID as proof that the full UAT app is isolated.
- Plan rollback points after each compatibility window; SQLCipher, codegen/analyzer, and AGP 9 lanes must be reverted atomically to their last green lockfile/native state.
- Keep legal/store owner values out of this roadmap; retain them as separate pre-store-release gates from v2.0.

## Sources

### Official primary sources

- Flutter SDK archive, 3.44 release notes, built-in Kotlin migration, dependency management, integration testing, build modes/performance, and SwiftPM guidance.
- pub.dev version pages and maintainer documentation for Flutter/Dart packages, SQLCipher, SQLite, Riverpod, Drift, Freezed, custom lint/import guard, speech, Firebase, and platform plugins.
- Android Developers AGP 9.0.1 release notes, Android 16/API 36 setup, release build/signing guidance; Kotlin release documentation.
- Apple Xcode support, physical-device, bundle-ID, signing/provisioning, Keychain, Swift package, distribution, and responsiveness documentation; CocoaPods `pod install`/`pod update` guide.
- SQLCipher API/design/changelog primary documentation.

### Project evidence

- `.planning/PROJECT.md`, `.planning/STATE.md`, `pubspec.yaml`, lockfile, Android Gradle configuration, `ios/Podfile`/lock/project, and current iOS 15 support decision.
- `docs/testing/DEPENDENCY_COMPATIBILITY.md`, `scripts/dependency_compatibility.dart`, `.github/workflows/{audit,device-e2e,flutter-future-compat}.yml`, `scripts/release_preflight.sh`, and performance scripts.
- Encrypted database/init code, historical migration tests, device critical journey, sync delivery tests, backup-restore atomicity tests, and architecture/dependency contract tests.

---
*Research completed: 2026-08-05*
*Ready for roadmap: yes*
