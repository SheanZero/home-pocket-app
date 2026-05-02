# Requirements: Home Pocket — まもる家計簿

**Defined:** 2026-05-01
**Milestone:** v1.1 幸福度指标与展示 (Happiness Metric & Display)
**Core Value:** A family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, with a dual-ledger system that distinguishes survival spending from soul spending so families can have honest money conversations.
**Milestone insight:** 花钱的本质是满足精神需求；金额 ≠ 快乐。10 元的小確幸可能比 1000 元的购物更幸福。本期需要把这个直觉变成数学载体，并通过数据让用户回看自己的幸福结构。

## v1.1 Requirements

Requirements for the v1.1 release. Each maps to roadmap phases (9-12) defined in ROADMAP.md.

### HAPPY — Happiness Domain & Formula Layer

Foundation: 4 personal indicators + supporting infrastructure (filters, empty-state handling, gamification ban).

- [ ] **HAPPY-01**: Compute **Avg Satisfaction** over month-to-date as the mean of soul-ledger transaction satisfaction values
- [ ] **HAPPY-02**: Compute **Joy per ¥** density via Prospect Theory Value Function: `density = Σ (soul_satisfaction × (amount / base)^0.88) / Σ amount`; α=0.88 (Kahneman & Tversky 1979 empirical fit); base by currency (JPY=500 / CNY=25 / USD=5; fallback=500); folded in Dart layer (DAO returns row-wise tuples); display formatted by `joy_density_formatter.dart`. See ADR-013.
- [ ] **HAPPY-03**: Compute **Highlights count** as the count of soul-ledger transactions where `satisfaction ≥ 6` ("Good or better") over month-to-date. Threshold matches the post-rename emoji semantic (emoji 3 writes 6).
- [ ] **HAPPY-04**: Compute **Top Joy / 本月最值** via SQL `ORDER BY soul_satisfaction DESC, amount DESC, timestamp DESC LIMIT 1` over month-to-date soul-ledger transactions; **former ¥500 minimum removed** (amount-DESC tiebreak handles small-amount over-rewarding); returns single transaction reference for story-card rendering. See ADR-013 implementation rationale + the user intent quote in CONTEXT.md `<specifics>`: "虽然小东西会让人开心，但也要鼓励为了自己的开心花更多的钱".
- [ ] **HAPPY-05**: All happiness aggregators consume a centralized **`_soulOnly()` SQL fragment** that filters `WHERE ledger_type = 'soul'`; survival rows must never contaminate metrics regardless of the `soul_satisfaction = 5` default
- [ ] **HAPPY-06**: Sealed **`MetricResult`** type with `empty` / `thinSample` / `value` variants handles n=0/1/2 cases gracefully; UI never renders raw NaN, infinity, or "0%" placeholders for empty windows
- [ ] **HAPPY-07**: Architecture decision record **`ADR-XXX_No_Gamification_v1_1.md`** ratifies "no streaks / no badges / no daily targets in v1.1" as a Goodhart's-Law defense; this rule is binding through milestone close
- [ ] **HAPPY-08**: 5-emoji ↔ value mapping pinned by unit tests under the unipolar positive satisfaction semantic so refactors cannot silently drift the bucketing.

| Picker emoji | DB value (post-v16) | Phase 9 label (current ARB) | Phase 12 label (post-rename) |
|--------------|---------------------|------------------------------|------------------------------|
| 1 | 2 | Bad / 差 / 悪い | Neutral / 中性 / 中性 |
| 2 | 4 | Slightly Bad / 较差 / やや悪い | OK / OK / OK |
| 3 | 6 | Normal / 一般 / 普通 | Good / 不错 / 不錯 |
| 4 | 8 | Good / 好 / 良い | Great / 满足 / 満足 |
| 5 | 10 | Very Good / 很好 / とても良い | Amazing / 最爱 / 最愛 |

Default value (no rating): **2** (was 5; bumped in schema v16 per ADR-014).
Voice estimator output range remains [3, 10] until v1.2 realignment (per ADR-014 / D-12).

### FAMILY — Family Cooperative Indicators

Two metrics that surface in family/group mode only. **All anti-comparison constraints are REQ-level**, not implementation detail.

