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

- [ ] **Phase 9: Happiness Domain & Formula Layer** — Lock formulas, contracts, soul-only filter, Top Joy ordering, sealed `MetricResult`, family aggregate-only return type, no-gamification ADR (linchpin)
- [ ] **Phase 10: HomePage SoulFullnessCard Redesign** — Replace misleading `Happiness ROI`; render 4 personal metric tiles + Best Joy story card + family card (group-mode + consent); delete inline helpers
- [ ] **Phase 11: Statistics Surface for 悦己账本** — Wire 3 dormant DAO methods + new Best Joy query through to AnalyticsScreen sub-region; Joy-per-¥ trend line + satisfaction histogram (with `5`-bar annotation); footprint-audit doc first
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
**Plans:** 13 plans across 6 waves

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

### Phase 10: HomePage SoulFullnessCard Redesign
**Goal**: Replace the misleading `Happiness ROI` card on HomePage with a redesigned `SoulFullnessCard` that renders the 4 personal happiness metrics + a story-mode Best Joy card, with the family card conditionally shown only in group mode + consent.
**Depends on**: Phase 9 (consumes `GetHappinessReportUseCase`, `GetBestJoyMomentUseCase`, `GetFamilyHappinessUseCase` and the sealed `MetricResult` contract)
**Requirements**: FAMILY-03, HOMEUI-01, HOMEUI-02, HOMEUI-03, HOMEUI-04
**Complexity**: Medium (UI rebuild on stable contracts; Container Widget With Async Provider pattern already established)
**Critical pitfalls encoded**:
- Family consent gate: if any family member has not opted into shared analytics, the family card collapses entirely (NOT "shows partial data")
- ≤2 `ⓘ` info icons total — explain voice-estimator bias and hedonic adaptation only; no other tooltip clutter
- Coverage caption ("n=23/31 rated") on the headline metric tile — honors HAPPY-06 empty-state contract
- ZERO daily-target / streak / badge / "vs last month" copy anywhere — enforces ADR-No-Gamification at UI level
- Both `_computeHappinessROI` (misleading "budget-share" formula) and `_computeSatisfaction` (intraday-only) must be DELETED from `home_screen.dart` — responsibilities now live in `GetHappinessReportUseCase`
**Success Criteria** (what must be TRUE):
  1. HomePage `SoulFullnessCard` renders all 4 personal metrics (Avg Satisfaction, Joy per ¥, Highlights count, Best Joy per ¥) with values sourced exclusively from Phase 9 use cases
  2. Best Joy story card renders the single argmax transaction with amount visible alongside satisfaction (anti-¥10-candy framing)
  3. Family card visible only when `isGroupModeProvider == true` AND all members have opted into shared analytics; collapses entirely otherwise
  4. Coverage caption present on headline metric tile; ≤2 `ⓘ` icons in the entire card; no streak/badge/target/cross-period copy
  5. `_computeHappinessROI` and `_computeSatisfaction` are gone from `home_screen.dart` (grep returns zero matches in `lib/`)
**Plans**: TBD
**UI hint**: yes

### Phase 11: Statistics Surface for 悦己账本
**Goal**: Wire the 3 dormant DAO methods (`getSoulSatisfactionOverview` / `getSatisfactionDistribution` / `getDailySatisfactionTrend`) plus the new Best Joy query through use case → provider → widgets into AnalyticsScreen as a composable 悦己账本统计 sub-region; deliver Joy-per-¥ trend line + satisfaction distribution histogram.
**Depends on**: Phase 9 (consumes DAO + use cases). Can start after Phase 10 OR run in parallel with Phase 10 if capacity allows; Phase 12 must wait for both.
**Requirements**: STATSUI-01, STATSUI-02, STATSUI-03, STATSUI-04
**Complexity**: Medium (mostly wiring + 2 new chart widgets, but 30-50% under-estimation risk on "just wire it up" tasks — first sub-task is the footprint audit, NOT code)
**Critical pitfalls encoded**:
- Phase 11 BEGINS with an integration footprint audit document (provider graph + widget tree + ARB namespace + DAO call sites) committed to `.planning/phases/11-*/` BEFORE any wiring code is written — counters typical 30-50% under-estimation
- Histogram bar at `5` MUST be annotated ("中央値・含未評価 / 中位数·含未评分 / Median + unrated") — acknowledges East-Asian central-tendency clustering + default-5 cluster from missed/OCR/quick-add inputs; do NOT try to "fix" the cluster
- Headline row shows mean (primary) + median (tooltip) + coverage caption ("n=k rated") — mean alone is fragile against the default-5 cluster
- Joy-per-¥ trend line uses baseline-anchored y-axis; gap-vs-zero policy documented in chart legend
- Text fallback rendered when sample size < 5 (HAPPY-06 empty-state contract)
- `shadowBooksProvider` family-mode book enumeration is the deeper-research moment for this phase (flagged MEDIUM-confidence in research)
**Success Criteria** (what must be TRUE):
  1. Integration footprint audit document exists in `.planning/phases/11-*/` and was committed BEFORE any wiring code in this phase
  2. Joy per ¥ trend line renders in AnalyticsScreen 悦己账本统计 sub-region as `LineChart` for month-to-date, with baseline-anchored y-axis and gap-vs-zero policy in legend
  3. Satisfaction distribution histogram renders as `BarChart`; the `5` bar is annotated with the trilingual caption acknowledging default-value clustering
  4. Headline metrics row shows mean as primary, median in tooltip, and coverage caption ("n=k rated"); honors HAPPY-06 empty-state by rendering text fallback when n<5
  5. All chart wiring consumes Phase 9 use cases (no direct DAO calls from widgets); `flutter analyze` reports 0 issues
**Plans**: TBD
**UI hint**: yes

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

- v1.1 requirements: 25 total
- Mapped to phases: 25 ✓
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
| 10. HomePage SoulFullnessCard Redesign    | v1.1 | 0/? | Not started | —          |
| 11. Statistics Surface for 悦己账本        | v1.1 | 0/? | Not started | —          |
| 12. UI Copy Rename Pass (ARB values)      | v1.1 | 0/? | Not started | —          |
