# ADR-010: CRDT 冲突解决策略增强

**文档编号:** ADR-010
**文档版本:** 2.0 (已接受)
**创建日期:** 2026-02-03
**状态:** ✅ 已接受
**决策者:** Architecture Team
**影响范围:** Family Sync (MOD-003), CRDT Implementation, Data Integrity
**相关 ADR:** ADR-004 (CRDT Sync Protocol)

---

## 📋 状态

**当前状态:** ✅ 已接受
**决策日期:** 2026-02-03
**实施状态:** 待开发

---

## 🎯 背景 (Context)

### 问题描述

在当前的 CRDT 实现中（`ARCH-005_Integration_Patterns.md` 和 `ADR-004_CRDT_Sync.md`），冲突解决策略过于简化，存在严重的数据丢失风险。

#### 当前实现

```dart
// lib/features/accounting/domain/repositories/transaction_repository.dart

abstract class TransactionRepository {
  /// 解决冲突
  Transaction resolveConflict(Transaction local, Transaction remote);
}

// lib/features/accounting/data/repositories/transaction_repository_impl.dart

@override
Transaction resolveConflict(Transaction local, Transaction remote) {
  // ❌ 简单的 Last-Write-Wins (LWW)
  if (remote.updatedAt!.isAfter(local.updatedAt!)) {
    return remote;  // 远程版本更新，使用远程版本
  }
  return local;      // 本地版本更新，使用本地版本
}
```

### 存在的问题

#### 1. 数据丢失风险

**场景: 并发修改同一笔交易**

```dart
// 初始状态
Transaction original = Transaction(
  id: 'tx-001',
  amount: 100,
  note: '晚餐',
  categoryId: 'cat-food',
  updatedAt: DateTime(2026, 2, 1, 18, 0, 0),
);

// Device A (妻子) 修改金额
Transaction localVersion = original.copyWith(
  amount: 120,  // 增加了一道菜
  updatedAt: DateTime(2026, 2, 1, 18, 30, 0),
);

// Device B (丈夫) 修改备注
Transaction remoteVersion = original.copyWith(
  note: '晚餐+宵夜',  // 添加了宵夜说明
  updatedAt: DateTime(2026, 2, 1, 18, 31, 0),  // 稍晚一分钟
);

// 同步时冲突解决
final resolved = resolveConflict(localVersion, remoteVersion);

// 结果: remote.updatedAt 更晚，使用 remoteVersion
// ❌ 问题: 妻子修改的金额 120 丢失了！
// 最终结果: amount=100 (错误), note='晚餐+宵夜' (正确)
```

**影响:**
- ✗ 财务数据不准确
- ✗ 用户修改被默默覆盖
- ✗ 没有任何提示
- ✗ 难以发现和追踪

#### 2. 无法处理字段级冲突

**问题:** 当前实现是整个对象级别的冲突解决，无法精确到字段。

```dart
// 理想情况: 字段级合并
// amount: 120 (来自 Device A)
// note: '晚餐+宵夜' (来自 Device B)
// categoryId: 保持不变

// 实际情况: 对象级覆盖
// 整个 remoteVersion 覆盖 localVersion
// amount, note, categoryId 全部来自同一个版本
```

#### 3. 时钟漂移问题

**问题:** 依赖设备本地时间戳不可靠。

```dart
// Device A 时间快了 5 分钟
localVersion.updatedAt = DateTime(2026, 2, 1, 18, 35, 0);

// Device B 时间正常
remoteVersion.updatedAt = DateTime(2026, 2, 1, 18, 30, 0);

// 结果: Device A 的修改总是胜出（即使 Device B 修改更晚）
// ❌ 时钟快的设备永远占优势
```

**影响:**
- ✗ 冲突解决结果不正确
- ✗ 依赖设备时间同步
- ✗ 用户无法调整设备时间

#### 4. 缺少因果关系判断

**问题:** 无法判断两个修改之间的因果关系。

```dart
// 场景1: 顺序修改 (有因果关系)
// Device A: 修改 amount = 100 (T1)
// Device B: 看到修改后，再修改 note = '晚餐' (T2)
// 正确做法: Device B 的修改应该包含 Device A 的修改

// 场景2: 并发修改 (无因果关系)
// Device A: 修改 amount = 100 (T1)
// Device B: 修改 note = '晚餐' (T1, 同时发生)
// 正确做法: 需要合并两个修改

// 当前实现: 无法区分这两种情况
// 都使用 Last-Write-Wins，可能丢失数据
```

#### 5. 删除冲突未处理

**场景: 一方删除，一方修改**

```dart
// Device A: 删除交易
localVersion = null;  // 或 isDeleted = true

// Device B: 修改交易
remoteVersion = transaction.copyWith(amount: 150);

// 同步时如何处理？
// 选项1: 删除优先 (丢失修改)
// 选项2: 修改优先 (忽略删除意图)
// 选项3: 提示用户选择

// 当前实现: 未明确处理，行为不确定
```

#### 6. 缺少冲突记录和通知

**问题:** 用户不知道发生了冲突。

