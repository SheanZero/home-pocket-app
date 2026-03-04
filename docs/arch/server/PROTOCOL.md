# Home Pocket Server-App 交互协议 v1

## 概述

Home Pocket 采用零知识加密中继架构。服务器仅存储和转发不透明的加密数据（opaque encrypted blobs），不接触明文数据或密钥。Push 通知用于实时通知客户端有新事件，客户端收到通知后通过 API 拉取详细数据。

> **当前状态 vs 目标状态**: 本文档同时描述了当前已实现的行为和计划改进的目标行为。
> 所有标记为 **🔜 待实现** 的内容表示尚未在服务器端实现，需要代码修改后才能生效。
> 未标记的内容反映当前服务器的实际行为。

---

## 1. Push 通知载荷标准

### 1.1 当前状态

当前所有 Push 通知仅包含一个 `type` 字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `type` | string | 事件类型标识符（当前唯一字段） |

### 1.2 目标结构 🔜 待实现

所有 Push 通知载荷应扩展为包含以下字段：

| 字段 | 类型 | 必须 | 说明 |
|------|------|------|------|
| `type` | string | Yes | 事件类型标识符 |
| `groupId` | string (UUID) | Yes | 关联的群组 ID |

### 1.3 事件类型定义

#### `join_request` — 有人申请加入群组

**触发时机**: 设备通过邀请码调用 `POST /group/join` 成功后
**接收方**: 群组 Owner
**通知类型**: Visible（显示通知栏）

**当前载荷** (仅含 `type`):
```json
{"aps": {"alert": {"title": "Join Request", "body": "<deviceID> wants to join your group"}, "sound": "default"}, "type": "join_request"}
```

> **已知问题**: 通知 body 中使用的是 `deviceID`（非人类可读），应改为 `deviceName`。缺少 `groupId`，客户端无法导航到对应群组。

**目标载荷** 🔜 待实现:

| 字段 | 类型 | 说明 |
|------|------|------|
| `type` | string | `"join_request"` |
| `groupId` | string | 群组 UUID |
| `deviceId` | string | 申请者的设备 ID |
| `deviceName` | string | 申请者的设备名称（人类可读） |

APNs:
```json
{
  "aps": {
    "alert": { "title": "加入申请", "body": "iPhone 想要加入你的家庭账本" },
    "sound": "default"
  },
  "type": "join_request",
  "groupId": "550e8400-e29b-41d4-a716-446655440000",
  "deviceId": "device-abc-123",
  "deviceName": "iPhone"
}
```

FCM:
```json
{
  "data": {
    "type": "join_request",
    "groupId": "550e8400-e29b-41d4-a716-446655440000",
    "deviceId": "device-abc-123",
    "deviceName": "iPhone"
  },
  "notification": {
    "title": "加入申请",
    "body": "iPhone 想要加入你的家庭账本"
  }
}
```

**客户端处理**:
1. 显示通知
2. 用户点击通知 → 导航到群组管理页面（当前需调用 `GET /group/{groupId}/status`，待实现后可直接使用推送中的 `groupId`）
3. 显示待确认成员列表

---

#### `member_confirmed` — 加入申请被批准

**触发时机**: Owner 调用 `POST /group/confirm` 成功后
**接收方**: **仅被批准的设备**（不是所有成员）
**通知类型**: Silent（静默推送）

> **注意**: 服务器当前行为 — `member_confirmed` 仅发送给新确认的设备。
> 其他已有的活跃成员收到的是 `sync_available`（而非 `member_confirmed`）。
> 具体逻辑见 `internal/handler/group_handler.go` line 124-134。

**当前载荷**:
```json
{"aps": {"content-available": 1}, "type": "member_confirmed"}
```

**目标载荷** 🔜 待实现:

| 字段 | 类型 | 说明 |
|------|------|------|
| `type` | string | `"member_confirmed"` |
| `groupId` | string | 群组 UUID |

```json
{"aps": {"content-available": 1}, "type": "member_confirmed", "groupId": "550e8400-e29b-41d4-a716-446655440000"}
```

**确认后的推送分发（当前行为）**:
| 接收方 | 推送类型 | 说明 |
|--------|---------|------|
| 被确认的新成员 | `member_confirmed` | 通知其已被批准 |
| 其他活跃成员（非 Owner、非新成员） | `sync_available` | 触发其向新成员推送数据 |
| Owner | 无推送 | Owner 本人发起了确认操作，无需通知 |

**客户端处理（新成员收到 `member_confirmed`）**:
1. 收到静默推送
2. 调用 `GET /group/{groupId}/status` 获取群组完整信息（成员列表、公钥等）
3. 初始化端到端加密通道（用成员公钥）
4. **等待接收全量同步数据**（见 §2.2）

