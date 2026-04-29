---
phase: 08-re-audit-exit-verification
plan: 07
subsystem: testing
tags: [smoke-test, checklist, manual-qa, i18n, dual-ledger, exit-verification]

# Dependency graph
requires:
  - phase: 08-re-audit-exit-verification
    provides: 08-CONTEXT.md D-06 (8 user-flow sections); 08-PATTERNS.md lines 377-441 (recommended structure); 08-05 re-audit baseline (issues.json) for SMOKE-NN integration; 08-06 coverage gate context for tester awareness
provides:
  - 08-SMOKE-TEST.md scaffold (8 D-06 sections + Sign-off, 34 empty checkboxes)
  - Audit trail entry-point for ROADMAP success criterion 4 (human attestation of byte-identical user-observable behavior)
  - Hook for SMOKE-NN finding-injection into .planning/audit/re-audit/issues.json (Task 2 human work, Task 3 post-hoc verification)
affects: [08-08 ADR-011 amendment cites Sign-off verdict; Phase 8 close gate; reaudit_diff.dart consistency check]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "User-filled smoke-test checklist as audit artifact"
    - "GitHub-flavored task lists (- [ ]) as binary acceptance unit"
    - "Sign-off block (tester / date / commit hash / platform / verdict) as repudiation-resistant attestation"
    - "Two-valid-verdict line ([None] / Recorded as new findings) wired to reaudit_diff.dart exit code"

key-files:
  created:
    - .planning/phases/08-re-audit-exit-verification/08-SMOKE-TEST.md
  modified: []

key-decisions:
  - "Followed PATTERNS.md lines 377-441 verbatim for the 8 D-06 sections + Sign-off structure"
  - "Wrote 2026-04-28 as the Created date (today, ISO; placeholder substitution at write time per plan instructions)"
  - "Did NOT execute Task 2 (human checkpoint) or Task 3 (post-hoc verification) — plan is autonomous: false; orchestrator objective explicitly forbids simulating user behavior or marking boxes complete"
  - "Used 34 empty checkboxes covering 8 sections + Sign-off (≥30 minimum); each is a binary acceptance unit per truths"

patterns-established:
  - "Smoke-test artifact: 8 sections × 2-6 task-list items = ~30 user-observable surface-checks, ticked individually by the tester"
  - "Discrepancy → SMOKE-NN finding → reaudit_diff.dart strict-exit: any unchecked box that surfaces a real defect becomes a new entry in .planning/audit/re-audit/issues.json (category: smoke_discrepancy), failing the Phase 8 gate until closed"
  - "Sign-off as load-bearing audit evidence: tester name + ISO date + git rev-parse HEAD + build platform reproducible; ADR-011 amendment cites verbatim"

requirements-completed: []

# Metrics
duration: ~5min (Task 1 only; Tasks 2 and 3 deferred to human + post-hoc executor)
completed: 2026-04-28
---

# Phase 08 Plan 07: Phase 8 Smoke Test Checklist Summary

**Scaffolded `.planning/phases/08-re-audit-exit-verification/08-SMOKE-TEST.md` — 8 D-06 user-flow sections (transaction CRUD, ledger switch, monthly report, backup, family sync, voice, locale switch, ARB spot-check) + Sign-off block; 34 empty checkboxes; awaiting human tester to run on a fresh local build.**

## Performance

- **Duration:** ~5 min (Task 1 only; Tasks 2 and 3 deferred per plan `autonomous: false` contract)
- **Started:** 2026-04-28T08:21:00Z (approx)
- **Completed:** 2026-04-28T08:26:28Z
- **Tasks:** 1 of 3 (Task 2 = human checkpoint; Task 3 = post-hoc verification, gated on Task 2)
- **Files modified:** 1 created, 0 modified

## Accomplishments

