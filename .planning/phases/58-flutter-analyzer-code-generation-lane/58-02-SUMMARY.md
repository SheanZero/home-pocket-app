---
phase: 58-flutter-analyzer-code-generation-lane
plan: "02"
subsystem: tooling
tags: [flutter, dart, analyzer, code-generation, riverpod, compatibility]
requires:
  - phase: 57-stable-baseline-compatibility-contract
    provides: Stable SDK identity and fail-closed compatibility baseline
  - plan: 58-01
    provides: Negative architecture and Riverpod guard fixtures
  - plan: 58-03
    provides: Two-pass generation wrapper contract
provides:
  - Exact analyzer 12.1.0 and code-generation cohort lock contract
  - Auditable Flutter 3.44.9 Stable candidate hold and four-condition exit rule
  - Dart 3.12.2 manifest/lock metadata agreement without overrides
affects: [58-04, 58-05, 59, 60, Stable CI]
tech-stack:
  added: []
  patterns:
    - Fail closed on each reviewed analyzer, generator, lint, and runtime lock member.
    - Record a newer Flutter patch as a hold until all SDK identity and generation proofs move together.
key-files:
  created: []
  modified:
    - pubspec.yaml
    - pubspec.lock
    - scripts/dependency_compatibility.dart
    - test/architecture/dependency_compatibility_contract_test.dart
    - docs/testing/STABLE_BASELINE.json
    - docs/testing/DEPENDENCY_COMPATIBILITY.md
decisions:
  - Keep the exact analyzer 12.1.0/import_lint 2.0.0/Riverpod 3.3.2 cohort; do not restore the superseded analyzer-8/custom_lint proposal.
  - Hold Flutter 3.44.9 until a single reviewed identity transaction passes the no-override, negative-fixture, and two-pass-generation conditions.
metrics:
  duration: 22min
  completed: 2026-08-08
  tasks: 2
  files: 6
status: complete
actuals:
  tokens: 7305
  tasks: 2
  commits: 4
---

# Phase 58 Plan 02: Exact Analyzer and Code-Generation Graph Summary

**Dart 3.12.2 with the exact analyzer 12.1.0, import_lint 2.0.0, Riverpod, Freezed, JSON, Drift, and build-runner solver cohort enforced without overrides.**

## Accomplishments

- Replaced the broad analyzer-12 check with exact lock assertions for analyzer, analyzer_plugin, build/source_gen, Riverpod, Freezed, JSON, Drift, build_runner, import_lint, and dart_code_linter.
- Raised `environment.sdk` to `^3.12.2`; locked resolution updates only the root Dart SDK metadata to `>=3.12.2 <4.0.0` and preserves every selected dependency version.
- Rechecked official Flutter/Pub sources on 2026-08-08. Flutter 3.44.9 is recorded as a Stable candidate hold; the selected Flutter 3.44.8/Dart 3.12.2 identity remains unchanged.
- Recorded the four-condition analyzer/import-boundary exit rule and the Phase-60-only SQLCipher/Drift boundary.

## Task Commits

1. **RED — exact graph mutations** — `8a244111` (`test`)
2. **GREEN — exact graph validator** — `93ecfb83` (`feat`)
3. **RED — canonical architecture lane** — `f45c6b12` (`test`)
4. **GREEN — SDK, manifest, policy, and lane alignment** — `cbc06b34` (`feat`)

## Verification

- `flutter pub get --enforce-lockfile` — pass; no dependency selection changes.
- `flutter test test/architecture/dependency_compatibility_contract_test.dart` — pass (43 tests).
- `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` — pass (0 errors, 0 warnings).
- `flutter analyze scripts/dependency_compatibility.dart test/architecture/dependency_compatibility_contract_test.dart` — pass (0 issues).
- `flutter analyze --no-fatal-infos` — exit 0; reports 289 pre-existing `prefer_initializing_formals` infos in unrelated application code.

## Deviations from Plan

### Superseded implementation details

The authored plan specified analyzer 8.4.0 and custom_lint/import_guard_custom_lint. The current committed canonical graph is analyzer 12.1.0 with active import_lint 2.0.0 and riverpod_lint 3.1.4; this plan preserved its fail-closed objective against that graph and did not downgrade or restore obsolete packages.

### Auto-fixed Issues

**1. [Rule 2 - Critical validation] Hold candidates were not required to be production-stable.**
- **Found during:** Task 2
- **Fix:** The compatibility validator now rejects non-path prerelease/EOL candidates regardless of whether their decision is `hold` or `already_current`; the reviewed local path package remains explicitly exempt.
- **Files modified:** `scripts/dependency_compatibility.dart`, `test/architecture/dependency_compatibility_contract_test.dart`
- **Commit:** `cbc06b34`

## Scope Boundary

No application, generated, database, migration, plugin, iOS, or Android host file changed. The pre-existing generated SwiftPM iOS-13/Firebase iOS-15 mismatch remains deferred to Phase 60 under D-10.

## Known Stubs

None.

## Self-Check: PASSED

- All six declared implementation artifacts exist and are included in the task commits.
- All four task commits are present in git history.
