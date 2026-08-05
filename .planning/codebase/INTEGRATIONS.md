# External Integrations

**Analysis Date:** 2026-08-05
**Last mapped commit:** `7b4f1bac44644ea821835e85d09d9571a601e82a`

## APIs & External Services

**Family sync relay:**
- Self-hosted REST endpoint defaults to `https://sync.happypocket.app/api/v1`; client `lib/infrastructure/sync/relay_api_client.dart` uses `http` and Ed25519-signed requests.
- Realtime channel is WebSocket `{base}/ws/group/{groupId}` via `lib/infrastructure/sync/websocket_service.dart` and `web_socket_channel`.
- Override with `--dart-define=SYNC_SERVER_URL`.

**Exchange rates:**
- `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart` queries Frankfurter, jsDelivr currency-api, then Cloudflare Pages currency-api; `exchange_rate_cache_service.dart` gates requests with `connectivity_plus` and caches through Drift.

**Push messaging:**
- Firebase Cloud Messaging (`firebase_core`, `firebase_messaging`) wakes sync; wrappers are `lib/infrastructure/sync/push_notification_service.dart` and `apns_push_messaging_client.dart`.
- Android configuration is `android/app/google-services.json`; iOS uses APNs bridge (no `GoogleService-Info.plist` detected).

## Data Storage

**Databases:** SQLCipher-encrypted SQLite through Drift (`lib/data/app_database.dart`, schema v36), tables/DAOs under `lib/data/tables/` and `lib/data/daos/`, repository implementations under `lib/data/repositories/`. Encryption executor is in `lib/infrastructure/crypto/`.

**File storage:** Local filesystem only via `path_provider`; app-owned files and encrypted receipt/photo data are managed by `lib/infrastructure/storage/`.

**Settings/cache:** `shared_preferences` stores non-database settings; exchange-rate and sync state are persisted locally in Drift. No cloud database or external cache detected.

## Authentication & Identity

- No hosted account/auth provider. Device identity and sync authorization use Ed25519 keys in `lib/infrastructure/crypto/`.
- Master/recovery material is protected by `secure_storage_service.dart` and application lock uses `biometric_service.dart` (`local_auth`) plus PIN KDF.
- Sync payloads are end-to-end encrypted by `lib/infrastructure/sync/e2ee_service.dart`; relay does not receive plaintext ledger data.

## Monitoring & Observability

**Error tracking:** None detected (no Sentry/Crashlytics dependency).

**Logs/audit:** Local security audit events use `lib/infrastructure/security/audit_logger.dart`; privacy rules prohibit sensitive payload logging.

## CI/CD & Deployment

- GitHub Actions workflow `.github/workflows/audit.yml` runs Flutter analyze, custom/import audits, generation checks, and coverage gates on Flutter 3.44.0.
- Distribution target is iOS App Store and Google Play; sync relay hosting/deployment is outside this repository.

## Device Capabilities & Permissions

- Voice recognition: `speech_to_text` (`lib/infrastructure/speech/`), with microphone/speech usage strings in `ios/Runner/Info.plist` and localized `ios/Runner/*/InfoPlist.strings`.
- Camera/files/sharing: `image_picker`, `file_picker`, `share_plus` in settings/accounting flows.
- Face ID/fingerprint: `local_auth` with iOS Face ID usage description.
- QR pairing: `qr_flutter`; network reachability: `connectivity_plus`; hosted legal/support links: `url_launcher` and `lib/core/config/legal_urls.dart`.

## Webhooks & Callbacks

**Incoming:** FCM/APNs push callbacks (`push_notification_service.dart`) and relay WebSocket events (`websocket_service.dart`).

**Outgoing:** Signed REST sync operations (`relay_api_client.dart`), WebSocket subscriptions, and exchange-rate HTTPS requests.

## ML / OCR

No external ML/OCR SDK is declared. Merchant normalization is rule-based in `lib/infrastructure/ml/merchant_name_normalizer.dart`; no `google_mlkit_*` or TFLite package is present.

---

*Integration audit: 2026-08-05*
