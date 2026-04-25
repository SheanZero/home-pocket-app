# Technology Stack

**Analysis Date:** 2026-04-25

## Languages

**Primary:**
- Dart `^3.10.8` (constraint from `pubspec.yaml`) — primary application language for all code under `lib/`
- Kotlin (JVM target 17) — Android host platform glue under `android/app/src/main/kotlin/`
- Swift / Objective-C — iOS host platform glue under `ios/Runner/`

**Secondary:**
- Ruby — CocoaPods Podfile (`ios/Podfile`)
- Groovy / Kotlin DSL — Gradle build scripts (`android/app/build.gradle.kts`)

## Runtime

**Environment:**
- Flutter SDK (Dart `^3.10.8` constraint implies Flutter 3.27+)
- iOS deployment target: `15.0` (`ios/Podfile`, `ios/Runner.xcodeproj/project.pbxproj`)
- Android: `compileSdk` and `minSdk` flow from Flutter Gradle plugin (`android/app/build.gradle.kts`)
- JVM target: Java 17 (Android `compileOptions` in `android/app/build.gradle.kts`)
- Core library desugaring enabled (`com.android.tools:desugar_jdk_libs:2.1.4`)

**Package Manager:**
- `pub` (Dart/Flutter) — manifest in `pubspec.yaml`, lockfile present at `pubspec.lock`
- CocoaPods for iOS native deps (`ios/Podfile`)
- Gradle (Kotlin DSL) for Android (`android/app/build.gradle.kts`)
- Lockfile: `pubspec.lock` present (committed)

## Frameworks

**Core:**
- `flutter` (Flutter SDK) — UI framework, Material Design enabled (`uses-material-design: true` in `pubspec.yaml`)
- `flutter_riverpod` `^2.6.1` + `riverpod_annotation` `^2.6.1` — state management (per `CLAUDE.md`, providers wired with `@riverpod` code generation)
- `freezed_annotation` `^3.0.0` + `json_annotation` `^4.9.0` — immutable models with `copyWith`
- `drift` `^2.25.0` — type-safe SQL ORM, schema in `lib/data/app_database.dart` (current `schemaVersion = 14`)
- `flutter_localizations` (SDK) + `intl` `0.20.2` (pinned, must not be upgraded per `CLAUDE.md`)

**Testing:**
- `flutter_test` (SDK) — Flutter widget/unit test runner
- `mockito` `^5.4.6` — mock generation
- `mocktail` `^1.0.4` — null-safe mocks without code-gen

**Build/Dev:**
- `build_runner` `^2.4.14` — code generation runner
- `freezed` `^3.0.0` — generates `*.freezed.dart` for immutable models
- `json_serializable` `^6.9.4` — generates JSON `toJson`/`fromJson`
- `riverpod_generator` `^2.6.4` — generates `*.g.dart` for `@riverpod` providers
- `drift_dev` `^2.25.0` — generates Drift schema/dao classes
- `flutter_lints` `^6.0.0` — analyzer ruleset (extended in `analysis_options.yaml`)
- `custom_lint` `^0.7.5` + `riverpod_lint` `^2.6.4` — Riverpod-specific lint rules

**Build configuration (`build.yaml`):**
- `freezed` builder: `format: true`
- `json_serializable` builder: `explicit_to_json: true`

## Key Dependencies

**Critical:**
- `drift` `^2.25.0` — primary persistence layer (`lib/data/app_database.dart`, DAOs in `lib/data/daos/`)
- `sqlcipher_flutter_libs` `^0.6.7` — SQLCipher AES-256-CBC encryption, used in `lib/infrastructure/crypto/database/encrypted_database.dart`. Per `CLAUDE.md`, `sqlite3_flutter_libs` is FORBIDDEN (conflicts).
- `sqlite3` `^2.7.5` — low-level SQLite bindings (loader override applied for Android in `ensureNativeLibrary()`).
- `cryptography` `^2.7.0` — Ed25519 signing, HKDF derivation, ChaCha20-Poly1305 (used by `lib/infrastructure/crypto/services/key_manager.dart`)
- `crypto` `^3.0.6` — SHA-256 hashing for request signing (`lib/infrastructure/sync/relay_api_client.dart`) and hash chain
- `pinenacl` `^0.6.0` — NaCl box (X25519 + XSalsa20-Poly1305) for E2EE in `lib/infrastructure/sync/e2ee_service.dart`
- `flutter_secure_storage` `^9.2.4` — iOS Keychain / Android Keystore wrapper (`lib/infrastructure/security/secure_storage_service.dart`)
- `local_auth` `^2.3.0` — Face ID / Touch ID / fingerprint (`lib/infrastructure/security/biometric_service.dart`)
- `firebase_core` `^4.1.1` + `firebase_messaging` `^16.0.1` — FCM push for sync notifications (`lib/infrastructure/sync/push_notification_service.dart`)
- `flutter_local_notifications` `^19.4.2` — local notification display (channel `family_sync`)
- `web_socket_channel` `^3.0.0` — relay server WebSocket (`lib/infrastructure/sync/websocket_service.dart`)
- `http` `^1.6.0` — HTTPS client for relay REST API (`lib/infrastructure/sync/relay_api_client.dart`)

