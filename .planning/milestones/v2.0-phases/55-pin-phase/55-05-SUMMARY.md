---
phase: 55-pin-phase
plan: 05
subsystem: infra
tags: [requirements, roadmap, descope, app-lock, pin, security-ledger]

# Dependency graph
requires:
  - phase: 55-pin-phase
    provides: "D-06 known-accepted-risk decision (CONTEXT) + 55-RESEARCH §Security Domain sign-off"
provides:
  - "LOCK-08 covered-by-descope: relocated to v2 family as LOCK-V2-04"
  - "REQUIREMENTS.md traceability row + App Lock v2 family updated"
  - "ROADMAP Phase 55 SC-4 cooldown clause annotated DESCOPED with sign-off pointer"
affects: [55-secure-phase, 55-verify, v2-app-lock, audit]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "covered-by-descope ledger pattern: a descoped security requirement is never silently dropped — it is downgraded in REQUIREMENTS.md, relocated to the v2 family, and annotated in ROADMAP with a research sign-off pointer"

key-files:
  created: []
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md

key-decisions:
  - "LOCK-08 (PIN 递增冷却/退避) descoped from Phase 55 per D-06 — MVP zero rate-limiting is a user-informed known-accepted-risk, not a silent drop"
  - "递增冷却 capability relocated to new v2 requirement LOCK-V2-04 (alongside LOCK-V2-01/02/03)"
  - "ROADMAP SC-4 keeps salted slow-hash / off-isolate / constant-time / no-wipe in scope (LOCK-07); only the cooldown clause is annotated descoped"

patterns-established:
  - "Descope auditability: every descoped requirement carries a D-NN citation + RESEARCH sign-off reference so audit/verification can trace the accepted risk"

requirements-completed: [LOCK-08]

coverage:
  - id: D1
    description: "REQUIREMENTS.md LOCK-08 rewritten/downgraded out of Phase 55 active scope and relocated to v2 App Lock family as LOCK-V2-04 (递增冷却); traceability row updated to 'Descoped → LOCK-V2-04 (D-06)'"
    requirement: "LOCK-08"
    verification:
      - kind: other
        ref: "grep -c 'LOCK-V2-04' .planning/REQUIREMENTS.md (>=1, with 递增冷却 text) + LOCK-08 row shows Descoped"
        status: pass
    human_judgment: false
  - id: D2
    description: "ROADMAP Phase 55 Success Criterion 4's '连续输错有递增冷却' clause annotated DESCOPED per D-06, citing 55-RESEARCH §Security Domain sign-off and LOCK-V2-04; rest of SC-4 intact and other phases untouched"
    requirement: "LOCK-08"
    verification:
      - kind: other
        ref: "grep -nE 'DESCOPED|LOCK-V2-04' .planning/ROADMAP.md (SC-4 line) + git diff --stat shows 1 line changed"
        status: pass
    human_judgment: false

# Metrics
duration: 2min
completed: 2026-06-30
status: complete
---

# Phase 55 Plan 05: LOCK-08 Descope Ledger Summary

**LOCK-08 (PIN 连错递增冷却) made covered-by-descope — downgraded to v2 LOCK-V2-04 in REQUIREMENTS.md and annotated DESCOPED in ROADMAP SC-4, citing the D-06 known-accepted-risk sign-off.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-30T06:48:54Z
- **Completed:** 2026-06-30T06:50:10Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Rewrote Phase 55 LOCK-08 entry as descoped (D-06, MVP zero rate-limiting, user-informed accepted risk), preserving the still-holding invariants: no data-wipe, no recovery path, no failure counter (success needs no reset because there is no counter).
- Added `LOCK-V2-04: PIN 连错递增冷却/退避` to the App Lock v2 family alongside LOCK-V2-01/02/03.
- Updated the REQUIREMENTS.md traceability row: LOCK-08 → `Descoped → LOCK-V2-04 (D-06)`.
- Annotated ROADMAP Phase 55 SC-4's `连续输错有递增冷却` clause as DESCOPED with a pointer to `55-RESEARCH.md §Security Domain` Known Accepted Risk sign-off + LOCK-V2-04, keeping LOCK-07's salted slow-hash / off-isolate / constant-time / no-wipe guarantees in scope.

## Task Commits

Each task was committed atomically:

1. **Task 1: Downgrade REQUIREMENTS.md LOCK-08 into v2 LOCK-V2-04** - `97b2908f` (docs)
2. **Task 2: Annotate ROADMAP Phase 55 SC-4 cooldown clause descoped** - `be40fe81` (docs)

## Files Created/Modified
- `.planning/REQUIREMENTS.md` - LOCK-08 line downgraded/descoped; LOCK-V2-04 added to v2 family; traceability row updated
- `.planning/ROADMAP.md` - Phase 55 SC-4 cooldown clause annotated DESCOPED with sign-off + LOCK-V2-04 pointer

## Decisions Made
None beyond the plan — executed the three mandated downstream descope actions exactly as specified (D-06 / RESEARCH §Security Domain downstream actions 1-2; the third action, device-calibrated KDF params, is owned by Plan 01/11, not this ledger plan).

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- LOCK-08 is now auditable as covered-by-descope; the security review (gsd-secure-phase) and verifier can trace the accepted risk to D-06 + the RESEARCH sign-off.
- The remaining App Lock plans (55-06..11) are unaffected; they implement LOCK-01..07/09/10 with no cooldown logic (consistent with this descope and D-12 shake+clear behavior).
- v2 carries LOCK-V2-04 for the deferred rate-limiting capability.

## Self-Check: PASSED

- FOUND: .planning/phases/55-pin-phase/55-05-SUMMARY.md
- FOUND: commit 97b2908f (Task 1)
- FOUND: commit be40fe81 (Task 2)

---
*Phase: 55-pin-phase*
*Completed: 2026-06-30*
