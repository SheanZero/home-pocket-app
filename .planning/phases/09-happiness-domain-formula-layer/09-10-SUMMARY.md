---
phase: 09-happiness-domain-formula-layer
plan: 10
subsystem: architecture-documentation
tags: [adr, gamification, goodhart, documentation]

requires:
  - phase: 09-happiness-domain-formula-layer
    provides: v1.1 happiness metric requirements and anti-feature context
provides:
  - ADR-012 draft ratifying HAPPY-07 no-gamification governance
  - Permanent forbidden-feature inventory for v1.1 happiness metric surfaces
  - ADR index entry for reviewer discovery
affects: [phase-10-homepage, phase-11-statistics, phase-12-closeout, future-feature-review]

tech-stack:
  added: []
  patterns: [Chinese-header ADR template, draft-before-ratification governance]

key-files:
  created:
    - docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md
  modified:
    - docs/arch/03-adr/ADR-000_INDEX.md

key-decisions:
  - "ADR-012 remains `📝 草稿` until Phase 12 milestone close ratifies it as accepted."
  - "HAPPY-07 is documented as a Goodhart's-Law defense that blocks streaks, badges, daily targets, cross-period deltas, public sharing, and per-member comparison surfaces."
  - "ADR-000_INDEX metadata/statistics were updated to reflect ADR-012 as the first draft ADR."

patterns-established:
  - "Anti-feature ADRs can serve as one-line PR rejection authority when future requests conflict with milestone governance."

requirements-completed: [HAPPY-07]

duration: 3min
completed: 2026-05-02
---

# Phase 09 Plan 10: No Gamification ADR Summary

**Goodhart's-Law defense ADR for v1.1 happiness metrics, with explicit permanent bans on gamification and family comparison surfaces.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-02T01:35:36Z
- **Completed:** 2026-05-02T01:38:14Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Drafted `ADR-012_No_Gamification_v1_1.md` using the current ADR-011 Chinese-header template and required section order.
- Captured HAPPY-07 with Goodhart 1975 rationale and a 7-item `Forbidden Features (Permanent)` list.
- Updated `ADR-000_INDEX.md` with ADR-012 in numerical order, draft status, rationale, rejected alternatives, review timing, and updated ADR counts.

## Task Commits

1. **Task 1: Draft ADR-012_No_Gamification_v1_1.md** - `5812be5` (docs)
2. **Task 2: Update ADR-000_INDEX.md with ADR-012 entry** - `2aa3de4` (docs)

## Files Created/Modified

- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` - Draft ADR ratifying HAPPY-07 as a Goodhart's-Law and family anti-comparison defense.
- `docs/arch/03-adr/ADR-000_INDEX.md` - ADR-012 index entry plus metadata/statistics/review table updates.

## Decisions Made

- Kept ADR-012 in `📝 草稿` status, matching the plan's Phase 12 closeout ratification path.
- Included Goodhart 1975, Strathern 1997, and Cabinet Office 2010 references from the plan so the rationale covers metrics, audit pressure, and cross-period wellbeing policy risks.
- Added `备选方案` to the index entry in addition to the plan's `Forbidden Features` subsection so ADR-012 mirrors the existing ADR-011 index format more closely.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Verification

- `test -f docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` - passed.
- `grep -q "Goodhart" docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` - passed.
- `grep -q "Forbidden Features" docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` - passed.
- `grep -c "^## " docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` - returned `8`.
- `grep -cE "Streak|Badge|Daily.*target|Cross-period|Public.*sharing|Per-member|leaderboard" docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` - returned `10`.
- `grep -q "ADR-012_No_Gamification_v1_1.md" docs/arch/03-adr/ADR-000_INDEX.md` - passed.
- Stub scan across modified files found no TODO/FIXME/placeholder/generated-empty-value patterns.

## Known Stubs

None.

## Threat Flags

None. Documentation-only ADR and index update; no new network, auth, file-access, persistence, or trust-boundary code surface.

## User Setup Required

None.

## Next Phase Readiness

Phase 10 and Phase 11 reviewers can cite ADR-012 directly to reject streaks, badges, daily targets, cross-period copy, public sharing, or per-member comparison surfaces in happiness metric UI.

## Self-Check: PASSED

- Created file exists: `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md`
- Summary file exists: `.planning/phases/09-happiness-domain-formula-layer/09-10-SUMMARY.md`
- Task commits found: `5812be5`, `2aa3de4`
