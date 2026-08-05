# Technology Stack

**Analysis Date:** 2026-08-05
**Last mapped commit:** `7b4f1bac44644ea821835e85d09d9571a601e82a`

## Languages

**Primary:**
- Dart (SDK `^3.10.8`) - Flutter application in `lib/`

**Secondary:**
- Swift/Objective-C - iOS host in `ios/Runner/`
- Kotlin/Gradle - Android host in `android/`
- ARB/JSON - localized resources in `lib/l10n/`

## Runtime

**Environment:** Flutter 3.44.0 (CI pin in `.github/workflows/audit.yml`), Dart `^3.10.8`

**Package Manager:** pub; lockfile `pubspec.lock` is present.

**Targets:** iOS 15+ and Android API 24+ (`android/app/build.gradle.kts`).

## Frameworks

**Core:**
- Flutter with Material Design - UI/runtime (`pubspec.yaml`)
- Riverpod 3.1 + riverpod_generator 4 - generated application state providers
- Drift 2.25 over SQLCipher - typed encrypted SQLite persistence
- Freezed/json_serializable - immutable models and JSON conversion
- GoRouter - declarative navigation (`lib/core/router/`)

**Testing:**
- `flutter_test`, `integration_test`, `mocktail`, and `fake_async`

**Build/Dev:**
- `build_runner`, `drift_dev`, `freezed`, `json_serializable`, `riverpod_generator`
- Flutter localization generation (`l10n.yaml` -> `lib/generated/`)
- `flutter_lints`, `custom_lint`, `riverpod_lint`, `import_guard_custom_lint`, `dart_code_linter`

## Key Dependencies

**Critical:**
- `drift ^2.25.0`, `sqlcipher_flutter_libs ^0.6.7`, `sqlite3 ^2.7.5` - encrypted database (schema version 36 in `lib/data/app_database.dart`)
- `cryptography`, `crypto`, `pinenacl` - AEAD, hashing, and Ed25519 cryptography
- `flutter_secure_storage ^10.2.0` - OS keychain/keystore key material
- `local_auth ^3.0.1` - biometric app lock

**Feature/UI:**
- `speech_to_text`, `fl_chart`, `table_calendar`, `qr_flutter`, `image_picker`
- `file_picker`, `share_plus`, `url_launcher`, `flutter_svg`, `lucide_icons_flutter`

**Infrastructure:**
- `http`, `web_socket_channel`, `connectivity_plus` - relay and network transport
- `firebase_core`, `firebase_messaging`, `flutter_local_notifications` - push notifications
- `shared_preferences`, `path_provider`, `path` - settings and local files

## Configuration

**Environment:** No `.env` files detected. Runtime relay configuration uses `--dart-define=SYNC_SERVER_URL` (default in `lib/infrastructure/sync/relay_api_client.dart`); secrets remain in secure storage.

**Build/config files:** `pubspec.yaml`, `analysis_options.yaml`, `build.yaml`, `l10n.yaml`, `ios/Podfile`, `android/app/build.gradle.kts`.

**Platform notes:** `ios/Podfile` preserves SQLCipher `-lsqlite3` stripping and simulator architecture exclusions; Android Firebase plugin is configured in `android/settings.gradle.kts` and `android/app/build.gradle.kts`.

## Platform Requirements

**Development:** Flutter 3.44.0, Dart 3.10.8, macOS for iOS builds and golden baselines; run code generation after annotated source/schema/ARB changes.

**Production:** iOS 15+ / Android 7+ mobile distribution; self-hosted sync relay is external to this repository.

---

*Stack analysis: 2026-08-05*
