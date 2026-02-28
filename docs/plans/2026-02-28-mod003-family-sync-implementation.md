# MOD-003 Family Sync Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement server-mediated family sync with E2EE, enabling remote device pairing and encrypted transaction synchronization.

**Architecture:** Go relay server (zero-knowledge, ephemeral storage) + Flutter client (E2EE, CRDT, offline queue). Server is a blind relay - stores only encrypted blobs, deletes after client ACK. Authentication via Ed25519 device key signing.

**Tech Stack:**
- Server: Go 1.22+, PostgreSQL 16, chi router, APNs/FCM
- Client: Flutter/Dart, Drift, Riverpod, Freezed, NaCl box (X25519-XSalsa20-Poly1305)

**Design Docs:**
- Client: `docs/arch/02-module-specs/MOD-003_FamilySync.md` (v3.0)
- Server: `docs/arch/server/SERVER-001_SyncRelay.md`

---

## Phase 1: Go Server Foundation

### Task 1: Initialize Go project

**Files:**
- Create: `server/go.mod`
- Create: `server/cmd/relay/main.go`
- Create: `server/internal/config/config.go`

**Step 1: Create project structure**

```bash
mkdir -p server/cmd/relay server/internal/{config,auth,handler,service,repository,model,middleware,scheduler}
mkdir -p server/migrations server/deploy
```

**Step 2: Initialize Go module**

```bash
cd server && go mod init github.com/homepocket/relay
```

**Step 3: Write config.go**

```go
// server/internal/config/config.go
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
// server/cmd/relay/main.go
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
cd server && go get github.com/go-chi/chi/v5 github.com/google/uuid github.com/lib/pq
```

**Step 6: Verify build**

Run: `cd server && go build ./cmd/relay`
Expected: Builds without errors

**Step 7: Commit**

```bash
git add server/
git commit -m "feat(server): initialize Go relay server project"
```

---

### Task 2: Database migrations

**Files:**
- Create: `server/migrations/001_create_devices.sql`
- Create: `server/migrations/002_create_pairs.sql`
- Create: `server/migrations/003_create_sync_messages.sql`

**Step 1: Write migration files**

```sql
-- server/migrations/001_create_devices.sql
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
-- server/migrations/002_create_pairs.sql
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
-- server/migrations/003_create_sync_messages.sql
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
git add server/migrations/
git commit -m "feat(server): add PostgreSQL migrations for devices, pairs, sync_messages"
```

---

### Task 3: Go models and API types

**Files:**
- Create: `server/internal/model/device.go`
- Create: `server/internal/model/pair.go`
- Create: `server/internal/model/sync_message.go`
- Create: `server/internal/model/api.go`
- Create: `server/internal/model/errors.go`

**Step 1: Write all model files**

See SERVER-001_SyncRelay.md Section "Go模型" and "API Request/Response 模型" for exact definitions. Each file contains the struct definitions with JSON tags and `db` tags for database mapping.

Key error types:
```go
// server/internal/model/errors.go
package model

import "errors"

var (
	ErrDeviceNotFound  = errors.New("device not found")
	ErrPairNotFound    = errors.New("pair not found or expired")
	ErrPairAlreadyUsed = errors.New("pair code already used")
	ErrPairNotActive   = errors.New("pair is not active")
	ErrUnauthorized    = errors.New("unauthorized")
	ErrForbidden       = errors.New("forbidden")
)
```

**Step 2: Verify build**

Run: `cd server && go build ./...`

**Step 3: Commit**

```bash
git add server/internal/model/
git commit -m "feat(server): add domain models and API types"
```

---

### Task 4: Repository layer

**Files:**
- Create: `server/internal/repository/device_repo.go`
- Create: `server/internal/repository/pair_repo.go`
- Create: `server/internal/repository/sync_repo.go`
- Test: `server/internal/repository/device_repo_test.go`
- Test: `server/internal/repository/pair_repo_test.go`
- Test: `server/internal/repository/sync_repo_test.go`

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

Run: `cd server && go test ./internal/repository/... -v`
Expected: All pass

**Step 8: Commit**

```bash
git add server/internal/repository/
git commit -m "feat(server): implement repository layer with tests"
```

---

### Task 5: Service layer

