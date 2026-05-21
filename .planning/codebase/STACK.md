# Technology Stack

**Analysis Date:** 2026-05-21

## Languages

**Primary:**
- Dart `^3.10.8` (SDK constraint in `pubspec.yaml`) — all application code in `lib/`
- Dart `>=3.38.4` (Flutter minimum per `pubspec.lock`) — runtime platform layer

**Secondary:**
- Kotlin — Android native (`android/app/src/main/kotlin/`), Java 17 target via `compileOptions`
- Swift/Objective-C — iOS native (`ios/Runner/`), minimum iOS 15.0 (Podfile line 1)
- Ruby — CocoaPods (`ios/Podfile`)

## Runtime

**Environment:**
- Flutter stable channel; version resolved from `pubspec.yaml` via `flutter-version-file` in CI
- Lock file minimum: `flutter: ">=3.38.4"` (`pubspec.lock`)
- iOS deployment target: **15.0** (`ios/Podfile` line 1) — CLAUDE.md states "iOS 14+" but Podfile sets 15.0
- Android: `minSdk = flutter.minSdkVersion` (delegates to Flutter default, API 24+ from CLAUDE.md); `compileSdk = flutter.compileSdkVersion`
- JVM: Java 17 (`android/app/build.gradle.kts` `compileOptions`)

**Package Manager:**
- Dart pub
- Lockfile: `pubspec.lock` — present and committed

## Frameworks

**Core:**
- Flutter (Material + Cupertino) — cross-platform UI framework
- `flutter_riverpod: ^3.1.0` (locked `3.1.0`) — reactive state management
- `drift: ^2.25.0` (locked `2.31.0`) — type-safe SQLite ORM with code generation
- `freezed_annotation: ^3.0.0` + `freezed: ^3.0.0` (locked `3.2.3`) — immutable data models via code generation

**Routing:**
- No `go_router` in pubspec; routing is handled via `Navigator.push` / `MaterialApp.home` pattern (see `lib/main.dart`)

**Internationalization:**
- `flutter_localizations` (Flutter SDK) + `flutter_gen-l10n` command
- Output class `S`, output dir `lib/generated/`, configured in `l10n.yaml`
- Template ARB: `lib/l10n/app_en.arb`; 3 locales: `ja`, `zh`, `en`

**Testing:**
- `flutter_test` (Flutter SDK) — unit + widget tests
- `mocktail: ^1.0.4` (locked `1.0.5`) — mock generation without codegen
- `fake_async: ^1.3.3` (locked `1.3.3`) — timer/async control in tests

**Build/Dev:**
- `build_runner: ^2.4.14` (locked `2.15.0`) — code generation orchestrator
- `riverpod_generator: ^4.0.0+1` (locked `4.0.0+1`) — `@riverpod` annotation processor
- `drift_dev: ^2.25.0` (locked `2.31.0`) — Drift table/DAO code generator
- `json_serializable: ^6.9.4` (locked via transitive) — JSON serialization codegen

## Key Dependencies

**Critical (production):**

