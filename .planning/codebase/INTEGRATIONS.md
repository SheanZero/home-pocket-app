# External Integrations

**Analysis Date:** 2026-06-23

## APIs & External Services

**Exchange Rate (three-source fallback chain):**
- Implemented in `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart`
- Source order (RATE-01):
  1. Frankfurter — `https://api.frankfurter.dev/v1/{date}?from=JPY&to={C}`
  2. fawazahmed0 jsDelivr — `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@{date}/...`
  3. fawazahmed0 Cloudflare — `https://{date}.currency-api.pages.dev/v1/...`
- SDK/Client: `http ^1.6.0`
- Auth: None (public APIs)
- Privacy: URLs contain ONLY a YYYY-MM-DD date and ISO 4217 currency code — no identifiers or monetary values. Full URL logged only under `kDebugMode`
- Timeouts: 1500ms primary, 1000ms Cloudflare fallback

**P2P Family Sync Relay:**
- HTTP client: `lib/infrastructure/sync/relay_api_client.dart`
- Default base URL: `https://sync.happypocket.app/api/v1`
- Auth: Ed25519 request signing — `Authorization: Ed25519 <deviceId>:<timestamp>:<base64Signature>`; signed message `<method>:<path>:<timestamp>:<SHA256(body)>` (`RequestSigner` class)
- WebSocket: `lib/infrastructure/sync/websocket_service.dart` — connects to `{baseUrl}/ws/group/{groupId}` via `web_socket_channel`
- E2EE: payloads encrypted before transport (`lib/infrastructure/sync/e2ee_service.dart`)

## Data Storage

**Databases:**
- SQLCipher (encrypted SQLite, AES-256-CBC, 256k PBKDF2)
  - Client: Drift `^2.25.0` (`lib/data/app_database.dart`, schema v21)
  - Native libs: `sqlcipher_flutter_libs ^0.6.7`
  - Encryption key sourced from `KeyManager` (never hardcoded)

**File Storage:**
- Local filesystem only (`path_provider`) — photos encrypted with AES-256-GCM (4-layer encryption, file layer)

**Caching:**
- Exchange rates cached in `exchange_rates` Drift table (cache-first repository)
- `shared_preferences` for lightweight settings

## Authentication & Identity

**Local Auth:**
- Biometric / device passcode via `local_auth ^3.0.1` (`lib/infrastructure/security/biometric_service.dart`)
- Master key + Ed25519 device keypair stored in OS keychain via `flutter_secure_storage ^10.2.0` (`secure_storage_service.dart`)
- BIP39 recovery phrase + HKDF key derivation (zero-knowledge, no remote auth provider)

**Device Identity (sync):**
- Ed25519 device keys (`pinenacl`) used to sign relay API requests (`KeyManager`)

## Monitoring & Observability

**Error Tracking:**
- None (no Sentry/Crashlytics). Privacy-focused; no third-party telemetry

**Logs:**
- Audit logging via `lib/infrastructure/security/audit_logger.dart`
- Debug-only console logging (`kDebugMode`); `avoid_print` lint enforced

## CI/CD & Deployment

**Hosting:**
- Mobile app stores (iOS App Store / Google Play) — not detected in repo config

**CI Pipeline:**
- GitHub Actions (`audit.yml` referenced in CLAUDE.md): `flutter analyze`, stale-generated-file guardrails (AUDIT-09/10), full `flutter test`

## Push Notifications

**Provider:**
- Firebase Cloud Messaging — `firebase_core ^4.1.1`, `firebase_messaging ^16.0.1`
- Config: `android/app/google-services.json` (iOS `GoogleService-Info.plist` not committed)
- Service: `lib/infrastructure/sync/push_notification_service.dart`, APNs client `apns_push_messaging_client.dart`
- Local display: `flutter_local_notifications ^21.0.0`

## Environment Configuration

**Required env vars:**
- None — local-first architecture, no server-injected secrets

**Secrets location:**
- OS keychain/keystore via `flutter_secure_storage` (master key, device keypair)
- Firebase config in committed `google-services.json` (Android)

## Webhooks & Callbacks

**Incoming:**
- WebSocket relay events (`websocket_service.dart`) — group sync push events
- FCM/APNs push messages (background message handling)

**Outgoing:**
- Signed POST requests to sync relay (`relay_api_client.dart`)
- GET requests to exchange-rate sources (`exchange_rate_api_client.dart`)

---

*Integration audit: 2026-06-23*
