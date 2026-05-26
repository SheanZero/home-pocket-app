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

## Milestone: v1.3 — 迭代帐本输入

**Shipped:** 2026-05-26
**Phases:** 6 (18-23) | **Plans:** 47 | **Duration:** 5 days (2026-05-22 → 2026-05-26) | **Commits:** 330 | **Diff:** 304 files, +64,157 / -4,747 LOC (`lib/` +6,559 / -2,197; `test/` +10,246 / -836)

### What Was Built
- **Shared details form foundation** (Phase 18): Single `TransactionDetailsForm` widget consumed by 4 hosts (manual, voice, edit, OCR review) via Freezed `TransactionDetailsFormConfig.when(.new/.edit)`; `UpdateTransactionUseCase` preserves `entry_source` verbatim; OCR two-step architectural slot reserved with MOD-005 marker.
- **Manual one-step + keypad polish** (Phase 19): `ManualOneStepScreen` collapses 2-screen entry chain; SmartKeyboard 48dp non-negotiable touch-target floor; 6 golden baselines (ja/zh/en × light/dark); DAO round-trip test for `entry_source='manual'`.
- **Voice number parser zh + ja** (Phase 20): Locale-aware numeral state machines (千/百/十/零/万) + JA numeral dictionary in `lib/infrastructure/voice/`; `VoiceChunkMerger` 2.5s continued-listening window via `SpeechRecognitionService.restartListen()`; zh corpus 96% + ja corpus 100% accuracy.
- **Voice category resolver L2 enforcement** (Phase 21): `VoiceCategoryResolver` always-L2 contract via `_ensureL2` 3-stage fallback (override → `${l1Id}_other` convention → `findByParent.first`); 19-L1 architecture invariant test; merchant DB + 59-entry synonym dict, both extensible without code changes (runtime-insert tests for 珍珠奶茶 + タピオカ).
- **Voice one-step integration + hold-to-record button UX** (Phase 22): `VoiceInputScreen` embeds `TransactionDetailsForm`; hold-to-record gesture via `RawGestureDetector` with `Duration.zero`; AnimatedContainer 180ms shape morph + AnimatedSwitcher caption swap to "录音中…"; Stopwatch test `<100ms` perceived state change. 2 BLOCKER gaps (G-01/G-02) elevated and closed.
- **v1.3 cleanup phase** (Phase 23): Scanner allow-list cleanup; 6 voice-flow surgical fixes (D-05/07/08/09/10/11); 4 mechanical polish items (D-12/13/14/15); REQUIREMENTS.md + 7 SUMMARY frontmatters reconciled; 9/9 carried device UATs run and passed; `voice_input_screen.dart` slimmed 838→776 LOC via `VoiceLocaleReadinessMixin` + pure-helper extraction.

### What Worked
- **Foundation phase first (Phase 18)**: shipping the shared `TransactionDetailsForm` before any host (manual, voice, edit, OCR) avoided 4× duplicate widget effort. The `Config.when(.new/.edit)` Freezed factory let each host parameterize behavior without subclassing.
- **Parallel-safe phase split**: Phase 20 (voice number parser) and Phase 19 (manual UI) ran concurrently because Phase 20 was deliberately UI-independent. Two-month timeline shrunk to ~3 days for shared parts.
- **Code-review gap elevation**: G-01 (recognizer self-termination) + G-02 (silent errors) were flagged advisory at Phase 22 close, then re-classified as BLOCKER before final SUMMARY. Plans 22-08/09/10 closed both before milestone audit. Pattern: code review with severity-bumping authority prevents production-risk debt from slipping into "advisory" buckets.
- **Cleanup phase inline (Phase 23) vs carrying to v1.4**: same-milestone debt absorption kept v1.3 close clean. 9 device UATs ran. 6 voice-flow surgical fixes + 4 mechanical polish items + REQUIREMENTS.md reconciliation + LOC-cap re-clear all fit in a single phase with 6 waves.
- **Architecture invariant tests for resolver contracts**: `category_other_l2_invariant_test.dart` enforced L1 → `${l1Id}_other` convention across 19 expense L1s, catching the `cat_other_expense` override at compile-time test. Cheaper than per-callsite enforcement.
- **Runtime extensibility tests as VOICE-06 proof**: inserting 珍珠奶茶 (zh) / タピオカ (ja) at test runtime and asserting the resolver picks them up was the exact "extensible without code changes" criterion — structural proof beats documentation.
- **Type-system invariants for OCR slot**: `EntrySource` Freezed enum + DAO CHECK constraint means OCR writer landing (MOD-005) requires only changing one literal at `ocr_review_screen.dart:54,58` — the schema slot is already claimed.

