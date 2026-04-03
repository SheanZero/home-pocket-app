# 数据同步引擎 PRD（SyncEngine）

**日期:** 2026-04-03
**状态:** 待审核
**相关模块:** Family Sync (MOD-003)
**前置依赖:**
- [User Profile Onboarding](2026-04-03-user-profile-onboarding-design.md)
- [Group Profile Flow](2026-04-03-group-profile-flow-design.md)

---

## 1. 概述

将现有散落的同步逻辑统一重构为 `SyncEngine`，作为数据同步的唯一入口。实现 Group 激活后的全量同步、Transaction 变更的增量同步（1分钟去抖）、Profile 变更的实时同步，以及多种兜底触发机制确保数据最终一致。

### 核心需求

1. **全量同步:** Group 激活后立即在后台双向同步所有 Transaction
2. **增量同步:** Transaction 变更后 1 分钟无操作触发 push，去抖避免频繁请求
3. **触发机制:** App Resume + Push Notification + 15 分钟轮询 + 24 小时全量兜底 + 手动同步
4. **Profile 随同步传播:** 每次 sync payload 携带最新姓名/头像，SHA-256 校验图片变更
5. **UI 实时响应:** GroupMember 为对方 Profile 的单一数据源，首页/统计自动更新

### 设计决策摘要

| 决策项 | 选择 | 理由 |
|--------|------|------|
| 架构方式 | SyncEngine 统一重构 | 将散落的 trigger/queue/use case 整合为三层架构 |
| 增量触发 | 1 分钟去抖 | 连续记账只触发一次，平衡实时性与性能 |
| 兜底策略 | 混合（15 分钟轮询 + push + 24 小时全量） | 覆盖 push 不可靠场景 |
| 24 小时全量 | 后台执行，不阻塞主画面 | 用户体验优先 |
| Profile 数据源 | GroupMember 单一数据源 | 避免多处存储不一致 |
| Profile 传播方式 | 随每次 push 携带 profile 操作 | 确保对方总能获取最新信息 |

---

## 2. SyncEngine 三层架构

```
                    ┌─────────────────────────────┐
                    │         SyncEngine           │
                    │                              │
  触发源 ──────────►│  SyncScheduler (调度层)       │
  • App Resume      │    • 去抖定时器 (1分钟)       │
  • Push Notify     │    • 前台轮询 (15分钟)        │
  • Transaction     │    • 24小时全量阈值           │
  • Profile Change  │    • 手动同步                 │
  • 手动触发        │                              │
                    │  SyncOrchestrator (编排层)    │
                    │    • InitialSync             │
                    │    • IncrementalSync          │
                    │    • ProfileSync             │
                    │    • FullPull                 │
                    │                              │
                    │  执行层 (现有 Use Case)        │
                    │    • PushSyncUseCase          │
                    │    • PullSyncUseCase          │
                    │    • FullSyncUseCase          │
                    │    • SyncAvatarUseCase        │
                    │    • SyncQueueManager         │
                    └─────────────────────────────┘
```

| 层 | 职责 | 对应类 |
|----|------|--------|
| **调度层** | 何时同步：管理所有触发源，去抖/节流/防重入 | `SyncScheduler` |
| **编排层** | 同步什么：协调多个 Use Case 的执行顺序 | `SyncOrchestrator` |
| **执行层** | 怎么同步：实际的 push/pull/加密/解密 | 现有 Use Case（保留） |

---

## 3. SyncScheduler 调度层

### 3.1 触发源与调度规则

