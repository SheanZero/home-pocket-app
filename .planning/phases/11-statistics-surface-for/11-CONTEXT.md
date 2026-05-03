# Phase 11: Statistics Surface for 悦己账本 - Context

**Gathered:** 2026-05-03
**Status:** Ready for `/gsd-ui-phase 11` (UI-SPEC.md must precede plan)

<domain>
## Phase Boundary

Phase 11 **完整重做 `AnalyticsScreen`**：删除现有 8 个 widget，重新设计统计页 IA，使其围绕 Phase 9 happiness 合约组织——「悦己账本」为一等视图，同时容纳「生存账本」与「跨账本总览」能力的等价重建。

**Phase 11 scope expanded during discussion**（原本只是 wire 3 dormant DAO methods + 子区）。用户明确要求把 AnalyticsScreen 整体重构提到本期，与 Phase 10 重建 HomePage hero 同级。Complexity 由 M → M-H（plan 量级预计 ~13，与 Phase 10 持平）。

**关键事实修正：** ROADMAP.md / PROJECT.md 写的「3 个休眠 DAO 方法」在 Phase 9 完成后只剩 1 个真休眠：
- `getSoulSatisfactionOverview`：✅ 已通过 `AnalyticsRepository` + 3 use cases 接通（`get_happiness_report_use_case.dart` / `get_best_joy_moment_use_case.dart` / `get_family_happiness_use_case.dart`）
- `getSatisfactionDistribution`：✅ 已通过 repo + 2 use cases 接通
- `getDailySatisfactionTrend`：❌ 仍休眠，但本期不再使用（被新的 `getDailySoulRowsForPtvf` 取代——见 D-05）
- `getBestJoyMoment`：✅ 已通过 repo + use case 接通

**Delivered surface:**
- 全新 `AnalyticsScreen.dart`（删除当前 274 行实现并重写）
- 删除 8 个旧 widget 文件：`SummaryCards` / `CategoryPieChart` / `DailyExpenseChart` / `LedgerRatioChart` / `BudgetProgressList` / `ExpenseTrendChart` / `CategoryBreakdownList` / `MonthComparisonCard`
- 新 IA 三大区域（具体形态由 `/gsd-ui-phase 11` Pencil 锁定）：
  - **【悦己账本】** headline (mean primary + median tooltip + coverage caption "n=k rated") + Joy/¥ trend line (LineChart, MTD) + 满足度 distribution histogram (BarChart, 1-10 bucket, `5` bar 三语注释) + Best Joy 故事条（与 HomePage 等价）
  - **【生存账本】** survival-only 分类视图 + 日频 + 预算进度（视 v1.1 资源决定，必要时 partial defer）
  - **【跨账本总览】** 总支出 KPI + 月对比 + 6 个月趋势
- 月份选择器保留（沿用 `selectedMonthProvider`），所有图表随选中月份变化（D-08）
- Phase 10 HomeHeroCard 整卡 tap → AnalyticsScreen「悦己」一级视图（具体落位形态 TBD UI-phase）
- 视觉合约源：`/Users/xinz/Documents/0503-analytics-redesign.pen`（新建，不沿用 0502.pen）

**Not delivered (downstream / deferred):**
- IA shape 具体形态——延期到 `/gsd-ui-phase 11`（D-03）
- ADR-XXX_Analytics_Redesign_v1_1.md（如 UI-phase 决定需要）
- v1.2 voice estimator 重对齐（histogram 5 bar caption 引用 voice cluster；voice scale 调整属 v1.2）
- ARB 文案 polish（与 Phase 12 ARB rename pass 协调，避免抢动）
- 颜色/排版 polish（沿用 Phase 10 D-13 模式，留作最后一个 plan unit）
- 多成员 trend 叠加 / leaderboard 类视觉——v1.1 binding ban，由 X2 决议（D-13）+ ADR-012 anti-leaderboard 合约保护

</domain>

<decisions>
## Implementation Decisions

### Scope expansion（Plan 阶段必须执行的 spec amendments，类比 Phase 10 D-06/D-07）

- **D-01（ROADMAP.md goal 改写）：** Phase 11 由「wire 3 dormant DAO methods + 子区 + Joy/¥ trend + histogram」升级为「重新设计 `AnalyticsScreen` 整体 IA；删除现有 8 个 widget；新 IA 围绕 Phase 9 happiness 合约组织『悦己 + 生存 + 跨账本』三大区域；Joy/¥ trend + 满足度 histogram + headline 是『悦己』区域核心」。Complexity M → M-H。Phase 11 仍可与 Phase 10 并行（不变）；Phase 12 仍 last（不变）。

