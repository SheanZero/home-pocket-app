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
- ⏳ **v1.8 统计页面重设计（实用化 × 悦己情感化）** — Phases 43-48 (in progress) — 设计探索关卡先行 + 收尾技术债

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

## v1.8 统计页面重设计（实用化 × 悦己情感化） — ACTIVE (Phases 43-48)

**Milestone Goal:** 把统计页面从「指标罗列」全面重设计为「更实用（支出总览 / 支出趋势 / 分类下钻）+ 凸显悦己、让用户为自己花钱而感到开心」的体验——在 ADR-012 反游戏化恒久约束内。开发前先用一个硬性「HTML 设计探索关卡」深入调研现状、产出多套 HTML 方向并充分讨论选定一案；**未获批前不进入开发**。这是一次**展示层重建**（数据已存在，最大化复用 5 层架构），不是绿地开发。

**Phase numbering:** Continues from v1.7's Phase 42 → v1.8 = Phases 43-48 (Phase 48 appended 2026-06-22 for post-audit tech-debt cleanup).

- [x] **Phase 43: HTML 设计探索关卡 (Design Gate — NO production code)** — 现状深研图 + ≥3 套 HTML 方向（各带 ADR-012 自审表）+ 讨论选定一案 + 新 ADR go/no-go + 词表锁定 + fl_chart 1.2.0 affordance 校验；关卡出口 = 用户批准 (completed 2026-06-16)
- [x] **Phase 44: 数据与用例补全 (Data / Use-Case Additions — reuse-first)** — 复用优先确认现状 reuse 图；按选定方向至多新增一条只读「分类下钻」路径（无预算、无 Drift 迁移）；窗口边界经 `DateBoundaries`/`TimeWindow` 规范化 (completed 2026-06-16)
- [x] **Phase 45: 展示外壳重建 (Presentation Shell Rebuild)** — 瘦身 `analytics_screen.dart` 外壳 + 数据驱动 `_refresh()` + `widgets/cards/` 卡片体系；HomeHero 隔离由结构保证（不读/不失效任何 `home/*` provider） (completed 2026-06-17)
- [x] **Phase 46: 卡片体系 (Cards)** (7/7 plans) — 总览 / 趋势 / 分类下钻 / 悦己×4，复用既有 chart widget + fl_chart 1.2.0 原生 label（删除直方图 Stack hack）；情感化呈现「已花悦己」满足感，全程反游戏化 — round-5 B flat 5-card lineup LIVE 2026-06-17
- [x] **Phase 47: i18n + 反毒性扫描 + macOS golden 重基线 + 全量门禁 + UAT** — 三语 ARB parity；每张新卡加入 `anti_toxicity_*_test` 禁词扫描；macOS golden 从零撰写/重基线；全量 `flutter test` 作为逐波门禁；真机视觉 UAT (completed 2026-06-20)
- [x] **Phase 48: v1.8 收尾技术债 (Tech-Debt Cleanup)** (2/2 plans) — 修 TD-1 成员筛选 donut 下拉刷新 staleness（把 donut 成员筛选穿过 `AnalyticsCardContext` 进 `categoryDonutRefreshTargets` + registry-test 白名单 + 完整性断言）+ TD-2 清除已移除 `getExpenseTrendUseCase`/`MonthlyTrend` 残留 dartdoc（regen `.g.dart`）+ 字符化测试描述

### Phase 43: HTML 设计探索关卡 (Design Gate — NO production code)

**Goal**: 在写任何生产代码之前，关闭本里程碑的核心设计问题——「为自己花钱而开心」如何在 ADR-012 恒久反游戏化约束下表达——通过深研现状、产出多套 HTML 方向并讨论，选定唯一一案并获用户批准。**本阶段不提交任何 Dart/生产代码（仅 HTML/Pencil mock + 决策文档）。**
**Depends on**: Nothing (first phase of v1.8; gates all build phases)
**Requirements**: GATE-01, GATE-02, GATE-03, GATE-04
**Success Criteria** (what must be TRUE):

  1. 存在一份书面的「现状统计实现深研图」，以 `.planning/research/ARCHITECTURE.md` 的 reuse 图为种子，标明 13/15 可复用用例、`MonthlyReport` 已算字段、HomeHero 隔离与反毒性的结构性锁点（GATE-01）
  2. 产出 ≥3 套 HTML 设计方向，每套自带一张 ADR-012 自审表，把每个情感元素映射为 *ambient / 庆祝过去 (OK)* 还是 *目标 / 跨期对比 / 成就 (forbidden)*（GATE-02）
  3. 经充分讨论后，用户明确选定恰好一套方向；关卡出口 = 用户批准，且仓库中无新增 Dart/生产代码（GATE-03）
  4. 针对选定方向产出：新 ADR 的 go/no-go 决定（如 JOY-04 需持久化用户自撰反思文本，则加密/隐私含义触发新 ADR）、锁定供反毒性扫描使用的情感词表、以及每个图表 affordance 对当前 fl_chart 1.2.0 API 的逐项校验结果（GATE-04）

