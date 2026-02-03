# ADR-004: 选择Yjs-inspired CRDT方案

**状态:** ✅ 已接受
**日期:** 2026-02-03
**决策者:** 技术架构团队
**影响范围:** 家庭同步功能(MOD-004)

---

## 背景与问题陈述

Home Pocket的家庭同步功能需要支持**多设备离线编辑**,并在设备重新连接时自动合并数据。这是一个经典的分布式系统数据一致性问题。

### 业务需求

1. **离线优先:** 用户在没有网络时可以继续记账
2. **多设备支持:** 夫妻双方各自的设备同时记账
3. **自动同步:** 设备相遇时自动同步数据
4. **冲突解决:** 自动处理并发修改冲突
5. **最终一致性:** 所有设备最终看到相同的数据

### 技术挑战

**场景1: 并发创建**
```
时间 T0:
  Device A: 创建交易 TX-1 (早餐 ¥50)
  Device B: 创建交易 TX-2 (午餐 ¥80)

时间 T1: 设备同步
  问题: TX-1 和 TX-2 如何合并?
  预期: 两笔交易都保留
```

**场景2: 并发修改**
```
时间 T0:
  原始数据: TX-1 (金额: ¥100, 备注: "晚餐")

时间 T1:
  Device A: 修改 TX-1 (金额: ¥120)
  Device B: 修改 TX-1 (备注: "晚餐+宵夜")

时间 T2: 设备同步
  问题: 哪个修改应该生效?
  预期: 智能合并(金额¥120, 备注"晚餐+宵夜")
```

**场景3: 删除冲突**
```
时间 T0:
  Device A: 删除 TX-1
  Device B: 修改 TX-1

时间 T1: 设备同步
  问题: 删除和修改如何处理?
  预期: 删除优先 或 提示用户
```

---

## 决策驱动因素

### 关键考虑因素

1. **冲突解决自动化** - 尽量减少用户介入
2. **数据完整性** - 不能丢失数据
3. **性能** - 同步速度要快
4. **实现复杂度** - 团队能够理解和维护
5. **可扩展性** - 支持未来更多设备

---

## 备选方案分析

### 方案1: Yjs-inspired CRDT ✅ (选择)

**CRDT:** Conflict-free Replicated Data Type (无冲突复制数据类型)

**核心思想:**
- 每个操作都是幂等的(多次应用结果相同)
- 操作可以按任意顺序应用
- 最终所有设备收敛到相同状态

**Yjs特点:**
- 高性能(针对实时协作优化)
- 紧凑的二进制格式
- 经过生产验证(大量实时协作应用使用)

**我们的简化版本:**
- 借鉴Yjs的思想,但针对财务应用简化
- 使用Last-Write-Wins (LWW) + 向量时钟
- 支持操作级别的冲突解决

**数据结构:**

```dart
/// CRDT文档
class CRDTDocument {
  final String id;                    // 交易ID
  final Map<String, int> vectorClock; // {deviceId: counter}
  final int lamportTimestamp;         // Lamport逻辑时钟
  final Transaction data;             // 实际数据
  final bool isDeleted;               // 删除标记(墓碑)

  /// 合并两个版本
  CRDTDocument merge(CRDTDocument other) {
    // 比较向量时钟
    final comparison = _compareVectorClocks(vectorClock, other.vectorClock);

    switch (comparison) {
      case ClockComparison.before:
        return other;  // 对方更新
      case ClockComparison.after:
        return this;   // 本地更新
      case ClockComparison.concurrent:
        // 并发修改,使用LWW策略
        return _resolveConflict(this, other);
    }
  }

  /// 解决冲突
  CRDTDocument _resolveConflict(CRDTDocument local, CRDTDocument remote) {
    // 1. 比较Lamport时间戳
    if (remote.lamportTimestamp > local.lamportTimestamp) {
      return remote;
    } else if (remote.lamportTimestamp < local.lamportTimestamp) {
      return local;
    }

    // 2. 时间戳相同,使用设备ID字典序
    return local.data.deviceId.compareTo(remote.data.deviceId) > 0
      ? local
      : remote;
  }
}

/// 向量时钟比较结果
enum ClockComparison {
  before,      // 本地早于远程
  after,       // 本地晚于远程
  concurrent,  // 并发(无因果关系)
}
```

**向量时钟实现:**

