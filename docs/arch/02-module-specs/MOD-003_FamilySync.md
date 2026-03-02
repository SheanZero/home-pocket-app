# MOD-003: 家庭同步 - 技术设计文档

**模块编号:** MOD-003
**模块名称:** 家庭同步
**文档版本:** 3.0
**创建日期:** 2026-02-03
**最后更新:** 2026-02-28
**预估工时:** 15天（客户端10天 + 服务器5天）
**优先级:** P0 (MVP核心功能)
**依赖项:** MOD-006 (安全模块), MOD-001 (基础记账)

---

## 📋 目录

1. [模块概述](#模块概述)
2. [架构变更说明](#架构变更说明)
3. [功能需求](#功能需求)
4. [技术设计](#技术设计)
5. [配对流程](#配对流程)
6. [同步流程](#同步流程)
7. [数据模型](#数据模型)
8. [安全设计](#安全设计)
9. [客户端架构](#客户端架构)
10. [UI组件设计](#ui组件设计)
11. [测试策略](#测试策略)
12. [性能优化](#性能优化)

---

## 模块概述

### 业务价值

家庭同步模块实现设备间的安全数据同步，通过轻量级服务器中转：

- **设备配对 (B01):** 服务器中转配对，支持二维码和6位短码（远程配对）
- **数据同步 (B03):** 服务器中转同步、CRDT冲突解决、离线队列
- **内部转账 (B05):** 两阶段提交的伙伴间转账
- **隐私保护:** 端到端加密(E2EE)、零知识服务器、灵魂账本详情隐藏
- **同步协议:** 基于CRDT的Yjs库 + Vector Clock

### v3.0 架构变更

**从P2P改为服务器中转架构：**

| 方面 | v2.0 (P2P) | v3.0 (Server Relay) |
|------|-----------|-------------------|
| 配对方式 | 面对面QR码 | 远程QR码 + 6位短码 |
| 同步方式 | BLE/NFC/WiFi Direct | HTTP REST + APNs/FCM |
| 服务器依赖 | 无 | 轻量级Go中转服务器 |
| 隐私级别 | 最高（无服务器） | 极高（E2EE零知识） |
| 可靠性 | 依赖蓝牙信号 | 高（标准HTTP） |
| 同步时机 | 两台设备必须在附近 | 异步，随时可同步 |

### 核心技术栈

```yaml
# 客户端
CRDT库: yjs (通过y-crdt Rust绑定)
加密: X25519-XSalsa20-Poly1305 (NaCl box E2EE)
认证: Ed25519 设备密钥签名
HTTP客户端: dio / http
推送: firebase_messaging (FCM) + APNs
状态管理: Riverpod 2.4+

# 服务器
语言: Go 1.22+
数据库: PostgreSQL 16
推送服务: APNs + FCM
部署: Docker / Cloud Run
域名: sync.happypocket.app (prod) / dev-sync.happypocket.app (dev)
```

---

## 架构变更说明

### 为什么从P2P改为服务器中转？

1. **配对便利性:** P2P要求两台设备在同一现场，服务器中转支持远程配对
2. **同步可靠性:** BLE/NFC连接不稳定，HTTP REST更可靠
3. **异步同步:** P2P要求设备同时在线，服务器中转支持异步
4. **实现复杂度:** BLE/NFC协议处理比标准HTTP复杂得多
5. **隐私保证:** 通过E2EE实现零知识服务器，隐私不妥协

### 服务器角色定义

```
服务器 = "盲中转站"
─────────────────────────────────────────
✅ 存储加密的数据块（无法解密）
✅ 中转数据到目标设备
✅ 发送推送通知
✅ 管理配对关系
✅ ACK后物理删除数据

❌ 解析帐单内容
❌ 合并或解决冲突
❌ 验证操作内容
❌ 维护Vector Clock状态
❌ 存储任何明文财务数据
```

---

## 功能需求

### FR-001: 设备配对

**用户故事:** 作为用户，我希望通过QR码或短码与伴侣安全配对设备。

**验收标准:**
- ✅ 生成包含配对码的QR码和6位短码
- ✅ 扫描QR码或输入短码完成配对
- ✅ 支持远程配对（不需要面对面）
- ✅ 配对码10分钟过期
- ✅ 配对过程中交换公钥（通过服务器中转）
- ✅ 配对需要发起方确认

### FR-002: 数据同步

**用户故事:** 作为用户，我希望帐单自动同步到伴侣设备。

**验收标准:**
- ✅ 新增/修改帐单时主动推送到服务器
- ✅ 打开App时自动拉取最新同步数据
- ✅ 收到推送通知时后台拉取
- ✅ 离线操作排队，恢复网络后自动推送
- ✅ 端到端加密，服务器无法解密
- ✅ 服务器ACK后物理删除数据
- ✅ CRDT保证并发编辑零数据丢失

### FR-003: 内部转账

**用户故事:** 作为用户，我希望发起转账请求并让伴侣确认。

**验收标准:**
- ✅ 发送带金额和原因的转账请求
- ✅ 伴侣收到通知并可接受/拒绝
- ✅ 接受后为双方创建记录
- ✅ 待处理请求24小时超时

---

## 技术设计

### 整体架构

```
Client A                    Server (Go)                  Client B
   |                           |                            |
   |-- POST /device/register ->| (store pubkey, no auth)    |
   |<-- 200 OK ---------------|                            |
   |                           |                            |
   |-- POST /pair/create ----->| (store pairing request)    |
   |<-- {pairCode, qrData} ---|                            |
   |                           |                            |
   |                           |<-- POST /device/register --|
   |                           |<-- POST /pair/join --------|
   |                           |   (match pairCode)         |
   |                           |-- push notify A ---------->|
   |<-- POST /pair/confirm --->|                            |
   |                           |-- push pair_confirmed B -->|
   |                           |                   B: confirming → active
   |== PAIRED (exchange public keys via server) ===========|
   |== Device A: fullSync() → push all existing txns ======|
   |                           |                            |
   |-- POST /sync/push ------>| (store encrypted blob)     |
   |                           |-- APNs/FCM notify B ------>|
   |                           |                            |
   |                           |<-- GET /sync/pull ---------|
   |                           |-- {encrypted blob} ------->|
   |                           |-- DELETE blob (after ACK) -|
```

### 服务器API概览

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/pair/create` | 创建配对请求，获取短码 |
| POST | `/api/v1/pair/join` | 用短码或QR数据加入配对 |
| POST | `/api/v1/pair/confirm` | 发起方确认配对 |
| GET | `/api/v1/pair/status/{pairId}` | 查询配对状态 |
| DELETE | `/api/v1/pair/{pairId}` | 解除配对 |
| POST | `/api/v1/sync/push` | 推送加密CRDT操作 |
| GET | `/api/v1/sync/pull` | 拉取待处理的加密消息 |
| POST | `/api/v1/sync/ack` | 确认已收到消息（触发删除） |
| POST | `/api/v1/device/register` | 注册设备 + 推送令牌 |
| PUT | `/api/v1/device/push-token` | 更新推送令牌 |

---

## 配对流程

### 配对发起（Device A）

```dart
// lib/application/family_sync/create_pair_use_case.dart

class CreatePairUseCase {
  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final BookRepository _bookRepo;
  final PairRepository _pairRepo;

  CreatePairUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
    required BookRepository bookRepo,
    required PairRepository pairRepo,
  })  : _apiClient = apiClient,
        _keyManager = keyManager,
        _bookRepo = bookRepo,
        _pairRepo = pairRepo;

  Future<CreatePairResult> execute(String bookId) async {
    try {
      // 1. 获取设备信息
      final deviceId = await _keyManager.getDeviceId();
      final publicKey = await _keyManager.getPublicKey();
      final deviceName = await _getDeviceName();

      if (deviceId == null || publicKey == null) {
        throw Exception('设备密钥未初始化');
      }

      // 2. 确保设备已注册（幂等，无需auth）
      //    服务器规则：首次注册写入公钥，后续调用同deviceId时
      //    必须携带相同公钥，否则返回409 Conflict（防止公钥劫持）
      await _apiClient.registerDevice(
        deviceId: deviceId,
        publicKey: publicKey,
        deviceName: deviceName,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      // 3. 请求服务器创建配对
      final response = await _apiClient.createPair(
        bookId: bookId,
        deviceId: deviceId,
        publicKey: publicKey,
        deviceName: deviceName,
      );

      // 4. 保存配对信息到本地
      await _pairRepo.savePendingPair(
        pairId: response.pairId,
        bookId: bookId,
        pairCode: response.pairCode,
        expiresAt: response.expiresAt,
      );

      return CreatePairResult.success(
        pairId: response.pairId,
        pairCode: response.pairCode,
        qrData: response.qrData,
        expiresAt: response.expiresAt,
      );
    } catch (e) {
      return CreatePairResult.error(e.toString());
    }
  }
}
```

### 配对加入（Device B）

```dart
// lib/application/family_sync/join_pair_use_case.dart

class JoinPairUseCase {
  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final PairRepository _pairRepo;
  final E2EEService _e2ee;

  JoinPairUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
    required PairRepository pairRepo,
    required E2EEService e2ee,
  })  : _apiClient = apiClient,
        _keyManager = keyManager,
        _pairRepo = pairRepo,
        _e2ee = e2ee;

  Future<JoinPairResult> execute(String pairCode) async {
    try {
      final deviceId = await _keyManager.getDeviceId();
      final publicKey = await _keyManager.getPublicKey();
      final deviceName = await _getDeviceName();

      if (deviceId == null || publicKey == null) {
        throw Exception('设备密钥未初始化');
      }

      // 1. 确保设备已注册（幂等，无需auth）
      //    服务器规则：首次注册写入公钥，后续调用同deviceId时
      //    必须携带相同公钥，否则返回409 Conflict（防止公钥劫持）
      await _apiClient.registerDevice(
        deviceId: deviceId,
        publicKey: publicKey,
        deviceName: deviceName,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      // 2. 请求加入配对
      final response = await _apiClient.joinPair(
        pairCode: pairCode,
        deviceId: deviceId,
        publicKey: publicKey,
        deviceName: deviceName,
      );

      // 3. 保存配对为"confirming"状态（含伴侣公钥，但尚未激活）
      await _pairRepo.saveConfirmingPair(
        pairId: response.pairId,
        bookId: response.bookId,
        partnerDeviceId: response.partnerDeviceId,
        partnerPublicKey: response.partnerPublicKey,
        partnerDeviceName: response.partnerDeviceName,
      );

      // 4. 预初始化E2EE共享密钥（确认后立即可用）
      await _e2ee.initializeSharedSecret(response.partnerPublicKey);

      // NOTE: Device B本地状态是"confirming"，getActivePair()不会返回它。
      // 等待A确认后，B收到推送通知，调用confirmLocalPair()将状态转为active，
      // 然后由A触发FullSync推送历史数据，B通过pullSync()拉取。

      return JoinPairResult.success(
        pairId: response.pairId,
        partnerDeviceName: response.partnerDeviceName,
      );
    } catch (e) {
      return JoinPairResult.error(e.toString());
    }
  }
}
```

### 配对确认（Device A）

```dart
// lib/application/family_sync/confirm_pair_use_case.dart

class ConfirmPairUseCase {
  final RelayApiClient _apiClient;
  final PairRepository _pairRepo;
  final E2EEService _e2ee;
  final FullSyncUseCase _fullSync;

  ConfirmPairUseCase({
    required RelayApiClient apiClient,
    required PairRepository pairRepo,
    required E2EEService e2ee,
    required FullSyncUseCase fullSync,
  })  : _apiClient = apiClient,
        _pairRepo = pairRepo,
        _e2ee = e2ee,
        _fullSync = fullSync;

  Future<ConfirmPairResult> execute({
    required String pairId,
    required String bookId,
    required bool accept,
  }) async {
    try {
      final response = await _apiClient.confirmPair(
        pairId: pairId,
        accept: accept,
      );

      if (accept && response.partnerPublicKey != null) {
        // 将本地配对状态从pending → active，同时保存伴侣信息
        await _pairRepo.activatePair(
          pairId: pairId,
          bookId: bookId,
          partnerDeviceId: response.partnerDeviceId!,
          partnerPublicKey: response.partnerPublicKey!,
          partnerDeviceName: response.partnerDeviceName!,
        );

        // 初始化E2EE共享密钥
        await _e2ee.initializeSharedSecret(response.partnerPublicKey!);

        // 触发首次全量同步（推送所有本地交易给伴侣）
        await _fullSync.execute(bookId);
      }

      return ConfirmPairResult.success();
    } catch (e) {
      return ConfirmPairResult.error(e.toString());
    }
  }
}
```

### 解除配对

```dart
// lib/application/family_sync/unpair_use_case.dart

class UnpairUseCase {
  final RelayApiClient _apiClient;
  final PairRepository _pairRepo;
  final SyncQueueManager _queueManager;

  UnpairUseCase({
    required RelayApiClient apiClient,
    required PairRepository pairRepo,
    required SyncQueueManager queueManager,
  })  : _apiClient = apiClient,
        _pairRepo = pairRepo,
        _queueManager = queueManager;

  Future<UnpairResult> execute(String pairId) async {
    try {
      // 1. 通知服务器解除配对
      await _apiClient.unpair(pairId: pairId);

      // 2. 清空离线队列
      await _queueManager.clearQueue();

      // 3. 更新本地配对状态
      await _pairRepo.deactivatePair(pairId);

      return UnpairResult.success();
    } catch (e) {
      return UnpairResult.error(e.toString());
    }
  }
}
```

---

## 同步流程

### 主动推送（Active Push）

```dart
// lib/application/family_sync/push_sync_use_case.dart

class PushSyncUseCase {
  final RelayApiClient _apiClient;
  final E2EEService _e2ee;
  final PairRepository _pairRepo;
  final SyncQueueManager _queueManager;
  final CRDTSyncService _crdt;

  PushSyncUseCase({
    required RelayApiClient apiClient,
    required E2EEService e2ee,
    required PairRepository pairRepo,
    required SyncQueueManager queueManager,
    required CRDTSyncService crdt,
  })  : _apiClient = apiClient,
        _e2ee = e2ee,
        _pairRepo = pairRepo,
        _queueManager = queueManager,
        _crdt = crdt;

  Future<PushSyncResult> execute(List<CRDTOperation> operations) async {
    try {
      // 1. 获取配对信息
      final pair = await _pairRepo.getActivePair();
      if (pair == null) return PushSyncResult.noPair();

      // 2. 序列化CRDT操作
      final payload = _crdt.serializeOperations(operations);

      // 3. 端到端加密
      final encryptedPayload = await _e2ee.encrypt(
        plaintext: payload,
        recipientPublicKey: pair.partnerPublicKey,
      );

      // 4. 推送到服务器
      try {
        await _apiClient.pushSync(
          pairId: pair.pairId,
          targetDeviceId: pair.partnerDeviceId,
          payload: encryptedPayload,
          vectorClock: _crdt.currentVectorClock,
          operationCount: operations.length,
        );

        return PushSyncResult.success(operations.length);
      } catch (e) {
        // 5. 推送失败，加入离线队列
        await _queueManager.enqueue(
          pairId: pair.pairId,
          targetDeviceId: pair.partnerDeviceId,
          encryptedPayload: encryptedPayload,
          vectorClock: _crdt.currentVectorClock,
          operationCount: operations.length,
        );

        return PushSyncResult.queued(operations.length);
      }
    } catch (e) {
      return PushSyncResult.error(e.toString());
    }
  }
}
```

### 被动拉取（Passive Pull）

```dart
// lib/application/family_sync/pull_sync_use_case.dart

class PullSyncUseCase {
  final RelayApiClient _apiClient;
  final E2EEService _e2ee;
  final PairRepository _pairRepo;
  final CRDTSyncService _crdt;
  final SyncQueueManager _queueManager;

  PullSyncUseCase({
    required RelayApiClient apiClient,
    required E2EEService e2ee,
    required PairRepository pairRepo,
    required CRDTSyncService crdt,
    required SyncQueueManager queueManager,
  })  : _apiClient = apiClient,
        _e2ee = e2ee,
        _pairRepo = pairRepo,
        _crdt = crdt,
        _queueManager = queueManager;

  Future<PullSyncResult> execute() async {
    try {
      final pair = await _pairRepo.getActivePair();
      if (pair == null) return PullSyncResult.noPair();

      // 1. 拉取待处理的加密消息（使用服务器时间戳作为游标）
      final lastSyncCursor = pair.lastSyncAt?.millisecondsSinceEpoch ?? 0;
      final messages = await _apiClient.pullSync(since: lastSyncCursor);

      if (messages.isEmpty) return PullSyncResult.noNewData();

      int appliedCount = 0;

      // 2. 逐条解密并应用
      for (final message in messages) {
        final plaintext = await _e2ee.decrypt(
          ciphertext: message.payload,
          senderPublicKey: pair.partnerPublicKey!,
        );

        final operations = _crdt.deserializeOperations(plaintext);
        await _crdt.applyOperations(operations);
        appliedCount += operations.length;
      }

      // 3. 确认已收到（服务器物理删除）
      final messageIds = messages.map((m) => m.messageId).toList();
      await _apiClient.ackSync(messageIds: messageIds);

      // 4. 更新同步游标：使用最后一条消息的服务器端 createdAt
      //    而非 DateTime.now()，避免客户端时钟偏差导致跳过消息
      final serverCursor = messages.last.createdAt;
      await _pairRepo.updateLastSyncTime(serverCursor);

      // 5. 同时推送队列中的待发送操作
      await _queueManager.drainQueue();

      return PullSyncResult.success(appliedCount);
    } catch (e) {
      return PullSyncResult.error(e.toString());
    }
  }
}
```

### 离线队列管理

```dart
// lib/infrastructure/sync/sync_queue_manager.dart

class SyncQueueManager {
  final SyncQueueDao _queueDao;
  final RelayApiClient _apiClient;

  static const int _maxBatchSize = 50;

  SyncQueueManager({
    required SyncQueueDao queueDao,
    required RelayApiClient apiClient,
  })  : _queueDao = queueDao,
        _apiClient = apiClient;

  /// 将操作加入离线队列
  Future<void> enqueue({
    required String pairId,
    required String targetDeviceId,
    required String encryptedPayload,
    required Map<String, int> vectorClock,
    required int operationCount,
  }) async {
    await _queueDao.insert(SyncQueueEntry(
      id: const Uuid().v4(),
      pairId: pairId,
      targetDeviceId: targetDeviceId,
      encryptedPayload: encryptedPayload,
      vectorClock: jsonEncode(vectorClock),
      operationCount: operationCount,
      retryCount: 0,
      createdAt: DateTime.now(),
    ));
  }

  /// 排空队列，批量推送
  Future<DrainResult> drainQueue() async {
    final pending = await _queueDao.getPending(limit: _maxBatchSize);
    if (pending.isEmpty) return DrainResult.empty();

    int sent = 0;
    int failed = 0;

    for (final entry in pending) {
      try {
        await _apiClient.pushSync(
          pairId: entry.pairId,
          targetDeviceId: entry.targetDeviceId,
          payload: entry.encryptedPayload,
          vectorClock: jsonDecode(entry.vectorClock),
          operationCount: entry.operationCount,
        );

        await _queueDao.delete(entry.id);
        sent++;
      } catch (e) {
        await _queueDao.incrementRetry(entry.id);
        failed++;
      }
    }

    return DrainResult(sent: sent, failed: failed);
  }

  /// 清空队列（解除配对时调用）
  Future<void> clearQueue() async {
    await _queueDao.deleteAll();
  }
}
```

### 推送通知服务（客户端）

```dart
// lib/infrastructure/sync/push_notification_service.dart

class PushNotificationService {
  final RelayApiClient _apiClient;
  final PairRepository _pairRepo;
  final PullSyncUseCase _pullSync;

  PushNotificationService({
    required RelayApiClient apiClient,
    required PairRepository pairRepo,
    required PullSyncUseCase pullSync,
  })  : _apiClient = apiClient,
        _pairRepo = pairRepo,
        _pullSync = pullSync;

  /// 初始化推送令牌，注册到服务器
  Future<void> initialize() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _apiClient.updatePushToken(token: token);
    }

    // 监听令牌刷新
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _apiClient.updatePushToken(token: newToken);
    });

    // 注册前台/后台消息处理
    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  /// 根据推送类型分发处理
  Future<void> _handleMessage(RemoteMessage message) async {
    final type = message.data['type'] as String?;

    switch (type) {
      case 'pair_confirmed':
        // Device B收到A的确认推送：confirming → active
        await _handlePairConfirmed();
        break;
      case 'sync_available':
        // 有新的同步数据可拉取
        await _pullSync.execute();
        break;
      case 'pair_request':
        // Device A收到B的加入请求（前台通知由系统处理）
        break;
    }
  }

  /// Device B处理配对确认推送
  Future<void> _handlePairConfirmed() async {
    final pendingPair = await _pairRepo.getPendingPair();
    if (pendingPair != null && pendingPair.status == PairStatus.confirming) {
      await _pairRepo.confirmLocalPair(pendingPair.pairId);
      // 配对激活后立即拉取A的fullSync数据
      await _pullSync.execute();
    }
  }
}

// 顶层函数，用于后台消息处理（Firebase要求）
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  // 后台处理仅支持sync_available和pair_confirmed
  // 需通过ProviderContainer获取依赖
  final type = message.data['type'] as String?;
  if (type == 'sync_available' || type == 'pair_confirmed') {
    // 注意：后台处理需要独立初始化数据库和服务
    // 详见App生命周期集成部分
  }
}
```

### 首次全量同步

```dart
// lib/application/family_sync/full_sync_use_case.dart

class FullSyncUseCase {
  final TransactionRepository _transactionRepo;
  final CRDTSyncService _crdt;
  final PushSyncUseCase _pushSync;

  static const int _chunkSize = 100; // 每块100条交易

  FullSyncUseCase({
    required TransactionRepository transactionRepo,
    required CRDTSyncService crdt,
    required PushSyncUseCase pushSync,
  })  : _transactionRepo = transactionRepo,
        _crdt = crdt,
        _pushSync = pushSync;

  /// 首次配对后全量同步所有交易
  Future<FullSyncResult> execute(String bookId) async {
    try {
      // 1. 获取所有本地交易
      final allTransactions = await _transactionRepo.getAll(bookId);
      final totalCount = allTransactions.length;

      if (totalCount == 0) return FullSyncResult.empty();

      // 2. 分块推送
      int sentCount = 0;
      for (int i = 0; i < totalCount; i += _chunkSize) {
        final chunk = allTransactions.skip(i).take(_chunkSize).toList();
        final operations = _crdt.generateInsertOperations(chunk);

        await _pushSync.execute(operations);
        sentCount += chunk.length;

        // 进度回调可通过Stream实现
      }

      return FullSyncResult.success(sentCount);
    } catch (e) {
      return FullSyncResult.error(e.toString());
    }
  }
}
```

---

## 数据模型

### 客户端 Drift 表定义

```dart
// lib/data/tables/paired_devices_table.dart

import 'package:drift/drift.dart';

@DataClassName('PairedDeviceData')
class PairedDevices extends Table {
  TextColumn get pairId => text()();
  TextColumn get bookId => text()();
  TextColumn get partnerDeviceId => text().nullable()();   // null during 'pending'
  TextColumn get partnerPublicKey => text().nullable()();   // null during 'pending'
  TextColumn get partnerDeviceName => text().nullable()();  // null during 'pending'
  TextColumn get status => text()();  // 'pending' | 'confirming' | 'active' | 'inactive'
  TextColumn get pairCode => text().nullable()();
  IntColumn get expiresAt => integer().nullable()();  // pair code expiry (epoch ms)
  IntColumn get createdAt => integer()();
  IntColumn get confirmedAt => integer().nullable()();
  IntColumn get lastSyncAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {pairId};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_paired_devices_status', columns: {#status}),
    TableIndex(name: 'idx_paired_devices_book', columns: {#bookId}),
  ];
}
```

```dart
// lib/data/tables/sync_queue_table.dart

import 'package:drift/drift.dart';

@DataClassName('SyncQueueData')
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get pairId => text()();
  TextColumn get targetDeviceId => text()();
  TextColumn get encryptedPayload => text()();  // base64 encoded
  TextColumn get vectorClock => text()();        // JSON encoded
  IntColumn get operationCount => integer()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_sync_queue_created', columns: {#createdAt}),
  ];
}
```

### 客户端领域模型

```dart
// lib/features/family_sync/domain/models/paired_device.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'paired_device.freezed.dart';
part 'paired_device.g.dart';

@freezed
class PairedDevice with _$PairedDevice {
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

enum PairStatus {
  pending,
  confirming,
  active,
  inactive,
}
```

```dart
// lib/features/family_sync/domain/models/sync_message.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_message.freezed.dart';
part 'sync_message.g.dart';

@freezed
class SyncMessage with _$SyncMessage {
  const factory SyncMessage({
    required String messageId,
    required String fromDeviceId,
    required String payload,           // encrypted base64
    required Map<String, int> vectorClock,
    required int operationCount,
    required DateTime createdAt,
  }) = _SyncMessage;

  factory SyncMessage.fromJson(Map<String, dynamic> json) =>
      _$SyncMessageFromJson(json);
}
```

```dart
// lib/features/family_sync/domain/models/sync_status.dart

enum SyncStatus {
  /// 未配对
  unpaired,
  /// 配对中（等待确认）
  pairing,
  /// 已配对，同步正常
  synced,
  /// 已配对，正在同步
  syncing,
  /// 已配对，同步失败
  syncError,
  /// 已配对，离线（队列中有待发送操作）
  offline,
}
```

### 客户端 Repository 接口

```dart
// lib/features/family_sync/domain/repositories/pair_repository.dart

abstract class PairRepository {
  /// 保存待确认的配对（Device A发起，状态: pending）
  /// 此时没有伴侣信息，只有pairCode和过期时间
  Future<void> savePendingPair({
    required String pairId,
    required String bookId,
    required String pairCode,
    required DateTime expiresAt,
  });

  /// 保存等待确认的配对（Device B加入，状态: confirming）
  /// 此时已有伴侣信息，但尚未激活，getActivePair()不返回此状态
  Future<void> saveConfirmingPair({
    required String pairId,
    required String bookId,
    required String partnerDeviceId,
    required String partnerPublicKey,
    required String partnerDeviceName,
  });

  /// 确认配对，将状态从pending/confirming → active（Device A确认时调用）
  Future<void> activatePair({
    required String pairId,
    required String bookId,
    required String partnerDeviceId,
    required String partnerPublicKey,
    required String partnerDeviceName,
  });

  /// Device B收到确认推送后，将本地状态从confirming → active
  Future<void> confirmLocalPair(String pairId);

  /// 获取当前激活的配对（仅返回status == 'active'的记录）
  Future<PairedDevice?> getActivePair();

  /// 获取当前待确认的配对（status == 'pending' 或 'confirming'）
  Future<PairedDevice?> getPendingPair();

  /// 更新最后同步时间（使用服务器端时间戳）
  Future<void> updateLastSyncTime(DateTime syncTime);

  /// 解除配对
  Future<void> deactivatePair(String pairId);
}
```

```dart
// lib/features/family_sync/domain/repositories/sync_repository.dart

abstract class SyncRepository {
  /// 获取待同步的CRDT操作
  Future<List<CRDTOperation>> getUnsyncedOperations(String bookId);

  /// 标记操作为已同步
  Future<void> markAsSynced(List<String> operationIds);

  /// 应用远程CRDT操作
  Future<void> applyRemoteOperations(List<CRDTOperation> operations);
}
```

---

## 安全设计

### E2EE 加密服务

```dart
// lib/infrastructure/sync/e2ee_service.dart

class E2EEService {
  final KeyManager _keyManager;

  E2EEService({required KeyManager keyManager}) : _keyManager = keyManager;

  /// 加密数据给指定接收方
  ///
  /// 1. Ed25519 → X25519 密钥转换
  /// 2. X25519 Diffie-Hellman 共享密钥
  /// 3. XSalsa20-Poly1305 加密 (NaCl box)
  Future<String> encrypt({
    required String plaintext,
    required String recipientPublicKey,
  }) async {
    final myPrivateKey = await _keyManager.getPrivateKey();

    // Ed25519 → X25519 转换
    final x25519PrivateKey = ed25519ToX25519Private(myPrivateKey!);
    final x25519PublicKey = ed25519ToX25519Public(recipientPublicKey);

    // 生成24字节随机nonce
    final nonce = generateSecureRandom(24);

    // XSalsa20-Poly1305 加密
    final ciphertext = naclBox(
      message: utf8.encode(plaintext),
      nonce: nonce,
      theirPublicKey: x25519PublicKey,
      mySecretKey: x25519PrivateKey,
    );

    // 返回 nonce + ciphertext 的base64编码
    return base64Encode(Uint8List.fromList([...nonce, ...ciphertext]));
  }

  /// 解密来自指定发送方的数据
  Future<String> decrypt({
    required String ciphertext,
    required String senderPublicKey,
  }) async {
    final myPrivateKey = await _keyManager.getPrivateKey();
    final raw = base64Decode(ciphertext);

    // 分离nonce和密文
    final nonce = raw.sublist(0, 24);
    final encrypted = raw.sublist(24);

    // Ed25519 → X25519 转换
    final x25519PrivateKey = ed25519ToX25519Private(myPrivateKey!);
    final x25519PublicKey = ed25519ToX25519Public(senderPublicKey);

    // 解密
    final plaintext = naclBoxOpen(
      ciphertext: encrypted,
      nonce: nonce,
      theirPublicKey: x25519PublicKey,
      mySecretKey: x25519PrivateKey,
    );

    return utf8.decode(plaintext);
  }
}
```

### 服务器地址配置

```dart
// lib/infrastructure/sync/relay_api_client.dart

class RelayApiClient {
  final String baseUrl;
  final RequestSigner _signer;
  final http.Client _httpClient;

  RelayApiClient({
    required this.baseUrl,
    required RequestSigner signer,
    http.Client? httpClient,
  })  : _signer = signer,
        _httpClient = httpClient ?? http.Client();

  /// 编译时环境选择：
  /// - Release: https://sync.happypocket.app/api/v1
  /// - Debug:   https://dev-sync.happypocket.app/api/v1
  static String get defaultBaseUrl {
    const url = String.fromEnvironment(
      'SYNC_SERVER_URL',
      defaultValue: '',
    );
    if (url.isNotEmpty) return url;
    return kReleaseMode
        ? 'https://sync.happypocket.app/api/v1'
        : 'https://dev-sync.happypocket.app/api/v1';
  }
}
```

**环境配置：**

| 环境 | 域名 | 用途 |
|------|------|------|
| Production | `sync.happypocket.app` | 正式版 App Store / Google Play |
| Development | `dev-sync.happypocket.app` | 开发和测试 |

可通过 `--dart-define=SYNC_SERVER_URL=https://custom.example.com/api/v1` 覆盖。

### 请求签名

```dart
// lib/infrastructure/sync/relay_api_client.dart (认证部分)

class RequestSigner {
  final KeyManager _keyManager;

  RequestSigner({required KeyManager keyManager}) : _keyManager = keyManager;

  /// 生成Ed25519签名的Authorization头
  Future<String> signRequest({
    required String method,
    required String path,
    required String body,
  }) async {
    final deviceId = await _keyManager.getDeviceId();
    final privateKey = await _keyManager.getPrivateKey();
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 构造签名消息
    final bodyHash = sha256(utf8.encode(body));
    final message = '$method:$path:$timestamp:${hex(bodyHash)}';

    // Ed25519 签名
    final signature = ed25519Sign(utf8.encode(message), privateKey!);

    return 'Ed25519 $deviceId:$timestamp:${base64Encode(signature)}';
  }
}
```

### 零知识保证

```
服务器可以知道的：
─────────────────────────────────────────
✅ device_id（匿名标识符）
✅ public_key（无法推导私钥）
✅ device_name（用户提供，可以是假名）
✅ 配对关系（A ↔ B）
✅ 同步时间（消息发送/拉取的时间）
✅ 加密数据块大小

服务器绝对无法知道的：
─────────────────────────────────────────
❌ 交易金额
❌ 交易分类
❌ 商户名称
❌ 备注和描述
❌ 账本/账簿详情
❌ 任何明文财务数据
```

---

## 客户端架构

### 模块结构

```
lib/
├── infrastructure/
│   └── sync/                          # 同步技术层
│       ├── relay_api_client.dart       # HTTP客户端（服务器API）
│       ├── e2ee_service.dart           # X25519加解密
│       ├── push_notification_service.dart # APNs/FCM令牌管理
│       └── sync_queue_manager.dart     # 离线队列管理
│
├── application/
│   └── family_sync/                   # 业务逻辑
│       ├── create_pair_use_case.dart   # 创建配对
│       ├── join_pair_use_case.dart     # 加入配对
│       ├── confirm_pair_use_case.dart  # 确认配对
│       ├── unpair_use_case.dart        # 解除配对
│       ├── push_sync_use_case.dart     # 主动推送
│       ├── pull_sync_use_case.dart     # 被动拉取
│       └── full_sync_use_case.dart     # 首次全量同步
│
├── data/
│   ├── tables/
│   │   ├── paired_devices_table.dart   # 配对设备表
│   │   └── sync_queue_table.dart       # 离线队列表
│   ├── daos/
│   │   ├── paired_device_dao.dart
│   │   └── sync_queue_dao.dart
│   └── repositories/
│       ├── pair_repository_impl.dart
│       └── sync_repository_impl.dart
│
├── features/
│   └── family_sync/
│       ├── domain/
│       │   ├── models/
│       │   │   ├── paired_device.dart
│       │   │   ├── sync_message.dart
│       │   │   └── sync_status.dart
│       │   └── repositories/
│       │       ├── pair_repository.dart
│       │       └── sync_repository.dart
│       └── presentation/
│           ├── screens/
│           │   ├── pairing_screen.dart
│           │   └── pair_management_screen.dart
│           ├── widgets/
│           │   ├── pair_code_display.dart
│           │   ├── pair_code_input.dart
│           │   ├── sync_status_badge.dart
│           │   └── partner_device_tile.dart
│           └── providers/
│               ├── repository_providers.dart
│               ├── pair_providers.dart
│               └── sync_providers.dart
```

### App生命周期集成

```dart
// 同步触发器集成到App生命周期

// AppLifecycleState.resumed（App被激活）
void onAppResumed() {
  if (hasPairedDevice) {
    pullSync();          // 被动拉取最新数据
    drainSyncQueue();    // 推送离线队列中的操作
  }
}

// 交易新增时
void onTransactionCreated(List<CRDTOperation> ops) {
  if (hasPairedDevice) {
    pushSync(ops);       // 主动推送新数据
  }
}

// 交易修改时
void onTransactionUpdated(List<CRDTOperation> ops) {
  if (hasPairedDevice) {
    pushSync(ops);       // 推送修改增量
  }
}

// 交易删除时
void onTransactionDeleted(List<CRDTOperation> ops) {
  if (hasPairedDevice) {
    pushSync(ops);       // 推送删除操作
  }
}

// 收到推送通知时（按type分发）
void onPushNotificationReceived(Map<String, dynamic> data) {
  final type = data['type'] as String?;
  switch (type) {
    case 'pair_confirmed':
      // Device B收到A的确认推送：将本地状态从confirming → active
      _handlePairConfirmed();
      break;
    case 'sync_available':
      // 有新的同步数据可拉取
      pullSync();
      break;
    case 'pair_request':
      // Device A收到B的加入请求（前台可见通知，由系统处理）
      break;
  }
}

/// Device B处理配对确认推送
Future<void> _handlePairConfirmed() async {
  final pendingPair = await pairRepo.getPendingPair();
  if (pendingPair != null && pendingPair.status == PairStatus.confirming) {
    await pairRepo.confirmLocalPair(pendingPair.pairId);
    // 配对激活后立即拉取A的fullSync数据
    await pullSync();
  }
}
```

---

## UI组件设计

### 配对界面

```dart
// lib/features/family_sync/presentation/screens/pairing_screen.dart

class PairingScreen extends ConsumerStatefulWidget {
  final String bookId;

  const PairingScreen({super.key, required this.bookId});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.devicePairing),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.showMyCode),
              Tab(text: l10n.enterPartnerCode),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PairCodeDisplay(bookId: widget.bookId),
            PairCodeInput(
              onCodeSubmitted: (code) => _handleJoinPair(code),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 配对码显示组件

```dart
// lib/features/family_sync/presentation/widgets/pair_code_display.dart

class PairCodeDisplay extends ConsumerStatefulWidget {
  final String bookId;

  const PairCodeDisplay({super.key, required this.bookId});

  @override
  ConsumerState<PairCodeDisplay> createState() => _PairCodeDisplayState();
}

class _PairCodeDisplayState extends ConsumerState<PairCodeDisplay> {
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime expiresAt) {
    _countdownTimer?.cancel();
    _remainingSeconds = expiresAt.difference(DateTime.now()).inSeconds;
    if (_remainingSeconds <= 0) {
      _remainingSeconds = 0;
      return;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _countdownTimer?.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final pairState = ref.watch(createPairProvider(widget.bookId));

    return pairState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (result) {
        // 基于服务器返回的 expiresAt 计算剩余时间
        if (_countdownTimer == null || !_countdownTimer!.isActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startCountdown(result.expiresAt);
          });
        }

        final minutes = _remainingSeconds ~/ 60;
        final seconds = _remainingSeconds % 60;
        final isExpired = _remainingSeconds <= 0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR码
            QrImageView(
              data: result.qrData,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
            ),

            const SizedBox(height: 32),

            // 6位短码
            Text(
              _formatPairCode(result.pairCode),
              style: AppTextStyles.amountLarge.copyWith(
                fontSize: 36,
                letterSpacing: 8,
                color: isExpired ? Colors.grey : null,
              ),
            ),

            const SizedBox(height: 16),

            // 动态倒计时（基于expiresAt）
            Text(
              isExpired
                  ? S.of(context).pairCodeExpired
                  : S.of(context).pairCodeExpiresIn(minutes),
              style: TextStyle(
                color: isExpired ? Colors.red : Colors.grey[600],
              ),
            ),

            const SizedBox(height: 24),

            OutlinedButton.icon(
              onPressed: () {
                _countdownTimer?.cancel();
                ref.invalidate(createPairProvider(widget.bookId));
              },
              icon: const Icon(Icons.refresh),
              label: Text(S.of(context).regenerate),
            ),
          ],
        );
      },
    );
  }

  String _formatPairCode(String code) {
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    }
    return code;
  }
}
```

### 同步状态组件

```dart
// lib/features/family_sync/presentation/widgets/sync_status_badge.dart

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final l10n = S.of(context);

    return switch (syncStatus) {
      SyncStatus.unpaired => _buildBadge(
        icon: Icons.link_off,
        label: l10n.unpaired,
        color: Colors.grey,
      ),
      SyncStatus.pairing => _buildBadge(
        icon: Icons.hourglass_top,
        label: l10n.pairing,
        color: Colors.orange,
      ),
      SyncStatus.synced => _buildBadge(
        icon: Icons.check_circle,
        label: l10n.synced,
        color: Colors.green,
      ),
      SyncStatus.syncing => _buildBadge(
        icon: Icons.sync,
        label: l10n.syncing,
        color: Colors.blue,
        animate: true,
      ),
      SyncStatus.syncError => _buildBadge(
        icon: Icons.error,
        label: l10n.syncError,
        color: Colors.red,
      ),
      SyncStatus.offline => _buildBadge(
        icon: Icons.cloud_off,
        label: l10n.offline,
        color: Colors.orange,
      ),
    };
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    bool animate = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
```

---

## 测试策略

### 单元测试

```dart
// test/unit/application/family_sync/push_sync_use_case_test.dart

