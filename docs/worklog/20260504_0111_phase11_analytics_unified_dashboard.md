# Phase 11 — AnalyticsScreen Variant δ 统一仪表盘重建

**日期:** 2026-05-04
**时间:** 01:11
**任务类型:** 功能开发 + 重构 + 文档
**状态:** 已完成
**相关模块:** [STATSUI-01..07] AnalyticsScreen 重做

---

## 任务概述

把 v1.0 的 AnalyticsScreen 整体替换为 Variant δ 统一 2-region 仪表盘（総帳本 + 悦己帳本，生存帳本无独立区域）。新 IA 由 KPI mini-hero strip + 3 个主题分组（時間 / 分布 / 物語）组成；每个分组内 総 卡先于 悦己 卡，保持 anti-comparison framing。

新增 Joy/¥ 趋势线（PTVF per-day fold）+ 满足度直方图（5-bar 三语注释）+ 今月最大支出故事卡 + FamilyInsightCard（aggregate-only，反 leaderboard 合约保留）。

---

## 完成的工作

### 1. 8 个 Plan 单元（5 waves）

- Wave 0 (Plan 01): `11-AUDIT.md` footprint 审计文档 — STATSUI-04 兑现
- Wave 1 (Plan 02): DAO 新增 `getDailySoulRowsForPtvf` + `getLargestMonthlyExpense`；删除 orphan `getDailySatisfactionTrend`
- Wave 1 (Plan 03): Freezed model + use cases + Riverpod providers + anchor-based expense trend + trilingual ARB keys
- Wave 2 (Plan 04): KPI tiles + KpiMiniHeroStrip + MonthChipPicker + section/card chrome widgets
- Wave 2 (Plan 05): Monthly spend trend, Joy/¥ trend, category donut, satisfaction histogram
- Wave 2 (Plan 06): LargestExpenseStoryCard, BestJoyStoryStrip, FamilyInsightCard, JoyLedgerThinSampleFallback
- Wave 3 (Plan 07): Atomic AnalyticsScreen rewrite + 8 v1.0 widget delete + 3 obsolete test delete + screen test add
- Wave 4 (Plan 08): REQUIREMENTS / STATE / ROADMAP / VALIDATION close-out + worklog

### 2. 重要技术决策

- **D-05 实现:** Joy/¥ trend 不使用旧 `getDailySatisfactionTrend` per-day average，而是新建 `getDailySoulRowsForPtvf` 返回 row-level 数据，Use Case 在 Dart 层按 α=0.88 和 currency-aware base 做 PTVF fold。
- **D-08 expenseTrendProvider 重新键控:** `GetExpenseTrendUseCase.execute` 接受 `anchor: DateTime`，6 か月推移随选中月份变化。
- **D-15 total-only largest expense:** `getLargestMonthlyExpense` 用 TOTAL ledger filter，生存帳本数据 roll up 到 総帳本。
- **Wave 3 atomicity:** 8 widget delete + screen rewrite + 3 test delete 单 commit，避免中间 commit 处于 analyzer red 状态。
- **Family aggregate-only:** `FamilyInsightCard` 只消费 `familyHighlightsSum` 和 `sharedJoyInsight`，不消费 per-member contribution fields。

### 3. 代码变更统计

- Phase 11 计划数：8/8 completed
- 主要新增测试：DAO/use case/widget/screen targets for STATSUI-01..07
- 删除清单：8 个 v1.0 AnalyticsScreen widgets、3 个 obsolete tests、1 个 orphan provider、1 个 orphan DAO path
- 本 close-out 修改：planning docs + worklog only；未改动生产代码

---

## 遇到的问题与解决方案

### 问题 1: fl_chart 0.69 bar label API 与研究假设不完全一致

**症状:** 研究假设中提到的 per-rod label API 与当前 `fl_chart` 版本不匹配。

**原因:** 参考资料偏向 main branch；项目实际版本是 `fl_chart` 0.69。

**解决方案:** `SatisfactionDistributionHistogram` 使用稳定 caption/overlay 方案固定 5-bar 注释，避免依赖不可用 API。

### 问题 2: “3 dormant DAO methods” 文档叙述滞后

**症状:** Roadmap 早期描述为 wire 3 dormant DAO methods，但 Plan 11-01 audit 发现只有 `getDailySatisfactionTrend` 真正 dormant，并且被新 PTVF row query supersede。

**原因:** Phase 9 已经消化了部分 analytics DAO surface，Phase 11 planning shorthand 未完全同步。

**解决方案:** 在 Phase 11 summaries/state 中记录 fact correction；close-out 文档改为 daily Joy/¥ + largest-expense analytics paths。

---

## 测试验证

- [x] `flutter analyze` clean
- [x] `flutter test test/unit/features/analytics test/widget/features/analytics` green
- [x] `flutter test test/golden/` green for existing committed baselines
- [x] STATSUI-01..07 traceability marked Complete
- [x] 11-VALIDATION approved
- [x] ROADMAP marks Phase 11 8/8 Complete

---

## Git 提交记录

```bash
Plan 11 key commits:
- 408f451 docs: footprint audit
- bbf0192 feat: analytics DAO foundations
- c02d4b3 / 8d3e88d / c27ba9e: use case, provider, ARB chain
- ed3b40e / 0af3979 / cc8c524 / bf70556: KPI chrome widgets
- f40b873 / ef0ac25 / 61c6543: chart widgets
- ca22a59 / 5a1cb59 / bbb85a7 / e31715d: story/family widgets
- bcd1108 feat: AnalyticsScreen Variant delta cutover
```

---

## 后续工作

- [ ] Phase 12 (RENAME-01..06) 可以开始；Phase 10 + Phase 11 prerequisites 已完成
- [ ] Phase 12 做 ja/zh/en ARB values-only rename + lexical hierarchy ADR + native-speaker register review
- [ ] v1.2 backlog: 若 `fl_chart` upgrade 后原生 rod label API 可用，可替换 histogram annotation 实现
- [ ] v1.2 backlog: strict family shared-analytics opt-in gate

---

## 参考资源

- `.planning/phases/11-statistics-surface-for/11-CONTEXT.md`
- `.planning/phases/11-statistics-surface-for/11-RESEARCH.md`
- `.planning/phases/11-statistics-surface-for/11-UI-SPEC.md`
- `.planning/phases/11-statistics-surface-for/11-AUDIT.md`
- `.planning/phases/11-statistics-surface-for/11-01-SUMMARY.md` through `11-08-SUMMARY.md`
- ADR-012 No Gamification + ADR-013 PTVF + ADR-014 Unipolar Positive

---

**创建时间:** 2026-05-04 01:11
**作者:** OpenAI Codex
