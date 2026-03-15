# 账单同步实现技术方案

**日期:** 2026-03-15
**状态:** 草稿
**相关模块:** MOD-003 FamilySync, MOD-001 BasicAccounting

---

## 1. 背景与目标

当前同步基础设施（E2EE、Relay API、SyncQueue、Push/Pull Use Cases）已完整实现，但账单数据尚未真正流通。本方案解决以下核心问题：

1. 第一次加入 Group 时，发起**全量同步**
2. 新增账目时，发起**增量同步**
3. 新增账单前，**检查 Group 有效性**，无效则清理同步数据
4. 对方同步过来的账单**如何存储**

### 1.1 当前缺口

| 缺口 | 现状 | 目标 |
|------|------|------|
| Transaction → Sync 触发 | `SyncTriggerService.onTransactionCreated()` 存在但未被调用 | 记账 Use Case 自动触发 push |
| `applyOperations` 回调 | `PullSyncUseCase` 中是 no-op | 实现 CRDT 写入逻辑 |
| `fetchAllTransactions` | `FullSyncUseCase` 中返回空 | 连接 TransactionRepository |
| 远端账单存储 | 无方案 | 本方案核心决策 |
| Group 有效性检查 | 无 | 新增前校验 |

---

## 2. 远端账单存储方案（Brainstorming）

### 方案 A: 同表同 Book — deviceId 区分

将对方账单存入**同一个 `transactions` 表、同一个 `bookId`**，通过 `deviceId` 字段区分来源。

```
transactions 表
├── id: "ulid-001" (本地, deviceId="my-device")
├── id: "ulid-002" (本地, deviceId="my-device")
├── id: "ulid-003" (同步, deviceId="partner-device", isSynced=true)
└── id: "ulid-004" (同步, deviceId="partner-device", isSynced=true)
```

**优势:**
- 零 schema 变更 — 现有表已有 `deviceId` 和 `isSynced` 字段
- 聚合查询自动包含家庭数据（月度总览无需改动）
- 实现最简单 — 插入并标记 `isSynced = true`

**劣势:**
- Hash Chain 完整性被破坏 — 两台设备的 hash 交错在同一个 book 中
- Books 表的 `survivalBalance` / `soulBalance` 反规范化余额混合
- 所有"我的支出"视图都需要加 `WHERE deviceId = ?` 过滤
- 退出 Group 删除同步数据后，需重算 book 余额
- 难以扩展到 3+ 家庭成员

**适用场景:** 极简 MVP，仅两人共享且不需要区分个人/家庭视图。

---

### 方案 B: 同表独立 Book — Shadow Book 模式（推荐）

为每个远端成员创建一个 **"Shadow Book"（影子账本）**，该成员同步过来的所有账单都写入这个 shadow book。若对方设备本身有多个 source book，不再在本机为 source book 再建子账本，而是在每条 transaction 的 `metadata` 中记录来源：

- `sourceBookId`
- `sourceBookName`
- `sourceBookType`

```
books 表
├── book-001 (我的账本, deviceId="my-device")
└── book-002 (Shadow Book, deviceId="partner-device", isShadow=true)

transactions 表
├── id: "ulid-001" (bookId="book-001", 本地)
├── id: "ulid-002" (bookId="book-001", 本地)
├── id: "ulid-003" (bookId="book-002", 同步, isSynced=true)
└── id: "ulid-004" (bookId="book-002", 同步, isSynced=true)
```

**优势:**
- 数据天然隔离 — 每个成员的数据在各自 shadow book 中
- 现有 bookId 查询无需改动（"我的账单" = 我的 bookId）
- Hash Chain 保持 per-book 完整性，无交错
- 退出 Group 批量删除简单：`deleteAllByBook(shadowBookId)` + 删除 Shadow Book
- 反规范化余额 per-book 正确
- 保留来源账本维度 — source book 信息写入 `metadata`，后续仍可做 UI 分组或迁移
- 自然支持 3+ 成员（每人一个 Shadow Book）
- 双轨账本（生存/灵魂）per-person 正确运作