```dart
// 当前实现
final resolved = resolveConflict(local, remote);
await repo.update(resolved);

// ❌ 问题:
// - 没有记录发生了冲突
// - 没有告诉用户哪个修改被覆盖了
// - 无法撤销错误的冲突解决
// - 难以调试和追踪问题
```

**影响:**
- ✗ 用户发现数据不对，但不知道原因
- ✗ 无法追溯冲突历史
- ✗ 难以改进冲突解决策略

---

## 🔍 考虑的方案 (Considered Options)

### 方案 1: 字段级合并（Field-Level Merge）

**描述:** 针对每个字段单独判断冲突，而非整个对象级别。

**实现:**

```dart
@override
Transaction resolveConflict(Transaction local, Transaction remote) {
  // 对每个字段进行独立的冲突解决

  return Transaction(
    id: local.id,  // ID 不变
    bookId: local.bookId,
    deviceId: local.deviceId,

    // 金额字段: 如果两者都修改了，使用较新的
    amount: _resolveAmount(local, remote),

    // 备注字段: 如果两者都修改了，尝试合并
    note: _resolveNote(local, remote),

    // 分类: 使用较新的修改
    categoryId: _resolveCategoryId(local, remote),

    // 其他字段类似...
    type: _resolveField(local.type, remote.type, local.updatedAt, remote.updatedAt),
    ledgerType: _resolveField(local.ledgerType, remote.ledgerType, local.updatedAt, remote.updatedAt),

    // 时间戳: 使用较新的
    timestamp: local.updatedAt!.isAfter(remote.updatedAt!)
        ? local.timestamp
        : remote.timestamp,

    // 哈希链: 需要重新计算
    prevHash: local.prevHash,
    currentHash: '',  // 稍后重新计算

    // 元数据
    createdAt: local.createdAt,
    updatedAt: DateTime.now(),
    isPrivate: _resolveField(local.isPrivate, remote.isPrivate, local.updatedAt, remote.updatedAt),
  );
}

/// 解决金额冲突
int _resolveAmount(Transaction local, Transaction remote) {
  // 如果金额相同，无冲突
  if (local.amount == remote.amount) {
    return local.amount;
  }

  // 金额不同，使用较新的修改
  return local.updatedAt!.isAfter(remote.updatedAt!)
      ? local.amount
      : remote.amount;
}

/// 解决备注冲突
String? _resolveNote(Transaction local, Transaction remote) {
  // 如果备注相同，无冲突
  if (local.note == remote.note) {
    return local.note;
  }

  // 如果一方为空，使用非空的
  if (local.note == null || local.note!.isEmpty) {
    return remote.note;
  }
  if (remote.note == null || remote.note!.isEmpty) {
    return local.note;
  }

  // 两者都有内容且不同
  // 策略1: 使用较新的
  if (local.updatedAt!.isAfter(remote.updatedAt!)) {
    return local.note;
  }

  // 策略2: 尝试合并（如果内容不重叠）
  // 例如: local='晚餐', remote='宵夜' => '晚餐+宵夜'
  if (!local.note!.contains(remote.note!) && !remote.note!.contains(local.note!)) {
    return '${local.note} / ${remote.note}';
  }

  return remote.note;
}

/// 通用字段解决
T _resolveField<T>(T local, T remote, DateTime localTime, DateTime remoteTime) {
  if (local == remote) {
    return local;
  }
  return localTime.isAfter(remoteTime) ? local : remote;
}
```

**优点:**
- ✅ 减少数据丢失（字段级精度）
- ✅ 更智能的合并策略
- ✅ 可以针对不同字段使用不同策略
- ✅ 实现相对简单

**缺点:**
- ❌ 仍然依赖时间戳（时钟漂移问题）
- ❌ 无法处理复杂的依赖关系
- ❌ 备注合并可能不符合用户意图
- ❌ 没有记录冲突发生

**适用场景:**
- MVP 阶段快速实现
- 冲突较少的场景
- 对数据完整性要求不是极高

**风险评估:**
- **数据丢失风险:** ⚠️ 中（仍有可能）
- **用户体验:** ⚠️ 中（静默解决）
- **实现复杂度:** ✅ 低

---

### 方案 2: 向量时钟 + 因果关系判断（Vector Clock）⭐

**描述:** 使用向量时钟精确判断操作的因果关系，避免覆盖并发修改。

**核心概念:**