**Files:**
- Create: `server/internal/service/device_service.go`
- Create: `server/internal/service/pair_service.go`
- Create: `server/internal/service/sync_service.go`
- Create: `server/internal/service/push_service.go`
- Test: `server/internal/service/pair_service_test.go`
- Test: `server/internal/service/sync_service_test.go`

**Step 1: Write failing tests for PairService**

Test: CreatePair generates 6-digit code, JoinPair matches code, ConfirmPair updates status, expired codes rejected.

**Step 2: Implement PairService**

Key methods: `CreatePair`, `JoinPair`, `ConfirmPair`, `DeletePair`. PairCode = 6 random digits with 10-minute expiry. IMPORTANT: Pair code generation MUST include a retry loop (max 5 attempts) to handle the UNIQUE constraint on `pair_code WHERE status = 'pending'`. On duplicate key error, regenerate and retry.

**Step 3: Write failing tests for SyncService**

Test: ValidateDevicePair, StoreSyncMessage, GetPendingMessages, AckMessages (verify physical DELETE).

**Step 4: Implement SyncService**

Key: `AckMessages` calls `syncRepo.DeleteByIDs` for physical deletion.

**Step 5: Implement DeviceService and PushService**

DeviceService.Register: MUST enforce public key immutability. If `deviceId` already exists and `publicKey` differs → return `ErrPublicKeyMismatch` (409 Conflict). Same `deviceId` + same `publicKey` → idempotent update of `deviceName`/`platform` (200 OK). New `deviceId` → create (201 Created). This prevents an attacker who knows a `deviceId` from replacing the public key and hijacking subsequent authenticated requests.

PushService: Three push event types, all silent push with no sensitive data:
- `NotifySyncAvailable(deviceID)` → `type: "sync_available"` — silent push (content-available: 1)
- `NotifyPairConfirmed(deviceID)` → `type: "pair_confirmed"` — silent push to Device B after A confirms. Without this method, Device B has no signal to transition from confirming → active.
- `NotifyPairRequest(deviceID, joinerName)` → `type: "pair_request"` — visible notification to Device A when B joins

**Step 6: Run all service tests**

Run: `cd server && go test ./internal/service/... -v`

**Step 7: Commit**

```bash
git add server/internal/service/
git commit -m "feat(server): implement service layer with pair/sync logic"
```

---

### Task 6: Auth middleware and request signing

**Files:**
- Create: `server/internal/auth/ed25519_verifier.go`
- Create: `server/internal/auth/middleware.go`
- Test: `server/internal/auth/middleware_test.go`

**Step 1: Write failing test**

Test: valid signature passes, expired timestamp rejects, invalid signature rejects, missing header rejects.

**Step 2: Implement Ed25519 verification**

```go
// Parses: "Ed25519 <deviceId>:<timestamp>:<signature>"
// Reconstructs message: "<method>:<path>:<timestamp>:<SHA256(body)>"
// Verifies with ed25519.Verify(publicKey, message, signature)
// Rejects if |timestamp - now| > 300 seconds
```

**Step 3: Run auth tests**

Run: `cd server && go test ./internal/auth/... -v`

**Step 4: Commit**

```bash
git add server/internal/auth/
git commit -m "feat(server): implement Ed25519 auth middleware"
```

---

### Task 7: HTTP handlers and routing

**Files:**
- Create: `server/internal/handler/helpers.go`
- Create: `server/internal/handler/health_handler.go`
- Create: `server/internal/handler/device_handler.go`
- Create: `server/internal/handler/pair_handler.go`
- Create: `server/internal/handler/sync_handler.go`
- Create: `server/internal/handler/routes.go`
- Test: `server/internal/handler/pair_handler_test.go`
- Test: `server/internal/handler/sync_handler_test.go`

**Step 1: Write helpers (respondJSON, respondError)**

**Step 2: Implement handlers**

See SERVER-001 for all handler implementations. Key patterns:
- Extract `deviceID` from `r.Context().Value(authDeviceIDKey)`
- Decode JSON body with `json.NewDecoder(r.Body).Decode(&req)`
- Call service methods
- Respond with appropriate status codes

**Step 3: Wire up routes**