**客户端处理（已有成员收到 `sync_available`）**:
1. 收到静默推送
2. 检测到有新成员加入 → 将当前账本全量数据打包推送（见 §2.2）

---

#### `sync_available` — 有新的同步消息

**触发时机**:
- 设备调用 `POST /sync/push` 存储同步消息后（发给群组内除发送者外的所有活跃成员）
- Owner 确认新成员后（发给其他已有活跃成员，触发全量同步）

**接收方**: 群组内除发送者外的所有活跃成员
**通知类型**: Silent（静默推送）

**当前载荷**:
```json
{"aps": {"content-available": 1}, "type": "sync_available"}
```

**目标载荷** 🔜 待实现:

| 字段 | 类型 | 说明 |
|------|------|------|
| `type` | string | `"sync_available"` |
| `groupId` | string | 群组 UUID |

```json
{"aps": {"content-available": 1}, "type": "sync_available", "groupId": "550e8400-e29b-41d4-a716-446655440000"}
```

**客户端处理**:
1. 收到静默推送
2. 调用 `GET /sync/pull` 拉取待接收消息
3. 解密并处理同步数据
4. 调用 `POST /sync/ack` 确认已处理的消息

---

#### `member_left` — 成员退出群组 🔜 待实现

> **当前状态**: Leave、Remove、Deactivate handler 均不发送任何推送通知。
> 此事件类型需要新增服务器端代码。

**触发时机**: 成员调用 `POST /group/{groupId}/leave` 或被 Owner 通过 `POST /group/{groupId}/remove` 移除后
**接收方**: 群组内所有剩余活跃成员
**通知类型**: Silent（静默推送）

| 字段 | 类型 | 说明 |
|------|------|------|
| `type` | string | `"member_left"` |
| `groupId` | string | 群组 UUID |
| `deviceId` | string | 离开/被移除的设备 ID |
| `deviceName` | string | 离开/被移除的设备名称 |
| `reason` | string | `"left"` 或 `"removed"` |

**客户端处理**:
1. 从本地成员列表中移除该设备
2. 更新 UI
3. 如果 `reason` = `"removed"` 且自己是该设备 → 清理本地群组数据

---

#### `group_dissolved` — 群组解散 🔜 待实现

> **当前状态**: Deactivate handler 不发送任何推送通知。
> 此事件类型需要新增服务器端代码。

**触发时机**: Owner 调用 `DELETE /group/{groupId}` 解散群组后
**接收方**: 群组内除 Owner 外的所有活跃成员
**通知类型**: Silent（静默推送）

| 字段 | 类型 | 说明 |
|------|------|------|
| `type` | string | `"group_dissolved"` |
| `groupId` | string | 群组 UUID |

**客户端处理**:
1. 清理该群组的本地数据
2. 导航回首页或账本选择页

---

## 2. 账单同步协议

### 2.1 同步消息结构

同步消息的 `payload` 是端到端加密的，服务器无法解读。以下定义的是**客户端之间**约定的明文结构（加密前/解密后）：

```json
{
  "syncType": "full | incremental",
  "syncId": "uuid",
  "operations": [
    {
      "op": "create | update | delete",
      "entityType": "bill | category | budget",
      "entityId": "uuid",
      "data": { ... },
      "timestamp": 1709568000000
    }
  ],
  "vectorClock": { "device-a": 5, "device-b": 3 }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `syncType` | string | `"full"` 全量同步，`"incremental"` 增量同步 |
| `syncId` | string | 本次同步的唯一 ID，用于去重 |
| `operations` | array | 操作列表 |
| `operations[].op` | string | 操作类型 |
| `operations[].entityType` | string | 实体类型 |
| `operations[].entityId` | string | 实体唯一 ID |
| `operations[].data` | object | 实体数据（`delete` 操作时可省略） |
| `operations[].timestamp` | number | 操作时间戳（毫秒） |
| `vectorClock` | object | 向量时钟，key 为 deviceId，value 为逻辑计数器 |

### 2.2 全量同步（新成员加入后）

**时序图**（反映当前服务器行为）:

```
Owner                    Server                   Existing Member    New Member
  |                        |                         |                  |
  | POST /group/confirm    |                         |                  |
  |----------------------->|                         |                  |
  |   200 OK               |                         |                  |
  |<-----------------------|                         |                  |
  |                        |  [member_confirmed]      |                  |
  |                        |-------- (不发给Owner) ---|-- silent push -->|
  |                        |  [sync_available]        |                  |
  |                        |------- silent push ----->|                  |
  |                        |                         |                  |
  | POST /sync/push        |                         |                  |
  | syncType: "full"       |                         |                  |
  |----------------------->|                         |   [sync_available]|
  |                        |                         |-- silent push -->|
  |                        |                         |                  |
  |                        |  POST /sync/push         |                  |
  |                        |  syncType: "full"        |                  |
  |                        |<------------------------|   [sync_available]|
  |                        |                         |-- silent push -->|
  |                        |                         |                  |
  |                        |                    GET /sync/pull           |
  |                        |<------------------------------------------|
  |                        |                    messages[]               |
  |                        |------------------------------------------>|
  |                        |                    POST /sync/ack          |
  |                        |<------------------------------------------|
