# Phase 36 Wave-0 TDD Test Scaffold

**日期:** 2026-06-07
**时间:** 20:55
**任务类型:** 测试
**状态:** 已完成
**相关模块:** Phase 36 — Data Layer + Domain + Import Guard (v1.6 购物清单)

---

## 任务概述

创建 Phase 36 的 Wave-0 TDD 验证脚手架，在任何生产代码编写之前建立测试基准。按照 TDD RED 阶段原则，三个测试文件全部以失败（RED）状态提交，待后续 Plans 02/05/06 实现生产代码后变为绿色。

---

## 完成的工作

### 1. Wave-0 合约测试（shopping_items_v20_contract_test.dart）
- 覆盖需求：SHOP-01（list_type CHECK 约束）、SYNC-05（completed_at 列，D-03 决策）
- `schemaVersion == 20` 断言 **FAILS RED**（当前为 19，符合预期）
- 原始 sqlite3 组测试全部通过：列名验证、CHECK 约束、completed_at NULL、软删除标志

### 2. Wave-0 DAO 测试（shopping_item_dao_test.dart）
- 覆盖需求：DONE-02（ORDER BY is_completed ASC, sort_order ASC, created_at ASC）
- **FAILS RED**：`ShoppingItemDao` 不存在，import 失败（5个 analyzer 错误，符合预期）
- 测试覆盖：流排序、软删除排除、upsert 插入+更新

### 3. Wave-0 Repository 测试（shopping_item_repository_impl_test.dart）
- 覆盖需求：ITEM-05（note 加密、tags JSON、estimatedPrice 整型）
- **FAILS RED**：`ShoppingItemDao`、`ShoppingItemRepositoryImpl`、`ShoppingItem` 不存在（10个 analyzer 错误，符合预期）
- 测试覆盖：加密调用验证、tags JSON 编解码、空标签存 null、解密失败静默返回 null

### 2. 自动修复的问题
- **[Rule 1 - Bug] Drift isNotNull/isNull 符号冲突：** `drift` 包导出自己的 `isNotNull`/`isNull` 与 `flutter_test` 冲突，导致 `ambiguous_import` 错误。修复方式：`import 'package:drift/drift.dart' hide isNotNull, isNull`

### 3. 代码变更统计
- 新建文件：3 个
- 修改文件：0 个（仅测试文件）
- 约 390 行新增测试代码

---

## 遇到的问题与解决方案

### 问题：Drift isNotNull 符号与 flutter_test 冲突
**症状：** `ambiguous_import` — `isNotNull` 在 drift 和 flutter_test 中均有定义
**原因：** Drift 内部包含自己的 SQL 查询构建器，导出了 `isNotNull` 谓词函数
**解决方案：** `import 'package:drift/drift.dart' hide isNotNull, isNull;`

---

## 测试验证

- [x] 合约测试：1 个失败（schemaVersion），5 个通过（raw-sqlite3 组）— RED 状态正确
- [x] DAO 测试：5 个 analyzer 错误（ShoppingItemDao 不存在）— RED 状态正确
- [x] Repository 测试：10 个 analyzer 错误（3 个文件缺失）— RED 状态正确
- [x] 合约测试文件本身通过 `flutter analyze` 零错误检查

---

## Git 提交记录

```
Commit: c5f3f6d6
test(36-01): add Wave-0 v20 contract test scaffold (RED)

Commit: b77b6870
test(36-01): add Wave-0 DAO test scaffold (RED)

Commit: 3d079fab
test(36-01): add Wave-0 repository test scaffold (RED)

Commit: dfea3b2d
docs(36-01): complete Wave-0 test scaffold plan
```

---

## 后续工作

- [ ] Plan 02：创建 ShoppingItems Drift 表 + v20 迁移（合约测试将变绿）
- [ ] Plan 04：创建 ShoppingItem Freezed 领域模型
- [ ] Plan 05：创建 ShoppingItemDao（DAO 测试将变绿）
- [ ] Plan 06：创建 ShoppingItemRepositoryImpl（Repository 测试将变绿）

---

**创建时间:** 2026-06-07 20:55
**作者:** Claude Sonnet 4.6
