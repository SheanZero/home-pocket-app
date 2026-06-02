# Roadmap: Home Pocket

## Milestones

- ✅ **v1.0 Codebase Cleanup Initiative** — Phases 1-8 (shipped 2026-04-29) — see [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Happiness Metric & Display** — Phases 9-12 (shipped 2026-05-05) — see [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Happiness Metric Refresh** — Phases 13-17 (shipped 2026-05-21) — see [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 迭代帐本输入** — Phases 18-23 (shipped 2026-05-26) — see [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 列表功能** — Phases 24-30 (shipped 2026-05-31) — see [archive](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 文案与配色统一** — Phases 31-35 (shipped 2026-06-02) — see [archive](milestones/v1.5-ROADMAP.md)

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

<details>
<summary>✅ v1.2 Happiness Metric Refresh (Phases 13-17) — SHIPPED 2026-05-21</summary>

- [x] Phase 13: ADR-016 Backend Foundation (7/7 plans) — completed 2026-05-19
- [x] Phase 14: ADR-016 Frontend + ARB Reconciliation (6/6 plans) — completed 2026-05-19
- [x] Phase 15: Custom Time Windows (6/6 plans) — completed 2026-05-19
- [x] Phase 16: Per-Category Breakdown + Soul-vs-Survival (10/10 plans) — completed 2026-05-20
- [x] Phase 17: Manual-Only Joy Sub-Metric (8/8 plans) — completed 2026-05-21

**Outcome:** v1.2 migrated the Joy metric from density (Joy/¥) to cumulative `Σ joy_contribution` (ADR-016): HomeHero rebuilt with sage-green→gold target ring, Settings exposes user-configurable `monthly_joy_target` with 3-month median recommendation + fallback baseline 50, AnalyticsScreen Variant ε retired density and added Custom Time Windows (week/month/quarter/year/arbitrary), Per-Category breakdown + Soul-vs-Survival comparison with anti-toxicity framing, and Manual-Only Joy sub-metric variant on Drift schema v17 (`entry_source` column). HomeHero isolation invariant (ADR-016 §3) structurally enforced. Audit status `tech_debt` accepted at close — Phase 13/17 lack VERIFICATION.md; 3 Nyquist VALIDATION.md drafts; documentation-grade debt only. Full details: `.planning/milestones/v1.2-ROADMAP.md` + `.planning/milestones/v1.2-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.3 迭代帐本输入 (Phases 18-23) — SHIPPED 2026-05-26</summary>

- [x] Phase 18: Shared Details Form Foundation (8/8 plans) — completed 2026-05-22
- [x] Phase 19: Manual One-Step + Keypad Polish (5/5 plans) — completed 2026-05-23
- [x] Phase 20: Voice Number Parser (zh + ja) (9/9 plans) — completed 2026-05-24
- [x] Phase 21: Voice Category Resolver Level-2 Enforcement (6/6 plans) — completed 2026-05-25
- [x] Phase 22: Voice One-Step Integration + Record Button UX (10/10 plans) — completed 2026-05-25
- [x] Phase 23: v1.3 Cleanup — Scanner Allow-Lists + Voice Flow Polish (9/9 plans) — completed 2026-05-26

**Outcome:** v1.3 transformed ledger entry into single-screen, voice-trustworthy core experience. Single shared `TransactionDetailsForm` widget powers 4 hosts (manual, voice, edit, OCR review). `ManualOneStepScreen` collapses 2-screen entry chain; SmartKeyboard 48dp non-negotiable touch-target floor with 6 golden baselines. Locale-aware zh+ja voice number parsing (state machines + `VoiceChunkMerger` 2.5s continued-listening window) at zh 96% + ja 100% corpus accuracy. `VoiceCategoryResolver` always-L2 contract with merchant DB + extensible synonym dictionary. Hold-to-record gesture with AnimatedContainer shape morph + caption swap (`<100ms` verified). 2 BLOCKER gaps (G-01/G-02) elevated and closed in Phase 22. Phase 23 cleanup absorbed carried tech-debt: scanner allow-lists, 6 voice-flow surgical fixes, 4 mechanical polish items, REQUIREMENTS.md reconciliation, 9/9 device UATs passed, `voice_input_screen.dart` slimmed 838→776 LOC via mixin + helpers extraction. Audit status `tech_debt` accepted at close — documentation-grade Nyquist debt only; all 15 v1.3 requirements satisfied and reconciled. Full details: `.planning/milestones/v1.3-ROADMAP.md` + `.planning/milestones/v1.3-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.4 列表功能 (Phases 24-30) — SHIPPED 2026-05-31</summary>

- [x] Phase 24: Data Layer Extension (3/3 plans) — completed 2026-05-29
- [x] Phase 25: Domain Models + Use Case (2/2 plans) — completed 2026-05-29
- [x] Phase 26: Providers + Shell Wiring (4/4 plans) — completed 2026-05-30
- [x] Phase 27: Calendar Header + Month Summary (4/4 plans) — completed 2026-05-30
- [x] Phase 28: Transaction Tile + Sort/Filter Bar (7/7 plans) — completed 2026-05-30
- [x] Phase 29: List Screen Assembly + Family (4/4 plans) — completed 2026-05-30
- [x] Phase 30: i18n + Empty States + Golden Polish (5/5 plans) — completed 2026-05-31

**Outcome:** Built the placeholder List tab into a full transaction overview. New `lib/features/list/` module: `table_calendar` month header (per-day expense grid + month nav + day-tap filter + month summary), a sortable (date / edit-time / amount ± direction) · searchable (category·merchant·note) · filterable (ledger · multi-category · family-member, AND-composed) transaction list, family-aware shadow-book merge with per-row owner attribution + "Mine only", reactive updates + pull-to-refresh reusing the v1.3 edit / soft-delete (hash-chain-safe) path, 3-variant empty states, and ~20–25 new ARB keys × 3 locales with golden baselines. Shared `DateBoundaries` util consolidated month-boundary arithmetic. GAP-1 (calendar staleness after family-sync / FAB) closed at milestone close via quick task 260531-u34. Audit `tech_debt` accepted — 22/22 requirements, 7/7 phases, 7/7 E2E flows satisfied; residual GAP-2 dead-code + draft-Nyquist documentation debt only. Full details: `.planning/milestones/v1.4-ROADMAP.md` + `.planning/milestones/v1.4-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.5 文案与配色统一 (Phases 31-35) — SHIPPED 2026-06-02</summary>

- [x] Phase 31: Terminology Rename (6/6 plans) — completed 2026-06-01
- [x] Phase 32: Palette Exploration & Selection (3/3 plans) — completed 2026-06-01
- [x] Phase 33: Color Token System & Consolidation (8/8 plans) — completed 2026-06-01
- [x] Phase 34: Golden Re-baseline & Verification (5/5 plans) — completed 2026-06-01
- [x] Phase 35: Close Vocab Leaks — a11y Semantics labels (W1) + totalSoulTx identifiers (W2) (2/2 plans) — completed 2026-06-02

**Outcome:** Brownfield consistency refactor unifying the half-migrated dual-ledger vocabulary across all 3 locales + internal code, and consolidating scattered colors into a single semantic token system. Phase 31 renamed the `LedgerType` enum (survival→daily, soul→joy) across 242 call sites, all 25 ledger-vocab ARB key roots + values to canonical 日常/悦己/ときめき/Daily/Joy, and ran the v17→v18 Drift migration (stored enum-value rewrite + `soul_satisfaction`→`joy_fullness`), recorded in ADR-017. Phase 32 mined 5 candidate palette directions → 5 Pencil schemes × 6 frames → user-selected Scheme D "Teal Clarity" (teal primary, Daily teal-navy ↔ Joy gold), recorded in ADR-018 with a full light+dark hex-per-role table. Phase 33 built the `AppPalette` ThemeExtension as the single source of truth, replaced all `Color(0x…)` literals, deleted the AppColors/AppColorsDark shims, and rolled out full dark mode (THEME-V2-02 pulled forward, D-07). Phase 34 re-baselined 50 golden masters + added 27 dark masters (77 total) to the teal palette with full suite 2281/2281 green. Phase 35 closed two residual leaks found by the milestone audit (W1 hardcoded a11y Semantics labels → l10n; W2 `totalSoulTx`→`totalJoyTx` across Freezed models + use-cases + 9 tests). Audit `tech_debt` accepted at close — 15/15 requirements, 5/5 phases, 6/6 integration seams wired; residual is one pending on-device screen-reader UAT, draft-Nyquist docs (P31/32/34/35), and the documented out-of-scope `Book.*Balance` DB-column carve-out. Full details: `.planning/milestones/v1.5-ROADMAP.md` + `.planning/milestones/v1.5-MILESTONE-AUDIT.md`.

</details>

## Milestone Progress

| Milestone | Phases | Plans Complete | Status | Shipped |
|-----------|--------|----------------|--------|---------|
| v1.0 Codebase Cleanup Initiative | 1-8 | 48/48 | Complete | 2026-04-29 |
| v1.1 Happiness Metric & Display | 9-12 | 40/40 | Complete | 2026-05-05 |
| v1.2 Happiness Metric Refresh | 13-17 | 37/37 | Complete | 2026-05-21 |
| v1.3 迭代帐本输入 | 18-23 | 47/47 | Complete | 2026-05-26 |
| v1.4 列表功能 | 24-30 | 29/29 | Complete | 2026-05-31 |
| v1.5 文案与配色统一 | 31-35 | 24/24 | Complete | 2026-06-02 |