**向量时钟 (Vector Clock):**
```dart
/// 向量时钟: 记录每个设备的逻辑时间
class VectorClock {
  final Map<String, int> clocks;  // deviceId -> logicalTime

  VectorClock(this.clocks);

  /// 增加本设备的逻辑时钟
  VectorClock increment(String deviceId) {
    final newClocks = Map<String, int>.from(clocks);
    newClocks[deviceId] = (newClocks[deviceId] ?? 0) + 1;
    return VectorClock(newClocks);
  }

  /// 合并两个向量时钟（取每个设备的最大值）
  VectorClock merge(VectorClock other) {
    final allDeviceIds = {...clocks.keys, ...other.clocks.keys};
    final mergedClocks = <String, int>{};

    for (final deviceId in allDeviceIds) {
      final ourTime = clocks[deviceId] ?? 0;
      final theirTime = other.clocks[deviceId] ?? 0;
      mergedClocks[deviceId] = max(ourTime, theirTime);
    }

    return VectorClock(mergedClocks);
  }

  /// 比较两个向量时钟
  ClockComparison compare(VectorClock other) {
    bool weAreAhead = false;
    bool theyAreAhead = false;

    final allDeviceIds = {...clocks.keys, ...other.clocks.keys};

    for (final deviceId in allDeviceIds) {
      final ourTime = clocks[deviceId] ?? 0;
      final theirTime = other.clocks[deviceId] ?? 0;

      if (ourTime > theirTime) {
        weAreAhead = true;
      } else if (theirTime > ourTime) {
        theyAreAhead = true;
      }
    }

    if (weAreAhead && !theyAreAhead) {
      return ClockComparison.after;  // 我们的版本更新
    } else if (theyAreAhead && !weAreAhead) {
      return ClockComparison.before;  // 他们的版本更新
    } else if (weAreAhead && theyAreAhead) {
      return ClockComparison.concurrent;  // 并发修改
    } else {
      return ClockComparison.equal;  // 相同
    }
  }
}

enum ClockComparison {
  before,      // 本地版本过时
  after,       // 本地版本更新
  concurrent,  // 并发修改（冲突）
  equal,       // 相同版本
}
```

**扩展 Transaction 模型:**

```dart
class Transaction {
  final String id;
  final int amount;
  final String? note;
  // ... 其他字段 ...

  // 新增: 向量时钟
  final VectorClock vectorClock;

  // 新增: 最后修改的设备ID
  final String lastModifiedBy;

  Transaction({
    required this.id,
    required this.amount,
    this.note,
    // ...
    required this.vectorClock,
    required this.lastModifiedBy,
  });
}
```

**冲突解决实现:**

```dart
@override
Transaction resolveConflict(Transaction local, Transaction remote) {
  // 1. 比较向量时钟
  final comparison = local.vectorClock.compare(remote.vectorClock);

  switch (comparison) {
    case ClockComparison.before:
      // 本地版本过时，直接使用远程版本
      return remote;

    case ClockComparison.after:
      // 本地版本更新，保留本地版本
      return local;

    case ClockComparison.equal:
      // 相同版本，无需解决
      return local;

    case ClockComparison.concurrent:
      // 并发修改，需要合并
      return _mergeConcurrentModifications(local, remote);
  }
}

/// 合并并发修改
Transaction _mergeConcurrentModifications(
  Transaction local,
  Transaction remote,
) {
  // 字段级合并
  return Transaction(
    id: local.id,

    // 金额: 使用设备ID的字典序决定（确定性）
    amount: local.lastModifiedBy.compareTo(remote.lastModifiedBy) > 0
        ? local.amount
        : remote.amount,

    // 备注: 尝试合并
    note: _mergeNotes(local.note, remote.note),

    // 其他字段: 使用设备ID字典序
    categoryId: local.lastModifiedBy.compareTo(remote.lastModifiedBy) > 0
        ? local.categoryId
        : remote.categoryId,

    // 向量时钟: 合并
    vectorClock: local.vectorClock.merge(remote.vectorClock),

    // 最后修改设备: 使用字典序较大的
    lastModifiedBy: local.lastModifiedBy.compareTo(remote.lastModifiedBy) > 0
        ? local.lastModifiedBy
        : remote.lastModifiedBy,

    // 时间戳: 使用当前时间
    updatedAt: DateTime.now(),
  );
}

String? _mergeNotes(String? local, String? remote) {
  if (local == null || local.isEmpty) return remote;
  if (remote == null || remote.isEmpty) return local;
  if (local == remote) return local;

  // 简单合并策略
  return '$local / $remote';
}
```

**修改操作时更新向量时钟:**

```dart
class TransactionRepositoryImpl {
  final String _currentDeviceId;

  @override
  Future<void> update(Transaction transaction) async {
    // 增加本设备的向量时钟
    final updatedTransaction = transaction.copyWith(
      vectorClock: transaction.vectorClock.increment(_currentDeviceId),
      lastModifiedBy: _currentDeviceId,
      updatedAt: DateTime.now(),
    );

    // 保存到数据库
    await _db.transaction(() async {
      // ... 保存逻辑 ...
    });
  }
}
```

**同步时合并向量时钟:**

```dart
class SyncService {
  Future<void> sync() async {
    // 1. 获取本地和远程的变更
    final localChanges = await _localRepo.getChanges();
    final remoteChanges = await _remoteRepo.getChanges();

    // 2. 对每个交易进行冲突检测和解决
    for (final remoteChange in remoteChanges) {
      final localVersion = await _localRepo.findById(remoteChange.id);

      if (localVersion != null) {
        // 存在冲突，解决
        final resolved = _localRepo.resolveConflict(localVersion, remoteChange);
        await _localRepo.update(resolved);
      } else {
        // 不存在，直接插入
        await _localRepo.insert(remoteChange);
      }
    }

    // 3. 发送本地变更到远程
    for (final localChange in localChanges) {
      await _remoteRepo.apply(localChange);
    }
  }
}
```

