---
phase: 62-automated-release-gate-lock
plan: 11
subsystem: release-gate
tags: [dart, flutter-test, process-timeout, diagnostics, privacy, report-evidence]
requires:
  - phase: 62-09
    provides: Candidate-bound release-gate execution and report authority
provides:
  - Bounded child-process timeout recovery that remains reachable while pipes are open
  - Key/value-aware diagnostic scrubber and persisted-evidence privacy validation
affects: [release-gate, report-rendering, serial-recovery, CI-evidence]
actuals:
  tokens: 4337
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns:
    - Exit timeout races independently-started stream drains; termination and drain grace periods are bounded.
    - Sensitive values are scrubbed at diagnostic ingress and rejected again before report persistence.
key-files:
  created:
    - test/scripts/release_gate_process_adapter_test.dart
    - test/scripts/release_gate_report_test.dart
  modified:
    - scripts/release_gate/process_adapter.dart
    - scripts/release_gate/report.dart
key-decisions:
  - "Arm the process exit timeout before awaiting output streams, then use SIGTERM/SIGKILL recovery and bounded drainage."
  - "Treat serial and UDID only as sensitive assignments so the serialHostSuite stage name remains publishable."
patterns-established:
  - "Release evidence is protected at collection and persistence boundaries with compatible key/value semantics."
requirements-completed: [QA-01, QA-02, QA-04]
coverage:
  - id: D1
    description: "Open-pipe process timeout reaches bounded termination, escalation, drainage, and exit 124 while normal exits retain scrubbed output."
    requirement: QA-02
    verification:
      - kind: unit
        ref: "test/scripts/release_gate_process_adapter_test.dart#timeout remains armed while child output pipes stay open"
        status: pass
    human_judgment: false
  - id: D2
    description: "Secret assignment variants are scrubbed and rejected before report persistence without blocking serialHostSuite evidence."
    requirement: QA-04
    verification:
      - kind: unit
        ref: "test/scripts/release_gate_process_adapter_test.dart and test/scripts/release_gate_report_test.dart"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-08-10
status: complete
---

# Phase 62 Plan 11: Shared Process and Evidence Privacy Summary

**Bounded release-gate child-process recovery plus two-layer key/value privacy protection for diagnostics and compatibility evidence.**

## Performance

- **Duration:** 4min
- **Started:** 2026-08-10T11:33:51Z
- **Completed:** 2026-08-10T11:37:49Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Started output drains without awaiting them, so a child with open pipes reaches exit timeout, TERM/KILL recovery, bounded drainage, and exit 124.
- Scrubbed colon, spaced-equals, compact-equals, and JSON secret assignments while keeping valid JSON decodable.
- Replaced the bare serial prohibition with actual serial/UDID assignment detection, allowing authoritative `serialHostSuite` results to validate and render.

## Task Commits

1. **Task 1: Arm timeout before awaiting open output streams** - `52676d12` (RED), `80366777` (GREEN)
2. **Task 2: Scrub secret assignment variants and narrow the serial rule** - `d8b829c9` (RED), `26064d70` (GREEN)

## Files Created/Modified

- `scripts/release_gate/process_adapter.dart` - bounded process termination and key/value-aware ingress scrubber.
- `scripts/release_gate/report.dart` - persisted-evidence assignment privacy backstop.
- `test/scripts/release_gate_process_adapter_test.dart` - live child timeout, normal completion, and scrubber coverage.
- `test/scripts/release_gate_report_test.dart` - synthetic GateResult privacy and serialHostSuite coverage.

## Decisions Made

- Arm the child exit timeout before stream drainage; after expiry, use TERM, a bounded grace period, KILL if necessary, then bounded drain collection.
- Preserve the `serialHostSuite` stage label and reject actual serial/UDID assignments instead of any substring containing `serial`.

## Verification

- `flutter test test/scripts/release_gate_process_adapter_test.dart --plain-name "timeout remains armed while child output pipes stay open" -r expanded` — passed.
- `flutter test test/scripts/release_gate_process_adapter_test.dart test/scripts/release_gate_report_test.dart -r expanded` — passed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The shared process and report boundaries now have focused regression coverage for the reviewed timeout and evidence-privacy defects. The plan intentionally did not run the full release gate, device lanes, or complete test suite.

## Self-Check: PASSED

- All four scoped implementation and test files exist.
- All four TDD commits are present in Git history.

---
*Phase: 62-automated-release-gate-lock*
*Completed: 2026-08-10*
