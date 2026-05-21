# External Integrations

**Analysis Date:** 2026-05-21

## APIs & External Services

**Sync Relay Server:**
- `sync.happypocket.app` — proprietary relay server for family sync
  - REST API base: `https://sync.happypocket.app/api/v1` (default; overridable via `--dart-define=SYNC_SERVER_URL=...`)
  - WebSocket base: `wss://sync.happypocket.app` (derived from REST URL by `RelayApiClient.wsBaseUrl`)
  - Client: `lib/infrastructure/sync/relay_api_client.dart` (uses `package:http ^1.6.0`)
  - Auth: Ed25519 signed requests — `Authorization: Ed25519 <deviceId>:<timestamp>:<base64Signature>`
  - Endpoints: `/device/register`, `/device/push-token`, `/group/create`, `/group/join`, `/group/{id}/confirm-join`, `/group/{id}/status`, `/group/{id}/leave`, `/group/{id}/remove`, `/group/{id}/invite`, `/sync/push`, `/sync/pull`, `/sync/ack`

**Firebase Cloud Messaging:**
- Used for family sync push notifications (Android FCM, iOS APNS via Firebase bridge)
  - SDK: `firebase_core: ^4.1.1` (locked `4.9.0`), `firebase_messaging: ^16.0.1` (locked `16.2.2`)
  - Firebase BOM: `com.google.firebase:firebase-bom:34.9.0` (`android/app/build.gradle.kts`)
  - Android config: `android/app/google-services.json`
  - iOS: requires `GoogleService-Info.plist` (not found in repo — likely gitignored)
  - Client: `lib/infrastructure/sync/push_notification_service.dart` (`FirebasePushMessagingClient`)
  - iOS note: `ios/Podfile` `post_install` strips `-l"sqlite3"` from every Pod xcconfig so system `libsqlite3.tbd` never enters the link line. This is **load-bearing for Firebase Messaging + SQLCipher coexistence** — removing the strip causes `PRAGMA cipher_version` to return empty at runtime and breaks encryption entirely (see `lib/infrastructure/crypto/database/encrypted_database.dart` `_setupEncryption`).
  - Push token registered to relay server via `RelayApiClient.updatePushToken` (platform: `apns` on iOS, `fcm` on Android)

**APNS (Apple Push Notification Service) — Direct Bridge:**
- Separate native push path for iOS alongside Firebase
  - Client: `lib/infrastructure/sync/apns_push_messaging_client.dart`
  - Bridge: `MethodChannel('home_pocket/apns_push/methods')` + `EventChannel` (3 channels for token refresh, foreground, opened)
  - `ApnsPushMessagingClient` implements the same `PushMessagingClient` interface as `FirebasePushMessagingClient`

## Data Storage

**Databases:**
- **Drift + SQLCipher** — primary local database
  - Schema version: **17** (as of 2026-05-21, v1.2 milestone close)
  - Database file: `app_database.dart` → `AppDatabase` at `lib/data/app_database.dart`
  - Encrypted executor: `lib/infrastructure/crypto/database/encrypted_database.dart` (`createEncryptedExecutor`)
  - Cipher: AES-256-CBC, KDF: PBKDF2-HMAC-SHA512, 256,000 iterations; key derived from master key via HKDF-SHA256
  - Library: `sqlcipher_flutter_libs: ^0.6.7` (locked `0.6.8`) — **must NOT be replaced with `sqlite3_flutter_libs`**
  - Tables (11): `AuditLogs`, `Books`, `Categories`, `CategoryKeywordPreferences`, `CategoryLedgerConfigs`, `GroupMembers`, `Groups`, `MerchantCategoryPreferences`, `SyncQueue`, `Transactions`, `UserProfiles`
  - v17 migration: `transactions.entry_source TEXT NOT NULL DEFAULT 'manual' CHECK(entry_source IN ('manual', 'voice', 'ocr'))` — added Phase 17 of v1.2
  - In-memory variant for tests: `AppDatabase.forTesting()` / `NativeDatabase.memory()`

**File Storage:**
- Local filesystem only — avatar images and backup exports stored via `path_provider`
- No cloud file storage

**Caching:**
- In-memory key cache in `EncryptionRepositoryImpl._cachedKey` (`lib/infrastructure/crypto/repositories/encryption_repository_impl.dart`) — cleared on logout

