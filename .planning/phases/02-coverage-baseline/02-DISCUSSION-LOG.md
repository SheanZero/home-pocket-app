# Phase 2: Coverage Baseline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-25
**Phase:** 02-coverage-baseline
**Areas discussed:** Gate invocation contract, CI gate staging, Baseline refresh policy, Artifact format

---

## Gate invocation contract

### Q: How should `coverage_gate.dart` receive the file list to check?

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid (CLI args + `--list`) | `dart run scripts/coverage_gate.dart lib/a.dart lib/b.dart` OR `dart run scripts/coverage_gate.dart --list path.txt`. Falls back to `.planning/audit/files-needing-tests.txt` when neither is supplied. | ✓ |
| CLI args only | Simplest, but bumps shell arg-length limits at scale; callers compose paths themselves. | |
| `--list` file only | Friendly to scripting; quick single-file checks need a temp file. | |
| Whole-lib default scan | No input; checks every non-generated `lib/` file. Mid-state always failing during fix phases. | |

**User's choice:** Hybrid mode (recommended).
**Notes:** Default fallback to `files-needing-tests.txt` covers ad-hoc local runs without args.

### Q: Is the 80% threshold hardcoded or parameterized?

| Option | Description | Selected |
|--------|-------------|----------|
| Parameterized, default 80 | `--threshold N` with default 80. Reserves headroom for Phase 8 to dial up. | ✓ |
| Hardcode 80 | Stays close to CLAUDE.md / `.claude/rules/testing.md` wording; one fewer flag. | |

**User's choice:** Parameterized, default 80 (recommended).

### Q: How does the gate locate the lcov file?

| Option | Description | Selected |
|--------|-------------|----------|
| Default `coverage/lcov_clean.info`, `--lcov` override | Convention-over-configuration; missing-default prints actionable hint. | ✓ |
| Required `--lcov` | Explicit but verbose. | |
| Default `coverage/lcov.info` with on-the-fly filter | Avoids needing `coverde filter` first; risks dual-path inconsistency with CI. | |

**User's choice:** Default `coverage/lcov_clean.info`, `--lcov` override (recommended).

### Q: How verbose should gate failure output be?

| Option | Description | Selected |
|--------|-------------|----------|
| Per-file detail table | `path | covered/total | % | PASS|FAIL` per row on stdout. | |
| FAIL lines only | Minimal stdout; manual cross-ref needed. | |
| Both: human stdout + `--json` flag | Default human-readable summary; `--json` for downstream consumers (`merge_findings`, `reaudit_diff`). | ✓ |

**User's choice:** JSON output + human-readable summary (both).

---

## CI gate staging

### Q: When does `very_good_coverage` global gate flip blocking?

| Option | Description | Selected |
|--------|-------------|----------|
| Stepped 50→80 across phases | Phase 2 close: 50 blocking; each fix phase raises threshold; Phase 6 hits 80. Ratchet, no mid-state PR break. | |
| Phase 6 close flip 80 | Mid-state stays report-only; aligned with Phase 1 D-04 staging. | |
| Phase 2 close flip 80 strict | Threshold stays 80; mid-state PRs blocked. Forces test-first discipline; cost: non-cleanup PRs cannot ship during cleanup window. | ✓ |

**User's choice:** Phase 2 close flip 80 strict.
**Notes:** Acknowledged that current global coverage is ~48% raw — flipping immediately means non-cleanup PRs are blocked during Phases 3–6. User picked this knowingly.

### Q: Does `coverage_gate.dart` per-file gate enter CI?

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 2 add report-only step; flip blocking per fix-phase exit | Mirrors D-04 staging; gives mid-state visibility. | |
| Add to CI only after Phase 6 close | No CI surface during fix phases; per-file enforcement lives in fix-phase verification only. | ✓ |
| Never in CI; local-only | Lightweight; fully relies on contributor discipline. | |

**User's choice:** Add to CI only after Phase 6 close.

### Q: How are non-cleanup PRs handled during the blocked window?

| Option | Description | Selected |
|--------|-------------|----------|
| No escape valve | Strict; PR must include enough test additions to pass the global gate. | |
| PR-label bypass (e.g., `cleanup-bypass-coverage`) | Conscious-opt-out path; needs CI implementation and a label-discipline contract. | |
| Repo lock — main accepts only cleanup PRs during Phase 3–6 | Project-level workflow constraint; no CI escape needed. | ✓ |

