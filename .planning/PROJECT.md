# Home Pocket — まもる家計簿

## Current State

**Shipped:** v1.0 Codebase Cleanup Initiative (2026-04-29) — see `.planning/milestones/v1.0-ROADMAP.md`
**Shipped:** v1.1 Happiness Metric & Display (2026-05-05) — see `.planning/milestones/v1.1-ROADMAP.md`
**Shipped:** v1.2 Happiness Metric Refresh (2026-05-21) — see `.planning/milestones/v1.2-ROADMAP.md` + `.planning/milestones/v1.2-MILESTONE-AUDIT.md`
**Shipped:** v1.3 迭代帐本输入 (2026-05-26) — see `.planning/milestones/v1.3-ROADMAP.md` + `.planning/milestones/v1.3-MILESTONE-AUDIT.md`
**Shipped:** v1.4 列表功能 (2026-05-31) — see `.planning/milestones/v1.4-ROADMAP.md` + `.planning/milestones/v1.4-MILESTONE-AUDIT.md`

**Next milestone:** TBD. Candidate themes carried forward: combined family-calendar totals + undo-on-delete (v1.4 deferrals), MOD-005 OCR writer landing, FAMILY-V2-01/02/03 family privacy hardening, FUTURE-QA-01 release-readiness QA, FUTURE-DOC/TOOL cleanup, fl_chart 1.x upgrade (TOOL-V2-01), voice flow polish carry (VOICE-POLISH-V2-01..08), English voice parser (VOICE-EN-V2-01). Use `/gsd:new-milestone` to scope.

The v1.0 initiative was a pure-refactor cleanup. It delivered an operational hybrid audit pipeline, eliminated 50 catalogued findings (24 CRITICAL, 8 HIGH, 8 MEDIUM, 7 LOW + 3 layer-violation closures), aligned all architecture documentation with the post-refactor codebase, and locked 4 permanent CI guardrails.

The v1.1 milestone delivered the happiness metric domain, HomePage `HomeHeroCard`, AnalyticsScreen Variant δ unified dashboard, and final trilingual UI copy rename pass. It also ratified the v1.1 anti-gamification and lexical hierarchy ADRs.

The v1.2 milestone shipped the ADR-016 Joy migration (density → `Σ joy_contribution`), HomeHero target ring rebuild with user-configurable `monthly_joy_target` + 3-month median recommendation, AnalyticsScreen Variant ε with Custom Time Windows (week/month/quarter/year/arbitrary), Per-Category breakdown + Soul-vs-Survival comparison (anti-toxicity framed), and Manual-Only Joy sub-metric variant on Drift schema v17 (`entry_source` column). HomeHero isolation invariant (ADR-016 §3) is structurally enforced. Audit closed at `tech_debt` — Phase 13/17 lack VERIFICATION.md and 3 VALIDATION.md drafts have `nyquist_compliant: false`; documentation-grade debt only, all 11 v1.2 requirements satisfied in implementation.

The v1.3 milestone transformed ledger entry into a single-screen, voice-trustworthy core experience. Shipped: single shared `TransactionDetailsForm` widget consumed by 4 hosts (manual, voice, edit, OCR review); `ManualOneStepScreen` replacing the prior 2-screen chain; SmartKeyboard 48dp touch-target floor; locale-aware zh + ja voice number parsing (state machines + `VoiceChunkMerger` 2.5s continued-listening window) at zh 96% + ja 100% corpus accuracy; `VoiceCategoryResolver` always-L2 contract with merchant DB + synonym dictionary (extensible without code changes); hold-to-record gesture with AnimatedContainer shape morph + caption swap (`<100ms` verified); edit-from-list path with `entry_source` verbatim preservation. Two BLOCKER gaps (G-01 recognizer self-termination, G-02 silent errors) closed in Phase 22. Phase 23 cleanup absorbed carried tech-debt (scanner allow-lists, 6 voice-flow surgical fixes, 4 mechanical polish items, REQUIREMENTS.md reconciliation, 9 device UATs run + passed, voice_input_screen.dart 838→776 LOC via mixin + helpers extraction). Audit closed at `tech_debt` — documentation-grade Nyquist debt only; all 15 v1.3 requirements satisfied and reconciled.

The v1.4 milestone built the placeholder List tab into a full transaction overview (Japanese-kakeibo layout) in a new `lib/features/list/` module. Shipped: a `table_calendar` month header with per-day expense totals (own-book in v1.4), month navigation, tap-a-day-to-filter, and a current-month expense summary; a transaction list that is sortable (date / edit-time / amount ± direction), text-searchable (category · merchant · note), and filterable by ledger, multiple categories, and family member — all AND-composed with one-tap clear; rows that reuse the v1.3 edit path on tap and route swipe-delete through `DeleteTransactionUseCase` (soft-delete, hash-chain preserved); family-aware shadow-book merge with per-row owner attribution + "Mine only"; reactive updates + pull-to-refresh; 3-variant empty states; and full ja/zh/en ARB coverage (533 keys/locale) with golden baselines. A shared `DateBoundaries` util consolidated month-boundary arithmetic; `table_calendar ^3.2.0` was added (iOS build verified green). Audit closed at `tech_debt` — 22/22 requirements, 7/7 phases, 7/7 E2E flows; the one functional gap (GAP-1 calendar staleness after family-sync/FAB) was closed at milestone close via quick task 260531-u34; residual GAP-2 dead-code (`watchByBookIds` unused) + draft-Nyquist documentation debt accepted.

<details>
<summary>v1.4 列表功能 (archived)</summary>

**Started:** 2026-05-29
**Shipped:** 2026-05-31 (~3 days)
**Phase numbering:** Phases 24-30
**Trigger:** v1.3 closed the input axis; the List tab was still a placeholder — owner wanted a kakeibo-style transaction overview before any v1 release.

**Goal:** Build the placeholder List tab into a full transaction overview — month calendar (per-day expense totals + tap-to-filter), sortable/searchable/filterable list, month summary — reusing the v1.3 edit path and surfacing family members' entries.

