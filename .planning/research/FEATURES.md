# Feature Landscape — v2.1 Dependency & Native Toolchain Modernization

**Domain:** Local-first, privacy-first Flutter family-accounting app (SQLCipher, Drift, Riverpod) undergoing a coordinated production-stable upgrade.
**Researched:** 2026-08-05
**Confidence:** MEDIUM — platform/tool expectations are cross-checked against official Flutter, Apple, and Android documentation; exact final version choices remain a phase-1 compatibility investigation.

## Product Framing

This is not a “make `pub outdated` empty” milestone. Its user-visible product is a *verified compatibility window*: a production-stable Flutter/Dart/native/plugin set whose generation outputs, encrypted on-device data, recovery paths, and essential accounting/sync flows all remain intact. Every changed version must have a resolved, locked, and explainable rationale; a package that is newer but breaks the encrypted native path is not an upgrade.

The existing repository already supplies most of the acceptance harness: a blocking compatibility contract, generated-code clean-diff gate, schema v36 migration tests, an encrypted device critical journey, Android/iOS simulator CI, release-preflight checks, and an opt-in device performance benchmark. v2.1 should consolidate and extend these into one release decision record rather than introduce product features.

## Must-Have Capabilities

These are release-blocking requirements. “Automated” means a committed test/script/CI job with a captured result; “human/device” means dated evidence from the specified target, not an assertion that it was probably tested.

