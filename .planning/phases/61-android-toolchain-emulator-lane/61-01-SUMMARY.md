---
phase: 61-android-toolchain-emulator-lane
plan: "01"
subsystem: android-toolchain-safety
tags: [flutter, android, agp, gradle, kotlin, provenance]
requires:
  - phase: 60
    provides: Verified SQLCipher and iOS native safety lane
provides:
  - Fail-closed selected-or-hold Android graph verifier
  - Dated AGP 9.3.1 / Gradle 9.5.0 candidate metadata
  - Redacted compile/package/runtime/physical-device evidence schema
affects: [phase-61-candidate-probe, phase-62-release-gates, AND-01, AND-02]
actuals:
  tokens: 9000
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns:
    - Android candidates are evaluated in disposable workspaces before any selected graph changes
    - Terminal graph validation accepts only a complete selected graph or the exact last-green hold graph
key-files:
  created:
    - scripts/verify_android_safety_lane.dart
    - test/architecture/android_toolchain_contract_test.dart
    - test/scripts/android_safety_lane_test.dart
    - .planning/phases/61-android-toolchain-emulator-lane/61-ANDROID-SAFETY-EVIDENCE.md
  modified:
    - docs/testing/STABLE_BASELINE.json
key-decisions:
  - "The execution-date candidate is AGP 9.3.1 / Gradle 9.5.0 / JDK 17 / API 36, but selected files stay on AGP 8.11.1 / Gradle 8.14 / Kotlin 2.2.20 until a disposable probe passes."
  - "A hold must retain both Flutter AGP compatibility flags and record an attributable blocker plus exit condition."
  - "Resolved plugin KGP consumers are inventoried from generated metadata but never patched in Pub cache."
patterns-established:
  - "NOT_RUN is the durable default for costly evidence; research and host inspection cannot become PASS."
requirements-completed: [AND-01, AND-02]
coverage:
  - id: D1
    description: Candidate metadata, selected versions, minSdk 24, JDK 17, and official provenance form one validated policy.
    requirement: AND-01
    verification:
      - kind: unit
        ref: test/architecture/android_toolchain_contract_test.dart
        status: pass
    human_judgment: false
  - id: D2
    description: Mixed AGP/Kotlin states, missing hold flags, stale provenance, and unclassified evidence fail closed.
    requirement: AND-02
    verification:
      - kind: unit
        ref: test/scripts/android_safety_lane_test.dart
        status: pass
    human_judgment: false
  - id: D3
    description: The current source graph verifies as the exact pending hold without claiming candidate, release, or Emulator acceptance.
    requirement: AND-02
    verification:
      - kind: other
        ref: dart run scripts/verify_android_safety_lane.dart --mode=verify --allow-not-run
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-09
status: complete
---

# Phase 61 Plan 01: Android Safety Tracer Summary

**A fail-closed Android candidate-or-hold tracer now protects the selected graph before the disposable AGP 9 attempt begins.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-08-09T14:44:00Z
- **Completed:** 2026-08-09T14:52:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added mutation tests that reject stale candidate facts, partial AGP 9 states, missing hold flags, raised minSdk, wrong JDK, incomplete evidence, and sensitive durable fields.
- Implemented the mode-based Android lane verifier with exact terminal-state validation, evidence redaction, source hashing, and resolved-plugin KGP inventory.
- Refreshed official candidate metadata to AGP 9.3.1 / Gradle 9.5.0 while leaving every selected Android build input unchanged.

## Task Commits

1. **Task 1: specify Android safety lane contract** - `54b3612a` (test)
2. **Task 2: add Android safety lane verifier** - `9a33769f` (feat)

## Files Created/Modified

- `scripts/verify_android_safety_lane.dart` - Parses policy/evidence and rejects unsafe terminal states.
- `test/architecture/android_toolchain_contract_test.dart` - Exercises terminal graph and platform-floor mutations.
- `test/scripts/android_safety_lane_test.dart` - Exercises evidence schema, redaction, and mode behavior.
- `docs/testing/STABLE_BASELINE.json` - Records dated official candidate metadata and the pending hold decision.
- `61-ANDROID-SAFETY-EVIDENCE.md` - Starts every costly result class at `NOT_RUN` with the physical-device disclaimer.

## Decisions Made

- Kept the source-selected graph at the exact last-green AGP 8 combination until the isolated candidate proves the complete graph.
- Made every mixed graph invalid, including AGP 9 with legacy Kotlin, a hold missing either compatibility flag, or any unsupported JDK/minSdk value.
- Treated plugin metadata as inventory-only input; no Pub-cache, generated Flutter, or resolved-plugin source mutation is permitted.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The sandbox blocked Dart's telemetry/cache write during the verifier run; the same repository-owned command passed when rerun with the permitted tool environment. No project file or result changed.

## User Setup Required

None.

## Next Phase Readiness

- Plan 61-02 can now run the AGP 9.3.1 / Gradle 9.5.0 candidate only in a disposable source copy and must converge to either the complete candidate or the exact AGP 8 hold.
- Candidate, release, Emulator, and physical-device result classes remain `NOT_RUN` by design.

## Self-Check: PASSED

- Eight focused tests pass.
- `--mode=verify --allow-not-run` accepts the exact pending hold and no migrated state.
- Selected Android source inputs are byte-identical to their pre-plan versions.

---
*Phase: 61-android-toolchain-emulator-lane*
*Completed: 2026-08-09*
