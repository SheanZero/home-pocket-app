---
phase: 08-re-audit-exit-verification
plan: "01"
subsystem: testing
tags: [dart, audit, ci-gate, subprocess-tests, json-diff]

requires:
  - phase: 01-audit-pipeline-tooling-setup
    provides: scripts/reaudit_diff.dart Phase 1 stub + scripts/audit/finding.dart schema model + .planning/audit/SCHEMA.md lifecycle/split-merge contract
  - phase: 07-documentation-sweep
    provides: ADR-011 created and ready for Phase 8 amendment (consumed downstream by Plan 08-08, not by this plan)
provides:
  - scripts/reaudit_diff.dart full implementation of D-01 strict-exit gate (replaces 9-line stub)
  - test/scripts/reaudit_diff_test.dart 9-test subprocess suite covering all 4 D-01 exit branches + JSON/MD shape + invocation errors
  - REAUDIT-DIFF.{json,md} output contract (summary + 4 buckets) ready for Plan 08-05 to invoke against re-audit catalogue
affects: [08-05-pipeline-rerun, 08-08-adr-amendment]

tech-stack:
  added: []
  patterns:
    - "Pattern A — Dart CLI in scripts/ (file-I/O + JSON contract): exit codes 0/1/2 idiom from coverage_gate.dart, [tool:tag] stderr prefix, JsonEncoder.withIndent('  ')"
    - "Pattern B — Subprocess test in test/scripts/: temp-dir + symlink-.dart_tool shortcut from merge_findings_test.dart (avoids per-test pub get)"

key-files:
  created:
    - test/scripts/reaudit_diff_test.dart
  modified:
    - scripts/reaudit_diff.dart

key-decisions:
  - "reaudit_diff match key drops line_start (Phase 1 D-07 + Phase 8 D-02): category|file_path|description — line numbers shift after cleanup but the triple is stable across re-runs"
  - "Reserved exit(2) for invocation errors (missing baseline / re-audit JSON, malformed JSON, unknown flag) per coverage_gate.dart precedent — keeps gate-failure (exit 1) and bug-in-CLI (exit 2) distinguishable"
  - "REAUDIT-DIFF.json carries no top-level generated_at field — keeps re-runs byte-stable per Phase 1 D-09 idempotency carry-over"

patterns-established:
  - "Bucket-first markdown rendering: Resolved → Regression → New → Still Open in Baseline, each grouped by severity then category, mirrors merge_findings.dart _renderMarkdown shape"
  - "Stable-sort across buckets: severity-rank → category-rank → file_path → description — deterministic ordering for golden files and downstream consumers"

requirements-completed:
  - EXIT-02

duration: 13min
completed: 2026-04-28
---

# Phase 8 Plan 01: reaudit_diff Implementation Summary

**Strict-exit re-audit gate (Phase 8 D-01): classifies findings into resolved/regression/new/open_in_baseline, exits 0 only when the latter three are zero, ready for Plan 08-05 to wire into CI.**

## Performance

- **Duration:** ~13 min
- **Started:** 2026-04-28T06:15:42Z
- **Completed:** 2026-04-28T06:19:05Z (plus SUMMARY/STATE work)
- **Tasks:** 2
- **Files modified:** 2 (1 new, 1 replaced)

## Accomplishments

- Replaced the 9-line Phase 1 stub with a 297-line full implementation honoring D-01 (strict exit), D-02 (3-tuple match key), and D-08 (split/merge baseline interpretation).
- Added 9 subprocess tests covering all 4 D-01 exit branches, REAUDIT-DIFF.json/MD shape assertions, and 3 exit-2 invocation-error paths.
- Verified end-to-end via real subprocess smoke test against a temp catalogue: happy path → exit 0, regression/new/open_in_baseline → exit 1, missing files / unknown flag → exit 2.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement scripts/reaudit_diff.dart with classified diff + strict exit** — `70a65d9` (feat)
2. **Task 2: Subprocess tests covering all 4 D-01 exit branches** — `833217d` (test)

