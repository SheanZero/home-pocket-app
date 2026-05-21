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

## Milestone: v1.2 — Happiness Metric Refresh

**Shipped:** 2026-05-21
**Phases:** 5 | **Plans:** 37 | **Duration:** 3 days (2026-05-19 → 2026-05-21) | **Commits:** 212 | **Diff:** 521 files, +57,460 / -7,168 LOC

### What Was Built
- **ADR-016 Joy migration** (density → `Σ joy_contribution`): backend fold rewrite, DAO surface, formatter rename, density code-path deletion across `lib/`. Single Joy expression now enforced by grep + ARB parity.
- **HomeHero rebuild** with sage-green→gold target ring, `monthly_joy_target` user config, ceil-median 3-month recommendation, fallback baseline 50, and a structurally absent 100% discrete-event surface (ADR-012 §2 / ADR-016 §5 contract).
- **AnalyticsScreen Variant ε**: Joy Index promoted to primary KPI, density retired.
- **Custom Time Windows** (week/month/quarter/year/arbitrary) wired through 6 analytics use cases via Freezed `TimeWindow` + `TimeWindowValidation`; HomeHero stayed current-month-anchored via locally-derived bounds.
- **Per-Category Breakdown card** with min-N=3 filter + "Other" rollup; **Soul-vs-Survival comparison** with type-system gate (`SurvivalLedgerSnapshot` has no `avgSatisfaction`); anti-toxicity widget sweep (24 cases × 3 locales × 4 states).
- **Manual-Only Joy variant** on Drift schema v17 (`entry_source` column, CHECK ∈ {manual, voice, ocr}); `EntrySource? entrySourceFilter` threaded through 12+ use cases + 16 providers; AnalyticsScreen toggle chip; HomeHero isolation SC-4 enforced.
- **HomeHero isolation invariant** structurally enforced: source-grep guards against forbidden imports + `verifyNever` widget assertions for Phase 16 + 17 provider non-effects.

### What Worked
- **ADR-016 ratify before code**: locking the Joy formula migration in an ADR on Day 0 meant Phase 13 (backend) and Phase 14 (frontend) could ship in lockstep with zero contract churn.
- **Schema migration first, then frontend** (Phase 13 + 17 backend → Phase 14 + 17 frontend): kept producers and consumers cleanly separated.
- **Type-system gates over runtime checks**: `SurvivalLedgerSnapshot` literally not having `avgSatisfaction` (D-04) made it impossible to render the forbidden surface — better than any test.
- **Trilingual anti-toxicity sweep**: forbidden-substring lists per locale (en 15 terms, zh 13, ja 10) caught copy regressions structurally; faster + cheaper than design review.
- **Window-keying + variant-keying as separate provider tuple components**: layering Phase 15 (`startDate, endDate`) + Phase 17 (`joyMetricVariant`) into the same provider family without rewriting Phase 15 was a clean win.
- **HomeHero isolation enforced by tests**: both Phase 16 and Phase 17 added their own SC-4-style isolation checks; this paid off when the integration audit verified zero leaks at milestone close.
- **3-day milestone tempo**: tight enough to keep all 5 phases in working memory; ADR-016 lock kept rework off the table.

### What Was Inefficient
- **Phase 13 and Phase 17 shipped without VERIFICATION.md** — `/gsd:verify-work` was not run as a closing step. Integration check at milestone close picked up the slack but the per-phase verifier artifacts are missing (mirrors v1.0 FUTURE-DOC-05 pattern).
- **VALIDATION.md sign-off lagged**: 3 of 5 phases left `nyquist_compliant: false` / `wave_0_complete: false` despite the planner-checker step running. The frontmatter never flipped to `true`.
- **REQUIREMENTS.md status markers stayed stale through close** — Phase 16's VERIFICATION.md explicitly flagged the drift, but the orchestrator caught it only at milestone-close audit. Should be a per-phase closure step.
- **Phase 15 ARB drift broke `family_insight_card_test.dart`** (6 failures) and the failure surfaced 2 phases later in Phase 16's verification. ARB rewrites should immediately re-baseline their consumer tests.
- **Quick-task metadata format mismatch**: 3 quick tasks marked `Verified` in STATE.md but `missing` in the audit tool's internal scan — the tool isn't reading the canonical source.
- **`EntrySource.ocr` schema slot has no current writer**, which is fine forward-compat but worth tracking for MOD-005 to claim.

