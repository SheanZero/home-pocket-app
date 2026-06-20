---
phase: quick-260620-v2m
plan: 01
subsystem: analytics
status: complete
tags: [analytics, trend-chart, donut, member-dimension, fl_chart, i18n, golden]
requires:
  - "lib/features/accounting/domain/repositories/transaction_repository.dart (findByBookIds)"
  - "lib/features/family_sync/presentation/providers/state_sync.dart (activeGroupMembers)"
  - "lib/features/analytics/domain/category_l1_rollup.dart (rollupCategoryBreakdownsToL1)"
provides:
  - "Softened trend line + below-line gradient + force-above endpoint label"
  - "Donut on-ring % labels (D3) + 分类/成员 dimension toggle + member filter"
  - "GetMemberSpendBreakdownUseCase + MemberSpendBreakdown model + providers"
  - "DonutDimensionState Notifier (dimension + memberFilterDeviceId)"
  - "AnalyticsCategoryPalette.memberSequence / memberColorFor (stable per-deviceId color)"
affects:
  - "lib/features/analytics/presentation/widgets/* (trend chart, donut hero, controls, card)"
tech-stack:
  added: []
  patterns: ["fl_chart isCurved+belowBarData gradient", "deviceId-keyed stable hash color", "Riverpod 3 immutable-record Notifier"]
key-files:
  created:
    - lib/features/analytics/domain/models/member_spend_breakdown.dart
    - lib/application/analytics/get_member_spend_breakdown_use_case.dart
    - lib/features/analytics/presentation/providers/state_donut_dimension.dart
    - lib/features/analytics/presentation/widgets/donut_dimension_member_controls.dart
    - test/unit/application/analytics/get_member_spend_breakdown_use_case_test.dart
    - test/features/analytics/presentation/providers/state_donut_dimension_test.dart
  modified:
    - lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart
    - lib/features/analytics/presentation/widgets/donut_hero.dart
    - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
    - lib/features/analytics/presentation/providers/state_analytics.dart
    - lib/features/analytics/presentation/providers/repository_providers.dart
    - lib/core/theme/analytics_category_palette.dart
    - lib/l10n/app_{ja,zh,en}.arb
decisions:
  - "Cross-dimension member filter is genuinely functional in BOTH dimensions (global narrowing)"
  - "On-ring % suppression threshold = 5% (small slices + long-tail Other stay legend-only)"
  - "Member dimension uses ledgerType:null (cross-ledger total spend per member)"
metrics:
  duration: ~55min
  completed: 2026-06-20
---

# Quick Task 260620-v2m: 统计页趋势图柔化/渐变/终点标签 + 圆环环上% + 成员维度/过滤 Summary

支出趋势折线柔化为曲线并加 below-line 渐变 + 终点正上方标签；分类圆环新增环上 % 标签（D3）、「分类/成员」维度切换、成员过滤下拉与成员切分渲染，全部用 ADR-019 自有配色与 i18n。

## Tasks Completed

| Task | Name | Commit | Key files |
|------|------|--------|-----------|
| 1 | 趋势折线柔化+渐变+终点标签 | `80c1d987` | within_month_cumulative_line_chart.dart (+test) |
| 2 | 成员支出聚合 use case+模型+provider (TDD) | `efdd2ec8` | get_member_spend_breakdown_use_case.dart, member_spend_breakdown.dart, state_analytics.dart, repository_providers.dart (+test) |
| 3 | 圆环维度+成员过滤 状态 Notifier (TDD) | `f8b1f722` | state_donut_dimension.dart (+test) |
| 4 | 环上%标签+成员维度接线+控件+稳定成员色+i18n | `0f18252a` | donut_hero.dart, donut_dimension_member_controls.dart, category_donut_card.dart, analytics_category_palette.dart, 3 ARB |
| 5 | golden 重基线+full-suite 门禁 | `eb74b990` | category_donut_card_golden_test.dart + 21 golden PNG |

## Part 1 — 趋势图

- 本月线 `isCurved: true` + `curveSmoothness: 0.22` + `preventCurveOverShooting: true`；上月参考线同样柔化保持视觉一致。
- 本月线 `belowBarData` 渐变填充：`seriesColor` alpha 0.18 → 0.0（top→bottom），颜色全由传入 `seriesColor`（ADR-019 palette）驱动，**无硬编码 hex**；上月线不填充避免双填充浑浊。
- 本月终点 date+amount 标签**强制锚定终点 marker 正上方**（`currentLabelAbove=true`），仅端点贴顶时 `_positionedLabel` 回退下方；上月参考标签恒取相反侧（`!currentLabelAbove`）。
- 保留 jx2/kll 全部契约：轴/横向网格从0/本地化日期刻度（6/12/18/24）/灰色虚线上月线+图例/carry-forward/整月 X extent/悦己单线（ADR-012 D-E1，结构性 `previousMonth=null`）。
- `labelAbove` 纯函数保留（Test 12 仍测其比较语义，现仅驱动上月相反侧）。

## Part 2 — 圆环

