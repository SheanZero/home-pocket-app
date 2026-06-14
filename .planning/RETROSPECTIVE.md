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

## Milestone: v1.4 — 列表功能 (Transaction List)

**Shipped:** 2026-05-31
**Phases:** 7 (24-30) | **Plans:** 29 | **Duration:** ~3 days (2026-05-29 → 2026-05-31) | **Commits:** 283 (vs v1.3 tag) | **Diff:** 316 files, +51,409 / -2,207 LOC

### What Was Built
- **Data foundation** (Phase 24): `findByBookIds` multi-book query + `watchByBookIds` reactive stream; extracted shared `DateBoundaries` util (consolidated 6 month-boundary call sites); `SortField`/`SortDirection` enums.
- **Pure-Dart domain + use case** (Phase 25): Freezed `ListFilterState`/`ListSortConfig`, `GetListTransactionsUseCase` (execute/watch) + `GetListParams`; 8 Mocktail tests, no Riverpod.
- **Providers + shell wiring** (Phase 26): list providers with `keepAlive`-under-`IndexedStack` filter persistence; `ListScreen` replaces shell placeholder.
- **Calendar header** (Phase 27): `table_calendar` grid, `calendarDailyTotalsProvider` per-day expense totals (filter-isolated, `_dayKey` normalization), month nav, day-tap filter, month summary.
- **Tile + sort/filter bar** (Phase 28): `ListTransactionTile` (swipe-delete via `DeleteTransactionUseCase`, tap-to-edit), day grouping, sort + text search + ledger + multi-category filters AND-composed.
- **List screen + family** (Phase 29): full screen, pull-to-refresh (honest spinner, dual-invalidate), shadow-book merge, per-row member chip, member + "Mine only" filters.
- **i18n + empty states + golden polish** (Phase 30): 3-variant `ListEmptyState`, ja/zh/en ARB (533 keys/locale), golden baselines.

### What Worked
- **Strict bottom-up layer progression** (data → domain → providers → calendar → tile → assembly → polish) matched the Clean Architecture dependency flow; each phase was independently testable and the UI phases never blocked on shaky foundations.
- **Reusing the v1.3 edit/soft-delete path wholesale** — ROW-01/02 cost almost nothing because `TransactionEditScreen` + `DeleteTransactionUseCase` + shared form already existed; no new write/delete logic, hash-chain integrity preserved by construction.
- **Calendar provider isolation from filter state** (`calendarDailyTotalsProvider` watches only bookId/year/month) — deliberately NOT watching search/filter avoided re-rendering 31 day cells on every keystroke. Encoding the perf contract as a provider-dependency decision (D-06/D-09) beat optimizing later.
- **Shared `DateBoundaries` util before the 7th call site** — consolidating the `DateTime(y, m+1, 0, 23,59,59)` idiom as a utility rather than copy-pasting it again.
- **On-device visual pass batched at close** — running the release build on a physical iPhone and walking a 9-item checklist (incl. voice items needing a real mic) cleared a backlog of "Pending visual check" quick tasks in one sitting.

