# Phase 37 Wave 2 — Shopping List Use Cases (Create/Delete/Toggle/Reorder)

**日期:** 2026-06-08
**时间:** 11:30
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** Phase 37 — Application Use Cases + Sync Integration (Wave 2, Plan 37-03)

---

## 任务概述

实现购物清单四个 Use Case：CreateShoppingItemUseCase、DeleteShoppingItemUseCase、ToggleItemCompletedUseCase、ReorderShoppingItemsUseCase。所有 Use Case 依赖 Wave 1（37-02）产出的 ShoppingItemChangeTracker 和 ShoppingItemSyncMapper。将 18 个 Wave-0 RED 测试转为 GREEN。

---

## 完成的工作

### 1. 主要变更

- **CreateShoppingItemUseCase** (`lib/application/shopping_list/create_shopping_item_use_case.dart`)
  - 定义 `CreateShoppingItemParams`（含 `deviceId` 字段，测试所需）
  - ITEM-01 验证：空名返回 `Result.error`
  - D37-06 隐私门：`listType == 'public'` 才调 `tracker.trackCreate`
  - uuid v4 ID 生成

- **DeleteShoppingItemUseCase** (`lib/application/shopping_list/delete_shopping_item_use_case.dart`)
  - MGMT-01/02：空 ID 和 findById not found → error
  - 软删（tombstone）：`_repo.softDelete(itemId)`
  - D37-06 隐私门：public 才调 `tracker.trackDelete(itemId: itemId)`

- **ToggleItemCompletedUseCase** (`lib/application/shopping_list/toggle_item_completed_use_case.dart`)
  - D-03 标记完成：`copyWith(isCompleted: true, completedAt: now, updatedAt: now)`
  - D37-02 主动取消：`copyWith(isCompleted: false, completedAt: null, updatedAt: now)` — 确认 Freezed null != freezed 哨兵，`copyWith(completedAt: null)` 正确清零字段
  - D37-06 隐私门：public 才调 `tracker.trackUpdate`

- **ReorderShoppingItemsUseCase** (`lib/application/shopping_list/reorder_shopping_items_use_case.dart`)
  - D37-01 纯本地：无 changeTracker、无 SyncEngine，仅调 `_repo.reorder(itemId, newSortOrder)`

### 2. 技术决策

- `CreateShoppingItemParams` 内联定义于 use case 文件中（镜像 `CreateTransactionParams` 模式），因为测试需要 `deviceId` 字段而 domain `ShoppingItemParams` 没有
- Freezed `copyWith(completedAt: null)` 验证：在 `shopping_item.freezed.dart` 第 787-790 行确认 null != freezed，所以 null 能正确赋值

### 3. Bug 修复（Rule 1）

- **`delete_shopping_item_use_case_test.dart`** — mocktail stub 注册顺序 bug：
  `any()` 注册在具体 stub 之后，mocktail `_responses.lastWhere()` 从末尾扫描，`any()` 总是优先匹配，导致 `findById('item-pub')` 返回 null
  - 修复：将 `when(() => repo.findById(any()))` 移到 `setUp` 最前，让具体 stub 最后注册，从而优先被 `lastWhere` 命中

### 4. 代码变更统计

- 创建文件：4 个（lib/application/shopping_list/ 下各 use case）
- 修改文件：1 个（delete use case test）
- 测试：18/18 GREEN

---

## 遇到的问题与解决方案

### 问题 1: Mocktail stub 注册顺序导致 2/5 delete 测试失败

**症状:** `softDelete called with correct itemId` 和 `public delete enqueues tombstone tracker op` 失败，`result.isSuccess = false`
**原因:** `when(() => repo.findById(any()))` 注册于具体 stub 之后；mocktail `_responses.lastWhere()` 从后往前扫描，`any()` 排在最后，先被命中，匹配 `'item-pub'` 并返回 null
**解决方案:** 将 `any()` stub 移到 `setUp` 最前，具体 stub 后注册，`lastWhere` 优先命中具体 stub

---

## 测试验证

- [x] 单元测试通过（18/18：create 5 + delete 5 + toggle 4 + reorder 4）
- [x] `flutter analyze lib/application/shopping_list/` → 0 issues
- [x] D37-06 门：`grep -c "if.*listType.*==.*'public'" create_shopping_item_use_case.dart` = 1
- [x] D37-01：`grep -c "trackDelete\|trackCreate\|trackUpdate" reorder_shopping_items_use_case.dart` = 0
- [x] D37-02：`grep -c "completedAt.*null" toggle_item_completed_use_case.dart` = 5

---

## Git 提交记录

```
Commit: 1c554c43
feat(37-03): implement CreateShoppingItemUseCase and DeleteShoppingItemUseCase

Commit: 4adb2f0d
feat(37-03): implement ToggleItemCompletedUseCase and ReorderShoppingItemsUseCase

Commit: 1334e090
docs(37-03): complete Create/Delete/Toggle/Reorder use cases plan
```

---

## 后续工作

- Plan 37-04（并行）：UpdateShoppingItemUseCase + ClearCompletedItemsUseCase
- Plan 37-05：ApplySyncOperationsUseCase + SyncOrchestrator wiring (Wave 3)
- Plan 37-06：Providers + final integration

---

**创建时间:** 2026-06-08 11:30
**作者:** Claude Sonnet 4.6
