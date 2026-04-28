---
phase: 08-re-audit-exit-verification
plan: "03"
subsystem: infra
tags: [github-actions, ci, audit-yml, repo-lock-policy, adr-011, permanent-gates]

requires:
  - phase: 08-re-audit-exit-verification (Plan 08-02)
    provides: "audit.yml coverage_gate now reads cleanup-touched-files.txt — same line ~107 this plan re-touches alongside the if: pull_request lift"
  - phase: 02-coverage-baseline
    provides: "REPO-LOCK-POLICY.md — the file Task 2 appends to (preserves all 5 prior sections)"
  - phase: 07
    provides: "ADR-011_Codebase_Cleanup_Initiative_Outcome.md — the cross-reference target wired into both audit.yml warning header and REPO-LOCK-POLICY Phase 8 Close section"
provides:
  - "Hardened audit.yml: 6-line top-of-file 'Permanent gate' warning + ADR-011 link + Phase 8 D-05 reference"
  - "Coverage job now runs on push:main (not only pull_request) — direct-to-main bypass closed"
  - "Zero soft-fail flags anywhere in audit.yml (continue-on-error / report-only / WARN-only swept)"
  - "REPO-LOCK-POLICY.md `## Phase 8 Close — Permanent Gates` section: all 4 guardrails enumerated, lock window CLOSES recorded, ADR-011 cross-reference set"
affects:
  - "Plan 08-04 (re-audit run): coverage gate now blocking on push:main, factored into expectations"
  - "Plan 08-08 (ADR-011 amendment): the `## Update YYYY-MM-DD` placeholder in REPO-LOCK-POLICY Cross-reference line gets the real date filled when ADR-011 closes"

tech-stack:
  added: []
  patterns:
    - "Permanent-gate documentation: top-of-file YAML comment block (matching existing line 40 / line 69 voice) cross-references ADR + Phase decision number to make load-bearing lines self-documenting"
    - "Append-only governance pattern: REPO-LOCK-POLICY.md preserves all 5 pre-existing sections; Phase 8 Close section stacks at end without rewriting prior policy state"

key-files:
  created: []
  modified:
    - ".github/workflows/audit.yml (+7 -1 lines; warning header + lifted if:pull_request)"
    - ".planning/audit/REPO-LOCK-POLICY.md (+17 -0 lines; Phase 8 Close section appended)"

key-decisions:
  - "Reworded the warning comment line 6 to drop the literal substrings 'continue-on-error: true' and 'soft-fail' — the verbatim plan text would have triggered its own grep-based acceptance criterion (sweep MUST find 0 occurrences). New phrasing 'coverage job intentionally has no PR-only guard, and every guardrail step is hard-failing by design' preserves the load-bearing intent without poisoning the sweep."
  - "Used ASCII '>=80%' in the audit.yml warning header (line 4) instead of the PATTERNS.md '≥80%' Unicode form — reduces YAML/encoding fragility for a permanent CI file. REPO-LOCK-POLICY.md (markdown) keeps '≥80%' per template."
  - "Locked: 2026-04-28 substituted at execution time; the Cross-reference line's '## Update YYYY-MM-DD' placeholder is preserved for Plan 08-08 to fill when it appends to ADR-011 (per CONTEXT D-08)."

patterns-established:
  - "Warning-header voice for permanent CI files: 6-line comment block at file top, ASCII-only, ADR cross-reference + Phase decision-number anchor, terse imperative sentences (no flag literals to avoid self-grep poisoning)"
  - "Phase-close governance addendum: append-only section at end of policy doc with `**Locked:** YYYY-MM-DD` metadata block matching the doc's existing line 3 voice; numbered guardrail enumeration mirrors audit.yml job ordering"

requirements-completed: [EXIT-05]

duration: 4m
completed: 2026-04-28
---

# Phase 08 Plan 03: Permanent Gates Hardening Summary

