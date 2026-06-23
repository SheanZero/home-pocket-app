# Technology Stack

**Analysis Date:** 2026-06-23

## Languages

**Primary:**
- Dart (SDK `^3.10.8`) - All application code under `lib/`, tests under `test/`

**Secondary:**
- Swift / Objective-C - iOS platform layer (`ios/Runner/`)
- Kotlin / Groovy - Android platform layer + Gradle (`android/app/build.gradle`)
- ARB (JSON) - Localization message catalogs (`lib/l10n/app_{en,ja,zh}.arb`)
- YAML - Config, CI, build (`pubspec.yaml`, `build.yaml`, `l10n.yaml`, `.github/workflows/audit.yml`)

## Runtime

**Environment:**
- Flutter 3.44.0 (stable channel) - pinned in CI (`.github/workflows/audit.yml`)
- Dart SDK `^3.10.8` (`pubspec.yaml` line 7)

**Target Platforms:**
- iOS 15.0+ (`ios/Podfile`: `platform :ios, '15.0'`) — note: CLAUDE.md states iOS 14+, Podfile enforces 15.0
- Android 7+ / API 24+ (`android/app/build.gradle`, Flutter default minSdk)

**Package Manager:**
- pub (Dart/Flutter)
- Lockfile: `pubspec.lock` present (committed)

## Frameworks

**Core:**
- Flutter (SDK) - UI framework
- Riverpod `^3.1.0` (`flutter_riverpod`) + `riverpod_annotation ^4.0.0` - State management with code generation
- Freezed `^3.0.0` (`freezed_annotation`) - Immutable models / unions
- Drift `^2.25.0` - Type-safe SQL ORM (database)
- GoRouter - Routing (declared in `lib/core/router/`)

**Testing:**
- `flutter_test` (SDK) - Test runner + widget testing
- `mocktail ^1.0.4` - Mocking
- `fake_async ^1.3.3` - Deterministic async/timer testing

**Build/Dev:**
- `build_runner ^2.4.14` - Code generation orchestrator
- `freezed ^3.0.0`, `json_serializable ^6.9.4`, `riverpod_generator ^4.0.0+1`, `drift_dev ^2.25.0` - Generators
- `custom_lint ^0.8.1` + `riverpod_lint ^3.1.0` + `import_guard_custom_lint ^1.0.0` - Lint plugins
- `flutter_lints ^6.0.0` - Base lint ruleset
- `dart_code_linter ^3.0.0` - Audit tooling

## Key Dependencies

**Critical:**
- `drift ^2.25.0` + `sqlcipher_flutter_libs ^0.6.7` + `sqlite3 ^2.7.5` - Encrypted local database (SQLCipher AES-256). NEVER use `sqlite3_flutter_libs` (conflict).
- `cryptography ^2.7.0` + `crypto ^3.0.6` + `pinenacl ^0.6.0` - Field encryption (ChaCha20-Poly1305), hashing, Ed25519 keys
- `flutter_secure_storage ^10.2.0` - OS keychain/keystore for master keys
- `local_auth ^3.0.1` - Biometric lock

**State / Models:**
- `flutter_riverpod ^3.1.0`, `riverpod_annotation ^4.0.0`
- `freezed_annotation ^3.0.0`, `json_annotation ^4.9.0`

**Networking / Sync:**
- `http ^1.6.0` - REST (relay API, exchange-rate fetch)
- `web_socket_channel ^3.0.0` - P2P/relay sync transport
- `connectivity_plus ^7.1.1` - Network state

**Firebase / Notifications:**
- `firebase_core ^4.1.1`, `firebase_messaging ^16.0.1` - Push (FCM)
- `flutter_local_notifications ^21.0.0` - Local notifications

**Platform / IO:**
- `path_provider ^2.1.5`, `path ^1.9.1`
- `file_picker ^11.0.2` (PINNED — do not bump in isolation), `image_picker ^1.1.2`
- `share_plus ^12.0.2` (PINNED), `package_info_plus ^9.0.1` (PINNED) — version-locked trio via `win32` constraint
- `shared_preferences ^2.3.4`

**UI / Misc:**
- `fl_chart ^1.2.0` - Charts (analytics)
- `table_calendar ^3.2.0`, `qr_flutter ^4.1.0`, `flutter_svg ^2.3.0`, `lucide_icons_flutter ^3.1.14`, `cupertino_icons ^1.0.8`
- `speech_to_text ^7.0.0` - Voice entry
- `ulid ^2.0.0`, `uuid ^4.5.3` - ID generation
- `intl 0.20.2` (EXACT pin — required by `flutter_localizations`), `collection ^1.19.1`

## Configuration

**Internationalization (`l10n.yaml`):**
- ARB dir: `lib/l10n`, template: `app_en.arb`
- Output class `S`, output dir `lib/generated`, `nullable-getter: false`
- Languages: ja (default), zh, en. Run `flutter gen-l10n` after ARB changes.

**Code generation (`build.yaml`):**
- `freezed`: format enabled
- `json_serializable`: `explicit_to_json: true`

**Analyzer (`analysis_options.yaml`):**
- Extends `package:flutter_lints/flutter.yaml`
- Excludes `**/*.g.dart`, `**/*.freezed.dart`, `build/**`
- `custom_lint` plugin enabled
- Custom rules: `prefer_single_quotes`, `prefer_relative_imports`, `avoid_print`

**Environment variables:**
- No `.env` files detected. Configuration is compile-time constants + secure storage at runtime.

## Platform Requirements

**Development:**
- Flutter 3.44.0 stable, Dart `^3.10.8`
- After modifying `@riverpod`/`@freezed`/Drift tables/ARB: `flutter pub run build_runner build --delete-conflicting-outputs`
- iOS clean rebuild requires `pod install`; `Podfile` `post_install` strips `-lsqlite3` (do not remove — protects SQLCipher symbol resolution)

**Production:**
- iOS 15+ / Android 7+ (API 24+)
- Database schema version: **21** (`lib/data/app_database.dart` line 49)

---

*Stack analysis: 2026-06-23*
