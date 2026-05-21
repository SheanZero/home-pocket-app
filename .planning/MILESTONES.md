# Milestones — Home Pocket

Historical record of shipped versions. Each entry links to its full archive in `.planning/milestones/`.

---

## v1.2 — Happiness Metric Refresh

**Shipped:** 2026-05-21
**Phases:** 13-17 (5 phases, 37 plans, 63 tasks)
**Duration:** 2026-05-19 → 2026-05-21 (3 days)
**Tag:** `v1.2`
**Audit Status at Close:** `tech_debt` — milestone goal achieved with documentation-grade close debt accepted (Phase 13/17 missing VERIFICATION.md; 3 VALIDATION.md drafts with `nyquist_compliant: false`). Mirrors v1.0 FUTURE-DOC-05 pattern. See `.planning/milestones/v1.2-MILESTONE-AUDIT.md`.
**Known deferred items at close:** 6 items (2 verification gaps, 1 Nyquist gap, 1 stale test from Phase 15 ARB drift, 1 forward-compat schema slot, 1 quick-task metadata drift) — see `.planning/STATE.md` Deferred Items §v1.2.

### Delivered

The Home Pocket Joy metric is now expressed as `Σ joy_contribution` (cumulative per-month) per ADR-016, superseding the v1.1 density (Joy/¥) formulation. HomeHero shows a single-month accumulation ring against a user-configurable `monthly_joy_target` with sage-green→gold color interpolation; AnalyticsScreen Variant ε retired density and added Custom Time Windows, Per-Category breakdown, Soul-vs-Survival comparison (anti-toxicity framed), and a Manual-Only Joy audit-lens variant. Drift schema migrated to v17 (`transactions.entry_source` column). HomeHero isolation invariant (ADR-016 §3) is structurally enforced by test guards across Phases 15-17.

### Key Accomplishments

1. **ADR-016 Joy migration shipped end-to-end** — `Σ joy_contribution = Σ (soul_satisfaction × (amount / base)^0.88)` replaces density (Joy/¥) as the single Joy expression. `lib/` is density-free (`grep -rn 'density|joyPerYen|homeHappinessROI' lib/` returns 0 hits); ARB density vocabulary fully scrubbed across ja/zh/en at 487 keys parity.
2. **HomeHero target ring + user-configurable target** — sage-green `#47B88A` → gold smooth color interpolation with clamp at 100% (no oscillation, no discrete events at threshold per ADR-012 §2 / ADR-016 §5). `monthly_joy_target` persists in SharedPreferences; recommended value = `ceil(median(past 3 months Σ joy_contribution))` when ≥3 months data, else fallback baseline 50 (Phase 13 spike decision).
3. **AnalyticsScreen Variant ε with Custom Time Windows** — Freezed `TimeWindow` sealed value object (week/month/quarter/year/arbitrary), `TimeWindowValidation` calendar-month guard, `selectedTimeWindowProvider` session state, AppBar `TimeWindowChip` + `TimeWindowPickerSheet`. Six analytics use cases migrated to `(startDate, endDate)`; HomeHero remains current-month-anchored.
4. **Per-Category Breakdown + Soul-vs-Survival comparison shipped with type-system invariants** — `PerCategoryBreakdownCard` with min-N=3 filter + "Other" rollup. `SoulVsSurvivalCard` Soul column shows entries + spend + avgSatisfaction; Survival column shows entries + spend only — enforced by `SurvivalLedgerSnapshot` Freezed class having no `avgSatisfaction` field (D-04 type-system gate). Trilingual anti-toxicity widget sweep (24 cases × 3 locales × 4 states) passes.
5. **Manual-Only Joy variant on schema v17** — `ALTER TABLE transactions ADD COLUMN entry_source TEXT NOT NULL DEFAULT 'manual' CHECK ∈ {manual, voice, ocr}`. `EntrySource? entrySourceFilter` threaded through 12+ use cases + 16 analytics providers + DAO `AND entry_source = ?` clauses. `JoyMetricVariantChip` toggle on AnalyticsScreen AppBar; HomeHero isolation SC-4 enforced (variant toggle does not affect HomeHero providers).
6. **HomeHero isolation invariant structurally enforced** — `lib/features/home/` has zero hits for `selectedTimeWindowProvider`, `state_time_window`, `state_joy_metric_variant`, or `joyMetricVariant`. `home_screen_isolation_test.dart` combines source-grep guards, Phase 16 `verifyNever` assertions, and Phase 17 SC-4 variant-toggle non-effect verification.