| Suggested requirement | Capability | Observable acceptance evidence | Classification |
|---|---|---|---|
| `UPG-BASE-01` | **Production-stable version baseline and lock**: record the selected Flutter/Dart, native toolchain, direct dependencies, and material transitive versions; commit `pubspec.lock`; explain each intentionally held version. | `flutter --version`, `dart --version`, `pubspec.yaml`, `pubspec.lock`, native wrapper/project versions, and a dated compatibility matrix agree. `flutter pub get` from a clean checkout resolves without overrides that merely force incompatibility. | Functional / release gate |
| `UPG-BASE-02` | **Coordinated compatibility lanes** rather than independent major bumps: SQLCipher/sqlite3; Riverpod/Freezed/Drift/analyzer/custom lint; Android Gradle/Kotlin/SDK; iOS SwiftPM/CocoaPods; constrained platform plugins. | `dart run scripts/dependency_compatibility.dart` passes after its expected versions/rationale are updated; negative contract tests reject forbidden or partial combinations. No `sqlite3_flutter_libs`; no `sqlcipher_flutter_libs 0.7.0+eol`; no unexplained `dependency_overrides`. | Security / compatibility |
| `UPG-GEN-01` | **Reproducible generated artifacts** for Riverpod, Freezed, JSON, Drift, and localization. | From clean generated state: `flutter pub get`, `flutter gen-l10n`, and `flutter pub run build_runner build --delete-conflicting-outputs` complete; `git diff --exit-code lib/` is clean afterwards; `flutter analyze` and custom lint pass. Existing CI’s build-runner clean-diff gate remains blocking. | Quality / reproducibility |
| `UPG-DB-01` | **SQLCipher cold reopen on iPhone**: the production encrypted executor opens, closes, and reopens one isolated database with the same key material. Encryption must be actively proven, not inferred from a successful Drift query. | On the wired iPhone: non-empty `PRAGMA cipher_version` after initial open *and after reopen*; persisted sentinel accounting row remains readable. Test data uses a deterministic non-production master key and an isolated file. | Security / device E2E |
| `UPG-DB-02` | **Historical schema migration preservation**: a DB fixture representing the previously shipped state upgrades to the current schema under the real `onUpgrade` path, with expected data/index/default invariants retained. Maintain host migration coverage for detailed DDL and an encrypted device/simulator ladder for the cipher boundary. | All committed migration tests for v8–v36 pass; the device ladder proves at least the prior release fixture → current schema under SQLCipher, asserts non-empty cipher version, target `PRAGMA user_version`, and critical schema/data checks. Any schema bump adds its migration test in the same change. | Data integrity / regression |
| `UPG-BACKUP-01` | **Encrypted backup export, destructive clear, and password restore** preserve a representative ledger. Compatibility includes the current Argon2id + AES-256-GCM format and supported legacy backup input. | Unit tests cover crypto format, wrong password, and resource limits. Device critical journey exports a `.hpb`, verifies it is non-empty, clears the test ledger, restores it, and verifies the sentinel transaction (amount/category/book as applicable) exactly. | Security / recovery |
| `UPG-LOCK-01` | **App-lock compatibility**: lock enabled + PIN succeeds after cold boot; Face ID/biometric succeeds on the enabled iPhone when available; biometric cancellation/unavailability/enrollment change falls back to PIN without dead end; foreground/resume relock remains correct. | Unit/widget tests remain green for Argon2id PIN KDF, fallback, and lifecycle guards. Wired-iPhone record shows lock setup, biometric success or documented device-unavailable result, PIN fallback, cold launch/reopen to lock screen, and unlock to the unchanged ledger. Never log PINs, hashes, biometric data, keys, or transaction details. | Security / device E2E |
| `UPG-CORE-01` | **Core accounting compatibility**: create and save a manual daily/joy ledger transaction through the real upgraded app path, then read the exact persisted result after restart. | Existing `device_critical_journey_test.dart` (or its successor) drives onboarding/test setup → manual entry → repository assertion → DB close/reopen → same assertion. Full host accounting integration/invariant suite passes. | Functional / data integrity |
| `UPG-SYNC-01` | **Critical sync compatibility without weakening E2EE**: encrypted queue/outbox survives SQLCipher reopen, pull/ack/offline queue behavior still settles correctly, and no production payload/key is recorded in logs or artifacts. | Existing device sync delivery integration test and host sync round-trip/degradation tests pass. If backend transport versions/configuration changed, add a controlled two-device or relay staging result; otherwise state that network delivery is not newly claimed. | Security / integration |
| `UPG-IOS-01` | **Isolated iPhone test identity and data boundary**. A test scheme/flavor uses a distinct Bundle ID from the shipping app; test keychain access group, app container, Firebase/notification configuration, and backup paths are reviewed for that identity. `RunnerTests` already has a separate unit-test Bundle ID, but a device integration runner must not silently install over or read the production app. | Build/install output identifies the test Bundle ID (for example a `.e2e` suffix), device settings show it as separate from the production app, and a pre-existing production app/database remains untouched. Device tests use test-only keys and temporary files. | Privacy / release safety |
| `UPG-IOS-02` | **Wired iPhone acceptance and performance evidence**. Validate the final release/profile-compatible build on one connected iPhone; simulators remain automation coverage but are not performance proof. | Dated UAT record: device model, iOS version, app build/commit, Flutter/Xcode versions, bundle ID, install/launch result, SQLCipher/backup/lock/core-flow results. Capture raw JSON from `scripts/performance/run_performance_benchmark.sh --device … --mode profile|release`; reviewed baseline/threshold evaluation must pass or explicitly return `baseline_required` (never silently pass as a limit). Startup/TTI needs a separate launcher trace because the current in-process benchmark explicitly cannot measure it. | Performance / human device gate |
| `UPG-ANDROID-01` | **Android release build, signing protection, and emulator validation**. Build a release AAB/APK with the upgraded toolchain and run the integration suite on a supported Android emulator. | `flutter build appbundle --release` (with non-debug signing credentials) or documented CI equivalent produces `build/app/outputs/bundle/release/app.aab`; Android signing contract rejects absent/debug credentials; emulator run `flutter test integration_test/ -d <emulator>` passes; release-preflight confirms integration-test plugins do not contaminate release registrants. | Release engineering / automated E2E |

## Nice-to-Have Capabilities