```dart
class VectorClock {
  Map<String, int> _clock = {};

  /// 递增本地计数器
  void increment(String deviceId) {
    _clock[deviceId] = (_clock[deviceId] ?? 0) + 1;
  }

  /// 合并向量时钟
  void merge(Map<String, int> other) {
    for (final entry in other.entries) {
      _clock[entry.key] = max(
        _clock[entry.key] ?? 0,
        entry.value,
      );
    }
    increment(_currentDeviceId);
  }

  /// 比较两个向量时钟
  static ClockComparison compare(
    Map<String, int> a,
    Map<String, int> b,
  ) {
    bool aBeforeB = true;
    bool bBeforeA = true;

    final allDevices = {...a.keys, ...b.keys};

    for (final device in allDevices) {
      final aCount = a[device] ?? 0;
      final bCount = b[device] ?? 0;

      if (aCount > bCount) bBeforeA = false;
      if (bCount > aCount) aBeforeB = false;
    }

    if (aBeforeB && !bBeforeA) return ClockComparison.before;
    if (bBeforeA && !aBeforeB) return ClockComparison.after;
    return ClockComparison.concurrent;
  }
}
```

**同步流程:**

```dart
class SyncService {
  Future<SyncResult> syncWith(String remoteDeviceId) async {
    // 1. 获取本地未同步的操作
    final localChanges = await _getLocalChanges();

    // 2. 发送到远程设备
    final remoteChanges = await _sendAndReceive(
      remoteDeviceId,
      localChanges,
    );

    // 3. 合并远程操作
    final merged = <Transaction>[];
    for (final remoteTx in remoteChanges) {
      final localTx = await _transactionRepo.findById(remoteTx.id);

      if (localTx == null) {
        // 本地不存在,直接插入
        await _transactionRepo.insert(remoteTx);
        merged.add(remoteTx);
      } else {
        // 存在冲突,使用CRDT合并
        final localDoc = _toDocument(localTx);
        final remoteDoc = _toDocument(remoteTx);
        final mergedDoc = localDoc.merge(remoteDoc);

        if (mergedDoc != localDoc) {
          await _transactionRepo.update(mergedDoc.data);
          merged.add(mergedDoc.data);
        }
      }
    }

    // 4. 更新同步状态
    await _updateSyncStatus(merged);

    return SyncResult(
      localSent: localChanges.length,
      remoteReceived: remoteChanges.length,
      merged: merged.length,
    );
  }
}
```

**优势:**
- ✅ 自动冲突解决,无需用户介入
- ✅ 最终一致性保证
- ✅ 支持离线编辑
- ✅ 性能优秀(O(n)复杂度)

**劣势:**
- ⚠️ 实现复杂度高
- ⚠️ 需要维护向量时钟(额外存储)
- ⚠️ LWW可能丢失部分修改

---

### 方案2: Operational Transformation (OT)

**核心思想:**
- 将操作转换为可交换的操作序列
- Google Docs使用的技术

**优势:**
- ✅ 精确的冲突解决
- ✅ 操作可交换

**劣势:**
- ❌ **实现极其复杂** - 需要为每种操作定义转换函数
- ❌ **需要中央服务器** - 维护全局操作顺序
- ❌ **不适合P2P同步** - 我们的场景是设备间直连

**为何不选择:**
- 实现复杂度远超CRDT
- 需要中央服务器,违反隐私优先原则
- 对于财务数据,CRDT的LWW已足够

---

### 方案3: 简单的Last-Write-Wins (无向量时钟)

**实现:**

```dart
Transaction resolveConflict(Transaction local, Transaction remote) {
  // 简单比较时间戳
  if (remote.updatedAt.isAfter(local.updatedAt)) {
    return remote;
  }
  return local;
}
```

**优势:**
- ✅ 实现极其简单

**劣势:**
- ❌ **时钟漂移问题** - 设备时钟不同步会导致错误
- ❌ **并发检测失败** - 无法区分因果关系和并发
- ❌ **数据丢失风险** - 真正的并发修改会丢失一方的更改

**示例问题:**

```
Device A (时钟快1小时):
  2026-02-03 11:00: 修改 TX-1 (金额: ¥100)

Device B (时钟准确):
  2026-02-03 10:30: 修改 TX-1 (金额: ¥120)

同步后:
  结果: ¥100 (错误! 应该是¥120,因为Device B的修改更新)
```

