# MOD-003 FamilySync: Server Relay Architecture Design

**Date:** 2026-02-28
**Status:** Approved
**Module:** MOD-003 FamilySync

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Server Stack | Go + PostgreSQL | High-performance, low resource, great concurrency model |
| Connection | HTTP REST + APNs/FCM Push | Not long-lived connections; most reliable for mobile |
| Pairing | Server-mediated (remote OK) | QR code + 6-digit short code, no face-to-face required |
| Encryption | E2EE (zero-knowledge server) | Client encrypts with partner's public key; server sees only ciphertext |
| Auth | Ed25519 device key signing | Anonymous, no user accounts, reuses existing crypto infrastructure |
| Conflict Resolution | Full CRDT (Yjs + Vector Clock) | Field-level LWW, client-side merge only, server is blind relay |

---

## Architecture Overview

```
Client A                    Server (Go)                  Client B
   |                           |                            |
   |-- POST /device/register ->| (store pubkey, no auth)    |
   |<-- 200 OK ---------------|                            |
   |                           |                            |
   |-- POST /pair/create ----->| (store pairing request)    |
   |<-- {pairCode, qrData} ---|                            |
   |                           |                            |
   |                           |<-- POST /device/register --|
   |                           |<-- POST /pair/join --------|
   |                           |   (match pairCode)         |
   |                           |-- push notify A ---------->|
   |<-- POST /pair/confirm --->|                            |
   |                           |-- push pair_confirmed B -->|
   |                           |                   B: confirming → active
   |== PAIRED (exchange public keys via server) ===========|
   |== Device A: fullSync() → push all existing txns ======|
   |                           |                            |
   |-- POST /sync/push ------>| (store encrypted blob)     |
   |                           |-- APNs/FCM notify B ------>|
   |                           |                            |
   |                           |<-- GET /sync/pull ---------|
   |                           |-- {encrypted blob} ------->|
   |                           |-- DELETE blob (after ACK) -|
```

Key principles:
1. Server is a "dumb relay" - only stores encrypted blobs it cannot read
2. Device key auth - every request signed with Ed25519 private key
3. Ephemeral storage - sync data physically deleted after successful delivery
4. CRDT operations - clients handle all merge logic locally

---

## Section 1: Pairing Flow

### Pairing Methods

| Method | Use Case |
|--------|----------|
| QR Code | Face-to-face or screenshot sharing |
| Short Code | Remote pairing via messaging/phone |

### Pairing Sequence

**Phase 0: Register Device (prerequisite for both A and B)**
- Each device calls POST /api/v1/device/register (unauthenticated, idempotent)
- Server stores deviceId + publicKey for subsequent signature verification
- Without this step, auth middleware cannot look up the public key to verify Ed25519 signatures

**Phase 1: Initiate (Device A)**
1. A calls registerDevice (idempotent, ensures server has public key)
2. A generates pairing request: bookId, deviceId, publicKey, deviceName, nonce
3. A sends POST /api/v1/pair/create to server
4. Server generates pairCode (6-digit, 10-min expiry, UNIQUE among pending) + pairToken (UUID)
5. Server stores pairing request (pending state)
6. A displays QR code + short code

**Phase 2: Join (Device B)**
1. B calls registerDevice (idempotent)
2. B scans QR code OR enters short code
3. B sends POST /api/v1/pair/join with B's publicKey, deviceId, deviceName
4. Server matches pairCode, stores B's info, marks "confirming"
5. Server sends push notification to A

**Phase 3: Confirm (Device A)**
1. A receives push, sees confirmation dialog
2. A confirms → POST /api/v1/pair/confirm
3. Server marks pair as "active", sends `pair_confirmed` silent push to B
4. B receives `pair_confirmed` push → calls `confirmLocalPair()` (confirming → active)
5. Both devices now have each other's public key and status == active
6. Device A triggers fullSync() — pushes all existing transactions to partner
7. B's `_handlePairConfirmed()` calls `pullSync()` after activation to receive fullSync data

### Unpair Flow
1. A sends DELETE /api/v1/pair/{pairId}
2. Server marks pair "inactive", deletes pending sync data
3. Server push notifies B
4. Both devices clear partner info locally