**Delivered:**
- **Data layer + shared util (Phase 24):** `findByBookIds` multi-book query + `watchByBookIds` stream; extracted `DateBoundaries` to `lib/shared/utils/` (consolidated 6 month-boundary call sites); `SortField`/`SortDirection` enums; 6 DAO tests.
- **Domain + use case (Phase 25):** Freezed `ListFilterState`/`ListSortConfig`, repo interface, `GetListTransactionsUseCase` (execute Future+Result / watch Stream) + `GetListParams`; 8 Mocktail tests; pure-Dart.
- **Providers + shell wiring (Phase 26):** list providers with `keepAlive`-under-`IndexedStack` filter persistence; `ListScreen` replaces shell placeholder.
- **Calendar header (Phase 27):** `table_calendar` grid, `calendarDailyTotalsProvider` per-day totals (expense-only, `_dayKey` normalization, filter-isolated), month nav, day-tap filter, month summary; iOS build gate; human-approved render.
- **Tile + sort/filter bar (Phase 28):** `ListTransactionTile` (swipe-delete via `DeleteTransactionUseCase`, tap-to-edit), day grouping, sort + text search + ledger + multi-category filters AND-composed.
- **List screen + family (Phase 29):** full screen, `RefreshIndicator` pull-to-refresh (honest spinner, dual-invalidate), shadow-book merge, per-row member chip, member + "Mine only" filters; `anyFilterActive` 5-condition fix.
- **i18n + empty states + golden polish (Phase 30):** 3-variant `ListEmptyState`, ja/zh/en ARB, golden baselines; closes LIST-03.

**Out of v1.4 scope (carried to v1.5+):**
- Combined family-calendar per-day totals (v1.4 calendar is own-book only; seam reserved)
- Undo-on-delete SnackBar (needs `RestoreTransactionUseCase`)
- Month settlement / month-lock (结账锁月), income tracking, amount-range filter, "New" badge
- MOD-005 OCR writer landing; FAMILY-V2 privacy hardening; voice-polish + English-voice carries (unchanged from v1.3)

**Known close debt** (documented in `.planning/milestones/v1.4-MILESTONE-AUDIT.md`):
- GAP-2: LIST-02 `watchByBookIds` reactive stream is dead code (reactivity via manual `ref.invalidate`); either consume `useCase.watch()` or delete the 3-layer chain + fix stale shell comments
- Draft-Nyquist documentation debt: Phases 25/26/27/29/30 `nyquist_compliant: false`; Phase 28 approved (`nyquist_compliant: true`)
- GAP-1 (calendar staleness) was the one functional gap — **closed at milestone close** via quick task 260531-u34

**Archive:** `.planning/milestones/v1.4-ROADMAP.md`, `.planning/milestones/v1.4-REQUIREMENTS.md`, `.planning/milestones/v1.4-MILESTONE-AUDIT.md`

</details>

<details>
<summary>v1.3 迭代帐本输入 (archived)</summary>

**Started:** 2026-05-22
**Shipped:** 2026-05-26 (~5 days)
**Phase numbering:** Phases 18-23
**Trigger:** "Input flow is too multi-step, mis-tap-prone, voice-unreliable" — owner feedback after v1.2

**Goal:** 把账本录入从「多步、易误按、语音不准」打磨成「单屏、稳准、语音可信」的核心体验，并复用同一 details 表单作为已存账本的编辑入口。

**Delivered:**
- **Shared details form foundation (Phase 18):** Single `TransactionDetailsForm` widget reused by 4 hosts (ManualOneStepScreen, VoiceInputScreen, TransactionEditScreen, OcrReviewScreen) via Freezed `TransactionDetailsFormConfig.when(.new/.edit)`; `UpdateTransactionUseCase` preserves `entry_source` verbatim through edits; OCR two-step architectural slot reserved with MOD-005 marker; widget test `ocr_two_step_seam_test.dart` enforces seam.
- **Manual one-step + keypad polish (Phase 19):** `ManualOneStepScreen` collapses 2-screen chain into single screen; `math.max(48.0, rawKeyHeight)` non-negotiable touch-target floor; 6 golden baselines (ja/zh/en × light/dark); `manual_save_entry_source_test.dart` verifies `entry_source='manual'` against real Drift DB.
- **Voice number parser zh + ja (Phase 20):** Locale-aware numeral state machines (千/百/十/零/万) + JA numeral dictionary in `lib/infrastructure/voice/`; `VoiceChunkMerger` 2.5s continued-listening window via `SpeechRecognitionService.restartListen()`; zh corpus 48/50 (96%) + ja corpus 50/50 (100%); anchor cases zh 2204 / 1840, ja 2204 / 1840 verbatim verified. VOICE-02 device UAT (8 anchor cases) cleared in Phase 23.
- **Voice category resolver L2 enforcement (Phase 21):** `VoiceCategoryResolver` always-L2 contract via `_ensureL2` 3-stage fallback (override map → `${l1Id}_other` convention → `findByParent.first` safety net); 19-L1 architecture invariant test; merchant DB (12 L2 entries) + synonym dict (59 seed entries) extensible without code changes — runtime-insert tests for 珍珠奶茶 (zh) + タピオカ (ja); legacy `FuzzyCategoryMatcher` + Levenshtein deleted.
- **Voice one-step integration + record button UX (Phase 22):** `VoiceInputScreen` embeds `TransactionDetailsForm`; hold-to-record gesture via `RawGestureDetector` with `Duration.zero`; AnimatedContainer 180ms shape morph + AnimatedSwitcher caption swap to "录音中…"; Stopwatch test enforces `<100ms` perceived state change. Two BLOCKER gaps (G-01 recognizer self-termination, G-02 silent errors) elevated from code review and closed via plans 22-08/09/10 with 4 new ARB error keys + permanent-error mic gate.
- **v1.3 cleanup (Phase 23):** Scanner allow-list cleanup (VOICE-SCANNER-ALLOWLIST); 6 voice-flow surgical fixes (D-05/07/08/09/10/11); 4 mechanical polish items (D-12/13/14/15); REQUIREMENTS.md + 7 SUMMARY frontmatters reconciled (D-04); 9/9 carried device UATs run and passed; `voice_input_screen.dart` slimmed 838 → 776 LOC via `VoiceLocaleReadinessMixin` + pure-helper extraction (Plan 23-09) — back under CLAUDE.md `<800` cap.

**Out of v1.3 scope (carried to v1.4+):**
- MOD-005 OCR writer landing — architectural slot reserved with `// MOD-005: flip to EntrySource.ocr when OCR writer ships` marker; schema already accepts 'ocr' literal
- FAMILY-V2-01/02/03 family privacy hardening
- FUTURE-QA-01 release-readiness smoke tests
- FUTURE-DOC-01..06 + FUTURE-TOOL-03 documentation/tooling cleanup
- TOOL-V2-01 fl_chart 1.x upgrade
- VOICE-POLISH-V2-01..08 voice flow polish (Phase 22 WR-02/03/06/07/NEW-02/NEW-03 + IN-03 + Phase 23 WR-06)
- VOICE-EN-V2-01 English voice parser (skeleton only in Plan 23-03)

