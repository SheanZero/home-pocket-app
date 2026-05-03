# Roadmap: Home Pocket

## Milestones

- ✅ **v1.0 Codebase Cleanup Initiative** — Phases 1-8 (shipped 2026-04-29) — see [archive](milestones/v1.0-ROADMAP.md)
- 📋 **v1.1 Happiness Metric & Display** — Phases 9-12 (active, planning 2026-05-01)

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

**Outcome:** REAUDIT-DIFF.json reports `resolved=50, regression=0, new=0, open_in_baseline=0`. 4 permanent CI guardrails active. See `.planning/milestones/v1.0-ROADMAP.md` for full details.

</details>

### 📋 v1.1 (Active) — Happiness Metric & Display

Phase numbering continues from Phase 9 (no reset).

- [x] **Phase 9: Happiness Domain & Formula Layer** — Lock formulas, contracts, soul-only filter, Top Joy ordering, sealed `MetricResult`, family aggregate-only return type, no-gamification ADR (linchpin) — completed 2026-05-02
- [x] **Phase 10: HomePage SoulFullnessCard Redesign (HomeHeroCard integrated rebuild)** — Replace 3 widgets with 1 integrated `HomeHeroCard`; 3 concentric rings encode Phase 9 contracts (single → `HappinessReport`, group → `FamilyHappiness`); delete `_computeHappinessROI` / `_computeSatisfaction` / `_buildLedgerRows` from `home_screen.dart` (completed 2026-05-03)
- [ ] **Phase 11: AnalyticsScreen Unified Dashboard (Variant δ)** — Rebuild AnalyticsScreen as a 2-region unified dashboard (総帳本 + 悦己帳本) with KPI mini-hero (総支出 + 悦己平均) + 3 themed groups (時間 / 分布 / 物語), 総-first card ordering. Wire 3 dormant DAO methods + new Best Joy query. 生存帳本 has no separate stats region. Footprint-audit doc first.
- [ ] **Phase 12: UI Copy Rename Pass (ARB values, ja/zh/en)** — Values-only rename of `soulLedger` / `survivalLedger` / `homeHappinessROI` / `homeSoulFullness`; lexical-hierarchy ADR; native-speaker register review

## Phase Details