**Lightweight Preferences:**
- `shared_preferences: ^2.3.4` (locked `2.5.5`) — used in `lib/data/repositories/settings_repository_impl.dart` and for feature flags like `lib/features/analytics/presentation/providers/state_joy_metric_variant.dart`

## Authentication & Identity

**Biometric Auth:**
- Provider: `local_auth: ^3.0.1` (locked `3.0.1`) — Face ID / Touch ID / Fingerprint
- Implementation: `lib/infrastructure/security/biometric_service.dart` (`BiometricService`)
- Supports: `faceId`, `fingerprint`, `strongBiometric` (Android Class 3), `weakBiometric` (Android Class 2)
- Failure counting with lockout strategy built in

**Secure Storage:**
- Provider: `flutter_secure_storage: ^10.2.0` (locked `10.2.0`)
- Used by:
  - `lib/infrastructure/crypto/repositories/master_key_repository_impl.dart` — stores master encryption key
  - `lib/infrastructure/crypto/repositories/key_repository_impl.dart` — stores Ed25519 device key pair
  - `lib/infrastructure/security/secure_storage_service.dart` — general secure storage wrapper

**Device Identity:**
- Ed25519 device key pair generated on first launch, stored in flutter_secure_storage
- Device ID derived from public key; used to authenticate all relay server requests
- Key management: `lib/infrastructure/crypto/services/key_manager.dart`
- Repository: `lib/data/repositories/device_identity_repository_impl.dart`

## Family Sync Transport

**Three-layer degradation:** WebSocket (primary) → APNS/FCM push (backup) → polling (fallback)

**Layer 1 — WebSocket Realtime:**
- Package: `web_socket_channel: ^3.0.0` (locked `3.0.3`)
- Service: `lib/infrastructure/sync/websocket_service.dart` (`WebSocketService`)
- Connects to `wss://sync.happypocket.app/ws/group/{groupId}`
- Auth: Ed25519 signed message on connect (`ws:connect:<groupId>:<deviceId>:<timestamp>`)
- Heartbeat: 30-second ping/45-second pong timeout; exponential backoff reconnect (max 30s)
- Background disconnect: 60-second timeout when app enters background
- Events: `member_confirmed`, `join_request`, `member_left`, `group_dissolved`, `group_status`, `sync_available`

**Layer 2 — Push Notifications:**
- Android: Firebase Cloud Messaging via `firebase_messaging` (initialized in `PushNotificationService`)
- iOS: APNS via native `MethodChannel` bridge (`ApnsPushMessagingClient`) or Firebase bridge
- Service: `lib/infrastructure/sync/push_notification_service.dart`
- Local notifications: `flutter_local_notifications: ^21.0.0` (locked `21.0.0`) for foreground message display

**E2EE Payload Encryption:**
- Service: `lib/infrastructure/sync/e2ee_service.dart` (`E2EEService`)
- Algorithm: NaCl Box (X25519-XSalsa20-Poly1305) via `pinenacl: ^0.6.0`
- Key derivation: Ed25519 → X25519 conversion using `TweetNaClExt`
- Payload envelope v2 format: `{"v":2,"t":"D","p":"<base64(nonce+ciphertext)>"}`
- Group key exchange: individual device encryption for key distribution

**Sync Scheduling:**
- Service: `lib/infrastructure/sync/sync_scheduler.dart` (`SyncScheduler`)
- Debounce: 10 seconds after transaction change → incremental push
- Polling: every 15 minutes → full pull check (if >24h since last sync)

**Queue Management:**
- Table: `SyncQueue` (`lib/data/tables/sync_queue_table.dart`)
- Manager: `lib/infrastructure/sync/sync_queue_manager.dart`

## Cryptography Services

**Field Encryption (ChaCha20-Poly1305 AEAD):**
- Package: `cryptography: ^2.7.0` (locked `2.9.0`)
- Implementation: `lib/infrastructure/crypto/repositories/encryption_repository_impl.dart`
- Format: `Base64(nonce[12B] + encrypted_data + MAC[16B])`
- Key derived via HKDF-SHA256 from master key

**Database Encryption (AES-256-CBC):**
- Library: `sqlcipher_flutter_libs ^0.6.7` via `lib/infrastructure/crypto/database/encrypted_database.dart`
- Setup: `PRAGMA key`, `PRAGMA cipher = "aes-256-cbc"`, `PRAGMA kdf_iter = 256000`

