# Phase 28 Plan 04: CategoryFilterSheet + ListEmptyState

**日期:** 2026-05-30
**时间:** 21:01
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** Phase 28 — Transaction Tile + Sort/Filter Bar

---

## 任务概述

实现 CategoryFilterSheet（C-05）和 ListEmptyState（C-06）两个 Flutter widget。CategoryFilterSheet 是一个带有 L1→L2 级联选择和三态 Checkbox 的多选底部弹窗。ListEmptyState 是一个根据 `isFilterActive` 标志显示不同空状态的占位符 widget。

---

## 完成的工作

### 1. CategoryFilterSheet (`lib/features/list/presentation/widgets/list_category_filter_sheet.dart`)

- `ConsumerStatefulWidget`，接受 `required Set<String> initialSelected`
- 本地 `_localSelected` 状态与 `listFilterProvider` 隔离，直到点击"适用"才写入
- `_loadCategories()` 完整复制 `category_selection_screen.dart` 的加载模式
- `_L1SelectState` 枚举（none/partial/all）实现三态逻辑
- `_l1State()` 根据子类别选中数量计算状态
- `_toggleL1()` 实现 L1 级联：none→all 选中全部子类别；all→none 取消全部
- 三态 Checkbox 渲染：`tristate: s == _L1SelectState.partial`，`value: null` 表示部分选中
- Apply 按钮：`setCategories(Set<String>.unmodifiable(_localSelected))` + `Navigator.pop`
- Cancel 按钮：仅 `Navigator.pop`，不修改 provider
- 使用 accounting feature 的 `categoryRepositoryProvider`（show import，不创建重复文件）

### 2. ListEmptyState (`lib/features/list/presentation/widgets/list_empty_state.dart`)

- `ConsumerWidget`，接受 `required bool isFilterActive`
- `isFilterActive = false`：显示 `Icons.receipt_long_outlined`，无操作按钮
- `isFilterActive = true`：显示 `Icons.search_off_outlined` + TextButton 调用 `clearAll()`
- 占位符文本将在 Phase 30 替换为 ARB key

### 3. 测试文件更新

- 将两个 Wave 0 stub 测试文件替换为真实 widget 测试
- CategoryFilterSheet 测试：使用 `ProviderScope` + `currentLocaleProvider` override 解决异步重试计时器问题
- ListEmptyState 测试：验证两条渲染路径的图标和按钮存在性

### 4. 代码变更统计

- 新建文件：4（2 widget + 2 test）
- 修改文件：0
- 主要文件路径：
  - `lib/features/list/presentation/widgets/list_category_filter_sheet.dart`
  - `lib/features/list/presentation/widgets/list_empty_state.dart`
  - `test/widget/features/list/list_category_filter_sheet_test.dart`
  - `test/widget/features/list/list_empty_state_test.dart`

---

## 遇到的问题与解决方案

### 问题 1: `ProviderElement.triggerRetry` 挂起计时器导致测试失败

**症状:** 测试在 `pumpAndSettle()` 后报 "A Timer is still pending even after the widget tree was disposed"

**原因:** `CategoryFilterSheet` 调用 `ref.watch(currentLocaleProvider)`，该 provider 依赖 `settingsRepositoryProvider` → `appDatabaseProvider`。使用 `UncontrolledProviderScope` 时，即使覆盖了 `categoryRepositoryProvider`，`currentLocaleProvider` 仍然失败并触发 Riverpod 内部的异步重试计时器。

**解决方案:** 改用 `ProviderScope`（绑定到 widget 生命周期），同时覆盖 `categoryRepositoryProvider` 和 `currentLocaleProvider.overrideWith((_) async => const Locale('ja'))`，防止 locale provider 进入错误重试循环。

---

## 测试验证

- [x] CategoryFilterSheet 单元测试通过（3/3）
- [x] ListEmptyState 单元测试通过（2/2）
- [x] `flutter analyze lib/features/list/presentation/widgets/` — 0 issues
- [x] 无硬编码十六进制颜色
- [x] 无重复 repository_providers.dart 文件

---

## Git 提交记录

```
Commit: 0ef7913
feat(28-04): build CategoryFilterSheet — L1/L2 multi-select bottom sheet with tristate (C-05)

Commit: e902376
feat(28-04): build ListEmptyState structural placeholder (C-06)

Commit: a5bbd0b
docs(28-04): complete CategoryFilterSheet + ListEmptyState plan
```

---

## 后续工作

- [ ] Phase 28-05: ListSortFilterBar — 集成 CategoryFilterSheet（通过 `showModalBottomSheet`）
- [ ] Phase 28-06: ListScreen — 集成 ListEmptyState
- [ ] Phase 30: 将占位符字符串替换为 ARB key（listEmptyFiltered / listEmptyMonth / listEmptyFilteredClear）

---

## 参考资源

- 计划文档: `.planning/phases/28-transaction-tile-sort-filter-bar/28-04-PLAN.md`
- 总结文档: `.planning/phases/28-transaction-tile-sort-filter-bar/28-04-SUMMARY.md`
- 模式参考: `.planning/phases/28-transaction-tile-sort-filter-bar/28-PATTERNS.md`

---

**创建时间:** 2026-05-30 21:01
**作者:** Claude Sonnet 4.6