### What Was Inefficient
- **GAP-1 — incomplete invalidation set** (the headline issue): when Phase 26 added `listTransactionsProvider` invalidation at the two shell sites (post-sync, post-FAB) as "D-03 forward-wiring," it did NOT also invalidate `calendarDailyTotalsProvider` added in Phase 27. List refreshed; calendar totals + month summary stayed stale until pull-to-refresh. A clean Phase 26↔27 boundary bug that slipped every phase verification and was only caught by the milestone audit — then fixed as quick task 260531-u34 at close.
- **GAP-2 — speculative reactive infrastructure**: `watchByBookIds` was built across DAO/repo/use-case in Phase 24 (LIST-02's "stated mechanism") but every mutation site achieves reactivity via manual `ref.invalidate`, so the stream has zero consumers and the shell comments describing it are stale. Building the reactive chain before deciding the reactivity strategy produced dead code.
- **REQUIREMENTS.md LIST-03 drift — 5th consecutive milestone**: Phase 30 VERIFICATION marked LIST-03 ✓ SATISFIED but the REQUIREMENTS.md checkbox/traceability stayed `[ ]`/`Pending` until milestone-close reconciliation. Identical pattern to v1.0/v1.1/v1.2/v1.3.
- **Pending-visual-check accumulation**: 9 quick tasks across ~2 weeks sat at "Pending visual check" because the manual device pass was never run inline — they piled up and surfaced as open items at milestone close (resolved in one batch pass, but a recurring "verify-later→never" smell).
- **Draft-Nyquist VALIDATION.md — 5th consecutive milestone**: Phases 25/26/27/29/30 `nyquist_compliant: false`; documentation-grade debt accepted again.

### Patterns Established
- **Invalidation-set completeness check**: when adding a new reactive surface (e.g., a calendar provider), audit EVERY existing mutation/refresh site to ensure it invalidates the new provider too — a new read surface implicitly extends the contract of every writer. (Direct GAP-1 lesson.)
- **Decide the reactivity strategy before building the stream**: manual-`invalidate` vs `watch()`-stream is an architecture choice; pick one and wire it, don't build both. (Direct GAP-2 lesson.)
- **Provider-dependency narrowing as a perf contract**: for grid/aggregate providers, explicitly enumerate the minimal watched keys and document why broader state is excluded.
- **Batch on-device visual pass at close**: stack "needs human eyes" quick tasks into one device session (release build, scripted checklist, voice items on real hardware) rather than per-task context switches — but ideally run inline to avoid accumulation.

### Key Lessons
1. **A new reactive read surface silently extends every writer's invalidation contract** — GAP-1 is the canonical failure. When introducing `calendarDailyTotalsProvider`, the two existing shell invalidation sites needed it added; nothing flagged the omission until audit. Make "audit all invalidation sites" a checklist item whenever a provider gains a new consumer surface.
2. **Don't build reactive infrastructure you won't consume** — `watchByBookIds` (GAP-2) is 3 layers of dead code because the team defaulted to manual `ref.invalidate` everywhere. Decide the mechanism once.
3. **REQUIREMENTS.md status drift is now a 5×-recurring close cost** — the per-plan status-flip discipline still isn't holding. This is the single most repeated inefficiency across all milestones; it warrants automation (a close-gate that diffs VERIFICATION ✓ against REQUIREMENTS checkboxes).
4. **"Pending visual check" is a verify-later trap** — visual/device acceptance deferred inline tends to never happen until forced at close. Either run the device pass at each phase/quick-task close or explicitly track it as acknowledged debt.
5. **Reuse pays off massively at the edges** — ROW-01/02 (tap-to-edit, swipe-delete) were near-free because v1.3 built the shared form + delete use case. Bottom-up layering + prior-milestone reuse is why a 22-requirement feature shipped in ~3 days.

### Cost Observations
- Model mix: not measured in local artifacts (profile `balanced`; planner/executor/checker/verifier all `sonnet` per config).
- Sessions: multi-session GSD execution across Phases 24-30 + numerous quick tasks; executor worktree merges visible in git log.
- Notable: 283 commits, docs-heavy (162 docs / 50 feat / 26 test / 25 fix / 15 chore / 2 refactor) — the high docs ratio reflects GSD planning artifacts per phase. Schema unchanged at v17 (no migration). One new pub dependency (`table_calendar ^3.2.0`), vetted intl-0.20.2-compatible + iOS-build-green.

---

## Milestone: v1.5 — 文案与配色统一 (Vocabulary & Palette Unification)

**Shipped:** 2026-06-02
**Phases:** 5 (31-35) | **Plans:** 24 | **Duration:** ~2 days (2026-05-31 → 2026-06-02) | **Commits:** 155 (vs v1.4 tag) | **Diff:** 550 files, +43,552 / -4,650 LOC

### What Was Built
- **Terminology rename** (Phase 31): `LedgerType { daily, joy }` enum + 242 call sites; `Transaction.joyFullness` replaces `soulSatisfaction`; 25 ARB key roots + zh/ja/en values to 日常/悦己/ときめき/Daily/Joy; v17→v18 Drift migration (atomic stored enum-value rewrite + `soul_satisfaction`→`joy_fullness`) with a Wave-0 raw-sqlite3 contract test; ADR-017.
- **Palette selection** (Phase 32, artifact-only): 5 directions mined from 7 VoltAgent DESIGN.md refs → 5 Pencil schemes × 6 frames → user-selected Scheme D "Teal Clarity"; ADR-018 ratified post-selection with a full light+dark hex-per-role table.
- **Token system + dark rollout** (Phase 33): `AppPalette` ThemeExtension as sole color source; all `Color(0x…)` literals replaced; AppColors/AppColorsDark shims deleted; full dark mode via `context.palette.*`; 11 on-device visual items approved.
- **Golden re-baseline** (Phase 34): 50 masters re-based + 27 new dark (77 total, 34 dark); diff-attribution confirmed palette-only delta; suite 2281/2281, 79.0% coverage.
- **Residual leak closure** (Phase 35): W1 a11y Semantics labels → l10n; W2 `totalSoulTx`→`totalJoyTx` across Freezed models + use-cases + 9 tests — both found by the initial milestone audit.

### What Worked
- **Terminology-before-palette workstream ordering** (P31 → P32-34): landing the `survival→daily`/`soul→joy` symbol rename first meant the Phase 33 token system was built on already-renamed symbols — zero rename churn in the color work. The dependency was identified at roadmap time (D-12 seam) and paid off exactly as planned.
- **Single `AppPalette` ThemeExtension as the consolidation target**: collapsing two shims (AppColors + AppColorsDark) + scattered literals into one `context.palette.*` source made the grep gates trivially enforceable (0 literals, 0 shim refs, 0 `isDark` ternaries) and the dark rollout near-free (THEME-V2-02 pulled forward).
- **The audit→Phase-35 closure loop**: the milestone audit (not any phase verification) caught W1/W2 — vocabulary leaks that every phase gate had passed. Inserting a small dedicated closure phase rather than accepting them as debt produced a genuinely clean vocabulary surface, re-verified at re-audit (grep exit 1).
- **Golden diff-attribution protocol** (D-04): re-baselining 77 masters with an explicit "palette change is the ONLY delta" check (halt-on-suspected-regression) made a large visual churn safe and reviewable.
- **Migration contract test as Wave-0 RED** (Phase 31): pinning the v18 migration behavior in a raw-sqlite3 test before implementation caught the CR-01 `from<4` column-collision regression in review, not in production.

### What Was Inefficient
- **Grep gates under-scoped → an entire extra phase (W1/W2)**: the milestone's "no stale vocabulary" gates only covered ARB *values* (`lib/l10n/*.arb`) and lower-case `soul[A-Z]` identifiers. They missed (a) hardcoded English `Semantics(label:)` Dart string literals (W1, genuinely user-facing via screen readers) and (b) capital-S `totalSoulTx`/`SoulTx` identifiers (W2). Both evaded every Phase 31-34 gate and surfaced only at milestone audit, forcing Phase 35. A leak surface the gate doesn't scan reads as "clean."
- **Pencil MCP cannot flush `.pen` to disk in this env — recurring**: the committed `home-pocket-palette.pen` still holds v1 coral content; the v2 Teal schemes live only in ADR-018. Documented as D-03b best-effort/non-blocking across Phases 32 and 34, but it's a standing tooling limitation that makes the design file untrustworthy as a source of truth.
- **Draft-Nyquist VALIDATION.md — 6th consecutive milestone**: Phases 31/32/34/35 `nyquist_compliant: false` (only Phase 33 approved). Documentation-grade debt accepted yet again.
- **Sparse SUMMARY `requirements_completed` frontmatter — recurring**: most plan SUMMARYs list `[]`; REQs are attributed only to closing plans. The 3-source cross-reference fell back to VERIFICATION.md tables (which were complete) — but the frontmatter source remains unreliable.
- **`Book.*Balance` carve-out is real but deferred indefinitely**: the milestone unified vocabulary "everywhere except the books balance columns." Internally consistent, but the app still carries `survival_balance`/`soul_balance` DB columns — the vocabulary job isn't 100% done, it's 100%-of-scope done.

### Patterns Established
- **Scope grep gates to EVERY leak surface, not just the obvious one**: a vocabulary/identifier rename gate must cover ARB values + ARB keys + Dart string literals (incl. a11y labels) + identifiers in all letter-cases (`soul`, `Soul`, `SoulTx`). Enumerate the surfaces up front; a single-surface grep gives false confidence. (Direct W1/W2 lesson.)
- **ThemeExtension single-source as the canonical color-consolidation pattern**: one `AppPalette` accessed via `context.palette.*`, registered for both light+dark, with an architecture scan test forbidding `Color(0x…)` outside the theme layer — this is the repeatable recipe for killing scattered color literals.
- **Closing audit→fix phase for brownfield refactors**: when the milestone goal is "consistency," a dedicated post-implementation audit phase (or the milestone audit itself) is the only thing that reliably finds gate-evading residuals; budget for a small closure phase.
- **Re-audit after a closure phase**: re-run the milestone audit after the fix phase and re-verify the original gates live, rather than trusting the phase's own verification.

### Key Lessons
1. **A grep gate is only as good as its surface coverage** — W1/W2 passed every phase gate because the gates scanned ARB values + lower-case identifiers only. User-facing a11y string literals and capital-case identifiers were invisible. When defining a "zero stale X" success criterion, list all the file types and case variants X can hide in.
2. **The milestone audit is a real backstop, not a formality** — it caught what 5 phases of verification missed. The audit→Phase-35→re-audit loop is the pattern that actually produced a clean surface.
3. **Workstream ordering by dependency pays compounding dividends** — terminology-before-palette eliminated rename churn entirely; identifying the seam at roadmap time was worth more than any in-phase optimization.
4. **Draft-Nyquist is now 6×-recurring and the team has structurally accepted it** — either wire `/gsd-validate-phase` into the close flow or formally drop the Nyquist artifact expectation; carrying it as "debt" every milestone is noise.
5. **"Out of scope" carve-outs should carry an explicit exit plan** — `Book.*Balance` is correctly deferred, but without a scheduled DB-migration phase the residual vocabulary will linger indefinitely; deferral needs a destination.
6. **Tooling that can't persist its output isn't a source of truth** — the Pencil `.pen` flush failure means ADR-018's hex table is authoritative and the design file is decorative; recognize and route around non-persisting tools early.

### Cost Observations
- Model mix: not measured in local artifacts (profile `balanced`; planner/executor/checker/verifier per config).
- Sessions: multi-session GSD execution across Phases 31-35 + a milestone-audit → Phase-35 → re-audit close loop.
- Notable: 155 commits; one schema migration (v17→v18, with contract test + CR-01 regression fix); 0 new pub dependencies; the largest single source of churn was the 77-master golden re-baseline (Phase 34) and the 242-call-site enum rename (Phase 31).

---

## Milestone: v1.6 — 购物清单 (Shopping List)

**Shipped:** 2026-06-12
**Phases:** 4 (36-39) | **Plans:** 27 | **Duration:** phases ~2 days (2026-06-07 → 2026-06-08), quick-task hardening through 2026-06-12 | **Commits:** 369 (vs v1.5 tag) | **Diff:** 630 files, +58,316 / −3,400 LOC (includes post-v1.5 ADR-019 palette re-value)

### What Was Built
- **Data + domain foundation** (Phase 36): `shopping_items` table at schema v20 (nullable `completedAt` per D-03), reactive DAO, repository with note-encryption boundary, Freezed models + zero-Drift interface, import-guard coverage, `LedgerTypeSelector` → shared. CR-01: declared `customIndices` were never created by Drift → explicit `CREATE INDEX` in onCreate+onUpgrade + real-Drift `sqlite_master` assertion.
- **Use cases + sync** (Phase 37): 6 privacy-gated use cases; tracker + mapper; `ApplySyncOperationsUseCase` shopping branch (tombstone + sticky-complete); orchestrator flush; reactive round-trip integration test with no `ref.invalidate`.
- **UI shell** (Phase 38): full shopping UI (tile, filter bar, empty states, batch chrome, form), nav rename + icon, context-aware FAB with the SC1 accounting-regression gate (all 6 invalidations preserved).
- **i18n + goldens + smoke** (Phase 39): ARB parity, 54 golden baselines (user-approved), provider-layer reactive smoke test, 77.3% shopping coverage.
- **Post-phase hardening** (quick tasks): sort-mode UX rebuilt on a single `reorderBatch`→`applyOrder` mechanism after two on-device reorder bugs; form redesign; iOS keychain-accessibility startup fix (260610-ss7); audit W1/W2 closure (260612-daz: fullSync shopping push + receiver listType gate).

### What Worked
- **The v1.4 GAP-2 lesson was applied structurally, not aspirationally**: reactive `readsFrom:` delivery was a Phase 36 success criterion and was proven by tests at BOTH the repository layer (Phase 37 round-trip) and the provider layer (Phase 39 smoke). v1.6 shipped zero dead reactive code.
- **Three-layer privacy enforcement evolved through the audit loop**: Phase 37 shipped dual sender-side gates (use case + tracker); the milestone audit's integration checker found the receiver still trusted the wire (W2); 260612-daz added the receiver gate + listType pin. The audit→quick-task→re-verify loop (v1.5's Phase-35 pattern, now at quick-task granularity) again caught what phase gates missed.
- **Integration checker with executed proof**: this audit ran 32/32 cross-phase tests rather than existence checks, which is exactly how W1 (a comment claiming a safety net that didn't exist) was caught — grep would have read the comment and believed it.
- **Wave-0 TDD scaffolds across all 4 phases**: contract tests before production code caught CR-01 (Drift indices) and CR-01-P37 (remote update clobbering local sortOrder) in-phase.
- **User-directed 7→4 phase consolidation** held up: 27 plans in ~2 days with wave parallelism and no inter-phase rework.

### What Was Inefficient
- **Reorder UX needed 4 on-device fix iterations** (260609-pmc plans 03/04/05): single-row sort_order writes + fixed extreme values + visible-position drag indices interacted badly with non-contiguous values; the eventual fix (transactional whole-table re-sequence) is what should have shipped first. Lesson: for orderable lists, a single batch "apply this exact order" primitive beats incremental single-row writes.
- **A code comment asserted a nonexistent safety net** (W1): the tracker's "fullSync on next launch will reconcile" claim was wrong on three counts (no shopping support in fullSync, initialSync only fires on pairing, debounce already flushes on pause). Comments stating recovery guarantees need the same verification as code.
- **Draft-Nyquist VALIDATION.md — 7th consecutive milestone** (Phases 37/38/39 `nyquist_compliant: false`). The artifact expectation is structurally ignored; v1.5's lesson ("wire it into close flow or drop it") remains unactioned.
- **Quick-task `status:` frontmatter convention still never adopted** — audit-open now flags 38 cosmetic `missing` entries at every close; the noise grows each milestone.
- **260609-ruu shipped with "待真机确认"** and was still pending at close — the v1.4 "pending visual check" trap recurring at quick-task scale.

### Patterns Established
- **Batch reorder primitive**: `reorderBatch(orderedIds)` writing contiguous 0..N-1 in a transaction, consumed by both drag and move-to-extreme actions — ONE mechanism for any future orderable list.
- **Receiver-side validation for any synced entity with a privacy attribute**: never trust the wire; gate inbound ops on the privacy invariant and pin immutable fields to `existing.*` in merges.
- **Audit warnings fixed inline at close via quick task** (vs deferred): W1/W2 closed same-day with TDD + full-suite verification — cheaper than a v1.7 carry and keeps the milestone audit honest.
- **Integration checking must execute tests, not read code**: claims in comments and seams "wired by existence" both lie; the checker's executed-proof stance is the standard.

### Key Lessons
1. **Comments that promise recovery behavior are load-bearing and must be verified** — W1 existed because a comment asserted "fullSync will reconcile" and nobody checked; treat recovery/fallback claims in comments as testable specs.
2. **Sender-side enforcement of a privacy invariant is half an invariant** — any peer can run different code; SYNC-02/03 became real only when the receiver started validating (W2). For E2EE-synced data, enforce invariants at every trust boundary.
3. **For orderable lists, design the persistence primitive around "apply this exact order"** — incremental single-row sort_order writes accumulate non-contiguous values that break both drag and move-to-extreme semantics (4 fix iterations to learn this).
4. **The executed-proof integration check is worth its cost** — it caught a phantom safety net and a wire-trust gap that 4 phases of verification + 2500 tests missed.
5. **Behavior-changing fixes invalidate tests that encoded the old behavior** — the W2 receiver gate broke the D39-06 smoke test which awaited a DB write that no longer happens; when hardening changes a contract, sweep for tests asserting the old one (the failure mode is a hang/timeout, not an assertion diff).

### Cost Observations
- Model mix: profile `balanced` (planner/executor/checker/verifier = sonnet per config).
- Sessions: multi-session GSD execution across Phases 36-39 + audit → quick-task-closure → re-verify close loop.
- Notable: 369 commits; one schema migration (v20, with raw-sqlite3 contract test + real-Drift index assertion); 0 new pub dependencies; largest churn sources were the 54-golden baseline set (Phase 39) and the 8-plan UI phase (38).

---

## Milestone: v1.7 — 多币种支持 (Multi-Currency)

**Shipped:** 2026-06-14
**Phases:** 3 (40-42) | **Plans:** 20 | **Sessions:** multi-session GSD execution + quick-task hardening

### What Was Built
- Foreign-currency ledger entry end to end: SmartKeyboard currency selector (`CurrencySelectorSheet`, JPY-first, recent-use reorder, full-ISO search) + zh/ja voice currency detection, with the JPY-only path left byte-for-byte unchanged.
- Transaction-date historical-rate conversion from a free no-key API (Frankfurter primary + fawazahmed0 fallback) via a cache-first encrypted Drift table (`exchange_rates`, schema v20→v21), with offline fallback, weekend/holiday actual-date transparency, and manual override.
- Storage model: JPY-converted integer in the existing `amount` column (drives all lists/analytics/sorting unchanged) + three nullable sync-safe fields (original currency/amount/rate); single `convertToJpy()` conversion site; hash invariant preserved (ADR-021).
- Live JPY conversion preview, foreign-row list annotation, and a two-input/one-derived edit host (ADR-022 D-01; JPY read-only derived).
- Three ADRs (ADR-020 string rate precision / ADR-021 hash scope / ADR-022 edit policy) locked before migration code landed.

### What Worked
- ADR-first lock-in (three blocking ADRs in Phase 40 before any migration) again produced a tight, low-rework multi-phase milestone — same pattern that worked for v1.2.
- 3-phase consolidation (data+domain+sync / infra client+use-cases / presentation+voice with voice as a parallel wave) kept wave parallelism high; mirrors the v1.6 7→4 success.
- Wave-0 RED test scaffolds in every phase locked acceptance contracts (SC-5 7415 figure, D-07/D-08 decimal semantics, voice corpus, ADR-022 edit) as executable specs before implementation.
- The "single conversion site" + "never-block-save" invariants were stated as structural contracts up front, so the integration checker could verify them mechanically (zero inline `* rate`, zero HTTP in accounting use cases).
- The first external network dependency was introduced without compromising local-first/privacy — outbound rate queries only, no user data on the wire, fully offline via cache + manual rate.

### What Was Inefficient
- The Phase 42 `human_needed` verification flag was never flipped after `42-UAT.md` passed 4/4 — it surfaced as a false-positive "verification gap" at the pre-close audit, needing manual reconciliation.
- The CLI accomplishment-extractor produced garbage (commit hashes, file paths, code-review fragments) because phase SUMMARY.md `one_liner` frontmatter was left empty — the MILESTONES.md entry had to be hand-curated.
- Heavy late-stage quick-task churn (12+ tasks 06-13/14 on foreign-currency UI/edit/voice polish) indicates the Phase 42 plans under-specified the edit/display UX; more of it could have been caught in-phase.
- REQUIREMENTS.md footer said "21 total" while the traceability table + audit enumerated 23 — count drift in the same document.

### Patterns Established
- **Single-conversion-site invariant** for any derived-value feature — one function, grep-enforced, consumed everywhere; prevents preview-vs-stored divergence.
- **Exclude-from-hash ADR before schema migration** — adding fields to an integrity hash would invalidate existing chains; decide scope first, document rationale.
- **Two-input/one-derived** over bidirectional linked editing for any "N linked fields" UI — eliminates circular-update loops by construction (supersedes the original DISP-04 wording).
- **Wire-boundary triple validation** — sync ingestion validates the full field-group inline with `is`-typed checks and degrades partial/invalid peer payloads rather than persisting them.
- **Reversible compile-time feature flag** (`kOcrEntryEnabled`) to hide a not-yet-ready entry point without touching the reserved infrastructure.

### Key Lessons
- A verification flag that outlives its resolution is a close-time false positive — flip `human_needed`→resolved in the same commit as the UAT that clears it.
- Empty SUMMARY `one_liner` frontmatter makes the milestone-close accomplishment extractor useless — either populate it during execution or expect to hand-curate the entry.
- "Bidirectional linked editing" requirements are a circular-dependency trap — reframe as one-derived early (ADR-022 D-01 caught it before implementation).
- Introducing the first network dependency is the moment to make the privacy/offline invariants structural (no user data in URLs, never-block-save), not aspirational.

### Cost Observations
- Model profile: `balanced`; multi-session GSD execution + a long quick-task hardening tail.
- Notable: 197 commits (docs 93 / feat 42 / fix 34 / test 18); one schema migration (v20→v21); 1 new pub dependency (`connectivity_plus ^7.1.1`); largest churn was the 06-13/14 foreign-currency UI/edit/voice quick-task series.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | multi-session | 8 | Audit-driven cleanup established quality gates and documentation hygiene. |
| v1.1 | multi-session | 4 | Feature work resumed on top of cleanup baseline with ADR-first domain contracts and UI-specific verification. |
| v1.2 | multi-session, 3 days | 5 | ADR-016 Joy migration in lockstep with v1.1-deferred backlog; type-system invariants for anti-toxicity; HomeHero isolation as structural test contract; orthogonal-provider-tuple composition (window × variant). |
| v1.3 | multi-session, 5 days | 6 | Foundation-phase-first for multi-host widget convergence; parallel-safe phase split (voice parser ∥ manual UI); architecture invariant tests for resolver contracts; runtime extensibility tests as VOICE-06 proof; same-milestone cleanup phase (Phase 23) for debt absorption; code-review severity-bumping authority for production-risk gaps. |
| v1.4 | multi-session, 3 days | 7 | Strict bottom-up layer progression (data→domain→providers→UI); heavy reuse of prior-milestone edit/delete path; provider-dependency narrowing as an explicit perf contract; batched on-device visual pass at close. Surfaced two wiring smells: incomplete invalidation set (GAP-1) + speculative unused reactive stream (GAP-2). |
| v1.5 | multi-session, 2 days | 5 | First pure consistency/refactor milestone since v1.0. Dependency-ordered workstreams (terminology→palette→tokens→goldens) eliminated rename churn; ThemeExtension single-source consolidation; migration contract test as Wave-0 RED. Milestone audit caught two gate-evading vocabulary leaks (W1 a11y string literals, W2 capital-case identifiers) → dedicated Phase-35 closure + re-audit. |
| v1.6 | multi-session, ~2 days + quick-task hardening | 4 | User-directed 7→4 phase consolidation; Wave-0 TDD scaffolds in all phases; reactive-stream delivery as a stated success criterion (v1.4 GAP-2 lesson applied structurally); executed-proof integration check at audit caught a phantom-comment safety net (W1) and receiver wire-trust (W2) → closed inline via quick task 260612-daz (audit→quick-task→re-verify loop at quick-task granularity). |
| v1.7 | multi-session, ~2 days + long quick-task tail | 3 | User-directed 6→3 phase consolidation; three blocking ADRs before migration code; first external network dependency introduced with structural privacy/offline invariants (single `convertToJpy()` site, never-block-save, no user data in URLs); Wave-0 RED scaffolds as executable acceptance specs; heavy 06-13/14 quick-task UX-polish tail signals Phase-42 plans under-specified edit/display. |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | cleanup/audit gates | ~74.6% global | n/a |
| v1.1 | full `flutter test` passed 1413 tests at Phase 12 close | not recomputed at milestone close | 0 new pub dependencies |
| v1.2 | full suite `+1430 All tests passed!` at Phase 14 close (with `--concurrency=1`); 6 pre-existing failures in `family_insight_card_test.dart` from Phase 15 ARB drift accepted as deferred | not recomputed at milestone close; ~6.5k LOC test additions | 0 new pub dependencies |
| v1.3 | corpus tests: zh 48/50 (96%), ja 50/50 (100%); voice category corpus zh 30/30 + ja 31/31 (100%); 15 pre-existing failures carried (7 home_hero_card_golden + 4 home_hero_card widget + 4 merchant_database); 9/9 device UATs (Phase 19+20+22 carry) pass in Phase 23 | not recomputed at milestone close; ~10.2k LOC test additions (1.56:1 test-to-code ratio) | 0 new pub dependencies |
| v1.4 | 2238/2238 tests pass at quick-task checkpoints; golden baselines re-based for list/calendar/tile; 9 quick-task visual checks confirmed on-device 2026-05-31; `flutter analyze` 0 issues | not recomputed at milestone close | 1 new pub dependency (`table_calendar ^3.2.0`, intl-0.20.2-compatible, iOS-build-green) |
| v1.5 | 2281/2281 tests pass (full suite, golden incl.); 77 golden masters re-baselined to teal (34 dark) with diff-attribution; `flutter analyze` 4 pre-existing infos (0 regressions); v18 migration contract test + CR-01 regression test green | 79.0% filtered coverage (≥70% gate) | 0 new pub dependencies |
| v1.6 | 2588/2588 tests pass at close (full suite incl. goldens); 54 new shopping golden baselines (user-approved); `flutter analyze` 0 issues; v20 migration contract test (raw-sqlite3 + real-Drift index assertion) green; 32/32 cross-phase integration tests executed at audit | 77.3% on shopping modules (≥70% gate); global not recomputed | 0 new pub dependencies |
| v1.7 | 2786/2786 tests pass at close (full suite incl. goldens); voice currency corpus ≥5 cases/currency/locale; CNY symbol goldens re-baselined; `flutter analyze` 0 issues; v21 migration + null-safe sync round-trip + partial-triple invariant tests green; 6/6 cross-phase integration seams verified at audit; Phase 42 4/4 device UAT passed | not recomputed at milestone close | 1 new pub dependency (`connectivity_plus ^7.1.1`, iOS-build-green) |

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
12. **(v1.4)** A new reactive read surface silently extends every writer's invalidation contract — when a provider gains a new consumer (e.g., a calendar grid), audit ALL existing `ref.invalidate` sites to add it (GAP-1). Make it a checklist item.
13. **(v1.4)** Decide the reactivity mechanism (manual `invalidate` vs `watch()` stream) once, then wire only that — building both leaves dead code (GAP-2).
14. **(v1.4)** REQUIREMENTS.md status drift is now 5×-recurring — escalate from "remember to flip it" to an automated close-gate diffing VERIFICATION ✓ against REQUIREMENTS checkboxes.
15. **(v1.4)** "Pending visual check" is a verify-later trap — deferred device/visual acceptance accumulates until forced at close; run inline or track as acknowledged debt.
16. **(v1.5)** A "zero stale X" grep gate is only as good as its surface coverage — scope it to every file type and case variant X can hide in (ARB values + keys + Dart string literals + identifiers in all letter-cases). W1/W2 passed 5 phases of gates because the gates scanned ARB values + lower-case identifiers only.
17. **(v1.5)** The milestone audit is a genuine backstop — it caught W1/W2 when every phase verification missed them; the audit→closure-phase→re-audit loop is what produced a clean surface. Don't treat the audit as a formality.
18. **(v1.5)** Dependency-ordered workstreams beat in-phase optimization — terminology-before-palette eliminated rename churn entirely; identify the cross-phase seam at roadmap time.
19. **(v1.5)** Draft-Nyquist is now 6×-recurring and structurally accepted — either wire `/gsd-validate-phase` into the close flow or formally drop the artifact expectation.
20. **(v1.5)** "Out of scope" carve-outs need a scheduled destination — `Book.*Balance` is correctly deferred but will linger indefinitely without a planned DB-migration phase.
21. **(v1.6)** Comments promising recovery behavior are testable specs — the tracker's "fullSync will reconcile" claim was false on three counts and survived 4 phases of gates; verify fallback claims, don't read them.
22. **(v1.6)** Privacy invariants on synced data must be enforced at every trust boundary — sender-side gates alone are half an invariant; the receiver must validate and pin immutable fields.
23. **(v1.6)** Orderable-list persistence should be a batch "apply this exact order" primitive (`reorderBatch` → contiguous 0..N-1), not incremental single-row writes — learned over 4 on-device fix iterations.
24. **(v1.6)** When a hardening fix changes a behavioral contract, sweep for tests encoding the old contract — the failure mode is a timeout/hang (awaiting an emission that no longer fires), not a clean assertion diff.
25. **(v1.7)** A `human_needed` verification flag that outlives the UAT clearing it becomes a close-time false positive — flip it in the same commit as the passing UAT, or the pre-close audit re-surfaces a resolved gap.
26. **(v1.7)** Empty SUMMARY `one_liner` frontmatter makes the milestone-close accomplishment extractor produce garbage (hashes, paths, review fragments) — populate it during execution or budget for hand-curation at close.
27. **(v1.7)** For any derived-value feature, declare a single conversion function up front and grep-enforce it — "no inline arithmetic anywhere" is mechanically verifiable and prevents preview-vs-stored divergence (the ADR-020 `convertToJpy()` site).
28. **(v1.7)** Decide hash/integrity scope via ADR *before* a schema migration adds fields — retrofitting fields into an integrity hash invalidates every existing chain (ADR-021 excluded them by design).
29. **(v1.7)** "N linked editable fields" requirements are a circular-update trap — reframe as two-input/one-derived early (ADR-022 D-01 voided the original "bidirectional" DISP-04 wording before it became code).
30. **(v1.7)** A heavy post-phase quick-task UX-polish tail (12+ tasks over 2 days) is a signal the UI phase's plans under-specified interaction/display detail — fold more of that into the phase plan or a dedicated polish wave.
