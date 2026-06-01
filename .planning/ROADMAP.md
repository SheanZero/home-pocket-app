# Roadmap: Home Pocket

## Milestones

- ✅ **v1.0 Codebase Cleanup Initiative** — Phases 1-8 (shipped 2026-04-29) — see [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Happiness Metric & Display** — Phases 9-12 (shipped 2026-05-05) — see [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Happiness Metric Refresh** — Phases 13-17 (shipped 2026-05-21) — see [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 迭代帐本输入** — Phases 18-23 (shipped 2026-05-26) — see [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 列表功能** — Phases 24-30 (shipped 2026-05-31) — see [archive](milestones/v1.4-ROADMAP.md)
- 🚧 **v1.5 文案与配色统一** — Phases 31-34 (in progress)

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

### v1.5 文案与配色统一 (Active)

- [x] **Phase 31: Terminology Rename** (6 plans) — Unify all user-facing ARB values (zh/ja/en) and rename internal identifiers (ARB keys, AppColors symbols, LedgerType enum + v18 migration, soul*/survival* files/classes, soul_satisfaction→joy_fullness column); close with analyze-clean gate + ADR-017 (completed 2026-06-01)
- [x] **Phase 32: Palette Exploration & Selection** — Mine design references, produce 4–5 Pencil color-scheme mockups, user selects one canonical palette recorded as ADR (completed 2026-06-01)
- [x] **Phase 33: Color Token System & Consolidation** (7 plans) — Build ThemeExtension<AppPalette> token system encoding ADR-018 Teal Clarity; replace 61 Color(0x…) literals; full dark-mode rollout (D-07/THEME-V2-02 absorbed) (completed 2026-06-01)
- [x] **Phase 34: Golden Re-baseline & Verification** — Regenerate all golden/visual baselines to the new palette; confirm full test suite green; verify no stale vocabulary or color literals remain (completed 2026-06-01)

## Phase Details

### Phase 31: Terminology Rename
**Goal**: The app's vocabulary for the two ledgers is unified across all three locales — user-facing ARB values read 日常/悦己/ときめき/Daily/Joy everywhere, and internal Dart/ARB identifiers (keys, AppColors symbols, dependent call sites) are renamed to match
**Depends on**: Phase 30
**Requirements**: TERM-01, TERM-02, TERM-03, TERM-04, TERMID-01, TERMID-02, TERMID-03, TERMID-04
**Success Criteria** (what must be TRUE):
  1. `grep -r 'soulLedger\|survival[A-Z]\|soul[A-Z]' lib/l10n/` returns zero hits in ARB key names; `flutter gen-l10n` completes without warnings
  2. `grep -rn 'AppColors\.survival\|AppColors\.soul' lib/` returns zero hits in non-generated source
  3. `grep -rn '生存\|灵魂\|魂\|ソウル\|Survival\|Soul' lib/l10n/*.arb` returns zero hits in user-facing value strings (excluding @description metadata)
  4. `flutter analyze` reports 0 issues; `dart run custom_lint --no-fatal-infos` reports 0 errors; `build_runner` clean-diff (AUDIT-10 guardrail green)
  5. ADR-015 (or successor) contains an appended section documenting the canonical 日常/悦己/ときめき/Daily/Joy mapping as the locked lexical hierarchy
**Plans**: 6 plans
- [x] 31-01-PLAN.md — Wave-0 RED v18 migration test (D-02/D-16 contract: enum-value rewrite + CHECK recreate + soul_satisfaction→joy_fullness)
- [x] 31-02-PLAN.md — LedgerType enum rename + v17→v18 migration + soul_satisfaction column rename + persistence literals (turns Wave-0 GREEN)
- [x] 31-03-PLAN.md — ARB keys (25 roots) + values + @description rewrite (3 locales) + gen-l10n + call sites
- [x] 31-04-PLAN.md — AppColors survival/soul + derived symbols rename + ~60 call sites
- [x] 31-05-PLAN.md — soul*/survival* file + class + snapshot-field renames (git mv + Serena)
- [x] 31-06-PLAN.md — ADR-017 Terminology Unification + ADR-015 pointer + INDEX + REQUIREMENTS Out-of-Scope amend (D-06)
**UI hint**: yes

### Phase 32: Palette Exploration & Selection
**Goal**: A canonical color palette is selected from 4–5 concrete Pencil mockup proposals, with the decision and exact hex values recorded in an ADR as the single authoritative reference for all subsequent color work
**Depends on**: Phase 31
**Requirements**: PALETTE-01, PALETTE-02, PALETTE-03
**Success Criteria** (what must be TRUE):
  1. Design references (VoltAgent/awesome-design-md brand palettes, dual-ledger family-finance context) are synthesized into written candidate directions with rationale — at least 4 distinct mood/palette directions identified
  2. Exactly 4–5 full color-scheme proposals exist as Pencil mockups covering representative screens (e.g. home hero, transaction list, analytics), each defining primary + 日常/悦己 ledger accents + surface + semantic roles
  3. The user has reviewed the Pencil proposals and designated one (or a named hybrid) as the selected palette, with that selection recorded as an accepted ADR containing the final hex values for every semantic color role
**Plans**: 3 plans
- [x] 32-01-PLAN.md — PALETTE-01 synthesis doc: mine VoltAgent brand DESIGN.md refs → ≥4 distinct named directions across the D-04×D-05 axis matrix (rationale + lineage + anchor hex + WCAG flags)
- [x] 32-02-PLAN.md — PALETTE-02 Pencil mockups: fresh `.pen`, get_guidelines-first, 4–5 scheme groups × 6 frames (home-hero/list/analytics × light/dark), palette-as-variables, every taxonomy role + per-scheme WCAG pass
- [x] 32-03-PLAN.md — PALETTE-03 human-selection checkpoint (autonomous:false) → ratify ADR-018 (post-selection only) with full light+dark hex-per-role table keyed to AppColors symbols + ADR-000_INDEX update
**UI hint**: yes

### Phase 33: Color Token System & Consolidation
**Goal**: The selected palette is encoded as the single source of truth in a complete semantic design-token system (`AppPalette` ThemeExtension); every hardcoded color literal in feature/UI code is replaced by an `AppPalette` token; the correct 日常/悦己 ledger accents are applied uniformly across all surfaces
**Depends on**: Phase 32
**Requirements**: COLOR-01, COLOR-02, COLOR-03
**Success Criteria** (what must be TRUE):
  1. `grep -rn 'Color(0x\|Color(0X' lib/features/ lib/application/ lib/shared/` returns zero hits — no raw hex color literals remain outside the theme layer
  2. The theme layer (`lib/core/theme/`) contains a single semantic design-token system (primary / ledger / surface / semantic groups + profile dark palette) with no duplicate constant definitions (e.g. `_joyTargetStartColor`, repeated profile-dark constants are consolidated)
  3. Every screen that surfaces a 日常 or 悦己 ledger context uses the correct token from the selected palette — no mismatched or stale pre-selection colors remain
  4. `flutter analyze` reports 0 issues after all token replacements; `build_runner` clean-diff
  5. Full dark-mode rollout (D-07, absorbs THEME-V2-02): every screen responds to dark mode via `context.palette.*` — no `isDark` ternaries and no `AppColorsDark.*` direct refs remain in `lib/features/`
**Plans**: 8 plans
- [x] 33-01-PLAN.md — Wave-0 RED tests (color_literal_scan, app_palette_test, theme_dark_mode_coverage)
- [x] 33-02-PLAN.md — AppPalette ThemeExtension + app_theme.dart registration + app_text_styles.dart fix
- [x] 33-03-PLAN.md — home/ + analytics/ migration (D-05 hero gradient, D-06 olive→success)
- [x] 33-04-PLAN.md — accounting/ migration (isDark removal, Bucket E error family, Bucket A)
- [x] 33-05a-PLAN.md — family_sync/ migration (Bucket B coral→teal gradients, Bucket C member gradients D-04)
- [x] 33-05b-PLAN.md — settings/ + list/ migration (Bucket F info/error, WCAG amount-text variants, dark-mode)
- [x] 33-06-PLAN.md — profile/ migration (Bucket A delete, avatar D-04 re-hue)
- [x] 33-07-PLAN.md — Shim deletion + REQUIREMENTS/ROADMAP THEME-V2-02 amend + full suite GREEN
**UI hint**: yes

### Phase 34: Golden Re-baseline & Verification
**Goal**: All visual/golden baselines are regenerated and passing against the new palette; the full test suite is green; and a final vocabulary + color-literal audit confirms zero stale hits — closing the milestone with no residual terminology or color debt
**Depends on**: Phase 33
**Requirements**: COLOR-04
**Success Criteria** (what must be TRUE):
  1. All golden test files regenerated; `flutter test` completes with 0 failures and 0 golden mismatches; diffs confirm the palette change is the only visual delta (no unexpected layout or text changes)
  2. Final cross-check: `grep -rn '生存\|灵魂\|魂\|ソウル\|Survival\|Soul' lib/l10n/*.arb` returns zero hits; `grep -rn 'Color(0x\|Color(0X' lib/features/ lib/application/ lib/shared/` returns zero hits
  3. `flutter analyze` reports 0 issues; coverage gate ≥70% global remains green
**Plans**: 5 plans
Plans:
- [x] 34-01-PLAN.md — Wave 0: add dark variants to 7 light-only golden test files + delete orphaned summary_cards PNGs
- [x] 34-02-PLAN.md — Wave 1: selective re-baseline with diff attribution (D-02/D-04 protocol) + generate 27 new dark masters
- [x] 34-03-PLAN.md — Wave 2: D-03a comprehensive audit + stale Color literal remediation + success-criteria greps
- [x] 34-04-PLAN.md — Wave 2 (parallel): D-03b best-effort .pen sync to ADR-018 (non-blocking)
- [x] 34-05-PLAN.md — Wave 3: final full-suite gate (flutter test 0 failures, analyze 0 issues, coverage ≥70%, both greps empty)

## Milestone Progress

| Milestone | Phases | Plans Complete | Status | Shipped |
|-----------|--------|----------------|--------|---------|
| v1.0 Codebase Cleanup Initiative | 1-8 | 48/48 | Complete | 2026-04-29 |
| v1.1 Happiness Metric & Display | 9-12 | 40/40 | Complete | 2026-05-05 |
| v1.2 Happiness Metric Refresh | 13-17 | 37/37 | Complete | 2026-05-21 |
| v1.3 迭代帐本输入 | 18-23 | 47/47 | Complete | 2026-05-26 |
| v1.4 列表功能 | 24-30 | 29/29 | Complete | 2026-05-31 |
| v1.5 文案与配色统一 | 31-34 | 0/5 (P31+P32+P33 done, P34 planned) | In progress | — |