```

**流程说明**:
1. Owner 调用 `POST /group/confirm` 确认新成员
2. 服务器推送分发：
   - **新成员**收到 `member_confirmed` → 获取群组信息、初始化加密通道、等待全量数据
   - **其他已有活跃成员**（非 Owner、非新成员）收到 `sync_available` → 触发全量同步推送
   - **Owner 不收到推送**（由 confirm API 的成功响应驱动）
3. Owner 在确认成功后，将当前账本的**全量数据**打包为 `syncType: "full"` 同步消息推送
4. 其他活跃成员收到 `sync_available` 后，也应推送全量数据给新成员
5. 新成员收到 `sync_available` → 拉取消息 → 解密 → 导入全量数据 → ack
6. 如果全量数据过大，使用 chunking（`chunkIndex` / `totalChunks`）分片发送

### 2.3 增量同步（日常使用）

**时序图**:

```
Device A                 Server                   Device B
  |                        |                         |
  |  [用户记了一笔账]        |                         |
  |                        |                         |
  |  POST /sync/push       |                         |
  |  syncType:"incremental"|                         |
  |  operations: [create]  |                         |
  |----------------------->|                         |
  |                        |   [sync_available]       |
  |                        |------- silent push ----->|
  |                        |                         |
  |                        |   GET /sync/pull         |
  |                        |<------------------------|
  |                        |   messages[]             |
  |                        |------------------------>|
  |                        |                         |
  |                        |   POST /sync/ack         |
  |                        |<------------------------|
```

**增量操作类型**:

| `op` | `entityType` | 说明 |
|------|-------------|------|
| `create` | `bill` | 新增账单 |
| `update` | `bill` | 修改账单（金额、分类、备注等） |
| `delete` | `bill` | 删除账单 |
| `create` | `category` | 新增分类 |
| `update` | `category` | 修改分类 |
| `delete` | `category` | 删除分类 |
| `create` | `budget` | 新增预算 |
| `update` | `budget` | 修改预算 |
| `delete` | `budget` | 删除预算 |

### 2.4 冲突解决

使用 **Vector Clock + Last-Writer-Wins (LWW)** 策略：

1. 每个设备维护本地向量时钟
2. 每次操作递增自己的计数器
3. 收到远端操作时比较向量时钟：
   - 如果远端时钟严格大于本地 → 直接应用
   - 如果本地时钟严格大于远端 → 忽略（已过时）
   - 如果并发（互不可比） → 使用 `timestamp` 较大的版本（LWW）

---

## 3. 退出群组 & 数据清理

### 3.1 成员主动退出

> **当前状态**: Leave handler 不发送任何推送。`member_left` 推送为计划功能（🔜 待实现）。

**当前行为**: 成员调用 Leave → 服务器返回 200 → 无推送。其他成员需主动查询才能发现成员变化。

**目标行为** 🔜:
```
Member                   Server                   Other Members
  |                        |                         |
  |  POST /group/{id}/leave|                         |
  |----------------------->|                         |
  |   200 OK               |   [member_left]          |
  |<-----------------------|------- silent push ----->|
  |                        |                         |
  | [清理本地群组数据]       |                         |
  | [保留个人账单数据]       |  [从成员列表移除该设备]    |
```

**客户端处理（退出方）**:
1. 调用 `POST /group/{groupId}/leave`
2. 收到成功响应后：
   - 清除该群组的同步状态（向量时钟、pending 消息等）
   - **保留**本地账单数据（数据归个人所有）
   - 移除群组关联的加密密钥
   - UI 回退到个人账本模式

**客户端处理（剩余成员）**:
1. 收到 `member_left` 推送
2. 从本地成员列表移除该设备
3. 该成员之前同步的账单数据**保留**在本地（已解密存储）
4. 不再向该设备发送同步消息（服务器端已处理）

### 3.2 Owner 移除成员

> **当前状态**: Remove handler 不发送任何推送。`member_left` 推送为计划功能（🔜 待实现）。

**目标行为** 🔜:
```
Owner                    Server                   Removed Member  Other Members
  |                        |                         |               |
  |POST /group/{id}/remove |                         |               |
  |  { deviceId: "xxx" }   |                         |               |
  |----------------------->|   [member_left]          |               |
  |   200 OK               |   reason:"removed"      |               |
  |<-----------------------|------silent push-------->|               |
  |                        |------silent push---------------------------->|
  |                        |                         |               |
