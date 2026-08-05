---
phase: 57-stable-baseline-compatibility-contract
plan: "03"
subsystem: infra
tags: [flutter, dart, ci, compatibility-contract, sqlcipher, android]
requires:
  - phase: 57-02
    provides: "Strict baseline/future-probe compatibility reports with non-demotable security diagnostics"
provides:
  - "Blocking Stable CI retrieval and running-SDK baseline verification"
  - "Explicit beta future-probe workflow calls that preserve fatal security and floor diagnostics"
  - "Canonical-manifest-linked human matrix and completed six-task validation evidence"
affects: [58-flutter-analyzer-code-generation, 59-platform-plugin-cohorts, 60-sqlcipher-ios-native-safety, 61-android-host-migration, 62-baseline-reproduction]
actuals:
  tokens: 5460
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns:
    - "Stable CI uses enforced lock retrieval before baseline-mode running-SDK verification."
    - "Future-probe CI may warn only for ordinary candidate drift; security and floor errors stay blocking."
key-files:
  created: []
  modified:
    - .github/workflows/audit.yml
    - .github/workflows/flutter-future-compat.yml
    - docs/testing/DEPENDENCY_COMPATIBILITY.md
    - test/architecture/dependency_compatibility_contract_test.dart
    - .planning/phases/57-stable-baseline-compatibility-contract/57-VALIDATION.md
key-decisions:
  - "Stable static analysis retrieves only the committed graph and verifies Flutter 3.44.8 / Dart 3.12.2 plus inherited Android API 24 before analysis."
  - "Both beta builds are future probes; neither security nor platform-floor failures can be converted to warnings."
requirements-completed: [BASE-02, BASE-03, BASE-04]
coverage:
  - id: D1
    description: "Stable and beta CI workflow source contracts enforce their distinct compatibility modes."
    requirement: BASE-03
    verification:
      - kind: unit
        ref: test/architecture/dependency_compatibility_contract_test.dart#CI workflow source contracts
        status: pass
      - kind: unit
        ref: test/architecture/audit_yml_invariants_test.dart
        status: pass
    human_judgment: false
  - id: D2
    description: "The human matrix and validation evidence remain aligned with the canonical stable manifest and fail-closed baseline validator."
    requirement: BASE-04
    verification:
      - kind: other
        ref: dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk
        status: pass
      - kind: other
        ref: flutter test --coverage --concurrency=1
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-08-05
status: complete
---

# Phase 57 Plan 03: Stable CI Compatibility Enforcement Summary

**Stable CI now retrieves the committed graph and blocks on the reviewed Flutter 3.44.8 / Dart 3.12.2 baseline, while beta builds are explicit future probes that cannot soften security or platform-floor failures.**

## Performance

- **Duration:** 5 min
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added RED/green workflow source contracts: Stable requires an enforced lockfile and baseline running-SDK check before analysis; both beta jobs require explicit future-probe mode while retaining real Android/iOS builds.
- Preserved the Flutter 3.44.8 Stable pin, all API 24/iOS 15/SQLCipher prohibitions, existing permanent audit gates, and hard-failing workflow semantics.
- Rebuilt the human compatibility matrix around the canonical JSON manifest and recorded six exact task IDs plus completed phase-final evidence without claiming simulator, device, or native-encryption proof.

## Task Commits

1. **Task 1: Enforce baseline mode in Stable CI and future-probe mode in beta CI**
   - `ba9f78e5` — RED workflow source contracts
   - `ef06b30e` — GREEN Stable/beta workflow wiring
2. **Task 2: Synchronize human evidence and seal the six-task validation contract**
   - `0e605dfe` — compatibility matrix and validation evidence

## Verification

- `flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/audit_yml_invariants_test.dart` — passed.
- `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` — passed; confirms Flutter 3.44.8 / Dart 3.12.2 Stable and effective Android API 24.
- `flutter pub get --enforce-lockfile` — passed without lockfile mutation.
- `flutter analyze` — passed with 0 issues.
- `flutter test --coverage --concurrency=1` — passed.
- Cleaned-LCOV 70% gate — passed: 15 required files checked, 0 below threshold, 0 missing, 0 deferred.
- `git diff --check` — passed.

## Decisions Made

- The production gate is the Stable CI baseline call after enforced lock retrieval; beta is observability-only for ordinary candidate drift.
- Explicit future-probe mode remains fail-closed for SQLCipher, override, EOL/plaintext, partial-lane, and platform-floor errors.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## TDD Gate Compliance

Passed: RED commit `ba9f78e5` precedes GREEN commit `ef06b30e`; no refactor was required.

## Next Phase Readiness

Phase 58 can consume a blocking Stable baseline and the canonical hold matrix. SQLCipher/iOS, plugin, Android, simulator, and device validation remain with their assigned owner phases.

## Self-Check: PASSED

- All five planned files and this summary exist.
- Task commits `ba9f78e5`, `ef06b30e`, and `0e605dfe` exist in Git history.
