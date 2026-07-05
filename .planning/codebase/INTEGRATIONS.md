# External Integrations

**Analysis Date:** 2026-07-05

Home Pocket is a local-first, privacy-focused app. Most data never leaves the device. External network usage is limited to (1) an optional family-sync relay server, (2) push notifications, (3) public exchange-rate APIs, and (4) a single outbound sponsor-link launch to the OS browser. There is no central backend account system and no `.env` / secret injection.

## APIs & External Services

**Exchange Rates (multi-currency, RATE-01 fallback chain):**
- Client: `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart` (HTTP via `http ^1.6.0`)
- Cache: `lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart` + Drift `exchange_rates` table (`lib/data/tables/exchange_rates_table.dart`)
- Domain models: `lib/features/currency/domain/models/rate_result.dart` (**moved here** from `lib/infrastructure/exchange_rate/`), `exchange_rate.dart`; repository interface `lib/features/currency/domain/repositories/exchange_rate_repository.dart`
- Source order with fallback:
  1. Frankfurter — `https://api.frankfurter.dev/v1/{date}?from=JPY&to={C}` (1500ms timeout)
  2. fawazahmed0 via jsDelivr — `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@{date}/v1/currencies/jpy.min.json`
  3. fawazahmed0 via Cloudflare — `https://{date}.currency-api.pages.dev/v1/currencies/jpy.min.json` (1000ms timeout)
- Auth: None (public APIs)
- Privacy (SC-5 / T-41-05): URLs contain ONLY a YYYY-MM-DD date + ISO 4217 currency code — no identifiers, ledger refs, or amounts. Full URL logged only in `kDebugMode`.
- Use case: `lib/application/currency/get_exchange_rate_use_case.dart`

**Family Sync Relay Server (optional, P2P-style sync):**
- Client: `lib/infrastructure/sync/relay_api_client.dart`
- Default base URL: `https://sync.happypocket.app/api/v1` (WebSocket derived as `wss://sync.happypocket.app`)
- Auth: Ed25519 request signing (`RequestSigner` in same file). Header: `Ed25519 <deviceId>:<timestamp>:<base64Signature>`; signed message `<method>:<path>:<timestamp>:<SHA256(body)>`. Keys from `lib/infrastructure/crypto/services/key_manager.dart`
- Transport: HTTP for control plane + WebSocket (`web_socket_channel`) for live channel via `lib/infrastructure/sync/websocket_service.dart`
- E2EE: `lib/infrastructure/sync/e2ee_service.dart` (transport payloads end-to-end encrypted)

**Sponsor / Donation Link (NEW — Phase 56, DONATE-02/04):**
- Launcher: `lib/features/settings/presentation/widgets/legal_sponsor_section.dart` `_openSponsor()` via `url_launcher` `launchUrl(..., LaunchMode.externalApplication)`
- Target: `LegalUrls.donation` (`lib/core/config/legal_urls.dart`) — currently a `https://example.com/homepocket/support` **placeholder** marked `上线前填真实值`; must be replaced with the real sponsor-platform URL before App Store submission
- Behavior: non-transactional, no dialog, no in-app WebView, no IAP (DONATE-01/03). Launches directly rather than pre-checking launchability (avoids Android 11+ `<queries>` false-negative). On any failure shows one neutral SnackBar (`l10n.sponsorLaunchError`) — never crashes, never retries (T-56-06). Failure diagnostics `debugPrint`ed only under `kDebugMode`.
- This is the ONLY in-app outbound browser launch. The hosted `privacyPolicyHosted` / `termsOfUseHosted` placeholders in the same file are for App Store Connect metadata, NOT launched in-app.

## Data Storage

**Databases:**
- Local SQLite encrypted with SQLCipher (AES-256-CBC, 256k PBKDF2)
  - Definition: `lib/data/app_database.dart` (Drift, **schema v23** — up from v22)
  - Encryption executor: `createEncryptedExecutor` (infrastructure/crypto database layer)
  - Connection key: derived/managed by `KeyManager`, master key in `flutter_secure_storage`
