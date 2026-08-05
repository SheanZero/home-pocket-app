# Upgrade Architecture Patterns: v2.1 Dependency and Native Toolchain Modernization

**Domain:** Local-first, encrypted Flutter family-accounting application
**Researched:** 2026-08-05
**Confidence:** MEDIUM — repository contracts and current official Flutter, Dart, and Apple guidance were cross-checked. Context7/CLI documentation lookup was unavailable for Drift/Riverpod, so their upgrade boundaries are derived from the locked graph and executable repository gates rather than undocumented version claims.

## Recommended Architecture

Treat v2.1 as a sequence of **verified compatibility windows**, not a `flutter pub upgrade --major-versions` exercise. A window owns one solver graph plus the native artefacts produced from it. It is complete only when its source changes, generated output, lockfile, platform build files, and gate evidence agree.

```text
immutable baseline / reproducible commands
                 |
                 v
Flutter-Dart SDK + pub solver snapshot
                 |
     +-----------+------------+
     |                        |
     v                        v
codegen/analyzer/lint lane   independently-safe Dart/Flutter package lane
     |                        |
     +-----------+------------+
                 |
                 v
native-security lane: sqlite3 API + SQLCipher asset + CocoaPods/SwiftPM
                 |
     +-----------+------------+
     |                        |
     v                        v
Android AGP/Gradle/Kotlin   iOS release preflight / isolated-device scheme
     |                        |
     +-----------+------------+
                 |
                 v
CI gates, emulator/simulator E2E, signed iPhone UAT and final lock
```

The existing application architecture does **not** need a Clean Architecture redesign. Keep dependency declarations and generation settings at the composition/build boundary; keep platform loading in `lib/infrastructure/`; and keep the current domain/data/presentation dependency rules intact. A dependency upgrade must not become a reason to move Drift tables, DAOs, repositories, crypto services, or Riverpod UI providers across those boundaries.

### Component Boundaries

| Component | Responsibility in v2.1 | Owns | Must not do |
|---|---|---|---|
| Compatibility manifest | Express one reviewed version window and explain intentional holds | `pubspec.yaml`, `pubspec.lock`, `docs/testing/DEPENDENCY_COMPATIBILITY.md`, `scripts/dependency_compatibility.dart` | Use `dependency_overrides` or a lockfile edit to conceal an incompatible graph |
| SDK/solver boundary | Pin the selected Flutter stable SDK in CI and resolve the complete pub graph | CI Flutter pin, SDK constraints, lockfile | Mix package solves produced by different SDKs or accept beta/RC packages |
| Generator/analyzer boundary | Upgrade generator APIs together and regenerate all derived source | `build.yaml`, `analysis_options.yaml`, generated `*.g.dart`, `*.freezed.dart`, `lib/generated/` | Hand-edit generated output or accept stale-diff gates |
| Secure native database boundary | Keep SQLCipher the loaded SQLite implementation before Drift opens the DB | `sqlcipher_flutter_libs`, `sqlite3`, `ios/Podfile`, `ios/Podfile.lock`, `encrypted_database.dart` | Introduce `sqlite3_flutter_libs`, system SQLite fallback, or SQLCipher `0.7.0+eol` |
| iOS native-resolution boundary | Prefer Flutter SwiftPM where supported and retain CocoaPods only for the SQLCipher exception | Xcode SwiftPM reference, Podfile/lock, iOS release preflight | Disable SwiftPM globally or remove the SQLCipher linker safeguard without a tested replacement |
| Android build boundary | Keep AGP, Gradle wrapper, Kotlin, JDK, Flutter Gradle integration, and affected plugins compatible as one host graph | `android/settings.gradle.kts`, `gradle.properties`, wrapper, app build file | Enable AGP 9/Built-in Kotlin while any app/plugin still relies on legacy KGP or old DSL |
| Product data boundary | Prove encrypted data is readable through every upgrade rather than replacing it | key init, `AppDatabase` migration ladder, encrypted backup/restore tests | Generate a new key when an encrypted DB exists, delete an installed production container, or log private records |
| Release/UAT boundary | Create clean release registrants and collect device evidence separately from developer data | `release_preflight.sh`, device E2E, a disposable iPhone test installation | Treat host tests, simulator success, or unsigned build as proof of a physical-device release flow |

### Invariants That Carry Forward

