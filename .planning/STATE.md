---
gsd_state_version: 1.0
milestone: shipped
milestone_name: v1.0 Codebase Cleanup Initiative
status: shipped
stopped_at: v1.0 milestone archived 2026-04-29 — awaiting next milestone via /gsd-new-milestone
last_updated: "2026-04-29T00:00:00.000Z"
last_activity: 2026-04-29
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-29)

**Core value:** Family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, dual-ledger system distinguishes survival spending from soul spending
**Current focus:** Planning v1.1 milestone (run `/gsd-new-milestone`)

## Current Position

**Milestone:** v1.0 SHIPPED 2026-04-29 (archived to `.planning/milestones/v1.0-ROADMAP.md`)
**Next:** No active milestone. Run `/gsd-new-milestone` to begin v1.1 planning (questioning → research → requirements → roadmap).

Progress: [          ] 0% (next milestone)

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

### Pending Todos

None at milestone close.

### Blockers / Concerns

No active blockers. Carried-forward debt:

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

## Session Continuity

Last session: 2026-04-29 (v1.0 milestone close + archive)
Stopped at: v1.0 archived; tag pending; ready for `/gsd-new-milestone`
Resume file: None

**Planned Next:** `/gsd-new-milestone` to define v1.1 requirements
