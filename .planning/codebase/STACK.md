# Technology Stack

**Analysis Date:** 2026-06-23

## Languages

**Primary:**
- Dart (SDK `^3.10.8`) - All application code in `lib/`

**Secondary:**
- Swift / Objective-C - iOS platform layer (`ios/Runner/`)
- Kotlin / Gradle - Android platform layer (`android/app/`)

## Runtime

**Environment:**
- Flutter SDK (Dart `^3.10.8`)
- Targets: iOS 14+ / Android 7+ (API 24+)

**Package Manager:**
- pub (Dart/Flutter)
- Manifest: `pubspec.yaml`
- Lockfile: `pubspec.lock` (present)

## Frameworks

**Core:**
- Flutter - Cross-platform UI framework
- flutter_riverpod `^3.1.0` + riverpod_annotation `^4.0.0` - State management (code-gen via `@riverpod`)
- freezed_annotation `^3.0.0` + json_annotation `^4.9.0` - Immutable models / serialization
- drift `^2.25.0` - Type-safe SQL ORM (schema v22)

**Testing:**
- flutter_test (SDK) - Unit/widget tests
- integration_test (SDK) - On-device encrypted-executor migration tests
- mocktail `^1.0.4` - Mocking
- fake_async `^1.3.3` - Time control

**Build/Dev:**
- build_runner `^2.4.14` - Code generation driver
- freezed `^3.0.0`, json_serializable `^6.9.4`, riverpod_generator `^4.0.0+1`, drift_dev `^2.25.0` - Generators
- custom_lint `^0.8.1` + riverpod_lint `^3.1.0` + import_guard_custom_lint `^1.0.0` - Lint/arch enforcement
- flutter_lints `^6.0.0`, dart_code_linter `^3.0.0` - Linting

## Key Dependencies

**Critical:**
- cryptography `^2.7.0`, crypto `^3.0.6`, pinenacl `^0.6.0` - Encryption / Ed25519 / ChaCha20
- flutter_secure_storage `^10.2.0` - Keychain/Keystore master-key storage (pinned accessibility — see CLAUDE.md)
- local_auth `^3.0.1` - Biometric lock
- sqlcipher_flutter_libs `^0.6.7` - SQLCipher native libs (NEVER `sqlite3_flutter_libs`)
- sqlite3 `^2.7.5`, drift `^2.25.0` - Encrypted database
- ulid `^2.0.0`, uuid `^4.5.3` - ID generation

**Infrastructure:**
- firebase_core `^4.1.1`, firebase_messaging `^16.0.1` - Push (FCM, Android)
- flutter_local_notifications `^21.0.0` - Local notification display
- web_socket_channel `^3.0.0`, http `^1.6.0`, connectivity_plus `^7.1.1` - P2P/relay sync transport
- speech_to_text `^7.0.0` - Voice entry
- fl_chart `^1.2.0` - Analytics charts
- table_calendar `^3.2.0`, qr_flutter `^4.1.0`, flutter_svg `^2.3.0`, lucide_icons_flutter `^3.1.14` - UI
- file_picker `^11.0.2`, image_picker `^1.1.2`, share_plus `^12.0.2`, package_info_plus `^9.0.1`, path_provider `^2.1.5` - File/IO (version-pinned trio — see CLAUDE.md)
- shared_preferences `^2.3.4` - Lightweight prefs

## Configuration

**Environment:**
- No `.env` files. Secrets handled via OS keychain (flutter_secure_storage), not env vars.
- intl pinned to exactly `0.20.2` (required by flutter_localizations)
- i18n config: `l10n.yaml` → class `S`, ARB dir `lib/l10n`, output `lib/generated`

**Build:**
- `pubspec.yaml` - Dependencies, assets (`assets/satisfaction/`), `generate: true`
- `analysis_options.yaml` - Lint + custom_lint rules
- `ios/Podfile` - CocoaPods (sqlite3 strip + EXCLUDED_ARCHS fixes — do not remove)
- `android/app/build.gradle.kts` - Android build, `applicationId com.sheanzero.happypocket.app`

## Platform Requirements

**Development:**
- Flutter SDK with Dart `^3.10.8`
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after editing `@riverpod`/`@freezed`/Drift tables/ARB files
- `flutter gen-l10n` after ARB changes

**Production:**
- iOS 14+ (CocoaPods, SQLCipher native)
- Android 7+ / API 24+ (Gradle, google-services.json for FCM)

---

*Stack analysis: 2026-06-23*
