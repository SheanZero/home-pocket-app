# Milestones — Home Pocket

Historical record of shipped versions. Each entry links to its full archive in `.planning/milestones/`.

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