| Package | Constraint | Locked | Purpose |
|---------|------------|--------|---------|
| `flutter_riverpod` | `^3.1.0` | `3.1.0` | State management (see CLAUDE.md Riverpod 3 conventions) |
| `riverpod_annotation` | `^4.0.0` | — | `@riverpod` annotation for code generation |
| `drift` | `^2.25.0` | `2.31.0` | SQLite ORM — Drift schema v17 at `lib/data/app_database.dart` |
| `sqlcipher_flutter_libs` | `^0.6.7` | `0.6.8` | SQLCipher AES-256-CBC encryption for database |
| `sqlite3` | `^2.7.5` | — | SQLite3 bindings (used with SQLCipher) |
| `freezed_annotation` | `^3.0.0` | — | `@freezed` for immutable models with `copyWith` |
| `cryptography` | `^2.7.0` | `2.9.0` | ChaCha20-Poly1305 AEAD field encryption (`lib/infrastructure/crypto/repositories/encryption_repository_impl.dart`) |
| `pinenacl` | `^0.6.0` | `0.6.0` | NaCl Box (X25519-XSalsa20-Poly1305) for E2EE sync (`lib/infrastructure/sync/e2ee_service.dart`) |
| `crypto` | `^3.0.6` | — | SHA-256 for request signing (`lib/infrastructure/sync/relay_api_client.dart`) |
| `flutter_secure_storage` | `^10.2.0` | `10.2.0` | Keychain/Keystore for device keys and master key |
| `local_auth` | `^3.0.1` | `3.0.1` | Biometric auth — Face ID / Touch ID / Fingerprint |
| `firebase_core` | `^4.1.1` | `4.9.0` | Firebase initialization (Android required for FCM) |
| `firebase_messaging` | `^16.0.1` | `16.2.2` | FCM push for family sync notifications |
| `flutter_local_notifications` | `^21.0.0` | `21.0.0` | Local notification display (foreground push) |
| `web_socket_channel` | `^3.0.0` | `3.0.3` | WebSocket to relay server (`lib/infrastructure/sync/websocket_service.dart`) |
| `http` | `^1.6.0` | `1.6.0` | REST calls to relay server (`lib/infrastructure/sync/relay_api_client.dart`) — only used here |
| `speech_to_text` | `^7.0.0` | `7.3.0` | Voice input (`lib/infrastructure/speech/speech_recognition_service.dart`) |
| `path_provider` | `^2.1.5` | — | Database file path resolution |
| `path` | `^1.9.1` | — | File path manipulation |

**Infrastructure:**

| Package | Constraint | Locked | Purpose |
|---------|------------|--------|---------|
| `intl` | `0.20.2` | — | **Exact pin** — required by `flutter_localizations`; bumping breaks localization build |
| `ulid` | `^2.0.0` | `2.0.1` | ULID generation for transaction IDs (`lib/application/accounting/`) |
| `uuid` | `^4.5.3` | `4.5.3` | UUID generation for sync/group IDs |
| `fl_chart` | `^1.2.0` | `1.2.0` | Charts for analytics screen (`lib/features/analytics/`) |
| `shared_preferences` | `^2.3.4` | `2.5.5` | Feature flags / lightweight preferences (e.g., joy metric variant state) |
| `image_picker` | `^1.1.2` | `1.2.2` | Profile avatar picking (`lib/features/profile/presentation/screens/avatar_picker_screen.dart`) |
| `file_picker` | `^11.0.2` | `11.0.2` | Backup import/export (`lib/features/settings/presentation/widgets/data_management_section.dart`) |
| `share_plus` | `^12.0.2` | `12.0.2` | Share invite codes and export files |
| `package_info_plus` | `^9.0.1` | `9.0.1` | App version display in settings |
| `qr_flutter` | `^4.1.0` | `4.1.0` | QR code generation for invite codes (in `pubspec.yaml`; no active import found — reserved for family sync invite flow) |
| `lucide_icons` | `^0.257.0` | `0.257.0` | Icon library used in family sync screens |
| `cupertino_icons` | `^1.0.8` | — | iOS-style icons |
| `collection` | `^1.19.1` | — | Dart collection utilities (`firstWhereOrNull`, etc.) |
| `json_annotation` | `^4.9.0` | — | `@JsonSerializable` support |

## Pinned and Constrained Versions

| Package | Constraint | Reason |
|---------|------------|--------|
| `intl` | `0.20.2` (exact) | Pinned by `flutter_localizations`; must not change independently |
| `file_picker` | `^11.0.2` | `^12.0.0-beta.*` has broken iOS Swift module; requires `win32 ^5.x` compat |
| `package_info_plus` | `^9.0.1` | `^10.x` requires `win32 ^6.0.1`, incompatible with `file_picker 11.x` |
| `share_plus` | `^12.0.2` | `^13.x` requires `win32 ^6.0.1`, same conflict |
| `sqlcipher_flutter_libs` | `^0.6.7` (locked `0.6.8`) | `0.7.0+eol` is a do-nothing package; project not yet migrated to `sqlite3` 3.x |

**Win32 trio constraint:** `file_picker`, `package_info_plus`, `share_plus` must be upgraded together when bumping; each depends on the same `win32` generation. See CLAUDE.md iOS Build section.

## Code Generation Toolchain