| # | 触发源 | 条件 | 动作 |
|---|--------|------|------|
| 1 | Transaction 变更 | create/update/delete | 重置 1 分钟去抖定时器，到期后 → IncrementalSync push |
| 2 | App Resume | 从后台回到前台 | 立即 → IncrementalSync pull + 启动 15 分钟轮询 |
| 3 | App Paused | 进入后台 | 取消去抖定时器 + 停止轮询 |
| 4 | Push Notification: syncAvailable | 对方有新数据 | 立即 → IncrementalSync pull |
| 5 | Push Notification: memberConfirmed | Group 激活 | 立即 → InitialSync |
| 6 | 前台定时器 | 每 15 分钟 | → IncrementalSync pull |
| 7 | 24 小时阈值 | app 启动时 lastSyncAt > 24h | 后台 → FullPull（不阻塞主画面） |
| 8 | 手动同步 | 用户点击按钮 | 跳过去抖，立即 → IncrementalSync |
| 9 | Profile 变更 | 用户修改姓名/头像 | 立即 → ProfileSync |

### 3.2 去抖机制

```dart
class SyncScheduler {
  Timer? _debounceTimer;
  Timer? _pollingTimer;
  
  /// Transaction 变更后调用
  void onTransactionChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(minutes: 1), () {
      _enqueueSync(SyncMode.incrementalPush);
    });
  }
  
  /// App 进入前台
  void onAppResumed() {
    _enqueueSync(SyncMode.incrementalPull);
    _startPollingTimer();
  }
  
  /// App 进入后台
  void onAppPaused() {
    // 如果去抖定时器有 pending push，立即 flush（避免 OS 杀进程丢数据）
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      _enqueueSync(SyncMode.incrementalPush);
    }
    _pollingTimer?.cancel();
  }
  
  /// 15 分钟前台轮询
  void _startPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _enqueueSync(SyncMode.incrementalPull);
    });
  }
}
```

### 3.3 防重入与请求累积

```dart
bool _isSyncing = false;
final Set<SyncMode> _pendingModes = {};

Future<void> _enqueueSync(SyncMode mode) async {
  if (_isSyncing) {
    _pendingModes.add(mode);  // 累积，不替换
    return;
  }
  _isSyncing = true;
  try {
    await onSyncRequested(mode);
  } finally {
    _isSyncing = false;
    if (_pendingModes.isNotEmpty) {
      // 按优先级排序，逐个执行
      final sorted = _pendingModes.toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));
      _pendingModes.clear();
      for (final pending in sorted) {
        await _enqueueSync(pending);
      }
    }
  }
}
```

**优先级:** `initialSync (0) > fullPull (1) > incremental (2) > profileSync (3)`

所有 pending 请求累积执行，不会丢弃低优先级请求（如 profileSync）。

### 3.4 24 小时全量阈值

```dart
Future<bool> needsFullPull() async {
  final group = await groupRepository.findActive();
  if (group == null) return false;
  final lastSync = group.lastSyncAt;
  if (lastSync == null) return true;
  return DateTime.now().difference(lastSync) > const Duration(hours: 24);
}
```

后台执行，主画面正常进入。UI 通过 SyncStatus 显示"同步中..."。

24 小时检查同时在 15 分钟轮询周期中执行，不仅限于 app 启动时。

---

## 4. SyncOrchestrator 编排层

### 4.1 同步模式

| 模式 | 触发时机 | 执行内容 |
|------|---------|---------|
| **InitialSync** | Group 激活后 | 双向全量 push + pull + 头像交换 |
| **IncrementalSync** | Transaction 变更 / resume / 轮询 / push | push 本地变更 + pull 对方变更 + Profile 比对 |
| **ProfileSync** | 用户修改姓名/头像 | push profileUpdate + avatarSync（如需要） |
| **FullPull** | 超 24 小时 / 手动 | 全量 pull（不 push） |

### 4.2 InitialSync 编排流程