**优点:**
- ✅ **精确的因果关系判断**（解决时钟漂移问题）
- ✅ **不依赖设备时间**（使用逻辑时钟）
- ✅ **确定性的冲突解决**（相同输入总是相同输出）
- ✅ **理论基础扎实**（学术界广泛研究）
- ✅ **可扩展**（支持任意数量设备）

**缺点:**
- ⚠️ **数据模型变更**（需要添加 vectorClock 字段）
- ⚠️ **存储开销增加**（每个交易多存储向量时钟）
- ⚠️ **实现复杂度中等**（需要理解向量时钟原理）
- ⚠️ **并发冲突仍需合并策略**（向量时钟只能检测，不能自动解决）

**适用场景:**
- ✅ 生产环境（推荐）
- ✅ 对数据完整性要求高
- ✅ 多设备频繁同步
- ✅ 长期项目

**风险评估:**
- **数据丢失风险:** ✅ 低（精确检测并发）
- **用户体验:** ⚠️ 中（仍需合并策略）
- **实现复杂度:** ⚠️ 中

**存储开销分析:**

```dart
// 假设 3 个设备
VectorClock {
  'device-a': 125,
  'device-b': 89,
  'device-c': 67,
}

// 存储为 JSON: ~60 bytes
// 每笔交易额外存储 ~60 bytes
// 10,000 笔交易 = 600 KB
// 可接受的开销
```

---

### 方案 3: 冲突记录 + 用户手动解决

**描述:** 检测到冲突时，不自动解决，而是记录冲突并让用户选择。

**实现:**

**冲突记录数据模型:**

```dart
/// 冲突记录表
class Conflicts extends Table {
  TextColumn get id => text()();  // 冲突ID
  TextColumn get transactionId => text()();  // 交易ID
  TextColumn get bookId => text()();
  TextColumn get localVersion => text()();  // JSON
  TextColumn get remoteVersion => text()();  // JSON
  DateTimeColumn get detectedAt => dateTime()();
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();
  TextColumn get resolvedVersion => text().nullable()();  // 用户选择的版本
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ConflictRecord {
  final String id;
  final String transactionId;
  final String bookId;
  final Transaction localVersion;
  final Transaction remoteVersion;
  final DateTime detectedAt;
  final bool isResolved;
  final Transaction? resolvedVersion;
  final DateTime? resolvedAt;

  ConflictRecord({
    required this.id,
    required this.transactionId,
    required this.bookId,
    required this.localVersion,
    required this.remoteVersion,
    required this.detectedAt,
    this.isResolved = false,
    this.resolvedVersion,
    this.resolvedAt,
  });
}
```

**冲突解决实现:**

```dart
@override
Transaction resolveConflict(Transaction local, Transaction remote) {
  // 1. 检查是否有实际冲突
  if (_hasRealConflict(local, remote)) {
    // 2. 创建冲突记录
    _createConflictRecord(local, remote);

    // 3. 暂时保留本地版本（用户未解决前）
    return local.copyWith(
      hasUnresolvedConflict: true,  // 标记有未解决冲突
    );
  }

  // 4. 无实际冲突，简单合并
  return _simpleResolve(local, remote);
}

/// 检查是否有实际冲突
bool _hasRealConflict(Transaction local, Transaction remote) {
  // 如果向量时钟显示并发修改
  final comparison = local.vectorClock.compare(remote.vectorClock);
  if (comparison != ClockComparison.concurrent) {
    return false;  // 不是并发修改，不算冲突
  }

  // 检查关键字段是否不同
  return local.amount != remote.amount ||
         local.note != remote.note ||
         local.categoryId != remote.categoryId ||
         local.type != remote.type ||
         local.ledgerType != remote.ledgerType;
}

/// 创建冲突记录
Future<void> _createConflictRecord(
  Transaction local,
  Transaction remote,
) async {
  final conflict = ConflictRecord(
    id: Ulid().toString(),
    transactionId: local.id,
    bookId: local.bookId,
    localVersion: local,
    remoteVersion: remote,
    detectedAt: DateTime.now(),
  );

  await _conflictRepo.insert(conflict);

  // 发送通知
  _notificationService.showConflictNotification(conflict);
}
```

**用户界面:**

