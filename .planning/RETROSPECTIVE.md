# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.1 — Happiness Metric & Display

**Shipped:** 2026-05-05
**Phases:** 4 | **Plans:** 40 | **Sessions:** multi-session GSD execution

### What Was Built
- Happiness metric domain: PTVF Joy-per-yen, Avg Satisfaction, Highlights count, Top Joy, sealed `MetricResult`, and soul-only filtering.
- Family aggregate-only Joy metrics with anti-leaderboard data shapes.
- HomePage `HomeHeroCard` replacing the previous split surfaces.
- AnalyticsScreen Variant δ unified dashboard with KPI, time, distribution, and story groups.
- Trilingual ja/zh/en Joy/Daily ledger copy rename and accepted ADR-015 lexical hierarchy.

### What Worked
- Locking formulas and ADRs before UI work kept Phase 10/11 consumers stable.
- Dedicated ARB rename phase avoided merge churn while large widgets were still moving.
- Wave-based execution with targeted verification caught generated/localization and golden drift quickly.
- Keeping family metrics aggregate-only prevented accidental leaderboard surfaces.

### What Was Inefficient
- Requirements status drifted behind implementation; milestone close had to repair stale `[ ]` and `Pending` rows.
- Auto-extracted milestone accomplishments were too noisy and required manual curation.
- Phase 11 still has human/device UAT debt; static tests covered structure but not final touch feel and device behavior.
- `STATE.md` carried stale progress fields after Phase 12 completion.

### Patterns Established
- Use `MetricResult` to keep empty/thin-sample states explicit instead of rendering raw zeros.
- Treat ledger terminology as a product-level lexical contract, not local widget copy.
- Use dedicated close-out phases for high-churn localization/spec alignment.
- Document anti-features (streaks, leaderboards, daily targets) as binding ADR constraints.

### Key Lessons
1. Milestone close needs a requirements/status parity check before archive generation.
2. Human UAT items should be either completed or deliberately deferred before `$gsd-complete-milestone`, not discovered at close.
3. GSD summary extraction is useful for raw recall, but final milestone summaries need editorial compression.
4. UI phases should keep final visual/device acceptance criteria explicit because widget and golden tests do not prove interaction feel.

### Cost Observations
- Model mix: not measured in local artifacts.
- Sessions: multiple executor/verifier/code-review sessions across Phases 9-12.
- Notable: fine-grained plans helped parallelism, but created a large volume of summary artifacts that needed curation at milestone close.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | multi-session | 8 | Audit-driven cleanup established quality gates and documentation hygiene. |
| v1.1 | multi-session | 4 | Feature work resumed on top of cleanup baseline with ADR-first domain contracts and UI-specific verification. |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | cleanup/audit gates | ~74.6% global | n/a |
| v1.1 | full `flutter test` passed 1413 tests at Phase 12 close | not recomputed at milestone close | 0 new pub dependencies |

### Top Lessons

1. Keep planning files in sync with implementation status during each phase; stale planning metadata becomes expensive during milestone close.
2. Archive files should be generated before originals are removed, then manually curated for signal.
3. Human UAT debt is acceptable only when explicitly acknowledged and recorded as deferred close debt.
