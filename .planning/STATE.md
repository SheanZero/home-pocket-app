---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: Happiness Metric Refresh
status: executing
stopped_at: Completed 15-05-PLAN.md
last_updated: "2026-05-19T13:23:48.712Z"
last_activity: 2026-05-19
progress:
  total_phases: 5
  completed_phases: 2
  total_plans: 19
  completed_plans: 18
  percent: 40
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-19)

**Core value:** Family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, dual-ledger system distinguishes survival spending from soul spending
**Current focus:** Phase 15 — custom-time-windows-happy-v2-02

## Current Position

Phase: 15 (custom-time-windows-happy-v2-02) — EXECUTING
Plan: 6 of 6
Status: Ready to execute
Last activity: 2026-05-19

## v1.2 Phase Plan

| Phase | Goal | Requirements | Depends on |
|-------|------|--------------|------------|
| 13. ADR-016 Backend Foundation | Stabilize Joy backend on Σ joy_contribution; ship schema + recommendation infra for Phases 14/17 | JOYMIG-02, JOYMIG-05 | — (first v1.2 phase) |
| 14. ADR-016 Frontend + ARB Reconciliation (TOOL-V2-02) | Ship HomeHero rebuild + AnalyticsScreen Variant ε + Settings target UI + ARB cleanup; honor 100% behavior contract | JOYMIG-01, JOYMIG-03, JOYMIG-04, JOYMIG-06, TOOL-V2-02 | Phase 13 |
| 15. Custom Time Windows | Week/month/quarter/year/arbitrary selector wired across all Joy metrics in AnalyticsScreen | HAPPY-V2-02 | Phase 14 |
| 16. Per-Category Breakdown + Soul-vs-Survival | Per-category satisfaction breakdown + Soul-vs-Survival comparison (both anti-toxicity framed) | HAPPY-V2-01, STATSUI-V2-01 | Phases 14 + 15 |
| 17. Manual-Only Joy Sub-Metric | Schema migration (entry_source column) + manual-only Joy variant toggle in AnalyticsScreen | HAPPY-V2-03 | Phases 13 + 14 |

**Coverage:** 11/11 v1.2 requirements mapped ✓

**Cross-phase constraints (apply to every phase):** ADR-012 No Gamification v1.1, ADR-014 Unipolar Positive Satisfaction, ADR-016 §2 single-Joy-expression, ADR-013 append-only update rule, all permanent CI guardrails (analyze 0, custom_lint 0, import_guard 0, riverpod_lint 0, per-file coverage ≥70%, global ≥70%, build_runner clean-diff, sqlite3_flutter_libs rejection), ARB ja/zh/en parity.

## Last Milestone Snapshot (v1.1)

- **Phases:** 4 (9-12)
- **Plans:** 40
- **Duration:** 2026-05-01 → 2026-05-05
- **Audit Status at Close:** `known_debt` — accepted (1 Phase 11 human UAT verification item)
- **Outcome:** Happiness Metric & Display shipped — HomeHeroCard, AnalyticsScreen Variant δ, trilingual rename pass, ADR-012/013/014/015 ratified
- **Tag:** `v1.1`

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table. v1.0 + v1.1 decisions captured there with outcomes.

**v1.2 milestone-start decisions (2026-05-19):**

- ADR-016 ratified 2026-05-19: Σ joy_contribution supersedes density (Joy/¥) as the single Joy expression; ADR-013 marked as superseded via append-only update (per-tx PTVF scaling formula stays active)
- v1.1 baseline-purity is explicitly broken with this milestone (per ADR-016 §1) — accepted cost
- HomeHero ring is single-month accumulation with sage-green→gold smooth color transition; **no discrete events** at 100% (no copy, no toast, no notification, no haptic, no celebration animation) per ADR-016 §5 + ADR-012 §2
- monthly_joy_target user-configurable; recommended value = `ceil(median(past 3 months Σ joy_contribution))` when ≥3 months data, else fallback baseline 50 (Phase 13 spike)
- Family privacy hardening (FAMILY-V2-01/02/03) explicitly deferred to keep v1.2 Joy-axis focused
- Phase numbering continues from v1.1 (Phase 13 starts v1.2)

