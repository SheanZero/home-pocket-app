---
phase: 02-coverage-baseline
plan: 03
subsystem: documentation
tags:
  - documentation
  - schema
  - policy
  - audit
dependency_graph:
  requires:
    - .planning/phases/02-coverage-baseline/02-CONTEXT.md (D-05, D-07, D-08, D-11, D-12)
    - .planning/audit/SCHEMA.md (existing §1-§8, header style)
    - .planning/PROJECT.md (initiative scope)
  provides:
    - .planning/audit/SCHEMA.md §9 (Coverage Baseline Schema — locked artifact contract)
    - .planning/audit/REPO-LOCK-POLICY.md (cleanup-window merge policy)
  affects:
    - Phase 3, 4, 5, 6 fix-phase planners (must read REPO-LOCK-POLICY.md before scoping)
    - Phase 8 re-audit (byte-compare normalizes against §9 schema)
    - .planning/phases/02-coverage-baseline/02-04-PLAN.md (artifact snapshot validates against §9)
tech_stack:
  added: []
  patterns:
    - locked-date frontmatter (Phase 1 SCHEMA.md convention)
    - field-table convention (`Field | Type | Required | Valid Values / Notes | Example`)
    - cross-reference Dart code mirror by repo-relative path
    - twin-artifact (txt + json) precedent from Phase 1 D-09/D-10
key_files:
  created:
    - .planning/audit/REPO-LOCK-POLICY.md (68 lines, 5092 bytes)
  modified:
    - .planning/audit/SCHEMA.md (186 → 287 lines; +101 insertions, 0 deletions)
decisions:
  - Inlined §9 into existing SCHEMA.md (vs creating separate COVERAGE-SCHEMA.md) — CONTEXT and PATTERNS both expressed preference for inlining to avoid doc proliferation
  - Added narrative line in §9.5 after table to mention `lines_below_threshold` in non-table prose, satisfying acceptance criterion "≥2 occurrences"
  - REPO-LOCK-POLICY.md is self-contained (a fresh reader without phase context can act on it)
metrics:
  duration: ~3.5 minutes
  completed_date: 2026-04-26
  task_count: 2
  file_count: 2
  total_commits: 2
---

# Phase 02 Plan 03: Schema + Repo-Lock Documentation Summary

Locked the Phase-2 contracts in writing: extended `.planning/audit/SCHEMA.md` with a self-contained §9 documenting the four coverage artifacts' shape, and created `.planning/audit/REPO-LOCK-POLICY.md` capturing CONTEXT D-07 (cleanup-window merge discipline). Two doc files; zero `lib/`, scripts, or CI changes.

## What Was Built

### SCHEMA.md §9 Coverage Baseline Schema

Appended a self-contained §9 (8 sub-sections, 2 field-tables, 2 example blocks) between existing §8 "JSON Example" and "Files Referenced":

- **§9.1 Common metadata block** — 6-field table (`generated_at`, `flutter_test_command`, `lcov_source`, `threshold`, `total_files`, `files_below_threshold`) shared by both JSON artifacts
- **§9.2 `coverage-baseline.txt`** — TSV format spec; example block with 3 sample records
- **§9.3 `coverage-baseline.json`** — 5-field per-entry table including `threshold_met` boolean
- **§9.4 `files-needing-tests.txt`** — bare-path filtered view; example block
- **§9.5 `files-needing-tests.json`** — 3-field per-entry table including `lines_below_threshold` derived sizing signal
- **§9.6 Idempotency invariant (D-12)** — re-runs are byte-identical except `generated_at`
- **§9.7 Decoupling from `issues.json` (D-12)** — no `issue_ids` cross-link; lazy join on `file_path`
- **§9.8 Frozen baseline (D-08)** — frozen at Phase 2, regenerated at Phase 8

The "Files Referenced" section gained 3 new entries: `scripts/coverage_baseline.dart` (producer), `scripts/coverage_gate.dart` (consumer), `scripts/coverage/lcov_parser.dart` (shared parser).

### REPO-LOCK-POLICY.md

Created from scratch — 68 lines, 8 top-level sections capturing CONTEXT D-07 verbatim:

1. **Why This Policy Exists** — justifies the BLOCKING flip when global coverage is ~48% raw
2. **The Policy** — cleanup-roadmap PRs only during Phase 2 close → Phase 6 close
3. **What This Is Not** — preempts the three most likely misreads (no CI bypass, not a hotfix freeze, not a doc freeze)
4. **Lifecycle** — 5-row table mapping each phase boundary to lock effect + owner
5. **Planner Responsibility (D-07)** — every fix-phase plan must include a "Repo Lock Note" preamble
6. **Rollback Path** — 2-step revert + mandatory dated breach entry
7. **Frozen Baseline (D-08) Interaction** — lock prevents non-cleanup PR drift from contaminating the Phase 8 diff
8. **References** — cross-links to CONTEXT.md, PROJECT.md, ROADMAP.md, audit.yml, SCHEMA.md §9

The doc is self-contained: a planner reading it without prior CONTEXT.md exposure can identify the policy, its scope, its lifecycle, and the rollback path.

## Final Byte Counts

| File | Lines | Bytes | Status |
|------|-------|-------|--------|
| `.planning/audit/SCHEMA.md` | 287 (was 186) | 19607 | extended (+101 / -0) |
| `.planning/audit/REPO-LOCK-POLICY.md` | 68 | 5092 | created |

