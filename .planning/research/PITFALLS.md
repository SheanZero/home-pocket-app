# v2.1 Dependency and Native Toolchain Modernization — Pitfalls

**Domain:** Upgrading a local-first Flutter family-accounting app with SQLCipher, Drift, Riverpod code generation, native plugins, and a required wired-iPhone acceptance run.
**Researched:** 2026-08-05
**Overall confidence:** MEDIUM — the research seam classified the cross-checked official-source findings as MEDIUM. Repository-specific controls were inspected directly.

## Release-blocker criteria

The following are release blockers for v2.1: a missing or empty SQLCipher proof on device; an unreadable existing encrypted DB; failed historical migration or backup restore; a changed production app identity/signing lineage; an unsigned/incorrectly signed release artifact; a code-generation or dependency-contract failure; and iPhone acceptance that does not run the actual isolated signing/entitlement combination.

It is acceptable debt to retain a deliberately pinned compatibility lane or Flutter's temporary legacy Kotlin flags **only** when the executable compatibility contract documents the rationale, the current stable lane is green, and the beta early-warning job remains enabled. It is not acceptable debt to replace encryption with system SQLite, suppress a broken native build warning, or substitute simulator/host results for the required device acceptance.

## Critical Pitfalls

### 1. System SQLite wins the iOS linker race, so SQLCipher silently disappears

**Classification:** Release blocker
**Confidence:** MEDIUM (official SQLCipher behavior cross-checked with direct repository implementation)

**What goes wrong:** A Pod such as FirebaseMessaging contributes `-lsqlite3`; iOS resolves `sqlite3_*` symbols from the system library instead of SQLCipher. The Dart API still opens a database, but `PRAGMA cipher_version` returns no row and encryption is unavailable. A host `flutter test` cannot prove this path because it intentionally uses plain system SQLite.

**Why it happens:** SQLCipher is a SQLite source-level build, not a runtime-loadable extension; it needs its own compiled SQLite symbols. A seemingly harmless Pod update, a regenerated Pods project, or removal/narrowing of the Podfile strip can reintroduce the system library.

**Warning signs:** `cipher_version` empty on simulator/device; `SQLCipher not loaded - encryption unavailable`; a new `-lsqlite3` in Pods xcconfig/link output; a database opens in host tests but fails after signing/installing iOS.

**Prevention:** Keep the Podfile post-install strip that removes system `sqlite3` from Pod xcconfigs; do not add `sqlite3_flutter_libs`; retain the `sqlcipher_flutter_libs 0.6.8`/`sqlite3 2.9.4` compatibility lane unless a reviewed replacement has passed the full device matrix. Preserve the runtime `ensureNativeLibrary()` path before encrypted executor creation.

**Detection:** Run `dart run scripts/dependency_compatibility.dart`; inspect the final pod lock and linker inputs after `pod install`; on the wired iPhone create/open/close/reopen the encrypted database and assert a non-empty `PRAGMA cipher_version` without logging keys, transaction data, or payloads.

**Recovery:** Stop the release. Restore the Podfile strip and the verified lockfile, run a clean CocoaPods installation, rebuild the signed test app, and repeat the encrypted reopen plus migration/backup restore acceptance. If an existing file cannot be read, preserve it and its key material; do not delete/reseed or mint a replacement master key.

**Suggested phase:** Phase 1 — compatibility baseline and native dependency lane; repeat in final iPhone acceptance.

### 2. `sqlcipher_flutter_libs 0.7.0+eol` looks newer but contains no functional SQLCipher native library

**Classification:** Release blocker
**Confidence:** MEDIUM (repository compatibility contract; device proof remains decisive)

**What goes wrong:** A blanket `pub upgrade --major-versions` resolves the EOL placeholder or replaces the SQLCipher lane with `sqlite3_flutter_libs`. The project may compile, but encryption cannot be demonstrated or system SQLite becomes the active implementation.

**Why it happens:** Package-version sorting rewards a higher version number and hides that this line is a retirement marker. `sqlite3` 3.x likewise is outside this app's verified encrypted executor path.