_Note: Task 2 carried `tdd="true"` but executes after Task 1 because the implementation file is the SUT — these are subprocess verification tests of an already-landed gate, not RED→GREEN cycle tests of new logic. Tests passed against the Task 1 implementation on first invocation; no separate RED commit was needed._

## Files Created/Modified

- `scripts/reaudit_diff.dart` (modified, 9 → 297 lines) — Full Phase 8 implementation: reads `.planning/audit/issues.json` baseline + `.planning/audit/re-audit/issues.json` re-audit, classifies into resolved/regression/new/open_in_baseline buckets, writes REAUDIT-DIFF.{json,md}, exits per D-01 strict contract.
- `test/scripts/reaudit_diff_test.dart` (created, 341 lines) — 9 subprocess tests using temp-dir + symlink-.dart_tool pattern; covers all 4 D-01 exit branches plus JSON/MD shape and 3 exit-2 invocation error paths.

## Decisions Made

- **Diff key drops `lineStart`** per Phase 1 D-07 + Phase 8 D-02: `String _diffKey(Finding f) => '${f.category}|${f.filePath}|${f.description}'`. Test 2 (regression branch) explicitly exercises this — re-emerging finding has `line: 5` while baseline has `line: 1`, but the key still matches.
- **`exit(2)` reserved for invocation errors** per `scripts/coverage_gate.dart` precedent (lines 96-98, 165-166). Six `exit(2)` paths in the implementation: missing baseline, missing re-audit, malformed baseline JSON, malformed re-audit JSON, missing top-level `findings` array (per file), malformed `Finding.fromJson` (per file), unknown CLI flag.
- **Bucket-first then severity-then-category Markdown structure** (matches CONTEXT D-01 explicit spec) — different from `merge_findings.dart`'s severity-first shape because the diff's primary classification axis is the bucket (resolved/regression/new/open), not severity.
- **No top-level `generated_at` in REAUDIT-DIFF.json** — keeps the file byte-stable across re-runs (Phase 1 D-09 idempotency carry-over). Test idempotency was not asserted explicitly in this plan but the choice is documented for downstream verification.

## Deviations from Plan

None — plan executed exactly as written.

The plan's `<acceptance_criteria>` for Task 1 included a regex grep `category}\\\\|\\\\\$\\{.*filePath\\}\\\\|\\\\\$\\{.*description\\}` that is hard to express through bash; verified equivalently via `grep -nE "f\\.category.*f\\.filePath.*f\\.description"` which matched line 161 (`String _diffKey(Finding f) => '${f.category}|${f.filePath}|${f.description}'`). Match-key correctness is also asserted by Test 2 (regression branch) which deliberately uses different `lineStart` between baseline and re-audit.

## Issues Encountered

None — both tasks landed first-try with passing analyzer and 9/9 tests green.

## User Setup Required

None — no external service configuration required.

## Threat Flags

None — implementation matches the plan's threat model (T-08-01-01..04). Read-only file I/O with `JsonEncoder.withIndent('  ')` typed decode (no string-concat JSON), wrapped `jsonDecode` with actionable stderr + exit(2), no shell-out, no network, no PII.

## Next Plan Readiness

- **Plan 08-05 (re-audit pipeline run)** can now invoke `dart run scripts/reaudit_diff.dart` against the produced `.planning/audit/re-audit/issues.json` and rely on the documented exit contract.
- **Plan 08-08 (ADR-011 amendment)** can cite the REAUDIT-DIFF.json schema (`summary.{resolved,regression,new,open_in_baseline}` integers + `buckets.{...}` lists) when documenting the Phase 8 close outcome.

## Self-Check: PASSED

Verification:

- `scripts/reaudit_diff.dart` exists, 297 lines (≥150).
- `test/scripts/reaudit_diff_test.dart` exists, 341 lines (≥200).
- Commit `70a65d9` present in `git log --oneline -5`.
- Commit `833217d` present in `git log --oneline -5`.
- `dart analyze scripts/reaudit_diff.dart test/scripts/reaudit_diff_test.dart` → "No issues found!".
- `flutter test test/scripts/reaudit_diff_test.dart` → 9/9 tests passed in ~6s.

---
*Phase: 08-re-audit-exit-verification*
*Completed: 2026-04-28*
