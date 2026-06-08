# Phase 37 Plan 01: Wave-0 TDD Test Scaffolds

**日期:** 2026-06-08
**时间:** 11:17
**任务类型:** 测试
**状态:** 已完成
**相关模块:** Phase 37 — Application Use Cases + Sync Integration

---

## 任务概述

为 Phase 37 购物清单功能的 TDD 合约创建 Wave-0 测试脚手架。8 个新测试文件 + 4 个现有文件修改，在任何生产代码编写之前建立完整的 RED/GREEN 验证框架。所有新文件故意处于 RED 状态（导入尚不存在的生产类）。

---

## 完成的工作

### 1. 新建 6 个用例单元测试文件（Task 1）

- `test/unit/application/shopping_list/create_shopping_item_use_case_test.dart` — SC-1 隐私门: private create → pendingCount==0; public → 1; ITEM-01 验证
- `test/unit/application/shopping_list/update_shopping_item_use_case_test.dart` — SC-2 listType 不可变: 返回含 'Invariant' 的 Result.error (D37-04)
- `test/unit/application/shopping_list/delete_shopping_item_use_case_test.dart` — MGMT-01/02 软删除 + 隐私门追踪器操作
- `test/unit/application/shopping_list/toggle_item_completed_use_case_test.dart` — DONE-01 切换 + D37-02 主动取消完成清除 completedAt=null
- `test/unit/application/shopping_list/reorder_shopping_items_use_case_test.dart` — D37-01 无追踪器本地排序
- `test/unit/application/shopping_list/clear_completed_items_use_case_test.dart` — DONE-03 批量软删除 + 每项追踪器操作

### 2. 新建变更追踪器测试 + 集成测试脚手架（Task 2）

- `test/unit/application/family_sync/shopping_item_change_tracker_test.dart` — 镜像 transaction_change_tracker_test.dart + D37-06 隐私门组 (SC-3)
- `test/integration/sync/shopping_sync_round_trip_test.dart` — SC-5 端到端: 公共项出现在 watch 流中 (SYNC-06); 私有项永不出现 (SYNC-02); 墓碑不被复活 (SC-4)

### 3. 修改 4 个现有测试文件（原子性构造站点更新）

- `apply_sync_operations_use_case_test.dart` — 添加 shoppingItemRepository 参数 + 3 个新 shopping_item 组测试
- `phase6_sync_coverage_test.dart` — SyncOrchestrator 添加 shoppingChangeTracker 参数 + 新测试
- `sync_providers_characterization_test.dart` — 添加 shoppingItemRepository 覆盖 + shoppingItemChangeTrackerProvider 测试
- `bill_sync_round_trip_test.dart` — 添加 shoppingItemRepository mock 参数

### 4. 技术决策

- 使用真实 ShoppingItemChangeTracker（非 Mock）来断言 pendingCount — 与 transaction_change_tracker_test.dart 模式一致
- apply_sync_operations_use_case_test.dart 新的 shopping 组使用 mock 仓库（单元隔离）; 完整 DB 轮回测试在集成测试中

---

## 遇到的问题与解决方案

无偏离 — 计划完全按照原计划执行。

---

## 测试验证

- [x] 6 个文件存在于 test/unit/application/shopping_list/
- [x] shopping_item_change_tracker_test.dart 存在
- [x] shopping_sync_round_trip_test.dart 存在
- [x] bill_sync_round_trip_test.dart 含 shoppingItemRepository (grep -c = 1)
- [x] phase6_sync_coverage_test.dart 含 shoppingChangeTracker (grep -c = 3)
- [x] create_shopping_item_use_case_test.dart 含 pendingCount (grep -c = 2)

---

## Git 提交记录

```bash
Commit: d653f3dd
Date: 2026-06-08
test(37-01): add Wave-0 use case unit test scaffolds (6 RED files)

Commit: 68095c33
Date: 2026-06-08
test(37-01): add change tracker test + integration scaffold; modify 4 existing construction sites

Commit: 34ceff4f
Date: 2026-06-08
docs(37-01): complete Wave-0 TDD scaffold plan
```

---

## 后续工作

- [ ] Wave 1 (Plan 37-02): 实现 6 个购物清单用例 (create, update, delete, toggle, reorder, clearCompleted)
- [ ] Wave 2 (Plan 37-03): 实现 ShoppingItemChangeTracker + ShoppingItemSyncMapper
- [ ] Wave 3 (Plan 37-04/05): 修改 ApplySyncOperationsUseCase + SyncOrchestrator 构造函数使测试变绿
- [ ] 所有 Wave-0 RED 测试在 Wave 1-3 完成后应变绿

---

**创建时间:** 2026-06-08 11:17
**作者:** Claude Sonnet 4.6