### Phase 9: Happiness Domain & Formula Layer
**Goal**: Lock the math, contracts, and anti-gamification defenses for happiness metrics so every downstream UI consumer builds on stable ground (linchpin phase — no UI may proceed until Phase 9 ships).
**Depends on**: Nothing (first v1.1 phase; consumes existing schema + 3 dormant DAO methods)
**Requirements**: HAPPY-01, HAPPY-02, HAPPY-03, HAPPY-04, HAPPY-05, HAPPY-06, HAPPY-07, HAPPY-08, FAMILY-01, FAMILY-02
**Complexity**: Medium-High (formula correctness + 1 new DAO query + ADR; mirrors `GetMonthlyReportUseCase` precedent)
**Critical pitfalls encoded**:
- Centralized `_soulOnly()` SQL fragment (`WHERE ledger_type = 'soul'`) — every aggregator MUST consume; survival rows with `soul_satisfaction = 5` default must NEVER contaminate metrics
- Schema bump v15 → v16 — `transactions.soul_satisfaction` default 5 → 2 (Path B unipolar positive scale; ADR-014). All five code-side defaults (column, transaction_dao parameters, Freezed model @Default, demo_data_service) edited in lockstep — partial edits silently revert to 5.
- PTVF α=0.88 (Kahneman & Tversky 1979) for HAPPY-02 with currency-aware base (JPY=500/CNY=25/USD=5/fallback=500); Dart-layer fold (SQLite has no POW/EXP). Performance trade-off vs SUM/GROUP BY <2s principle accepted (10-100 monthly soul tx per book). See ADR-013.
- HAPPY-04 Top Joy: pure satisfaction sort with amount-DESC tiebreak (`ORDER BY soul_satisfaction DESC, amount DESC, timestamp DESC LIMIT 1`). NO 500-yen minimum — amount-DESC handles "small amount over-rewarding" (D-06).
- Three new ADRs ratified at Phase 9: ADR-012 (No Gamification), ADR-013 (Joy Density PTVF Scaling), ADR-014 (Soul Satisfaction Unipolar Positive Scale). Drafts created in Phase 9 plans 09-10/09-11/09-12; status flips to ✅ 已接受 at Phase 12 close.
- Sealed `MetricResult` with `Empty<T>` / `Value<T>` variants — UI never sees raw NaN, infinity, or "0%" placeholders
- `FamilyHighlightsSum` returns `int` aggregate-only — `Map<MemberId, int>` is FORBIDDEN by contract (anti-leaderboard, anti-surveillance)
- `SharedJoyInsight` requires min-N=3 transactions per category — single-data-point categories cannot be crowned
- `ADR-XXX_No_Gamification_v1_1.md` ratifies "no streaks / no badges / no daily targets" as Goodhart's-Law defense
- 5-emoji ↔ value mapping pinned by unit test under the post-v16 unipolar positive semantic ({2, 4, 6, 8, 10})
**Success Criteria** (what must be TRUE):
  1. All 4 personal happiness metrics (Avg Satisfaction, Joy per ¥, Highlights count, Best Joy per ¥) computable from a fresh test fixture, with survival rows demonstrably excluded by the centralized `_soulOnly()` fragment
  2. HAPPY-04 Top Joy ordering pinned by DAO test fixture: with rows {(¥10000, sat=8), (¥500, sat=10), (¥3000, sat=10), (¥3000, sat=10, older)}, the query returns the ¥3000 sat=10 (newer) row — proves sat DESC primary + amount DESC tiebreak + timestamp DESC final tiebreak (D-06).
  3. Sealed `MetricResult` handles empty and value states without producing NaN/infinity/raw-zero outputs
  4. `FamilyHighlightsSum` use case signature returns `int` (compile-time enforced); `SharedJoyInsight` returns `(categoryId, avgSatisfaction, totalCount)` only — no per-member fields
  5. `ADR-XXX_No_Gamification_v1_1.md` and `ADR-XXX_Lexical_Hierarchy_v1_1.md` (the latter drafted, ratified in Phase 12) are committed; 5-emoji↔1-10 mapping test passes for the post-v16 default-2 semantic (voice-bias regression test removed per D-18 — moved to v2 HAPPY-V2-03).
  6. Schema migration v15→v16 round-trip test green (default soul_satisfaction reads back as 2 on fresh inserts; CHECK BETWEEN 1 AND 10 survives).
**Plans:** 14 plans across 7 waves

Plans:
**Wave 1**
- [x] 09-01-PLAN.md — Schema migration v15→v16 (default soul_satisfaction 5→2; 5 code-side defaults aligned)
- [x] 09-02-PLAN.md — Domain models (sealed MetricResult<T>, HappinessReport, FamilyHappiness, BestJoyMomentRow, SharedJoyInsight)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 09-03-PLAN.md — DAO additions (_soulExpenseFilter const, getBestJoyMoment, getSoulRowsForPtvf, getSharedJoyCategoryInsight)
- [x] 09-04-PLAN.md — Repository interface + impl extension (5 new methods)
- [x] 09-09-PLAN.md — joy_density_formatter.dart (PTVF base + display unit maps; locale-aware formatting)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 09-05-PLAN.md — GetHappinessReportUseCase (HAPPY-01..04 with PTVF α=0.88 + median)
- [x] 09-06-PLAN.md — GetBestJoyMomentUseCase (standalone HAPPY-04 entry point)
- [x] 09-07-PLAN.md — GetFamilyHappinessUseCase (FAMILY-01 int aggregate + FAMILY-02 3-tuple; anti-leaderboard contract)

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 09-08-PLAN.md — Riverpod providers (3 use case providers + state_happiness.dart consumer-facing async providers)

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 09-10-PLAN.md — ADR-012 No Gamification v1.1 (Goodhart Law defense; Forbidden Features inventory)
- [x] 09-11-PLAN.md — ADR-013 Joy Density PTVF Scaling (K-T 1979 citation; currency table; perf trade-off)
- [x] 09-12-PLAN.md — ADR-014 Soul Satisfaction Unipolar Positive Scale (default 5→2 rationale; voice-realignment defer)

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 09-13-PLAN.md — Spec amendments (REQUIREMENTS.md + ROADMAP.md edits per D-22)

