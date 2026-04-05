# Server: Remove `since` Parameter from Sync Pull

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Simplify sync pull — server returns all un-ACK'd messages for the device, no cursor needed.

**Architecture:** ACK physically deletes messages from DB, so every pull returns only unprocessed messages. The `since` timestamp cursor is redundant and error-prone (same-second messages can be skipped). Remove it from handler → service → repository.

**Tech Stack:** Go, PostgreSQL, chi router

**Server codebase:** `/Users/xinz/Development/home-pocket-server`

---

## Task 1: Remove `since` from repository layer

**File:** `internal/repository/sync_repo.go:57-67`

```go
// BEFORE:
func (r *SyncRepo) FindPendingByDevice(ctx context.Context, deviceID string, since time.Time) ([]model.SyncMessage, error) {
    rows, err := r.db.QueryContext(ctx,
        `SELECT message_id, group_id, from_device_id, to_device_id,
                payload, vector_clock, operation_count, chunk_index, total_chunks,
                created_at, expires_at
         FROM sync_messages
         WHERE to_device_id = $1 AND created_at > $2
         ORDER BY created_at ASC
         LIMIT 100`,
        deviceID, since,
    )

// AFTER:
func (r *SyncRepo) FindPendingByDevice(ctx context.Context, deviceID string) ([]model.SyncMessage, error) {
    rows, err := r.db.QueryContext(ctx,
        `SELECT message_id, group_id, from_device_id, to_device_id,
                payload, vector_clock, operation_count, chunk_index, total_chunks,
                created_at, expires_at
         FROM sync_messages
         WHERE to_device_id = $1
         ORDER BY created_at ASC
         LIMIT 100`,
        deviceID,
    )
```

---

## Task 2: Remove `since` from service layer

**File:** `internal/service/sync_service.go:116-125`

```go
// BEFORE:
func (s *SyncService) GetPendingMessages(ctx context.Context, deviceID string, sinceStr string) ([]model.SyncMessage, error) {
    var since time.Time
    if sinceStr != "" {
        parsed, err := time.Parse(time.RFC3339, sinceStr)
        if err == nil {
            since = parsed
        }
    }
    return s.syncRepo.FindPendingByDevice(ctx, deviceID, since)
}

// AFTER:
func (s *SyncService) GetPendingMessages(ctx context.Context, deviceID string) ([]model.SyncMessage, error) {
    return s.syncRepo.FindPendingByDevice(ctx, deviceID)
}
```

---

## Task 3: Remove `since` from handler layer

**File:** `internal/handler/sync_handler.go:87-92`

```go
// BEFORE:
func (h *SyncHandler) Pull(w http.ResponseWriter, r *http.Request) {
    deviceID := auth.GetDeviceID(r.Context())
    sinceStr := r.URL.Query().Get("since")
    messages, err := h.syncService.GetPendingMessages(r.Context(), deviceID, sinceStr)

// AFTER:
func (h *SyncHandler) Pull(w http.ResponseWriter, r *http.Request) {
    deviceID := auth.GetDeviceID(r.Context())
    messages, err := h.syncService.GetPendingMessages(r.Context(), deviceID)
```

---

## Task 4: Update tests

**File:** `internal/service/sync_service_test.go`
- Remove `sinceStr` parameter from `GetPendingMessages` calls
- Remove "with valid since param" test case (no longer applicable)

**File:** `internal/repository/sync_repo_test.go`
- Remove `since time.Time` parameter from `FindPendingByDevice` calls
- Update SQL expectation to not include `created_at >` condition

---

## Task 5: Update API Protocol documentation

**File:** `/Users/xinz/Development/home-pocket-app/docs/server/API_PROTOCOL.md`

Update section 5.2 (around line 793):

```markdown
## BEFORE:
GET /api/v1/sync/pull?since={messageId}
| `since` | (optional) Message ID — returns only messages created after this ID |

## AFTER:
GET /api/v1/sync/pull
(No query parameters — returns all pending un-ACK'd messages for the device)
```

---

## Verification

```bash
cd /Users/xinz/Development/home-pocket-server
go build ./...
go vet ./...
go test ./internal/... -v
```

**Backward compatibility:** Client already deployed without `since` parameter. Old clients sending `?since=...` will have the parameter silently ignored by the server (query param not read). No breaking change.
