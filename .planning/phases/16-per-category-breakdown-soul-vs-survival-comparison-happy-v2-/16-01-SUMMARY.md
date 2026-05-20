---
phase: 16
plan: 01
subsystem: roadmap
tags: [doc-fix, scope-correction, sc-3, engagement-axis]
requires: []
provides:
  - "Corrected Phase 16 SC-3 wording (engagement-axis re-frame per D-15)"
affects:
  - ".planning/ROADMAP.md (Phase 16 Success Criteria item 3)"
tech-stack:
  added: []
  patterns: []
key-files:
  created: []
  modified:
    - ".planning/ROADMAP.md"
decisions:
  - "Adopt CONTEXT D-15 replacement text verbatim — no further re-wording, no annotation"
metrics:
  duration: "<5min"
  completed: "2026-05-20"
requirements: [HAPPY-V2-01, STATSUI-V2-01]
---

# Phase 16 Plan 01: ROADMAP SC-3 Wording Correction Summary

**One-liner:** Rewrote ROADMAP Phase 16 Success Criteria 3 from a misleading "avg satisfaction across both ledgers" example to the engagement-axis re-frame (entry count + total spend for both ledgers; avg satisfaction only on Soul column), per CONTEXT D-15.

## Why This Plan Existed

The pre-edit SC-3 sentence used a worked example —

> "Soul ledger averages 7.4 satisfaction; survival ledger 5.1"

— that misrepresents the actual data surface. `transactions.soul_satisfaction` defaults to `2` and the satisfaction picker only renders for soul-ledger entries, so a raw `AVG(soul_satisfaction)` over survival rows is structurally meaningless. Phase 16 plans 02–10 (ARB additions, domain models, DAO+repo, use cases, providers, widgets, integration) all build on this success criterion. Letting plans 02–10 land against the old SC-3 wording would have introduced a contract mismatch: the widgets/queries downstream plans actually build are engagement-axis (entry count + total spend), not avg-satisfaction-of-both-ledgers. Fixing SC-3 first eliminates that drift before any code is written.

## What Changed

Single-line edit to `.planning/ROADMAP.md` line 116:

| | Wording |
|---|---|
| Before | "AnalyticsScreen renders a Soul-vs-Survival comparison surface displaying both ledgers' average satisfaction (e.g., 'Soul ledger averages 7.4 satisfaction; survival ledger 5.1') with descriptive copy only — no value-judgment terms ('better', 'worse', 'higher is good', winner/loser framing); verified by ARB review + widget assertion of forbidden-substring absence in all three locales." |
| After | "AnalyticsScreen renders a Soul-vs-Survival 'Ledger · This window' surface displaying both ledgers' engagement metrics (entry count + total spend), with the Soul column additionally showing average satisfaction. Copy is descriptive only — no value-judgment terms (better/worse/winner/loser/vs framing) — verified by ARB review + widget assertion of forbidden-substring absence in all three locales." |

Key semantic shifts:

- **Metric axis:** "average satisfaction (both ledgers)" → "engagement metrics (entry count + total spend)" with Soul column adding avg satisfaction as a supplementary measure.
- **Surface label:** added explicit "Ledger · This window" surface name to ground downstream widget/ARB work.
- **Anti-toxicity guard:** the forbidden-substring list now includes "vs framing" alongside better/worse/winner/loser; "higher is good" wording dropped (subsumed under value-judgment ban).

## Tasks Executed

| # | Task | Files | Commit |
|---|------|-------|--------|
| 1 | Rewrite ROADMAP Phase 16 SC-3 to engagement-axis framing (D-15) | `.planning/ROADMAP.md` | `18b95c5` |

## Verification Evidence

All plan-level acceptance checks passed:

```
$ grep -F "Soul ledger averages" .planning/ROADMAP.md
  exit=1   (substring absent ✓)

$ grep -F "engagement metrics (entry count + total spend)" .planning/ROADMAP.md
  → SC-3 line matched ✓

$ grep -F "Ledger · This window" .planning/ROADMAP.md
  → SC-3 line matched ✓

$ grep -F "no value-judgment terms (better/worse/winner/loser/vs framing)" .planning/ROADMAP.md
  → SC-3 line matched ✓

$ git diff --stat .planning/ROADMAP.md HEAD~1
  1 file changed, 1 insertion(+), 1 deletion(-)
  → diff scoped exactly to SC-3 line; SC-1/SC-2/SC-4/SC-5 untouched ✓
```

## Deviations from Plan

None — plan executed exactly as written. Replacement text used verbatim from `<action>` block (CONTEXT D-15 wording).

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None — pure documentation edit, no security-relevant surface introduced.

## Decisions Made

1. **Adopt CONTEXT D-15 replacement text verbatim.** The plan's `<action>` block specified the exact string; no further re-wording or annotation was added. This preserves the canonical source-of-truth flow (CONTEXT → ROADMAP) and keeps the git diff to one line.

## Files Created

None.

## Files Modified

- `.planning/ROADMAP.md` — Phase 16 Success Criteria item 3 only (line 116)

## Self-Check: PASSED

- File `.planning/ROADMAP.md` exists ✓
- Commit `18b95c5` exists in worktree branch history ✓ (`git log --oneline | grep 18b95c5` → `18b95c5 docs(16-01): rewrite ROADMAP Phase 16 SC-3 to engagement-axis framing`)
- All four substring acceptance checks return expected exit codes ✓
- `git diff` scope confirmed: 1 file, 1 insertion, 1 deletion ✓

## Downstream Impact

Plans 16-02 through 16-10 now build against the corrected SC-3:

- **16-02 (ARB)** — 17 new keys must include entry-count + total-spend labels for both ledgers and avg-satisfaction label scoped to Soul column.
- **16-03 (Domain models)** — `LedgerSnapshot` split confirmed: `SurvivalLedgerSnapshot` has NO `avgSatisfaction` field (type-system gate per D-04); `SoulLedgerSnapshot` includes it.
- **16-04 (DAO+repo)** — DAO queries return engagement metrics for both ledgers; satisfaction aggregation runs only on soul rows.
- **16-08 (SoulVsSurvivalCard widget)** — surface label "Ledger · This window" is canonical; Soul column has three rows (count / total spend / avg satisfaction), Survival has two (count / total spend).
- **16-09 (Anti-toxicity sweep)** — forbidden-substring list now must include "vs framing" alongside better/worse/winner/loser across ja/zh/en.

The misleading averaging example is permanently removed from the ROADMAP — downstream agents will no longer accidentally build against the old contract.