- Scaffolded `08-SMOKE-TEST.md` with the 8 D-06 sections verbatim:
  1. Transaction CRUD on both ledgers (6 boxes — create / edit / delete on Survival + Soul)
  2. Ledger switch (Survival ↔ Soul) (3 boxes — bidirectional + soul fullness card localization)
  3. Monthly report screen with currency formatting (5 boxes — JPY/USD/CNY + compact + date headers per locale)
  4. Settings: backup export + import (2 boxes)
  5. Family sync push + pull (2 boxes — bidirectional)
  6. Voice input (2 boxes — parser + form population)
  7. Language switch (ja → zh → en) with locale-specific formatting (4 boxes — 3 locales + round-trip)
  8. ARB-driven UI text spot-check on Phase-5-touched screens (4 boxes — home, analytics, settings, transaction form)
- Added Sign-off block with 6 fields (verdict / tester name / date / commit hash / build platform / discrepancies-found line)
- Header carries `Created`, `Phase 8`, `Source of Truth`, `Closes` metadata per PATTERNS.md analog
- Wired the verdict line to `reaudit_diff.dart` exit code consistency rule (Task 3 spec):
  - `[None]` → reaudit_diff exits 0
  - `Recorded as new findings ...` → reaudit_diff exits 1

## Task Commits

1. **Task 1: Scaffold 08-SMOKE-TEST.md with 8 sections per D-06** — `e6094f8` (docs)
2. **Task 2 [HUMAN]: Run the app and tick boxes** — DEFERRED (plan is `autonomous: false`; this executor explicitly does NOT simulate the human; awaiting project owner)
3. **Task 3: Post-hoc automated verification** — DEFERRED (gated on Task 2 output; resumes when human commits the completed file)

**Plan metadata commit:** pending — final commit will include this SUMMARY.md + STATE.md + ROADMAP.md updates.

## Files Created/Modified

- `.planning/phases/08-re-audit-exit-verification/08-SMOKE-TEST.md` — User-filled smoke-test checklist (71 lines, 8 numbered sections + Sign-off, 34 empty checkboxes); load-bearing artifact for ROADMAP success criterion 4

## Decisions Made

- **Followed PATTERNS.md lines 377-441 verbatim** for section structure + heading conventions. The plan template (lines 100-104 of 08-07-PLAN.md) provided the exact body text and was copied without modification (only the `{YYYY-MM-DD execution date}` placeholder was substituted with `2026-04-28`).
- **Did NOT execute Task 2 or Task 3.** Plan frontmatter says `autonomous: false` and the orchestrator objective is explicit: "Your job is ONLY to produce the artifact ... Do NOT attempt to execute the smoke test yourself, simulate user behavior, or mark items as complete on the human's behalf." Task 2 is a `checkpoint:human-confirm` that gates a fresh local build + 30 minutes of manual UI walkthrough; Task 3 depends on Task 2's committed output to run grep/awk/reaudit_diff consistency checks.
- **34 empty checkboxes** (≥30 required by `must_haves.truths`); breakdown: Section 1=6, Section 2=3, Section 3=5, Section 4=2, Section 5=2, Section 6=2, Section 7=4, Section 8=4, Sign-off=6.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Acceptance regex bug] Plan-internal acceptance regex inconsistent with plan template**
- **Found during:** Task 1 (post-write verification)
- **Issue:** The plan's acceptance criterion (line 183 of 08-07-PLAN.md) specifies `grep -cE "^\*\*(Created|Phase 8|Source of Truth|Closes):"` should return 4. But the plan's verbatim file template (line 102 of 08-07-PLAN.md) writes the second header line as `**Phase 8** —` (no colon, em-dash separator), which the regex misses. The PATTERNS.md analog (line 386) also uses `**Phase 8** —`. So the file matches the load-bearing template + analog, but the regex is buggy.
- **Resolution:** Kept the file as `**Phase 8** —` (matches both template + analog). Verified all 4 metadata lines are present individually:
  - `^\*\*Created:` → 1
  - `^\*\*Phase 8\*\*` → 1
  - `^\*\*Source of Truth:` → 1
  - `^\*\*Closes:` → 1
  - Adjusted regex `^\*\*(Created:|Phase 8\*\*|Source of Truth:|Closes:)` → 4
