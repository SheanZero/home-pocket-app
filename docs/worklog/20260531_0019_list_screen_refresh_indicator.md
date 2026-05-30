# RefreshIndicator + anyFilterActive Fix for list_screen.dart

**日期:** 2026-05-31
**时间:** 00:19
**任务类型:** 功能开发
**状态:** 已完成 (Task 1 — awaiting human checkpoint Task 2)
**相关模块:** [LIST-04] Pull-to-Refresh + [FAM-03] Member Filter

---

## 任务概述

Phase 29 Plan 04 Task 1: 为 `list_screen.dart` 添加 `RefreshIndicator` 并修复 `anyFilterActive` 第5个条件 (`filter.memberBookId != null`)。这是 Phase 29 的最终集成计划，关闭 LIST-04 需求并完成全阶段测试门控。

---

## 完成的工作

### 1. 主要变更

- `lib/features/list/presentation/screens/list_screen.dart`
  - 用 `RefreshIndicator(color: AppColors.accentPrimary)` 包裹 `_buildList` 的整个 `txsAsync.when(...)` 表达式
  - `onRefresh` 回调: 使 `ref.invalidate` 同时失效 `listTransactionsProvider` 和 `calendarDailyTotalsProvider`，然后 `await .future.catchError` 诚实地等待 spinner 完成 (Pitfall F)
  - loading/error 分支包裹在 `SingleChildScrollView(physics: AlwaysScrollableScrollPhysics())` 中 (Pitfall E)
  - 空数据分支的 `ListEmptyState` 也包裹在 `SingleChildScrollView(AlwaysScrollableScrollPhysics)` 中 (Pitfall E 完整修复)
  - `ListView.builder` 添加 `physics: const AlwaysScrollableScrollPhysics()`
  - `anyFilterActive` 增加第5个条件: `|| filter.memberBookId != null` (Pitfall B fix, FAM-03)

- `lib/features/list/presentation/widgets/list_sort_filter_bar.dart`
  - 删除 Plan 03 遗留的 `// ignore: avoid_types_on_closure_parameters` 注释 (Rule 3 auto-fix)
  - 将 `error: (Object e, StackTrace s) => const []` 改为 `error: (e, s) => const []`

- `test/widget/features/list/list_screen_refresh_test.dart`
  - 将 fling 手势目标从 `find.byType(ListView)` 改为 `find.byType(RefreshIndicator)` (Wave 0 测试 bug 修复)
  - `find.byType(SingleChildScrollView).first` 会命中 `ListSortFilterBar` 的横向滚动而非列表区域

### 2. 技术决策

- **Pitfall E 完整修复**: loading/error/empty-data 三个分支都需要 `SingleChildScrollView(AlwaysScrollableScrollPhysics)` 包裹，否则列表为空时拖拽手势无法触发 `RefreshIndicator`
- **fling → drag 修正**: 测试中使用 `tester.drag(find.byType(RefreshIndicator), ...)` 而非 `tester.fling(find.byType(ListView), ...)` — `ListView` 在空数据时不存在，fling 也会命中 filter bar 的 `SingleChildScrollView`

### 3. 代码变更统计
- 修改文件: 3
- 添加: 93 行
- 删除: 66 行

---

## 遇到的问题与解决方案

### 问题 1: Wave 0 测试使用 `find.byType(ListView)` 但空数据时无 ListView
**症状:** 第2、3个刷新测试失败，"no widget found matching ListView"
**原因:** Mock 返回空 `List<Transaction>`，data 分支显示 `ListEmptyState` 而非 `ListView`
**解决方案:** 
1. 给 `ListEmptyState` 也包裹 `SingleChildScrollView(AlwaysScrollableScrollPhysics)` (生产代码修复)
2. 测试改用 `tester.drag(find.byType(RefreshIndicator), ...)` (测试修复)

### 问题 2: `getDailyTotals` 在第3个测试中只被调用1次
**症状:** `verify(getDailyTotals).called(greaterThan(1))` 失败
**原因:** `tester.fling(find.byType(SingleChildScrollView).first, ...)` 命中的是 `ListSortFilterBar` 的横向 chip bar，不是列表区域，导致 `onRefresh` 未被触发
**解决方案:** 改为 `tester.drag(find.byType(RefreshIndicator), ...)` — 直接在 `RefreshIndicator` 上拖拽确保 `onRefresh` 被调用

### 问题 3: 预存在的 stale suppression 测试失败
**症状:** `stale_suppressions_scan_test.dart` 检测到 `list_sort_filter_bar.dart:489` 有未批准的 `// ignore:` 注释
**原因:** Plan 03 遗留，`(Object e, StackTrace s)` 触发 `avoid_types_on_closure_parameters` lint
**解决方案:** 改为 `(e, s)` — Dart 类型推断可处理，删除 ignore 注释

---

## 测试验证

- [x] `flutter test test/widget/features/list/list_screen_refresh_test.dart` — 3/3 PASS
- [x] `flutter test test/unit/features/list/ test/widget/features/list/` — 96/96 PASS
- [x] `flutter analyze lib/features/list/presentation/screens/list_screen.dart` — 0 issues
- [x] `flutter analyze lib/features/list/presentation/widgets/list_sort_filter_bar.dart` — 0 issues
- [ ] Human checkpoint (Task 2): visual pull-to-refresh + family mode verification

**Pre-existing failures (not caused by this task):**
- `test/golden/home_hero_card_golden_test.dart` — 11 pixel diffs from quick task `260522-fj5` (pending re-baseline)

---

## Git 提交记录

```bash
Commit: 63c745e0
Date: 2026-05-31

feat(29-04): add RefreshIndicator + anyFilterActive fix to list_screen.dart

- Wrap _buildList's txsAsync.when(...) in RefreshIndicator (AppColors.accentPrimary)
- onRefresh invalidates listTransactionsProvider + calendarDailyTotalsProvider
- Wrap loading/error/empty branches in SingleChildScrollView(AlwaysScrollableScrollPhysics)
- Add physics: AlwaysScrollableScrollPhysics to ListView.builder
- Add filter.memberBookId != null as 5th anyFilterActive condition (Pitfall B fix)
- Fix pre-existing stale suppress in list_sort_filter_bar.dart
- Update refresh test fling to drag on RefreshIndicator directly
```

---

## 后续工作

- [ ] Human checkpoint (Task 2): 视觉验证 pull-to-refresh + 家庭模式
- [ ] Phase 30: i18n + Empty States + Golden Polish

---

**创建时间:** 2026-05-31 00:19
**作者:** Claude Sonnet 4.6