```go
// server/internal/handler/routes.go
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

Run: `cd server && go test ./internal/handler/... -v`

**Step 6: Commit**

```bash
git add server/internal/handler/
git commit -m "feat(server): implement HTTP handlers and routing"
```

---

### Task 8: Rate limiting, logging, scheduler

**Files:**
- Create: `server/internal/middleware/ratelimit.go`
- Create: `server/internal/middleware/logging.go`
- Create: `server/internal/middleware/cors.go`
- Create: `server/internal/scheduler/cleanup.go`

**Step 1: Implement rate limiter**

Rate limits per device: pair 10/min, sync/push 60/min, sync/pull 30/min, device 5/min. Uses `golang.org/x/time/rate`.

**Step 2: Implement request logging middleware**

Structured JSON logs via `slog`. Log: method, path, status, duration, deviceId. NEVER log: payload, publicKey, signature.

**Step 3: Implement cleanup scheduler**

Three periodic jobs:
- Every 1 min: expire pending pair codes
- Every 1 hour: delete expired sync_messages
- Every 7 days: delete inactive devices (90+ days)

**Step 4: Commit**

```bash
git add server/internal/middleware/ server/internal/scheduler/
git commit -m "feat(server): add rate limiting, logging, cleanup scheduler"
```

---

### Task 9: Wire everything in main.go and add deployment

**Files:**
- Modify: `server/cmd/relay/main.go`
- Create: `server/deploy/Dockerfile`
- Create: `server/deploy/docker-compose.yml`

**Step 1: Complete main.go**

Wire up: database connection, run migrations, create repos, create services, create handlers, setup routes with middleware, start scheduler.

**Step 2: Write Dockerfile**

Multi-stage build: golang:1.22-alpine → alpine:3.19. Binary at `/usr/local/bin/relay`.

**Step 3: Write docker-compose.yml**

Services: relay + postgres:16-alpine with health check.

**Step 4: Test full server startup**

Run: `cd server/deploy && docker-compose up --build`
Expected: Server starts, health check returns 200

**Step 5: Commit**

```bash
git add server/cmd/ server/deploy/
git commit -m "feat(server): complete server wiring and Docker deployment"
```

---

## Phase 2: Flutter Client - Domain & Data Layer

### Task 10: Domain models (Freezed)

**Files:**
- Create: `lib/features/family_sync/domain/models/paired_device.dart`
- Create: `lib/features/family_sync/domain/models/sync_message.dart`
- Create: `lib/features/family_sync/domain/models/sync_status.dart`

**Step 1: Write paired_device.dart**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'paired_device.freezed.dart';
part 'paired_device.g.dart';

enum PairStatus { pending, confirming, active, inactive }

@freezed
abstract class PairedDevice with _$PairedDevice {
  const factory PairedDevice({
    required String pairId,
    required String bookId,
    String? partnerDeviceId,     // null during 'pending' state
    String? partnerPublicKey,    // null during 'pending' state
    String? partnerDeviceName,   // null during 'pending' state
    required PairStatus status,
    String? pairCode,
    DateTime? expiresAt,         // pair code expiry
    required DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? lastSyncAt,
  }) = _PairedDevice;

  factory PairedDevice.fromJson(Map<String, dynamic> json) =>
      _$PairedDeviceFromJson(json);
}
```

**Step 2: Write sync_message.dart and sync_status.dart**

Follow same Freezed pattern. SyncStatus is a plain enum (unpaired, pairing, synced, syncing, syncError, offline).

**Step 3: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Generates `.freezed.dart` and `.g.dart` files

**Step 4: Commit**

```bash
git add lib/features/family_sync/domain/
git commit -m "feat(sync): add domain models for family sync"
```

---

### Task 11: Repository interfaces

**Files:**
- Create: `lib/features/family_sync/domain/repositories/pair_repository.dart`
- Create: `lib/features/family_sync/domain/repositories/sync_repository.dart`

**Step 1: Write abstract interfaces**

See MOD-003 v3.0 "客户端 Repository 接口" section for exact method signatures.

**Step 2: Commit**

```bash
git add lib/features/family_sync/domain/repositories/
git commit -m "feat(sync): add repository interfaces for pair and sync"
```

---

### Task 12: Drift tables

**Files:**
- Create: `lib/data/tables/paired_devices_table.dart`
- Create: `lib/data/tables/sync_queue_table.dart`
- Modify: `lib/data/app_database.dart` (add tables, bump schema version)

