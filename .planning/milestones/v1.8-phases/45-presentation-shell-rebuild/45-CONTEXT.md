# Phase 45: 展示外壳重建 (Presentation Shell Rebuild) - Context

**Gathered:** 2026-06-17
**Status:** Ready for planning

<domain>
## Phase Boundary

纯展示层**结构重建**——把 739 行的 `analytics_screen.dart` 单体（ROADMAP 写 592，已漂移）拆成：
1. **瘦外壳** = AppBar（title + `TimeWindowChip` + `JoyMetricVariantChip`）+ 滚动容器 + **卡片注册表驱动**的卡片列表。
2. **`widgets/cards/` 卡片体系** — 现内联的 7 张 `_*Card` 各抽成独立文件，每卡 < 400 LOC、是 `ConsumerWidget`、watch 自己唯一 provider family、本地 `.when(data/loading/error)`（绝大部分现状已满足，差在「内联在 shell 文件里」）。
3. **数据驱动 `_refresh()`** — 由 analytics 卡片注册表派生失效并集，替换现手写 ~108 行手列 13 个 provider 的 `_refresh()`，使 HomeHero 隔离**由构造保证**（注册表结构上不可能含 `home/*` provider）。

**本阶段定调（A1）：纯结构重构、行为保持。** 保持现 Variant-δ 7 卡 + 现 IA（Time / Distribution / Stories 分区）不变，页面观感不变 → golden 保绿、`home_screen_isolation_test` 同断言过、Phase 45 diff ≈ 纯机械抽取（易评易验）。**round-5 B 的 IA 重排 / 卡片增删全部留给 Phase 46**（届时只是注册表重排 + 换条目）；所有可见变化集中在 46，golden 重基线集中在 47。

**不在本阶段：** 任何新卡片内容 / round-5 B 重排 / 图表打磨 / 动效（Phase 46）；数据/用例（Phase 44 已完成）；i18n / 反毒性扫描 / golden 重基线 / 全量门禁 / UAT（Phase 47）；下钻宿主的真实落地（Phase 46，见 D-C1/D-C2）。

**唯一允许的非纯抽取增量：** ADR-012 的 append-only `## Update` 补正（见 D-D1）——doc-only，零功能耦合。

</domain>

<decisions>
## Implementation Decisions

### A. 外壳范围边界
- **D-A1:** Phase 45 = **纯结构重构、行为保持**。保留现 7 卡 + 现 IA（Time/Distribution/Stories 分区头）不变，仅把内联卡抽到 `presentation/widgets/cards/` + 建注册表 + `_refresh()` 改为注册表派生。页面观感不变 → **golden 保绿**、isolation test 同断言过、diff = 纯机械抽取。round-5 B 的重排（趋势置顶 + donut hero）、卡片增删（删 KPI mini-hero / 值得 headline / 记忆故事；加 悦己花在哪 / 小确幸日历）**全部落在 Phase 46**——届时仅是注册表 list 重排 + 换条目，不再触 shell 机制。
- **Discretion:** scroll container 具体选型（`SingleChildScrollView`+`Column` 由注册表 build vs `ListView.builder` 驱动）由 planner 定；注意条件卡（见 D-B3）使纯扁平 builder 略复杂，行为保持优先。