**为何不选择:**
- 无法可靠检测并发
- 依赖设备时钟同步(不现实)
- 数据丢失风险高

---

### 方案4: 三路合并 (3-way Merge)

**核心思想:**
- 记录每个版本的共同祖先
- 合并时比较三个版本: 祖先、本地、远程

**实现:**

```dart
Transaction merge3Way({
  required Transaction ancestor,
  required Transaction local,
  required Transaction remote,
}) {
  // 比较每个字段
  return Transaction(
    amount: _mergeField(
      ancestor.amount,
      local.amount,
      remote.amount,
    ),
    note: _mergeField(
      ancestor.note,
      local.note,
      remote.note,
    ),
    // ...
  );
}

T _mergeField<T>(T ancestor, T local, T remote) {
  if (local == remote) return local;
  if (local == ancestor) return remote;  // 仅远程修改
  if (remote == ancestor) return local;  // 仅本地修改
  // 冲突: 都修改了,需要策略
  return _resolveFieldConflict(local, remote);
}
```

**优势:**
- ✅ 精确的冲突检测
- ✅ 字段级合并

**劣势:**
- ❌ **需要存储祖先版本** - 存储开销大
- ❌ **复杂度高** - 每个字段需要合并逻辑
- ❌ **不适合频繁修改** - Git适合,但财务交易不频繁修改

**为何不选择:**
- 财务交易创建后很少修改
- 存储祖先版本开销不值得
- CRDT的LWW对我们的场景已足够

---

## 决策对比矩阵

| 特性 | Yjs-CRDT | OT | 简单LWW | 3-way Merge |
|------|----------|----|---------|-----------|
| 自动冲突解决 | ✅✅✅ | ✅✅✅ | ✅ | ✅✅ |
| 实现复杂度 | ✅✅ | ❌ | ✅✅✅ | ✅ |
| 并发检测准确性 | ✅✅✅ | ✅✅✅ | ❌ | ✅✅✅ |
| 数据丢失风险 | ✅✅ | ✅✅✅ | ⚠️ | ✅✅ |
| 性能 | ✅✅✅ | ✅✅ | ✅✅✅ | ✅✅ |
| P2P支持 | ✅✅✅ | ❌ | ✅✅✅ | ✅✅✅ |
| 生产验证 | ✅✅✅ | ✅✅✅ | ⚠️ | ✅✅ |

---

## 最终决策

**选择 Yjs-inspired CRDT (Last-Write-Wins + 向量时钟)**

### 核心理由

1. **自动冲突解决** - 用户无需手动处理冲突
2. **并发检测准确** - 向量时钟精确区分因果和并发
3. **最终一致性保证** - 数学证明的收敛性
4. **P2P友好** - 无需中央服务器
5. **生产验证** - Yjs在大量实时协作应用中使用
6. **实现复杂度适中** - 比OT简单,比简单LWW可靠

---

## 实施细节

### 数据模型扩展

```dart
// 在Transaction模型中添加CRDT字段
class Transaction {
  // 原有字段...
  String id;
  int amount;
  String note;

  // CRDT字段
  Map<String, int> vectorClock;  // 向量时钟
  int lamportTimestamp;          // Lamport时间戳
  DateTime createdAt;            // 创建时间(本地)
  DateTime? updatedAt;           // 最后更新时间
}

// 数据库表定义
class Transactions extends Table {
  // ...
  TextColumn get vectorClock => text()();  // JSON格式
  IntColumn get lamportTimestamp => integer()();
}
```

### 同步协议

```
1. 握手阶段
   Device A -> Device B: Hello {deviceId, lastSync}
   Device B -> Device A: Hello {deviceId, lastSync}

2. 差异计算
   Device A: 计算自lastSync以来的变更
   Device B: 计算自lastSync以来的变更

3. 数据交换
   Device A -> Device B: Changes [TX-1, TX-2, ...]
   Device B -> Device A: Changes [TX-3, TX-4, ...]

4. CRDT合并
   Device A: 合并Device B的变更
   Device B: 合并Device A的变更

5. 确认
   Device A -> Device B: Ack
   Device B -> Device A: Ack
```

### 冲突解决策略

**策略1: Last-Write-Wins (默认)**
```dart
// 用于大部分字段
if (remote.lamportTimestamp > local.lamportTimestamp) {
  return remote;
}
```