## Pre-Edit Section Preservation (SCHEMA.md §1-§8)

`git diff --stat 564575d HEAD -- .planning/audit/SCHEMA.md` reports `101 insertions(+), 0 deletions`. The change is purely additive — every byte of §1 through §8 (lines 1-179 of the original, ending at the `---` separator) is unchanged in the new file. The only structural touch outside the inserted §9 block is the addition of 3 entries at the end of "## Files Referenced".

## Self-Contained Verification (REPO-LOCK-POLICY.md)

A fresh reader can act on the policy without needing to open CONTEXT.md, because the doc:

- Quotes the substance of D-07 in its own words in the "Why This Policy Exists" section
- Names the exact CI mechanism being flipped (`very_good_coverage@v2`) and the exact file (`.github/workflows/audit.yml`)
- Specifies the start trigger (Phase 2 plan 02 lands), the end trigger (Phase 6 close), and the post-lock state (Phase 7 normal merge rules)
- Lists the rollback steps explicitly (re-add `continue-on-error: true`, append to `## Lock Breaches`)
- Cross-references all source-of-truth docs in the "References" section

The doc could be merged with no other artifacts and a future planner would still understand what to do.

## Acceptance Criteria Results

### Task 1 — SCHEMA.md §9

| Check | Required | Actual | Status |
|-------|----------|--------|--------|
| `^## 9. Coverage Baseline Schema` | =1 | 1 | PASS |
| `^### 9.1 Common metadata block` | =1 | 1 | PASS |
| `^### 9.6 Idempotency invariant` | =1 | 1 | PASS |
| `scripts/coverage_baseline.dart` | ≥2 | 3 | PASS |
| `scripts/coverage_gate.dart` | ≥2 | 2 | PASS |
| `scripts/coverage/lcov_parser.dart` | ≥1 | 1 | PASS |
| `lines_below_threshold` | ≥2 | 2 | PASS |
| `threshold_met` | ≥1 | 1 | PASS |
| `files_below_threshold` | ≥1 | 1 | PASS |
| `^## 1. Required Fields` | =1 | 1 | PASS |
| `^## 8. JSON Example` | =1 | 1 | PASS |
| `^## Files Referenced` | =1 | 1 | PASS |
| Line count | ≥280 | 287 | PASS |

### Task 2 — REPO-LOCK-POLICY.md

| Check | Required | Actual | Status |
|-------|----------|--------|--------|
| File exists | yes | yes | PASS |
| `^# Repo Lock Policy` | =1 | 1 | PASS |
| `^## ` (top-level subsections) | ≥8 | 8 | PASS |
| `D-07` references | ≥2 | 4 | PASS |
| `D-05` references | ≥2 | 4 | PASS |
| `D-08` references | ≥1 | 3 | PASS |
| `Phase 6 close` | ≥2 | 3 | PASS |
| `very_good_coverage` | ≥2 | 3 | PASS |
| CI bypass mention | ≥1 | 1 | PASS |
| `Rollback Path` | =1 | 1 | PASS |
| `Repo Lock Note` | ≥1 | 1 | PASS |
| Line count | ≥60 | 68 | PASS |

## Verification

- `git diff --stat lib/` returned empty — no `lib/` changes
- `git diff --stat scripts/` returned empty — no script changes
- `git diff --stat .github/` returned empty — no CI changes
- Both docs follow the locked-date frontmatter convention from Phase 1 SCHEMA.md
- All cross-references between the two docs work (REPO-LOCK-POLICY.md cites SCHEMA.md §9 in References block)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plan's verbatim §9.5 content failed its own acceptance criterion**

- **Found during:** Task 1 verification
- **Issue:** The plan body specified pasting verbatim §9.5 content where `lines_below_threshold` appears only in the field-table row (one occurrence). The plan's own acceptance criteria require ≥2 occurrences ("in §9.5 table + section narrative"). Verbatim paste would have failed the check.
- **Fix:** Added one sentence after the §9.5 entries lex-sort note explicitly mentioning `lines_below_threshold` as a sizing signal for fix-phase planners. Preserves the table verbatim and adds the missing narrative the acceptance criterion expected.
- **Files modified:** `.planning/audit/SCHEMA.md` (1 sentence added in §9.5)
- **Commit:** 179f33e (folded into the Task 1 commit)

No architectural changes, no Rule 4 escalation needed.

## Authentication Gates

None — pure documentation plan; no auth-gated tooling involved.

## Known Stubs

None. Both documents are complete and self-contained. No placeholder text, no "TODO", no empty fields awaiting later wire-up.

## Self-Check: PASSED

**Created files exist:**
- FOUND: .planning/audit/REPO-LOCK-POLICY.md
- FOUND: .planning/audit/SCHEMA.md (extended; pre-existed)

**Commits exist:**
- FOUND: 179f33e (`docs(02-03): extend SCHEMA.md with §9 Coverage Baseline Schema`)
- FOUND: 5bae644 (`docs(02-03): add REPO-LOCK-POLICY.md capturing D-07 contract`)

**Acceptance criteria:** 13/13 Task 1 + 12/12 Task 2 = 25/25 pass.

**Out-of-scope check:** `git diff --stat lib/ scripts/ .github/` empty against base.
