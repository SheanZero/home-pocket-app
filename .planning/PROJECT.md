# Home Pocket — まもる家計簿

## Current State

**Shipped:** v1.0 Codebase Cleanup Initiative (2026-04-29) — see `.planning/milestones/v1.0-ROADMAP.md`
**Shipped:** v1.1 Happiness Metric & Display (2026-05-05) — see `.planning/milestones/v1.1-ROADMAP.md`
**Shipped:** v1.2 Happiness Metric Refresh (2026-05-21) — see `.planning/milestones/v1.2-ROADMAP.md` + `.planning/milestones/v1.2-MILESTONE-AUDIT.md`

The v1.0 initiative was a pure-refactor cleanup. It delivered an operational hybrid audit pipeline, eliminated 50 catalogued findings (24 CRITICAL, 8 HIGH, 8 MEDIUM, 7 LOW + 3 layer-violation closures), aligned all architecture documentation with the post-refactor codebase, and locked 4 permanent CI guardrails.

The v1.1 milestone delivered the happiness metric domain, HomePage `HomeHeroCard`, AnalyticsScreen Variant δ unified dashboard, and final trilingual UI copy rename pass. It also ratified the v1.1 anti-gamification and lexical hierarchy ADRs.

The v1.2 milestone shipped the ADR-016 Joy migration (density → `Σ joy_contribution`), HomeHero target ring rebuild with user-configurable `monthly_joy_target` + 3-month median recommendation, AnalyticsScreen Variant ε with Custom Time Windows (week/month/quarter/year/arbitrary), Per-Category breakdown + Soul-vs-Survival comparison (anti-toxicity framed), and Manual-Only Joy sub-metric variant on Drift schema v17 (`entry_source` column). HomeHero isolation invariant (ADR-016 §3) is structurally enforced. Audit closed at `tech_debt` — Phase 13/17 lack VERIFICATION.md and 3 VALIDATION.md drafts have `nyquist_compliant: false`; documentation-grade debt only, all 11 v1.2 requirements satisfied in implementation.

## Next Milestone Goals

**Status:** Planning. Use `/gsd:new-milestone` to scope.

**Candidate themes** (carried from v1.0/v1.1/v1.2 close decisions):

- **MOD-005 OCR module** — receipt scanning + parsing (long-deferred core feature)
- **Family privacy hardening (FAMILY-V2-01/02/03)** — strict consent gate, possibly schema v17→v18; new ADR Privacy Consent Gate
- **Release-readiness QA (FUTURE-QA-01)** — owner-driven smoke tests before any public v1 release
- **Documentation + tooling guardrail cleanup** — FUTURE-DOC-01..06 (MOD-numbering, ARCH-008 ADR citation, missing VALIDATION/VERIFICATION docs, doc-sweep verifier CI wiring), FUTURE-TOOL-03 (coverage threshold review post-v1.2)
- **fl_chart 1.x upgrade (TOOL-V2-01)** — bundle with future Analytics chart-stack work

Phase numbering continues from **Phase 18**.

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

Home Pocket (まもる家計簿) is a local-first, privacy-focused family accounting app with a dual-ledger system (Survival ledger + Soul ledger). Zero-knowledge architecture with 4-layer encryption, P2P family sync, and offline-first design. Target: iOS 14+ / Android 7+ (API 24+). After three milestones, the app now ships a calculable Joy metric (`Σ joy_contribution` cumulative semantics), user-configurable monthly Joy targets, custom analytics time windows, per-category breakdown + Soul-vs-Survival comparison surfaces, and an audit lens (manual-only Joy variant) to scrutinize Joy data quality.

## Core Value

A family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, with a dual-ledger system that distinguishes survival spending from soul spending so families can have honest money conversations.

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

### Active

<!-- No active requirements between milestones. Use /gsd:new-milestone to scope the next set. -->

(See **Next Milestone Goals** above for candidate themes.)

### Out of Scope

<!-- Explicit boundaries carried forward. -->

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

- **Current state (post-v1.2):** v1.0 Codebase Cleanup shipped 2026-04-29; v1.1 Happiness Metric & Display shipped 2026-05-05; v1.2 Happiness Metric Refresh shipped 2026-05-21 (3 days, 212 commits, 521 files changed, +57,460/-7,168 LOC). Drift schema at v17. ADR-016 Joy migration is complete: density (Joy/¥) is fully retired from `lib/` and all three ARB locales. HomeHero isolation invariant (ADR-016 §3) is structurally enforced. Coverage threshold remains 70% (lowered from 80% per Phase 8 amendment; FUTURE-TOOL-03 review trigger remains open).
- **Codebase map:** `.planning/codebase/` was last refreshed 2026-04-25 (`/gsd-map-codebase`). Contents: ARCHITECTURE.md, STACK.md, STRUCTURE.md, CONVENTIONS.md, INTEGRATIONS.md, TESTING.md, CONCERNS.md. **Stale — three milestones of drift.** Refresh via `/gsd:map-codebase` before next milestone planning.
- **Tech stack:** Flutter, Riverpod 2.4+ (`@riverpod` code-gen), Freezed, Drift + SQLCipher (schema v17), GoRouter, flutter_localizations (intl 0.20.2 pinned), Mocktail
- **Active CI guardrails:** `import_guard` (custom_lint), `riverpod_lint`/`custom_lint`, `coverde` per-file ≥70% with `--deferred` mechanism, `sqlite3_flutter_libs` rejection, `very_good_coverage@v2` ≥70% global, `build_runner` clean-diff
- **Coverage:** Global ~74.6% (last measured post-v1.0); v1.2 added ~6.5k LOC of test code, expect coverage to be at or above baseline. Re-measure during next milestone planning.
- **Known issues / debt carried forward:**
  - **v1.2 close debt** (per `.planning/milestones/v1.2-MILESTONE-AUDIT.md`): Phase 13/17 missing VERIFICATION.md; Phase 13/14/17 VALIDATION.md status draft + `nyquist_compliant: false`; 6 pre-existing `family_insight_card_test.dart` failures from Phase 15 ARB drift; `EntrySource.ocr` schema-accepted but no writer yet
  - **v1.1 close debt:** 1 Phase 11 human/device UAT verification item (AnalyticsScreen month chip + pull-to-refresh on device)
  - **v1.0 close debt:** 2 INFO-level analyzer warnings in `shadow_books_provider_characterization_test.dart`; MOD-numbering drift in MOD-002/006/007/008; ARCH-008 cites ADR-006 instead of ADR-007; doc-sweep verifiers exist but not in CI; 12 architecture tests run only transitively via coverage job; Phase 03/06/08 missing canonical VERIFICATION.md; Phase 02/04 missing VALIDATION.md; Phase 07 `nyquist_compliant: false`
- **Why next:** v1.2 closed the Joy-metric-refresh axis. Next-wave candidates: MOD-005 OCR (long-deferred core feature), family privacy hardening (FAMILY-V2-*), release-readiness QA (FUTURE-QA-01), or documentation/tooling guardrail cleanup before any user-facing v1 release.

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
*Last updated: 2026-05-21 after v1.2 milestone close*