| Suggested requirement | Capability | Value | Evidence | Classification |
|---|---|---|---|---|
| `UPG-NICE-01` | Machine-readable signed/dated upgrade decision manifest containing SDK, plugin, AGP/Kotlin, CocoaPods/SwiftPM, Xcode, Java, Gradle, and resolved transitive versions. | Makes the next upgrade/audit diffable and lowers incident triage time. | CI artifact plus a concise checked-in matrix. | Documentation / reproducibility |
| `UPG-NICE-02` | Upgrade smoke matrix across iOS Simulator and Android emulator for both fresh-install and upgrade-in-place fixtures. | Finds platform-specific registrar/linker failures earlier. | CI results attached to the upgrade PR. | Automated compatibility |
| `UPG-NICE-03` | iPhone Instruments trace (Time Profiler / responsiveness-oriented template) alongside app benchmark JSON. | Diagnoses regressions; Apple recommends real hardware for realistic hitch measurements. | Saved trace or summarized metrics with raw file/artifact location. | Performance evidence |
| `UPG-NICE-04` | Controlled backup fixture corpus: current encrypted backup, supported pre-v2 backup, wrong-password, truncated, and resource-limit inputs. | Prevents format drift and turns legacy compatibility into an explicit contract. | Deterministic test fixtures and passing import tests. | Recovery / security |
| `UPG-NICE-05` | Weekly future-channel probe kept non-release-blocking. | Detects Flutter/AGP/SwiftPM deprecations before stable moves. | Existing `flutter-future-compat` workflow succeeds or creates a tracked compatibility issue. | Early warning |

## Explicit Anti-Features / Out of Scope

| Anti-feature or excluded work | Why it must not enter v2.1 | Do instead |
|---|---|---|
| Blind `flutter pub upgrade --major-versions` / “upgrade everything” | It can select a resolver-valid but native-incompatible set and obscures causality. | Upgrade one coordinated lane at a time; keep the executable matrix current. |
| Replacing SQLCipher with `sqlite3_flutter_libs`, system SQLite, or `sqlcipher_flutter_libs 0.7.0+eol` just to get a higher version number | Violates the at-rest-encryption contract or replaces the native library with an EOL placeholder. | Retain the proven encrypted path until an ADR-reviewed replacement completes real-device cipher/reopen/migration/backup proof. |
| Analyzer/Riverpod/serializer partial override | Bypasses the single-version solver and can leave generation/lint tooling internally incompatible. | Upgrade the custom-lint/import-boundary/Riverpod/JSON lane together, regenerate, then run all lint/architecture gates. |
| New accounting, UI, onboarding, sync, biometric, or backup product features | Changes behavior and dilutes the upgrade compatibility signal. | Repair only a regression required to preserve existing behavior; record any unavoidable behavioral change explicitly. |
| Beta/RC/dev versions in the production baseline | Project goal is latest *production stable*, not speculative toolchain validation. | Keep beta only in the existing scheduled future-compat warning workflow. |
| Android physical-device UAT | Explicitly not required for this milestone and cannot be claimed as completed. | Require release build + Android Emulator E2E; record “no Android physical device tested” in the final verification. |
| iPad matrix, store submission, legal-content work, or production support/URL changes | Separate release-owner and legal scope. | Preserve current release gates; do not invent production values. |
| Overwriting a user’s installed app, keychain, or backup while testing | A privacy and data-loss failure, especially for a finance app. | Install a distinct test Bundle ID and use only deterministic test keys, app container, temporary DB, and synthetic backup data. |
| Treating a simulator or host `flutter test` as a SQLCipher/performance substitute | Host tests can use plain SQLite; Apple states simulators do not replicate physical-device performance/features. | Keep host tests for fast coverage, but require native device/simulator cipher assertion and wired-iPhone final evidence. |

## Feature Dependencies

```text
Production-stable SDK/native baseline + lockfile
  ├──> coordinated compatibility contract
  │     ├──> code generation + l10n reproducibility
  │     ├──> host quality gates (analyze / custom lint / test / coverage)
  │     └──> Android + iOS native builds and release-preflight
  ├──> encrypted migration/reopen verification
  │     ├──> backup restore verification
  │     ├──> PIN/biometric/cold-start verification
  │     └──> accounting + sync compatibility verification
  └──> isolated test Bundle ID
        └──> wired-iPhone install + final E2E + performance evidence

Android release build + emulator E2E ── independent final platform gate
```

## MVP Recommendation

Prioritize in this order:

1. **Baseline and compatibility lanes** — establish the exact stable target and prohibitions before editing version constraints.
2. **Regeneration and host gates** — make resolver, code generation, architecture, analysis, tests, coverage, and release-preflight reproducible.
3. **Data/security device proof** — SQLCipher reopen, prior-release schema migration, encrypted backup restore, and app lock are the non-negotiable privacy core.
4. **Business compatibility** — manual accounting persistence and encrypted sync queue flow prove the app remains useful, not merely buildable.
5. **Platform release gates** — Android signed release + emulator; then an isolated wired-iPhone final run with performance evidence.