**Infrastructure:**
- `path_provider` `^2.1.5` — locate app documents directory for DB file
- `path` `^1.9.1` — path joining for database file location
- `shared_preferences` `^2.3.4` — non-sensitive settings persistence
- `package_info_plus` `^8.1.3` — app version metadata
- `ulid` `^2.0.0` — sortable unique IDs (transactions, etc.)
- `uuid` `^4.5.3` — RFC 4122 UUIDs
- `collection` `^1.19.1` — algorithms (e.g., deep equality)

**UI / Capability:**
- `cupertino_icons` `^1.0.8` — iOS-style icons
- `lucide_icons` `^0.257.0` — extended icon set
- `fl_chart` `^0.69.0` — analytics charts (`lib/features/analytics/`)
- `qr_flutter` `^4.1.0` — QR code rendering for family-sync invitations
- `speech_to_text` `^7.0.0` — voice input (`lib/infrastructure/speech/speech_recognition_service.dart`)
- `file_picker` `^8.1.6` + `image_picker` `^1.1.2` + `share_plus` `^10.1.4` — file & share integrations

## Configuration

**Environment:**
- Build-time configuration via `--dart-define` (e.g., `SYNC_SERVER_URL`, see `lib/infrastructure/sync/relay_api_client.dart` `defaultBaseUrl`)
- No runtime `.env` files are used (none present in repo); secrets supplied via dart-define / platform secure storage
- `android/app/google-services.json` — Firebase config; listed in `.gitignore` (line 50) due to embedded API keys. Existence confirmed; contents NEVER read.

**Localization (`l10n.yaml`):**
- `arb-dir: lib/l10n`
- `template-arb-file: app_en.arb`
- `output-localization-file: app_localizations.dart`
- `output-class: S`
- `output-dir: lib/generated`
- `nullable-getter: false`
- ARB sources: `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb`
- Generated file location is gitignored (`lib/generated/` in `.gitignore`)

**Analyzer (`analysis_options.yaml`):**
- Includes `package:flutter_lints/flutter.yaml`
- Excludes generated files: `**/*.g.dart`, `**/*.freezed.dart`
- Suppresses `invalid_annotation_target`
- Custom lint rules: `prefer_single_quotes: true`, `prefer_relative_imports: true`, `avoid_print: false`

**iOS (`ios/Podfile`):**
- Platform: `ios, '15.0'`
- COCOAPODS_DISABLE_STATS enabled
- Standard `flutter_install_all_ios_pods` + `flutter_additional_ios_build_settings` post-install hook
- Per `CLAUDE.md`: post-install hook must preserve `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64` for ML Kit (note: current Podfile is minimal; ML Kit is not yet a runtime dependency in `pubspec.yaml`)

**Android (`android/app/build.gradle.kts`):**
- `namespace`: `com.sheanzero.happypocket.app`
- `applicationId`: `com.sheanzero.happypocket.app`
- Plugins: `com.android.application`, `kotlin-android`, `com.google.gms.google-services`, `dev.flutter.flutter-gradle-plugin`
- `isCoreLibraryDesugaringEnabled = true`
- Firebase BOM: `com.google.firebase:firebase-bom:34.9.0`
- Firebase Analytics implementation included
- Manifest permissions (`android/app/src/main/AndroidManifest.xml`): `RECORD_AUDIO`, `<queries>` for `PROCESS_TEXT` and `RecognitionService`
- Activity: `singleTop` launchMode

**iOS Permissions (`ios/Runner/Info.plist`):**
- `NSMicrophoneUsageDescription` — voice input (Japanese description)
- `NSSpeechRecognitionUsageDescription` — voice transaction parsing
- `UIBackgroundModes`: `remote-notification` (for FCM/APNs background delivery)
- Bundle id: `com.sheanzero.happypocket.app`

**Build Tooling:**
- `build.yaml` configures `freezed` (`format: true`) and `json_serializable` (`explicit_to_json: true`)
- `devtools_options.yaml` present at root (Dart DevTools settings)
- Helper script: `scripts/arb_to_csv.dart` (translation tooling)

## Code Generation

Generated artifacts (must be regenerated after editing annotated source — per `CLAUDE.md`):

- `*.freezed.dart` — Freezed immutable classes (e.g., `lib/infrastructure/crypto/models/device_key_pair.freezed.dart`)
- `*.g.dart` — Riverpod providers, json_serializable, Drift database schema (e.g., `lib/data/app_database.g.dart`, `lib/infrastructure/crypto/providers.g.dart`)
- `lib/generated/app_localizations.dart` — generated by `flutter gen-l10n`

**Generation commands:**
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

**When required:** after modifying `@riverpod`, `@freezed`, Drift tables, ARB files, or after `git merge`/`rebase`/`pull`.

## Platform Requirements

**Development:**
- Flutter SDK matching `sdk: ^3.10.8` (Dart 3.10+)
- Xcode + CocoaPods (iOS)
- Android SDK with desugaring (Java 17)

**Production:**
- iOS 15.0+ (Podfile / Xcode project) — note: project README/`CLAUDE.md` mention iOS 14+ as marketing target, but actual deployment target in `ios/Podfile` is 15.0
- Android API 24+ (Android 7+, per `CLAUDE.md`); concrete `minSdk` resolved by Flutter Gradle plugin
- iOS bundle id: `com.sheanzero.happypocket.app`
- Android applicationId: `com.sheanzero.happypocket.app`

---

*Stack analysis: 2026-04-25*
