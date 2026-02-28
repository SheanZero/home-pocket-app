# MOD-003 Family Sync - Server Implementation Plan (Go Relay)

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a zero-knowledge Go relay server that mediates device pairing and encrypted sync message delivery for the Home Pocket family sync feature.

**Scope:** Server-side only. This is a standalone Go project, deployed independently. Client implementation is in `2026-02-28-mod003-family-sync-client.md`.

**Repository:** Separate repository (e.g., `github.com/homepocket/relay`)

**Tech Stack:** Go 1.22+, PostgreSQL 16, chi router, APNs/FCM push

**Design Docs:**
- Server Architecture: `SERVER-001_SyncRelay.md`
- Relay Design: `2026-02-28-mod003-family-sync-server-relay-design.md`
- Client Spec (for API contract): `MOD-003_FamilySync.md` (v3.0)

**Core Principles:**
1. **Zero-knowledge:** Server stores only encrypted blobs it cannot read
2. **Ephemeral storage:** Sync data physically deleted after client ACK
3. **Device key auth:** Ed25519 signature on every request, no user accounts
4. **Blind relay:** No conflict resolution, no data parsing, no business logic

---

## Milestone Overview

The server plan is divided into 4 independently verifiable milestones:

| Milestone | Phases | Verification | Est. Time |
|-----------|--------|-------------|-----------|
| M1: Foundation | S1-S2 (project + DB + models + repos) | `go build` + `go test ./internal/repository/...` | 1.5 days |
| M2: Business Logic | S3-S4 (services + auth) | `go test ./internal/service/...` + `go test ./internal/auth/...` | 1.5 days |
| M3: API Layer | S5-S6 (handlers + middleware) | `go test ./internal/handler/...` + manual curl test | 1 day |
| M4: Deployment & Integration | S7-S8 (wiring + Docker + integration tests) | `docker-compose up` + `go test ./... -v` coverage >=80% | 1 day |

---

## Milestone 1: Foundation

### Phase S1: Project Setup + Database

#### Task 1: Initialize Go project

**Files:**
- Create: `go.mod`
- Create: `cmd/relay/main.go`
- Create: `internal/config/config.go`

**Step 1: Create project structure**

```bash
mkdir -p cmd/relay internal/{config,auth,handler,service,repository,model,middleware,scheduler}
mkdir -p migrations deploy
```

**Step 2: Initialize Go module**

```bash
go mod init github.com/homepocket/relay
```

**Step 3: Write config.go**

```go
// internal/config/config.go
package config

import (
	"fmt"
	"os"
	"strconv"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	APNs     APNsConfig
	FCM      FCMConfig
}

type ServerConfig struct {
	Port     int
	LogLevel string
}

type DatabaseConfig struct {
	URL             string
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime int
}

type APNsConfig struct {
	KeyPath  string
	KeyID    string
	TeamID   string
	BundleID string
	Sandbox  bool
}

type FCMConfig struct {
	CredentialsPath string
}

func Load() (*Config, error) {
	port, _ := strconv.Atoi(getEnv("SERVER_PORT", "8080"))
	maxOpen, _ := strconv.Atoi(getEnv("DB_MAX_OPEN_CONNS", "25"))
	maxIdle, _ := strconv.Atoi(getEnv("DB_MAX_IDLE_CONNS", "5"))
	connMaxLife, _ := strconv.Atoi(getEnv("DB_CONN_MAX_LIFETIME", "300"))
	sandbox, _ := strconv.ParseBool(getEnv("APNS_SANDBOX", "true"))

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		return nil, fmt.Errorf("DATABASE_URL is required")
	}

	return &Config{
		Server: ServerConfig{
			Port:     port,
			LogLevel: getEnv("LOG_LEVEL", "info"),
		},
		Database: DatabaseConfig{
			URL:             dbURL,
			MaxOpenConns:    maxOpen,
			MaxIdleConns:    maxIdle,
			ConnMaxLifetime: connMaxLife,
		},
		APNs: APNsConfig{
			KeyPath:  os.Getenv("APNS_KEY_PATH"),
			KeyID:    os.Getenv("APNS_KEY_ID"),
			TeamID:   os.Getenv("APNS_TEAM_ID"),
			BundleID: getEnv("APNS_BUNDLE_ID", "com.homepocket.app"),
			Sandbox:  sandbox,
		},
		FCM: FCMConfig{
			CredentialsPath: os.Getenv("FCM_CREDENTIALS_PATH"),
		},
	}, nil
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
```

