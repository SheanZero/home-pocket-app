# External Integrations

**Analysis Date:** 2026-04-25

## APIs & External Services

**Sync Relay (HTTPS REST):**
- Service: Custom relay server at `https://sync.happypocket.app/api/v1`
- Override at build time via `--dart-define=SYNC_SERVER_URL=...`
- Client: `RelayApiClient` (`lib/infrastructure/sync/relay_api_client.dart`)
- Auth: Ed25519 signed `Authorization` header
  - Format: `Ed25519 <deviceId>:<timestamp>:<base64Signature>`
  - Signature message: `<method>:<path>:<timestamp>:<SHA256(body)>`
  - Implemented by `RequestSigner` (`lib/infrastructure/sync/relay_api_client.dart`, lines 19-50)
- Endpoints used:
  - `POST /device/register` (unauthenticated, idempotent)
  - `PUT /device/push-token` (authenticated)
  - Group lifecycle (`/group/...`) and CRDT pull/push
- Note: Server URL is a public default — no API keys are bundled in the app. All authentication flows from the device's Ed25519 keypair.

**Sync Relay (WebSocket):**
- Service: `wss://sync.happypocket.app` (derived from REST base URL)
- Client: `WebSocketService` (`lib/infrastructure/sync/websocket_service.dart`)
- Library: `web_socket_channel` `^3.0.0`
- Purpose: realtime group status notifications during waiting/approval
- Events: `memberConfirmed`, `joinRequest`, `memberLeft`, `groupDissolved`, `groupStatus`, `syncAvailable`
- Degradation strategy: WebSocket (primary) → push notification (backup) → polling (fallback)
- Auth: Ed25519 signed message via injected `SignMessageFn`

**Firebase Cloud Messaging (FCM):**
- Service: Google Firebase (Android push notifications)
- SDKs: `firebase_core` `^4.1.1`, `firebase_messaging` `^16.0.1`
- Initialization: `firebase_core` per platform (Android uses `google-services.json`)
- Auth/Config: `android/app/google-services.json` (gitignored — contains API keys; existence noted only, contents not read)
- Android SDK plugin: `com.google.gms.google-services` (in `android/app/build.gradle.kts`)
- BOM: `com.google.firebase:firebase-bom:34.9.0`
- Implementation: `FirebasePushMessagingClient` (`lib/infrastructure/sync/push_notification_service.dart`, lines 106-138)

**Apple Push Notification service (APNs):**
- Service: Apple APNs (iOS push notifications via custom native bridge)
- Implementation: `MethodChannelApnsPushBridge` (`lib/infrastructure/sync/apns_push_messaging_client.dart`)
- Method channels:
  - Methods: `home_pocket/apns_push/methods`
  - Token refresh: `home_pocket/apns_push/token_refresh`
  - Foreground messages: `home_pocket/apns_push/foreground_messages`
  - Opened messages: `home_pocket/apns_push/opened_messages`
- Background mode declared in `ios/Runner/Info.plist` (`UIBackgroundModes`: `remote-notification`)

## Data Storage

**Primary Database:**
- Provider: Local SQLite via SQLCipher (AES-256-CBC, PBKDF2-HMAC-SHA512, 256,000 iterations)
- Library: `drift` `^2.25.0` + `sqlcipher_flutter_libs` `^0.6.7` + `sqlite3` `^2.7.5`
- Schema definition: `lib/data/app_database.dart` (`schemaVersion = 14`)
- Encrypted executor factory: `lib/infrastructure/crypto/database/encrypted_database.dart` (`createEncryptedExecutor`)
- Native loader: `ensureNativeLibrary()` (overrides sqlite3 → SQLCipher on Android)
- Database file: `<documents>/databases/home_pocket.db` (per `path_provider`)
- Tables (`lib/data/tables/`): `audit_logs_table.dart`, `books_table.dart`, `categories_table.dart`, `category_keyword_preferences_table.dart`, `category_ledger_configs_table.dart`, `group_members_table.dart`, `groups_table.dart`, `merchant_category_preferences_table.dart`, `sync_queue_table.dart`, `transactions_table.dart`, `user_profiles_table.dart`
- DAOs: `lib/data/daos/` (12 DAO files)
- Repositories: `lib/data/repositories/` (12 implementations)
- Connection: encryption key derived via HKDF-SHA256 from master key (`MasterKeyRepository.deriveKey('database_encryption')`)
- IMPORTANT: `sqlite3_flutter_libs` is forbidden (conflicts with SQLCipher per `CLAUDE.md`)