**劣势:**
- 需要在建立 Group 后创建/管理 Shadow Book
- 家庭聚合查询需要 `WHERE bookId IN (...)`
- UI 需要"家庭视图"切换，且远端 source book 视图要读 `metadata`
- 远端多账本不会直接映射成多个本地 book；若未来要精确镜像，需要迁移
- Shadow Book 的 currency 仅用于满足当前 book schema，不能单独代表远端每个 source book
- Book 生命周期与 Group 生命周期耦合

**适用场景:** 本项目的最佳选择。充分利用现有 Book 抽象，天然隔离，易于扩展。

---

### 方案 C: 独立 synced_transactions 表

创建一个与 `transactions` 结构相同的 **`synced_transactions`** 表，所有远端数据存入此表。

```
transactions 表 (仅本地数据)
├── id: "ulid-001"
└── id: "ulid-002"

synced_transactions 表 (仅远端数据)
├── id: "ulid-003" (来自 partner-device)
└── id: "ulid-004" (来自 partner-device)
```

**优势:**
- 完全隔离 — 本地数据零风险
- 批量删除最简单：`DELETE FROM synced_transactions WHERE groupId = ?`
- 对现有查询、hash chain、余额零影响
- 可以针对同步数据优化 schema（例如不需要 hash chain）

**劣势:**
- Schema 重复 — 相同列定义两次
- DAO 重复 — 需要 `SyncedTransactionDao`
- 所有聚合/分析查询需要 UNION
- Drift 代码生成量翻倍
- 维护成本高 — 每次 schema 变更都要改两个表
- Model 映射复杂（`TransactionRow` vs `SyncedTransactionRow`）

**适用场景:** 对数据隔离有极端要求，或同步数据 schema 与本地有显著差异时。

---

### 方案对比总结

| 维度 | 方案 A (同Book) | 方案 B (Shadow Book) | 方案 C (独立表) |
|------|:-:|:-:|:-:|
| Schema 变更量 | 无 | 小 (Books 加 isShadow) | 大 (新表+DAO) |
| 数据隔离性 | 差 | 好 | 最好 |
| Hash Chain 完整性 | 破坏 | 保持 | 保持 |
| 退出 Group 清理 | 复杂 | 简单 | 最简单 |
| 聚合查询改动 | 无 | 小 | 大 (UNION) |
| 多成员扩展性 | 差 | 好 | 中 |
| 实现复杂度 | 低 | 中 | 高 |
| 维护成本 | 低 | 低 | 高 |

### 决策：采用方案 B 的变体 — 单成员 Shadow Book + 来源账本元数据

理由：
1. 充分利用现有 `bookId` 抽象，架构变更最小
2. 数据隔离清晰，退出 Group 时清理简洁
3. Hash chain per-book 完整性不受影响
4. 天然支持未来多成员扩展
5. 通过 `metadata.sourceBookId/sourceBookName/sourceBookType` 保留远端来源账本维度

---

## 3. 整体架构

### 3.1 数据流全景

```
┌─────────────────────────────────────────────────────────┐
│                      Device A (本机)                     │
│                                                          │
│  CreateTransactionUseCase                                │
│         │                                                │
│         ├─1→ checkGroupValidity()                        │
│         │    ├─ Group 有效 → 继续                         │
│         │    └─ Group 无效 → deactivate + cleanSyncData  │
│         │                                                │
│         ├─2→ transactionRepo.insert() [本地 book]        │
│         │                                                │
│         └─3→ syncTriggerService.onTransactionCreated()   │
│              └─→ pushSyncUseCase.execute()               │
│                  ├─ 成功 → relay server 转发             │
│                  └─ 失败 → syncQueue 入队                │
│                                                          │
│  PullSyncUseCase                                         │
│         │                                                │
│         └─→ applyOperations()                            │
│             └─→ 写入 Shadow Book                         │
│                 └─→ metadata 记录 source book            │
└──────────────────────────┬──────────────────────────────┘
                           │ HTTPS + E2EE
                    ┌──────┴──────┐
                    │ Relay Server │
                    └──────┬──────┘
                           │
┌──────────────────────────┴──────────────────────────────┐
│                      Device B (对方)                     │
│  同样的逻辑，角色对调                                      │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Shadow Book 生命周期

```
Group 创建/加入
     │
     ├─ Owner: confirmMember() 成功后
     │   └─→ 为 member 创建 Shadow Book
     │
     └─ Member: 收到 member_confirmed 后
         └─→ 为 owner 创建 Shadow Book
              │
              ├─→ FullSyncUseCase.execute() [push 本地全量]
              └─→ PullSyncUseCase.execute() [pull 对方全量]

