# Technology Stack — v2.1 Dependency & Native Toolchain Modernization

**Project:** Happy Pocket (`home_pocket`)
**Research cutoff:** 2026-08-05
**Scope:** Flutter/Dart, generated-code tooling, encrypted SQLite lane, native plugins, Android build chain, and iOS build/dependency managers.
**Overall confidence:** MEDIUM — repository state is directly observed; version and migration claims come only from official Flutter/Dart, pub.dev, Android, Kotlin, Apple, CocoaPods, and maintainer GitHub sources. The research classifier assigns verified web retrieval MEDIUM confidence.

## Recommendation

Modernize by **compatibility lane**, not with `flutter pub upgrade --major-versions`. Adopt Flutter **3.44.7** (Dart **3.12**) and the Android AGP 9 migration, but keep two deliberately pinned lanes intact until their real native/architecture replacements exist:

1. Keep `sqlcipher_flutter_libs 0.6.8` plus `sqlite3 2.9.4`. The apparent latest `sqlcipher_flutter_libs 0.7.0+eol` is an EOL marker with no usable native SQLCipher payload; it is not an upgrade. Do not add `sqlite3_flutter_libs`.
2. Keep the analyzer-8 custom-lint boundary lane while `import_guard_custom_lint 1.0.0` and `custom_lint 0.8.1` are retained. Both constrain the resolver below analyzer 9, so forcing modern Riverpod generators/analyzer with overrides would disable or destabilize an architecture gate.

Everything else proceeds only after `flutter pub get` resolves the exact lane without dependency overrides, then code is regenerated and all native/security gates pass.

## Current → Target Matrix

### Flutter, Dart, and generated code

| Area | Current resolved / configured | Latest production stable at cutoff | v2.1 decision | Required coupling and migration | Confidence |
|---|---|---|---|---|---|
| Flutter SDK | 3.44.0 (`.flutter-plugins-dependencies`) | **3.44.7** | **Upgrade** to 3.44.7; it is the latest documented stable patch. Do not take 3.47 merely because it is scheduled for August—its release status must be stable/GA at execution time. | Run `flutter upgrade` on stable; update `.metadata`; regenerate SwiftPM plugin integration and verify all platform builds. Flutter 3.44 is the release containing legacy-KGP/new-DSL transition support. | MEDIUM |
| Dart SDK / app constraint | Flutter 3.44 supplies Dart 3.12; app permits `^3.10.8` | Dart **3.12.0** bundled with Flutter 3.44 | **Raise lower bound to `^3.12.0`** after the SDK upgrade. | This unlocks packages that require Dart 3.12 while remaining inside the actual Flutter SDK. Do not use a separately installed Dart SDK to build the Flutter app. | MEDIUM |
| Riverpod runtime | `flutter_riverpod 3.1.0`; annotation/generator/lint `4.0.0` / `4.0.0+1` / `3.1.0` | 3.4.1 / 4.0.6 / 4.0.8 / 3.1.8 (all need Dart 3.12) | **Defer as one analyzer/codegen lane**; do not partially update runtime, annotation, generator, or lint. | Latest generator/lint no longer fit the analyzer-8 architecture-gate lane. First replace or upgrade the import-boundary/custom-lint implementation with one supporting a common modern analyzer version; then update all four together, regenerate every `.g.dart`, and resolve Riverpod 3 migration diagnostics. | MEDIUM |
| Freezed | `freezed 3.2.3`, `freezed_annotation 3.1.0` | **3.2.5**, **3.1.0** | **Upgrade generator patch only** (`freezed: ^3.2.5`); keep annotation 3.1.0. | Run Freezed generation in the same codegen validation phase. Do not select `freezed 4.0.0-dev.3` (pre-release). | MEDIUM |
| Drift runtime / generator | `drift 2.31.0`, `drift_dev 2.31.0` | **2.34.3**, **2.34.5** | **Defer with the encrypted-native lane**. | Current releases require Dart 3.10, but the generator and `sqlite3` resolution must be proven with the functional SQLCipher path before committing. Upgrade runtime and `drift_dev` together; execute migration tests, encrypted reopen, `PRAGMA cipher_version`, and backup/restore on an iPhone. | MEDIUM |
| Analyzer | 8.4.0 (transitive lock) | **14.1.0** | **Patch only to 8.4.1 if pub resolves it; do not target 9–14 yet.** | `custom_lint 0.8.1` declares `analyzer ^8.0.0`; `import_guard_custom_lint 1.0.0` declares `>=7 <9`. The latter is the hard blocker. No `dependency_overrides`. | HIGH for blocker; MEDIUM for latest |
| `build_runner` | 2.15.1 | **2.16.0** | **Defer until the analyzer/codegen lane is resolver-proven.** | It needs Dart 3.11, which Flutter 3.44 satisfies, but it must be upgraded with the actual generators, not in isolation. | MEDIUM |
| JSON codegen | `json_annotation 4.9.0`, `json_serializable 6.11.2` | **4.12.0**, **6.14.1** | **Candidate upgrade in the analyzer/codegen lane only.** | Run a clean solve; retain only if it leaves the required analyzer 8.x lock and generators compatible. Regenerate and test encrypted backup/sync JSON codecs. | MEDIUM |
| Boundary lints | `custom_lint 0.8.1`, `import_guard_custom_lint 1.0.0` | same published stable versions | **Hold; treat replacement/upgrade as a prerequisite research spike, not a version override.** | The project must retain an enforced Clean Architecture import boundary before removing either. `custom_lint` itself is stable but tied to analyzer 8; `import_guard` has no newer stable release in pub.dev. | HIGH |

