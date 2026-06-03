# 首页月份切换 + 查看全部功能实现

**日期:** 2026-06-03
**时间:** 20:21
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [Home Feature] 首页月份导航 + 列表跳转

---

## 任务概述

实现首页两项功能补全：(1) 月份切换器——用 `homeSelectedMonthProvider` 替换硬编码的 `DateTime.now()` 月份；在 `HeroHeader` 加上左/右翻页箭头和月份标签点击打开月历弹窗；所有首页数据 provider 响应所选月份。(2) "查看全部"导航——把现有 TODO 桩接上实现，点击后设置 listFilter 为当前月并切换到列表 Tab。

---

## 完成的工作

### 1. 主要变更

- `lib/features/home/presentation/providers/state_home.dart`：新增 `HomeSelectedMonth` keepAlive notifier，状态为命名记录 `({int year, int month})`，提供 `selectMonth`/`prevMonth`/`nextMonth` 方法
- `lib/features/home/presentation/providers/state_home.g.dart`：代码生成，产出 `homeSelectedMonthProvider`
- `lib/features/home/presentation/widgets/hero_header.dart`：新增 `onPrevMonth`/`onNextMonth` 必填回调；左侧 `IconButton(chevron_left)` + 右侧 `IconButton(chevron_right)` 夹住月份标签 GestureDetector
- `lib/features/home/presentation/screens/home_screen.dart`：
  - watch `homeSelectedMonthProvider` 取 year/month（替换 `DateTime.now()`）
  - `HeroHeader` 传入 `onPrevMonth`/`onNextMonth`/`onDateTap`（打开月历弹窗）
  - 新增 `_showMonthPicker` 静态方法（`showDialog` + 结果回写 provider）
  - 新增 `_MonthPickerDialog`（StatefulWidget，年份限定 2000-2099，4×3 月份网格）
  - "查看全部" onTap 接入 `listFilterProvider.notifier.selectMonth` + `selectedTabIndexProvider.notifier.select(1)`
- `lib/l10n/app_ja.arb` / `app_zh.arb` / `app_en.arb`：新增 `homeMonthPickerTitle`、`homeMonthPickerClose` 三语翻译
- `lib/generated/app_localizations*.dart`：`flutter gen-l10n` 重新生成
- `test/features/home/presentation/widgets/home_header_test.dart`：补充新增的必填参数（Rule 1 自动修复）
- `test/widget/features/home/presentation/widgets/hero_header_test.dart`：同上

### 2. 技术决策

- 弹窗年份限定 `[2000, 2099]`：防止快速点击导致 DateTime 溢出（STRIDE T-s07-02）
- "查看全部"永远跳转到「今天所在月」（非当前选中月）：用户希望列表展示当前账期
- `prevMonth()`/`nextMonth()` 利用 `DateTime(year, month ± 1)` 自然进位（跨年边界自动处理）

### 3. 代码变更统计

- 修改文件：13 个
- 主要文件：state_home.dart, hero_header.dart, home_screen.dart, 3 × ARB, 4 × generated, 2 × test

---

## 遇到的问题与解决方案

### 问题 1: HeroHeader 新增必填参数导致测试编译失败

**症状:** `flutter analyze` 报 8 个 `missing_required_argument` error
**原因:** 两个测试文件的 `HeroHeader(...)` 构造调用未传新增的 `onPrevMonth`/`onNextMonth`
**解决方案:** Rule 1 自动修复——所有测试调用处补充 `onPrevMonth: () {}, onNextMonth: () {}`；`hero_header_test.dart` buildTestWidget helper 增加可选参数并以 `?? () {}` 兜底

---

## 测试验证

- [x] `flutter analyze`: 0 error/warning（2 个 pre-existing info 在非本次文件）
- [x] `flutter test`: 2299/2299 通过，无回归
- [x] 首页 home + widget golden 全组通过（104 tests）
- [x] ARB 三文件 homeMonthPickerTitle/homeMonthPickerClose 均已添加
- [x] homeSelectedMonthProvider grep 验证存在于 home_screen.dart
- [x] listFilterProvider.notifier.selectMonth 接入 view-all tap 验证

---

## Git 提交记录

```
Commit: baa2f927
feat(260603-s07): add homeSelectedMonthProvider + HeroHeader prev/next chevrons

Commit: 2f6e93ca
feat(260603-s07): wire homeSelectedMonthProvider + month dialog + view-all nav
```

---

## 后续工作

- 无需后续跟进；功能完整落地

---

**创建时间:** 2026-06-03 20:21
**作者:** Claude Sonnet 4.6
