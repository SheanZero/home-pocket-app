# ADR-010 CRDT 冲突解决策略 - 实施总结

**日期:** 2026-02-03
**优化主题:** CRDT 冲突解决策略增强
**相关 ADR:** ADR-010, ADR-004
**状态:** ✅ 决策完成，待开发实施

---

## 📋 决策概览

### 问题识别

在当前的 CRDT 实现中发现冲突解决策略过于简化，存在严重的数据丢失风险：

1. **数据丢失风险**: 并发修改会丢失数据（一方的修改被默默覆盖）
2. **时钟漂移问题**: 依赖设备本地时间戳不可靠
3. **无法处理字段级冲突**: 整个对象级别覆盖，无法精确到字段
4. **缺少冲突记录和通知**: 用户不知道发生了冲突

### 解决方案

采用 **向量时钟 + 因果关系判断** 策略（详见 ADR-010）

---

## ✅ 已完成的工作

### 1. 创建 ADR-010 ✅

**文件:** `arch2/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md`

**内容包括:**
- 问题详细分析（数据丢失、时钟漂移、字段级冲突、缺少通知）
- 4 个备选方案深度对比
  - 方案1: 字段级合并 (⭐⭐⭐)
  - 方案2: 向量时钟 + 因果关系判断（**推荐**）⭐⭐⭐⭐⭐
  - 方案3: 用户手动解决 (⭐⭐)
  - 方案4: 操作型 CRDT (⭐)
- 完整实施计划（6 个 Phase）
- 向量时钟设计和实现
- 冲突记录机制设计

### 2. 决策 4 个关键问题 ✅

**问题 1: 并发修改金额的处理**
- **决策:** D - 转为用户手动解决
- **理由:** 金额是财务数据核心，不能随意选择，确保数据准确性

**问题 2: 删除冲突的处理**
- **决策:** D - 恢复交易，标记为"曾被删除"
- **理由:** 保留数据避免永久丢失，让用户知道曾有删除意图

**问题 3: 冲突通知的时机**
- **决策:** B - 批量通知（同步完成后汇总）
- **理由:** 避免频繁打扰，一次性展示所有冲突，用户可集中处理

**问题 4: 向量时钟的清理策略**
- **决策:** A - 不清理（接受存储开销）
- **理由:** 开销极低（<$0.0001/年/用户），避免清理带来的同步风险

### 3. 完成存储影响分析 ✅

**文件:** `arch2/ADR-010_VECTOR_CLOCK_STORAGE_ANALYSIS.md` (40KB)

**分析内容:**
- 不同数据规模的存储对比（1,000 - 100,000 笔交易）
- JSON vs 二进制格式对比
- 性能影响测试数据
- 成本分析（云存储成本）
- ROI 计算
- 优化方案

**关键结论:**
- 二进制格式: 38-70 bytes/交易
- 10,000 笔交易: 540 KB 额外存储
- 存储成本: $0.00003/年/用户（极低）
- 性能影响: <3ms 查询延迟（可忽略）
- ROI: 8,333x（收益远大于成本）

### 4. 创建快速参考总结 ✅

**文件:** `arch2/ADR-010_STORAGE_IMPACT_SUMMARY.md` (6.4KB)

提供关键数据速查表和决策建议。

### 5. 更新 ADR 索引 ✅

**文件:** `arch2/03-adr/ADR-000_INDEX.md`

**更新内容:**
- 添加 ADR-010 条目
- 更新决策统计（现在有 10 个 ADR）
- 更新 ADR 关系图
- 添加 Review 计划

---

## 📊 方案对比

### 选择的方案: 向量时钟 + 因果关系判断

| 方案 | 数据丢失风险 | 用户体验 | 实现复杂度 | 存储开销 | 推荐度 |
|------|------------|---------|-----------|---------|--------|
| 字段级合并 | ⚠️ 中 | ✅ 好 | ✅ 低 | ✅ 无 | ⭐⭐⭐ |
| **向量时钟** | **✅ 低** | **✅ 好** | **⚠️ 中** | **⚠️ 小** | **⭐⭐⭐⭐⭐** |
| 用户手动解决 | ✅ 极低 | ❌ 差 | ❌ 高 | ⚠️ 中 | ⭐⭐ |
| 操作型CRDT | ✅ 极低 | ⚠️ 中 | ❌ 极高 | ❌ 大 | ⭐ |

---

## 🎯 核心技术方案

