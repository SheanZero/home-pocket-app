# Phase 40 Plan 06: Transaction Domain Extension, Sync Pipeline, Partial-Triple Invariant, STORE-04 Closure

**日期:** 2026-06-12
**时间:** 11:01
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** Phase 40 — Multi-Currency Data Foundation & Domain Sync

---

## 任务概述

为 Transaction Freezed 模型添加三个可空的外币溯源字段（originalCurrency, originalAmount, appliedRate），更新 TransactionSyncMapper 实现 v1.7/v1.6 双向兼容同步，在 CreateTransactionUseCase 添加 partial-triple 不变量验证和 appliedRate 有效性验证，并将 STORE-04 verifyChain 存根测试实现为绿色（关闭 Phase 40 的最后一个验收条件）。

---

## 完成的工作

### 1. 主要变更

- **`lib/features/accounting/domain/models/transaction.dart`** — 添加三个可空字段：`String? originalCurrency`、`int? originalAmount`、`String? appliedRate`（无 @Default，与 note/photoHash/merchant 保持一致）
- **`lib/features/accounting/domain/models/transaction.freezed.dart` + `transaction.g.dart`** — build_runner 重新生成，新字段包含在 copyWith/==/hashCode/toJson/fromJson 中
- **`lib/features/accounting/domain/models/transaction_sync_mapper.dart`** — toSyncMap 添加三个条件性 if-in-map 条目（v1.6 向后兼容）；fromSyncMap 添加三个 `as T?` null-safe 读取（Pitfall 4 防护）
- **`lib/application/accounting/create_transaction_use_case.dart`** — CreateTransactionParams 添加三个可选字段；execute() 添加 partial-triple 不变量检查 + appliedRate 有效性检查（D-05）；Transaction 构造时传递三个货币字段
- **`test/unit/data/migrations/schema_v21_migration_test.dart`** — 实现 STORE-04 verifyChain 测试（替换 `fail('not implemented')`），添加 calculateTransactionHash 4参数架构断言测试
- **`test/unit/application/accounting/create_transaction_use_case_test.dart`** — 添加 partial-triple 不变量测试组（7个用例）和 appliedRate 有效性测试组（4个用例）

### 2. 技术决策

- **`double.parse('NaN')` 在 Dart 中不抛 FormatException**：返回 `double.nan`。添加 `rate.isNaN || rate.isInfinite` 守卫，保证 NaN/Infinity 也能被正确拒绝。计划文档说"FormatException path"有误，已在实现中修正（外部行为不变）。
- **STORE-04 verifyChain 测试设计**：HashChainService.verifyChain 接受 `List<Map<String, dynamic>>`，不需要数据库句柄。测试同时在内存 AppDatabase 中插入行（验证数据层兼容性）并构建内存 chainData（验证哈希链完整性）。ADR-021 确认：货币字段排除在哈希公式外。

### 3. 代码变更统计

- 修改的文件数量：7
- 涉及的主要文件路径：见上

---

## 遇到的问题与解决方案

### 问题 1: double.parse('NaN') 不抛 FormatException

**症状:** 测试 `appliedRate='NaN' → Result.error (FormatException path)` 失败，报 Mock 调用异常（Category.findById 返回 null 而非 Future<Category?>）
**原因:** Dart 的 `double.parse('NaN')` 遵循 IEEE 754，返回 `double.nan` 而非抛出异常；验证通过后执行到 category 查找，Mock 未设置导致 null 返回类型不匹配
**解决方案:** 在 appliedRate 验证中添加 `rate.isNaN || rate.isInfinite` 守卫，NaN 被 isNaN 守卫捕获并返回 `Result.error('appliedRate must be a positive number')`；测试更新为对应正确的错误路径

### 问题 2: 本地函数以下划线开头的 analyzer 警告

**症状:** `flutter analyze` 报 `no_leading_underscores_for_local_identifiers` info (测试中的 `_baseParams`)
**解决方案:** 将 `_baseParams` 重命名为 `makeParams`，消除 analyzer 警告

---

## 测试验证

- [x] 单元测试通过（2635/2635）
- [x] 集成测试通过（schema_v21_migration_test.dart STORE-04 GREEN）
- [x] 架构测试通过（test/architecture/ 47/47）
- [x] `flutter analyze` 0 issues
- [ ] 手动测试验证（Phase 40 是纯后端/Domain 层，无 UI）
- [x] 代码审查完成（Plan 验收条件全部满足）

---

## Git 提交记录

```
Commit: 10e7c8b9
Task 1: feat(40-06): extend Transaction model with currency fields, update sync mapper, implement STORE-04 verifyChain test

Commit: 0e812a81
Task 2: feat(40-06): add partial-triple invariant and appliedRate validation to CreateTransactionUseCase

Commit: f838ae43
docs(40-06): complete transaction domain extension and STORE-04 closure plan summary
```

---

## 后续工作

- Phase 40 全部完成（6个Plan全部交付）
- Phase 41: 汇率服务（rate service）+ RateResult 状态模型（isManualOverride flag，D-02 弹窗所需）
- Phase 42: 编辑页 UI 实现（D-01 日元只读 + D-02 弹窗 + D-03 toast）

---

## 参考资源

- ADR-021: Hash Chain Scope — 货币字段排除在哈希公式外
- ADR-022: Edit Semantics — 外币行编辑模型（D-01/D-02/D-03）
- ADR-020: Exchange Rate Precision — appliedRate TextColumn 决策
- .planning/phases/40-data-foundation-domain-sync/40-06-SUMMARY.md

---

**创建时间:** 2026-06-12 11:01
**作者:** Claude Sonnet 4.6