---

## Section 2: Sync Flow

### Sync Triggers

| Mode | Trigger | Direction |
|------|---------|-----------|
| Active Push | Client creates/edits/deletes transaction | Client → Server → Partner |
| Passive Pull | Client opens app or returns from background | Client ← Server |

### Active Push
1. A generates CRDT operation
2. A encrypts with E2EE (X25519-XSalsa20-Poly1305)
3. A sends POST /api/v1/sync/push with encrypted payload
4. Server stores in sync_messages table
5. Server sends silent push (APNs/FCM) to B
6. On failure → A queues for retry

### Passive Pull
1. B sends GET /api/v1/sync/pull?since={lastServerCursor}
2. Server returns all pending encrypted messages (filtered by server-side created_at)
3. B decrypts each payload, applies CRDT operations locally
4. B sends POST /api/v1/sync/ack with messageIds
5. Server physically DELETEs acknowledged messages
6. B stores the last message's server-side created_at as the sync cursor (NOT client wall-clock time, to avoid clock-skew message loss)

### Server Ephemeral Storage Lifecycle
```
Created → Stored → Push Sent → Pulled → ACKed → DELETED
                      │                    │
                      │                    └─ Physical DELETE
                      └─ Retry push if no pull within 1h
TTL: 7 days max (auto-cleanup if never pulled)
```

### Offline Queue
- Operations saved to local sync_queue table
- Drain on app foreground / network restore
- Batch push: up to 50 operations per request
- Queue capacity: 10,000+ operations

### Batch Sync (Initial Full Sync)
- After pairing, generate CRDT snapshot of all transactions
- Split into chunks (max 500KB, gzip compressed)
- Push/pull chunks sequentially
- Switch to incremental mode after completion

---

