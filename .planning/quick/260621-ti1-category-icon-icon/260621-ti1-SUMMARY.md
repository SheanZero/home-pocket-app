---
phase: quick-260621-ti1
plan: 01
subsystem: analytics-presentation
tags: [analytics, donut, joy-spend, category-icon, l1-rollup, fl_chart]
requirements: [TI1-ICON-01]
status: complete
provides:
  - "donut_hero 分类 legend 行 leading L1 icon（无色块，icon 取 arc 颜色）"
  - "donut_hero 圆环显示了%的扇区 icon+% 合成居中 Column badge（icon 在 % 正上方、中线对齐）"
  - "donut_hero 圆环放大：外径 ×1.2（radius 41.4）/ 内径 ×1.1（centerSpaceRadius 59.4）"
  - "JoySpendSegment.icon 字段 + 悦己 legend 行 leading L1 icon（无色块，icon 取 segment 颜色）"
requires:
  - "parentCategoryIconFromId (lib/features/accounting/presentation/utils/category_display_utils.dart)"
  - "fl_chart 1.2.0 PieChartSectionData.badgeWidget"
affects:
  - lib/features/analytics/presentation/widgets/donut_hero.dart
  - lib/features/analytics/presentation/widgets/joy_spend_stacked_bar.dart
  - lib/features/analytics/presentation/widgets/joy_spend_drawer_body.dart
tech_stack:
  added: []
  patterns:
    - "复用共享 parentCategoryIconFromId（零新 icon 映射）"
    - "fl_chart badgeWidget + badgePositionPercentageOffset 在环带上叠加 icon"
key_files:
  created: []
  modified:
    - lib/features/analytics/presentation/widgets/donut_hero.dart
    - lib/features/analytics/presentation/widgets/joy_spend_stacked_bar.dart
    - lib/features/analytics/presentation/widgets/joy_spend_drawer_body.dart
decisions:
  - "圆环 icon 仅对「显示了%」的扇区添加（与 % 露出规则一致），抑制的小扇区与「其他」扇区不加 badge"
  - "JoySpendSegment.icon 设为 required（仅一处构造入口 drawer_body），编译期保证不漏传"
metrics:
  duration: "~6 min (Task1+Task2) + 4 轮 checkpoint 迭代（放大/icon位/去色块）"
  completed_date: "2026-06-21"
  tasks_completed: "3 of 3 (设备端 UAT approved)"
  files_modified: 3
  commits: 6
---

# Quick 260621-ti1: 分类支出卡片三处加 L1 类目 icon Summary

统计页「分类支出」donut 卡片三处加上「上一级（L1 顶层）类目」icon——分类维度详细列表行、悦己/Joy「钱花在哪」legend 行、以及圆环每个「显示了百分比」扇区的 % 标签上方；全部经共享 `parentCategoryIconFromId` 解析，零新 ARB、零数据层改动、零新依赖。

## 执行状态

- **Task 1 (auto):** ✅ 完成并提交 — commit `0903114b`
- **Task 2 (auto):** ✅ 完成并提交 — commit `a2925f42`
- **icon golden 重基线（Task1/2）:** ✅ commit `0064693f`
- **Task 3 (checkpoint:human-verify, gate="blocking"):** ✅ **设备端 UAT approved**（2026-06-21）。全量门禁（`flutter analyze` 0、`flutter test` 3091/3091）+ golden macOS 重基线由 orchestrator 执行；用户设备端确认通过，期间提出 4 项跟进调整（见下「跟进变更」），均已实现并各自重基线+全绿后提交。

## 完成的工作

### Task 1 — donut_hero.dart（commit 0903114b）

(A) **分类 legend 行**：`LegendRow` 新增可空字段 `final IconData? leadingIcon;`（ctor 参数）。在 build 的 Row 中，swatch 色块与 name Text 之间，当 `leadingIcon != null` 时渲染 `Icon(leadingIcon, size: 14, color: palette.textSecondary)` + `SizedBox(width: 7)`。分类维度 legend 构造处传 `leadingIcon: parentCategoryIconFromId(entry.value.categoryId)`。长尾「其他」行与成员维度 `_buildMemberMode` 行均不传 `leadingIcon`（保持 null → 不渲染 icon；成员行保持其 `leadingEmoji` 头像）。

(B) **圆环扇区 badge**：分类维度 `PieChartSectionData` 新增 `badgeWidget` + `badgePositionPercentageOffset: 0.35`。badge 仅当 `_onRingPctTitle(amount, total) != _suppressedRingTitle`（即该扇区显示了 %）时为 `Icon(parentCategoryIconFromId(entry.value.categoryId), size: 11, color: palette.card)`，否则为 `null`——与 % 露出规则一致，抑制的小扇区无 badge。长尾「其他」扇区不加 badge。

新增 import：`import '../../../accounting/presentation/utils/category_display_utils.dart';`

verify：`flutter analyze` 该文件 0 issue；`grep -c parentCategoryIconFromId` = 2（legend 行 + badge）。

### Task 2 — joy_spend_stacked_bar.dart + joy_spend_drawer_body.dart（commit a2925f42）

(A) **joy_spend_stacked_bar.dart**：`JoySpendSegment`（@immutable）新增 `required final IconData icon;`（放在 `color` 之后）。`_LegendRow.build` 的 Row 中，swatch 11×11 dot 与 `segment.label` Text 之间插入 `Icon(segment.icon, size: 13, color: palette.joyText)` + `SizedBox(width: 7)`。stacked bar 本体彩色段 `_Segment` 未加 icon。

