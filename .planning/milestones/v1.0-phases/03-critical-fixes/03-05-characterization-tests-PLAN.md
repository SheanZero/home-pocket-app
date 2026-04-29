---
phase: 03-critical-fixes
plan: 05
type: tdd
wave: 1
depends_on: []
files_modified:
  - test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart
  - test/features/family_sync/use_cases/regenerate_invite_use_case_characterization_test.dart
  - test/features/family_sync/use_cases/remove_member_use_case_characterization_test.dart
  - test/infrastructure/security/providers_characterization_test.dart
  - test/main_characterization_smoke_test.dart
autonomous: true
requirements:
  - CRIT-05
  - CRIT-06
tags:
  - characterization_tests
  - wave_0_test_infra
  - tdd
  - critical_fixes
must_haves:
  truths:
    - "Characterization tests are written BEFORE the matching refactor commits land in Plans 03-02/03-03/03-04 — they 'lock current behavior' so refactors are provably non-regressing per CONTEXT.md D-15"
    - "Scope = `Phase 3 touched-files ∩ .planning/audit/files-needing-tests.txt` per CONTEXT.md D-15 + RESEARCH.md Open Question Q3. The intersection is computed below in `<interfaces>` and is FROZEN for this plan (no scope creep — files already ≥80% pre-Phase-3 are exempted from new test writing per Q3 recommendation)"
    - "Specifically — the 4 files in the intersection: `lib/features/family_sync/use_cases/deactivate_group_use_case.dart`, `lib/features/family_sync/use_cases/regenerate_invite_use_case.dart`, `lib/features/family_sync/use_cases/remove_member_use_case.dart`, `lib/infrastructure/security/providers.dart`"
    - "Plus one additional smoke test for `lib/main.dart` per RESEARCH.md Q2 recommendation (CRIT-05 D-15 strict — main.dart is touched; smoke `testWidgets` for `_HomePocketApp` covers both `_initialized=true` and `_error != null` branches; Plan 03-02 Task 6's `_InitFailureApp` widget test complements this)"
    - "All characterization tests use Mocktail-style hand-written fakes (NEVER Mockito codegen) per CONTEXT.md `<deferred>` — Phase 4 HIGH-07 owns the *.mocks.dart strategy decision"
    - "All characterization tests NEVER touch real `flutter_secure_storage` or `recoverFromSeed()` (FUTURE-ARCH-04 protection)"
    - "All characterization tests use `AppDatabase.forTesting()` (in-memory SQLite) when a database is needed; never SQLCipher"
    - "After Plan 03-05 lands BUT BEFORE Plans 03-02/03/04's refactor commits, the new tests run GREEN against the PRE-refactor codebase (proving they capture current behavior)"
    - "AFTER Plans 03-02/03/04 ship their refactors, the same tests run GREEN against the POST-refactor codebase at the new file paths (proving behavior is preserved across the move/refactor)"
    - "Plan 03-02 (Wave 2) explicitly depends_on Plan 03-05 because its `app_initializer_test.dart` infrastructure piggy-backs on the Mocktail fake patterns established here for `MasterKeyRepository`"
    - "Operational repo lock per Phase 2 D-07 / D-16 active throughout; Wave 1 — runs in parallel with Plans 03-01, 03-03, 03-04 (test-only changes; no source-file modifications in this plan)"
    - "coverage_gate.dart per-plan run targets the 4 source files in the intersection plus lib/main.dart and verifies each reaches ≥80% post-Phase-3"
  artifacts:
    - path: "test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart"
      provides: "Mocktail-style behavior lock for DeactivateGroupUseCase pre-move (Plan 03-03 Task 2 dependency)"
      min_lines: 40
    - path: "test/features/family_sync/use_cases/regenerate_invite_use_case_characterization_test.dart"
      provides: "Mocktail-style behavior lock for RegenerateInviteUseCase pre-move (Plan 03-03 Task 4 dependency)"
      min_lines: 40
    - path: "test/features/family_sync/use_cases/remove_member_use_case_characterization_test.dart"
      provides: "Mocktail-style behavior lock for RemoveMemberUseCase pre-move (Plan 03-03 Task 5 dependency)"
      min_lines: 40
    - path: "test/infrastructure/security/providers_characterization_test.dart"
      provides: "Locks current `appDatabaseProvider` UnimplementedError throw + auditLogger consumer behavior pre-Plan-03-02 refactor"
      min_lines: 30
    - path: "test/main_characterization_smoke_test.dart"
      provides: "Smoke testWidgets covering _HomePocketApp's _initialized + _error branches (CRIT-05 strict per RESEARCH.md Q2)"
      min_lines: 40
  key_links:
    - from: "test/features/family_sync/use_cases/<X>_characterization_test.dart"
      to: "lib/features/family_sync/use_cases/<X>.dart (pre-move) AND lib/application/family_sync/<X>.dart (post-move)"
      via: "import 'package:home_pocket/features/family_sync/use_cases/<X>.dart' (pre-Plan-03-03) — updated by Plan 03-03 to import from `application/family_sync/`"
      pattern: "package:home_pocket/.*family_sync/.*<X>\\.dart"
    - from: "test/infrastructure/security/providers_characterization_test.dart"
      to: "lib/infrastructure/security/providers.dart"
      via: "ProviderContainer().read(appDatabaseProvider) throws UnimplementedError currently; Plan 03-02 changes it to StateError"
      pattern: "appDatabaseProvider"
---

<objective>
Plan 03-05 is the **Wave 0 test-infrastructure plan** for Phase 3 — it writes characterization tests for files in `Phase 3 touched-files ∩ files-needing-tests.txt` BEFORE the corresponding refactor commits land in Plans 03-02/03/04. Per CONTEXT.md D-15: tests written first, refactors second.

The intersection — computed below — is **5 source files**:
1. `lib/features/family_sync/use_cases/deactivate_group_use_case.dart` (file-needing-tests line 70; Plan 03-03 moves it)
2. `lib/features/family_sync/use_cases/regenerate_invite_use_case.dart` (line 71; Plan 03-03 moves it)
3. `lib/features/family_sync/use_cases/remove_member_use_case.dart` (line 72; Plan 03-03 moves it)
4. `lib/infrastructure/security/providers.dart` (line 93; Plan 03-02 refactors `appDatabaseProvider`)
5. `lib/main.dart` (NOT in files-needing-tests.txt but RESEARCH.md Q2 surfaces it as in-scope under D-15 strict; Plan 03-02 Task 6 refactors it)