- `main.dart` must call `ensureNativeLibrary()` before `AppInitializer.initialize()`; the initializer’s existing “missing master key + existing encrypted DB = fail closed” rule is non-negotiable.
- `lib/infrastructure/crypto/database/encrypted_database.dart` must still execute a non-empty `PRAGMA cipher_version`; it is the runtime proof that the native SQLCipher library, not plain SQLite, handles the database.
- Keep `AppDatabase.schemaVersion` and historical migration ladders semantically unchanged unless an app data schema change is explicitly required. A package/tool upgrade alone is not permission to bump the application schema.
- Retain SQLCipher pod `4.10.0` and the Podfile post-install removal of `-lsqlite3` until an ADR-approved replacement proves SwiftPM/native symbol behavior on simulator and signed hardware. The current compatibility matrix correctly treats `sqlcipher_flutter_libs 0.6.8` with `sqlite3 2.9.4` as the last proven encrypted route.
- Keep iOS minimum deployment at 15.0 and Android minimum API 24; reject a package whose production-stable line forces a floor increase unless the milestone scope is amended and store/device support is revalidated.

## Execution Sequence and Phase Recommendation

The next roadmap should continue after v2.0 (Phases 57–63 suggested). Each phase produces a reviewable commit and a green recovery point; proceed only from a tagged or otherwise recorded green SHA.

| Suggested phase | Goal and exit condition | Atomic lane / why it cannot be split | Rollback point |
|---|---|---|---|
| **57 — Baseline evidence and candidate manifest** | Capture `flutter --version`, Dart, Xcode, CocoaPods, Java, Gradle, Android SDK, `pod --version`, resolved graph, warning inventory, and baseline gate results. Research only official stable releases, make an allow/hold table, and add/update a machine-checked manifest. | None; this freezes the control result used for every comparison. | No runtime change; revert only documentation/contract commit if evidence is wrong. |
| **58 — Flutter/Dart solver and codegen/analyzer compatibility** | Select one Flutter stable SDK; resolve and test the analyzer/custom-lint/import-guard/Riverpod/Freezed/JSON/Drift-generator set together; run generation and fix source compatibility. | **Atomic:** analyzer, `custom_lint`, `import_guard_custom_lint`, `riverpod_lint`, Riverpod runtime/annotation/generator, JSON annotation/serializer, Freezed/build_runner/Drift dev. They share analyzer/build APIs and generated source. | Commit A: SDK + constraints/lock + compatibility contract. Commit B: hand-written adaptation + regenerated source. Revert both together if generated APIs or lint enforcement cannot pass. |
| **59 — Pure Dart and Flutter package windows** | Upgrade only packages with no native-project, SQLCipher, or solver-lane coupling; characterize affected public behaviors before each cohort. | Cohorts are atomic per observable contract: `file_picker` + `share_plus` + `package_info_plus` + `win32`; speech package + voice adapter/tests; notification packages + their initialization/routing tests. | One cohort per commit after a clean solve. Revert the whole cohort, never a single member that reintroduces an unsatisfied `win32` or adapter graph. |
| **60 — Encrypted native database and iOS dependency resolution** | Regenerate iOS artefacts cleanly and prove SQLCipher linkage, old-schema upgrade, encrypted reopen, and backup restore on simulator before hardware. Prefer SwiftPM for plugins that supply manifests; retain only documented CocoaPods SQLCipher fallback. | **Atomic:** `sqlcipher_flutter_libs`, `sqlite3`, native asset/linker settings, Podfile/lock, Xcode package references, encrypted executor, and database migration tests. Their only valid result is a working encrypted backend. | Commit A: chosen native graph / Podfile / Xcode project / lock. Commit B: any executor or migration-test changes. If `cipher_version` is empty or existing data cannot reopen, restore both commits immediately; do not ship a plaintext fallback. |
| **61 — Android host toolchain migration** | Upgrade AGP, Gradle wrapper, Kotlin/JDK, Android SDK targets, Flutter Gradle integration and affected plugin fleet as allowed by the selected Flutter stable. Only then migrate to AGP 9 Built-in Kotlin/new DSL. | **Atomic at AGP 9:** flags, KGP removal/migration, old DSL usage in app and plugins, wrapper/AGP compatibility, and debug/release builds. Flutter says legacy KGP support is temporary, so a half-migrated fleet is not a final state. | Commit A: toolchain versions/flags and compilation fixes. Commit B: package/plugin changes needed by that toolchain. Keep the last AGP 8 green commit until both debug/release and device E2E pass. |
| **62 — Reproducible release and automated-gate hardening** | Make CI use the exact stable SDK and lockfile; run codegen stale-diff, analysis/custom-lint/architecture gates, full tests/coverage, Android release preflight, iOS unsigned release preflight, Android emulator and iPhone-simulator E2E, and future beta early warning. | **Atomic:** gate implementation plus architecture tests that assert it. A gate without its contract test is accidental policy; a test without the actual CI step is no protection. | One commit for CI/scripts and their test coverage. Roll back an overly strict new gate only with a replacement that still verifies the same invariant. |
| **63 — Isolated wired-iPhone UAT and final compatibility lock** | Install a development-signed test build on one wired iPhone under a **different explicit bundle ID**, execute the critical journey, record redacted evidence, then lock versions and rationale. | **Atomic:** test configuration, App ID/provisioning, entitlements, test install, and UAT record. The test identity must not share the production app container. | Test config is additive and removed/disabled only after UAT. Production bundle ID, production provisioning, installed production app, and production data are never modified for UAT. |

