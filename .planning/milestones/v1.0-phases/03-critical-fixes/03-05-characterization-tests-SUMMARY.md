---
phase: 03-critical-fixes
plan: "05"
subsystem: test-infrastructure
tags:
  - characterization_tests
  - wave_1_test_infra
  - tdd
  - mocktail
  - coverage_gate

dependency_graph:
  requires: []
  provides:
    - test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart
    - test/features/family_sync/use_cases/regenerate_invite_use_case_characterization_test.dart
    - test/features/family_sync/use_cases/remove_member_use_case_characterization_test.dart
    - test/infrastructure/security/providers_characterization_test.dart
    - test/main_characterization_smoke_test.dart
  affects:
    - Plan 03-03 Tasks 2, 4, 5 (use case moves; imports updated as part of git mv)
    - Plan 03-02 Task 3 (providers.dart refactor; characterization test accepts both UnimplementedError + StateError)
    - Plan 03-02 Task 6 (main.dart refactor; deferred-final-gate combined coverage check)
    - Plan 03-01 Task 4 (Phase 3 close gate; inherits combined-coverage check for lib/main.dart)

tech_stack:
  added: []
  patterns:
    - "Mocktail-style hand-written fakes (class _Fake extends Mock implements ...)"
    - "AppDatabase.forTesting() for in-memory SQLite (no SQLCipher in tests)"
    - "ProviderContainer overrides to drive provider state without real dependencies"
    - "familySyncNotificationNavigationProvider override to avoid real PushNotificationService"

key_files:
  created:
    - test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart
    - test/features/family_sync/use_cases/regenerate_invite_use_case_characterization_test.dart
    - test/features/family_sync/use_cases/remove_member_use_case_characterization_test.dart
    - test/infrastructure/security/providers_characterization_test.dart
    - test/main_characterization_smoke_test.dart
  modified: []

decisions:
  - "biometricServiceProvider and biometricAvailabilityProvider added to providers_characterization_test to reach 100% on providers.dart (was 66.67% without them)"
  - "FamilySyncNotificationRouteListener required overriding familySyncNotificationNavigationProvider alongside pushNotificationServiceProvider to avoid UnimplementedError during MainShellScreen pump"
  - "buildSuccessOverrides renamed from _successOverrides to satisfy no_leading_underscores_for_local_identifiers lint rule"
  - "lib/main.dart standalone coverage 59.74% — deferred-final-gate applied per Task 4 acceptance; combined with Plan 03-02 Task 6 main_smoke_test.dart expected to reach >=80%"

metrics:
  duration_minutes: 45
  completed_date: "2026-04-26"
  tasks_completed: 5
  tasks_total: 5
  files_created: 5
  files_modified: 0
---

# Phase 03 Plan 05: Characterization Tests Summary

**One-liner:** Wave 1 test-infra plan locking pre-refactor behavior of 4 source files (use cases + providers) plus main.dart smoke coverage via Mocktail fakes and ProviderContainer overrides.

## Frozen Intersection (5 source files)

Per CONTEXT.md D-15 and RESEARCH.md Q3 — files in `Phase 3 touched-files ∩ files-needing-tests.txt`:

| File | Plan that moves/modifies | Status |
|------|--------------------------|--------|
| `lib/features/family_sync/use_cases/deactivate_group_use_case.dart` | Plan 03-03 Task 2 | COVERED 100% |
| `lib/features/family_sync/use_cases/regenerate_invite_use_case.dart` | Plan 03-03 Task 4 | COVERED 100% |
| `lib/features/family_sync/use_cases/remove_member_use_case.dart` | Plan 03-03 Task 5 | COVERED 100% |
| `lib/infrastructure/security/providers.dart` | Plan 03-02 Task 3 | COVERED 100% |
| `lib/main.dart` | Plan 03-02 Task 6 | DEFERRED FINAL GATE (59.74% standalone) |

The intersection file is at `/tmp/phase3-plan05-intersection.txt` (5 entries).

## Coverage Gate Results

Run: `dart run scripts/coverage_gate.dart --list /tmp/phase3-plan05-intersection.txt --threshold 80 --lcov coverage/lcov.info`

| File | Lines Covered/Total | Coverage | Status |
|------|---------------------|----------|--------|
| `lib/features/family_sync/use_cases/deactivate_group_use_case.dart` | 12/12 | 100.00% | PASS |
| `lib/features/family_sync/use_cases/regenerate_invite_use_case.dart` | 15/15 | 100.00% | PASS |
| `lib/features/family_sync/use_cases/remove_member_use_case.dart` | 14/14 | 100.00% | PASS |
| `lib/infrastructure/security/providers.dart` | 15/15 | 100.00% | PASS |
| `lib/main.dart` | 46/77 | 59.74% | **DEFERRED FINAL GATE** |

**Result: 4 of 5 files PASS at submission; lib/main.dart deferred per Task 4 acceptance.**

