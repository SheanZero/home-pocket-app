# Technology Stack

**Analysis Date:** 2026-08-08

## Languages

**Primary:**
- Dart 3.10.8 (`pubspec.yaml`) — Flutter application, domain, data, infrastructure, and tests in `lib/`, `test/`, and `integration_test/`.

**Secondary:**
- Swift/Objective-C — iOS host and APNs bridge in `ios/Runner/AppDelegate.swift` and generated plugin registration.
- Kotlin/Java — Android host/plugin registration under `android/app/`.

## Runtime

**Environment:**
- Flutter SDK (Material app targeting iOS 15+ and Android 7+; SDK constraint is Dart `^3.10.8`).

**Package Manager:**
- Dart Pub/Flutter (`pubspec.yaml`)
- Lockfile: present (`pubspec.lock`)

## Frameworks

**Core:**
- Flutter with Material/Cupertino — cross-platform UI (`lib/main.dart`).
- Riverpod 3.3.2 + riverpod_annotation 4.0.3 — generated dependency/state management.
- Drift 2.34.0 — typed SQLite persistence and DAOs in `lib/data/`.
- GoRouter — declarative navigation under `lib/core/router/`.
- Freezed/json_serializable — immutable models and JSON code generation.

**Testing:**
- `flutter_test`, `integration_test`, `mocktail`, and `fake_async`; architecture tests live in `test/architecture/`.

**Build/Dev:**
- `build_runner`, `riverpod_generator`, `drift_dev`, `freezed`, `json_serializable`.
- `flutter gen-l10n` generates `lib/generated/` from `lib/l10n/*.arb`.
- `flutter_lints`, `riverpod_lint`, `import_lint`, and `dart_code_linter` enforce quality/boundaries.

## Key Dependencies

**Critical:**
- `sqlite3` 3.3.1 + Drift — SQLCipher Native Assets selected by `hooks.user_defines.sqlite3.source: sqlcipher` in `pubspec.yaml`.
- `cryptography`, `crypto`, `pinenacl` — field/file encryption, hashing, and Ed25519/E2EE in `lib/infrastructure/crypto/` and `lib/infrastructure/sync/`.
- `flutter_secure_storage`, `local_auth` — key storage and biometric app lock.
- `flutter_riverpod`, `riverpod_generator` — application wiring and generated providers.

**Infrastructure:**
- `http`, `web_socket_channel`, `connectivity_plus` — REST, realtime sync, and network reachability.
- `firebase_core`, `firebase_messaging`, `flutter_local_notifications` — push notification lifecycle.
- `speech_to_text`, `fl_chart`, `table_calendar` — voice input, charts, and calendar UI.
- `path_provider`, `file_picker`, `image_picker`, `share_plus`, `url_launcher` — local files, import/export, sharing, and hosted legal/support links.
- `shared_preferences` — non-sensitive settings; `intl`, `flutter_localizations` — Japanese/Chinese/English localization and formatting.

## Configuration

**Environment:**
- Compile-time sync endpoint override: `--dart-define=SYNC_SERVER_URL=...`, consumed by `lib/infrastructure/sync/relay_api_client.dart`.
- No environment files are read by application code; platform Firebase/APNs setup is host-managed.

**Build:**
- `pubspec.yaml` (dependencies, assets, fonts, SQLCipher hook), `analysis_options.yaml`, `android/build.gradle.kts`, and `ios/Podfile`.
- Generated Dart/plugin registrants are produced by Flutter/build_runner; do not hand-edit generated outputs.

## Platform Requirements

**Development:**
- Flutter/Dart toolchain, Android SDK and/or Xcode for native verification; run `flutter pub get`, code generation, `flutter analyze`, and tests.

**Production:**
- iOS 15+ and Android 7+ binaries with native SQLCipher asset, secure storage, biometric APIs, and APNs/FCM notification integration.

---

*Stack analysis: 2026-08-08*