Defer: any net-new product feature, Android physical-device validation, iPad coverage, store submission operations, and an encrypted-storage architecture rewrite. They reduce the diagnostic value of this milestone without improving its stated acceptance target.

## Existing Assets to Reuse (Not Rebuild)

| Existing asset | What it already proves / where to extend |
|---|---|
| `docs/testing/DEPENDENCY_COMPATIBILITY.md` + `scripts/dependency_compatibility.dart` | Compatibility lanes, SQLCipher prohibition, analyzer/native constraints, and future probe. Update its matrix and executable contract together with a version decision. |
| `.github/workflows/audit.yml` | Stable Flutter build, compatibility contract, `flutter analyze`, custom lint, generated-code clean diff, full tests, and coverage. |
| `.github/workflows/device-e2e.yml` | Android API-35 emulator and iPhone Simulator integration runs plus release-preflight regeneration after test registrants. |
| `integration_test/device_critical_journey_test.dart` | Isolated encrypted DB, manual ledger entry, encrypted backup restore, SQLCipher close/reopen assertion, and cold-PIN unlock. Make the shipped-DB migration and isolated iPhone identity explicit. |
| `integration_test/merchant_migration_ladder_test.dart` + `test/unit/data/migrations/` | Current SQLCipher device ladder plus granular historical migration coverage through schema v36. |
| `integration_test/device_sync_delivery_test.dart` + `test/integration/sync/` | Encrypted queue reopen, pull/ack/offline delivery plus host sync behavior. |
| `scripts/performance/run_performance_benchmark.sh`, `integration_test/performance/`, `scripts/performance/performance_gate.dart` | Raw, labeled, opt-in device benchmark; it intentionally fails closed when a required baseline is missing and does not claim startup/TTI. |
| `scripts/release_preflight.sh` + Android signing contract tests | Removes dev-only integration-test registrants, builds credential-free native smoke artifacts, scans release binary, and enforces non-debug Android signing for packaging. |

## Sources

### Official primary sources (platform/tool requirements)

- [Flutter: Package dependency management](https://docs.flutter.dev/packages-and-plugins/dependency-management) — Flutter apps should commit `pubspec.lock`; it records exact direct and transitive versions, while overrides are temporary and must be thoroughly tested. **Confidence: MEDIUM** (official source; classified by research seam).
- [Flutter: Integration testing concepts](https://docs.flutter.dev/cookbook/testing/integration/introduction) and [Check app functionality with an integration test](https://docs.flutter.dev/testing/integration-tests) — `integration_test` runs on targets/devices/emulators and supports end-to-end behavior/performance; it cannot automate native platform UI. **Confidence: MEDIUM**.
- [Flutter: Build and release an Android app](https://docs.flutter.dev/deployment/android) — `flutter build appbundle` produces the release AAB; Play prefers AAB. **Confidence: MEDIUM**.
- [Apple: Running apps on simulated or physical devices](https://developer.apple.com/documentation/Xcode/running-your-app-on-simulated-or-physical-devices) — simulator hardware/features and real-device behavior differ; use a physical device to verify intended operation. **Confidence: MEDIUM**.
- [Apple: Improving app responsiveness](https://developer.apple.com/documentation/xcode/improving-app-responsiveness) — real-device Instruments measurement is recommended for realistic hitch evaluation. **Confidence: MEDIUM**.
- [Apple: Preparing your app for distribution](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution) — bundle IDs uniquely identify apps, supporting a distinct device-test identity. **Confidence: MEDIUM**.
- [Android Developers: Build your app from the command line](https://developer.android.com/build/building-cmdline) and [Build and test your Android App Bundle](https://developer.android.com/guide/app-bundle/test) — release artifacts must be built/signed and can be tested through emulator/device-oriented workflows. **Confidence: MEDIUM**.

### Project evidence

- `PROJECT.md`, `STATE.md`, `docs/testing/DEPENDENCY_COMPATIBILITY.md`, current `pubspec.yaml`/lockfile, platform configurations, existing integration tests, scripts, and CI workflows inspected on 2026-08-05.
