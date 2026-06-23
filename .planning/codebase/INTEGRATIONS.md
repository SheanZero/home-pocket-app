# External Integrations

**Analysis Date:** 2026-06-23

This is a local-first, privacy-focused app. Most data stays on-device. External
network calls are limited to: (1) a self-hosted relay for P2P family sync,
(2) public exchange-rate APIs, and (3) Firebase Cloud Messaging for push.

## APIs & External Services

**Family Sync Relay:**
- Self-hosted relay server - Coordinates P2P family sync (E2EE payloads only).
  - Client: `lib/infrastructure/sync/relay_api_client.dart`
  - Default base URL: `https://sync.happypocket.app/api/v1` (`relay_api_client.dart` line 69)
  - Transport: HTTPS (REST) + WebSocket
  - Auth: **Ed25519 request signing** — `Authorization: Ed25519 {deviceId}:{timestamp}:{base64(signature)}` (`relay_api_client.dart` lines 24-44). Signed via `KeyManager.signData`.
  - Key endpoint: `PUT /device/push-token` (register push token)

**Exchange Rate APIs (3-source fallback chain):**
- Client: `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart`
- Cache: `lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart` (persisted to `exchange_rates` Drift table)
- Source order (RATE-01):
  1. Frankfurter - `https://api.frankfurter.dev/v1/{date}?from=JPY&to={C}` (primary, 1500ms timeout)
  2. fawazahmed0 via jsDelivr - `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@{date}/...` (1500ms)
  3. fawazahmed0 via Cloudflare - `https://{date}.currency-api.pages.dev/...` (1000ms)
- No API key required. Privacy: URLs contain ONLY a date + ISO 4217 currency code — no identifiers, amounts, or ledger refs (SC-5 / T-41-05).
- Throws `ExchangeRateApiException` only when all three sources fail.

## Data Storage

**Database:**
- Drift + SQLCipher (local, on-device, AES-256-CBC encrypted) — `lib/data/app_database.dart`, schema version **21**
- Encryption key managed via `lib/infrastructure/crypto/` + `flutter_secure_storage`
- Tables (`lib/data/tables/`): transactions, books, categories, groups, group_members, user_profiles, audit_logs, sync_queue, exchange_rates, shopping_items, category_ledger_configs, category_keyword_preferences, merchant_category_preferences

**File Storage:**
- Local filesystem only via `path_provider`. Photos encrypted with AES-256-GCM (per security architecture). No cloud object storage.

**Caching:**
- `shared_preferences` for lightweight settings
- Exchange rates cached in the Drift `exchange_rates` table

## Authentication & Identity

**No external auth provider.** Identity is device-local and key-based:
- Ed25519 device key pair - `lib/infrastructure/crypto/` (`DeviceKeyPair`)
- BIP39 recovery phrase + HKDF key derivation
- Biometric lock - `local_auth ^3.0.1`
- Family/group membership authenticated via Ed25519-signed relay requests (no username/password, no OAuth)

## Monitoring & Observability

**Error Tracking:**
- None (no Sentry/Crashlytics detected). On-device audit logging via `audit_logs` table + `lib/infrastructure/security/audit_logger`.

**Logs:**
- `debugPrint` gated behind `kDebugMode`. `avoid_print` lint enforced. Sensitive data never logged (crypto rules).

## CI/CD & Deployment

**Hosting / Distribution:**
- Mobile app (iOS App Store / Google Play). No backend hosted in this repo (relay server is external).

**CI Pipeline (`.github/workflows/audit.yml`):**
- Triggers: PR to `main` + push to `main`
- Runner: `ubuntu-latest`, Flutter 3.44.0 stable via `subosito/flutter-action@v2`
- Gates (blocking): `flutter analyze`, `import_guard`/`custom_lint`, per-file coverage ≥70% (`coverde 0.3.0+1`), `sqlite3_flutter_libs` reject guard, stale-generated-file check (AUDIT-10)

## Push / Messaging

**Firebase Cloud Messaging (FCM):**
- `firebase_core ^4.1.1`, `firebase_messaging ^16.0.1`
- Android config present: `android/app/google-services.json`
- iOS config NOT present in repo: `ios/Runner/GoogleService-Info.plist` missing (must be supplied for iOS push builds)
- Service: `lib/infrastructure/sync/push_notification_service.dart`
- iOS APNs path: `lib/infrastructure/sync/apns_push_messaging_client.dart`
- Local notifications: `flutter_local_notifications ^21.0.0`
- iOS note: FirebaseMessaging declares `s.libraries = 'sqlite3'`; `ios/Podfile` `post_install` strips `-lsqlite3` so SQLCipher symbols win at runtime (do not remove)

## On-Device ML

- `lib/infrastructure/ml/merchant_database.dart` - 500+ merchant lookup (no network)
- TFLite classifier planned but not yet wired — `lib/application/dual_ledger/classification_service.dart` has `// TODO: Implement TFLiteClassifier when model is available`. No `.tflite` asset or `google_mlkit` dependency currently present.

## Environment Configuration

**Required external config files:**
- `android/app/google-services.json` (committed) - Android FCM
- `ios/Runner/GoogleService-Info.plist` (MISSING) - needed for iOS FCM
- No `.env` files; runtime secrets live in OS secure storage (keychain/keystore)

**Secrets location:**
- Device keys / DB key: `flutter_secure_storage` (iOS Keychain / Android Keystore) via `lib/infrastructure/crypto/services/key_manager.dart`

## Webhooks & Callbacks

**Incoming:**
- FCM push messages (handled by `push_notification_service.dart`)
- WebSocket inbound sync events: `ws://.../ws/group/{groupId}` (`lib/infrastructure/sync/websocket_service.dart` line 123)

**Outgoing:**
- Signed REST calls to relay (`relay_api_client.dart`)
- Outbound WebSocket sync frames to relay group channel

---

*Integration audit: 2026-06-23*
