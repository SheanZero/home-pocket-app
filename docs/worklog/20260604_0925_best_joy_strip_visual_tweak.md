# 本月最爱（Best Joy strip）视觉微调

**日期:** 2026-06-04
**时间:** 09:25
**任务类型:** UI 调整
**状态:** 已完成
**相关模块:** [MOD-007] Analytics / Home Hero Card

---

## 任务概述

调整首页「本月最爱」票根卡（`HomeHeroCard._bestJoyValue` / `_bestJoyCalendarTile`）的日历瓦片与右侧满意度印记的视觉细节，按用户反馈迭代两轮定稿。

---

## 完成的工作

### 日历瓦片（`_bestJoyCalendarTile`）
- 日期数字字号 19 → **17**（值态 + 占位「—」一并改）
- 月份带 ↔ 日期数字间距 `SizedBox` 3 → **7**，月份带垂直内边距 3 → **4** —— 顶部不再挤在一起

### 右侧满意度印记（`_bestJoyValue`）
- 满意度 icon 放大 24 → **30**
- icon ↔ 档位词间距 3 → **6**
- 两侧保留 6px 留白（`Padding(horizontal: 6)`）
- 颜色保持原 **`satisfactionPillRose` 玫瑰色**、无底色（无框印记）

### 迭代记录
- 第一轮曾尝试「白色 icon + 白色文字」：因票根主体为极浅粉（joy 7% alpha 叠暖米白），白字在浅色模式对比度仅 ~1.05:1 不可见，故配套加了深玫瑰实心「印章」底（浅色 `joyText` / 深色 `joy` 压暗 40%）。
- 用户反馈实心印章「不好看」→ **回退**：去掉实心背景与白字，改回玫瑰色无框，但**保留**放大后的 icon 尺寸与间距。
- 回退后移除了不再使用的 `sealColor` 派生变量，避免 `color_literal_scan` 命中（曾用 `Colors.black.withValues(alpha:0.4)` 规避 `Color(0x..)` 原始字面量）。

### 代码变更统计
- 1 个源文件：`lib/features/home/presentation/widgets/home_hero_card.dart`
- 10 张 golden master 重拍（`test/golden/goldens/home_hero_card_*.png`）

---

## 测试验证

- [x] `flutter analyze` —— 0 新增（仅 4 处既有遗留：firebase 示例 + 2× onReorder deprecation）
- [x] `flutter test` 全量 —— **2313/2313 全绿**
- [x] golden 明/暗目视确认（日期更小+顶部更松、满意度 icon 放大且无框玫瑰）

---

## 后续工作

- 无。如需进一步调整间距/留白，单点改即可。