**Step 4: Write main.go (skeleton)**

```go
// cmd/relay/main.go
package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/homepocket/relay/internal/config"
)

var Version = "dev"

func main() {
	cfg, err := config.Load()
	if err != nil {
		slog.Error("failed to load config", "error", err)
		os.Exit(1)
	}

	logger := setupLogger(cfg.Server.LogLevel)
	logger.Info("starting relay server", "version", Version, "port", cfg.Server.Port)

	// TODO: Initialize database, services, handlers, router

	srv := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Server.Port),
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Error("server failed", "error", err)
			os.Exit(1)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("shutting down server")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	srv.Shutdown(ctx)
}

func setupLogger(level string) *slog.Logger {
	var lvl slog.Level
	switch level {
	case "debug":
		lvl = slog.LevelDebug
	case "warn":
		lvl = slog.LevelWarn
	case "error":
		lvl = slog.LevelError
	default:
		lvl = slog.LevelInfo
	}
	return slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: lvl}))
}
```

**Step 5: Add dependencies**

```bash
go get github.com/go-chi/chi/v5 github.com/google/uuid github.com/lib/pq
```

**Step 6: Verify build**

Run: `go build ./cmd/relay`
Expected: Builds without errors

**Step 7: Commit**

```bash
git add .
git commit -m "feat(server): initialize Go relay server project"
```

---

#### Task 2: Database migrations

**Files:**
- Create: `migrations/001_create_devices.sql`
- Create: `migrations/002_create_pairs.sql`
- Create: `migrations/003_create_sync_messages.sql`

**Step 1: Write migration files**

```sql
-- migrations/001_create_devices.sql
CREATE TABLE IF NOT EXISTS devices (
    device_id       TEXT PRIMARY KEY,
    public_key      TEXT NOT NULL,
    device_name     TEXT NOT NULL,
    platform        TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
    push_token      TEXT,
    push_platform   TEXT CHECK (push_platform IN ('apns', 'fcm')),
    registered_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON devices(last_seen_at);
```

```sql
-- migrations/002_create_pairs.sql
CREATE TABLE IF NOT EXISTS pairs (
    pair_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id         TEXT NOT NULL,
    device_a_id     TEXT NOT NULL REFERENCES devices(device_id),
    device_b_id     TEXT REFERENCES devices(device_id),
    device_a_public_key  TEXT NOT NULL,
    device_a_name        TEXT NOT NULL,
    device_b_public_key  TEXT,
    device_b_name        TEXT,
    pair_code       TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'confirming', 'active', 'inactive')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL,
    confirmed_at    TIMESTAMPTZ,
    deactivated_at  TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_pairs_pair_code ON pairs(pair_code) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_pairs_device_a ON pairs(device_a_id) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_pairs_device_b ON pairs(device_b_id) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_pairs_status_expires ON pairs(status, expires_at) WHERE status = 'pending';
```

```sql
-- migrations/003_create_sync_messages.sql
CREATE TABLE IF NOT EXISTS sync_messages (
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

CREATE INDEX IF NOT EXISTS idx_sync_messages_to_device ON sync_messages(to_device_id, created_at);
CREATE INDEX IF NOT EXISTS idx_sync_messages_expires ON sync_messages(expires_at);
CREATE INDEX IF NOT EXISTS idx_sync_messages_pair ON sync_messages(pair_id);
```

**Step 2: Commit**

```bash
git add migrations/
git commit -m "feat(server): add PostgreSQL migrations for devices, pairs, sync_messages"
```

---

### Phase S2: Domain Models + Repository Layer

#### Task 3: Go models and API types

**Files:**
- Create: `internal/model/device.go`
- Create: `internal/model/pair.go`
- Create: `internal/model/sync_message.go`
- Create: `internal/model/api.go`
- Create: `internal/model/errors.go`

**Step 1: Write all model files**

See SERVER-001_SyncRelay.md Section "Go模型" and "API Request/Response 模型" for exact definitions. Each file contains the struct definitions with JSON tags and `db` tags for database mapping.

Key error types:
```go
// internal/model/errors.go
package model

import "errors"

var (
	ErrDeviceNotFound     = errors.New("device not found")
	ErrPairNotFound       = errors.New("pair not found or expired")
	ErrPairAlreadyUsed    = errors.New("pair code already used")
	ErrPairNotActive      = errors.New("pair is not active")
	ErrPublicKeyMismatch  = errors.New("public key mismatch for existing device")
	ErrUnauthorized       = errors.New("unauthorized")
	ErrForbidden          = errors.New("forbidden")
)
```