- **D-02（REQUIREMENTS.md 追加 STATSUI-05/06/07）：**
  - `STATSUI-05`: AnalyticsScreen 重构为「悦己 / 生存 / 跨账本」三区 IA；删除 v1.0 时代 8 个 analytics widget；删除清单与替换/搬移决议明确逐项记录。
  - `STATSUI-06`: 「生存账本」区域以 survival-only 视图形态重建分类 / 日频 / 预算进度能力；不沿用 v1.0 widget 实现。
  - `STATSUI-07`: 「跨账本总览」区域重建总支出 KPI / 月对比 / 6 个月趋势；月份选择器保留并复用 `selectedMonthProvider`。
  - Traceability：STATSUI-05/06/07 → Phase 11；v1.1 active REQ 数 28 → 31。
  - **额外**：PROJECT.md `Validated` 基线显式标注 v1.0 之前的 Analytics 表面在 v1.1 Phase 11 重做中被替换；release notes 必须说明这是有意替换而非回归。

### IA & 视觉合约（交给 UI-phase 锁）

- **D-03（IA shape = TBD，交给 `/gsd-ui-phase 11`）：** 用户要求在 Pencil 中先出 3 种 IA 形态再做选择。本期 CONTEXT.md 仅记录 3 个候选起始名称：
  - **候选 A：Tab 架构**（AppBar 下 TabBar：「悦己 / 生存 / 总览」三 tab；Phase 10 hero tap → `AnalyticsScreen(initialTab: AnalyticsTab.joy)`）
  - **候选 B：单页折叠**（SingleChildScrollView 三 section + 折叠 chevron；Phase 10 hero tap → `Scrollable.ensureVisible` 锚点滚动到「悦己」section；总览默认 collapse）
  - **候选 C：入口式**（主屏 = 「悦己」；「生存」/「总览」为顶部入口按钮 push 子 screen；Phase 10 hero tap → 默认主屏）
  - UI-phase 各画 light + dark 至少 1 张全屏线框，6 张总，**视觉级别为 wireframe**（颜色暂用占位）；颜色 polish 延期到 Phase 11 最后一个 plan unit（沿用 Phase 10 D-13）。

- **D-04（Pencil 文档 = `/Users/xinz/Documents/0503-analytics-redesign.pen`）：** 新建独立文档，**不沿用** Phase 10 的 `/Users/xinz/Documents/0502.pen`。理由：v1.1 版本管理便利、避免与 Phase 10 hero card 卡片混淆、Phase 11 视觉合约语境独立（屏级 IA vs 卡级合约）。

### Joy/¥ trend line 数据通路

- **D-05（数据源策略 = 新增 DAO `getDailySoulRowsForPtvf` + Dart use case 按日 fold）：** DAO 返回 `(day, amount, sat)` 行（复用 `_soulExpenseFilter` + `DATE(timestamp,'unixepoch','localtime')` 分组），不动 schema。Use case `GetDailyJoyPerYenUseCase` 按 day 分组、每组独立 fold PTVF（α=0.88，base 由 `joy_density_formatter` 提供，currency-aware）；输出 `List<DailyJoyPerYenPoint>`，顶层 `MetricResult.Empty/Value` 处理 thin sample。新 Freezed 模型 `SoulRowSampleWithDay` 与 Phase 9 `SoulRowSample` 并存不冲突。**dormant DAO `getDailySatisfactionTrend` 在本期不再使用**（被 `getDailySoulRowsForPtvf` 取代——可考虑删除 dormant DAO method 或保留待 v2，由 planner 决定）。

- **D-06（gap-vs-zero policy = 断点）：** 某日零魂账 tx 时该日**不渲染点 + 线段跳过**。chart legend 必须明示「断点 = 该日未记录魂账」。语义最准确（「未记录」≠「Joy=0」）。fl_chart（或所选 chart 库）以分段 `LineChartBarData` 实现，dotData 仅在有点的日上 show。

- **D-07（thin-sample fallback = 月总 n<5 时 trend 与 histogram 共用文本 fallback）：** trend + histogram 两图所在区域整体替换为单张占位 Card：「本月魂账记录不足 5 笔。多记录一周后回来看 Joy 趋势」+ 「去记录 »」CTA（导航到 transaction add screen）。ARB 仅需 1 个 key。headline mean / median 仍可显示（"n=k" 状态明示）。Phase 10 D-09 中 hero card「总是渲染」的契约不影响——Phase 11 chart 是统计深度页面，文本 fallback 是 STATSUI-02 字面要求。