**Known close debt** (documented in `.planning/milestones/v1.3-MILESTONE-AUDIT.md`):
- Phase 18 + 21 missing VALIDATION.md (Nyquist); Phase 19 + 20 draft + `nyquist_compliant: false`; Phase 22 draft + `nyquist_compliant: true` — documentation-grade debt only
- Phase 22 advisory WR-02/03/06/07/NEW-02/NEW-03 + IN-01/02/03 — 9 standing warnings + 3 infos on `voice_input_screen.dart` carry as voice-flow polish backlog
- Pre-existing 15 test failures + 4 analyzer findings carry from v1.2 (none touched by v1.3)

**Archive:** `.planning/milestones/v1.3-ROADMAP.md`, `.planning/milestones/v1.3-REQUIREMENTS.md`, `.planning/milestones/v1.3-MILESTONE-AUDIT.md`, `.planning/milestones/v1.3-phases/`

</details>

<details>
<summary>v1.2 Happiness Metric Refresh (archived)</summary>

**Started:** 2026-05-19
**Shipped:** 2026-05-21 (3 days)
**Phase numbering:** Phases 13-17
**Trigger:** ADR-016 ratify (2026-05-19) — Joy metric supersede from density to `Σ joy_contribution`

**Goal:** Package the ADR-016 Joy metric supersede with v1.1-deferred Joy/Analytics backlog into one coherent refresh; redraw HomePage + AnalyticsScreen under the new `Σ joy_contribution` semantics.

**Delivered:**
- **ADR-016 backend foundation (Phase 13):** `HappinessReport.joyContribution` field, `getSoulRowsForJoyContribution` DAO, `joy_cumulative_formatter` (replaced `joy_density_formatter`), `AppSettings.monthlyJoyTarget` SharedPreferences persistence, `GetMonthlyJoyTargetRecommendationUseCase` (ceil-median of past 3 months + fallback baseline 50), density code-path deletion across `lib/`
- **ADR-016 frontend + ARB reconciliation (Phase 14):** HomeHeroCard rebuilt with cumulative center display + sage-green→gold target ring + clamp-at-100% color contract, Settings `JoyTargetSection` with user-configurable target + recommendation display + null-clears-to-recommendation flow, AnalyticsScreen Variant ε with Joy Index promoted to primary KPI, ARB density/ROI vocabulary fully scrubbed across ja/zh/en (key count 487 per locale parity)
- **Custom Time Windows (Phase 15):** Freezed `TimeWindow` sealed value object (week/month/quarter/year/custom), `TimeWindowValidation` calendar-month guard, `selectedTimeWindowProvider` session state, `TimeWindowChip` + `TimeWindowPickerSheet` widgets, six analytics use cases migrated to `(startDate, endDate)`, retired month-chip / MoM-delta UI, HomeHero stays current-month-anchored
- **Per-Category Breakdown + Soul-vs-Survival comparison (Phase 16):** `PerCategoryBreakdownCard` with min-N=3 filter + Other rollup + top-5/expand toggle (HAPPY-V2-01), `SoulVsSurvivalCard` with Soul vs Survival columns (D-04 type gate: `SurvivalLedgerSnapshot` has NO `avgSatisfaction` field, STATSUI-V2-01), 4 new DAO methods + repository surface + 4 use cases + 4 Riverpod providers, 22 new ARB keys × 3 locales, trilingual anti-toxicity widget sweep (24 cases), light/dark goldens for both surfaces
- **Manual-Only Joy Sub-Metric (Phase 17):** Drift schema v16→v17 (`transactions.entry_source` TEXT NOT NULL DEFAULT 'manual' CHECK ∈ {manual, voice, ocr}), `EntrySource` enum + Freezed `Transaction` field + sync mapper with manual fallback, `CreateTransactionParams.entrySource` required-no-default + 3 push-site stampings (voice/manual/demo), `entrySourceFilter: EntrySource?` threaded through 12+ analytics use cases + 16 analytics providers + DAO `AND entry_source = ?` clauses, `selectedJoyMetricVariantProvider` + `JoyMetricVariantChip` widget, HomeHero isolation extended for SC-4 (variant toggle non-effect verification)

**Out of v1.2 scope (carried to v1.3+):**
- FAMILY-V2-01/02/03 — family privacy hardening
- TOOL-V2-01 — fl_chart 1.x upgrade
- MOD-005 OCR
- FUTURE-QA-01 — release-readiness smoke tests

**Known close debt** (documented in `.planning/milestones/v1.2-MILESTONE-AUDIT.md`):
- Phase 13 + 17 lack VERIFICATION.md (live code wired + integration-verified; per-phase verifier artifact never run)
- Phase 13, 14, 17 VALIDATION.md status: draft, `nyquist_compliant: false` (FUTURE-DOC-equivalent)
- 6 pre-existing `family_insight_card_test.dart` failures from Phase 15 ARB drift commit `8d5f136` (`今月、` prefix dropped) — does NOT break any v1.2 flow
- `EntrySource.ocr` literal accepted by schema but no production writer yet (consistent with MOD-005 OCR being a future module)
- 3 quick-task metadata drift entries (tool reports `missing` while STATE.md confirms `verified`)

**Archive:** `.planning/milestones/v1.2-ROADMAP.md`, `.planning/milestones/v1.2-REQUIREMENTS.md`, `.planning/milestones/v1.2-MILESTONE-AUDIT.md`, `.planning/milestones/v1.2-phases/`

</details>

<details>
<summary>v1.1 Happiness Metric & Display (archived)</summary>

**Goal:** 把"花钱的幸福"从模糊感觉变成可计算、可展示的指标——让 HomePage 和统计页围绕「悦己账本」的幸福度数据组织起来；同时为家庭模式提供反对抗、合作型的共同指标。

**Delivered:**
- 4 personal Joy indicators: Avg Satisfaction, Joy per ¥, Highlights count, Best Joy story
- 2 aggregate-only family indicators: Family Highlights Sum and Shared Joy Insight
- HomePage integrated `HomeHeroCard`
- AnalyticsScreen Variant δ unified dashboard
- ARB-only rename across ja/zh/en: Joy/Daily ledger language, Joy density/index, satisfaction ladder, and `satisfactionExcellent`

**Archive:** `.planning/milestones/v1.1-ROADMAP.md`, `.planning/milestones/v1.1-REQUIREMENTS.md`

</details>

<details>
<summary>v1.0 Project Description (archived)</summary>

## What This Is (v1.0)