```

### 3.3 Owner 解散群组

> **当前状态**: Deactivate handler 不发送任何推送。`group_dissolved` 推送为计划功能（🔜 待实现）。

**目标行为** 🔜:
```
Owner                    Server                   All Members
  |                        |                         |
  |DELETE /group/{id}      |                         |
  |----------------------->|   [group_dissolved]      |
  |   200 OK               |------- silent push ----->|
  |<-----------------------|                         |
  |                        |                         |
  | [清理群组数据]           |  [清理群组数据]           |
  | [保留个人账单数据]       |  [保留个人账单数据]       |
```

### 3.4 退出后的账单删除同步

如果成员退出前需要删除自己在群组中的账单数据：

```
Member                   Server                   Other Members
  |                        |                         |
  |  POST /sync/push       |                         |
  |  operations: [          |                         |
  |    {op:"delete",        |                         |
  |     entityType:"bill",  |                         |
  |     entityId:"xxx"}     |                         |
  |  ]                     |                         |
  |----------------------->|   [sync_available]       |
  |                        |------- silent push ----->|
  |                        |                         |
  |  POST /group/{id}/leave|                         |
  |----------------------->|   [member_left] 🔜       |
  |   200 OK               |------- silent push ----->|
  |<-----------------------|                         |
```

**注意**: 删除同步消息必须在退出群组**之前**发送，因为退出后将无法向群组发送消息。

---

## 4. API 端点总览

### 4.1 设备管理

| Method | Path | Auth | 说明 |
|--------|------|------|------|
| POST | `/api/v1/device/register` | No | 注册设备 |
| PUT | `/api/v1/device/push-token` | Ed25519 | 更新推送令牌 |

### 4.2 群组管理

| Method | Path | Auth | 说明 |
|--------|------|------|------|
| POST | `/api/v1/group/create` | Ed25519 | 创建群组 |
| POST | `/api/v1/group/join` | Ed25519 | 加入群组 |
| POST | `/api/v1/group/confirm` | Ed25519 | 确认成员（Owner） |
| GET | `/api/v1/group/{groupId}/status` | Ed25519 | 查询群组状态 |
| DELETE | `/api/v1/group/{groupId}` | Ed25519 | 解散群组（Owner） |
| POST | `/api/v1/group/{groupId}/leave` | Ed25519 | 退出群组 |
| POST | `/api/v1/group/{groupId}/remove` | Ed25519 | 移除成员（Owner） |
| POST | `/api/v1/group/{groupId}/invite` | Ed25519 | 重新生成邀请码（Owner） |

### 4.3 数据同步

| Method | Path | Auth | 说明 |
|--------|------|------|------|
| POST | `/api/v1/sync/push` | Ed25519 | 推送同步消息 |
| GET | `/api/v1/sync/pull?since=` | Ed25519 | 拉取同步消息 |
| POST | `/api/v1/sync/ack` | Ed25519 | 确认同步消息 |

### 4.4 监控

| Method | Path | Auth | 说明 |
|--------|------|------|------|
| GET | `/api/v1/health` | No | 健康检查 |
| GET | `/api/v1/push/stats` | No | 推送统计（调试/监控用，返回最近推送记录和统计） |

---

## 5. 认证协议

### 5.1 Ed25519 签名

**Header 格式**: `Authorization: Ed25519 <deviceId>:<timestamp>:<signature>`

- `deviceId`: 设备唯一标识
- `timestamp`: Unix 秒级时间戳，服务器允许 ±300 秒偏差
- `signature`: 对签名消息的 Ed25519 签名（base64 编码）

**签名消息构造**:

```
<method>:<path>:<timestamp>:<SHA256(body)>
```

- `method`: HTTP 方法大写（`GET`, `POST`, `PUT`, `DELETE`）
- `path`: 请求路径（如 `/api/v1/sync/push`）
- `timestamp`: 与 Header 中相同的时间戳
- `SHA256(body)`: 请求 body 的 SHA-256 哈希（十六进制小写）。GET 等无 body 的请求使用空字节的 SHA-256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`

**示例**（Go）:
```go
bodyHash := sha256.Sum256(body)
message := fmt.Sprintf("%s:%s:%s:%x", method, path, timestamp, bodyHash)
signature := ed25519.Sign(privateKey, []byte(message))
```

