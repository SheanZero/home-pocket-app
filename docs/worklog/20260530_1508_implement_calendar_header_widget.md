# CalendarHeaderWidget 实现

**日期:** 2026-05-30
**时间:** 15:08
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [Phase 27] Calendar Header + Month Summary

---

## 任务概述

实现 `CalendarHeaderWidget` —— 完整的日历 UI，包含月份导航栏、带自定义日格的 `TableCalendar`，以及含当月合计 + 条件性日汇总行的 `SummaryRow`。将其挂载到 `ListScreen` 顶部。替换 Wave 0 widget test stubs 为 3 个通过的测试 (SC#1/SC#3/SC#4)。

---

## 完成的工作

### 1. 主要变更

- **新增** `lib/features/list/presentation/widgets/list_calendar_header.dart`
  - `CalendarHeaderWidget extends ConsumerWidget`，参数 `{bookId, currencyCode, locale}`
  - 月份导航栏 (`_MonthNavBar`)：左右 chevron 48dp 触控目标 + 月份标签点击跳回当月
  - `TableCalendar`：`CalendarFormat.month` 锁定，`headerVisible: false`，`rowHeight: 52`，locale-aware `startingDayOfWeek`
  - 自定义日格 (`_buildDayCell`)：4 种状态 (selected/today/default/outside)，`_dayKey` 归一化
  - 当月合计 (`_SummaryRow`)：`AppTextStyles.amountSmall`，`AnimatedSize` 日汇总子行
  - `_onDayTapped` toggle：`selectDay(day)` / `selectDay(null)` via `isSameDay`

- **修改** `lib/features/list/presentation/screens/list_screen.dart`
  - 移除旧的 `transactionsAsync.when()` 结构
  - 改为 `Column`，`CalendarHeaderWidget` 置顶
  - `currencyCode = 'JPY'` Phase 27 占位符 (Phase 29 seam comment)
  - 使用 `currentLocaleProvider.value ?? Locale('ja')` (Riverpod 3 pattern)

- **修改** `test/widget/features/list/presentation/widgets/list_calendar_header_test.dart`
  - 替换 Wave 0 TODO stubs 为 3 个真实 widget 测试
  - TDD RED → GREEN → REFACTOR 流程完整执行

### 2. 技术决策

- `currencyCode` 在 Phase 27 作为 const `'JPY'` 传递，避免从 `bookByIdProvider` 读取（import-guard 风险，该 provider 属于 analytics/home feature）
- 提取 `_MonthNavBar` 和 `_SummaryRow` 为 private `StatelessWidget` 类，控制 `build()` 方法行数
- `error` callback 参数使用 `(e, st)` 而非 `(_, __)` 以满足 lint 规则

### 3. 代码变更统计

- 创建文件：1 (`list_calendar_header.dart`)
- 修改文件：2 (`list_screen.dart`, `list_calendar_header_test.dart`)
- 新增代码：~400 行

---

## 遇到的问题与解决方案

### 问题 1: `dart:ui` 不必要导入
**症状:** `flutter analyze` 报 `unnecessary_import` for `dart:ui`
**原因:** `Locale` 已通过 `package:flutter/material.dart` 重新导出
**解决方案:** 移除 `import 'dart:ui'` 从 widget 文件和测试文件

### 问题 2: 错误回调参数命名 lint 冲突
**症状:** `(_, __)` 触发 `unnecessary_underscores`；`(_, _s)` 触发 `no_leading_underscores_for_local_identifiers`
**原因:** Dart linter 规则不允许多个下划线参数或以下划线开头的本地标识符
**解决方案:** 改为 `(e, st)` 明确命名

---

## 测试验证

- [x] SC#1 widget 测试通过：右侧 chevron 点击将 `selectedMonth` 前进 1
- [x] SC#3 widget 测试通过：点击日格选中；再次点击清除 `activeDayFilter`
- [x] SC#4 widget 测试通过：摘要行显示 JPY 当月合计 (`¥12,345`)
- [x] 全部 5 个 provider 单元测试继续通过
- [x] `flutter analyze` 0 新增 issues（4 个已有 pre-existing issues）
- [x] 全套测试：2149 通过，12 失败（全为 pre-existing failures，无新增）

---

## Git 提交记录

```
Commit: 0228717
test(27-03): add failing widget tests for CalendarHeaderWidget (SC#1/SC#3/SC#4)

Commit: 85fc53b
feat(27-03): implement CalendarHeaderWidget with full calendar UI

Commit: e3e5f54
feat(27-03): mount CalendarHeaderWidget in ListScreen

Commit: 661df78
chore(27-03): remove unnecessary dart:ui import from widget test

Commit: ac3977e
docs(27-03): complete CalendarHeaderWidget plan
```

---

## 后续工作

- [ ] Phase 27 Plan 04 — 最终验证 / 收尾
- [ ] Phase 28 — Transaction Tile + Sort/Filter Bar（替换 `list_screen.dart` 中的 placeholder spinner）
- [ ] Phase 29 — `currencyCode` 从 `bookByIdProvider` 动态读取

---

## 参考资源

- `.planning/phases/27-calendar-header-month-summary/27-03-PLAN.md`
- `.planning/phases/27-calendar-header-month-summary/27-UI-SPEC.md`
- `.planning/phases/27-calendar-header-month-summary/27-PATTERNS.md`
- `lib/features/list/presentation/providers/state_calendar_totals.dart` (Plan 27-02)

---

**创建时间:** 2026-05-30 15:08
**作者:** Claude Sonnet 4.6