### Persistence and native plugins

| Area | Current resolved / configured | Latest production stable at cutoff | v2.1 decision | Required coupling and migration | Confidence |
|---|---|---|---|---|---|
| Functional SQLCipher lane | `sqlcipher_flutter_libs 0.6.8`, `sqlite3 2.9.4`, SQLCipher CocoaPod 4.10.0 | `sqlcipher_flutter_libs 0.7.0+eol`; `sqlite3 3.5.1`; upstream SQLCipher 4.15.0 | **Keep 0.6.8/2.9.4/4.10.0 exactly.** | `0.7.0+eol` explicitly says it is no longer used and tells consumers to use `sqlite3` 3.x. That is a separate design/migration, not an automatic patch. The current Podfile strip that removes `-lsqlite3` is mandatory because FirebaseMessaging may otherwise link system SQLite first. | HIGH |
| `sqlite3_flutter_libs` | absent and forbidden | 0.6.0+eol | **Never add.** | It is also EOL and would conflict with the SQLCipher linker arrangement. The desired outcome is an encrypted `PRAGMA cipher_version`, not simply a newer package number. | HIGH |
| File / share / package metadata / win32 | `file_picker 11.0.3`, `share_plus 12.0.2`, `package_info_plus 9.0.1`, `win32 5.15.0` | file_picker **11.0.3** (12.0.0-beta.7 is pre-release); share_plus **13.3.0**; package_info_plus **10.2.1** | **Keep the complete group for this milestone.** `file_picker` is already latest stable. | share/package-info majors move to the win32-6 ecosystem while the stable picker remains on the existing compatible group. Revisit only after file_picker 12 is stable and verify exactly-one `.hpb` selection plus the export share sheet. | HIGH |
| Speech | exact `speech_to_text 7.3.0` | **7.4.0** (7.5.0-beta.1 rejected) | **Upgrade in an isolated adapter phase, not as a casual solve.** | 7.4.0 is now published as stable even though the repository notes its beta-line origin. Update the adapter/mocks for its changed API, then verify Android microphone and iOS speech permission/recognition in ja/zh/en after `flutter clean`. | MEDIUM |
| Firebase Core / Messaging | 4.13.0 / 16.5.0 | **4.13.0 / 16.5.0** | **No version change.** | Already latest stable. Keep the Firebase BoM in step with the plugin set; retest FCM registration, foreground, cold-start tap, APNs token/delivery on signed iPhone build. | MEDIUM |
| Local notifications | 22.2.0 | **22.2.0** | **No version change.** | Already latest stable. Do not alter notification routing while changing native tools; test scheduled/foreground/tap behavior with the FCM sequence. | MEDIUM |