> 参见 `internal/auth/ed25519_verifier.go` 中的 `ConstructMessage()` 函数。

### 5.2 设备注册

设备首次使用时：
1. 本地生成 Ed25519 密钥对
2. 调用 `POST /device/register` 提交公钥
3. 公钥一旦注册**不可更改**（安全约束）
4. 后续所有请求使用私钥签名

---

## 6. 需要服务器端修改的内容

### 6.1 Push 通知载荷增强

**当前状态**: 所有推送仅包含 `{"type": "<pushType>"}`
**需要改为**: 包含 `groupId` 及其他上下文字段

需要修改的接口：

```go
// 当前
type PushNotifier interface {
    SendSilentPush(ctx context.Context, token, platform, pushType string) error
    SendVisiblePush(ctx context.Context, token, platform, title, body, pushType string) error
}

// 建议改为
type PushNotifier interface {
    SendPush(ctx context.Context, req PushRequest) error
}

type PushRequest struct {
    Token      string
    Platform   string
    PushType   string
    Silent     bool
    Title      string            // 仅 visible push
    Body       string            // 仅 visible push
    ExtraData  map[string]string // groupId, deviceId, deviceName, reason 等
}
```

### 6.2 新增推送事件

- `member_left`: 在 Leave 和 Remove handler 中触发
- `group_dissolved`: 在 Deactivate handler 中触发

### 6.3 join_request 修正

当前使用 `deviceID` 作为通知内容中的名称，应改为使用 `deviceName`。

---

## 7. REST API 详细定义

所有请求和响应均为 JSON 格式（`Content-Type: application/json`）。
标注 "Auth: Ed25519" 的端点需要携带签名 Header（见 §5.1）。
错误响应统一格式：`{"error": "<message>"}`。

---

### 7.1 设备管理

#### `POST /api/v1/device/register` — 注册设备

注册新设备或更新已有设备信息。公钥一旦注册不可更改。

**Auth**: 无（公开端点，受 IP 级速率限制）

**Request Body**:

| 字段 | 类型 | 必须 | 说明 |
|------|------|------|------|
| `deviceId` | string | Yes | 设备唯一标识 |
| `publicKey` | string | Yes | Ed25519 公钥（base64 编码） |
| `deviceName` | string | Yes | 设备名称（人类可读，如 "iPhone 15"） |
| `platform` | string | Yes | `"ios"` 或 `"android"` |

```json
{
  "deviceId": "device-abc-123",
  "publicKey": "MCowBQYDK2VwAyEA...",
  "deviceName": "iPhone 15",
  "platform": "ios"
}
```

**Response (201 Created)** — 新设备注册成功:
**Response (200 OK)** — 已有设备（相同公钥）更新成功:

| 字段 | 类型 | 说明 |
|------|------|------|
| `deviceId` | string | 设备 ID |
| `deviceName` | string | 设备名称 |
| `platform` | string | 平台 |
| `created` | boolean | `true` 为新注册，`false` 为已有设备更新 |

```json
{
  "deviceId": "device-abc-123",
  "deviceName": "iPhone 15",
  "platform": "ios",
  "created": true
}
```

**Error Responses**:

| Status | 条件 |
|--------|------|
| 400 | 缺少必填字段，或 `platform` 不是 `"ios"` / `"android"` |
| 409 | 该 `deviceId` 已注册了不同的公钥（`public key mismatch for existing device`） |

---

#### `PUT /api/v1/device/push-token` — 更新推送令牌

**Auth**: Ed25519

**Request Body**:

| 字段 | 类型 | 必须 | 说明 |
|------|------|------|------|
| `pushToken` | string | Yes | APNs 或 FCM 推送令牌 |
| `pushPlatform` | string | Yes | `"apns"` 或 `"fcm"` |

```json
{
  "pushToken": "abc123def456...",
  "pushPlatform": "apns"
}
```

**Response (200 OK)**:

```json
{
  "status": "ok"
}
```

**Error Responses**:

| Status | 条件 |
|--------|------|
| 400 | 缺少必填字段，或 `pushPlatform` 不是 `"apns"` / `"fcm"` |
| 401 | 签名验证失败 |

---

### 7.2 群组管理

#### `POST /api/v1/group/create` — 创建群组

创建一个新群组，调用者自动成为 Owner。同时生成一个 6 位数邀请码。

**Auth**: Ed25519

**Request Body**:

| 字段 | 类型 | 必须 | 说明 |
|------|------|------|------|
| `bookId` | string | Yes | 关联的账本 ID |

```json
{
  "bookId": "book-xyz-789"
}
```

**Response (201 Created)**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `groupId` | string (UUID) | 群组 ID |
| `bookId` | string | 账本 ID |
| `inviteCode` | string | 6 位数邀请码 |
| `expiresAt` | number (Unix timestamp) | 邀请码过期时间 |

