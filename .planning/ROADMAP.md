# Roadmap: Home Pocket

## Milestones

- ✅ **v1.0 Codebase Cleanup Initiative** — Phases 1-8 (shipped 2026-04-29) — see [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Happiness Metric & Display** — Phases 9-12 (shipped 2026-05-05) — see [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Happiness Metric Refresh** — Phases 13-17 (shipped 2026-05-21) — see [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 迭代帐本输入** — Phases 18-23 (shipped 2026-05-26) — see [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 列表功能** — Phases 24-30 (shipped 2026-05-31) — see [archive](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 文案与配色统一** — Phases 31-35 (shipped 2026-06-02) — see [archive](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 购物清单** — Phases 36-39 (shipped 2026-06-12) — see [archive](milestones/v1.6-ROADMAP.md)
- ✅ **v1.7 多币种支持** — Phases 40-42 (shipped 2026-06-14) — see [archive](milestones/v1.7-ROADMAP.md)
- ⏳ **v1.8 统计页面重设计（实用化 × 悦己情感化）** — Phases 43-47 (in progress) — 设计探索关卡先行

## Phases

<details>
<summary>✅ v1.0 Codebase Cleanup Initiative (Phases 1-8) — SHIPPED 2026-04-29</summary>

- [x] Phase 1: Audit Pipeline + Tooling Setup (8/8 plans) — completed 2026-04-25
- [x] Phase 2: Coverage Baseline (4/4 plans) — completed 2026-04-26
- [x] Phase 3: CRITICAL Fixes (5/5 plans) — completed 2026-04-26
- [x] Phase 4: HIGH Fixes (6/6 plans) — completed 2026-04-27
- [x] Phase 5: MEDIUM Fixes (5/5 plans) — completed 2026-04-27
- [x] Phase 6: LOW Fixes (6/6 plans) — completed 2026-04-27
- [x] Phase 7: Documentation Sweep (6/6 plans) — completed 2026-04-28
- [x] Phase 8: Re-Audit + Exit Verification (8/8 plans) — completed 2026-04-28

**Outcome:** REAUDIT-DIFF.json reports `resolved=50, regression=0, new=0, open_in_baseline=0`. 4 permanent CI guardrails active. Full details: `.planning/milestones/v1.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.1 Happiness Metric & Display (Phases 9-12) — SHIPPED 2026-05-05</summary>

- [x] Phase 9: Happiness Domain & Formula Layer (14/14 plans) — completed 2026-05-02
- [x] Phase 10: HomePage SoulFullnessCard Redesign (13/13 plans) — completed 2026-05-03
- [x] Phase 11: AnalyticsScreen Unified Dashboard (8/8 plans) — completed 2026-05-04
- [x] Phase 12: UI Copy Rename Pass (5/5 plans) — completed 2026-05-04

**Outcome:** v1.1 delivered the happiness metric domain, integrated HomeHeroCard, Variant δ AnalyticsScreen, trilingual Joy/Daily ledger copy rename, and accepted ADR-015 lexical hierarchy. One Phase 11 human UAT verification item is acknowledged as deferred at close in `.planning/STATE.md`. Full details: `.planning/milestones/v1.1-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.2 Happiness Metric Refresh (Phases 13-17) — SHIPPED 2026-05-21</summary>

- [x] Phase 13: ADR-016 Backend Foundation (7/7 plans) — completed 2026-05-19
- [x] Phase 14: ADR-016 Frontend + ARB Reconciliation (6/6 plans) — completed 2026-05-19
- [x] Phase 15: Custom Time Windows (6/6 plans) — completed 2026-05-19
- [x] Phase 16: Per-Category Breakdown + Soul-vs-Survival (10/10 plans) — completed 2026-05-20
- [x] Phase 17: Manual-Only Joy Sub-Metric (8/8 plans) — completed 2026-05-21

**Outcome:** v1.2 migrated the Joy metric from density (Joy/¥) to cumulative `Σ joy_contribution` (ADR-016): HomeHero rebuilt with sage-green→gold target ring, Settings exposes user-configurable `monthly_joy_target` with 3-month median recommendation + fallback baseline 50, AnalyticsScreen Variant ε retired density and added Custom Time Windows (week/month/quarter/year/arbitrary), Per-Category breakdown + Soul-vs-Survival comparison with anti-toxicity framing, and Manual-Only Joy sub-metric variant on Drift schema v17 (`entry_source` column). HomeHero isolation invariant (ADR-016 §3) structurally enforced. Audit status `tech_debt` accepted at close — Phase 13/17 lack VERIFICATION.md; 3 Nyquist VALIDATION.md drafts; documentation-grade debt only. Full details: `.planning/milestones/v1.2-ROADMAP.md` + `.planning/milestones/v1.2-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.3 迭代帐本输入 (Phases 18-23) — SHIPPED 2026-05-26</summary>

- [x] Phase 18: Shared Details Form Foundation (8/8 plans) — completed 2026-05-22
- [x] Phase 19: Manual One-Step + Keypad Polish (5/5 plans) — completed 2026-05-23
- [x] Phase 20: Voice Number Parser (zh + ja) (9/9 plans) — completed 2026-05-24
- [x] Phase 21: Voice Category Resolver Level-2 Enforcement (6/6 plans) — completed 2026-05-25
- [x] Phase 22: Voice One-Step Integration + Record Button UX (10/10 plans) — completed 2026-05-25
- [x] Phase 23: v1.3 Cleanup — Scanner Allow-Lists + Voice Flow Polish (9/9 plans) — completed 2026-05-26

**Outcome:** v1.3 transformed ledger entry into single-screen, voice-trustworthy core experience. Single shared `TransactionDetailsForm` widget powers 4 hosts (manual, voice, edit, OCR review). `ManualOneStepScreen` collapses 2-screen entry chain; SmartKeyboard 48dp non-negotiable touch-target floor with 6 golden baselines. Locale-aware zh+ja voice number parsing (state machines + `VoiceChunkMerger` 2.5s continued-listening window) at zh 96% + ja 100% corpus accuracy. `VoiceCategoryResolver` always-L2 contract with merchant DB + extensible synonym dictionary. Hold-to-record gesture with AnimatedContainer shape morph + caption swap (`<100ms` verified). 2 BLOCKER gaps (G-01/G-02) elevated and closed in Phase 22. Phase 23 cleanup absorbed carried tech-debt. Audit status `tech_debt` accepted at close. Full details: `.planning/milestones/v1.3-ROADMAP.md` + `.planning/milestones/v1.3-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.4 列表功能 (Phases 24-30) — SHIPPED 2026-05-31</summary>

- [x] Phase 24: Data Layer Extension (3/3 plans) — completed 2026-05-29
- [x] Phase 25: Domain Models + Use Case (2/2 plans) — completed 2026-05-29
- [x] Phase 26: Providers + Shell Wiring (4/4 plans) — completed 2026-05-30
- [x] Phase 27: Calendar Header + Month Summary (4/4 plans) — completed 2026-05-30
- [x] Phase 28: Transaction Tile + Sort/Filter Bar (7/7 plans) — completed 2026-05-30
- [x] Phase 29: List Screen Assembly + Family (4/4 plans) — completed 2026-05-30
- [x] Phase 30: i18n + Empty States + Golden Polish (5/5 plans) — completed 2026-05-31

**Outcome:** Built the placeholder List tab into a full transaction overview. Audit `tech_debt` accepted — 22/22 requirements, 7/7 phases, 7/7 E2E flows satisfied. Full details: `.planning/milestones/v1.4-ROADMAP.md` + `.planning/milestones/v1.4-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.5 文案与配色统一 (Phases 31-35) — SHIPPED 2026-06-02</summary>

- [x] Phase 31: Terminology Rename (6/6 plans) — completed 2026-06-01
- [x] Phase 32: Palette Exploration & Selection (3/3 plans) — completed 2026-06-01
- [x] Phase 33: Color Token System & Consolidation (8/8 plans) — completed 2026-06-01
- [x] Phase 34: Golden Re-baseline & Verification (5/5 plans) — completed 2026-06-01
- [x] Phase 35: Close Vocab Leaks — a11y Semantics labels (W1) + totalSoulTx identifiers (W2) (2/2 plans) — completed 2026-06-02

**Outcome:** Brownfield consistency refactor — unified 日常/悦己 vocabulary + `AppPalette` ThemeExtension (ADR-019 "Sakura Mochi × Wakaba" supersedes ADR-018). Audit `tech_debt` accepted at close — 15/15 requirements, 5/5 phases, 6/6 integration seams wired. Full details: `.planning/milestones/v1.5-ROADMAP.md` + `.planning/milestones/v1.5-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.6 购物清单 (Phases 36-39) — SHIPPED 2026-06-12</summary>

- [x] Phase 36: Data Layer + Domain + Import Guard (7/7 plans) — completed 2026-06-07
- [x] Phase 37: Application Use Cases + Sync Integration (6/6 plans) — completed 2026-06-08
- [x] Phase 38: Presentation Shell + UI Widgets (8/8 plans) — completed 2026-06-08
- [x] Phase 39: i18n + Golden Re-baseline + Smoke Test (6/6 plans) — completed 2026-06-09

**Outcome:** The placeholder 4th nav tab is a complete family shopping list — public/private segmented lists, family sync for public items via the existing E2EE pipeline, private items never entering the pipeline (three-layer privacy enforcement). ARB parity ja/zh/en, 54 golden baselines, schema v19→v20. Audit `tech_debt` accepted; W1/W2 sync warnings closed at close by quick task 260612-daz; suite 2588/2588 green. Full details: `.planning/milestones/v1.6-ROADMAP.md` + `.planning/milestones/v1.6-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.7 多币种支持 (Phases 40-42) — SHIPPED 2026-06-14</summary>

**Milestone Goal:** 记账支持外币输入——小键盘选币种、按账目日期自动取汇率转换成日元入账，原币种/原金额/汇率作为附加字段保留并在 UI 中可见。

- [x] Phase 40: 数据与同步基础 (Data Foundation + Domain + Sync) (6/6 plans) — completed 2026-06-12
- [x] Phase 41: 汇率服务 (Exchange Rate Service) (5/5 plans) — completed 2026-06-13
- [x] Phase 42: 输入与展示 + 语音 (Entry UI + Display + Voice) (9/9 plans) — completed 2026-06-13

**Outcome:** Foreign-currency ledger entry end to end (SmartKeyboard currency selector + zh/ja voice), transaction-date historical rate fetch (Frankfurter + fawazahmed0, encrypted Drift cache, offline fallback), JPY-converted integer stored in `amount` with original currency/amount/rate as three nullable sync-safe fields, single `convertToJpy()` conversion site, hash invariant preserved (ADR-021), two-input/one-derived edit (ADR-022 D-01). JPY-only path byte-unchanged. Drift v20→v21. Audit `tech_debt` accepted at close — 23/23 requirements, 3/3 phases, 6/6 seams, E2E complete; residual is draft-Nyquist docs (P40/41/42). Suite 2786/2786 green. Full details: `.planning/milestones/v1.7-ROADMAP.md` + `.planning/milestones/v1.7-MILESTONE-AUDIT.md`.

</details>

## v1.8 统计页面重设计（实用化 × 悦己情感化） — ACTIVE (Phases 43-47)

**Milestone Goal:** 把统计页面从「指标罗列」全面重设计为「更实用（支出总览 / 支出趋势 / 分类下钻）+ 凸显悦己、让用户为自己花钱而感到开心」的体验——在 ADR-012 反游戏化恒久约束内。开发前先用一个硬性「HTML 设计探索关卡」深入调研现状、产出多套 HTML 方向并充分讨论选定一案；**未获批前不进入开发**。这是一次**展示层重建**（数据已存在，最大化复用 5 层架构），不是绿地开发。

**Phase numbering:** Continues from v1.7's Phase 42 → v1.8 = Phases 43-47.

- [x] **Phase 43: HTML 设计探索关卡 (Design Gate — NO production code)** — 现状深研图 + ≥3 套 HTML 方向（各带 ADR-012 自审表）+ 讨论选定一案 + 新 ADR go/no-go + 词表锁定 + fl_chart 1.2.0 affordance 校验；关卡出口 = 用户批准 (completed 2026-06-16)
- [x] **Phase 44: 数据与用例补全 (Data / Use-Case Additions — reuse-first)** — 复用优先确认现状 reuse 图；按选定方向至多新增一条只读「分类下钻」路径（无预算、无 Drift 迁移）；窗口边界经 `DateBoundaries`/`TimeWindow` 规范化 (completed 2026-06-16)
- [ ] **Phase 45: 展示外壳重建 (Presentation Shell Rebuild)** — 瘦身 `analytics_screen.dart` 外壳 + 数据驱动 `_refresh()` + `widgets/cards/` 卡片体系；HomeHero 隔离由结构保证（不读/不失效任何 `home/*` provider）
- [ ] **Phase 46: 卡片体系 (Cards)** — 总览 / 趋势 / 分类下钻 / 悦己×4 / 故事卡，复用既有 chart widget + fl_chart 1.2.0 原生 label（删除直方图 Stack hack）；情感化呈现「已花悦己」满足感，全程反游戏化
- [ ] **Phase 47: i18n + 反毒性扫描 + macOS golden 重基线 + 全量门禁 + UAT** — 三语 ARB parity；每张新卡加入 `anti_toxicity_*_test` 禁词扫描；macOS golden 从零撰写/重基线；全量 `flutter test` 作为逐波门禁；真机视觉 UAT

### Phase 43: HTML 设计探索关卡 (Design Gate — NO production code)

**Goal**: 在写任何生产代码之前，关闭本里程碑的核心设计问题——「为自己花钱而开心」如何在 ADR-012 恒久反游戏化约束下表达——通过深研现状、产出多套 HTML 方向并讨论，选定唯一一案并获用户批准。**本阶段不提交任何 Dart/生产代码（仅 HTML/Pencil mock + 决策文档）。**
**Depends on**: Nothing (first phase of v1.8; gates all build phases)
**Requirements**: GATE-01, GATE-02, GATE-03, GATE-04
**Success Criteria** (what must be TRUE):

  1. 存在一份书面的「现状统计实现深研图」，以 `.planning/research/ARCHITECTURE.md` 的 reuse 图为种子，标明 13/15 可复用用例、`MonthlyReport` 已算字段、HomeHero 隔离与反毒性的结构性锁点（GATE-01）
  2. 产出 ≥3 套 HTML 设计方向，每套自带一张 ADR-012 自审表，把每个情感元素映射为 *ambient / 庆祝过去 (OK)* 还是 *目标 / 跨期对比 / 成就 (forbidden)*（GATE-02）
  3. 经充分讨论后，用户明确选定恰好一套方向；关卡出口 = 用户批准，且仓库中无新增 Dart/生产代码（GATE-03）
  4. 针对选定方向产出：新 ADR 的 go/no-go 决定（如 JOY-04 需持久化用户自撰反思文本，则加密/隐私含义触发新 ADR）、锁定供反毒性扫描使用的情感词表、以及每个图表 affordance 对当前 fl_chart 1.2.0 API 的逐项校验结果（GATE-04）

**Plans**: 7 plans in 3 wavesPlans:
**Wave 1**

- [x] 43-01-PLAN.md — Wave 1: GATE-01 现状深研图 + 共享示例数据 + mock 阵容 README（mock 前置基座）

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 43-02-PLAN.md — Wave 2: M1 实用主导 mock（light+dark+ADR-012 自审）
- [x] 43-03-PLAN.md — Wave 2: M2 均衡 mock（light+dark+ADR-012 自审）
- [x] 43-04-PLAN.md — Wave 2: M3 极简实用派 mock（低悦己强度，light+dark+自审）
- [x] 43-05-PLAN.md — Wave 2: M4 温暖反思派 mock（中强度 + kakeibo Q4 静态提示，light+dark+自审）
- [x] 43-06-PLAN.md — Wave 2: M5 故事画报派 mock（高强度，light+dark+自审）

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 43-07-PLAN.md — Wave 3: GATE-03 选定一案（round-5 B，M2 衍生）→ GATE-04 三决策文档（ADR no-go + 支出跨期 amendment / 词表 / fl_chart 校验）

**Cross-cutting constraints:**

- Dark mock uses ADR-019 桜餅×若葉 warm palette hex
- git diff shows zero .dart/pubspec/lib/test changes (GATE-03)
- Both HTML files self-contained: inline <style>, no external CDN font/JS/CSS
- Mocks draw expense overview only — never 结余率/收入/savings-rate

**UI hint**: yes

### Phase 44: 数据与用例补全 (Data / Use-Case Additions — reuse-first)

**Goal**: 仅补齐选定方向真正需要的展示层之下的数据/用例。复用优先：总览（`GetMonthlyReportUseCase`）与趋势（`GetExpenseTrendUseCase`）零新增数据工作；分类下钻至多新增一条只读路径。**不引入预算表、不做 Drift 迁移、不触收入/结余率（总览仅支出侧）。**
**Depends on**: Phase 43 (selected direction defines exactly which data is needed)
**Requirements**: OVW-01, TREND-01, DRILL-01
**Success Criteria** (what must be TRUE):

  1. 支出总览所需数据（总支出 + 日常/悦己拆分 + Top 分类）确认为对 `monthlyReportProvider` 的纯展示变换，零新增用例/DAO/迁移（OVW-01）
  2. 6 个月滚动支出趋势数据经 `GetExpenseTrendUseCase` 暴露，作为中性滚动上下文（TREND-01）
  3. 若选定方向含下钻，存在至多一条新只读路径（`CategoryDrillDown` Freezed 模型 + `GetCategoryDrillDownUseCase` + `AnalyticsDao.getCategoryTransactions`，或复用 v1.4 `GetListTransactionsUseCase` 过滤路径），TDD 覆盖，并完成 `(book_id, category_id, timestamp)` 索引核查（DRILL-01）
  4. 所有新 provider 的 family key 经 `DateBoundaries`/`TimeWindow` 规范化后再进入 key tuple（避免 microsecond-exact provider rebuild storm）；Drift schema 保持 v21 不变

**Plans**: 3 plans in 2 waves

**Wave 1** (parallel — no file overlap)

- [x] 44-01-PLAN.md — 共享 L1-rollup 纯 helper + 单测（OVW-01 唯一新代码；下钻小结复用同源）
- [x] 44-02-PLAN.md — `MonthlyTrend` +dailyTotal/+joyTotal + `GetExpenseTrendUseCase` per-ledger 扩展（TREND-01；零迁移、无 joy 跨期 delta）

**Wave 2** *(blocked on 44-01 — drill 小结复用其 rollup helper)*

- [x] 44-03-PLAN.md — TDD-first 分类下钻：`CategoryDrillDown` + `GetCategoryDrillDownUseCase`（走 `findByBookIds` + Dart 侧 L1 过滤）+ auto-dispose drill family（DRILL-01；无新 DAO/索引/迁移）

### Phase 45: 展示外壳重建 (Presentation Shell Rebuild)

**Goal**: 在填充卡片之前先确立卡片契约——把 739 行的 `analytics_screen.dart` 单体重建为瘦外壳（AppBar + `TimeWindowChip` + `JoyMetricVariantChip` + 滚动容器 + 卡片列表驱动），并把手写的 108 行 `_refresh()` 改为由卡片注册表派生的数据驱动失效，使 HomeHero 隔离由构造保证。**纯结构重构、行为保持（D-A1）：golden 保绿、隔离测试同断言过、diff = 机械抽取。**
**Depends on**: Phase 44
**Requirements**: REDES-01, GUARD-01
**Success Criteria** (what must be TRUE):

  1. `analytics_screen.dart` 成为瘦外壳；卡片拆分进 `presentation/widgets/cards/`，每卡 < 400 LOC，且每卡是一个 `ConsumerWidget`、watch 自己唯一的 provider family、本地 `.when(data/loading/error)`（REDES-01）
  2. `_refresh()` 数据驱动——失效集合由 analytics 卡片注册表派生，结构上不可能包含任何 `home/*` provider（REDES-01）
  3. `home_screen_isolation_test.dart` 保持 green；analytics 不读取也不失效任何 `home/*` provider，不新增任何 Home 与 Analytics 共享的 provider（GUARD-01）
  4. analytics 卡片 provider 保持 auto-dispose（离开 tab 释放、重入重算）；不向任何 home widget「共享」时间窗 provider

**Plans**: 7 plans in 4 waves

**Wave 1** (parallel — no file overlap)

- [x] 45-01-PLAN.md — 抽共享卡壳 `AnalyticsDataCard` + 4 张卡（KpiHero/TotalSixMonth/CategoryDonut/SatisfactionHistogram）到 `widgets/cards/`，各带单源 `*RefreshTargets`（D-A1/D-B2/D-B5）
- [x] 45-02-PLAN.md — 抽 3 张 Stories 卡（LargestExpense/BestJoy/FamilyInsightData）；FamilyInsight 丢弃 `shadowBooksProvider` 直接失效（D-B3 Option A）
- [ ] 45-06-PLAN.md — ADR-012 append-only `## Update` 补正：支出侧 本月vs上月 为 §4 记录在案例外（D-D1，doc-only）

**Wave 2** *(blocked on 45-01 + 45-02)*

- [ ] 45-03-PLAN.md — 建 typed 注册表 `analytics_card_registry.dart`（AnalyticsCardContext/Spec + 有序 `analyticsCardRegistry` + `shellRefreshTargets`），渲染顺序与 refresh 并集单一来源；DailyVsJoy spec group-aware（含 `dailyVsJoySnapshotFamilyProvider` 仅 group）（D-B1/D-B2/D-B4）

**Wave 3** *(parallel — both blocked on 45-03, no file overlap)*

- [ ] 45-04-PLAN.md — 瘦身 `analytics_screen.dart`：删 7 张内联卡 + `_AnalyticsDataCard`，build 映射注册表（1:1 树）、`_refresh()` 由注册表派生（D-A1/D-B1/D-B3）
- [ ] 45-05-PLAN.md — D-B3 注册表并集单测（⊆ analytics、0 个 `home/*`）+ 渲染顺序/可见性 + `dailyVsJoySnapshotFamily` group-presence + 每卡结构/键单源（Nyquist Wave-0：注册表一就绪即验，与 04 并行）（GUARD-01）

**Wave 4** *(blocked on 45-04 + 45-05)*

- [ ] 45-07-PLAN.md — A1 group-mode 刷新回归（familyHappiness 透传 re-read）+ solo 不触 family + 既有 screen test 不改断言 + 全量门禁（golden 零重基线）（GUARD-01）

**Cross-cutting constraints:**

- 纯结构、行为保持：所有可见变化（round-5 B IA 重排/卡片增删/图表打磨/动效）压到 Phase 46，golden 重基线压到 Phase 47
- 每卡 = `ConsumerWidget` watch 唯一 provider family + 本地 `.when`；single-source `refreshTargets` == error-retry == 注册表并集（卡就是契约）
- 注册表/各 `cards/*` 仅 import analytics providers（home/* 隔离的物理来源）；D-B3 单测背书
- 下钻宿主（D-C1/D-C2）Phase 45 零预留，全部留 Phase 46

**UI hint**: yes (但本阶段零视觉变化——见 45-UI-SPEC.md preserve-as-is 合约)

### Phase 46: 卡片体系 (Cards)

**Goal**: 在外壳契约就绪后，逐卡构建/迁移设计批准的卡片——实用半边（支出总览、趋势、分类下钻入口）与悦己情感半边（值得 / 值不值 / 记忆故事 / kakeibo Q4 反思），全部复用既有 chart widget 并采用 fl_chart 1.2.0 原生能力；情感呈现「庆祝为自己投资」而非「打分」，每张新卡满足反游戏化。
**Depends on**: Phase 45
**Requirements**: OVW-02, JOY-01, JOY-02, JOY-03, JOY-04, REDES-02, REDES-03, GUARD-02
**Success Criteria** (what must be TRUE):

  1. 支出总览卡呈现当前时间窗的中性总览，**无跨期 delta、无评判式措辞**（`MonthlyReport.previousMonthComparison` 保持不被 analytics 页面 surface）（OVW-02）
  2. 「值得」肯定卡呈现 已花悦己 + `Σ joy_contribution` 作为 *为自己投资* 的庆祝；为 ambient 呈现，**绝不成为 progress/target ring**（HomeHero 独占唯一 target ring，ADR-016 §3）（JOY-01）
  3. 「值不值」满足反思卡复用满足度直方图 + 分类悦己（min-N=3），框定为自豪/满足，绝无「超过上月」/排名；「记忆故事」卡抬升既有 best-joy moment；kakeibo Q4 反思 prompt 按 Phase 43 决定的形态落地（若持久化用户自撰文本则按已批准的新 ADR 加密落地）（JOY-02, JOY-03, JOY-04）
  4. 图表采用 fl_chart 1.2.0 原生 per-rod `label`（删除直方图 `Stack` hack）+ 可选 donut `cornerRadius`，**不升级/不更换图表库（保持 `^1.2.0`）**；温暖肯定的动效用 Flutter 内建动画（`TweenAnimationBuilder` count-up / `AnimatedSwitcher` / glow），ADR-012-safe（REDES-02, REDES-03）
  5. `FamilyHappiness` 保持 aggregate-only（无 per-member 字段，无排行）；单一悦己表达保持（`grep density|joyPerYen lib/` == 0）；每张新卡都准备好接入反毒性禁词扫描（GUARD-02）

**Plans**: TBD
**UI hint**: yes

### Phase 47: i18n + 反毒性扫描 + macOS golden 重基线 + 全量门禁 + UAT

**Goal**: 验证已完成的重设计页面——补齐三语文案与 parity、把每张新卡纳入反毒性禁词扫描、在 macOS 上从零撰写/重基线图表 golden（今天图表无 golden 覆盖），以全量 `flutter test`（含隔离/反毒性/架构/CJK/density grep）作为逐波里程碑门禁，并完成真机视觉 UAT。
**Depends on**: Phase 46
**Requirements**: GUARD-03, GUARD-04, GUARD-05
**Success Criteria** (what must be TRUE):

  1. 所有新文案在 ja/zh/en 三语 ARB parity，`flutter gen-l10n` 干净，生存/灵魂 grep-ban 保持 green（ADR-017）（GUARD-03）
  2. 每张新/改卡片加入 `anti_toxicity_*_test` 禁词扫描，禁词在 3 语 × 全部状态下 `findsNothing`（GUARD-02 措辞层 + GUARD-03）
  3. 新/改 analytics 表面的 golden 在 **macOS** 上从零撰写并重基线，diff 归因清晰（无图表库变更混入 diff）；全量 `flutter test` 套件作为逐波门禁通过（含 `home_screen_isolation_test.dart` + 两个反毒性扫描 + 架构/CJK 扫描）（GUARD-04）
  4. 重设计后的统计页通过真机视觉 UAT（GUARD-05）

**Plans**: TBD
**UI hint**: yes

## Milestone Progress

| Milestone | Phases | Plans Complete | Status | Shipped |
|-----------|--------|----------------|--------|---------|
| v1.0 Codebase Cleanup Initiative | 1-8 | 48/48 | Complete | 2026-04-29 |
| v1.1 Happiness Metric & Display | 9-12 | 40/40 | Complete | 2026-05-05 |
| v1.2 Happiness Metric Refresh | 13-17 | 37/37 | Complete | 2026-05-21 |
| v1.3 迭代帐本输入 | 18-23 | 47/47 | Complete | 2026-05-26 |
| v1.4 列表功能 | 24-30 | 29/29 | Complete | 2026-05-31 |
| v1.5 文案与配色统一 | 31-35 | 24/24 | Complete | 2026-06-02 |
| v1.6 购物清单 | 36-39 | 27/27 | Complete | 2026-06-12 |
| v1.7 多币种支持 | 40-42 | 20/20 | Complete | 2026-06-14 |
| v1.8 统计页面重设计 | 43-47 | 10 plans (P43-44 done; P45 planned 0/7) | In progress | - |
