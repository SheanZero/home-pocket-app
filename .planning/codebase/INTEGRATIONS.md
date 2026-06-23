# External Integrations

**Analysis Date:** 2026-06-23

## APIs & External Services

**Sync Relay (self-hosted backend):**
- Home Pocket Relay API - P2P family sync coordination
  - SDK/Client: `lib/infrastructure/sync/relay_api_client.dart`
  - Base URL: `https://sync.happypocket.app/api/v1` (default)
  - WebSocket: derived `wss://sync.happypocket.app/ws/group/{groupId}` (`lib/infrastructure/sync/websocket_service.dart`)
  - Auth: device Ed25519 key-based; payloads E2EE before transport

**Push (Firebase Cloud Messaging):**
- FCM - Sync wake / family notifications (Android primary)
  - Client: firebase_messaging via `lib/infrastructure/sync/push_notification_service.dart`
  - Provider wiring: `lib/application/family_sync/repository_providers.dart`
  - Config: `android/app/google-services.json`

**APNs:**
- iOS push path - `lib/infrastructure/sync/apns_push_messaging_client.dart`

## Data Storage

**Databases:**
- SQLite via Drift + SQLCipher (AES-256-CBC, schema v21)
  - Definition: `lib/data/app_database.dart`, tables in `lib/data/tables/`, DAOs in `lib/data/daos/`
  - Encryption key: SQLCipher executor (`lib/infrastructure/crypto/database/`)
  - Local-first; no remote/cloud database

**File Storage:**
- Local filesystem only (path_provider). Photos encrypted AES-256-GCM. Export/import via file_picker + share_plus.

**Caching:**
- shared_preferences for lightweight settings; no external cache service

## Authentication & Identity

**Auth Provider:**
- Custom, fully local (zero-knowledge architecture)
  - Device identity: Ed25519 keypair (`lib/infrastructure/crypto/`)
  - Recovery: BIP39 phrase + HKDF derivation
  - Master key: flutter_secure_storage (Keychain/Keystore)
  - Biometric lock: local_auth (`lib/infrastructure/security/biometric_service`)
  - No third-party identity provider, no accounts/passwords

## Monitoring & Observability

**Error Tracking:**
- None (privacy-focused; no external telemetry/crash reporting)

**Logs:**
- Local audit logger (`lib/infrastructure/security/audit_logger`); no remote log shipping

## CI/CD & Deployment

**Hosting:**
- Mobile app (App Store / Play Store); sync relay self-hosted at `sync.happypocket.app`

**CI Pipeline:**
- GitHub Actions (`audit.yml`) - flutter analyze, full test suite, stale-generated-file guardrails (AUDIT-09/10)

## Environment Configuration

**Required env vars:**
- None — no `.env` files. Relay base URL has a compiled-in default; secrets live in OS keychain.

**Secrets location:**
- OS-native: iOS Keychain / Android Keystore via flutter_secure_storage
- `android/app/google-services.json` (FCM project config) — present in repo

## Webhooks & Callbacks

**Incoming:**
- FCM push messages (data messages → sync wake) handled by `push_notification_service.dart`
- WebSocket frames from relay (`websocket_service.dart`) — sync events / CRDT updates

**Outgoing:**
- HTTPS calls to relay API (`relay_api_client.dart`)
- WebSocket connection to `/ws/group/{groupId}`

## Connectivity

- connectivity_plus monitors network state; sync scheduler/lifecycle observers gate transport (`lib/infrastructure/sync/sync_scheduler.dart`, `sync_lifecycle_observer.dart`)

---

*Integration audit: 2026-06-23*