```
Group 激活
  │
  ├─ Owner 端 (confirmMember 成功后):
  │   1. 创建对方的 Shadow Book
  │   2. FullSyncUseCase.execute() → push 所有本地 Transaction (50条/批)
  │   3. SyncAvatarUseCase.pushAvatarIfNeeded() → push 自己的头像
  │   4. PullSyncUseCase.execute() → pull 对方数据
  │   5. 处理 profile/avatar 操作 → 更新 GroupMember
  │   6. 更新 SyncStatus → synced
  │
  ├─ Joiner 端 (收到 memberConfirmed 后):
  │   1. 创建对方的 Shadow Book
  │   2. PullSyncUseCase.execute() → pull Owner 数据
  │   3. 处理 profile/avatar 操作 → 更新 GroupMember
  │   4. FullSyncUseCase.execute() → push 自己的 Transaction
  │   5. SyncAvatarUseCase.pushAvatarIfNeeded() → push 自己的头像
  │   6. 更新 SyncStatus → synced
  │
  └─ 全程后台执行，UI 通过 SyncStatus 显示进度
```

### 4.3 IncrementalSync 编排流程

```
触发 (去抖1分钟 / app resume / 15分钟轮询 / syncAvailable push / 手动)
  │
  1. 检查 Group 有效性 (5分钟缓存)
  │   → 无效: 清理本地数据，退出
  │
  2. Push 阶段:
  │   a. 收集 lastSyncAt 之后的本地变更
  │   b. 注入当前 Profile 信息作为第一条操作
  │   c. PushSyncUseCase.execute() → E2EE 加密 push
  │   d. 失败 → SyncQueueManager.enqueue()
  │
  3. Pull 阶段:
  │   a. PullSyncUseCase.execute(since: lastSyncAt)
  │   b. 解密 → ApplySyncOperationsUseCase 处理
  │   c. bill 操作 → 写入 Shadow Book
  │   d. profile 操作 → 更新 GroupMember
  │   e. avatar 操作 → SHA-256 校验 + 保存图片 + 更新 GroupMember
  │   f. ACK 已处理消息
  │
  4. 排空离线队列:
  │   SyncQueueManager.drainQueue()
  │
  5. 更新 lastSyncAt + SyncStatus
```

### 4.4 ProfileSync 编排流程

```
用户在 Settings 修改姓名/头像
  │
  1. 保存到本地 UserProfile (DB)
  │
  2. 检查是否有 active Group
  │   → 无: 结束
  │
  3. 构建 profile 操作 + 按需构建 avatar 操作
  │   (avatarImageHash 变化 → SyncAvatarUseCase 传输图片)
  │
  4. PushSyncUseCase.execute() → E2EE 加密 push
  │
  5. 对方 pull 后:
  │   → 更新 GroupMember → Riverpod invalidate → UI 自动更新
```

---

## 5. Sync Payload 扩展

### 5.1 新增操作类型

在现有 `operations` 数组中新增两种 `entityType`:

```json
// Profile 更新（文本信息，随每次 push 携带）
{
  "op": "update",
  "entityType": "profile",
  "entityId": "device_id",
  "data": {
    "displayName": "たけし",
    "avatarEmoji": "🐱",
    "avatarImageHash": "sha256_xxx"
  },
  "fromDeviceId": "xxx",
  "timestamp": "2026-04-03T12:00:00Z"
}

// 头像图片传输（仅 hash 变化时发送）
{
  "op": "update",
  "entityType": "avatar",
  "entityId": "device_id",
  "data": {
    "avatarImageHash": "sha256_xxx",
    "avatarImageBase64": "..."
  },
  "fromDeviceId": "xxx",
  "timestamp": "2026-04-03T12:00:00Z"
}
```

### 5.2 Profile 随 push 携带（仅变化时）

通过 `lastPushedProfileHash` 跟踪上次已推送的 Profile 状态，仅在变化时注入 profile 操作，避免每次 push 的冗余开销：