**Step 1: Write paired_devices_table.dart**

Follow existing pattern in `transactions_table.dart`. Use `TextColumn`, `IntColumn`, `@DataClassName('PairedDeviceData')`. Primary key: `{pairId}`. Indices: `idx_paired_devices_status`, `idx_paired_devices_book`. Use Symbol syntax `{#status}`. IMPORTANT: `partnerDeviceId`, `partnerPublicKey`, `partnerDeviceName` MUST be `.nullable()` (null during 'pending' state before partner joins). Add `expiresAt` as `integer().nullable()()` for pair code expiry countdown.

**Step 2: Write sync_queue_table.dart**

Primary key: `{id}`. Index: `idx_sync_queue_created` on `{#createdAt}`.

**Step 3: Register tables in app_database.dart**

Add `PairedDevices` and `SyncQueue` to `@DriftDatabase(tables: [...])`. Increment `schemaVersion`. Add migration for new tables.

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

**Step 5: Commit**

```bash
git add lib/data/tables/ lib/data/app_database.dart
git commit -m "feat(sync): add Drift tables for paired devices and sync queue"
```

---

### Task 13: DAOs

**Files:**
- Create: `lib/data/daos/paired_device_dao.dart`
- Create: `lib/data/daos/sync_queue_dao.dart`

**Step 1: Write PairedDeviceDao**

Methods: `insert`, `update`, `findActive`, `findByPairId`, `updateStatus`, `updateLastSyncTime`. Follow pattern from `transaction_dao.dart` - constructor takes `AppDatabase`.

**Step 2: Write SyncQueueDao**

Methods: `insert`, `getPending(limit)`, `delete(id)`, `incrementRetry(id)`, `deleteAll`.

**Step 3: Run code generation and verify build**

Run: `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze`

**Step 4: Commit**

```bash
git add lib/data/daos/
git commit -m "feat(sync): add DAOs for paired devices and sync queue"
```

---

### Task 14: Repository implementations

**Files:**
- Create: `lib/data/repositories/pair_repository_impl.dart`
- Create: `lib/data/repositories/sync_repository_impl.dart`
- Test: `test/unit/data/repositories/pair_repository_impl_test.dart`

**Step 1: Write failing test for PairRepositoryImpl**

Test: savePendingPair (status=pending, partner fields null), saveConfirmingPair (status=confirming, partner fields set), activatePair (status=active), confirmLocalPair (confirming→active), getActivePair returns null when no active pair, getActivePair returns null for confirming/pending pairs, deactivatePair.

**Step 2: Implement PairRepositoryImpl**

Implements `PairRepository` interface. Uses `PairedDeviceDao`. Converts between `PairedDeviceData` (Drift) and `PairedDevice` (domain model). IMPORTANT: `getActivePair()` must filter `WHERE status = 'active'` only — never return pending or confirming pairs, otherwise sync logic starts before confirmation.

**Step 3: Run test**

Run: `flutter test test/unit/data/repositories/pair_repository_impl_test.dart`

**Step 4: Implement SyncRepositoryImpl**

**Step 5: Commit**

```bash
git add lib/data/repositories/ test/unit/data/repositories/
git commit -m "feat(sync): implement pair and sync repositories"
```

---

## Phase 3: Flutter Client - Infrastructure Layer

### Task 15: E2EE Service

**Files:**
- Create: `lib/infrastructure/sync/e2ee_service.dart`
- Test: `test/unit/infrastructure/sync/e2ee_service_test.dart`

**Step 1: Add NaCl dependency**

Check if `cryptography` package (already in pubspec) supports X25519 + XSalsa20-Poly1305. If not, add `pinenacl: ^0.6.0` or `tweetnacl: ^1.0.0`.

**Step 2: Write failing test**

Test: encrypt then decrypt returns original plaintext. Test: decrypt with wrong key fails.

**Step 3: Implement E2EEService**

Key operations:
1. Ed25519 → X25519 key conversion
2. X25519 Diffie-Hellman shared secret
3. XSalsa20-Poly1305 encrypt/decrypt (NaCl box)
4. Output format: base64(nonce_24bytes + ciphertext)

**Step 4: Run test**

Run: `flutter test test/unit/infrastructure/sync/e2ee_service_test.dart`

**Step 5: Commit**