**audit.yml gets a 6-line ADR-011 warning header, the coverage gate's `if: pull_request` is lifted, and REPO-LOCK-POLICY.md gains a `## Phase 8 Close — Permanent Gates` section enumerating the four guardrails as indefinitely blocking.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-28T06:29:35Z
- **Completed:** 2026-04-28T06:33:35Z
- **Tasks:** 2 / 2
- **Files modified:** 2

## Accomplishments
- audit.yml is now self-documenting as a permanent gate: 6-line warning header pointing at ADR-011 and Phase 8 D-05, anchored above `name: audit` (line 8).
- Direct-to-main commits can no longer bypass the 80% coverage gate — `if: ${{ github.event_name == 'pull_request' }}` removed from the `coverage` job; trigger declaration at the top of the file (lines 10-14, `pull_request` + `push: branches: [main]`) now governs.
- Zero soft-fail flags survive the sweep: `continue-on-error: true`, `report-only`, WARN-only / soft-fail patterns all confirmed absent across all 133 lines.
- REPO-LOCK-POLICY.md gains its closing chapter: the `## Phase 8 Close — Permanent Gates` section preserves all 5 prior sections (`## Why This Policy Exists`, `## The Policy`, `## Lifecycle`, `## Frozen Baseline (D-08) Interaction`, `## References`) and stacks a new locked policy on top — gate-permanence is independent of the cleanup-window PR lock that lifts at Phase 6 close.

## Task Commits

Each task was committed atomically:

1. **Task 1: Prepend warning comment + lift coverage `if: pull_request` + sweep for soft-fail flags** — `67b1aff` (ci)
2. **Task 2: Append `## Phase 8 Close — Permanent Gates` section to REPO-LOCK-POLICY.md** — `cb2c35f` (docs)

## Files Created/Modified

- `.github/workflows/audit.yml` — Top-of-file warning comment block (6 lines) added before `name: audit`; `coverage` job's `if: ${{ github.event_name == 'pull_request' }}` line removed. Net +7 -1 = +6 lines (128 → 133).
- `.planning/audit/REPO-LOCK-POLICY.md` — `## Phase 8 Close — Permanent Gates` section appended after `## References`. Net +17 -0 (69 → 85 visible lines, 86 with trailing newline).

## Decisions Made

1. **Reworded warning comment to dodge self-grep poisoning.** The plan's verbatim text for line 6 was `'continue-on-error: true' flag is intentional`, but the same plan's Step 3 sweep mandates `grep -c "continue-on-error: true" .github/workflows/audit.yml` returns 0. The verbatim text would have failed its own gate. Reworded to `every guardrail step is hard-failing by design` — preserves the intent (no soft-fail flags allowed) without naming the literal flag in the file. Also avoided `soft-fail` substring because the broader sweep regex `soft.fail` would match it.
2. **ASCII-only in audit.yml warning, Unicode em-dash + ≥ in markdown doc.** YAML comments stay strict ASCII (`>=80%`); REPO-LOCK-POLICY.md keeps the PATTERNS.md verbatim Unicode form (`≥80%`, `—`).
3. **Real ISO date 2026-04-28 substituted in `**Locked:**`; `## Update YYYY-MM-DD` placeholder kept for Plan 08-08.** Per CONTEXT D-08, the ADR-011 amendment date is filled when that ADR is closed (last plan in Phase 8). REPO-LOCK-POLICY's Cross-reference line preserves the placeholder by design.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reworded audit.yml warning comment line 6 to avoid plan-internal self-grep contradiction**
- **Found during:** Task 1 (post-edit verification)
- **Issue:** The plan's `<action>` Step 1 prescribed a verbatim line 6: `# job and any 'continue-on-error: true' flag is intentional.` But the same plan's Step 3 sweep (and `<acceptance_criteria>`) requires `grep -c "continue-on-error: true" .github/workflows/audit.yml` to return 0. The verbatim text would have been the only matching line, breaking the guardrail-permanence sweep. A second iteration revealed `soft-fail` substring in my first rewording also matched the broader `soft.fail` regex.
- **Fix:** Final line 6 reads: `# guard, and every guardrail step is hard-failing by design.` Preserves the intent (every guardrail step has no soft-fail flag, and the lift of `if: pull_request` is intentional) without naming the literal flag substrings the sweep filters out.
- **Files modified:** `.github/workflows/audit.yml`
- **Verification:** All sweep greps return 0; `head -7 ... | grep "Permanent gate"`, `... grep "ADR-011"`, `... grep "Phase 8 D-05"` all return ≥1.
- **Committed in:** 67b1aff (Task 1)

