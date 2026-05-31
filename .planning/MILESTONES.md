# Milestones — Home Pocket

Historical record of shipped versions. Each entry links to its full archive in `.planning/milestones/`.

---

## v1.4 — 列表功能 (Transaction List)

**Shipped:** 2026-05-31
**Phases:** 24-30 (7 phases, 29 plans, 33 tasks)
**Duration:** 2026-05-29 → 2026-05-31 (~3 days; git range `v1.3..HEAD` spans 2026-05-26, including v1.3.x voice hotfix quick-tasks tagged after v1.3)
**Tag:** `v1.4`
**Audit Status at Close:** `tech_debt` — milestone goal achieved (22/22 requirements, 7/7 phases, 7/7 E2E flows). The one functional gap, GAP-1 (calendar staleness after family-sync / FAB), was closed at milestone close via quick task 260531-u34. Residual debt is non-blocking: GAP-2 (LIST-02 `watchByBookIds` reactive stream is dead code — reactivity achieved via manual `ref.invalidate`) and draft-Nyquist documentation debt (Phases 25/26/27/29/30 `nyquist_compliant: false`; Phase 28 approved). Mirrors v1.2/v1.3 close precedent. See `.planning/milestones/v1.4-MILESTONE-AUDIT.md`.
**Known deferred items at close:** see `.planning/STATE.md` Deferred Items §v1.4.

### Delivered

The placeholder List tab is now a full transaction overview in a Japanese-kakeibo layout. A `table_calendar` month header shows per-day expense totals (expense-only, own-book in v1.4), supports month navigation and tap-a-day-to-filter, and carries a current-month expense summary. Below it, a transaction list is sortable (date / edit-time / amount, with direction toggle), text-searchable (category · merchant · note), and filterable by ledger, multiple categories, and — in family mode — by member, all composing with AND logic and a one-tap clear. Rows reuse the v1.3 edit path on tap and route swipe-delete exclusively through `DeleteTransactionUseCase` (soft-delete, hash-chain preserved). When a family is joined, members' transactions (shadow books) merge in with per-row owner attribution and a "Mine only" shortcut. The list updates reactively after add / edit / delete / family-sync and supports pull-to-refresh; empty states have three distinct variants; all new strings ship in ja/zh/en with golden baselines.

### Key Accomplishments

1. **Data foundation + shared month-boundary util** (Phase 24) — `TransactionDao.findByBookIds(...)` multi-book query + `watchByBookIds(...)` reactive stream; extracted `DateBoundaries` utility to `lib/shared/utils/` consolidating the `DateTime(y, m+1, 0, 23,59,59)` idiom (6 prior call sites); `SortField` + `SortDirection` enums; 6 SC#1 DAO tests.
2. **Pure-Dart domain + use case** (Phase 25) — Freezed `ListFilterState` / `ListSortConfig` value objects, repository interface, and `GetListTransactionsUseCase` with `execute()` (Future + Result) and `watch()` (Stream) methods + `GetListParams` composite; 8 Mocktail tests covering SORT-01..04 forwarding, no Riverpod dependency.
3. **Providers + shell wiring** (Phase 26) — all list Riverpod providers wired with an explicit `keepAlive`-under-`IndexedStack` policy so filter/sort state persists across tab switches; `ListScreen` replaces the `main_shell_screen.dart` text placeholder (loading state reachable).
4. **Calendar header + month summary** (Phase 27) — `table_calendar` month grid with `calendarDailyTotalsProvider` per-day expense totals (`_dayKey` normalization contract, expense-only, isolated from filter state), month navigation, day-tap filter, and a `NumberFormatter`-formatted month summary; iOS build gate passed; human-approved render. (CAL-01..04)
5. **Transaction tile + sort/filter bar** (Phase 28) — `ListTransactionTile` (Dismissible swipe-delete via `DeleteTransactionUseCase`, tap-to-edit into the v1.3 `TransactionEditScreen`, ledger-color tag, tabular-figure amounts) + `ListDayGroupHeader` day grouping; sort/filter bar wiring text search + ledger + multi-category filters with AND composition. (LIST-01, ROW-01/02, SORT/FILTER)
6. **List screen assembly + family-aware** (Phase 29) — full screen with `RefreshIndicator` pull-to-refresh (honest spinner via dual-invalidate + `await .future.catchError`); shadow-book merge, per-row member chip attribution, per-member + "Mine only" filters guarded by `isGroupMode`; the `anyFilterActive` 5-condition fix (incl. `memberBookId`) mirrored across screen + bar. (LIST-04, FAM-01..04)
7. **i18n + empty states + golden polish** (Phase 30) — 3-variant `ListEmptyState` (no-data / no-match / loading-error), full ja/zh/en ARB coverage, and golden baselines; closes LIST-03.

Plus, at milestone close: **GAP-1 closed** (quick task 260531-u34) — `calendarDailyTotalsProvider(current month)` now invalidated at both shell sites (post-family-sync, post-FAB) so calendar totals + month summary refresh without pull-to-refresh.

### Stats

