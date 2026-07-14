# Technology Stack

**Analysis Date:** 2026-07-14

## Languages

**Primary:**
- Dart (SDK `^3.10.8`) - All application code under `lib/`

**Secondary:**
- Swift / Objective-C - iOS native shell (`ios/Runner/`)
- Kotlin / Gradle - Android native shell (`android/app/`)
- ARB (JSON) - Localization source strings (`lib/l10n/app_{en,ja,zh}.arb`)

## Runtime

**Environment:**
- Flutter SDK - pinned to `3.44.0` in CI (`.github/workflows/audit.yml`, `subosito/flutter-action@v2`)
- Dart SDK `^3.10.8` (`pubspec.yaml` `environment.sdk`)

**Package Manager:**
- pub (Flutter/Dart)
- Lockfile: `pubspec.lock` present (committed)

**Target Platforms:**
- iOS 14+ (`ios/`)
- Android 7+ / API 24+ (`android/`), applicationId `com.sheanzero.happypocket.app`

## Frameworks

**Core:**
- Flutter - UI framework (Material Design, `uses-material-design: true`)
- Riverpod `flutter_riverpod ^3.1.0` + `riverpod_annotation ^4.0.0` - State management (code-gen via `@riverpod`)
- Freezed `freezed_annotation ^3.0.0` + `json_annotation ^4.9.0` - Immutable models / serialization
- Drift `^2.25.0` - Type-safe SQL ORM over SQLCipher

**Testing:**
- `flutter_test` (SDK) - Unit / widget tests
- `integration_test` (SDK) - On-device SQLCipher encrypted-executor migration tests (`integration_test/`)
- `mocktail ^1.0.4` - Mocking
- `fake_async ^1.3.3` - Deterministic async / timer tests

**Build/Dev:**
- `build_runner ^2.4.14` - Code generation driver
- `freezed ^3.0.0`, `json_serializable ^6.9.4`, `riverpod_generator ^4.0.0+1`, `drift_dev ^2.25.0` - Generators
- `flutter gen-l10n` - Localization codegen (config in `l10n.yaml`)

## Key Dependencies

**Critical:**
- `drift ^2.25.0` + `sqlcipher_flutter_libs ^0.6.7` + `sqlite3 ^2.7.5` - Encrypted database. NEVER add `sqlite3_flutter_libs` (CI-blocked, conflicts)
- `cryptography ^2.7.0`, `crypto ^3.0.6`, `pinenacl ^0.6.0` - Encryption (ChaCha20-Poly1305, Ed25519, hashing)
- `flutter_secure_storage ^10.2.0` - OS keychain/keystore for master key
- `local_auth ^3.0.1` - Biometric (Face ID / fingerprint) app lock
- `flutter_riverpod ^3.1.0` - State graph

**Feature:**
- `speech_to_text ^7.0.0` - Voice transaction entry
- `fl_chart ^1.2.0` - Analytics charts (donut/overview)
- `table_calendar ^3.2.0` - Calendar UI
- `qr_flutter ^4.1.0` - QR codes (family sync pairing)
- `image_picker ^1.1.2` - Receipt photo capture
- `ulid ^2.0.0`, `uuid ^4.5.3` - ID generation
- `flutter_svg ^2.3.0`, `lucide_icons_flutter ^3.1.14`, `cupertino_icons ^1.0.8` - Assets/icons

**Infrastructure:**
- `firebase_core ^4.1.1` + `firebase_messaging ^16.0.1` + `flutter_local_notifications ^21.0.0` - Push / local notifications
- `web_socket_channel ^3.0.0` + `http ^1.6.0` - P2P family sync relay transport
- `connectivity_plus ^7.1.1` - Network state for sync scheduling
- `shared_preferences ^2.3.4` - Plaintext settings persistence (NOT Drift)
- `path_provider ^2.1.5`, `path ^1.9.1` - Filesystem paths
- `url_launcher ^6.3.2` - Hosted privacy/terms + sponsor links

**Pinned dependency trio (DO NOT bump in isolation — tied via transitive `win32`):**
- `file_picker ^11.0.2` (12.x ships broken iOS Swift module)
- `package_info_plus ^9.0.1` (10.x requires win32 ^6.0.1)
- `share_plus ^12.0.2` (13.x requires win32 ^6.0.1)
- Also pinned: `intl 0.20.2` (exact — required by `flutter_localizations`)

## Linting & Code Quality

- `flutter_lints ^6.0.0` base ruleset (`analysis_options.yaml`)
- Custom lints via `custom_lint ^0.8.1` + `riverpod_lint ^3.1.0` + `import_guard_custom_lint ^1.0.0`
- `dart_code_linter ^3.0.0` - Audit tooling
- Enforced lint rules: `prefer_single_quotes`, `prefer_relative_imports`, `avoid_print`
- Analyzer excludes generated files (`*.g.dart`, `*.freezed.dart`, `build/**`)

## Configuration

**Environment:**
- No `.env` files. Runtime config via `--dart-define` (e.g. `SYNC_SERVER_URL`)
- Secrets live in OS keychain via `flutter_secure_storage`, never in source
- Firebase config: `android/app/google-services.json` (project `happy-pocket-11c5c`). No `ios/Runner/GoogleService-Info.plist` or `lib/firebase_options.dart` committed

**Build:**
- `l10n.yaml` - Localization: output class `S`, arb-dir `lib/l10n`, output `lib/generated`
- `build.yaml` - Freezed/json_serializable options (`explicit_to_json: true`, format on)
- `analysis_options.yaml` - Analyzer + custom_lint plugin config

**iOS native (`ios/Podfile`):**
- `post_install` strips `-lsqlite3` from every Pod xcconfig (prevents system libsqlite3 shadowing SQLCipher)
- `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64` for ML Kit compatibility

## Platform Requirements

**Development:**
- Flutter 3.44.0, Dart `^3.10.8`
- macOS required for iOS builds and golden baselining (goldens are macOS-baselined; CI on ubuntu uses a baseline-existence comparator)
- Run `build_runner` after modifying `@riverpod`, `@freezed`, Drift tables, or ARB files

**Production:**
- iOS 14+ / Android 7+ (API 24+)
- Drift schema at v23 (`schemaVersion => 23`, `lib/data/app_database.dart`)

---

*Stack analysis: 2026-07-14*
