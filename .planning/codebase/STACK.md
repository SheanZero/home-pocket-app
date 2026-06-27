# Technology Stack

**Analysis Date:** 2026-06-27

## Languages

**Primary:**
- Dart `^3.10.8` (SDK constraint in `pubspec.yaml`) - All application code under `lib/`

**Secondary:**
- Kotlin - Android host (`android/app/build.gradle.kts`, plugin glue)
- Swift / Objective-C - iOS host (`ios/Runner/`)
- SQL - Drift-generated and hand-written DDL/migrations (`lib/data/`)

## Runtime

**Environment:**
- Flutter SDK (Dart `^3.10.8`). Targets iOS 15+ (`ios/Podfile` `platform :ios, '15.0'`) and Android (minSdk/targetSdk/compileSdk inherited from Flutter via `flutter.minSdkVersion` etc. in `android/app/build.gradle.kts`). Product target per CLAUDE.md is iOS 14+ / Android 7+ (API 24+); the Podfile pins the iOS build floor to 15.0.

**Package Manager:**
- pub (Flutter/Dart). Manifest: `pubspec.yaml`
- Lockfile: `pubspec.lock` (present)
- iOS native: CocoaPods (`ios/Podfile`, `ios/Podfile.lock`)
- Android native: Gradle Kotlin DSL (`android/app/build.gradle.kts`)

## Frameworks

**Core:**
- Flutter (Material, `uses-material-design: true`) - UI framework
- Riverpod `flutter_riverpod ^3.1.0` + `riverpod_annotation ^4.0.0` - State management (code-gen via `@riverpod`)
- Freezed `freezed_annotation ^3.0.0` - Immutable models + unions
- Drift `^2.25.0` - Type-safe SQL ORM over SQLCipher

**Testing:**
- `flutter_test` (SDK) - Unit/widget tests
- `integration_test` (SDK) - On-device/simulator SQLCipher migration ladder (`integration_test/`)
- `mocktail ^1.0.4` - Mocking
- `fake_async ^1.3.3` - Deterministic async testing

**Build/Dev:**
- `build_runner ^2.4.14` - Code generation driver
- `freezed ^3.0.0`, `json_serializable ^6.9.4`, `riverpod_generator ^4.0.0+1`, `drift_dev ^2.25.0` - Generators
- `flutter_lints ^6.0.0`, `custom_lint ^0.8.1`, `riverpod_lint ^3.1.0` - Linting
- `import_guard_custom_lint ^1.0.0`, `dart_code_linter ^3.0.0`, `yaml ^3.1.0` - Architecture/import enforcement and arch tests

## Key Dependencies

**Critical:**
- `drift ^2.25.0` + `sqlcipher_flutter_libs ^0.6.7` + `sqlite3 ^2.7.5` - Encrypted database. NEVER swap to `sqlite3_flutter_libs` (conflict; SQLCipher symbols must win at runtime)
- `cryptography ^2.7.0` - ChaCha20-Poly1305 field encryption, HKDF
- `crypto ^3.0.6` - SHA-256 (hash chain, request signing)
- `pinenacl ^0.6.0` - Ed25519 device keys / NaCl primitives
- `flutter_secure_storage ^10.2.0` - Keychain/Keystore master key (accessibility level `unlocked_this_device` — do not change, bricks existing installs)
- `local_auth ^3.0.1` - Biometric unlock
- `ulid ^2.0.0`, `uuid ^4.5.3` - Identifier generation

**Feature dependencies:**
- `speech_to_text ^7.0.0` - Voice input (PTT entry)
- `fl_chart ^1.2.0` - Analytics charts (donut/overview)
- `table_calendar ^3.2.0` - Calendar UI
- `qr_flutter ^4.1.0` - QR codes (family sync invite)
- `flutter_svg ^2.3.0`, `lucide_icons_flutter ^3.1.14`, `cupertino_icons ^1.0.8` - Iconography/vector assets

**Infrastructure:**
- `firebase_core ^4.1.1`, `firebase_messaging ^16.0.1` - Push (Android FCM; iOS uses APNs directly — see INTEGRATIONS.md)
- `flutter_local_notifications ^21.0.0` - Local notification display
- `web_socket_channel ^3.0.0` - Sync relay WebSocket transport
- `connectivity_plus ^7.1.1` - Network state for sync scheduling
- `http ^1.6.0` - Relay API + exchange-rate fetches
- `shared_preferences ^2.3.4` - Lightweight settings
- `path_provider ^2.1.5`, `path ^1.9.1` - Filesystem paths
- `file_picker ^11.0.2`, `image_picker ^1.1.2`, `share_plus ^12.0.2`, `package_info_plus ^9.0.1` - Backup import/export, receipt images, sharing

**Pinned dependency trio (do NOT bump in isolation — `win32` transitive conflict):**
- `file_picker ^11.0.2`, `package_info_plus ^9.0.1`, `share_plus ^12.0.2`

**Pinned:**
- `intl 0.20.2` (exact pin — required by `flutter_localizations`)

## Configuration

**Environment:**
- No `.env` file present. App is local-first; no runtime secret injection.
- i18n config: `l10n.yaml` (output class `S`, dir `lib/generated`)
- Internationalization: `flutter_localizations` + ARB files (`lib/l10n/`), languages ja (default), zh, en. `generate: true` in `pubspec.yaml`.

**Build:**
- `pubspec.yaml` - Dependencies + assets (`assets/satisfaction/`)
- `android/app/build.gradle.kts` - Android build (`namespace com.sheanzero.happypocket.app`, `firebase-bom 34.9.0`, `com.google.gms.google-services` plugin)
- `android/app/google-services.json` - Firebase Android config (present, committed)
- `ios/Podfile` - CocoaPods. Critical `post_install`: strips `-lsqlite3` from every pod xcconfig (else system libsqlite3 wins over SQLCipher) + `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64` for ML Kit
- `analysis_options.yaml` - Lint + custom_lint (import_guard) rules

## Database

- Drift schema **version 22** (`schemaVersion => 22` in `lib/data/app_database.dart`)
- Migration ladder runs `from < N` steps; v21 added `exchange_rates` + transaction currency columns (Phase 40), **v22 (Phase 49) created `merchants` and `merchant_match_keys` tables** — the merchant Drift cutover is COMPLETE on disk (prior map described it as deferred/in-flight)
- SQLCipher: AES-256-CBC, 256k PBKDF2, via `createEncryptedExecutor`
- `customIndices` getter is decorative — indexes created explicitly via `_createMerchantIndexes` / `_createShoppingItemIndexes` in both onCreate and onUpgrade paths

## Platform Requirements

**Development:**
- Flutter SDK with Dart `^3.10.8`
- macOS required for golden test baselines (goldens are macOS-baselined; CI ubuntu uses `BaselineExistenceGoldenComparator`)
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after modifying `@riverpod`, `@freezed`, Drift tables, or ARB files
- iOS clean rebuild requires `pod install` after `flutter clean`

**Production:**
- iOS 14+ / Android 7+ (API 24+); iOS build floor 15.0 (Podfile)
- App ID: `com.sheanzero.happypocket.app`

---

*Stack analysis: 2026-06-27*
