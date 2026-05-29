# Multi-Book DAO Methods: findByBookIds + watchByBookIds

**日期:** 2026-05-29
**时间:** 15:00
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** Phase 24 Plan 02 — Data Layer Extension

---

## 任务概述

为 `TransactionDao` 添加两个跨多账本的查询方法：`findByBookIds`（一次性查询）和 `watchByBookIds`（响应式 Stream）。这两个方法是 LIST-02 需求的数据层基础，`watchByBookIds` 通过 Drift 的 `readsFrom` 机制自动推送变更，消除了对 `ref.invalidate` 的依赖。

---

## 完成的工作

### 1. 主要变更

**`lib/data/daos/transaction_dao.dart`（修改）**
- 添加 `import '../../shared/constants/sort_config.dart'`
- 添加私有辅助方法 `_orderByClause(SortField, SortDirection)` — 通过 enum switch 构建 ORDER BY 字符串，防止 SQL 注入（T-24-02-02）
- 添加 `findByBookIds` — customSelect + `IN (?)` 参数化绑定，支持 ledgerType/categoryId 过滤和 SortField 排序，无默认 limit（D-02）
- 添加 `watchByBookIds` — 与 findByBookIds 相同 SQL，加 `readsFrom: {_db.transactions}` 使 Drift 在任何写操作后自动推送新结果（D-03）

**`test/unit/data/daos/transaction_dao_multi_book_test.dart`（新建）**
- SC#1：findByBookIds 的 6 个测试用例（多账本、过滤、排序、空 bookIds 短路）
- SC#2：watchByBookIds 的 3 个测试用例（insert/soft-delete/UPDATE 后自动推送）
- SC#4：softDelete 不修改 currentHash/prevHash，verifyChain 对全部 3 行（含软删除行）返回 valid

### 2. 技术决策

- **`table.map(row.data)` 而非 `mapFromRow`：** Drift 的 `mapFromRow` 接受 `QueryRow` 且为异步（返回 `Future<D>`）。生成代码中的 `table.map(Map<String, dynamic>)` 是同步的，直接适用于 `customSelect` 的 row.data。
- **`readsFrom: {_db.transactions}` 为必选：** 不设置此参数时，Drift 无法追踪表变更，stream 不会响应写操作（会导致 SC#2 静默失败）。
- **ORDER BY 通过 enum switch 构建：** 列名为编译期字符串字面量，用户输入永远不会进入 ORDER BY 子句（T-24-02-02）。

### 3. 代码变更统计
- 修改文件：1（transaction_dao.dart）
- 新建文件：1（transaction_dao_multi_book_test.dart）
- 新增代码：约 220 行（DAO 方法 ~100 行，测试 ~380 行）

---

## 遇到的问题与解决方案

### 问题 1: mapFromRow 类型不匹配
**症状:** 编译错误 `The argument type 'Map<String, dynamic>' can't be assigned to the parameter type 'QueryRow'`
**原因:** 计划中建议使用 `mapFromRow(row.data)`，但该方法签名为 `Future<D> mapFromRow(QueryRow row)`，不接受 Map
**解决方案:** 改用生成代码中的同步方法 `_db.transactions.map(row.data)`

### 问题 2: SC#2 UPDATE 测试的 CHECK 约束失败
**症状:** `SqliteException(275): CHECK constraint failed: entry_source IN ('manual', 'voice', 'ocr')`
**原因:** 测试传入 `entrySource: 'sync'`，但数据库有 CHECK 约束限制合法值
**解决方案:** 改用 `entrySource: 'manual'`（仍能验证 stream 响应性，与 entrySource 值无关）

### 问题 3: 测试文件缺少 OrderingTerm 导入
**症状:** 编译错误 `Undefined name 'OrderingTerm'`
**原因:** SC#4 测试中直接使用了 `OrderingTerm.asc()` 但未导入 Drift
**解决方案:** 添加 `import 'package:drift/drift.dart' show OrderingTerm;`

---

## 测试验证

- [x] 单元测试通过（11/11）
- [x] flutter analyze 0 issues
- [x] 代码审查完成（内联）
- [x] 文档已更新（SUMMARY.md）

---

## Git 提交记录

```
Commit: 5fe9dfe
feat(24-02): add findByBookIds + watchByBookIds to TransactionDao

Commit: 93b9f65
docs(24-02): complete multi-book DAO methods plan — findByBookIds + watchByBookIds
```

---

## 后续工作

- [ ] Phase 26+：实现多账本列表屏，消费 watchByBookIds
- [ ] Plan 03（本 Phase）：其他数据层扩展

---

## 参考资源

- Plan: `.planning/phases/24-data-layer-extension/24-02-PLAN.md`
- Summary: `.planning/phases/24-data-layer-extension/24-02-SUMMARY.md`
- Drift customSelect 参考: `lib/data/daos/analytics_dao.dart` lines 505-536

---

**创建时间:** 2026-05-29 15:00
**作者:** Claude Sonnet 4.6