**Warning signs:** Lockfile has `sqlcipher_flutter_libs 0.7.0+eol`, a new `sqlite3_flutter_libs` entry, `cipher_version` failure, or CI compatibility-contract failure.

**Prevention:** Treat `sqlcipher_flutter_libs ^0.6.8`, `sqlite3 ^2.9.4`, and the SQLCipher 4.10.0 Pod as an atomic lane. Do not change it for cosmetic version freshness. An eventual replacement requires an ADR, native packaging review, and actual-device encrypted reopen, migration, and backup/restore evidence.

**Detection:** Keep `test/architecture/dependency_compatibility_contract_test.dart` and the CI grep rejection of `sqlite3_flutter_libs` blocking; inspect both `pubspec.yaml` and `pubspec.lock` before generating native artifacts.

**Recovery:** Revert only the dependency resolution/lockfile to the reviewed encrypted lane, clean generated native state, fetch dependencies, and repeat all SQLCipher acceptance. Existing encrypted databases are evidence, never disposable test fixtures.

**Suggested phase:** Phase 1 — lockfile and encrypted database lane.

### 3. Partial Riverpod/Freezed/Drift/JSON/analyzer upgrade breaks generators or weakens architecture linting

**Classification:** Release blocker if generated output or analyzer/lint contract is not green; otherwise no upgrade is preferable
**Confidence:** MEDIUM

**What goes wrong:** Updating `flutter_riverpod`, `riverpod_generator`, `json_serializable`, `build_runner`, `drift_dev`, or `analyzer` independently produces an unsatisfiable Pub graph, stale `.g.dart`/`.freezed.dart`, changed generated APIs, or a custom-lint/import-boundary plugin that no longer executes. `flutter analyze` can be deceptively clean when the expected lint plugin was not loaded.

**Why it happens:** Builders consume analyzer APIs and mutually constrain annotations, generators, runtime packages, and custom lint. The current project deliberately holds analyzer 8.x because the custom lint/import guard is proven on that line; newer runtime/generator candidates require incompatible analyzer lines.

**Warning signs:** Pub solver overrides; analyzer outside the compatibility contract; generated-file diff after build_runner; missing custom-lint diagnostics; Riverpod provider name/API changes; Drift migration generation differs unexpectedly.

**Prevention:** Upgrade one resolved toolchain lane at a time and never add a forced analyzer override. First establish a common analyzer line for `custom_lint`, `import_guard_custom_lint`, Riverpod runtime/annotation/generator/lint, JSON annotation/serializer, Freezed, Drift/Drift dev, and build_runner; then update sources and generators together.

**Detection:** Run `flutter pub get`, `dart run scripts/dependency_compatibility.dart`, `flutter pub run build_runner build --delete-conflicting-outputs`, `flutter gen-l10n`, `flutter analyze`, `dart run custom_lint --no-fatal-infos`, architecture tests, and assert no generated `lib/` diff. Run migration tests after Drift generator output changes.

**Recovery:** Return the whole lane to the last coherent lockfile (not one arbitrary package), remove only generated artifacts that build_runner regenerates, regenerate, and compare the output before retrying a coordinated lane upgrade. Do not hand-edit generated files to mask the mismatch.

**Suggested phase:** Phase 2 — Dart/Flutter and code-generation lane after the encrypted baseline.

### 4. AGP 9 / built-in Kotlin / new Android DSL migration is enabled before every plugin has migrated

**Classification:** Release blocker for Android release build; acceptable temporary debt while flags and early warning remain
**Confidence:** MEDIUM

**What goes wrong:** Enabling `android.builtInKotlin=true`, removing `kotlin-android`, or enabling the new DSL with an old app/plugin combination fails Gradle configuration or native plugin compilation. Updating AGP, Gradle wrapper, Kotlin, Java target, compile/target SDK, and Flutter together magnifies the failure surface.

**Why it happens:** Flutter 3.44 introduced a temporary legacy bridge. Its current official migration guidance says AGP 9 needs built-in Kotlin and the new DSL, but also says Flutter will remove the legacy KGP/DSL support in a future release. The bridge is not proof that a random mixed version set is compatible.