```bash
git add lib/infrastructure/sync/ test/unit/infrastructure/sync/
git commit -m "feat(sync): implement E2EE service with NaCl box"
```

---

### Task 16: Request Signer and Relay API Client

**Files:**
- Create: `lib/infrastructure/sync/relay_api_client.dart`
- Test: `test/unit/infrastructure/sync/relay_api_client_test.dart`

**Step 1: Add HTTP dependency**

Verify `dio` or `http` is in pubspec. Add if needed.

**Step 2: Write request signer**

`RequestSigner` class: constructs message `"$method:$path:$timestamp:$bodyHash"`, signs with Ed25519 private key from `KeyManager`, returns `"Ed25519 $deviceId:$timestamp:$base64Signature"`.

**Step 3: Write RelayApiClient**

Server URL configuration:
- Production (kReleaseMode): `https://sync.happypocket.app/api/v1`
- Development (!kReleaseMode): `https://dev-sync.happypocket.app/api/v1`
- Override via `--dart-define=SYNC_SERVER_URL=https://...`

Wraps all server API calls. Adds `Authorization` header via `RequestSigner`. Methods: `createPair`, `joinPair`, `confirmPair`, `unpair`, `pushSync`, `pullSync`, `ackSync`, `registerDevice`, `updatePushToken`.

Retry with exponential backoff on network errors.

**Step 4: Write unit test with mock HTTP**

Test: createPair sends correct request body, adds auth header. Test: pushSync handles 201 response. Test: network error throws.

**Step 5: Run tests**

Run: `flutter test test/unit/infrastructure/sync/relay_api_client_test.dart`

**Step 6: Commit**

```bash
git add lib/infrastructure/sync/ test/unit/infrastructure/sync/
git commit -m "feat(sync): implement relay API client with Ed25519 signing"
```

---

### Task 17: Sync Queue Manager

**Files:**
- Create: `lib/infrastructure/sync/sync_queue_manager.dart`
- Test: `test/unit/infrastructure/sync/sync_queue_manager_test.dart`

**Step 1: Write failing test**

Test: enqueue adds entry. Test: drainQueue sends and deletes on success. Test: drainQueue increments retry on failure. Test: clearQueue deletes all.

**Step 2: Implement SyncQueueManager**

Max batch size: 50. Uses `SyncQueueDao` for persistence and `RelayApiClient` for pushing.

**Step 3: Run test**

Run: `flutter test test/unit/infrastructure/sync/sync_queue_manager_test.dart`

**Step 4: Commit**

```bash
git add lib/infrastructure/sync/ test/unit/infrastructure/sync/
git commit -m "feat(sync): implement offline sync queue manager"
```

---

### Task 18: Push Notification Service

**Files:**
- Create: `lib/infrastructure/sync/push_notification_service.dart`

**Step 1: Add firebase_messaging dependency**

```bash
flutter pub add firebase_messaging
```

**Step 2: Implement PushNotificationService**

- Request permission on iOS
- Get and register FCM/APNs token with server
- Message dispatch by `type` field:
  - `pair_confirmed` → call `_handlePairConfirmed()`: get `getPendingPair()`, if status == confirming call `confirmLocalPair(pairId)` then `pullSync()`. This is the ONLY path that transitions Device B from confirming → active.
  - `sync_available` → call `pullSync()`
  - `pair_request` → handled by system notification (foreground only)
- Handle background message: support both `sync_available` and `pair_confirmed`
- Refresh token on change

**Step 3: Commit**

```bash
git add lib/infrastructure/sync/
git commit -m "feat(sync): implement push notification service"
```

---

## Phase 4: Flutter Client - Application Layer (Use Cases)

### Task 19: Pairing use cases

**Files:**
- Create: `lib/application/family_sync/create_pair_use_case.dart`
- Create: `lib/application/family_sync/join_pair_use_case.dart`
- Create: `lib/application/family_sync/confirm_pair_use_case.dart`
- Create: `lib/application/family_sync/unpair_use_case.dart`
- Test: `test/unit/application/family_sync/create_pair_use_case_test.dart`
- Test: `test/unit/application/family_sync/join_pair_use_case_test.dart`

**Step 1: Write failing tests for CreatePairUseCase**

Test: success returns pairId + pairCode. Test: error when keyManager has no keys.

