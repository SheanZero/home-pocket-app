---
phase: 60-sqlcipher-ios-native-safety-lane
plan: "08"
subsystem: ios-native-linkage
tags: [flutter, ios, xcode, swiftpm, sqlcipher, architecture-tests]
requires:
  - phase: 60-07
    provides: Phase 60 native-safety evidence and the blocked lifecycle gate
provides:
  - Locked Flutter 3.44.8 AppDelegate launch lifecycle contract
  - Singular Runner generated Swift-package product wiring guard
  - Clean Debug-Simulator compile/link diagnosis with compile/runtime separation
affects: [60-09, 60-10, SEC-02, SEC-03]
actuals:
  tokens: 3394
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns:
    - Source-controlled iOS lifecycle seams guarded with focused mutation cases
    - Clean Flutter regeneration is evidence; ephemeral generated edits are prohibited
key-files:
  created:
    - test/architecture/ios_native_linkage_contract_test.dart
    - .planning/phases/60-sqlcipher-ios-native-safety-lane/60-NATIVE-LINKAGE-DIAGNOSIS.md
  modified:
    - ios/Runner/AppDelegate.swift
key-decisions:
  - "The historical linker failure did not reproduce from clean artifacts, so it is attributed only to stale/generated native state; the missing launch override is recorded as separate template drift."
  - "Runner project wiring remains unchanged because its generated Swift-package product and target dependency were already singular."
patterns-established:
  - "Native-linkage contracts validate both live source and focused missing/duplicate mutations."
requirements-completed: [SEC-02, SEC-03]
coverage:
  - id: D1
    description: Locked Flutter AppDelegate launch and implicit-engine registration seams are restored and guarded.
    requirement: SEC-02
    verification:
      - kind: unit
        ref: test/architecture/ios_native_linkage_contract_test.dart#AppDelegate contract and mutations
        status: pass
    human_judgment: false
  - id: D2
    description: Runner links exactly one generated Flutter Swift-package product and declares one target dependency.
    requirement: SEC-02
    verification:
      - kind: unit
        ref: test/architecture/ios_native_linkage_contract_test.dart#Runner Frameworks mutations
        status: pass
    human_judgment: false
  - id: D3
    description: A clean supported unsigned Debug-Simulator Flutter build compiles and links Runner.
    requirement: SEC-03
    verification:
      - kind: other
        ref: flutter build ios --simulator --debug --no-codesign
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-08-09
status: complete
---

# Phase 60 Plan 08: Native Linkage Repair Summary

**Locked Flutter AppDelegate lifecycle restoration, mutation-guarded Swift-package wiring, and a clean unsigned Debug-Simulator compile/link pass**

## Performance

- **Duration:** 6 min
- **Started:** 2026-08-09T22:12:47+09:00
- **Completed:** 2026-08-09T13:18:53Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Restored the Flutter 3.44.8 launch override while preserving implicit-engine generated plugin registration.
- Added focused missing/duplicate mutation coverage for every AppDelegate and Runner package-product linkage seam.
- Proved a clean unsigned Debug-Simulator compile/link path and recorded that the historical linker failure did not reproduce; runtime remains explicitly unclaimed.

## Task Commits

1. **Task 1 RED: expose missing launch lifecycle** - `9efcbfdd` (test)
2. **Task 1 GREEN: restore locked launch lifecycle** - `78d18603` (fix)
3. **Task 2 RED: add linkage mutation cases** - `2973f9d1` (test)
4. **Task 2 GREEN: lock every native linkage seam** - `3766265a` (test)

## Files Created/Modified

- `ios/Runner/AppDelegate.swift` - Restores locked Flutter launch delegation.
- `test/architecture/ios_native_linkage_contract_test.dart` - Guards AppDelegate and Runner Swift-package wiring with focused mutations.
- `.planning/phases/60-sqlcipher-ios-native-safety-lane/60-NATIVE-LINKAGE-DIAGNOSIS.md` - Records before/after commands, toolchain, source inventory, and evidence limits.

## Decisions Made

- Did not change `project.pbxproj`; clean evidence showed singular Runner Frameworks and target-dependency membership.
- Did not claim the restored override caused the historical failure, because the clean pre-repair build already exited zero.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced nonexistent notification contract paths with their canonical owners**
- **Found during:** Task 2
- **Issue:** `notification_stack_release_contract_test.dart` and `no_apns_uat_contract_test.dart` do not exist.
- **Fix:** Ran the existing dependency-compatibility, first-release, and iOS UAT identity contracts that own notification removal and no-APNs invariants.
- **Files modified:** None for the substitution; the diagnosis records the mapping.
- **Verification:** Focused architecture suite passed 103 tests.
- **Committed in:** `3766265a`

**2. [Rule 1 - Bug] Corrected the initial PBX object parser before the RED commit**
- **Found during:** Task 1 RED
- **Issue:** The first Dart regular expression used an unsupported group construct, adding an unrelated parser failure.
- **Fix:** Replaced it with section-bounded PBX object parsing so RED failed only for the missing launch override.
- **Files modified:** `test/architecture/ios_native_linkage_contract_test.dart`
- **Verification:** Package-product test passed while the intended AppDelegate assertion failed.
- **Committed in:** `9efcbfdd`

---

**Total deviations:** 2 auto-fixed (1 blocking plan-path defect, 1 test bug).  
**Impact on plan:** Evidence is stronger and remains within the planned iOS linkage scope; no dependency, schema, or generated-file change was introduced.

## Issues Encountered

- The first native command was stopped by workspace sandbox access to the shared Flutter SDK cache before Xcode ran. It was rerun with the required SDK-cache permission and excluded from native evidence.
- The historical undefined-symbol state did not reproduce. The diagnosis records an empty observed undefined-symbol set instead of fabricating a root cause.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The Debug-Simulator compile/link tracer is green and plan 60-09 can run the retained/from-zero compile-only matrix.
- Booted-Simulator SQLCipher runtime evidence is still unproved and remains reserved for plan 60-10.

## Self-Check: PASSED

- Created files exist.
- Four `60-08` task commits exist.
- Focused architecture suite passed 103 tests.
- Clean `flutter build ios --simulator --debug --no-codesign` exited zero.
- `git diff --check` passed before close-out.

---
*Phase: 60-sqlcipher-ios-native-safety-lane*
*Completed: 2026-08-09*
