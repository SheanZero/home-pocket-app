---
phase: 60-sqlcipher-ios-native-safety-lane
plan: "01"
subsystem: testing
tags: [sqlcipher, sqlite3, native-assets, swiftpm, ios, compatibility]
requires:
  - phase: 57-stable-baseline-compatibility-contract
    provides: Stable baseline manifest and dependency compatibility validator
  - phase: 58-flutter-analyzer-code-generation-lane
    provides: iOS 15 source-floor contract and generated SwiftPM mismatch finding
provides:
  - Exact Native Assets graph and prohibition contract
  - Generated Swift package iOS-floor validator input
  - Cross-artifact Phase 60 compatibility wording
affects: [60-02, 60-07, release-gates, iOS-native-safety]
actuals:
  tokens: 3800
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: [injected generated Swift package manifest validation, compile-only evidence labels]
key-files:
  created: []
  modified:
    - scripts/dependency_compatibility.dart
    - test/architecture/dependency_compatibility_contract_test.dart
    - docs/testing/STABLE_BASELINE.json
    - docs/testing/DEPENDENCY_COMPATIBILITY.md
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
key-decisions:
  - "Generated Flutter Swift package inspection is an explicit CLI input and remains compile-only, never runtime encryption proof."
  - "Phase 60 selects Drift 2.34.0, sqlite3 3.5.1, and SQLCipher Native Assets 4.17.x while rejecting every legacy native substitution."
patterns-established:
  - "Native safety validators accept generated artifacts only as injected post-generation evidence."
  - "iOS compile evidence, generated-floor proof, and Simulator runtime proof use distinct labels."
requirements-completed: [SEC-01, SEC-02]
coverage:
  - id: D1
    description: Exact Native Assets graph rejects declaration, lock, hook, Pod, linker, and generated-floor mutations.
    requirement: SEC-01
    verification:
      - kind: unit
        ref: flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/ios_minimum_version_contract_test.dart
        status: pass
    human_judgment: false
  - id: D2
    description: Planning, readable, and machine contracts name one Native Assets lane and separate compile-only from runtime evidence.
    requirement: SEC-02
    verification:
      - kind: other
        ref: dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk
        status: pass
      - kind: other
        ref: git diff --exit-code -- docs/arch/03-adr/ADR-002_Database_Solution.md
        status: pass
    human_judgment: false
duration: 4m
completed: 2026-08-09
status: complete
---

# Phase 60 Plan 01: Native Assets Compatibility Contract Summary

**Exact Drift 2.34.0/sqlite3 3.5.1/SQLCipher Native Assets 4.17.x policy with fail-closed source, lock, native, and generated Swift package floor checks.**

## Performance

- **Duration:** 4m
- **Started:** 2026-08-09T05:19:19Z
- **Completed:** 2026-08-09T05:23:51Z
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added independent mutations for wrong Drift/sqlite3 declarations and locks, both retired Flutter libraries, SQLCipher hook loss, CocoaPod restoration, linker-strip restoration, and generated Swift package floor drift.
- Added `--generated-swift-package-manifest=<path>` to the existing validator. A supplied manifest below iOS 15 fails closed; omitted input is explicitly reported as compile-only and not generated-floor or runtime proof.
- Replaced stale Phase 60 contracts with the exact Native Assets lane, retained-lock/from-zero resolution requirement, iOS 15 generated-floor requirement, six unsigned build boundary, and distinct Simulator runtime evidence.

## Task Commits

1. **Task 1: Trace one forbidden native substitution through the executable compatibility gate** - `883b770f` (test) and `2ab9d8b4` (feat)
2. **Task 2: Correct all stale readable and machine compatibility contracts as one lane** - `59ec0c50` (docs)

## Files Created/Modified

- `scripts/dependency_compatibility.dart` - validates injected generated Swift package deployment floors and reports compile-only evidence boundaries.
- `test/architecture/dependency_compatibility_contract_test.dart` - covers each independent prohibited Native Assets substitution.
- `docs/testing/STABLE_BASELINE.json` - records the selected Native Assets graph, prohibitions, and exit evidence boundary.
- `docs/testing/DEPENDENCY_COMPATIBILITY.md` - documents the reproducibility, iOS-floor, and runtime-proof contract.
- `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` - reconcile Phase 60 SC-1/SC-2 and SEC-01/SEC-02.

## Decisions Made

- Generated `Package.swift` is never edited or accepted by implication: later supported regeneration must deliberately supply its manifest to the shared validator.
- Compilation is labelled compile-only; only separately recorded Simulator runtime evidence can support SQLCipher encryption claims.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Kept the machine lane string synchronized with the corrected baseline.**
- **Found during:** Task 2
- **Issue:** The validator still expected the superseded singular `SQLCipher Native Asset 4.17` text after the canonical baseline was corrected to `SQLCipher Native Assets 4.17.x`.
- **Fix:** Updated the validator's exact lane member and CLI output together with the baseline.
- **Files modified:** `scripts/dependency_compatibility.dart`
- **Verification:** Targeted architecture tests and the baseline validator passed.
- **Committed in:** `59ec0c50`

---

**Total deviations:** 1 auto-fixed (Rule 2)
**Impact on plan:** Required to keep the machine and readable contracts coherent; no dependency or generated-output change was made.

## Verification

- `flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/ios_minimum_version_contract_test.dart` — PASS (92 tests)
- `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` — PASS (0 errors, 0 warnings)
- `git diff --exit-code -- docs/arch/03-adr/ADR-002_Database_Solution.md` — PASS (no ADR diff)
- `git diff --check` — PASS

## Known Stubs

None.

## Self-Check: PASSED

- All six modified task files and this summary exist.
- All three task commits (`883b770f`, `2ab9d8b4`, `59ec0c50`) exist.
- No task commit deleted tracked files; no stub patterns were found in the task artifacts.

## Next Phase Readiness

- Plan 60-02 can supply the manifest produced by supported Flutter regeneration to the shared CLI; the current on-disk generated manifest remains intentionally untouched.
- The generated-package input is compile-only and leaves SQLCipher Simulator runtime acceptance for the subsequent native-evidence plans.

---
*Phase: 60-sqlcipher-ios-native-safety-lane*
*Completed: 2026-08-09*
