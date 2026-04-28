---
phase: 07-documentation-sweep
plan: 06
subsystem: docs
tags: [adr, documentation, ci-gates, verification, arch]

requires:
  - phase: 07-05-cleanup-outcome-adr
    provides: "ADR-011_Codebase_Cleanup_Initiative_Outcome.md created and indexed"

provides:
  - "Gate 4 in verify-doc-sweep.sh mechanically detects doc/arch/ singular-path drift"
  - "Hermetic smoke fixture verify-doc-sweep-smoke.sh proves gate 4 rejects injected drift"
  - "ADR append-only rule added to .claude/rules/arch.md:157-162"
  - "Orphan trailing metadata relocated in ADR-002, ADR-008, ADR-010"
  - "Obsolete citation :171-173 replaced with :157-162 in all 4 append-only ADRs"
  - "ADR-000_INDEX.md, docs/arch/README.md, ARCH-000_INDEX.md statistics synced to 11 ADRs"

affects: [future-doc-additions, ci-doc-gate, adr-management]

tech-stack:
  added: []
  patterns:
    - "Gate regression testing via hermetic smoke fixture (mktemp + trap EXIT + sed path rewrite)"
    - "ADR append-only convention enforced by rules citation pointing to real content"

key-files:
  created:
    - .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh
  modified:
    - .planning/phases/07-documentation-sweep/verify-doc-sweep.sh
    - .claude/rules/arch.md
    - docs/arch/03-adr/ADR-002_Database_Solution.md
    - docs/arch/03-adr/ADR-007_Layer_Responsibilities.md
    - docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md
    - docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md
    - docs/arch/03-adr/ADR-000_INDEX.md
    - docs/arch/README.md
    - docs/arch/01-core-architecture/ARCH-000_INDEX.md

key-decisions:
  - "Gate 4 grep pattern changed from 'doc/arch[^/]' to '(^|[^s])doc/arch' to correctly detect 'doc/arch/foo' style drift — the [^/] variant missed paths with trailing slash"
  - "Smoke fixture uses sed path-rewrite rather than string injection into real files — guarantees hermeticity (real CLAUDE.md never mutated)"
  - "ADR append-only rule added to arch.md:157-162 subsection 文档更新规则 item 4, citation range updated in all 4 ADRs from obsolete :171-173"

patterns-established:
  - "ci-gate-smoke-test: hermetic fixtures that inject violations into temp copies and assert non-zero exit prove gate correctness without side effects"
  - "adr-append-only: ADRs in 已接受 status use Update sections appended at file end; footer metadata belongs before the separator preceding the Update heading"

requirements-completed: [DOCS-01, DOCS-02, DOCS-03, DOCS-04]

duration: 35min
completed: 2026-04-28
---

# Phase 07 Plan 06: Verification Gap Closure Summary

**Phase 7 final gate closure: fixed structurally-broken verify-doc-sweep.sh gate 4, added hermetic smoke fixture, relocated orphan ADR footer metadata, added real append-only rule to arch.md, and synced statistics rollups to ADR-011 across three index files.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-04-28T01:40:00Z
- **Completed:** 2026-04-28T02:13:51Z
- **Tasks:** 9 (8 execution + 1 final gate verification)
- **Files modified:** 10

## Accomplishments

- Gate 4 in `verify-doc-sweep.sh` now mechanically detects `doc/arch/` singular-path drift (fixed `grep -cE` multi-file count bug + `pipefail` termination; corrected pattern to match `doc/arch/foo` style)
- Hermetic smoke fixture `verify-doc-sweep-smoke.sh` proves gate 4 rejects injected drift (SMOKE PASS) without touching real files
- ADR-002, ADR-008, ADR-010 each end with `## Update 2026-04-27` as their last top-level heading; previously-orphaned footer metadata relocated before the Update section
- Real ADR append-only rule added to `.claude/rules/arch.md:157-162`; all 4 append-only ADRs now cite the actual rule location instead of fictitious `:171-173`
- ADR-000_INDEX.md, docs/arch/README.md, ARCH-000_INDEX.md all report 11 ADRs with correct totals

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix gate 4 grep-count sum (WR-01)** - `73e5bbb` (fix)
2. **Task 1b: Improve gate 4 pattern to match doc/arch/ paths (Rule 1)** - `41de0cb` (fix)
3. **Task 2: Add hermetic smoke fixture (WR-01)** - `4e31fc0` (feat)
4. **Task 3: Relocate orphan trailing metadata ADR-002/008/010 (WR-02)** - `259cf60` (fix)
5. **Task 4: Add ADR append-only rule to arch.md (WR-03)** - `29c8934` (feat)
6. **Task 5: Update citation :171-173 → :157-162 in 4 ADRs (WR-03)** - `5ff300e` (fix)
7. **Task 6: Sync ADR-000_INDEX.md statistics + ADR-011 review row (WR-04)** - `09150f2` (docs)
8. **Task 7: Sync README.md statistics + directory tree (WR-05)** - `f970674` (docs)
9. **Task 8: Sync ARCH-000_INDEX.md completion stats (WR-05)** - `3e7fdd5` (docs)

## Files Created/Modified

