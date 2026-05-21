# Roadmap: Home Pocket

## Milestones

- ✅ **v1.0 Codebase Cleanup Initiative** — Phases 1-8 (shipped 2026-04-29) — see [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Happiness Metric & Display** — Phases 9-12 (shipped 2026-05-05) — see [archive](milestones/v1.1-ROADMAP.md)
- 🟢 **v1.2 Happiness Metric Refresh** — Phases 13-17 (in progress, started 2026-05-19)

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

### 🟢 v1.2 — Happiness Metric Refresh (Phases 13-17 — in progress)

Phase numbering continues from Phase 13 (no reset). Triggered by ADR-016 ratify (2026-05-19).

- [x] **Phase 13: ADR-016 Backend Foundation** — Spike fallback baseline; schema bump (`user_settings.monthly_joy_target` field + table reuse); `GetHappinessReportUseCase` rewrite (density → Σ joy_contribution); DAO query simplification; formatter rename (`joy_density_formatter` → `joy_cumulative_formatter`); recommendation algorithm (median of past 3 months + fallback) — completed 2026-05-19
- [x] **Phase 14: ADR-016 Frontend + ARB Reconciliation (TOOL-V2-02)** — `HomeHeroCard` rebuild (累加 ring + sage-green→gold color state machine); AnalyticsScreen Variant ε redesign (density KPI retired); Settings UI (`monthly_joy_target` config + recommended-value display); ARB key reconciliation (density-related keys removed/renamed across ja/zh/en); 100%-behavior gate (no discrete events per ADR-012 §2 / ADR-016 §5); golden regen for 0% / 50% / 100% / >100% states (completed 2026-05-19)
- [x] **Phase 15: Custom Time Windows (HAPPY-V2-02)** — Week / month / quarter / year / arbitrary date-range selector wired across all Joy metrics in AnalyticsScreen; selection persists per session; HomeHero remains month-anchored (per ADR-016 ring semantics) (completed 2026-05-19)
- [x] **Phase 16: Per-Category Breakdown + Soul-vs-Survival Comparison (HAPPY-V2-01 + STATSUI-V2-01)** — Per-category satisfaction breakdown view in AnalyticsScreen; Soul-vs-Survival happiness comparison surface with anti-toxicity framing (descriptive only, no value-judgment language) (completed 2026-05-20)
- [ ] **Phase 17: Manual-Only Joy Sub-Metric (HAPPY-V2-03)** — Schema migration adding `transactions.entry_source` column; backend filter for manual-only Joy variant; AnalyticsScreen toggle to switch between full and manual-only Joy metric

## Phase Details

### Phase 13: ADR-016 Backend Foundation
**Goal**: Stabilize the Joy-metric backend on `Σ joy_contribution` (replacing density) and ship the schema + recommendation infrastructure that Phases 14 and 17 will consume, so every downstream UI consumer builds on a single, locked Joy expression.
**Depends on**: Nothing (first v1.2 phase; consumes v1.1's stable HAPPY domain as input)
**Requirements**: JOYMIG-02, JOYMIG-05
**Success Criteria** (what must be TRUE):
  1. `GetHappinessReportUseCase` returns `Σ joy_contribution = Σ (soul_satisfaction × (amount / base)^0.88)` (no division by Σ amount); density (Joy/¥) computation is removed from the use case and DAO; verified by use-case + DAO tests.
  2. `AppSettings.monthlyJoyTarget int?` persists via SharedPreferences (`settings_repository_impl.dart`); round-trip getter/setter unit test green; no v1.1 baseline data lost (settings keys are additive, not replacing).
  3. Recommendation algorithm computes `ceil(median(past 3 complete months Σ joy_contribution))` when ≥3 months of soul data exist; falls back to spike-decided hardcoded baseline otherwise; algorithm covered by unit tests including outlier-sensitivity case.
  4. 1-day spike has decided and documented (in plan deliverable) the fallback baseline number, the outlier-truncation policy, and whether recommended value persists in UI after user configuration.
  5. ADR-016 §2 single-Joy-expression constraint holds across the use case, DAO, and formatter layers — `grep -r 'density' lib/` returns only deprecation notes or removed-call comments; no live density code path remains.
**Plans**: 7 plans
  - [x] 13-01-PLAN.md — Correct ROADMAP SC-2 wording (SharedPreferences not Drift) per D-02
  - [x] 13-02-PLAN.md — Replace joy_density_formatter with joy_cumulative_formatter; preserve ptvfBaseFor
  - [x] 13-03-PLAN.md — Add AppSettings.monthlyJoyTarget int? + SharedPreferences round-trip (D-01/D-03)
  - [x] 13-04-PLAN.md — Rewrite GetHappinessReportUseCase fold to Σ joy_contribution; rename HappinessReport field + DAO method
  - [x] 13-05-PLAN.md — Spike simulation + 13-SPIKE.md (fallback baseline, outlier policy, persistence behavior)
  - [x] 13-06-PLAN.md — GetMonthlyJoyTargetRecommendationUseCase + Riverpod provider wiring
  - [x] 13-07-PLAN.md — Density rip (delete trend/daily files), HomeHero rename, AnalyticsScreen histogram gate rewire, grep gate verification

### Phase 14: ADR-016 Frontend + ARB Reconciliation (TOOL-V2-02)
**Goal**: Ship the user-facing redesign of HomeHero and AnalyticsScreen on the new `Σ joy_contribution` backend, plus the Settings target-configuration UI and ARB cleanup, so the end-user perceives the full ADR-016 migration in one coherent surface.
**Depends on**: Phase 13 (backend use case, schema, recommendation algorithm must be locked first)
**Requirements**: JOYMIG-01, JOYMIG-03, JOYMIG-04, JOYMIG-06, TOOL-V2-02
**Success Criteria** (what must be TRUE):
  1. `HomeHeroCard` central numeric display shows `Σ joy_contribution` and the ring fill is driven by `min(current / active_target, 1.0)` where `active_target` is the user-configured `monthly_joy_target` or the recommended value from Phase 13.
  2. HomeHero ring resets to 0% on the 1st of each calendar month (verified by clock-injection test) and increments monotonically as soul transactions are committed within the month.
  3. Ring color transitions smoothly from sage green `#47B88A` (soul ledger green) to gold across 0%-100%; at and beyond 100% it stays at gold saturation with no oscillation, no second-cycle re-color, no discrete pulse; goldens regenerated for 0% / 50% / 100% / >100% states.
  4. **100% behavior contract (ADR-012 §2 + ADR-016 §5) holds** — at and beyond 100% the app produces no copy text, no toast, no snackbar, no notification, no haptic feedback, no celebration animation, no `>100%` percentage display; verified by widget test asserting absence of these UI events.
  5. Settings screen exposes a numeric input for `monthly_joy_target`; when blank, copy displays the recommended value ("基于过去 3 个月，建议 X" / "Based on past 3 months, recommended X" / equivalent in zh); ARB keys exist in ja/zh/en parity and `flutter gen-l10n` succeeds without warnings.
  6. AnalyticsScreen renders `Σ joy_contribution` as the primary Joy KPI; density (Joy/¥) UI elements are removed (KPI strip, trend, distribution, story); ARB keys related to density are removed or renamed; `grep -r 'joyPerYen\|homeHappinessROI' lib/` returns 0 hits in live UI code.
**Plans**: 6 plans
  - [x] 14-01-PLAN.md — ARB foundation for JoyContribution, Settings target, and Analytics epsilon copy
  - [x] 14-02-PLAN.md — HomeHero active target data contract and ring ratio wiring
  - [x] 14-03-PLAN.md — HomeHero color state machine, 100% no-event contract, and 0/50/100/>100 goldens
  - [x] 14-04-PLAN.md — Settings monthly Joy target UI with neutral recommendation framing
  - [x] 14-05-PLAN.md — Analytics Variant epsilon Joy Index KPI ordering and cumulative value display
  - [x] 14-06-PLAN.md — Final density ARB cleanup, generated localization, and full verification sweep
**UI hint**: yes

### Phase 15: Custom Time Windows (HAPPY-V2-02)
**Goal**: Let users select week / month / quarter / year / arbitrary date ranges for AnalyticsScreen Joy metrics so the Joy story extends beyond the month-anchored HomeHero view.
**Depends on**: Phase 14 (AnalyticsScreen Variant ε must be the stable base; custom-window selector queries the new `Σ joy_contribution` metric established in Phase 13/14)
**Requirements**: HAPPY-V2-02
**Success Criteria** (what must be TRUE):
  1. AnalyticsScreen exposes a time-window selector with week / month / quarter / year / arbitrary-range options; selection persists across navigation within the same session (not across app restart in v1.2).
  2. All AnalyticsScreen Joy metrics (Σ joy_contribution KPI, trend, distribution, story cards) re-query and re-render against the selected window; use-case parameters accept arbitrary `(startDate, endDate)` pairs validated for `start <= end` and rejected for windows >12 months.
  3. HomeHero remains month-anchored and is **not** affected by the selector — ADR-016 §3 ring semantics (single-month accumulation, 1st-of-month reset) hold unchanged; verified by widget test.
  4. Selector and resulting metric labels respect ARB parity across ja/zh/en; no hardcoded date strings introduced; `DateFormatter` consumed for all date display.
  5. No cross-period delta UI is introduced (e.g., "this quarter vs last quarter" overlays) — ADR-012 §4 holds; verified by widget test asserting no delta-comparison surface exists.
**Plans**: 6 plans
  - [x] 15-01-PLAN.md — ARB foundation: 15 new analyticsTimeWindow* keys + retire MoM delta keys + analyticsKpiTotalLabel generalization
  - [x] 15-02-PLAN.md — TimeWindow Freezed sealed domain model + TimeWindowValidation helper (calendar-month math)
  - [x] 15-03-PLAN.md — Use-case (startDate, endDate) migration + display-anchor (Option A) + MoM delta UI retirement
  - [x] 15-04-PLAN.md — Provider re-keying + SelectedTimeWindow notifier + HomeScreen current-month adapter
  - [x] 15-05-PLAN.md — TimeWindowChip + TimeWindowPickerSheet widgets + DateFormatter additions
  - [x] 15-06-PLAN.md — AnalyticsScreen integration + MonthChipPicker deletion + HomeHero isolation lock + no-delta widget tests
**UI hint**: yes

### Phase 16: Per-Category Breakdown + Soul-vs-Survival Comparison (HAPPY-V2-01 + STATSUI-V2-01)
**Goal**: Extend AnalyticsScreen with two cooperative-framed surfaces — per-category satisfaction breakdown and Soul-vs-Survival happiness comparison — that deepen Joy insight without introducing value-judgment or competitive framing.
**Depends on**: Phase 14 (Σ joy_contribution backend), Phase 15 (time-window selector — per-category breakdown should respect user's selected window)
**Requirements**: HAPPY-V2-01, STATSUI-V2-01
**Success Criteria** (what must be TRUE):
  1. AnalyticsScreen renders a per-category satisfaction breakdown showing category name, average satisfaction, and entry count (e.g., "Coffee shops: 8.2 avg / 12 entries") for soul-ledger transactions within the active time window from Phase 15.
  2. Per-category breakdown respects min-N filtering (categories with <3 entries grouped or suppressed) consistent with v1.1 SharedJoyInsight contract — single-data-point categories never crowned.
  3. AnalyticsScreen renders a Soul-vs-Survival "Ledger · This window" surface displaying both ledgers' engagement metrics (entry count + total spend), with the Soul column additionally showing average satisfaction. Copy is descriptive only — no value-judgment terms (better/worse/winner/loser/vs framing) — verified by ARB review + widget assertion of forbidden-substring absence in all three locales.
  4. New AnalyticsScreen widgets follow v1.1 Variant ε / δ-derived layout conventions; goldens added for both surfaces in light + dark themes (if applicable per current theme support).
  5. ADR-012 §6 holds — no per-family-member breakdown is introduced anywhere in the comparison surface; only ledger-type aggregates are shown.
**Plans**: 10 plans
  - [x] 16-01-PLAN.md — ROADMAP SC-3 wording correction to engagement-axis framing (D-15)
  - [x] 16-02-PLAN.md — ARB additions: 17 new keys across en/ja/zh for Phase 16 surfaces
  - [x] 16-03-PLAN.md — Domain models: PerCategorySoulBreakdown + LedgerSnapshot (SurvivalLedgerSnapshot has NO avgSatisfaction — D-04 type-system gate)
  - [x] 16-04-PLAN.md — DAO methods (4) + _survivalExpenseFilter + repository interface/impl + DAO unit tests
  - [x] 16-05-PLAN.md — Application use cases (4): per-category single + family-aggregate; soul-vs-survival single + family-aggregate
  - [x] 16-06-PLAN.md — Riverpod providers: new state_ledger_snapshot.dart (4 providers) + repository_providers extension
  - [x] 16-07-PLAN.md — PerCategoryBreakdownCard widget + widget tests + light/dark/group goldens
  - [x] 16-08-PLAN.md — SoulVsSurvivalCard widget + widget tests + light/dark/group goldens
  - [x] 16-09-PLAN.md — Anti-toxicity widget test (trilingual forbidden-substring sweep across both cards × 3 locales × 4 states)
  - [x] 16-10-PLAN.md — AnalyticsScreen integration (Distribution composition + _refresh()) + home_screen_isolation_test extension
**UI hint**: yes

### Phase 17: Manual-Only Joy Sub-Metric (HAPPY-V2-03)
**Goal**: Ship a manual-entry-only Joy sub-metric variant so users can audit Joy data quality by excluding voice-estimated entries, completing the v1.1-deferred HAPPY-V2-03 work.
**Depends on**: Phase 13 (schema-migration tooling/pattern), Phase 14 (AnalyticsScreen Variant ε base for the toggle UI)
**Requirements**: HAPPY-V2-03
**Success Criteria** (what must be TRUE):
  1. Schema migration adds `transactions.entry_source` column (enum/string: `manual` / `voice` / future values); existing rows backfill to a documented default; round-trip migration test green and no data loss verified.
  2. Voice-entry code path stamps `entry_source = 'voice'` on new transactions; manual-entry code path stamps `entry_source = 'manual'`; verified by integration tests covering both entry surfaces.
  3. When manual-only is selected, every data card on AnalyticsScreen re-queries with entry_source = 'manual' filter (including total spend / category distribution / 6-month trend / largest expense / Soul-vs-Survival both columns). HomeHero and Settings recommendation remain unaffected (SC-4).
  4. HomeHero remains unaffected by the toggle — HomeHero ring continues to reflect all entries per ADR-016 §3 (toggle is an analytics-side audit lens, not a global metric switch); verified by widget test.
  5. ARB keys for the toggle and explanatory copy exist in ja/zh/en parity; `flutter gen-l10n` succeeds; copy is neutral (no implication that voice entries are "less valid", only that the toggle "excludes voice-estimated entries").
**Plans**: 8 plans
  - [x] 17-01-PLAN.md — Correct ROADMAP Phase 17 SC-3 wording to whole-AnalyticsScreen audit-lens framing (D-16)
  - [x] 17-02-PLAN.md — Drift schema v16→v17: entry_source column + customStatement migration + round-trip test (D-01/D-04/D-05)
  - [x] 17-03-PLAN.md — EntrySource enum + Transaction Freezed field + TransactionSyncMapper extension with manual fallback (D-01/D-03/D-09)
  - [x] 17-04-PLAN.md — TransactionDao + repo impl + CreateTransactionParams required-no-default + 3 push sites (voice/manual/demo); OCR untouched (D-02/D-06/D-07/D-08)
  - [x] 17-05-PLAN.md — AnalyticsDao 12+ methods gain EntrySource? entrySourceFilter; predicate-drift constants byte-identical; repo interface re-emitted; DAO tests (D-15/D-17)
  - [x] 17-06-PLAN.md — 11 use-case execute() signatures gain entrySourceFilter; recommendation use case byte-identical; 3 representative use-case tests (D-15)
  - [x] 17-07-PLAN.md — ARB ×3 trilingual lockstep + state_joy_metric_variant provider + JoyMetricVariantChip widget + family-key extensions; anti-toxicity + chip-flow tests (D-10..D-14/D-18)
  - [x] 17-08-PLAN.md — AnalyticsScreen integration (AppBar chip + _refresh) + HomeHero isolation test extension + entry-path-stamping + sync round-trip integration tests (SC-2/SC-3/SC-4/D-03/D-09)
**UI hint**: yes

## Current Status

**Active milestone:** v1.2 Happiness Metric Refresh (in progress)
**Current phase:** Phase 17 (executing)

## Progress

| Milestone | Phases | Plans Complete | Status | Shipped |
|-----------|--------|----------------|--------|---------|
| v1.0 Codebase Cleanup Initiative | 1-8 | 48/48 | Complete | 2026-04-29 |
| v1.1 Happiness Metric & Display | 9-12 | 40/40 | Complete | 2026-05-05 |
| v1.2 Happiness Metric Refresh | 13-17 | 37/37 | In Progress | — |

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 13. ADR-016 Backend Foundation | 7/7 | Complete | 2026-05-19 |
| 14. ADR-016 Frontend + ARB Reconciliation | 6/6 | Complete | 2026-05-19 |
| 15. Custom Time Windows | 6/6 | Complete    | 2026-05-19 |
| 16. Per-Category Breakdown + Soul-vs-Survival | 10/10 | Complete    | 2026-05-20 |
| 17. Manual-Only Joy Sub-Metric | 8/8 | Complete | 2026-05-21 |