- **Files modified:** None (file is correct as written; this is a self-check regex inconsistency in the plan, not a defect in the artifact)
- **Verification:** Individual greps above prove all 4 metadata lines exist with the correct values
- **Committed in:** Task 1 commit (`e6094f8`)
- **Impact:** Cosmetic. The artifact is correctly structured; the plan's acceptance regex has a `:` vs ` —` typo that does not affect correctness of the deliverable.

---

**Total deviations:** 1 auto-fixed (Rule 1 — plan-internal acceptance regex inconsistency, no artifact change required)
**Impact on plan:** None. The artifact matches both the verbatim plan template and the PATTERNS.md analog.

## Issues Encountered

None. Task 1 completed cleanly. The "issue" was identifying the regex/template inconsistency, which is a self-check artifact bug in the plan and not a defect in the deliverable.

## Sign-off Verdict (from 08-SMOKE-TEST.md)

**This SUMMARY is filed AT THE TASK 1 BOUNDARY**, before Task 2 (human checkpoint) executes. The Sign-off block is therefore EMPTY.

For Plan 08-08 (ADR-011 amendment) to cite the Sign-off verdict, it must read `08-SMOKE-TEST.md` after Task 2 (human run) completes — at which point the file will carry one of:
- `Discrepancies found: [None]` → ADR-011 amendment cites `PASS`
- `Discrepancies found: [Recorded as new findings in .planning/audit/re-audit/issues.json]` → ADR-011 amendment cites `DISCREPANCIES_FOUND` with the SMOKE-NN finding count

**Plan 08-08 is therefore BLOCKED on Plan 08-07 Task 2 (human work).** This blocker is consistent with the existing Phase 8 blocker noted in STATE.md (4 of 8 EXIT-04 gates failing post-cleanup); Plan 08-08 was already gated on those discoveries plus Plan 08-07's outcome.

### SMOKE-NN Findings (post-Task-2 reference)

To be populated by Task 2 + Task 3 if any sections fail. Schema:
```
SMOKE-NN | severity (HIGH default per plan) | filePath (lib/features/...) | disposition (open / closed by follow-up plan / deferred)
```
Currently: **none recorded** (Task 2 has not run).

## User Setup Required

**HUMAN ACTION REQUIRED — Task 2 of 08-07-PLAN.md is a `checkpoint:human-confirm`.**

The project owner / tester must:

1. **Build a fresh local app:**
   ```bash
   flutter clean
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   flutter run     # picks up the connected device / simulator
   git rev-parse HEAD   # record this for the Sign-off section
   ```

2. **Walk the app through every section** of `.planning/phases/08-re-audit-exit-verification/08-SMOKE-TEST.md` in order. For each item: perform the user action, compare to the expected behavior, tick the box if it passes, leave it unchecked + add a one-line note if it fails.

3. **For each unchecked discrepancy, append a SMOKE-NN finding** to `.planning/audit/re-audit/issues.json` per the schema in 08-07-PLAN.md Task 2 Step 3.

4. **Re-run reaudit_diff.dart** to confirm consistency: `[None]` verdict ↔ exit 0; `Recorded as new findings` verdict ↔ exit 1.

5. **Fill the Sign-off block** with tester name, ISO date (`date +%Y-%m-%d`), commit hash (`git rev-parse HEAD`), build platform (e.g., `iOS Simulator iPhone 15 (iOS 17.4)` or `Android Pixel 7 (API 34)`), and the discrepancies-found verdict.

6. **Commit the completed file:**
   ```bash
   gsd-sdk query commit "docs(phase-08): complete smoke-test checklist" .planning/phases/08-re-audit-exit-verification/08-SMOKE-TEST.md
   ```