**Plans**: 7 plans in 4 waves

**Wave 1** (parallel — no file overlap)

- [x] 46-01-PLAN.md — within-month per-day-cumulative trend data path + DELETE 6-month MonthlyTrend/BarChart stack (D-E1/D-E2/D-A3)
- [x] 46-03-PLAN.md — docs: mark JOY-03/JOY-04 Descoped (superseded by GATE-03) + rewrite Phase 46 SC #3 to round-5 B 5-card lineup (D-A2)
- [x] 46-06-PLAN.md — REDES-02 histogram native label (delete Stack hack) + donut hero rebuild (10 L1 legend rows → drill push + count-up) + read-only CategoryDrillDownScreen (D-B1/B2/B3, DRILL-01 UI)

**Wave 2** *(46-02 blocked on 46-01 shared providers; 46-04 blocked on 46-01 trend provider — no mutual overlap)*

- [x] 46-02-PLAN.md — joy data paths: per-L1 joy AMOUNT (悦己花在哪) + per-day joy COUNT (小确幸日历), reuse-first over findByBookIds(joy) (D-C1/D-C2)
- [x] 46-04-PLAN.md — within-month cumulative LineChart widget + within_month_trend_card (pill tabs 总/日常/悦己; joy single-line zero cross-period) (D-E1)

**Wave 3** *(blocked on 46-02 joy providers)*

- [x] 46-05-PLAN.md — 悦己花在哪 stacked bar (R-1 custom) + 小确幸日历 heatmap (R-2 custom) cards, ambient + tap interactions + count-up header (D-C1/D-C2/D-D2)

**Wave 4** *(integration — blocked on all card plans)*

- [x] 46-07-PLAN.md — re-order registry to round-5 B flat 5-card lineup + delete dead cards + remove section headers + update registry/screen/anti-toxicity tests + full-suite gate (D-F1/D-F2, GUARD-01/02) — completed 2026-06-17 (suite 2971/2971)

**UI hint**: yes

### Phase 46: 卡片体系 (Cards)

**Goal**: 在 Phase 45 瘦外壳 + 卡片注册表契约就绪后，逐卡构建/迁移已批准的 **round-5 B** 设计（GATE-03 选定方向），全程反游戏化（ADR-012）。这是 v1.8「45 立机制 → 46 填内容 → 47 验视觉」的填充阶段。
**Depends on**: Phase 45
**Requirements**: OVW-02, JOY-01, JOY-02, REDES-02, REDES-03, GUARD-02 （JOY-03 / JOY-04 **Descoped — superseded by GATE-03 round-5 B**，见 REQUIREMENTS.md）
**Success Criteria** (what must be TRUE):

  1. 支出总览面（OVW-02）严守 ADR-012：当前窗口中性呈现，无跨期 delta、无评判措辞（复用 `GetMonthlyReportUseCase`，零新数据）
  2. 悦己情感面以 round-5 B 既定形态承载 JOY-01/JOY-02——「已花悦己」金额由悦己 tab + 悦己花在哪 header 描述性承载（ambient，**analytics 不画 target ring；HomeHero 独占唯一 target ring，ADR-016 §3/§4**，D-A4），满足度由直方图（分布 + 中位）呈现，分类悦己由悦己花在哪堆叠条呈现——celebrate-past，绝不目标/排名/跨期
  3. **卡片阵容忠于 round-5 B 实际 5 张卡（D-A1/D-A2，扁平叙事流，无分区头）：** ①支出趋势（top，pill tabs 总支出/日常/悦己；当月内按天累计 LineChart，支出侧本月+上月双线、悦己侧本月单线零跨期）→ ②支出分类圆环 hero donut（中心「本月支出」，10 个 L1 金额降序图例，整行 tap 下钻）→ ③悦己花在哪 横向堆叠分段条（R-1 自定义 Row+Flexible，悦己金额在 L1 严格子集间构成）→ ④小确幸日历热力（R-2 自定义 GridView，色深 = 当天悦己笔数，tap 某天 inline 展开）→ ⑤悦己满足度分布直方图（频次分布 + 中位）；其后追加 **group-mode 条件卡 `family_insight`**（`isVisible(ctx)`，GUARD-02 聚合面存续，D-F1）。悦己侧全为描述性「庆祝过去」（已花悦己金额 + 去向 + 满足度 + 日历纹理），ADR-012-safe，绝不排名/目标/跨期。**记忆故事（JOY-03）+ kakeibo Q4 反思（JOY-04）随 round-5 B drop，零加回——Descoped (superseded by GATE-03 round-5 B)，由 REQUIREMENTS.md 台账补正承载，不另建卡（D-A1/D-A2）**
  4. 图表 polish（REDES-02）：采用 fl_chart 1.2.0 原生 per-rod `label`（删除直方图 `Stack` hack）+ 可选 donut `cornerRadius`；**不升级/不换图表库（保持 `^1.2.0`）**
  5. 暖色入场动效（REDES-03）经 Flutter 内建实现（`TweenAnimationBuilder` count-up 落点仅 donut 中心总额 + 悦己花在哪 header 总额，`AnimatedSwitcher`），ADR-012-safe（ambient value-affirming，非 achievement-reward；克制微动，无循环/glow 脉冲/庆祝爆发，D-D1/D-D2）

