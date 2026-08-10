---
phase: 62-automated-release-gate-lock
plan: 03
subsystem: release-gate
tags: [dart, release-gate, candidate-fingerprint, privacy, process-boundary]
requires:
  - phase: 62-01
    provides: "Temporary-Git candidate fixtures and release-gate behavior contract"
  - phase: 62-02
    provides: "RPT-A immutable-candidate attestation decision"
provides:
  - "Repository-owned Dart authority for the Phase 62 release-gate tracer"
  - "Candidate-bound, privacy-safe JSON evidence and Markdown preview under ignored build/release_gate/"
  - "Fail-closed pre-run and post-run candidate identity proof"
affects: [62-04, 62-07, 62-08, 62-09, release-ci]
tech-stack:
  added: []
  patterns:
    - "Hardcode the lower-level prerequisite graph behind an injectable argument-vector process adapter."
    - "Snapshot a clean Git candidate before execution and prove the same fingerprint again before persisting evidence."
key-files:
  created:
    - scripts/release_gate.dart
    - scripts/release_gate/models.dart
    - scripts/release_gate/process_adapter.dart
  modified:
    - test/scripts/release_gate_test.dart
key-decisions:
  - "Apply RPT-A narrowly: only docs/testing/RELEASE_COMPATIBILITY.md is attestation metadata; build/release_gate/ is the ignored raw-artifact root."
  - "Treat missing, dirty, untracked, or post-run-mutated candidate state as BLOCKED without launching or accepting a weaker prerequisite graph."
patterns-established:
  - "Release evidence records only allowlisted command/stage data, UTC timing, SHA-256 candidate inputs, and bounded scrubbed diagnostics."
  - "The production CLI parses only --scope and --result, while tests inject process outcomes but cannot replace the fixed prerequisite command."
requirements-completed: [QA-01, QA-03]
coverage:
  - id: D1
    description: "Candidate-bound repository release-gate tracer with normalized JSON and Markdown-preview evidence"
    requirement: QA-01
    verification:
      - kind: unit
        ref: "test/scripts/release_gate_test.dart#clean committed candidate produces bound JSON and Markdown evidence"
        status: pass
      - kind: other
        ref: "dart run scripts/release_gate.dart --scope=tracer --result=build/release_gate/62-03-final-tracer.json"
        status: pass
    human_judgment: false
  - id: D2
    description: "Fail-closed candidate scope and final drift proof under the RPT-A lifecycle"
    requirement: QA-03
    verification:
      - kind: unit
        ref: "test/scripts/release_gate_test.dart#prerequisite mutation fails final candidate drift proof"
        status: pass
    human_judgment: false
actuals:
  tokens: 7719
  tasks: 2
  commits: 2
duration: 13min
completed: 2026-08-10
status: complete
---

# Phase 62 Plan 03: Candidate-Bound Release-Gate Tracer Summary

**A single Dart release-gate authority now binds a clean committed candidate to SHA-256 inputs, executes the repository codegen prerequisite, and persists scrubbed evidence only after its final drift proof.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-08-10T04:05:53Z
- **Completed:** 2026-08-10T04:18:04Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added the production CLI, immutable result models, and a `runInShell: false` process adapter that hardcodes the existing codegen/reproducibility prerequisite.
- Proved clean committed temporary-Git candidates produce matching JSON and Markdown identities, while failed prerequisites stop with `BLOCKED`.
- Added strict candidate eligibility and final drift proof for manifest inputs plus gate/workflow controls; child mutations and untracked generated residue cannot pass.
- Ran the real clean-checkout tracer successfully: `PASS` with candidate, prerequisite, and final-drift stages all green.

## Task Commits

1. **Task 1: Prove one clean candidate through the prerequisite-to-evidence path** — `9e52effa` (feat)
2. **Task 2: Make candidate identity and final drift proof fail closed** — `eb061451` (feat)

## Files Created/Modified

- `scripts/release_gate.dart` — sole CLI authority, candidate capture, bounded evidence persistence, and final drift proof.
- `scripts/release_gate/models.dart` — immutable candidate, stage, verdict, and result contracts.
- `scripts/release_gate/process_adapter.dart` — argument-vector child-process boundary with timeout and diagnostic scrubbing.
- `test/scripts/release_gate_test.dart` — temporary-Git end-to-end, failure, privacy, RPT-A scope, residue, and mutation coverage.

## Decisions Made

- Applied RPT-A as an exact positive exception for `docs/testing/RELEASE_COMPATIBILITY.md`; no wildcard report exclusion exists.
- Kept `build/release_gate/` ignored and outside candidate identity so raw evidence cannot dirty the checkout.
- Reserved retry/resume behavior for Plan 62-04 with a conservative fail-closed contract until its full proof is implemented.

## Verification

- PASS: `flutter test test/scripts/release_gate_test.dart -r expanded` (14 tests).
- PASS: `dart format --output=none --set-exit-if-changed scripts/release_gate.dart scripts/release_gate test/scripts/release_gate_test.dart`.
- PASS: `flutter analyze scripts/release_gate.dart scripts/release_gate/models.dart scripts/release_gate/process_adapter.dart test/scripts/release_gate_test.dart` (0 issues).
- PASS: `dart run scripts/release_gate.dart --scope=tracer --result=build/release_gate/62-03-final-tracer.json` (`PASS`; ignored evidence only).
- PASS: `git diff --check`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The first live tracer attempts overlapped while the existing serialized tooling-guard fixture suite was active, correctly yielding `BLOCKED` on transient untracked fixtures. After its built-in cleanup completed, one clean, non-overlapping tracer run passed. No repository files were modified or removed to resolve the transient condition.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 62-04 can extend the same candidate/result contracts with its closed retry and resume policy. Plans 62-07 through 62-09 can consume the one-authority CLI and candidate-safe evidence boundary.

## Self-Check: PASSED

Confirmed all four release-gate artifacts and both atomic task commits (`9e52effa`, `eb061451`) exist.

---
*Phase: 62-automated-release-gate-lock*
*Completed: 2026-08-10*