## Native Toolchain Target

### Android

| Technology | Current | Recommended target | v2.1 action | Constraints / verification |
|---|---:|---:|---|---|
| Android Gradle Plugin | 8.11.1 | **9.0.1** | **Upgrade** using the AGP Upgrade Assistant/migration guidance. | AGP 9 requires Gradle 9.1 and JDK 17, defaults to new DSL and built-in Kotlin. All Flutter plugins must be audited/build-tested under that mode. |
| Gradle wrapper | 8.14 | **9.1.0** | **Upgrade with AGP 9.** | Do not pair AGP 9 with Gradle 8.14. |
| Kotlin Gradle plugin | 2.2.20 applied as `kotlin-android` | **Remove app-level KGP application; use AGP 9 built-in Kotlin** | **Migrate; do not independently bump to Kotlin 2.4.10.** | AGP 9 has a runtime KGP dependency (2.2.10) and built-in Kotlin is the supported path. Delete the top-level `org.jetbrains.kotlin.android` version and app `id("kotlin-android")` only after all plugins build. |
| Java | 17 | **17** | **Keep.** | AGP 9 requires JDK 17; retain compileOptions and Kotlin JVM target 17. |
| Android SDK | Flutter-managed `compileSdk` / `targetSdk` | **API 36** | **Make the resolved values explicit/verify 36**, not a preview API. | Android's API-36 setup guidance requires compileSdk and targetSdk 36; AGP 9 supports through API 36.1. Test Android 16 behavior changes on emulator. |
| Legacy migration flags | `android.builtInKotlin=false`, `android.newDsl=false` | absent after full migration | **Remove only as the final Android migration commit.** | Flutter 3.44 temporarily supports the legacy KGP/DSL route; this is a bridge, not the destination. Any remaining incompatible plugin blocks flag removal. |

Implementation order: first update Flutter 3.44.7; then make the Gradle 9.1/AGP 9 migration on a clean branch of the work, remove KGP usage and both opt-out flags, run `flutter build apk --debug` and the signed Android release build. Do not leave AGP 9 running in “legacy flags permanently false” mode; it postpones a removal scheduled for AGP 10.

### iOS

| Technology | Current | Recommended target | v2.1 action | Constraints / verification |
|---|---:|---:|---|---|
| Xcode | project last-upgraded under Xcode 15.1; Swift language mode 5 | **Xcode 26.6 stable** | **Use 26.6 for CI/local device acceptance; keep Swift 5 language mode unless compiler diagnostics require a source migration.** | Apple lists Xcode 26.6 as current stable and supports deployment to iOS 15+. Do not choose Xcode 27 beta. Build simulator plus the required wired iPhone. |
| iOS deployment target | 15.0 | **15.0** | **Keep.** | It is supported by Xcode 26.6 and matches the product contract; no benefit justifies raising it in a tooling milestone. |
| SwiftPM | Flutter-generated local `FlutterGeneratedPluginSwiftPackage` enabled | SwiftPM remains enabled | **Keep enabled.** | Flutter-supported plugins should stay on the generated SwiftPM route. Regenerate after Flutter upgrade; do not globally disable it to force Pods. |
| CocoaPods | 1.16.2 lockfile; only SQLCipher in Podfile.lock | **Keep 1.16.2 / use `pod install`** | **Keep Pods only for SQLCipher.** | CocoaPods is in maintenance mode; its official guide says `pod install` respects the locked versions and `pod update PODNAME` is the intentional operation when changing one. Do not bulk-update pods. |
| SQLCipher Pod | 4.10.0 through `sqlcipher_flutter_libs` | 4.10.0 until the functional package lane is replaced | **Hold.** | Preserve the Podfile's xcconfig `-lsqlite3` removal. A Pod/SwiftPM migration cannot be inferred from the package EOL marker; it requires a reviewed maintained plugin/fork and device encryption evidence. |