**Warning signs:** Flutter's KGP/DSL warnings grow or become errors; plugin Kotlin source fails; Gradle cache errors after a version switch; `android.builtInKotlin`/`android.newDsl` are changed without a full plugin audit.

**Prevention:** On the present lane retain AGP 8.11.1, Gradle 8.14, Kotlin 2.2.20, Java 17, and the two false migration flags. Use the weekly Flutter-beta Android build as an early signal. Perform the actual AGP-9 migration only after Flutter and every native plugin meet the official app/plugin migration requirements.

**Detection:** Run the compatibility contract, debug and release Android builds, targeted notification/speech/file-picker workflows, and the release-signing contract. Treat beta CI failure as planning work, not a release-time surprise.

**Recovery:** Restore the last working Android lane atomically, invalidate only the generated build outputs through `flutter clean`, run `flutter pub get`, and rebuild. File/track the failing plugin instead of suppressing the warning or pinning a hidden local artifact.

**Suggested phase:** Phase 3 — Android native toolchain lane, after code generation is stable.

### 5. SwiftPM/CocoaPods hybrid migration drops SQLCipher fallback or leaves stale native assets/signatures

**Classification:** Release blocker
**Confidence:** MEDIUM

**What goes wrong:** Flutter 3.44 defaults iOS/macOS plugin dependency resolution to Swift Package Manager and falls back to CocoaPods for plugins without SwiftPM support. Removing CocoaPods wholesale breaks SQLCipher; incomplete Xcode project migration omits `FlutterGeneratedPluginSwiftPackage`. Conversely, changing a native plugin then switching simulator/device or unsigned/signed builds can leave stale frameworks, registrants, Swift packages, or code signatures, producing device-only install/load failures.

**Why it happens:** Two package managers now contribute to one app. DerivedData/Pods/.symlinks/native assets and Flutter-generated registrants retain outputs whose validity depends on platform, architecture, build mode, and signing identity.

**Warning signs:** `FlutterGeneratedPluginSwiftPackage` missing from Runner dependency/frameworks; `pod install` changes SQLCipher unexpectedly; `CodeSign`/embedded framework errors; stale plugin symbols; simulator success but signed iPhone install fails; release binary contains dev-only `integration_test` registrant code.

**Prevention:** Keep SwiftPM enabled and CocoaPods scoped to the SQLCipher fallback until a reviewed SQLCipher SwiftPM replacement exists. Preserve the project/scheme SwiftPM integration. After every native plugin, package-manager, device/simulator, or signing-mode change, use the clean rebuild protocol from AGENTS.md; use `scripts/release_preflight.sh` to regenerate registrants and scan release artifacts.

**Detection:** Check `Package.resolved`, Podfile.lock, Xcode target dependencies, `flutter run`, unsigned release smoke build, and the actual signed isolated iPhone build. Verify the preflight's dev-only registrant scan and runtime SQLCipher reopen.

**Recovery:** Stop packaging; clean Flutter outputs and iOS Pods/Podfile.lock/.symlinks following the documented clean-rebuild procedure, restore the reviewed Pod/SwiftPM locks, run `flutter pub get` and `pod install`, then create a fresh signed device build. Never attempt to patch a framework signature in place.

**Suggested phase:** Phase 4 — iOS package manager and signed-device preflight.

### 6. Minimum OS version or plugin deployment targets drift and turn a build upgrade into an install/runtime regression

**Classification:** Release blocker if iOS 15+ or Android 7+ support changes without an approved product decision; otherwise acceptable documented constraint
**Confidence:** MEDIUM

**What goes wrong:** A newer native plugin raises its iOS deployment target, Android minSdk, Java/NDK requirement, or permission manifest behavior. The app still compiles on the CI simulator but rejects an older supported device, crashes on a conditional native API, or changes the App Store/Play support footprint without a decision.

**Why it happens:** Project values are inherited from `flutter.*` for Android and must agree across Podfile, Xcode build settings, Pods, and plugin manifests for iOS. Plugin release notes and build tooling can move these floors indirectly.

