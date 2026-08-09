---
phase: 61-android-toolchain-emulator-lane
plan: "02"
subsystem: android-toolchain-safety
tags: [android, agp, gradle, kotlin, jdk17, disposable-probe]
requires:
  - phase: 61-01
    provides: Fail-closed Android selected-or-hold tracer and evidence schema
provides:
  - Contamination-proof disposable AGP 9 candidate probe
  - Observed Flutter 3.44.8 built-in-Kotlin incompatibility evidence
  - Exact AGP 8.11.1 / Gradle 8.14 / Kotlin 2.2.20 terminal hold
affects: [phase-61-release, phase-61-emulator, phase-62-release-gates, AND-01, AND-02]
actuals:
  tokens: 16000
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns:
    - Candidate build inputs are applied only to a unique git-archive workspace
    - JDK archives are accepted only after published SHA-256 verification
    - A successful configuration command can prove incompatibility when the tool restores prohibited compatibility flags
key-files:
  created: []
  modified:
    - scripts/verify_android_safety_lane.dart
    - test/scripts/android_safety_lane_test.dart
    - test/architecture/android_toolchain_contract_test.dart
    - docs/testing/STABLE_BASELINE.json
    - docs/testing/DEPENDENCY_COMPATIBILITY.md
    - .planning/phases/61-android-toolchain-emulator-lane/61-ANDROID-SAFETY-EVIDENCE.md
key-decisions:
  - "AGP 9.3.1 is incompatible with the selected Flutter 3.44.8 identity because Flutter restores both legacy opt-outs and officially requires Flutter 3.47+ for built-in Kotlin."
  - "file_picker, package_info_plus, share_plus, and speech_to_text remain separately observed legacy-KGP blockers in the exact resolved graph."
  - "The terminal source graph remains AGP 8.11.1 / Gradle 8.14 / Kotlin 2.2.20 with both opt-outs and minSdk 24."
patterns-established:
  - "Every candidate command has bounded/redacted output, timeout classification, source/plugin before-after digests, and unconditional temp cleanup."
requirements-completed: [AND-01, AND-02]
coverage:
  - id: D1
    description: The complete AGP 9.3.1 / Gradle 9.5.0 / built-in-Kotlin transaction is constructed atomically in a disposable workspace and leaves source/plugin inputs unchanged.
    requirement: AND-01
    verification:
      - kind: unit
        ref: test/scripts/android_safety_lane_test.dart
        status: pass
    human_judgment: false
  - id: D2
    description: Verified JDK 17 locked retrieval and Flutter configuration capture the observed opt-out restoration without treating command exit zero as candidate acceptance.
    requirement: AND-01
    verification:
      - kind: integration
        ref: dart run scripts/verify_android_safety_lane.dart --mode=candidate-probe
        status: pass
    human_judgment: false
  - id: D3
    description: Strict verification accepts only the exact evidence-backed hold, named blocker inventory, and non-circular Flutter 3.47+/Phase 59 exit gate.
    requirement: AND-02
    verification:
      - kind: unit
        ref: test/architecture/android_toolchain_contract_test.dart
        status: pass
      - kind: other
        ref: dart run scripts/verify_android_safety_lane.dart --mode=verify
        status: pass
    human_judgment: false
duration: 13min
completed: 2026-08-09
status: complete
---

# Phase 61 Plan 02: Disposable AGP 9 Decision Summary

**The current AGP 9 candidate was attempted under verified JDK 17 and cleanly converged to the exact AGP 8 hold with no source or cache contamination.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-08-09T14:52:00Z
- **Completed:** 2026-08-09T15:05:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Implemented an interruption-safe candidate runner that archives tracked source into a unique temporary directory, applies every AGP 9/Kotlin/new-DSL edit together, bounds and redacts process output, verifies input digests, and always cleans up.
- Verified official Temurin JDK 17.0.20 against Adoptium's published SHA-256, then ran locked dependency retrieval and the bounded Flutter Android configuration command.
- Observed Flutter 3.44.8 restore both prohibited legacy opt-outs, inventoried four exact legacy-KGP plugin blockers, and sealed the last-green AGP 8 graph with a machine-checkable exit condition.

## Task Commits

1. **Task 1: make candidate probing disposable and contamination-proof** - `ab6c25a4` (feat)
2. **Task 2: seal observed terminal hold and exit condition** - `ad80f5a8` (docs)

## Files Created/Modified

- `scripts/verify_android_safety_lane.dart` - Adds atomic candidate mutation, verified-JDK selection, bounded execution, input digests, cleanup, and evidence recording.
- `test/scripts/android_safety_lane_test.dart` - Covers coupled mutations, incomplete inputs, success/failure cleanup, output bounds/redaction, and JDK parsing.
- `test/architecture/android_toolchain_contract_test.dart` - Requires the observed blocker set and non-circular exit gate.
- `docs/testing/STABLE_BASELINE.json` - Changes the Phase 61 reason from pending to the actual evidence-backed hold.
- `docs/testing/DEPENDENCY_COMPATIBILITY.md` - Records the current AGP candidate, attempt, result, selected graph, and exit transaction.
- `61-ANDROID-SAFETY-EVIDENCE.md` - Captures source/times/commands/result/inventory and unchanged-input evidence without local paths or credentials.

## Decisions Made

- Classified the candidate as `INCOMPATIBLE`, not `PASS`, even though configuration exited zero: the command restored compatibility flags that are forbidden in the selected AGP 9 graph.
- Required both a reviewed Flutter 3.47+ identity transaction and Phase 59-approved non-KGP plugin releases before any re-probe.
- Preserved minSdk 24 and every selected Android file byte-for-byte.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical] Added staged evidence validation**
- **Found during:** Task 2 strict verification
- **Issue:** The initial verifier required compile/package/Emulator PASS before those later plans could execute, so Plan 02 could not strictly verify its own terminal decision.
- **Fix:** Added monotonic `completed_stage` validation: candidate evidence is strict now, while compile/package/Emulator become mandatory only at their owning stages.
- **Verification:** Mutation tests reject a compile stage without compile PASS; current candidate stage passes strict verification.
- **Committed in:** `ad80f5a8`

**2. [Rule 1 - Bug] Corrected host provenance**
- **Found during:** Task 2 evidence review
- **Issue:** The first host string used the Dart VM version instead of the macOS product version.
- **Fix:** Record `sw_vers -productVersion` plus `uname -m`; corrected the durable record to macOS 26.5.1 arm64.
- **Verification:** Evidence schema and redaction tests pass.
- **Committed in:** `ad80f5a8`

---

**Total deviations:** 2 auto-fixed (1 missing critical gate, 1 provenance bug).
**Impact on plan:** Both fixes strengthen attribution and staged fail-closed behavior without changing the selected graph or scope.

## Issues Encountered

- No installed JDK 17 was available. A temporary official Temurin archive was downloaded, matched its published SHA-256, and was used only from `/private/tmp`.

## User Setup Required

None.

## Next Phase Readiness

- The terminal graph is unambiguous and ready for Plan 61-03 compilation/contract locking.
- Release package and Emulator results remain `NOT_RUN`; physical Android hardware remains explicitly not performed or claimed.

## Self-Check: PASSED

- Fifteen focused tests pass and targeted Dart analysis reports no issues.
- Strict `--mode=verify` passes at candidate stage.
- No candidate directory remains and selected Android/Pub/plugin inputs are unchanged.

---
*Phase: 61-android-toolchain-emulator-lane*
*Completed: 2026-08-09*