**策略2: 删除优先**
```dart
// 删除操作优先于修改
if (remote.isDeleted || local.isDeleted) {
  return CRDTDocument(isDeleted: true);
}
```

**策略3: 数值累加 (未来扩展)**
```dart
// 用于计数器等可累加字段
merged.amount = local.amount + remote.amount;
```

---

## 性能优化

### 1. 增量同步

```dart
// 仅同步未同步的交易
final changes = await db.select(db.transactions)
  .where((t) => t.isSynced.equals(false))
  .get();
```

### 2. 压缩向量时钟

```dart
// 定期清理旧设备的向量时钟
Map<String, int> pruneVectorClock(Map<String, int> clock) {
  final now = DateTime.now();
  return Map.fromEntries(
    clock.entries.where((e) {
      final device = deviceRegistry.get(e.key);
      return device != null &&
             now.difference(device.lastSeen).inDays < 90;
    }),
  );
}
```

### 3. 批量合并

```dart
// 批量处理CRDT合并,减少数据库写入
await db.transaction(() async {
  for (final tx in remoteChanges) {
    await _mergeSingle(tx);
  }
});
```

---

## 测试策略

### 场景测试

```dart
void main() {
  test('并发创建: 两笔交易都保留', () async {
    // Device A: 创建 TX-1
    final txA = Transaction.create(
      bookId: 'book1',
      deviceId: 'deviceA',
      amount: 100,
    );

    // Device B: 创建 TX-2
    final txB = Transaction.create(
      bookId: 'book1',
      deviceId: 'deviceB',
      amount: 200,
    );

    // 同步
    await syncService.sync();

    // 验证: 两笔都存在
    final allTxs = await repo.getTransactions(bookId: 'book1');
    expect(allTxs, hasLength(2));
    expect(allTxs, contains(txA));
    expect(allTxs, contains(txB));
  });

  test('并发修改: LWW解决冲突', () async {
    // 初始状态
    final tx = Transaction.create(
      id: 'tx1',
      amount: 100,
    );

    // Device A: 修改金额
    final txA = tx.copyWith(
      amount: 120,
      lamportTimestamp: 10,
    );

    // Device B: 修改金额
    final txB = tx.copyWith(
      amount: 150,
      lamportTimestamp: 15,
    );

    // 合并
    final merged = await crdt.merge(txA, txB);

    // 验证: 时间戳更大的胜出
    expect(merged.amount, equals(150));
  });
}
```

---

## 限制与权衡

### 已知限制

1. **LWW可能丢失数据**
   ```
   场景: A和B同时修改金额
   A: ¥100 -> ¥120
   B: ¥100 -> ¥150

   结果: ¥150 (A的修改丢失)
   ```

   **缓解:** 对于重要字段,考虑字段级合并

2. **向量时钟膨胀**
   - 向量时钟大小随设备数量增长
   - 长期运行后可能很大

   **缓解:** 定期清理旧设备

3. **删除语义**
   - 删除必须使用墓碑(软删除)
   - 不能真正删除,否则会"复活"

   **缓解:** 定期垃圾回收墓碑

---

## 未来扩展

### Phase 2: 字段级CRDT

```dart
// 为重要字段使用专门的CRDT类型
class Transaction {
  LWWRegister<int> amount;         // Last-Write-Wins寄存器
  ORSet<String> tags;              // Observed-Remove集合
  RGA<String> note;                // Replicated Growable Array
}
```

### Phase 3: 冲突通知

```dart
// 当检测到并发修改时通知用户
if (isConflict(local, remote)) {
  await _notifyUser(ConflictEvent(
    transaction: merged,
    localVersion: local,
    remoteVersion: remote,
  ));
}
```

---

## 相关决策

- **ADR-002:** Drift数据库方案
- **ADR-003:** 多层加密策略

---

## 参考资料

### 学术论文
- [CRDTs: Consistency without concurrency control](https://hal.inria.fr/inria-00397981/)
- [A comprehensive study of CRDTs](https://crdt.tech/)

### 实现参考
- [Yjs文档](https://docs.yjs.dev/)
- [Automerge](https://github.com/automerge/automerge)

### 最佳实践
- [CRDT设计模式](https://crdt.tech/papers)

---

## 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2026-02-03 | 1.0 | 初始版本 | 架构团队 |

---

**文档维护者:** 技术架构团队
**审核者:** CTO, 技术负责人
**下次Review日期:** 2026-08-03
