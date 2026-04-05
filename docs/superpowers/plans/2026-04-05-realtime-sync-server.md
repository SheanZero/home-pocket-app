# Realtime Sync — Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `sync_available` WebSocket broadcast to `POST /sync/push` so Device B receives instant notification to pull when Device A pushes data.

**Architecture:** Inject `*ws.Hub` into `SyncHandler` (currently only `GroupHandler` has it). After `StoreSyncMessage` succeeds, broadcast `sync_available` event to all group clients. Hub broadcasts to ALL clients including sender — client ignores events from its own deviceId via SyncEngine deduplication.

**Tech Stack:** Go, chi router, gorilla/websocket, existing Hub pattern

**Server codebase:** `/Users/xinz/Development/home-pocket-server`

---

## Current State

**`SyncHandler` struct** (`internal/handler/sync_handler.go:18-22`):
```go
type SyncHandler struct {
    syncService *service.SyncService
    pushService *service.PushService
    logger      *slog.Logger
}
```
No `hub` field — only `GroupHandler` has it.

**Push handler** (`sync_handler.go:28-72`):
After `StoreSyncMessage()`, iterates `targetDeviceIDs` and sends push notifications. No WebSocket broadcast.

**Broadcast pattern** (from `group_handler.go:209-217`):
```go
if h.hub != nil {
    h.hub.Broadcast(req.GroupID, ws.EventMessage{
        Type:      "member_confirmed",
        GroupID:   req.GroupID,
        DeviceID:  req.DeviceID,
        Timestamp: time.Now(),
    })
}
```

**Hub has no sender exclusion** — broadcasts to ALL clients in group. Client-side deduplication handles self-events.

---

## Task 1: Add Hub to SyncHandler and broadcast sync_available

**Files:**
- Modify: `internal/handler/sync_handler.go`
- Modify: `internal/handler/routes.go`

- [ ] **Step 1: Add `hub` field to SyncHandler**

```go
// internal/handler/sync_handler.go

import (
    // ... existing imports ...
    "time"
    "github.com/homepocket/relay/internal/ws"
)

type SyncHandler struct {
    syncService *service.SyncService
    pushService *service.PushService
    hub         *ws.Hub
    logger      *slog.Logger
}

func NewSyncHandler(syncService *service.SyncService, pushService *service.PushService, hub *ws.Hub, logger *slog.Logger) *SyncHandler {
    return &SyncHandler{syncService: syncService, pushService: pushService, hub: hub, logger: logger}
}
```

- [ ] **Step 2: Add WebSocket broadcast after push notifications in Push()**

In `Push()`, after the push notification loop (line 67-69), add:

```go
    for _, targetID := range targetDeviceIDs {
        go h.pushService.NotifySyncAvailable(context.Background(), targetID, req.GroupID)
    }

    // Broadcast sync_available via WebSocket to all group clients
    if h.hub != nil {
        h.hub.Broadcast(req.GroupID, ws.EventMessage{
            Type:      "sync_available",
            GroupID:   req.GroupID,
            DeviceID:  deviceID,
            Timestamp: time.Now(),
        })
    }

    respondJSON(w, http.StatusOK, model.PushSyncResponse{RecipientCount: len(targetDeviceIDs)})
```

- [ ] **Step 3: Update routes.go to pass hub to SyncHandler**

In `NewHandlers()` (routes.go:25-41), change:

```go
// Before:
Sync: NewSyncHandler(syncService, pushService, logger),

// After:
Sync: NewSyncHandler(syncService, pushService, hub, logger),
```

- [ ] **Step 4: Run tests**

```bash
cd /Users/xinz/Development/home-pocket-server
go build ./...
go test ./internal/handler/ -v
```

- [ ] **Step 5: Commit**

```bash
git add internal/handler/sync_handler.go internal/handler/routes.go
git commit -m "feat: broadcast sync_available via WebSocket on sync push"
```

---

## Task 2: Update API Protocol documentation

**File:** `/Users/xinz/Development/home-pocket-app/docs/server/API_PROTOCOL.md`

- [ ] **Step 1: Add sync_available to WebSocket Event Types table (line 964)**

```markdown
| `sync_available` | pusher's deviceId | `POST /api/v1/sync/push` | New sync data available for pull |
```

- [ ] **Step 2: Add WebSocket broadcast to sync push Side Effects (line 787)**

```markdown
**Side Effects:**
- Push notification: `sync_available` (silent) to each recipient device
- WebSocket broadcast: `sync_available` event to all group clients
```

- [ ] **Step 3: Commit**

```bash
git commit -m "docs: add sync_available WebSocket event to API protocol"
```

---

## Verification

1. `go build ./...` — compiles
2. `go test ./...` — all pass
3. Manual test:
   - Connect two devices to same group via WebSocket
   - Device A calls `POST /sync/push`
   - Device B receives `{"type":"sync_available","groupId":"...","deviceId":"device-a","timestamp":"..."}`
   - Push notification `sync_available` still fires (unchanged)