7. **Resume the orchestrator** so Task 3 (automated post-hoc verification) can run.

**Estimated time:** ~30 minutes (per plan threat-model T-08-07-04).

## Next Phase Readiness

**Plan 08-07 is at the Task 1 boundary.** Plan 08-08 (final plan in Phase 8 — ADR-011 amendment) is BLOCKED on:

1. **Plan 08-07 Task 2** (this plan, human checkpoint) — completion of the smoke-test checklist with all boxes ticked AND Sign-off populated AND any SMOKE-NN findings recorded.
2. **Plan 08-07 Task 3** (this plan, post-hoc automated verification) — confirmation that the verdict line is consistent with reaudit_diff.dart exit code.
3. **Plan 08-06 4-gate-failure resolution** (separate blocker noted in STATE.md) — Phase 8 cannot close until those gates pass; Plan 08-08 cites the resolution path.

**No code or behavior changes were made in Task 1.** The deliverable is a markdown artifact; `flutter analyze` / tests / coverage are unaffected.

## Self-Check: PASSED

- [x] `.planning/phases/08-re-audit-exit-verification/08-SMOKE-TEST.md` exists (verified `test -f`)
- [x] Commit `e6094f8` exists (verified `git log --oneline | grep e6094f8`)
- [x] 8 numbered sections present (verified `grep -cE "^## [1-8]\\." → 8`)
- [x] Sign-off section present (verified `grep -c "^## Sign-off" → 1`)
- [x] ≥30 empty checkboxes (verified `grep -c "^- \\[ \\]" → 34`)
- [x] All 4 metadata lines present individually (Rule 1 deviation: plan's combined regex has `:` vs ` —` bug)
- [x] Placeholder `{YYYY-MM-DD execution date}` absent (verified `grep -c "{YYYY-MM-DD execution date}" → 0`)
- [x] File ≥50 lines (verified `wc -l → 71`)
- [x] All D-06 surface keywords present (Survival, Soul, ja, zh, en, JPY, USD, CNY, voice, backup, sync — all ≥1 occurrence)
- [x] No file deletions in commit (verified `git diff --diff-filter=D HEAD~1 HEAD → empty`)

---
*Phase: 08-re-audit-exit-verification*
*Completed: 2026-04-28 (Task 1 boundary; Tasks 2 + 3 deferred to human + post-hoc executor)*

---

## Update 2026-04-28 — Tasks 2 + 3 formally deferred to v1 release gate

User directive after Plan 08-07 produced the checklist artifact: skip human-execution at Phase 8 close, move it to v1 release gate as owner's responsibility. Recorded as `FUTURE-QA-01` in `.planning/REQUIREMENTS.md` v2 backlog.

**What this means:**
- Plan 08-07 is **complete** at the artifact-production boundary (Task 1). The checklist file lives at `.planning/phases/08-re-audit-exit-verification/08-SMOKE-TEST.md` with 34 empty checkboxes and an empty Sign-off block.
- The execution side (Tasks 2 + 3 of the plan as originally written) is **not** Phase-8-blocking. ROADMAP success criterion 4 has been amended to make the artifact the deliverable; behavior verification is the v1 release gate.
- ADR-011 (Plan 08-08) records this deferral honestly so that any future reader sees the cleanup initiative closed without lying about smoke-test signoff.

**At v1 release:**
1. Owner runs `flutter clean && flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs && flutter run` on a fresh local build.
2. Walks the 8-section checklist, ticks boxes.
3. Records any SMOKE-NN findings in `.planning/audit/re-audit/issues.json`; re-runs `dart run scripts/reaudit_diff.dart` to confirm gate stays GREEN.
4. Fills the Sign-off block (tester / date / commit hash / platform / verdict).
5. Commits the completed file.

If smoke uncovers a regression, that becomes a follow-up bug-fix phase — it does not retroactively reopen the cleanup initiative; the cleanup closed on the discovery+remediation contract, not on perfect-as-released proof.