---

**Total deviations:** 1 auto-fixed (1 Rule 1 — plan-internal acceptance-criterion contradiction)
**Impact on plan:** Content semantically identical to plan-prescribed verbatim text; no scope creep. The plan author's intent (warning comment that documents the load-bearing-ness of guardrails) is preserved.

## Issues Encountered

### Acceptance-criterion grep-mismatches (informational, not blocking)

Three of Task 2's detailed `<acceptance_criteria>` checks fail their literal grep form even though the file content matches the PATTERNS.md verbatim template exactly:

1. `grep -c "## The Policy" .planning/audit/REPO-LOCK-POLICY.md` returns **2** (criterion expected 1). The PATTERNS verbatim template's last paragraph references `"## The Policy"` in quotes, which is itself a grep match. Anchored grep `grep -c "^## The Policy$"` correctly returns 1.
2. `grep -c "coverde per-file" .planning/audit/REPO-LOCK-POLICY.md` returns **0** (criterion expected ≥1). The verbatim template renders `` `coverde` per-file ≥80% `` — a closing backtick interrupts the literal `coverde per-file` substring. Token sequence is correct; literal-substring grep doesn't span backticks.
3. `grep -E "Locked: 20[0-9]{2}-..."` returns **0** (criterion expected ≥1). The template format is `**Locked:** 2026-04-28` (with markdown bold markers). The regex `Locked: 20[0-9]{2}` doesn't match because of the intervening `**`. The corrected regex `Locked:\*\* 20[0-9]{2}` returns 2 (line 3 + line 72).

The plan's `<verify><automated>` block (the canonical verification gate) passes cleanly: all 7 conjuncts succeed. Recording the detailed-criterion mismatches here so verifier / future readers can see the verbatim PATTERNS template was followed; the criterion regexes are the bug, not the content.

## User Setup Required

None — no external service configuration required. CI guardrails are now permanent and self-enforcing.

## Next Phase Readiness

- Plans 08-04 / 08-05 (re-audit run + smoke test) inherit a hardened CI: every plan touched by their refactors will hit the 80% gate even on direct push to main.
- Plan 08-08 (ADR-011 amendment) has its cross-reference target wired in both directions: REPO-LOCK-POLICY links to ADR-011 §`## Update YYYY-MM-DD: Re-audit Outcome`, and audit.yml's warning header points at ADR-011 by file path. Plan 08-08 just needs to fill the YYYY-MM-DD placeholder when it lands.
- No blockers.

## Self-Check: PASSED

Verified:
- `.planning/phases/08-re-audit-exit-verification/08-03-SUMMARY.md` (this file): created, ≥85 lines.
- `.github/workflows/audit.yml`: 67b1aff present in `git log`, file 133 lines, all 7 plan `<verify>` greps pass.
- `.planning/audit/REPO-LOCK-POLICY.md`: cb2c35f present in `git log`, file 85 lines, all 7 plan `<verify>` greps pass.

Commit hashes verified via `git log --oneline | grep <hash>`:
- 67b1aff: Task 1 (audit.yml hardening)
- cb2c35f: Task 2 (REPO-LOCK-POLICY append)

---
*Phase: 08-re-audit-exit-verification*
*Completed: 2026-04-28*