```dart
String? _lastPushedProfileHash;

List<Map<String, dynamic>> buildOperations(
  List<Map<String, dynamic>> transactionOps,
  UserProfile currentProfile,
  String deviceId,
) {
  final profileHash = sha256(
    '${currentProfile.displayName}|${currentProfile.avatarEmoji}|${currentProfile.avatarImageHash}'
  );
  
  final ops = <Map<String, dynamic>>[];
  
  // 仅在 Profile 变化时注入
  if (profileHash != _lastPushedProfileHash) {
    ops.add({
      'op': 'update',
      'entityType': 'profile',
      'entityId': deviceId,
      'data': {
        'displayName': currentProfile.displayName,
        'avatarEmoji': currentProfile.avatarEmoji,
        'avatarImageHash': currentProfile.avatarImageHash,
      },
      'fromDeviceId': deviceId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _lastPushedProfileHash = profileHash;
  }
  
  ops.addAll(transactionOps);
  return ops;
}
```

### 5.3 ApplySyncOperationsUseCase 扩展

```dart
Future<void> apply(List<Map<String, dynamic>> operations) async {
  for (final op in operations) {
    switch (op['entityType']) {
      case 'bill':
        await _applyBillOperation(op);      // 现有逻辑
      case 'profile':
        await _applyProfileOperation(op);   // 新增: 更新 GroupMember
      case 'avatar':
        await _applyAvatarOperation(op);    // 新增: SHA-256 校验 + 保存图片
    }
  }
}
```

**Profile 操作处理:**
- LWW (Last-Write-Wins by timestamp)
- 更新 `GroupMember.displayName` / `avatarEmoji` / `avatarImageHash`
- 如果 `avatarImageHash` 变化但无 `avatar` 操作 → 标记待拉取，下次 pull 重试

**Avatar 操作处理:**
- 验证 SHA-256 → 解密 → 保存到 `avatars/` 目录 → 更新 `GroupMember.avatarImagePath`

---

## 6. UI 自动更新链路

### 6.1 数据流

```
GroupMember DB 更新
  → groupMemberDao.watchByGroupId() (Drift Stream)
  → groupMembersProvider (Riverpod StreamProvider)
  → 首页 widget rebuild（对方姓名/头像）
  → 统计页 widget rebuild（对方数据标签）
  → Group 管理页 rebuild（成员列表）
```

### 6.2 现有代码迁移

| 现有读取 | 当前来源 | 改为 |
|----------|---------|------|
| 首页家庭成员头像 | `shadowBook.ownerDeviceName` | `groupMember.displayName` + `avatarEmoji` |
| 统计页对方账本标签 | `shadowBook.ownerDeviceName` | `groupMember.displayName` |
| Group 管理页成员列表 | `groupMember.deviceName` | `groupMember.displayName` + `avatarEmoji` |

### 6.3 SyncStatus UI 展示

| 状态 | UI 表现 |
|------|---------|
| `idle` | 无显示 |
| `syncing` | 小旋转图标 + "同步中..." |
| `synced` | 绿点 + "上次同步: {time}" |
| `error` | 红点 + "同步失败" + 重试按钮 |
| `queuedOffline` | 橙点 + "{count}条变更待发送" |

位置: Group 管理页标题下方 + Settings Family Sync 区域

### 6.4 手动同步入口

- **Group 管理页:** 同步状态旁的刷新图标按钮
- **Settings Family Sync 区域:** "手动同步" 按钮

---

## 7. 文件结构

```
lib/infrastructure/sync/
├── sync_scheduler.dart                 # 新: 调度层（去抖/轮询/阈值）— 纯平台机制
├── sync_lifecycle_observer.dart        # 保留: 重构为只转发事件给 SyncEngine
├── push_notification_service.dart      # 保留: 事件转发给 SyncEngine
├── e2ee_service.dart                   # 保留: 不变
├── relay_api_client.dart               # 保留: 不变
└── sync_queue_manager.dart             # 保留: 不变

lib/application/family_sync/
├── sync_engine.dart                    # 新: 统一入口 facade，组装三层
├── sync_orchestrator.dart              # 新: 编排层（Initial/Incremental/Profile）— 业务逻辑
├── full_sync_use_case.dart             # 保留: 不变
├── pull_sync_use_case.dart             # 扩展: 传递 profile/avatar 操作
├── push_sync_use_case.dart             # 保留: 不变
├── apply_sync_operations_use_case.dart # 扩展: 增加 profile/avatar 处理
├── sync_avatar_use_case.dart           # 新: SHA-256 校验 + E2EE 图片传输
├── check_group_validity_use_case.dart  # 保留: 不变
├── shadow_book_service.dart            # 保留: 不变
└── ...
```