- **环上 % 标签（D3 新增核心）**：donut_hero value 切片 `title: '<pct>%'`（`palette.card` 反白底色, `titlePositionPercentageOffset: 0.5`, radius 22→30 / centerSpace 62→54 让 % 落在环带可读）；分类模式 AND 成员模式都标。
- **小切片/长尾「其他」避让**：`_onRingPctThreshold = 0.05`，<5% 的切片与「其他」走 `_suppressedRingTitle`（named const, 非裸 `title: ''`），仅图例显示 %，防 8–10 类重叠。
- 图例行 name+¥amount+% 与中心「本月支出」+count-up 总额结构保持。
- **成员维度**：`DonutHero.members` 分支按 deviceId 切片（环上各成员 %）+ 成员图例行（emoji + displayName + ¥amount + %）；单设备降级为 1 片（100%），不报错不空白。
- **稳定成员色**：`AnalyticsCategoryPalette.memberSequence`（若叶绿/钢蓝/柚绿/浅蓝/琥珀，避 error 红、留樱粉给悦己）+ `memberColorFor(deviceId)` 用 `deviceId.hashCode.abs() % len` 稳定哈希，**同一 deviceId 跨刷新颜色稳定**。
- **控件** `DonutDimensionMemberControls`：分类/成员 segmented pill（ADR-019 `palette.daily` 选中态）+ 成员过滤 bottomsheet（`activeGroupMembers` 解析 displayName/avatarEmoji，回退 deviceName→截断 deviceId）；单设备仅「所有成员」(+自己)。
- i18n：3 套 ARB 新增 `analyticsDonutDimensionCategory/Member`、`analyticsDonutMemberFilterAll/Label` + `flutter gen-l10n`，生成文件 `git add -f lib/generated/`（gitignored-yet-tracked gotcha）。金额走 NumberFormatter，全文案 S.of(context)。

## Cross-Dimension Member-Filter Semantic（明确记录 — 任务要求）

**所选语义：成员过滤为全局收窄，在两个维度都 genuinely functional。**

- **成员模式 + 过滤某成员**：环只显示该成员单片（100%），图例只该成员行——即「只看某成员的支出」在成员维度的体现。
- **分类模式 + 过滤某成员**：新增 `memberFilteredCategoryBreakdownProvider`（reuse `findByBookIds` 两账本 → Dart 侧 expense + `deviceId==filter` 过滤 → 按 leaf categoryId 聚合 → 喂 DonutHero，由其滚到 L1 + 重算 %）——即「看某成员的分类支出占比」。
- **无过滤**：成员模式用 `memberSpendBreakdown`，分类模式维持原 `monthlyReport.categoryBreakdowns` 路径（byte-stable）。
- 选择此（而非「分类维度下过滤置灰」的省事分支）因为过滤在两维度都有真实意义，且增量仅一个轻量 provider，未超 Task4 预算。

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] 控件行 en locale 溢出 90px**
- **Found during:** Task 5 golden 重基线（en `value — light` 报 RenderFlex overflowed by 90px）
- **Issue:** DonutDimensionMemberControls 顶层 Row 在 en（"Category"/"Member"/"All members" 较长）下子项自然宽度超过卡宽。
- **Fix:** 维度 Wrap 包 `Flexible` + `runSpacing`；成员过滤触发器包 `Flexible` + `ConstrainedBox(maxWidth: 150)`，标签 ellipsize。
- **Files:** donut_dimension_member_controls.dart
- **Commit:** `eb74b990`（随 Task 5；该文件为 Task4 产物，溢出仅在 golden 阶段暴露）

**2. [Rule 2 - test-sync] 注册表测试白名单 + 目标 shape 同步**
- **Found during:** Task 4（`memberSpendBreakdownProvider` 折入 `categoryDonutRefreshTargets` 触发 analytics_card_registry_test 3 失败）
- **Issue:** 新 provider 不在测试的 analytics 家族白名单；(e) 单源 key 断言期望旧 2 元目标列表。
- **Fix:** 白名单加 `MemberSpendBreakdownProvider`（确为 analytics state_* 家族、零 home/*、GUARD-01 合规）；(e) 期望列表补第 3 元。语义未放宽——provider 真属 analytics 家族。
- **Files:** test/widget/features/analytics/presentation/analytics_card_registry_test.dart
- **Commit:** `0f18252a`

**3. [Rule 1 - test-sync] 趋势图 Part1② 上月相反侧逻辑**
- **Found during:** Task 1（新 Part1② widget 测试初次失败）
- **Issue:** 本月强制 above 后，上月旧 `prevAbove = !currentAbove`（比较驱动）在本月<上月时仍会算到 above，与强制 above 的本月撞车。
- **Fix:** 改 `prevAbove = !currentLabelAbove`（相对强制侧），本月恒 above → 上月恒 below；移除已死的 `currentAbove` 变量（保留 `labelAbove` 纯函数 + Test 12）。
- **Files:** within_month_cumulative_line_chart.dart
- **Commit:** `80c1d987`

## Invariants Preserved

- jx2/kll 趋势契约全保留（轴/网格/上月线/carry-forward/整月X/悦己单线 D-E1）。
- 圆环分类模式中心总额/图例行结构、ADR-019 配色不变（新增的是环上 % per D3）。
- 零新 DAO/migration（schema 仍 v21）；零 home/* provider 读写（GUARD-01，home_screen_isolation 绿）。
- 不发明「共同帐户」伪成员（D2）。

## Quality Gates

- `flutter analyze`：**0 issues**（全仓）。
- `flutter test`：**3088/3088 全绿**（含 anti_toxicity / hardcoded_cjk_ui_scan / provider_graph_hygiene / home_screen_isolation 架构测试）。
- Task2 use case 单测 **6/6**；Task3 状态单测 **5/5**。
- analytics golden 在 macOS（darwin）重基线：趋势卡 6 + 圆环卡 8（含环上 % + 3 新成员 master）+ 整页 smoke。

## Known Stubs

None — 成员维度数据全部走真实 provider；无硬编码空值流向 UI。

## Self-Check: PASSED

- 所有新建文件存在（见下方校验）。
- 5 个任务 commit 均在 git log。