```dart
/// 冲突解决页面
class ConflictResolutionScreen extends ConsumerWidget {
  final ConflictRecord conflict;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('解决冲突'),
      ),
      body: Column(
        children: [
          // 说明
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '这笔交易在多个设备上被同时修改，请选择要保留的版本：',
              style: TextStyle(fontSize: 16),
            ),
          ),

          // 本地版本
          _VersionCard(
            title: '本设备的版本',
            transaction: conflict.localVersion,
            onSelect: () => _resolveWithLocal(context, ref),
          ),

          SizedBox(height: 16),

          // 远程版本
          _VersionCard(
            title: '其他设备的版本',
            transaction: conflict.remoteVersion,
            onSelect: () => _resolveWithRemote(context, ref),
          ),

          SizedBox(height: 16),

          // 手动合并
          ElevatedButton(
            onPressed: () => _manualMerge(context, ref),
            child: Text('手动合并'),
          ),
        ],
      ),
    );
  }

  void _resolveWithLocal(BuildContext context, WidgetRef ref) async {
    await ref.read(conflictRepoProvider).resolve(
      conflictId: conflict.id,
      resolvedVersion: conflict.localVersion,
    );

    Navigator.pop(context);
  }

  void _resolveWithRemote(BuildContext context, WidgetRef ref) async {
    await ref.read(conflictRepoProvider).resolve(
      conflictId: conflict.id,
      resolvedVersion: conflict.remoteVersion,
    );

    Navigator.pop(context);
  }

  void _manualMerge(BuildContext context, WidgetRef ref) {
    // 打开编辑页面，允许用户手动合并两个版本
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConflictMergeEditor(conflict: conflict),
      ),
    );
  }
}

/// 版本卡片
class _VersionCard extends StatelessWidget {
  final String title;
  final Transaction transaction;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),

            // 显示交易详情
            _DetailRow(label: '金额', value: '¥${transaction.amount}'),
            _DetailRow(label: '备注', value: transaction.note ?? '无'),
            _DetailRow(label: '分类', value: transaction.categoryId),
            _DetailRow(
              label: '修改时间',
              value: transaction.updatedAt.toString(),
            ),

            SizedBox(height: 12),

            // 选择按钮
            ElevatedButton(
              onPressed: onSelect,
              child: Text('使用此版本'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**冲突通知:**

```dart
/// 冲突通知服务
class NotificationService {
  void showConflictNotification(ConflictRecord conflict) {
    // 显示通知
    LocalNotification.show(
      title: '发现数据冲突',
      body: '交易"${conflict.localVersion.note}"存在冲突，请手动解决',
      payload: conflict.id,
      onTap: () {
        // 打开冲突解决页面
        navigateToConflictResolution(conflict);
      },
    );

    // 在应用内显示Badge
    _conflictBadgeProvider.increment();
  }
}
```

**优点:**
- ✅ **零数据丢失**（用户做决定）
- ✅ **用户完全控制**（透明化）
- ✅ **可审计**（保留冲突历史）
- ✅ **灵活**（支持手动合并）

**缺点:**
- ❌ **用户体验差**（需要用户介入）
- ❌ **增加认知负担**（用户需要理解冲突）
- ❌ **实现复杂**（需要完整的UI流程）
- ❌ **存储开销**（需要额外的冲突记录表）

**适用场景:**
- 关键财务数据（不能容忍自动解决）
- 冲突较少的场景（不频繁打扰用户）
- 专业用户（理解冲突概念）

**风险评估:**
- **数据丢失风险:** ✅ 极低（用户决定）
- **用户体验:** ❌ 差（打断工作流）
- **实现复杂度:** ❌ 高

---

### 方案 4: 操作型 CRDT (Operation-based)

**描述:** 不传输最终状态，而是传输操作序列，通过重放操作达到一致。

**核心概念:**

```dart
/// 操作类型
enum OperationType {
  create,
  updateAmount,
  updateNote,
  updateCategory,
  delete,
}

/// 操作记录
class Operation {
  final String id;
  final String transactionId;
  final OperationType type;
  final Map<String, dynamic> data;
  final VectorClock vectorClock;
  final DateTime timestamp;
  final String deviceId;

  Operation({
    required this.id,
    required this.transactionId,
    required this.type,
    required this.data,
    required this.vectorClock,
    required this.timestamp,
    required this.deviceId,
  });
}

/// 操作序列
class OperationLog {
  final List<Operation> operations;

  OperationLog(this.operations);

  /// 应用操作序列到交易
  Transaction apply(Transaction? initial) {
    var current = initial;

    for (final op in operations) {
      current = _applyOperation(current, op);
    }

    return current!;
  }

  Transaction? _applyOperation(Transaction? current, Operation op) {
    switch (op.type) {
      case OperationType.create:
        return Transaction.fromJson(op.data);

      case OperationType.updateAmount:
        return current?.copyWith(amount: op.data['amount']);

      case OperationType.updateNote:
        return current?.copyWith(note: op.data['note']);

      case OperationType.updateCategory:
        return current?.copyWith(categoryId: op.data['categoryId']);

      case OperationType.delete:
        return current?.copyWith(isDeleted: true);

      default:
        return current;
    }
  }
}
```

**修改操作记录:**

```dart
class TransactionRepositoryImpl {
  final OperationLogRepository _operationLogRepo;