**层级划分原则:**
- `SyncScheduler` 在 `infrastructure/` — 管理平台机制（Timer、Lifecycle、Push），输出 `Stream<SyncRequest>` 事件流
- `SyncEngine` + `SyncOrchestrator` 在 `application/` — 消费事件流，编排业务逻辑
- 依赖方向: `Application (Engine/Orchestrator)` ← 依赖抽象事件流 ← `Infrastructure (Scheduler)` 产生

**旧文件删除:** `sync_trigger_service.dart` 被 `SyncEngine` 替代。

**Push Notification 事件处理迁移:**

| 事件 | 现有 handler | 迁移目标 |
|------|-------------|---------|
| `syncAvailable` | `_handleSyncAvailable()` → pull | `SyncEngine` — 触发 IncrementalSync pull |
| `memberConfirmed` | `_handleMemberConfirmed()` → activate + full sync | `SyncEngine` — 触发 InitialSync |
| `joinRequest` | `_handleJoinRequest()` → 转发给 UI | `PushNotificationService` — 直接转发给 UI 事件流（非 sync 操作） |
| `memberLeft` | `_handleMemberLeft()` → cleanup | `application/family_sync/` — 独立 Use Case（Group 生命周期，非 sync） |
| `groupDissolved` | `_handleGroupDissolved()` → cleanup | `application/family_sync/` — 独立 Use Case（Group 生命周期，非 sync） |

**SyncTriggerEvent 保留:** 现有 `SyncTriggerEvent` 事件流（用于 UI 导航，如 joinRequest 弹窗）是独立关注点，不被 `SyncStatus` 替代。由 `PushNotificationService` 继续暴露 `Stream<SyncTriggerEvent>` 供 UI 消费。

**与现有代码的集成点:**

| 现有调用点 | 当前 | 改为 |
|-----------|------|------|
| `main.dart` 初始化 | `syncTriggerService.initialize()` | `syncEngine.initialize()` |
| `CreateTransactionUseCase._triggerIncrementalSync()` | 直接调用 push | `syncEngine.onTransactionChanged()` |
| `UpdateTransactionUseCase` | 无 sync 触发 | `syncEngine.onTransactionChanged()` |
| `DeleteTransactionUseCase` | 无 sync 触发 | `syncEngine.onTransactionChanged()` |
| Settings Profile 修改 | 无 | `syncEngine.onProfileChanged()` |

---

## 8. SyncStatus 状态模型

```dart
enum SyncState {
  noGroup,        // 无 Group
  idle,           // Group 存在，无同步活动
  initialSyncing, // 首次全量同步中（Group 刚激活）
  syncing,        // 增量同步进行中
  synced,         // 同步完成
  error,          // 同步失败
  queuedOffline,  // 离线队列中有待发送数据
}

@freezed
class SyncStatus with _$SyncStatus {
  const factory SyncStatus({
    required SyncState state,
    DateTime? lastSyncAt,
    int? pendingQueueCount,
    String? errorMessage,
  }) = _SyncStatus;
}
```

**Provider 设计:**

```dart
// keepAlive: true — SyncEngine 管理 Timer 和 lifecycle observer，不能被自动 dispose
@Riverpod(keepAlive: true)
SyncEngine syncEngine(Ref ref) {
  final engine = SyncEngine(...);
  ref.onDispose(() => engine.dispose());
  return engine;
}

@riverpod
Stream<SyncStatus> syncStatus(Ref ref) {
  return ref.watch(syncEngineProvider).statusStream;
}

// 需要在 GroupMemberDao 中新增 watchByGroupId() 方法
// 返回 Stream<List<GroupMemberData>> (Drift watch query)
@riverpod
Stream<List<GroupMember>> groupMembers(Ref ref) {
  final activeGroup = ref.watch(activeGroupProvider).value;
  if (activeGroup == null) return Stream.value([]);
  return ref.watch(groupMemberDaoProvider).watchByGroupId(activeGroup.groupId);
}
```