For each source file the plan ships a focused characterization test that:
- locks the current observable behavior (constructor + happy-path + key error/branching cases)
- uses Mocktail-style hand-written fakes (CONTEXT.md `<deferred>`)
- never touches real `flutter_secure_storage` (FUTURE-ARCH-04 protection)
- uses `AppDatabase.forTesting()` when needed
- imports from the CURRENT file path (Plan 03-03 will update the test imports as part of its `git mv` task; Plans 03-02/Task 6 update similarly)

Files already ≥80% pre-Phase-3 (NOT in `files-needing-tests.txt`) are exempted — their existing tests must continue to pass through the refactors per RESEARCH.md Q3 recommendation. This includes `check_group_use_case.dart`, `leave_group_use_case.dart`, `init_result.dart` (new — Plan 03-02 covers), `app_initializer.dart` (new — Plan 03-02 covers), `init_failure_screen.dart` (new — Plan 03-02 covers), and the 6 yamls + arch test (Plan 03-01).

Purpose: Convert the strict ≥80% coverage rule from a "we'll add tests after" promise into a "tests already exist before the refactor" reality. Make Plans 03-02/03/04 commit cleanly without coverage debt.

Output:
- 5 NEW test files (3 for family_sync use_cases + 1 for providers + 1 for main.dart smoke)
- Frozen intersection list `/tmp/phase3-plan05-intersection.txt` produced for traceability
- coverage_gate.dart run against the intersection produces a baseline ≥80% report (the post-refactor re-run by Plans 03-02/03/04 verifies behavior preservation)
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/REQUIREMENTS.md
@.planning/phases/03-critical-fixes/03-CONTEXT.md
@.planning/phases/03-critical-fixes/03-RESEARCH.md
@.planning/phases/03-critical-fixes/03-PATTERNS.md
@.planning/phases/03-critical-fixes/03-VALIDATION.md
@.planning/audit/files-needing-tests.txt
@.planning/audit/coverage-baseline.txt
@.planning/audit/REPO-LOCK-POLICY.md
@CLAUDE.md

<interfaces>
<!-- Embedded contracts -->

## The intersection — frozen for this plan

Compute via:
1. Phase 3 touched-source-files = union of `files_modified` across Plans 03-01, 03-02, 03-03, 03-04 (filtered to `.dart` files under `lib/`)
2. Files-needing-tests = `.planning/audit/files-needing-tests.txt`
3. Intersection = the overlap

The intersection (verified by inspection of `files-needing-tests.txt` and the touched lists in CONTEXT.md `<canonical_refs>`):

| File (in intersection) | Source of touch | files-needing-tests.txt line |
|---|---|---|
| lib/features/family_sync/use_cases/deactivate_group_use_case.dart | Plan 03-03 Task 2 (move) | 70 |
| lib/features/family_sync/use_cases/regenerate_invite_use_case.dart | Plan 03-03 Task 4 (move) | 71 |
| lib/features/family_sync/use_cases/remove_member_use_case.dart | Plan 03-03 Task 5 (move) | 72 |
| lib/infrastructure/security/providers.dart | Plan 03-02 Task 3 (concrete appDatabaseProvider) | 93 |
| lib/main.dart | Plan 03-02 Task 6 (delegate to AppInitializer) | (not in file but in scope per RESEARCH.md Q2) |

**Files explicitly NOT in this plan's scope** (exempted per RESEARCH.md Q3):
- `check_group_use_case.dart`, `leave_group_use_case.dart` — not in files-needing-tests.txt; existing tests stay GREEN through Plan 03-03 moves
- `lib/features/home/presentation/screens/home_screen.dart`, `lib/features/home/presentation/widgets/ledger_comparison_section.dart` — not in files-needing-tests.txt; existing `ledger_comparison_section_test.dart` covers behavior across Plan 03-04 move
- New files created by Plans 03-01/02/04 (init_result.dart, app_initializer.dart, init_failure_screen.dart, the 11 new domain yamls, presentation/models/ledger_row_data.dart) — covered by their owning plans' Task tests
- The 6 family_sync use_cases tests already exist in `test/unit/features/family_sync/use_cases/` (verified by `find` earlier in planning); Plan 03-05 ADDS supplementary `_characterization_test.dart` files alongside, designed specifically to lock observable behavior across the upcoming move

## Mocktail fake convention (analog: `test/application/family_sync/sync_engine_dedup_test.dart`)

```dart
import 'package:mocktail/mocktail.dart';

class _FakeRepo extends Mock implements GroupRepository {}

void main() {
  setUpAll(() { registerFallbackValue(/* any required value class */); });

  setUp(() {
    fake = _FakeRepo();
    when(() => fake.someMethod()).thenAnswer((_) async => result);
  });
  // ...
}
```

Established by `sync_engine_dedup_test.dart`; CONTEXT.md `<deferred>` locks Phase 3 to this style.

## RESEARCH.md §"Per-file characterization technique" recommendations

| File | Test type | Rationale |
|---|---|---|
| use case (deactivate/regenerate/remove_member) | Unit test with constructor injection + Mocktail fakes for repos | Stateless logic; isolate via fakes; verify Result.success/error per branch |
| infrastructure/security/providers.dart | Unit test with `ProviderContainer` + Mocktail fakes for upstream deps | Provider wiring; assert `ref.watch(providerName)` returns expected concrete type given known overrides |
| lib/main.dart | Sparse `testWidgets` covering both branches of `_HomePocketAppState._buildHome` | Boot code is hard to fully unit-test; smoke covers `_initialized=true` (MainShellScreen branch) and `_error != null` (Scaffold with error text) |

## CONTEXT.md D-15 caveat