### What Was Inefficient
- **REQUIREMENTS.md drift through 5 phases**: 11/15 REQ-IDs were functionally satisfied but still marked `[ ]` / `Pending` until Phase 23 plan 23-07 reconciliation. Same staleness pattern as v1.2 Phase 16 — should be a per-plan closing step, not a milestone-close cleanup.
- **SUMMARY frontmatter `requirements-completed` not flipped**: Phase 18's 8 plans had empty frontmatter for INPUT-03/04 + EDIT-01/02 despite VERIFICATION.md marking them SATISFIED. Phase 19 had INPUT-01 missing from 19-03/05. Backfilled in Phase 23 plan 23-07.
- **VALIDATION.md (Nyquist) drift**: Phase 18 + 21 missing entirely; Phase 19/20/22 draft + `wave_0_complete: false`. Documentation-grade only but mirrors v1.0 FUTURE-DOC-05 / v1.2 close precedent for the 4th time. Should be a hard closing step.
- **Phase 20 architecture-scanner regression** (VOICE-SCANNER-ALLOWLIST): 3 NLP lexicon files in `lib/infrastructure/voice/` flagged by `hardcoded_cjk_ui_scan`; 8 `// ignore: avoid_print` in corpus tests flagged by `stale_suppressions_scan`. NLP data must remain CJK; print() needed for accuracy printers. Allow-list extension needed but not part of Phase 20's plan — surfaced in audit. Cleared 2026-05-24 commit `f04b978`.
- **`voice_input_screen.dart` LOC growth past CLAUDE.md `<800` cap**: ended Phase 22 at 832 LOC, 38 over cap. Closed in Phase 23 plan 23-09 via `VoiceLocaleReadinessMixin` + 3 pure helpers (countVoiceWords, extractVoiceKeyword, buildVoiceAudioFeatures) → 776 LOC. Pattern: voice screen will grow again as MOD-005 OCR consumer wires in — consider `VoiceInputController` notifier in v1.4+.
- **9 standing Phase 22 advisory warnings (WR-02/03/06/07/NEW-02/NEW-03)** + 3 INFOs — vacuous null check, async pipeline race, mocktail catch-all stub, listener closure equality, spurious tear-down toast, double-parse — all non-blocking but accumulate as voice-flow polish backlog. Pattern: code review with severity-keep authority lets advisory queue grow unchecked.
- **Device UAT timing**: 9 device UATs (6 carried + 3 from Phase 22) were stacked into Phase 23 plan 23-08 instead of being run inline at each phase close. This worked but means audit shows `human_needed` status for 3 of 6 phases mid-milestone.

### Patterns Established
- **Foundation widget phase first** when multiple host surfaces converge — costs one phase, saves 4× duplicate work.
- **Hold-to-record over tap-to-toggle** for mobile voice input — long-press is dominant pattern, reduces accidental activation. Document the choice + consistency-app-wide as an explicit decision.
- **Architecture invariant tests for resolver contracts** — when a fallback chain has a "must always return X" property, encode it as a test that iterates the input space (e.g., 19 expense L1s).
- **Runtime extensibility tests** — for "extensible without code changes" requirements, the test that inserts a new entry at runtime and asserts resolver picks it up is the canonical proof.
- **Cleanup phase inline at milestone close** for same-milestone debt absorption — Phase 23 pattern. Surgical fixes + documentation reconciliation + device UAT runbook + LOC-cap closure all fit one phase with wave parallelism.
- **`Config.when(.new/.edit)` Freezed factory** for multi-mode widgets — single widget, mode-parameterized behavior, no subclassing.
- **Stopwatch-bounded perceived state change tests** (`<100ms`) for UI interactions — encode perception threshold as test contract.

### Key Lessons
1. **Flip REQUIREMENTS.md status markers + SUMMARY frontmatter `requirements-completed` in the same commit as the closing phase plan** — milestone-close audit catching staleness is the 4th time this happened (v1.0, v1.1 Phase 11, v1.2 Phase 16, v1.3 Phase 23). Should be hard per-plan closing step.
2. **VALIDATION.md (Nyquist) is missing or draft for the 4th consecutive milestone** — documentation-grade debt but consistently accepted at close. Either make it a hard close gate or formally drop the requirement.
3. **Code review with severity-bumping authority prevents production-risk slippage** — G-01/G-02 elevation in Phase 22 worked. But advisory severity-keep also lets WR-* queue grow — need a counter-mechanism (e.g., voice-flow polish phase scheduled when WR count > 6).
4. **Same-milestone cleanup phase (Phase 23 pattern) > carry-to-next** — keeps v1.3 close clean, no carry-forward verification debt accumulation. Worth replicating when phase count allows.
5. **Foundation phase first when multiple hosts converge** — Phase 18 model is cheaper than parallel-host development.
6. **LOC cap (`<800` for feature screens) is a useful soft constraint but feature growth will push past it** — pattern is to extract mixins + pure helpers (Plan 23-09 model). For screens with growing controller state, consider Notifier extraction in v1.4+.
7. **Device UAT timing matters**: stacking all device UATs at milestone close (Phase 23 plan 23-08) works but masks `human_needed` status mid-milestone. Inline per-phase device UAT closure would be cleaner.
8. **Architecture-scanner allow-lists should be co-developed with the code that triggers them** — Phase 20 introduced NLP lexicon files without extending `hardcoded_cjk_ui_scan` allow-list. Same for corpus print() suppressions. Pattern: when adding files that legitimately trigger an existing scanner, extend the allow-list in the same commit.