**Warning signs:** Pod warnings that deployment target is below a Pod's minimum; changed `IPHONEOS_DEPLOYMENT_TARGET`, `platform :ios`, `minSdk`, `targetSdk`, Java target, or Gradle compatibility warning; device install says OS version unsupported.

**Prevention:** Make iOS 15.0 and Android 7+ a compatibility acceptance criterion. Diff all deployment floors after `pub get`, `pod install`, and Gradle upgrade. Do not resolve an iOS Pod conflict by globally raising `IPHONEOS_DEPLOYMENT_TARGET`; either keep the proven dependency or obtain a product/ADR decision.

**Detection:** CI/simulator builds plus one iOS 15-compatible physical device where available; inspect `Podfile`, project.pbxproj, app Gradle configuration, generated Pod settings, and resulting IPA/APK manifests. Confirm the wired test iPhone meets, but does not redefine, the supported floor.

**Recovery:** Revert the incompatible plugin/toolchain lane or choose an officially supported older version; if raising the floor is approved, update product requirements, store availability, documentation, and testing matrix before shipping.

**Suggested phase:** Phase 3 (Android) and Phase 4 (iOS), as a shared acceptance checklist.

### 7. Isolated test Bundle ID or entitlement changes make the app appear to lose its master key/app-lock PIN

**Classification:** Release blocker for iPhone acceptance validity; not a production-data-loss finding by itself
**Confidence:** MEDIUM

**What goes wrong:** The required wired iPhone test uses an isolated Bundle ID. Apple's application identifier is team ID plus bundle ID and becomes the default Keychain access group. Unless Keychain Sharing is intentionally configured, the isolated app cannot read production app keychain entries. A test run may therefore show `masterKeyMissingWithData`, fresh onboarding, missing PIN, or app-lock behavior unlike production. Conversely, accidentally installing a test build over production with the same identity can exercise real data without an isolation plan.

**Why it happens:** Bundle ID, team, provisioning profile, Keychain access group, capabilities, and entitlements are coupled at code-sign time. Apple invalidates provisioning profiles when relevant App ID capabilities change; the repository's `Runner.entitlements` is presently empty, so any new capability is especially meaningful.

**Warning signs:** `errSecMissingEntitlement`, `errSecItemNotFound`, initialization's existing-data/missing-key guard, a device requiring re-enrollment or new PIN unexpectedly, provisioning/profile mismatch, or Xcode selecting an unintended team.

**Prevention:** Define an explicit isolated acceptance identity: its Bundle ID, team, App ID/capabilities, entitlement file, Firebase configuration if applicable, signing profile, and expected clean Keychain state. Do not claim isolated-ID behavior proves production upgrade data continuity. Keep a separate, controlled in-place production-identity upgrade test when release approval requires continuity evidence.

**Detection:** Before install, inspect the signed app's entitlements and provisioning profile; record the bundle identifier shown by the device; test cold start, secure-storage initialization, app-lock setup/unlock, background resume, uninstall/reinstall behavior, and intentional absence of production secrets. Test profile regeneration after any App ID capability change.

**Recovery:** Do not generate a new master key over an existing database. Remove only the isolated test app/data, repair the profile/entitlements, and reinstall. For production identity, preserve the database and keychain state, restore the previous signing/entitlement configuration, and investigate from a copied device backup/test fixture.

**Suggested phase:** Phase 4 — iOS signing identity design; Phase 6 — wired iPhone acceptance.

### 8. Schema migrations or backup restore pass unit tests but lose real encrypted data or sync consistency

**Classification:** Release blocker
**Confidence:** MEDIUM (direct repository migration/restore controls plus official SQLCipher migration guidance)

**What goes wrong:** A Drift/SQLite/SQLCipher upgrade changes table/index behavior, keying parameters, WAL behavior, generated SQL, or serializer defaults. A database can open but omit an index, fail only on an old schema rung, corrupt/replace data during restore, or resume sync before post-restore cleanup. Backup import has a cross-store atomicity problem: database transaction and preferences/key settings do not share a single native transaction.