### Dependency Graph and Ordering Rationale

```text
57 baseline / official-version decision
       |
       v
58 SDK + solver + generation -------------------+
       |                                         |
       v                                         v
59 pure Dart/Flutter cohorts               60 SQLCipher + iOS native graph
       |                                         |
       +-------------------+---------------------+
                           |
                           v
                  61 Android host migration
                           |
                           v
                  62 automated release gates
                           |
                           v
                    63 wired iPhone UAT
```

Phase 58 precedes all package cohorts because Flutter’s SDK pins Dart and constrains pub resolution. Phase 60 follows the solver so the native artefacts come from the exact final package graph; it must precede final gates because encryption validity cannot be inferred from host VM tests. Android and iOS host work are separable in code but converge at the lockfile and release gates; make Phase 61 sequential after Phase 60 in this milestone to keep one known-good native rollback point. UAT is last because it validates the candidate that CI will actually build, not an earlier transient graph.

## Atomic Upgrade Rules

| Lane | Required members | Required proof before merging | Current safe decision if no compatible stable exists |
|---|---|---|---|
| Code generation and static analysis | Flutter/Dart SDK, analyzer, build_runner, Freezed, json_serializable/annotation, Drift dev, Riverpod runtime/annotation/generator/lint, custom lint/import guard | Clean `flutter pub get`; generation; no diff in `lib/`; `flutter analyze`; custom lint; architecture suite; full tests | Keep the proven graph and document the blocker. Never force via `dependency_overrides` or an analyzer pin. |
| File/share/metadata | `file_picker`, `share_plus`, `package_info_plus`, `win32` | Solver plus single-`.hpb` import and platform share-sheet assertions | Hold the whole group; do not pull one package onto an incompatible `win32` major. |
| Speech | `speech_to_text` plus platform adapter and ja/zh/en parser tests | Host language matrix, Android microphone/iOS speech permission behavior, real-device voice check if adapter/native API changes | Keep exact 7.3.0 until a stable compatible release is verified; do not adopt a beta-origin 7.4.0 line. |
| SQLCipher | SQLCipher plugin, sqlite3 API, Podfile/lock, SwiftPM/CocoaPods configuration, executor and migration testing | Non-empty cipher pragma, close/reopen, migration ladder, encrypted backup/restore on simulator and wired iPhone | Keep 0.6.x + sqlite3 2.x and record it as intentionally latest *supported*, not cosmetically latest. |
| Android AGP 9 | Flutter SDK, AGP, Gradle wrapper, Kotlin/KGP removal, `android.builtInKotlin`, `android.newDsl`, affected plugins | App and plugin migration review, debug + release compilation, emulator E2E | Remain on the selected AGP 8 compatible window with the two false flags and beta early-warning workflow. |

## Generated Artefact and Lockfile Strategy