## Section 3: Server API Design

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/pair/create` | Create pairing request |
| POST | `/pair/join` | Join with short code or QR |
| POST | `/pair/confirm` | Confirm pairing |
| GET | `/pair/status/{pairId}` | Poll pairing status |
| DELETE | `/pair/{pairId}` | Unpair devices |
| POST | `/sync/push` | Push encrypted CRDT operations |
| GET | `/sync/pull` | Pull pending messages |
| POST | `/sync/ack` | ACK received messages |
| POST | `/device/register` | Register device + push token |
| PUT | `/device/push-token` | Update push token |

### Authentication
```
Authorization: Ed25519 <deviceId>:<timestamp>:<signature>
Signature = sign("<method>:<path>:<timestamp>:<SHA256(body)>", privateKey)
```

### Rate Limiting

| Endpoint | Limit |
|----------|-------|
| `/pair/*` | 10 req/min |
| `/sync/push` | 60 req/min |
| `/sync/pull` | 30 req/min |
| `/device/*` | 5 req/min |

---

## Section 4: Server Data Model

### PostgreSQL Schema

```sql
CREATE TABLE devices (
    device_id       TEXT PRIMARY KEY,
    public_key      TEXT NOT NULL,
    device_name     TEXT NOT NULL,
    platform        TEXT NOT NULL,
    push_token      TEXT,
    push_platform   TEXT,
    registered_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE pairs (
    pair_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id         TEXT NOT NULL,
    device_a_id     TEXT NOT NULL REFERENCES devices(device_id),
    device_b_id     TEXT REFERENCES devices(device_id),
    pair_code       TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'pending',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL,
    confirmed_at    TIMESTAMPTZ,
    deactivated_at  TIMESTAMPTZ
);

CREATE TABLE sync_messages (
    message_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pair_id         UUID NOT NULL REFERENCES pairs(pair_id),
    from_device_id  TEXT NOT NULL REFERENCES devices(device_id),
    to_device_id    TEXT NOT NULL REFERENCES devices(device_id),
    payload         BYTEA NOT NULL,
    vector_clock    JSONB NOT NULL,
    operation_count INT NOT NULL DEFAULT 1,
    chunk_index     INT NOT NULL DEFAULT 0,
    total_chunks    INT NOT NULL DEFAULT 1,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '7 days'
);
```

### Cleanup Jobs

| Job | Schedule | Action |
|-----|----------|--------|
| Expire pair codes | Every 1 min | Set expired pending pairs to inactive |
| Delete expired messages | Every 1 hour | DELETE sync_messages past TTL |
| Cleanup inactive devices | Weekly | DELETE devices not seen in 90 days |

---

## Section 5: Client Architecture Changes

### New Client Module Structure

```
lib/infrastructure/sync/          # Sync technology layer
├── relay_api_client.dart          # HTTP client for server API
├── e2ee_service.dart              # X25519 encrypt/decrypt
├── push_notification_service.dart # APNs/FCM token management
└── sync_queue_manager.dart        # Offline queue drain

lib/application/family_sync/      # Business logic
├── create_pair_use_case.dart
├── join_pair_use_case.dart
├── confirm_pair_use_case.dart
├── unpair_use_case.dart
├── push_sync_use_case.dart
├── pull_sync_use_case.dart
└── full_sync_use_case.dart

lib/data/tables/                   # Drift tables
├── paired_devices_table.dart
└── sync_queue_table.dart

lib/features/family_sync/         # Thin Feature
├── domain/models/
├── domain/repositories/
└── presentation/
```

### Removed Components (vs Original P2P Design)
- No BLE (flutter_blue_plus)
- No NFC (nfc_manager)
- No WiFi Direct
- No connection_manager (BLE version)

### App Lifecycle Integration
- `resumed` → pullSync() + drainSyncQueue()
- `onTransactionCreated` → pushSync(crdtOps)
- `onTransactionUpdated` → pushSync(crdtOps)
- `onTransactionDeleted` → pushSync(crdtOps)
- `onPushNotification` → pullSync()

---

## Section 6: Security Design

### E2EE Flow
1. Convert Ed25519 → X25519 (Montgomery form)
2. Derive shared secret via X25519 Diffie-Hellman
3. Encrypt with XSalsa20-Poly1305 (NaCl box)
4. Server sees only ciphertext

### Request Authentication
- Ed25519 signature on every request
- Signed message: `<method>:<path>:<timestamp>:<bodyHash>`
- Server rejects requests older than 5 minutes

### Zero-Knowledge Guarantee
Server knows: device_id, public_key, pair relationships, sync timing, blob size
Server CANNOT know: amounts, categories, merchants, notes, any financial data

### Push Notification Security
- No sensitive data in any push payload
- Three event types, all silent push (content-available: 1):
  - `sync_available` — signals "new sync data available", client calls pullSync()
  - `pair_confirmed` — signals "partner confirmed pairing", client calls confirmLocalPair() + pullSync()
  - `pair_request` — visible notification to Device A that B wants to pair (only event with alert body)

---

## Section 7: CRDT Integration

CRDT logic remains 100% client-side. Server is a blind relay.

### Operation Format (plaintext before encryption)
```json
{
  "version": 1,
  "deviceId": "dev-A",
  "vectorClock": {"dev-A": 42, "dev-B": 38},
  "operations": [
    {
      "id": "op-uuid",
      "type": "insert",
      "entityType": "transaction",
      "entityId": "tx-uuid",
      "timestamp": 1709123456,
      "data": { ... }
    }
  ]
}
```

### Conflict Resolution (per ADR-010)
- Field-level Last-Write-Wins (LWW)
- Delete wins over edit
- Vector clock for causal ordering

---

## Section 8: Future Consideration - Message Queue

**Not in MVP.** Evaluate when scaling needs arise.

### Options to Evaluate

| Option | Pros | Cons | Evaluate When |
|--------|------|------|---------------|
| Redis Streams | Sub-ms latency, consumer groups | Extra infrastructure | sync_messages > 100K rows |
| NATS JetStream | Go-native, lightweight, persistent | One more service | Push latency > 5s P95 |
| PostgreSQL LISTEN/NOTIFY | No new infra | 8KB payload limit | Need real-time without push |

### Migration Signals
- sync_messages table sustained > 100K rows → Redis Streams
- Push delivery latency > 5s P95 → NATS JetStream
- > 10K active pairs → Must migrate off pure PostgreSQL
- Current design works fine → Don't change

---

**Document Status:** Approved
**Created:** 2026-02-28