- **Commits since v1.3 tag:** 283
- **Files changed:** 316 (+51,409 / -2,207 LOC)
- **Commit categories:** docs 162, feat 50, test 26, fix 25, chore 15, refactor 2
- **Requirements:** 22/22 v1.4 requirements complete (LIST-03 checkbox reconciled at close — Phase 30 VERIFICATION had it ✓ SATISFIED)
- **ARB parity:** 533 keys per locale (ja=zh=en) — +27 from v1.3 baseline of 506
- **Drift schema:** unchanged at v17 (no migration this milestone)
- **New stack dep:** `table_calendar: ^3.2.0` (intl 0.20.2-compatible; no win32/native; iOS build verified green)

### Notable Decisions

- **Calendar per-day totals own-book only in v1.4** — combined family-calendar totals deferred to v1.5+ (CAL-02 family mode seam reserved; `bookId` is a single value in `calendarDailyTotalsProvider`).
- **Swipe-delete is confirm-only soft-delete, no undo SnackBar** — undo deferred (needs `RestoreTransactionUseCase`); deletion stays on the hash-chain-safe `DeleteTransactionUseCase` path.
- **Filter/sort state persists across tab switches** via `keepAlive: true` under `IndexedStack` (Phase 26 decision).
- **Calendar provider isolated from filter state** (`_dayKey` normalization, watches only bookId/year/month) to avoid re-rendering 31 cells on every search keystroke.
- **Scope held to expense-only** — no income tracking, no month settlement/lock, no amount-range filter, no "New" badge (all explicitly deferred).
- **GAP-1 fixed inline as a quick task at close** rather than carried to v1.5; GAP-2 (dead `watchByBookIds` stream) and draft-Nyquist docs accepted as tracked debt.

### Archive

- `.planning/milestones/v1.4-ROADMAP.md` — full phase details
- `.planning/milestones/v1.4-REQUIREMENTS.md` — final requirement status (22/22) + v1.5+ backlog
- `.planning/milestones/v1.4-MILESTONE-AUDIT.md` — pre-close audit report (status: `tech_debt`; GAP-1 closed after audit was taken)

---

## v1.3 — 迭代帐本输入

**Shipped:** 2026-05-26
**Phases:** 18-23 (6 phases, 47 plans)
**Duration:** 2026-05-22 → 2026-05-26 (~5 days)
**Tag:** `v1.3`
**Audit Status at Close:** `tech_debt` — milestone goal achieved with documentation-grade Nyquist debt accepted (Phase 18/21 missing VALIDATION.md; Phase 19/20 draft + `nyquist_compliant: false`; Phase 22 draft + `nyquist_compliant: true`). Phase 23 closed all functional gaps from the original audit. Mirrors v1.0 FUTURE-DOC-05 / v1.2 close precedent. See `.planning/milestones/v1.3-MILESTONE-AUDIT.md`.
**Known deferred items at close:** 4 items — see `.planning/STATE.md` Deferred Items §v1.3.

### Delivered

Home Pocket ledger entry now lives on a single screen for both manual and voice flows. A single shared `TransactionDetailsForm` widget powers four hosts: manual entry, voice entry, edit-existing, and OCR-review (architectural slot reserved for MOD-005). The numeric keypad enforces a 48dp touch-target floor across iOS HIG / Material guidance; six light/dark × ja/zh/en golden baselines lock visual discriminability. Voice number parsing now correctly combines 千/百/十/零/万 across zh + ja, including intra-pause merges via a `VoiceChunkMerger` 2.5s continued-listening window — corpora pass at zh 48/50 (96%) + ja 50/50 (100%). Voice category resolution always lands on an L2 category via a 3-stage fallback (override → `${l1Id}_other` convention → `findByParent.first`) consulting both merchant DB and an extensible synonym dictionary. The record button uses a hold-to-record gesture with AnimatedContainer shape morph + caption swap to "录音中…" — Stopwatch-verified perceived state change `<100ms`. Edit-from-list opens the shared form pre-populated; `entry_source` is preserved verbatim through edits.

### Key Accomplishments