  @override
  Future<void> updateAmount(String transactionId, int newAmount) async {
    // 1. 创建操作记录
    final operation = Operation(
      id: Ulid().toString(),
      transactionId: transactionId,
      type: OperationType.updateAmount,
      data: {'amount': newAmount},
      vectorClock: _getCurrentVectorClock().increment(_deviceId),
      timestamp: DateTime.now(),
      deviceId: _deviceId,
    );

    // 2. 保存操作记录
    await _operationLogRepo.insert(operation);

    // 3. 应用操作到本地交易
    final transaction = await findById(transactionId);
    final updated = transaction!.copyWith(amount: newAmount);
    await _updateLocal(updated);
  }
}
```

**同步时交换操作:**

```dart
class SyncService {
  Future<void> sync() async {
    // 1. 获取本地和远程的操作日志
    final localOps = await _localOperationRepo.getOperations(since: lastSyncTime);
    final remoteOps = await _remoteOperationRepo.getOperations(since: lastSyncTime);

    // 2. 合并操作日志（按向量时钟排序）
    final mergedOps = _mergeOperations(localOps, remoteOps);

    // 3. 重放操作到本地
    for (final op in mergedOps) {
      await _applyOperation(op);
    }
  }

  List<Operation> _mergeOperations(
    List<Operation> local,
    List<Operation> remote,
  ) {
    // 按照向量时钟的因果关系排序
    final all = [...local, ...remote];
    all.sort((a, b) {
      final comparison = a.vectorClock.compare(b.vectorClock);
      if (comparison == ClockComparison.before) return -1;
      if (comparison == ClockComparison.after) return 1;
      // 并发操作：使用设备ID字典序
      return a.deviceId.compareTo(b.deviceId);
    });
    return all;
  }
}
```

**优点:**
- ✅ **理论上最准确**（记录所有操作）
- ✅ **可重放**（可以重建任意时刻的状态）
- ✅ **支持复杂合并**（操作级别）

**缺点:**
- ❌ **实现极其复杂**（需要操作转换算法）
- ❌ **存储开销巨大**（需要保存所有操作历史）
- ❌ **性能问题**（重放操作慢）
- ❌ **不适合财务应用**（交易是原子的，不需要操作级别）

**适用场景:**
- ❌ **不推荐用于本项目**
- 适合文本协作编辑（Google Docs）
- 适合需要完整历史的场景

**风险评估:**
- **数据丢失风险:** ✅ 极低
- **用户体验:** ⚠️ 中
- **实现复杂度:** ❌ 极高

---

## 📊 方案对比总结

| 方案 | 数据丢失风险 | 用户体验 | 实现复杂度 | 存储开销 | 性能 | 推荐度 |
|------|------------|---------|-----------|---------|------|--------|
| 方案1: 字段级合并 | ⚠️ 中 | ✅ 好 | ✅ 低 | ✅ 无 | ✅ 优秀 | ⭐⭐⭐ |
| **方案2: 向量时钟** | **✅ 低** | **✅ 好** | **⚠️ 中** | **⚠️ 小** | **✅ 优秀** | **⭐⭐⭐⭐⭐** |
| 方案3: 用户手动解决 | ✅ 极低 | ❌ 差 | ❌ 高 | ⚠️ 中 | ✅ 优秀 | ⭐⭐ |
| 方案4: 操作型CRDT | ✅ 极低 | ⚠️ 中 | ❌ 极高 | ❌ 大 | ❌ 差 | ⭐ |

---

## 💡 推荐方案

**方案 2: 向量时钟 + 因果关系判断**

### 为什么选择此方案？

1. **解决核心问题**
   - ✅ 精确检测并发修改
   - ✅ 不依赖设备时间
   - ✅ 确定性的冲突解决

2. **平衡用户体验**
   - ✅ 自动解决大部分冲突
   - ✅ 不打扰用户
   - ✅ 可配置通知策略

3. **实现可行**
   - ✅ 复杂度适中
   - ✅ 有成熟理论支持
   - ✅ 团队可理解和维护

4. **扩展性好**
   - ✅ 支持任意数量设备
   - ✅ 可后续增强为用户手动解决
   - ✅ 可记录冲突历史

### 实施建议

**Phase 1: 基础实施（MVP）**
- 实现向量时钟
- 实现基本的冲突检测
- 简单的字段级合并策略
- 记录冲突日志（后台）

**Phase 2: 增强（V1.0）**
- 添加冲突通知
- 提供冲突历史查看
- 优化合并策略

**Phase 3: 高级功能（V2.0）**
- 用户可配置冲突解决策略
- 关键冲突转为手动解决
- 冲突分析和统计

---

## ✅ 已决策的问题

以下问题已完成团队讨论和决策（2026-02-03）：

### 1. 并发修改金额的处理

**场景:**
- Device A: 修改金额 100 → 120
- Device B: 修改金额 100 → 150
- 检测到并发修改

**选项:**
- A. 使用设备ID字典序（确定性，但可能不合理）
- B. 使用较大的金额（可能导致记账不准）
- C. 使用较小的金额（更保守）
- D. 转为用户手动解决（打断工作流）✅ **已选择**

**决策:** **D - 转为用户手动解决**

**理由:**
- 金额是财务数据的核心，不能随意选择
- 自动合并可能导致记账错误
- 用户介入可以确保数据准确性
- 并发修改金额的场景相对较少

### 2. 删除冲突的处理

**场景:**
- Device A: 删除交易
- Device B: 修改交易

**选项:**
- A. 删除优先（用户明确想删除）
- B. 修改优先（保留数据）
- C. 转为用户手动解决
- D. 恢复交易，但标记为"曾被删除"✅ **已选择**

**决策:** **D - 恢复交易，标记为"曾被删除"**

**理由:**
- 保留数据，避免永久丢失
- 让用户知道曾经有删除意图
- 用户可以在了解情况后再决定
- 可追溯冲突历史

### 3. 冲突通知的时机

**选项:**
- A. 立即通知（可能频繁打扰）
- B. 批量通知（同步完成后汇总）✅ **已选择**
- C. 不通知（后台记录）
- D. 仅关键冲突通知（金额冲突）

**决策:** **B - 批量通知（同步完成后汇总）**

**理由:**
- 避免频繁打扰用户
- 一次性展示所有冲突，用户可集中处理
- 提供完整的同步结果反馈
- 仍然保证用户知情

### 4. 向量时钟的清理策略

**问题:** 向量时钟会随着设备增加而膨胀。

**选项:**
- A. 不清理（接受存储开销）✅ **已选择**
- B. 定期清理离线设备（可能影响后续同步）
- C. 使用版本向量（更紧凑的表示）
- D. 设置设备数量上限（限制家庭成员数）

**决策:** **A - 不清理（接受存储开销）**

**理由:**
- 根据 ADR-010 存储分析，开销极低（<$0.0001/年/用户）
- 避免清理带来的同步风险
- 家庭场景设备数量有限（通常 2-4 个）
- 简化实现，提高可靠性

---

## 🔧 实施细节

基于已做的决策，以下是具体的实施方案：

### 实现：金额并发冲突处理

```dart
/// 解决并发冲突
Transaction _mergeConcurrentModifications(
  Transaction local,
  Transaction remote,
) {
  // 检查是否是金额冲突
  final hasAmountConflict = local.amount != remote.amount;

  if (hasAmountConflict) {
    // 决策1: 金额冲突转为用户手动解决
    _createConflictRecord(
      local: local,
      remote: remote,
      conflictType: ConflictType.amountMismatch,
    );

    // 暂时保留本地版本，标记为有冲突
    return local.copyWith(
      hasUnresolvedConflict: true,
      conflictId: _generateConflictId(),
    );
  }

  // 非金额字段：使用字段级合并
  return Transaction(
    id: local.id,
    bookId: local.bookId,

    // 金额保持一致（不冲突）
    amount: local.amount,

    // 备注：尝试合并
    note: _mergeNotes(local.note, remote.note),

    // 分类：使用设备ID字典序
    categoryId: local.lastModifiedBy.compareTo(remote.lastModifiedBy) > 0
        ? local.categoryId
        : remote.categoryId,

    // 向量时钟：合并
    vectorClock: local.vectorClock.merge(remote.vectorClock),

    // 最后修改设备
    lastModifiedBy: local.lastModifiedBy.compareTo(remote.lastModifiedBy) > 0
        ? local.lastModifiedBy
        : remote.lastModifiedBy,

    // 更新时间
    updatedAt: DateTime.now(),
  );
}
```

### 实现：删除冲突处理

```dart
/// 处理删除冲突
Transaction? _handleDeleteConflict(
  Transaction? local,
  Transaction? remote,
) {
  // 场景1: 本地删除 + 远程修改
  if (local == null || local.isDeleted) {
    if (remote != null && !remote.isDeleted) {
      // 决策2: 恢复交易，标记为"曾被删除"
      return remote.copyWith(
        wasDeleted: true,
        deletedBy: local?.lastModifiedBy,
        deletedAt: local?.updatedAt,
        hasUnresolvedConflict: true,
      );
    }
  }

  // 场景2: 远程删除 + 本地修改
  if (remote == null || remote.isDeleted) {
    if (local != null && !local.isDeleted) {
      // 决策2: 恢复交易，标记为"曾被删除"
      return local.copyWith(
        wasDeleted: true,
        deletedBy: remote?.lastModifiedBy,
        deletedAt: remote?.updatedAt,
        hasUnresolvedConflict: true,
      );
    }
  }

  // 双方都删除，保持删除状态
  return local ?? remote;
}
```

### 实现：批量冲突通知

```dart
/// 同步完成后批量通知冲突
class SyncService {
  Future<SyncResult> sync() async {
    final conflicts = <ConflictRecord>[];

    // ... 同步过程中收集冲突 ...

    // 同步完成后，批量通知
    if (conflicts.isNotEmpty) {
      // 决策3: 批量通知（同步完成后汇总）
      await _showConflictSummary(conflicts);
    }

    return SyncResult.success(
      syncedCount: syncedCount,
      conflictsCount: conflicts.length,
    );
  }