- **D-08（时间窗 = 保留 selectedMonthProvider，所有图表随选中月份变化）：** AnalyticsScreen 顶部保留月份选择器（具体形态视 IA 候选决定——Tab 下可能在 AppBar bottom；单页折叠下可能跟原位）；Joy/¥ trend / histogram / headline / Best Joy 全部 keyed by `(bookId, year, month)`。PROJECT.md 锁定的「时间窗 = 本月累计」指的是「不要双时间轴」而非「只能看当月」——保留选择器与之不冲突。

### 满足度 histogram

- **D-09（x 轴粒度 + 5 bar 注释 = 1-10 全 bucket，5 bar 加三语注释「中央値・含未評価 / 中位数·含未评分 / Median + unrated」）：** picker 不可达的 1/3/5/7/9 在 voice / legacy 数据下仍可能出现，自然落点到对应 bar。5 bar 注释 trilingual 锁定。与 ADR-014 voice 重对齐 v1.2 衔接：v1.1 仍能看到 voice 产出奇数/5 分布，v1.2 voice 对齐后该分布会自然变化。

- **D-10（bar 渐变 = 双色相 cool→warm，1 冷色 → 10 暖色）：** 用户选 cool→warm 双色相渐变（与 satisfaction picker emoji 引导色一致）。**已知张力（必须在 UI-phase + 代码评审时解决）：** ADR-014 unipolar positive scale 规定 sat 1 是「不那么高」而非「负面」；cool→warm 在文化语境下偶尔被读作「沮丧→快乐」，需要：(1) UI-phase Pencil 设计 caption 上明示「色彩仅为 ordinal 视觉区分，1 不代表负面情绪 (per ADR-014)」；(2) 代码评审检查 widget 不得在 ARB / tooltip / accessibilityLabel 中暗示「低 = 不好」语义；(3) 颜色具体值（蓝紫色相 vs 中性灰起始 vs 其他）由 UI-phase 决定，但起始端**避免** red/orange 这类强负面文化色。

### group mode 表达（anti-leaderboard binding）

- **D-11（group mode trend = 仅当前 book）：** group mode 下 Joy/¥ trend line **只画当前 book**，不跨成员叠加。理由：多色叠加折线本质是 `Map<MemberId, List<Point>>`，是隐性 leaderboard——直接违反 FAMILY-01/02 anti-leaderboard 合约 + ADR-012 binding ban + Phase 9 D-08「`FamilyHighlightsSum` 返回 int aggregate-only」编译时强制。Phase 11 严格遵守 v1.1 milestone「家庭模式 = 反对抗」核心定位。

- **D-12（group mode histogram = 仅当前 book）：** 与 D-11 一致。Histogram 不合并家庭所有 book 的 distribution，避免「trend 不家庭化、histogram 家庭化」的不一致体验。家庭维度的表达交给 D-13 的 FamilyInsightCard。

- **D-13（FamilyInsightCard 新 widget = 句式表达）：** group mode 下「悦己」区域顶部新增 `FamilyInsightCard`（视具体 IA 决定落位）。基于 Phase 9 已有合约组合：
  - `FamilyHighlightsSum`（int）→「本月家族小確幸 N 次」
  - `SharedJoyInsight`（categoryId, avgSatisfaction, totalCount）→「你们都偏爱 [category] (n 笔, avg X.X)」
  - empty state（SharedJoyInsight 为 null，min-N=3 不达）→「本月还没有共同最爱品类——再多记录几笔魂账试试」
  - **不破合约**：不消费成员级数据；不引入 `Map<MemberId, ?>` 形态；不新增 DAO 方法
  - 句式 ARB 模板由 planner / UI-phase 起草；ja/zh/en 三语；register 与 Phase 12 lexical hierarchy ADR 协调

- **D-14（HomePage rings × Analytics sentence 渲染分工）：** 同一份 Phase 9 family 合约（`FamilyHighlightsSum` + `SharedJoyInsight`）以两种形态在两个屏渲染：HomePage HomeHeroCard 用 3 环图（Phase 10 D-04 已锁定，**不动**）；AnalyticsScreen FamilyInsightCard 用句式（信息密度优先）。两者完全互补，**禁止**抽出共享 ring widget 跨屏复用（Phase 10 ring 是 hero 卡级合约，Phase 11 是屏级信息密度，合约不同）。

### Claude's Discretion