(B) **joy_spend_drawer_body.dart**：构造 `JoySpendSegment(...)` 的 for 循环新增 `icon: parentCategoryIconFromId(entry.value.categoryId)`。新增 import `import '../../../accounting/presentation/utils/category_display_utils.dart';`。该 body 是 `JoySpendCard` 与嵌套 `_JoyDrawer` 的 single source，改一处两入口都生效。

verify：两文件 `flutter analyze` 0 issue；`grep -c parentCategoryIconFromId joy_spend_drawer_body.dart` = 1。

## 跟进变更（Task 3 checkpoint 设备端迭代，均全量门禁绿 + 受影响 golden macOS 重基线）

1. **圆环放大（commit `5ae71263`）** — `donut_hero.dart`：section `radius` 30→**41.4**、`centerSpaceRadius` 54→**59.4**（外径 ×1.2 / 内径 ×1.1），容器 `SizedBox` height 200→**234** 容纳放大环不被裁，center hole `_centerTotalMaxWidth` 96→**106** 保持金额填充比例。widget test `category_donut_card_test.dart` 将 bare card 包进 `SingleChildScrollView`（生产本就在滚动视图内，沿用文件内既有 >10 类目测试同款写法），避免放大后卡片在 800×600 测试窗口 26px 溢出。
2. **圆环 icon 移到 % 正上方、中线对齐（commit `87a313b1`）** — 之前 icon 用 `badgeWidget`(offset 0.35) 与内置 `title`(% offset 0.5) 分置，fl_chart 沿半径定位 → 非 6/12 点钟位扇区上 icon 与 % 横向重叠（`88🍴%`）。改为抑制内置 title（`showTitle: false`），将 icon+% 合成单个居中 `Column` badge（icon 在上、% 在下、`badgePositionPercentageOffset: 0.5` 居环带中部），任意扇区角度都呈 icon 正上方堆叠。
3. **列表行去色块、icon 取色块颜色（commit `6c9794d3`）** — `donut_hero` `LegendRow`：有 L1 icon 的分类行不再画 11×11 色块，icon 颜色 `palette.textSecondary`→该行 arc 颜色（`color`）；成员行（emoji）与「其他」行（无 icon）保留色块。`joy_spend_stacked_bar` `_LegendRow`：去掉 `.jl .dot` 色块，icon 颜色 `palette.joyText`→`segment.color`。

跟进累计受影响 golden：`category_donut_card`（分类变体）、`joy_spend_card`、`analytics_screen_scroll_smoke` 多轮 macOS 重基线；成员/empty 变体在去色块轮未变（成员行保留色块）。

## 遵守的 LOCKED 决策

- 仅用现有共享 `parentCategoryIconFromId`，未新建任何 icon-name→IconData 映射，未复制 drill-down 屏的 `_resolveL1IconForCategory`。
- 成员维度 `_buildMemberMode` legend 行未改（保持 `leadingEmoji` 头像）。
- 圆环 icon 颜色 `palette.card`；列表 icon 颜色初始为 `palette.textSecondary`（分类）/ `palette.joyText`（悦己）——后经跟进#3 改为该行 arc 颜色（`color`）/ `segment.color`，仍为动态色、无硬编码（用户要求 icon 取色块颜色）。
- 零新 ARB key、零数据层/migration 改动、零新依赖（复用 fl_chart 1.2.0 既有 badgeWidget）。

## Deviations from Plan

None — plan executed exactly as written (Task 1 + Task 2). `JoySpendSegment.icon` 取 `required` 而非可空，因为唯一构造入口 `joy_spend_drawer_body.dart` 已确认能解析（categoryId 已是 L1），required 在编译期保证不漏传——属于 plan「加入 const ctor 参数」的直读，非偏差。

## Threat Flags

None — 纯展示层改动：无新输入/网络/IO/存储/依赖。`parentCategoryIconFromId` 对未知/custom id 返回 `Icons.favorite_border`，永不抛异常（T-ti1-01 accept 已确认）。

## Known Stubs

None.

## Task 3 — 人工验收 ✅ APPROVED（checkpoint:human-verify, blocking）

由 orchestrator 在 macOS 上执行 + 用户设备端确认（2026-06-21）：
1. `flutter analyze` 全量 → **0 issue**。✅
2. 受影响 golden macOS 重基线（多轮，diff 仅为预期视觉变化）：`category_donut_card`、`joy_spend_card`、`analytics_screen_scroll_smoke`。✅
3. `flutter test` 全量 → **3091/3091 全绿**。✅
4. 设备/模拟器视觉确认（用户 `approved`）：圆环放大且 icon 在 % 正上方居中、分类/悦己列表行去色块且 icon 取色块颜色、成员维度仍头像 emoji + 色块。✅

## Self-Check: PASSED

- 三文件修改落盘并提交；6 commits（`0903114b`→`6c9794d3`）可经 `git log --grep 260621-ti1` 验证。
- 全量 `flutter analyze` 0、`flutter test` 3091/3091；受影响 golden 已 macOS 重基线。
- 设备端 UAT 用户 approved，blocking checkpoint 关闭，任务 complete。
