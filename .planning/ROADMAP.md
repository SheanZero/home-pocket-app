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
- 🚧 **v1.9 语音类目与商家识别系统重构（解耦 · 交叉验证 · 日本商家库）** — Phases 49-52 (planning) — current milestone

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

---

## 🚧 Current Milestone: v1.9 语音类目与商家识别系统重构（解耦 · 交叉验证 · 日本商家库）

**Milestone Goal:** 把语音记账的「类目识别」与「商家识别」拆成两个独立、可相互验证的引擎，构建 ~400 家日本商家库（schema 预留 600-800 上限），并补齐中日英三语语音输入体验。让用户用一句话（中/日/英）就能把一笔花费稳准地记成「正确的类目 + 正确的账本（日常/悦己）」。

**Granularity:** fine · **Phase numbering:** continues from v1.8's Phase 48 → v1.9 starts at **Phase 49** (NO reset). **Schema:** v21→v22 (Phase 49 only) · **No new heavy deps** (drift stays 2.31.0, no FTS5; optional `kana_kit` only).

**Structure:** 4 phases (49-52). This is the user-directed **6→4 merge** of an earlier dependency-forced 6-phase decomposition. The two logic-pair merges fold contracts that turn out to be **the same code surgery**: Phase 51 combines cross-validation (the old Phase 51, XVAL) with the daily/joy ledger rework (the old Phase 52, LEDGER) — both delete the merchant short-circuit / ledger-from-merchant branch at `parse_voice_input_use_case.dart:106`; Phase 52 combines recognition UX (the old Phase 53, RECUX) with English voice parity (the old Phase 54, VEN) — both touch `TransactionDetailsForm` and share the trilingual ARB-parity + anti-toxicity-sweep + golden-rebaseline close-out that the 6-phase version already ran inline across 53-54. **The two merged phases (51, 52) each carry MORE plans/waves than a single-concern phase** — wave structure inside the phase preserves the original internal dependency ordering (in Phase 51, the reconciler/XVAL work lands before the LEDGER invariant that reads the single post-reconciliation ledger site; in Phase 52, the RECUX surface lands before/with VEN coverage). Phases 49 (Merchant Data) and 50 (Decoupled Recognizers) are unchanged from the 6-phase version.

v1.9 是一次**分层解耦 + 仲裁插入**，不是重写。现有语音管线已有正确骨架（`ParseVoiceInputUseCase` 协调器、类目解析器、商家查找、两张学习表、DB 支撑的 ledger 解析器），缺的是**独立性**（商家匹配嵌在 `VoiceTextParser` 且短路类目解析器）与**仲裁**（无处让两路独立裁决相互校验）。本里程碑把管线拆成两个互不调用的纯 Dart 引擎——`MerchantRecognizer` 与 `CategoryRecognizer`——并插入纯领域 `RecognitionReconciler` 仲裁两者，由真实日本商家 Drift 库支撑。依赖强制顺序：数据先于逻辑 → 解耦引擎 →（交叉验证 + 账本重做合并）→（识别 UX + 英文/覆盖合并）。

- [ ] **Phase 49: Merchant Data Foundation** — 商家目录从 13 条硬编码迁移到 Drift `merchants` 表（v21→v22），seed ~400 家日本商家 + region/多语店名/归一化 match-key
- [ ] **Phase 50: Decoupled Recognizers** — 拆出互不调用的 `MerchantRecognizer`（锚定/归一化匹配）与 `CategoryRecognizer`（无条件运行，category-only 路径）
- [ ] **Phase 51: Cross-Validation + Daily/Joy Ledger Rework** — 纯领域 `RecognitionReconciler` 经 3×3 真值表仲裁两路裁决（删除商家短路，resolve-on-final + hysteresis），**同一处手术**把 ledger 重做成最终类目的纯函数、重 seed `category_ledger_configs`、退役死的 `RuleEngine`/`ClassificationService`（合并 XVAL + LEDGER，多 plan/wave）
- [ ] **Phase 52: Recognition UX + English Voice** — 录入表单展示 3 档定性置信度带 + 备选 chips + 内联纠错回流学习表，ADR-012-safe；**同屏**补英文关键词/别名/货币词 + 有界英文数字词兜底 + `localeId` 端到端；ARB parity + anti-toxicity-sweep + golden-rebaseline 内联收尾（合并 RECUX + VEN，多 plan/wave）