下列由 planner / UI-phase 决定，本期不锁：
- 具体 chart 库（fl_chart / charts_flutter / 其他）—— researcher 检查 v1.0 widget 删除后 chart 库依赖能否同步移除或仍保留
- ARB 命名空间前缀（`analytics*` vs `joyLedger*` 或新增 `joyAnalytics*`）—— planner 在 plan 阶段 grep 现有命名约定后决定
- 8 个旧 widget 文件的物理删除策略（直接 `rm` vs 移到 `deprecated/` 缓冲一段时间）—— planner 决定，**默认建议直接删除**（与 Phase 10 删除 SoulFullnessCard / MonthOverviewCard / LedgerComparisonSection 一致）
- 旧 widget 配套 ARB key 是否同步删除 / 迁移 / 保留（视新设计是否复用 KEY）—— planner 决定；ARB-parity CI guardrail 必须绿
- 月份选择器在不同 IA 候选下的具体 affordance（Tab 下放 AppBar bottom 还是 page-top；单页折叠下是否 sticky）—— UI-phase 决定
- `getDailySatisfactionTrend` dormant DAO 的处置（删除 vs 保留）—— planner 决定
- ADR-XXX_Analytics_Redesign_v1_1.md 草稿是否需要 —— UI-phase 锁 IA 后由 planner 评估（IA 决议本身就是 ADR 候选）
- chart y 轴 baseline / unit display / tooltip 内容细节 —— UI-phase + planner
- TabController 状态保持策略（如果走 Tab IA）—— planner

### Folded Todos

- **Phase 11 deeper-research moment for `shadowBooksProvider` family-mode book enumeration**（STATE.md Pending Todos）：被 D-11/D-12/D-13 决议覆盖——shadowBooksProvider 在重建 AnalyticsScreen 中**不被消费**（family insight 通过 Phase 9 已有 `FamilyHighlightsSum` + `SharedJoyInsight` 合约表达，二者已内部处理 book 枚举）。该 todo 实质上消解。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning (always)
- `.planning/PROJECT.md` — v1.1 milestone vision，「不动 schema / 不动色调 / 不动 enum」锁定，core insight「10 元小確幸 vs 1000 元购物」，Phase 9-11 状态
- `.planning/REQUIREMENTS.md` — STATSUI-01..04 active for Phase 11；STATSUI-05/06/07 在 Phase 11 plan 阶段追加（D-02）；HAPPY-06 thin-sample 合约在 Phase 11 chart 层兑现
- `.planning/ROADMAP.md` — Phase 11 entry；goal/critical-pitfalls/complexity 在 plan 阶段按 D-01 改写
- `.planning/STATE.md` — Phase 10 complete (2026-05-03)，Phase 11 ready to plan
- `.planning/phases/09-happiness-domain-formula-layer/09-CONTEXT.md` — Phase 9 决策 D-13（sealed `MetricResult`）/ D-15（`HappinessReport` / `FamilyHappiness` shape）/ D-08（family aggregate-only int 强制）/ D-09（`familyHappinessProvider` 内部短路）/ D-21（headline 决议下沉到 consumer）
- `.planning/phases/10-homepage-soulfullnesscard-redesign/10-CONTEXT.md` — Phase 10 决策 D-04（HomePage rings 已定）/ D-08（minimum gate）/ D-09（hero card「总是渲染」与 Phase 11 chart「文本 fallback」分工）/ D-11（hero tap → AnalyticsScreen 落地契约）/ D-13（颜色 polish 留最后）

### Phase 9 deliverables consumed by Phase 11 (read before planning)
- `lib/features/analytics/domain/models/happiness_report.dart` — `HappinessReport` Freezed 模型（headline mean/median + Joy/¥ + highlights count + best joy 5 个 MetricResult 字段）
- `lib/features/analytics/domain/models/family_happiness.dart` — `FamilyHappiness` 反 leaderboard 合约（int aggregate + 3-tuple insight + median sat）
- `lib/features/analytics/domain/models/best_joy_moment_row.dart` — `BestJoyMomentRow`
- `lib/features/analytics/domain/models/metric_result.dart` — sealed `MetricResult<T>` (Empty / Value)
- `lib/features/analytics/domain/models/shared_joy_insight.dart` — `SharedJoyInsight(categoryId, avgSatisfaction, totalCount)`
- `lib/features/analytics/presentation/providers/state_happiness.dart` — `happinessReportProvider` / `bestJoyMomentProvider` / `familyHappinessProvider`（Phase 11 仍消费）
- `lib/application/analytics/get_happiness_report_use_case.dart` — Phase 11 新增 `GetDailyJoyPerYenUseCase` 的模板参考（同模块）
- `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` — Phase 9 D-20 PTVF base + display unit；Phase 11 daily fold 直接复用