**v1.1 execution decisions (carried for reference):**

- Phase 11 audit corrects the dormant-DAO framing: only `getDailySatisfactionTrend` is truly dormant and it is superseded by `getDailySoulRowsForPtvf`.
- [Phase 11]: Daily Joy/¥ folds use the same α=0.88 PTVF density formula and ptvfBaseFor(currencyCode) base as monthly happiness reports.
- [Phase 11]: Expense trend now trails the selected month via an explicit anchor instead of DateTime.now().
- [Phase 11]: Analytics ARB strings were added to ja/zh/en in one commit with the hard-locked bar-5 histogram annotation.
- [Phase 11]: Variant δ AnalyticsScreen shipped as a 2-region unified dashboard.
- [Phase 15]: Plan 03 retains MonthlyReport.previousMonthComparison for HomeHero but removes the AnalyticsScreen total-spending MoM delta UI. — This preserves HomeHero compatibility while clearing the ADR-012 cross-period delta surface.
- [Phase 15]: Plan 03 uses endDate as the display anchor for MonthlyReport, HappinessReport, and FamilyHappiness year/month fields. — Source-of-truth query bounds are now startDate/endDate.
- [Phase 15]: Plan 04 keeps SelectedTimeWindow default auto-dispose because MainShellScreen IndexedStack keeps tabs alive. — Avoids unnecessary provider lifetime widening while preserving tab-session behavior.
- [Phase 15]: Plan 05 added FormatterService.formatShortMonthDay as the presentation-safe delegate for selector date labels. — The selector widgets must not import infrastructure formatters directly, and DateFormatter already owned the actual formatting behavior.
- [Phase 15]: Plan 05 uses isScrollControlled for the time-window bottom sheet. — The type row plus chooser body overflows Flutter's default half-height modal constraint in tests.

### Pending Todos

- **Phase 17 prereq:** confirm `transactions.entry_source` column truly doesn't exist (Phase 9 of v1.1 noted absence; re-verify before plan-phase 17)

### Blockers / Concerns

No active v1.2 blockers. Carried-forward debt (from v1.0/v1.1):

- **FUTURE-TOOL-03** *(coverage-baseline-review)*: Review 70% coverage threshold after v1.2 close
- **FUTURE-QA-01** *(smoke-test-owner-driven)*: Owner runs smoke tests before v1 release
- **FUTURE-DOC-01..06** *(documentation drift)*: 6 doc-related items (MOD-numbering, ARCH-008 ADR citation, missing VALIDATION/VERIFICATION docs, doc-sweep verifier CI wiring)
- **FUTURE-ARCH-04** *(security)*: `recoverFromSeed()` key-overwrite bug fix (held — security architecture out of scope per long-term project rule)
- **v1.1 verification debt:** Phase 11 device/simulator UAT for AnalyticsScreen month chip + pull-to-refresh (human_needed)

### Quick Tasks Completed

| # | Description | Date | Commit | Status | Directory |
|---|-------------|------|--------|--------|-----------|
| 260518-kyr | Fix soul stats and monthly favorite not refreshing after new soul ledger entry | 2026-05-18 | 7f216e7 | Verified | [260518-kyr-fix-soul-stats-and-monthly-favorite-not-](./quick/260518-kyr-fix-soul-stats-and-monthly-favorite-not-/) |
| 260518-pf5 | Home polish Bucket A — typography spacing, ledger bar color, caption removal, family invite i18n, tx display, analytics spacing | 2026-05-18 | 5b7b6ee | Verified (3/6 PASS round 1; remaining 3 items reworked in pf6) | [260518-pf5-home-polish-typography-spacing-ledger-ba](./quick/260518-pf5-home-polish-typography-spacing-ledger-ba/) |
| 260518-v4v | Home polish Round 2 — Best Joy Variant A (Pencil mock) + r2 flat-layout tweak, recent-tx soul color + icon reposition, home SizedBox 16→24 for analytics parity | 2026-05-19 | e142f4f | Verified | [260518-v4v-home-polish-round-2-best-joy-variant-a-r](./quick/260518-v4v-home-polish-round-2-best-joy-variant-a-r/) |