### Phase 49: Merchant Data Foundation

**Goal**: 商家目录从 13 条硬编码 in-memory 列表迁移到一张持久、加索引、可幂等重 seed 的 Drift `merchants` 表，为所有读商家的组件提供数据底座——无行为变化，安全先落地。
**Depends on**: Nothing (first phase of v1.9; builds on v1.8's schema v21)
**Requirements**: MERCH-01, MERCH-02, MERCH-03, MERCH-04, MERCH-05
**Success Criteria** (what must be TRUE):

  1. 全新安装与从旧版本升级两条路径下，`merchants` 表都装载 ~400 家日本商家（覆盖每个日常类目的全国连锁头部：便利店/超市/牛丼·拉面/咖啡/ファミレス/药妆/百元店/家电/服饰/交通IC/加油/外卖/订阅 + 东京·大阪重点），每行 `categoryId` 都解析为 `default_categories.dart` 中真实的 L2 类目（seed-categoryId-is-real-L2 集成测试通过，杜绝 D-04「不存在 L1 → 静默 null」类 bug）。
  2. `PRAGMA index_list(merchants)` 在 fresh-install DB 与 migrated DB 上都返回非空（归一化 match-key + region/category 索引经 onCreate 与 onUpgrade 两处显式 `CREATE INDEX IF NOT EXISTS` 建立——验证 `customIndices` 装饰性陷阱已规避）。
  3. 重复运行 seed（双启动 / 版本升级再 seed）收敛而非翻倍——稳定字符串 id + `INSERT OR IGNORE`/upsert + 单事务批量插入，重启后商家行数不变。
  4. 完整迁移阶梯（v3→v22、v17→v22、v21→v22、fresh v22）在带 SQLCipher key 的加密 executor 路径下验证通过（不仅 `NativeDatabase.memory()`），匹配真实升级。
  5. schema 含 `region`（默认 JP）+ 多语店名变体 + aliases + 种子期计算的归一化 match-key + L2 `categoryId` + 非权威 ledger 提示，按 600-800 上限设计，可被未来中国/其他地区扩展与 MOD-005 OCR 复用；商家名作为数据存于 Drift 多语列、不进 ARB。

**Plans**: 6 plans (waves 1-4)
**Wave 1**

- [ ] 49-01-PLAN.md — Schema: merchants + merchant_match_keys tables, v22 migration, explicit indexes (onCreate+onUpgrade), migration unit test [wave 1]
- [ ] 49-02-PLAN.md — MerchantNameNormalizer (NFKC-lite + kana fold, zero-dep) + property-style test [wave 1]
- [ ] 49-03-PLAN.md — DefaultMerchants ~400 const list + deriveLedgerHint + categoryId-∈-L2 hard gate + ledger parity test [wave 1]

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 49-04-PLAN.md — Merchant domain model + MerchantRepository interface/impl + MerchantDao + provider [wave 2]

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 49-05-PLAN.md — SeedMerchantsUseCase (count-guarded, idempotent) + SeedAllUseCase third-leaf wiring + seed tests [wave 3]

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 49-06-PLAN.md — integration_test/ encrypted migration ladder (cipher_version asserted) + human-verify checkpoint [wave 4]

### Phase 50: Decoupled Recognizers

**Goal**: 把商家识别与类目识别拆成两个互不调用的纯 Dart 引擎；商家命中不再直接决定类目，类目引擎无条件运行——这是里程碑解耦前提的落地。
**Depends on**: Phase 49 (`MerchantRepository`)
**Requirements**: DECOUP-01, DECOUP-02, DECOUP-03
**Success Criteria** (what must be TRUE):

  1. `CategoryRecognizer` 与 `MerchantRecognizer` 互不调用（构造上独立、各自可单测）；`VoiceCategoryResolver` 的「商家优先短路关键词」逻辑被移除——四象限测试中 (merchant✓ keyword✓) 用例同时产出两路引擎输出，不再短路。
  2. `MerchantRecognizer` 用锚定/归一化匹配（NFKC + 片↔平假名折叠 + 全角/小写、按字种最小别名长度），返回带分数的排序候选——不再用双向子串（`query.contains||contains(query)`）；`merchant_false_positive_test.dart` 对抗语料（お米/杉並区/comment-words 等 ~40 条）断言无误命中或低分。
  3. 单说「スタバ」（及半角假名 ｽﾀﾊﾞ、Kansai 缩写 マクド、romaji Starbucks）独立解析为星巴克 → 咖啡（其默认类目为弱信号、ledger 为提示，均非权威）——JP 名变体覆盖测试各 surface 形态命中。
  4. `CategoryRecognizer` 无条件运行：即使无商家也能从活动/物品关键词解析出 L2 类目——「加油用了400块」→ 燃料/交通 L2（Case B，merchant✗-keyword✓ 象限通过）。

**Plans**: TBD

### Phase 51: Cross-Validation + Daily/Joy Ledger Rework

**Goal**: 插入纯领域 `RecognitionReconciler` 经显式 none/weak/strong 3×3 真值表合并两路裁决，**在同一处删除商家短路与 ledger-from-merchant 分支**——交叉验证（旧 Phase 51）与账本重做（旧 Phase 52）合并，因为它们是同一段代码手术：都删掉 `parse_voice_input_use_case.dart:106` 的「商家短路 / ledger-from-merchant」分支。仲裁先落地、确立唯一 post-reconciliation `resolveLedgerType` 站点，再让 ledger 退化为该站点读取的纯函数。**本阶段多 plan/wave**；wave 顺序保留内部依赖：先 reconciler/XVAL，后读单一 ledger 站点的 LEDGER 不变量。
**Depends on**: Phase 50 (both verdict shapes — reconciler is a pure function of two verdicts)
**Requirements**: XVAL-01, XVAL-02, XVAL-03, LEDGER-01, LEDGER-02
**Success Criteria** (what must be TRUE):

  1. （XVAL，wave 1）`RecognitionReconciler` 为纯领域服务（零 I/O），经显式 3×3 真值表合并：一致 → 升置信度（agreement 在 L1/ledger 粒度定义）；强关键词-强商家冲突 → 关键词胜，商家降为备选 chip；无关键词 → 商家兜底；双弱 → 询问用户（低置信度 + 备选，绝不自动高置信度盖章）——`cross_validation_test.dart` 把真值表逐 cell 作为测试 spec（含 bare-merchant、weak-keyword-不否决-strong-merchant、both-weak 四类边界）。
  2. （XVAL，wave 1）Case A「在星巴克买了个杯子」解析为 购物（关键词意图胜），而非商家默认的咖啡；裸「スタバ」仍解析为星巴克→咖啡（关键词 null 不胜）。
  3. （XVAL，wave 1）识别在 STT **最终结果**上裁定并加滞后（hysteresis）——展示 partial 仅作原始文本、提交一次类目猜测；复用 v1.3 `VoiceChunkMerger` 2.5s 窗口作为「足够稳定可裁定」边界，类目 chip 不随中间 partial 抖动/重排。
  4. （LEDGER，wave 2）语音条目的 ledger 是 `resolveLedgerType(finalCategoryId)` 的纯函数——商家 `ledgerType` 短路（`parse_voice_input_use_case.dart:106`）被删除（与 wave-1 reconciler 落地为同一处手术）；每条解析路径有 `ledgerType == resolveLedgerType(finalCategoryId)` 不变量测试，无路径盖一个与自身类目矛盾的账本（星巴克买杯子 → 购物/悦己，而非咖啡/日常）。
  5. （LEDGER，wave 2）`category_ledger_configs` 重新 seed/扩展，覆盖全部 19 L1 + 有意义的 L2 都有正确 日常/悦己 默认（在 v1.5 `LedgerType { daily, joy }` 词汇下）——不再有新可达 L2 返回 null 静默回退。
  6. （LEDGER，wave 2）死的 `RuleEngine`/`ClassificationService` 桩被退役（先 grep 确认无消费者——OCR MOD-005?/测试?；若有则折叠进 config seed 而非删除），代码中不再存在第二套发散的硬编码 日常/悦己 映射。

**Plans**: TBD

### Phase 52: Recognition UX + English Voice

**Goal**: 在录入表单展示定性置信度 + 可点备选 chips + 内联纠错（回流 KEYWORD 学习表、绝不污染商家表），**同屏**把中日英三语语音输入体验对齐（英文从英文关键词/别名/货币词识别、英文 STT 数字金额正确解析、`localeId` 端到端）——识别 UX（旧 Phase 53）与英文语音（旧 Phase 54）合并，因为两者都触 `TransactionDetailsForm` 且共享 ARB-parity + anti-toxicity-sweep + golden-rebaseline 三语收尾。**本阶段多 plan/wave**；wave 顺序保留内部依赖：先 RECUX 识别面（置信度/chips/纠错），再/同时 VEN 英文覆盖；ARB parity + 反毒性扫描 + golden 重基线作为合并前内联门禁（不延到里程碑 close，per v1.7/v1.8 lessons）。
**Depends on**: Phase 51 (`RecognitionOutcome` contract); Phase 49 (alias columns), Phase 50 (recognizers)
**Requirements**: RECUX-01, RECUX-02, RECUX-03, RECUX-04, RECUX-05, VEN-01, VEN-02
**Success Criteria** (what must be TRUE):

  1. （RECUX，wave 1）语音识别后，录入表单展示选定类目 + 3 档**定性**置信度带（绝不显示数字 %/分数/gauge/meter），置信度仅驱动排序与是否自动选中；低置信度时显示可点的备选 chips（备选类目 + 商家默认类目）让用户一键纠正。
  2. （RECUX，wave 1）对关键词-商家冲突的内联纠错教 KEYWORD 表（`category_keyword_preferences`），绝不污染 `merchant_category_preferences`；`resolvedKeyword` 写键 == 读键身份端到端成立（防 260526-pg6 orphan-key 回归，写键即 recognizer 查找的同一规范键）。
  3. （RECUX + VEN 共享，wave 2）识别 UX 不引入任何游戏化（无准确率分数/连胜/徽章/排行/「教了 N 次」框架）——扩展反毒性扫描覆盖新界面（chips/纠错 sheet/置信度 affordance）× ja/zh/en × 全状态，禁词表完整含 score/streak/accuracy/正确率/連続/ストリーク/達成；商家名是数据（存 Drift 多语列、不进 ARB），类目标签是 ARB，所有新增 UI 文案三语 ARB parity，`flutter gen-l10n` 干净、`git add -f lib/generated/` 后无残留 stale Dart——parity check（三语键数相等、无 orphan key）作为合并前内联门禁。
  4. （VEN，wave 2）英文语音从英文关键词识别类目、从英文别名/locale 名识别商家、识别英文货币词（dollar/dollars/buck/bucks/USD/$、pound/quid/£、euro/€…复用 v1.7 longest-first `_detectCurrency` 扫描，不 fork）——达到与 zh/ja 的实用对齐，不做口述数字状态机。
  5. （VEN，wave 2）英文 STT 数字金额正确解析；~30 行有界英文数字词兜底（one…twenty、thirty…ninety、hundred/thousand、a/an→1、「X fifty」→X.50 习语，仅当数字正则无命中时触发）处理「fifty」/「a hundred」而**不进 CJK 数字路径**——「fifty dollars」→ amount + USD（不再 amount 0）；`localeId` 端到端贯通 en-US，测试断言任何英文 utterance 永不进入 ja/zh 数字路径（复用已验证的 locale plumbing，防 v1.8 golden WR-04 `currentLocaleProvider`-miss 类回归）。

**Plans**: TBD
**UI hint**: yes

### v1.9 Cross-Cutting Constraints (every phase carries these)

- **Drift pins:** drift stays **2.31.0** (NEVER ≥2.32.0 — drops SQLCipher easy-support); `sqlcipher_flutter_libs` 0.6.8; schema bump **v21→v22** (only Phase 49); explicit `CREATE INDEX IF NOT EXISTS` in onCreate AND onUpgrade (`customIndices` is decorative — MEMORY.md gotcha).
- **No new heavy deps:** decoupled engines / cross-validation / category-only are pure in-house Dart; merchant library is a curated Drift seed. No FTS5 (CJK tokenization broken + SQLCipher ships no CJK tokenizer + 400 rows too small), no Levenshtein/fuzzy lib (v1.3 deleted `FuzzyCategoryMatcher` as net-negative), no TFLite/embeddings/cloud NLU. `kana_kit ^2.1.1` is the ONLY optional candidate (seed-time romaji normalization); hand-rolled NFKC + kana-fold covers the 80% case if zero-new-deps preferred.
- **Merchant scope:** ~400 entries committed for v1.9 (national-chain spine per everyday category); schema designed for 600-800 ceiling; regional/depachika tail deferred to v2 (MERCH-V2-01).
- **ADR-012 anti-gamification (permanent):** no accuracy-%/streak/badge/leaderboard around recognition; confidence is qualitative 3-tier, never a number; low-confidence guesses are confirmed/corrected, never auto-committed. New recognition UI joins the anti-toxicity sweep (Phase 52), extended inline (not deferred to close) within Phase 52's RECUX+VEN close-out wave.
- **Thin-Feature Clean Architecture:** recognizers + use case in `lib/application/voice/recognition/`; reconciler + verdict models + repo interface in `domain/` (`features/accounting/domain/`); merchants table/DAO/repo-impl in `lib/data/`. Domain never imports application/data/infrastructure.
- **Learning-key identity contract:** `resolvedKeyword` write key == recognizer read key end-to-end (260526-pg6 orphan-key lesson); corrections on conflict teach the KEYWORD table, never the merchant table.
- **i18n:** merchant proper-nouns are DATA (Drift multi-locale columns), category labels are ARB; trilingual parity + `flutter gen-l10n` clean + `git add -f lib/generated/`; parity gate inline within Phase 52 (the phase touching UI strings).
- **Security:** never log raw transcript/amount/merchant (zero-knowledge); resolved merchant stays in the already-encrypted transaction field; merchant seed list is non-sensitive public data; learning-table sync stays under existing E2EE gates.

### v1.9 Pitfall → Phase → Regression-Test Map

| Pitfall | Phase | Named regression test / invariant |
|---------|-------|-----------------------------------|
| 1. Bidirectional-substring merchant false-positives at scale | 50 (+51 veto) | `merchant_false_positive_test.dart` adversarial corpus → no/low match |
| 2. Ledger desync when removing merchant short-circuit | 51 (wave-2 LEDGER; wave-1 reconciler stamps ledger last) | invariant `ledgerType == resolveLedgerType(finalCategoryId)` on every path; configs cover all reachable L2 |
| 3. Cross-validation mis-fires on weak/absent signals | 51 (wave-1 XVAL) | `cross_validation_test.dart` 3×3 truth table (bare-merchant / weak-keyword / both-weak / strong-conflict cells) |
| 4. Category-only path mis-fire | 50 (+51 parallel-not-fallback) | four-quadrant test incl. merchant✗-keyword✓ (加油) and merchant✓-keyword✗ |
| 5. JP name-variant gaps (kana/kanji/romaji/abbrev/full-width) | 49 (normalized-key column) + 50 (NFKC query) + 52 (romaji/EN) | half-width-kana + Kansai-abbrev (マクド) + romaji each match in test |
| 6. `customIndices` decorative + non-idempotent seed + migration ladder | 49 | `PRAGMA index_list` non-empty (fresh+upgrade); double-seed converges; full ladder vs real sqlite3 + SQLCipher key |
| 7. English STT number-words / currency words / locale-not-threaded | 52 (wave-2 VEN) | `"fifty dollars"` → amount + USD; English never enters CJK numeral path; `localeId` threaded |
| 8. ADR-012 leaks in recognition UX | 52 (wave-1 RECUX, swept in wave-2 close-out) | anti-toxicity sweep covers new UI, ja/zh/en × states, complete banned-token list |
| 9. ARB parity / proper-noun-vs-category-label split | 49 (multi-locale columns) + 52 (chrome strings, inline parity gate) | equal key counts, no orphans, merchant names in table not ARB, gen-l10n clean |
| 10. Low-confidence thrash on STT partials | 51 (wave-1 resolve-on-final) + 52 (partial-vs-committed render) | resolve-on-final test + hysteresis margin test; no flicker on partials |

### v1.9 Phase Ordering Rationale

- **Data before logic:** Phase 49 blocks every component that reads `merchants`; re-migrating the schema after rows are loaded is the expensive mistake.
- **Recognizers before arbitration:** the reconciler is a pure function of two verdicts — both verdict shapes must exist (Phase 50) before Phase 51 can combine them.
- **Cross-validation + ledger rework merged into Phase 51 (one code surgery):** the reconciler insert AND the ledger rework both delete the same merchant short-circuit / ledger-from-merchant branch at `parse_voice_input_use_case.dart:106`, and ledger purity depends on the single post-reconciliation `resolveLedgerType` site existing. Doing them in one phase (XVAL wave first, LEDGER wave second) keeps the surgery atomic and prevents the two-ledger-maps inconsistency; the wave order preserves the original 51→52 dependency.
- **Recognition UX + English merged into Phase 52 (shared surface + close-out):** both touch `TransactionDetailsForm`, and the trilingual ARB-parity + anti-toxicity-sweep + golden-rebaseline close-out is a single inline gate (the 6-phase version already ran it across 53-54). RECUX surface lands before/with VEN coverage; English coverage is additive data over the Phase-50 engines + Phase-49 alias columns, lowest structural risk, so it trails inside the phase.

### v1.9 Research Flags (deeper spec needed at plan time)

- **Phase 51 (Cross-Validation — wave-1 XVAL):** the 3×3 truth table — band definitions, agreement granularity, confidence floors, hysteresis margin — is where the real logic lives and is easy to under-spec. Write the truth table as the test spec before coding (`cross_validation_test.dart` as spec). The wave-2 LEDGER rework is a standard pattern — grep-verify `ClassificationService` blast radius (OCR MOD-005? tests?) before retiring; fold into config if a consumer exists.
- **Phase 49 (Data Foundation):** seed-timing decision (inside-migrator `rootBundle` read vs count-guarded post-open seed, given `AppInitializer` order KeyManager→Database→others) needs an early answer; count-guarded post-open is the safer default. Full migration-ladder test against the encrypted-executor path, not just `NativeDatabase.memory()`.
- **Phase 52 (English — wave-2 VEN):** well-scoped additive data + a small bounded number-word fallback; the RECUX wave is fresh ADR-012 UI surface — keep the affordance qualitative and extend the anti-toxicity sweep with the COMPLETE banned-token list inline.

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
| v1.9 语音类目与商家识别系统重构 | 49-52 | 0/TBD | Planning | - |
