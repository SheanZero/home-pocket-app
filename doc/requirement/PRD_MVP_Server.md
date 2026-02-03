# Home Pocket MVP - Server端总体PRD

**文档版本:** 1.0
**创建日期:** 2026年2月3日
**状态:** Draft
**相关文档:** PRD_MVP_Global.md, PRD_MVP_App.md
**重要说明:** Server端功能为V1.0计划，MVP版本不包含

---

## 目录

1. [Server端架构设计](#1-server端架构设计)
2. [API设计规范](#2-api设计规范)
3. [数据同步协议](#3-数据同步协议)
4. [安全与隐私保护](#4-安全与隐私保护)
5. [部署与运维要求](#5-部署与运维要求)
6. [开发路线图](#6-开发路线图)

---

## 重要声明

**MVP版本（Week 1-12）不包含Server端功能。**

所有同步功能在MVP阶段通过设备间直接通信实现（蓝牙/NFC/本地网络），无需中心化服务器。

**Server端功能将在V1.0版本（Month 4-6）引入，用于:**
- 远程配对（6位短码中继）
- 实时同步推送（WebSocket）
- 照片云存储（S3加密）
- 多设备同步（3+设备）

本文档为V1.0阶段的预先规划，供技术评审和架构设计参考。

---

## 1. Server端架构设计

### 1.1 架构原则

**核心原则:**
1. **Zero-Knowledge Architecture（零知识架构）**
   - 服务器永不接触明文数据
   - 所有数据端到端加密（E2EE）
   - 服务器仅作为"哑中继"（Dumb Relay）

2. **Local-First Amplification（本地优先增强）**
   - 服务器是可选增强，非必需依赖
   - 客户端可随时切换为纯本地模式
   - 即使服务器宕机，用户仍可正常使用

3. **Privacy by Design（隐私设计）**
   - 最小化数据收集
   - 最大化用户控制
   - 可审计的开源服务器代码

4. **Horizontal Scalability（水平扩展）**
   - 无状态设计，易于扩展
   - 使用Redis/NATS实现分布式
   - 支持多区域部署（日本优先）

### 1.2 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        Client Layer                          │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│   │ Device A │  │ Device B │  │ Device C │  │ Device D │   │
│   │ (iOS)    │  │ (Android)│  │ (iOS)    │  │ (Android)│   │
│   └─────┬────┘  └─────┬────┘  └─────┬────┘  └─────┬────┘   │
│         │             │              │              │        │
│         └──────────── TLS 1.3 + E2EE ───────────────┘        │
└─────────────────────────────────────────────────────────────┘
                          ↓↑
┌─────────────────────────────────────────────────────────────┐
│                      Load Balancer                           │
│                  (AWS ALB / Cloudflare)                      │
└─────────────────────────────────────────────────────────────┘
                          ↓↑
┌─────────────────────────────────────────────────────────────┐
│                     API Gateway Layer                        │
│   ┌──────────────────────────────────────────────────────┐  │
│   │  Rate Limiting · Authentication · Logging            │  │
│   └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          ↓↑
┌─────────────────────────────────────────────────────────────┐
│                   Application Services                       │
│  ┌───────────────┐  ┌───────────────┐  ┌─────────────────┐ │
│  │ Relay Service │  │ Photo Storage │  │ Pairing Service │ │
│  │ (WebSocket)   │  │ (S3 Encrypted)│  │ (6-digit codes) │ │
│  └───────────────┘  └───────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                          ↓↑
┌─────────────────────────────────────────────────────────────┐
│                     Data & Cache Layer                       │
│  ┌───────────────┐  ┌───────────────┐  ┌─────────────────┐ │
│  │ Redis         │  │ PostgreSQL    │  │ S3 Bucket       │ │
│  │ (短码/会话)   │  │ (元数据)      │  │ (加密照片)      │ │
│  └───────────────┘  └───────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 技术栈选型

**编程语言与框架:**
```yaml
语言: Rust 1.75+
框架: Actix-web 4.x
理由:
  - 内存安全（防止缓冲区溢出等安全问题）
  - 高性能（C/C++级别，低延迟）
  - 强类型系统（减少运行时错误）
  - 优秀的WebSocket支持
  - 小内存占用（适合容器化部署）
```

**核心依赖:**
```toml
[dependencies]
actix-web = "4.4"
actix-rt = "2.9"
tokio = { version = "1.35", features = ["full"] }
redis = { version = "0.24", features = ["tokio-comp"] }
sqlx = { version = "0.7", features = ["postgres", "runtime-tokio-native-tls"] }
aws-sdk-s3 = "1.10"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
uuid = { version = "1.6", features = ["v4"] }
chrono = "0.4"
ring = "0.17"  # 加密原语
base64 = "0.21"
tracing = "0.1"
tracing-subscriber = "0.3"
```

**数据存储:**
- **Redis 7.x:** 短码缓存、会话管理、Pub/Sub
- **PostgreSQL 15.x:** 元数据存储（用户设备信息、同步记录）
- **AWS S3:** 加密照片存储（日本区域）

**部署平台:**
- **Kubernetes (EKS/GKE):** 容器编排
- **Docker:** 容器化
- **Terraform:** 基础设施即代码
- **GitHub Actions:** CI/CD

### 1.4 服务模块设计

**模块1：Relay Service（中继服务）**
```
功能：转发客户端之间的加密CRDT操作
端点：
  - WebSocket /ws/relay/{book_id}
  - POST /api/v1/relay/send
工作流程：
  1. 客户端连接WebSocket（携带JWT token）
  2. 服务器验证token，加入book_id对应的频道
  3. 客户端发送CRDT操作（已加密）
  4. 服务器原样转发给同频道其他客户端
  5. 不解密、不存储、不修改
```

**模块2：Pairing Service（配对服务）**
```
功能：生成和验证6位配对短码
端点：
  - POST /api/v1/pairing/generate
  - POST /api/v1/pairing/verify
  - POST /api/v1/pairing/exchange
工作流程：
  1. Device A请求生成短码
  2. 服务器生成6位数字（000000-999999）
  3. 存储到Redis（TTL=5分钟）
  4. Device B输入短码验证
  5. 服务器匹配成功后，交换双方公钥
  6. 删除短码
```

**模块3：Photo Storage Service（照片存储服务）**
```
功能：存储客户端上传的加密照片
端点：
  - POST /api/v1/photos/upload
  - GET /api/v1/photos/{photo_id}
  - DELETE /api/v1/photos/{photo_id}
工作流程：
  1. 客户端本地加密照片（AES-GCM）
  2. 上传到S3（通过预签名URL）
  3. 服务器记录元数据（photo_id, book_id, size）
  4. 下载时验证权限，返回预签名URL
  5. 客户端下载后本地解密
```

**模块4：Metadata Service（元数据服务）**
```
功能：存储最小化元数据（不含敏感数据）
数据模型：
  - devices: 设备ID、公钥、最后活跃时间
  - books: 账本ID、创建时间、设备数量
  - sync_records: 同步时间戳、操作数量（不含内容）
端点：
  - GET /api/v1/books/{book_id}/devices
  - GET /api/v1/books/{book_id}/sync_status
```

---

## 2. API设计规范

### 2.1 RESTful API设计原则

**基础URL:**
```
生产环境: https://api.homepocket.app
测试环境: https://api-staging.homepocket.app
```

**版本管理:**
```
路径版本: /api/v1/...
响应头:  API-Version: 1.0
```

**认证方式:**
```
Bearer Token (JWT):
Authorization: Bearer eyJhbGciOiJFZDI1NTE5...

JWT Payload:
{
  "sub": "device-uuid",
  "book_id": "book-uuid",
  "exp": 1706947200,
  "iat": 1706860800
}
```

**标准响应格式:**
```json
// 成功响应
{
  "success": true,
  "data": { ... },
  "meta": {
    "timestamp": 1706860800,
    "request_id": "req-abc123"
  }
}

// 错误响应
{
  "success": false,
  "error": {
    "code": "INVALID_SHORT_CODE",
    "message": "短码已过期或不存在",
    "details": {
      "short_code": "123456",
      "expiry": "2026-02-03T10:30:00Z"
    }
  },
  "meta": {
    "timestamp": 1706860800,
    "request_id": "req-abc123"
  }
}
```

**HTTP状态码规范:**
| 状态码 | 含义 | 使用场景 |
|--------|------|---------|
| 200 | OK | 请求成功 |
| 201 | Created | 资源创建成功 |
| 204 | No Content | 删除成功 |
| 400 | Bad Request | 请求参数错误 |
| 401 | Unauthorized | 未认证 |
| 403 | Forbidden | 无权限 |
| 404 | Not Found | 资源不存在 |
| 409 | Conflict | 资源冲突（如短码已被占用）|
| 429 | Too Many Requests | 超过速率限制 |
| 500 | Internal Server Error | 服务器错误 |
| 503 | Service Unavailable | 服务不可用 |

### 2.2 核心API端点定义

**配对API:**

```http
POST /api/v1/pairing/generate
请求头:
  Authorization: Bearer {device_jwt}

请求体:
{
  "book_id": "book-uuid-123"
}

响应体:
{
  "success": true,
  "data": {
    "short_code": "123456",
    "expires_at": "2026-02-03T10:35:00Z",
    "ttl_seconds": 300
  }
}
```

```http
POST /api/v1/pairing/verify
请求头:
  Authorization: Bearer {device_jwt}

请求体:
{
  "short_code": "123456",
  "public_key": "base64-encoded-ed25519-public-key"
}

响应体:
{
  "success": true,
  "data": {
    "matched": true,
    "peer_public_key": "base64-encoded-peer-public-key",
    "book_id": "book-uuid-123"
  }
}
```

**Relay API:**

```http
WebSocket /ws/relay/{book_id}
连接头:
  Authorization: Bearer {device_jwt}
  Upgrade: websocket

消息格式（JSON）:
{
  "type": "crdt_operation",
  "payload": "base64-encoded-encrypted-data",
  "timestamp": 1706860800,
  "device_id": "device-uuid-123"
}

服务器转发:
{
  "type": "crdt_operation",
  "payload": "base64-encoded-encrypted-data",
  "timestamp": 1706860800,
  "device_id": "device-uuid-456",  // 发送者ID
  "relay_timestamp": 1706860801
}
```

**照片存储API:**

```http
POST /api/v1/photos/upload
请求头:
  Authorization: Bearer {device_jwt}
  Content-Type: multipart/form-data

请求体:
  file: <binary-encrypted-photo>
  metadata: {
    "book_id": "book-uuid-123",
    "transaction_id": "tx-uuid-456",
    "size_bytes": 524288,
    "mime_type": "image/jpeg"
  }

响应体:
{
  "success": true,
  "data": {
    "photo_id": "photo-uuid-789",
    "s3_key": "encrypted/book-123/photo-789.enc",
    "upload_url": "https://s3.ap-northeast-1.amazonaws.com/...",
    "expires_in": 300
  }
}
```

```http
GET /api/v1/photos/{photo_id}
请求头:
  Authorization: Bearer {device_jwt}

响应体:
{
  "success": true,
  "data": {
    "photo_id": "photo-uuid-789",
    "download_url": "https://s3.ap-northeast-1.amazonaws.com/...",
    "expires_in": 300,
    "size_bytes": 524288,
    "created_at": "2026-02-03T10:30:00Z"
  }
}
```

**元数据API:**

```http
GET /api/v1/books/{book_id}/devices
请求头:
  Authorization: Bearer {device_jwt}

响应体:
{
  "success": true,
  "data": {
    "devices": [
      {
        "device_id": "device-uuid-123",
        "public_key": "base64-encoded-key",
        "last_active_at": "2026-02-03T10:30:00Z",
        "is_current": true
      },
      {
        "device_id": "device-uuid-456",
        "public_key": "base64-encoded-key",
        "last_active_at": "2026-02-03T09:15:00Z",
        "is_current": false
      }
    ],
    "total_count": 2
  }
}
```

### 2.3 速率限制

| 端点 | 限制 | 窗口 | 免费用户 | 付费用户 |
|------|------|------|---------|---------|
| POST /pairing/generate | 10次 | 1小时 | ✅ | ✅ |
| WebSocket连接 | 5次 | 10分钟 | ✅ | ✅ |
| POST /photos/upload | 100次 | 1天 | ✅ | ✅ (1000次) |
| GET /photos/{id} | 500次 | 1天 | ✅ | ✅ (无限) |
| POST /relay/send | 1000次 | 1天 | ✅ | ✅ (10000次) |

**超过限制响应:**
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "已超过速率限制，请稍后重试",
    "details": {
      "limit": 100,
      "window": "24h",
      "retry_after": 3600
    }
  }
}

响应头:
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1706864400
Retry-After: 3600
```

---

## 3. 数据同步协议

### 3.1 CRDT集成方案

**选用Yjs CRDT库:**
- 成熟稳定，广泛应用于协同编辑场景
- 支持多种数据结构（Y.Map, Y.Array）
- 自动冲突解决
- 紧凑的二进制格式

**数据模型映射:**
```javascript
// Yjs文档结构
const ydoc = new Y.Doc();

// 交易列表（Y.Array）
const transactions = ydoc.getArray('transactions');

// 每个交易是Y.Map
const transaction = new Y.Map();
transaction.set('id', 'tx-123');
transaction.set('amount', 1280);
transaction.set('category_id', 'food_restaurant');
transaction.set('timestamp', 1706860800);
transaction.set('note', encryptedNote);  // 客户端已加密
transaction.set('current_hash', 'hash-xyz');

transactions.push([transaction]);

// 序列化为二进制
const update = Y.encodeStateAsUpdate(ydoc);
```

**同步流程:**
```
Device A                Relay Server             Device B
   │                         │                        │
   ├── 生成CRDT操作 ──────►│                        │
   │   (Y.encodeUpdate)     │                        │
   │                         │                        │
   │                         ├─ 验证JWT ───────────►│
   │                         │ 转发加密操作            │
   │                         │                        │
   │                         │◄───── ACK ─────────────┤
   │◄───── Broadcast ────────┤                        │
   │   (其他设备的操作)       │                        │
   │                         │                        │
   ├─ 应用CRDT更新           │                        ├─ 应用更新
   │   (Y.applyUpdate)       │                        │   (自动合并)
   │                         │                        │
   └─ 本地数据库持久化       │                        └─ 持久化
```

### 3.2 冲突解决策略

**Yjs自动冲突解决规则:**
1. **Last-Write-Wins（LWW）:** 对于单值字段（如amount），使用时间戳判定
2. **Operation Transformation:** 对于列表操作（插入/删除），自动转换
3. **Causal Consistency:** 保证因果顺序（依赖Lamport时钟）

**特殊业务逻辑冲突:**

**场景1：家庭内部转账的两阶段提交**
```
问题：
  Device A发起转账请求 → Device B离线
  Device A超时未收到ACK → 取消请求
  Device B上线后看到取消的请求 → 冲突

解决方案：
  1. 转账请求生成唯一request_id
  2. 状态机：PENDING → CONFIRMED / REJECTED / EXPIRED
  3. Device B收到PENDING状态的请求：
     - 检查timestamp，如超过24小时 → 自动EXPIRED
     - 如未过期，提示用户确认
  4. CRDT自动同步最终状态
```

**场景2：同一笔消费被两个设备同时记录**
```
问题：
  夫妻同时记录同一笔超市购物
  生成两个不同的transaction ID

解决方案：
  1. 客户端检测相似交易：
     - 同一天（±1小时）
     - 同一商家
     - 同一金额（±5%）
  2. 提示用户："检测到可能重复的交易，是否合并？"
  3. 用户确认后，生成合并操作（保留一个，删除另一个）
  4. 删除操作通过CRDT同步到其他设备
```

### 3.3 离线支持

**离线队列设计:**
```dart
// 客户端离线队列
class OfflineQueue {
  final Database db;

  // 添加到队列
  Future<void> enqueue(CRDTOperation operation) async {
    await db.into(db.offlineQueue).insert(
      OfflineQueueEntry(
        id: uuid.v4(),
        operation: operation.toJson(),
        createdAt: DateTime.now(),
        retryCount: 0,
      ),
    );
  }

  // 重新上线时处理队列
  Future<void> processQueue() async {
    final pending = await (db.select(db.offlineQueue)
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();

    for (final entry in pending) {
      try {
        await _syncService.send(CRDTOperation.fromJson(entry.operation));
        await _deleteEntry(entry.id);
      } catch (e) {
        await _incrementRetryCount(entry.id);
      }
    }
  }
}
```

**冲突检测与通知:**
```dart
// 检测到冲突后的处理
void onConflictDetected(Conflict conflict) {
  // 1. 记录冲突日志
  Logger.log(LogLevel.warning, 'Sync conflict detected', metadata: {
    'conflict_type': conflict.type,
    'local_version': conflict.localVersion,
    'remote_version': conflict.remoteVersion,
  });

  // 2. 自动解决（CRDT算法）
  final resolved = _crdtResolver.resolve(conflict);

  // 3. 通知用户（仅当影响显著时）
  if (conflict.requiresUserAction) {
    _showConflictDialog(
      title: '同步冲突',
      message: '您的设备与伴侣设备数据不一致，已自动合并',
      actions: [
        TextButton('查看详情', onPressed: () => _showConflictDetails(conflict)),
        TextButton('确定', onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  // 4. 应用解决结果
  _applyResolution(resolved);
}
```

---

## 4. 安全与隐私保护

### 4.1 零知识架构实现

**原则：服务器永不接触明文数据**

**加密层级:**
```
客户端                            服务器
  │
  ├─ 明文数据: "吉野家午餐 ¥1,280"
  │
  ├─ 本地加密（ChaCha20）
  │   密钥：从设备密钥派生
  │   ↓
  │   "bGFkamZsa2FqZGZsa2ph..."
  │
  ├─ CRDT封装
  │   ↓
  │   Y.Map { note: "encrypted" }
  │
  ├─ 二进制序列化
  │   ↓
  │   Uint8Array [0x12, 0x34, ...]
  │
  ├─ TLS 1.3传输
  │   ↓
  └─────────► 服务器仅看到加密二进制
                  │
                  ├─ 不解密
                  ├─ 不存储
                  └─ 仅转发给其他设备
```

**服务器日志脱敏:**
```rust
// 日志中移除敏感信息
fn sanitize_log(request: &HttpRequest) -> LogEntry {
    LogEntry {
        method: request.method().to_string(),
        path: request.path().to_string(),
        user_agent: request.headers().get("User-Agent").map(|v| v.to_str().ok()).flatten(),
        // 移除敏感字段
        body: "[REDACTED]".to_string(),
        auth_token: "[REDACTED]".to_string(),
        device_id: hash_id(&extract_device_id(request)),  // 哈希化
    }
}
```

### 4.2 认证与授权

**JWT Token生成（客户端）:**
```dart
class JWTGenerator {
  Future<String> generateToken() async {
    final deviceId = await _getDeviceId();
    final bookId = await _getBookId();
    final privateKey = await _getDevicePrivateKey();

    final claims = {
      'sub': deviceId,
      'book_id': bookId,
      'exp': DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch ~/ 1000,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };

    // 使用Ed25519签名
    final jwt = JWT(claims);
    return jwt.sign(privateKey, algorithm: JWTAlgorithm.Ed25519);
  }
}
```

**JWT验证（服务器）:**
```rust
use jsonwebtoken::{decode, DecodingKey, Validation, Algorithm};

async fn verify_jwt(token: &str) -> Result<Claims, AuthError> {
    // 1. 解析token获取device_id
    let unverified = decode_header(token)?;
    let device_id = unverified.claims.sub;

    // 2. 从数据库获取该设备的公钥
    let public_key = db.get_device_public_key(&device_id).await?;

    // 3. 验证签名
    let validation = Validation::new(Algorithm::EdDSA);
    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_ed_pem(&public_key)?,
        &validation,
    )?;

    // 4. 验证过期时间
    if token_data.claims.exp < current_timestamp() {
        return Err(AuthError::TokenExpired);
    }

    Ok(token_data.claims)
}

#[derive(Deserialize)]
struct Claims {
    sub: String,       // device_id
    book_id: String,
    exp: u64,
    iat: u64,
}
```

**访问控制:**
```rust
// Actix-web中间件：验证设备是否属于该账本
async fn authorize_book_access(
    req: HttpRequest,
    claims: ReqData<Claims>,
    book_id: Path<String>,
) -> Result<HttpResponse, AuthError> {
    // 验证JWT中的book_id与请求的book_id匹配
    if claims.book_id != *book_id {
        return Err(AuthError::Forbidden);
    }

    // 验证设备确实属于该账本
    let is_member = db.is_device_in_book(&claims.sub, &book_id).await?;
    if !is_member {
        return Err(AuthError::Forbidden);
    }

    Ok(HttpResponse::Ok().finish())
}
```

### 4.3 DDoS防护

**速率限制（Rate Limiting）:**
```rust
use actix_web_lab::middleware::RateLimiter;
use redis::Client as RedisClient;

// 基于Redis的分布式速率限制
async fn rate_limit_middleware(
    req: ServiceRequest,
    next: Next<BoxBody>,
) -> Result<ServiceResponse<BoxBody>, Error> {
    let device_id = extract_device_id(&req)?;
    let endpoint = req.path();

    // 从Redis检查速率
    let key = format!("rate_limit:{}:{}", device_id, endpoint);
    let count: u32 = redis.incr(&key, 1).await?;

    if count == 1 {
        redis.expire(&key, 3600).await?;  // 1小时窗口
    }

    let limit = get_rate_limit(endpoint);
    if count > limit {
        return Ok(req.error_response(
            HttpResponse::TooManyRequests()
                .insert_header(("X-RateLimit-Limit", limit.to_string()))
                .insert_header(("X-RateLimit-Remaining", "0"))
                .insert_header(("Retry-After", "3600"))
                .json(ErrorResponse {
                    code: "RATE_LIMIT_EXCEEDED",
                    message: "请求过于频繁",
                })
        ));
    }

    next.call(req).await
}
```

**IP黑名单:**
```rust
// Cloudflare WAF规则
// 规则1：阻止已知恶意IP段
// 规则2：验证Captcha（如短时间内大量请求）
// 规则3：地域限制（仅允许日本、美国、欧盟）

// 应用层额外检查
async fn check_ip_reputation(ip: &IpAddr) -> bool {
    // 查询IP信誉数据库（如AbuseIPDB）
    let reputation = abuse_ipdb.check(ip).await?;
    reputation.abuse_confidence_score < 75  // 阈值
}
```

### 4.4 审计日志

**服务器端审计日志:**
```rust
#[derive(Serialize)]
struct AuditLog {
    timestamp: i64,
    event_type: String,
    device_id_hash: String,  // 哈希化，不存储明文
    book_id_hash: String,
    ip_address: IpAddr,
    user_agent: String,
    action: String,
    result: String,  // "success" | "failed"
    metadata: Option<serde_json::Value>,
}

async fn log_audit_event(
    event_type: &str,
    device_id: &str,
    action: &str,
    result: &str,
    req: &HttpRequest,
) {
    let log = AuditLog {
        timestamp: Utc::now().timestamp(),
        event_type: event_type.to_string(),
        device_id_hash: hash_sha256(device_id),
        book_id_hash: hash_sha256(&extract_book_id(req)),
        ip_address: req.peer_addr().unwrap().ip(),
        user_agent: req.headers().get("User-Agent").and_then(|v| v.to_str().ok()).unwrap_or("unknown"),
        action: action.to_string(),
        result: result.to_string(),
        metadata: None,
    };

    // 写入日志文件（ELK Stack收集）
    tracing::info!(target: "audit", "{}", serde_json::to_string(&log).unwrap());
}

// 使用示例
log_audit_event(
    "pairing",
    &claims.sub,
    "generate_short_code",
    "success",
    &req,
).await;
```

**保留策略:**
- 审计日志保留90天
- 90天后自动删除
- 支持用户请求导出个人相关日志

---

## 5. 部署与运维要求

### 5.1 容器化部署

**Dockerfile:**
```dockerfile
# Stage 1: Builder
FROM rust:1.75-slim as builder
WORKDIR /app

# 安装依赖
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖清单
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf src

# 复制源代码
COPY src ./src
RUN touch src/main.rs && cargo build --release

# Stage 2: Runtime
FROM debian:bookworm-slim
WORKDIR /app

# 安装运行时依赖
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# 从builder复制二进制文件
COPY --from=builder /app/target/release/homepocket-server /app/server

# 非root用户
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1

CMD ["/app/server"]
```

**Kubernetes部署清单:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: homepocket-server
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: homepocket-server
  template:
    metadata:
      labels:
        app: homepocket-server
    spec:
      containers:
      - name: server
        image: homepocket/server:v1.0.0
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: redis-credentials
              key: url
        - name: AWS_REGION
          value: "ap-northeast-1"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: homepocket-server
  namespace: production
spec:
  type: LoadBalancer
  selector:
    app: homepocket-server
  ports:
  - protocol: TCP
    port: 443
    targetPort: 8080
```

### 5.2 基础设施架构（AWS）

**网络拓扑:**
```
Internet
    │
    ▼
┌─────────────────────────────────────┐
│  Cloudflare CDN + WAF               │
│  - DDoS防护                         │
│  - 速率限制                         │
│  - SSL/TLS终止                      │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│  AWS ALB (Application Load Balancer)│
│  - 健康检查                         │
│  - 跨AZ负载均衡                     │
└─────────────────────────────────────┘
    │
    ├───────────┬───────────┐
    ▼           ▼           ▼
┌────────┐  ┌────────┐  ┌────────┐
│ EKS Pod│  │ EKS Pod│  │ EKS Pod│
│ (AZ-a) │  │ (AZ-c) │  │ (AZ-d) │
└────────┘  └────────┘  └────────┘
    │           │           │
    └───────────┴───────────┘
                │
        ┌───────┴───────┐
        ▼               ▼
    ┌────────┐      ┌──────┐
    │RDS (PG)│      │Redis │
    │Multi-AZ│      │Cluster│
    └────────┘      └──────┘
                        │
                        ▼
                    ┌──────┐
                    │  S3  │
                    │Bucket│
                    └──────┘
```

**Terraform配置示例:**
```hcl
# VPC配置
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "homepocket-vpc"
  }
}

# RDS PostgreSQL
resource "aws_db_instance" "postgres" {
  identifier              = "homepocket-db"
  engine                  = "postgres"
  engine_version          = "15.4"
  instance_class          = "db.t4g.small"
  allocated_storage       = 20
  storage_encrypted       = true
  multi_az                = true
  db_name                 = "homepocket"
  username                = var.db_username
  password                = var.db_password
  backup_retention_period = 7
  skip_final_snapshot     = false

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
}

# ElastiCache Redis
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "homepocket-redis"
  replication_group_description = "Redis cluster for session and cache"
  engine                     = "redis"
  engine_version             = "7.0"
  node_type                  = "cache.t4g.micro"
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  subnet_group_name = aws_elasticache_subnet_group.main.name
}

# S3 Bucket（加密照片存储）
resource "aws_s3_bucket" "photos" {
  bucket = "homepocket-photos-prod"

  tags = {
    Name = "homepocket-photos"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "photos" {
  bucket = aws_s3_bucket.photos.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "photos" {
  bucket = aws_s3_bucket.photos.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### 5.3 监控与告警

**Prometheus + Grafana:**
```yaml
# 关键指标
metrics:
  - name: http_requests_total
    type: counter
    labels: [method, endpoint, status]

  - name: http_request_duration_seconds
    type: histogram
    labels: [method, endpoint]
    buckets: [0.01, 0.05, 0.1, 0.5, 1, 5]

  - name: websocket_connections_active
    type: gauge

  - name: sync_operations_total
    type: counter
    labels: [book_id, result]

  - name: database_query_duration_seconds
    type: histogram

  - name: redis_operations_total
    type: counter
    labels: [command, result]
```

**告警规则:**
```yaml
groups:
- name: homepocket_alerts
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "服务器错误率过高"
      description: "5分钟内5xx错误率 > 5%"

  - alert: DatabaseDown
    expr: up{job="postgres"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "数据库不可用"

  - alert: HighLatency
    expr: histogram_quantile(0.95, http_request_duration_seconds_bucket) > 1
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "API响应延迟过高"
      description: "P95延迟 > 1秒"
```

### 5.4 成本估算

**AWS月度成本（基于1,000活跃用户）:**

| 服务 | 规格 | 月费用（USD）| 说明 |
|------|------|------------|------|
| EKS集群 | 1个集群 | $73 | 控制平面 |
| EC2 (EKS节点) | 3 × t3.small | $30 | 计算节点 |
| RDS PostgreSQL | db.t4g.small Multi-AZ | $50 | 数据库 |
| ElastiCache Redis | 2 × cache.t4g.micro | $24 | 缓存 |
| S3存储 | 10GB照片 | $1 | 对象存储 |
| S3请求费用 | 10,000次/月 | $0.5 | API调用 |
| 数据传输 | 50GB/月 | $4.5 | 出站流量 |
| CloudWatch日志 | 5GB/月 | $2.5 | 日志存储 |
| ALB | 1个 | $23 | 负载均衡 |
| **总计** | | **~$208/月** | |

**扩展成本（10,000活跃用户）:**
- EKS节点：6 × t3.medium = $180
- RDS：db.t4g.medium = $120
- Redis：cache.t4g.small = $48
- S3存储：100GB = $2.3
- 数据传输：500GB = $45
- **总计：~$520/月**

---

## 6. 开发路线图

### 6.1 V1.0开发计划（Month 4-6，12周）

**Phase 1：基础设施搭建（Week 1-2）**
- Week 1:
  - Rust项目初始化
  - Docker容器化
  - CI/CD Pipeline（GitHub Actions）
  - AWS账户设置
- Week 2:
  - Terraform基础设施代码
  - RDS/Redis/S3资源创建
  - EKS集群部署
  - 测试环境搭建

**Phase 2：核心服务开发（Week 3-6）**
- Week 3:
  - JWT认证中间件
  - 配对服务（短码生成/验证）
  - 元数据API
- Week 4:
  - WebSocket Relay服务
  - CRDT集成（Yjs）
  - 实时同步测试
- Week 5:
  - 照片上传/下载API
  - S3预签名URL
  - 照片元数据管理
- Week 6:
  - 速率限制中间件
  - 错误处理完善
  - API文档生成（Swagger）

**Phase 3：安全与性能（Week 7-8）**
- Week 7:
  - 安全审计
  - 渗透测试
  - DDoS防护测试
- Week 8:
  - 性能优化
  - 数据库索引优化
  - Redis缓存策略
  - 负载测试（JMeter）

**Phase 4：监控与部署（Week 9-10）**
- Week 9:
  - Prometheus监控
  - Grafana仪表盘
  - 告警规则配置
  - ELK日志收集
- Week 10:
  - 生产环境部署
  - 蓝绿发布测试
  - 灾难恢复演练

**Phase 5：Beta测试与上线（Week 11-12）**
- Week 11:
  - Beta用户接入
  - 监控关键指标
  - Bug修复
- Week 12:
  - 正式上线
  - 文档完善
  - 运维交接

### 6.2 技术债务管理

**已知技术债务:**
1. **CRDT库依赖风险**
   - Yjs主要为JavaScript设计，Rust绑定可能不成熟
   - 备选方案：Automerge（Rust原生）

2. **WebSocket连接管理**
   - 需要处理大量长连接
   - 考虑使用专门的WebSocket网关（如Centrifugo）

3. **数据库迁移策略**
   - 初期版本Schema可能变化频繁
   - 使用sqlx的迁移工具，保证向后兼容

**偿还计划:**
- Q3 2026: 评估Automerge替换Yjs
- Q4 2026: 引入WebSocket网关（如需要）

---

## 7. 附录

### 7.1 API Endpoint完整清单

| 分类 | 方法 | 端点 | 说明 |
|------|------|------|------|
| 配对 | POST | /api/v1/pairing/generate | 生成6位短码 |
| 配对 | POST | /api/v1/pairing/verify | 验证短码 |
| 配对 | POST | /api/v1/pairing/exchange | 交换公钥 |
| 同步 | WS | /ws/relay/{book_id} | WebSocket中继 |
| 同步 | POST | /api/v1/relay/send | 发送CRDT操作 |
| 照片 | POST | /api/v1/photos/upload | 上传照片 |
| 照片 | GET | /api/v1/photos/{id} | 下载照片 |
| 照片 | DELETE | /api/v1/photos/{id} | 删除照片 |
| 元数据 | GET | /api/v1/books/{id}/devices | 获取设备列表 |
| 元数据 | GET | /api/v1/books/{id}/sync_status | 同步状态 |
| 健康检查 | GET | /health | 健康检查 |
| 健康检查 | GET | /ready | 就绪检查 |

### 7.2 错误码完整清单

| 错误码 | HTTP状态 | 说明 |
|--------|---------|------|
| INVALID_TOKEN | 401 | JWT token无效或过期 |
| FORBIDDEN | 403 | 无权限访问资源 |
| INVALID_SHORT_CODE | 400 | 短码格式错误或不存在 |
| SHORT_CODE_EXPIRED | 400 | 短码已过期 |
| RATE_LIMIT_EXCEEDED | 429 | 超过速率限制 |
| BOOK_NOT_FOUND | 404 | 账本不存在 |
| DEVICE_NOT_FOUND | 404 | 设备不存在 |
| PHOTO_NOT_FOUND | 404 | 照片不存在 |
| PHOTO_TOO_LARGE | 400 | 照片超过大小限制（10MB）|
| INTERNAL_ERROR | 500 | 服务器内部错误 |
| DATABASE_ERROR | 500 | 数据库操作失败 |
| S3_ERROR | 500 | S3存储操作失败 |

### 7.3 相关文档

- [PRD_MVP_Global.md](./PRD_MVP_Global.md) - MVP全局需求
- [PRD_MVP_App.md](./PRD_MVP_App.md) - App端需求
- [PRD_Module_FamilySync.md](./PRD_Module_FamilySync.md) - 家庭同步详细设计

---

**文档状态:** Draft
**需要评审:** 后端架构师、DevOps工程师、安全专家
**下一步行动:** 技术选型评审，基础设施成本评估