```json
{
  "groupId": "550e8400-e29b-41d4-a716-446655440000",
  "bookId": "book-xyz-789",
  "inviteCode": "123456",
  "expiresAt": 1709654400
}
```

**Error Responses**:

| Status | 条件 |
|--------|------|
| 400 | 缺少 `bookId` |
| 401 | 签名验证失败 |

---

#### `POST /api/v1/group/join` — 加入群组

通过邀请码申请加入群组。成功后 member 状态为 `"pending"`，需要 Owner 确认。

**Auth**: Ed25519

**Request Body**:

| 字段 | 类型 | 必须 | 说明 |
|------|------|------|------|
| `inviteCode` | string | Yes | 6 位数邀请码 |

```json
{
  "inviteCode": "123456"
}
```

**Response (200 OK)**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `groupId` | string (UUID) | 群组 ID |
| `bookId` | string | 账本 ID |
| `deviceName` | string | 加入者自己的设备名称 |
| `members` | MemberInfo[] | 当前活跃成员列表 |

```json
{
  "groupId": "550e8400-e29b-41d4-a716-446655440000",
  "bookId": "book-xyz-789",
  "deviceName": "iPhone 15",
  "members": [
    {
      "deviceId": "device-owner-001",
      "publicKey": "MCowBQYDK2VwAyEA...",
      "deviceName": "iPad Pro",
      "role": "owner",
      "status": "active"
    }
  ]
}
```

**Side Effect**: 向群组 Owner 发送 `join_request` 推送通知。

**Error Responses**:

| Status | 条件 |
|--------|------|
| 400 | 缺少 `inviteCode` |
| 401 | 签名验证失败 |
| 404 | 邀请码不存在或已过期 |
| 409 | 该设备已是群组成员；或群组已满 |

---

#### `POST /api/v1/group/confirm` — 确认成员加入

Owner 批准一个 pending 状态的成员加入群组。

**Auth**: Ed25519（必须是群组 Owner）

**Request Body**:

| 字段 | 类型 | 必须 | 说明 |
|------|------|------|------|
| `groupId` | string (UUID) | Yes | 群组 ID |
| `deviceId` | string | Yes | 要确认的设备 ID |

```json
{
  "groupId": "550e8400-e29b-41d4-a716-446655440000",
  "deviceId": "device-new-member"
}
```

**Response (200 OK)**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `status` | string | 确认后的状态（`"active"`） |
| `memberPublicKey` | string | 被确认成员的公钥 |
| `memberDeviceName` | string | 被确认成员的设备名称 |

```json
{
  "status": "active",
  "memberPublicKey": "MCowBQYDK2VwAyEA...",
  "memberDeviceName": "iPhone 15"
}
```

**Side Effects**:
- 向被确认的成员发送 `member_confirmed` 静默推送
- 向其他活跃成员（非 Owner、非新成员）发送 `sync_available` 静默推送

**Error Responses**:

| Status | 条件 |
|--------|------|
| 400 | 缺少 `groupId` 或 `deviceId` |
| 401 | 签名验证失败 |
| 403 | 调用者不是群组 Owner |
| 404 | 群组不存在；或该成员不在群组中 |
| 409 | 该成员不是 `"pending"` 状态（已确认或已移除） |

---

#### `GET /api/v1/group/{groupId}/status` — 查询群组状态

获取群组详细信息，包括所有成员列表。

**Auth**: Ed25519（必须是群组成员且状态非 `"removed"`）

**Path Params**:

| 参数 | 类型 | 说明 |
|------|------|------|
| `groupId` | string (UUID) | 群组 ID |

**Response (200 OK)**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `groupId` | string (UUID) | 群组 ID |
| `bookId` | string | 账本 ID |
| `status` | string | 群组状态（`"active"` / `"inactive"`） |
| `inviteCode` | string? | 当前邀请码（仅群组活跃时返回） |
| `inviteExpiresAt` | number? | 邀请码过期时间（Unix timestamp） |
| `members` | MemberInfo[] | 所有成员列表 |

```json
{
  "groupId": "550e8400-e29b-41d4-a716-446655440000",
  "bookId": "book-xyz-789",
  "status": "active",
  "inviteCode": "123456",
  "inviteExpiresAt": 1709654400,
  "members": [
    {
      "deviceId": "device-owner-001",
      "publicKey": "MCowBQYDK2VwAyEA...",
      "deviceName": "iPad Pro",
      "role": "owner",
      "status": "active"
    },
    {
      "deviceId": "device-member-002",
      "publicKey": "MCowBQYDK2VwAyEB...",
      "deviceName": "iPhone 15",
      "role": "member",
      "status": "active"
    }
  ]
}
```

