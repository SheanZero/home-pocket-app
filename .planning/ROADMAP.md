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
- ✅ **v1.8 统计页面重设计（实用化 × 悦己情感化）** — Phases 43-48 (shipped 2026-06-22) — see [archive](milestones/v1.8-ROADMAP.md)
- ✅ **v1.9 语音类目与商家识别系统重构（解耦 · 交叉验证 · 日本商家库）** — Phases 49-52 (shipped 2026-06-25) — see [archive](milestones/v1.9-ROADMAP.md)
- 🚧 **v2.0 完成第一版上线前最后的功能开发** — Phases 53-56 (in progress, started 2026-06-28)

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

**Outcome:** Brownfield consistency refactor — unified 日常/悦己 vocabulary + `AppPalette` ThemeExtension (ADR-019 "Sakura Mochi × Wakaba" supersedes ADR-018). Audit `tech_debt` accepted at close — 15/15 requirements, 5/5 phases, 6/6 cross-phase integration seams wired. Full details: `.planning/milestones/v1.5-ROADMAP.md` + `.planning/milestones/v1.5-MILESTONE-AUDIT.md`.

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

<details>
<summary>✅ v1.8 统计页面重设计（实用化 × 悦己情感化） (Phases 43-48) — SHIPPED 2026-06-22</summary>

**Milestone Goal:** 把统计页面从「指标罗列」全面重设计为「更实用（支出总览 / 支出趋势 / 分类下钻）+ 凸显悦己、让用户为自己花钱而感到开心」的体验——在 ADR-012 反游戏化恒久约束内，先经一个硬性「HTML 设计探索关卡」选定方向再开发。展示层重建（数据已存在，最大化复用 5 层架构）。

- [x] Phase 43: HTML 设计探索关卡 (Design Gate — NO production code) (7/7 plans) — completed 2026-06-16
- [x] Phase 44: 数据与用例补全 (Data / Use-Case Additions — reuse-first) (3/3 plans) — completed 2026-06-16
- [x] Phase 45: 展示外壳重建 (Presentation Shell Rebuild) (7/7 plans) — completed 2026-06-17
- [x] Phase 46: 卡片体系 (Cards — round-5 B 5-card lineup) (7/7 plans) — completed 2026-06-17
- [x] Phase 47: i18n + 反毒性扫描 + macOS golden 重基线 + 全量门禁 + UAT (6/6 plans) — completed 2026-06-20
- [x] Phase 48: v1.8 收尾技术债 (Tech-Debt Cleanup) (2/2 plans) — completed 2026-06-22