### 向量时钟机制

**VectorClock 类:**

```dart
class VectorClock {
  final Map<String, int> clocks;  // deviceId -> logicalTime

  VectorClock(this.clocks);

  /// 增加本设备的逻辑时钟
  VectorClock increment(String deviceId) {
    final newClocks = Map<String, int>.from(clocks);
    newClocks[deviceId] = (newClocks[deviceId] ?? 0) + 1;
    return VectorClock(newClocks);
  }

  /// 合并两个向量时钟
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

### 冲突解决流程

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
  // 检查金额冲突
  final hasAmountConflict = local.amount != remote.amount;

  if (hasAmountConflict) {
    // 决策1: 金额冲突转为用户手动解决
    _createConflictRecord(
      local: local,
      remote: remote,
      conflictType: ConflictType.amountMismatch,
    );

    return local.copyWith(
      hasUnresolvedConflict: true,
      conflictId: _generateConflictId(),
    );
  }

  // 非金额字段：字段级合并
  return Transaction(
    id: local.id,
    amount: local.amount,
    note: _mergeNotes(local.note, remote.note),
    categoryId: local.lastModifiedBy.compareTo(remote.lastModifiedBy) > 0
        ? local.categoryId
        : remote.categoryId,
    vectorClock: local.vectorClock.merge(remote.vectorClock),
    lastModifiedBy: local.lastModifiedBy.compareTo(remote.lastModifiedBy) > 0
        ? local.lastModifiedBy
        : remote.lastModifiedBy,
    updatedAt: DateTime.now(),
  );
}
```

### 删除冲突处理

```dart
/// 处理删除冲突
Transaction? _handleDeleteConflict(
  Transaction? local,
  Transaction? remote,
) {
  // 场景: 本地删除 + 远程修改
  if ((local == null || local.isDeleted) &&
      (remote != null && !remote.isDeleted)) {
    // 决策2: 恢复交易，标记为"曾被删除"
    return remote.copyWith(
      wasDeleted: true,
      deletedBy: local?.lastModifiedBy,
      deletedAt: local?.updatedAt,
      hasUnresolvedConflict: true,
    );
  }

  // 场景: 远程删除 + 本地修改
  if ((remote == null || remote.isDeleted) &&
      (local != null && !local.isDeleted)) {
    // 决策2: 恢复交易，标记为"曾被删除"
    return local.copyWith(
      wasDeleted: true,
      deletedBy: remote?.lastModifiedBy,
      deletedAt: remote?.updatedAt,
      hasUnresolvedConflict: true,
    );
  }

  return local ?? remote;
}
```

### 批量冲突通知

```dart
/// 同步完成后批量通知冲突
class SyncService {
  Future<SyncResult> sync() async {
    final conflicts = <ConflictRecord>[];

    // ... 同步过程中收集冲突 ...

    // 同步完成后，批量通知（决策3）
    if (conflicts.isNotEmpty) {
      await _showConflictSummary(conflicts);
    }

    return SyncResult.success(
      syncedCount: syncedCount,
      conflictsCount: conflicts.length,
    );
  }

  Future<void> _showConflictSummary(List<ConflictRecord> conflicts) async {
    await NotificationService.show(
      title: '同步完成 - 发现 ${conflicts.length} 个冲突',
      body: '点击查看并解决冲突',
      payload: {
        'type': 'sync_conflicts',
        'conflicts': conflicts.map((c) => c.id).toList(),
      },
    );

    await _updateConflictBadge(conflicts.length);
  }
}
```

---

## 🎯 下一步行动

### Phase 1: 数据模型扩展（预计 1 周）

**待办事项:**
- [ ] 在 Transaction 模型中添加 `vectorClock` 字段
- [ ] 在 Transaction 模型中添加 `lastModifiedBy` 字段
- [ ] 添加冲突管理字段（`hasUnresolvedConflict`, `conflictId`）
- [ ] 添加删除冲突字段（`wasDeleted`, `deletedBy`, `deletedAt`）
- [ ] 扩展数据库 Schema（Drift migration）
- [ ] 实现向量时钟序列化/反序列化（二进制格式）

### Phase 2: 向量时钟实现（预计 1 周）

**待办事项:**
- [ ] 实现 `VectorClock` 类
- [ ] 实现向量时钟比较逻辑（`compare()`）
- [ ] 实现向量时钟合并逻辑（`merge()`）
- [ ] 实现向量时钟增量逻辑（`increment()`）
- [ ] 实现二进制编解码（`VectorClockCodec`）
- [ ] 单元测试覆盖