**Why it happens:** The app is schema version 36 with a historical migration ladder. Drift's custom index declaration is not automatically materialized by its migrator, so the repository deliberately creates indexes in both fresh and upgrade paths. SQLCipher also requires care when old encryption defaults need migration; its official `cipher_migrate` is an expensive, one-time recovery path after failed keyed access, not a startup action.

**Warning signs:** Historical ladder tests fail; `PRAGMA user_version` differs; missing index/table after upgrade; old encrypted fixture cannot reopen; backup restore fails after partial settings writes; sync resumes before cleanup; current-data records vanish or duplicate.

**Prevention:** Keep every historical migration test and run the encrypted executor ladder on device, not only `AppDatabase.forTesting()`. Preserve initialization order: master key before encrypted DB; never create a fresh key when data exists. Preserve restore sequencing (suspend pull, validate/decrypt, atomically replace DB with compensating settings rollback, reset/resume sync). Use versioned real encrypted fixtures for pre-upgrade, not only freshly created current-schema data.

**Detection:** Run all migration tests, import/export and resource-limit/atomicity tests, and a device E2E sequence: install prior fixture/build, create transactions, upgrade, close/reopen, migrate, verify row/index counts and encrypted content, export, restore into nonempty data, confirm rollback on a deliberately bad backup, then check the core accounting and sync flows.

**Recovery:** Halt rollout. Preserve the original encrypted file and keychain key, prevent automatic reseeding, ship a tested forward repair or rollback build, and restore from an encrypted backup only after proving the backup on a copy. Never call SQLCipher migration on every startup; only attempt it as a designed, measured recovery path with a verified result.

**Suggested phase:** Phase 5 — data preservation and migration/restore acceptance, before user-facing final validation.

### 9. Release signing and generated registrants differ from the test artifact

**Classification:** Release blocker
**Confidence:** MEDIUM

**What goes wrong:** Android debug/profile compiles without release credentials; iOS simulator builds are unsigned/differently signed. Generated plugin registrants can include dev-only `integration_test` after device test runs, and then cause a release compilation or artifact-hygiene failure. A passing normal test suite therefore says little about the actual AAB/IPA.

**Why it happens:** Signing is intentionally external to version control. Android's release key, alias, and certificate are resolved at build time; iOS provisioning profiles bind bundle ID, certificates, registered devices, and capabilities. Flutter-generated registrants vary with the resolved pubspec/native build scope.

**Warning signs:** Android release build reports missing credentials or debug certificate; iOS archive cannot install; production artifacts contain `integration_test`; a release build passes only after manually editing registrants; device sees a different app identity than expected.

**Prevention:** Run `scripts/release_preflight.sh` as the authoritative clean state transition. Preserve its temporary iOS manifest scope that excludes native `integration_test` from shipping artifacts; never hand-edit registrants. Android release packaging must depend on its signing verification task and reject the debug certificate. iPhone acceptance must use the same intended test signing configuration rather than an Xcode-default accidental profile.

**Detection:** Execute release preflight with regeneration when inputs changed, verify generated registrants and binary scan, run Android `verifyReleaseSigning`/release packaging, inspect iOS provisioning/signing in Xcode, and install the exact signed iPhone artifact.

**Recovery:** Regenerate from a clean dependency state, fix credentials/profile/certificate selection, rebuild a fresh artifact, and retest installation. Do not suppress signing failures or distribute a debug-signed surrogate.

**Suggested phase:** Phase 4 — release-artifact preflight; Phase 6 — acceptance uses produced artifacts.

### 10. Cold-start and interaction numbers are measured in debug/simulator mode and accepted as performance proof

**Classification:** Release blocker only if performance is a v2.1 acceptance claim; otherwise acceptable debt if reported as unbaselined, never as a pass
**Confidence:** MEDIUM

**What goes wrong:** Debug/JIT builds, simulator hardware, warmed caches, a tiny seed dataset, or an uncontrolled device produce flattering or noisy startup/interactions. The upgrade may regress encryption/key derivation/native loading but report “fast” because it was tested in the wrong mode.

