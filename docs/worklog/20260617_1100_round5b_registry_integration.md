# Round-5 B 注册表集成（Phase 46-07，统计页面填充阶段收官）

**日期:** 2026-06-17
**时间:** 11:00
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [MOD-007] Analytics（统计页面 round-5 B 重设计）

---

## 任务概述

Phase 46 最后一个 plan（Wave 4 集成点）。把已构建但未注册的 round-5 B 卡片接入 `analyticsCardRegistry`，删除旧 Variant-δ 死卡与分区头，外壳改为扁平卡片流，并同步更新注册表/外壳/反毒性测试，使全量测试套件保持绿。

---

## 完成的工作

### 1. 主要变更

- **注册表重排为 round-5 B 扁平 5 卡阵容**（`analytics_card_registry.dart`）：
  - 趋势 `WithinMonthTrendCard` → 圆环 `CategoryDonutCard` → 悦己花在哪 `JoySpendCard` → 小确幸日历 `JoyCalendarCard` → 满足度直方图 `SatisfactionHistogramCard` →（组模式条件卡）`FamilyInsightDataCard`（`isVisible:(ctx)=>ctx.isGroupMode`，D-F1 保留）。
  - 删除 `sectionHeaderKey` 字段及全部用法（扁平列表，零分区头，D-F2）。
  - 移除已废弃的 `dailyVsJoyRefreshTargets`/`perCategorySoloRefreshTargets`/`perCategoryFamilyRefreshTargets` 函数 + 未使用的 `state_ledger_snapshot` import。
- **外壳瘦身**（`analytics_screen.dart`）：移除分区头交错逻辑、`_sectionLabel` 方法、section_header import；body 改为可见卡片的扁平 Column + 卡间 spacer。`FamilyInsight` 的 shadowBooks 注入与注册表派生的 `_refresh` 并集保持不变。
- **删除 4 个死文件**：`best_joy_card.dart`、`kpi_hero_card.dart`、`largest_expense_card.dart`、`analytics_screen_section_header.dart`（`total_six_month_card.dart` + `monthly_spend_trend_bar_chart.dart` 已在 46-01 删除，本次核实缺失）。`daily_vs_joy_card.dart`/`per_category_breakdown_card.dart` 保留（仅去注册，保留各自测试）。
- **三个测试 lockstep 更新**：注册表测试改 6 卡形态 + 新 provider 白名单 + 新卡单源 key 断言；外壳测试断言扁平 5 卡 + 覆写 3 个新卡 provider；anti_toxicity_phase17 新增 3 张新卡作为 ja/zh/en 扫描对象。

### 2. 技术决策

- **46-01 sequencing blocker 实为已解决**：46-01 当时已连同数据层一并删除趋势的呈现消费者（total_six_month_card / monthly_spend_trend_bar_chart / Time 分区头），使数据删除可编译。46-07 仅核实缺失 + 完成集成，标记 blocker resolved。
- **`bestJoyMomentProvider`/`largestMonthlyExpenseProvider` provider 保留**：`bestJoyMomentProvider` 被 HomeHero 消费（home_screen / main_shell_screen / invalidate_transaction_dependents），非死卡独占符号，不在 D-A3 删除名单。
- **分区头 ARB key 孤立但延后**：`analyticsGroupHeaderTime/Distribution/Stories` 现无源消费者，删除需 gen-l10n + force-add gitignored 生成文件，按 plan 延到 Phase 47 ARB sweep。

### 3. 代码变更统计

- 修改/删除 10 个文件（3 lib + 3 test + 4 删除）。
- 净删除 > 500 行（死卡 + 分区头 + 废弃 refreshTargets）。

---

## 遇到的问题与解决方案

### 问题 1: 注册表 doc-comment 残留死卡引用
**症状:** `category_donut_card.dart` doc-comment 含 `[KpiHeroCard]` 悬空 dartdoc 链接（删卡后）。
**解决方案:** 改写为直接描述 `monthlyReportProvider` key 元组（Rule 3）。

### 问题 2: `sectionHeaderKey` grep 残留
**症状:** plan verify 要求 `grep -c sectionHeaderKey` == 0，但 doc-comment 含字面 token。
**解决方案:** 改写注释措辞避开字面 `sectionHeaderKey`。

---

## 测试验证

- [x] `flutter analyze`（全项目）0 issues
- [x] FULL `flutter test` **2971/2971 green**（含 anti_toxicity / hardcoded_cjk_ui_scan / import_guard / provider_graph_hygiene / registry-isolation / home_screen_isolation / ADR-017 grep-ban）
- [x] `grep density|joyPerYen lib/` == 0（单一 Joy 表达保持）
- [x] 死卡文件缺失确认；`sectionHeaderKey` 计数 0

---

## Git 提交记录

```
cc0b8534  feat(46-07): re-order registry to round-5 B flat 5-card lineup; delete dead cards + section header
cfb7b1bf  test(46-07): update registry/screen/anti-toxicity tests for round-5 B lineup
31c3fbd0  docs(46-07): complete round-5 B registry integration plan
```

---

## 后续工作

- [ ] Phase 47（VALIDATION）：孤立分区头 ARB key 清理 + 反毒性扫描扩充 + macOS golden 重基线 + 全量门禁 + UAT。

---

## 参考资源

- `.planning/phases/46-cards/46-07-SUMMARY.md`
- `.planning/phases/46-cards/46-CONTEXT.md`（D-F1/D-F2/D-A3）

---

**创建时间:** 2026-06-17 11:00
**作者:** Claude Opus 4.8