**Plans**: 7 plans in 4 waves (see Wave 1–4 listing under the v1.8 Phases block above)
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

**Plans**: 6 plans in 4 waves

**Wave 1** (parallel — no file overlap; WR fixes before UAT, D-01)

- [x] 47-01-PLAN.md — WR-01 delete dead `currencyCode` plumbing + WR-02 donut true-total reconciliation (neutral "Other" rollup slice) + WR-04 calendar inline-list refresh consistency (registry/cards/drill/test)
- [x] 47-02-PLAN.md — WR-03 `GetJoyCategoryAmountsUseCase` single-pass accumulate + honest docstring (independent use-case file)

**Wave 2** (parallel — ARB-edit lane isolated from the test-author lane)

- [x] 47-03-PLAN.md — delete 3 orphan section-header ARB keys symmetric ×3 + `flutter gen-l10n` + `git add -f lib/generated/` (GUARD-03)
- [x] 47-04-PLAN.md — `anti_toxicity_phase47_test.dart` sweep: 5 round-5 B cards × ja/zh/en × all states (incl. WR-02 Other + calendar inline-expand), locked forbidden lists reused verbatim (GUARD-02 wording + GUARD-03)

**Wave 3** (golden authoring — after WR fixes + ARB clean + anti-toxicity gate)

- [x] 47-05-PLAN.md — 8 macOS golden test files (5 cards + family_insight + drill screen + full-page scroll-smoke) wrapping production AppTheme; ≈30+ baselines incl. Other-slice/inline-expand/group/empty states; count-up settled (GUARD-04)

**Wave 4** (full-suite gate + on-device UAT — blocking)

- [x] 47-06-PLAN.md — FULL `flutter test` per-wave gate (isolation + 3 anti-toxicity + architecture/CJK/density/logging-privacy) + analyze 0 + coverage ≥80%, then blocking on-device D-10 visual UAT (real iOS, locale=ja; D-12 no defer path) (GUARD-04, GUARD-05)

**UI hint**: yes

### Phase 48: Address v1.8 tech debt: member-filter donut refresh + stale trend comments

**Goal:** 清除 v1.8 里程碑审计记录的两项代码级技术债（`v1.8-MILESTONE-AUDIT.md` Tech Debt §1/§2），不引入任何新功能/新卡/新 provider/schema 迁移：**TD-1** — 把 donut 成员筛选 (`donutDimensionStateProvider.memberFilterDeviceId`) 穿过 `AnalyticsCardContext` → `buildAnalyticsCardContext` → `categoryDonutRefreshTargets`，使成员筛选状态下的 pull-to-refresh 真正失效 `memberFilteredCategoryBreakdownProvider`（今天服务陈旧缓存数据），并把该家族加入 registry-test 白名单 + 新增「并集 ⊇ 卡片活动监听」完整性断言防回归；**TD-2** — 清除 `repository_providers.dart` 残留 dartdoc 对已移除的 `getExpenseTrendUseCase`/`MonthlyTrend` 符号的命名（build_runner regen `.g.dart` 三处镜像）+ 更新一处字符化测试描述串。验收：`grep -rn "getExpenseTrend\|MonthlyTrend" lib/ test/` 返回 0。
**Requirements**: none mapped (REQUIREMENTS.md has no REQ-IDs for Phase 48; decision coverage tracked via CONTEXT.md D-01..D-04)
**Depends on:** Phase 47
**Plans:** 2 plans in 1 wave

**Wave 1** (parallel — disjoint file sets; 48-01 TD-1 code/test, 48-02 TD-2 doc-hygiene)

- [x] 48-01-PLAN.md — TD-1: thread donut member filter through `AnalyticsCardContext` → `categoryDonutRefreshTargets` (D-01) + registry-test whitelist `MemberFilteredCategoryBreakdownProvider` (D-02) + completeness regression assertion (D-03) — DONE (3/3 tasks; analyze 0, registry test 9/9, 0 golden)
- [x] 48-02-PLAN.md — TD-2: scrub removed-symbol dartdoc in `repository_providers.dart` + regen `.g.dart` (D-04) + update characterization test description; `grep -rn "getExpenseTrend\|MonthlyTrend" lib/ test/` = 0 — DONE (2/2 tasks; analyze 0, char test 3/3, 0 golden; .g.dart regenerated via build_runner, only 3 dartdoc mirror lines changed)

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
| v1.8 统计页面重设计 | 43-48 | P43-47 all plans done (Phase 47: 6/6); Phase 48: 2/2 done (48-01 ✓ 48-02 ✓) | In progress | - |
