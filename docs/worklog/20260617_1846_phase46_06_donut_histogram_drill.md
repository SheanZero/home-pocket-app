# Phase 46 Plan 06: 圆环 hero + 直方图原生 label + 只读下钻

**日期:** 2026-06-17
**时间:** 18:46
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [MOD-007] Analytics（统计页面重设计 v1.8）

---

## 任务概述

执行 Phase 46 wave-1 的 46-06 计划：重建 round-5 B 的两张卡（分类圆环 hero #2 + 满足度直方图 #5），并新增只读分类下钻路由。全程反游戏化（ADR-012），桜餅×若葉配色（ADR-019）。

---

## 完成的工作

### 1. 主要变更

- **Task 1 — 直方图原生 label（REDES-02）** `897235cd`
  - 删除 `satisfaction_distribution_histogram.dart` 的 `Stack`+`Align`+`DecoratedBox` "5" 注记 hack
  - 中央値・含未評価 注记迁移到 fl_chart 1.2.0 原生 `BarChartRodData.label`（仅 score-5 rod `show:true`）
  - `_normalize`/`_colorForScore`/`_semanticLabel` 逐字节保留

- **Task 2 — 只读 `CategoryDrillDownScreen`（DRILL-01 UI, D-B1/B2/B3）** `abf355a1`
  - 新 `ConsumerWidget(bookId, l1CategoryId)`，窗口走 `selectedTimeWindowProvider` keepAlive session（D-C1），watch Phase-44 `categoryDrillDownProvider`
  - 顶部 = 小计 + 笔数 + 日均 三个中性描述量（D-B2, ADR-012-safe）
  - 列表只读：给共享 `ListTransactionTile` 加 `readOnly` flag，跳过 Dismissible swipe + tap-编辑；行体抽出 `_buildRow` 共享，列表 tab 逐字节不变
  - ja/zh/en 新增 ARB header/empty/error keys + gen-l10n

- **Task 3 — 圆环 hero 重建（D-B1/D-D2/D-11）** `e000b623`
  - 图例 = 10 行 L1-rollup（`rollupCategoryBreakdownsToL1` 单一来源 D-11），金额降序；每行整行可点（InkWell）→ `Navigator.push` 只读下钻（D-B1 行非扇区）
  - 中心「本月支出」总额 `TweenAnimationBuilder<int>` count-up ~480ms（D-D2 锚点 #1）；`cornerRadius:4`
  - 新增 auto-dispose `analyticsCategoriesMapProvider`（复用 `categoryRepository.findAll`，零新 DAO）

### 2. 技术决策

- 直方图 ValueKey 无法保留（canvas 绘制的 label 无 widget key）→ 测试改断言 rod label text + 仅 score-5 `label.show==true`（Rule 1）
- 只读下钻选「复用 ListTransactionTile + readOnly flag」而非新 tile 变体（最低 surface，视觉逐字节忠实）
- 下钻排序保留 provider 时间倒序（D-B2 允许 amount-desc/time-desc）

### 3. 代码变更统计

- 14 文件（3 新建 + 11 修改），4 task 提交 + 1 chore + 1 docs
- 新 drill screen 329 行

---

## 遇到的问题与解决方案

### 问题 1: analytics_screen_test 断言已删除的 CategorySpendDonutChart
**症状:** 圆环卡重建后不再渲染旧 chart widget，screen test 红
**原因:** 测试断言下移一层
**解决方案:** 改 `find.byType(CategoryDonutCard)`（Rule 1 deviation）

### 问题 2: 直方图原生 label 无法承载 widget ValueKey
**症状:** plan truth 要求 ValueKey 仍可 find
**原因:** 原生 BarChartRodLabel 在 canvas 绘制
**解决方案:** 保留 l10n 字串 + score-5 落点（载荷语义），测试改断言 rod label text

---

## 测试验证

- [x] plan trio 全绿（histogram 7 / donut 4 / drill 6）
- [x] `flutter analyze` 全项目 0 issues
- [x] **FULL `flutter test` 2928/2928 全绿**（含 anti_toxicity / ADR-017 grep-ban / hardcoded_cjk_ui_scan / import_guard / registry）
- [x] grep 验证：histogram 无 Stack、drill 无 Dismissible、donut 含 rollupCategoryBreakdownsToL1 + Navigator

---

## Git 提交记录

```
897235cd feat(46-06): histogram native BarChartRodData.label (REDES-02)
abf355a1 feat(46-06): read-only CategoryDrillDownScreen (DRILL-01 UI, D-B1/B2/B3)
e000b623 feat(46-06): donut hero — tappable L1 legend rows + count-up center (D-B1/D-D2)
62c3fbd3 chore(46-06): reword drill-screen doc comments + drop unused test param
4820d9b3 docs(46-06): complete donut hero + histogram label + read-only drill plan
```

---

## 后续工作

- [ ] 46-07：注册表重排 + isVisible 条件卡（圆环卡 + 下钻屏本计划未注册）；保留 STATE.md 既有 46-07 sequencing blocker
- [ ] Phase 47：macOS golden 从零撰写 + 重基线

---

## 参考资源

- `.planning/phases/46-cards/46-06-PLAN.md` / `46-06-SUMMARY.md`
- `.planning/phases/46-cards/46-CONTEXT.md`（D-11/D-B1/B2/B3/D-D2）
- `.planning/phases/46-cards/46-RESEARCH.md`（fl_chart 1.2.0 原生 label API）

---

**创建时间:** 2026-06-17 18:46
**作者:** Claude Opus 4.8