### Phase 11 source files (must read for refactor decisions)
- `lib/features/analytics/presentation/screens/analytics_screen.dart` — **当前 274 行实现整体重写**（删除 8 widget 引用 / `_buildSection` helper / 月份选择器视 IA 决议保留与重排）
- `lib/features/analytics/presentation/widgets/summary_cards.dart` — DELETE
- `lib/features/analytics/presentation/widgets/category_pie_chart.dart` — DELETE
- `lib/features/analytics/presentation/widgets/daily_expense_chart.dart` — DELETE
- `lib/features/analytics/presentation/widgets/ledger_ratio_chart.dart` — DELETE
- `lib/features/analytics/presentation/widgets/budget_progress_list.dart` — DELETE
- `lib/features/analytics/presentation/widgets/expense_trend_chart.dart` — DELETE
- `lib/features/analytics/presentation/widgets/category_breakdown_list.dart` — DELETE
- `lib/features/analytics/presentation/widgets/month_comparison_card.dart` — DELETE
- `lib/data/daos/analytics_dao.dart` — 新增 `getDailySoulRowsForPtvf` 方法（D-05），与现有 `getSoulRowsForPtvf` 并存
- `lib/data/repositories/analytics_repository_impl.dart` — 追加 `getDailySoulRowsForPtvf` 实现
- `lib/features/analytics/domain/repositories/analytics_repository.dart` — 追加 `getDailySoulRowsForPtvf` 接口
- `lib/application/analytics/get_happiness_report_use_case.dart` 同目录 — 新增 `GetDailyJoyPerYenUseCase`
- `lib/features/analytics/presentation/providers/state_analytics.dart` — `selectedMonthProvider` 保留（D-08）；`monthlyReportProvider` 是否仍需保留视 STATSUI-07「跨账本总览」如何实现决定（默认保留）
- `lib/features/family_sync/presentation/providers/state_active_group.dart` — `isGroupModeProvider` 用于 D-13 FamilyInsightCard gate
- `lib/features/home/presentation/screens/home_screen.dart` — Phase 10 hero card 整卡 tap 调用点（导航 contract 由 D-03 IA 决议确定后回填）
- `lib/features/home/presentation/widgets/home_hero_card.dart`（待 Phase 10 实现完成后核对路径）— hero tap 形态参考
- `lib/core/router/*.dart` — 如果 D-03 选候选 C（入口式独立子 screen），需要新增路由