### Stats

- **Commits since v1.1 tag:** 212
- **Files changed:** 521 (+57,460 / -7,168 LOC); `lib/` +15,828 / -5,189; `test/` +8,034 / -1,565
- **Phase commit distribution:** 13: 26, 14: 17, 15: 36, 16: 39, 17: 32
- **Requirements:** 11/11 v1.2 requirements complete (8 fully verified, 3 partial-due-to-missing-VERIFICATION.md with integration-check substitute evidence)
- **ARB parity:** 487 keys per locale (ja=zh=en)
- **Drift schema:** v16 → v17 (single column addition + inline backfill default)

### Notable Decisions

- ADR-016 ratify (2026-05-19) consciously broke v1.1 baseline purity to consolidate density retirement and target-ring rebuild into a single coherent milestone (ADR-016 §1 accepted cost).
- HomeHero ring is **single-month accumulation only**; no cross-period delta surfaces (hard ADR-012 §4 boundary).
- HomeHero ring at and beyond 100%: **no copy, no toast, no notification, no haptic, no celebration animation** — only ambient color change (hard ADR-012 §2 / ADR-016 §5 contract; verified by widget test asserting absence of all event paths).
- Monthly Joy target fallback baseline = 50 (Phase 13 spike-decided); revisit after real-user data collected.
- `SurvivalLedgerSnapshot` deliberately lacks `avgSatisfaction` field (D-04) — type-system gate against value-judgment framing on the survival ledger.
- Family privacy hardening (FAMILY-V2-01/02/03) explicitly out of v1.2 scope to keep Joy-axis focused; remains v2 backlog.
- Phase 13 + 17 shipped without running `/gsd:verify-work` — integration check at milestone close acts as backstop; documented as v1.2 close debt for retroactive backfill.

### Archive

- `.planning/milestones/v1.2-ROADMAP.md` — full phase details
- `.planning/milestones/v1.2-REQUIREMENTS.md` — final requirement status + v2 backlog
- `.planning/milestones/v1.2-MILESTONE-AUDIT.md` — pre-close audit report (status: `tech_debt`)
- `.planning/milestones/v1.2-phases/` — archived phase directories (13-17)

---

## v1.1 — Happiness Metric & Display

**Shipped:** 2026-05-05
**Phases:** 9-12 (4 phases, 40 plans)
**Tag:** `v1.1`
**Audit Status at Close:** `known_debt` — milestone goal achieved; one Phase 11 human UAT verification item acknowledged as deferred
**Known deferred items at close:** 1 verification gap (Phase 11 `11-VERIFICATION.md` human UAT); see `.planning/STATE.md` Deferred Items.

### Delivered

Home Pocket now has a v1.1 happiness metric layer and UI surface: personal Joy metrics, aggregate-only family Joy insights, an integrated HomeHeroCard, a unified AnalyticsScreen dashboard, and final ja/zh/en product copy aligned to the 悦己 / ときめき / Joy lexical hierarchy.

### Key Accomplishments

1. **Happiness metric domain locked** — schema v16 default satisfaction semantics, sealed `MetricResult`, PTVF Joy-per-yen math, Top Joy ordering, soul-only filtering, and family aggregate-only contracts are implemented and verified.
2. **Anti-gamification decisions codified** — ADR-012/013/014/015 capture no-gamification, Joy density scaling, unipolar satisfaction semantics, and trilingual lexical hierarchy.
3. **HomePage rebuilt around Joy context** — `HomeHeroCard` replaces the previous monthly overview, ledger comparison, and SoulFullness surfaces with rings, split bar, Best Joy story, and group-mode family rows.
4. **AnalyticsScreen Variant δ shipped** — unified KPI strip plus Time, Distribution, and Story groups render total-ledger and Joy-ledger analytics through use cases/providers, with v1.0 analytics widgets removed.
5. **Trilingual copy rename completed** — ARB values for Joy/Daily ledger language, Joy density/index labels, satisfaction ladder, and `satisfactionExcellent` are updated across ja/zh/en; ADR-015 is accepted.
6. **Verification baseline passed** — final Phase 12 gates included `flutter analyze`, full `flutter test` (1413 tests), ARB parity, hardcoded-CJK scan, picker tests, analytics widget tests, and refreshed HomeHeroCard goldens.

### Stats