- `.planning/phases/07-documentation-sweep/verify-doc-sweep.sh` - Gate 4 fixed: grep pattern + pipefail handling
- `.planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh` - NEW: hermetic smoke fixture
- `.claude/rules/arch.md` - Added item 4: ADR append-only rule under 文档更新規則
- `docs/arch/03-adr/ADR-002_Database_Solution.md` - Metadata relocated + citation updated
- `docs/arch/03-adr/ADR-007_Layer_Responsibilities.md` - Citation updated only (metadata was correct)
- `docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md` - Metadata relocated + citation updated
- `docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md` - Metadata relocated + citation updated
- `docs/arch/03-adr/ADR-000_INDEX.md` - Statistics 9→10 已接受, 10→11 total; ADR-011 review row added
- `docs/arch/README.md` - Statistics ADR 10→11, total 32→33; ADR-011 in directory tree
- `docs/arch/01-core-architecture/ARCH-000_INDEX.md` - ADR 10→11, total 30→31

## Decisions Made

- Gate 4 pattern changed from `doc/arch[^/]` to `(^|[^s])doc/arch` — the original `[^/]` excluded the trailing slash in `doc/arch/foo`, making the gate unable to detect the primary drift format the smoke fixture injects. The new pattern uses a negative lookbehind to distinguish `doc/arch` (singular, drift) from `docs/arch` (correct plural).
- Smoke fixture uses `sed` to rewrite file references in a temp script copy rather than injecting strings directly into real files — ensures the real CLAUDE.md is never mutated even on failure paths.
- ADR footer metadata (下次Review日期, 下次审查, 优先级) placed before the `---` separator that introduces the Update section, not before any other existing footer content — preserves the ADR's append-only-at-file-end contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Gate 4 grep pattern `doc/arch[^/]` cannot detect `doc/arch/foo` drift**
- **Found during:** Task 2 (adding smoke fixture that injects `doc/arch/foo`)
- **Issue:** The pattern `doc/arch[^/]` requires a non-slash character after `doc/arch`. The canonical drift string `doc/arch/foo` has a slash, so grep returns exit 0 with no matches. The smoke fixture produced SMOKE FAIL (gate 4 did not detect injected drift).
- **Fix:** Changed pattern to `(^|[^s])doc/arch` — distinguishes `doc/arch` (drift, no preceding `s`) from `docs/arch` (correct, preceded by `s`). Added `|| true` inside subshell to prevent `set -e` from aborting on grep's non-zero exit code when there are zero matches.
- **Files modified:** `.planning/phases/07-documentation-sweep/verify-doc-sweep.sh`
- **Verification:** `bash verify-doc-sweep.sh` exits 0 on clean tree; `bash verify-doc-sweep-smoke.sh` reports SMOKE PASS.
- **Committed in:** `41de0cb` (separate fix commit after Task 1's initial `73e5bbb`)

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug in gate 4 grep pattern)
**Impact on plan:** Fix was required for the smoke fixture to work correctly. No scope creep — both commits are within Task 1's scope of "make gate 4 mechanically functional."

## Final Gate Results

| Gate | Command | Result |
|------|---------|--------|
| 1 | `bash verify-doc-sweep.sh` | EXIT 0, all 6 OK |
| 2 | `bash verify-doc-sweep-smoke.sh` | EXIT 0, SMOKE PASS |
| 3 | `bash scripts/verify_index_health.sh` | EXIT 0, zero BROKEN/ORPHAN |
| 4 | `git diff --name-only ef4b770..HEAD \| grep -cE '^(lib/\|test/\|...)'` | 0 |
| 5 | `git diff --name-only main..HEAD \| grep -cE '^(lib/\|...)'` | 0 |

## WR Gap Closure

| Gap | Status |
|-----|--------|
| WR-01: gate 4 structurally broken | CLOSED — grep pattern + pipefail fixed; smoke proves detection |
| WR-02: orphan trailing metadata in ADR-002/008/010 | CLOSED — metadata relocated before Update heading |
| WR-03: fictitious citation :171-173 in 4 ADRs | CLOSED — real rule added; citation updated to :157-162 |
| WR-04: ADR-000_INDEX.md stats not synced to ADR-011 | CLOSED — 10/11 counts + review row added |
| WR-05: README + ARCH-000 stats not synced to ADR-011 | CLOSED — both indexes report 11 ADRs |

## Issues Encountered

- `grep -cE` with multiple files + `set -euo pipefail` causes silent script termination when grep finds no matches (exits 1). Required wrapping grep in a subshell group with `|| true` before piping to awk. The original gap_evidence suggested `... | awk ...` without the subshell, which failed.

## Next Phase Readiness

- Phase 7 is complete. All 6 plans executed. All 4 WR gaps closed.
- `verify-doc-sweep.sh` exits 0 on the post-07-06 tree and mechanically detects future drift.
- `verify_index_health.sh` exits 0 — INDEX health unbroken.
- lib/-clean invariant holds (0 forbidden files modified across all Phase 7 plans).
- The codebase is ready for Phase 8 (post-cleanup stabilization / backlog).

## Self-Check: PASSED

All created files confirmed on disk. All 9 task commit hashes verified in git log.
All 4 final gates pass (verify-doc-sweep.sh, smoke fixture, index health, lib/-clean).

---

*Phase: 07-documentation-sweep*
*Completed: 2026-04-28*
