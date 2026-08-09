---
phase: 60-sqlcipher-ios-native-safety-lane
plan: "09"
subsystem: ios-native-safety
tags: [flutter, ios, xcode, swiftpm, sqlcipher, compile-evidence]
requires:
  - phase: 60-08
    provides: Clean Flutter/Xcode native linkage and locked AppDelegate lifecycle
provides:
  - Deterministic compile-only native safety lane with a null runtime path
  - Exact retained-lock/from-zero graph and generated iOS 15 floor evidence
  - Six passing unsigned Runner configuration/destination compile records
affects: [60-10, SEC-02, SEC-03]
actuals:
  tokens: 11679
  tasks: 2
  commits: 6
tech-stack:
  added: []
  patterns:
    - Compile and runtime evidence use separate CLI contracts and result classes
    - Unsupported Flutter Simulator AOT modes use explicit Debug artifact preparation while retaining the requested Xcode configuration
key-files:
  created: []
  modified:
    - scripts/verify_ios_native_safety_lane.dart
    - test/architecture/ios_minimum_version_contract_test.dart
    - ios/Runner.xcodeproj/project.pbxproj
    - docs/testing/STABLE_BASELINE.json
    - .planning/phases/60-sqlcipher-ios-native-safety-lane/60-NATIVE-SAFETY-EVIDENCE.md
    - .planning/phases/60-sqlcipher-ios-native-safety-lane/60-VALIDATION.md
key-decisions:
  - "Runner target configurations explicitly own the iOS 15 floor so supported Flutter generation exports .iOS(\"15.0\") without editing ephemeral output."
  - "Profile/Release Simulator rows prove their Xcode Runner configurations only; Flutter artifact preparation is forced to supported Debug mode and is never described as Profile/Release runtime or AOT proof."
  - "The compile lane rejects runtime-test input and skips the Simulator runtime function entirely."
patterns-established:
  - "Every native matrix record names configuration, destination class, signing state, artifact-mode override, exit code, and evidence class."
requirements-completed: [SEC-02]
coverage:
  - id: D1
    description: Retained locks and disposable from-zero resolution select the exact D-01 native graph and generated iOS 15 floor.
    requirement: SEC-02
    verification:
      - kind: integration
        ref: dart run scripts/verify_ios_native_safety_lane.dart --lane=compile#retained-and-disposable-graph
        status: pass
    human_judgment: false
  - id: D2
    description: Debug, Profile, and Release compile unsigned for generic Simulator and generic device destinations.
    requirement: SEC-02
    verification:
      - kind: integration
        ref: dart run scripts/verify_ios_native_safety_lane.dart --lane=compile#six-build-matrix
        status: pass
      - kind: unit
        ref: test/architecture/ios_minimum_version_contract_test.dart#compile-lane-matrix
        status: pass
    human_judgment: false
  - id: D3
    description: Compile evidence has a null runtime test, no runtime invocation, and no runtime-success result.
    requirement: SEC-02
    verification:
      - kind: unit
        ref: test/architecture/ios_minimum_version_contract_test.dart#compile-lane-runtime-separation
        status: pass
      - kind: other
        ref: build/native_safety_evidence.json#runtime_test-null-and-no-runtime-records
        status: pass
    human_judgment: false
duration: 19min
completed: 2026-08-09
status: complete
---

# Phase 60 Plan 09: Deterministic Compile Evidence Summary

**Exact retained/from-zero SQLCipher graph convergence, generated iOS 15 floors, and six passing unsigned Xcode configuration/destination builds with no runtime claim**

## Performance

- **Duration:** 19 min
- **Started:** 2026-08-09T22:26:00+09:00
- **Completed:** 2026-08-09T22:45:21+09:00
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `--lane=compile`, which accepts no runtime test, performs retained and disposable resolution, runs the exact six-build matrix, and never calls Simulator runtime.
- Made the Runner iOS 15 floor effective in every target configuration; supported Flutter regeneration now produces `.iOS("15.0")` in retained and disposable generated manifests.
- Recorded a clean PASS at source `570064236eead5e9bdbd8567f8c866bf9d48aa99`: both graphs select Drift 2.34.0 / sqlite3 3.5.1 / SQLCipher 4.17.x with identical digest, and all six unsigned build records exit zero.

## Task Commits

1. **Task 1 RED: expose missing compile lane and iOS floor** - `dfe063e6` (test)
2. **Task 1 GREEN: add compile lane and six-build matrix** - `c2b6e50e` (feat)
3. **Task 1 baseline: synchronize canonical Xcode input digest** - `13612e3c` (chore)
4. **Task 1 RED: expose Simulator artifact-mode constraint** - `3e4430ac` (test)
5. **Task 1 GREEN: compile Profile/Release Simulator configurations honestly** - `57006423` (fix)
6. **Task 2: publish exact compile evidence** - `1b4192f2` (docs)

