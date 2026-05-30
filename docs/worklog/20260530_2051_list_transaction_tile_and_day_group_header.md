# ListTransactionTile and ListDayGroupHeader Implementation (Phase 28 Plan 03)

**日期:** 2026-05-30
**时间:** 20:51
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** Phase 28 — Transaction Tile + Sort/Filter Bar

---

## 任务概述

实现 Phase 28 Plan 03：构建 `ListTransactionTile` 和 `ListDayGroupHeader` 两个 Widget，以及 `buildFlatList` 日期分组辅助函数。将 Wave 0 的 RED 测试桩转为 GREEN。

---

## 完成的工作

### 1. 主要变更

**新建 `lib/features/list/presentation/widgets/list_transaction_tile.dart`:**
- `ListTransactionTile` ConsumerWidget，包裹 `Dismissible(endToStart)` 实现左滑删除
- 匹配 C-04 规格的删除确认对话框（titleSmall/bodyMedium/取消/红色删除按钮）
- `onDismissed` 关键顺序：ScaffoldMessenger → fire-and-forget deleteUseCase → ref.invalidate
- D-09 时间子标签（HH:mm 显示在 category 行右侧，日期在 day-group header 中）
- `buildTileTapHandler()` 导出辅助函数，供父级传入 TransactionEditScreen 导航回调
- `formatTransactionTime()` 辅助函数，直接使用 intl DateFormat（不含日期）
- 严格使用 `AppColors.*`，仅 `Colors.red` 出现在滑动删除背景和删除确认按钮

**新建 `lib/features/list/presentation/widgets/list_day_group_header.dart`:**
- `ListDayGroupHeader` StatelessWidget：32dp 高度，`AppColors.backgroundMuted` 背景，`DateFormatter.formatDate` 日期格式
- 公共 sealed 类型：`ListItem`/`DayHeaderItem`/`TransactionRowItem`（非私有以支持测试中的 `isA<>` 断言）
- `buildFlatList(txs, direction)` 函数：按日历日期分组，按 `SortDirection` 排序日期键

**更新 `test/widget/features/list/list_transaction_tile_test.dart`:**
- ROW-01：onTap 回调被调用 ✓
- ROW-02：左滑显示 AlertDialog ✓

**更新 `test/unit/features/list/list_grouping_test.dart`:**
- asc：最旧日期在前 ✓
- desc：最新日期在前 ✓

### 2. 技术决策

- **onTap 委托给回调**：Tile 本身只调用 `onTap: VoidCallback`，导航逻辑由父级通过 `buildTileTapHandler()` 注入。原因：内部导航会在 Widget 测试中触发 `TransactionDetailsForm._loadCategoryFromSeed` 读取 `appDatabaseProvider`，导致测试失败
- **Sealed 类型公开**：使用 `DayHeaderItem`/`TransactionRowItem` 而非 `_HeaderItem`/`_RowItem`，因为 Dart 私有符号无法从测试文件中引用

### 3. 代码变更统计

- 新增文件：2（list_transaction_tile.dart, list_day_group_header.dart）
- 修改文件：2（测试文件）
- 净增行数：约 360 行

---

## 遇到的问题与解决方案

### 问题 1: ROW-01 测试 — 内部导航触发 appDatabaseProvider
**症状:** tap 后 `pumpAndSettle` 时 TransactionEditScreen 尝试读取未初始化的数据库
**原因:** TransactionEditScreen 的 `_loadCategoryFromSeed` 在 `initState` 中读取 `categoryRepository`，而 `categoryRepository` 依赖 `appDatabaseProvider`
**解决方案:** 将导航逻辑移出 Tile Widget 内部，改为通过 `onTap: VoidCallback` 参数注入；导出 `buildTileTapHandler()` 工厂函数供父级使用

### 问题 2: Sealed 类型私有无法在测试中使用
**症状:** Wave 0 测试桩中使用 `_HeaderItem` 在 test 文件里无法访问私有类型
**原因:** Dart 私有类型只在同一 library（文件）内可见
**解决方案:** 改用公共命名 `DayHeaderItem`/`TransactionRowItem`

---

## 测试验证

- [x] 单元测试通过（list_grouping_test.dart: 2 tests GREEN）
- [x] 集成测试通过（list_transaction_tile_test.dart: 2 tests GREEN）
- [x] flutter analyze lib/features/list/presentation/widgets/ 0 issues
- [ ] 手动测试验证（设备测试在 Phase 28-06 ListScreen 组装后进行）
- [x] 代码审查完成（偏差已记录）

---

## Git 提交记录

```bash
Commit: 2322005
feat(28-03): build ListTransactionTile — Dismissible + tap-to-edit + swipe-delete

Commit: 9d8a0ad
feat(28-03): build ListDayGroupHeader + buildFlatList helper

Commit: 8c3d2c0
docs(28-03): complete list-transaction-tile + day-group-header plan
```

---

## 后续工作

- [ ] Phase 28-04: CategoryFilterSheet（并行 Wave）
- [ ] Phase 28-05: SortFilterBar
- [ ] Phase 28-06: ListScreen 组装（使用本 Plan 的 ListTransactionTile + ListDayGroupHeader + buildFlatList）
- [ ] Phase 30: ARB 国际化（替换硬编码日文字符串）

---

## 参考资源

- Plan: `.planning/phases/28-transaction-tile-sort-filter-bar/28-03-PLAN.md`
- Summary: `.planning/phases/28-transaction-tile-sort-filter-bar/28-03-SUMMARY.md`
- UI-SPEC: `.planning/phases/28-transaction-tile-sort-filter-bar/28-UI-SPEC.md` (C-01, C-02, C-04)
- PATTERNS: `.planning/phases/28-transaction-tile-sort-filter-bar/28-PATTERNS.md`

---

**创建时间:** 2026-05-30 20:51
**作者:** Claude Sonnet 4.6