**Why it happens:** Debug mode adds assertions/JIT behavior and simulators/emulators do not represent mobile device performance. Cold-start work is especially sensitive to prior process state, secure-storage state, SQLCipher file/cache state, and the first generated/native load.

**Warning signs:** Results lack device model, OS, build mode, dataset, run count, baseline ID, and cold-start procedure; performance obtained from iOS simulator/debug; a `baseline_required` result interpreted as green; secrets appear in profiling/log output.

**Prevention:** Use the repository's explicit-device benchmark script in `--profile` (and release where required) mode, fixed 1k/10k dataset, named baseline, and a documented cold-start reset procedure. Collect only timing/count telemetry; do not log amounts, merchant names, notes, keys, or backup contents. Treat thresholds with no reviewed baseline as `baseline_required`, not passed.

**Detection:** Check raw JSON/log metadata and `performance_gate.dart` status; run the launch, unlock, transaction-save, encrypted reopen, backup-export/restore path on the wired iPhone under profile mode. Compare p95 to a reviewed same-device baseline and use DevTools startup profile only as diagnostic evidence.

**Recovery:** Discard incomparable numbers, remeasure under a stable protocol, then diagnose traces. If the upgrade regresses the baseline, defer the offending lane or optimize it with a targeted benchmark; do not simply increase thresholds.

**Suggested phase:** Phase 6 — device performance acceptance after data safety checks.

### 11. Automation passes but a physical iPhone fails permissions, lifecycle, hardware auth, or encrypted native loading

**Classification:** Release blocker
**Confidence:** MEDIUM

**What goes wrong:** Host tests mock secure storage and local authentication; simulator builds do not prove profile/release device behavior; CI lacks a physical Keychain, Face ID/PIN enrollment, real signing profile, or production native loader. App lock may relock incorrectly around the OS biometric sheet, background privacy mask may leak, or an actual cold start may fail SQLCipher reopen.

**Why it happens:** These are platform services with hardware, entitlements, and lifecycle transitions that unit tests intentionally isolate. The app's current unit tests correctly cover guards, but the scope explicitly requires a wired iPhone to close the remaining evidence gap.

**Warning signs:** Test doubles are the only secure-storage/biometric evidence; no signed-device install record; AppLifecycle `inactive`/`paused` path untested on a real biometric sheet; SQLCipher prove-open is only a host result.

**Prevention:** Treat device UAT as an independent release gate. Use the isolated identity procedure from Pitfall 7 and test: install/start, master-key/SQLCipher create-close-reopen, historical migration, encrypted backup export/restore, lock setup/PIN/Face ID fallback, lifecycle background/resume and switcher privacy, core transaction create/edit, sync-related regression smoke, and profile-mode startup/interaction measurement.

**Detection:** Keep a written UAT ledger with artifact hash/version, device model/iOS version, Bundle ID/team/profile, exact expected/actual results, screenshots that exclude sensitive data, and the nonempty `cipher_version` assertion. A skipped, blocked, or substitute simulator step is a failed release gate until rerun on device.

**Recovery:** Mark the lane blocked, preserve logs with secrets redacted, reproduce on the same identity/device, then make the smallest rollback or fix and repeat the full affected device sequence. Do not close the issue with a unit-test-only regression test.

**Suggested phase:** Phase 6 — final wired iPhone release acceptance.

## Moderate Pitfalls

### 12. Coordinated file/share/package-info upgrade alters backup import semantics

**Classification:** Release blocker if backup import/export changes; otherwise acceptable pinned debt
**Confidence:** MEDIUM

**What goes wrong:** Updating `file_picker`, `share_plus`, `package_info_plus`, and their `win32` transitives independently may force incompatible Windows/native package constraints or change picker defaults. Backup restore may accept multiple/unexpected files instead of exactly one `.hpb`, or export may no longer open the platform share sheet.

**Why it happens:** These plugins share transitive native constraints while the app depends on a precise backup-file selection contract; a Pub resolution proves neither picker UI nor platform sheet behavior.

**Warning signs:** `win32` resolution changes while only one plus plugin moved; a picker permits more than one file or a non-`.hpb` selection; export completes but no platform share sheet appears.