## Required Compatibility Gates

Make `dart run scripts/dependency_compatibility.dart` version-aware for the approved targets, but keep the following invariants executable:

```text
must never resolve: sqlite3_flutter_libs
must never resolve: sqlcipher_flutter_libs 0.7.0+eol
encrypted lane: sqlcipher_flutter_libs 0.6.8 + sqlite3 2.9.4 + SQLCipher pod 4.10.0
architecture gate: analyzer 8.x while import_guard_custom_lint 1.0.0 remains installed
file/share lane: file_picker 11.0.3 + share_plus 12.0.2 + package_info_plus 9.0.1 + win32 5.15.0
```

For every native plugin/toolchain change: `flutter clean`, `flutter pub get`, dependency gate, `flutter gen-l10n`, and `build_runner build --delete-conflicting-outputs`; then `flutter analyze`, architecture/custom-lint gates, targeted tests, full suite, Android debug/release builds, and iOS simulator build.

The real-device iPhone gate is mandatory for any database/Pod/Flutter-native change: create/open/reopen the encrypted database; assert non-empty `PRAGMA cipher_version`; migrate historical schemas; restore encrypted backup; exercise app lock; create/edit transaction; and capture FCM/local-notification behavior. Never log key material, amount/merchant/note contents, tokens, or sync payloads.

## Ordered Upgrade Plan

1. **Baseline and Flutter patch:** record `flutter --version`; move stable Flutter 3.44.0 → 3.44.7; raise Dart constraint to `^3.12.0`; regenerate the project integration files; run all existing gates before dependency changes.
2. **Android AGP 9 migration:** Gradle 9.1 + AGP 9.0.1 + API 36, migrate to built-in Kotlin/new DSL, then remove legacy flags only when every plugin builds. This is the first native-risk phase because Flutter's legacy support is temporary.
3. **Low-risk already-compatible refresh:** keep already-current file/Firebase/notification packages unchanged; take the Freezed 3.2.5 patch. Attempt JSON/build tooling only as one clean resolver-tested unit that retains analyzer 8.x.
4. **Speech adapter migration:** move 7.3.0 → 7.4.0, update mocks/adapter code, regenerate, and prove real platform recognition/permission flow.
5. **Deferred gates, explicitly not a forced update:** retain SQLCipher/Drift/sqlite and analyzer/Riverpod-generator groups until a phase has researched and implemented, respectively, (a) a maintained encrypted sqlite3-3 solution and (b) an analyzer-9+ import-boundary lint solution. Both need separate acceptance before version bumps.

## Alternatives Considered

| Category | Recommended | Rejected | Why |
|---|---|---|---|
| Flutter | 3.44.7 stable | Flutter 3.47 scheduled release / beta | Only GA stable is permitted; the archive's schedule is not a release guarantee. |
| Android Kotlin | AGP 9 built-in Kotlin | Kotlin Gradle Plugin 2.4.10 upgrade | AGP 9's architecture is built-in Kotlin. Independently pinning a newer KGP preserves the legacy path rather than completing the migration. |
| SQLCipher | retain 0.6.8 + sqlite3 2.9.4 | `sqlcipher_flutter_libs 0.7.0+eol`, `sqlite3_flutter_libs`, or plain SQLite | None prove equivalent encrypted persistence. The EOL package itself directs a migration; it is not a native library release. |
| File group | retain stable coordinated group | file_picker 12 beta / partial plus-plugin upgrades | Beta violates scope; partial majors conflict with the tested win32 lane. |
| Analyzer | retain 8.x behind lints | force analyzer 14 with overrides | Overrides would violate declared contracts and could remove the architecture boundary that protects the codebase. |
| iOS dependencies | SwiftPM for supported plugins + SQLCipher CocoaPods exception | disable SwiftPM globally or bulk `pod update` | Current mixed strategy is intentional and locked. Use `pod install` for reproducibility. |

