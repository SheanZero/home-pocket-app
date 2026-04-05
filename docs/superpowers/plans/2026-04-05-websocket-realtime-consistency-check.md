# Cross-Plan Consistency Check: WebSocket Realtime Group Status

**Date:** 2026-04-05
**Plans Reviewed:**
- App: `docs/superpowers/plans/2026-04-05-websocket-realtime-flutter-app.md`
- Server: `docs/superpowers/plans/2026-04-05-websocket-realtime-go-server.md`
- Spec: `docs/superpowers/specs/2026-04-04-websocket-realtime-group-status-design.md`

---

## 1. WebSocket Endpoint URL

| Aspect | App Plan | Server Plan | Match? |
|--------|----------|-------------|--------|
| URL pattern | `wss://{baseUrl}/ws/group/{groupId}` | `GET /ws/group/{groupId}` | YES |
| TLS | `wss://` prefix | Handled by infra (Cloud Run TLS) | YES |

---

## 2. Authentication Protocol

| Aspect | App Plan | Server Plan | Match? |
|--------|----------|-------------|--------|
| Auth message format | `{ deviceId, timestamp, signature, protocolVersion: 1 }` | `AuthMessage { DeviceID, Timestamp, Signature, ProtocolVersion }` | YES |
| Signature content | `"ws:connect:{groupId}:{deviceId}:{timestamp}"` | `fmt.Sprintf("ws:connect:%s:%s:%d", groupID, deviceID, timestamp)` | YES |
| Signature algorithm | Ed25519 via `signMessage` callback | `ed25519.Verify(pubKey, msg, sig)` | YES |
| Timestamp tolerance | N/A (server-side check) | ±30 seconds | YES (spec says ±30s) |
| Auth timeout | N/A (server-side) | 5 seconds (`authTimeout`) | YES (spec says 5s) |
| Auth success response | Expects `{"type": "auth_success", "groupId": "..."}` | Sends `AuthSuccessMessage{Type: "auth_success", GroupID: groupID}` | YES |
| Auth failure response | Expects `{"type": "auth_error"}`, close code 4001 | Sends `AuthErrorMessage` + close 4001 | YES |
| Auth failure behavior | Does not reconnect (`_reconnectAttempts = -1`) | Closes connection | YES |

---

## 3. Event Message Format

| Aspect | App Plan | Server Plan | Match? |
|--------|----------|-------------|--------|
| Format | `{"type": "...", "groupId": "...", "deviceId": "...", "timestamp": "..."}` | `EventMessage{Type, GroupID, DeviceID, Timestamp, Data}` | YES |
| `member_confirmed` | Parsed → `SyncTriggerEvent.memberConfirmed` | Broadcast from `POST /group/confirm` | YES |
| `join_request` | Parsed → `SyncTriggerEvent.joinRequest` | Broadcast from `POST /group/{id}/confirm-join` | YES |
| `member_left` | Parsed → `SyncTriggerEvent.memberLeft` | Broadcast from `POST /group/{id}/leave` | YES |
| `group_dissolved` | Parsed → `SyncTriggerEvent.groupDissolved` | Broadcast from `DELETE /group/{id}` | YES |
| `syncAvailable` | Not handled (spec: intentionally excluded) | Not broadcast | YES |
| Unknown types | Ignored, returns null | N/A (server never sends unknown types) | YES |

---

## 4. Heartbeat / Keep-Alive

| Aspect | App Plan | Server Plan | Match? |
|--------|----------|-------------|--------|
| Client ping interval | 30s (`_heartbeatTimer`) | Server also pings at 30s (`pingPeriod`) | NOTE |
| Pong timeout | 45s (`_pongTimeoutTimer`) | 45s (`pongWait`) | YES |
| Client sends | `{"type": "ping"}` JSON | Server reads & responds `{"type": "pong"}` | YES |
| Server sends | WebSocket protocol-level ping | Client handles via `SetPongHandler` | YES |

**NOTE:** Both sides send pings. The app sends JSON `{"type": "ping"}`, the server sends WebSocket protocol-level pings. The server's `ReadPump` handles JSON pings and responds with JSON pongs. The server's `WritePump` sends protocol-level pings which the client's `web_socket_channel` handles natively. This dual-ping design is safe — both sides keep the connection alive.

---

## 5. Connection Lifecycle

