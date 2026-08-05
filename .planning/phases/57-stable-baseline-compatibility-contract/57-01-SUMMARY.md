---
phase: 57-stable-baseline-compatibility-contract
plan: "01"
subsystem: infra
tags: [flutter, dart, sqlcipher, dependency-policy, ci, android]
requires: []
provides:
  - "Versioned Stable baseline manifest with direct-dependency inventory and tracked-input digests"
  - "Pure compatibility validator that checks manifest, repository, Stable CI, and effective Flutter Android floor"
affects: [58-flutter-analyzer-code-generation, 59-platform-plugin-cohorts, 60-sqlcipher-ios-native-safety, 61-android-host-migration, 62-baseline-reproduction]
actuals:
  tokens: 13216
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns:
    - "Committed JSON policy is parsed fail-closed with accumulated diagnostics"
    - "Repository inputs are compared in-memory to manifest SHA-256 digests"
key-files:
  created:
    - docs/testing/STABLE_BASELINE.json
  modified:
    - scripts/dependency_compatibility.dart
    - test/architecture/dependency_compatibility_contract_test.dart
    - .metadata
    - .github/workflows/audit.yml
key-decisions:
  - "Flutter 3.44.8 / Dart 3.12.2 Stable identity is the selected Phase 57 baseline."
  - "SQLCipher 0.6.8, sqlite3 2.9.4, SQLCipher Pod 4.10.0, iOS 15, and Android API 24 remain held safety invariants."
patterns-established:
  - "Stable CI must pin every stable job to the manifest Flutter version and run real SDK verification."
requirements-completed: [BASE-01, BASE-02]
coverage:
  - id: D1
    description: "Canonical dated Stable baseline manifest and SQLCipher hold"
    requirement: BASE-01
    verification:
      - kind: unit
        ref: test/architecture/dependency_compatibility_contract_test.dart#BASE-01 traces the reviewed SQLCipher hold through the validator
        status: pass
    human_judgment: false
  - id: D2
    description: "Direct dependency, digest, Stable CI, and effective Android floor validation"
    requirement: BASE-02
    verification:
      - kind: unit
        ref: test/architecture/dependency_compatibility_contract_test.dart#BASE-02 rejects an effective Flutter Android floor below API 24
        status: pass
      - kind: other
        ref: dart run scripts/dependency_compatibility.dart --verify-running-flutter-sdk
        status: pass
    human_judgment: false
duration: 42min
completed: 2026-08-05
status: complete
---

# Phase 57 Plan 01: Stable Baseline Compatibility Contract Summary

**Flutter 3.44.8 / Dart 3.12.2 Stable baseline with a complete dependency manifest, SQLCipher safety hold, tracked-input digests, and effective Android API 24 proof.**

## Performance

- **Duration:** 42 min
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added a deterministic, dated `STABLE_BASELINE.json` that inventories every direct main, dev, SDK, and path dependency, eight toolchains, safety holds, and ten tracked Pub/native inputs.
- Extended the pure compatibility contract to reject malformed or incomplete manifests, direct-dependency/digest drift, missing Stable CI pins, overrides, unsafe SQLCipher changes, and an inherited Flutter Android floor below API 24.
- Aligned tracked `.metadata` and every Stable audit job with the locally installed official Flutter 3.44.8 framework revision, while preserving all dependency, lockfile, native, generated, and application inputs.

## Task Commits

1. **Task 1: Trace one reviewed SQLCipher hold from manifest through the pure validator** - `5386f9c6` (RED), `6641cf2d` (GREEN)
2. **Task 2: Complete the official-source inventory and reproducible tracked-input snapshot** - `9b5731c4` (test)

## Verification

- `flutter pub get --enforce-lockfile` — passed
- `flutter test test/architecture/dependency_compatibility_contract_test.dart` — passed (9 tests)
- `dart run scripts/dependency_compatibility.dart --verify-running-flutter-sdk` — passed
- `flutter analyze` — passed, 0 issues
- `git diff --check` — passed
- Protected-input diff check for Pub, native, and generated sources — passed

## Files Created/Modified

- `docs/testing/STABLE_BASELINE.json` — canonical evidence, inventory, holds, and SHA-256 snapshot.
- `scripts/dependency_compatibility.dart` — pure parser/validator plus real installed-SDK verification mode.
- `test/architecture/dependency_compatibility_contract_test.dart` — portable repository fixture and negative contract coverage.
- `.metadata` — Flutter 3.44.8 Stable framework identity.
- `.github/workflows/audit.yml` — all Stable jobs pinned to 3.44.8; static analysis runs the real SDK proof.

## Decisions Made

- The selected production Stable Flutter identity is 3.44.8 / Dart 3.12.2 / framework revision `058e0af2c2b57e369d905a03ac9748b0ebf543c6`.
- The validator stays network-free and accepts all repository inputs as strings so unit tests remain hermetic; only the CLI resolves the `flutter` executable and reads its `FlutterExtension.kt` source.
- Xcode and AGP/Gradle candidates remain documented holds for their owner phases; no migration was folded into this policy phase.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Repaired interrupted baseline implementation before validation**
- **Found during:** Task 1
- **Issue:** The partial validator referenced missing runtime SDK helpers, the test read a machine-specific Flutter path, and the partial manifest omitted required dependency/digest coverage.
- **Fix:** Added portable injected fixtures, complete manifest parsing/inventory/digest checks, and CLI-only SDK resolution.
- **Files modified:** `scripts/dependency_compatibility.dart`, `test/architecture/dependency_compatibility_contract_test.dart`, `docs/testing/STABLE_BASELINE.json`
- **Verification:** Targeted test suite and real SDK validator both passed.
- **Committed in:** `6641cf2d`

**2. [Rule 3 - Blocking] Restored parseable sequential plan position in planning state**
- **Found during:** Plan close-out
- **Issue:** `state.advance-plan` could not advance from the pre-existing `Plan: —` placeholder even though three Phase 57 plans are present.
- **Fix:** Recorded the next executable position as Plan 02 of 03 after the state metrics, decisions, session, roadmap, and requirement handlers completed.
- **Files modified:** `.planning/STATE.md`

**Total deviations:** 2 auto-fixed (Rule 1, Rule 3)

## Known Stubs

None.

## Self-Check: PASSED

- All five implementation artifacts and this summary exist on disk.
- RED (`5386f9c6`) and both implementation commits (`6641cf2d`, `9b5731c4`) exist in Git history.

## User Setup Required

None.

## Next Phase Readiness

Phases 58–62 can consume the versioned manifest and fail-closed validator without treating newer candidate rows as authorization to upgrade. The project and Stable CI now agree with the installed Flutter 3.44.8 SDK.