**Step 2: Implement CreatePairUseCase**

See MOD-003 "配对发起" section. IMPORTANT: Must call `_apiClient.registerDevice()` (idempotent, unauthenticated) BEFORE `_apiClient.createPair()`. Without this, the server has no public key to verify the device's Ed25519 signature on the createPair request.

**Step 3: Write failing tests for JoinPairUseCase**

Test: success stores partner public key. Test: initializes E2EE shared secret. Test: calls registerDevice before joinPair.

**Step 4: Implement JoinPairUseCase, ConfirmPairUseCase, UnpairUseCase**

IMPORTANT for JoinPairUseCase: Must call `registerDevice()` before `joinPair()` (same auth bootstrap reason).

IMPORTANT for ConfirmPairUseCase: After confirm succeeds and E2EE is initialized, MUST trigger `fullSync.execute(bookId)` to push all existing local transactions to the newly paired partner. Without this, the partner's device starts empty and only receives future changes.

**Step 5: Run all tests**

Run: `flutter test test/unit/application/family_sync/`

**Step 6: Commit**

```bash
git add lib/application/family_sync/ test/unit/application/family_sync/
git commit -m "feat(sync): implement pairing use cases with tests"
```

---

### Task 20: Sync use cases

**Files:**
- Create: `lib/application/family_sync/push_sync_use_case.dart`
- Create: `lib/application/family_sync/pull_sync_use_case.dart`
- Create: `lib/application/family_sync/full_sync_use_case.dart`
- Test: `test/unit/application/family_sync/push_sync_use_case_test.dart`
- Test: `test/unit/application/family_sync/pull_sync_use_case_test.dart`

**Step 1: Write failing tests for PushSyncUseCase**

Test: success encrypts and pushes. Test: network failure queues offline. Test: no pair returns noPair.

**Step 2: Implement PushSyncUseCase**

See MOD-003 "主动推送" section.

**Step 3: Write failing tests for PullSyncUseCase**

Test: pulls and decrypts messages. Test: ACKs after pull. Test: drains queue after pull. Test: stores server-issued `createdAt` of last message as sync cursor (NOT `DateTime.now()`).

IMPORTANT: The sync cursor MUST use the server's `created_at` timestamp from the last pulled message, not the client's wall-clock time. Client clock skew ahead of server time would cause subsequent pulls to skip valid messages.

**Step 4: Implement PullSyncUseCase and FullSyncUseCase**

PullSyncUseCase: After ACK, update `lastSyncAt` with `messages.last.createdAt` (server timestamp), not `DateTime.now()`.

FullSyncUseCase: Chunks all local transactions and pushes via PushSyncUseCase. Triggered by ConfirmPairUseCase after successful pairing.

**Step 5: Run all tests**

Run: `flutter test test/unit/application/family_sync/`

**Step 6: Commit**

```bash
git add lib/application/family_sync/ test/unit/application/family_sync/
git commit -m "feat(sync): implement sync use cases (push, pull, full sync)"
```

---

## Phase 5: Flutter Client - Providers

### Task 21: Riverpod providers

**Files:**
- Create: `lib/features/family_sync/presentation/providers/repository_providers.dart`
- Create: `lib/features/family_sync/presentation/providers/pair_providers.dart`
- Create: `lib/features/family_sync/presentation/providers/sync_providers.dart`

**Step 1: Write repository_providers.dart**

Single source of truth. Wire up: `pairRepository`, `syncRepository`, `relayApiClient`, `e2eeService`, `syncQueueManager`.

Follow pattern from `lib/features/accounting/presentation/providers/repository_providers.dart`:
```dart
@riverpod
PairRepository pairRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = PairedDeviceDao(database);
  return PairRepositoryImpl(dao: dao);
}
```

**Step 2: Write pair_providers.dart**

Wire up: `createPairUseCase`, `joinPairUseCase`, `confirmPairUseCase`, `unpairUseCase`. Reference `repository_providers.dart`.

**Step 3: Write sync_providers.dart**

Wire up: `pushSyncUseCase`, `pullSyncUseCase`, `syncStatusProvider`.

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

**Step 5: Verify build**

Run: `flutter analyze`
Expected: No issues found

**Step 6: Commit**