正常运作
     └─→ 增量同步 push/pull

退出 Group
     ├─→ deactivateGroup()
     ├─→ deleteAllByBook(shadowBookId)
     └─→ 删除 Shadow Book 记录
```

---

## 4. 详细设计

### 4.1 Schema 变更

#### Books 表新增字段

```dart
// lib/data/tables/books_table.dart
class Books extends Table {
  // ... 现有字段 ...

  /// 是否为同步产生的 Shadow Book
  BoolColumn get isShadow => boolean().withDefault(const Constant(false))();

  /// 关联的 groupId（Shadow Book 专用）
  TextColumn get groupId => text().nullable()();

  /// 远端设备 ID（Shadow Book 专用，标识数据来源）
  TextColumn get ownerDeviceId => text().nullable()();

  /// 远端设备名称（显示用，如 "太太的 iPhone"）
  TextColumn get ownerDeviceName => text().nullable()();
}
```

#### 新增索引

```dart
List<TableIndex> get customIndices => [
  // ... 现有索引 ...
  TableIndex(name: 'idx_books_group_id', columns: {#groupId}),
  TableIndex(name: 'idx_books_is_shadow', columns: {#isShadow}),
];
```

### 4.2 Shadow Book 管理

#### 新增 ShadowBookService

```dart
// lib/application/family_sync/shadow_book_service.dart

class ShadowBookService {
  final BookRepository _bookRepo;
  final TransactionRepository _transactionRepo;

  /// 为远端成员创建 Shadow Book
  Future<String> createShadowBook({
    required String groupId,
    required String memberDeviceId,
    required String memberDeviceName,
    required String currency,
  }) async {
    final shadowBookId = Ulid().toString();
    await _bookRepo.createShadowBook(
      id: shadowBookId,
      name: '$memberDeviceName の記録',
      currency: currency,
      groupId: groupId,
      ownerDeviceId: memberDeviceId,
      ownerDeviceName: memberDeviceName,
    );
    return shadowBookId;
  }

  /// 根据 deviceId 查找 Shadow Book
  Future<Book?> findShadowBook(String deviceId) async {
    return _bookRepo.findShadowBookByDeviceId(deviceId);
  }

  /// 清理指定 Group 的所有同步数据
  Future<void> cleanSyncData(String groupId) async {
    final shadowBooks = await _bookRepo.findShadowBooksByGroupId(groupId);
    for (final book in shadowBooks) {
      await _transactionRepo.deleteAllByBook(book.id);
      await _bookRepo.delete(book.id);
    }
  }
}
```

### 4.3 全量同步（加入 Group 时）

#### 触发时机

- **Owner:** 在 `ConfirmMemberUseCase` 成功后
- **Member:** 收到 `member_confirmed` 推送通知后

#### 流程

```dart
// lib/application/family_sync/initial_sync_use_case.dart

class InitialSyncUseCase {
  final FullSyncUseCase _fullSync;
  final PullSyncUseCase _pullSync;
  final ShadowBookService _shadowBookService;
  final GroupRepository _groupRepo;
  final BookRepository _bookRepo;

  Future<Result<void>> execute() async {
    // 1. 获取当前 active group
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return Result.failure('No active group');

    // 2. 获取任一本地非 shadow book 的 currency（用于创建 Shadow Book）
    final localBook = await _bookRepo.getDefaultBook();
    if (localBook == null) return Result.failure('No local book');

    // 3. 为每个远端成员创建 Shadow Book（如果不存在）
    for (final member in group.members) {
      if (member.deviceId == group.localDeviceId) continue; // 跳过自己

      final existing = await _shadowBookService.findShadowBook(member.deviceId);
      if (existing == null) {
        await _shadowBookService.createShadowBook(
          groupId: group.groupId,
          memberDeviceId: member.deviceId,
          memberDeviceName: member.deviceName,
          currency: localBook.currency,
        );
      }
    }

    // 4. Push 本地全量数据给对方
    await _fullSync.execute();

    // 5. Pull 对方的全量数据
    await _pullSync.execute();

    return Result.success(null);
  }
}
```

#### FullSyncUseCase 修改

```dart
// 现有 FullSyncUseCase 需要连接 fetchAllTransactions
@riverpod
FullSyncUseCase fullSyncUseCase(Ref ref) {
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  final bookRepo = ref.watch(bookRepositoryProvider);

  return FullSyncUseCase(
    pushSync: ref.watch(pushSyncUseCaseProvider),
    fetchAllTransactions: () async {
      final defaultBook = await bookRepo.getDefaultBook();
      if (defaultBook == null) return [];
      // 仅推送本地非 shadow books 的数据，并在 metadata 中附带来源 book 信息
      final allBooks = await bookRepo.findAll();
      final localBooks = allBooks.where((book) => !book.isShadow).toList();
      final operations = <Map<String, dynamic>>[];

      for (final book in localBooks) {
        final transactions = await transactionRepo.findAllByBook(book.id);
        operations.addAll(
          transactions.map(
            (tx) => TransactionSyncMapper.toCreateOperation(
              tx,
              sourceBookId: book.id,
              sourceBookName: book.name,
              sourceBookType: 'remote_book:${book.id}',
            ),
          ),
        );
      }

      return operations;
    },
  );
}
```

### 4.4 增量同步（新增账目时）

#### Push 端：CreateTransactionUseCase 集成

```dart
// lib/application/accounting/create_transaction_use_case.dart
// 在现有 execute() 方法末尾添加同步触发

Future<Result<Transaction>> execute(CreateTransactionParams params) async {
  // ... 现有创建逻辑 (步骤 1-10) ...

  // 11. 触发增量同步（异步，不阻塞返回）
  _triggerIncrementalSync(transaction);

  return Result.success(transaction);
}

void _triggerIncrementalSync(Transaction transaction) {
  // fire-and-forget，不影响本地创建结果
  unawaited(
    _syncTriggerService.onTransactionCreated(
      transaction.toSyncMap(),
    ).catchError((e) {
      // 同步失败会自动入队，仅记录日志
      debugPrint('Sync trigger failed: $e');
    }),
  );
}
```

同样的模式应用于 `UpdateTransactionUseCase` 和 `DeleteTransactionUseCase`。

#### Pull 端：applyOperations 实现

```dart
// lib/application/family_sync/apply_sync_operations_use_case.dart

class ApplySyncOperationsUseCase {
  final TransactionRepository _transactionRepo;
  final ShadowBookService _shadowBookService;

  Future<void> execute(List<Map<String, dynamic>> operations) async {
    for (final op in operations) {
      final entityType = op['entityType'] as String?;
      if (entityType != 'bill') continue;  // 目前仅处理 bill

      final opType = op['op'] as String;
      final entityId = op['entityId'] as String;
      final data = op['data'] as Map<String, dynamic>?;
      final fromDeviceId = op['fromDeviceId'] as String?;

      switch (opType) {
        case 'create':
        case 'insert':
          await _handleCreate(entityId, data!, fromDeviceId!);
        case 'update':
          await _handleUpdate(entityId, data!, fromDeviceId!);
        case 'delete':
          await _handleDelete(entityId);
      }
    }
  }

  Future<void> _handleCreate(
    String entityId,
    Map<String, dynamic> data,
    String fromDeviceId,
  ) async {
    // 幂等：如果已存在则跳过
    final existing = await _transactionRepo.findById(entityId);
    if (existing != null) return;

    // 查找该 deviceId 对应的 Shadow Book
    final shadowBook = await _shadowBookService.findShadowBook(fromDeviceId);
    if (shadowBook == null) {
      debugPrint('No shadow book for device: $fromDeviceId');
      return;
    }

    // 构建 Transaction，bookId 指向 Shadow Book，并保留来源 book 维度
    final transaction = Transaction.fromSyncMap(
      data,
      bookId: shadowBook.id,     // 写入 Shadow Book
      isSynced: true,            // 标记为同步数据
    );

    await _transactionRepo.insert(transaction);
  }

  Future<void> _handleUpdate(
    String entityId,
    Map<String, dynamic> data,
    String fromDeviceId,
  ) async {
    final existing = await _transactionRepo.findById(entityId);
    if (existing == null) {
      // 没有旧数据，当作 create 处理
      await _handleCreate(entityId, data, fromDeviceId);
      return;
    }

    final updated = existing.copyWith(
      amount: data['amount'] as int? ?? existing.amount,
      note: data['note'] as String?,
      categoryId: data['categoryId'] as String? ?? existing.categoryId,
      merchant: data['merchant'] as String?,
      updatedAt: DateTime.now(),
    );

    await _transactionRepo.update(updated);
  }

  Future<void> _handleDelete(String entityId) async {
    await _transactionRepo.softDelete(entityId);
  }
}
```

#### Provider 连接

```dart
// lib/features/family_sync/presentation/providers/sync_providers.dart

@riverpod
ApplySyncOperationsUseCase applySyncOperationsUseCase(Ref ref) {
  return ApplySyncOperationsUseCase(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
  );
}

@riverpod
PullSyncUseCase pullSyncUseCase(Ref ref) {
  final applyOps = ref.watch(applySyncOperationsUseCaseProvider);

  return PullSyncUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
    groupRepo: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    keyManager: ref.watch(keyManagerProvider),
    applyOperations: (operations) => applyOps.execute(operations),
  );
}
```

### 4.5 Group 有效性检查 + 同步数据清理

#### 触发时机

在**每次新增账单前**检查当前 Group 是否仍有效。

#### CheckGroupValidityUseCase

```dart
// lib/application/family_sync/check_group_validity_use_case.dart

sealed class GroupValidityResult {
  const factory GroupValidityResult.valid() = GroupValid;
  const factory GroupValidityResult.noGroup() = GroupNoGroup;
  const factory GroupValidityResult.invalid(String reason) = GroupInvalid;
}

class CheckGroupValidityUseCase {
  final GroupRepository _groupRepo;
  final RelayApiClient _apiClient;
  final ShadowBookService _shadowBookService;

  Future<GroupValidityResult> execute() async {
    // 1. 检查本地是否有 active group
    final group = await _groupRepo.getActiveGroup();
    if (group == null) {
      return const GroupValidityResult.noGroup();
    }

    // 2. 向服务器确认 group 状态
    try {
      await _apiClient.checkGroup();
      return const GroupValidityResult.valid();
    } on RelayApiException catch (e) {
      if (e.isNotFound || e.isForbidden) {
        // Group 已不存在或设备已被移除
        await _handleInvalidGroup(group);
        return GroupValidityResult.invalid(
          e.isNotFound ? 'Group dissolved' : 'Removed from group',
        );
      }
      // 网络错误等其他情况，视为有效（离线容错）
      return const GroupValidityResult.valid();
    } catch (_) {
      // 网络不可达，宽容处理
      return const GroupValidityResult.valid();
    }
  }

  Future<void> _handleInvalidGroup(GroupInfo group) async {
    // 1. 清理同步数据（删除 Shadow Book 及其所有交易）
    await _shadowBookService.cleanSyncData(group.groupId);

    // 2. 将 Group 状态设为 inactive
    await _groupRepo.deactivateGroup(group.groupId);
  }
}
```

#### 集成到 CreateTransactionUseCase

```dart
Future<Result<Transaction>> execute(CreateTransactionParams params) async {
  // 0. 检查 Group 有效性（如果当前在 Group 中）
  final groupCheck = await _checkGroupValidity.execute();
  if (groupCheck is GroupInvalid) {
    // Group 已失效，同步数据已清理
    // 继续创建本地账单（不触发同步）
    debugPrint('Group invalidated: ${groupCheck.reason}');
  }

  // 1-10. 现有创建逻辑 ...

  // 11. 仅在 Group 有效时触发同步
  if (groupCheck is GroupValid) {
    _triggerIncrementalSync(transaction);
  }

  return Result.success(transaction);
}
```

#### 性能优化：缓存与节流

```dart
/// 避免每次创建账单都请求服务器
class GroupValidityCache {
  DateTime? _lastCheckTime;
  GroupValidityResult? _cachedResult;

  static const _cacheDuration = Duration(minutes: 5);

  bool get isExpired =>
      _lastCheckTime == null ||
      DateTime.now().difference(_lastCheckTime!) > _cacheDuration;

  GroupValidityResult? get cachedResult => isExpired ? null : _cachedResult;

  void update(GroupValidityResult result) {
    _cachedResult = result;
    _lastCheckTime = DateTime.now();
  }

  void invalidate() {
    _lastCheckTime = null;
    _cachedResult = null;
  }
}
```

集成到 `CheckGroupValidityUseCase`：

```dart
Future<GroupValidityResult> execute({bool forceCheck = false}) async {
  // 优先使用缓存
  if (!forceCheck) {
    final cached = _cache.cachedResult;
    if (cached != null) return cached;
  }

  // ... 实际检查逻辑 ...

  _cache.update(result);
  return result;
}
```

### 4.6 Transaction 序列化/反序列化

```dart
// lib/features/accounting/domain/models/transaction.dart 扩展

extension TransactionSyncExtension on Transaction {
  /// 序列化为同步 payload
  Map<String, dynamic> toSyncMap({
    required String sourceBookId,
    required String sourceBookName,
    required String sourceBookType,
  }) {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'ledgerType': ledgerType.name,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'merchant': merchant,
      'metadata': {
        ...?metadata,
        'sourceBookId': sourceBookId,
        'sourceBookName': sourceBookName,
        'sourceBookType': sourceBookType,
      },
      'soulSatisfaction': soulSatisfaction,
      'isPrivate': isPrivate,
      'createdAt': createdAt.toIso8601String(),
    };
    // 注意：不包含 bookId（对方有自己的 book）
    // 注意：不包含 hash chain 字段（per-book 独立）
    // 注意：不包含 deviceId（从 sync message 的 fromDeviceId 获取）
  }

  /// 从同步 payload 反序列化
  static Transaction fromSyncMap(
    Map<String, dynamic> data, {
    required String bookId,
    required bool isSynced,
  }) {
    return Transaction(
      id: data['id'] as String,
      bookId: bookId,
      deviceId: data['deviceId'] as String? ?? '',
      amount: data['amount'] as int,
      type: TransactionType.values.byName(data['type'] as String),
      categoryId: data['categoryId'] as String,
      ledgerType: LedgerType.values.byName(data['ledgerType'] as String),
      timestamp: DateTime.parse(data['timestamp'] as String),
      note: data['note'] as String?,
      merchant: data['merchant'] as String?,
      soulSatisfaction: data['soulSatisfaction'] as int? ?? 5,
      isPrivate: data['isPrivate'] as bool? ?? false,
      isSynced: isSynced,
      currentHash: '',  // Shadow Book 不维护 hash chain
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(
        data['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
```

---

## 5. 家庭视图聚合

### 5.1 聚合 Provider

```dart
// lib/features/home/presentation/providers/family_transactions_provider.dart

@riverpod
Future<List<Transaction>> familyTransactions(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final bookRepo = ref.watch(bookRepositoryProvider);
  final txRepo = ref.watch(transactionRepositoryProvider);

  // 获取所有 book（本地 + Shadow Books）
  final allBooks = await bookRepo.getAllActiveBooks();

  final allTransactions = <Transaction>[];
  for (final book in allBooks) {
    final txs = await txRepo.findByBookId(
      book.id,
      startDate: startDate,
      endDate: endDate,
    );
    allTransactions.addAll(txs);
  }

  // 按时间排序
  allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return allTransactions;
}
```

### 5.2 月度总览扩展

```dart
// HomeScreen 的 MonthOverviewCard 需要区分：
// - 我的支出: 仅本地 bookId
// - 家庭支出: 本地 + 所有 Shadow Book
// - 对方支出: 仅 Shadow Book(s)
```

---

## 6. 实现阶段

### Phase 1: Schema + Shadow Book (约 2 天)

- [ ] Books 表添加 `isShadow`, `groupId`, `ownerDeviceId`, `ownerDeviceName` 字段
- [ ] BookDao 添加 Shadow Book CRUD 方法
- [ ] BookRepository 接口和实现扩展
- [ ] ShadowBookService 实现
- [ ] Drift migration
- [ ] 单元测试

### Phase 2: applyOperations 实现 (约 2 天)

- [ ] Transaction.toSyncMap() / fromSyncMap() 序列化
- [ ] ApplySyncOperationsUseCase 实现
- [ ] PullSyncUseCase provider 连接 applyOperations
- [ ] 幂等性测试（重复 create 不重复插入）
- [ ] 单元测试 + 集成测试

### Phase 3: 增量同步触发 (约 1 天)

- [ ] CreateTransactionUseCase 集成 SyncTriggerService
- [ ] UpdateTransactionUseCase 集成
- [ ] DeleteTransactionUseCase 集成
- [ ] fire-and-forget 模式验证
- [ ] 单元测试

### Phase 4: 全量同步 (约 1 天)

- [ ] FullSyncUseCase 连接 fetchAllTransactions，并附带来源 book metadata
- [ ] InitialSyncUseCase 实现
- [ ] ConfirmMemberUseCase 中触发 InitialSync
- [ ] member_confirmed 推送处理中触发 InitialSync
- [ ] 集成测试

### Phase 5: Group 有效性检查 (约 1 天)

- [ ] CheckGroupValidityUseCase 实现
- [ ] GroupValidityCache 实现
- [ ] CreateTransactionUseCase 集成检查
- [ ] 同步数据清理验证
- [ ] 单元测试

### Phase 6: 家庭视图 (约 2 天)

- [ ] familyTransactionsProvider 实现
- [ ] MonthOverviewCard 家庭视图扩展
- [ ] AnalyticsScreen 家庭聚合
- [ ] UI 测试

---

## 7. 关键设计决策

### 7.1 为什么不用 CRDT 做冲突解决？

当前场景下（家庭记账），冲突概率极低（各自记各自的账）。采用**幂等 + Last-Write-Wins (LWW)** 策略即可：

- 相同 `entityId` 的 `create` 操作幂等（已存在则跳过）
- `update` 使用 `updatedAt` 时间戳作为 LWW 判断
- `delete` 幂等（已删除则跳过）

### 7.2 为什么 Shadow Book 不维护 Hash Chain？

- Hash chain 的目的是验证本地数据完整性
- 远端数据的完整性由 E2EE + 签名保证
- 在 Shadow Book 中维护 hash chain 会增加复杂度，且无实际收益

### 7.3 为什么离线时视为 Group 有效？

- 本地优先架构 — 离线时应该能正常记账
- 同步失败会自动入队
- 下次在线时会自然发现 Group 状态变化

### 7.4 fromDeviceId 如何传递？

- `PullSyncUseCase` 解密消息时，每条消息都有 `fromDeviceId` 字段
- 需要将 `fromDeviceId` 注入到 operations 中传递给 `applyOperations`
- 修改 `PullSyncUseCase._processDataMessage()` 在每个 operation 中添加 `fromDeviceId`

---

## 8. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| Shadow Book currency 与远端 source book 不一致 | 仅影响展示语义 | 统一以本地非 shadow book currency 建 shadow book，来源账本信息放 metadata |
| 全量同步数据量大 | 同步超时 | 已有 chunk 机制（50条/批） |
| 对方删除账单后再同步 | 数据不一致 | soft delete + LWW |
| 多设备同时创建 Shadow Book | 重复 Shadow Book | 用 deviceId 做唯一约束 |
| Group 检查的网络延迟 | 创建账单变慢 | 5分钟缓存 + 异步检查 |

---

## 9. 测试策略

### 单元测试
- ShadowBookService: 创建、查找、清理
- ApplySyncOperationsUseCase: create/update/delete 操作 + 幂等性
- CheckGroupValidityUseCase: valid/invalid/noGroup/offline 场景
- Transaction.toSyncMap() / fromSyncMap() 序列化正确性

### 集成测试
- 全量同步：push 全量 → pull 写入 Shadow Book → 验证数据完整
- 增量同步：本地创建 → push → 模拟 pull → 验证 Shadow Book 更新
- 退出 Group：deactivate → 验证 Shadow Book 和交易已删除
- Group 失效检查：模拟服务器返回 404 → 验证清理逻辑

---

**创建时间:** 2026-03-15
**作者:** Claude
