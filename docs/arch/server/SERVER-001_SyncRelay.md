# SERVER-001: 同步中转服务器 - 技术设计文档

**文档编号:** SERVER-001
**文档名称:** 同步中转服务器
**文档版本:** 1.0
**创建日期:** 2026-02-28
**关联模块:** MOD-003 (家庭同步)
**技术栈:** Go 1.22+ / PostgreSQL 16 / APNs / FCM

---

## 📋 目录

1. [服务概述](#服务概述)
2. [架构设计](#架构设计)
3. [项目结构](#项目结构)
4. [API设计](#api设计)
5. [数据模型](#数据模型)
6. [认证与安全](#认证与安全)
7. [推送通知](#推送通知)
8. [后台任务](#后台任务)
9. [部署方案](#部署方案)
10. [监控与运维](#监控与运维)
11. [测试策略](#测试策略)

---

## 服务概述

### 服务定位

同步中转服务器是一个**轻量级、零知识的盲中转服务**。它的唯一职责是：

1. 管理设备配对关系
2. 中转加密的同步数据块
3. 发送推送通知

**核心原则:**
- **零知识:** 服务器永远无法解密客户端数据
- **临时存储:** 同步数据在ACK后物理删除
- **无状态认证:** 基于Ed25519设备密钥签名，无session
- **最小权限:** 服务器只存储配对关系和加密数据块

### 技术选型

| 组件 | 选择 | 理由 |
|------|------|------|
| 语言 | Go 1.22+ | 高性能、低资源占用、原生并发 |
| 数据库 | PostgreSQL 16 | 可靠、支持JSONB、丰富的索引 |
| HTTP框架 | chi / echo | 轻量、高性能、中间件支持好 |
| 推送 | APNs + FCM SDK | iOS/Android原生推送 |
| 部署 | Docker + Cloud Run | 按需扩缩容、成本低 |
| 域名 | `sync.happypocket.app` (prod) / `dev-sync.happypocket.app` (dev) | HTTPS only, TLS 1.3 |

---

## 架构设计

### 系统架构

```
                    ┌─────────────────┐
                    │   Load Balancer  │
                    │   (Cloud Run)    │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   Go HTTP Server │
                    │                  │
                    │  ┌────────────┐  │
                    │  │  Handlers   │  │
                    │  ├────────────┤  │
                    │  │  Services   │  │
                    │  ├────────────┤  │
                    │  │  Auth MW    │  │
                    │  ├────────────┤  │
                    │  │  Rate Limit │  │
                    │  └────────────┘  │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
     ┌────────▼───┐  ┌──────▼──────┐  ┌───▼────────┐
     │ PostgreSQL  │  │ APNs Gateway│  │ FCM Gateway │
     │             │  │             │  │             │
     │ - devices   │  │ (iOS push)  │  │ (Android    │
     │ - pairs     │  │             │  │  push)      │
     │ - messages  │  └─────────────┘  └────────────┘
     └─────────────┘
```

### 分层架构

```
Handler层 (HTTP handlers)
    ↓ 调用
Service层 (业务逻辑)
    ↓ 调用
Repository层 (数据访问)
    ↓ 操作
Database层 (PostgreSQL)
```

---

## 项目结构

```
server/
├── cmd/
│   └── relay/
│       └── main.go                 # 应用入口
│
├── internal/
│   ├── config/
│   │   └── config.go               # 配置加载 (env / yaml)
│   │
│   ├── auth/
│   │   ├── ed25519_verifier.go     # Ed25519签名验证
│   │   └── middleware.go           # 认证中间件
│   │
│   ├── handler/
│   │   ├── device_handler.go       # 设备注册API
│   │   ├── pair_handler.go         # 配对API
│   │   ├── sync_handler.go         # 同步API
│   │   └── health_handler.go       # 健康检查
│   │
│   ├── service/
│   │   ├── device_service.go       # 设备管理逻辑
│   │   ├── pair_service.go         # 配对业务逻辑
│   │   ├── sync_service.go         # 同步业务逻辑
│   │   └── push_service.go         # 推送通知逻辑
│   │
│   ├── repository/
│   │   ├── device_repo.go          # 设备数据访问
│   │   ├── pair_repo.go            # 配对数据访问
│   │   └── sync_repo.go            # 同步消息数据访问
│   │
│   ├── model/
│   │   ├── device.go               # 设备模型
│   │   ├── pair.go                 # 配对模型
│   │   ├── sync_message.go         # 同步消息模型
│   │   └── api.go                  # API请求/响应模型
│   │
│   ├── middleware/
│   │   ├── ratelimit.go            # 速率限制
│   │   ├── logging.go              # 请求日志
│   │   └── cors.go                 # CORS配置
│   │
│   └── scheduler/
│       ├── cleanup.go              # 定时清理任务
│       └── scheduler.go            # 任务调度器
│
├── migrations/
│   ├── 001_create_devices.sql
│   ├── 002_create_pairs.sql
│   └── 003_create_sync_messages.sql
│
├── deploy/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── cloud-run.yaml
│
├── go.mod
├── go.sum
└── README.md
```

---

## API设计

### 路由定义

```go
// internal/handler/routes.go

func SetupRoutes(r chi.Router, h *Handlers, authMW func(http.Handler) http.Handler) {
    r.Route("/api/v1", func(r chi.Router) {
        // 健康检查（无需认证）
        r.Get("/health", h.Health.Check)

        // 设备注册（无需认证，首次注册，公钥不可变）
        // 安全规则：已注册的deviceId不允许更换publicKey
        // 相同deviceId+相同publicKey → 200 OK（幂等更新deviceName/platform）
        // 相同deviceId+不同publicKey → 409 Conflict（防止公钥劫持）
        // 新deviceId → 201 Created
        r.Post("/device/register", h.Device.Register)

        // 需要认证的路由
        r.Group(func(r chi.Router) {
            r.Use(authMW)

            // 设备管理
            r.Put("/device/push-token", h.Device.UpdatePushToken)

            // 配对
            r.Post("/pair/create", h.Pair.Create)
            r.Post("/pair/join", h.Pair.Join)
            r.Post("/pair/confirm", h.Pair.Confirm)
            r.Get("/pair/status/{pairId}", h.Pair.Status)
            r.Delete("/pair/{pairId}", h.Pair.Delete)

            // 同步
            r.Post("/sync/push", h.Sync.Push)
            r.Get("/sync/pull", h.Sync.Pull)
            r.Post("/sync/ack", h.Sync.Ack)
        })
    })
}
```

### 配对API实现

```go
// internal/handler/pair_handler.go

type PairHandler struct {
    pairService *service.PairService
    pushService *service.PushService
}

// POST /api/v1/pair/create
func (h *PairHandler) Create(w http.ResponseWriter, r *http.Request) {
    deviceID := r.Context().Value(authDeviceIDKey).(string)

    var req CreatePairRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        respondError(w, http.StatusBadRequest, "invalid request body")
        return
    }

    result, err := h.pairService.CreatePair(r.Context(), deviceID, req)
    if err != nil {
        respondError(w, http.StatusInternalServerError, err.Error())
        return
    }

    respondJSON(w, http.StatusCreated, CreatePairResponse{
        PairID:    result.PairID,
        PairCode:  result.PairCode,
        QRData:    result.QRData,
        ExpiresAt: result.ExpiresAt,
    })
}

// POST /api/v1/pair/join
func (h *PairHandler) Join(w http.ResponseWriter, r *http.Request) {
    deviceID := r.Context().Value(authDeviceIDKey).(string)

    var req JoinPairRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        respondError(w, http.StatusBadRequest, "invalid request body")
        return
    }

    result, err := h.pairService.JoinPair(r.Context(), deviceID, req)
    if err != nil {
        switch {
        case errors.Is(err, ErrPairNotFound):
            respondError(w, http.StatusNotFound, "pair code not found or expired")
        case errors.Is(err, ErrPairAlreadyUsed):
            respondError(w, http.StatusConflict, "pair code already used")
        default:
            respondError(w, http.StatusInternalServerError, err.Error())
        }
        return
    }

    // 推送通知给发起方（Device A）
    go h.pushService.NotifyPairRequest(r.Context(), result.InitiatorDeviceID, result.JoinerDeviceName)

    respondJSON(w, http.StatusOK, JoinPairResponse{
        PairID:            result.PairID,
        PartnerDeviceID:   result.InitiatorDeviceID,
        PartnerPublicKey:  result.InitiatorPublicKey,
        PartnerDeviceName: result.InitiatorDeviceName,
        Status:            "confirming",
    })
}

// POST /api/v1/pair/confirm
func (h *PairHandler) Confirm(w http.ResponseWriter, r *http.Request) {
    deviceID := r.Context().Value(authDeviceIDKey).(string)

    var req ConfirmPairRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        respondError(w, http.StatusBadRequest, "invalid request body")
        return
    }

    result, err := h.pairService.ConfirmPair(r.Context(), deviceID, req)
    if err != nil {
        respondError(w, http.StatusInternalServerError, err.Error())
        return
    }

    // 推送通知给加入方（Device B）
    if req.Accept {
        go h.pushService.NotifyPairConfirmed(r.Context(), result.JoinerDeviceID)
    }

    respondJSON(w, http.StatusOK, ConfirmPairResponse{
        Status:            result.Status,
        PartnerDeviceID:   result.JoinerDeviceID,
        PartnerPublicKey:  result.JoinerPublicKey,
        PartnerDeviceName: result.JoinerDeviceName,
    })
}
```

### 同步API实现

```go
// internal/handler/sync_handler.go

type SyncHandler struct {
    syncService *service.SyncService
    pushService *service.PushService
}

// POST /api/v1/sync/push
func (h *SyncHandler) Push(w http.ResponseWriter, r *http.Request) {
    deviceID := r.Context().Value(authDeviceIDKey).(string)

    var req PushSyncRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        respondError(w, http.StatusBadRequest, "invalid request body")
        return
    }

    // 验证设备是该配对的成员
    if err := h.syncService.ValidateDevicePair(r.Context(), deviceID, req.PairID); err != nil {
        respondError(w, http.StatusForbidden, "device not authorized for this pair")
        return
    }

    // 存储加密消息
    msgID, err := h.syncService.StoreSyncMessage(r.Context(), service.StoreSyncMessageInput{
        PairID:         req.PairID,
        FromDeviceID:   deviceID,
        ToDeviceID:     req.TargetDeviceID,
        Payload:        req.Payload,         // 加密的，服务器无法解密
        VectorClock:    req.VectorClock,
        OperationCount: req.OperationCount,
        ChunkIndex:     req.ChunkIndex,
        TotalChunks:    req.TotalChunks,
    })
    if err != nil {
        respondError(w, http.StatusInternalServerError, err.Error())
        return
    }

    // 发送静默推送通知给目标设备
    pushSent := false
    go func() {
        if err := h.pushService.NotifySyncAvailable(context.Background(), req.TargetDeviceID); err == nil {
            pushSent = true
        }
    }()

    respondJSON(w, http.StatusCreated, PushSyncResponse{
        MessageID:            msgID,
        Pushed:               true,
        PushNotificationSent: pushSent,
    })
}

// GET /api/v1/sync/pull?since=<timestamp>
func (h *SyncHandler) Pull(w http.ResponseWriter, r *http.Request) {
    deviceID := r.Context().Value(authDeviceIDKey).(string)

    sinceStr := r.URL.Query().Get("since")
    since, _ := strconv.ParseInt(sinceStr, 10, 64)

    messages, err := h.syncService.GetPendingMessages(r.Context(), deviceID, since)
    if err != nil {
        respondError(w, http.StatusInternalServerError, err.Error())
        return
    }

    // 转换为API响应
    var items []SyncMessageResponse
    for _, msg := range messages {
        items = append(items, SyncMessageResponse{
            MessageID:      msg.MessageID,
            FromDeviceID:   msg.FromDeviceID,
            Payload:        msg.Payload,
            VectorClock:    msg.VectorClock,
            OperationCount: msg.OperationCount,
            CreatedAt:      msg.CreatedAt.Unix(),
        })
    }

    respondJSON(w, http.StatusOK, PullSyncResponse{
        Messages: items,
        HasMore:  len(items) >= 100, // 分页限制
    })
}

// POST /api/v1/sync/ack
func (h *SyncHandler) Ack(w http.ResponseWriter, r *http.Request) {
    deviceID := r.Context().Value(authDeviceIDKey).(string)

    var req AckSyncRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        respondError(w, http.StatusBadRequest, "invalid request body")
        return
    }

    // 物理删除已确认的消息
    deleted, err := h.syncService.AckMessages(r.Context(), deviceID, req.MessageIDs)
    if err != nil {
        respondError(w, http.StatusInternalServerError, err.Error())
        return
    }

    respondJSON(w, http.StatusOK, AckSyncResponse{
        Deleted: deleted,
    })
}
```

### API Request/Response 模型

```go
// internal/model/api.go

// === Device ===

type RegisterDeviceRequest struct {
    DeviceID   string `json:"deviceId" validate:"required"`
    PublicKey  string `json:"publicKey" validate:"required"`
    DeviceName string `json:"deviceName" validate:"required"`
    Platform   string `json:"platform" validate:"required,oneof=ios android"`
    PushToken  string `json:"pushToken,omitempty"`
}

type UpdatePushTokenRequest struct {
    PushToken    string `json:"pushToken" validate:"required"`
    PushPlatform string `json:"pushPlatform" validate:"required,oneof=apns fcm"`
}

// === Pair ===

type CreatePairRequest struct {
    BookID     string `json:"bookId" validate:"required"`
    PublicKey  string `json:"publicKey" validate:"required"`
    DeviceName string `json:"deviceName" validate:"required"`
}

type CreatePairResponse struct {
    PairID    string `json:"pairId"`
    PairCode  string `json:"pairCode"`
    QRData    string `json:"qrData"`
    ExpiresAt int64  `json:"expiresAt"`
}

type JoinPairRequest struct {
    PairCode   string `json:"pairCode" validate:"required,len=6"`
    PublicKey  string `json:"publicKey" validate:"required"`
    DeviceName string `json:"deviceName" validate:"required"`
}

type JoinPairResponse struct {
    PairID            string `json:"pairId"`
    PartnerDeviceID   string `json:"partnerDeviceId"`
    PartnerPublicKey  string `json:"partnerPublicKey"`
    PartnerDeviceName string `json:"partnerDeviceName"`
    Status            string `json:"status"`
}

type ConfirmPairRequest struct {
    PairID string `json:"pairId" validate:"required"`
    Accept bool   `json:"accept"`
}

type ConfirmPairResponse struct {
    Status            string `json:"status"`
    PartnerDeviceID   string `json:"partnerDeviceId,omitempty"`
    PartnerPublicKey  string `json:"partnerPublicKey,omitempty"`
    PartnerDeviceName string `json:"partnerDeviceName,omitempty"`
}

// === Sync ===

type PushSyncRequest struct {
    PairID         string         `json:"pairId" validate:"required"`
    TargetDeviceID string         `json:"targetDeviceId" validate:"required"`
    Payload        string         `json:"payload" validate:"required"`   // encrypted base64
    VectorClock    map[string]int `json:"vectorClock" validate:"required"`
    OperationCount int            `json:"operationCount" validate:"required,min=1"`
    ChunkIndex     int            `json:"chunkIndex"`
    TotalChunks    int            `json:"totalChunks"`
}

type PushSyncResponse struct {
    MessageID            string `json:"messageId"`
    Pushed               bool   `json:"pushed"`
    PushNotificationSent bool   `json:"pushNotificationSent"`
}

type PullSyncResponse struct {
    Messages []SyncMessageResponse `json:"messages"`
    HasMore  bool                  `json:"hasMore"`
}

type SyncMessageResponse struct {
    MessageID      string         `json:"messageId"`
    FromDeviceID   string         `json:"fromDeviceId"`
    Payload        string         `json:"payload"`
    VectorClock    map[string]int `json:"vectorClock"`
    OperationCount int            `json:"operationCount"`
    CreatedAt      int64          `json:"createdAt"`
}

type AckSyncRequest struct {
    MessageIDs []string `json:"messageIds" validate:"required,min=1"`
}

type AckSyncResponse struct {
    Deleted int `json:"deleted"`
}

// === Error ===

type ErrorResponse struct {
    Error   string `json:"error"`
    Code    string `json:"code,omitempty"`
    Details string `json:"details,omitempty"`
}
```

---

## 数据模型

### 数据库迁移

```sql
-- migrations/001_create_devices.sql

CREATE TABLE devices (
    device_id       TEXT PRIMARY KEY,
    public_key      TEXT NOT NULL,
    device_name     TEXT NOT NULL,
    platform        TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
    push_token      TEXT,
    push_platform   TEXT CHECK (push_platform IN ('apns', 'fcm')),
    registered_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_devices_last_seen ON devices(last_seen_at);
```

```sql
-- migrations/002_create_pairs.sql

CREATE TABLE pairs (
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

CREATE UNIQUE INDEX idx_pairs_pair_code ON pairs(pair_code) WHERE status = 'pending';
CREATE INDEX idx_pairs_device_a ON pairs(device_a_id) WHERE status = 'active';
CREATE INDEX idx_pairs_device_b ON pairs(device_b_id) WHERE status = 'active';
CREATE INDEX idx_pairs_status_expires ON pairs(status, expires_at) WHERE status = 'pending';
```

```sql
-- migrations/003_create_sync_messages.sql

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

CREATE INDEX idx_sync_messages_to_device ON sync_messages(to_device_id, created_at);
CREATE INDEX idx_sync_messages_expires ON sync_messages(expires_at);
CREATE INDEX idx_sync_messages_pair ON sync_messages(pair_id);
```

### Go模型

```go
// internal/model/device.go

type Device struct {
    DeviceID     string    `db:"device_id"`
    PublicKey    string    `db:"public_key"`
    DeviceName   string    `db:"device_name"`
    Platform     string    `db:"platform"`
    PushToken    *string   `db:"push_token"`
    PushPlatform *string   `db:"push_platform"`
    RegisteredAt time.Time `db:"registered_at"`
    LastSeenAt   time.Time `db:"last_seen_at"`
}

// internal/model/pair.go

type Pair struct {
    PairID          uuid.UUID  `db:"pair_id"`
    BookID          string     `db:"book_id"`
    DeviceAID       string     `db:"device_a_id"`
    DeviceBID       *string    `db:"device_b_id"`
    DeviceAPublicKey string   `db:"device_a_public_key"`
    DeviceAName     string     `db:"device_a_name"`
    DeviceBPublicKey *string   `db:"device_b_public_key"`
    DeviceBName     *string    `db:"device_b_name"`
    PairCode        string     `db:"pair_code"`
    Status          string     `db:"status"`
    CreatedAt       time.Time  `db:"created_at"`
    ExpiresAt       time.Time  `db:"expires_at"`
    ConfirmedAt     *time.Time `db:"confirmed_at"`
    DeactivatedAt   *time.Time `db:"deactivated_at"`
}

// internal/model/sync_message.go

type SyncMessage struct {
    MessageID      uuid.UUID      `db:"message_id"`
    PairID         uuid.UUID      `db:"pair_id"`
    FromDeviceID   string         `db:"from_device_id"`
    ToDeviceID     string         `db:"to_device_id"`
    Payload        []byte         `db:"payload"`
    VectorClock    map[string]int `db:"vector_clock"`
    OperationCount int            `db:"operation_count"`
    ChunkIndex     int            `db:"chunk_index"`
    TotalChunks    int            `db:"total_chunks"`
    CreatedAt      time.Time      `db:"created_at"`
    ExpiresAt      time.Time      `db:"expires_at"`
}
```

---

## 认证与安全

### 设备注册安全规则

**公钥不可变原则：** `POST /device/register` 是唯一的未认证端点。为防止攻击者通过已知 `deviceId` 替换公钥从而劫持后续所有已认证请求，服务端必须执行以下逻辑：

```go
// internal/service/device_service.go

func (s *DeviceService) Register(ctx context.Context, req RegisterDeviceRequest) error {
    existing, err := s.repo.FindByID(ctx, req.DeviceID)
    if err != nil {
        return err
    }

    if existing != nil {
        // 已注册：公钥必须匹配，否则拒绝（防止公钥劫持）
        if existing.PublicKey != req.PublicKey {
            return ErrPublicKeyMismatch // → 409 Conflict
        }
        // 幂等更新：允许更新 deviceName 和 platform
        return s.repo.Update(ctx, req.DeviceID, req.DeviceName, req.Platform)
    }

    // 首次注册
    return s.repo.Create(ctx, model.Device{
        DeviceID:   req.DeviceID,
        PublicKey:  req.PublicKey,
        DeviceName: req.DeviceName,
        Platform:   req.Platform,
    })
}
```

**密钥轮换流程（未来扩展）：** 如果设备需要更换公钥（如恢复出厂设置后），必须通过已认证端点（用旧私钥签名）提交新公钥，而非通过未认证的 register 端点。

### Ed25519签名验证中间件

```go
// internal/auth/middleware.go

func AuthMiddleware(deviceRepo *repository.DeviceRepo) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            authHeader := r.Header.Get("Authorization")
            if authHeader == "" {
                respondError(w, http.StatusUnauthorized, "missing authorization header")
                return
            }

            // 解析: "Ed25519 <deviceId>:<timestamp>:<signature>"
            deviceID, timestamp, signature, err := parseAuthHeader(authHeader)
            if err != nil {
                respondError(w, http.StatusUnauthorized, "invalid authorization format")
                return
            }

            // 检查时间戳（防重放，±5分钟）
            ts, err := strconv.ParseInt(timestamp, 10, 64)
            if err != nil || abs(time.Now().Unix()-ts) > 300 {
                respondError(w, http.StatusUnauthorized, "request timestamp expired")
                return
            }

            // 查找设备公钥
            device, err := deviceRepo.FindByID(r.Context(), deviceID)
            if err != nil || device == nil {
                respondError(w, http.StatusUnauthorized, "device not registered")
                return
            }

            // 构造签名消息
            bodyBytes, _ := io.ReadAll(r.Body)
            r.Body = io.NopCloser(bytes.NewReader(bodyBytes))

            bodyHash := sha256.Sum256(bodyBytes)
            message := fmt.Sprintf("%s:%s:%s:%x",
                r.Method, r.URL.Path, timestamp, bodyHash)

            // 验证Ed25519签名
            pubKey, err := decodePublicKey(device.PublicKey)
            if err != nil {
                respondError(w, http.StatusUnauthorized, "invalid public key")
                return
            }

            sig, err := base64.StdEncoding.DecodeString(signature)
            if err != nil || !ed25519.Verify(pubKey, []byte(message), sig) {
                respondError(w, http.StatusUnauthorized, "invalid signature")
                return
            }

            // 更新最后活跃时间
            go deviceRepo.UpdateLastSeen(context.Background(), deviceID)

            // 将deviceID注入context
            ctx := context.WithValue(r.Context(), authDeviceIDKey, deviceID)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}
```

### 速率限制

```go
// internal/middleware/ratelimit.go

type RateLimiter struct {
    limits map[string]rate.Limit
    store  map[string]*rate.Limiter
    mu     sync.RWMutex
}

func NewRateLimiter() *RateLimiter {
    return &RateLimiter{
        limits: map[string]rate.Limit{
            "/api/v1/pair/":   rate.Every(6 * time.Second),   // 10/min
            "/api/v1/sync/push": rate.Every(time.Second),     // 60/min
            "/api/v1/sync/pull": rate.Every(2 * time.Second), // 30/min
            "/api/v1/device/": rate.Every(12 * time.Second),  // 5/min
        },
        store: make(map[string]*rate.Limiter),
    }
}

func (rl *RateLimiter) Middleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        deviceID := r.Context().Value(authDeviceIDKey)
        if deviceID == nil {
            next.ServeHTTP(w, r)
            return
        }

        key := fmt.Sprintf("%s:%s", deviceID, matchRoutePrefix(r.URL.Path))
        limiter := rl.getLimiter(key, r.URL.Path)

        if !limiter.Allow() {
            w.Header().Set("Retry-After", "60")
            respondError(w, http.StatusTooManyRequests, "rate limit exceeded")
            return
        }

        next.ServeHTTP(w, r)
    })
}
```

---

## 推送通知

### 推送服务

```go
// internal/service/push_service.go

type PushService struct {
    apnsClient *apns2.Client
    fcmClient  *messaging.Client
    deviceRepo *repository.DeviceRepo
}

// 发送静默推送（不包含任何敏感数据）
func (s *PushService) NotifySyncAvailable(ctx context.Context, deviceID string) error {
    device, err := s.deviceRepo.FindByID(ctx, deviceID)
    if err != nil || device == nil || device.PushToken == nil {
        return fmt.Errorf("device not found or no push token: %s", deviceID)
    }

    switch device.Platform {
    case "ios":
        return s.sendAPNs(ctx, *device.PushToken)
    case "android":
        return s.sendFCM(ctx, *device.PushToken)
    default:
        return fmt.Errorf("unknown platform: %s", device.Platform)
    }
}

func (s *PushService) sendAPNs(ctx context.Context, token string) error {
    notification := &apns2.Notification{
        DeviceToken: token,
        Topic:       "com.homepocket.app",
        Payload: payload.NewPayload().
            ContentAvailable().
            Custom("type", "sync_available"),
    }

    _, err := s.apnsClient.PushWithContext(ctx, notification)
    return err
}

func (s *PushService) sendFCM(ctx context.Context, token string) error {
    message := &messaging.Message{
        Token: token,
        Data: map[string]string{
            "type": "sync_available",
        },
        Android: &messaging.AndroidConfig{
            Priority: "high",
        },
    }

    _, err := s.fcmClient.Send(ctx, message)
    return err
}

// 配对确认推送（对加入方Device B）
// B收到此推送后调用 confirmLocalPair() 将本地状态从 confirming → active
func (s *PushService) NotifyPairConfirmed(ctx context.Context, deviceID string) error {
    device, err := s.deviceRepo.FindByID(ctx, deviceID)
    if err != nil || device == nil || device.PushToken == nil {
        return fmt.Errorf("device not found or no push token: %s", deviceID)
    }

    switch device.Platform {
    case "ios":
        notification := &apns2.Notification{
            DeviceToken: *device.PushToken,
            Topic:       "com.homepocket.app",
            Payload: payload.NewPayload().
                ContentAvailable().
                Custom("type", "pair_confirmed"),
        }
        _, err = s.apnsClient.PushWithContext(ctx, notification)
    case "android":
        message := &messaging.Message{
            Token: *device.PushToken,
            Data: map[string]string{
                "type": "pair_confirmed",
            },
            Android: &messaging.AndroidConfig{
                Priority: "high",
            },
        }
        _, err = s.fcmClient.Send(ctx, message)
    }

    return err
}

// 配对请求推送（对发起方）
func (s *PushService) NotifyPairRequest(ctx context.Context, deviceID, joinerName string) error {
    device, err := s.deviceRepo.FindByID(ctx, deviceID)
    if err != nil || device == nil || device.PushToken == nil {
        return err
    }

    switch device.Platform {
    case "ios":
        notification := &apns2.Notification{
            DeviceToken: *device.PushToken,
            Topic:       "com.homepocket.app",
            Payload: payload.NewPayload().
                AlertTitle("配对请求").
                AlertBody(fmt.Sprintf("%s 想要与你配对", joinerName)).
                Sound("default").
                Custom("type", "pair_request"),
        }
        _, err = s.apnsClient.PushWithContext(ctx, notification)
    case "android":
        message := &messaging.Message{
            Token: *device.PushToken,
            Notification: &messaging.Notification{
                Title: "配对请求",
                Body:  fmt.Sprintf("%s 想要与你配对", joinerName),
            },
            Data: map[string]string{
                "type": "pair_request",
            },
        }
        _, err = s.fcmClient.Send(ctx, message)
    }

    return err
}
```

---

## 后台任务

### 定时清理

```go
// internal/scheduler/cleanup.go

type CleanupScheduler struct {
    pairRepo *repository.PairRepo
    syncRepo *repository.SyncRepo
    deviceRepo *repository.DeviceRepo
    logger   *slog.Logger
}

func (s *CleanupScheduler) Start(ctx context.Context) {
    // 每分钟：过期配对码
    go s.runPeriodically(ctx, 1*time.Minute, s.expirePairCodes)

    // 每小时：过期同步消息
    go s.runPeriodically(ctx, 1*time.Hour, s.deleteExpiredMessages)

    // 每周：清理不活跃设备
    go s.runPeriodically(ctx, 7*24*time.Hour, s.cleanupInactiveDevices)
}

func (s *CleanupScheduler) expirePairCodes(ctx context.Context) {
    count, err := s.pairRepo.ExpirePendingPairs(ctx)
    if err != nil {
        s.logger.Error("failed to expire pair codes", "error", err)
        return
    }
    if count > 0 {
        s.logger.Info("expired pair codes", "count", count)
    }
}

func (s *CleanupScheduler) deleteExpiredMessages(ctx context.Context) {
    count, err := s.syncRepo.DeleteExpired(ctx)
    if err != nil {
        s.logger.Error("failed to delete expired messages", "error", err)
        return
    }
    if count > 0 {
        s.logger.Info("deleted expired sync messages", "count", count)
    }
}

func (s *CleanupScheduler) cleanupInactiveDevices(ctx context.Context) {
    count, err := s.deviceRepo.DeleteInactive(ctx, 90*24*time.Hour)
    if err != nil {
        s.logger.Error("failed to cleanup inactive devices", "error", err)
        return
    }
    if count > 0 {
        s.logger.Info("cleaned up inactive devices", "count", count)
    }
}

func (s *CleanupScheduler) runPeriodically(ctx context.Context, interval time.Duration, fn func(context.Context)) {
    ticker := time.NewTicker(interval)
    defer ticker.Stop()

    // 启动时立即执行一次
    fn(ctx)

    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            fn(ctx)
        }
    }
}
```

---

## 部署方案

### Dockerfile

```dockerfile
# deploy/Dockerfile

FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /relay ./cmd/relay

FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata

COPY --from=builder /relay /usr/local/bin/relay
COPY migrations/ /app/migrations/

EXPOSE 8080

CMD ["relay"]
```

### Docker Compose (开发环境)

```yaml
# deploy/docker-compose.yml

version: '3.9'

services:
  relay:
    build:
      context: ..
      dockerfile: deploy/Dockerfile
    ports:
      - "8080:8080"
    environment:
      DATABASE_URL: postgres://relay:relay@postgres:5432/relay?sslmode=disable
      APNS_KEY_PATH: /secrets/apns-key.p8
      APNS_KEY_ID: ${APNS_KEY_ID}
      APNS_TEAM_ID: ${APNS_TEAM_ID}
      FCM_CREDENTIALS_PATH: /secrets/firebase-credentials.json
      SERVER_PORT: 8080
      LOG_LEVEL: debug
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - ./secrets:/secrets:ro

  postgres:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: relay
      POSTGRES_PASSWORD: relay
      POSTGRES_DB: relay
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U relay"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  pgdata:
```

### 配置

```go
// internal/config/config.go

type Config struct {
    Server   ServerConfig
    Database DatabaseConfig
    APNs     APNsConfig
    FCM      FCMConfig
}

type ServerConfig struct {
    Port     int    `env:"SERVER_PORT" envDefault:"8080"`
    LogLevel string `env:"LOG_LEVEL" envDefault:"info"`
}

type DatabaseConfig struct {
    URL             string `env:"DATABASE_URL,required"`
    MaxOpenConns    int    `env:"DB_MAX_OPEN_CONNS" envDefault:"25"`
    MaxIdleConns    int    `env:"DB_MAX_IDLE_CONNS" envDefault:"5"`
    ConnMaxLifetime int    `env:"DB_CONN_MAX_LIFETIME" envDefault:"300"` // seconds
}

type APNsConfig struct {
    KeyPath  string `env:"APNS_KEY_PATH"`
    KeyID    string `env:"APNS_KEY_ID"`
    TeamID   string `env:"APNS_TEAM_ID"`
    BundleID string `env:"APNS_BUNDLE_ID" envDefault:"com.homepocket.app"`
    IsSandbox bool  `env:"APNS_SANDBOX" envDefault:"true"`
}

type FCMConfig struct {
    CredentialsPath string `env:"FCM_CREDENTIALS_PATH"`
}
```

---

## 监控与运维

### 健康检查

```go
// internal/handler/health_handler.go

type HealthHandler struct {
    db *sql.DB
}

// GET /api/v1/health
func (h *HealthHandler) Check(w http.ResponseWriter, r *http.Request) {
    ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
    defer cancel()

    if err := h.db.PingContext(ctx); err != nil {
        respondJSON(w, http.StatusServiceUnavailable, map[string]string{
            "status":   "unhealthy",
            "database": "unreachable",
        })
        return
    }

    respondJSON(w, http.StatusOK, map[string]interface{}{
        "status":   "healthy",
        "database": "connected",
        "version":  Version,
        "uptime":   time.Since(startTime).String(),
    })
}
```

### 关键指标

| 指标 | 类型 | 告警阈值 |
|------|------|---------|
| API响应时间 P95 | Latency | >500ms |
| 错误率 | Rate | >1% |
| 数据库连接池使用率 | Gauge | >80% |
| sync_messages表行数 | Gauge | >100K |
| 推送送达率 | Rate | <90% |
| 活跃配对数 | Gauge | 监控趋势 |

### 日志格式

```go
// 结构化日志 (JSON)
slog.Info("sync message stored",
    "messageId", msgID,
    "pairId", pairID,
    "fromDevice", fromDeviceID,
    "toDevice", toDeviceID,
    "payloadSize", len(payload),  // 只记录大小，不记录内容
    "operationCount", opCount,
)

// 安全规则：
// ❌ 绝不记录 payload 内容
// ❌ 绝不记录 publicKey 或 signature
// ✅ 只记录 deviceId, pairId, messageId
// ✅ 只记录 payload 大小和操作数量
```

---

## 测试策略

### 单元测试

```go
// internal/service/pair_service_test.go

func TestPairService_CreatePair(t *testing.T) {
    repo := newMockPairRepo()
    svc := service.NewPairService(repo)

    t.Run("generates 6-digit pair code", func(t *testing.T) {
        result, err := svc.CreatePair(context.Background(), "dev-A", CreatePairRequest{
            BookID:     "book-001",
            PublicKey:  "pk-A",
            DeviceName: "Alice's Phone",
        })

        assert.NoError(t, err)
        assert.Len(t, result.PairCode, 6)
        assert.Regexp(t, `^\d{6}$`, result.PairCode)
    })

    t.Run("pair code expires in 10 minutes", func(t *testing.T) {
        result, err := svc.CreatePair(context.Background(), "dev-A", CreatePairRequest{
            BookID: "book-001", PublicKey: "pk-A", DeviceName: "Phone",
        })

        assert.NoError(t, err)
        expectedExpiry := time.Now().Add(10 * time.Minute)
        assert.WithinDuration(t, expectedExpiry, time.Unix(result.ExpiresAt, 0), 5*time.Second)
    })
}

func TestPairService_JoinPair(t *testing.T) {
    repo := newMockPairRepo()
    svc := service.NewPairService(repo)

    t.Run("matches valid pair code", func(t *testing.T) {
        // Create pair first
        createResult, _ := svc.CreatePair(context.Background(), "dev-A", CreatePairRequest{
            BookID: "book-001", PublicKey: "pk-A", DeviceName: "Alice",
        })

        // Join with code
        joinResult, err := svc.JoinPair(context.Background(), "dev-B", JoinPairRequest{
            PairCode: createResult.PairCode, PublicKey: "pk-B", DeviceName: "Bob",
        })

        assert.NoError(t, err)
        assert.Equal(t, "pk-A", joinResult.InitiatorPublicKey)
        assert.Equal(t, "confirming", joinResult.Status)
    })

    t.Run("rejects expired pair code", func(t *testing.T) {
        // Create expired pair in mock
        repo.InsertExpiredPair("123456", "dev-A")

        _, err := svc.JoinPair(context.Background(), "dev-B", JoinPairRequest{
            PairCode: "123456", PublicKey: "pk-B", DeviceName: "Bob",
        })

        assert.ErrorIs(t, err, ErrPairNotFound)
    })
}
```

### 集成测试

```go
// internal/handler/sync_handler_integration_test.go

func TestSyncFlow_PushPullAck(t *testing.T) {
    // Setup: 创建两个已配对的设备
    db := setupTestDB(t)
    defer db.Close()

    deviceA := createTestDevice(t, db, "dev-A", "pk-A")
    deviceB := createTestDevice(t, db, "dev-B", "pk-B")
    pair := createActivePair(t, db, deviceA, deviceB)

    srv := setupTestServer(t, db)

    t.Run("full push-pull-ack cycle", func(t *testing.T) {
        // 1. Device A pushes encrypted data
        pushReq := PushSyncRequest{
            PairID:         pair.PairID.String(),
            TargetDeviceID: "dev-B",
            Payload:        "encrypted-base64-data",
            VectorClock:    map[string]int{"dev-A": 1},
            OperationCount: 1,
        }

        pushResp := doAuthedRequest(t, srv, "POST", "/api/v1/sync/push", pushReq, deviceA)
        assert.Equal(t, 201, pushResp.StatusCode)

        var pushResult PushSyncResponse
        json.NewDecoder(pushResp.Body).Decode(&pushResult)
        assert.NotEmpty(t, pushResult.MessageID)

        // 2. Device B pulls
        pullResp := doAuthedRequest(t, srv, "GET", "/api/v1/sync/pull?since=0", nil, deviceB)
        assert.Equal(t, 200, pullResp.StatusCode)

        var pullResult PullSyncResponse
        json.NewDecoder(pullResp.Body).Decode(&pullResult)
        assert.Len(t, pullResult.Messages, 1)
        assert.Equal(t, "encrypted-base64-data", pullResult.Messages[0].Payload)

        // 3. Device B acknowledges
        ackReq := AckSyncRequest{
            MessageIDs: []string{pullResult.Messages[0].MessageID},
        }
        ackResp := doAuthedRequest(t, srv, "POST", "/api/v1/sync/ack", ackReq, deviceB)
        assert.Equal(t, 200, ackResp.StatusCode)

        var ackResult AckSyncResponse
        json.NewDecoder(ackResp.Body).Decode(&ackResult)
        assert.Equal(t, 1, ackResult.Deleted)

        // 4. Verify message physically deleted
        pullResp2 := doAuthedRequest(t, srv, "GET", "/api/v1/sync/pull?since=0", nil, deviceB)
        var pullResult2 PullSyncResponse
        json.NewDecoder(pullResp2.Body).Decode(&pullResult2)
        assert.Empty(t, pullResult2.Messages)
    })
}
```

### 测试覆盖率目标

| 层 | 覆盖率目标 |
|----|----------|
| Handler | ≥70% |
| Service | ≥85% |
| Repository | ≥80% |
| Auth | ≥90% |
| 整体 | ≥80% |

---

## 未来扩展

### TODO: 消息队列可行性评估

**当前方案 (MVP):** PostgreSQL sync_messages 表作为消息存储和队列。

**未来可选方案:**

| 方案 | 优势 | 劣势 | 评估触发条件 |
|------|------|------|------------|
| Redis Streams | 亚毫秒延迟，内置消费者组，自动裁剪 | 额外基础设施，需要持久化配置 | sync_messages持续>100K行 |
| NATS JetStream | Go原生，轻量，内置持久化和ACK | 多一个服务需要部署和监控 | 推送延迟P95>5s |
| PostgreSQL LISTEN/NOTIFY | 无需新基础设施，可实时通知 | 8KB载荷限制，重连后丢失 | 需要低延迟但不想增加服务 |

**评估指标:**
- sync_messages 表行数趋势
- 消息在表中平均停留时间
- push → pull → ack 全链路延迟
- 数据库 CPU 和 I/O 使用率

**决策原则:** 当前设计正常工作时不改变。过早优化是万恶之源。

---

**文档状态:** 已完成 (v1.0)
**最后更新:** 2026-02-28
**维护者:** 架构团队