**Step 2: Verify build**

Run: `go build ./...`

**Step 3: Commit**

```bash
git add internal/model/
git commit -m "feat(server): add domain models and API types"
```

---

#### Task 4: Repository layer

**Files:**
- Create: `internal/repository/device_repo.go`
- Create: `internal/repository/pair_repo.go`
- Create: `internal/repository/sync_repo.go`
- Test: `internal/repository/device_repo_test.go`
- Test: `internal/repository/pair_repo_test.go`
- Test: `internal/repository/sync_repo_test.go`

**Step 1: Write failing tests for DeviceRepo**

Test: Create, FindByID, UpdatePushToken, UpdateLastSeen, DeleteInactive

**Step 2: Implement DeviceRepo**

See SERVER-001 for method signatures. Uses `database/sql` with parameterized queries.

**Step 3: Write failing tests for PairRepo**

Test: Create, FindByCode, FindByID, UpdateStatus, UpdateDeviceB, ExpirePendingPairs

**Step 4: Implement PairRepo**

PairCode generation: 6 random digits, `crypto/rand`. Note: `idx_pairs_pair_code` is a UNIQUE partial index on pending pairs. The PairRepo.Create method must handle duplicate key errors (return sentinel error for retry in service layer).

**Step 5: Write failing tests for SyncRepo**

Test: Create, FindPendingByDevice, DeleteByIDs, DeleteExpired

**Step 6: Implement SyncRepo**

Key: `DeleteByIDs` physically deletes rows. `FindPendingByDevice` filters by `to_device_id` and `created_at > since`.

**Step 7: Run all repo tests**

Run: `go test ./internal/repository/... -v`
Expected: All pass

**Step 8: Commit**

```bash
git add internal/repository/
git commit -m "feat(server): implement repository layer with tests"
```

---

### Milestone 1 Verification

```bash
# Build succeeds
go build ./cmd/relay

# All repository tests pass
go test ./internal/repository/... -v

# Migrations apply cleanly (requires local PostgreSQL)
psql $DATABASE_URL -f migrations/001_create_devices.sql
psql $DATABASE_URL -f migrations/002_create_pairs.sql
psql $DATABASE_URL -f migrations/003_create_sync_messages.sql
```

---

## Milestone 2: Business Logic

### Phase S3: Service Layer

#### Task 5: Service layer

**Files:**
- Create: `internal/service/device_service.go`
- Create: `internal/service/pair_service.go`
- Create: `internal/service/sync_service.go`
- Create: `internal/service/push_service.go`
- Test: `internal/service/pair_service_test.go`
- Test: `internal/service/sync_service_test.go`

**Step 1: Write failing tests for PairService**

Test: CreatePair generates 6-digit code, JoinPair matches code, ConfirmPair updates status, expired codes rejected.

**Step 2: Implement PairService**

Key methods: `CreatePair`, `JoinPair`, `ConfirmPair`, `DeletePair`. PairCode = 6 random digits with 10-minute expiry. IMPORTANT: Pair code generation MUST include a retry loop (max 5 attempts) to handle the UNIQUE constraint on `pair_code WHERE status = 'pending'`. On duplicate key error, regenerate and retry.

**Step 3: Write failing tests for SyncService**

Test: ValidateDevicePair, StoreSyncMessage, GetPendingMessages, AckMessages (verify physical DELETE).

**Step 4: Implement SyncService**

Key: `AckMessages` calls `syncRepo.DeleteByIDs` for physical deletion.

**Step 5: Implement DeviceService**

DeviceService.Register: MUST enforce public key immutability. If `deviceId` already exists and `publicKey` differs -> return `ErrPublicKeyMismatch` (409 Conflict). Same `deviceId` + same `publicKey` -> idempotent update of `deviceName`/`platform` (200 OK). New `deviceId` -> create (201 Created). This prevents an attacker who knows a `deviceId` from replacing the public key and hijacking subsequent authenticated requests.

**Step 6: Implement PushService**

Three push event types, all silent push with no sensitive data:
- `NotifySyncAvailable(deviceID)` -> `type: "sync_available"` -- silent push (content-available: 1)
- `NotifyPairConfirmed(deviceID)` -> `type: "pair_confirmed"` -- silent push to Device B after A confirms. Without this method, Device B has no signal to transition from confirming -> active.
- `NotifyPairRequest(deviceID, joinerName)` -> `type: "pair_request"` -- visible notification to Device A when B joins