**MemberInfo 字段说明**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `deviceId` | string | 设备 ID |
| `publicKey` | string | Ed25519 公钥 |
| `deviceName` | string | 设备名称 |
| `role` | string | `"owner"` 或 `"member"` |
| `status` | string | `"active"` / `"pending"` / `"removed"` |

**Error Responses**:

| Status | 条件 |
|--------|------|
| 400 | `groupId` 格式无效 |
| 401 | 签名验证失败 |
| 403 | 调用者不是群组成员，或状态为 `"removed"` |
| 404 | 群组不存在 |

---

#### `DELETE /api/v1/group/{groupId}` — 解散群组

Owner 解散群组。群组状态变为 `"inactive"`，所有成员状态变为 `"removed"`。

**Auth**: Ed25519（必须是群组 Owner）

**Path Params**:

| 参数 | 类型 | 说明 |
|------|------|------|
| `groupId` | string (UUID) | 群组 ID |

**Response (200 OK)**:

```json
{
  "status": "inactive"
}
```

**Side Effect**: 向所有活跃成员（除 Owner 外）发送 `group_dissolved` 静默推送。

**Error Responses**:

| Status | 条件 |
|--------|------|
| 400 | `groupId` 格式无效 |
| 401 | 签名验证失败 |
| 403 | 调用者不是群组 Owner |
| 404 | 群组不存在 |

---

#### `POST /api/v1/group/{groupId}/leave` — 退出群组

成员主动退出群组。Owner 不能退出，必须使用解散。

**Auth**: Ed25519

**Path Params**:

| 参数 | 类型 | 说明 |
|------|------|------|
| `groupId` | string (UUID) | 群组 ID |

**Request Body**: 无

**Response (200 OK)**:

```json
{
  "status": "removed"
}
```

**Side Effect**: 向群组内所有其他活跃成员发送 `member_left` 推送（`reason: "left"`）。

**Error Responses**:

| Status | 条件 |
|--------|------|
| 400 | `groupId` 格式无效；或调用者是 Owner（`owner cannot leave, deactivate group instead`） |
| 401 | 签名验证失败 |
| 404 | 群组不存在 |

---

#### `POST /api/v1/group/{groupId}/remove` — 移除成员

Owner 将指定成员从群组中移除。

**Auth**: Ed25519（必须是群组 Owner）

**Path Params**:

| 参数 | 类型 | 说明 |
|------|------|------|
| `groupId` | string (UUID) | 群组 ID |

**Request Body**:

| 字段 | 类型 | 必须 | 说明 |
|------|------|------|------|
| `deviceId` | string | Yes | 要移除的设备 ID |

```json
{
  "deviceId": "device-member-002"
}
```

**Response (200 OK)**:

```json
{
  "status": "removed"
}
```

**Side Effect**: 向所有活跃成员（含被移除者，除 Owner 外）发送 `member_left` 推送（`reason: "removed"`）。

**Error Responses**:

| Status | 条件 |
|--------|------|
| 400 | 缺少 `deviceId`；或尝试移除 Owner 自己 |
| 401 | 签名验证失败 |
| 403 | 调用者不是群组 Owner |

---

#### `POST /api/v1/group/{groupId}/invite` — 重新生成邀请码

Owner 生成新的邀请码，旧邀请码立即失效。

**Auth**: Ed25519（必须是群组 Owner）

**Path Params**:

| 参数 | 类型 | 说明 |
|------|------|------|
| `groupId` | string (UUID) | 群组 ID |

**Request Body**: 无

**Response (200 OK)**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `inviteCode` | string | 新的 6 位数邀请码 |
| `expiresAt` | number (Unix timestamp) | 新邀请码过期时间 |

```json
{
  "inviteCode": "654321",
  "expiresAt": 1709654400
}
```

**Error Responses**:

| Status | 条件 |
|--------|------|
| 400 | `groupId` 格式无效 |
| 401 | 签名验证失败 |
| 403 | 调用者不是群组 Owner |
| 404 | 群组不存在 |

---

### 7.3 数据同步

#### `POST /api/v1/sync/push` — 推送同步消息

向群组内其他活跃成员推送加密的同步消息。服务器不解析 payload 内容。

**Auth**: Ed25519

**Request Body**:

| 字段 | 类型 | 必须 | 说明 |
|------|------|------|------|
| `groupId` | string (UUID) | Yes | 群组 ID |
| `payload` | string | Yes | 加密后的同步数据（base64 编码） |
| `vectorClock` | object | No | 向量时钟，key 为 deviceId，value 为逻辑计数器 |
| `operationCount` | number | No | 操作数量 |
| `chunkIndex` | number | No | 分片索引（从 0 开始） |
| `totalChunks` | number | No | 总分片数（0 或 1 表示不分片） |