**Hash Chain Integrity:**
- Service: `lib/infrastructure/crypto/services/hash_chain_service.dart`
- Package: `crypto: ^3.0.6`

**E2EE Transport:**
- Library: `pinenacl: ^0.6.0` (NaCl Box, X25519-XSalsa20-Poly1305)
- Service: `lib/infrastructure/sync/e2ee_service.dart`

## Machine Learning / OCR

**Merchant Classification (Stub):**
- Service: `lib/infrastructure/ml/merchant_database.dart` (`MerchantDatabase`)
- Current state: ~20 seed entries (backlog: full 500+ merchant list)
- Fuzzy matching for voice and OCR classification
- 3-layer classification pipeline at `lib/application/dual_ledger/classification_service.dart`:
  1. Rule Engine (fully implemented)
  2. Merchant DB lookup (stub — `// TODO`)
  3. TFLite ML Classifier (stub — `// TODO`)

**OCR (Stub):**
- Screen: `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart` — UI stub only (shutter button pops back)
- No `google_ml_kit` or `tflite_flutter` packages in `pubspec.yaml`
- `EntrySource.ocr` column reserved in Drift schema v17 (`transactions.entry_source` CHECK constraint)
- MOD-005 OCR is **pending** — schema slot reserved but ML Kit / TFLite packages not yet added

**Voice Recognition:**
- Package: `speech_to_text: ^7.0.0` (locked `7.3.0`)
- Service: `lib/infrastructure/speech/speech_recognition_service.dart` (`SpeechRecognitionService`)
- Modes: dictation, auto-punctuation, partial results
- Platform normalization: Android RMS-based (0–10) → 0.0–1.0; iOS dB scale (-50–0) → 0.0–1.0

## File and Platform Plugins

**File Operations:**
- `file_picker: ^11.0.2` (locked `11.0.2`) — backup import (`lib/features/settings/presentation/widgets/data_management_section.dart`)
- `image_picker: ^1.1.2` (locked `1.2.2`) — avatar photo selection (`lib/features/profile/presentation/screens/avatar_picker_screen.dart`)
- `share_plus: ^12.0.2` (locked `12.0.2`) — share invite codes, export files (`lib/features/family_sync/presentation/screens/create_group_screen.dart`, data management)
- `package_info_plus: ^9.0.1` (locked `9.0.1`) — app version metadata

**QR Code:**
- `qr_flutter: ^4.1.0` (locked `4.1.0`) — in `pubspec.yaml` but no active `import 'package:qr_flutter'` found in current sources; reserved for invite code QR display in family sync flow

## Routing

**Internal routing:**
- No `go_router` package; `MaterialApp.home` pattern with direct `Navigator.push` for screen transitions
- Routing handled declaratively in `lib/main.dart` (`_buildHome` dispatches to `MainShellScreen`, `ProfileOnboardingScreen`, or error screen based on initialization state)

## Monitoring & Observability

**Error Tracking:**
- None — no Sentry, Crashlytics, or equivalent in `pubspec.yaml`

**Logs:**
- `debugPrint(...)` wrapped in `if (kDebugMode)` blocks throughout — no production log framework
- Audit log stored locally in `AuditLogs` Drift table (`lib/data/tables/audit_logs_table.dart`) via `lib/infrastructure/security/audit_logger.dart`

## Webhooks & Callbacks

**Incoming:**
- WebSocket events from relay server (`wss://sync.happypocket.app/ws/group/{groupId}`) — see sync transport above
- APNS/FCM push messages — received via `PushNotificationService`

**Outgoing:**
- Push token registration via `POST /device/push-token` on relay server
- Sync push via `POST /sync/push` to relay server

## Environment Configuration

**No `.env` files present.** All configuration is via:
- `--dart-define=SYNC_SERVER_URL=<url>` — override sync server (defaults to `https://sync.happypocket.app/api/v1`)
- `const _useInMemoryDatabase = false` in `lib/main.dart` — dev toggle for in-memory DB
- `android/app/google-services.json` — Firebase Android config (committed)
- Firebase iOS `GoogleService-Info.plist` — must be placed in `ios/Runner/` (gitignored)

**Required for production:**
- Firebase `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) for FCM/APNS push
- Relay server accessible at `https://sync.happypocket.app` (or custom `SYNC_SERVER_URL`)

---

*Integration audit: 2026-05-21*
