# WebSocket Realtime Group Status Notification

**Date:** 2026-04-04
**Status:** Approved
**Related Module:** MOD-003 FamilySync

---

## Problem

When joining a group, both the applicant and the owner have waiting screens. The current mechanism relies on FCM/APNS push notifications to trigger the next step, but push notifications can be disabled by the user, throttled by the OS, or lost during network transitions. The existing 30-second polling fallback introduces unacceptable latency.

## Solution

Add a WebSocket realtime channel as the primary notification mechanism for group status changes, with push notifications and HTTP polling as fallback layers.

### Prerequisites

- Add `web_socket_channel: ^3.0.0` to `pubspec.yaml`

---

## Architecture: Three-Layer Notification Strategy

```
Priority 1: WebSocket realtime channel (primary, 1-2s latency)
    ↓ connection fails or drops
Priority 2: FCM/APNS push notifications (existing, unreliable)
    ↓ push disabled or lost
Priority 3: HTTP polling (fallback, 5s interval only when WebSocket unavailable)
```

---

## WebSocket Connection Lifecycle

WebSocket connections are **on-demand**, not globally persistent:

- **Establish:** When entering `WaitingApprovalScreen` or `MemberApprovalScreen`
- **Disconnect:** When leaving the waiting screen, receiving a confirmation event, or app backgrounded >60 seconds
- **Reconnect:** Exponential backoff (1s → 2s → 4s → 8s → max 30s), auto-degrade to polling during reconnection
- **Heartbeat:** Client sends ping every 30s, server responds pong, 45s without pong = disconnect

---

## Server-Side Design (Go Relay Server)

### New Endpoint

```
ws(s)://sync.happypocket.app/ws/group/{groupId}
```

### WebSocket Hub (Connection Manager)

```
Hub struct {
    groups:     map[string]map[*Client]bool   // groupId → connection set
    register:   chan *Client                    // register channel
    unregister: chan *Client                    // unregister channel
    broadcast:  chan BroadcastMessage           // broadcast channel
}
```

- Single Hub instance running a main loop goroutine, all operations serialized via channels (lock-free design)
- Each Client holds `groupId`, `deviceId`, `conn *websocket.Conn`
- Each Client has independent `readPump()` and `writePump()` goroutines

### Authentication Flow

1. Client connects and sends first message: `{ deviceId, timestamp, signature, protocolVersion: 1 }`
2. Signature content: `"ws:connect:{groupId}:{deviceId}:{timestamp}"` signed with device Ed25519 private key
3. Server verifies using registered public key, timestamp ±30s tolerance (replay prevention)
4. Auth success → register to Hub, immediately push current group status snapshot
5. Auth failure → close with code 4001, client does not retry (auth errors are non-recoverable)

**Note on signature format:** The WebSocket auth uses a purpose-specific signature prefix (`ws:connect`) instead of the REST HTTP method-based format (`<method>:<path>:<timestamp>:<SHA256(body)>`) because WebSocket upgrade requests do not carry request bodies, and the connection is scoped to a specific groupId which must be part of the signed payload. The `protocolVersion` field enables future backwards-compatible protocol changes.

### Integration with Existing REST APIs

Existing status-change endpoints broadcast to Hub after database operations:

| REST Endpoint | Hub Broadcast Event |
|---|---|
| `POST /group/confirm` (owner confirms member) | `member_confirmed` |
| `POST /group/{groupId}/confirm-join` (joiner confirms) | `join_request` |
| `POST /group/{groupId}/leave` | `member_left` |
| `DELETE /group/{groupId}` | `group_dissolved` |

Push notifications (FCM/APNS) continue to fire simultaneously as backup. No existing logic is removed.

### Event Message Format

```json
{
  "type": "member_confirmed | join_request | member_left | group_dissolved",
  "groupId": "uuid",
  "deviceId": "affected-device-id",
  "timestamp": "2026-04-04T12:00:00Z",
  "data": {}
}
```

Aligned with existing `SyncTriggerEvent` types so the client can process events through the same handler.

**Scope note:** The `syncAvailable` event type is intentionally excluded from the WebSocket channel. WebSocket connections are only active during group join/approval flows (on-demand), so data sync notifications continue to use push notifications as their primary channel. If WebSocket is later extended to be persistent, `syncAvailable` can be added.

### Resource Cleanup

- Connection closed → remove from Hub
- Group dissolved → close all connections under that group
- Idle groups (no connections) → map entry auto-cleaned, no memory cost
- Graceful shutdown → close all WebSocket connections

### Anti-Abuse

- Same `deviceId` + same `groupId` allows only one active connection (new connection kicks old)
- Unauthenticated connection not sending auth message within 5s → server closes
- Max 10 concurrent WebSocket connections per IP
- Max message size: 4KB for both client-to-server and server-to-client frames

---

## Client-Side Design (Flutter)

### New Component: WebSocketService

**Location:** `lib/infrastructure/sync/websocket_service.dart`

```
WebSocketService
├── connect(groupId, deviceId, privateKey) → void
├── disconnect() → void
├── eventStream → Stream<SyncTriggerEvent>
├── connectionState → Stream<ConnectionState>  // connected/connecting/disconnected
├── _startHeartbeat()
├── _handleReconnect()
└── _authenticateOnConnect()
```