- **Files archived:** `.planning/milestones/v1.1-ROADMAP.md`, `.planning/milestones/v1.1-REQUIREMENTS.md`
- **Phase execution:** 4 phases, 40 plans, 80 GSD tasks
- **Requirements:** 29/29 v1.1 requirements complete
- **Timeline:** 2026-05-01 → 2026-05-05

### Notable Decisions

- Strict per-member family analytics consent is deferred to v1.2 (`FAMILY-V2-03`) rather than partially shipping schema/settings work.
- ARB key renames are deferred (`TOOL-V2-02`); v1.1 changed values only to avoid wider generated-code churn.
- Voice estimator range realignment is deferred (`HAPPY-V2-03`) because v1.1 locked picker semantics first.
- One Phase 11 visual/device UAT item remains human-needed and is accepted as known close debt.

### Archive

- `.planning/milestones/v1.1-ROADMAP.md` — full phase details
- `.planning/milestones/v1.1-REQUIREMENTS.md` — final requirement status + v2 backlog

---

## v1.0 — Codebase Cleanup Initiative

**Shipped:** 2026-04-29
**Phases:** 1-8 (8 phases, 48 plans)
**Duration:** 2026-04-25 → 2026-04-28 (~4 days)
**Tag:** `v1.0`
**Audit Status at Close:** `tech_debt` — milestone goal achieved with deferred items accepted as known debt
**Known deferred items at close:** ~17 items across 4 categories (see Tech Debt Carried Forward in archive). None are blockers; FUTURE-TOOL-03, FUTURE-QA-01, FUTURE-DOC-01..06 are tracked for v1.1+.

### Delivered

An audit-driven, severity-ordered refactor of the Home Pocket Flutter codebase that established a hybrid (automated + AI semantic) audit pipeline, eliminated all 50 known findings across the 4 categories (layer violations, redundant code, dead code, Riverpod hygiene), added characterization-test coverage on touched files, swept architecture documentation, and re-ran the full audit pipeline to verify zero remaining violations. Result: `REAUDIT-DIFF.json` reports `resolved=50, regression=0, new=0, open_in_baseline=0`.

### Key Accomplishments

1. **Hybrid audit pipeline operational** — 4 automated scanners + AI semantic-scan workflow + machine-readable `issues.json` + 4 permanent CI guardrails (`import_guard`, `riverpod_lint`, `coverde` per-file ≥70%, `sqlite3_flutter_libs` rejection)
2. **Zero open findings on re-audit** — 50 resolved, 0 regression, 0 new (REAUDIT-DIFF.json)
3. **Architectural debt eliminated** — Family-sync use cases moved to Application layer; Domain purity enforced; provider hygiene locked (single `repository_providers.dart` per feature, `keepAlive` reconciled, `ResolveLedgerTypeService` deleted, 33 presentation→infrastructure imports rerouted)
4. **i18n + dead-code cleanup** — All hardcoded CJK extracted to ARB; ARB key parity enforced; MOD-009 references deleted; `CategoryService` collision eliminated; 3 Drift indices added with v15 migration
5. **Coverage safety net** — `coverage_gate.dart` per-file gate (164 files, 0 failed at 70%) with `--deferred` mechanism for 10 explicit exceptions; global `very_good_coverage@v2` ≥70% (74.6% achieved)
6. **Documentation aligned** — All ARCH/MOD/ADR/CLAUDE.md updated; ADR-011 v1.1 amendment records cleanup outcome with commit-level traceability

### Stats

- **Initiative commits:** 315 (since 2026-04-25)
- **Files changed:** 1,061 (+282,686 / -100 lines, including tests + tooling + audit artifacts)
- **Languages:** Dart / Flutter
- **Requirements:** 54/54 complete (42 fully verified, 12 partial-due-to-bookkeeping with substitute evidence)

### Notable Decisions

- Coverage threshold amended 80→70% post-cleanup (FUTURE-TOOL-03 to revisit after v1 feature work)
- Smoke-test execution deferred to v1 release as owner-driven gate (FUTURE-QA-01)
- Mocktail big-bang migration chosen over CI-generated `*.mocks.dart` (HIGH-07)
- Documentation sweep centralized at Phase 7 rather than per-phase (avoids churn)
- ADR-011 v1.1 amendment uses 4-layer narrative (honest documentation pattern) rather than retrospective clean-win framing

### Archive

- `.planning/milestones/v1.0-ROADMAP.md` — full phase details
- `.planning/milestones/v1.0-REQUIREMENTS.md` — final requirement status + v2 backlog
- `.planning/milestones/v1.0-MILESTONE-AUDIT.md` — pre-close audit report
