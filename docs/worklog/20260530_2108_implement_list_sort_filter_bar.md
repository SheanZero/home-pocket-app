# ListSortFilterBar 实现 (Phase 28 Plan 05)

**日期:** 2026-05-30
**时间:** 21:08
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** Phase 28 — Transaction Tile + Sort/Filter Bar

---

## 任务概述

实现 `ListSortFilterBar` widget (UI-SPEC C-03)，即交易列表的固定排序/筛选控制栏。将 Wave 0 预埋的 RED stub 测试（SC#4 排序标签、FILTER-02 账本 chip、FILTER-04 清除 chip）转为 GREEN。

---

## 完成的工作

### 1. 主要变更

- **新建** `lib/features/list/presentation/widgets/list_sort_filter_bar.dart`
  - `ConsumerStatefulWidget`，持有 `bool _searchExpanded` + `TextEditingController`
  - 排序 chip：`ActionChip` 带 always-accentPrimary 边框，label 始终显示当前字段名（`_sortFieldLabel`，SC#4 强制要求）
  - `showMenu<SortField>` 弹出排序菜单，通过 `RenderBox.localToGlobal` + `RelativeRect` 定位到 chip 下方
  - 方向箭头：`IconButton` 切换 `SortDirection.asc/desc`
  - 三个互斥账本 chip（全部/生存/魂），通过 `setLedgerFilter` 路由
  - 分类计数 chip，点击调用 `showModalBottomSheet(CategoryFilterSheet(...))`
  - `AnimatedContainer` 展开/收起搜索框，含 prefix/suffix 图标
  - 条件渲染 clear chip（`クリア`），仅在 `anyFilterActive` 时显示
  - `clearAll()` + `setState` 同时清空提供者状态和本地搜索状态
  - 新增 `_L10n` helper class 提供 ja/zh/en 字符串映射，避免在非 build 方法中传递 `BuildContext`

- **更新** `test/widget/features/list/list_sort_filter_bar_test.dart`
  - 移除所有 `fail(...)` stub
  - 将 `ProviderContainer.test()` + `UncontrolledProviderScope` 改为 `ProviderScope` + `currentLocaleProvider.overrideWith` 模式（与 `list_category_filter_sheet_test.dart` 保持一致，避免 async 定时器挂起问题）
  - SC#4: `find.text('更新日時')` findsOneWidget + `find.text('Sort')` findsNothing ✓
  - FILTER-02: 点击 `生存` chip → `ledgerType == LedgerType.survival` ✓
  - FILTER-04: 初始无 clear chip，`setLedgerFilter(soul)` 后出现 ✓

### 2. 技术决策

- **_L10n helper vs S.of(context)**: 选择 thin helper class 而非直接引用 `S.of(context)`，原因是 `_showSortMenu` 等方法从按钮回调调用，使用 `S.of(context)` 需要额外传 `BuildContext` 且有 lint 警告。Helper 的字符串值与 28-01 ARB 文件中的值一致。
- **ProviderScope 覆盖 currentLocaleProvider**: 遵循项目中 `list_category_filter_sheet_test.dart` 的先例，避免 async 设置链（DB → `settingsRepositoryProvider` → `localeProvider` → `currentLocaleProvider`）在测试中产生 pending timer 报错。

### 3. 代码变更统计

- 新增文件: 1 (`list_sort_filter_bar.dart`, 385 行)
- 修改文件: 1 (`list_sort_filter_bar_test.dart`, 84 行取代 102 行旧 stub)
- 净增代码: ~574 行 (含测试)

---

## 遇到的问题与解决方案

### 问题 1: currentLocaleProvider async 导致 Pending timers 测试失败

**症状:** `flutter test` 报 "Pending timers: Timer (duration: 0:00:00.200000...)" 并测试失败
**原因:** 初始版本使用 `ProviderContainer.test()` + `UncontrolledProviderScope`，`currentLocaleProvider` 是 Future provider 依赖 DB，触发 retry timer
**解决方案:** 改为 `ProviderScope` + `currentLocaleProvider.overrideWith((_) async => const Locale('ja'))`，与 `list_category_filter_sheet_test.dart` 保持一致

---

## 测试验证

- [x] 单元测试通过 — `flutter test test/widget/features/list/list_sort_filter_bar_test.dart` → 3/3 PASS
- [x] 代码分析通过 — `flutter analyze lib/features/list/presentation/widgets/list_sort_filter_bar.dart` → 0 issues
- [x] 验证 done criteria grep 全部通过 (ConsumerStatefulWidget/\_sortFieldLabel/accentPrimary/showMenu/CategoryFilterSheet/clearAll/AnimatedContainer/listFilterProvider 各 ≥ 1 次，'Sort' 硬编码标签 = 0)

---

## Git 提交记录

```
Commit: 1cefd25
Date: 2026-05-30
feat(28-05): build ListSortFilterBar pinned chip bar (C-03)

Commit: 9d44e4c
Date: 2026-05-30
docs(28-05): complete ListSortFilterBar plan summary and state update
```

---

## 后续工作

- Phase 28 Plan 06: 将 ListSortFilterBar 集成到 ListScreen (替换现有的 CircularProgressIndicator 占位符)
- Phase 28 Plan 07: 收尾/清理

---

**创建时间:** 2026-05-30 21:08
**作者:** Claude Sonnet 4.6