1. Do not manually edit `pubspec.lock`, `*.g.dart`, `*.freezed.dart`, Drift generated files, `lib/generated/`, Flutter plugin registrants, `Pods/`, or DerivedData.
2. For any package or SDK change, start from a clean worktree and use the selected SDK to run `flutter clean`, `flutter pub get`, `flutter gen-l10n`, and `flutter pub run build_runner build --delete-conflicting-outputs`. Commit intentional generated source with its input/lockfile change; never commit ignored Pods, build folders, or generated registrants.
3. Use `dart pub get --enforce-lockfile` for candidate/release reproduction after the reviewed `pubspec.lock` is committed. Dart documents the lockfile as the resolved graph and warns that `dependency_overrides` can break declared compatibility; allow an override only in an ignored local probe, never in the release manifest.
4. Preserve `scripts/release_preflight.sh`’s temporary iOS manifest technique: it removes dev-only `integration_test` solely for release-native registrant generation, restores the developer manifest/lock in its trap, and scans the resulting Runner binary. A release build must never include the integration-test plugin.

## Data Safety and Device UAT Design

### Isolated iPhone configuration

Create a development-only Xcode configuration/scheme (for example `DeviceUAT`) whose `PRODUCT_BUNDLE_IDENTIFIER` is an explicit, unambiguous suffix such as `com.sheanzero.happypocket.app.deviceuat`. Register that **separate App ID**, enable only the capability set needed for the UAT, and let Xcode automatic signing create a development profile for the connected phone. Keep its values out of the production Release configuration and add an architecture/configuration test that asserts the UAT ID differs from production.

Apple’s documentation requires an explicit App ID to match the target’s bundle ID; it also says automatic signing can register a connected physical device and generate its development profile. A different bundle ID creates a separate iOS app container, which protects the user’s installed production database, secure-storage namespace, preferences, and notifications from test installation/deletion. Do not change the production ID `com.sheanzero.happypocket.app`, overwrite its profile, or run destructive restore/delete-all against it.

### Mandatory wired-iPhone record

Use temporary test data and a disposable encrypted `.hpb`, then document device model, iOS version, Xcode/Flutter versions, selected dependency lock SHA, UAT bundle ID, build configuration, date/time, pass/fail, and redacted screenshots/logs. Do not record transaction text, amounts, encrypted files, PINs, key material, recovery data, APNs/FCM token, relay payload, or device UDID.

The required flow is:

1. Install isolated build, fresh onboarding, and one normal ledger entry; terminate and cold relaunch.
2. Assert SQLCipher is active (`PRAGMA cipher_version` non-empty), close and reopen the same encrypted file, and execute the historical-schema migration ladder used by the app’s integration tests.
3. Export an encrypted backup, delete only the **test** ledger data, import it, and verify the entry after another cold relaunch.
4. Enable PIN and, where enrolled, Face ID; background/terminate/reopen; verify both supported unlock paths and no lock loop.
5. Exercise the critical sync/push-facing route appropriate to the available non-production environment without exposing payload data; record unavailable provider credentials as a UAT limitation, not as a pass.
6. Capture startup and interaction observations against the existing performance baseline; reject material regression with an explained, reproducible measurement rather than subjective impressions.

`integration_test/device_critical_journey_test.dart` already isolates its key store, preferences, identity, database directory, and PIN in test fixtures. Preserve that pattern; CI’s simulator/emulator suite is a prerequisite, while Apple explicitly notes that simulators do not replicate a physical device and physical-device execution is the verification step for intended behavior.

## Patterns to Follow

### Pattern 1: Compatibility contract co-evolves with the lockfile

**What:** Move `pubspec.yaml`, `pubspec.lock`, `docs/testing/DEPENDENCY_COMPATIBILITY.md`, `scripts/dependency_compatibility.dart`, and its contract test together for every exceptional pin or lane change.

**When:** Every version change, every hold removal, and every native package manager change.

**Why:** The repository already fails closed on stale expectations. Updating only the manifest leaves CI contradictory; updating only the script launders an unreviewed graph.

### Pattern 2: Native changes start from a clean generated state

**What:** `flutter clean` → resolve graph → regenerate code/resources when inputs changed → platform build/preflight → native integration tests.

**When:** Any plugin/native asset/SDK/Pod/Gradle change, and before iOS physical-device verification.

**Why:** This project has documented stale native-asset and dev-only registrant contamination risks. A clean build proves the candidate, rather than cached Pods or simulator/device framework remnants.

### Pattern 3: Security invariant is tested at the native execution point

