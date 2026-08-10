---
phase: 62-automated-release-gate-lock
plan: 05
subsystem: android-release-gate
tags: [android, release-gate, provenance, emulator, signing, flutter-test]
requires:
  - phase: 62-02
    provides: Owner-authorized SIGN-A separation of JDK 17 and signing evidence
  - phase: 62-04
    provides: CandidateFingerprint and normalized release-stage conventions
provides:
  - Candidate-bound, ignored Phase 62 Android evidence JSON with immutable Phase 61 history
  - Mandatory API 36 arm64-v8a readiness and discovered/executed integration accounting
  - Explicit x86_64 supplemental limitation and Android physical-device no-claim boundary
affects: [62-07, 62-08, 62-09, phase-63]
actuals:
  tokens: 8512
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns:
    - Phase-specific adapters emit ignored normalized evidence and never rewrite historical ledgers.
    - JDK 17 selection and explicit signing-evidence activation are independent controls.
key-files:
  created: []
  modified:
    - scripts/verify_android_safety_lane.dart
    - scripts/release_preflight.sh
    - test/scripts/android_safety_lane_test.dart
    - test/architecture/android_toolchain_contract_test.dart
    - test/architecture/device_e2e_contract_test.dart
key-decisions:
  - "SIGN-A uses PHASE61_SIGNING_EVIDENCE only for the controlled evidence route; verified JDK 17 selection stays independent."
  - "Only the local API 36 google_apis arm64-v8a result can satisfy the Android stage; x86_64 remains supplemental."
patterns-established:
  - "Candidate identity is checked before preparation, before packaging, and at exit; a mismatch writes BLOCKED evidence only."
requirements-completed: [QA-03, QA-04]
coverage:
  - id: D1
    description: Candidate-bound Android evidence is persisted outside Git while the Phase 61 ledger remains byte-identical.
    requirement: QA-04
    verification:
      - kind: unit
        ref: flutter test test/scripts/android_safety_lane_test.dart test/architecture/android_toolchain_contract_test.dart -r expanded
        status: pass
    human_judgment: false
  - id: D2
    description: API 36 arm64 readiness, recursive discovery accounting, release hygiene, supplemental x86, and physical-device boundaries fail closed.
    requirement: QA-03
    verification:
      - kind: unit
        ref: flutter test test/scripts/android_safety_lane_test.dart test/architecture/android_toolchain_contract_test.dart test/architecture/device_e2e_contract_test.dart test/scripts/release_preflight_test.dart -r expanded
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-10
status: complete
---

# Phase 62 Plan 05: Android Candidate-Bound Evidence Summary

**Phase 62 now emits fail-closed, current-candidate Android evidence without altering Phase 61 history, while keeping local arm64 mandatory and x86/physical-device claims distinct.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-08-10T04:34:58Z
- **Completed:** 2026-08-10T04:46:58Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added a strict `--mode=phase62` Android adapter that accepts an exact candidate and ignored result path, checks provenance before every irreversible boundary, and persists privacy-safe JSON only under `build/release_gate/`.
- Kept the Phase 61 Markdown ledger byte-identical for both successful and candidate-mismatch evidence paths; Phase 62 uses existing emulator, integration discovery, bounded-command, and release-hygiene primitives without their historical write side effects.
- Made JDK 17/tool/image prerequisites explicit `BLOCKED` results, reject empty or incomplete recursive integration matrices, require post-test release hygiene, and prevent x86_64 evidence from satisfying arm64 or implying Android physical-device coverage.

## Task Commits

1. **Task 1: Emit Android evidence for the current candidate without mutating Phase 61** — `dae79c7d` (RED), `a83b76ce` (GREEN)
2. **Task 2: Lock local arm64 readiness, recursive execution, and supplemental classification** — `f4e68273` (RED), `3d570dcd` (GREEN), `c660ec3b` (ledger-failure regression)

## Files Created/Modified

- `scripts/verify_android_safety_lane.dart` — Phase 62 adapter, strict candidate CLI, readiness classification, non-mutating execution, and complete matrix enforcement.
- `scripts/release_preflight.sh` — separates the explicit evidence-signing switch from JDK selection.
- `test/scripts/android_safety_lane_test.dart` — provenance, ledger immutability, readiness, matrix, and classification mutations.
- `test/architecture/android_toolchain_contract_test.dart` — locks the SIGN-A independence contract.
- `test/architecture/device_e2e_contract_test.dart` — locks the primary arm64/supplemental x86/no-physical-device evidence boundary.

## Decisions Made

- SIGN-A repairs the legacy `PHASE61_GRADLE_JAVA_HOME` coupling by using `PHASE61_SIGNING_EVIDENCE` solely to activate the controlled signing-evidence route; JDK 17 still comes from the verified environment.
- An unavailable or failed x86_64 result is a named non-blocking limitation, never a substitute for the mandatory local arm64 result and never Android physical-device validation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Separated the preflight signing switch from JDK selection**
- **Found during:** Task 1
- **Issue:** The existing preflight script coupled `PHASE61_GRADLE_JAVA_HOME` to both JDK selection and special signing-evidence activation, contrary to selected SIGN-A.
- **Fix:** Replaced the coupling with the explicit `PHASE61_SIGNING_EVIDENCE` switch while retaining normal JDK selection through the verified process environment.
- **Files modified:** `scripts/release_preflight.sh`, `scripts/verify_android_safety_lane.dart`
- **Verification:** Android toolchain and preflight focused tests passed.
- **Committed in:** `a83b76ce`

**2. [Rule 1 - Bug] Corrected the Phase 62 privacy-pattern matcher**
- **Found during:** Task 1 GREEN verification
- **Issue:** Dart rejected an inline regex flag in the evidence privacy scan.
- **Fix:** Used the supported `caseSensitive: false` option.
- **Files modified:** `scripts/verify_android_safety_lane.dart`
- **Verification:** Focused adapter tests passed.
- **Committed in:** `a83b76ce`

**Total deviations:** 2 auto-fixed (1 Rule 2, 1 Rule 1).
**Impact on plan:** Both fixes were required to preserve the selected signing contract and fail-closed evidence validation; no product or device scope changed.

## Issues Encountered

The sandbox blocked Flutter's external SDK-cache refresh until elevated execution was approved. Rerun verification passed; no repository source or generated output was altered by the cache refresh.

## Known Stubs

None — the adapter returns `BLOCKED` when prerequisites are unavailable and does not use placeholder runtime evidence.

## User Setup Required

None - no external service configuration required. Android physical-device testing remains explicitly unavailable and unclaimed by this plan.

## Verification

- `flutter test test/scripts/android_safety_lane_test.dart test/architecture/android_toolchain_contract_test.dart test/architecture/device_e2e_contract_test.dart test/scripts/release_preflight_test.dart -r expanded` — passed.
- `flutter analyze` — passed with 0 issues.
- `flutter test -r expanded` — passed (exit 0).

## Next Phase Readiness

Plans 62-07 through 62-09 can consume candidate-bound Android JSON with mandatory arm64 evidence, explicit prerequisites, post-integration hygiene, and the retained supplemental/no-physical-device boundary.

## Self-Check: PASSED

- Confirmed the Android runner and all three focused test contracts exist.
- Confirmed task commits `dae79c7d`, `a83b76ce`, `f4e68273`, `3d570dcd`, and `c660ec3b` exist in Git history.

---
*Phase: 62-automated-release-gate-lock*
*Completed: 2026-08-10*
