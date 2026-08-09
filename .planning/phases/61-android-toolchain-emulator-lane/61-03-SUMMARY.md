---
phase: 61-android-toolchain-emulator-lane
plan: "03"
subsystem: android-terminal-graph
tags: [android, gradle, jdk17, api36, x86_64, ci]
requires:
  - phase: 61-02
    provides: Evidence-backed exact AGP 8 hold decision
provides:
  - Canonical fail-closed Android terminal-graph validation
  - Clean debug APK compile under verified JDK 17
  - API 36 x86_64 full integration-suite workflow declaration
affects: [phase-61-release, phase-61-emulator, phase-62-release-gates, AND-01, AND-02, AND-04]
actuals:
  tokens: 12000
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns:
    - The compatibility contract branches on the baseline terminal decision and rejects partial hold/selected graphs
    - Workflow declaration and host compilation remain separate from Emulator runtime evidence
key-files:
  created: []
  modified:
    - scripts/dependency_compatibility.dart
    - test/architecture/dependency_compatibility_contract_test.dart
    - .github/workflows/device-e2e.yml
    - test/architecture/device_e2e_contract_test.dart
    - test/architecture/android_toolchain_contract_test.dart
    - .planning/phases/61-android-toolchain-emulator-lane/61-ANDROID-SAFETY-EVIDENCE.md
key-decisions:
  - "Compile evidence is accepted only from direct Gradle launcher and daemon output proving JDK 17; Flutter's host-selected JBR 21 run is excluded."
  - "API 36 x86_64 executes the complete integration_test directory and a clean post-test Android release preflight."
  - "The checked-in Android build inputs remain byte-identical to the selected hold graph."
patterns-established:
  - "Android compile, target, minSdk, Java, AGP, Gradle, Kotlin, opt-out, and plugin-inventory components are independently mutation-tested."
requirements-completed: [AND-01, AND-02, AND-04]
coverage:
  - id: D1
    description: Canonical compatibility validation rejects AGP, Gradle, Kotlin, opt-out, minSdk, compile/target API, JDK, and terminal-decision drift.
    requirement: AND-02
    verification:
      - kind: unit
        ref: test/architecture/dependency_compatibility_contract_test.dart
        status: pass
      - kind: other
        ref: dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk
        status: pass
    human_judgment: false
  - id: D2
    description: The exact held graph cleanly assembles a debug APK with Gradle 8.14 launcher and daemon on verified Temurin JDK 17.
    requirement: AND-01
    verification:
      - kind: integration
        ref: ./gradlew --no-daemon -Dorg.gradle.java.home=<verified-jdk17> clean :app:assembleDebug
        status: pass
    human_judgment: false
  - id: D3
    description: Device E2E pins Flutter 3.44.8, JDK 17, API 36 x86_64, every integration test, and clean post-test release regeneration without claiming execution.
    requirement: AND-04
    verification:
      - kind: unit
        ref: test/architecture/device_e2e_contract_test.dart
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-08-09
status: complete
---

# Phase 61 Plan 03: Terminal Graph and API 36 Lane Summary

**The exact AGP 8 hold is now a canonical compatibility invariant, compiles under verified JDK 17, and has a reproducible API 36 x86_64 full-suite declaration.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-08-09T15:06:00Z
- **Completed:** 2026-08-09T15:18:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Extended the baseline validator to reject every partial hold/selected mutation across AGP, Gradle, Kotlin, flags, platform floors, JDK, and legacy plugin inventory.
- Cleanly assembled the debug APK with Gradle 8.14 launcher and daemon both reporting Temurin 17.0.20.
- Updated device E2E to API 36 x86_64, locked retrieval, the full five-file integration inventory, and clean post-test release regeneration while preserving `NOT_RUN` runtime evidence.

## Task Commits

1. **Task 1: lock the terminal Android graph** - `5870a04e` (test)
2. **Task 2: declare the API 36 Android lane** - `237d5629` (ci)

## Files Created/Modified

- `scripts/dependency_compatibility.dart` - Adds canonical terminal Android graph validation.
- `test/architecture/dependency_compatibility_contract_test.dart` - Adds atomic graph and platform-floor mutations.
- `.github/workflows/device-e2e.yml` - Moves the Android job to API 36 x86_64 and locked full-suite execution.
- `test/architecture/device_e2e_contract_test.dart` - Locks job versions, ABI, command, cleanup, and integration-file inventory.
- `test/architecture/android_toolchain_contract_test.dart` - Advances strict evidence-stage mutation coverage.
- `61-ANDROID-SAFETY-EVIDENCE.md` - Records attributable JDK 17 compile PASS and keeps hosted Emulator execution NOT_RUN.

## Decisions Made

- Did not count a successful Flutter-driven build that selected Android Studio JBR 21; only the direct Gradle run with launcher and daemon proven at JDK 17 is durable compile evidence.
- Kept workflow presence as declaration-only, not runtime proof.
- Left all selected Android source inputs unchanged because Plan 02 chose the exact hold.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Bypassed Flutter's JBR precedence for attributable JDK evidence**
- **Found during:** Task 2 compile proof
- **Issue:** Flutter selected Android Studio JBR 21 despite `JAVA_HOME`, so the first successful APK could not satisfy the JDK 17 contract.
- **Fix:** Reran the wrapper directly with `org.gradle.java.home` and `--no-daemon`; both launcher and single-use daemon reported Temurin 17.0.20 before a clean successful assembly.
- **Verification:** Gradle `--version` and `BUILD SUCCESSFUL` evidence are recorded; the JBR 21 run is excluded.
- **Committed in:** `237d5629`

---

**Total deviations:** 1 auto-fixed blocking host-precedence issue.
**Impact on plan:** Stronger runtime attribution; no source graph or scope change.

## Issues Encountered

- The held graph emits expected deprecation warnings for legacy Kotlin/Gradle APIs, consistent with the recorded AGP 9 blocker; compilation still passed.

## User Setup Required

None.

## Next Phase Readiness

- The exact graph is ready for non-debug signed AAB/APK packaging and artifact hygiene in Plan 61-04.
- Emulator execution remains unclaimed until Plan 61-05.

## Self-Check: PASSED

- Canonical baseline validator passes under the pinned Flutter identity.
- Focused terminal-graph and device-lane tests pass with no analyzer issues.
- Strict Android safety verification passes at compile stage.

---
*Phase: 61-android-toolchain-emulator-lane*
*Completed: 2026-08-09*
