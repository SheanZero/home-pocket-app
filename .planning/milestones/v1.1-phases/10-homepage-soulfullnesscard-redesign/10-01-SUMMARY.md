---
phase: 10-homepage-soulfullnesscard-redesign
plan: 01
subsystem: docs
tags: [requirements, spec-amendment, traceability]

# Dependency graph
requires:
  - phase: 10-homepage-soulfullnesscard-redesign
    provides: 10-CONTEXT.md decisions D-06 (scope expansion) and D-08 (FAMILY-03 minimum-gate)
provides:
  - HOMEUI-05/06/07 codified as v1.1 active requirements
  - Traceability rows mapping HOMEUI-05/06/07 to Phase 10
  - v1.1 active requirement count updated 25 → 28
  - FAMILY-03 annotated with Phase 10 minimum-gate semantic
  - FAMILY-V2-03 added to v2 deferred section
affects: [phase-10 downstream plans, phase-checker, re-audit, roadmap-update]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Spec amendment via append + targeted edit (no renumbering, no removals)"

key-files:
  created: []
  modified:
    - .planning/REQUIREMENTS.md

key-decisions:
  - "Append HOMEUI-05/06/07 as new v1.1 active requirements rather than reshuffling existing IDs (preserves traceability and downstream phase-checker references)"
  - "FAMILY-03 stays in v1.1 with relaxed minimum-gate semantic; strict per-member opt-in deferred to FAMILY-V2-03 in v1.2 (consent infrastructure disproportionate to ship for a single AC)"

patterns-established:
  - "Phase-internal scope expansion → REQUIREMENTS.md amendment plan (Wave 1) before downstream UI plans, preventing silent doc/code drift"

requirements-completed: []

# Metrics
duration: 2min
completed: 2026-05-02
---

# Phase 10 Plan 01: REQUIREMENTS.md Spec Amendment Summary

**HOMEUI-05/06/07 codified + FAMILY-03 minimum-gate annotated; v1.1 active count 25 → 28; FAMILY-V2-03 deferred to v1.2.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-05-02T13:34:09Z
- **Completed:** 2026-05-02T13:36:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Added HOMEUI-05 (hero card absorbs MonthOverviewCard), HOMEUI-06 (魂/生存 inline split bar with absolute Yen labels), HOMEUI-07 (group-mode per-member rows) per Phase 10 D-06 scope expansion
- Inserted three new traceability rows (HOMEUI-05/06/07 → Phase 10 → Pending) in alphabetical/sequential order after HOMEUI-04
- Updated Coverage block: v1.1 active requirements 25 → 28 (with annotation explaining the +3 from D-06)
- Annotated FAMILY-03 with Phase 10 minimum-gate semantic per D-08 (renders iff `isGroupModeProvider == true && shadowBooks.isNotEmpty`); strict per-member opt-in deferred to FAMILY-V2-03 in v1.2
- Added FAMILY-V2-03 to v2 deferred Family extension section with full deferral rationale (schema migration v16→v17 + consent provider + settings UI + new ADR — disproportionate to ship for a single AC)
- Updated "Last updated" footer to 2026-05-02 with D-06/D-08 attribution

## Task Commits

1. **Task 1.1: Add HOMEUI-05/06/07 entries + update FAMILY-03 deferral note** — `4fed3b1` (docs)

## Files Created/Modified
- `.planning/REQUIREMENTS.md` — 11 insertions, 4 deletions: added 3 new HOMEUI bullets, 3 traceability rows, 1 FAMILY-V2-03 entry, FAMILY-03 deferral annotation, coverage block update, footer update

## Decisions Made
- **Append, not renumber:** Preserved existing HOMEUI-01..04 IDs and all other requirement IDs (HAPPY-01..08, FAMILY-01..02, STATSUI-01..04, RENAME-01..06) to avoid breaking downstream phase-checker / re-audit references. New IDs continue the existing sequence (05/06/07).
- **FAMILY-03 staged deferral:** Kept FAMILY-03 in v1.1 active set with the structurally-checkable minimum gate (group-mode + shadow-books-present), while moving the strict per-member opt-in semantic to FAMILY-V2-03. This preserves the v1.1 user-visible behavior (family card respects mode/data presence) without forcing a schema migration + consent UI build into Phase 10.
- **Footer attribution:** Footer now points to 2026-05-02 with D-06 / D-08 references so reviewers can trace the amendment back to the CONTEXT.md decisions that justify it.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## Verification

Acceptance criteria from plan:

- `grep -c "HOMEUI-05" .planning/REQUIREMENTS.md` = 3 (≥ 2 required) ✓
- `grep -c "HOMEUI-06" .planning/REQUIREMENTS.md` = 2 (≥ 2 required) ✓
- `grep -c "HOMEUI-07" .planning/REQUIREMENTS.md` = 2 (≥ 2 required) ✓
- `grep -c "HOMEUI-0[5-7]" .planning/REQUIREMENTS.md` = 7 (plan requires ≥ 6) ✓
- `grep -q "v1.1 requirements: 28 total" .planning/REQUIREMENTS.md` → exit 0 ✓
- `grep -q "FAMILY-V2-03" .planning/REQUIREMENTS.md` → exit 0 ✓
- `grep -q "Phase 10 minimum-gate" .planning/REQUIREMENTS.md` → exit 0 ✓
- Pre-existing IDs preserved: `grep -c "HAPPY-0[1-8]\|FAMILY-0[1-2]\|HOMEUI-0[1-4]\|STATSUI-0[1-4]\|RENAME-0[1-6]" .planning/REQUIREMENTS.md` = 49 (≥ 26 required) ✓

## Next Phase Readiness
- REQUIREMENTS.md is now the single source of truth for the Phase 10 expanded scope; downstream Phase 10 plans (Wave 2+) and the phase-checker / re-audit can reference HOMEUI-05/06/07 without scope-drift flags.
- FAMILY-V2-03 stays parked in v2 deferred section; v1.2 roadmap planning will pick it up.
- No blockers for subsequent waves.

## Self-Check: PASSED

Verification summary:
- File `.planning/REQUIREMENTS.md` exists and contains all required additions/annotations.
- Commit `4fed3b1` exists in `git log`.

```
$ git log --oneline -1
4fed3b1 docs(10-01): amend REQUIREMENTS with HOMEUI-05/06/07 + FAMILY-03 deferral note
```

---
*Phase: 10-homepage-soulfullnesscard-redesign*
*Completed: 2026-05-02*