### B. 卡片注册表契约（本阶段核心交付）
- **D-B1:** **一个 typed 注册表是布局与 refresh 的单一来源**。注册表（如 `List<AnalyticsCard>` 抽象基类，或 `List<AnalyticsCardSpec>` 数据条目——abstract-base vs spec-list 由 planner 定）**同时驱动**：(a) shell 的卡片列表渲染顺序；(b) `_refresh()` 的失效并集。两者不得各走各的。
- **D-B2:** 每卡声明自己的 **`refreshTargets(ctx)`**（返回该卡 watch 的那组 keyed provider family）；`_refresh()` = `registry.where(isVisible).expand((c) => c.refreshTargets(ctx))` 后逐个 `ref.invalidate`。`ctx` 至少含 `(bookId, startDate, endDate, joyMetricVariant, currencyCode, trendAnchor, isGroupMode)`——与各卡 `build` watch 时用的 keys 同源，避免 build 与 invalidation 漂移。
- **D-B3:** **「由构造保证 home 隔离」升为显式 enforce**：新增一条**单测**断言 `_refresh()` / 注册表派生的失效并集 **⊆ analytics provider 集合、含 0 个 `home/*` provider**。把现状「隐含、靠 `home_screen_isolation_test` 间接断言」升级为直接断言。现有 `home_screen_isolation_test` 仍须保绿（GUARD-01）。
- **D-B4:** **条件卡用注册表 `isVisible(ctx)` 谓词**：仅 group-mode 的 `_FamilyCard` + 第二张 `PerCategoryBreakdownCard(scope: family)` 带 `isVisible: (ctx) => ctx.isGroupMode`；shell 只 build 可见卡，`_refresh()` 也只失效可见卡的 provider（不浪费失效隐藏卡、solo 模式不再 invalidate family 变体）。
- **D-B5:** **依赖异步数据的自隐留在卡内**：`_SatisfactionHistogramOrFallback` 的 `report.totalJoyTx < 5` 自隐（`SizedBox.shrink`）依赖 provider 已取数，`ctx` 拿不到——保持卡内 `.when` 内部判断；`refreshTargets` 照常包含其 provider（`happinessReport` + `satisfactionDistribution`）。

### C. 下钻宿主落点（结转 Phase 44 D-01）
- **D-C1:** 下钻宿主形态 = **pushed route (GoRouter)**（独立页，非 bottom sheet）。现在锁定形态，**实现全部在 Phase 46**。
- **D-C2:** 在 A1（行为保持）下，下钻宿主**整体入 Phase 46，Phase 45 零预留**——下钻是新行为（donut 分类 tap 触发），与 A1 冲突；Phase 45 什么都不建，注册表契约天然容得下「下一张会 push route 的卡」。保持 45 diff 纯净 + golden 绿。
- **Phase 46 research flag（pushed route 落地须知）：** 时间窗是 keepAlive session state（`selectedTimeWindowProvider`），pushed route 的 ConsumerWidget 可直接 watch，**无需 route param 穿线**；route 只需传 `l1CategoryId`。drill provider family `(bookIds, startDate, endDate, l1CategoryId)` **保持 auto-dispose**（Phase 44 D-01/D-14）。GoRouter route 注册随 Phase 46 落地（会触 router config）。

### D. ADR-012 补正时机
- **D-D1:** **折进 Phase 45**——把支出侧「本月vs上月」趋势作为 **ADR-012 §4 跨期约束的记录在案例外**，以 **append-only `## Update YYYY-MM-DD`** 段落补正 `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md`（**悦己侧跨期仍绝对禁止**）。文档原定「Phase 45 前」做、至今未做（STATE.md 行 192 确认 Phase 43 punt）；A1 下 Phase 45 并不渲染该 callout，故无功能依赖——但此为 append-only、近乎零成本、兑现已记录义务、把红线提前上档。ADR 状态 append-only（`.claude/rules/arch.md`：✅已接受后只能 `## Update` 追加，不改原决策正文）。

### Claude's Discretion
- 注册表抽象具体形态：abstract `AnalyticsCard` 基类（build+refreshTargets+isVisible 内聚一类）vs `List<AnalyticsCardSpec>`（builder + refreshTargets + isVisible 闭包，卡保持 dumb ConsumerWidget）——由 planner 定（两者都给到 D-B1/B2/B3 的并集与结构断言）。
- scroll container 选型（D-A1）、卡片文件拆分粒度/命名、`AnalyticsCardContext` 字段集的精确形状——planner 定。
- `_AnalyticsDataCard`（标题/caption 壳）是留在 shell 还是抽到 `widgets/cards/` 作共享卡壳——planner 定。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 里程碑与需求（锁定范围）
- `.planning/ROADMAP.md` — Phase 45 定义（REDES-01 / GUARD-01 success criteria）+ v1.8 里程碑约束（Phases 43-47）
- `.planning/REQUIREMENTS.md` — REDES-01 / GUARD-01 全文 + **Out of Scope** 锁定（无收入/无结余率、无预算迁移、固定布局、Sankey 仅方向探索）；REDES-02/03 + GUARD-02 是 Phase 46、GUARD-03/04/05 是 Phase 47（本阶段不做）