## Files Created/Modified

- `scripts/verify_ios_native_safety_lane.dart` - Adds compile CLI semantics, exact graph/floor checks, provenance, six serial unsigned builds, and runtime isolation.
- `test/architecture/ios_minimum_version_contract_test.dart` - Guards the Runner floor, compile parser/control flow, matrix, signing, and Simulator artifact-mode constraint.
- `ios/Runner.xcodeproj/project.pbxproj` - Gives standard Runner Debug/Profile/Release configurations an explicit iOS 15 deployment target.
- `docs/testing/STABLE_BASELINE.json` - Synchronizes the reviewed Xcode source digest after the explicit floor change.
- `60-NATIVE-SAFETY-EVIDENCE.md` - Publishes the source commit, timestamp, toolchain, graph digest, floors, and six exact results.
- `60-VALIDATION.md` - Marks SEC-02 passing while keeping SEC-03 pending plan 60-10.

## Decisions Made

- Kept generated `Package.swift` read-only. The source-owned Runner floor is now visible to Flutter's supported generator.
- Classified Simulator Profile/Release as Xcode-configuration compile checks with Debug Flutter artifact preparation. This is the only supported Flutter Simulator packaging mode and remains explicitly compile-only.
- Preserved `full` as compile-plus-runtime orchestration while making `compile` structurally incapable of a runtime call.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Mapped nonexistent plan paths to canonical repository owners**
- **Found during:** Task 1
- **Issue:** `scripts/validate_ios_generated_manifest.dart` and `tool/pubspec.lock` do not exist.
- **Fix:** Reused the canonical `scripts/dependency_compatibility.dart` generated-manifest validator and root `pubspec.lock`.
- **Files modified:** None for the mapping.
- **Verification:** Canonical validator passed with the generated retained manifest and the final lane passed both graph modes.
- **Committed in:** `c2b6e50e`

**2. [Rule 3 - Blocking] Made the source iOS floor effective for Flutter generation**
- **Found during:** Task 1 RED and the first evidence attempt
- **Issue:** Standard Runner target configurations lacked an explicit deployment target, so Flutter generated iOS 13 despite project-level iOS 15 declarations; adding the target floor then correctly tripped the canonical tracked-input digest.
- **Fix:** Added iOS 15 to the three standard Runner target configurations and synchronized the reviewed baseline digest.
- **Files modified:** `ios/Runner.xcodeproj/project.pbxproj`, `docs/testing/STABLE_BASELINE.json`
- **Verification:** Both retained and disposable generated manifests report iOS 15+; the canonical validator passes.
- **Committed in:** `c2b6e50e`, `13612e3c`

**3. [Rule 1 - Bug] Adapted non-Debug Simulator compile rows to Flutter's supported artifact mode**
- **Found during:** Task 2 real matrix execution
- **Issue:** Runner Profile on generic Simulator failed because Flutter rejects profile/release AOT packaging for Simulator before Xcode compilation.
- **Fix:** Retained the requested Runner Xcode configuration while setting `FLUTTER_BUILD_MODE=debug` only for Profile/Release Simulator rows; evidence records the override and refuses runtime/AOT language.
- **Files modified:** `scripts/verify_ios_native_safety_lane.dart`, `test/architecture/ios_minimum_version_contract_test.dart`
- **Verification:** A manual Profile diagnostic and the final checked-in six-build lane both exited zero.
- **Committed in:** `3e4430ac`, `57006423`

---

**Total deviations:** 3 auto-fixed (2 blocking plan/environment contracts, 1 runtime-discovered build bug).  
**Impact on plan:** All changes are required to produce honest, reproducible SEC-02 evidence; no dependency, app schema, generated source, runtime behavior, signing, or physical-device scope was added.

## Issues Encountered

- The first lane attempt failed closed because the canonical baseline still held the pre-floor Xcode digest. Updating that reviewed digest made the validator green.
- The second lane attempt failed at Profile Simulator and produced a large redacted Xcode diagnostic. The supported artifact-mode adjustment was regression-tested before the complete lane was rerun.
- Two zero-byte stale `.git/index.lock` files were left without an owning process and removed before scoped commits.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- SEC-02 compile convergence is complete and durable.
- Plan 60-10 can now run the current-schema lifecycle on a booted Simulator; SEC-03 remains pending and cannot be inferred from these compile results.

## Self-Check: PASSED

- Six `matrix-*` records exist, are unique, are `COMPILE_ONLY`, and exit zero.
- Retained/disposable selected graphs and normalized graph digests match.
- Both generated manifest floor records are iOS 15+.
- `runtime_test` is null and no runtime result exists.
- Focused architecture suite passes 23 tests and `git diff --check` passes.

---
*Phase: 60-sqlcipher-ios-native-safety-lane*
*Completed: 2026-08-09*
