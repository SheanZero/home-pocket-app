# Phase 6: LOW Fixes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-27
**Phase:** 06-LOW Fixes
**Areas discussed:** LOW scope source of truth, Debug logging boundary, Gate tightening timing

---

## LOW Scope Source of Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Re-scan first | Treat the missing LOW catalogue as stale; Phase 6 starts by running LOW scanners and updating/adding LOW findings before fixes. | Yes |
| Plan from roadmap | Treat roadmap and LOW requirements as authoritative; do not create new issue rows unless scanners find regressions during verification. | |
| Hybrid | Re-scan first, but only add stable LOW issue rows for concrete scanner-backed findings; roadmap-only items stay as requirements. | |
| You decide | Let the planner choose the cleanest path and document the catalogue mismatch clearly. | |

**User's choice:** Re-scan first.
**Notes:** `.planning/audit/issues.json` has no open LOW rows even though roadmap and requirements define LOW work.

### Follow-up: Recording Re-scan Findings

| Option | Description | Selected |
|--------|-------------|----------|
| Add stable issue rows | Add scanner-backed LOW findings to `.planning/audit/issues.json` with stable IDs, then close them during the phase. | Yes |
| Keep scan output only | Leave `issues.json` unchanged and use shard files plus plan summaries as the working list. | |
| Do not mutate audit catalogue | Use re-scan only to scope plans; preserve Phase-1 catalogue history exactly as-is. | |
| You decide | Planner chooses, but must explain the decision in the context file. | |

**User's choice:** Add stable issue rows.
**Notes:** This favors Phase 8 traceability over preserving the stale catalogue as-is.

---

## Debug Logging Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Only unguarded print/debugPrint | Strictly fix LOW-06 wording: `print()` and bare `debugPrint()` in production paths. Leave `dev.log` alone unless tests expose a leak. | |
| All production logging | Review `print`, `debugPrint`, and `dev.log`; scrub or guard anything that could expose identifiers, request bodies, transaction IDs, or device IDs. | Yes |
| Central logging utility | Route production logs through one utility that enforces debug-only behavior and redaction rules. | |
| You decide | Planner chooses the minimum safe boundary and records the rationale. | |

**User's choice:** All production logging.
**Notes:** User asked to continue in Chinese before answering this area. The decision is broader than the literal LOW-06 wording because Home Pocket is privacy-focused.

---

## Gate Tightening Timing

| Option | Description | Selected |
|--------|-------------|----------|
| Final close commit only | Fix all LOW items first, then flip CI/scanner gates to blocking in the final close commit. | Yes |
| Incremental blocking by category | Make each gate blocking as its category is fixed: dead-code, then logging, then coverage. | |
| Blocking from first Phase 6 plan | Turn on blocking gates at the start so every later commit stays clean. | |
| You decide | Planner chooses timing but must ensure all gates are blocking at Phase 6 close. | |

**User's choice:** Final close commit only.
**Notes:** This avoids intermediate CI churn while LOW debt is still intentionally in progress.

---

## the agent's Discretion

- Exact Phase 6 plan split and sequencing.
- Exact LOW stable ID numbering after re-scan.
- Exact implementation shape for logging cleanup, as long as production logs are privacy-safe.
- Exact test implementation for migration/index verification and per-file coverage.

## Deferred Ideas

None.