- Uses `web_socket_channel` package (Flutter official)
- Connection states: `connected` / `connecting` / `disconnected`
- Parses received JSON messages, maps to existing `SyncTriggerEvent` types, pushes to `eventStream`
- Events merge with existing `SyncTriggerService` stream — UI is unaware of event source

### SyncTriggerService Integration

```
SyncTriggerService
├── _pushNotificationService    // existing: push → events
├── _webSocketService           // NEW: WebSocket → events
├── _eventController            // merges all event sources
└── eventStream                 // UI listens (unchanged)
```

WebSocket events and push events flow through the same `_eventController`. Downstream (UI layer) is completely unaware.

### Event Deduplication

The same event (e.g., `member_confirmed`) may arrive via both WebSocket and push notification within seconds. `SyncTriggerService` deduplicates at the processing level:

- Track last-processed event key as `(type, groupId)` with timestamp
- If a duplicate arrives within 10 seconds of the first, skip processing (log only)
- This prevents redundant `confirmLocalGroup()`, `fullSync()`, and `pullSync()` calls

### Three-Layer Degradation Logic in Waiting Screens

`WaitingApprovalScreen` and `MemberApprovalScreen` updated:

```
initState():
  1. Attempt WebSocket connection
  2. Listen to connectionState:
     - connected → stop polling, rely on WebSocket
     - disconnected → start 5s polling as fallback
     - connecting → maintain current state
  3. Listen to SyncTriggerEvent (unified entry, source-agnostic)
  4. Push notifications always active in background (unaffected by WebSocket state)

dispose():
  1. Disconnect WebSocket
  2. Cancel polling timer
```

### App Lifecycle Handling

```
App backgrounded → disconnect WebSocket after 60s (battery saving)
App foregrounded → if on waiting screen, reconnect WebSocket + execute one proactive check (compensate for events missed while backgrounded)
```

`WebSocketService` internally observes `AppLifecycleState` for its own connection management (background timer, foreground reconnect). This is WebSocket-specific logic and does not modify the existing `SyncLifecycleObserver` which handles data sync on resume.

### New Provider

```dart
// lib/features/family_sync/presentation/providers/sync_providers.dart
final webSocketServiceProvider = Provider<WebSocketService>(...);
```

Injected through existing `syncTriggerServiceProvider`, no new UI-layer providers.

---

## Security

### Transport Security
- `wss://` (TLS encrypted), same certificate as existing REST API
- Event messages contain no sensitive data (only type, groupId, deviceId, timestamp)
- Actual data sync (e.g., group key exchange) remains through existing E2EE REST API

### Authentication
- Ed25519 signature verification consistent with existing REST API auth
- Timestamp ±30s tolerance prevents replay attacks
- Auth failure = close code 4001, no retry

---

## Error Handling

| Scenario | Client Behavior |
|---|---|
| WebSocket connection failure | Degrade to polling (5s), background exponential backoff reconnect |
| WebSocket connection drop | Immediately start polling + reconnect, execute proactive check on reconnect |
| Auth failure (4001) | No retry, rely on push + polling only |
| Abnormal server message | Ignore and log, connection unaffected |
| App backgrounded | Disconnect after 60s, reconnect + proactive check on foreground |
| Network switch (WiFi ↔ cellular) | Proactive reconnect on network change detection |

---

## Test Strategy

### Server (Go)
- Hub unit tests: register/unregister/broadcast/concurrency safety
- WebSocket Handler tests: auth success/failure, message format, connection cleanup
- Integration tests: REST API trigger → WebSocket client receives event

### Client (Flutter)
- `WebSocketService` unit tests: connect/disconnect/reconnect/heartbeat/auth (mock WebSocket channel)
- `SyncTriggerService` integration tests: verify WebSocket events correctly merge into unified event stream
- Widget tests: `WaitingApprovalScreen` three-layer degradation (WebSocket connected → no polling, disconnected → polling active)
- Widget tests: `MemberApprovalScreen` refreshes list on `join_request` event

Integration test: simulate WebSocket disconnect mid-wait and verify the screen seamlessly falls back to polling and eventually receives the confirmation.

---

## Impact Summary

### Changed
- **New:** `WebSocketService` (infrastructure layer)
- **Modified:** `SyncTriggerService` adds WebSocket event source
- **Modified:** `WaitingApprovalScreen` / `MemberApprovalScreen` add three-layer degradation logic
- **Modified:** Polling interval from 30s → 5s with adaptive backoff (5s → 10s → 15s → 30s if no changes detected, only when WebSocket unavailable)
- **New:** Go Relay Server WebSocket Hub + Handler

### Architecture Note

A pre-existing `lib/features/family_sync/use_cases/` directory exists (violates the "Thin Feature" rule). This design does not introduce new use cases there. No new use cases are needed for this feature — all changes are in infrastructure (`WebSocketService`) and presentation (screen degradation logic).

### Unchanged
- `SyncTriggerEvent` types
- Use Case layer
- Domain layer (models, repository interfaces)
- Data layer (tables, DAOs, repository implementations)
- Push notification logic
- E2EE encryption logic
- All other screens