**Secure Key-Value Storage:**
- Service: iOS Keychain / Android Keystore via `flutter_secure_storage` `^9.2.4`
- Wrapper: `SecureStorageService` (`lib/infrastructure/security/secure_storage_service.dart`)
- iOS option: `KeychainAccessibility.unlocked_this_device` (no iCloud sync)
- Android option: `encryptedSharedPreferences: true`
- Centralized keys in `StorageKeys`: `device_private_key`, `device_public_key`, `device_id`, `pin_hash`, `recovery_kit_hash`, `master_key`

**Non-sensitive preferences:**
- Library: `shared_preferences` `^2.3.4`
- Used for app settings (e.g., theme mode, locale)

**File Storage:**
- Local filesystem only (`path_provider` resolves application documents dir)
- No remote object storage (S3, Firebase Storage, etc.) configured
- File operations: `file_picker` `^8.1.6`, `image_picker` `^1.1.2`, `share_plus` `^10.1.4`

**Caching:**
- None as a dedicated layer — Drift queries serve as the cache via local-first design

## Authentication & Identity

**Device Identity:**
- Service: Self-managed Ed25519 device keypair (no third-party auth provider)
- Implementation: `KeyManager` (`lib/infrastructure/crypto/services/key_manager.dart`)
- Library: `cryptography` `^2.7.0` (Ed25519 signing/verify)
- Key storage: `KeyRepository` impls (`lib/infrastructure/crypto/repositories/key_repository_impl.dart`) backed by `SecureStorageService`
- Device ID format: SHA-256(publicKey) first 16 chars
- Recovery: BIP39-style seed (`KeyManager.recoverFromSeed`) — per `CLAUDE.md` ARCH-003

**User Authentication (local):**
- Biometric: `BiometricService` (`lib/infrastructure/security/biometric_service.dart`)
  - Library: `local_auth` `^2.3.0`
  - Supports Face ID, Touch ID, fingerprint, Android BIOMETRIC_STRONG (Class 3) and BIOMETRIC_WEAK (Class 2)
  - Lockout policy: max 3 consecutive failures
- PIN: SHA-256 hash stored in secure storage as `pin_hash`

**End-to-End Encryption (E2EE):**
- Service: NaCl Box (X25519 + XSalsa20-Poly1305)
- Library: `pinenacl` `^0.6.0`
- Implementation: `E2EEService` (`lib/infrastructure/sync/e2ee_service.dart`)
- Key conversion: Ed25519 keys converted to X25519 via TweetNaCl primitives
- Output format: `base64(nonce_24bytes + ciphertext)`
- Group key: 32-byte random key, distributed via per-recipient NaCl box

**Hash Chain Integrity:**
- Service: blockchain-style append-only hash chain (`lib/infrastructure/crypto/services/hash_chain_service.dart`)
- Verification: `ChainVerificationResult` model (`lib/infrastructure/crypto/models/chain_verification_result.dart`)

## Monitoring & Observability

**Error Tracking:**
- None configured (no Sentry, Crashlytics, Bugsnag, or similar in `pubspec.yaml`)
- Firebase Analytics IS included on Android (`android/app/build.gradle.kts`: `com.google.firebase:firebase-analytics`) but no Dart `firebase_analytics` package — currently passive/native-only

**Logs:**
- `dart:developer` `dev.log` (used in `lib/main.dart` with `name: 'AppInit'`)
- `flutter/foundation.dart` `debugPrint` (used in `RequestSigner` for debug-only request inspection)
- App-level audit log: `AuditLogger` (`lib/infrastructure/security/audit_logger.dart`) writes to `audit_logs_table.dart`
- `avoid_print` is disabled in `analysis_options.yaml` (warning, not error)

## CI/CD & Deployment

**Hosting:**
- Mobile app distribution (App Store / Google Play); no `.github/workflows/` or `.gitlab-ci.yml` directories detected at root
- iOS bundle id: `com.sheanzero.happypocket.app`
- Android applicationId: `com.sheanzero.happypocket.app`

**CI Pipeline:**
- None detected (no CI config files in standard locations)

## Environment Configuration

