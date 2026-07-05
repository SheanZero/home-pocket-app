# Technology Stack

**Analysis Date:** 2026-07-05

## Languages

**Primary:**
- Dart `^3.10.8` (SDK constraint in `pubspec.yaml`) - All application code under `lib/`

**Secondary:**
- Kotlin - Android host (`android/app/build.gradle.kts`, plugin glue)
- Swift / Objective-C - iOS host (`ios/Runner/`)
- SQL - Drift-generated and hand-written DDL/migrations (`lib/data/app_database.dart`)
- Markdown - Bundled offline legal documents (`assets/legal/*.md`, first `rootBundle` text assets)

## Runtime

**Environment:**
- Flutter SDK (Dart `^3.10.8`). Targets iOS 15+ (`ios/Podfile` `platform :ios, '15.0'`) and Android (minSdk/targetSdk/compileSdk inherited from Flutter via `flutter.minSdkVersion` etc. in `android/app/build.gradle.kts`). Product target per CLAUDE.md is iOS 14+ / Android 7+ (API 24+); the Podfile pins the iOS build floor to 15.0.

**Package Manager:**
- pub (Flutter/Dart). Manifest: `pubspec.yaml`
- Lockfile: `pubspec.lock` (present, committed)
- iOS native: CocoaPods (`ios/Podfile`, `ios/Podfile.lock`)
- Android native: Gradle Kotlin DSL (`android/app/build.gradle.kts`)

## Frameworks

**Core:**
- Flutter (Material, `uses-material-design: true`) - UI framework
- Riverpod `flutter_riverpod ^3.1.0` (resolved 3.1.0) + `riverpod_annotation ^4.0.0` - State management (code-gen via `@riverpod`)
- Freezed `freezed_annotation ^3.0.0` (resolved 3.1.0) - Immutable models + unions
- Drift `^2.25.0` (resolved 2.31.0) - Type-safe SQL ORM over SQLCipher

**Testing:**
- `flutter_test` (SDK) - Unit/widget/golden tests
- `integration_test` (SDK) - On-device/simulator SQLCipher migration ladder (`integration_test/`)
- `mocktail ^1.0.4` - Mocking
- `fake_async ^1.3.3` - Deterministic async testing
- `plugin_platform_interface ^2.1.8`, `url_launcher_platform_interface ^2.3.2` - **NEW (Phase 56)** dev-only; mock `UrlLauncherPlatform.instance` in the sponsor-launch widget test (56-05)

**Build/Dev:**
- `build_runner ^2.4.14` - Code generation driver
- `freezed ^3.0.0`, `json_serializable ^6.9.4`, `riverpod_generator ^4.0.0+1`, `drift_dev ^2.25.0` - Generators
- `flutter_lints ^6.0.0`, `custom_lint ^0.8.1`, `riverpod_lint ^3.1.0` - Linting
- `import_guard_custom_lint ^1.0.0`, `dart_code_linter ^3.0.0`, `yaml ^3.1.0` - Architecture/import enforcement and arch tests

## Key Dependencies

**Critical:**
- `drift ^2.25.0` (resolved 2.31.0) + `sqlcipher_flutter_libs ^0.6.7` (resolved 0.6.8) + `sqlite3 ^2.7.5` - Encrypted database. NEVER swap to `sqlite3_flutter_libs` (conflict; SQLCipher symbols must win at runtime)
- `cryptography ^2.7.0` (resolved 2.9.0) - ChaCha20-Poly1305 field encryption, HKDF, **and now Argon2id + AES-256-GCM** for both `.hpb` backup encryption and the app-lock PIN KDF. No new crypto package was added for Argon2id — it ships inside this existing dependency.
- `crypto ^3.0.6` - SHA-256 (hash chain, request signing)
- `pinenacl ^0.6.0` - Ed25519 device keys / NaCl primitives
- `flutter_secure_storage ^10.2.0` - Keychain/Keystore master key + PIN PHC slot (accessibility level `unlocked_this_device` — do not change, bricks existing installs)
- `local_auth ^3.0.1` - Biometric unlock (app-lock)
- `ulid ^2.0.0`, `uuid ^4.5.3` - Identifier generation

**Feature dependencies:**
- `speech_to_text ^7.0.0` (resolved 7.3.0) - Voice input (PTT entry)
- `fl_chart ^1.2.0` - Analytics charts (donut/overview)
- `table_calendar ^3.2.0` - Calendar UI
- `qr_flutter ^4.1.0` - QR codes (family sync invite)
- `url_launcher ^6.3.2` (resolved 6.3.2) - **NEW (Phase 56)** launches the sponsor URL in the external browser (`lib/features/settings/presentation/widgets/legal_sponsor_section.dart`). `url_launcher_windows` has no `win32` dep, so it is safe alongside the pinned `win32` trio.
- `flutter_svg ^2.3.0`, `lucide_icons_flutter ^3.1.14`, `cupertino_icons ^1.0.8` - Iconography/vector assets

**Infrastructure:**
- `firebase_core ^4.1.1` (resolved 4.9.0), `firebase_messaging ^16.0.1` (resolved 16.2.2) - Push (Android FCM; iOS uses APNs directly — see INTEGRATIONS.md)
- `flutter_local_notifications ^21.0.0` - Local notification display
- `web_socket_channel ^3.0.0` - Sync relay WebSocket transport
- `connectivity_plus ^7.1.1` - Network state for sync scheduling
- `http ^1.6.0` - Relay API + exchange-rate fetches
- `shared_preferences ^2.3.4` - Lightweight settings (plaintext; see CONCERNS)
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
- External URL placeholders: `lib/core/config/legal_urls.dart` — compile-time `const` placeholders (`privacyPolicyHosted`, `termsOfUseHosted`, `donation`) each marked `上线前填真实值` (fill real value before launch). Only `donation` is launched in-app; the hosted privacy/terms URLs are for App Store Connect submission metadata.