## Deferred Final Gate — lib/main.dart

Per Task 4 acceptance criteria:

- Standalone coverage from `main_characterization_smoke_test.dart`: **59.74%** (below 80%)
- Combined coverage after Plan 03-02 Task 6's `main_smoke_test.dart` merges into main is the BINDING check
- Plan 03-01 Task 4 (Phase 3 close gate / audit.yml flip) MUST wait on the combined coverage check before proceeding
- If combined coverage still < 80% after Plan 03-02 merges, surface to orchestrator as Phase 3 blocker (not deferral)

## Commits

| Hash | Description |
|------|-------------|
| `4659b99` | test(03-05): add characterization test for deactivate_group_use_case |
| `a6bc096` | test(03-05): add characterization test for regenerate_invite_use_case |
| `42eaa2b` | test(03-05): add characterization test for remove_member_use_case |
| `d376e56` | test(03-05): add characterization test for security/providers.dart |
| `4783e5f` | test(03-05): add smoke characterization test for main.dart |
| `86c7efa` | style(03-05): rename _successOverrides (lint fix) |
| `ac0b562` | test(03-05): add biometric providers coverage to providers_characterization_test |

## Mocktail Fake Patterns Established

These patterns are prior art for Phase 4 HIGH-07 (*.mocks.dart strategy decision):

```dart
// Pattern 1: Simple hand-written fake for interface
class _FakeGroupRepository extends Mock implements GroupRepository {}

// Pattern 2: Fake with stub methods for interface w/ streams
class _FakePushNotificationService extends Mock implements PushNotificationService {
  final _navController = StreamController<PushNavigationIntent>.broadcast();
  @override
  PushNavigationIntent? takePendingNavigationIntent() => null;
  @override
  Stream<PushNavigationIntent> get navigationIntents => _navController.stream;
}

// Pattern 3: Fake with state for use case stubs
class _FakeGetUserProfileUseCase extends Fake implements GetUserProfileUseCase {
  final UserProfile? _profile;
  _FakeGetUserProfileUseCase(this._profile);
  @override
  Future<UserProfile?> execute() async => _profile;
}
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] FamilySyncNotificationRouteListener requires familySyncNotificationNavigationProvider override**
- **Found during:** Task 4 (main.dart smoke test)
- **Issue:** `MainShellScreen` embeds `FamilySyncNotificationRouteListener` which calls `pushNotificationService.takePendingNavigationIntent()` — a concrete method not covered by `Fake`
- **Fix:** Added `familySyncNotificationNavigationProvider.overrideWith(...)` alongside `pushNotificationServiceProvider` override in test setup; `_FakePushNotificationService` extended to `Mock` with stub methods
- **Files modified:** `test/main_characterization_smoke_test.dart`

**2. [Rule 2 - Missing Coverage] biometricServiceProvider and biometricAvailabilityProvider not covered**
- **Found during:** Task 5 coverage gate run
- **Issue:** `providers.dart` coverage was 66.67% (10/15 lines) due to lines 26-35 (biometric providers) not exercised
- **Fix:** Added 2 tests to `providers_characterization_test.dart`: one for `biometricServiceProvider` resolution, one for `biometricAvailabilityProvider` with a `_FakeBiometricService`
- **Files modified:** `test/infrastructure/security/providers_characterization_test.dart`
- **Commit:** `ac0b562`

**3. [Rule 1 - Lint] `_successOverrides` local function name violates no_leading_underscores_for_local_identifiers**
- **Found during:** Task 5 (flutter analyze --no-fatal-infos run)
- **Fix:** Renamed to `buildSuccessOverrides`
- **Commit:** `86c7efa`

## Known Stubs

None — all characterization tests test real observable behavior; no UI stubs introduced.

## Threat Flags

No new security-relevant surface introduced (test-only plan; no source file modifications).

## Full Suite Status

- `flutter analyze --no-fatal-infos`: PASS (0 issues)
- `dart run custom_lint`: EXIT 1 — **pre-existing** 91 issues (import_guard WARNINGs + riverpod INFOs from other files; NOT introduced by Plan 03-05); same count before and after Plan 03-05 commits
- `flutter test`: PASS (1001 tests green)
- `flutter test --coverage`: PASS

## Self-Check: PASSED

Files created:
- test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart: FOUND
- test/features/family_sync/use_cases/regenerate_invite_use_case_characterization_test.dart: FOUND
- test/features/family_sync/use_cases/remove_member_use_case_characterization_test.dart: FOUND
- test/infrastructure/security/providers_characterization_test.dart: FOUND
- test/main_characterization_smoke_test.dart: FOUND

Commits verified:
- 4659b99: FOUND
- a6bc096: FOUND
- 42eaa2b: FOUND
- d376e56: FOUND
- 4783e5f: FOUND
- 86c7efa: FOUND
- ac0b562: FOUND