**Step 7: Run all service tests**

Run: `go test ./internal/service/... -v`

**Step 8: Commit**

```bash
git add internal/service/
git commit -m "feat(server): implement service layer with pair/sync logic"
```

---

### Phase S4: Auth Middleware

#### Task 6: Auth middleware and request signing

**Files:**
- Create: `internal/auth/ed25519_verifier.go`
- Create: `internal/auth/middleware.go`
- Test: `internal/auth/middleware_test.go`

**Step 1: Write failing test**

Test: valid signature passes, expired timestamp rejects, invalid signature rejects, missing header rejects.

**Step 2: Implement Ed25519 verification**

```
// Parses: "Ed25519 <deviceId>:<timestamp>:<signature>"
// Reconstructs message: "<method>:<path>:<timestamp>:<SHA256(body)>"
// Verifies with ed25519.Verify(publicKey, message, signature)
// Rejects if |timestamp - now| > 300 seconds
```

**Step 3: Run auth tests**

Run: `go test ./internal/auth/... -v`

**Step 4: Commit**

```bash
git add internal/auth/
git commit -m "feat(server): implement Ed25519 auth middleware"
```

---

### Milestone 2 Verification

```bash
# All service tests pass
go test ./internal/service/... -v

# All auth tests pass
go test ./internal/auth/... -v

# Combined check
go test ./internal/... -v
go vet ./...
```

---

## Milestone 3: API Layer

### Phase S5: HTTP Handlers + Routing

#### Task 7: HTTP handlers and routing

**Files:**
- Create: `internal/handler/helpers.go`
- Create: `internal/handler/health_handler.go`
- Create: `internal/handler/device_handler.go`
- Create: `internal/handler/pair_handler.go`
- Create: `internal/handler/sync_handler.go`
- Create: `internal/handler/routes.go`
- Test: `internal/handler/pair_handler_test.go`
- Test: `internal/handler/sync_handler_test.go`

**Step 1: Write helpers (respondJSON, respondError)**

**Step 2: Implement handlers**

See SERVER-001 for all handler implementations. Key patterns:
- Extract `deviceID` from `r.Context().Value(authDeviceIDKey)`
- Decode JSON body with `json.NewDecoder(r.Body).Decode(&req)`
- Call service methods
- Respond with appropriate status codes

**Step 3: Wire up routes**

```go
// internal/handler/routes.go
func SetupRoutes(r chi.Router, h *Handlers, authMW func(http.Handler) http.Handler) {
    r.Route("/api/v1", func(r chi.Router) {
        r.Get("/health", h.Health.Check)
        r.Post("/device/register", h.Device.Register)

        r.Group(func(r chi.Router) {
            r.Use(authMW)
            r.Put("/device/push-token", h.Device.UpdatePushToken)
            r.Post("/pair/create", h.Pair.Create)
            r.Post("/pair/join", h.Pair.Join)
            r.Post("/pair/confirm", h.Pair.Confirm)
            r.Get("/pair/status/{pairId}", h.Pair.Status)
            r.Delete("/pair/{pairId}", h.Pair.Delete)
            r.Post("/sync/push", h.Sync.Push)
            r.Get("/sync/pull", h.Sync.Pull)
            r.Post("/sync/ack", h.Sync.Ack)
        })
    })
}
```

**Step 4: Write handler integration tests**

Test full push-pull-ack cycle with test HTTP server.

**Step 5: Run all handler tests**

Run: `go test ./internal/handler/... -v`

**Step 6: Commit**

```bash
git add internal/handler/
git commit -m "feat(server): implement HTTP handlers and routing"
```

---

### Phase S6: Cross-Cutting Middleware

#### Task 8: Rate limiting, logging, scheduler

**Files:**
- Create: `internal/middleware/ratelimit.go`
- Create: `internal/middleware/logging.go`
- Create: `internal/middleware/cors.go`
- Create: `internal/scheduler/cleanup.go`

**Step 1: Implement rate limiter**

Rate limits per device: pair 10/min, sync/push 60/min, sync/pull 30/min, device 5/min. Uses `golang.org/x/time/rate`.

**Step 2: Implement request logging middleware**

Structured JSON logs via `slog`. Log: method, path, status, duration, deviceId. NEVER log: payload, publicKey, signature.