**Prevention:** Keep the verified `file_picker 11.0.3` / `share_plus 12.0.2` / `package_info_plus 9.0.1` / `win32 5.15.0` group together until a stable, reviewed file_picker lane exists. Manually check one-file `.hpb` selection and share sheet after every group upgrade.

**Detection:** Compatibility contract, backup widget/use-case tests, Android and iOS manual export/import.

**Recovery:** Restore the full group lockfile and rerun backup round-trip; do not silently broaden accepted file selection.

**Suggested phase:** Phase 3/4 with native plugin lanes; revalidate in Phase 5.

### 13. Native notification/speech plugin refresh builds but regresses real permission and cold-start paths

**Classification:** Release blocker for a release that claims notifications/voice continue to work; otherwise explicit deferred debt
**Confidence:** MEDIUM

**What goes wrong:** Firebase Messaging, local notifications, or `speech_to_text` update native manifests/SDK calls. Tests can mock their Dart facade while real microphone permission, APNs/FCM registration, foreground routing, cold-start notification tap, or stale Kotlin native symbols fail.

**Why it happens:** Native plugin packages own OS manifest, permission, platform-channel, and service-lifecycle details that ordinary Dart tests do not exercise; this project already treats the present speech version as an adapter-compatible exact pin.

**Warning signs:** Native build warnings/errors after a plugin switch; a real device denies or never presents microphone permission; notification registration/tap callback lacks expected signed-device evidence; a clean build fixes a stale-symbol error.

**Prevention:** Hold the exact speech version until a stable compatible release and clean after native plugin change. Verify Firebase/notification flows and device microphone/speech on their applicable platforms; the iPhone-only v2.1 gate cannot certify Android real-device behavior, so record Android device verification as release follow-up if the lane changes there.

**Detection:** Build both platforms, run unit/widget tests, and collect real signed delivery/permission evidence where the plugin changed.

**Recovery:** Revert the affected native plugin lane, clean outputs, and rerun native acceptance. Do not call Android CI compilation proof of push delivery.

**Suggested phase:** Platform-specific lane phases; make Android real-device gap visible in final release notes if intentionally deferred.

## Phase-Specific Warnings

| Recommended phase | Likely pitfall | Required mitigation / exit evidence |
|---|---|---|
| 1. Compatibility baseline | SQLCipher placeholder/mixed SQLite, undocumented pins | Lockfile + dependency contract green; no forbidden package; preserved Podfile strip |
| 2. Dart and codegen lane | Analyzer/builder/linter mismatch | Resolver is coherent; regenerate outputs/l10n; analyze, custom lint, architecture gates, and migration tests green |
| 3. Android lane | Premature AGP 9/Kotlin/DSL, minSdk/signing change | Stable Android debug/release build; signing contract; beta workflow remains; no unapproved support-floor drift |
| 4. iOS native/build lane | SwiftPM/CocoaPods split, stale framework/signature, Bundle ID/entitlement mismatch | Clean Pods/SwiftPM rebuild; preflight artifact scan; signed isolated test identity is recorded |
| 5. Data preservation | Old encrypted DB/migration/backup restore loss | Historical encrypted fixture upgrade, close/reopen, row/index checks, backup rollback and restore evidence |
| 6. Wired iPhone acceptance | Device-only Keychain/Face ID/lifecycle/SQLCipher/performance failure | Exact artifact installed; UAT ledger complete; cipher_version nonempty; profile-mode benchmark baselined |

## Accepted Debt Ledger

| Debt | Accept only when | Must not become |
|---|---|---|
| Analyzer 8.x and current Riverpod/JSON/lint lane remain pinned | Compatibility contract, generated files, static/custom/architecture tests are green; a future upgrade is tracked as a coordinated lane | A forced analyzer override or disabled lint |
| Legacy Kotlin/old Android DSL flags stay false | Stable Android builds and Flutter-beta early warning continue; migration scheduled before Flutter removes support | A permanent unsupported configuration hidden by warning suppression |
| SQLCipher 0.6.x remains rather than a superficially newer package | Device SQLCipher proof and documented EOL incompatibility remain valid | System SQLite, `sqlite3_flutter_libs`, or no-op 0.7.0+eol |
| iPhone acceptance uses an isolated Bundle ID | The report labels it as clean-install/identity evidence, not production in-place data continuity | An assumption that it reads production keychain data or proves production upgrade retention |
| Android real-device UAT remains outside this milestone | No Android-native dependency behavior changed beyond build-verifiable work, and the gap is documented for release owner | Claiming device-level Android push/speech/keychain proof from CI |