void main() {
  late MockRelayApiClient mockApiClient;
  late MockE2EEService mockE2ee;
  late MockPairRepository mockPairRepo;
  late MockSyncQueueManager mockQueueManager;
  late MockCRDTSyncService mockCrdt;
  late PushSyncUseCase useCase;

  setUp(() {
    mockApiClient = MockRelayApiClient();
    mockE2ee = MockE2EEService();
    mockPairRepo = MockPairRepository();
    mockQueueManager = MockSyncQueueManager();
    mockCrdt = MockCRDTSyncService();

    useCase = PushSyncUseCase(
      apiClient: mockApiClient,
      e2ee: mockE2ee,
      pairRepo: mockPairRepo,
      queueManager: mockQueueManager,
      crdt: mockCrdt,
    );
  });

  group('PushSyncUseCase', () {
    test('成功推送加密操作到服务器', () async {
      // Given: 已配对
      when(mockPairRepo.getActivePair()).thenAnswer(
        (_) async => testPairedDevice,
      );
      when(mockE2ee.encrypt(any, any)).thenAnswer((_) async => 'encrypted');
      when(mockApiClient.pushSync(any)).thenAnswer((_) async => pushResponse);

      // When
      final result = await useCase.execute([testOperation]);

      // Then
      expect(result, isA<PushSyncSuccess>());
      verify(mockApiClient.pushSync(any)).called(1);
      verifyNever(mockQueueManager.enqueue(any));
    });

    test('网络失败时操作加入离线队列', () async {
      // Given: 已配对但无网络
      when(mockPairRepo.getActivePair()).thenAnswer(
        (_) async => testPairedDevice,
      );
      when(mockE2ee.encrypt(any, any)).thenAnswer((_) async => 'encrypted');
      when(mockApiClient.pushSync(any)).thenThrow(Exception('Network error'));

      // When
      final result = await useCase.execute([testOperation]);

      // Then: 加入队列而不是报错
      verify(mockQueueManager.enqueue(any)).called(1);
    });

    test('未配对时返回noPair', () async {
      when(mockPairRepo.getActivePair()).thenAnswer((_) async => null);

      final result = await useCase.execute([testOperation]);

      expect(result, isA<PushSyncNoPair>());
    });
  });
}
```

### 测试矩阵

| 测试场景 | 类型 | 验证内容 |
|---------|------|---------|
| 配对全流程 | 集成 | create → join → confirm → 双方都有公钥 |
| 推送同步 | 集成 | A创建交易 → push → B pull → B有新交易 |
| 离线队列 | 单元 | 无网络 → enqueue → 恢复网络 → drain |
| E2EE加解密 | 单元 | A加密 → B解密 → 内容一致 |
| CRDT合并 | 单元 | 双方并发编辑 → 同步后一致 |
| 解除配对 | 集成 | unpair → 同步停止 → 本地数据保留 |
| 请求签名 | 单元 | 签名生成 → 服务器验证通过 |
| 配对码过期 | 单元 | 10分钟后配对码无效 |

---

## 性能优化

### 同步优化策略

**1. 增量同步**
- 仅同步自上次同步以来的变更
- 使用Vector Clock跟踪同步状态
- gzip压缩加密载荷

**2. 批量操作**
- 多个CRDT操作合并为单个push请求
- 批量ACK（单次确认多条消息）
- 限制同步频率（最多每5秒1次push）

**3. 首次全量同步优化**
- 分块传输（500KB/chunk, gzip）
- 进度显示（已同步 / 总数）
- 支持断点续传（通过chunkIndex）

**4. 推送通知优化**
- 静默推送，不打扰用户
- 推送去重（5秒内多次变更合并为一次推送）
- 推送失败不阻塞同步（客户端定期pull兜底）

### 性能指标

| 指标 | 目标 |
|------|------|
| 配对完成时间 | <15s |
| 同步延迟（前台） | <5s |
| 首次全量同步 | <30s（1000条交易） |
| 离线队列容量 | 10,000+ 操作 |
| 加密/解密速度 | <10ms/操作 |
| 推送送达率 | >95% |

---

## 验收标准

### 功能需求

- ✅ QR码/短码配对成功率 >95%
- ✅ 端到端加密，服务器无法解密任何帐单数据
- ✅ CRDT同步冲突率 <1%
- ✅ 1000条交易全量同步在<30秒内完成
- ✅ 离线队列可容纳10000+操作且无数据丢失
- ✅ 服务器ACK后物理删除同步数据

### 非功能需求

| 指标 | 目标 |
|------|------|
| 配对时间 | <15s |
| 同步延迟 | <5s |
| 推送送达率 | >95% |
| 服务器可用性 | >99.5% |
| API响应时间 P95 | <500ms |

---

## 未来扩展

### TODO: 消息队列可行性评估

当前MVP使用PostgreSQL作为消息存储和队列。未来规模扩大时，评估以下替代方案：

| 方案 | 优势 | 触发条件 |
|------|------|---------|
| Redis Streams | 亚毫秒延迟，内置消费者组 | sync_messages > 100K行 |
| NATS JetStream | Go原生，轻量，内置持久化 | 推送延迟 > 5s P95 |
| PostgreSQL LISTEN/NOTIFY | 无需新基础设施 | 需要实时推送但不想增加服务 |

---

**文档状态:** 已完成 (v3.0)
**最后更新:** 2026-02-28
**维护者:** 架构团队