### Architecture / spec docs
- `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` — 5-layer 架构 / Thin Feature rule（features 内部禁有 application/data，遵循）
- `docs/arch/01-core-architecture/ARCH-004_State_Management.md` — Riverpod conventions
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — anti-Goodhart binding / 跨期/跨成员对比禁令（**Phase 11 D-11/D-12 决议直接保护此 ADR**）
- `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md` — PTVF formula rationale（D-05 daily fold 与之一致）
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` — D-09/D-10 直接消费此 ADR；D-10 双色相渐变张力的解决基线
- `.planning/research/FEATURES.md` — 第 81-82 行 Joy ROI 反 pattern；第 47 行 Spotify Wrapped argmax；第 79-86 行 anti-features inventory
- `.planning/research/PITFALLS.md` — survival contamination guard
- `.planning/codebase/ARCHITECTURE.md` / `STRUCTURE.md` / `CONVENTIONS.md` — codebase patterns（v1.0 cleanup 后；Phase 11 删除 8 widget 后 STRUCTURE.md 需更新到 v1.1）

### Project rules
- `CLAUDE.md` — Thin Feature rule / Drift TableIndex syntax（D-05 不增表只增方法 / 无 TableIndex）/ Riverpod provider rules / Common Pitfalls 1-13 / **Amount Display Style**（`AppTextStyles.amountLarge/Medium/Small` 用于所有 ¥ 数字）
- `.claude/rules/coding-style.md` — Immutability / file size targets <800 lines（重写 AnalyticsScreen 不得超）
- `.claude/rules/testing.md` — TDD workflow / ≥70% per-file 覆盖 / `--deferred` 机制
- `.claude/rules/arch.md` — ADR 编号协议（如 D-03 IA 决议触发新 ADR，遵循）
- `.claude/rules/worklog.md` — 任务完成必生成 worklog（plan 阶段每个 plan unit 完成后执行）

### 视觉合约 (source-of-truth, to be authored)
- `/Users/xinz/Documents/0503-analytics-redesign.pen` —— **新建文档**（D-04），由 `/gsd-ui-phase 11` ramp 填充：
  - 候选 A `P11-IA-Tab` light + dark
  - 候选 B `P11-IA-SinglePage` light + dark
  - 候选 C `P11-IA-EntryPoints` light + dark
  - 后续视觉迭代直至锁定 1 个 IA + 完整线框

### 外部 / 学术 sources
- Kahneman & Tversky (1979) "Prospect Theory" — α=0.88 PTVF 经验拟合（D-05 daily fold 与之一致）
- Frederick & Loewenstein (1999) "Hedonic Adaptation" — Joy/¥ 公式语义来源
- Goodhart's Law (Goodhart, 1975) — 已被 ADR-012 引用；Phase 11 D-11/D-12 决议直接守护

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`happinessReportProvider` / `bestJoyMomentProvider` / `familyHappinessProvider`**（`lib/features/analytics/presentation/providers/state_happiness.dart`）—— Phase 9 deliverable，Phase 11 直接消费 headline + Best Joy + family insight
- **`AnalyticsRepository.getSoulSatisfactionOverview` / `getSatisfactionDistribution` / `getBestJoyMoment` / `getSoulRowsForPtvf`**（`lib/data/repositories/analytics_repository_impl.dart`）—— Phase 9 已接通，Phase 11 直接消费 histogram + headline；新增 `getDailySoulRowsForPtvf` 平行加在该接口
- **`selectedMonthProvider`**（`lib/features/analytics/presentation/providers/state_analytics.dart`）—— D-08 时间窗保留，跨图共享；月份变化时所有 chart provider 自动 invalidate
- **`isGroupModeProvider` / `activeGroupProvider`**（`lib/features/family_sync/presentation/providers/state_active_group.dart`）—— D-13 FamilyInsightCard gate（Phase 10 D-08 minimum gate 同步沿用）
- **`AppTextStyles.amountLarge/Medium/Small`**（`lib/core/theme/app_text_styles.dart`）—— `FontFeature.tabularFigures()`，所有 ¥ 数字必用
- **`FormatterService` / `NumberFormatter` / `DateFormatter`**（`lib/infrastructure/i18n/formatters/`）—— 货币 / 日期 locale-aware
- **`CategoryLocalizationService.resolveFromId(categoryId, locale)`**—— D-13 FamilyInsightCard 句式中 category 名解析；Best Joy 故事条 category 解析
- **`AppColors.soul` / `AppColors.survival` / `AppColors.accentPrimary`** + `app_theme_colors.dart` 扩展方法（`context.wmCard` / `context.wmTextPrimary` 等）—— D-10 渐变色起止端最终从这些 token 选择
- **`joy_density_formatter.dart`**（Phase 9 D-20）—— PTVF base + display unit；Phase 11 daily fold 中 base 与 monthly 一致

### Established Patterns

- **Container Widget With Async Provider** —— widget 收 Freezed aggregate，由父级 `AsyncValue.when` 包装。Phase 11 各 chart widget 沿用：parent screen 做 `.when()`，chart widget 收 `(report, dailyJoy, distribution)` 直接渲染
- **Sealed `MetricResult<T>` pattern matching** —— UI 通过 `switch (result) { case Empty(): ...; case Value(:final data, :final sampleSize): ...; }` 消费；Phase 11 thin-sample fallback (D-07) 直接 dispatch 这两个 case
- **One repository_providers.dart per feature/domain** —— Phase 11 不新增 repository provider；新 use case provider 加在 `state_happiness.dart` 或新 `state_joy_trend.dart`，由 planner 决定
- **Widget Parameter Pattern (CLAUDE.md Pitfall #9)** —— chart widget 收 nullable 参数 + provider fallback；零硬编码 `'JPY'`
- **Drift `_soulOnly()` SQL fragment**（Phase 9 D-21）—— `getDailySoulRowsForPtvf` 必用 `_soulExpenseFilter` 常量；survival 行不能污染 Joy/¥ trend
- **Phase 10 `HomeHeroCard` Container 模式** —— Phase 11 chart widget 同样的 parent 解开 AsyncValue 模式

### Integration Points

- **Phase 11 → Phase 10**：D-11 落地由 Phase 11 IA 决议（D-03）确定。Phase 10 的 `_buildHeroCard` 中 onTap 调用点需要在 IA 锁定后回填具体调用形态：
  - 候选 A → `Navigator.push(... AnalyticsScreen(bookId, initialTab: AnalyticsTab.joy))`
  - 候选 B → `Navigator.push(... AnalyticsScreen(bookId, scrollToJoyLedger: true))`
  - 候选 C → `Navigator.push(... AnalyticsScreen(bookId))` （主屏即「悦己」）
- **Phase 11 → Phase 12**：Phase 12 ARB rename pass 改 `homeHappinessROI` / `homeSoulFullness` 等 KEY 的 VALUE。Phase 11 新增 ARB KEY（`analyticsJoy*` 或 `joyLedger*`）不应被 Phase 12 改动；planner 应核对 Phase 12 RENAME-01..06 不与 Phase 11 新 KEY 冲突
- **Phase 11 → 路由层**：D-03 候选 C 需要新增 GoRouter 路由；候选 A/B 不需要
- **删除 8 个 widget 后的 imports 清理**：`analytics_screen.dart` import 删除 8 行 + 相应 widget 文件删除；`flutter analyze` 必须 0 issues 才能 commit

### Known forbidden patterns (CI-enforced or project policy)

- ❌ 多色叠加跨成员 trend line（D-11 binding；FAMILY-01/02 + ADR-012）
- ❌ Histogram 合并家庭所有 book 的 distribution（D-12 binding）
- ❌ 暴露 `Map<MemberId, ?>` 形态合约（Phase 9 D-08 编译时强制）
- ❌ 多色相渐变在 ARB caption / accessibilityLabel 中暗示「低 = 不好 / 沮丧」（D-10 ADR-014 张力解决方案）
- ❌ 抽出共享 ring widget 跨 HomePage/Analytics 复用（D-14；合约不同，强行共享导致 Phase 10 hero 卡级合约扩散）
- ❌ 引入 `sqlite3_flutter_libs` 替换 `sqlcipher_flutter_libs`（CI 守护）
- ❌ 在 `lib/features/analytics/` 下新增 `application/` / `data/`（Thin Feature rule，import_guard 强制）
- ❌ 硬编码 `'JPY'`（CLAUDE.md Pitfall #9）
- ❌ 在 ARB 复数文件 KEY 不一致（ARB-parity CI guardrail）
- ❌ 删除 widget 后忘记跑 `flutter gen-l10n`（如有 ARB key 删除）
- ❌ 删除 widget 后忘记跑 `build_runner`（如有 `@riverpod` 引用变化）

</code_context>

<specifics>
## Specific Ideas

讨论中沉淀的、定向影响 downstream 判断的产品哲学瞬间：

- **「删除现有 widget，在当前 phase 重新设计分析页面」** —— 用户明确要求 Phase 11 与 Phase 10 量级对等。AnalyticsScreen 不再是「插一个子区」，而是一次完整的 IA 重设。这意味着 plan 阶段必然伴随 PROJECT.md / REQUIREMENTS.md / ROADMAP.md 的 spec amendments；release notes 必须显式说明被替换的 v1.0 能力（预算 / 月对比 / 6 个月趋势 / 分类排行榜等）以避免被误判为回归。

- **「在 Pencil 中给出 3 种 IA 形态的样式，我再做选择」** —— 用户拒绝在 discuss-phase 用语言锁定 IA，直接派给 UI-phase 走视觉迭代。延续 Phase 10 的成功经验（v3..v8 视觉迭代）。这是用户在 GSD ramp 流程上的成熟使用——决策延迟到合适的工具阶段，不强行在文字层敲定。

- **「保留 selectedMonthProvider，所有图表随选中月份变化」** —— PROJECT.md 的「时间窗 = 本月累计，避免双时间轴」被用户重新解读为「不要双时间轴」而不是「只能看当月」。这与 v1.0 AnalyticsScreen 的实际能力一致；保留意味着 v1.0 的关键能力「回看历史月份」未被退化。

- **「双色相 cool→warm」（histogram 渐变）** —— 用户偏离了 Recommendation（单色相 soul-green 强度渐变），这选择背后是「让色彩与 satisfaction picker emoji 表达对齐」的产品语言一致性诉求。但与 ADR-014 unipolar positive 存在张力，必须在 UI-phase 设计语言层、代码评审 ARB caption 层、accessibilityLabel 层三处显式守护「色彩 ≠ 情绪」。

- **X2 决议（FamilyInsightCard 句式）vs 原始 multi-line trend 偏好** —— 用户最初选了「多成员叠加 trend」+「histogram aggregate」，被 Phase 9 anti-leaderboard 合约 + ADR-012 binding 阻挡。X2 路径（trend/histogram 仍 single book + 新增句式 FamilyInsightCard）是用户在 milestone 合约面前的合作选择。这次回归说明：v1.1「家庭模式 = 反对抗」是用户认同的核心定位，不是 Claude 单方面的合约洁癖。Phase 11 在保护这个差异化卖点。

- **「HomePage = 环图视觉冲击，Analytics = 句式信息密度」（D-14）** —— 同一份 family 合约在两个屏的渲染分工。环图给情绪冲击（HomePage 只看一眼），句式给信息密度（Analytics 来读细节）。这是产品双屏分工的优雅样板，不应通过「抽共享 ring widget」破坏。

- **`getDailySatisfactionTrend` 的命运** —— 该 dormant DAO 方法在 Phase 11 被 `getDailySoulRowsForPtvf` 取代。说明 ROADMAP.md / PROJECT.md 写「3 个休眠 DAO 方法」时的假设——「直接接线即可」——在 Phase 9 实际接通后已经改变。本期 audit 文档（STATSUI-04）应明示这个事实修正，避免 planner 误以为还要去 wire 它。

</specifics>

<deferred>
## Deferred Ideas

### Out-of-Phase-11 — 仍在 v1.1 内（Phase 12 处理）
- **ARB 文案 polish**（包括 Phase 11 新增 KEY 的 ja/zh/en register review）—— Phase 12 RENAME 范围；planner 应在 plan 中标注 Phase 11 新 KEY 不在 Phase 12 RENAME-01..06 名单里，但 native-speaker register review 可顺便覆盖
- **`homeSoulFullness` / `homeHappinessROI` ARB 重命名**与 Phase 11 chart 标题如何引用 —— Phase 11 chart 不引用 home* ARB key（命名空间隔离）；Phase 12 改 home* 不影响 Phase 11

### Out-of-v1.1 — v2 / 未来 milestone
- **多成员 Joy/¥ trend 叠加**（解禁 cross-member 比较）—— 直接违反 ADR-012 + FAMILY-01/02 binding。**defer 到 v1.2** 立 `FAMILY-V2-04` REQ + 新 ADR `ADR-XXX_Cross_Member_Comparison_Reevaluation_v1_2` 评审是否解禁、何种 scope 解禁、如何避免 leaderboard。这是 milestone-level 决策，不能在 phase 级偷渡
- **family aggregate distribution / family daily series**—— Phase 9 family 合约（int + 3-tuple + median）刻意不含这些。如未来需要 family-level histogram / family daily Joy/¥，需 v1.2+ 立新 family 合约 + 新 DAO；当前 D-12/D-13 决议不打开缺口
- **ADR-014 voice estimator 重对齐** —— v1.1 Phase 9 D-12 已 defer；Phase 11 D-09 5 bar 注释「含未評価」承担过渡期解释。voice 对齐发生时该 caption 自然消解
- **预算管理 UI 重设计** —— Phase 11 删除 `BudgetProgressList` 后预算表面短期消失（D-02 release notes 明示）；v1.2 立新 REQ「预算管理表面重设计」+ 评估是否搬到设置页 / 主页 hero 副条 / 新独立 screen
- **6 个月趋势 / 月对比 / 总支出 KPI 在「跨账本总览」的具体形态** —— STATSUI-07 给了 placeholder，UI-phase 锁定 IA 后 planner 决定是否拆分到独立 v1.2 plan 单位
- **共享 chart widget 抽象层**（如果 Phase 11 chart 实现后发现与未来 v1.2 chart 高度重合）—— v1.2 重构机会；Phase 11 不主动抽象
- **删除 8 个 widget 后 ARB key 的清理 pass** —— Phase 11 同步处理；如果遗漏，v1.2 加 ARB key garbage collection lint
- **AnalyticsScreen 重构相关 ADR (`ADR-XXX_Analytics_Redesign_v1_1`)** —— UI-phase 锁定 IA 后由 planner 评估必要性；如必要，Phase 11 plan 中加 ADR 草稿 plan unit

### Forbidden anti-features (binding through milestone close)
- ❌ **多成员叠加 trend line / 多成员 histogram / 任何 Map<MemberId, ?> 形态的合约**（D-11/D-12；ADR-012 + FAMILY-01/02 + Phase 9 D-08 binding）
- ❌ **跨期 happiness 对比** ("vs 上月 Joy: -3%")（ADR-012 binding；Phase 11 仅在 STATSUI-07「跨账本总览」中显示**支出**月对比，不是 happiness 月对比）
- ❌ **streaks / badges / daily targets**（ADR-012 binding；Phase 11 不引入任何 chart 标记或 caption 形成 streak 暗示）
- ❌ **AI 生成 Joy 数据解释** 或 **公开分享**（research line 84/86；Phase 11 chart tooltip 必须是固定文案，不调 LLM）
- ❌ **「最低/最高满足度成员排行」** 或类似排行榜（D-11/D-13；FamilyInsightCard 句式严格基于 aggregate + insight 三元组）
- ❌ **Joy ROI / happiness share / soul %** 类框架重新出现 在重建 AnalyticsScreen 上（Phase 10 D-02 / research line 81-82 binding）

### Reviewed but not folded
- 无（cross_reference_todos 步骤匹配 0 个 todo；STATE.md 中 `Phase 11 deeper-research moment for shadowBooksProvider` 被 D-11/D-12/D-13 决议直接消解，已记录在 Folded Todos）

</deferred>

---

*Phase: 11-Statistics Surface for 悦己账本*
*Context gathered: 2026-05-03*