  Future<void> _showConflictSummary(List<ConflictRecord> conflicts) async {
    // 显示冲突汇总通知
    await NotificationService.show(
      title: '同步完成 - 发现 ${conflicts.length} 个冲突',
      body: '点击查看并解决冲突',
      payload: {
        'type': 'sync_conflicts',
        'conflicts': conflicts.map((c) => c.id).toList(),
      },
    );

    // 更新Badge
    await _updateConflictBadge(conflicts.length);
  }
}
```

### 实现：向量时钟存储（不清理）

```dart
/// 向量时钟序列化（二进制格式）
class VectorClockCodec {
  /// 序列化为二进制（节省存储）
  Uint8List encode(VectorClock clock) {
    // 决策4: 不清理向量时钟，接受存储开销
    // 使用二进制格式减少存储（参考 ADR-010 存储分析）

    final buffer = BytesBuilder();

    // 写入设备数量
    buffer.addByte(clock.clocks.length);

    // 写入每个设备的时钟
    for (final entry in clock.clocks.entries) {
      // 设备ID（UTF-8，最多 36 字节）
      final deviceIdBytes = utf8.encode(entry.key);
      buffer.addByte(deviceIdBytes.length);
      buffer.add(deviceIdBytes);

      // 时钟值（4字节整数）
      buffer.add(_int32ToBytes(entry.value));
    }

    return buffer.toBytes();
  }