### Cost Observations
- Model mix: not measured in local artifacts.
- Sessions: multi-session execution across Phases 18-23; multiple executor worktree merges visible in git log (worktree-agent-* branches).
- Notable: 330 commits in 5 days; ~66 commits/day sustained. Test additions (+10,246 LOC) substantially exceed lib additions (+6,559 LOC) — ~1.56:1 test-to-code ratio, reflecting heavy corpus fixture work in Phase 20 + 21 + Phase 23's regression tests.
- Phase 23 was 9 plans across 6 waves in a single phase — wave parallelism amortized cleanup cost across one-day execution.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | multi-session | 8 | Audit-driven cleanup established quality gates and documentation hygiene. |
| v1.1 | multi-session | 4 | Feature work resumed on top of cleanup baseline with ADR-first domain contracts and UI-specific verification. |
| v1.2 | multi-session, 3 days | 5 | ADR-016 Joy migration in lockstep with v1.1-deferred backlog; type-system invariants for anti-toxicity; HomeHero isolation as structural test contract; orthogonal-provider-tuple composition (window × variant). |
| v1.3 | multi-session, 5 days | 6 | Foundation-phase-first for multi-host widget convergence; parallel-safe phase split (voice parser ∥ manual UI); architecture invariant tests for resolver contracts; runtime extensibility tests as VOICE-06 proof; same-milestone cleanup phase (Phase 23) for debt absorption; code-review severity-bumping authority for production-risk gaps. |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | cleanup/audit gates | ~74.6% global | n/a |
| v1.1 | full `flutter test` passed 1413 tests at Phase 12 close | not recomputed at milestone close | 0 new pub dependencies |
| v1.2 | full suite `+1430 All tests passed!` at Phase 14 close (with `--concurrency=1`); 6 pre-existing failures in `family_insight_card_test.dart` from Phase 15 ARB drift accepted as deferred | not recomputed at milestone close; ~6.5k LOC test additions | 0 new pub dependencies |
| v1.3 | corpus tests: zh 48/50 (96%), ja 50/50 (100%); voice category corpus zh 30/30 + ja 31/31 (100%); 15 pre-existing failures carried (7 home_hero_card_golden + 4 home_hero_card widget + 4 merchant_database); 9/9 device UATs (Phase 19+20+22 carry) pass in Phase 23 | not recomputed at milestone close; ~10.2k LOC test additions (1.56:1 test-to-code ratio) | 0 new pub dependencies |

### Top Lessons

1. Keep planning files in sync with implementation status during each phase; stale planning metadata becomes expensive during milestone close (4× recurrence: v1.0, v1.1, v1.2, v1.3).
2. Archive files should be generated before originals are removed, then manually curated for signal.
3. Human UAT debt is acceptable only when explicitly acknowledged and recorded as deferred close debt.
4. Per-phase VERIFICATION.md should be a hard closing step, not optional — integration-check-at-close is a backstop, not a substitute.
5. ARB rewrites must re-baseline consumer widget tests in the same commit; cross-phase test-string drift is silent for too long.
6. Type-system invariants (missing fields, sealed types) outperform documentation conventions when the forbidden surface is non-fixable.
7. ADR-first lock-in before code is the cheapest way to ship a tight milestone with multiple consumer phases.
8. **(v1.3)** Foundation phase first when N hosts converge on shared infrastructure — costs 1 phase, saves N-fold duplicate work; `Config.when(.new/.edit)` Freezed factory is the canonical pattern.
9. **(v1.3)** Same-milestone cleanup phase (Phase 23 pattern) > carry-to-next for debt absorption — wave parallelism amortizes cleanup cost across one-day execution.
10. **(v1.3)** Code review needs severity-bumping authority for production-risk gaps (G-01/G-02 elevation from advisory to BLOCKER worked); also needs counter-mechanism for advisory-queue growth (e.g., voice-flow polish phase scheduled when WR count > N).
11. **(v1.3)** Architecture-scanner allow-lists must be co-developed with the code that legitimately triggers them — extend in same commit, not catch at audit.