**Outcome:** 统计页全面重设计——设计关卡先行（Phase 43 HTML 探索 → 用户选定 round-5 B）、复用优先构建（域纯 L1-rollup + 当月累计趋势 + 只读分类下钻，全经 `findByBookIds`，零新 DAO/迁移）、注册表驱动瘦外壳（`analytics_screen.dart` 739→176 LOC，HomeHero 隔离由结构保证）、round-5 B 扁平 5 卡阵容（当月趋势 / 分类圆环带下钻 / 悦己花在哪堆叠条 / 小确幸日历热力 / 满足度直方图 + group-mode `family_insight`）、fl_chart 1.2.0 原生 label（删 Stack hack）。schema 仍 v21、fl_chart 仍 ^1.2.0、零新依赖。Audit `tech_debt` accepted — 18/18 requirements satisfied + 2 descoped at GATE (JOY-03/04)、5/5 phases、9/9 integration flows、10/10 on-device UAT；两项代码级 TD 由 Phase 48 内联清除，residual documentation-grade。Suite 3090/3090 green. Full details: `.planning/milestones/v1.8-ROADMAP.md` + `.planning/milestones/v1.8-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.9 语音类目与商家识别系统重构（解耦 · 交叉验证 · 日本商家库） (Phases 49-52) — SHIPPED 2026-06-25</summary>

**Milestone Goal:** 把语音记账的「类目识别」与「商家识别」拆成两个独立、可相互验证的引擎，构建 ~400 家日本商家库（schema 预留 600-800 上限），并补齐中日英三语语音输入体验——让用户用一句话（中/日/英）就能把一笔花费稳准地记成「正确的类目 + 正确的账本（日常/悦己）」。

- [x] Phase 49: Merchant Data Foundation (6/6 plans) — completed 2026-06-23
- [x] Phase 50: Decoupled Recognizers (5/5 plans) — completed 2026-06-24
- [x] Phase 51: Cross-Validation + Daily/Joy Ledger Rework (5/5 plans) — completed 2026-06-24
- [x] Phase 52: Recognition UX + English Voice (6/6 plans) — completed 2026-06-24

**Outcome:** 语音管线分层解耦 + 仲裁插入（非重写）：拆出互不调用的 `MerchantRecognizer` 与 `CategoryRecognizer`，插入纯领域 `RecognitionReconciler`（none/weak/strong 3×3 真值表——关键词胜冲突、商家兜底、双弱询问），ledger 重做成最终类目的纯函数（删商家短路 + 退役 `lib/application/dual_ledger/`），商家库从 13 条硬编码迁入持久化加密 Drift 表（391 家日本商家，schema v21→v22），并补齐英文语音实用对齐。录入表单展示定性 3 档置信度带 + 备选 chips + 内联纠错（仅教 KEYWORD 表、绝不污染商家表），全程 ADR-012-safe。Audit `tech_debt` accepted — 20/20 requirements、4/4 phases verified（49:5/5·50:4/4·51:14/14·52:7/7）、5/5 seams、4/4 E2E flows；T-01/T-02 收口前解决（识别置信度带重新启用），residual documentation/confirm-only。Suite 3352/3353 green、analyze 0、drift 2.31.0、no new heavy deps。Full details: `.planning/milestones/v1.9-ROADMAP.md` + `.planning/milestones/v1.9-MILESTONE-AUDIT.md`.

</details>

## 🚧 Active Milestone: v2.0 完成第一版上线前最后的功能开发 (Phases 53-56)

**Milestone Goal:** 在首次公开上线（面向日本市场）前补齐欢迎引导、应用锁、合规/赞助三块「上线必备」能力，使 app 可发布。这是一个**整合里程碑**（几乎全部能力已存在，唯一新运行时依赖 `url_launcher`）：两道新 gate 挂在 `lib/main.dart` `HomePocketApp._buildHome()` 既有同步 gate ladder（`AppInitializer` settle 之后判定）。先用 Claude design 出 HTML 设计稿、用户确认后严格按稿实现（沿用 v1.8 Phase 43 设计关卡模式，关卡未过不写生产代码）。复用既有 i18n / 多币种 / 语音 locale / 安全基础设施。

**Phase summary:**

- [x] **Phase 53: HTML 设计关卡（零生产代码）** — 欢迎引导 / 应用锁屏 / Setting 法务·赞助三块 HTML 设计稿，经用户确认；零生产 Dart (completed 2026-06-29)
- [x] **Phase 54: 欢迎 / 首启引导（Onboarding gate）** — init-settle 后的首启 gate + UI语言/币种/语音语言强制写穿 + 末尾可跳过的锁配置入口 (completed 2026-06-29)
- [x] **Phase 55: 应用锁（生物识别 + PIN，最高风险）** — 冷启动+回前台完整重锁 + 切换器隐私遮罩 + 4位PIN加盐慢哈希兜底；独立安全评审 (completed 2026-06-30)
- [ ] **Phase 56: Setting 法务 + 赞助 + 日本合规（上线关卡）** — 隐私政策/利用規約/OSS/特商法 + 外链赞助；为真实 store-review round-trip 留余量

### Phase 53: HTML 设计关卡（零生产代码）

**Goal**: 产出并经用户确认欢迎引导、应用锁屏、Setting 法务/赞助三块的 HTML 设计稿；关卡未获批前不写对应生产 Dart 代码（沿用 v1.8 Phase 43 precedent，产物仅 `.planning/` 下 HTML/Markdown）。
**Depends on**: Nothing（里程碑首个 phase；零生产代码，可早/并行启动）
**Requirements**: DESIGN-01, DESIGN-02, DESIGN-03, DESIGN-04
**Success Criteria** (what must be TRUE):

  1. 用户已审阅并批准欢迎/首启引导流程的 HTML 设计稿（含 app 介绍 + UI语言/币种/语音语言三步设置）— DESIGN-01
  2. 用户已审阅并批准应用锁屏（生物识别提示 + PIN 输入）的 HTML 设计稿 — DESIGN-02
  3. 用户已审阅并批准 Setting 法务/赞助区块布局的 HTML 设计稿 — DESIGN-03
  4. 关卡退出时仓库零新增生产 Dart——所有关卡产物仅在 `.planning/` 下的 HTML/Markdown — DESIGN-04

**Plans**: 4/4 plans complete
**Wave 1**

- [x] 53-01-PLAN.md — onboarding (001/A) QA against DESIGN-01 + approval-ready summary [wave 1]
- [x] 53-02-PLAN.md — app-lock (002/B light+dark) QA against DESIGN-02 + approval-ready summary [wave 1]
- [x] 53-03-PLAN.md — Settings legal/sponsor (003/C) QA against DESIGN-03 + approval-ready summary [wave 1]

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 53-04-PLAN.md — gate closure: user approval of all three + Phase 54/55/56 handoff + DESIGN-04 zero-Dart gate-exit [wave 2]

**Cross-cutting constraints:**

- git diff --name-only shows only .planning/ paths (.md/.html/.css) — zero .dart/pubspec/lib/test/ARB changes (DESIGN-04 gate-exit)

### Phase 54: 欢迎 / 首启引导（Onboarding flow）

**Goal**: 在 `AppInitializer` settle 之后、主 shell 之前插入首启引导 gate（`_buildHome()` branch 3），用户一次性确认 UI 语言 / 记账币种 / 语音输入语言并写穿既有 provider，引导末尾提供可明确跳过的「设置应用锁」入口；`onboarding_complete` 仅在显式完成时一次性落最后。
**Depends on**: Phase 53（设计稿批准后才实现）
**Requirements**: ONBOARD-01, ONBOARD-02, ONBOARD-03, ONBOARD-04, ONBOARD-05, ONBOARD-06, ONBOARD-07
**Success Criteria** (what must be TRUE):

  1. 全新安装首次启动展示引导；完成后再次启动直接进入主 shell、引导不再出现（幂等；gate 在 init settle 后判定，绝不与 init 竞态、绝不从 currency≠null 反推）— ONBOARD-01/07
  2. 用户在引导内看到 app 整体介绍（隐私 / 本地优先 / 双账本卖点），介绍部分可跳过 — ONBOARD-02
  3. 用户确认 UI 语言后 MaterialApp 即时切换；确认记账币种（JPY 默认）写入既有 `Book.currency`（复用 v1.7 货币选择器）；确认语音输入语言（默认=所选 UI 语言）写入既有语音 locale 设置 — ONBOARD-03/04/05
  4. 引导可返回上一步、无法卡死（re-entrant）（进度仅靠返回键/手势体现、无显式进度条 — D-12 有意取舍，supersedes 早先「显示进度」措辞）；末尾「设置应用锁」入口可明确跳过，跳过后锁保持关闭 — ONBOARD-06/07
  5. 所有新增引导文案三语（ja/zh/en）ARB 齐全，过 parity + 硬编码CJK扫描

**Plans**: 7/7 plans complete
**UI hint**: yes

**Wave 1** *(parallel — independent foundation, zero file overlap)*

- [x] 54-01-PLAN.md — persisted `onboardingComplete` flag (SharedPreferences, no Drift migration) + pure device-preselect/voice-default resolution helpers [wave 1]
- [x] 54-02-PLAN.md — onboarding ARB copy ja/zh/en (single owner) incl. `この設定で始める` + gen-l10n [wave 1]
- [x] 54-03-PLAN.md — Settings deep-link target: `scrollToSecurity` + SecuritySection anchor (D-13) [wave 1]

**Wave 2** *(parallel — depends on Wave 1)*

- [x] 54-04-PLAN.md — data-reset semantics: import forces flag true (D-06); clear resets flag + wipes UserProfile (D-05) [wave 2]
- [x] 54-05-PLAN.md — merged onboarding settings page: identity (nickname[req]/avatar) + UI-lang/currency/voice write-through, 行+変更 rows (D-01/03/07/08/09/10/14) [wave 2]
- [x] 54-06-PLAN.md — intro (skippable selling points, D-02) + trailing lock-entry screen (D-11/D-13) [wave 2]

**Wave 3** *(depends on Wave 2 screens)*

- [x] 54-07-PLAN.md — OnboardingFlowScreen nested-Navigator host (re-entrant, D-12) + main.dart captured-after-init gate + retire ProfileOnboardingScreen gate (D-01) [wave 3]

### Phase 55: 应用锁（生物识别 + PIN — 最高风险，独立 phase + 安全评审）

**Goal**: 实现「已解密 DB 之上的 UI gate」应用锁：冷启动 + 回前台（`paused`→`resumed`）完整重锁、任务切换器隐私遮罩（`inactive` 盖遮罩层）、生物识别优先 + 4 位 PIN 强制兜底；PIN 以加盐慢哈希存入既有 secure storage（accessibility 保持 unlocked_this_device 不变）；完整 `local_auth` 错误分类一律回退 PIN；Setting 可开关、关闭时完全 no-op。
**Depends on**: Phase 54（引导末尾的「设置应用锁」入口需先存在）
**Requirements**: LOCK-01, LOCK-02, LOCK-03, LOCK-04, LOCK-05, LOCK-06, LOCK-07, LOCK-08, LOCK-09, LOCK-10
**Success Criteria** (what must be TRUE):

  1. 用户可在 Setting 开启/关闭应用锁；开启必须先设 4 位 PIN（强制兜底凭据）；关闭时锁逻辑完全 no-op — LOCK-01/06
  2. 启用后冷启动与从后台回前台均需重新解锁才进入主 shell；任务切换器/后台快照显示隐私遮罩不泄露账目（重锁在 `paused`→`resumed`、遮罩在 `inactive`）— LOCK-02/03/04
  3. 解锁默认先自动尝试生物识别，失败/不可用回退 PIN；完整 `local_auth` 错误分类（notAvailable/notEnrolled/lockedOut/permanentlyLockedOut/passcodeNotSet/cancel）一律回退 PIN，绝不把用户锁在自己数据外 — LOCK-05/10
  4. PIN 加盐慢哈希（≥100k 迭代或 Argon2id，跑主 isolate 外）存入既有 secure storage（`StorageKeys.pinHash`，accessibility 不变）、常量时间比对、绝不明文、无默认数据擦除 — LOCK-07。~~连续输错有递增冷却（持久化计数，成功才清零）~~ **DESCOPED per D-06**（MVP 零速率限制，用户知情接受风险；见 `55-RESEARCH.md §Security Domain` Known Accepted Risk sign-off）→ 移入 v2 **LOCK-V2-04**；PIN 输错仅抖动+清空、可立即重试，无失败计数器
  5. 锁屏文案明确告知忘记 PIN 无法找回（需重装且丢失未同步本地数据）、不暗示存在恢复路径；新增锁屏文案三语 ARB 齐全过 parity + 硬编码CJK扫描 — LOCK-09

**Plans**: 12/12 plans complete (gap-closure 55-12: G2+G3+G4 verified on-device 2026-07-01)
**Wave 1**

- [x] 55-01-PLAN.md — PIN KDF: Argon2id off-isolate + PHC + constant-time [LOCK-07] (wave 1)
- [x] 55-02-PLAN.md — Biometric error-model rewrite for local_auth 3.x LocalAuthException [LOCK-05/10] (wave 1)
- [x] 55-03-PLAN.md — AppSettings appLockEnabled/biometricUnlockEnabled + retire legacy flag (D-02) [LOCK-01/06] (wave 1)
- [x] 55-04-PLAN.md — ARB i18n foundation: lock/PIN/forgot-PIN/SecuritySection keys (ja/zh/en) [LOCK-09] (wave 1)
- [x] 55-05-PLAN.md — LOCK-08 descope ledger: REQUIREMENTS→LOCK-V2-04 + ROADMAP SC-4 annotation [LOCK-08] (wave 1)
- [x] 55-06-PLAN.md — Lifecycle observer: relock + mask two-flag guard [LOCK-03/04] (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 55-07-PLAN.md — AppLockService: lockEffective predicate + setPin/verifyPin/reauth/disable [LOCK-01/06] (wave 2)
- [x] 55-08-PLAN.md — Lock widgets (tone B): PinKeypad/PinDots/FaceIdPanel/PrivacyMask [LOCK-04/06] (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 55-09-PLAN.md — AppLockScreen: Face ID page + PIN page, instant verify, escape [LOCK-05/06] (wave 3)
- [x] 55-10-PLAN.md — SecuritySection D-11 refactor + set-PIN double-entry + reauth + deep-link [LOCK-01/06] (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 55-11-PLAN.md — main.dart gate branch + observer + opaque mask host + device QA [LOCK-01/02/03/04] (wave 4)

**Gap closure** *(from 55-UAT.md — G2/G3/G4, verified on-device 2026-07-01)*

- [x] 55-12-PLAN.md — app-lock hardening: biometric-only (device passcode never accepted, G2) + NSFaceIDUsageDescription (Face ID TCC crash, G3) + honor biometricUnlockEnabled (biometric-off → PIN-only, G4) [LOCK-05/06/07/10] (wave 1)

**UI hint**: yes
**Research flag**: 最高风险整合（keychain accessibility 砖机风险 / 应用生命周期 / 生物识别错误分类 / off-isolate KDF 调优）——规划时做一次专项安全评审（`gsd-secure-phase` 或 `--research-phase`）。

### Phase 56: Setting 法务 + 赞助 + 日本合规（上线关卡）

**Goal**: 在 Setting 补齐日本市场上线必备的合规与赞助：隐私政策 / 利用規約（app 内置三语文本离线可读 + 托管 URL 占位）、OSS 许可证（Flutter 内置 `showLicensePage` 自动聚合）、特商法表記页，以及一个不打扰、中性非交易性的外链赞助入口（`url_launcher` 外部浏览器到日本赞助平台，绝不 WebView/IAP）；对齐商店隐私表单；为真实 store-review round-trip 预留余量。
**Depends on**: Phase 54（Setting 承载面）——与 Phase 55 相互独立、可并行；排在最后但尽早调度外部评审
**Requirements**: DONATE-01, DONATE-02, DONATE-03, DONATE-04, LEGAL-01, LEGAL-02, LEGAL-03, LEGAL-04, LEGAL-05, LEGAL-06
**Success Criteria** (what must be TRUE):

  1. 用户可在 Setting 离线阅读隐私政策（プライバシーポリシー）与利用規約（内置三语文本 + 托管 URL 占位），并查看 OSS 开源许可证页（`showLicensePage` 自动聚合，不手维护清单）— LEGAL-01/02/03
  2. 用户可在 Setting 看到「特定商取引法に基づく表記」页（运营者信息，参考 napu.co.jp/sale 表記结构，三语承载，细节上线前由日本法务确认）— LEGAL-04
  3. Setting 内有一个不打扰、中性非交易性措辞的「応援/支援」入口；点击经外部浏览器（`LaunchMode.externalApplication`）打开日本赞助平台（FANBOX/OFUSE）链接，绝不内嵌 WebView / IAP / 反复弹窗；URL 可配置（需求阶段留占位）— DONATE-01/02/03/04
  4. 商店隐私表单（Apple Privacy Nutrition Labels / Google Data Safety）如实填写，与 v1.7 汇率出站网络调用一致（非反射式「不收集」）— LEGAL-05
  5. 所有新增法务/合规/赞助文案三语（ja/zh/en）覆盖，过 ARB parity + 硬编码CJK扫描（长文本用 bundled per-locale assets 时附「三语齐全」存在性门）— LEGAL-06

**Plans**: 6 plans
- [ ] 56-01-PLAN.md — url_launcher dep + assets/legal/ decl + LegalUrls config + asset-parity gate (DONATE-04, LEGAL-06)
- [ ] 56-02-PLAN.md — trilingual legal drafts: privacy / terms / 特商法 (請求時提供 型) (LEGAL-01/02/04/06)
- [ ] 56-03-PLAN.md — ARB short labels (ja/zh/en) + gen-l10n (LEGAL-06)
- [ ] 56-04-PLAN.md — LegalDocScreen per-locale asset reader (rootBundle, V12 whitelist) (LEGAL-01/02/04)
- [ ] 56-05-PLAN.md — LegalSponsorSection (5 rows, external sponsor launch) + AboutSection slim (DONATE-01/02/03, LEGAL-03)
- [ ] 56-06-PLAN.md — Settings wiring + store-privacy-form checklist (LEGAL-05, LEGAL-06)
**UI hint**: yes
**Research flag**: MEDIUM-confidence 外部合规——特商法 applicability（个人开发者外部平台赞助）+ Apple/Google donation-review 立场需 JP-legal sign-off + 真实 TestFlight/internal-track 提交（非自评）；调度时为 review round-trip 留余量。

---

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
| v1.8 统计页面重设计 | 43-48 | 32/32 | Complete | 2026-06-22 |
| v1.9 语音类目与商家识别系统重构 | 49-52 | 22/22 | Complete | 2026-06-25 |
| v2.0 完成第一版上线前最后的功能开发 | 53-56 | 23/TBD (P53-55 done; P56 unplanned) | In progress | - |