### Patterns Established
- **Type-system gates beat documentation gates**: missing-field-as-invariant is more durable than naming-convention warnings.
- **Forbidden-substring trilingual sweep** as a generic anti-toxicity / consistency tool — replicable for any future copy-sensitive surface.
- **Provider tuple composition**: when adding orthogonal data-fetch dimensions (window + variant), prefer extending the family key over forking providers.
- **Schema-additive migration with inline default backfill**: `ALTER TABLE … ADD COLUMN … NOT NULL DEFAULT 'manual'` in a single statement is cleaner than two-step add-then-update.
- **HomeHero isolation as a structural test convention** — every milestone that touches AnalyticsScreen should extend `home_screen_isolation_test.dart` with its new providers.

### Key Lessons
1. **Run `/gsd:verify-work <N>` as the last step of every phase** — the verifier artifact is the canonical evidence trail; "verified via integration check at milestone close" is acceptable but not equivalent.
2. **Flip REQUIREMENTS.md status markers in the same commit as the closing phase plan SUMMARY** — don't let the orchestrator catch staleness at milestone close.
3. **ARB key rewrites that change user-facing strings must re-baseline consumer widget tests in the same commit** — the Phase 15 → Phase 16 detection lag is the example.
4. **Treat schema additions with CHECK constraints as forward-compat contracts** — `EntrySource.ocr` was added with no current writer; document the future-claim explicitly.
5. **Type-system invariants beat runtime guards** — when the cost of a "wrong" surface is non-fixable (toxic comparison framing, gamification creep), structural absence is the right tool.
6. **Tight 3-day milestone is feasible when the ADR is locked first** — but only if every phase ships its own verification step.

### Cost Observations
- Model mix: not measured in local artifacts.
- Sessions: multi-session execution across Phases 13-17; multiple executor worktree merges visible in git log.
- Notable: 212 commits in 3 days; ~70 commits/day sustained. ~14k LOC of test additions vs ~16k LOC of `lib/` additions — close-to-1:1 test-to-code ratio.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | multi-session | 8 | Audit-driven cleanup established quality gates and documentation hygiene. |
| v1.1 | multi-session | 4 | Feature work resumed on top of cleanup baseline with ADR-first domain contracts and UI-specific verification. |
| v1.2 | multi-session, 3 days | 5 | ADR-016 Joy migration in lockstep with v1.1-deferred backlog; type-system invariants for anti-toxicity; HomeHero isolation as structural test contract; orthogonal-provider-tuple composition (window × variant). |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | cleanup/audit gates | ~74.6% global | n/a |
| v1.1 | full `flutter test` passed 1413 tests at Phase 12 close | not recomputed at milestone close | 0 new pub dependencies |
| v1.2 | full suite `+1430 All tests passed!` at Phase 14 close (with `--concurrency=1`); 6 pre-existing failures in `family_insight_card_test.dart` from Phase 15 ARB drift accepted as deferred | not recomputed at milestone close; ~6.5k LOC test additions | 0 new pub dependencies |

### Top Lessons

1. Keep planning files in sync with implementation status during each phase; stale planning metadata becomes expensive during milestone close.
2. Archive files should be generated before originals are removed, then manually curated for signal.
3. Human UAT debt is acceptable only when explicitly acknowledged and recorded as deferred close debt.
4. Per-phase VERIFICATION.md should be a hard closing step, not optional — integration-check-at-close is a backstop, not a substitute.
5. ARB rewrites must re-baseline consumer widget tests in the same commit; cross-phase test-string drift is silent for too long.
6. Type-system invariants (missing fields, sealed types) outperform documentation conventions when the forbidden surface is non-fixable.
7. ADR-first lock-in before code is the cheapest way to ship a tight (3-day) milestone with multiple consumer phases.
