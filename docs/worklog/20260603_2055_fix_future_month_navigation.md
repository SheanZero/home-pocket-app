# 修复未来月份越界导致 analytics endDate 崩溃

**日期:** 2026-06-03
**时间:** 20:55
**任务类型:** Bug修复
**状态:** 已完成
**相关模块:** Home 首页月份导航 + List 列表月份导航

---

## 任务概述

用户点击首页 HeroHeader 或列表页 AppBar 的向右箭头可以切换到未来月份，导致 analytics providers 抛出 "endDate must not be in the future" 错误。修复方案：在 UI 层隐藏向右箭头（当已处于当前月份时），并在 notifier 层加保险锁（clamp guard），双重防护。

---

## 完成的工作

### 1. 主要变更

**HeroHeader (`lib/features/home/presentation/widgets/hero_header.dart`)**
- 新增 `required bool showNextChevron` 参数
- 当 `showNextChevron: false` 时，用 `SizedBox(28×28)` 替换右侧 `IconButton`，保持布局稳定

**HomeScreen (`lib/features/home/presentation/screens/home_screen.dart`)**
- 读取 `selectedMonth` 后派生 `isCurrentMonth = year == now.year && month == now.month`
- 传递 `showNextChevron: !isCurrentMonth` 给 HeroHeader

**HomeSelectedMonth notifier (`lib/features/home/presentation/providers/state_home.dart`)**
- `nextMonth()` 加 clamp 保险：当 `state` 已是当前月份时直接 return（no-op）
- 防止通过编程方式绕过 UI 层防护

**ListScreen (`lib/features/list/presentation/screens/list_screen.dart`)**
- 派生 `isCurrentMonth`
- AppBar `actions:` 使用 collection-if `if (!isCurrentMonth) IconButton(...)`（惯用 Flutter 写法，无需 SizedBox 占位）

### 2. 测试变更

- `test/features/home/presentation/widgets/home_header_test.dart`：7 个已有构造调用加 `showNextChevron: true`；新增"hides right chevron when showNextChevron is false"
- `test/widget/features/home/presentation/widgets/hero_header_test.dart`：helper 加参数 `showNextChevron`；新增"right chevron absent when showNextChevron is false"
- `test/widget/features/list/list_screen_refresh_test.dart`：`_pumpScreen` 参数化 `year/month`；新增两个 chevron 可见性测试

### 3. 代码变更统计

- 修改文件：7 个
- 新增测试：4 个
- 代码行：约 +80 行

---

## 遇到的问题与解决方案

无特殊问题。TDD 三阶段（RED → GREEN → verify）均按预期完成。

---

## 测试验证

- [x] 单元/widget 测试通过：2303/2303（新增 4 个）
- [x] flutter analyze 0 新增 issue（2 个遗留 onReorder 警告为历史遗留）
- [ ] 手动测试（设备/模拟器）：留待用户在真机验证当前月份无右箭头

---

## Git 提交记录

```
Commit: 18e62888
feat(260603-stw): add showNextChevron to HeroHeader + clamp nextMonth()

Commit: c0cc3786
feat(260603-stw): hide ListScreen AppBar right chevron when on current month
```

---

## 后续工作

无。quick task 已完成所有目标。

---

**创建时间:** 2026-06-03 20:55
**作者:** Claude Sonnet 4.6