```bash
git add lib/features/family_sync/presentation/providers/
git commit -m "feat(sync): add Riverpod providers for family sync"
```

---

## Phase 6: Flutter Client - UI

### Task 22: Pairing screen

**Files:**
- Create: `lib/features/family_sync/presentation/screens/pairing_screen.dart`
- Create: `lib/features/family_sync/presentation/widgets/pair_code_display.dart`
- Create: `lib/features/family_sync/presentation/widgets/pair_code_input.dart`

**Step 1: Add QR code dependency**

```bash
flutter pub add qr_flutter
```

**Step 2: Implement PairCodeDisplay**

Shows QR code (250x250) + 6-digit code (formatted "XXX XXX") + 10-min expiry timer + regenerate button. Uses `ref.watch(createPairProvider(bookId))`.

**Step 3: Implement PairCodeInput**

6-digit input field with large font + submit button. Calls `ref.read(joinPairProvider(code))`.

**Step 4: Implement PairingScreen**

TabBarView with 2 tabs: "Show My Code" and "Enter Partner Code".

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/
git commit -m "feat(sync): implement pairing screen with QR and short code"
```

---

### Task 23: Sync status widgets

**Files:**
- Create: `lib/features/family_sync/presentation/widgets/sync_status_badge.dart`
- Create: `lib/features/family_sync/presentation/widgets/partner_device_tile.dart`
- Create: `lib/features/family_sync/presentation/screens/pair_management_screen.dart`

**Step 1: Implement SyncStatusBadge**

Displays icon + label based on `SyncStatus` enum. Colors: green (synced), blue (syncing), orange (pairing/offline), red (error), grey (unpaired).

**Step 2: Implement PartnerDeviceTile**

Shows partner device name, last sync time (using `DateFormatter`), sync status badge.

**Step 3: Implement PairManagementScreen**

Shows current pair info, sync status, unpair button with confirmation dialog.

**Step 4: Commit**

```bash
git add lib/features/family_sync/presentation/
git commit -m "feat(sync): implement sync status widgets and pair management"
```

---

### Task 24: App lifecycle integration

**Files:**
- Modify: `lib/core/initialization/app_initializer.dart`
- Modify: App lifecycle observer (create if needed)

**Step 1: Add lifecycle observer**

On `AppLifecycleState.resumed`: if paired, call `pullSync()` and `drainSyncQueue()`.

**Step 2: Hook transaction changes (create, update, delete)**

After `CreateTransactionUseCase`, `UpdateTransactionUseCase`, and `DeleteTransactionUseCase` succeed: if paired, call `pushSync()` with CRDT operations. FR-002 requires syncing both new AND modified bills. Without hooking update/delete, partner replicas will diverge for edits and removals.

**Step 3: Hook push notifications**

Push messages are dispatched by `type` field (see Task 18 PushNotificationService):
- `pair_confirmed` → `_handlePairConfirmed()` (confirmLocalPair + pullSync). Without this, Device B stays in `confirming` forever and `getActivePair()` never returns it.
- `sync_available` → `pullSync()`
- `pair_request` → system notification (no code action needed)

**Step 4: Commit**

```bash
git add lib/core/ lib/application/
git commit -m "feat(sync): integrate sync triggers with app lifecycle"
```

---

### Task 25: Navigation and routing

**Files:**
- Modify: `lib/core/router/` (add routes for pairing_screen, pair_management_screen)

**Step 1: Add routes**

```dart
GoRoute(
  path: '/pairing',
  builder: (context, state) => PairingScreen(
    bookId: state.extra as String,
  ),
),
GoRoute(
  path: '/pair-management',
  builder: (context, state) => const PairManagementScreen(),
),
```

**Step 2: Add entry point in settings or home screen**

Add "Family Sync" option in settings screen or home screen widget.

**Step 3: Commit**

```bash
git add lib/core/router/ lib/features/
git commit -m "feat(sync): add navigation routes for family sync screens"
```

---

## Phase 7: Integration Testing

### Task 26: Server integration tests

**Files:**
- Create: `server/internal/handler/integration_test.go`

**Step 1: Write full pairing flow test**

Test: register devices → create pair → join pair → confirm pair → verify both have partner keys.

**Step 2: Write full sync flow test**

Test: push encrypted blob → pull returns blob → ack deletes blob → second pull returns empty.

**Step 3: Write auth tests**

Test: request without auth header → 401. Request with expired timestamp → 401. Request with invalid signature → 401.

**Step 4: Run all server tests**

Run: `cd server && go test ./... -v`
Expected: All pass, coverage ≥80%

**Step 5: Commit**

```bash
git add server/
git commit -m "test(server): add integration tests for pairing and sync flows"
```

---

### Task 27: Client unit tests

**Files:**
- Test: `test/unit/infrastructure/sync/e2ee_service_test.dart`
- Test: `test/unit/application/family_sync/push_sync_use_case_test.dart`
- Test: `test/unit/application/family_sync/pull_sync_use_case_test.dart`
- Test: `test/unit/application/family_sync/create_pair_use_case_test.dart`
- Test: `test/unit/data/repositories/pair_repository_impl_test.dart`

**Step 1: Verify all client tests pass**

Run: `flutter test`
Expected: All pass

**Step 2: Check coverage**

Run: `flutter test --coverage`
Expected: ≥80% coverage for new files

**Step 3: Commit**

```bash
git commit -m "test(sync): verify all client tests pass with 80%+ coverage"
```

---

### Task 28: Add i18n strings

**Files:**
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`