A focused, audit-driven refactor of the Home Pocket (まもる家計簿) Flutter codebase, targeting four categories of accumulated technical debt: layer violations, redundant code, dead code, and Riverpod provider hygiene. The goal was to bring the codebase into a long-term stable state — pure refactor, zero behavior change to end users — before the next wave of feature modules (MOD-005 OCR, MOD-007 Analytics, MOD-013 Gamification) is implemented.

## Core Value (v1.0)

**Re-running the audit at the end finds zero violations across all four categories.** Met — REAUDIT-DIFF.json reports `resolved=50, regression=0, new=0, open_in_baseline=0`.

</details>

## What This Is

Home Pocket (まもる家計簿) is a local-first, privacy-focused family accounting app with a dual-ledger system (Survival ledger + Soul ledger). Zero-knowledge architecture with 4-layer encryption, P2P family sync, and offline-first design. Target: iOS 14+ / Android 7+ (API 24+). After four milestones, the app ships a single-screen voice-capable ledger entry flow, a calculable Joy metric (`Σ joy_contribution` cumulative semantics) with user-configurable monthly targets, custom analytics time windows, per-category + Soul-vs-Survival comparison surfaces, an audit lens (manual-only Joy variant), and — as of v1.4 — a full kakeibo-style transaction list: month calendar with per-day expense totals + tap-to-filter, sortable/searchable/filterable rows, a month summary, and family-aware display of members' entries.

## Core Value

A family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, with a dual-ledger system that distinguishes survival spending from soul spending so families can have honest money conversations.

## Current Milestone: v1.5 文案与配色统一 (Terminology & Color Unification)

**Goal:** Unify the half-migrated dual-ledger vocabulary across all three locales *and* internal code identifiers; explore and select a stronger global color palette (Pencil mockups, 4–5 options); then apply it through a single semantic design-token system that replaces scattered hardcoded colors — a brownfield terminology + palette/color refactor with no new user features.

**Target features:**
- Trilingual terminology rename (user-facing ARB values, all 3 locales) — 生存/Survival → 日常/Daily; 灵魂·魂/ソウル/Soul → 悦己/ときめき/Joy
- Internal-identifier rename — ARB keys (`soulLedger`→`joyLedger`, `survival*`→`daily*`), `AppColors.survival`→`daily` / `soul`→`joy`, related symbols
- Palette exploration — mine design references (VoltAgent/awesome-design-md), propose 4–5 full color schemes rendered in Pencil, user selects one (recorded as ADR)
- Color consolidation — ~62 hardcoded `Color(0x…)` literals → centralized `AppColors` tokens encoding the selected palette
- Ledger theme-color consistency audit — selected 日常 / 悦己 ledger accents applied uniformly
- Semantic design-token system — primary/ledger/surface/semantic + profile dark palette as single source of truth

**Locale mapping (locked):**

| Concept | zh | ja | en |
|---|---|---|---|
| Survival ledger | 日常 | 日常 (にちじょう) | Daily |
| Soul ledger | 悦己 | ときめき | Joy |

**Key context:** Risk concentrated in the ARB-key + `AppColors` symbol rename (ripples into `.g.dart` generation and golden baselines). May warrant an ADR update if ADR-015 governs the lexical hierarchy. `ときめき` reuses the existing ja joy-index term (`ときめき指数`) for vocabulary coherence.

## Requirements

### Validated

<!-- Capabilities shipped or confirmed stable. -->

**Existing app baseline (unchanged by milestone work):**

- ✓ Local-first encrypted accounting database (SQLCipher AES-256, 11 Drift tables) — schema bumped v14 → v15 in v1.0 (3 new indices), v15 → v16 in v1.1 (satisfaction default 5 → 2 unipolar), v16 → v17 in v1.2 (`entry_source` column)
- ✓ 5-layer Clean Architecture with "Thin Feature" rule — structurally enforced by `import_guard` (v1.0)
- ✓ Field-level encryption (ChaCha20-Poly1305), hash-chain integrity verification
- ✓ Key management (Ed25519 device keys, BIP39 recovery phrase, biometric lock, secure storage)
- ✓ Dual-ledger system (Survival + Soul) with rule-engine + merchant-database classification
- ✓ Family sync (WebSocket relay + APNS push + E2EE + sync queue + CRDT-style apply pipeline)
- ✓ Voice input (speech recognition + parser + fuzzy category matching + correction learning)
- ✓ Analytics (monthly reports, expense trends, budget progress)
- ✓ Settings: backup export/import, clear-all-data
- ✓ Profile management (user profile + avatar sync)
- ✓ i18n infrastructure (ja default / zh / en, ARB-driven, custom formatters)
- ✓ Riverpod-based DI (`@riverpod` code-gen)
- ✓ Freezed-based immutable domain models
- ✓ Explicit, ordered app boot (`AppInitializer`: KeyManager → Database → others) — extracted in v1.0 (CRIT-03)

**Shipped in v1.0 (Codebase Cleanup Initiative):**

- ✓ Hybrid audit pipeline (4 automated scanners + AI semantic-scan workflow) producing machine-readable `issues.json` with stable IDs — v1.0
- ✓ Zero open findings across all 4 audit categories (REAUDIT-DIFF.json `resolved=50, regression=0, new=0, open=0`) — v1.0
- ✓ All layer-violation findings eliminated; Domain purity enforced by `import_guard` — v1.0
- ✓ All redundant-code findings eliminated (duplicate providers, `ResolveLedgerTypeService` deletion, `CategoryService` collision resolved) — v1.0
- ✓ All dead-code findings eliminated; MOD-009 deprecated code removed; `dart_code_linter check-unused-code/files` reports 0 — v1.0
- ✓ All Riverpod provider-hygiene findings eliminated (single `repository_providers.dart` per feature, `keepAlive` reconciled, no `UnimplementedError` outside test fixtures) — v1.0
- ✓ All hardcoded CJK strings extracted to ARB; ARB key parity locked across ja/zh/en — v1.0
- ✓ All ARCH/MOD/ADR docs and CLAUDE.md aligned with post-refactor codebase; ADR-011 records cleanup outcome — v1.0
- ✓ 4 permanent CI guardrails (`import_guard`, `riverpod_lint`/`custom_lint`, `coverde` per-file ≥70%, `sqlite3_flutter_libs` rejection) + global `very_good_coverage@v2` ≥70% + `build_runner` clean-diff — v1.0
- ✓ Mocktail big-bang migration (13 fixtures); mockito removed — v1.0 (HIGH-07)

**Shipped in v1.1 (Happiness Metric & Display):**