**Step 3: Implement CORS middleware**

Allow requests from the client app domains.

**Step 4: Implement cleanup scheduler**

Three periodic jobs:
- Every 1 min: expire pending pair codes
- Every 1 hour: delete expired sync_messages
- Every 7 days: delete inactive devices (90+ days)

**Step 5: Commit**

```bash
git add internal/middleware/ internal/scheduler/
git commit -m "feat(server): add rate limiting, logging, cleanup scheduler"
```

---

### Milestone 3 Verification

```bash
# All handler tests pass
go test ./internal/handler/... -v

# Full test suite
go test ./... -v

# Manual API smoke test (requires running server + PostgreSQL)
curl http://localhost:8080/api/v1/health
# Expected: {"status":"ok"}
```

---

## Milestone 4: Deployment & Integration Testing

### Phase S7: Wiring + Deployment

#### Task 9: Wire everything in main.go and add deployment

**Files:**
- Modify: `cmd/relay/main.go`
- Create: `deploy/Dockerfile`
- Create: `deploy/docker-compose.yml`

**Step 1: Complete main.go**

Wire up: database connection, run migrations, create repos, create services, create handlers, setup routes with middleware, start scheduler.

**Step 2: Write Dockerfile**

Multi-stage build: golang:1.22-alpine -> alpine:3.19. Binary at `/usr/local/bin/relay`.

**Step 3: Write docker-compose.yml**

Services: relay + postgres:16-alpine with health check.

```yaml
version: "3.9"
services:
  relay:
    build:
      context: ..
      dockerfile: deploy/Dockerfile
    ports:
      - "8080:8080"
    environment:
      DATABASE_URL: postgres://relay:relay@db:5432/relay?sslmode=disable
      LOG_LEVEL: debug
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: relay
      POSTGRES_PASSWORD: relay
      POSTGRES_DB: relay
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U relay"]
      interval: 5s
      timeout: 5s
      retries: 5
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

**Step 4: Test full server startup**

Run: `cd deploy && docker-compose up --build`
Expected: Server starts, health check returns 200

**Step 5: Commit**

```bash
git add cmd/ deploy/
git commit -m "feat(server): complete server wiring and Docker deployment"
```

---

### Phase S8: Integration Tests

#### Task 10: Server integration tests

**Files:**
- Create: `internal/handler/integration_test.go`

**Step 1: Write full pairing flow test**

Test: register devices -> create pair -> join pair -> confirm pair -> verify both have partner keys.

**Step 2: Write full sync flow test**

Test: push encrypted blob -> pull returns blob -> ack deletes blob -> second pull returns empty.

**Step 3: Write auth tests**

Test: request without auth header -> 401. Request with expired timestamp -> 401. Request with invalid signature -> 401.

**Step 4: Write device registration security test**

Test: register device A -> re-register with different publicKey -> 409 Conflict (ErrPublicKeyMismatch). Re-register with same publicKey -> 200 OK (idempotent).

**Step 5: Run all server tests**

Run: `go test ./... -v -count=1`
Expected: All pass, coverage >=80%

**Step 6: Check coverage**

Run: `go test ./... -cover`
Expected: >=80% overall coverage

**Step 7: Commit**

```bash
git add internal/handler/
git commit -m "test(server): add integration tests for pairing and sync flows"
```

---

### Milestone 4 Verification

```bash
# Docker build and startup
cd deploy && docker-compose up --build -d
curl http://localhost:8080/api/v1/health
# Expected: {"status":"ok"}

# Full test suite with coverage
go test ./... -v -cover
# Expected: All pass, coverage >= 80%