Pure renames count as touched. Existing tests for files NOT in `files-needing-tests.txt` (so already ≥80% per Phase 2 baseline) must STAY GREEN through any Phase 3 move. Plans 03-03/04 enforce this; Plan 03-05 does NOT need to write new tests for them.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Compute & freeze the intersection list + write characterization test for `deactivate_group_use_case.dart`</name>
  <files>
    test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart
  </files>
  <read_first>
    - .planning/audit/files-needing-tests.txt (lines 70-72, 93)
    - lib/features/family_sync/use_cases/deactivate_group_use_case.dart (CURRENT path — pre-move; full file content; map all dependencies the use case takes via constructor)
    - test/unit/features/family_sync/use_cases/deactivate_group_use_case_test.dart (existing test, if any — note WHAT it currently covers vs WHAT it does NOT cover that brings the file under 80%)
    - test/application/family_sync/sync_engine_dedup_test.dart (Mocktail-style hand-written fake convention)
    - .planning/phases/03-critical-fixes/03-RESEARCH.md (§"Per-file characterization technique" — recommended unit-test approach)
    - .planning/phases/03-critical-fixes/03-PATTERNS.md (§"`test/application/family_sync/*_use_case_test.dart` (5 MOVE targets)")
  </read_first>
  <behavior>
    - Test file constructs `DeactivateGroupUseCase` with hand-written Mocktail fakes for all repos / services it injects via its constructor
    - Asserts the use case's happy path: `execute(...)` returns `Result.success(...)` (or whatever sealed-class success variant the use case uses)
    - Asserts at least 2 failure branches: e.g., repository throws → use case returns `Result.error(...)`; preconditions fail → returns appropriate `Result` variant
    - All assertions reference the use case's existing observable behavior — DO NOT change behavior; LOCK it
    - Test file imports the production file via `package:home_pocket/features/family_sync/use_cases/deactivate_group_use_case.dart` (current path; Plan 03-03 Task 2 will rewrite this import alongside its `git mv`)
    - Never touches `flutter_secure_storage`; never `recoverFromSeed()`; never SQLCipher real DB
  </behavior>
  <action>
    **Step 1 — write the intersection file** at `/tmp/phase3-plan05-intersection.txt` with these 5 lines:
    ```
    lib/features/family_sync/use_cases/deactivate_group_use_case.dart
    lib/features/family_sync/use_cases/regenerate_invite_use_case.dart
    lib/features/family_sync/use_cases/remove_member_use_case.dart
    lib/infrastructure/security/providers.dart
    lib/main.dart
    ```
    Commit-time note: this is FROZEN for the duration of Plan 03-05 (D-15 strict + Phase 2 D-08 frozen baseline).

    **Step 2 — read `lib/features/family_sync/use_cases/deactivate_group_use_case.dart` in full** to understand:
    - Class name (likely `DeactivateGroupUseCase`)
    - Constructor parameters (which repos / services are injected)
    - The single `execute(...)` method signature + return type (likely a sealed class result with `success/error` variants)
    - Each visible branch in `execute(...)` body (success path + 1-3 error paths)

    Then read `test/unit/features/family_sync/use_cases/deactivate_group_use_case_test.dart` if it exists to map gaps.

    **Step 3 — write `test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart`** following the Mocktail style of `test/application/family_sync/sync_engine_dedup_test.dart`. Skeleton:

    ```dart
    // Characterization test: locks DeactivateGroupUseCase behavior pre-Plan-03-03 move.
    //
    // Per Phase 3 D-15 (CONTEXT.md): tests written BEFORE refactor lands.
    // Plan 03-03 Task 2 will move the production file from
    //   lib/features/family_sync/use_cases/deactivate_group_use_case.dart
    // to
    //   lib/application/family_sync/deactivate_group_use_case.dart
    // and this test's import line gets rewritten as part of that PR.
    //
    // The test asserts the CURRENT observable behavior. Post-move it must
    // still pass — proving the move was a pure refactor (PROJECT.md
    // behavior preservation).

    import 'package:flutter_test/flutter_test.dart';
    import 'package:home_pocket/features/family_sync/use_cases/deactivate_group_use_case.dart';
    // (Plus imports for the repos/services used in the use case's constructor;
    //  e.g., GroupRepository, KeyManager, etc. — discover from Step 2 read.)
    import 'package:mocktail/mocktail.dart';

    // Mocktail fakes for each constructor dependency.
    class _FakeGroupRepository extends Mock implements GroupRepository {}
    // ... add additional fakes as the use case's constructor demands ...

    void main() {
      group('DeactivateGroupUseCase characterization', () {
        late _FakeGroupRepository fakeGroupRepo;
        // ... late vars for additional fakes ...
        late DeactivateGroupUseCase useCase;

        setUpAll(() {
          // registerFallbackValue for any value-types Mocktail will use as args
        });

        setUp(() {
          fakeGroupRepo = _FakeGroupRepository();
          // ... initialize other fakes ...
          // Default happy-path stubs — adjust per the use case's actual API:
          when(() => fakeGroupRepo.deactivate(any())).thenAnswer((_) async {});
          // ...
          useCase = DeactivateGroupUseCase(
            // ... pass in the fakes ...
          );
        });

        test('returns success when repository deactivation succeeds', () async {
          final result = await useCase.execute(/* required args from production signature */);
          expect(result.isSuccess, isTrue);
          // OR per the actual sealed-class shape:
          // expect(result, isA<DeactivateGroupSuccess>());
        });

        test('returns error when repository throws', () async {
          when(() => fakeGroupRepo.deactivate(any())).thenThrow(StateError('db'));
          final result = await useCase.execute(/* args */);
          expect(result.isSuccess, isFalse);
          // Variant depends on the use case's actual error sealed-class — assert per current behavior
        });

        // Add 1-3 additional tests covering ANY observable branches in the
        // CURRENT implementation. Goal: characterize observable behavior;
        // do NOT add new behavior tests.
      });
    }
    ```

    Adjust the skeleton to match the actual production file's API (constructor args, return type, branches). The exact set of tests is determined by the production file's branches. Aim for ≥80% coverage on `deactivate_group_use_case.dart` (the executor will run `flutter test --coverage` to verify).

    **Step 4 — verify** the test runs GREEN against the CURRENT (pre-move) production code:
    1. `flutter test test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart` exits 0
    2. The test does NOT touch `flutter_secure_storage` (verify with `! grep "flutter_secure_storage" test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart`)

    **Step 5 — verify coverage** for `deactivate_group_use_case.dart` reaches ≥80%:
    1. `flutter test --coverage`
    2. `coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info --mode w --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'`
    3. `dart run scripts/coverage_gate.dart --files lib/features/family_sync/use_cases/deactivate_group_use_case.dart --threshold 80 --lcov coverage/lcov_clean.info` exits 0

    If coverage falls short of 80%, add more branch-coverage tests until the gate passes.

    Commit message: `test(03-05): add characterization test for deactivate_group_use_case (Plan 03-03 dependency)`.
  </action>
  <verify>
    <automated>flutter test test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart &amp;&amp; ! grep "flutter_secure_storage" test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart</automated>
  </verify>
  <acceptance_criteria>
    - `test -f /tmp/phase3-plan05-intersection.txt && [ "$(wc -l < /tmp/phase3-plan05-intersection.txt)" -eq 5 ]` exits 0 (intersection list frozen with 5 entries)
    - `test -f test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart` exits 0
    - `grep -q "import 'package:home_pocket/features/family_sync/use_cases/deactivate_group_use_case.dart'" test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart` exits 0 (PRE-move import path; Plan 03-03 will rewrite)
    - `grep -q "import 'package:mocktail/mocktail.dart'" test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart` exits 0 (Mocktail style)
    - `! grep "package:mockito" test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart` exits 0 (NO Mockito codegen)
    - `! grep "flutter_secure_storage" test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart` exits 0
    - `flutter test test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart` exits 0
    - `dart run scripts/coverage_gate.dart --files lib/features/family_sync/use_cases/deactivate_group_use_case.dart --threshold 80 --lcov coverage/lcov_clean.info` exits 0
  </acceptance_criteria>
  <done>Intersection list frozen; deactivate_group_use_case characterization test ≥80% coverage; ready for Plan 03-03 Task 2.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Characterization tests for `regenerate_invite_use_case.dart` and `remove_member_use_case.dart`</name>
  <files>
    test/features/family_sync/use_cases/regenerate_invite_use_case_characterization_test.dart,
    test/features/family_sync/use_cases/remove_member_use_case_characterization_test.dart
  </files>
  <read_first>
    - lib/features/family_sync/use_cases/regenerate_invite_use_case.dart (full source; map constructor + branches)
    - lib/features/family_sync/use_cases/remove_member_use_case.dart (full source; map constructor + branches)
    - test/unit/features/family_sync/use_cases/regenerate_invite_use_case_test.dart (existing — note gaps)
    - test/unit/features/family_sync/use_cases/remove_member_use_case_test.dart (existing — note gaps)
    - test/application/family_sync/sync_engine_dedup_test.dart (Mocktail convention)
  </read_first>
  <behavior>
    - For each file: a `_characterization_test.dart` with happy + 1-3 error branches per current observable behavior
    - All Mocktail; no flutter_secure_storage; no recoverFromSeed
    - Each file's coverage reaches ≥80% post-test (`coverage_gate.dart` confirms)
    - Both tests run GREEN against current pre-move codebase
  </behavior>
  <action>
    Apply the SAME procedure as Task 1 but for the two remaining files in the intersection:

    **regenerate_invite_use_case.dart** (Plan 03-03 Task 4 dependency):
    1. Read source + existing test
    2. Write `test/features/family_sync/use_cases/regenerate_invite_use_case_characterization_test.dart` with Mocktail fakes for the constructor's repos/services + happy + error branches
    3. Verify `flutter test <path>` exits 0
    4. Verify coverage ≥80% via `coverage_gate.dart --files lib/features/family_sync/use_cases/regenerate_invite_use_case.dart`

    **remove_member_use_case.dart** (Plan 03-03 Task 5 dependency):
    1. Same procedure
    2. Write `test/features/family_sync/use_cases/remove_member_use_case_characterization_test.dart`
    3. Verify

    Commit each in its own commit:
    - `test(03-05): add characterization test for regenerate_invite_use_case (Plan 03-03 dependency)`
    - `test(03-05): add characterization test for remove_member_use_case (Plan 03-03 dependency)`
  </action>
  <verify>
    <automated>flutter test test/features/family_sync/use_cases/regenerate_invite_use_case_characterization_test.dart test/features/family_sync/use_cases/remove_member_use_case_characterization_test.dart</automated>
  </verify>
  <acceptance_criteria>
    - `test -f test/features/family_sync/use_cases/regenerate_invite_use_case_characterization_test.dart` exits 0
    - `test -f test/features/family_sync/use_cases/remove_member_use_case_characterization_test.dart` exits 0
    - `grep -q "import 'package:home_pocket/features/family_sync/use_cases/regenerate_invite_use_case.dart'" test/features/family_sync/use_cases/regenerate_invite_use_case_characterization_test.dart` exits 0
    - `grep -q "import 'package:home_pocket/features/family_sync/use_cases/remove_member_use_case.dart'" test/features/family_sync/use_cases/remove_member_use_case_characterization_test.dart` exits 0
    - `! grep "package:mockito" test/features/family_sync/use_cases/regenerate_invite_use_case_characterization_test.dart` exits 0
    - `! grep "package:mockito" test/features/family_sync/use_cases/remove_member_use_case_characterization_test.dart` exits 0
    - `! grep "flutter_secure_storage" test/features/family_sync/use_cases/regenerate_invite_use_case_characterization_test.dart` exits 0
    - `! grep "flutter_secure_storage" test/features/family_sync/use_cases/remove_member_use_case_characterization_test.dart` exits 0
    - `flutter test test/features/family_sync/use_cases/regenerate_invite_use_case_characterization_test.dart test/features/family_sync/use_cases/remove_member_use_case_characterization_test.dart` exits 0
    - `dart run scripts/coverage_gate.dart --files lib/features/family_sync/use_cases/regenerate_invite_use_case.dart --threshold 80 --lcov coverage/lcov_clean.info` exits 0
    - `dart run scripts/coverage_gate.dart --files lib/features/family_sync/use_cases/remove_member_use_case.dart --threshold 80 --lcov coverage/lcov_clean.info` exits 0
  </acceptance_criteria>
  <done>regenerate + remove_member characterization tests GREEN with ≥80% coverage; ready for Plan 03-03 Tasks 4-5.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Characterization test for `lib/infrastructure/security/providers.dart` (pre-Plan-03-02 refactor) — locks current `UnimplementedError` behavior + auditLogger consumer</name>
  <files>
    test/infrastructure/security/providers_characterization_test.dart
  </files>
  <read_first>
    - lib/infrastructure/security/providers.dart (full file — current state with `UnimplementedError`)
    - test/infrastructure/security/audit_logger_test.dart (existing test for auditLogger consumer; provides analog patterns)
    - lib/data/app_database.dart (`AppDatabase.forTesting()` factory)
    - .planning/phases/03-critical-fixes/03-RESEARCH.md (§"Per-file characterization technique" — provider files row)
  </read_first>
  <behavior>
    - Locks the CURRENT pre-Plan-03-02 behavior: `appDatabaseProvider` body throws `UnimplementedError` when read without override
    - Locks the CURRENT pass-through behavior: when override is supplied via `appDatabaseProvider.overrideWithValue(AppDatabase.forTesting())`, `ref.read(appDatabaseProvider)` returns the supplied database
    - Locks the CURRENT auditLogger wiring: `ref.read(auditLoggerProvider)` resolves successfully when `appDatabaseProvider` and `flutterSecureStorageProvider` are properly overridden
    - **Important**: Plan 03-02 Task 3 will REPLACE the test's `UnimplementedError` assertion with `StateError`. That is fine — Plan 03-02's `providers_test.dart` (Task 3) supersedes the StateError assertion. This characterization test serves the BEFORE-state baseline; it is removed/superseded after Plan 03-02 lands.
    - Mocktail-style fakes for `FlutterSecureStorage` if needed
  </behavior>
  <action>
    Read `lib/infrastructure/security/providers.dart` in full. Note that:
    - `flutterSecureStorageProvider` returns a real `FlutterSecureStorage` instance (which we should NOT exercise in tests)
    - `secureStorageServiceProvider` reads `flutterSecureStorageProvider` and wraps it
    - `auditLoggerProvider` reads `appDatabaseProvider` and `secureStorageServiceProvider`
    - `appDatabaseProvider` currently throws `UnimplementedError`

    Write `test/infrastructure/security/providers_characterization_test.dart`:

    ```dart
    // Characterization test: locks lib/infrastructure/security/providers.dart
    // PRE-Plan-03-02 behavior. Plan 03-02 Task 3 replaces UnimplementedError
    // with a diagnostic StateError; that's a documented behavior change for
    // CRIT-03 closure, NOT a regression — Plan 03-02 ships
    // test/infrastructure/security/providers_test.dart which supersedes
    // the StateError assertion below.
    //
    // The remaining behaviors locked here (override pass-through, auditLogger
    // wiring) MUST stay GREEN through Plan 03-02 — they are the contracts
    // the auditLogger and other consumers depend on.

    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import 'package:flutter_secure_storage/flutter_secure_storage.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:home_pocket/data/app_database.dart';
    import 'package:home_pocket/infrastructure/security/audit_logger.dart';
    import 'package:home_pocket/infrastructure/security/providers.dart';
    import 'package:home_pocket/infrastructure/security/secure_storage_service.dart';
    import 'package:mocktail/mocktail.dart';

    class _FakeSecureStorage extends Mock implements FlutterSecureStorage {}

    void main() {
      group('appDatabaseProvider current behavior (PRE-Plan-03-02)', () {
        test('throws when read without override (current placeholder)', () {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          expect(
            () => container.read(appDatabaseProvider),
            throwsA(
              // BEFORE Plan 03-02: UnimplementedError
              // AFTER Plan 03-02: StateError (Plan 03-02 Task 3 replaces this assertion)
              anyOf(
                isA<UnimplementedError>(),
                isA<StateError>(),
              ),
            ),
          );
        });

        test('returns the supplied AppDatabase when overrideWithValue applied', () {
          final db = AppDatabase.forTesting();
          addTearDown(db.close);
          final container = ProviderContainer(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
          );
          addTearDown(container.dispose);
          expect(identical(container.read(appDatabaseProvider), db), isTrue);
        });
      });

      group('auditLoggerProvider wiring', () {
        test('resolves when appDatabaseProvider and flutterSecureStorageProvider overridden', () {
          final db = AppDatabase.forTesting();
          addTearDown(db.close);
          final fakeStorage = _FakeSecureStorage();
          final container = ProviderContainer(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              flutterSecureStorageProvider.overrideWithValue(fakeStorage),
            ],
          );
          addTearDown(container.dispose);

          final logger = container.read(auditLoggerProvider);
          expect(logger, isA<AuditLogger>());
        });
      });

      group('secureStorageServiceProvider wiring', () {
        test('resolves to a SecureStorageService when storage overridden', () {
          final fakeStorage = _FakeSecureStorage();
          final container = ProviderContainer(
            overrides: [
              flutterSecureStorageProvider.overrideWithValue(fakeStorage),
            ],
          );
          addTearDown(container.dispose);
          expect(container.read(secureStorageServiceProvider),
              isA<SecureStorageService>());
        });
      });
    }
    ```

    Note: the first test uses `anyOf(isA<UnimplementedError>(), isA<StateError>())` — accepts BOTH the pre-Plan-03-02 (`UnimplementedError`) AND post-Plan-03-02 (`StateError`) behaviors so the test stays GREEN before AND after Plan 03-02. Plan 03-02 Task 3's `providers_test.dart` (a different file) carries the strict `StateError`-only assertions for the post-refactor world.

    Verify:
    1. `flutter test test/infrastructure/security/providers_characterization_test.dart` exits 0
    2. `dart run scripts/coverage_gate.dart --files lib/infrastructure/security/providers.dart --threshold 80 --lcov coverage/lcov_clean.info` exits 0

    Commit message: `test(03-05): add characterization test for security/providers.dart (Plan 03-02 dependency)`.
  </action>
  <verify>
    <automated>flutter test test/infrastructure/security/providers_characterization_test.dart</automated>
  </verify>
  <acceptance_criteria>
    - `test -f test/infrastructure/security/providers_characterization_test.dart` exits 0
    - `grep -q "appDatabaseProvider" test/infrastructure/security/providers_characterization_test.dart` exits 0
    - `grep -q "auditLoggerProvider" test/infrastructure/security/providers_characterization_test.dart` exits 0
    - `grep -q "anyOf(" test/infrastructure/security/providers_characterization_test.dart` exits 0 (accepts both UnimplementedError AND StateError)
    - `grep -q "AppDatabase.forTesting()" test/infrastructure/security/providers_characterization_test.dart` exits 0
    - `! grep "package:mockito" test/infrastructure/security/providers_characterization_test.dart` exits 0
    - `flutter test test/infrastructure/security/providers_characterization_test.dart` exits 0 (passes against CURRENT codebase)
    - `dart run scripts/coverage_gate.dart --files lib/infrastructure/security/providers.dart --threshold 80 --lcov coverage/lcov_clean.info` exits 0
  </acceptance_criteria>
  <done>providers.dart pre/post-Plan-03-02 characterization test green; coverage ≥80%; auditLogger + secureStorageService wirings locked.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 4: Smoke characterization test for `lib/main.dart` (CRIT-05 D-15 strict per RESEARCH.md Q2)</name>
  <files>
    test/main_characterization_smoke_test.dart
  </files>
  <read_first>
    - lib/main.dart (current full file — covering both `main()` and `_HomePocketApp` / `_HomePocketAppState` lines 85-196)
    - .planning/phases/03-critical-fixes/03-RESEARCH.md (§"Open Questions" Q2 — recommendation: smoke testWidgets covering _initialized=true and _error != null branches)
    - .planning/phases/03-critical-fixes/03-PATTERNS.md (§"`lib/main.dart` (MODIFIED — delegate to AppInitializer)")
    - test/helpers/test_localizations.dart (existing helper for localized widget pumps — usable here)
    - lib/features/home/presentation/screens/main_shell_screen.dart (existing — to know what to find when _initialized branch resolves)
  </read_first>
  <behavior>
    - Smoke `testWidgets` exercising `_HomePocketAppState._buildHome` for both observable branches:
      1. `_error != null` branch → renders Scaffold + error AppBar text
      2. `_initialized && _bookId != null && !_needsProfileOnboarding` branch → reaches `MainShellScreen(bookId: ...)`
    - The test does NOT call `runApp` directly (that requires SQLCipher native library + flutter_secure_storage); instead it pumps `HomePocketApp` inside an `UncontrolledProviderScope` with overrides that bypass real database/secure-storage paths, supplying enough stubs so `_HomePocketAppState._initialize()` can reach the desired terminal state
    - Achieves ≥80% coverage on `lib/main.dart` per `coverage_gate.dart`
    - Survives Plan 03-02 Task 6 refactor (delegation to AppInitializer): the test asserts post-refactor that `_HomePocketApp`'s build branches still produce the expected widgets given a properly-overridden ProviderContainer
  </behavior>
  <action>
    Read `lib/main.dart` in full. Note the structure:
    - `main()` does init + `runApp`
    - `HomePocketApp` is a `ConsumerStatefulWidget`
    - `_HomePocketAppState._initialize()` runs seedCategories + ensureDefaultBook + syncEngine init + push notification + getUserProfile
    - `_buildHome()` returns: `Scaffold` (error case), `CircularProgressIndicator` (not initialized), `ProfileOnboardingScreen` (initialized but no profile), `MainShellScreen` (initialized + has profile)

    Write `test/main_characterization_smoke_test.dart`:

    ```dart
    // Smoke characterization test for lib/main.dart's _HomePocketApp shell.
    //
    // Per CRIT-05 D-15 strict + RESEARCH.md Q2 recommendation: even though
    // main.dart is mostly UI scaffolding, write a smoke testWidgets covering
    // the _initialized=true and _error != null observable branches in
    // _HomePocketAppState._buildHome. Plan 03-02 Task 6's _InitFailureApp
    // widget test complements this characterization (the InitFailureApp
    // wrapper is the new failure-shell; HomePocketApp is the success-path shell).

    import 'package:flutter/material.dart';
    import 'package:flutter_localizations/flutter_localizations.dart';
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:home_pocket/data/app_database.dart';
    import 'package:home_pocket/generated/app_localizations.dart';
    import 'package:home_pocket/infrastructure/security/providers.dart';
    import 'package:home_pocket/main.dart';
    import 'package:mocktail/mocktail.dart';

    // (Add additional imports for the providers _initialize() reads:
    //   seedCategoriesUseCaseProvider, ensureDefaultBookUseCaseProvider,
    //   syncEngineProvider, pushNotificationServiceProvider,
    //   getUserProfileUseCaseProvider, currentLocaleProvider, appSettingsProvider)
    // and Mocktail fakes for each of these.

    void main() {
      // Helper: pump HomePocketApp inside an UncontrolledProviderScope with
      // overrides that drive _HomePocketAppState._initialize() to the desired
      // terminal state.
      Future<void> _pumpApp(
        WidgetTester tester, {
        required List<Override> overrides,
      }) async {
        final container = ProviderContainer(overrides: overrides);
        addTearDown(container.dispose);
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: const HomePocketApp(),
        ));
      }

      testWidgets(
          'renders MainShellScreen on success path with existing profile',
          (tester) async {
        // Stub: seedCategories.execute() returns success;
        // ensureDefaultBook.execute() returns success with a Book(id: 'book-1');
        // syncEngine.initialize() and connectPushNotifications no-op;
        // getUserProfile returns a non-null profile (so _needsProfileOnboarding == false)
        await _pumpApp(tester, overrides: [
          appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
          // ... additional stubbed providers ...
        ]);
        await tester.pumpAndSettle();
        expect(find.byType(MainShellScreen), findsOneWidget);
      });

      testWidgets('renders error Scaffold when _initialize sets _error',
          (tester) async {
        // Stub: ensureDefaultBook.execute() throws or returns Result.error('boom')
        await _pumpApp(tester, overrides: [
          appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
          // ... seedCategories stub returns success, ensureDefaultBook stub throws ...
        ]);
        await tester.pumpAndSettle();
        // The error path renders Scaffold with AppBar(title: error) and Center(Text(initializationError(...)))
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('renders ProfileOnboardingScreen when profile is null',
          (tester) async {
        // Stub: ensureDefaultBook returns success, getUserProfile returns null
        await _pumpApp(tester, overrides: [
          appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
          // ... profile stubbed to null ...
        ]);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileOnboardingScreen), findsOneWidget);
      });
    }
    ```

    Note on practicality: the actual stubs for `seedCategoriesUseCaseProvider`, `ensureDefaultBookUseCaseProvider`, `syncEngineProvider`, etc. require Mocktail fakes that match each provider's return type (a Use Case class that has `execute()`). The executor reads `lib/main.dart` and the provider chain to determine the exact set of overrides needed. If the dependency graph proves too deep to stub cleanly, the test can scope down to ONLY the `_error != null` and `_initialized` branches that DO NOT require the full `_initialize()` chain — e.g., by injecting a partially-initialized `_HomePocketApp` via testing helpers, OR by skipping the `_initialize()` call and asserting the build tree given pre-set state. **If full provider stubbing exceeds 100 lines of test setup, the executor should pivot to a lighter-weight approach: pump just the `_buildHome()` method's output via a mini-harness widget that exposes the same conditional tree.** Document the chosen approach in the test file's header comment.

    Verify:
    1. `flutter test test/main_characterization_smoke_test.dart` exits 0
    2. Coverage protocol — see acceptance criteria below for the deferred-final-gate procedure (`coverage_gate.dart` may legitimately fail on standalone `lib/main.dart` because Plan 03-02 Task 6's `main_smoke_test.dart` will land later; the combined post-Wave-2 coverage closes the gap).

    Commit message: `test(03-05): add smoke characterization test for main.dart (Plan 03-02 dependency)`.
  </action>
  <verify>
    <automated>flutter test test/main_characterization_smoke_test.dart</automated>
  </verify>
  <acceptance_criteria>
    - `test -f test/main_characterization_smoke_test.dart` exits 0
    - `grep -q "HomePocketApp" test/main_characterization_smoke_test.dart` exits 0
    - `grep -q "UncontrolledProviderScope" test/main_characterization_smoke_test.dart` exits 0
    - `! grep "package:mockito" test/main_characterization_smoke_test.dart` exits 0
    - `flutter test test/main_characterization_smoke_test.dart` exits 0 (passes against current pre-Plan-03-02 codebase)
    - **Coverage protocol — deferred-final-gate (per checker nit fix #6):** If `dart run scripts/coverage_gate.dart --files lib/main.dart --threshold 80 --lcov coverage/lcov_clean.info` reports `lib/main.dart` standalone coverage <80% from `main_characterization_smoke_test.dart` alone, then:
        (a) Mark Plan 03-05 Task 4's coverage_gate run as `deferred-final-gate` in `.planning/phases/03-critical-fixes/03-05-SUMMARY.md` (record the standalone coverage % observed).
        (b) Plan 03-05 may still merge — Task 5's full-suite gate continues with a documented note.
        (c) Wait until Plan 03-02 Task 6 (`test/main_smoke_test.dart`) merges into main.
        (d) Then re-run, AS THE FINAL GATE, against the combined post-Wave-2 lcov_clean.info:
            ```
            flutter test --coverage
            coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info --mode w --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'
            dart run scripts/coverage_gate.dart --files lib/main.dart --threshold 80 --lcov coverage/lcov_clean.info
            ```
            This combined run MUST exit 0. Both `main_characterization_smoke_test.dart` (this task) AND `main_smoke_test.dart` (Plan 03-02 Task 6) contribute coverage to the same `lib/main.dart` source file; together they reach ≥80%.
        (e) **Phase 3 close gate** (Plan 03-01 Task 4 audit.yml flip) WAITS on this combined-coverage check passing. The audit.yml blocking flip is the LAST commit of Phase 3 (D-17); it cannot land until this final coverage gate exits 0. Plan 03-01 Task 4's gating condition explicitly checks for zero open CRITICALs in `issues.json` — extend its pre-flight to also check this combined coverage report.
        (f) If the combined coverage STILL falls short of 80% (rare — would indicate `lib/main.dart` has a chunk neither test exercises), surface to orchestrator BEFORE the Phase 3 close. Treat as a Phase 3 blocker, not a deferral.
  </acceptance_criteria>
  <done>main.dart smoke characterization test GREEN at submission; combined with Plan 03-02 Task 6's main_smoke_test.dart, coverage on lib/main.dart reaches ≥80% via the deferred-final-gate protocol; Phase 3 close gate (Plan 03-01 Task 4) inherits the requirement.</done>
</task>

<task type="auto">
  <name>Task 5: Final per-plan exit gate — full suite + coverage gate against the frozen intersection</name>
  <files></files>
  <read_first>
    - .planning/phases/03-critical-fixes/03-VALIDATION.md (§"Sampling Rate" — per-plan acceptance contract)
    - .planning/phases/03-critical-fixes/03-RESEARCH.md (§"Code Examples — Coverage-gate invocation pattern")
    - /tmp/phase3-plan05-intersection.txt (frozen list from Task 1)
  </read_first>
  <action>
    Run, in order, all must exit 0:
    1. `flutter analyze --no-fatal-infos`
    2. `dart run custom_lint`
    3. `flutter test`
    4. `flutter test --coverage`
    5. `coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info --mode w --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'`
    6. `dart run scripts/coverage_gate.dart --list /tmp/phase3-plan05-intersection.txt --threshold 80 --lcov coverage/lcov_clean.info`

    Each of the 5 files in the frozen intersection MUST reach ≥80% coverage. EXCEPTION: if `lib/main.dart` standalone coverage <80% from this plan's tests alone, follow Task 4's deferred-final-gate protocol — Plan 03-05 may still merge with the deferral noted in 03-05-SUMMARY.md, and the combined coverage with Plan 03-02 Task 6's `main_smoke_test.dart` becomes the binding check at Phase 3 close (Plan 03-01 Task 4 gates on it).

    For all OTHER 4 files in the intersection, the gate is strict at submission time. If any falls short, adjust tests in Tasks 1-3 BEFORE merging Plan 03-05.

    Coordinate with Plans 03-02/03/04: their per-plan coverage gates re-run against the same files post-refactor and must also pass. If pre-refactor coverage is borderline, add tests now (Plan 03-05) so post-refactor margin is safe.

    Record the per-file coverage percentages — including any deferred-final-gate note for `lib/main.dart` — in `.planning/phases/03-critical-fixes/03-05-SUMMARY.md` for traceability.
  </action>
  <verify>
    <automated>flutter analyze --no-fatal-infos &amp;&amp; dart run custom_lint &amp;&amp; flutter test &amp;&amp; dart run scripts/coverage_gate.dart --list /tmp/phase3-plan05-intersection.txt --threshold 80 --lcov coverage/lcov_clean.info</automated>
  </verify>
  <acceptance_criteria>
    - `flutter analyze --no-fatal-infos` exits 0
    - `dart run custom_lint` exits 0
    - `flutter test` exits 0 (full suite GREEN — including the 5 new characterization tests)
    - `dart run scripts/coverage_gate.dart --list /tmp/phase3-plan05-intersection.txt --threshold 80 --lcov coverage/lcov_clean.info` exits 0 — OR — the gate fails ONLY on `lib/main.dart` standalone, in which case `.planning/phases/03-critical-fixes/03-05-SUMMARY.md` records the deferred-final-gate note per Task 4 acceptance and Plan 03-01 Task 4 inherits the combined-coverage gating condition
    - 4 files in the intersection (excluding `lib/main.dart` if deferred) reach ≥80% coverage at Plan 03-05 submission per `lcov_clean.info`
    - `.planning/phases/03-critical-fixes/03-05-SUMMARY.md` records per-file coverage percentages AND, if applicable, the deferred-final-gate note for `lib/main.dart` plus the Phase 3 close cross-link to Plan 03-01 Task 4
  </acceptance_criteria>
  <done>Phase 3 Plan 05 ready to merge; all characterization tests GREEN against pre-refactor codebase; coverage baseline locked for Plans 03-02/03/04 to inherit; lib/main.dart deferred-final-gate (if needed) is documented and gated on Plan 03-01 Task 4 combined-coverage check.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Test → real flutter_secure_storage | NEVER reached; FUTURE-ARCH-04 protection |
| Test → SQLCipher | NEVER reached; AppDatabase.forTesting() (in-memory) only |
| Mocktail fakes → production interfaces | Tests use stubs, not real implementations |
| Pre-refactor test → post-refactor test | Test imports from CURRENT path; Plan 03-02/03/04 rewrite imports as part of their refactors |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-03-05-01 | Tampering | Test accidentally exercises real `flutter_secure_storage` (FUTURE-ARCH-04) | mitigate | Acceptance criterion `! grep "flutter_secure_storage" <test_file>` enforced on every Plan 03-05 test file. Mocktail fakes substitute. |
| T-03-05-02 | Tampering | Test accidentally calls `recoverFromSeed()` and triggers FUTURE-ARCH-04 key-overwrite bug | mitigate | Mocktail fakes for MasterKeyRepository/KeyManager only respond to stubbed methods; `recoverFromSeed` is never in the stub set |
| T-03-05-03 | Repudiation | "We didn't actually verify behavior pre-refactor" | mitigate | Each task includes step "verify the test runs GREEN against the CURRENT (pre-move) production code" before commit |
| T-03-05-04 | Tampering | Plan 03-05 ships tests against the WRONG path because Plan 03-03 already moved files mid-execution | mitigate | Wave 1 parallel ordering: 03-05 tests written PRE-move using current paths; Plan 03-03 rewrites the imports as part of its `git mv`. Document in Plan 03-03 Task 5's per-file rewrite step |
| T-03-05-05 | Information Disclosure | None — tests only exercise observable behavior | accept | No secrets in test fixtures |

**Security block on:** HIGH (per security_threat_model_gate). All threats above MITIGATED.
</threat_model>

<verification>
**Per-plan exit gates** (Task 5 enforces all):
- `flutter analyze --no-fatal-infos` exits 0 (CRIT-06)
- `dart run custom_lint` exits 0 (CRIT-06)
- `flutter test` exits 0 (full suite GREEN)
- `dart run scripts/coverage_gate.dart --list /tmp/phase3-plan05-intersection.txt --threshold 80 --lcov coverage/lcov_clean.info` exits 0 (CRIT-05 D-15) — with the documented deferred-final-gate exception for `lib/main.dart` per Task 4 acceptance, gated at Phase 3 close on Plan 03-01 Task 4
- 4 source files in the frozen intersection reach ≥80% coverage at Plan 03-05 submission; `lib/main.dart` reaches ≥80% combined with Plan 03-02 Task 6

**Manual verification:** None — all exit gates are automated.
</verification>

<success_criteria>
- 5 NEW characterization test files exist
- Frozen intersection list at `/tmp/phase3-plan05-intersection.txt` (5 entries)
- All tests pass against the CURRENT (pre-refactor) codebase
- 4 files in the intersection reach ≥80% coverage at submission per `coverage_gate.dart`
- `lib/main.dart` reaches ≥80% combined coverage with Plan 03-02 Task 6's `main_smoke_test.dart` (deferred-final-gate); Plan 03-01 Task 4 inherits the gating condition
- All tests use Mocktail-style fakes (no Mockito codegen)
- All tests avoid `flutter_secure_storage` and `recoverFromSeed()`
- Operational repo lock (D-16) honored — Plan 03-05 ships under the lock; Plan 03-02/03/04 inherit
</success_criteria>

<output>
After completion, create `.planning/phases/03-critical-fixes/03-05-SUMMARY.md` recording: the frozen intersection (5 entries), per-file coverage percentages from the final gate run (with explicit deferred-final-gate note for `lib/main.dart` if the standalone coverage falls below 80%), the cross-link to Plan 03-01 Task 4 for the combined post-Wave-2 coverage check, the Mocktail fake patterns established (which Phase 4 HIGH-07 inherits as prior art), and a confirmation that all tests pass against the pre-refactor codebase.

Generate `doc/worklog/YYYYMMDD_HHMM_phase3_plan05_characterization_tests.md` per `.claude/rules/worklog.md`.
</output>
