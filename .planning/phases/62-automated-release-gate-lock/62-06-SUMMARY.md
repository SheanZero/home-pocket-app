---
phase: 62-automated-release-gate-lock
plan: 06
subsystem: release-gate
tags: [dart, ios, simulator, integration-test, release-preflight, privacy]
requires:
  - phase: 62-04
    provides: Candidate-bound release-gate evidence and closed retry classification
  - phase: 60
    provides: SQLCipher/iOS native safety boundary retained as a lower-level lane
provides:
  - Isolated iPhone Simulator selection, cold preparation, and redacted evidence
  - Recursive candidate-bound iOS integration inventory with exact skip validation
  - Mandatory post-integration iOS release-preflight and final candidate proof
affects: [62-08, 62-09, phase-63]
actuals:
  tokens: 8741
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns:
    - Simctl commands retain raw identifiers only in process arguments and persist hash-derived simulator tokens
    - Each integration execution record carries its candidate commit while the aggregate verdict remains external
key-files:
  created:
    - scripts/release_gate/ios_simulator_stage.dart
    - test/scripts/release_gate_ios_test.dart
    - test/architecture/release_gate_ios_contract_test.dart
  modified:
    - test/scripts/release_preflight_test.dart
key-decisions:
  - "Require exactly one available iPhone Simulator and reject ambiguous or non-iPhone destinations before destructive commands."
  - "Use recursive inventory equality (executed plus explicit, complete skip records) rather than Phase 60's two-test runtime allowlist."
  - "Run unsigned iOS release preflight after every prepared integration suite, then erase the Simulator and recheck candidate identity."
patterns-established:
  - "Simulator evidence contains only device kind, model, runtime, a hash-derived token, redacted commands, and candidate-bound test records."
requirements-completed: [QA-03, QA-04]
coverage:
  - id: D1
    description: Isolated iPhone Simulator preparation with physical-destination rejection, cold erase/boot/readiness, redacted evidence, and terminal candidate-drift checks.
    requirement: QA-03
    verification:
      - kind: unit
        ref: test/scripts/release_gate_ios_test.dart#Phase 62 iOS Simulator stage
        status: pass
      - kind: unit
        ref: test/architecture/release_gate_ios_contract_test.dart#Phase 62 iOS simulator stage is a full-suite adapter, not Phase 60
        status: pass
    human_judgment: false
  - id: D2
    description: Recursive complete iOS integration execution, explicit skip-matrix validation, candidate-bound execution records, and post-integration iOS release preflight.
    requirement: QA-04
    verification:
      - kind: unit
        ref: flutter test test/scripts/release_gate_ios_test.dart test/architecture/release_gate_ios_contract_test.dart test/scripts/release_preflight_test.dart -r expanded
        status: pass
      - kind: unit
        ref: test/scripts/release_preflight_test.dart#the iOS release gate always routes integration cleanup to preflight
        status: pass
    human_judgment: false
duration: 13min
completed: 2026-08-10
status: complete
---

# Phase 62 Plan 06: iOS Simulator Stage Summary

**A candidate-bound iPhone Simulator adapter now runs the full recursive integration inventory from erased state, persists redacted evidence, and restores unsigned iOS release hygiene.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-08-10T04:47:00Z
- **Completed:** 2026-08-10T04:59:45Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Added strict iPhone Simulator-only discovery with shutdown, erase, cold boot, readiness, cleanup, and pre/post-cleanup candidate binding.
- Added recursive integration discovery and exact executed-plus-allowlisted-skip matrix validation; each execution record binds to the candidate commit.
- Added mandatory `release_preflight.sh --platform ios` after integration execution, preserving Phase 60 as the distinct SQLCipher/native safety lane.

## Task Commits

1. **Task 1: Prepare an isolated current-candidate iPhone Simulator stage** — `0536850f` (RED), `3cfc61cb` (GREEN)
2. **Task 2: Execute the recursive suite and restore clean iOS release state** — `b21ad163` (RED), `daaa1433` (GREEN)
3. **Follow-up regression coverage** — `791af9f3` (test)

## Files Created/Modified

- `scripts/release_gate/ios_simulator_stage.dart` — simulator isolation, recursive execution, matrix validation, redacted evidence, and preflight adapter.
- `test/scripts/release_gate_ios_test.dart` — pure simctl ordering, privacy, candidate drift, inventory, and skip-matrix mutations.
- `test/architecture/release_gate_ios_contract_test.dart` — guards the Phase 62 full-suite boundary against Phase 60 scope collapse.
- `test/scripts/release_preflight_test.dart` — asserts iOS gate cleanup routes through release preflight before final erase.

## Decisions Made

- Phase 62 persists no simulator UDID, host path, diagnostics, credential, backup, or application-data value; only a hash-derived simulator token can enter evidence.
- A full-suite test failure still allows the safe post-integration iOS preflight and cleanup to run, while its normalized evidence remains non-passing for the aggregate gate.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added post-cleanup candidate-drift regression coverage**
- **Found during:** Task 2
- **Issue:** The adapter rechecked candidate identity after cleanup, but the regression suite had not proved that terminal path.
- **Fix:** Added a deterministic mutation test that changes the candidate only after cleanup and asserts a non-retryable block.
- **Files modified:** `test/scripts/release_gate_ios_test.dart`
- **Verification:** Focused iOS adapter, contract, and preflight tests; project-wide `flutter analyze`.
- **Committed in:** `791af9f3`

---

**Total deviations:** 1 auto-fixed (1 Rule 2 missing-critical regression guard).
**Impact on plan:** Tightens the locked candidate-bound safety requirement without expanding runtime scope.

## Issues Encountered

- Flutter SDK cache refresh requires access outside the workspace sandbox; elevated verification completed successfully with no code changes outside the repository.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The release-gate authority now has a testable iOS full-suite adapter ready for aggregate orchestration and report wiring in later Phase 62 plans. Physical-device work, signing, and Phase 60 SQLCipher-native claims remain outside this adapter.

## Self-Check: PASSED

- Confirmed all four implementation/test artifacts exist.
- Confirmed commits `0536850f`, `3cfc61cb`, `b21ad163`, `daaa1433`, and `791af9f3` exist.
- Focused tests and project-wide analysis passed.

---
*Phase: 62-automated-release-gate-lock*
*Completed: 2026-08-10*