# Cleanup
cd deploy && docker-compose down -v
```

---

## Full API Reference

### POST /api/v1/device/register (No Auth)

```json
// Request
{
  "deviceId": "dev-uuid",
  "publicKey": "base64-ed25519-pubkey",
  "deviceName": "iPhone 15",
  "platform": "ios"
}
// Response 201 (new) / 200 (idempotent update)
{"status": "ok"}
// Response 409 (public key mismatch)
{"error": "public key mismatch for existing device"}
```

### POST /api/v1/pair/create (Auth Required)

```json
// Request
{
  "bookId": "book-uuid",
  "deviceName": "iPhone 15",
  "publicKey": "base64-ed25519-pubkey"
}
// Response 201
{
  "pairId": "uuid",
  "pairCode": "123456",
  "expiresAt": "2026-02-28T12:10:00Z"
}
```

### POST /api/v1/pair/join (Auth Required)

```json
// Request
{
  "pairCode": "123456",
  "deviceName": "Galaxy S24",
  "publicKey": "base64-ed25519-pubkey"
}
// Response 200
{
  "pairId": "uuid",
  "partnerPublicKey": "base64-device-a-pubkey",
  "partnerDeviceName": "iPhone 15",
  "bookId": "book-uuid"
}
```

### POST /api/v1/pair/confirm (Auth Required)

```json
// Request
{"pairId": "uuid"}
// Response 200
{
  "status": "active",
  "partnerPublicKey": "base64-device-b-pubkey",
  "partnerDeviceName": "Galaxy S24"
}
```

### POST /api/v1/sync/push (Auth Required)

```json
// Request
{
  "pairId": "uuid",
  "payload": "base64-encrypted-blob",
  "vectorClock": {"dev-A": 42, "dev-B": 38},
  "operationCount": 3,
  "chunkIndex": 0,
  "totalChunks": 1
}
// Response 201
{"messageId": "uuid"}
```

### GET /api/v1/sync/pull?since=2026-02-28T12:00:00Z (Auth Required)

```json
// Response 200
{
  "messages": [
    {
      "messageId": "uuid",
      "fromDeviceId": "dev-A",
      "payload": "base64-encrypted-blob",
      "vectorClock": {"dev-A": 42},
      "operationCount": 3,
      "chunkIndex": 0,
      "totalChunks": 1,
      "createdAt": "2026-02-28T12:01:00Z"
    }
  ]
}
```

### POST /api/v1/sync/ack (Auth Required)

```json
// Request
{"messageIds": ["uuid1", "uuid2"]}
// Response 200
{"deleted": 2}
```

---

## Project Structure

```
homepocket-relay/
├── cmd/relay/main.go             # Entry point
├── internal/
│   ├── config/config.go          # Environment configuration
│   ├── model/                    # Domain models + API types + errors
│   │   ├── device.go
│   │   ├── pair.go
│   │   ├── sync_message.go
│   │   ├── api.go
│   │   └── errors.go
│   ├── repository/               # Data access (PostgreSQL)
│   │   ├── device_repo.go
│   │   ├── pair_repo.go
│   │   └── sync_repo.go
│   ├── service/                  # Business logic
│   │   ├── device_service.go
│   │   ├── pair_service.go
│   │   ├── sync_service.go
│   │   └── push_service.go
│   ├── auth/                     # Ed25519 auth middleware
│   │   ├── ed25519_verifier.go
│   │   └── middleware.go
│   ├── handler/                  # HTTP handlers + routes
│   │   ├── helpers.go
│   │   ├── health_handler.go
│   │   ├── device_handler.go
│   │   ├── pair_handler.go
│   │   ├── sync_handler.go
│   │   └── routes.go
│   ├── middleware/                # Rate limiting, logging, CORS
│   │   ├── ratelimit.go
│   │   ├── logging.go
│   │   └── cors.go
│   └── scheduler/                # Cleanup jobs
│       └── cleanup.go
├── migrations/                   # PostgreSQL migrations
│   ├── 001_create_devices.sql
│   ├── 002_create_pairs.sql
│   └── 003_create_sync_messages.sql
├── deploy/
│   ├── Dockerfile
│   └── docker-compose.yml
├── go.mod
└── go.sum
```

---

## Estimated Effort

| Milestone | Tasks | Estimated Time |
|-----------|-------|---------------|
| M1: Foundation (project + DB + models + repos) | T1-T4 | 1.5 days |
| M2: Business Logic (services + auth) | T5-T6 | 1.5 days |
| M3: API Layer (handlers + middleware) | T7-T8 | 1 day |
| M4: Deployment & Integration | T9-T10 | 1 day |
| **Total** | **10 tasks** | **~5 days** |

---

## Security Checklist

- [ ] No sensitive data logged (amounts, notes, merchant names)
- [ ] Ed25519 signature verified on all authenticated endpoints
- [ ] Timestamp window enforced (5 min max)
- [ ] Public key immutability enforced on device registration
- [ ] Rate limiting applied per device per endpoint
- [ ] Parameterized SQL queries only (no string concatenation)
- [ ] Pair codes expire after 10 minutes
- [ ] Sync messages physically deleted after ACK
- [ ] Inactive devices cleaned up after 90 days
- [ ] Push notifications contain no sensitive data
- [ ] CORS configured for allowed origins only