- [ ] **FAMILY-01**: **Family Highlights Sum** = aggregate count of `satisfaction ≥ 6` soul-ledger transactions across all family shadow books over month-to-date; **return type is `int` (single aggregate)**; per-member breakdown (e.g. `Map<MemberId, int>`) is forbidden by contract — the use case must not expose the data shape that enables leaderboards. (Threshold matches HAPPY-03.)
- [ ] **FAMILY-02**: **Shared Joy Insight** identifies the category with the highest avg satisfaction across the family's soul-ledger transactions over month-to-date; **min-N=3 transactions per category** guard prevents single-data-point categories from being crowned; returns `(categoryId, avgSatisfaction, totalCount)` only — no per-member contributions
- [ ] **FAMILY-03**: Family card consent gate — if any family member has not opted into shared analytics, the family card collapses entirely (not "shows partial data")

### HOMEUI — HomePage Redesign

Replace `SoulFullnessCard` to consume Phase 9 contracts. Drop the buggy inline helpers.

- [ ] **HOMEUI-01**: `SoulFullnessCard` rebuilt to render the 4 personal happiness metrics (Avg Satisfaction, Joy per ¥, Highlights count, Best Joy per ¥ story card)
- [ ] **HOMEUI-02**: Inline helpers `_computeHappinessROI` (misleading "budget-share" formula) and `_computeSatisfaction` (intraday-only) deleted from `home_screen.dart`; both responsibilities now live in `GetHappinessReportUseCase`
- [ ] **HOMEUI-03**: Family card (FAMILY-01 + FAMILY-02) conditionally rendered when `isGroupModeProvider == true`; respects FAMILY-03 consent gate
- [ ] **HOMEUI-04**: At most 2 `ⓘ` info icons explain voice estimator bias and hedonic adaptation; coverage caption ("n=23/31 rated") visible on the headline metric tile; no daily-target / streak / badge copy anywhere

### STATSUI — Statistics Surface (悦己账本统计)

Wire the 3 dormant DAO methods + the new Best Joy DAO query into `AnalyticsScreen` as a composable sub-region.

- [ ] **STATSUI-01**: **Joy per ¥ trend line** for month-to-date rendered as `LineChart` in a new AnalyticsScreen sub-region; baseline-anchored y-axis; gap-vs-zero policy documented in chart legend
- [ ] **STATSUI-02**: **Satisfaction distribution histogram** rendered as `BarChart`; the bar at `5` is annotated "中央値・含未評価 / 中位数·含未评分 / Median + unrated" to acknowledge default-value clustering; text fallback rendered when sample size < 5
- [ ] **STATSUI-03**: Headline metrics row above the charts shows mean (primary) + median (tooltip) + coverage caption ("n=k rated"); honors HAPPY-06 empty-state contract
- [ ] **STATSUI-04**: Phase 11 begins with an **integration footprint audit document** (provider graph + widget tree + ARB namespace + DAO call sites) committed to `.planning/phases/11-*/` before any wiring code is written; counters typical 30-50% under-estimation of "just wire it up" tasks

### RENAME — UI Copy Rename Pass

ARB-only changes (values, NOT keys). 三语 ja/zh/en. Native-speaker register review.

- [ ] **RENAME-01**: `soulLedger` ARB value renamed across ja/zh/en — JP: ときめき帳; ZH: 悦己账本; EN: Joy Ledger. Key unchanged.
- [ ] **RENAME-02**: `survivalLedger` ARB value renamed across ja/zh/en — JP: 日々の帳; ZH: 日常账本; EN: Daily Ledger. Key unchanged.
- [ ] **RENAME-03**: `homeHappinessROI` ARB value renamed — JP: ハピネス密度; ZH: 幸福密度; EN: Joy per ¥. Key unchanged (semantically misleading post-rename, but key-rename forces wider edits and triggers ARB-parity CI churn; deferred to v1.2+).
- [ ] **RENAME-04**: `homeSoulFullness` ARB value renamed — JP: ときめき度; ZH: 悦己充盈; EN: Joy Index. Key unchanged.
- [ ] **RENAME-05**: ADR **`ADR-XXX_Lexical_Hierarchy_v1_1.md`** captures the translation register hierarchy: 幸福 / happiness reserved for documentation; ときめき / 悦己 / Joy used in-product; CN family-mode uses 「家族的小确幸」 NOT 「家族悦己」 (collision with personal account name)
- [ ] **RENAME-06**: Native-speaker register review for ja/zh translations completed before merge — register matters more than lexical accuracy here

## v2 Requirements (Deferred — tracked but not in v1.1 roadmap)

