# External Integrations

**Analysis Date:** 2026-08-08

## APIs & External Services

**Family sync relay:**
- `https://sync.happypocket.app/api/v1` REST API and derived `wss://sync.happypocket.app` WebSocket in `lib/infrastructure/sync/relay_api_client.dart` and `websocket_service.dart`.
  - SDK/Client: `http`, `web_socket_channel`
  - Auth: device Ed25519 signatures (`Authorization`) and one-time `X-Request-Nonce`; endpoint override via `SYNC_SERVER_URL`.
- Relay transports opaque E2EE payloads; encryption/key handling is in `lib/infrastructure/sync/e2ee_service.dart` and `lib/infrastructure/crypto/`.

**Exchange rates:**
- Frankfurter (`api.frankfurter.dev`), fawazahmed0 currency API via jsDelivr and Cloudflare Pages, chained in `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart`.
  - SDK/Client: `http`
  - Auth: none; requests contain only date and ISO currency code.

## Data Storage

**Databases:**
- Local encrypted SQLite/SQLCipher database managed by Drift (`lib/data/app_database.dart`, `lib/infrastructure/crypto/database/encrypted_database.dart`).
  - Connection: app-private path from `path_provider`; encryption key from secure key manager.
  - Client: `drift` 2.34.0 + `sqlite3` 3.3.1 Native Assets (SQLCipher 4.17.x verification).

**File Storage:**
- Local app-owned files and encrypted attachments using `path_provider`, `file_picker`, and `image_picker`; privacy cleanup services live in `lib/infrastructure/storage/`.

**Caching:**
- Drift tables cache exchange rates and sync queues; `shared_preferences` stores non-sensitive settings. No remote cache detected.

## Authentication & Identity

**Auth Provider:**
- Custom device identity for relay authentication, with Ed25519 keys and E2EE (`lib/infrastructure/crypto/services/key_manager.dart`, `lib/infrastructure/sync/relay_api_client.dart`).
- Local biometric/PIN lock uses `local_auth`, `flutter_secure_storage`, and `lib/application/security/app_lock_service.dart`.

## Monitoring & Observability

**Error Tracking:**
- None detected; Firebase Analytics is not configured.

**Logs:**
- `debugPrint` and custom privacy-aware audit logging (`lib/infrastructure/security/audit_logger.dart`); sensitive payloads are excluded from production logs.

## CI/CD & Deployment

**Hosting:**
- Mobile distribution targets iOS and Android; no web/backend deployment configuration is present in this repository.

**CI Pipeline:**
- No CI provider workflow detected; release/preflight checks are implemented as Dart tests under `test/scripts/`.

## Environment Configuration

**Required env vars:**
- No runtime environment variables detected. Optional compile-time `SYNC_SERVER_URL` customizes the sync relay.

**Secrets location:**
- Device/database keys are generated and held through `flutter_secure_storage` abstraction; Firebase/APNs credentials are supplied by platform configuration outside Dart source.

## Webhooks & Callbacks

**Incoming:**
- APNs/FCM push callbacks and opened-message events bridged through native channels (`lib/infrastructure/sync/apns_push_messaging_client.dart`, `ios/Runner/AppDelegate.swift`).
- Relay WebSocket events are consumed by `lib/infrastructure/sync/websocket_service.dart`.

**Outgoing:**
- Relay REST/WebSocket sync requests; push-token registration via `/device/push-token`.
- External URL launches for hosted privacy/terms/support/sponsor destinations via `url_launcher`.

---

*Integration audit: 2026-08-08*
