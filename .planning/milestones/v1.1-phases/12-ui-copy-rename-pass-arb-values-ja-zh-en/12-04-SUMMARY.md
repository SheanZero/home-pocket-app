---
phase: 12-ui-copy-rename-pass-arb-values-ja-zh-en
plan: 04
subsystem: docs
tags: [adr, lexical-hierarchy, i18n, ja, zh, en]

requires:
  - phase: 12-ui-copy-rename-pass-arb-values-ja-zh-en
    provides: Phase 12 ARB/picker register decisions and prior ADR context
provides:
  - Draft ADR-015 codifying trilingual lexical hierarchy for v1.1 UI copy
  - CN family-mode anti-collision rule for 家族的小确幸 vs 家族悦己
  - JP wellbeing-kanji-ladder rationale for 無難 / 快適 / 順調 / 満足 / 至福
  - ADR index entry, statistics update, and review schedule row
affects: [phase-12, i18n, adr, copy-review, register-review]

tech-stack:
  added: []
  patterns:
    - Append-only ADR protocol for accepted architecture decisions
    - Documentation-vs-product-vs-math-density lexical hierarchy

key-files:
  created:
    - docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md
    - .planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-04-SUMMARY.md
  modified:
    - docs/arch/03-adr/ADR-000_INDEX.md

key-decisions:
  - "Cited actual commit-of-record fbd3148 for homeRingSectionTitleGroup because git history shows the string landed in Phase 10, while Phase 11 D-13 reused the pattern."
  - "Kept ADR-015 in Draft status; Plan 05 owns the status flip to accepted."
  - "Did not update STATE.md, ROADMAP.md, or REQUIREMENTS.md because the orchestrator owns shared tracking updates after wave completion."

patterns-established:
  - "Future product copy should reserve 幸福/happiness/ハピネス for documentation, except the homeHappinessROI math-density title."
  - "Family-mode copy should use 家族的小确幸 / 家族の小確幸 / Family Joy, not 家族悦己."

requirements-completed:
  - RENAME-05

duration: 5min
completed: 2026-05-04
---

# Phase 12 Plan 04: ADR-015 Lexical Hierarchy Summary

**Draft ADR-015 now codifies the v1.1 trilingual lexical hierarchy, family-mode anti-collision rule, and JP wellbeing picker register.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-04T03:28:48Z
- **Completed:** 2026-05-04T03:33:19Z
- **Tasks:** 4
- **Files modified:** 2 docs files + this summary

## Accomplishments

- Identified `fbd3148 feat(10-04): add 24 Phase 10 ARB keys to ja/zh/en atomically` as the commit-of-record that introduced `homeRingSectionTitleGroup` zh=「家族的小确幸」.
- Added `ADR-015_Lexical_Hierarchy_v1_1.md` as a 189-line Draft ADR with all 12 planned sections.
- Updated `ADR-000_INDEX.md` with the ADR-015 entry, Draft count 3->4, total ADR count 14->15, review row, and version/date bump.

## ADR-015 Outline

1. 背景与问题陈述
2. 决策驱动因素
3. 备选方案
4. 决策
5. JP wellbeing-register subsection
6. 实施计划
7. 后果
8. 不在本ADR范围
9. 相关决策 / References-from
10. Append-only protocol
11. 变更历史
12. 下次Review

## Task Commits

1. **Tasks 1-4: Commit identification, ADR-015 authoring, index update, and atomic docs commit** - `7391076` (docs)
2. **Plan metadata: Summary creation** - committed separately after this file was written.

## Files Created/Modified

- `docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` - Draft ADR codifying the lexical hierarchy, family-mode anti-collision rule, JP wellbeing kanji ladder, negative scope, references, and append-only protocol.
- `docs/arch/03-adr/ADR-000_INDEX.md` - Added ADR-015 entry, updated statistics, added review schedule row, and bumped document metadata to 2026-05-04 / 1.4.
- `.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-04-SUMMARY.md` - Execution summary and self-check evidence.

## Verification

- `git log -S"家族的小确幸" -- lib/l10n/app_zh.arb`: PASS, returned `fbd3148`.
- `wc -l docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md`: PASS, 189 lines.
- ADR-015 content greps: PASS for `📝 草稿`, `2026-05-04`, `ハピネス密度`, `家族的小确幸`, `家族悦己`, `無難`, `至福`, `ADR-012`, `ADR-013`, `ADR-014`, `Append-only`, and HAPPY-08 mapping negative scope.
- Forbidden re-decision phrase check: PASS, `Path B unipolar-positive scale 决议` returned 0.
- Index greps: PASS for ADR-015 link, `📝 草稿 | 4`, `15个ADR`, review row, `最后更新: 2026-05-04`, and `文档版本: 1.4`; old Draft 3 / total 14 lines returned 0.
- Commit verification: PASS, `7391076` has subject `docs(arch): add ADR-015 Lexical Hierarchy v1.1 (Draft)` and `git diff HEAD~1 --stat` shows exactly the two planned docs files.
- Deletion check: PASS, no tracked files deleted in `7391076`.

## Decisions Made

- Used the actual git evidence for the family-mode citation: the earliest commit is `fbd3148` from Phase 10, while Phase 11 D-13 is referenced as a downstream reuse of the same pattern.
- Left ADR-015 as `📝 草稿`; Plan 05 owns the acceptance flip.
- Left shared tracking files untouched per executor prompt.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Plan Evidence Mismatch] Corrected Phase 11 commit-of-record assumption**
- **Found during:** Task 1 (Identify commit-of-record)
- **Issue:** The plan described the `homeRingSectionTitleGroup` origin as Phase 11, but `git log -S"家族的小确幸" -- lib/l10n/app_zh.arb` identifies `fbd3148`, a Phase 10 ARB commit, as the string-introducing commit.
- **Fix:** ADR-015 cites `fbd3148` as the commit-of-record and separately references Phase 11 D-13 as downstream evidence.
- **Files modified:** `docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md`
- **Verification:** `grep -c "fbd3148"` returned 2; `grep -c "Phase 11 D-13"` returned 2.
- **Committed in:** `7391076`

---

**Total deviations:** 1 auto-fixed evidence correction.
**Impact on plan:** No scope expansion; the ADR is more accurate and still preserves the intended Phase 11 family-mode rationale.

## Issues Encountered

- None beyond the plan evidence mismatch documented above.

## Known Stubs

None - stub-pattern scan of the created/modified plan files returned no TODO/FIXME/placeholder/coming-soon/not-available matches.

## Threat Flags

None - this plan added architecture documentation only and introduced no new network endpoints, auth paths, file access patterns, schema changes, or runtime trust-boundary surfaces.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 05 can flip ADR-015 from Draft to Accepted and update the index consistently. ADR-015 now provides the copy-review reference for blocking future 「家族悦己」 or product-surface 「幸福」 drift outside the `homeHappinessROI` math-density exception.

## Self-Check: PASSED

- Found ADR file: `docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md`.
- Found index file: `docs/arch/03-adr/ADR-000_INDEX.md`.
- Found summary file path prepared: `.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-04-SUMMARY.md`.
- Found implementation commit: `7391076 docs(arch): add ADR-015 Lexical Hierarchy v1.1 (Draft)`.
- Commit deletion check: no tracked file deletions in `7391076`.
- Shared tracking files: `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md` were not modified by this executor.

---
*Phase: 12-ui-copy-rename-pass-arb-values-ja-zh-en*
*Completed: 2026-05-04*