**Wave 7** *(gap closure after verification)*
- [x] 09-14-PLAN.md — HAPPY-08 satisfaction picker mapping test closure (`face_0..face_4` → `[2, 4, 6, 8, 10]`)

### Phase 10: HomePage SoulFullnessCard Redesign (HomeHeroCard integrated rebuild)
**Goal**: Replace 3 separate sections (`MonthOverviewCard` + `LedgerComparisonSection` + `SoulFullnessCard`) on HomePage with 1 integrated `HomeHeroCard`. The integrated card encodes Phase 9 happiness contracts as 3 concentric gradient rings with mode-specific metric mapping (single mode → `HappinessReport`; group mode → `FamilyHappiness`), plus a hero header (total + month-over-month chip + previous-month sub-line), an inline 魂/生存 absolute-amount split bar, a Best Joy story strip emphasizing "what + when" over "amount", and (group mode only) per-member spending rows. Whole-card tap navigates to AnalyticsScreen (Phase 11 unified dashboard, default scroll-top so 悦己平均 KPI tile + 時間/Joy/¥ card are immediately visible).
**Depends on**: Phase 9 (consumes `happinessReportProvider`, `bestJoyMomentProvider`, `familyHappinessProvider`, sealed `MetricResult` contract, and `BestJoyMomentRow` Freezed model)
**Requirements**: FAMILY-03, HOMEUI-01, HOMEUI-02, HOMEUI-03, HOMEUI-04, HOMEUI-05, HOMEUI-06, HOMEUI-07
**Complexity**: Medium-High (UI rebuild on stable contracts + new `CustomPainter` for 3 concentric gradient rings + integrated card composition replacing 3 widgets + spec amendments to REQUIREMENTS.md/ROADMAP.md per D-06/D-07; Container Widget With Async Provider pattern already established)
**Critical pitfalls encoded**:
- Hero card single-mode rings encode `HappinessReport` (Phase 9 personal contract); group-mode rings encode `FamilyHappiness` (Phase 9 family contract). Switching mid-card is forbidden — provider/mode selection is a top-level branch in the parent screen.
- Currency code MUST resolve from `Book.currency` via `bookByIdProvider`-style lookup (not hardcoded `'JPY'`); existing `FormatterService().formatCurrency(amount, 'JPY', locale)` violation in `SoulFullnessCard:162` is eliminated by this rebuild (CLAUDE.md Pitfall #9).
- 魂/生存 split bar is a CATEGORY DISTRIBUTION (factual), not a happiness metric. Labels MUST stay "魂帳" / "生存帳" — NEVER "Joy ROI", "Joy %", "happiness share", "joy ratio", "soul %". Resurrecting joy-share framing reverts the milestone's anti-Goodhart stance (research line 81-82). Code reviewer is the final gate.
- Strict FAMILY-03 consent (any-member-not-opted-in collapses card) is **DEFERRED to v1.2** per D-08 (new REQ FAMILY-V2-03); Phase 10 ships with minimum gate only: `isGroupModeProvider == true && shadowBooks.isNotEmpty`.
- Both `_computeHappinessROI` (misleading "budget-share" formula) and `_computeSatisfaction` (intraday-only) — plus `_buildLedgerRows` (no longer needed) — must be DELETED from `home_screen.dart`. Grep `_computeHappinessROI\|_computeSatisfaction\|_buildLedgerRows` in `lib/` returns zero matches as a hard gate.
- ≤2 `ⓘ` info icons total in the card (HOMEUI-04 hard cap); voice-bias mention REMOVED per D-10 (replaced with PTVF + hedonic adaptation only — Phase 9 D-12 deferred voice realignment to v1.2).
- ZERO daily-target / streak / badge / "vs last month" copy anywhere — enforces ADR-012 binding ban at the UI level. The `+X%` trend chip on hero header is for SPENDING (absolute Yen, not gamified).
- Coverage caption "n=k/N rated" sources from `MetricResult.Value.sampleSize` and `HappinessReport.totalSoulTx` per HAPPY-06 empty-state contract.
- Color polish (D-13) is the LAST plan unit of Phase 10 — all hex literals in mockup are tentative; final tokens come from `lib/core/theme/app_colors.dart` + `lib/core/theme/app_theme_colors.dart` extension methods, not Pencil hex literals.
**Success Criteria** (what must be TRUE):
  1. HomePage renders a single `HomeHeroCard` widget (no `MonthOverviewCard`, `LedgerComparisonSection`, or `SoulFullnessCard` widgets exist in `lib/features/home/presentation/widgets/`)
  2. `HomeHeroCard` renders all 4 personal metrics (Avg Satisfaction, Joy per ¥, Highlights count, Best Joy per ¥) with values sourced exclusively from Phase 9 use cases
  3. `HomeHeroCard` displays 3 concentric gradient rings encoding `HappinessReport` in single mode and `FamilyHappiness` in group mode
  4. Best Joy story strip renders the single argmax transaction with `category · date` BIG (fontSize 14) and `¥amount · 满足 X/10 ✨` small (fontSize 9) — anti-`¥10 candy` framing per D-04
  5. Family card region (rings + member rows) visible only when `isGroupModeProvider == true` AND `shadowBooks.isNotEmpty`; collapses entirely otherwise (D-08 minimum gate)
  6. Coverage caption visible on headline metric tile when `0 < totalSoulTx`; ≤2 `ⓘ` icons in the entire card
  7. `_computeHappinessROI`, `_computeSatisfaction`, `_buildLedgerRows` are gone from `home_screen.dart` (`grep` returns zero matches in `lib/`)
  8. `home_screen.dart` net line count DECREASES (currently 386 lines; post-Phase-10 must be < 386)
  9. All ¥ amounts use `AppTextStyles.amountLarge/Medium/Small` (`FontFeature.tabularFigures()`); zero hardcoded `'JPY'` in `home_hero_card.dart`
  10. All UI strings via `S.of(context)`; ARB keys added to all 3 locales (ja/zh/en); `flutter gen-l10n` regenerates without warnings; ARB-parity CI guardrail green
  11. `flutter analyze lib/features/home/` reports 0 issues
**Plans**: TBD
**UI hint**: yes

### Phase 11: AnalyticsScreen Unified Dashboard (Variant δ)
**Goal**: Rebuild `AnalyticsScreen` as a unified 2-region dashboard composed of (a) a KPI mini-hero strip showing 総支出 + 悦己平均 and (b) 3 themed groups — 時間 / 分布 / 物語 — each containing 総-first then 悦己-second cards, plus a 物語 trio (総 highlight + 悦己 Best Joy + group-mode FamilyInsightCard). Wire the 3 dormant DAO methods (`getSoulSatisfactionOverview` / `getSatisfactionDistribution` / `getDailySatisfactionTrend`) plus the new Best Joy query through use case → provider → widgets. **生存帳本 has no separate stats region** (生存 metrics roll up into 総帳本 column; family mode = 家庭账本 aggregate-only, anti-leaderboard preserved).
**Depends on**: Phase 9 (consumes DAO + use cases). Can start after Phase 10 OR run in parallel with Phase 10 if capacity allows; Phase 12 must wait for both.
**Requirements**: STATSUI-01, STATSUI-02, STATSUI-03, STATSUI-04, STATSUI-05, STATSUI-06, STATSUI-07
**Complexity**: Medium-High (full AnalyticsScreen rebuild — 8 v1.0 widgets deleted; new layout + 4 chart cards + 3 story cards + KPI mini-hero; 30-50% under-estimation risk persists on "just wire it up" tasks — first sub-task is the footprint audit, NOT code)
**Critical pitfalls encoded**:
- Phase 11 BEGINS with an integration footprint audit document (provider graph + widget tree + ARB namespace + DAO call sites) committed to `.planning/phases/11-*/` BEFORE any wiring code is written — counters typical 30-50% under-estimation
- 8 v1.0 AnalyticsScreen widgets deleted (`SummaryCards` / `CategoryPieChart` / `DailyExpenseChart` / `LedgerRatioChart` / `BudgetProgressList` / `ExpenseTrendChart` / `CategoryBreakdownList` / `MonthComparisonCard`) — replaced by Variant δ unified dashboard
- 生存帳本 receives NO separate stats region (per 2026-05-03 SCOPE revision); 生存 spending category data appears inside 総帳本 cards (e.g., 類別支出 donut breaks down 生存 + 悦己 categories together)
- Histogram bar at `5` MUST be annotated ("中央値・含未評価 / 中位数·含未评分 / Median + unrated") — acknowledges East-Asian central-tendency clustering + default-5 cluster from missed/OCR/quick-add inputs; do NOT try to "fix" the cluster
- 悦己 KPI tile shows mean (primary) + median (tooltip) + coverage caption ("n=k rated") — mean alone is fragile against the default-5 cluster
- Joy-per-¥ trend line uses baseline-anchored y-axis; gap-vs-zero policy documented in chart legend
- Text fallback rendered when sample size < 5 (HAPPY-06 empty-state contract)
- 総-first ordering global: in every themed group, 総 card precedes 悦己 card (anti-comparison framing — financial reality before subjective rating)
- `shadowBooksProvider` family-mode book enumeration is the deeper-research moment for this phase (flagged MEDIUM-confidence in research)
**Success Criteria** (what must be TRUE):
  1. Integration footprint audit document exists in `.planning/phases/11-*/` and was committed BEFORE any wiring code in this phase
  2. AnalyticsScreen renders as unified 2-region Variant δ dashboard: AppBar + month chip → KPI mini-hero (総支出 + 悦己平均) → 時間 group (総 6 か月 推移 + 悦己 Joy/¥ trend) → 分布 group (総 類別支出 + 悦己 満足度 histogram) → 物語 group (総 今月の最大支出 + 悦己 Best Joy + group-mode FamilyInsightCard)
  3. Joy per ¥ trend line renders as `LineChart` for month-to-date, with baseline-anchored y-axis and gap-vs-zero policy in legend (悦己 card in 時間 group)
  4. Satisfaction distribution histogram renders as `BarChart`; the `5` bar is annotated with the trilingual caption acknowledging default-value clustering (悦己 card in 分布 group)
  5. KPI mini-hero 悦己 tile shows mean as primary, median in tooltip/sub-line, and coverage caption ("n=k rated"); honors HAPPY-06 empty-state by rendering text fallback when n<5
  6. 8 v1.0 AnalyticsScreen widgets deleted from `lib/features/analytics/presentation/widgets/` (verified by `grep` returning zero matches)
  7. All chart wiring consumes Phase 9 use cases (no direct DAO calls from widgets); `flutter analyze` reports 0 issues
**Plans**: TBD
**UI hint**: yes (UI-SPEC = 11-UI-SPEC.md, Variant δ locked)

### Phase 12: UI Copy Rename Pass (ARB values, ja/zh/en)
**Goal**: Rename 4 ARB values across all 3 locales (ja/zh/en) to reflect the milestone's lexical hierarchy (悦己 / ときめき / Joy in product; 幸福 / happiness reserved for documentation); ratify the lexical hierarchy as an ADR; complete native-speaker register review.
**Depends on**: Phase 10 AND Phase 11 (this phase MUST be LAST — running ARB churn during widget edits causes merge friction; isolating to a dedicated phase keeps the diff small and reviewable)
**Requirements**: RENAME-01, RENAME-02, RENAME-03, RENAME-04, RENAME-05, RENAME-06
**Complexity**: Small-Medium (mechanical ARB value edits + register review + ADR; CI guardrail enforces ARB key parity)
**Critical pitfalls encoded**:
- VALUES change, KEYS stay — `homeHappinessROI` becomes a slightly misleading key name post-rename, but key rename forces wider edits and triggers ARB-parity CI churn; key rename deferred to v1.2 (TOOL-V2-02)
- Native-speaker register review for ja/zh required BEFORE merge — register matters more than lexical accuracy here
- `ADR-XXX_Lexical_Hierarchy_v1_1.md` captures the hierarchy: 幸福 / happiness for docs; ときめき / 悦己 / Joy in-product
- CN family-mode MUST use 「家族的小确幸」 NOT 「家族悦己」 (collision with personal account name post-rename)
- JP `「幸福」` register-mismatch (philosophical/wellbeing-research weight) — use `ときめき` / `小確幸` for in-product copy only
- 5 satisfaction-level emoji ARB labels also renamed (D-11 expansion of original 4-key scope): `satisfactionBad` → "中性 / Neutral / 中性"; `satisfactionSlightlyBad` → "OK / OK / OK"; `satisfactionNormal` → "不错 / Good / 不錯"; `satisfactionGood` → "满足 / Great / 満足"; `satisfactionVeryGood` → "最爱 / Amazing / 最愛".
- Picker icon update for emoji 1: `sentiment_very_dissatisfied_outlined` → `sentiment_neutral_outlined` (or equivalent). Other 4 icons may need symmetric adjustment — Phase 12 / planner decides icon set.
- Voice estimator output realignment ([3,10] vs picker post-remap {2,4,6,8,10}) DEFERRED to v1.2 per D-12 / ADR-014.
**Success Criteria** (what must be TRUE):
  1. ARB values updated for all 4 keys (`soulLedger`, `survivalLedger`, `homeHappinessROI`, `homeSoulFullness`) across ja/zh/en; KEYS unchanged (verified by grep)
  2. ARB-parity CI guardrail passes; `flutter gen-l10n` succeeds without warnings; `S.of(context)` call sites untouched
  3. `ADR-XXX_Lexical_Hierarchy_v1_1.md` committed and references the 「家族的小确幸」 vs 「家族悦己」 disambiguation
  4. Native-speaker register review evidence (annotated review doc or commit) committed for ja AND zh translations
  5. No 「家族悦己」 string appears in CN family-mode UI (grep confirms collision-free naming)
  6. 5 emoji ARB labels updated across ja/zh/en (`satisfactionBad`/`satisfactionSlightlyBad`/`satisfactionNormal`/`satisfactionGood`/`satisfactionVeryGood`); picker icon for emoji 1 updated; existing satisfaction picker tests still pass with updated labels (HAPPY-08 mapping pinned by test).
**Plans**: TBD
**UI hint**: yes

## Phase Ordering Rationale

- **9 → 10/11 → 12**: Formulas/contracts before consumers; UI before rename to keep ARB diff small and reviewable.
- **10 before 11**: HomePage surfaces a smaller subset of the same metrics; doing it first validates the use-case API shape before AnalyticsScreen extension consumes it more broadly. Phase 11 can run in parallel with Phase 10 if capacity allows.
- **12 LAST**: ARB churn during widget edits causes merge friction; isolate to its own phase.
- **No stack-prep phase**: Zero dependency additions — Phase 9 starts directly on domain + DAO.

## Coverage

- v1.1 requirements: 28 total (was 25; +3 from Phase 10 D-06 scope expansion: HOMEUI-05/06/07)
- Mapped to phases: 28 ✓
- Unmapped: 0
- See `.planning/REQUIREMENTS.md` Traceability table for the full REQ-ID → phase map

## Progress

| Phase | Milestone | Plans Complete | Status      | Completed  |
|-------|-----------|----------------|-------------|------------|
| 1. Audit Pipeline + Tooling Setup | v1.0 | 8/8 | Complete | 2026-04-25 |
| 2. Coverage Baseline              | v1.0 | 4/4 | Complete | 2026-04-26 |
| 3. CRITICAL Fixes                 | v1.0 | 5/5 | Complete | 2026-04-26 |
| 4. HIGH Fixes                     | v1.0 | 6/6 | Complete | 2026-04-27 |
| 5. MEDIUM Fixes                   | v1.0 | 5/5 | Complete | 2026-04-27 |
| 6. LOW Fixes                      | v1.0 | 6/6 | Complete | 2026-04-27 |
| 7. Documentation Sweep            | v1.0 | 6/6 | Complete | 2026-04-28 |
| 8. Re-Audit + Exit Verification   | v1.0 | 8/8 | Complete | 2026-04-28 |
| 9. Happiness Domain & Formula Layer       | v1.1 | 0/? | Not started | —          |
| 10. HomePage SoulFullnessCard Redesign    | v1.1 | 13/13 | Complete    | 2026-05-03 |
| 11. Statistics Surface for 悦己账本        | v1.1 | 0/? | Not started | —          |
| 12. UI Copy Rename Pass (ARB values)      | v1.1 | 0/? | Not started | —          |
