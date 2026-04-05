# Home Pocket Relay — API & WebSocket Protocol

> Version: 2026-04-05  
> Base URL: `https://sync.happypocket.app/api/v1`  
> WebSocket URL: `wss://sync.happypocket.app/ws`

## Table of Contents

- [General](#general)
- [Authentication](#authentication)
- [Rate Limiting](#rate-limiting)
- [Error Format](#error-format)
- [REST API](#rest-api)
  - [Health](#1-health-check)
  - [Push Stats](#2-push-stats)
  - [Device](#3-device)
  - [Group](#4-group)
  - [Sync](#5-sync)
- [WebSocket Protocol](#websocket-protocol)
  - [Connection & Auth](#connection--auth)
  - [Server → Client Events](#server--client-events)
  - [Client → Server Messages](#client--server-messages)
  - [Heartbeat](#heartbeat)
- [Push Notifications](#push-notifications)

---

## General

| Item | Value |
|---|---|
| Content-Type | `application/json` |
| Body Limit | 2 MB (`/api/v1` routes) |
| CORS | `Access-Control-Allow-Origin: *` |
| Timestamp format | ISO 8601 `2006-01-02T15:04:05Z` (response fields) / Unix epoch seconds (auth) |

---

## Authentication

All `/api/v1` endpoints except `/health`, `/push/stats`, and `/device/register` require Ed25519 signature authentication.

### Auth Header Format

```
Authorization: Ed25519 <deviceId>:<timestamp>:<signature>
```

| Component | Description |
|---|---|
| `deviceId` | The registered device ID |
| `timestamp` | Current Unix epoch seconds (integer) |
| `signature` | Base64-encoded Ed25519 signature of the signed message |

### Signed Message Construction

```
<HTTP_METHOD>:<PATH>:<timestamp>:<SHA256_HEX(body)>
```

- `HTTP_METHOD`: uppercase (`GET`, `POST`, `PUT`, `DELETE`)
- `PATH`: full path including prefix, e.g. `/api/v1/sync/push`
- `timestamp`: same value as in the header
- `SHA256_HEX(body)`: lowercase hex SHA-256 of the raw request body (empty body → SHA-256 of empty bytes)

### Timestamp Window

Server accepts timestamps within **±300 seconds** (5 minutes) of server time.

### Signature Verification

The server decodes the device's registered `publicKey` (Base64 Ed25519, 32 bytes) and verifies the signature over the signed message bytes.

---

## Rate Limiting

### Authenticated endpoints (keyed by deviceId)

| Route prefix | Rate | Burst |
|---|---|---|
| `/api/v1/group/` | 10/min (1 per 6s) | 5 |
| `/api/v1/sync/push` | 60/min (1 per 1s) | 10 |
| `/api/v1/sync/pull` | 30/min (1 per 2s) | 5 |
| `/api/v1/sync/ack` | 30/min (1 per 2s) | 5 |

### Unauthenticated endpoints (keyed by client IP)

| Route prefix | Rate | Burst |
|---|---|---|
| `/api/v1/device/` | 5/min (1 per 12s) | 5 |

### WebSocket

Max **10 concurrent WebSocket connections** per client IP.

### Rate Limit Response

```
HTTP/1.1 429 Too Many Requests
Retry-After: 60
Content-Type: application/json

{"error": "rate limit exceeded"}
```

---

## Error Format

All errors return:

```json
{
  "error": "<human-readable message>"
}
```

---

## REST API

### 1. Health Check

```
GET /api/v1/health
```

**Auth:** None

**Response 200:**

```json
{
  "status": "healthy",
  "database": "connected",
  "version": "1.0.0",
  "uptime": "2h30m15s"
}
```

**Response 503:**

```json
{
  "status": "unhealthy",
  "database": "unreachable"
}
```

---

### 2. Push Stats

```
GET /api/v1/push/stats
```

**Auth:** None

**Response 200:**

```json
{
  "since": "2026-04-05T10:00:00Z",
  "byPlatform": {
    "apns": { "sent": 150, "failed": 2 },
    "fcm": { "sent": 80, "failed": 0 }
  },
  "byType": {
    "sync_available": { "sent": 200, "failed": 1 },
    "join_request": { "sent": 30, "failed": 1 }
  },
  "recent": [
    {
      "time": "2026-04-05T12:00:00Z",
      "platform": "apns",
      "pushType": "sync_available",
      "silent": true,
      "success": true
    }
  ]
}
```

---

### 3. Device

#### 3.1 Register Device

```
POST /api/v1/device/register
```

**Auth:** None (IP rate-limited)

**Request:**

```json
{
  "deviceId": "string (required)",
  "publicKey": "string, Base64 Ed25519 public key (required)",
  "deviceName": "string (required)",
  "platform": "string, 'ios' | 'android' (required)"
}
```

**Response 201** (new device created):

```json
{
  "deviceId": "abc123",
  "deviceName": "iPhone 15",
  "platform": "ios",
  "created": true
}
```

**Response 200** (existing device, same publicKey — idempotent update):

```json
{
  "deviceId": "abc123",
  "deviceName": "iPhone 15",
  "platform": "ios",
  "created": false
}
```

**Error Responses:**

| Status | Condition |
|---|---|
| 400 | Missing required fields or invalid platform |
| 409 | `deviceId` exists with a **different** `publicKey` |

---

#### 3.2 Update Push Token

```
PUT /api/v1/device/push-token
```

**Auth:** Required

**Request:**

```json
{
  "pushToken": "string (required)",
  "pushPlatform": "string, 'apns' | 'fcm' (required)"
}
```

**Response 200:**

```json
{
  "status": "ok"
}
```

**Error Responses:**

| Status | Condition |
|---|---|
| 400 | Missing fields or invalid pushPlatform |
| 401 | Not authenticated |

---

### 4. Group

All group endpoints require authentication.

#### 4.1 Check Group

```
GET /api/v1/group/check
```

Check whether the authenticated device belongs to an active group.

**Response 200:**

```json
{
  "groupExisted": true,
  "groupId": "550e8400-e29b-41d4-a716-446655440000"
}
```

or:

```json
{
  "groupExisted": false
}
```

---

#### 4.2 Create Group

```
POST /api/v1/group/create
```

Creates a new group with the authenticated device as owner. **Idempotent** — if the device already owns a group, returns the existing group (with a newly regenerated invite code).

**Request (optional body):**

```json
{
  "groupName": "string (optional, 1-50 chars)",
  "displayName": "string (optional, owner display name)",
  "avatarEmoji": "string (optional, e.g. '🏠')",
  "avatarImageHash": "string | null (optional)"
}
```

**Response 201** (new group):

```json
{
  "groupId": "550e8400-e29b-41d4-a716-446655440000",
  "inviteCode": "A1B2C3",
  "expiresAt": 1712345678
}
```

**Response 200** (existing group, idempotent):

Same format as above with refreshed invite code.

---

#### 4.3 Join Group (Preview)

```
POST /api/v1/group/join
```

Lookup a group by invite code and return group/owner info for the joiner to review. This is a **read-only** operation — the member is not persisted until `confirm-join`.

**Request:**

```json
{
  "inviteCode": "string (required, 6-char code)",
  "displayName": "string (optional)",
  "avatarEmoji": "string (optional)",
  "avatarImageHash": "string | null (optional)"
}
```

**Response 200:**

```json
{
  "groupId": "550e8400-e29b-41d4-a716-446655440000",
  "deviceName": "iPhone 15",
  "members": [
    {
      "deviceId": "owner-device-id",
      "publicKey": "Base64...",
      "deviceName": "iPhone 15",
      "role": "owner",
      "status": "active",
      "displayName": "Papa",
      "avatarEmoji": "🏠",
      "avatarImageHash": "sha256hex..."
    }
  ],
  "status": "active",
  "groupName": "My Family",
  "owner": {
    "deviceId": "owner-device-id",
    "displayName": "Papa",
    "avatarEmoji": "🏠",
    "avatarImageHash": "sha256hex..."
  }
}
```

**Error Responses:**

| Status | Condition |
|---|---|
| 400 | Missing `inviteCode` |
| 404 | Invite code not found or expired |
| 409 | Device already a member / Group full |

---

#### 4.4 Confirm Join

```
POST /api/v1/group/{groupId}/confirm-join
```

Called by the joiner after reviewing group info. Persists the member as `pending` and notifies the owner.

**Path Parameters:**

| Param | Description |
|---|---|
| `groupId` | UUID of the group |

**Request:**

```json
{
  "confirmed": true,
  "displayName": "string (optional)",
  "avatarEmoji": "string (optional)",
  "avatarImageHash": "string | null (optional)"
}
```

If `confirmed: false`, this is a no-op (joiner declined).

**Response 200:**

```json
{
  "success": true
}
```

**Error Responses:**

| Status | Condition |
|---|---|
| 400 | Invalid `groupId` |
| 404 | Group not found / Device not found |
| 409 | Group inactive / Group full / Already has pending joiner |

**Side Effects:**
- WebSocket broadcast: `join_request` event to all group clients
- Push notification: `join_request` to group owner

---

#### 4.5 Confirm Member (Owner approves)

```
POST /api/v1/group/confirm
```

Called by the group owner to confirm a pending member. Changes member status from `pending` → `active`.

**Request:**

```json
{
  "groupId": "string UUID (required)",
  "deviceId": "string, the joining device (required)"
}
```

**Response 200:**

```json
{
  "status": "active",
  "memberPublicKey": "Base64...",
  "memberDeviceName": "Pixel 8"
}
```

**Error Responses:**

| Status | Condition |
|---|---|
| 400 | Missing `groupId` or `deviceId` |
| 403 | Caller is not the group owner |
| 404 | Group or member not found |
| 409 | Member is not in `pending` status |

**Side Effects:**
- WebSocket broadcast: `member_confirmed` event
- Push notification: `member_confirmed` to the newly confirmed member
- Push notification: `sync_available` to other active members

---

#### 4.6 Group Status

```
GET /api/v1/group/{groupId}/status
```

Returns the full group status including all members.

**Path Parameters:**

| Param | Description |
|---|---|
| `groupId` | UUID of the group |

**Response 200:**

```json
{
  "groupId": "550e8400-...",
  "status": "active",
  "groupName": "My Family",
  "inviteCode": "A1B2C3",
  "inviteExpiresAt": 1712345678,
  "members": [
    {
      "deviceId": "device-1",
      "publicKey": "Base64...",
      "deviceName": "iPhone 15",
      "role": "owner",
      "status": "active",
      "displayName": "Papa",
      "avatarEmoji": "🏠",
      "avatarImageHash": null
    },
    {
      "deviceId": "device-2",
      "publicKey": "Base64...",
      "deviceName": "Pixel 8",
      "role": "member",
      "status": "pending",
      "displayName": "Mama",
      "avatarEmoji": "🌸",
      "avatarImageHash": null
    }
  ]
}
```

**Error Responses:**

| Status | Condition |
|---|---|
| 400 | Invalid `groupId` |
| 403 | Caller is not a member of this group |
| 404 | Group not found |

---

#### 4.7 Rename Group

```
PUT /api/v1/group/{groupId}/name
```

Owner-only. Renames the group.

**Path Parameters:**

| Param | Description |
|---|---|
| `groupId` | UUID of the group |

**Request:**

```json
{
  "groupName": "string (required, 1-50 chars)"
}
```

**Response 200:**

```json
{
  "groupId": "550e8400-...",
  "groupName": "New Name",
  "updatedAt": "2026-04-05T12:00:00Z"
}
```

**Error Responses:**

| Status | Condition |
|---|---|
| 400 | Invalid `groupId` or invalid group name |
| 403 | Caller is not the group owner |

**Side Effects:**
- Push notification: `group_name_updated` to all non-owner members

---

#### 4.8 Deactivate Group (Dissolve)

```
DELETE /api/v1/group/{groupId}
```

Owner-only. Deactivates the group, marks it as `inactive`.

**Path Parameters:**

| Param | Description |
|---|---|
| `groupId` | UUID of the group |

**Response 200:**

```json
{
  "status": "inactive"
}
```

**Error Responses:**

| Status | Condition |
|---|---|
| 400 | Invalid `groupId` |
| 403 | Caller is not the group owner |
| 404 | Group not found |

**Side Effects:**
- WebSocket broadcast: `group_dissolved` event to all group clients
- WebSocket: all group connections are closed immediately after broadcast
- Push notification: `group_dissolved` to all active non-owner members

---

#### 4.9 Leave Group

```
POST /api/v1/group/{groupId}/leave
```

Non-owner member voluntarily leaves the group.

**Path Parameters:**

| Param | Description |
|---|---|
| `groupId` | UUID of the group |

**Request:** Empty body

**Response 200:**

```json
{
  "status": "removed"
}
```

**Error Responses:**

| Status | Condition |
|---|---|
| 400 | Invalid `groupId` / Owner cannot leave (must deactivate instead) |
| 404 | Group not found |

**Side Effects:**
- WebSocket broadcast: `member_left` event (with leaving device's `deviceId`)
- Push notification: `member_left` (reason: `"left"`) to all remaining active members

---

#### 4.10 Remove Member

```
POST /api/v1/group/{groupId}/remove
```

Owner-only. Removes a member from the group.

**Path Parameters:**

| Param | Description |
|---|---|
| `groupId` | UUID of the group |

**Request:**

```json
{
  "deviceId": "string, the device to remove (required)"
}
```

**Response 200:**

```json
{
  "status": "removed"
}
```

**Error Responses:**

| Status | Condition |
|---|---|
| 400 | Missing `deviceId` / Cannot remove owner |
| 403 | Caller is not the group owner |

**Side Effects:**
- WebSocket broadcast: `member_left` event (with removed device's `deviceId`)
- Push notification: `member_left` (reason: `"removed"`) to all remaining active members (including the removed member)

---

#### 4.11 Regenerate Invite Code

```
POST /api/v1/group/{groupId}/invite
```

Owner-only. Generates a new 6-digit invite code, invalidating the previous one.

**Path Parameters:**

| Param | Description |
|---|---|
| `groupId` | UUID of the group |

**Request:** Empty body

**Response 200:**

```json
{
  "inviteCode": "X9Y8Z7",
  "expiresAt": 1712345678
}
```

**Error Responses:**

| Status | Condition |
|---|---|
| 400 | Invalid `groupId` |
| 403 | Caller is not the group owner |
| 404 | Group not found |

---

### 5. Sync

All sync endpoints require authentication. The server stores and forwards **opaque encrypted blobs** — it never interprets payload content.

#### 5.1 Push Sync Message

```
POST /api/v1/sync/push
```

Store an encrypted sync message for all other active members of the group.

**Request:**

```json
{
  "groupId": "string UUID (required)",
  "payload": "string, Base64-encoded encrypted blob (required)",
  "vectorClock": { "device-1": 5, "device-2": 3 },
  "operationCount": 10,
  "chunkIndex": 0,
  "totalChunks": 1,
  "syncId": "string (optional, for multi-chunk dedup)"
}
```

**Response 200:**

```json
{
  "recipientCount": 2
}
```

**Error Responses:**

| Status | Condition |
|---|---|
| 400 | Missing `groupId` or `payload`, invalid `groupId` |
| 403 | Device is not an active member of the group |
| 413 | Request body exceeds 2 MB |

**Side Effects:**
- Push notification: `sync_available` (silent) to each recipient device

---

#### 5.2 Pull Sync Messages

```
GET /api/v1/sync/pull?since={messageId}
```

Retrieve pending sync messages for the authenticated device.

**Query Parameters:**

| Param | Description |
|---|---|
| `since` | (optional) Message ID — returns only messages created after this ID (for pagination) |

**Response 200:**

```json
{
  "messages": [
    {
      "messageId": "uuid-string",
      "fromDeviceId": "sender-device-id",
      "payload": "Base64-encoded encrypted blob",
      "vectorClock": { "device-1": 5, "device-2": 3 },
      "operationCount": 10,
      "chunkIndex": 0,
      "totalChunks": 1,
      "createdAt": "2026-04-05T12:00:00Z"
    }
  ],
  "hasMore": false
}
```

- `messages` is always an array (empty `[]` if none pending)
- `hasMore: true` when there are 100+ messages — client should pull again with `since` set to the last `messageId`

---

#### 5.3 Acknowledge Sync Messages

```
POST /api/v1/sync/ack
```

Acknowledge (and physically delete) received sync messages.

**Request:**

```json
{
  "messageIds": ["uuid-1", "uuid-2"]
}
```

**Response 200:**

```json
{
  "deleted": 2
}
```

**Error Responses:**

| Status | Condition |
|---|---|
| 400 | Empty `messageIds` array |
| 413 | Request body exceeds 2 MB |

---

## WebSocket Protocol

Real-time group status events are delivered over WebSocket. The WebSocket connection supplements push notifications — both channels deliver the same event types.

### Connection & Auth

#### 1. Connect

```
GET /ws/group/{groupId}
```

Upgrade to WebSocket. No HTTP `Authorization` header is needed — authentication is performed in-band.

#### 2. Client sends Auth Message (within 5 seconds)

```json
{
  "deviceId": "string",
  "timestamp": 1712345678,
  "signature": "Base64 Ed25519 signature",
  "protocolVersion": 1
}
```

**Signed Message:**

```
ws:connect:<groupId>:<deviceId>:<timestamp>
```

Timestamp tolerance: **±30 seconds**.

#### 3a. Auth Success

```json
{
  "type": "auth_success",
  "groupId": "550e8400-..."
}
```

Immediately followed by a `group_status` snapshot:

```json
{
  "type": "group_status",
  "groupId": "550e8400-...",
  "timestamp": "2026-04-05T12:00:00Z",
  "data": {
    "groupId": "550e8400-...",
    "status": "active",
    "groupName": "My Family",
    "inviteCode": "A1B2C3",
    "inviteExpiresAt": 1712345678,
    "members": [ ... ]
  }
}
```

`data` is the full `GroupStatusResponse` object (same as `GET /group/{groupId}/status`).

#### 3b. Auth Failure

```json
{
  "type": "auth_error",
  "message": "invalid signature"
}
```

Followed by WebSocket close frame with code `4001`.

**Possible auth error messages:**
- `"invalid auth message format"`
- `"timestamp out of range"`
- `"unknown device"`
- `"invalid signature"`

### Connection Management

- **Max message size:** 4096 bytes
- **Duplicate device:** If the same `deviceId` connects again to the same group, the previous connection is kicked
- **Group dissolve:** All connections in the group are closed after `group_dissolved` broadcast

### Server → Client Events

All events have this structure:

```json
{
  "type": "<event_type>",
  "groupId": "uuid",
  "deviceId": "string (optional, the device that caused the event)",
  "timestamp": "2026-04-05T12:00:00Z",
  "data": null
}
```

#### Event Types

| Type | `deviceId` | Trigger | Description |
|---|---|---|---|
| `group_status` | omitted | On auth success | Full group status snapshot (see above) |
| `join_request` | joiner's deviceId | `POST /group/{groupId}/confirm-join` (confirmed) | A new member submitted a join request (status: pending) |
| `member_confirmed` | confirmed member's deviceId | `POST /group/confirm` | Owner confirmed a pending member (status: active) |
| `member_left` | leaving/removed member's deviceId | `POST /group/{groupId}/leave` or `POST /group/{groupId}/remove` | A member left or was removed |
| `group_dissolved` | omitted | `DELETE /group/{groupId}` | Owner dissolved the group. All WS connections close after this event |

### Client → Server Messages

#### Ping

```json
{
  "type": "ping"
}
```

Server responds:

```json
{
  "type": "pong"
}
```

### Heartbeat

The server sends WebSocket-level **ping frames** every **30 seconds**. The client must respond with pong frames (handled automatically by most WebSocket libraries). If no pong is received within **45 seconds**, the server closes the connection.

The application-level `ping`/`pong` messages (JSON) are optional and can be used for latency measurement or keep-alive on frameworks that don't expose WebSocket-level ping/pong.

### Timing Constants

| Constant | Value |
|---|---|
| Auth timeout | 5 seconds |
| Write timeout | 10 seconds |
| Pong wait | 45 seconds |
| Ping interval | 30 seconds |
| Send buffer | 256 messages |

---

## Push Notifications

Push notifications are sent asynchronously and are best-effort. They complement WebSocket events.

### Notification Types

| Type | Silent | Recipient | Trigger |
|---|---|---|---|
| `join_request` | No | Group owner | New member confirmed join |
| `member_confirmed` | Yes | Newly confirmed member | Owner confirmed member |
| `sync_available` | Yes | Target devices | Sync message pushed / Member confirmed |
| `member_left` | Yes | All remaining active members | Member left or was removed |
| `group_dissolved` | Yes | All active non-owner members | Owner dissolved group |
| `group_name_updated` | Yes | All non-owner members | Owner renamed the group |

### Push Payload Fields

All push notifications include `extraData`:

**`join_request`:**
```json
{
  "groupId": "...",
  "deviceId": "joiner-device-id",
  "deviceName": "joiner device name",
  "displayName": "Mama",
  "avatarEmoji": "🌸",
  "avatarImageHash": "sha256hex..."
}
```

**`member_confirmed`:**
```json
{
  "groupId": "...",
  "displayName": "Papa",
  "avatarEmoji": "🏠",
  "avatarImageHash": "sha256hex..."
}
```

**`sync_available`:**
```json
{
  "groupId": "..."
}
```

**`member_left`:**
```json
{
  "groupId": "...",
  "deviceId": "left-device-id",
  "deviceName": "device name",
  "reason": "left | removed"
}
```

**`group_dissolved`:**
```json
{
  "groupId": "..."
}
```

**`group_name_updated`:**
```json
{
  "groupId": "...",
  "groupName": "New Group Name"
}
```

---

## Group State Machine

```
(none) --[create]--> active
(none) --[join + confirm-join]--> pending member in active group
pending --[confirm]--> active member
active --[leave/remove]--> removed
active --[deactivate]--> inactive (entire group)
```

### Member Roles

| Role | Permissions |
|---|---|
| `owner` | Create, confirm, remove members, rename, deactivate, regenerate invite |
| `member` | Sync push/pull/ack, leave, view status |

### Member Statuses

| Status | Description |
|---|---|
| `pending` | Join confirmed by joiner, awaiting owner approval |
| `active` | Fully confirmed, can sync |
| `removed` | Left or was removed from the group |