```json
{
  "groupId": "550e8400-e29b-41d4-a716-446655440000",
  "payload": "eyJzeW5jVHlwZSI6Imlu...",
  "vectorClock": {"device-a": 5, "device-b": 3},
  "operationCount": 2,
  "chunkIndex": 0,
  "totalChunks": 1
}
```

**Response (200 OK)**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `recipientCount` | number | 消息接收者数量（不含发送者） |

```json
{
  "recipientCount": 2
}
```

**Side Effect**: 向每个接收者发送 `sync_available` 静默推送。

**Error Responses**:

| Status | 条件 |
|--------|------|
| 400 | 缺少 `groupId` 或 `payload`；`groupId` 格式无效 |
| 401 | 签名验证失败 |
| 403 | 调用者不是该群组的活跃成员 |

---

#### `GET /api/v1/sync/pull` — 拉取同步消息

拉取当前设备所有待接收的同步消息。

**Auth**: Ed25519

**Query Params**:

| 参数 | 类型 | 必须 | 说明 |
|------|------|------|------|
| `since` | string (ISO 8601) | No | 只返回此时间之后的消息。省略则返回所有待接收消息 |

示例: `GET /api/v1/sync/pull?since=2024-03-01T00:00:00Z`

**Response (200 OK)**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `messages` | SyncMessage[] | 消息列表（空数组表示无待接收消息） |

**SyncMessage 字段**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `messageId` | string (UUID) | 消息唯一 ID，用于 ack |
| `fromDeviceId` | string | 发送方设备 ID |
| `payload` | string | 加密的同步数据（base64 编码） |
| `vectorClock` | object | 向量时钟 |
| `operationCount` | number | 操作数量 |
| `chunkIndex` | number | 分片索引 |
| `totalChunks` | number | 总分片数 |
| `createdAt` | string (ISO 8601) | 消息创建时间 |

```json
{
  "messages": [
    {
      "messageId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "fromDeviceId": "device-abc-123",
      "payload": "eyJzeW5jVHlwZSI6Imlu...",
      "vectorClock": {"device-a": 5},
      "operationCount": 1,
      "chunkIndex": 0,
      "totalChunks": 1,
      "createdAt": "2024-03-01T12:00:00Z"
    }
  ]
}
```

**Error Responses**:

| Status | 条件 |
|--------|------|
| 401 | 签名验证失败 |

---

#### `POST /api/v1/sync/ack` — 确认同步消息

确认已处理的消息。消息被确认后将从服务器物理删除。

**Auth**: Ed25519

**Request Body**:

| 字段 | 类型 | 必须 | 说明 |
|------|------|------|------|
| `messageIds` | string[] | Yes | 要确认的消息 ID 列表（不能为空） |

```json
{
  "messageIds": [
    "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "b2c3d4e5-f6a7-8901-bcde-f12345678901"
  ]
}
```

**Response (200 OK)**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `deleted` | number | 实际删除的消息数量 |

```json
{
  "deleted": 2
}
```

**Error Responses**:

| Status | 条件 |
|--------|------|
| 400 | 缺少 `messageIds` 或数组为空 |
| 401 | 签名验证失败 |

---

### 7.4 监控端点

#### `GET /api/v1/health` — 健康检查

**Auth**: 无

**Response (200 OK)** — 服务正常:

```json
{
  "status": "healthy",
  "database": "connected",
  "version": "1.0.0",
  "uptime": "2h30m15s"
}
```

**Response (503 Service Unavailable)** — 数据库不可用:

```json
{
  "status": "unhealthy",
  "database": "unreachable"
}
```

---

#### `GET /api/v1/push/stats` — 推送统计

返回推送通知的统计信息和最近记录，用于调试和监控。

**Auth**: 无

**Response (200 OK)**:

```json
{
  "byPlatform": {
    "apns": {"sent": 100, "failed": 2},
    "fcm": {"sent": 50, "failed": 1}
  },
  "byType": {
    "join_request": {"sent": 10, "failed": 0},
    "member_confirmed": {"sent": 8, "failed": 0},
    "sync_available": {"sent": 120, "failed": 3},
    "member_left": {"sent": 5, "failed": 0},
    "group_dissolved": {"sent": 2, "failed": 0}
  },
  "recent": [
    {
      "time": "2024-03-01T12:00:00Z",
      "deviceId": "device-abc-123",
      "platform": "apns",
      "pushType": "sync_available",
      "success": true,
      "error": ""
    }
  ]
}
```