  /// 从二进制反序列化
  VectorClock decode(Uint8List bytes) {
    // ... 反序列化逻辑 ...
  }
}

// Drift 表定义
class Transactions extends Table {
  // ... 其他字段 ...

  // 向量时钟（二进制格式）
  BlobColumn get vectorClock => blob()();

  // 最后修改设备
  TextColumn get lastModifiedBy => text()();

  // 冲突标记
  BoolColumn get hasUnresolvedConflict => boolean().withDefault(const Constant(false))();
  TextColumn get conflictId => text().nullable()();

  // 删除冲突标记
  BoolColumn get wasDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get deletedBy => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
```

### 数据模型扩展

```dart
// lib/features/accounting/domain/models/transaction.dart

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String bookId,
    required int amount,
    String? note,
    required String categoryId,
    required TransactionType type,
    required LedgerType ledgerType,
    required DateTime timestamp,

    // CRDT字段（ADR-010）
    required VectorClock vectorClock,
    required String lastModifiedBy,

    // 冲突管理
    @Default(false) bool hasUnresolvedConflict,
    String? conflictId,

    // 删除冲突标记
    @Default(false) bool wasDeleted,
    String? deletedBy,
    DateTime? deletedAt,

    // 哈希链
    String? prevHash,
    String? currentHash,

    // 元数据
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(false) bool isDeleted,
    @Default(false) bool isPrivate,
    required String deviceId,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
```

---

## 📝 下一步行动

### Phase 1: 数据模型扩展（预计 1 周）

**待办事项:**
- [ ] 在 Transaction 模型中添加 `vectorClock` 字段
- [ ] 在 Transaction 模型中添加 `lastModifiedBy` 字段
- [ ] 扩展数据库 Schema（Drift migration）
- [ ] 实现向量时钟序列化/反序列化

### Phase 2: 向量时钟实现（预计 1 周）

**待办事项:**
- [ ] 实现 `VectorClock` 类
- [ ] 实现向量时钟比较逻辑
- [ ] 实现向量时钟合并逻辑
- [ ] 单元测试覆盖

### Phase 3: 冲突解决实现（预计 1 周）

**待办事项:**
- [ ] 更新 `resolveConflict()` 方法使用向量时钟
- [ ] 实现并发修改检测
- [ ] 实现字段级合并策略
- [ ] 实现删除冲突处理（标记为"曾被删除"）
- [ ] 单元测试和集成测试

### Phase 4: 冲突记录和通知（预计 3 天）

**待办事项:**
- [ ] 创建 Conflicts 表
- [ ] 实现冲突记录功能
- [ ] 实现批量通知机制
- [ ] 实现用户手动解决 UI（金额冲突）
- [ ] 冲突历史查看 UI

### Phase 5: 集成和测试（预计 3 天）

**待办事项:**
- [ ] 集成到现有同步流程
- [ ] 端到端测试
- [ ] 性能测试
- [ ] 用户体验测试

### Phase 6: 文档更新（预计 2 天）

**待办事项:**
- [ ] 更新 ARCH-002_Data_Architecture.md
- [ ] 更新 ARCH-005_Integration_Patterns.md
- [ ] 更新 MOD-003_FamilySync.md
- [ ] 更新 ADR-004_CRDT_Sync.md
- [ ] 编写开发者指南

---

**文档状态:** ✅ 已接受
**决策完成:** 2026-02-03
**预计实施时间:** 4-5 周
**优先级:** P1（高优先级）

---

## Update 2026-04-27: Cleanup Initiative Outcome

**Cross-reference:** [ADR-011](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)

Phase 3 centralization moved the file at line 37 of this ADR
(`lib/features/accounting/data/repositories/transaction_repository_impl.dart`) to
`lib/data/repositories/transaction_repository_impl.dart`. The line-37 reference is
preserved as historical context per ADR append-only convention.

The original decision body above is preserved verbatim per ADR append-only convention
(`.claude/rules/arch.md:171-173`).