1. **Single shared `TransactionDetailsForm` widget across 4 hosts** (Phase 18) — Freezed `TransactionDetailsFormConfig` sealed class with `.$new(...)` and `.edit(seed:)` factories; consumed by `ManualOneStepScreen`, `VoiceInputScreen`, `TransactionEditScreen`, `OcrReviewScreen` via `Config.when(...)`. `UpdateTransactionUseCase` preserves `entry_source` verbatim via `seed.copyWith()` with no `entrySource` override (DAO test exercises all 3 EntrySource literals).
2. **Manual one-step entry + keypad polish** (Phase 19) — `ManualOneStepScreen` collapses prior 2-screen entry chain; SmartKeyboard `math.max(48.0, rawKeyHeight)` non-negotiable touch-target floor; 6 golden baselines (ja/zh/en × light/dark) at 390×844; `manual_save_entry_source_test.dart` verifies `entry_source='manual'` round-trip against real Drift DB.
3. **Voice number parser zh + ja with continued-listening** (Phase 20) — Locale-aware numeral state machines + JA numeral dictionary in `lib/infrastructure/voice/` (per "Thin Feature" rule); `VoiceChunkMerger` 2.5s window via `SpeechRecognitionService.restartListen()`; zh corpus 96% + ja corpus 100%; anchor cases (zh 2204 / 1840, ja 2204 / 1840) verbatim verified. VOICE-02 device UAT (8 anchor cases) cleared in Phase 23 plan 23-08.
4. **Voice category resolver Level-2 enforcement** (Phase 21) — `VoiceCategoryResolver` always-L2 contract via `_ensureL2` 3-stage fallback (override map → `${l1Id}_other` convention → `findByParent.first` safety net); 19-L1 architecture invariant test; merchant DB (12 L2 entries) + synonym dict (59 seed entries) extensible without code changes — runtime-insert tests for 珍珠奶茶 (zh) + タピオカ (ja); legacy `FuzzyCategoryMatcher` + Levenshtein deleted.
5. **Voice one-step integration + hold-to-record button UX** (Phase 22) — `VoiceInputScreen` embeds `TransactionDetailsForm`; hold-to-record gesture via `RawGestureDetector` with `Duration.zero`; AnimatedContainer 180ms shape morph + AnimatedSwitcher caption swap to "录音中…"; Stopwatch test enforces `<100ms` perceived state change. Two BLOCKER gaps (G-01 recognizer self-termination, G-02 silent errors) elevated from code review and closed via plans 22-08/09/10 with 4 new ARB error keys + permanent-error mic gate.
6. **v1.3 cleanup phase absorbs carried tech-debt** (Phase 23) — Scanner allow-list cleanup (VOICE-SCANNER-ALLOWLIST cleared 2026-05-24); 6 voice-flow surgical fixes (D-05 intra-session guard, D-07 cold-start race, D-08 popUntil deferral, D-09 listener-leak regression, D-10 mixin extraction, D-11 G-02 localized assert); 4 mechanical polish items (D-12 constant dedup, D-13 substring guard, D-14 SeedAllUseCase, D-15 その他/其他/other seed); REQUIREMENTS.md + 7 SUMMARY frontmatters reconciled (D-04); 9/9 carried device UATs run and passed; `voice_input_screen.dart` slimmed 838 → 776 LOC via `VoiceLocaleReadinessMixin` + pure-helper extraction (Plan 23-09) — back under CLAUDE.md `<800` cap.

### Stats

- **Commits since v1.2 tag:** 330
- **Files changed:** 304 (+64,157 / -4,747 LOC); `lib/` +6,559 / -2,197; `test/` +10,246 / -836
- **Commit categories:** feat 52, fix 18, refactor 14, test 38, docs 158
- **Phase commit distribution:** Phase 20: 15, Phase 21: 14, Phase 22: 11, Phase 23: 10 (Phases 18-19 commits intermixed in early v1.3 tail)
- **Requirements:** 15/15 v1.3 requirements complete (4 fully verified at audit time + 11 partial-by-documentation-only reconciled in Phase 23 plan 23-07)
- **ARB parity:** 506 keys per locale (ja=zh=en) — +19 from v1.2 baseline of 487
- **Drift schema:** unchanged at v17 (no migration this milestone)
- **LOC cap:** `voice_input_screen.dart` 776 LOC (under 800 cap after Plan 23-09 mixin + helpers extraction)

### Notable Decisions

- 5-phase split (18-22) + cleanup phase (23) separates voice number parser (state-machine corpus) from voice category resolver (database resolution); isolates voice integration phase; cleanup phase chosen inline (vs carry to v1.4) for same-milestone debt absorption.
- Phase 18 ships first as foundation — INPUT-03 shared widget unblocks INPUT-01 (manual), INPUT-02 (voice), and EDIT-01/02 (edit-from-list).
- Phase 20 deliberately UI-independent (parallel-safe with Phase 19); both feed into Phase 22 integration.
- **Hold-to-record gesture** (vs tap-to-toggle) chosen and consistent app-wide; reduces accidental activation; documented in 22-04 SUMMARY.
- L1 → `${l1Id}_other` convention + `cat_other_expense → cat_other_other` override; always-L2 contract via deterministic fallback; architecture invariant test enforces 19 expense L1s.
- Phase 22 G-01/G-02 elevated to BLOCKER from code review (production-risk recognizer self-termination + silent errors); cannot be advisory-deferred. Closed in plans 22-08/09/10 before Phase 22 close.
- OCR slot intentionally hardcodes `EntrySource.manual` pending MOD-005 writer (annotated `// MOD-005: flip to EntrySource.ocr when OCR writer ships (D-12)`); schema accepts 'ocr' literal already.
- Phase 23 plan 23-09 LOC-cap extraction (838 → 776) via `VoiceLocaleReadinessMixin` + 3 pure helpers; zero behavior change.

### Archive

- `.planning/milestones/v1.3-ROADMAP.md` — full phase details
- `.planning/milestones/v1.3-REQUIREMENTS.md` — final requirement status + v1.4+ backlog
- `.planning/milestones/v1.3-MILESTONE-AUDIT.md` — pre-close audit report (status: `tech_debt`; Phase 23 closed all functional gaps after audit was taken)
- `.planning/milestones/v1.3-phases/` — archived phase directories (18-23)

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
