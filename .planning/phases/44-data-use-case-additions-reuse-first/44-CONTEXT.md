# Phase 44: 数据与用例补全 (Data / Use-Case Additions — reuse-first) - Context

**Gathered:** 2026-06-16
**Status:** Ready for planning

<domain>
## Phase Boundary

仅补齐 Phase 43 选定方向（**round-5 B**，M2 衍生）展示层之下**真正缺**的数据/用例。**复用优先、纯展示层重建**：Drift schema 保持 **v21 不变**，无迁移，无 budget 表，仅支出侧（无收入/无 savings-rate）。

本阶段交付三件事（对应 OVW-01 / TREND-01 / DRILL-01）：

1. **支出总览数据** — 确认为对 `monthlyReportProvider` 的纯展示变换，**零新增** use case/DAO/迁移。
2. **支出趋势数据** — `GetExpenseTrendUseCase` 扩展出 per-ledger（总/日常/悦己）6 月滚动序列。
3. **分类下钻数据** — 至多**一条新只读路径**（`CategoryDrillDown` + `GetCategoryDrillDownUseCase`），走既有 `findByBookIds` 原语。

**不在本阶段：** 任何 UI 外壳/卡片（Phase 45/46）、悦己情感卡的呈现（Phase 46）、i18n/反毒性/golden（Phase 47）、ADR-012 `## Update` 补正本体（Phase 45 前单独做）。

</domain>

<decisions>
## Implementation Decisions

### 分类下钻 (DRILL-01)
- **D-01:** 下钻形态 = **analytics 内轻量下钻视图**（bottom sheet 或 pushed 页，具体壳由 Phase 45/46 定）。尊重当前 analytics 时间窗（week/month/quarter/year/custom）；provider **auto-dispose**（离开释放、重入重算）。**不**跳转既有「列表」tab —— 其 `GetListTransactionsUseCase` 是「年月/单日」日期模型，无法干净映射 analytics 的任意窗口。
- **D-02:** 下钻深度 = 点 **L1 分类** → **平铺该 L1（含其全部 L2 子类）在当前窗口内的全部交易**。不做 L1→L2 中间 breakdown 层。
- **D-03:** 下钻内容 = 顶部一个**中性描述性小结**（该分类小计 + 笔数；可选日均）+ 交易列表（复用 `ListTransactionTile`）。小结严格 ADR-012-safe：无目标、无跨期、无排名、无评判措辞。
- **D-04:** 数据路径 = **一条新 thin 只读路径**（DRILL-01 允许「至多一条新只读路径」）：`CategoryDrillDown` Freezed 模型（`transactions` + `subtotal` + `count`，可选 `avgPerDay`）+ `GetCategoryDrillDownUseCase`，走既有 `TransactionRepository.findByBookIds(bookIds, startDate, endDate, …)` 原语。**不**复用 v1.4 `GetListTransactionsUseCase`（窗口模型不契合 + 不带聚合）。**TDD 覆盖**（先写 use case 测试）。
- **D-05:** L1 过滤机制 = **Dart 侧按 category 的 L1 父类过滤**（取窗口内交易后 `.where`，沿用 v1.4 多分类 Dart-side 过滤先例）。**零新增** DAO/SQL 方法。小计/笔数复用 donut 卡已算的 **L1 rollup**（同一来源，避免二次聚合不一致）。
- **D-06:** 索引结论 = `(book_id, category_id, timestamp)` 复合索引 **N/A / 不新增** —— 因为无 SQL 侧分类过滤；下钻窗口取数走既有 `findByBookIds`（`(book_id, timestamp)` 范围）。planner 仍须核查**窗口取数路径**已有合适索引（不是新增分类索引）。