**Assets (`pubspec.yaml` `flutter.assets`):**
- `assets/satisfaction/` - Satisfaction-level SVGs (`sat_01.svg` … `sat_05.svg`)
- `assets/legal/` - **NEW (Phase 56)** bundled offline legal docs: `privacy_{ja,zh,en}.md`, `terms_{ja,zh,en}.md`, `tokusho_{ja,zh,en}.md` (9 files; 特商法 = 特定商取引法 / Act on Specified Commercial Transactions). Rendered offline by `LegalDocScreen` via `rootBundle.loadString`.

**Build:**
- `pubspec.yaml` - Dependencies + assets
- `android/app/build.gradle.kts` - Android build (`namespace com.sheanzero.happypocket.app`, `applicationId com.sheanzero.happypocket.app`, `firebase-bom 34.9.0`, `com.google.gms.google-services` plugin)
- `android/app/google-services.json` - Firebase Android config (present, committed)
- `ios/Podfile` - CocoaPods. Critical `post_install`: strips `-lsqlite3` from every pod xcconfig (else system libsqlite3 wins over SQLCipher) + `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64` for ML Kit
- `ios/Runner/Info.plist` - iOS permission strings: `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` (voice entry), `NSFaceIDUsageDescription` (**NEW, Phase 55-12** — app-lock; its absence caused a Face ID TCC crash on biometric-only unlock)
- `analysis_options.yaml` - Lint + custom_lint (import_guard) rules

## Database

- Drift schema **version 23** (`schemaVersion => 23` in `lib/data/app_database.dart`) — **up from v22 at the 2026-06-27 map**
- 15 tables: `AuditLogs`, `Books`, `Categories`, `CategoryKeywordPreferences`, `CategoryLedgerConfigs`, `ExchangeRates`, `GroupMembers`, `Groups`, `MerchantCategoryPreferences`, `MerchantMatchKeys`, `Merchants`, `ShoppingItems`, `SyncQueue`, `Transactions`, `UserProfiles`
- Migration ladder runs `from < N` steps (v3 … v23):
  - v19→v20 (Phase 36): `shopping_items` table
  - v20→v21 (Phase 40): `exchange_rates` table + three nullable transaction currency-provenance columns (`original_currency`, `original_amount`, `applied_rate`)
  - v21→v22 (Phase 49): `merchants` + `merchant_match_keys` tables
  - **v22→v23 (NEW): index backfill** via `_createAllDeclaredIndexes()`. The `customIndices` getter is decorative (never consumed by Drift's migrator); 19 declared indices were never created, and audit_logs / user_profiles / category_ledger_configs indices previously existed only on upgraded devices. `CREATE INDEX IF NOT EXISTS` makes the backfill idempotent per device.
- SQLCipher: AES-256-CBC, 256k PBKDF2, via `createEncryptedExecutor`
- Explicit index creation helpers in both onCreate and onUpgrade: `_createShoppingItemIndexes`, `_createExchangeRateIndexes`, `_createMerchantIndexes`, `_createAllDeclaredIndexes`

## Cryptography Summary

- **DB layer:** SQLCipher AES-256-CBC (256k PBKDF2) — `createEncryptedExecutor`
- **Field layer:** ChaCha20-Poly1305 AEAD + HKDF — `cryptography` package (`lib/infrastructure/crypto/services/field_encryption_service.dart`)
- **Backup (`.hpb`) layer:** **Argon2id (m=19456 KiB, t=2, p=1, 32-byte) + AES-256-GCM** with a self-describing versioned header (`HPB` magic + version 2 + KDF params + salt + nonce + ciphertext + mac). Legacy headerless PBKDF2-HMAC-SHA256 (100k) files stay importable via auto-detect. Impl: `lib/infrastructure/crypto/services/backup_crypto_service.dart` (**relocated here from the settings layer + KDF upgraded PBKDF2→Argon2id, commit `84eb8f7a`**). KDF runs off-isolate via `Isolate.run`; header-supplied params are capped to prevent a hostile file demanding unbounded memory.
- **App-lock PIN:** **Argon2id (same OWASP profile) → PHC string** `argon2id$v=19$m=19456,t=2,p=1$<salt>$<hash>` stored in the keychain `pinHash` slot; constant-time compare via `constantTimeBytesEquality`. Impl: `lib/infrastructure/security/pin_kdf.dart` (**NEW, Phase 55**). Plaintext PIN never stored/compared.
- **Device identity:** Ed25519 (`pinenacl`) via `KeyManager`; BIP39 recovery phrase
- **Hash chain integrity:** SHA-256 (`crypto` package) — `lib/infrastructure/crypto/services/hash_chain_service.dart`

## Platform Requirements

**Development:**
- Flutter SDK with Dart `^3.10.8`
- macOS required for golden test baselines (goldens are macOS-baselined; CI ubuntu uses `BaselineExistenceGoldenComparator`)
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after modifying `@riverpod`, `@freezed`, Drift tables, or ARB files
- iOS clean rebuild requires `pod install` after `flutter clean`

**Production:**
- iOS 14+ / Android 7+ (API 24+); iOS build floor 15.0 (Podfile)
- App ID: `com.sheanzero.happypocket.app`
- On-device features requiring hardware/permissions: microphone + speech recognition (voice entry), Face ID / biometrics (app-lock), keychain/keystore (secure storage)

---

*Stack analysis: 2026-07-05*