**Required env vars (build-time `--dart-define`):**
- `SYNC_SERVER_URL` (optional) — overrides default relay URL `https://sync.happypocket.app/api/v1` (`lib/infrastructure/sync/relay_api_client.dart`)

**Required platform config files:**
- `android/app/google-services.json` — Firebase config (gitignored; contents NOT read by analysis)

**Secrets location:**
- Per-device runtime secrets: iOS Keychain / Android Keystore via `flutter_secure_storage` (`lib/infrastructure/security/secure_storage_service.dart`)
- No build-time secrets bundled in the Dart source. Server-side authentication uses the per-device Ed25519 keypair generated on first launch (`lib/main.dart` lines 44-57).

**Sensitive data NEVER logged or stored in plaintext:**
- Master key, device private key, PIN hash, recovery kit hash, group keys, transaction field values

## Webhooks & Callbacks

**Incoming (push notifications):**
- FCM data messages → `FirebasePushMessagingClient.onMessage` / `onMessageOpenedApp` (`lib/infrastructure/sync/push_notification_service.dart`)
- APNs (iOS) via method channels: `home_pocket/apns_push/foreground_messages`, `home_pocket/apns_push/opened_messages`, `home_pocket/apns_push/token_refresh`
- WebSocket events from relay: `WebSocketService` (`lib/infrastructure/sync/websocket_service.dart`)
- Local notifications channel: `family_sync` (`FlutterLocalNotificationClient` in `push_notification_service.dart`)

**Outgoing:**
- HTTPS push to relay server (`RelayApiClient`); CRDT operations sent in encrypted batches
- Sync queue drain on app resume / after pulls (`SyncQueueManager`, `lib/infrastructure/sync/sync_queue_manager.dart`, max batch 50, max 5 retries)

## Sync Technologies

**Active sync transport:**
- Internet relay over HTTPS REST + WebSocket (see "Sync Relay" sections above)
- CRDT-style sync queue persisted in `sync_queue_table.dart`, drained via `SyncQueueManager`
- Three-layer realtime degradation: WebSocket → push (FCM/APNs) → polling

**P2P / local sync technologies (per `CLAUDE.md`):**
- Bluetooth, NFC, Wi-Fi Direct mentioned as planned in `lib/infrastructure/sync/` design
- Status: NOT YET implemented in Dart code under `lib/infrastructure/sync/` (current files cover only relay/E2EE/push/queue/lifecycle)
- No `flutter_blue`, `nfc_manager`, `wifi_iot`, or similar packages currently in `pubspec.yaml`

## Platform Integrations

**Voice / Speech:**
- Library: `speech_to_text` `^7.0.0`
- Service: `SpeechRecognitionService` (`lib/infrastructure/speech/speech_recognition_service.dart`)
- Permissions: `RECORD_AUDIO` (Android), `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` (iOS)
- Android manifest declares `<intent>` query for `android.speech.RecognitionService`

**Charts:**
- Library: `fl_chart` `^0.69.0`
- Used in `lib/features/analytics/`

**QR Codes:**
- Library: `qr_flutter` `^4.1.0`
- Used for family-sync invitation flow

**Native Method Channels (custom):**
- `home_pocket/apns_push/methods` — APNs control (request permission, fetch token, fetch initial message)
- `home_pocket/apns_push/token_refresh` — APNs token refresh stream
- `home_pocket/apns_push/foreground_messages` — APNs foreground message stream
- `home_pocket/apns_push/opened_messages` — APNs notification-tap stream

## Machine Learning / OCR

**Current state:**
- `lib/infrastructure/ml/` contains ONLY `merchant_database.dart` — a static merchant lookup with fuzzy matching (no on-device ML model loaded)
- No ML Kit Dart packages in `pubspec.yaml` (`google_mlkit_*` not present)
- No TFLite Dart packages in `pubspec.yaml` (`tflite_flutter` not present)
- iOS `EXCLUDED_ARCHS` workaround for ML Kit referenced in `CLAUDE.md` but NOT currently active in `ios/Podfile` (post-install is the default Flutter helper only)
- OCR / TFLite classifier mentioned in architecture docs (`CLAUDE.md`, ARCH-008) is planned for MOD-005; implementation pending

**MerchantMatch contract:**
- Defined in `lib/infrastructure/ml/merchant_database.dart`
- Returns `(merchantName, categoryId, confidence, ledgerType)` for voice/OCR consumers

---

*Integration audit: 2026-04-25*
