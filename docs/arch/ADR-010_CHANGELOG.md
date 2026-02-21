# ADR-010 变更日志

**日期:** 2026-02-03
**主题:** CRDT 冲突解决策略增强 - 决策完成

---

## 📝 变更摘要

ADR-010 从草稿状态正式转为**已接受**状态，完成了所有关键决策，明确了实施方案。

---

## ✅ 完成的决策

### 核心决策

**采用方案:** 向量时钟 + 因果关系判断（方案 2）

**理由:**
1. 精确检测并发修改，不依赖设备时间
2. 确定性的冲突解决
3. 实现复杂度适中
4. 存储开销可接受（<$0.0001/年/用户）
5. 可扩展性好

### 关键问题决策

#### 1. 并发修改金额的处理
- **决策:** D - 转为用户手动解决
- **理由:** 金额是财务数据核心，自动合并可能导致记账错误

#### 2. 删除冲突的处理
- **决策:** D - 恢复交易，标记为"曾被删除"
- **理由:** 保留数据避免永久丢失，让用户知道曾有删除意图

#### 3. 冲突通知的时机
- **决策:** B - 批量通知（同步完成后汇总）
- **理由:** 避免频繁打扰，一次性展示所有冲突

#### 4. 向量时钟的清理策略
- **决策:** A - 不清理（接受存储开销）
- **理由:** 开销极低，避免清理带来的同步风险

---

## 📄 更新的文档

### 1. ADR-010 主文档

**文件:** `arch2/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md`

**变更:**
- ✅ 状态从"草稿"改为"已接受"
- ✅ 决策日期确定为 2026-02-03
- ✅ 待决策问题 → 已决策问题（记录 4 个决策）
- ✅ 添加实施细节章节（完整代码示例）
- ✅ 添加下一步行动（6 个 Phase）

### 2. ADR-010 实施总结

**文件:** `arch2/ADR-010_IMPLEMENTATION_SUMMARY.md` (新建)

**内容:**
- 决策概览
- 方案对比
- 核心技术方案（向量时钟、冲突解决、批量通知）
- 实施计划（6 个 Phase，详细任务列表）
- 验收标准
- 风险和缓解措施

### 3. ADR-010 存储分析

**文件:** `arch2/ADR-010_VECTOR_CLOCK_STORAGE_ANALYSIS.md` (已存在)

**状态:** 保持不变（之前已完成）

### 4. ADR-010 快速总结

**文件:** `arch2/ADR-010_STORAGE_IMPACT_SUMMARY.md` (已存在)

**状态:** 保持不变（之前已完成）

### 5. ADR 索引

**文件:** `arch2/03-adr/ADR-000_INDEX.md`

**变更:**
- ✅ 添加 ADR-010 完整条目
- ✅ 更新决策统计（9 → 10 个ADR）
- ✅ 更新 ADR 关系图（添加 ADR-010）
- ✅ 添加 Review 计划

### 6. ADR-004 CRDT 同步

**文件:** `arch2/03-adr/ADR-004_CRDT_Sync.md`

**变更:**
- ✅ 状态标注"被 ADR-010 增强"
- ✅ 添加重要更新说明
- ✅ 更新限制部分（LWW 问题已在 ADR-010 解决）
- ✅ 相关决策中添加 ADR-010

---

## 🔧 实施细节补充

### 数据模型扩展

```dart
@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    // ... 原有字段 ...

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
  }) = _Transaction;
}
```

### 向量时钟存储

**格式:** 二进制（推荐，节省 50% 存储）

**存储开销:**
- 每笔交易: 38-70 bytes
- 10,000 笔: 540 KB
- 成本: $0.00003/年/用户

### 冲突处理策略

| 场景 | 策略 | 说明 |
|------|------|------|
| 金额并发修改 | 用户手动解决 | 确保财务数据准确 |
| 非金额字段 | 字段级合并 | 自动合并，减少打扰 |
| 删除冲突 | 标记"曾被删除" | 保留数据，用户决定 |
| 通知时机 | 批量通知 | 同步完成后汇总 |

---

## 📊 影响范围

### 直接影响

- ✅ `TransactionRepository` 实现
- ✅ `SyncService` 同步逻辑
- ✅ Transaction 数据模型
- ✅ 数据库 Schema（Drift）

### 间接影响

- ⚠️ 同步 UI（需要显示冲突）
- ⚠️ 通知系统（批量通知）
- ⚠️ 冲突历史 UI（新增）
- ⚠️ 用户手动解决 UI（新增）

---

## 🎯 下一步

### 立即行动

1. **开发团队会议:** 讨论实施计划和时间线
2. **技术方案评审:** Review 向量时钟实现方案
3. **UI/UX 设计:** 设计冲突通知和解决界面

### 实施顺序

1. **Week 1-2:** 数据模型扩展 + 向量时钟实现
2. **Week 3-4:** 冲突解决实现 + 冲突记录和通知
3. **Week 5:** 集成测试 + 文档更新

### 风险监控

- 向量时钟实现正确性
- 性能影响（存储、计算）
- 用户体验（冲突通知是否清晰）

---

## 📞 参考资料

### 学术论文
- [CRDTs: Consistency without concurrency control](https://hal.inria.fr/inria-00397981/)
- [Vector Clocks in Distributed Systems](https://en.wikipedia.org/wiki/Vector_clock)

### 实现参考
- [Automerge](https://github.com/automerge/automerge) - 成熟的 CRDT 实现
- [Y.js](https://docs.yjs.dev/) - 高性能 CRDT 库

### 相关 ADR
- [ADR-004: CRDT 同步协议](../03-adr/ADR-004_CRDT_Sync.md)
- [ADR-003: 多层加密策略](../03-adr/ADR-003_Multi_Layer_Encryption.md)

---

**文档状态:** ✅ 完成
**创建日期:** 2026-02-03
**维护者:** Architecture Team