## Sources

### Official primary sources

- [Flutter: Swift Package Manager for app developers](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers) — Flutter 3.44 defaults to SwiftPM, falls back to CocoaPods for unsupported plugins, and identifies the Xcode integration to verify. (MEDIUM)
- [Flutter: migrate Android apps to built-in Kotlin](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers) and [migration overview](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin) — AGP 9 migration requirements and temporary legacy bridge/removal trajectory. (MEDIUM)
- [Dart: build_runner](https://dart.dev/tools/build_runner) — generated output is produced by builder packages and must be regenerated from a resolved dependency graph. (MEDIUM)
- [Flutter: build modes](https://docs.flutter.dev/testing/build-modes) and [performance profiling](https://docs.flutter.dev/perf/ui-performance) — profile mode and a physical device are required for representative mobile performance evidence. (MEDIUM)
- [Apple: sharing Keychain items](https://developer.apple.com/documentation/security/sharing-access-to-keychain-items-among-a-collection-of-apps) and [Keychain access-groups entitlement](https://developer.apple.com/documentation/BundleResources/Entitlements/keychain-access-groups) — the code-signed app identifier/default access-group relationship. (MEDIUM)
- [Apple: provisioning profiles](https://developer.apple.com/help/account/provisioning-profiles/edit-download-or-delete-profiles/) and [registered-device distribution](https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices) — profile/certificate/device/bundle-ID linkage and capability-driven profile regeneration. (MEDIUM)
- [Android: how app updates work](https://developer.android.com/google/play/app-updates) — continuity requires the same application ID and signing keys; otherwise uninstall erases app data. (MEDIUM)
- [SQLCipher API](https://www.zetetic.net/sqlcipher/sqlcipher-api/) and [SQLCipher design](https://www.zetetic.net/sqlcipher/design/) — `cipher_version`, one-off migration behavior, and why SQLCipher is not a plug-in over arbitrary SQLite binaries. (MEDIUM)

### Repository evidence inspected

- `docs/testing/DEPENDENCY_COMPATIBILITY.md`, `scripts/dependency_compatibility.dart`, and its architecture test: current coordinated lanes and fail-closed contract.
- `ios/Podfile`: system SQLite strip explaining the `cipher_version` failure mode; `ios/Runner.xcodeproj/project.pbxproj` and `Runner.entitlements`: iOS 15.0, automatic signing, current identity, and entitlement scope.
- `lib/infrastructure/crypto/database/encrypted_database.dart`: keying and runtime `cipher_version` assertion; `lib/core/initialization/app_initializer.dart`: no-new-key-with-existing-data guard.
- `lib/data/app_database.dart`, `lib/data/app_database_migrations.dart`, `integration_test/merchant_migration_ladder_test.dart`, and migration tests: historical migration/index risks.
- `test/unit/application/settings/import_backup_use_case_atomicity_test.dart` and `restore_backup_use_case_test.dart`: cross-store restore compensation and sync barrier behavior.
- `scripts/release_preflight.sh` and `scripts/performance/*`: artifact hygiene and device/profile measurement controls.

## Research gaps to resolve during planning

- Obtain a concrete production-stable target-version matrix from the version-research agent before choosing any lane; this file intentionally does not recommend a version by numeric freshness.
- Before a SQLCipher lane replacement, get official maintained-plugin/SwiftPM packaging evidence and test it against a real encrypted historical fixture; no current source justifies that change.
- Define whether final release approval additionally requires an in-place production-identity iPhone upgrade test. The required isolated Bundle ID is safer for acceptance but cannot prove continuity of production Keychain data.
