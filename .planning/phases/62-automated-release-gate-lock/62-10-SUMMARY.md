---
phase: 62-automated-release-gate-lock
plan: 10
subsystem: release-gate-validation
tags: [release-gate, git-provenance, ios-simulator, android-emulator, tdd]
requires:
  - phase: 62-09
    provides: Candidate-bound release-gate authority and retained platform evidence seams
provides:
  - First-parent-aware candidate attribution for candidate-scoped merge commits
  - Validator-enforced iOS and Android acceptance at the authoritative aggregate boundary
affects: [phase-62-verification, phase-63, release-process]
actuals:
  tokens: 4108
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns:
    - Candidate-scoped merge commits are diffed against their first parent before fingerprinting.
    - Platform adapters supply evidence only; the release authority invokes published validators before stage PASS.
key-files:
  created: []
  modified:
    - scripts/release_gate.dart
    - scripts/release_gate/ios_simulator_stage.dart
    - test/scripts/release_gate_test.dart
    - test/scripts/release_gate_ios_test.dart
key-decisions:
  - "Resolve merge candidates from their first-parent diff so the attested SHA and hashed tree are the same candidate."
  - "Treat iOS/Android validator success and shared inventory equality as mandatory aggregate-stage requirements."
patterns-established:
  - "Injected platform evidence tests exercise release authority decisions without booting a Simulator or Emulator."
requirements-completed: [QA-01, QA-04]
coverage:
  - id: D1
    description: "Candidate-scoped merge commits are attributed to the merge SHA rather than an older parent or side commit."
    requirement: QA-01
    verification:
      - kind: unit
        ref: "flutter test test/scripts/release_gate_test.dart --plain-name candidate-scoped merge is attributed to the merge commit -r expanded"
        status: pass
    human_judgment: false
  - id: D2
    description: "Malformed iOS and Android evidence cannot pass the mandatory aggregate platform stages."
    requirement: QA-04
    verification:
      - kind: unit
        ref: "flutter test test/scripts/release_gate_ios_test.dart --plain-name iOS evidence validator requires successful records and preflight -r expanded"
        status: pass
      - kind: unit
        ref: "flutter test test/scripts/release_gate_test.dart --plain-name full scope blocks malformed platform evidence at aggregate boundary -r expanded"
        status: pass
    human_judgment: false
duration: 4m 20s
completed: 2026-08-10
status: complete
---

# Phase 62 Plan 10: Candidate Provenance and Platform Validation Summary

**Release-gate candidate selection now attributes scoped merges to their own SHA, while iOS and Android stages require complete validated evidence before PASS.**

## Performance

- **Duration:** 4m 20s
- **Started:** 2026-08-10T20:25:21+09:00
- **Completed:** 2026-08-10T11:29:41Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Added an isolated temporary-Git merge regression and changed candidate discovery to compare every non-root commit with its first parent.
- Required redacted iPhone Simulator evidence to have no failure, a completed preflight, complete candidate-bound records, and zero record exit codes.
- Required the published iOS and Android validators plus shared test-inventory accounting at the release authority boundary; malformed injected evidence now blocks.

## Task Commits

1. **Task 1: Attribute candidate-scoped merges to the merge SHA** - `4eb6a08d` (RED), `3e204caf` (GREEN)
2. **Task 2: Require complete iOS and Android validators at aggregation** - `67e302f3` (RED), `4883d466` (GREEN)

## Files Created/Modified

- `scripts/release_gate.dart` - Resolves candidate merges against their first parent and invokes both mandatory platform validators.
- `scripts/release_gate/ios_simulator_stage.dart` - Validates successful candidate-bound test records and completed iOS preflight.
- `test/scripts/release_gate_test.dart` - Covers merge provenance and aggregate rejection of injected malformed platform evidence.
- `test/scripts/release_gate_ios_test.dart` - Covers iOS failure, preflight, record, candidate, and exit-code mutations.

## Decisions Made

- Resolve candidate-scoped merge changes against the first parent so release evidence names the exact merged candidate.
- Keep device tests injected and deterministic; no Simulator, Emulator, physical device, or complete release gate was run.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The merge-provenance and platform-evidence blockers are closed by targeted regressions. Plan 62-11 can continue with the remaining release-gate repairs.

## Verification

- `flutter test test/scripts/release_gate_test.dart --plain-name "candidate-scoped merge is attributed to the merge commit" -r expanded` — passed.
- `flutter test test/scripts/release_gate_ios_test.dart --plain-name "iOS evidence validator requires successful records and preflight" -r expanded` — passed.
- `flutter test test/scripts/release_gate_test.dart --plain-name "full scope blocks malformed platform evidence at aggregate boundary" -r expanded` — passed.

## Self-Check: PASSED

- Confirmed all four modified files exist.
- Confirmed TDD RED and GREEN commits `4eb6a08d`, `3e204caf`, `67e302f3`, and `4883d466` exist in Git history.
