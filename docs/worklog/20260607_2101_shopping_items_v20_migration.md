# Phase 36 Plan 02: ShoppingItems Drift Table + v20 Migration

**日期:** 2026-06-07
**时间:** 21:01
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** Phase 36 — Data Layer + Domain + Import Guard

---

## 任务概述

创建 `ShoppingItems` Drift 表（18 列），将其注册到 `AppDatabase` 中，将 `schemaVersion` 从 19 升级到 20，添加 `if (from < 20)` 迁移块，运行 build_runner 重新生成 `app_database.g.dart`。Wave-0 合约测试由 RED 变为 GREEN（6/6 测试通过）。

---

## 完成的工作

### 1. 主要变更

- 创建 `lib/data/tables/shopping_items_table.dart`（18 列，4 个 CHECK 约束，5 个 TableIndex 条目）
- 修改 `lib/data/app_database.dart`：
  - 新增导入 `shopping_items_table.dart`
  - `ShoppingItems` 添加到 `@DriftDatabase(tables: [...])` 列表
  - `schemaVersion` 19 → 20
  - 新增 `if (from < 20) { await migrator.createTable(shoppingItems); }` 迁移块
- 重新生成 `lib/data/app_database.g.dart`（包含 `$ShoppingItemsTable` 访问器）

### 2. 技术决策

- 使用 `migrator.createTable(shoppingItems)` 而非 `customStatement` 原始 DDL — 确保 `customConstraints` 和 `customIndices` 被正确发出（RESEARCH Pattern 2）
- `customIndices` 不加 `@override`（CLAUDE.md 陷阱 #11 — `customConstraints` 加 `@override`，`customIndices` 不加）
- `completedAt` 列 nullable（D-03/SYNC-05 sticky-complete 合并参考时间戳，合并算法在 Phase 37 实现）
- 导入按字母顺序排列：`shopping_items_table` 位于 `merchant_category_preferences_table` 和 `sync_queue_table` 之间

### 3. 代码变更统计

- 新增文件：1（`shopping_items_table.dart`）
- 修改文件：2（`app_database.dart`、`app_database.g.dart`）
- 新增行数：~2250（主要来自重新生成的 `.g.dart`）

---

## 遇到的问题与解决方案

### 问题 1: flutter test 不支持 -x 标志
**症状:** `Missing argument for "-x"` 错误
**原因:** Flutter 的 `flutter test` 命令不支持 `-x` 标志（这是 dart test 的标志）
**解决方案:** 使用不带 `-x` 的 `flutter test` 命令，结果相同

---

## 测试验证

- [x] 合约测试通过（6/6）：`shopping_items_v20_contract_test.dart`
  - schemaVersion 等于 20 ✓
  - 列名验证（18 列）✓
  - `list_type` CHECK 约束拒绝 'shared' ✓
  - `list_type` 接受 'public' 和 'private' ✓
  - `completed_at` 接受 NULL ✓
  - 软删除标志持久化 ✓
- [x] `flutter analyze` 在修改的文件上：0 问题
- [x] `build_runner` 成功：34 秒，1486 输出

---

## Git 提交记录

```bash
Commit: 02cf82f9
feat(36-02): create ShoppingItems Drift table with 18 columns

Commit: e9c995e6
feat(36-02): wire ShoppingItems into AppDatabase, bump schemaVersion to 20

Commit: aada2500
docs(36-02): complete ShoppingItems table + v20 migration plan
```

---

## 后续工作

- [ ] Plan 36-03: domain models (ShoppingItem, ShoppingListFilter, ShoppingItemParams) + repository interface
- [ ] Plan 36-04: domain model Freezed generation
- [ ] Plan 36-05: ShoppingItemDao implementation
- [ ] Plan 36-06: ShoppingItemRepositoryImpl + encryption boundary
- [ ] Plans 37-39: use cases, UI, i18n/goldens

---

**创建时间:** 2026-06-07 21:01
**作者:** Claude Sonnet 4.6
