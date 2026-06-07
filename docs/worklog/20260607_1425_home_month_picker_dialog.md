# 首页月份选择改为弹窗式月份网格选择

**日期:** 2026-06-07
**时间:** 14:25
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [MOD-001] 基础记账 / 首页 home/presentation

---

## 任务概述

将首页 header 的左右翻月箭头（‹ ›，逐月步进）改为：点击月份标签弹出「月份网格」对话框选择。
弹窗顶部 `‹ YYYY年 ›` 年份导航，下面 3×4 月份网格，当前选中月灰底胶囊高亮，未来月份/未来年置灰禁用。
（quick task 260607-jrz）

---

## 完成的工作

### 1. 主要变更

- **新建 `lib/features/home/presentation/widgets/month_picker_dialog.dart`**
  - 顶层助手 `showMonthPickerDialog(context, {selectedYear, selectedMonth})` 包 `showDialog`，
    居中圆角卡片（`palette.background` + `RoundedRectangleBorder(16)`），返回 `({int year, int month})?`。
  - 私有 `StatefulWidget` 持有显示年份。年导航行：`Icons.chevron_left`（始终可用、年-1）+
    本地化年标题 `analyticsTimeWindowChipLabelYear`（accentPrimary）+ `Icons.chevron_right`
    （`displayYear >= now.year` 时 `onPressed: null` 禁用、染 textTertiary）。
  - `GridView.count(crossAxisCount: 3)` 12 格，文案 `homeMonthLabel(month)`。选中→`backgroundMuted`
    中性胶囊；未来月（`displayYear==now.year && month>now.month`）→ textTertiary 置灰不可点；
    可点月份 tap → `Navigator.pop((year, month))`。
- **`hero_header.dart`**：移除 `onPrevMonth`/`onNextMonth`/`showNextChevron` 及两个 chevron
  IconButton + Transform.translate + SizedBox 占位；新增必填 `onMonthTap`；月标签 +
  `Icons.keyboard_arrow_down` 包进单个 `InkWell` 整体 tap 区域。其余（Spacer/mode badge/settings）不变。
- **`home_screen.dart`**：`onMonthTap` 打开弹窗，非空结果（`context.mounted` 守卫）→
  `homeSelectedMonthProvider.notifier.selectMonth(...)`。删除仅供旧 chevron 用的 `now`/`isCurrentMonth` 局部。
- **测试**：`hero_header_test.dart` + `home_header_test.dart` 改用新 API，删 chevron 导航用例，
  新增「无 chevron」「有 keyboard_arrow_down」「点标签触发 onMonthTap」。

### 2. 技术决策

- 复用既有 ARB key（`homeMonthLabel` / `analyticsTimeWindowChipLabelYear`），无需新增、无需 `flutter gen-l10n`。
- 弹窗为纯 UI widget，返回 `(year, month)`，provider 写入留在 home_screen（保持 header 纯净）。
- 未来月份/未来年通过 `onPressed`/`onTap` 置 null 禁用，沿用 `nextMonth()` clamp 语义。

### 3. 代码变更统计

- 新建 2 文件，修改 4 文件；3 个 atomic commit。

---

## 测试验证

- [x] TDD：6 个弹窗 widget 测试先 RED 后 GREEN（6/6）
- [x] `flutter analyze` 改动 4 文件 0 issues（全工程 4 issues 均为既有遗留、非本次文件）
- [x] `flutter test test/widget/features/home/ test/features/home/` 112/112 绿
- [x] 无硬编码 hex（grep=0）；无残留 `onPrevMonth/onNextMonth/showNextChevron` 引用
- [x] 无 golden 受影响（无 hero_header golden）

---

## Git 提交记录

```
80b16179 feat(260607-jrz): add month-grid picker dialog
15d11f73 feat(260607-jrz): rewire home header to tap-to-open month picker
99debfc6 test(260607-jrz): update header tests for tap-to-open month picker API
```

---

## 后续工作

- [ ] 设备/模拟器目视确认：点月份标签开弹窗、未来月/未来年禁用、选月后首页刷新并关闭弹窗。

---

## 参考资源

- Plan / Context: `.planning/quick/260607-jrz-month-picker-dialog/`
- 配色：`docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md`

---

**创建时间:** 2026-06-07 14:25
**作者:** Claude Opus 4.8