**迁移说明:** 现有 `SyncStatus` enum（`unpaired`, `pairing`, `synced`, `syncing`, `syncError`, `offline`）和 `SyncStatusNotifier` 将被新的 Freezed `SyncStatus` 类替代。所有消费方（`SyncStatusBadge`、Settings Family Sync 区域等）需迁移到新 provider。

---

## 9. 边界情况与错误处理

### 9.1 网络失败

| 场景 | 处理 |
|------|------|
| Push 失败 | 自动入 SyncQueueManager，下次 pull 后排空 |
| Pull 失败 | SyncStatus → error，不阻塞 app，下次触发重试 |
| 头像传输失败 | 对方继续显示 emoji fallback，下次 pull 重试 |

### 9.2 去抖定时器边界

| 场景 | 行为 |
|------|------|
| 连续记账 5 笔（5分钟内） | 每笔重置定时器，最终只触发 1 次 push |
| 记 1 笔后立即关 app | 定时器取消，下次 resume 时 push 未同步数据 |
| 记 1 笔后切后台又切回 | Resume 立即 pull + push，定时器重置 |

### 9.3 InitialSync 中断恢复

不需要断点续传 — `FullSyncUseCase` 的 push 是幂等的（create 操作对已存在记录自动跳过）。中断后下次触发会重新执行，最终一致。

### 9.4 Profile 变更冲突

- Profile 操作使用 LWW（Last-Write-Wins by timestamp）
- 各人改自己的 Profile，实际冲突概率极低

### 9.5 同步防重入

多个触发源同时触发时，排队而非并发执行。优先级：`initialSync > fullPull > incremental > profileSync`。

---

## 10. i18n 新增键

3 语言全部添加:

| 键 | ja | zh | en |
|----|----|----|-----|
| `syncInProgress` | 同期中... | 同步中... | Syncing... |
| `syncCompleted` | 同期完了 | 同步完成 | Sync complete |
| `syncFailed` | 同期に失敗しました | 同步失败 | Sync failed |
| `syncRetry` | 再試行 | 重试 | Retry |
| `syncManual` | 手動で同期 | 手动同步 | Sync Now |
| `syncLastTime` | 最終同期: {time} | 上次同步: {time} | Last sync: {time} |
| `syncOfflineQueued` | {count}件の変更が送信待ち | {count}条变更待发送 | {count} changes pending |
| `syncInitialProgress` | 初回同期中... | 首次同步中... | Initial sync... |
| `syncProfileUpdated` | {name}がプロフィールを更新しました | {name}更新了个人资料 | {name} updated their profile |

---

## 11. 安全说明

- **所有 sync payload 经 E2EE 加密:** NaCl box (X25519-XSalsa20-Poly1305)，服务器无法读取内容
- **Profile 信息在 sync payload 内加密传输:** 服务器仅在配对阶段（E2EE 建立前）暂存明文 Profile，激活后所有 Profile 更新通过加密通道
- **头像图片 SHA-256 校验:** 确保传输完整性，hash 本身为低敏感元数据
- **离线队列加密存储:** SyncQueueManager 存储的是已加密的 payload

---

## 12. 不在范围内

- CRDT 冲突解决（当前 LWW 足够，会计数据低冲突）
- 多成员 Group (>2人) 的扇形同步优化
- 后台静默推送触发同步（依赖 iOS/Android 后台限制）
- Transaction 以外的数据类型同步（Category、Book 等）
- 同步进度百分比显示（显示状态即可，不显示 3/50 等详细进度）