- No remote/cloud database. All ledger data stays on device.

**File Storage:**
- Local filesystem only (`path_provider`). Backup export/import via `lib/application/settings/export_backup_use_case.dart` / `import_backup_use_case.dart` (user-driven file share, not a service)
- Backup `.hpb` files are password-encrypted (**Argon2id + AES-256-GCM**, versioned header) by `lib/infrastructure/crypto/services/backup_crypto_service.dart` before leaving the device via the share sheet — offline brute force is the stated threat model. Legacy PBKDF2 backups remain importable.
- Bundled read-only assets: offline legal Markdown (`assets/legal/*.md`) loaded via `rootBundle.loadString` in `LegalDocScreen` (first `rootBundle` consumer; asset path built from a closed `LegalDoc` enum + whitelist-guarded language code, so no untrusted value reaches the loader — V12 / T-56-02)
- Receipt images via `image_picker` (local)

**Caching:**
- Exchange-rate cache (in-DB `exchange_rates` table, see above)
- `shared_preferences` for lightweight settings (plaintext, not SQLCipher)

## Authentication & Identity

**Device Identity:**
- Ed25519 device key pair (`pinenacl`), managed by `KeyManager`. Used for relay request signing.
- BIP39 recovery phrase, HKDF key derivation (see ARCH-003 Security Architecture)

**Local Auth (app-lock):**
- Biometric unlock via `local_auth ^3.0.1` (`lib/infrastructure/security/biometric_service.dart`) — biometric-only; the device passcode is deliberately never accepted (Phase 55-12 G2). Requires `NSFaceIDUsageDescription` in `Info.plist` (Phase 55-12 G3).
- 4-digit PIN fallback: Argon2id PHC verified by `lib/infrastructure/security/pin_kdf.dart`; orchestrated by `lib/application/security/app_lock_service.dart`. PIN rate-limiting is descoped (D-06 accepted risk) — the memory-hard Argon2id cost is the sole brute-force defense.
- No username/password or OAuth provider. No central user account.

## Monitoring & Observability

**Error Tracking:**
- None (no Sentry/Crashlytics in `pubspec.yaml`). Firebase Analytics is declared on Android (`firebase-analytics` via firebase-bom in `android/app/build.gradle.kts`) but no Dart-side analytics SDK is wired.

**Logs:**
- `debugPrint` under `kDebugMode` only (including sponsor-launch failures). Audit logging is local: `lib/data/tables/audit_logs_table.dart` + `lib/infrastructure/security/audit_logger`. No remote log shipping.

## Push Notifications

**Android — Firebase Cloud Messaging:**
- `firebase_core ^4.1.1` (resolved 4.9.0), `firebase_messaging ^16.0.1` (resolved 16.2.2)
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

**Placeholder values to fill before launch (`lib/core/config/legal_urls.dart`):**
- `privacyPolicyHosted`, `termsOfUseHosted` — App Store Connect-mandated hosted URLs (LEGAL-01/02)
- `donation` — sponsor-platform URL launched by the settings sponsor row (DONATE-04)
- All three are `example.com` placeholders marked `上线前填真实值` and MUST be replaced before submission.

**Secrets location:**
- Master encryption key + Ed25519 device keys + app-lock PIN PHC: OS keychain/keystore via `flutter_secure_storage` (accessibility `unlocked_this_device`)
- Firebase Android config: `android/app/google-services.json` (project config, not a secret)

## Webhooks & Callbacks

**Incoming:**
- Push notification callbacks (FCM on Android / APNs on iOS) handled by `push_notification_service.dart` → routed via `FamilySyncNotificationRouteListener` (uses `ref.listen` for navigation side effects, Riverpod 3 pattern)
- WebSocket inbound sync events (`websocket_service.dart`)

**Outgoing:**
- Signed HTTP requests to relay server (`relay_api_client.dart`)
- Read-only GET requests to exchange-rate APIs
- One user-initiated external-browser launch to the sponsor URL (`legal_sponsor_section.dart`)

---

*Integration audit: 2026-07-05*