- ✓ Happiness metric domain (Phase 9): personal metric formulas, family aggregate-only return type, sealed `MetricResult`, soul-only filter, v16 default-2 satisfaction semantics, no-gamification ADRs, full HAPPY-08 picker mapping test coverage
- ✓ HomePage happiness display (Phase 10): personal metric tiles, Best Joy story card, group-mode family insight, empty states, info tooltips, golden coverage
- ✓ AnalyticsScreen Variant δ unified dashboard (Phase 11): KPI mini-hero, Joy-per-¥ trend, satisfaction histogram, story cards, month picker, aggregate-only family insight
- ✓ UI copy rename pass (Phase 12): ARB value rewrites for ja/zh/en, picker sentiment-positive icon ladder, RENAME-07 requirement, ADR-015 lexical hierarchy accepted, refreshed goldens

**Shipped in v1.2 (Happiness Metric Refresh):**

- ✓ **JOYMIG-01** HomeHero principal Joy metric migrated to cumulative `Σ joy_contribution` — v1.2 Phase 14
- ✓ **JOYMIG-02** User-configurable `monthly_joy_target` in Settings + recommendation (ceil-median past 3 months) + fallback baseline 50 — v1.2 Phases 13-14
- ✓ **JOYMIG-03** HomeHero ring resets monthly + fills toward active target — v1.2 Phase 14
- ✓ **JOYMIG-04** Sage-green→gold ring color state machine, clamps at gold at/beyond 100% — v1.2 Phase 14
- ✓ **JOYMIG-05** AnalyticsScreen Joy Index promoted; density (Joy/¥) UI fully removed; `lib/` density-free — v1.2 Phases 13-14
- ✓ **JOYMIG-06** 100% behavior contract — zero discrete events at threshold; structurally enforced by HomeHero source inspection — v1.2 Phase 14
- ✓ **HAPPY-V2-01** Per-category satisfaction breakdown card with min-N=3 filter + Other rollup — v1.2 Phase 16
- ✓ **HAPPY-V2-02** Custom Time Windows (week/month/quarter/year/arbitrary) wired through 6 analytics use cases; HomeHero remains current-month-anchored — v1.2 Phase 15
- ✓ **HAPPY-V2-03** Manual-only Joy sub-metric variant + Drift schema v17 (`entry_source` column) + AnalyticsScreen chip toggle; isolation SC-4 enforced — v1.2 Phase 17
- ✓ **STATSUI-V2-01** Soul-vs-Survival comparison card with anti-toxicity framing (24-case trilingual forbidden-substring sweep) — v1.2 Phase 16
- ✓ **TOOL-V2-02** ARB density/ROI keys removed; ja/zh/en parity locked at 487 keys per locale — v1.2 Phase 14

**Shipped in v1.3 (迭代帐本输入):**

- ✓ **INPUT-03** Single shared `TransactionDetailsForm` widget across 4 hosts (manual, voice, edit, OCR review) — v1.3 Phase 18
- ✓ **INPUT-04** OCR two-step architectural slot reserved (`OcrReviewScreen` mounts shared widget; writer pending MOD-005) — v1.3 Phase 18
- ✓ **EDIT-01** Tap any existing transaction in home recent-tx list → shared form opens pre-populated — v1.3 Phase 18
- ✓ **EDIT-02** Edit-existing path preserves `entry_source` verbatim (manual/voice/ocr; DAO test exercises all 3 literals) — v1.3 Phase 18
- ✓ **KEYPAD-01** SmartKeyboard 48dp non-negotiable touch-target floor + visual-discriminability goldens (ja/zh/en × light/dark) — v1.3 Phase 19
- ✓ **INPUT-01** `ManualOneStepScreen` single-screen manual entry, no "下一步" navigation — v1.3 Phase 19
- ✓ **VOICE-01** Voice parser zh "2千2百零4元" → 2204, ja 「にせんにひゃくよん」 → 2204 — v1.3 Phase 20
- ✓ **VOICE-02** Voice parser intra-pause merge: zh "1千8百4十元" → 1840, ja 「せんはっぴゃくよんじゅう」 → 1840; VOICE-02-DEVICE-VERIFY 8 anchor cases cleared via Phase 23 device UAT — v1.3 Phase 20 (+ Phase 23 23-08)
- ✓ **VOICE-03** Per-locale corpus accuracy: zh 48/50 (96%) + ja 50/50 (100%), both ≥95% — v1.3 Phase 20
- ✓ **VOICE-04** `VoiceCategoryResolver` returns L2 whenever spoken phrase matches merchant DB or synonym dict L2 entry — v1.3 Phase 21
- ✓ **VOICE-05** `_ensureL2` 3-stage fallback ensures L2 always; architecture invariant test enforces across 19 expense L1s — v1.3 Phase 21
- ✓ **VOICE-06** Merchant DB + synonym dict extensible without code changes (runtime-insert tests for 珍珠奶茶 / タピオカ) — v1.3 Phase 21
- ✓ **REC-01** Hold-to-record idle caption via `holdToRecord` ARB key × ja/zh/en; consistent app-wide — v1.3 Phase 22
- ✓ **REC-02** Recording state: AnimatedContainer 180ms shape morph + AnimatedSwitcher caption swap to "录音中…"; Stopwatch test `<100ms` — v1.3 Phase 22
- ✓ **INPUT-02** Voice-driven entry on same single screen as manual; parser fills amount/category/note/merchant in-place; edit any field before save — v1.3 Phase 22

**Shipped in v1.4 (列表功能 / Transaction List):**

- ✓ **CAL-01** Month switch (prev/next + picker) on the List tab — v1.4 Phase 27
- ✓ **CAL-02** Month calendar grid with per-day expense totals (own-book in v1.4; family-combine seam reserved) — v1.4 Phase 27
- ✓ **CAL-03** Tap a day to filter the list to that day; tap the selected day again to clear — v1.4 Phase 27
- ✓ **CAL-04** Current-month expense summary (expense-only basis) on the List tab — v1.4 Phase 27
- ✓ **LIST-01** Scrollable month transaction list; rows show category emoji + name, ledger-color tag, date, tabular-figure amount — v1.4 Phase 28
- ✓ **LIST-02** List updates reactively after add/edit/delete/family-sync (via manual `ref.invalidate`; `watchByBookIds` stream exists but is dead code — GAP-2) — v1.4 Phases 24/26/29
- ✓ **LIST-03** Clear 3-variant empty state when no transactions match month + filters — v1.4 Phase 30
- ✓ **LIST-04** Pull-to-refresh (RefreshIndicator, honest spinner) — v1.4 Phase 29
- ✓ **SORT-01/02/03/04** Sort by date / edit-time / amount + asc/desc toggle — v1.4 Phases 25/28
- ✓ **FILTER-01/02/03/04** Text search (category·merchant·note) + ledger + multi-category filters, AND-composed with one-tap clear — v1.4 Phases 26/28
- ✓ **ROW-01** Tap row → edit via v1.3 `TransactionEditScreen` + shared form (`entry_source` preserved) — v1.4 Phase 28
- ✓ **ROW-02** Swipe-to-delete with confirmation; routes exclusively through `DeleteTransactionUseCase` (soft-delete, hash-chain-safe) — v1.4 Phase 28
- ✓ **FAM-01/02/03/04** Family shadow-book merge + per-row owner attribution + member filter + "Mine only" — v1.4 Phase 29

