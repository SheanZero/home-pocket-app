---
phase: 23-v1-3-cleanup-scanner-allow-lists-voice-flow-polish
plan: 02
subsystem: application/seed
tags: [seed-orchestration, use-case-wrapper, riverpod, tdd, d-14]
decisions-implemented: [D-14]
requirements: []

dependency_graph:
  requires: []
  provides:
    - seedAllUseCaseProvider (lib/application/seed/seed_providers.dart)
    - SeedAllUseCase (lib/application/seed/seed_all_use_case.dart)
  affects:
    - lib/main.dart (bootstrap seed wiring collapsed)

tech_stack:
  added: []
  patterns:
    - Use-case orchestrator composing leaf use cases with ordered execution
    - "@riverpod function-style provider wiring via ref.watch"
    - Mocktail timestamp-capture pattern for ordering assertions

key_files:
  created:
    - lib/application/seed/seed_all_use_case.dart
    - lib/application/seed/seed_providers.dart
    - lib/application/seed/seed_providers.g.dart
    - test/unit/application/seed/seed_all_use_case_test.dart
  modified:
    - lib/main.dart

decisions:
  - "Result.failure does not exist in this codebase; the correct constructor is Result.error(String). Test stubs use Result.error('...') accordingly."
  - "seed_providers.dart imports only repository_providers.dart and seed_all_use_case.dart — the leaf use case type imports are not needed directly since the types flow through the providers."

metrics:
  duration_minutes: 3
  completed_date: "2026-05-25"
  tasks_completed: 2
  files_created: 4
  files_modified: 1
---

# Phase 23 Plan 02: SeedAllUseCase orchestrator + ordering unit tests (D-14) Summary

## One-liner

SeedAllUseCase wrapper encodes categories-before-synonyms ordering contract structurally; main.dart seed wiring collapsed from 6 lines to 1 provider read; ordering verified via mocktail timestamp-capture unit tests.

## What Was Built

### Task 2.1: Create SeedAllUseCase + Riverpod provider + collapse main.dart

Created `lib/application/seed/seed_all_use_case.dart`: a use-case orchestrator that composes `SeedCategoriesUseCase` and `SeedVoiceSynonymsUseCase` using constructor injection and ordered `execute()` with failure short-circuit. The ordering contract that was previously a comment in `main.dart:111` ("Phase 21 D-01: synonyms must run AFTER categories") is now encoded structurally in the wrapper body.

Created `lib/application/seed/seed_providers.dart`: `@riverpod` function-style provider `seedAllUseCase(Ref ref)` composing the two existing leaf providers via `ref.watch`. Follows the analog pattern from `lib/application/voice/repository_providers.dart`.

Generated `lib/application/seed/seed_providers.g.dart` via `flutter pub run build_runner build`: exports `seedAllUseCaseProvider`.

Modified `lib/main.dart`: replaced the 6-line seed block (reading two leaf providers + comment) with 2 lines using `seedAllUseCaseProvider`. Import block updated to remove unused leaf provider symbols.

### Task 2.2: Add unit test asserting seed ordering + short-circuit-on-failure

Created `test/unit/application/seed/seed_all_use_case_test.dart` with two tests:

- **D-14: seeds categories before synonyms** — mocks `seedCategories.execute` to delay 5ms then capture `categoriesCompletedAt = DateTime.now()`, mocks `seedVoiceSynonyms.execute` to capture `synonymsStartedAt = DateTime.now()`, asserts `categoriesCompletedAt!.isBefore(synonymsStartedAt!)` with descriptive reason string.

- **D-14: synonyms not invoked when categories fails** — mocks `seedCategories.execute` to return `Result.error(...)`, calls `useCase.execute()`, asserts `result.isSuccess` is false and `verifyNever(() => mockSynonyms.execute())` confirms short-circuit.

Both tests pass. The test structure follows the analog in `test/unit/application/accounting/seed_categories_use_case_test.dart`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Result.failure does not exist — used Result.error**
- **Found during:** Task 2.2 test authoring (reading result.dart)
- **Issue:** PLAN.md and RESEARCH.md references use `Result.failure(...)` but `lib/shared/utils/result.dart` only defines `Result.success(T?)` and `Result.error(String)`. No `Result.failure` constructor exists.
- **Fix:** Used `Result.error('categories seed failed')` in the short-circuit test stub. This matches the actual API.
- **Files modified:** test/unit/application/seed/seed_all_use_case_test.dart
- **Commit:** 27c5157

## Verification Results

- `flutter pub run build_runner build --delete-conflicting-outputs`: completed successfully, wrote 1336 outputs
- `flutter test test/unit/application/seed/seed_all_use_case_test.dart`: 2/2 tests passed
- `flutter analyze lib/application/seed/ lib/main.dart`: No issues found
- `flutter analyze test/unit/application/seed/seed_all_use_case_test.dart`: No issues found
- `grep -c "seedAllUseCaseProvider" lib/application/seed/seed_providers.g.dart`: 2
- `grep -c "seedAllUseCaseProvider" lib/main.dart`: 1
- `grep -c "seedCategoriesUseCaseProvider\|seedVoiceSynonymsUseCaseProvider" lib/main.dart`: 0

## Known Stubs

None — all wiring is live and functional.

## Threat Flags

None — no new network endpoints, auth paths, file access, or schema changes introduced. This plan only reorganizes existing use-case call sites at the bootstrap layer.

## Self-Check: PASSED

- lib/application/seed/seed_all_use_case.dart: FOUND
- lib/application/seed/seed_providers.dart: FOUND
- lib/application/seed/seed_providers.g.dart: FOUND
- test/unit/application/seed/seed_all_use_case_test.dart: FOUND
- Commit 23c6f4a (Task 2.1): FOUND
- Commit 27c5157 (Task 2.2): FOUND