### Personal extension
- **HAPPY-V2-01**: Per-category satisfaction breakdown view (which categories bring most joy?)
- **HAPPY-V2-02**: Custom time windows (week / quarter / year / arbitrary range) for happiness metrics
- **HAPPY-V2-03**: Manual-only sub-metric variant if voice-bias proves problematic. Depends on adding `entry_source` column in a future schema migration (Phase 9 verified the column does NOT currently exist; HAPPY-09 was folded into this entry per CONTEXT.md D-18).
- **STATSUI-V2-01**: Soul-vs-Survival happiness comparison surface (with anti-toxicity framing)

### Family extension
- **FAMILY-V2-01**: 4th DAO method for SQL-side `category × avg satisfaction` aggregation if data volumes justify it
- **FAMILY-V2-02**: Family conversation-prompt cards ("This month you all loved coffee shops. Share a story?") — explicitly opt-in, no automation

### Tooling
- **TOOL-V2-01**: `fl_chart 1.x` upgrade (`FUTURE-TOOL-fl_chart-1x`) — incidental sweep of existing AnalyticsScreen chart call sites
- **TOOL-V2-02**: ARB key rename (`homeHappinessROI` → `homeJoyPerYen`, `homeSoulFullness` → `homeJoyIndex`) — deferred from v1.1 to avoid CI parity churn during widget edits

## Out of Scope

Explicitly excluded from v1.1. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| New schema fields (mood tags / location / category-specific satisfaction) | Locked: zero schema migrations in v1.1 |
| Satisfaction backfill / rescore for historical transactions | Out of scope; historical data preserved as-is |
| Member interaction (like / comment / mention on others' soul records) | Requires new tables; defer to v2+ |
| Per-member breakdown surfaces (leaderboards, contribution charts) | **Anti-feature** — produces toxic family dynamics; never to be added |
| Streaks / badges / daily satisfaction targets | **Anti-feature** — Goodhart's Law; explicitly banned via HAPPY-07 ADR |
| Cross-period delta on home tile ("vs last month: +3.2 Joy points") | Comparison anti-pattern; surfaces self-judgment dynamics |
| Public sharing of happiness metrics | Privacy + comparison risks; never to be added |
| Theme color changes / visual rebrand | User instruction: "先不改变色调" — color tone locked at v1.1 start |
| ARB key renames (vs value renames) | Triggers ARB-parity CI churn; key rename deferred to v1.2 |
| `fl_chart 1.x` upgrade | Cosmetic, would force incidental sweep across existing AnalyticsScreen |
| Riverpod 3.x upgrade | `analyzer` conflict with `json_serializable` (FUTURE-TOOL-01, deferred from v1.0) |
| `recoverFromSeed()` key-overwrite bug fix | Security architecture out of scope (FUTURE-ARCH-04, deferred from v1.0) |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| HAPPY-01 | Phase 9 | Pending |
| HAPPY-02 | Phase 9 | Pending |
| HAPPY-03 | Phase 9 | Pending |
| HAPPY-04 | Phase 9 | Pending |
| HAPPY-05 | Phase 9 | Pending |
| HAPPY-06 | Phase 9 | Pending |
| HAPPY-07 | Phase 9 | Pending |
| HAPPY-08 | Phase 9 | Pending |
| FAMILY-01 | Phase 9 | Pending |
| FAMILY-02 | Phase 9 | Pending |
| FAMILY-03 | Phase 10 | Pending |
| HOMEUI-01 | Phase 10 | Pending |
| HOMEUI-02 | Phase 10 | Pending |
| HOMEUI-03 | Phase 10 | Pending |
| HOMEUI-04 | Phase 10 | Pending |
| STATSUI-01 | Phase 11 | Pending |
| STATSUI-02 | Phase 11 | Pending |
| STATSUI-03 | Phase 11 | Pending |
| STATSUI-04 | Phase 11 | Pending |
| RENAME-01 | Phase 12 | Pending |
| RENAME-02 | Phase 12 | Pending |
| RENAME-03 | Phase 12 | Pending |
| RENAME-04 | Phase 12 | Pending |
| RENAME-05 | Phase 12 | Pending |
| RENAME-06 | Phase 12 | Pending |

**Coverage:**
- v1.1 requirements: 25 total
- Mapped to phases: 25 (provisional — confirmed during roadmap creation)
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-01*
*Last updated: 2026-05-01 after Phase 9 spec amendments (HAPPY-02/03/04/08 + HAPPY-09 removal + FAMILY-01 — see ADR-012/013/014)*