## Deferred Items

Items acknowledged and deferred at v1.0 milestone close on 2026-04-29:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| FUTURE-ARCH-01 | Drive `CategoryLocaleService` from ARB files (eliminate 735-line static map) | v2 backlog | v1.0 close |
| FUTURE-ARCH-02 | Replace residual committed `*.mocks.dart` with full Mocktail (largely closed in Phase 4) | v2 backlog | v1.0 close |
| FUTURE-ARCH-03 | Upgrade audit pipeline to DCM (paid) | v2 backlog | v1.0 close |
| FUTURE-ARCH-04 | Fix `recoverFromSeed()` key-overwrite bug (security-architecture) | v2 backlog | v1.0 close |
| FUTURE-TOOL-01 | Add `riverpod_lint` 3.x once `json_serializable` analyzer conflict resolves upstream | v2 backlog | v1.0 close |
| FUTURE-TOOL-02 | Drift-column unused-detection custom Dart script | v2 backlog | v1.0 close |
| FUTURE-TOOL-03 | Coverage-baseline review (raise uniformly to 80% or split per-area) | v2 backlog | 2026-04-28 (Phase 8 amend) |
| FUTURE-QA-01 | Owner-driven smoke-test execution before v1 release | v2 backlog | 2026-04-28 (Phase 8 close) |
| FUTURE-DOC-01 | MOD-numbering drift in MOD-002/006/007/008 internal headers | v2 backlog | v1.0 close |
| FUTURE-DOC-02 | ARCH-008 ADR-006 → ADR-007 citation drift | v2 backlog | v1.0 close |
| FUTURE-DOC-03 | Wire doc-sweep verifiers into CI | v2 backlog | v1.0 close |
| FUTURE-DOC-04 | Backfill 02-VALIDATION.md + 04-VALIDATION.md | v2 backlog | v1.0 close |
| FUTURE-DOC-05 | Backfill 03/06/08-VERIFICATION.md (substitute evidence exists) | v2 backlog | v1.0 close |
| FUTURE-DOC-06 | /gsd-validate-phase 07 (`nyquist_compliant: false`) | v2 backlog | v1.0 close |
| Tech-debt nit | 2 INFO-level analyzer warnings in `shadow_books_provider_characterization_test.dart` (lines 57, 73) | accept | v1.0 close |
| Tech-debt nit | `amount_display.dart` absent from `cleanup-touched-files.txt` (Plan 08-04 deferred-items.md) | accept | v1.0 close |

**v1.1-deferred items (now subsumed into v1.2 active scope):**

- HAPPY-V2-01..03 → Phases 16, 15, 17 respectively
- STATSUI-V2-01 → Phase 16
- TOOL-V2-02 → Phase 14
- FAMILY-V2-01..03 → still v2 backlog (explicitly out of v1.2 scope to keep Joy-axis focus)
- TOOL-V2-01 (fl_chart 1.x) → still v2 backlog

**Items acknowledged and deferred at v1.1 milestone close on 2026-05-05:**

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| verification_gap | Phase 11 `11-VERIFICATION.md` human UAT: run AnalyticsScreen on device/simulator and exercise month chip + pull-to-refresh on real app data | human_needed | v1.1 close |

## Session Continuity

Last session: 2026-05-19T13:23:48.706Z
Stopped at: Completed 15-05-PLAN.md
Resume file: None

**Planned Next:** `/gsd:discuss-phase 15` — discuss Custom Time Windows before planning
