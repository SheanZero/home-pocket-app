# External Integrations

**Analysis Date:** 2026-06-27

Home Pocket is a local-first, privacy-focused app. Most data never leaves the device. External network usage is limited to (1) an optional family-sync relay server, (2) push notifications, and (3) public exchange-rate APIs. There is no central backend account system and no `.env` / secret injection.

## APIs & External Services

**Exchange Rates (multi-currency, RATE-01 fallback chain):**
- Client: `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart` (HTTP via `http ^1.6.0`)
- Source order with fallback:
  1. Frankfurter — `https://api.frankfurter.dev/v1/{date}?from=JPY&to={C}` (1500ms timeout)
  2. fawazahmed0 via jsDelivr — `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@{date}/v1/currencies/jpy.min.json`
  3. fawazahmed0 via Cloudflare — `https://{date}.currency-api.pages.dev/v1/currencies/jpy.min.json` (1000ms timeout)
- Auth: None (public APIs)
- Privacy (SC-5 / T-41-05): URLs contain ONLY a YYYY-MM-DD date + ISO 4217 currency code — no identifiers, ledger refs, or amounts. Full URL logged only in `kDebugMode`.
- Caching: `lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart` + Drift `exchange_rates` table (`lib/data/tables/exchange_rates_table.dart`)
- Use case: `lib/application/currency/get_exchange_rate_use_case.dart`

**Family Sync Relay Server (optional, P2P-style sync):**
- Client: `lib/infrastructure/sync/relay_api_client.dart`
- Default base URL: `https://sync.happypocket.app/api/v1` (WebSocket derived as `wss://sync.happypocket.app`)
- Auth: Ed25519 request signing (`RequestSigner` in same file). Header: `Ed25519 <deviceId>:<timestamp>:<base64Signature>`; signed message `<method>:<path>:<timestamp>:<SHA256(body)>`. Keys from `lib/infrastructure/crypto/services/key_manager.dart`
- Transport: HTTP for control plane + WebSocket (`web_socket_channel`) for live channel via `lib/infrastructure/sync/websocket_service.dart`
- E2EE: `lib/infrastructure/sync/e2ee_service.dart` (transport payloads end-to-end encrypted)

## Data Storage

**Databases:**
- Local SQLite encrypted with SQLCipher (AES-256-CBC, 256k PBKDF2)
  - Definition: `lib/data/app_database.dart` (Drift, schema v22)
  - Encryption executor: `createEncryptedExecutor` (infrastructure/crypto database layer)
  - Connection key: derived/managed by `KeyManager`, master key in `flutter_secure_storage`
- No remote/cloud database. All ledger data stays on device.

**File Storage:**
- Local filesystem only (`path_provider`). Backup export/import via `lib/application/settings/export_backup_use_case.dart` / `import_backup_use_case.dart` (user-driven file share, not a service)
- Receipt images via `image_picker` (local)

**Caching:**
- Exchange-rate cache (in-DB, see above)
- `shared_preferences` for lightweight settings

## Authentication & Identity

**Device Identity:**
- Ed25519 device key pair (`pinenacl`), managed by `KeyManager`. Used for relay request signing.
- BIP39 recovery phrase, HKDF key derivation (see ARCH-003 Security Architecture)

**Local Auth:**
- Biometric lock via `local_auth ^3.0.1` (`lib/infrastructure/security/`)
- No username/password or OAuth provider. No central user account.

## Monitoring & Observability

**Error Tracking:**
- None (no Sentry/Crashlytics in `pubspec.yaml`). Firebase Analytics dependency is declared on Android (`firebase-analytics` in `android/app/build.gradle.kts` via firebase-bom) but no Dart-side analytics SDK is wired.

**Logs:**
- `debugPrint` under `kDebugMode` only. Audit logging is local: `lib/data/tables/audit_logs_table.dart` + `lib/infrastructure/security/audit_logger`. No remote log shipping.

## Push Notifications

**Android — Firebase Cloud Messaging:**
- `firebase_core ^4.1.1`, `firebase_messaging ^16.0.1`
- Config: `android/app/google-services.json` (committed), `com.google.gms.google-services` Gradle plugin, `firebase-bom 34.9.0`
- `Firebase.initializeApp` invoked only on Android (`lib/application/family_sync/repository_providers.dart`, `lib/infrastructure/sync/push_notification_service.dart`)

**iOS — APNs direct (no Firebase init on iOS):**
- `lib/infrastructure/sync/apns_push_messaging_client.dart`
- Firebase deliberately NOT initialized on iOS (`Platform.isIOS ? null : Firebase.initializeApp`)
- Note: `FirebaseMessaging` pod still pulled in on iOS — Podfile `post_install` strips `-lsqlite3` to prevent it overriding SQLCipher at runtime

**Local notifications:**
- `flutter_local_notifications ^21.0.0` via `lib/infrastructure/sync/push_notification_service.dart`

## CI/CD & Deployment

**Hosting:**
- Mobile app stores (iOS / Android). Relay server (`sync.happypocket.app`) is a separate, out-of-repo service.

**CI Pipeline:**
- GitHub Actions (`audit.yml` referenced in CLAUDE.md): `flutter analyze` (0 issues), full `flutter test`, AUDIT-09/AUDIT-10 guardrails (stale generated files, sqlite3 conflict), import_guard custom_lint
- Golden tests: macOS-baselined; CI ubuntu swaps in `BaselineExistenceGoldenComparator` (cannot pixel-match)

## Environment Configuration

**Required env vars:**
- None. No `.env` file; app runs without external configuration.

**Secrets location:**
- Master encryption key + device keys: OS keychain/keystore via `flutter_secure_storage` (accessibility `unlocked_this_device`)
- Firebase Android config: `android/app/google-services.json` (project config, not a secret)

## Webhooks & Callbacks

**Incoming:**
- Push notification callbacks (FCM on Android / APNs on iOS) handled by `push_notification_service.dart` → routed via `FamilySyncNotificationRouteListener` (uses `ref.listen` for navigation side effects, Riverpod 3 pattern)
- WebSocket inbound sync events (`websocket_service.dart`)

**Outgoing:**
- Signed HTTP requests to relay server (`relay_api_client.dart`)
- Read-only GET requests to exchange-rate APIs

---

*Integration audit: 2026-06-27*