**User's choice:** Repo lock — only cleanup-plan PRs merge to main during Phases 3–6.
**Notes:** This is a project-level policy, not a CI feature. Planner is responsible for surfacing it in every fix-phase plan.

---

## Baseline refresh policy

### Q: When are `coverage-baseline.txt` and `files-needing-tests.txt` refreshed?

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 2 frozen, Phase 8 regenerated, no mid-refresh | Single "before" image, single "after" image, diff is the empirical evidence. | ✓ |
| Refresh after each fix phase | Lists shrink as phases progress; clearer per-phase scope, but loses the immutable "before" image. | |
| Phase 8 only refresh | Equivalent to Phase 2 frozen + Phase 8 regenerated, but explicitly says no manual mid-runs. | |
| On-demand manual refresh script | Most flexible but loses freeze semantics. | |

**User's choice:** Phase 2 frozen, Phase 8 regenerated (recommended).

### Q: How do fix phases know which files to check after the freeze?

| Option | Description | Selected |
|--------|-------------|----------|
| Plan-supplied touched files, intersected with `files-needing-tests.txt` to identify characterization-test targets | Each fix-phase plan declares its `touched-files`; planner / verifier joins with frozen list. | ✓ |
| Reverse-derive from `issues.json` via `scripts/touched_files_for_phase.dart` | Auto-derived; couples Phase 2 consumption tightly to issues.json shape. | |
| `files-needing-tests.txt` is the upper bound; phase only checks intersection it touched | Path-intersection-based; close to (1) but constrains fix scope harder. | |

**User's choice:** Plan-supplied touched files, intersected with `files-needing-tests.txt` (recommended).

### Q: How is `files-needing-tests.txt` ordered?

| Option | Description | Selected |
|--------|-------------|----------|
| Lexicographic path ascending | Deterministic, grep-friendly, diff-stable. | ✓ |
| Coverage-percentage ascending | Easy "0% files first" scan; ordering churns each run. | |
| Grouped by `lib/` sub-layer | Layer-aligned readability; doesn't match issues.json severity grouping. | |

**User's choice:** Path lexicographic ascending (recommended).

---

## Artifact format

### Q: What format do `coverage-baseline.txt` and `files-needing-tests.txt` use?

| Option | Description | Selected |
|--------|-------------|----------|
| Twin: `.txt` (human) + `.json` (machine) | Mirrors `issues.json` + `ISSUES.md` precedent from Phase 1. | ✓ |
| `.txt` only (file → %) | Minimal; future machine consumers re-parse text. | |
| `.json` only | Machine-first; loses grep-ability. | |
| `.txt` with metadata header comments | Single-file but mixed audiences. | |

**User's choice:** Twin artifacts (recommended).

### Q: Do JSON artifacts cross-link to `issues.json` finding IDs?

| Option | Description | Selected |
|--------|-------------|----------|
| No cross-link; coverage decoupled from findings catalogue | Phase 2 stays independent of Phase 1; fix-phase planner joins on `file_path` lazily. | ✓ |
| Carry `issue_ids` in coverage JSON | Tight coupling; quick lookup; Phase 2 must read `issues.json`. | |
| Separate `coverage-by-issue.json` cross-file | Decouples but adds a third artifact; opt-in. | |

**User's choice:** No cross-link; decoupled (recommended).

---

## Claude's Discretion

- lcov stripping mechanism — `coverde filter` (already activated globally in CI line 29 of `audit.yml`)
- Coverage-baseline regeneration script naming — `scripts/coverage_baseline.dart` + optional shell wrapper
- Test-suite flake handling — assume stable; address only if first run reveals flake
- `coverage/` directory remains gitignored; only `.planning/audit/coverage-*` artifacts committed
- Phase 2 idempotency invariant — byte-identical reruns thanks to deterministic ordering and stable JSON keys

## Deferred Ideas

- `coverage_gate.dart` enters CI as blocking — Phase 7 / Phase 8 territory
- Threshold dialed past 80 — Phase 8 lever via `--threshold`
- Cross-link coverage to `issues.json` IDs — out of scope by D-12
- Flake quarantine — Phase 2.x if discovered
- Per-feature aggregate coverage report — out of scope
- Pre-commit hook for local coverage check — declined (consistent with Phase 1)
- `coverde` migration to pubspec dev_dependency — post-Phase-8 consideration
- Test-suite re-sampling cadence — Phase 2 baseline runs once at close, once at Phase 8