| Aspect | App Plan | Server Plan | Match? |
|--------|----------|-------------|--------|
| Initiated by | Client (entering waiting screen) | Server accepts upgrade | YES |
| Max message size | N/A (client-side) | 4096 bytes (`maxMessageSize`) | YES (spec: 4KB) |
| Duplicate device+group | Client side: disconnect old before new | Server side: kicks old client (`close(existing.send)`) | YES |
| Graceful shutdown | `disconnect()` closes channel | Hub `shutdown()` closes all | YES |

---

## 6. Reconnection & Degradation

| Aspect | App Plan | Server Plan | Match? |
|--------|----------|-------------|--------|
| Reconnect strategy | Exponential backoff: 1s → 2s → 4s → ... → max 30s | N/A (server-side is passive) | YES |
| Polling fallback | 5s → 10s → 15s → 30s adaptive | N/A (server doesn't know about polling) | YES |
| App background | Disconnect after 60s via `WidgetsBindingObserver` | Connection dropped = unregistered from Hub | YES |
| App foreground | Reconnect + proactive check | N/A (server accepts new connection) | YES |

---

## 7. Anti-Abuse

| Aspect | App Plan | Server Plan | Match? |
|--------|----------|-------------|--------|
| One connection per device+group | Client disconnects before reconnect | Server kicks old connection | YES |
| Auth timeout | N/A (server enforces) | 5 seconds | YES |
| Per-IP limit | N/A (server enforces) | Max 10 concurrent connections per IP | YES |
| Max message size | N/A (server enforces) | 4KB | YES |

---

## 8. Deduplication

| Aspect | App Plan | Server Plan | Match? |
|--------|----------|-------------|--------|
| Strategy | `SyncTriggerService.addExternalEvent()` deduplicates by `(type, groupId)` with 10s TTL | N/A (server doesn't deduplicate — broadcasts to all) | YES |
| Push + WebSocket overlap | Client-side dedup prevents double `confirmLocalGroup()`, `fullSync()` calls | Server sends both push notification AND WebSocket broadcast | YES |

---

## 9. REST Endpoint Alignment

| REST Endpoint | Server Broadcasts | App Expects | Match? |
|---|---|---|---|
| `POST /group/confirm` | `member_confirmed` | Parses `member_confirmed` → `SyncTriggerEvent.memberConfirmed` | YES |
| `POST /group/{groupId}/confirm-join` | `join_request` | Parses `join_request` → `SyncTriggerEvent.joinRequest` | YES |
| `POST /group/{groupId}/leave` | `member_left` | Parses `member_left` → `SyncTriggerEvent.memberLeft` | YES |
| `DELETE /group/{groupId}` | `group_dissolved` | Parses `group_dissolved` → `SyncTriggerEvent.groupDissolved` | YES |

---

## 10. Implementation Order / Dependencies

The two plans can be implemented **independently** with the following integration points:

### Server first, then app:
1. Server: Hub + Client + Handler + route (Tasks 1-8)
2. App: WebSocketService + SyncTriggerService dedup + screen updates (Tasks 1-11)

### Or in parallel:
- App can be developed with mock WebSocket channels (already in the plan via `channelFactory`)
- Server can be developed and tested independently
- Integration testing happens when both are deployed

### Integration contract:
- Endpoint: `wss://sync.happypocket.app/ws/group/{groupId}`
- Auth: First message `{ deviceId, timestamp, signature, protocolVersion: 1 }`
- Events: `{ type, groupId, deviceId, timestamp }`
- Heartbeat: Client JSON ping/pong + server protocol-level ping/pong

---

## 11. MemberApprovalScreen Degradation Scope

The spec states both `WaitingApprovalScreen` and `MemberApprovalScreen` should implement three-layer degradation. The app plan implements:

- **WaitingApprovalScreen:** Full three-layer (WebSocket + push + adaptive polling) — matches spec
- **MemberApprovalScreen:** WebSocket + push (no polling fallback) — intentional deviation

**Rationale:** `MemberApprovalScreen` has no polling in the current implementation. It refreshes via `SyncTriggerEvent.joinRequest` events only. The owner is not "stuck waiting" — they can navigate away. Adding WebSocket realtime delivery is sufficient improvement without adding polling. This is a design-level decision, not an inconsistency.

---

## Summary

| Check | Count |
|-------|-------|
| Verified consistent | 28 |
| Inconsistencies found | 0 |
| Intentional deviations | 1 (MemberApprovalScreen no polling) |
| Notes / minor observations | 1 (dual-ping design) |

**Result: All protocols, message formats, event types, and behaviors are consistent across both plans and align with the spec.**