## Installation / Execution Commands

```bash
# Start each approved lane from a clean native artifact state.
flutter clean
flutter pub get
dart run scripts/dependency_compatibility.dart
flutter gen-l10n
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test --concurrency=1

# Android after AGP migration (release requires the existing production signing inputs).
flutter build apk --debug
flutter build appbundle --release

# iOS dependency resolution remains locked; do not use a bulk pod update.
cd ios
pod install
cd ..
flutter build ios --simulator --debug
```

## Sources

Primary official sources (all checked 2026-08-05):

- [Flutter SDK archive](https://docs.flutter.dev/install/archive) — stable-channel policy, 3.44.7 documentation baseline, 2026 release schedule, and Dart pairing.
- [Flutter 3.44 release notes](https://docs.flutter.dev/release/release-notes/release-notes-3.44.0) and [built-in Kotlin migration](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin) / [app guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers).
- pub.dev official version pages: [Riverpod](https://pub.dev/packages/flutter_riverpod/versions), [Riverpod annotation](https://pub.dev/packages/riverpod_annotation/versions), [generator](https://pub.dev/packages/riverpod_generator/versions), [lint](https://pub.dev/packages/riverpod_lint/versions), [Freezed](https://pub.dev/packages/freezed/versions), [Drift](https://pub.dev/packages/drift/versions), [Drift dev](https://pub.dev/packages/drift_dev/versions), [analyzer](https://pub.dev/packages/analyzer/versions), [build_runner](https://pub.dev/packages/build_runner/versions), [JSON annotation](https://pub.dev/packages/json_annotation/versions), [JSON serializable](https://pub.dev/packages/json_serializable/versions), [custom_lint](https://pub.dev/packages/custom_lint/versions), and [import guard](https://pub.dev/packages/import_guard_custom_lint/versions).
- pub.dev official native/plugin version pages: [SQLCipher Flutter libs](https://pub.dev/packages/sqlcipher_flutter_libs/versions), [sqlite3](https://pub.dev/packages/sqlite3/versions), [sqlite3 Flutter libs](https://pub.dev/packages/sqlite3_flutter_libs/versions), [file_picker](https://pub.dev/packages/file_picker/versions), [share_plus](https://pub.dev/packages/share_plus/versions), [package_info_plus](https://pub.dev/packages/package_info_plus/versions), [speech_to_text](https://pub.dev/packages/speech_to_text/versions), [Firebase Core](https://pub.dev/packages/firebase_core/versions), [Firebase Messaging](https://pub.dev/packages/firebase_messaging/versions), and [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications/versions).
- [Android Gradle Plugin 9.0.1 release notes](https://developer.android.com/build/releases/agp-9-0-0-release-notes), [Android 16 SDK setup](https://developer.android.com/about/versions/16/setup-sdk), and [Kotlin releases](https://kotlinlang.org/docs/releases.html).
- [Apple Xcode support matrix](https://developer.apple.com/support/xcode/), [Apple Swift packages](https://developer.apple.com/documentation/Xcode/swift-packages), [adding Swift package dependencies](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app), and [CocoaPods `pod install` versus `pod update`](https://guides.cocoapods.org/using/pod-install-vs-update.html).
- Maintainer primary sources supporting the security hold: [current `sqlcipher_flutter_libs` README](https://pub.dev/packages/sqlcipher_flutter_libs) (SQLCipher/iOS linker precautions) and [SQLCipher changelog](https://github.com/sqlcipher/sqlcipher/blob/master/CHANGELOG.md).
- Repository evidence: `pubspec.yaml`, `pubspec.lock`, `docs/testing/DEPENDENCY_COMPATIBILITY.md`, `scripts/dependency_compatibility.dart`, Android Gradle files, `ios/Podfile`, `ios/Podfile.lock`, and `ios/Runner.xcodeproj/project.pbxproj`.
