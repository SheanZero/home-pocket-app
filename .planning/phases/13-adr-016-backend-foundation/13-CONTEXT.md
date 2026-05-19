# Phase 13: ADR-016 Backend Foundation - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 13 is the **backend foundation phase** of v1.2. It locks the Joy expression migration from density (Joy/¥) to `Σ joy_contribution` at the use case + DAO + formatter layer, and ships the `monthly_joy_target` persistence + recommendation infrastructure that Phase 14 will consume to drive the HomeHero ring and Settings UI.

**Delivered surface:**
- Backend formula migration: `Σ joy_contribution = Σ (soul_satisfaction × (amount / base)^0.88)` (no division by Σ amount); density path removed from `GetHappinessReportUseCase`, DAO Σ-amount column (if any) simplified, formatter layer renamed/replaced.
- New use case `GetMonthlyJoyTargetRecommendationUseCase` in `lib/application/analytics/` returning `MetricResult<int>` (recommended monthly Joy target from past 3 months median; Empty when <3 months of soul data exist or all zero).
- `AppSettings.monthlyJoyTarget: int?` field + SharedPreferences-backed persistence (no Drift schema bump).
- 1-day spike (Phase 13 plan deliverable) producing a short Markdown report that decides: fallback baseline number (anchor 50, may adjust within [30, 100] based on demo-data simulation), outlier-truncation policy (none — rely on median robustness), recommendation persistence behavior (always show in Settings UI when configured).
- AnalyticsScreen density UI removal: `joy_trend_line_chart.dart` and its container section wrapper deleted; `dailyJoyPerYen` provider deleted; `GetDailyJoyPerYenUseCase` + `DailyJoyPerYenPoint` model deleted.
- HappinessReport model: `joyPerYen: MetricResult<double>` field retired in favor of `joyContribution: MetricResult<...>` (exact field name + numeric type → planner discretion; see §Claude's Discretion).
- HomeHero `home_hero_card.dart` minimal migration: field rename (`happiness.joyPerYen` → `happiness.joyContribution`), KPI tile switches to `formatJoyCumulative`, ring fill math kept at Phase-13-baseline (the redesign is Phase 14).
- ROADMAP SC-2 and REQUIREMENTS.md JOYMIG-02 wording corrections (drop "schema migration adds user_settings.monthly_joy_target" framing; replace with SharedPreferences round-trip semantics).

**Not delivered in Phase 13** (downstream phases):
- HomeHero ring color state machine (sage green → gold), monthly reset, 100% behavior contract → Phase 14 (JOYMIG-01, JOYMIG-03, JOYMIG-04, JOYMIG-06).
- Settings UI for `monthly_joy_target` configuration + dual display (user value + recommended) → Phase 14.
- ARB key rename for density vocabulary (`homeJoyPerYen` etc.) across ja/zh/en → Phase 14 (TOOL-V2-02).
- AnalyticsScreen Variant ε redesign → Phase 14.

</domain>

<decisions>
## Implementation Decisions

### Persistence for `monthly_joy_target`

- **D-01 SharedPreferences, not Drift.** `monthly_joy_target` extends the existing `AppSettings` Freezed model and persists via `settings_repository_impl.dart` (SharedPreferences-backed). **No new `user_settings` Drift table is created.** Schema version stays at 16.
  - **Why:** Current `AppSettings` already covers theme / language / notifications / biometric lock / voice language via SharedPreferences. A single nullable integer for a Joy target does not justify a schema bump. The encryption argument is weak: `monthly_joy_target` is a personal preference number, not a soul transaction; it leaks no spend pattern and does not need SQLCipher protection.
  - **Cost accepted:** ROADMAP SC-2 wording deviation — addressed by D-02.

- **D-02 ROADMAP SC-2 and REQUIREMENTS.md JOYMIG-02 wording corrections are Phase 13 plan task #1.**
  - ROADMAP `.planning/ROADMAP.md` Phase 13 Success Criteria 2 currently reads: *"Schema migration adds `user_settings.monthly_joy_target` (INTEGER NULLABLE) with round-trip migration test green; existing rows nullable-default; no v1.1 baseline data lost."* Must be rewritten to: *"`AppSettings.monthlyJoyTarget int?` persists via SharedPreferences (`settings_repository_impl.dart`); round-trip getter/setter unit test green; no v1.1 baseline data lost (settings keys are additive, not replacing)."*
  - `.planning/REQUIREMENTS.md` JOYMIG-02 references "Phase 13 spike"; the spike scope is unchanged but no schema-related wording needs revising there.

- **D-03 Null encoding: key absence = null.** `prefs.getInt('monthly_joy_target')` returns null when never written. Setting the value to null is equivalent to `prefs.remove('monthly_joy_target')`. Domain layer types it as `int?`. No sentinel value, no parallel `isConfigured: bool` key. This matches the existing `_languageKey` / `_themeModeKey` pattern in `settings_repository_impl.dart`.
  - **Why:** Sentinel encoding ("store 0 for unconfigured") is a classic anti-pattern that distributes the "0 is special" rule across every consumer. Two-key encoding adds inconsistency surface for zero benefit at v1.2 volume.

- **D-04 Recommendation lives in its own use case: `GetMonthlyJoyTargetRecommendationUseCase`** in `lib/application/analytics/`. Not folded into `GetHappinessReportUseCase` (scope mismatch — recommendation queries past 3 months; HappinessReport is current-month-scoped). Not a Repository-layer helper (would skip the application layer, inconsistent with sibling happiness use cases).
  - Inputs: `bookId: String, currencyCode: String, asOf: DateTime` (asOf injectable for clock-injection tests).
  - Output: `MetricResult<int>` — Empty when <3 complete past-month soul transactions exist, Value(ceil(median(...)), sampleSize=count of months with data ≥1 tx).
  - DAO support: planner discretion — either reuse existing `getSoulRowsForPtvf` × 3 month calls (3 round-trips for 10–100 rows each is negligible) or add a new range method `getSoulRowsForPtvfRange(bookId, startDate, endDate)` returning all rows across the 3-month window with day/month grouping in Dart. Both are acceptable.

### Spike scoping (Phase 13 plan deliverable)

- **D-05 Spike form: demo-data-driven simulation + Markdown report.** Use `demo_data_service.dart` to seed 3–5 representative monthly soul-expense scenarios (e.g., low-frequency ¥10 candy month; mid-frequency ¥50-500 month; mixed high-amount month; high-density month with 30+ small transactions; very-low-engagement month with 2 transactions). Run the `Σ joy_contribution` formula in a throwaway Dart script (or test fixture) per scenario and tabulate. Output: one short Markdown file under `.planning/phases/13-adr-016-backend-foundation/13-SPIKE.md` (or equivalent) recording inputs, computed values, decided defaults, and rationale.
  - **Why a real simulation, not a judgment call:** ADR-016 §4 explicitly says "需基于早期种子数据测试" — judgment-only output would fail that wording.

- **D-06 Fallback baseline: anchor at 50, spike may adjust within [30, 100].** Starting point: 50, calibrated against the intuition that ~10 soul transactions at ¥500 / satisfaction=6 yields `10 × 6 = 60`. Spike may revise down to 30 (low-engagement protection) or up to 80 (avoid premature ring saturation for moderate users). Spike must not exit ADR-016 candidate range [30, 100] without a re-discussion.
  - The fallback applies whenever `<3` complete past-month soul records exist (matching ADR-016 §4 table row 2).

- **D-07 No outlier trimming on the median.** `ceil(median(Σ_M-1, Σ_M-2, Σ_M-3))` without per-month or per-transaction outlier filtering. The median itself is robust to a single extreme month within 3 data points; trimming would shrink the already-small sample and discard signal. Users override via manual `monthly_joy_target` configuration if the recommendation feels off.
  - Spike report records this as the explicit choice (rather than silently no-op).
  - Explicitly rejected: per-transaction trim (single-tx > 3× per-month p75 — ADR-013 already accepts large-tx attenuation via PTVF α scaling, so a second trim layer is redundant); month-level trim (drop max/min month → mathematically equivalent to median itself on 3 points).

- **D-08 Recommendation persistence in Settings UI: always-show dual display ("user value + recommended").** Settings UI permanently displays both the user-configured `monthly_joy_target` and the system-recommended value. After the user has configured their target, the recommendation does NOT disappear — it stays visible as a reference line ("系统推荐 X，基于过去 3 个月中位数").
  - **Hard constraint for Phase 14 ARB copy review:** the framing must be reference-only. No delta language ("高于建议 +N" / "低于推荐" / "比建议多 N" / arrow indicators / colored deltas). The recommendation is a parallel reference value, NOT a comparison target. This stays within ADR-012 §4 (no cross-period delta surfaces): the recommendation is a point estimate from history, presented neutrally, not a "this period vs that period" comparison.
  - Phase 14 reviewer (`gsd-ui-checker` or equivalent) must scan ARB ja/zh/en for forbidden delta substrings around the `monthly_joy_target` setting key cluster.

### Density-removal scope (Phase 13 boundary vs Phase 14)

- **D-09 Phase 13 = backend + AnalyticsScreen full rip; HomeHero = field rename + draft only.** Two-tier scope split inside the user-facing density removal.
  - **Phase 13 deletes / migrates:**
    - `lib/application/analytics/get_daily_joy_per_yen_use_case.dart` — deleted (entire file).
    - `lib/features/analytics/domain/models/daily_joy_per_yen_point.dart` (+ `.freezed.dart`) — deleted.
    - `lib/features/analytics/presentation/widgets/joy_trend_line_chart.dart` — deleted (widget + provider consumer).
    - `lib/features/analytics/presentation/providers/state_happiness.dart` — `dailyJoyPerYen` provider deleted (other providers stay).
    - `lib/application/analytics/get_happiness_report_use_case.dart` — `_computePtvfDensity` deleted; replaced by `_computeJoyContribution` (sum of `soul_satisfaction × (amount/base)^0.88`, no division by Σ amount).
    - `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` — file deleted; new file `joy_cumulative_formatter.dart` co-located (PTVF base map stays; display formatter rebuilt for integer + thousand-separator semantics — exact format → planner discretion within "integer + locale thousand-separator").
    - `lib/features/analytics/domain/models/happiness_report.dart` field `joyPerYen: MetricResult<double>` → `joyContribution: MetricResult<...>` (numeric type / field name → planner discretion, see §Claude's Discretion).
    - AnalyticsScreen `lib/features/analytics/presentation/screens/analytics_screen.dart` (or equivalent): the wrapping container that hosted the `JoyTrendLineChart` is also deleted (no placeholder, no SizedBox shim, no banner — screen reflows naturally). Phase 14's Variant ε will add the new structure in its own commit.
    - Affected tests: `test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart` deleted; `test/unit/application/analytics/get_happiness_report_use_case_test.dart` updated to assert `joyContribution` field shape and value semantics; `test/unit/infrastructure/i18n/formatters/joy_density_formatter_test.dart` deleted (replaced by `joy_cumulative_formatter_test.dart`); `test/unit/features/analytics/domain/models/happiness_report_test.dart` updated.
  - **Phase 13 HomeHero (minimal compile-clean migration):**
    - `lib/features/home/presentation/widgets/home_hero_card.dart`: field reference `happiness.joyPerYen` → `happiness.joyContribution` (single rename); `formatJoyDensity(...)` call → `formatJoyCumulative(...)`; tooltip key `_TooltipKey.joyPerYen` → renamed (e.g., `_TooltipKey.joyContribution`).
    - **Not touched in Phase 13:** ring color, monthly reset, 100% behavior, central numeric display layout, KPI tile copy, ARB key references (those keys keep their old strings for Phase 14 to rename in one ARB sweep with TOOL-V2-02). The ring fill math (`_outerSingle(...)`) is left at its Phase-13-baseline form (likely an arithmetic shim reading the new field) — Phase 14 redesigns this.
  - **Phase 14 owns:** HomeHero ring color state machine, monthly reset behavior, 100% behavior contract (per ADR-016 §5), Settings UI for `monthly_joy_target`, AnalyticsScreen Variant ε layout, ARB key reconciliation across ja/zh/en (TOOL-V2-02).

- **D-10 ROADMAP SC-5 "no live density code path" must be satisfied at Phase 13 close.** After Phase 13 commits land:
  - `grep -rn 'density' lib/ --include='*.dart'` returns only deprecation-style references inside ADR-013 doc text and possibly inside the Phase 13 plan's spike Markdown — NOT any executable code path.
  - `grep -rn 'joyPerYen\|joyDensity\|formatJoyDensity\|_computePtvfDensity' lib/ --include='*.dart' | grep -v .g.dart\|.freezed.dart` returns zero hits.
  - The "minimal HomeHero migration" (D-09) is what enables this — without renaming HomeHero's field references, the grep gate fails.

### ADR-013 disposition

- **D-11 ADR-013 already has the `## Update 2026-05-19: Superseded by ADR-016 §2` segment appended** (confirmed via `git log --oneline` and ratify commit `c256dd9`). Phase 13 does **not** append further updates to ADR-013. The active-formula portion of ADR-013 (PTVF α=0.88 + base-by-currency table) remains canonical and is cited by ADR-016 §2 by reference.
  - Phase 13 plan should reference ADR-013 (for PTVF base table + α value) and ADR-016 (for the Σ — non-ratio — formula). No new ADR is created in Phase 13.

### Claude's Discretion

- **HappinessReport field name + numeric type.** Choices: `joyContribution` / `cumulativeJoy` / `joyIndex` for the field name; `MetricResult<int>` (round at use case layer) vs `MetricResult<double>` (defer rounding to formatter) for the numeric type. The user explicitly did not select this gray area for discussion — planner picks per Phase 9 conventions (where `joyPerYen` was `MetricResult<double>`). Recommendation: keep `MetricResult<double>` to preserve precision through the model; the formatter rounds/floors at display. Field name: `joyContribution` is most descriptive and matches ADR-016 vocabulary.
- **DAO support strategy for the recommendation use case.** Choices: reuse `getSoulRowsForPtvf` × 3 month-specific calls vs add `getSoulRowsForPtvfRange(bookId, startDate, endDate)`. Either is acceptable at v1.2 transaction volumes. Recommendation: reuse 3× existing calls to minimize new DAO surface; revisit if Phase 17 (entry_source filter) wants overlapping range queries.
- **Spike report file location and exact format.** Recommendation: `.planning/phases/13-adr-016-backend-foundation/13-SPIKE.md`, mirroring CONTEXT.md/PLAN.md naming. Format: short Markdown with scenario table, computed Σ joy_contribution per scenario, decided defaults section, rationale section.
- **Test fixture strategy for the new use case and formatter.** Recommendation: extend the Phase 9 `valueMetric<T>` / `emptyMetric<T>` test helpers; reuse `demo_data_service.dart` data shapes where convenient; add fixtures for ≥3-months / 2-months / 0-months edge cases for the recommendation use case.
- **Drift DAO simplification.** Phase 13 deletes `_computePtvfDensity` (no Σ amount denominator), but `getSoulRowsForPtvf` still returns `(amount, soul_satisfaction)` tuples. The DAO method may be renamed (e.g., `getSoulRowsForJoyContribution`) or kept under the existing name; rename is preferred for clarity but not required. If renamed, all callers (`GetHappinessReportUseCase`, new recommendation use case) update accordingly.
- **`build_runner` regeneration ordering and atomic commit grouping.** Planner decides per existing project convention (CLAUDE.md: regenerate after `@freezed` / `@riverpod` / Drift table changes; AUDIT-10 CI guardrail catches stale generated files).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning (always)
- `.planning/PROJECT.md` — v1.2 milestone vision; explicitly accepts the v1.1-baseline-not-pure cost of ADR-016 ratify.
- `.planning/REQUIREMENTS.md` — Active v1.2 REQ list; Phase 13 owns JOYMIG-02 + JOYMIG-05; cross-phase constraints in §"Cross-Phase Constraints" (ADR-012, ADR-014, ADR-016 §2, ADR-013 append-only, CI guardrails, i18n parity).
- `.planning/ROADMAP.md` — Phase 13 Goal + 5 Success Criteria; SC-2 wording requires fixup per D-02; SC-3 (recommendation algorithm), SC-4 (spike outputs), SC-5 (no live density) are load-bearing.
- `.planning/STATE.md` — Current milestone state (planning, awaiting plan-phase).

### Phase 9 (v1.1) prior context — patterns and constraints that carry forward
- `.planning/milestones/v1.1-phases/09-happiness-domain-formula-layer/09-CONTEXT.md` — Phase 9 decisions D-04 (PTVF α=0.88, base by currency), D-13–D-16 (MetricResult contract), D-22 (ADR ratification path); the Phase 13 use case structure mirrors `GetMonthlyReportUseCase` per Phase 9 §code_context patterns.
- `.planning/milestones/v1.1-phases/11-statistics-surface-for/11-CONTEXT.md` — AnalyticsScreen Variant δ structure that Phase 13 partially demolishes (trend chart) and Phase 14 replaces (Variant ε).

### Architecture / ADRs (locked constraints)
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` — Decision §1–§8, especially §2 (single Joy expression), §4 (recommendation algorithm + TBDs), §5 (100% behavior contract — Phase 14 enforcement), §7 (Phase 13 must-haves checklist).
- `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md` — α=0.88 + base-by-currency table; superseded for Joy expression by ADR-016 §2 (append-only update already in place); PTVF base map citation source.
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — Forbidden features §2 (no achievements/badges), §4 (no cross-period delta — load-bearing for D-08 framing constraint), §5–§7 (no streaks, no public sharing, no leaderboards).
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` — `soul_satisfaction` default=2, scale 1..10 retained; do not alter.
- `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` — 5-layer architecture; Thin Feature rule.
- `docs/arch/01-core-architecture/ARCH-002_Data_Architecture.md` — Drift schema patterns (relevant only because Phase 13 explicitly does NOT bump schema; reference for "no schema migration was performed" justification in plan).
- `docs/arch/01-core-architecture/ARCH-004_State_Management.md` — Riverpod conventions; `state_<aggregate>.dart` naming pattern.

### Key source files (read for layer placement decisions)
- `lib/data/repositories/settings_repository_impl.dart` — SharedPreferences pattern for AppSettings; D-01 extends this file with `_monthlyJoyTargetKey` constant + `setMonthlyJoyTarget(int?)` method + read path in `getSettings()`.
- `lib/features/settings/domain/repositories/settings_repository.dart` — `SettingsRepository` abstract interface; needs `setMonthlyJoyTarget(int? value)` and (optionally) `getMonthlyJoyTarget()` methods added.
- `lib/features/settings/domain/models/app_settings.dart` (path inferred) — `AppSettings` Freezed model; needs `monthlyJoyTarget: int?` field added.
- `lib/application/analytics/get_happiness_report_use_case.dart` — current density fold path; Phase 13 deletes `_computePtvfDensity`, adds `_computeJoyContribution`, return type updated.
- `lib/application/analytics/get_daily_joy_per_yen_use_case.dart` — entire file deleted in Phase 13.
- `lib/data/daos/analytics_dao.dart` lines 230–411 — `getSoulRowsForPtvf` (kept, possibly renamed), `getSoulSatisfactionOverview`, `getSatisfactionDistribution` (all kept; only fold-side changes).
- `lib/features/analytics/domain/models/happiness_report.dart` (+ `.freezed.dart`) — `joyPerYen` field migration to `joyContribution`.
- `lib/features/analytics/domain/models/daily_joy_per_yen_point.dart` (+ `.freezed.dart`) — entire model deleted.
- `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` — replaced by `joy_cumulative_formatter.dart`; PTVF base map preserved (still needed by Σ joy_contribution math).
- `lib/features/analytics/presentation/widgets/joy_trend_line_chart.dart` — deleted; consumers in `analytics_screen.dart` and its wrapper section also removed.
- `lib/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart` — KEPT (reads `avgSatisfaction` + `medianSatisfaction`, no direct density dep).
- `lib/features/analytics/presentation/widgets/best_joy_story_strip.dart` — KEPT.
- `lib/features/analytics/presentation/providers/state_happiness.dart` — `dailyJoyPerYen` provider deleted; other providers kept; new `monthlyJoyTargetRecommendation` provider added per D-04.
- `lib/features/home/presentation/widgets/home_hero_card.dart` lines 362, 478–482, 818, 850 — field rename + formatter switch only. Visual redesign is Phase 14.
- `lib/data/app_database.dart` line 45 — `schemaVersion` stays at 16 (no bump for Phase 13).

### Project rules (CLAUDE.md and .claude/rules/)
- `CLAUDE.md` — Thin Feature rule; Drift TableIndex syntax (not used in Phase 13 — no new tables); Riverpod provider rules; common pitfall #2 (Domain must not import Data — relevant for new use case); `intl 0.20.2` pin; Joy/¥ family handling.
- `.claude/rules/arch.md` — ADR numbering protocol (Phase 13 does NOT add a new ADR); ADR append-only after status `✅ 已接受` (relevant when documenting Phase 13 close vs ADR-013).
- `.claude/rules/coding-style.md` — Immutability (use case + DAO return values), error handling, file size targets.
- `.claude/rules/testing.md` — TDD workflow; ≥70% per-file coverage on changed files (cross-phase CI constraint per REQUIREMENTS.md §Cross-Phase Constraints §5).
- `.claude/rules/worklog.md` — Phase 13 close requires a `doc/worklog/YYYYMMDD_HHMM_*.md` entry.

### External / academic sources (for ADR-013 / ADR-016 citation continuity)
- Kahneman & Tversky (1979). "Prospect Theory: An Analysis of Decision under Risk." *Econometrica*, 47(2), 263–292. — α=0.88 PTVF empirical fit (cited by ADR-013, carried forward by ADR-016 §2).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`GetMonthlyReportUseCase`** (`lib/application/analytics/get_monthly_report_use_case.dart`) — still the canonical use case template; new `GetMonthlyJoyTargetRecommendationUseCase` mirrors this structure (constructor-inject `AnalyticsRepository`, single `execute()` method, returns Freezed/sealed model).
- **`GetHappinessReportUseCase`** (`lib/application/analytics/get_happiness_report_use_case.dart`) — survives Phase 13 with fold logic rewritten; `Future.wait` parallelization pattern + Empty/Value branching + use of `ptvfBaseFor(currencyCode)` all stay.
- **`AnalyticsRepository`** (`lib/features/analytics/domain/repositories/analytics_repository.dart`) — extended with the recommendation-use-case DAO surface (either by reusing `getSoulRowsForPtvf` or adding a range variant per D-04 planner discretion).
- **`SettingsRepositoryImpl`** (`lib/data/repositories/settings_repository_impl.dart`) — extended in place with `_monthlyJoyTargetKey` private const + `setMonthlyJoyTarget(int?)` method + read path in `getSettings()`.
- **`MetricResult<T>` sealed type** (`lib/features/analytics/domain/models/metric_result.dart`) — reused for the recommendation use case output (`MetricResult<int>`).
- **`ptvfBaseFor(currencyCode)`** in current `joy_density_formatter.dart` — surviving function; moves into new `joy_cumulative_formatter.dart`. The `_ptvfBaseByCurrency` map definition is preserved verbatim.

### Established Patterns

- **One Drift table per file in `lib/data/tables/`** — Phase 13 adds NO new table (D-01). The `user_settings` Drift naming is deliberately NOT introduced.
- **AppSettings extension via SharedPreferences key constants** — keys are `static const String` private to the impl; getters wrap `_prefs.getXxx(key)` with default fallback; setters call `_prefs.setXxx(key, value)`; the new `monthlyJoyTarget` follows the same shape but with nullable int (null → `_prefs.remove(key)`).
- **Use Case Per Aggregate** — Phase 9 D-22; reapplied for `GetMonthlyJoyTargetRecommendationUseCase`.
- **Dart-layer PTVF fold** — Phase 9 D-04 carries forward; SQLite has no POW, all power-law math stays in Dart.
- **`state_<aggregate>.dart` Riverpod provider naming** — `state_happiness.dart` is the existing file; a new provider `monthlyJoyTargetRecommendation` joins it (does NOT warrant a new file).
- **Single `repository_providers.dart` per feature/domain** (CLAUDE.md rule) — new use case provider lives in `lib/application/analytics/repository_providers.dart` (or `lib/features/analytics/presentation/providers/repository_providers.dart` if that's the established home — planner verifies per current convention).

### Integration Points

- **Phase 13 → Phase 14 hand-off:** Phase 14 consumes:
  - `HappinessReport.joyContribution` (renamed field, populated by `GetHappinessReportUseCase`)
  - `AppSettings.monthlyJoyTarget` (configured value, possibly null)
  - `monthlyJoyTargetRecommendation` provider (recommended value, `MetricResult<int>`)
  - `formatJoyCumulative` formatter (display layer)
- **Phase 13 → Phase 17 hand-off:** Phase 17 adds `transactions.entry_source` schema column; Phase 13 leaves the underlying DAO/use case soul-only filter (`_soulOnly()` per Phase 9 D-01) untouched. The recommendation use case will inherit the "manual-only" toggle behavior in Phase 17 — the use case signature may need an optional `entrySourceFilter: EntrySource?` parameter in Phase 17 (NOT in Phase 13).
- **HomeHero ↔ Phase 13 backend:** HomeHero presentation already reads `state_happiness.dart` providers; field rename + formatter switch is the only change. The ring widget (`_RingPainter` or equivalent) keeps its current math.
- **Settings UI ↔ Phase 13 persistence:** Phase 14 builds the Settings screen control; Phase 13 only ships the persistence + recommendation read path. The Settings UI reads `currentAppSettingsProvider` + `monthlyJoyTargetRecommendationProvider`.

### Known forbidden patterns (CI-enforced or project policy)

- ❌ Adding a Drift `user_settings` table for the single `monthly_joy_target` field (D-01 rejection).
- ❌ Storing `monthly_joy_target` with a sentinel value (D-03 rejection — key absence is the null encoding).
- ❌ Folding the recommendation calculation into `GetHappinessReportUseCase` output (D-04 rejection — scope/range mismatch).
- ❌ Leaving any live density code path after Phase 13 (D-10 + ROADMAP SC-5).
- ❌ Outlier-trimming the recommendation median (D-07 rejection — relies on median robustness).
- ❌ Delta language ("higher than recommended", "+N from target") in Settings UI copy (D-08 framing constraint; load-bearing against ADR-012 §4).
- ❌ Phase 13 also redesigning the HomeHero ring color / monthly reset / 100% behavior (Phase 14 scope; D-09).
- ❌ Skipping `flutter pub run build_runner build --delete-conflicting-outputs` after `@freezed` / `@riverpod` / Drift changes (CLAUDE.md + AUDIT-10 CI guardrail).
- ❌ Renaming ARB keys in Phase 13 (TOOL-V2-02 is explicitly Phase 14).
- ❌ Adding a `dailyJoyContribution` daily trend use case in Phase 13 (Phase 14 Variant ε decides whether daily-Σ is reintroduced — Phase 13 only deletes the daily-density variant).

</code_context>

<specifics>
## Specific Ideas

These anchor downstream judgment calls:

- **"现在没有用户使用"** — pre-launch context, carried from Phase 9 (D-02). Means SharedPreferences is acceptable for `monthly_joy_target` without a data-migration story: no existing settings rows need backfill, and the absent-key-equals-null encoding causes zero behavior change for users who haven't configured.

- **"建议 X 始终显示" but framing limited to reference, not delta** — load-bearing for D-08 and the Phase 14 ARB review checklist. The user picked "always show both values" over "only show when unconfigured" — accepted on condition that copy stays reference-flavored, never comparative. This is the most likely cross-phase failure mode for v1.2 if Phase 14 isn't reviewed against it.

- **"50 作为始点拍板"** — D-06 anchor. Calibrated against "10 笔 ¥500 sat=6 → 60" mental model. Spike is the empirical correction, not the inventor.

- **"AnalyticsScreen 全奉, HomeHero 只草图"** — D-09 boundary. Codifies the user's intuition that Phase 13 is "rip and rebuild backend"; Phase 14 is "redesign user-facing surface." HomeHero's ring is the most visible user-facing surface and rightly belongs to the redesign phase, not the migration phase.

- **No new ADR in Phase 13** — D-11. ADR-016 already ratified, ADR-013 already has the supersede Update segment. Phase 13 implements existing decisions; it does not add new architectural debt.

</specifics>

<deferred>
## Deferred Ideas

### Out-of-Phase-13 — comes back in Phase 14 (still v1.2)

- HomeHero ring color state machine (sage green → gold), monthly reset, 100% behavior contract (ADR-012 §2 + ADR-016 §5 enforcement), central numeric display rebuild → Phase 14 (JOYMIG-01, JOYMIG-03, JOYMIG-04, JOYMIG-06).
- Settings UI control for `monthly_joy_target` (numeric input + dual display per D-08) → Phase 14.
- AnalyticsScreen Variant ε redesign (replace the deleted trend section + KPI strip rework) → Phase 14.
- ARB key rename across ja/zh/en for density vocabulary (`homeJoyPerYen`, `homeHappinessROI`, trend-chart strings, picker-tooltip strings) → Phase 14 (TOOL-V2-02).
- ARB framing review: forbidden delta substrings around `monthly_joy_target` cluster — required check per D-08.
- Golden regen for HomeHero 0% / 50% / 100% / >100% states → Phase 14.

### Out-of-Phase-13 — comes back in Phase 15+ (still v1.2)

- Custom time-window selector wired across all Joy metrics (HAPPY-V2-02) → Phase 15. Recommendation use case becomes parameterized by `(startMonth, endMonth)` if Phase 15 chooses to support multi-month custom windows for the target setting (TBD in Phase 15).
- Per-category satisfaction breakdown + Soul-vs-Survival comparison surface → Phase 16.
- `transactions.entry_source` schema migration + manual-only Joy variant toggle (HAPPY-V2-03) → Phase 17.

### Out-of-v1.2 — v1.3+ / future milestones

- Per-book `monthly_joy_target` (multi-book scenario) — currently single-target; Phase 14 may need to clarify what "current book" means for the Settings UI.
- Target history (user changes target over time; UI shows past values) — out of v1.2 scope; would justify a Drift table at that point.
- Multi-currency PTVF base extensions (EUR, GBP, KRW) — out of v1.2 scope; map is structured for trivial extension.
- v1.3+ re-evaluation of "Drift `user_settings` table" decision IF/when 2+ additional user-finance config fields accumulate (e.g., per-book target, weekly target override, target history). Today's SharedPreferences extension is the right call at v1.2 surface area; revisit when the surface area grows.

### Forbidden anti-features (never to be added — cross-phase boundary defense)

- ❌ Delta UI on Settings target ("你比建议 +N" / "你的目标比推荐低 X%") — D-08 constraint, ADR-012 §4 derivation.
- ❌ Multi-month progress ring on HomeHero (3-month average ring, year-to-date ring) — ADR-016 §3 monthly-anchored ring is the locked semantic.
- ❌ Recommendation that updates dynamically as the current month accumulates — recommendation strictly uses *past 3 complete* months, never the current in-progress month.
- ❌ Auto-adjust user-configured target based on actual achievement ("you exceeded 3 months, raise target?") — out of v1.2 scope, ADR-012 §2 risk.

### Reviewed Todos (not folded)

`cross_reference_todos` step was implicit — STATE.md's "Last activity" section did not surface any pending todos matching Phase 13's scope. The single v1.1-deferred Phase 11 human/device UAT item is unrelated to Phase 13.

</deferred>

---

*Phase: 13-ADR-016 Backend Foundation*
*Context gathered: 2026-05-19*