### Active

<!-- No active milestone. v1.4 shipped 2026-05-31. Run /gsd-new-milestone to scope the next. -->

_(none — between milestones; see Next Milestone above)_

### Out of Scope

<!-- Explicit boundaries carried forward. -->

- **Combined family-calendar per-day totals** — v1.4 calendar is own-book only; combining members' per-day totals deferred to v1.5+ (seam reserved in `calendarDailyTotalsProvider`)
- **Undo-on-delete SnackBar** — v1.4 swipe-delete is confirm-only soft-delete; undo needs a `RestoreTransactionUseCase` (deferred)
- **Month settlement / month-lock (结账锁月), income tracking, amount-range filter, "New" badge** — explicit v1.4 list-feature exclusions; candidates for a later milestone
- **`recoverFromSeed()` key-overwrite bug fix** — HIGH-severity per CONCERNS.md but security-architecture changes are out of scope; deferred to FUTURE-ARCH-04
- **Riverpod 3.x upgrade** — confirmed `analyzer` version conflict with `json_serializable` (deferred to FUTURE-TOOL-01)
- **`sqlite3_flutter_libs` adoption** — SQLCipher conflict; actively rejected by CI guardrail
- **Removal of historical deprecated documentation** — deprecated *code* is deleted; deprecated *doc entries* (e.g., MOD-009 index entry) remain as historical record
- **DCM (paid) audit pipeline upgrade** — deferred to FUTURE-ARCH-03
- **Cross-period Joy comparison** (this month vs last month) — hard-blocked by ADR-012 §4 and ADR-016 §3 (cross-milestone permanent)
- **Joy achievement notifications / milestone toasts** — hard-blocked by ADR-012 §2 and ADR-016 §5 (cross-milestone permanent)
- **Family member Joy leaderboards** — hard-blocked by ADR-012 §6 (cross-milestone permanent)
- **Streak displays (consecutive days, etc.)** — hard-blocked by ADR-012 §5 (cross-milestone permanent)
- **Public sharing of Joy data** — hard-blocked by ADR-012 §5 (cross-milestone permanent)

<details>
<summary>v1.0 Out of Scope (archived — most no longer apply post-shipment)</summary>

- **New feature modules** (MOD-005 OCR, MOD-007 Analytics expansion, MOD-013 Gamification) — feature work was paused for the cleanup initiative; **lifted now that v1.0 has shipped**
- **User-visible behavior changes** — strict pure refactor for v1.0; v1.1+ may include user-visible changes
- **API/database breaking changes** — held backward-compatible during cleanup; v1.1+ may revisit
- **Performance optimization as a goal** — was not a v1.0 target
- **Security-architecture changes** — the 4-layer encryption stack was treated as fixed; security cleanup limited to enforcing existing rules
- **Per-phase doc updates** — v1.0 used centralized sweep at Phase 7 to avoid churn

</details>

## Context