**Step 1: Add translation keys**

Keys needed: `devicePairing`, `showMyCode`, `enterPartnerCode`, `pairCodeExpiresIn`, `regenerate`, `unpaired`, `pairing`, `synced`, `syncing`, `syncError`, `offline`, `unpair`, `unpairConfirmation`, `pairSuccess`, `pairFailed`.

Add to all 3 ARB files with @metadata.

**Step 2: Generate localization files**

Run: `flutter gen-l10n`

**Step 3: Commit**

```bash
git add lib/l10n/ lib/generated/
git commit -m "feat(sync): add i18n strings for family sync (ja/en/zh)"
```

---

### Task 29: Final verification

**Step 1: Run flutter analyze**

Run: `flutter analyze`
Expected: No issues found

**Step 2: Run all tests**

Run: `flutter test`
Expected: All pass

**Step 3: Run server tests**

Run: `cd server && go test ./... -v`
Expected: All pass

**Step 4: Build check**

Run: `flutter build ios --no-codesign` (or `flutter build apk --debug`)
Expected: Builds without errors

**Step 5: Commit any fixes**

```bash
git commit -m "chore(sync): final verification pass - all tests and build green"
```

---

## Task Dependency Graph

```
Phase 1: Go Server
  T1 (init) → T2 (migrations) → T3 (models) → T4 (repos) → T5 (services)
                                                              ↓
  T6 (auth) ──────────────────────────────────────────→ T7 (handlers)
                                                              ↓
  T8 (middleware) ────────────────────────────────────→ T9 (wire + deploy)

Phase 2: Flutter Domain & Data (can start in parallel with Phase 1)
  T10 (models) → T11 (repo interfaces) → T12 (Drift tables) → T13 (DAOs) → T14 (repo impls)

Phase 3: Flutter Infrastructure (depends on T14)
  T15 (E2EE) ─┐
  T16 (API) ──┤→ T17 (queue) → T18 (push)
               │
Phase 4: Flutter Use Cases (depends on T15-T18)
  T19 (pair UCs) → T20 (sync UCs)

Phase 5: Providers (depends on T19-T20)
  T21 (providers)

Phase 6: UI (depends on T21)
  T22 (pairing screen) → T23 (status widgets) → T24 (lifecycle) → T25 (routing)

Phase 7: Testing (depends on all above)
  T26 (server integration) + T27 (client tests) → T28 (i18n) → T29 (final verify)
```

---

## Estimated Effort

| Phase | Tasks | Estimated Time |
|-------|-------|---------------|
| Phase 1: Go Server | T1-T9 | 5 days |
| Phase 2: Flutter Domain & Data | T10-T14 | 2 days |
| Phase 3: Flutter Infrastructure | T15-T18 | 2 days |
| Phase 4: Use Cases | T19-T20 | 1.5 days |
| Phase 5: Providers | T21 | 0.5 days |
| Phase 6: UI | T22-T25 | 2 days |
| Phase 7: Testing & i18n | T26-T29 | 2 days |
| **Total** | **29 tasks** | **~15 days** |