**What:** Treat a non-empty SQLCipher pragma plus encrypted reopen/migration/backup restore as the acceptance boundary.

**When:** Every native database or iOS package-manager change.

**Why:** Host tests use a different SQLite execution path and cannot prove the application’s actual encrypted native linkage.

## Anti-Patterns to Avoid

### Blanket major upgrade

**What:** Run `flutter pub upgrade --major-versions`, accept the solver, then repair scattered errors.

**Why bad:** It destroys causal attribution across analyzer, codegen, plugins, Gradle and iOS link resolution, and can select a graph that compiles while losing SQLCipher on device.

**Instead:** Upgrade one documented lane at a time, with an atomic commit and a complete gate set.

### Superficial “latest” SQLCipher upgrade

**What:** Replace the proven encrypted plugin with `sqlcipher_flutter_libs 0.7.0+eol`, `sqlite3_flutter_libs`, or system SQLite merely to increase version numbers.

**Why bad:** The current repository contract documents that `0.7.0+eol` carries no native library and the Podfile strip prevents system SQLite from winning symbols.

**Instead:** Treat functional, verified encryption as the version-selection criterion and retain the proven lane until a reviewed replacement meets the full device proof.

### Global switch away from CocoaPods

**What:** Disable SwiftPM or delete all CocoaPods plumbing because Flutter now prefers SwiftPM.

**Why bad:** Flutter supports a hybrid transition; this project’s SQLCipher native dependency is the explicit remaining CocoaPods exception.

**Instead:** Keep SwiftPM enabled for capable plugins and CocoaPods narrowly scoped to SQLCipher until a SwiftPM-capable, device-verified path exists.

### Production-device test installation

**What:** Change the production Runner bundle ID/configuration in place, or run test backup/restore using an installed user’s data.

**Why bad:** It risks data loss and can alter provisioned capabilities/profile state.

**Instead:** Use an additive, explicitly provisioned UAT configuration with separate App ID and disposable test data.

## Scalability Considerations

| Concern | Current milestone scale | Future release scale | Architectural response |
|---|---|---|---|
| Dependency drift | One app and a single lockfile | More plugins / platform SDK changes | Keep a machine-readable compatibility contract plus weekly beta probe; promote warnings before they become stable blockers. |
| Generated source | Multiple generators in one library tree | More feature modules and generated files | One reproducible generator command and a blocking stale-diff; keep generated source tied to inputs. |
| Native package management | SwiftPM with one SQLCipher Pod fallback | CocoaPods registry/read-only deadline and plugin migration | Reduce the fallback only through an ADR-approved, hardware-verified replacement; never remove it globally first. |
| Device evidence | One wired iPhone, CI simulator/emulator | Store release / more real devices | Preserve redacted UAT templates and a non-production bundle configuration; expand coverage by adding scenarios, not by sharing production containers. |

## Sources

- [Flutter: built-in Kotlin migration overview](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin) — MEDIUM confidence (official primary source; cross-checked against app configuration and Flutter 3.44 compatibility contract).
- [Flutter: Built-in Kotlin migration for app developers](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers) — MEDIUM confidence.
- [Flutter: Swift Package Manager and CocoaPods transition](https://docs.flutter.dev/add-to-app/ios/project-setup?tab=embed-using-cocoapods) and [plugin native dependency guidance](https://docs.flutter.dev/packages-and-plugins/developing-packages) — MEDIUM confidence.
- [Dart: package dependencies](https://dart.dev/tools/pub/dependencies), [lockfiles/versioning](https://dart.dev/tools/pub/versioning), and [production package retrieval](https://dart.dev/tools/pub/packages) — MEDIUM confidence.
- [Apple: Register an App ID](https://developer.apple.com/help/account/identifiers/register-an-app-id/), [run on physical devices](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices), and [change a bundle identifier](https://developer.apple.com/documentation/xcode/changing-the-bundle-identifier) — MEDIUM confidence.
- Repository evidence: `docs/testing/DEPENDENCY_COMPATIBILITY.md`, `scripts/dependency_compatibility.dart`, `.github/workflows/{audit,device-e2e,flutter-future-compat}.yml`, `scripts/release_preflight.sh`, `integration_test/device_critical_journey_test.dart`, `lib/infrastructure/crypto/database/encrypted_database.dart` — HIGH confidence for the project’s current constraints.
