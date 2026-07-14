# External Integrations

**Analysis Date:** 2026-07-14

## Overview

Home Pocket is **local-first and privacy-focused** with a zero-knowledge architecture. External network dependencies are deliberately minimal: a self-hosted sync relay for P2P family sync and Firebase Cloud Messaging for push. No third-party analytics, no cloud database, no auth SaaS.

## APIs & External Services

**Sync Relay (self-hosted):**
- Purpose: Relays end-to-end-encrypted CRDT sync payloads between family devices
- Client: `lib/infrastructure/sync/relay_api_client.dart` (HTTP via `http ^1.6.0`)
- Default base URL: `https://sync.happypocket.app/api/v1`
- Override: `--dart-define=SYNC_SERVER_URL=...`
- Auth: Requests signed with Ed25519 device key (no bearer token / API key)
- WebSocket transport: `lib/infrastructure/sync/websocket_service.dart` — connects to `{baseUrl}/ws/group/{groupId}` via `web_socket_channel ^3.0.0`

**Firebase Cloud Messaging:**
- Purpose: Wake devices for sync (push notification signal)
- SDK: `firebase_core ^4.1.1`, `firebase_messaging ^16.0.1`
- Config: `android/app/google-services.json` (project `happy-pocket-11c5c`)
- Client wrappers: `lib/infrastructure/sync/push_notification_service.dart`, `apns_push_messaging_client.dart` (APNs on iOS)

## Data Storage

**Databases:**
- SQLCipher (SQLite + AES-256-CBC encryption) via Drift
  - Definition: `lib/data/app_database.dart` (schema v23)
  - Tables: `lib/data/tables/`, DAOs: `lib/data/daos/`, repos: `lib/data/repositories/`
  - Encryption executor: `lib/infrastructure/crypto/database/createEncryptedExecutor`
  - Natives: `sqlcipher_flutter_libs ^0.6.7` (NOT `sqlite3_flutter_libs`)

**File Storage:**
- Local filesystem only (`path_provider`). Receipt photos encrypted with AES-256-GCM before write

**Settings:**
- `shared_preferences ^2.3.4` — plaintext key/value (`AppSettings`), one key per field. NOT encrypted, NOT Drift

**Caching:**
- None (offline-first local DB is the source of truth)

## Authentication & Identity

**No external auth provider.** Zero-knowledge / device-local identity:
- Device identity: Ed25519 device key pair (`lib/infrastructure/crypto/`)
- Recovery: BIP39 recovery phrase, HKDF key derivation
- App lock: biometric (Face ID / fingerprint) + PIN via `local_auth ^3.0.1` — `lib/features/applock/`
- Master key stored in OS keychain via `flutter_secure_storage ^10.2.0` (accessibility `unlocked_this_device` — DO NOT change)
- Sync server auth: Ed25519-signed HTTP requests (no accounts, no passwords server-side)

## Monitoring & Observability

**Error Tracking:**
- None (no Sentry/Crashlytics — privacy-by-design)

**Logs:**
- Local audit logging via `lib/infrastructure/security/audit_logger`. `avoid_print` lint enforced; no sensitive data logged

## CI/CD & Deployment

**Hosting:**
- Mobile app (App Store / Google Play). Sync relay self-hosted (out of this repo)

**CI Pipeline:**
- GitHub Actions: `.github/workflows/audit.yml`
- Runner: ubuntu-latest, `subosito/flutter-action@v2` pinned to Flutter `3.44.0`
- Jobs: `flutter analyze --no-fatal-infos`, `dart run custom_lint`, audit scanners (`scripts/merge_findings.dart`), build_runner clean-diff gate (AUDIT-10), `sqlite3_flutter_libs` reject gate (AUDIT-09), `flutter test --coverage` with per-file ≥70% gate (`scripts/coverage_gate.dart`, `coverde 0.3.0+1`)

## Device Capabilities & Permissions

**iOS (`ios/Runner/Info.plist`):**
- `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` — voice entry (`speech_to_text ^7.0.0`)
- `NSFaceIDUsageDescription` — biometric app lock (required or TCC crash on device)

**Feature plugins:**
- Voice input: `speech_to_text ^7.0.0` (`lib/infrastructure/speech/`, `voice/`)
- Camera / photo: `image_picker ^1.1.2` (receipt capture)
- Network state: `connectivity_plus ^7.1.1` (sync scheduling)
- QR: `qr_flutter ^4.1.0` (family pairing)
- File import/export: `file_picker ^11.0.2`, `share_plus ^12.0.2` (backup)
- External URLs: `url_launcher ^6.3.2` (privacy/terms/sponsor links)

## ML / OCR

- CLAUDE.md references ML Kit / TFLite receipt OCR and a merchant classifier as **planned** architecture. No `google_mlkit_*` or `tflite` package is present in `pubspec.yaml` as of this analysis. The only shipped ML code is a rule-based `lib/infrastructure/ml/merchant_name_normalizer.dart`. The iOS `EXCLUDED_ARCHS` Podfile fix anticipates ML Kit but the SDK is not yet a dependency

## Webhooks & Callbacks

**Incoming:**
- FCM/APNs push messages (handled by `push_notification_service.dart` / `apns_push_messaging_client.dart`)
- WebSocket sync messages from relay (`websocket_service.dart`)

**Outgoing:**
- Ed25519-signed HTTP calls to the sync relay (`relay_api_client.dart`)

---

*Integration audit: 2026-07-14*
