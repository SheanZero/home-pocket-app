---
phase: 57-stable-baseline-compatibility-contract
plan: "02"
subsystem: infra
tags: [flutter, dart, compatibility-contract, sqlcipher, ci, android]
requires:
  - "57-01 stable baseline manifest and repository input adapters"
provides:
  - "Immutable compatibility reports with deterministic errors and warnings"
  - "Fail-closed negative fixture matrix for policy, crypto, lane, and platform drift"
  - "Strict baseline/future-probe CLI mode parser with SDK identity verification"
affects: [57-03, 58-flutter-analyzer-code-generation, 59-platform-plugin-cohorts, 60-sqlcipher-ios-native-safety, 61-android-host-migration, 62-baseline-reproduction]
tech-stack:
  added: []
  patterns:
    - "Pure validator inputs and immutable report values keep concurrent checks invocation-local"
    - "Only ordinary dependency candidate drift is advisory in future-probe mode"
key-files:
  created: []
  modified:
    - scripts/dependency_compatibility.dart
    - test/architecture/dependency_compatibility_contract_test.dart
decisions:
  - "No argument aliases baseline; malformed or duplicate mode arguments are usage failures with exit code 2."
  - "Future-probe may warn only for non-SQLCipher direct-dependency candidate prerelease drift; security and floor diagnostics remain errors."
metrics:
  duration: 11min
  completed: 2026-08-05
status: complete
actuals:
  tokens: 6669
  tasks: 2
  commits: 4
---

# Phase 57 Plan 02: Fail-Closed Compatibility Report Modes Summary

**A deterministic, read-only dependency contract now rejects unsafe baseline states while preserving a narrowly advisory future-probe path.**

## Accomplishments

- Added isolated, in-memory coverage for malformed evidence, EOL/prerelease selections, overrides, SQLCipher fallbacks, linker-strip loss, incomplete lanes, iOS/Android floors, input digests, CI identity, and Flutter SDK-source failures.
- Added immutable `CompatibilityIssue`/`CompatibilityReport` values and explicit `baseline` / `futureProbe` modes.
- Made CLI arguments strict: malformed or duplicate arguments print usage and exit 2; compatibility errors exit 1; passing reports print deterministic PASS/WARN output with counts.
- Kept running-SDK source inspection optional and explicit through `--verify-running-flutter-sdk`; the verified Stable SDK remains Flutter 3.44.8 / Dart 3.12.2 with API 24 inherited minSdk.

## Task Commits

1. **Task 1: Prove every unsafe manifest and repository state fails closed**
   - `4cfbb942` — RED rejection fixtures
   - `8da4a2f2` — GREEN policy, lane, security, and platform validation
2. **Task 2: Add strict baseline and future-probe report modes**
   - `edf88c51` — RED CLI mode contract
   - `9158014a` — GREEN immutable reports, parser, severity mapping, and concurrency proof

## Verification

- `flutter test test/architecture/dependency_compatibility_contract_test.dart` — passed (27 tests)
- `dart run scripts/dependency_compatibility.dart` — passed
- `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` — passed
- `dart run scripts/dependency_compatibility.dart --mode=unknown` — usage output with exit code 2
- `flutter analyze` — passed, 0 issues
- `git diff --check` — passed

## Decisions Made

- Baseline mode remains the default and blocks every compatibility diagnostic.
- Future-probe warnings are deliberately restricted to ordinary direct-dependency candidate drift; SQLCipher, overrides, EOL selections, floors, policy malformedness, and partial lanes cannot be demoted.
- The report model derives diagnostics from pure strings and copies them into unmodifiable collections, so concurrent validations cannot share report state or modify repository inputs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced an in-test child CLI process with pure parser coverage**
- **Found during:** Task 2 RED verification
- **Issue:** A nested `dart run` child process remained blocked under the Flutter test runner's build-hook lifecycle, preventing the test runner from completing.
- **Fix:** Tested strict parser behavior directly in the hermetic suite; separately executed the real CLI to verify its usage text and exit code 2.
- **Files modified:** `test/architecture/dependency_compatibility_contract_test.dart`
- **Verification:** Targeted suite passed; direct malformed CLI invocation returned exit 2.

## Known Stubs

None.

## Self-Check: PASSED

- Both planned implementation/test files exist and are covered by the completed targeted suite.
- TDD RED commits `4cfbb942`, `edf88c51` precede GREEN commits `8da4a2f2`, `9158014a` in Git history.
