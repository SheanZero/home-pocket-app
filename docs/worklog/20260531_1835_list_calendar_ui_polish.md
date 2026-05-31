# 日历列表页 UI 6 项调整

**日期:** 2026-05-31
**时间:** 18:35
**任务类型:** 功能开发 / UI
**状态:** 已完成（视觉 UAT 待人工确认）
**相关模块:** MOD-001 列表 / List feature
**Quick Task:** 260531-oqn

---

## 任务概述

对列表（日历）页做 6 项 UI 调整，使其头部与统计页保持一致、日历对齐与配色更合理、排序简化、列表项布局按一级类目图标 + 二级类目名重构。通过 `/gsd-quick` 流程执行（plan → execute，worktree 隔离，原子提交）。

---

## 完成的工作

### 1. 主要变更（4 个原子提交 + 1 个测试修复提交）

- `b0926be3` feat(260531-oqn-ui-01)：ListScreen 加 `Scaffold` + `AppBar`，当前月份移到 AppBar 标题（居中，可点击跳当月），左 `chevron_left` / 右 `chevron_right` 翻月；删除 `list_calendar_header.dart` 中的 `_MonthNavBar`；无金额日期格补 `SizedBox(height:14)` 占位使数字垂直对齐。
- `6efd1de9` feat(260531-oqn-ui-02)：新增 `WeekStartDay` 枚举与 `AppSettings.weekStartDay`（默认 `monday`），`SettingsRepositoryImpl` 用 SharedPreferences key `week_start_day` 持久化；外观设置页加「每周起始日」选择器（周一/周日）；日历 `startingDayOfWeek` 读 provider；周六数字蓝色 `0xFF1565C0`、周日黑色（`AppColors.textPrimary`），按 `day.weekday` 判定。新增 3 个 ARB key（ja/zh/en）。
- `8b75cd91` feat(260531-oqn-ui-03)：`SortField` 删除 `updatedAt`，仅留 `timestamp` + `amount`；`ListSortConfig` 默认改 `timestamp`（降序）；同步删除 `transaction_dao.dart` 的 `updatedAt` ORDER BY 映射与 `list_sort_filter_bar.dart` 的「更新日期」选项。
- `09faf694` feat(260531-oqn-ui-04)：重构 `ListTransactionTile` —— 主标题 = 一级类目图标 + 二级类目名（灵魂账本追加满足度 emoji）；副标题 = 账本类型（+ 店名，如有）；右侧仅金额；去除时间显示。`list_screen.dart` 加 `_resolveL1IconForCategory` 解析一级类目图标。tile golden re-baseline。
- `002ac6b3` fix(260531-oqn-ui-03)：随 `SortField.updatedAt` 移除更新受影响的测试。

### 2. 技术决策

- **需求 1（头部）经用户澄清**：选「加 AppBar，月份放标题」，与统计页（`analytics_screen.dart` 自带 `Scaffold` + `AppBar`）结构对齐；AppBar 提供状态栏间距，解决「头部无月份」+「顶太高」两点。
- **周末配色按 `day.weekday` 而非列位置**：在 item 3 可变周起始下仍正确。
- **一级类目图标**：用 `list_screen.dart` 内静态映射（避免 build 中同步 DB 调用），调用方解析、tile 纯展示。

### 3. 代码变更统计

- 41 个文件，+426 / −259。
- 主要：`list_screen.dart`、`list_calendar_header.dart`、`list_transaction_tile.dart`、`app_settings.dart`、`settings_repository_impl.dart`、`sort_config.dart`、3 个 ARB + 生成文件、10 个 golden/测试文件。

---

## 测试验证

- [x] `flutter pub run build_runner build` 0 错误
- [x] `flutter gen-l10n` 0 错误
- [x] `flutter analyze` 0 新问题
- [x] `flutter test` 2238/2238 通过；43 golden 全通过（已 re-baseline）
- [ ] 真机视觉 UAT（待人工确认）

---

## Git 提交记录

```
b0926be3 feat(260531-oqn-ui-01): ListScreen AppBar with month nav + empty-cell placeholder
6efd1de9 feat(260531-oqn-ui-02): week-start setting + Saturday blue + calendar wiring
8b75cd91 feat(260531-oqn-ui-03): remove updatedAt from SortField — Date+Amount only
09faf694 feat(260531-oqn-ui-04): re-baseline tile goldens for rebuilt ListTransactionTile layout
002ac6b3 fix(260531-oqn-ui-03): update tests for SortField.updatedAt removal
```

---

## 后续工作

- [ ] 真机/模拟器视觉确认 6 项改动（尤其 AppBar 翻月、周末配色、列表项布局、灵魂满足度 emoji）。
- [ ] 确认「每周起始日」设置变更后日历即时刷新。

---

**创建时间:** 2026-05-31 18:35
**作者:** Claude (gsd-quick 260531-oqn)

---

## 追加修复（2026-05-31 19:45，真机反馈后）

commit `8999a77e`：

1. **周日数字改红色**（`0xFFD32F2F` Material Red 700）—— 原需求 #4 设的黑色，真机确认后改红；周六仍蓝（`0xFF1565C0`）。
2. **列表项左侧重排**（`list_transaction_tile.dart`）：
   - 一级类目图标移到 leading 位置，放大到 28dp 并垂直居中（跨主/副两行）。
   - 灵魂/生存标记由纯文字改为**背景 badge**（`tagBgColor` 圆角 pill），且与二级类目标题**左对齐**（同一左边界，图标右侧）。
   - 店名改为 badge 右侧的弱化文字（`textSecondary`）。
- 验证：`flutter analyze` 0 问题；list widget + golden 共 69 测试通过；`list_calendar_header` / `list_transaction_tile` goldens 三语言 re-baseline。
- 仍待真机视觉确认。

---

## 追加修复 2（2026-05-31 19:55，真机反馈后）

commit `b5615c72`：

1. **去掉当天（31 日）外框 + 背景**：移除 `isToday` 装饰分支，仅选中日保留填充 chip。
2. **日历更紧凑**：`rowHeight` 52→44、`daysOfWeekHeight` 20→18，减少周间距。
3. **星期表头配色与日期一致**：周六蓝、周日红（按真实 `weekday`），用 `dowBuilder` + 新增 `DateFormatter.formatShortWeekday`；周末色提为共享常量 `_saturdayColor`/`_sundayColor`，日期格与表头复用。
4. **最后一条被底部菜单挡住**：`ListView` 加 `padding: bottom 100`，让末行避开悬浮底栏。
- 验证：`flutter analyze` 0 问题；list widget + golden 共 69 测试通过；`list_calendar_header` goldens 三语言 re-baseline。仍待真机视觉确认。