### Phase 3: 冲突解决实现（预计 1 周）

**待办事项:**
- [ ] 更新 `resolveConflict()` 方法使用向量时钟
- [ ] 实现并发修改检测
- [ ] 实现字段级合并策略
- [ ] 实现金额冲突处理（转用户手动解决）
- [ ] 实现删除冲突处理（标记为"曾被删除"）
- [ ] 单元测试和集成测试

### Phase 4: 冲突记录和通知（预计 3 天）

**待办事项:**
- [ ] 创建 Conflicts 表（Drift Schema）
- [ ] 实现 ConflictRepository
- [ ] 实现冲突记录功能
- [ ] 实现批量通知机制（同步完成后汇总）
- [ ] 实现用户手动解决 UI（金额冲突）
- [ ] 实现冲突历史查看 UI

### Phase 5: 集成和测试（预计 3 天）

**待办事项:**
- [ ] 集成到现有同步流程（`SyncService`）
- [ ] 更新 `TransactionRepository` 实现
- [ ] 端到端测试
- [ ] 性能测试（验证存储和性能影响）
- [ ] 用户体验测试

### Phase 6: 文档更新（预计 2 天）

**待办事项:**
- [ ] 更新 ARCH-002_Data_Architecture.md
- [ ] 更新 ARCH-005_Integration_Patterns.md
- [ ] 更新 MOD-003_FamilySync.md
- [ ] 更新 ADR-004_CRDT_Sync.md
- [ ] 编写开发者指南

---

## 📚 相关文档

### 核心 ADR
- [ADR-010: CRDT 冲突解决策略增强](arch2/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md)
- [ADR-004: CRDT 同步协议](arch2/03-adr/ADR-004_CRDT_Sync.md)

### 分析文档
- [ADR-010 向量时钟存储影响分析](arch2/ADR-010_VECTOR_CLOCK_STORAGE_ANALYSIS.md)
- [ADR-010 存储影响快速总结](arch2/ADR-010_STORAGE_IMPACT_SUMMARY.md)
- [ADR-010 Review 总结](arch2/ADR-010_REVIEW_SUMMARY.md)

### 需要同步修改的文档
- [ ] `ARCH-002_Data_Architecture.md` - 更新 Transaction 模型定义
- [ ] `ARCH-005_Integration_Patterns.md` - 更新 Repository 冲突解决逻辑
- [ ] `MOD-003_FamilySync.md` - 更新同步流程和冲突处理
- [ ] `ADR-004_CRDT_Sync.md` - 标注被 ADR-010 增强

---

## ✅ 验收标准

### 功能验收
- [ ] 向量时钟正确实现并测试
- [ ] 并发修改能被准确检测
- [ ] 金额冲突转为用户手动解决
- [ ] 删除冲突正确标记为"曾被删除"
- [ ] 批量冲突通知正常工作
- [ ] 冲突历史可查看和追溯

### 性能验收
- [ ] 存储开销符合预期（<70 bytes/交易）
- [ ] 性能影响可忽略（<3ms）
- [ ] 不影响同步速度
- [ ] 不造成内存问题

### 数据一致性验收
- [ ] 无数据丢失
- [ ] 冲突解决结果确定性
- [ ] 多设备最终一致性
- [ ] 冲突记录完整准确

---

## 🔍 风险和缓解措施

### 风险 1: 向量时钟实现错误

**缓解措施:**
- 完整的单元测试覆盖
- 参考学术论文和成熟实现
- 代码 Review

### 风险 2: 用户不理解冲突通知

**缓解措施:**
- 清晰的 UI 设计
- 提供详细的冲突说明
- 示例和帮助文档

### 风险 3: 性能影响超出预期

**缓解措施:**
- 使用二进制格式减少存储
- 性能测试和监控
- 必要时进一步优化

---

## 📞 联系方式

**负责人:** Architecture Team
**问题反馈:** architecture@homepocket.com
**Slack:** #architecture-decisions

---

**文档状态:** ✅ 决策完成
**实施状态:** ⏳ 待开发实施
**预计完成时间:** 5 周（从开发启动开始）

**与其他 ADR 关系:**
- ADR-004: CRDT 同步协议（基础）
- ADR-010: 冲突解决策略增强（本 ADR）
- ADR-003: 多层加密（同步加密）