### 支出趋势 (TREND-01)
- **D-07:** **三 tab 全上** = 总支出 / 日常 / 悦己（与 Phase 43 已批准的选定方向一致）。
- **D-08:** 实现 = **扩展 `MonthlyTrend` 增加 `dailyTotal` + `joyTotal` 字段**；每月一次取齐三值（用 DAO 既有 `getLedgerTotals` 原语，或 repo 层补一条 per-ledger 月度总计；**无 Drift 迁移**）。单一 trend provider family 同时驱动三 tab，避免 3× 查询 / 3× family。
- **D-09:** 悦己趋势跨期约束 = 悦己 tab 为中性 6 月滚动线，**无「本月 vs 上月」delta callout**。Phase 44 数据层**不计算、不暴露任何 joy 跨期 delta**。「本月 vs 上月」highlight **仅**在 总支出/日常 两个支出侧 tab，且属 Phase 46 呈现 framing（6 月序列已含本月/上月，非新数据）。该支出侧例外是 ADR-012 §4 的**记录在案**例外，须在 **Phase 45 前**由 ADR-012 `## Update` 补正 —— **不在本阶段改 ADR-012 本体**。

### 支出总览 (OVW-01) — 锁定纯复用
- **D-10:** **零新增数据工作**。总支出 + 日常/悦己拆分 + Top 分类全部来自 `MonthlyReport`（`totalExpenses`/`dailyTotal`/`joyTotal`/`categoryBreakdowns`），是对 `monthlyReportProvider` 的**纯展示变换**。
- **D-11:** donut 的「10 个 level-1 分类金额降序」需把 **L2 粒度**的 `categoryBreakdowns`（`getCategoryTotals` 按存储的 `category_id`=L2 leaf 分组）按 **L1 父类 rollup + 降序**。这是纯展示变换（仍零新 use case/DAO/迁移）。**L1 rollup 能力同时被 donut 卡与下钻小结复用** —— 放在一个共享 pure 函数/extension（位置由 planner 定）。

### 通用约束（工程铁律，照做）
- **D-12:** 所有新 provider 的 family key 必须先经 `DateBoundaries`/`TimeWindow` 规范化再进 key tuple（避免 microsecond-exact provider rebuild storm）。
- **D-13:** Drift schema 保持 **v21** 不变；无迁移；无 budget 表；仅支出侧（无收入/savings-rate）。
- **D-14:** analytics 总览/趋势/下钻 provider 保持 **auto-dispose**；**不**读取/不失效任何 `home/*` provider，不与 Home 共享任何 provider（GUARD-01 / HomeHero 隔离，结构保证在 Phase 45）。

### Claude's Discretion
- 下钻壳的具体形态（bottom sheet vs pushed route）—— Phase 45/46 presentation 决定；本阶段只定**数据层契约**。
- `CategoryDrillDown` 是否含 `avgPerDay`、交易排序（按金额 or 时间）—— planner 定。
- L1 rollup 的具体放置（pure 函数 / extension / provider）—— planner 定。
- per-ledger 月度数据补在 repo（如新 `getMonthlyLedgerTotals`）还是 use case 内循环 `getLedgerTotals` —— planner 定（两者均无迁移）。

### Research flags（给 gsd-phase-researcher 的轻核查）
- **小确幸日历 per-day 悦己数据归属：** 选定设计的「小确幸日历」热力需 per-day **悦己（joy-ledger）**纹理；现有 `getDailyTotals` **无 ledger 过滤**（只按 `type='expense'` + 可选 `entry_source`）。researcher 核实：现有 joy 数据是否已覆盖 per-day 悦己呈现，或需一条 thin per-day-joy 取数。该卡是 **Phase 46 surface**，但若需新数据须厘清归属（Phase 44 数据层 vs Phase 46）。
- **窗口取数索引核查（D-06）：** 确认 `findByBookIds` 的 `(book_id, timestamp)` 范围查询已有索引（下钻 + 总览 + 趋势均依赖）；**不**新增 `(book_id, category_id, timestamp)`。
- **收入录入可靠性已结论：** 无录入路径、`totalIncome`==0、总览仅支出侧 —— 已锁定（INCOME-V2-01），无需再核。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 里程碑与需求（锁定范围）
- `.planning/ROADMAP.md` — Phase 44 定义（OVW-01/TREND-01/DRILL-01 success criteria）+ v1.8 里程碑约束（Phases 43-47）
- `.planning/REQUIREMENTS.md` — OVW/TREND/DRILL 全文 + **Out of Scope** 锁定（无收入/无结余率、无预算迁移、固定布局、Sankey 仅方向探索、滚动带延后）

