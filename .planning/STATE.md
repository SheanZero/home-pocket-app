---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: Happiness Metric & Display
status: executing
stopped_at: Completed Wave 2 (11-04, 11-05, 11-06); ready for 11-07
last_updated: "2026-05-03T15:53:17.397Z"
last_activity: 2026-05-03
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 35
  completed_plans: 33
  percent: 94
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-02)

**Core value:** Family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, dual-ledger system distinguishes survival spending from soul spending
**Current focus:** Phase 11 — statistics-surface-for

## Current Position

Phase: 11 (statistics-surface-for) — EXECUTING
Plan: 7 of 8
Status: Ready to execute
Last activity: 2026-05-03

## v1.1 Phase Plan

| Phase | Goal | Requirements | Depends on |
|-------|------|--------------|------------|
| 9. Happiness Domain & Formula Layer       | Lock formulas, contracts, soul-only filter, ¥500 floor, sealed `MetricResult`, family aggregate-only return type, no-gamification ADR | HAPPY-01..09 + FAMILY-01 + FAMILY-02 (11 REQs) | — (linchpin) |
| 10. HomePage SoulFullnessCard Redesign    | Replace misleading `Happiness ROI`; render 4 personal metrics + Best Joy story card + family card with consent gate | FAMILY-03 + HOMEUI-01..04 (5 REQs) | Phase 9 |
| 11. Statistics Surface for 悦己账本        | Wire 3 dormant DAO methods + new query into AnalyticsScreen; Joy-per-¥ trend line + satisfaction histogram | STATSUI-01..04 (4 REQs) | Phase 9 (parallel-able with Phase 10) |
| 12. UI Copy Rename Pass (ARB values)      | Rename 4 ARB values ja/zh/en; lexical-hierarchy ADR; native-speaker register review | RENAME-01..06 (6 REQs) | Phase 10 + Phase 11 (must be LAST) |

**Coverage:** 26/26 v1.1 requirements mapped ✓

## Last Milestone Snapshot (v1.0)

- **Phases:** 8 (1-8)
- **Plans:** 48
- **Duration:** 2026-04-25 → 2026-04-28 (~4 days)
- **Audit Status at Close:** `tech_debt` — accepted as known debt
- **Outcome:** REAUDIT-DIFF.json reports `resolved=50, regression=0, new=0, open_in_baseline=0`
- **Tag:** `v1.0`

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table. v1.0 decisions are captured there with outcomes; older execution-log decisions are archived in `.planning/milestones/v1.0-ROADMAP.md` Milestone Summary.

**v1.1 milestone-start decisions (2026-05-01):**

- No schema changes; reuse existing `transactions.soul_satisfaction` (1-10) field
- No theme color changes; survival/soul/primary tokens locked
- No `LedgerType` enum rename; ARB values only
- Zero new pub dependencies (research HIGH-confidence: every capability maps to existing packages)
- Phase 9 is the linchpin — all formulas, contracts, and anti-gamification defenses must lock before any UI consumer builds on them

**v1.1 execution decisions (2026-05-03):**

- Phase 11 audit corrects the dormant-DAO framing: only `getDailySatisfactionTrend` is truly dormant and it is superseded by `getDailySoulRowsForPtvf`.
- Plan 07 must land the AnalyticsScreen rewrite, 8 widget deletions, test deletions, and replacement screen test as one atomic commit.
- [Phase 11]: Daily Joy/¥ folds use the same α=0.88 PTVF density formula and ptvfBaseFor(currencyCode) base as monthly happiness reports.
- [Phase 11]: Expense trend now trails the selected month via an explicit anchor instead of DateTime.now().
- [Phase 11]: Analytics ARB strings were added to ja/zh/en in one commit with the hard-locked bar-5 histogram annotation.

### Pending Todos

- Phase 9: verify `transactions.entry_source` column existence in substep 9.0 (single grep) — gates voice-bias manual-only sub-metric feasibility
- Phase 9: product decision on mean-vs-median headline (recommend mean primary + median tooltip + coverage caption)
- Phase 9: pick `Result<T>` vs `throw` envelope to match existing analytics module convention (recommend `throw`)
- Phase 11: deeper-research moment for `shadowBooksProvider` family-mode book enumeration (MEDIUM-confidence in research)

### Blockers / Concerns

No active v1.1 blockers. Carried-forward debt (from v1.0):

- **FUTURE-TOOL-03** *(coverage-baseline-review)*: After v1 feature work completes, review the active 70% coverage threshold (lowered from 80% by Phase 8 amendment); decide raise-uniformly or split-per-area
- **FUTURE-QA-01** *(smoke-test-owner-driven)*: Owner runs `08-SMOKE-TEST.md` on fresh local build before v1 release; SMOKE-NN findings recorded in `re-audit/issues.json` and `reaudit_diff.dart` re-run before v1 ships
- **FUTURE-DOC-03**: Wire `verify-doc-sweep.sh` + `verify_index_health.sh` into `.github/workflows/audit.yml` (verifiers exist locally but not in CI)
- **FUTURE-DOC-04**: Backfill `02-VALIDATION.md` and `04-VALIDATION.md` (Nyquist gap)
- **FUTURE-DOC-05**: Backfill `03-VERIFICATION.md`, `06-VERIFICATION.md`, `08-VERIFICATION.md` (canonical artifacts; substitute evidence exists)
- **FUTURE-DOC-06**: `/gsd-validate-phase 07` to remediate `nyquist_compliant: false`
- **FUTURE-DOC-01**: Pre-existing MOD-numbering drift inside MOD-002/006/007/008 internal headers
- **FUTURE-DOC-02**: ARCH-008 cites ADR-006 instead of ADR-007 in 7 places

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

**v1.1-deferred items (tracked in REQUIREMENTS.md "v2 Requirements"):**

- HAPPY-V2-01..03, STATSUI-V2-01, FAMILY-V2-01..02, TOOL-V2-01..02

## Session Continuity

Last session: 2026-05-03T14:59:33.844Z
Stopped at: Completed 11-03-PLAN.md
Resume file: None

**Planned Next:** `/gsd-execute-phase 11` to continue with Plan 11-07