All four generators run via `flutter pub run build_runner build --delete-conflicting-outputs`:

1. **`riverpod_generator` `4.0.0+1`** — processes `@riverpod` annotations → `*.g.dart` providers
   - Provider naming: `class LocaleNotifier` → generates `localeProvider` (not `localeNotifierProvider`)
2. **`freezed` `3.2.3`** + **`json_serializable`** — processes `@freezed` + `@JsonSerializable` → `*.freezed.dart` + `*.g.dart`
   - Config in `build.yaml`: `explicit_to_json: true`, `format: true`
3. **`drift_dev` `2.31.0`** — processes `@DriftDatabase` + `@DriftAccessor` → `*.g.dart` DAOs and query code
   - Schema v17 at `lib/data/app_database.dart`
4. **`flutter gen-l10n`** — processes ARB files → `lib/generated/app_localizations*.dart`
   - Output class `S`, configured via `l10n.yaml`

CI guardrail (AUDIT-10): `build_runner` run in CI; git diff of `lib/` must be clean or PR is blocked.

## Linting and Static Analysis

- `flutter_lints: ^6.0.0` — base Flutter lint rules
- `custom_lint: ^0.8.1` (locked `0.8.1`) — plugin host for `riverpod_lint` and `import_guard_custom_lint`
- `riverpod_lint: ^3.1.0` (locked `3.1.0`) — Riverpod-specific lint rules
- `import_guard_custom_lint: ^1.0.0` (locked `1.0.0`) — enforces layer dependency rules; blocks `sqlite3_flutter_libs` imports
- `dart_code_linter: ^3.0.0` (locked `3.2.1`) — dead code and complexity metrics
- `analysis_options.yaml`: `prefer_single_quotes`, `prefer_relative_imports`, `avoid_print`; generated files excluded

## Configuration

**Environment:**
- No `.env` files present
- Sync server URL via `--dart-define=SYNC_SERVER_URL=...` (defaults to `https://sync.happypocket.app/api/v1`)
- In-memory database toggle: `const _useInMemoryDatabase = false` in `lib/main.dart`
- Firebase Android: `android/app/google-services.json` (committed)
- Firebase iOS: `GoogleService-Info.plist` not detected in repo (likely gitignored for iOS)

**Build:**
- `build.yaml` — code generation options (Freezed `format: true`, json_serializable `explicit_to_json: true`)
- `l10n.yaml` — ARB dir `lib/l10n`, output class `S`, output dir `lib/generated`
- `analysis_options.yaml` — linting configuration

## CI/CD

**Pipeline:** `.github/workflows/audit.yml` — runs on every PR/push to `main`

Three jobs:
1. **`static-analysis`**: `flutter analyze --no-fatal-infos`, `dart run custom_lint --no-fatal-infos`, audit scripts (layer, dead code, providers, duplication), findings merged to `.planning/audit/`
2. **`guardrails`**: AUDIT-09 (rejects `sqlite3_flutter_libs` in lock), AUDIT-10 (stale generated files diff check)
3. **`coverage`**: `flutter test --coverage`, `coverde filter` strips generated files, per-file coverage gate at **70%** (threshold amended from 80% on 2026-04-28; see audit.yml header), `VeryGoodOpenSource/very_good_coverage@v2`

Coverage tool: `coverde 0.3.0+1` (activated globally via `dart pub global activate`)

## Platform Requirements

**Development:**
- Flutter stable channel, Dart SDK `^3.10.8`
- CocoaPods for iOS dependencies
- Android SDK (via local.properties: `sdk.dir=/Users/xinz/Library/Android/sdk`)
- `flutter pub run build_runner build --delete-conflicting-outputs` required after any `@riverpod`, `@freezed`, Drift table, or ARB change

**Production:**
- iOS 15.0+ (Podfile enforces this; CLAUDE.md lists iOS 14+ as target but Podfile is 15.0)
- Android API 24+ (`minSdk = flutter.minSdkVersion`, CLAUDE.md specifies API 24)
- Kotlin + Java 17 on Android
- Firebase google-services plugin required on Android (`com.google.gms.google-services` in `build.gradle.kts`)

---

*Stack analysis: 2026-05-21*
