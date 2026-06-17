# Phase 46 Plan 02：JOY 侧两条数据路径（per-L1 金额 + per-day 笔数）

**日期:** 2026-06-17
**时间:** 09:54
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [MOD-007] Analytics（悦己卡数据层）

---

## 任务概述

为 round-5 B 的两张悦己卡补齐既有查询不提供的数据路径：(a) per-L1 悦己**金额**（悦己花在哪横向堆叠分段条的段权重，D-C2）；(b) per-day 悦己**笔数**（小确幸日历热力的色深，D-C1）。二者皆为对既有 `findByBookIds(ledgerType: joy)` 原语 + 锁定的 L1 rollup helper 的纯 Dart 变换——零新 DAO、零迁移，schema 维持 v21。

---

## 完成的工作

### 1. 主要变更
- `GetJoyCategoryAmountsUseCase` + `JoyCategoryAmount`（domain-pure 值类）：单次 `findByBookIds(joy)` → expense-only + manualOnly 过滤 → 经同源 `l1AncestorOf`/`l1RollupFromTransactions`（D-11，无二次 rollup）按 L1 汇总 → 金额降序（D-C2 段序）。
- `GetPerDayJoyCountsUseCase` + `PerDayJoyCount`（domain-pure 值类）：单次 `findByBookIds(joy)` → expense-only + manualOnly → 按本地日历日 group-by **计数**（笔数，非求和——Pitfall 3）。
- `joyCategoryAmounts`（窗口规范化 key）+ `perDayJoyCounts`（月锚 key）两个 `@riverpod` auto-dispose family 接入 `state_analytics.dart`，与 46-01 趋势 provider 并存；两个 use-case provider 接入 `repository_providers.dart`。零 home/*（GUARD-01）。

### 2. 技术决策
- per-day 笔数取 Dart group-over `findByBookIds(joy)` 而非新建 SQL ledger+COUNT DAO 变体：零 DAO 表面、笔数粒度天然可得、且不触 DRILL-01 scope 锁（per-day-joy 是 ambient 日历纹理，区别于唯一允许的分类下钻路径——RESEARCH Flag 2 裁定）。
- `JoyCategoryAmount` 用专用语义类型而非复用 `L1CategoryRollup`（后者多带无用的 transactionCount）。

### 3. 代码变更统计
- 新增 6 文件（2 model + 2 use case + 2 test），修改 2 provider 文件（+ 2 生成 .g.dart）。

---

## 测试验证

- [x] 单元测试通过（11/11：per-L1 rollup / joy-only / expense-only / subset-of-L1 invariant / 空窗 / book-set-faithful / count-not-sum / local-day-correct）
- [x] `flutter analyze` 0 issues（触及目录）
- [x] Pitfall-3 grep 守卫通过（use case 不调用 daily-totals SQL 聚合）
- [x] 结构锁测试保绿（analytics_card_registry / home_screen_isolation）
- [x] build_runner clean

---

## Git 提交记录

```
1dfdbc31 feat(46-02): per-L1 joy-amount use case + JoyCategoryAmount model
c8ef3cd3 feat(46-02): per-day joy COUNT use case + model; wire both joy providers
```

---

## 后续工作

- [ ] 46-04 / 46-05 卡片层消费 `joyCategoryAmountsProvider` + `perDayJoyCountsProvider`，届时 JOY-01/JOY-02 端到端落地。

---

**创建时间:** 2026-06-17 09:54
**作者:** Claude Opus 4.8
