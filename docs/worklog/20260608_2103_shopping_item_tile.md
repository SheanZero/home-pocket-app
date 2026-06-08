# ShoppingItemTile 实现 (Phase 38 Plan 04)

**日期:** 2026-06-08
**时间:** 21:03
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** Phase 38 — 购物清单 UI (v1.6)

---

## 任务概述

实现 `ShoppingItemTile` — 购物清单的核心列表项 widget，包含全部交互功能：DONE-01 动画切换、SHOP-03 双账本左侧边框、MGMT-01 左滑删除、MGMT-03 批量选择保护、SYNC-04 归属标签（仅公共清单）、D38-01 编辑箭头、D38-02 拖拽排序手柄。

---

## 完成的工作

### 1. 主要变更

- **创建** `lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart`
  - `Dismissible` 包裹 `GestureDetector`，`confirmDismiss` 弹出 `showSoftConfirmDialog`，`onDismissed` 先调 `showSuccessFeedback` 再调 `deleteShoppingItemUseCaseProvider`（关键顺序 MGMT-01）
  - `DismissDirection.none` + 隐藏拖拽手柄当 `batchSelectModeProvider.state.isActive`（MGMT-03 / D38-02）
  - `AnimatedDefaultTextStyle` + `AnimatedOpacity` 200ms/easeInOut 划线 + 淡出（DONE-01）
  - `ReorderableDragStartListener(index: index)` — L2 fix for `buildDefaultDragHandles:false`
  - 归属标签通过 `ref.watch(shadowBooksProvider).value ?? const []`（Riverpod 3 `.value` 非 `.valueOrNull`），仅公共清单渲染（T-38-04-01）
  - 估算价格：`AppTextStyles.amountSmall.copyWith(color: palette.joyText)`（绝不用 raw `palette.joy`）

- **创建** `lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart`
  - Plan 38-07 的编译前桩（stub），仅包含正确构造函数签名，body 为 loading indicator

- **新增 ARB 键** (ja/zh/en 三语)：7 个购物项交互字符串

- **创建** `test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart`
  - 10 个测试：SHOP-02/03、DONE-01、MGMT-03、SYNC-04 全覆盖

- **创建** `test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_swipe_test.dart`
  - 4 个测试：MGMT-01 左滑删除完整流程

### 2. 技术决策

- `showSuccessFeedback` 必须在 `execute()` 之前调用（context 在 onDismissed 之后可能失效）
- 测试使用 `overrideWithValue(MockUseCase)` 而非 duck-typed fake，Riverpod 3 需要精确类型匹配
- `_pumpTile` 用命名参数 `shadowBooksOverride` 避免重复 override 断言
- 左滑测试 `tester.fling` 后需 `pump() + pump(500ms)` 等待 `confirmDismiss` 异步 Dialog 出现

### 3. 代码变更统计

- 创建文件：4 个
- 修改文件：7 个（ARB + generated）
- 测试：2416/2416 全部通过（新增 +30）
- flutter analyze lib/: 0 新增问题（2 个预存 deprecated info 不在本计划范围）

---

## 遇到的问题与解决方案

### 问题 1: 类型错误 — fake 类无法满足 Riverpod 3 provider override
**症状:** `A value of type '_FakeDeleteUseCase' can't be returned from a function with return type 'DeleteShoppingItemUseCase'`
**原因:** Riverpod 3 的 `overrideWith` 要求返回值与 provider 声明类型完全匹配
**解决方案:** 改用 `overrideWithValue(MockDeleteShoppingItemUseCase())` + Mocktail mock

### 问题 2: shadowBooksProvider 重复 override 断言
**症状:** `Tried to override a provider twice within the same container: shadowBooksProvider`
**原因:** `_pumpTile` 设了默认 override，`extraOverrides` 中又传了一个
**解决方案:** 在 `_pumpTile` 签名中加 `Override? shadowBooksOverride` 命名参数，替换默认值

### 问题 3: 左滑后 Dialog 不出现
**症状:** `find.byType(Dialog)` 返回 0 matches
**原因:** `confirmDismiss` 是异步的，单次 `pump()` 不足以完成 dialog route inflating
**解决方案:** 添加 `await tester.pump(const Duration(milliseconds: 500))`

---

## 测试验证

- [x] 单元测试通过（shopping_item_tile_test.dart 10/10）
- [x] 集成测试通过（shopping_item_tile_swipe_test.dart 4/4）
- [x] 全套测试通过（2416/2416）
- [x] flutter analyze 0 新增问题
- [x] 代码审查完成（自动 Rule 1/2/3 修复均已记录）

---

## Git 提交记录

```
Commit: 13c201dd
feat(38-04): implement ShoppingItemTile with all D38 interaction affordances

Commit: 71998d7f
test(38-04): fill in shopping_item_tile_test.dart and shopping_item_tile_swipe_test.dart

Commit: 365f97c7
docs(38-04): complete ShoppingItemTile plan
```

---

## 后续工作

- [ ] Plan 38-06: ShoppingListScreen 消费 ShoppingItemTile
- [ ] Plan 38-07: 实现完整 ShoppingItemFormScreen（替换本计划的桩）

---

**创建时间:** 2026-06-08 21:03
**作者:** Claude Sonnet 4.6