### Phase 43/44 上游决策（本阶段契约的来源）
- `.planning/phases/44-data-use-case-additions-reuse-first/44-CONTEXT.md` — 数据契约已锁（下钻 thin 只读路径 auto-dispose、趋势 per-ledger 三 tab、总览纯变换、family key 经 `DateBoundaries`/`TimeWindow` 规范化）；**D-01 把下钻宿主形态明确留给 Phase 45/46**（本阶段 D-C1/C2 关闭）
- `.planning/phases/43-html-design-gate-no-production-code/GATE-03-direction-selection.md` — 选定 = round-5 B（M2 衍生，用户批准）；Phase 46 IA 重排的依据
- `.planning/phases/43-html-design-gate-no-production-code/GATE-04-adr-go-no-go.md` — 支出侧跨期 = 记录在案的 ADR-012 §4 例外（**本阶段 D-D1 落地 `## Update` 补正**）；JOY-04 持久化 = no-go
- `.planning/phases/43-html-design-gate-no-production-code/GATE-01-current-impl-deep-map.md` — 17 widget 清单 + 结构锁点（外壳重建的对照地图）

### ADR 约束（红线）
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — 反游戏化恒久契约；**本阶段须 append `## Update`**（D-D1）记录支出侧 本月vs上月 为 §4 例外，悦己侧跨期仍绝对禁止。状态 append-only（`.claude/rules/arch.md`）
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` — §3 HomeHero 独占 target ring（analytics 侧不得复制）；§5 ambient-vs-discrete 线
- `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` — 生存/灵魂 grep-ban（新代码命名 + cards/ 文件命名）

### 现状实现（本阶段直接重建/拆分的源码）
- `lib/features/analytics/presentation/screens/analytics_screen.dart` — **739 LOC 单体**（待瘦身）。现状结构：`AnalyticsScreen`（shell + `_refresh()`）+ 内联私有卡 `_KpiHero` / `_TotalSixMonthCard` / `_CategoryDonutCard` / `_SatisfactionHistogramOrFallback` / `_LargestExpenseCard` / `_BestJoyCard` / `_FamilyCard` + 共享卡壳 `_AnalyticsDataCard`
- `lib/features/analytics/presentation/widgets/` — 17 个现成 widget（cards/ 抽取后引用它们）+ `time_window_chip` / `joy_metric_variant_chip` / `analytics_screen_section_header` / `analytics_card_error_state`
- `lib/features/analytics/presentation/providers/` — `state_analytics`（`monthlyReportProvider` / `expenseTrendProvider` / `earliestTransactionMonthProvider` / `largestMonthlyExpenseProvider` 等）/ `state_happiness`（`happinessReportProvider` / `satisfactionDistributionProvider` / `bestJoyMomentProvider` / `perCategoryJoyBreakdownProvider`(+Family) / `dailyVsJoySnapshotProvider`(+Family) / `familyHappinessProvider`）/ `state_joy_metric_variant` / `state_ledger_snapshot` / `state_time_window` / `repository_providers`
- `lib/shared/utils/date_boundaries.dart` — 窗口规范化（family key 不漂移）

### 结构锁点（不可破；测试断言）
- `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` — HomeHero 隔离（GUARD-01）。现断言：HomeScreen 不 import `selectedTimeWindowProvider` / `state_ledger_snapshot`；AnalyticsScreen JoyMetricVariant 切换不动 HomeHero（Phase 17 SC-4）。**本阶段须保绿，并新增 D-B3 的注册表-targets 断言**
- `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` + `anti_toxicity_phase17_test.dart` — 反毒性禁词扫描（结构重构不得引入新文案；新文案/新卡的扫描扩充是 Phase 46/47）

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **7 张内联私有卡已基本符合目标契约**：各是 `ConsumerWidget`、watch 自己唯一 provider family `(bookId, startDate, endDate, joyMetricVariant[, currencyCode])`、本地 `.when(data/loading/error)`，error 分支带 `AnalyticsCardErrorState` + per-provider `ref.invalidate` retry。Phase 45 的真实工作 = **抽文件 + 建注册表 + refresh 派生**，而非重写卡逻辑。
- **`_AnalyticsDataCard`**（title/caption/child 卡壳）可抽成 `widgets/cards/` 共享卡壳，供多卡复用。
- **`AnalyticsCardErrorState`** 已是独立 widget——per-card error retry 的 `refreshTargets` 与 D-B2 的注册表 refreshTargets 同源（同一组 provider），planner 可让 retry 复用 card 的 `refreshTargets` 避免二处声明。

### Established Patterns
- 每卡 = `ConsumerWidget` watch 唯一 provider family；本地 `.when`。family key 先经 `DateBoundaries`/`TimeWindow` 规范化（避免 microsecond-exact rebuild storm）。
- analytics provider 全 **auto-dispose**；与 `home/*` 零共享（GUARD-01 / D-B3）。
- 现 `_refresh()` 已显式标注「MUST NOT invalidate any home/* provider」（行 222）——D-B3 把该注释级约束升为结构+测试级保证。

### Integration Points
- 注册表新建于 `presentation/`（位置由 planner 定，建议 `widgets/cards/` 或 `presentation/analytics_card_registry.dart`）；shell `build` 与 `_refresh()` 都消费它。
- 各 `cards/*.dart` 仅 import analytics providers + analytics widgets——**这是「结构上不可能含 home/*」的物理来源**（D-B3 测试为其背书）。
- group-mode 条件分支（`isGroupMode` + `shadowBooksProvider`）现散在 shell；D-B4 后由注册表 `isVisible(ctx)` 表达。

</code_context>

<specifics>
## Specific Ideas

- **「卡就是契约」**：理想下每卡是单一来源——它 watch 的 provider 组 == 它 `refreshTargets(ctx)` 返回的组 == error retry 失效的组。planner 应让这三者同源（一个 getter/方法），杜绝 build 与 refresh 漂移。
- **45 = 不可见的结构重构**：用户明确要 Phase 45 页面观感不变（golden 绿）。所有可见变化（round-5 B IA + 新卡 + 图表打磨 + 动效）压到 Phase 46，golden 重基线压到 Phase 47。这是「shell-before-cards」的纯净读法：45 立机制、46 填内容、47 验视觉。
- **下钻选 pushed route 而非 sheet**（用户定，覆盖我对 sheet 的推荐）：要独立页的屏幕空间 + back 栈承载分类下钻交易列表。

</specifics>

<deferred>
## Deferred Ideas

以下均为里程碑级已锁定的范围外项 / 后续阶段项（记录以防丢失，非本次讨论新增的范围蔓延）：

- **round-5 B IA 重排 + 卡片增删 + 图表打磨（fl_chart 1.2.0 native label / donut cornerRadius）+ 暖色动效** — Phase 46（REDES-02/03、GUARD-02、JOY-01..04、OVW-02）
- **下钻宿主真实落地（pushed route + GoRouter 注册 + donut tap 入口）** — Phase 46（本阶段仅锁形态 D-C1）
- **i18n ARB parity / 反毒性禁词扫描扩充 / macOS golden 从零撰写+重基线 / 全量门禁 / 真机 UAT** — Phase 47（GUARD-03/04/05）
- **收入录入 / 真实结余率**（INCOME-V2-01）、**预算 vs 实际**（ANALYTICS-V2-03）、**可定制仪表盘**（ANALYTICS-V2-02）、**Sankey 流向图**（ANALYTICS-V2-01）、**"about typical" 中性滚动带**（ANALYTICS-V2-04）、**分币种 analytics 小计**（CUR-V2-02）、**JOY-04 自撰反思持久化**（需新 ADR + non-Drift）、**fl_chart 1.x→2.x 升级**（TOOL-V2-01）

None — discussion stayed within phase scope（以上均为里程碑级已锁定的范围外项或后续阶段项）。

</deferred>

---

*Phase: 45-presentation-shell-rebuild*
*Context gathered: 2026-06-17*
