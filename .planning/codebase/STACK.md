# Technology Stack

**Analysis Date:** 2026-06-23

## Languages

**Primary:**
- Dart `^3.10.8` (SDK constraint in `pubspec.yaml`) - All application code under `lib/`

**Secondary:**
- Swift / Objective-C - iOS platform layer (`ios/Runner/`)
- Kotlin / Gradle - Android platform layer (`android/app/`)
- SQL (Drift DSL + SQLCipher) - Schema and queries in `lib/data/tables/` and `lib/data/daos/`

## Runtime

**Environment:**
- Flutter `3.44.0` (stable channel, framework revision `559ffa3f75`, 2026-05-15)
- Dart SDK `^3.10.8`

**Package Manager:**
- `pub` (Flutter/Dart built-in)
- Lockfile: present (`pubspec.lock`, committed)

## Frameworks

**Core:**
- Flutter - Cross-platform UI framework (iOS 15+, Android API 24+)
- Riverpod `flutter_riverpod ^3.1.0` + `riverpod_annotation ^4.0.0` - State management with code generation
- Drift `^2.25.0` - Type-safe ORM over SQLCipher (`lib/data/app_database.dart`, schema v21)
- Freezed `freezed_annotation ^3.0.0` - Immutable data models

**Testing:**
- `flutter_test` (SDK) - Unit and widget tests
- `integration_test` (SDK) - On-device migration ladder (`integration_test/`); SQLCipher natives only load on real device/sim
- `mocktail ^1.0.4` - Mocking
- `fake_async ^1.3.3` - Deterministic async testing

**Build/Dev:**
- `build_runner ^2.4.14` - Code generation driver
- `freezed ^3.0.0`, `json_serializable ^6.9.4`, `riverpod_generator ^4.0.0+1`, `drift_dev ^2.25.0` - Generators
- `custom_lint ^0.8.1` + `riverpod_lint ^3.1.0` + `import_guard_custom_lint ^1.0.0` - Lint plugins (layer/import enforcement)
- `flutter_lints ^6.0.0` - Base lint ruleset (`analysis_options.yaml`)
- `dart_code_linter ^3.0.0` - Audit tooling

## Key Dependencies

**Critical:**
- `sqlcipher_flutter_libs ^0.6.7` - SQLCipher native libs (AES-256 DB encryption). NEVER swap for `sqlite3_flutter_libs` (conflict)
- `sqlite3 ^2.7.5` - SQLite bindings (pinned <3.x; not migrated to sqlite3 3.x)
- `cryptography ^2.7.0` - ChaCha20-Poly1305 field encryption, HKDF
- `crypto ^3.0.6` - SHA-256 hash chain, request signing
- `pinenacl ^0.6.0` - Ed25519 device keys / NaCl primitives
- `flutter_secure_storage ^10.2.0` - Keychain/Keystore for master key (accessibility pinned to `unlocked_this_device`)
- `local_auth ^3.0.1` - Biometric lock

**Infrastructure:**
- `firebase_core ^4.1.1`, `firebase_messaging ^16.0.1` - Push notifications (FCM)
- `flutter_local_notifications ^21.0.0` - Local notification display
- `web_socket_channel ^3.0.0` - P2P sync relay WebSocket
- `http ^1.6.0` - REST calls (relay API, exchange-rate API)
- `connectivity_plus ^7.1.1` - Network state for sync scheduling
- `path_provider ^2.1.5`, `path ^1.9.1` - Filesystem paths for DB/photos
- `ulid ^2.0.0`, `uuid ^4.5.3` - Identifier generation
- `shared_preferences ^2.3.4` - Lightweight settings

**UI:**
- `fl_chart ^1.2.0` - Analytics charts
- `flutter_svg ^2.3.0` - SVG rendering (satisfaction assets)
- `table_calendar ^3.2.0`, `qr_flutter ^4.1.0`, `lucide_icons_flutter ^3.1.14`, `cupertino_icons ^1.0.8`

**Device I/O:**
- `speech_to_text ^7.0.0` - Voice entry
- `image_picker ^1.1.2`, `file_picker ^11.0.2`, `share_plus ^12.0.2`, `package_info_plus ^9.0.1`

**Pinned trio (do not bump in isolation — shared `win32` constraint):** `file_picker ^11.0.2`, `package_info_plus ^9.0.1`, `share_plus ^12.0.2`. `intl` pinned exactly at `0.20.2` (required by `flutter_localizations`).

## Configuration

**Environment:**
- No `.env` files (local-first app; no server-injected env)
- Secrets (master key, device keys) live in OS keychain via `flutter_secure_storage`, never in source
- Firebase: `android/app/google-services.json` present; iOS `GoogleService-Info.plist` not committed

**Build:**
- `pubspec.yaml` - Dependencies and asset declarations
- `analysis_options.yaml` - Linter config (single quotes, relative imports, avoid_print, custom_lint plugin)
- `build.yaml` - build_runner config
- `l10n.yaml` - Localization codegen (output class `S`, dir `lib/generated`, ARB in `lib/l10n`)
- `dart_test.yaml`, `devtools_options.yaml`

## Platform Requirements

**Development:**
- Flutter 3.44.0 stable, Dart `^3.10.8`
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after editing `@riverpod`/`@freezed`/Drift tables/ARB files
- `flutter gen-l10n` after ARB changes

**Production:**
- iOS 15.0+ (`ios/Podfile`), Android API 24+ (minSdk)
- iOS Podfile contains required `-lsqlite3` strip and `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64` fixes — do not remove

---

*Stack analysis: 2026-06-23*