- **Current state (post-v1.4):** v1.0 shipped 2026-04-29; v1.1 2026-05-05; v1.2 2026-05-21; v1.3 2026-05-26; **v1.4 列表功能 shipped 2026-05-31** (~3 days, 283 commits, 316 files changed, +51,409/-2,207 LOC). New `lib/features/list/` module: kakeibo-style List tab — `table_calendar` month header (per-day expense totals, own-book), sortable/searchable/filterable transaction list, month summary, family-aware shadow-book merge + "Mine only", pull-to-refresh, 3-variant empty states. Shared `DateBoundaries` util; `table_calendar ^3.2.0` added. Drift schema unchanged at v17 (no migration). ARB parity now 533 keys per locale (+27 from v1.3's 506). GAP-1 (calendar staleness) closed at close via quick task 260531-u34; GAP-2 (`watchByBookIds` dead code) + draft-Nyquist docs carried as debt.
- **Prior state (post-v1.3):** v1.3 迭代帐本输入 shipped 2026-05-26 (~5 days, 330 commits, 304 files, +64,157/-4,747 LOC). Ledger entry single-screen for manual + voice; voice parser zh+ja, hold-to-record, edit-from-list.
- **Codebase map:** `.planning/codebase/` was last refreshed 2026-04-25 (`/gsd-map-codebase`). Contents: ARCHITECTURE.md, STACK.md, STRUCTURE.md, CONVENTIONS.md, INTEGRATIONS.md, TESTING.md, CONCERNS.md. **Stale — four milestones of drift.** Refresh via `/gsd:map-codebase` before next milestone planning.
- **Tech stack:** Flutter, Riverpod 3.x (`@riverpod` code-gen, generator 4.x), Freezed, Drift + SQLCipher (schema v17), GoRouter, flutter_localizations (intl 0.20.2 pinned), Mocktail
- **Active CI guardrails:** `import_guard` (custom_lint), `riverpod_lint`/`custom_lint`, `coverde` per-file ≥70% with `--deferred` mechanism, `sqlite3_flutter_libs` rejection, `very_good_coverage@v2` ≥70% global, `build_runner` clean-diff
- **Coverage:** Global ~74.6% baseline (last measured post-v1.0); v1.2 + v1.3 added substantial test code (~17k LOC), expect coverage at or above baseline. Re-measure during next milestone planning.
- **Known issues / debt carried forward:**
  - **v1.3 close debt** (per `.planning/milestones/v1.3-MILESTONE-AUDIT.md`): Phase 18/21 missing VALIDATION.md; Phase 19/20 VALIDATION.md draft + `nyquist_compliant: false`; Phase 22 VALIDATION.md draft + `nyquist_compliant: true`; Phase 22 advisory WR-02/03/06/07/NEW-02/NEW-03 + IN-01/02/03 on `voice_input_screen.dart` (voice-flow polish backlog); Phase 23 WR-06 build-side `_voiceLocaleId` reassignment functionally dead; OCR slot hardcodes `EntrySource.manual` pending MOD-005 writer
  - **v1.2 close debt** (per `.planning/milestones/v1.2-MILESTONE-AUDIT.md`): Phase 13/17 missing VERIFICATION.md; Phase 13/14/17 VALIDATION.md status draft + `nyquist_compliant: false`; 6 pre-existing `family_insight_card_test.dart` failures from Phase 15 ARB drift; `EntrySource.ocr` schema-accepted but no writer yet (now also reserved at OCR review screen layer in v1.3)
  - **v1.1 close debt:** 1 Phase 11 human/device UAT verification item (AnalyticsScreen month chip + pull-to-refresh on device)
  - **v1.0 close debt:** 2 INFO-level analyzer warnings in `shadow_books_provider_characterization_test.dart`; MOD-numbering drift in MOD-002/006/007/008; ARCH-008 cites ADR-006 instead of ADR-007; doc-sweep verifiers exist but not in CI; 12 architecture tests run only transitively via coverage job; Phase 03/06/08 missing canonical VERIFICATION.md; Phase 02/04 missing VALIDATION.md; Phase 07 `nyquist_compliant: false`
- **Why next:** v1.3 closed the input-flow axis. Next-wave candidates: **MOD-005 OCR writer landing** (architectural slot reserved in v1.3, ready to consume; schema accepts 'ocr' literal), **VOICE-POLISH-V2** (consolidate Phase 22 advisory WR-* into a focused polish phase if voice work continues), **FAMILY-V2-01/02/03** family privacy hardening, **FUTURE-QA-01** release-readiness QA, **VOICE-EN-V2-01** English voice parser, **TOOL-V2-01** fl_chart 1.x upgrade, or documentation/tooling guardrail cleanup (FUTURE-DOC/TOOL) before any user-facing v1 release.

## Constraints

- **Tech stack:** Flutter / Dart; intl 0.20.2 pinned; `sqlcipher_flutter_libs` (not `sqlite3_flutter_libs`); Mocktail (mockito removed in v1.0)
- **Quality gates (permanent):** `flutter analyze` MUST be 0 issues; `dart run custom_lint --no-fatal-infos` 0 errors; `import_guard` 0 violations; `riverpod_lint` 0 violations; per-file coverage ≥70% on cleanup-touched files (with `--deferred` for exceptions); global coverage ≥70%; `build_runner` clean-diff; `sqlite3_flutter_libs` rejection
- **Coverage threshold:** Active 70% (lowered from 80% on 2026-04-28 per Phase 8 amendment; FUTURE-TOOL-03 to revisit)
- **Documentation:** ADRs are append-only after status `✅ 已接受`; new context appended via `## Update YYYY-MM-DD: <topic>` at file end
- **Architecture:** 5-layer Clean Architecture with "Thin Feature" rule, structurally enforced by `import_guard`
- **Internationalization:** All UI text via `S.of(context)`; ARB key parity locked across ja/zh/en (487 keys per locale at v1.2 close); `flutter gen-l10n` must succeed without warnings
- **Joy metric semantics (ADR-016):** `Σ joy_contribution = Σ (soul_satisfaction × (amount / base)^0.88)` is the single Joy expression. Density (Joy/¥) is retired permanently.
- **No-gamification (ADR-012):** no streaks, no badges, no achievement unlocks, no cross-period delta surfaces, no leaderboards, no public sharing — applies cross-milestone.
- **HomeHero isolation (ADR-016 §3):** HomeHero ring is single-month accumulation, anchored to current calendar month; never affected by AnalyticsScreen time-window selector or Joy-variant audit-lens toggles. Structurally enforced by `home_screen_isolation_test.dart`.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Audit-driven (no manual issue list) | Codebase too large for memory-based enumeration | ✓ Good — 26 baseline findings; 50 resolved with no regressions (v1.0) |
| Hybrid audit (tooling + AI agent) | Tooling catches mechanical issues; AI catches semantic/structural | ✓ Good — both surfaced findings the other missed (v1.0) |
| Severity-ordered phases (CRITICAL → LOW) | Architecture-breaking violations before polish | ✓ Good — no rework cycles (v1.0) |
| Strict behavior preservation (pure refactor) | Lowers blast radius; allows regression-style verification | ✓ Good — characterization + golden tests caught regressions early (v1.0) |
| ≥80% coverage on refactored files | Without test net, refactor regressions go silent | ⚠️ Revisit — global 74.6% at v1.0 close; threshold lowered 80→70% (FUTURE-TOOL-03) |
| New feature work paused (v1.0) | Prevents conflicts; ensures cleanup completes | ✓ Good — initiative shipped in 4 days without merge conflicts |
| Delete deprecated code (MOD-009 references) | Dead weight gets copy-pasted into new modules | ✓ Good — MOD-009 references gone from `lib/` (v1.0) |
| Phase 5 MEDIUM guardrails | MEDIUM cleanup needs automated regression guards | ✓ Good (v1.0) |
| Centralized doc sweep (not per-phase) | Doc churn during refactor is wasted effort | ✓ Good — single Phase 7 sweep aligned all docs (v1.0) |
| Audit re-run as final gate (zero violations) | Without programmatic exit criterion, "done" becomes negotiable | ✓ Good — REAUDIT-DIFF.json `open_in_baseline=0` is the close signal (v1.0) |
| Mocktail big-bang migration (HIGH-07) | CI-generated `*.mocks.dart` strategy added complexity for marginal benefit | ✓ Good — 13 fixtures migrated; mockito removed (v1.0) |
| Coverage threshold 80→70% (Phase 8) | Post-cleanup global coverage at 74.6%; raising bar would block close on baseline-fixable items | ⚠️ Revisit — FUTURE-TOOL-03 |
| Per-file coverage `--deferred` mechanism | 10 files below 70%; raising them in-scope was substantive | ⚠️ Revisit — FUTURE-TOOL-03 |
| Smoke-test execution deferred to v1 release | Owner-driven release gate, not cleanup-initiative gate | — Pending — FUTURE-QA-01 |
| ADR-011 v1.1 amendment with 4-layer narrative | Honest documentation pattern: surface adaptations explicitly | ✓ Good (v1.0) |
| ADR-013 per-tx PTVF scaling (α=0.88) | Single calibrated formula that survives ADR-016 supersede | ✓ Good — still active and consumed by `Σ joy_contribution` (v1.1, carried to v1.2) |
| ADR-014 unipolar positive satisfaction (default=2, scale 1..10) | Anchor metric semantics, never permit value-judgment framing | ✓ Good — D-04 type-system gate in Phase 16 enforces in code (v1.1, carried to v1.2) |
| ADR-016 Joy supersede (density → Σ joy_contribution) | Density was conceptually clean but visually unintuitive; cumulative is what users mentally model | ✓ Good — full migration completed in 1 backend + 1 frontend phase (v1.2) |
| Monthly Joy target fallback baseline = 50 (Phase 13 spike) | Needed a sane recommendation when <3 months of soul data; 50 chosen via simulation | — Pending — re-evaluate after real-user data |
| HomeHero ring: monthly reset + no discrete 100% events | ADR-012 §2 / ADR-016 §5 hard contract — gamification is the enemy of honest money | ✓ Good — structurally absent in `home_hero_card.dart` (v1.2) |
| Σ joy_contribution single-Joy-expression (no density anywhere in `lib/`) | Prevent metric drift back to Joy/¥ via partial implementations | ✓ Good — `grep -rn 'density\|joyPerYen' lib/` returns 0 hits (v1.2) |
| Custom Time Windows: HomeHero isolation kept | AnalyticsScreen window selector must never bleed into HomeHero ring semantics (single-month invariant) | ✓ Good — structural test enforcement + zero forbidden imports in `lib/features/home/` (v1.2) |
| Manual-only as audit-lens (not gating) | User wants visibility into Joy data quality without breaking the universal Joy metric | ✓ Good — AnalyticsScreen-scope chip toggle, HomeHero untouched (v1.2) |
| `entry_source` CHECK ∈ {manual, voice, ocr} | Forward-compat for MOD-005 OCR; manual fallback at sync boundary | ✓ Good — schema v17 stable; OCR writer slot reserved (v1.2) |
| Phase 13 + 17 ship without VERIFICATION.md | Single-developer flow; verification ran transitively via integration check at milestone close | ⚠️ Accept — recorded as documentation-grade close debt (v1.2) |
| 5-phase split (18-22) + cleanup phase (23) for v1.3 | Separates voice number parser (state-machine corpus) from voice category resolver (database resolution); isolates voice integration phase; cleanup phase chosen inline (vs carry to v1.4) for same-milestone debt absorption | ✓ Good — independent test surfaces, clean wave parallelism, 9/9 device UATs run in Phase 23 (v1.3) |
| Phase 18 ships first as v1.3 foundation | INPUT-03 shared widget unblocks INPUT-01 (manual), INPUT-02 (voice), EDIT-01/02 (edit-from-list) | ✓ Good — 4 hosts consume single `TransactionDetailsForm` via `Config.when(.new/.edit)` (v1.3) |
| Hold-to-record gesture (vs tap-to-toggle) | Long-press model is the dominant mobile voice-input pattern; reduces accidental activation | ✓ Good — RawGestureDetector with `Duration.zero` works on iOS + Android; consistent app-wide (v1.3) |
| `_ensureL2` 3-stage fallback (override → `${l1Id}_other` convention → `findByParent.first`) | Always-L2 contract via deterministic fallback; data-driven extensibility | ✓ Good — architecture invariant test enforces 19 expense L1s (v1.3) |
| Phase 22 G-01/G-02 elevated to BLOCKER from code review | Recognizer self-termination + silent errors are production-risk; cannot be advisory-deferred | ✓ Good — closed in plans 22-08/09/10 before Phase 22 close (v1.3) |
| OCR slot hardcodes `EntrySource.manual` pending MOD-005 | Schema accepts 'ocr' literal already (v1.2); v1.3 reserves architectural slot only with `// MOD-005: flip when writer ships (D-12)` marker | — Pending — MOD-005 OCR writer landing (v1.4+) |
| Plan 23-09 LOC-cap extraction (`voice_input_screen.dart` 838 → 776) | CLAUDE.md `<800` line cap; `VoiceLocaleReadinessMixin` + 3 pure helpers preserve behavior | ✓ Good — zero behavior change, cap re-cleared (v1.3) |
| Phase 23 cleanup phase inline (vs carry to v1.4) | Same-milestone debt absorption: surgical fixes + documentation reconciliation + device UAT runbook in single phase | ✓ Good — 9/9 plans complete; 9/9 device UATs pass; LOC-cap closed (v1.3) |
| v1.4 calendar own-book only (family-combine deferred) | Keep v1.4 list feature scoped; combining members' per-day totals adds multi-book aggregation cost | ✓ Good — `calendarDailyTotalsProvider` seam reserved; deferred to v1.5+ (v1.4) |
| `keepAlive: true` filter/sort state under `IndexedStack` | Filter/search/sort must survive tab switches; natural under IndexedStack | ✓ Good — state persists across tabs (v1.4 Phase 26) |
| Calendar provider isolated from filter state (`_dayKey` normalization) | Watching search/filter would re-render 31 day cells per keystroke | ✓ Good — provider watches only bookId/year/month (v1.4 Phase 27) |
| Swipe-delete confirm-only soft-delete, no undo | Undo needs `RestoreTransactionUseCase`; soft-delete keeps hash-chain intact | — Pending — undo deferred to v1.5+ (v1.4) |
| LIST-02 reactivity via manual `ref.invalidate` (not `watchByBookIds` stream) | Stream chain built but every mutation site already invalidates; stream went unconsumed | ⚠️ Revisit — GAP-2 dead-code debt: consume `useCase.watch()` or delete the 3-layer chain (v1.4) |
| GAP-1 fixed inline at milestone close (quick task) vs carry to v1.5 | One small, precisely-diagnosed wiring gap; cheaper to close now than track | ✓ Good — quick task 260531-u34 invalidates `calendarDailyTotalsProvider` at sync + FAB sites (v1.4) |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-31 — started milestone v1.5 文案与配色统一 (Terminology & Color Unification). Brownfield consistency refactor: unify 日常/悦己/ときめき/Daily/Joy vocabulary across ja/zh/en + internal identifiers, consolidate ~62 hardcoded colors into a semantic design-token system. Locale mapping locked; rename depth = strings + internal symbols. Defining requirements next.*

*Prior: 2026-05-31 after v1.4 列表功能 milestone — shipped + archived (7 phases, 29 plans, tag `v1.4`). Full kakeibo-style List tab. Audit `tech_debt` accepted (22/22 requirements, 7/7 phases, 7/7 flows); GAP-1 closed via quick task 260531-u34; GAP-2 dead-code + draft-Nyquist docs carried as debt.*