### Phase 43 选定方向 + GATE-04 决策（本阶段数据需求的来源）
- `.planning/phases/43-html-design-gate-no-production-code/GATE-03-direction-selection.md` — 选定 = round-5 B（M2 衍生）；用户批准
- `.planning/phases/43-html-design-gate-no-production-code/mocks/selected/README.md` — 选定方向一句话描述 + 悦己子类 ⊆ 主 L1 分类的数据修正
- `.planning/phases/43-html-design-gate-no-production-code/GATE-04-adr-go-no-go.md` — JOY-04 持久化 = no-go（无新 ADR、保持 no-Drift）；支出侧跨期 = 记录在案的 ADR-012 §4 例外（Phase 45 前以 `## Update` 补正）
- `.planning/phases/43-html-design-gate-no-production-code/GATE-04-flchart-affordance-verification.md` — 逐图 fl_chart 1.2.0 校验（donut/histogram/trend 原生 ✅；悦己堆叠条 ⚠ + 小确幸日历 ❌ 为 Phase 46 自定义 widget 风险）
- `.planning/phases/43-html-design-gate-no-production-code/GATE-01-current-impl-deep-map.md` — 17 widget 清单 + `MonthlyReport` 已算字段 + 13/15 用例可复用 + 结构锁点

### ADR 约束（红线）
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — 反游戏化恒久契约（§4 跨期约束；下钻小结/悦己趋势的对照基准）
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` — §3 HomeHero 独占 target ring（analytics 侧不得复制）；§5 ambient-vs-discrete 线
- `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` — 生存/灵魂 grep-ban（新代码命名）

### 现状实现（本阶段直接动到/复用的源码）
- `lib/features/analytics/domain/models/expense_trend.dart` — `MonthlyTrend`（现仅 `totalExpenses`/`totalIncome`，**D-08 加 daily/joy**）+ `ExpenseTrendData`
- `lib/application/analytics/get_expense_trend_use_case.dart` — 现 6 月循环逐月取 `getMonthlyTotals`；扩展点
- `lib/features/analytics/domain/models/monthly_report.dart` — `MonthlyReport` + `CategoryBreakdown`（OVW-01 来源；L2 粒度）
- `lib/data/daos/analytics_dao.dart` — `getCategoryTotals`（L2 leaf 分组）/ `getLedgerTotals`（per-ledger，D-08 原语）/ `getMonthlyTotals`（无 ledger 拆分）
- `lib/application/list/get_list_transactions_use_case.dart` — v1.4 list 路径（**不复用**，D-04；仅作对照）
- `lib/features/accounting/domain/repositories/transaction_repository.dart` — `findByBookIds(bookIds, ledgerType, categoryId, startDate, endDate, sort…)` —— 下钻**复用此原语**
- `lib/features/list/presentation/widgets/`（`list_transaction_tile.dart`）— 下钻列表复用的 tile
- `lib/shared/utils/date_boundaries.dart` — 窗口规范化（D-12）

### 结构锁点（不可破；测试断言）
- `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` — HomeHero 隔离（GUARD-01）
- `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` + `anti_toxicity_phase17_test.dart` — 反毒性禁词扫描（下钻小结措辞对照）

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`MonthlyReport`（`GetMonthlyReportUseCase`）已算全部总览字段**：`totalExpenses` / `dailyTotal` / `joyTotal` / `categoryBreakdowns`（含 amount/percentage/txCount/icon/color）/ `dailyExpenses`。OVW-01 = 纯展示变换（D-10）。
- **`TransactionRepository.findByBookIds`** 接收任意 `(startDate, endDate)` + `categoryId`（单个）+ `ledgerType` + 排序 —— 是下钻的**真正可复用原语**（D-04）。
- **`AnalyticsDao.getLedgerTotals`** 已给单窗口 per-ledger 总计 —— per-ledger 趋势的原语（D-08）。
- **`ListTransactionTile`**（v1.4）— 下钻列表行直接复用（D-03）。
- **悦己 surface 用例已存在（Phase 46 复用，非本阶段工作）：** `GetPerCategoryJoyBreakdownUseCase`（「悦己花在哪」堆叠条）、`GetSatisfactionDistributionUseCase`（满足度直方图）、`GetBestJoyMomentUseCase`（记忆瞬间）。本阶段无需为它们补数据。

### Established Patterns
- 每卡/每查询 = `ConsumerWidget` watch 唯一 provider family `(bookId, startDate, endDate, joyMetricVariant)`；本地 `.when(data/loading/error)`。
- family key 先经 `DateBoundaries`/`TimeWindow` 规范化再进 tuple（D-12）。
- analytics provider 全 auto-dispose；与 `home/*` 零共享（D-14 / GUARD-01）。
- 多分类过滤的 Dart-side 先例（v1.4 `listTransactionsProvider` 用 `filter.categoryIds.contains`）—— D-05 L1 父类过滤沿用。

### Integration Points
- 新 `GetCategoryDrillDownUseCase` 经 `repository_providers` 注入 `TransactionRepository`；新 drill provider family `(bookIds, startDate, endDate, l1CategoryId)`，auto-dispose。
- 趋势扩展点在 `GetExpenseTrendUseCase` + `MonthlyTrend`；现有 `expenseTrend` provider 改吃扩展后的模型（一个 family 驱动三 tab）。
- donut 的 L1 rollup（D-11）为共享 pure 变换，donut 卡 + 下钻小结同源。
- 下钻壳接入点（路由 vs sheet）= Phase 45/46；本阶段只交付数据契约 + use case。

</code_context>

<specifics>
## Specific Ideas

- **选定方向（round-5 B）一句话：** 支出趋势置顶（纯 CSS pill tabs：总/日常/悦己）→ 加粗支出分类圆环 hero（中心「本月支出 ¥…」，10 个 L1 分类金额降序，无悦己合计拆分）→「悦己花在哪」横向堆叠分段条 → 小确幸日历热力 → 满足度分布直方图。**无悦己占比 · 无「值得卡」headline · 无记忆故事。**
- **下钻气质：** analytics 内轻量、克制、描述性 —— 让用户「看清这个分类花在哪」，不打分、不较劲。
- **跨期边界（关键）：** 唯一跨期 = 支出侧趋势（总/日常 tab）的本月vs上月；悦己侧（趋势 tab + 所有悦己元素）**zero 跨期 / zero 目标 / zero 排名**。

</specifics>

<deferred>
## Deferred Ideas

以下均为**里程碑级已锁定的范围外项**（记录以防丢失，非本次讨论新增的范围蔓延）：

- **收入录入 / 真实结余率** — 无录入路径，`totalIncome`==0；→ INCOME-V2-01
- **预算 vs 实际** — 需 `budgets` 表 + v21→v22 迁移；→ ANALYTICS-V2-03
- **可定制 / 可重排仪表盘** — v1.8 固定布局；→ ANALYTICS-V2-02
- **Sankey 收入→支出→结余流向图** — 无收入侧数据 + 无 native fl_chart 支持；→ ANALYTICS-V2-01
- **"about typical" 中性滚动带** — 贴近 ADR-012 §4 边界，需新 ADR；→ ANALYTICS-V2-04
- **分币种 analytics 小计** — 携带自 v1.7；→ CUR-V2-02
- **JOY-04 用户自撰反思文本持久化** — 本里程碑静态只读（GATE-04 no-go）；未来若做需新 ADR（加密/隐私）+ non-Drift 存储

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 44-data-use-case-additions-reuse-first*
*Context gathered: 2026-06-16*
