---
phase: 62-automated-release-gate-lock
plan: 12
subsystem: release-preflight
tags: [bash, android, jdk-17, release-packaging, flutter-test]
requires:
  - phase: 62-02
    provides: Independently controlled JDK and signing-evidence requirements
  - phase: 62-11
    provides: Hardened release-gate process and evidence seams
provides:
  - Direct Android release packaging fails closed unless a configured JDK reports exact major 17
  - The verified JDK home is exported for Gradle or Flutter package commands
affects: [android-release, release-preflight, QA-03, signing-evidence]
actuals:
  tokens: 1820
  tasks: 1
  commits: 2
tech-stack:
  added: []
  patterns:
    - Android package prerequisites resolve and validate a configured toolchain independently of signing-route selection.
key-files:
  created: []
  modified:
    - scripts/release_preflight.sh
    - test/scripts/release_preflight_test.dart
key-decisions:
  - "Resolve PHASE61_JAVA_HOME before JAVA_HOME, require executable bin/java and exact major 17, then export the selected home for Android packaging."
  - "Keep PHASE61_SIGNING_EVIDENCE exclusively as the pre-existing signing-route selector."
patterns-established:
  - "Direct release package routes validate their selected JDK before any package command and prove that ordering with fake-toolchain mutation tests."
requirements-completed: [QA-03]
coverage:
  - id: D1
    description: "Direct Android package dry-runs select and export only a configured JDK 17, while JDK 21, invalid Java, and a missing binary fail before package commands."
    requirement: QA-03
    verification:
      - kind: unit
        ref: "test/scripts/release_preflight_test.dart#Android package requires independent JDK 17 proof"
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-08-10
status: complete
---

# Phase 62 Plan 12: Android Package JDK Proof Summary

**Direct Android release packaging now independently resolves, validates, and exports an exact JDK 17 before Gradle or Flutter package commands can start.**

## Performance

- **Duration:** 5min
- **Started:** 2026-08-10T11:44:53Z
- **Completed:** 2026-08-10T11:49:15Z
- **Tasks:** 1/1
- **Files modified:** 2

## Accomplishments

- Added a fail-closed Android package prerequisite that chooses `PHASE61_JAVA_HOME` or `JAVA_HOME`, requires executable `bin/java`, parses its version, and permits only major 17.
- Exported the verified home and its `bin` directory so the subsequent Gradle or Flutter package route uses the proven toolchain.
- Added disposable fake-JDK and source-mutation coverage for valid, invalid, missing, late, removed, and weakened JDK-gate cases without invoking a real package build.

## Task Commits

Each TDD stage was committed atomically:

1. **Task 1 RED: Block direct Android packaging outside verified JDK 17** - `75354212` (`test`)
2. **Task 1 GREEN: Block direct Android packaging outside verified JDK 17** - `9e96d381` (`feat`)

## Files Created/Modified

- `scripts/release_preflight.sh` - Validates and exports an independently selected JDK 17 before Android package commands.
- `test/scripts/release_preflight_test.dart` - Exercises disposable fake JDK homes and mutation-resistant source-order contracts.

## Decisions Made

- Prefer the explicit `PHASE61_JAVA_HOME` override, then `JAVA_HOME`; both are toolchain inputs and neither depends on the signing selector.
- Apply the prerequisite to Android-containing package runs (`android` and `all`) before `package_signed_release`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the new mutation helper's source-placement matching**
- **Found during:** Task 1 GREEN verification
- **Issue:** The initial test helper used incorrectly escaped Dart strings and could fail to mutate the intended source ordering.
- **Fix:** Used literal invocation markers and real newlines so removal, late-placement, and weakened-major mutations are each rejected.
- **Files modified:** `test/scripts/release_preflight_test.dart`
- **Verification:** `flutter test test/scripts/release_preflight_test.dart --plain-name "Android package requires independent JDK 17 proof" -r expanded`
- **Committed in:** `9e96d381`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug)
**Impact on plan:** The correction is test-only and ensures the required mutation evidence accurately protects the JDK gate.

## Issues Encountered

- The Flutter SDK cache is outside the workspace sandbox; the targeted test was rerun with approved access to that cache. No release packaging or broad suite ran.

## User Setup Required

None - callers must provide a configured JDK through `PHASE61_JAVA_HOME` or `JAVA_HOME` when requesting Android release packaging.

## Next Phase Readiness

- CR-06 and the direct-package JDK portion of QA-03 are closed with targeted behavior and mutation evidence.
- Plan 62-13 can continue the remaining release-gate closure work.

## Self-Check: PASSED

- Found `scripts/release_preflight.sh` and `test/scripts/release_preflight_test.dart`.
- Found task commits `75354212` and `9e96d381` in Git history.
- Re-ran the named fake-toolchain/mutation test successfully; no real package build, release gate, or device command was run.

---
*Phase: 62-automated-release-gate-lock*
*Completed: 2026-08-10*
