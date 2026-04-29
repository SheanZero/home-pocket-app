---
phase: 04-high-fixes
plan: 04
type: execute
wave: 1
depends_on:
  - 04-06
files_modified:
  - test/integration/sync/bill_sync_round_trip_test.dart
  - test/integration/sync/bill_sync_round_trip_test.mocks.dart
  - test/unit/application/accounting/create_transaction_use_case_test.dart
  - test/unit/application/accounting/create_transaction_use_case_test.mocks.dart
  - test/unit/application/accounting/delete_transaction_use_case_test.dart
  - test/unit/application/accounting/delete_transaction_use_case_test.mocks.dart
  - test/unit/application/accounting/ensure_default_book_use_case_test.dart
  - test/unit/application/accounting/ensure_default_book_use_case_test.mocks.dart
  - test/unit/application/accounting/get_transactions_use_case_test.dart
  - test/unit/application/accounting/get_transactions_use_case_test.mocks.dart
  - test/unit/application/accounting/seed_categories_use_case_test.dart
  - test/unit/application/accounting/seed_categories_use_case_test.mocks.dart
  - test/unit/application/voice/fuzzy_category_matcher_test.dart
  - test/unit/application/voice/fuzzy_category_matcher_test.mocks.dart
  - test/unit/application/voice/parse_voice_input_use_case_test.dart
  - test/unit/application/voice/parse_voice_input_use_case_test.mocks.dart
  - test/unit/application/voice/record_category_correction_use_case_test.dart
  - test/unit/application/voice/record_category_correction_use_case_test.mocks.dart
  - test/unit/application/family_sync/apply_sync_operations_use_case_test.dart
  - test/unit/application/family_sync/apply_sync_operations_use_case_test.mocks.dart
  - test/unit/application/family_sync/shadow_book_service_test.dart
  - test/unit/application/family_sync/shadow_book_service_test.mocks.dart
  - test/unit/data/repositories/transaction_repository_impl_test.dart
  - test/unit/data/repositories/transaction_repository_impl_test.mocks.dart
  - test/unit/features/home/presentation/providers/today_transactions_provider_test.dart
  - test/unit/features/home/presentation/providers/today_transactions_provider_test.mocks.dart
  - pubspec.yaml
autonomous: true
requirements:
  - HIGH-07
tags:
  - mocktail_migration
  - test_infra
  - high_fixes
must_haves:
  goals:
    - "13 `*.mocks.dart` files (excluding RLS-test mock deleted by Plan 04-03 per D-14) and their `@GenerateMocks`/`build_runner` mockito artifacts are gone; all 13 corresponding `_test.dart` files use inline Mocktail-style hand-written fakes (`class _Mock<X> extends Mock implements X {}`); `mockito` removed from `pubspec.yaml dev_dependencies` if no transitive consumer remains (HIGH-07 + CONTEXT.md D-08, D-09, D-10, D-11)"
  truths:
    - "Repo lock active throughout Phase 4 (CONTEXT.md D-19 + .planning/audit/REPO-LOCK-POLICY.md) — only Phase 4 cleanup PRs merge to main"
    - "coverage_gate.dart enforced per-plan only; CI integration deferred to Phase 6 (CONTEXT.md D-21)"
    - "import_guard remains BLOCKING (Phase 3 D-17 flip)"
    - "Wave 1 — depends on Plan 04-06 (Wave 0). Per CONTEXT.md D-17 strict: Plan 04-06's characterization tests for the 12 source files this plan\'s migrated tests cover MUST land BEFORE this plan modifies the test files so coverage_gate.dart can pass at this plan\'s exit gate. Plan 04-04 is parallel to Plan 04-03 within Wave 1"
    - "Mocktail-only test convention (Phase 4 de-facto from this plan forward) — `class _MockX extends Mock implements X` with `import 'package:mocktail/mocktail.dart';` only"
    - "Inline fakes per CONTEXT.md D-10 — no new `test/_fakes/` directory; if a fake is needed by multiple tests, duplicate it (acceptable cost)"
    - "Per CONTEXT.md D-11 — no NEW Mockito mocks generated for previously-uncovered files; existing 14-file coverage is migrated 1-to-1, then 13 actually migrated since Plan 04-03 deletes the 14th (RLS test mock)"
    - "Plan 04-03 (Wave 1, parallel) deletes `resolve_ledger_type_service_test.mocks.dart` per its commit 5 — Plan 04-04 explicitly EXCLUDES that file from its 13-fixture migration list (CONTEXT.md D-14)"
    - "Mocktail closure-wrapped stub style: `when(() => mock.method(any())).thenAnswer(...)` (NOT Mockito's `when(mock.method(any)).thenAnswer(...)`)"
    - "After this plan: `find test -name '*.mocks.dart'` returns 0 results; `grep -rn 'package:mockito' test/' returns 0 matches; `grep -rn '@GenerateMocks' test/' returns 0 matches"
    - "Plan 04-06 (Wave 0) characterization tests already follow Mocktail-only convention — Plan 04-04 doesn't touch them; this plan migrates only the 13 EXISTING Mockito-using tests"
  artifacts:
    - path: "pubspec.yaml"
      provides: "EDITED — `mockito` removed from `dev_dependencies` (or kept with comment if transitive consumer exists; documented in summary)"
    - path: "test/integration/sync/bill_sync_round_trip_test.mocks.dart"
      provides: "DELETED"
    - path: "test/unit/application/accounting/*_test.mocks.dart"
      provides: "DELETED — 5 files (create, delete, ensure_default_book, get_transactions, seed_categories)"
    - path: "test/unit/application/voice/*_test.mocks.dart"
      provides: "DELETED — 3 files (fuzzy_category_matcher, parse_voice_input_use_case, record_category_correction_use_case)"
    - path: "test/unit/application/family_sync/apply_sync_operations_use_case_test.mocks.dart"
      provides: "DELETED"
    - path: "test/unit/application/family_sync/shadow_book_service_test.mocks.dart"
      provides: "DELETED"
    - path: "test/unit/data/repositories/transaction_repository_impl_test.mocks.dart"
      provides: "DELETED"
    - path: "test/unit/features/home/presentation/providers/today_transactions_provider_test.mocks.dart"
      provides: "DELETED"
  key_links:
    - from: "Plan 04-03 commit 5"
      to: "Plan 04-04 scope exclusion"
      via: "D-14 cross-coordination — `resolve_ledger_type_service_test.mocks.dart` is NOT in this plan's migration list"
      pattern: "resolve_ledger_type_service_test\\.mocks\\.dart"
    - from: "Plan 04-04 (this plan)"
      to: "Plan 04-06 (Wave 0)"
      via: "Plan 04-06 already follows Mocktail-only convention; this plan retroactively converts the 13 legacy Mockito tests to match. Also satisfies depends_on prerequisite — Plan 04-06 lands characterization tests for the source files covered by these tests BEFORE this plan modifies them (CONTEXT.md D-17 strict)"
      pattern: "extends Mock implements"
---

<objective>
Plan 04-04 is the **Mocktail big-bang migration** (HIGH-07). It deletes 13 `*.mocks.dart` files and converts the 13 corresponding `_test.dart` files to use inline Mocktail-style hand-written fakes (`class _Mock<X> extends Mock implements X {}`). It also removes `mockito` from `pubspec.yaml dev_dependencies` if no transitive consumer remains.

Per CONTEXT.md D-09: this is a single-PR big-bang migration to make Mocktail conventions land cohesively across the repo. Per D-10: fakes are inline in each test file (no shared `test/_fakes/` directory). Per D-14: `resolve_ledger_type_service_test.mocks.dart` is EXCLUDED from this plan's 13-fixture migration list — Plan 04-03 deletes it.

Per CONTEXT.md `<specifics>` 4th bullet: "Mocktail migration is the de-facto Phase 4+ test convention." After this plan lands, every new test in the project uses Mocktail.

Output: HIGH-07 closed; `find test -name '*.mocks.dart'` returns 0; `grep -rn 'package:mockito' test/` returns 0; `grep -rn '@GenerateMocks' test/` returns 0; `flutter test` GREEN; coverage_gate.dart exits 0 on touched test files.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/04-high-fixes/04-CONTEXT.md
@.planning/phases/04-high-fixes/04-PATTERNS.md
@.planning/audit/REPO-LOCK-POLICY.md
@CLAUDE.md

<!-- Mocktail-only template (the gold standard) -->
@test/unit/application/family_sync/create_group_use_case_test.dart

<!-- Phase 3 hand-written fake pattern -->
@test/core/initialization/app_initializer_test.dart

<!-- Files this plan migrates (read each before editing) — sample 3 representative ones -->
@test/unit/application/family_sync/shadow_book_service_test.dart
@test/unit/application/accounting/create_transaction_use_case_test.dart
@test/unit/data/repositories/transaction_repository_impl_test.dart

@pubspec.yaml

<interfaces>
<!-- Migration delta: Mockito → Mocktail -->

BEFORE (Mockito codegen):
```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FieldEncryptionService])
import 'shadow_book_service_test.mocks.dart';

void main() {
  late MockFieldEncryptionService mockEncryption;
  setUp(() {
    mockEncryption = MockFieldEncryptionService();
    when(mockEncryption.encryptField(any)).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
  });
}
```

AFTER (Mocktail inline):
```dart
import 'package:mocktail/mocktail.dart';

class _MockFieldEncryptionService extends Mock implements FieldEncryptionService {}

void main() {
  late _MockFieldEncryptionService mockEncryption;
  setUp(() {
    mockEncryption = _MockFieldEncryptionService();
    when(() => mockEncryption.encryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
  });
}
```

Key syntactic differences (Mockito → Mocktail):
- `import 'package:mockito/...'` → `import 'package:mocktail/mocktail.dart'`
- `MockX` (codegen) → `_MockX extends Mock implements X` (private inline class)
- `when(mock.foo(any))` → `when(() => mock.foo(any()))` (closure-wrapped + `any()` parens)
- `@GenerateMocks([X])` → DELETED entirely
- `import 'foo_test.mocks.dart'` → DELETED entirely
- `verify(mock.foo(any))` → `verify(() => mock.foo(any()))`
- `verifyNever(mock.foo(any))` → `verifyNever(() => mock.foo(any()))`

For complex types used as method args, Mocktail requires `registerFallbackValue(...)` calls in setUpAll if the type isn't built-in.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Verify mocktail dev_dep present + ensure registerFallbackValue infra</name>
  <files>pubspec.yaml</files>
  <read_first>
    - pubspec.yaml (full file — verify `mocktail:` is in `dev_dependencies` already; if not, add it)
    - test/unit/application/family_sync/create_group_use_case_test.dart (template that already uses mocktail successfully)
  </read_first>
  <action>
    1. Open `pubspec.yaml` and scan `dev_dependencies` for `mocktail:`. If present (Phase 3 should have added it for `app_initializer_test.dart`), no change needed in this task. If absent, add `mocktail: ^1.0.0` (or whatever pinned version Phase 3 settled on — check `pubspec.lock` for the resolved version).
    2. Run `flutter pub get` to confirm clean resolution.
    3. Do NOT remove `mockito` yet — Task 5 handles that after all 13 tests are migrated.

    Then commit (only if pubspec changed):
    ```
    chore(04-04): ensure mocktail dev_dep present (HIGH-07 prep)
    ```
  </action>
  <verify>
    <automated>grep -E "^\s+mocktail:" pubspec.yaml; flutter pub get 2>&amp;1 | tail -3</automated>
  </verify>
  <acceptance_criteria>
    - `grep "mocktail:" pubspec.yaml` returns at least 1 match in `dev_dependencies` block
    - `flutter pub get` exits 0
  </acceptance_criteria>
  <done>
    Mocktail dependency confirmed; ready for migration tasks.
  </done>
</task>

<task type="auto">
  <name>Task 2: Migrate 5 accounting + 3 voice tests (8 files)</name>
  <files>
    test/unit/application/accounting/create_transaction_use_case_test.dart,
    test/unit/application/accounting/create_transaction_use_case_test.mocks.dart,
    test/unit/application/accounting/delete_transaction_use_case_test.dart,
    test/unit/application/accounting/delete_transaction_use_case_test.mocks.dart,
    test/unit/application/accounting/ensure_default_book_use_case_test.dart,
    test/unit/application/accounting/ensure_default_book_use_case_test.mocks.dart,
    test/unit/application/accounting/get_transactions_use_case_test.dart,
    test/unit/application/accounting/get_transactions_use_case_test.mocks.dart,
    test/unit/application/accounting/seed_categories_use_case_test.dart,
    test/unit/application/accounting/seed_categories_use_case_test.mocks.dart,
    test/unit/application/voice/fuzzy_category_matcher_test.dart,
    test/unit/application/voice/fuzzy_category_matcher_test.mocks.dart,
    test/unit/application/voice/parse_voice_input_use_case_test.dart,
    test/unit/application/voice/parse_voice_input_use_case_test.mocks.dart,
    test/unit/application/voice/record_category_correction_use_case_test.dart,
    test/unit/application/voice/record_category_correction_use_case_test.mocks.dart
  </files>
  <read_first>
    - All 8 `_test.dart` files in scope (read full to understand current Mockito usage)
    - test/unit/application/family_sync/create_group_use_case_test.dart (Mocktail template)
  </read_first>
  <action>
    For each of the 8 `_test.dart` files (5 accounting + 3 voice), apply the Mockito→Mocktail migration delta:

    1. Replace `import 'package:mockito/annotations.dart';` and `import 'package:mockito/mockito.dart';` with `import 'package:mocktail/mocktail.dart';`.
    2. Remove `@GenerateMocks([...])` annotation entirely (along with its closing comment).
    3. Remove `import '<filename>_test.mocks.dart';`.
    4. For each `MockX` referenced in the test, declare an inline private class at the top of the file: `class _MockX extends Mock implements X {}`. Use `_Mock` prefix to keep it private to the file.
    5. Replace `MockX()` constructor calls with `_MockX()`.
    6. Convert every Mockito stub call to Mocktail closure-wrapped style:
       - `when(mock.foo(any)).thenAnswer(...)` → `when(() => mock.foo(any())).thenAnswer(...)`
       - `when(mock.bar()).thenReturn(x)` → `when(() => mock.bar()).thenReturn(x)`
       - `verify(mock.foo(any))` → `verify(() => mock.foo(any()))`
       - `verifyNever(mock.foo(any))` → `verifyNever(() => mock.foo(any()))`
    7. For methods that take complex (non-built-in) typed arguments, add `setUpAll(() { registerFallbackValue(SomeFakeInstance()); });` at the top of `main()`. The `SomeFakeInstance` should be the simplest constructible instance of the type (or a `class _FakeX extends Fake implements X {}` if construction is hard).
    8. After editing, delete the corresponding `*.mocks.dart` file: `git rm test/.../<file>_test.mocks.dart`.
    9. Run `flutter test test/unit/application/accounting/<file>_test.dart` (and similarly for voice) and ensure GREEN.

    Commit pattern (one commit per test file is preferred for bisect safety, but bundling 8 in one commit is acceptable per CONTEXT.md D-09 "single-PR big-bang"):
    ```
    test(04-04): migrate accounting + voice tests to Mocktail (HIGH-07 part 1 of 3)
    ```
  </action>
  <verify>
    <automated>flutter test test/unit/application/accounting/ test/unit/application/voice/ 2>&amp;1 | tail -10; find test/unit/application/accounting test/unit/application/voice -name "*.mocks.dart"</automated>
  </verify>
  <acceptance_criteria>
    - `find test/unit/application/accounting test/unit/application/voice -name "*.mocks.dart"` returns 0 results
    - `grep -rn "package:mockito" test/unit/application/accounting/ test/unit/application/voice/` returns 0 matches
    - `grep -rn "@GenerateMocks" test/unit/application/accounting/ test/unit/application/voice/` returns 0 matches
    - `grep -c "extends Mock implements" test/unit/application/accounting/create_transaction_use_case_test.dart` returns ≥1
    - `grep -c "when(() =>" test/unit/application/accounting/create_transaction_use_case_test.dart` returns ≥1
    - `flutter test test/unit/application/accounting/ test/unit/application/voice/` exits 0
  </acceptance_criteria>
  <done>
    8 tests migrated; 8 mocks files deleted; all GREEN.
  </done>
</task>

<task type="auto">
  <name>Task 3: Migrate 2 family_sync + 1 data repository + 1 home presentation + 1 integration test (5 files)</name>
  <files>
    test/unit/application/family_sync/apply_sync_operations_use_case_test.dart,
    test/unit/application/family_sync/apply_sync_operations_use_case_test.mocks.dart,
    test/unit/application/family_sync/shadow_book_service_test.dart,
    test/unit/application/family_sync/shadow_book_service_test.mocks.dart,
    test/unit/data/repositories/transaction_repository_impl_test.dart,
    test/unit/data/repositories/transaction_repository_impl_test.mocks.dart,
    test/unit/features/home/presentation/providers/today_transactions_provider_test.dart,
    test/unit/features/home/presentation/providers/today_transactions_provider_test.mocks.dart,
    test/integration/sync/bill_sync_round_trip_test.dart,
    test/integration/sync/bill_sync_round_trip_test.mocks.dart
  </files>
  <read_first>
    - All 5 `_test.dart` files in scope (especially `shadow_book_service_test.dart` lines 9-13, 26 — Mockito-style `when(mockEncryption.encryptField(any))`)
    - test/unit/application/family_sync/create_group_use_case_test.dart (Mocktail template)
    - test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart (verify it does NOT exist — Plan 04-03 commit 5 deletes it; if still present in this Wave 1, EXIT and wait for 04-03)
  </read_first>
  <action>
    Apply the same Mockito→Mocktail migration delta from Task 2 to the remaining 5 test files:
    - `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart`
    - `test/unit/application/family_sync/shadow_book_service_test.dart`
    - `test/unit/data/repositories/transaction_repository_impl_test.dart`
    - `test/unit/features/home/presentation/providers/today_transactions_provider_test.dart`
    - `test/integration/sync/bill_sync_round_trip_test.dart`

    Specifically for `shadow_book_service_test.dart` (PATTERNS.md §11):
    - Remove `import 'package:mockito/annotations.dart';` and `import 'package:mockito/mockito.dart';` (lines 9-10)
    - Add `import 'package:mocktail/mocktail.dart';`
    - Remove `@GenerateMocks([FieldEncryptionService])` annotation (line 12)
    - Remove `import 'shadow_book_service_test.mocks.dart';` (line 13)
    - Add `class _MockFieldEncryptionService extends Mock implements FieldEncryptionService {}` at the top
    - Convert `when(mockEncryption.encryptField(any))` (line 26) to `when(() => mockEncryption.encryptField(any()))`
    - Delete `test/unit/application/family_sync/shadow_book_service_test.mocks.dart`

    Specifically for `bill_sync_round_trip_test.dart` (integration test):
    - This is an integration test — it likely uses real `AppDatabase.forTesting()` plus mocked sync clients
    - Apply the same migration pattern; integration tests have no special handling
    - Delete `test/integration/sync/bill_sync_round_trip_test.mocks.dart`

    Run `flutter test` for each migrated file and ensure GREEN.

    Then commit:
    ```
    test(04-04): migrate family_sync + data + home + integration tests to Mocktail (HIGH-07 part 2 of 3)
    ```
  </action>
  <verify>
    <automated>flutter test test/unit/application/family_sync/apply_sync_operations_use_case_test.dart test/unit/application/family_sync/shadow_book_service_test.dart test/unit/data/repositories/transaction_repository_impl_test.dart test/unit/features/home/presentation/providers/today_transactions_provider_test.dart test/integration/sync/bill_sync_round_trip_test.dart 2>&amp;1 | tail -10; find test -name "*.mocks.dart" -not -path "*resolve_ledger*"</automated>
  </verify>
  <acceptance_criteria>
    - `find test -name "*.mocks.dart"` returns 0 results (Plan 04-03 already deleted the RLS mock; Plan 04-04 deleted the other 13)
    - `grep -rn "package:mockito" test/unit/application/family_sync/apply_sync_operations_use_case_test.dart test/unit/application/family_sync/shadow_book_service_test.dart test/unit/data/repositories/transaction_repository_impl_test.dart test/unit/features/home/presentation/providers/today_transactions_provider_test.dart test/integration/sync/bill_sync_round_trip_test.dart` returns 0 matches
    - `grep -rn "@GenerateMocks" test/unit/application/family_sync/apply_sync_operations_use_case_test.dart test/unit/application/family_sync/shadow_book_service_test.dart test/unit/data/repositories/transaction_repository_impl_test.dart test/unit/features/home/presentation/providers/today_transactions_provider_test.dart test/integration/sync/bill_sync_round_trip_test.dart` returns 0 matches
    - `flutter test test/unit/application/family_sync/ test/unit/data/repositories/ test/unit/features/home/ test/integration/sync/` exits 0
  </acceptance_criteria>
  <done>
    Remaining 5 tests migrated; corresponding 5 mocks files deleted; all GREEN. After this task, `find test -name "*.mocks.dart"` returns 0.
  </done>
</task>

<task type="auto">
  <name>Task 4: Run full test suite + verify zero mocks files + zero mockito imports across the entire test/ tree</name>
  <files>(no files modified — verification only)</files>
  <read_first>
    - All previously migrated test files for evidence of completion
  </read_first>
  <action>
    Comprehensive verification pass:

    1. `find test -name "*.mocks.dart" -type f` — must return 0 results.
    2. `grep -rln "package:mockito" test/` — must return 0 matches (no test file imports mockito).
    3. `grep -rln "@GenerateMocks" test/` — must return 0 matches.
    4. `flutter test` — entire test suite must pass GREEN.
    5. `flutter analyze` — must exit 0.

    If any test file outside the documented 13-file migration list still uses Mockito (i.e., a missed file), STOP and add it to the migration list, then re-run Tasks 2/3 patterns.

    No commit needed for this task — it's verification only.
  </action>
  <verify>
    <automated>find test -name "*.mocks.dart" -type f | wc -l; grep -rln "package:mockito" test/ | wc -l; grep -rln "@GenerateMocks" test/ | wc -l; flutter test 2>&amp;1 | tail -5</automated>
  </verify>
  <acceptance_criteria>
    - `find test -name "*.mocks.dart" -type f | wc -l` returns 0
    - `grep -rln "package:mockito" test/ | wc -l` returns 0
    - `grep -rln "@GenerateMocks" test/ | wc -l` returns 0
    - `flutter test` exits 0
    - `flutter analyze` exits 0
  </acceptance_criteria>
  <done>
    Repo-wide verification confirms HIGH-07 is structurally satisfied: no mocks files, no mockito imports, no @GenerateMocks, full test suite GREEN.
  </done>
</task>

<task type="auto">
  <name>Task 5: Remove `mockito` from pubspec.yaml dev_dependencies (if no transitive consumer) + coverage gate</name>
  <files>pubspec.yaml</files>
  <read_first>
    - pubspec.yaml (full file)
    - pubspec.lock (search for `mockito` to detect transitive consumers)
  </read_first>
  <action>
    1. Search `pubspec.lock` for `mockito` entries:
       ```bash
       grep -A 2 "name: mockito" pubspec.lock
       ```
       Look at the `dependency:` field. If it says `direct dev`, `mockito` is only a direct dev_dep — safe to remove. If it says `transitive`, some other dep pulls it in — keep `mockito` in pubspec.yaml with a `# transitive: <package>` comment (per CONTEXT.md "Claude's Discretion" item 4).

    2. If safe to remove:
       - Edit `pubspec.yaml` and remove the `mockito:` line from `dev_dependencies`.
       - Edit `pubspec.yaml` and remove `build_runner: ` ONLY IF no other dev_dep needs it (Riverpod, Freezed, Drift all use it — almost certainly stays).
       - Run `flutter pub get`.
       - Run `flutter test` — must pass GREEN.

    3. If transitive consumer exists, add a comment:
       ```yaml
       dev_dependencies:
         mockito: ^5.0.0  # transitive: <package_name> still requires; remove in Phase 6
       ```

    4. Run coverage gate on the touched test files (note: test files don't really have "coverage" — coverage_gate.dart checks production source coverage. The 13 test files are not counted in lcov; this task's coverage gate target is the SOURCE files those tests cover. Per CONTEXT.md D-18: Plan 04-04 touches ~14 test files; the gate runs against the source files those tests cover, which are already ≥80% pre-Phase-4 because tests existed before — Mocktail migration is not supposed to drop coverage.). Concretely run:
       ```bash
       dart run scripts/coverage_gate.dart \
         --files lib/application/accounting/create_transaction_use_case.dart,lib/application/accounting/delete_transaction_use_case.dart,lib/application/accounting/ensure_default_book_use_case.dart,lib/application/accounting/get_transactions_use_case.dart,lib/application/accounting/seed_categories_use_case.dart,lib/application/voice/fuzzy_category_matcher.dart,lib/application/voice/parse_voice_input_use_case.dart,lib/application/voice/record_category_correction_use_case.dart,lib/application/family_sync/apply_sync_operations_use_case.dart,lib/application/family_sync/shadow_book_service.dart,lib/data/repositories/transaction_repository_impl.dart,lib/features/home/presentation/providers/today_transactions_provider.dart \
         --threshold 80 \
         --lcov coverage/lcov_clean.info
       ```
       This must exit 0.

    5. Commit:
       ```
       chore(04-04): remove mockito dev_dep + close HIGH-07 (HIGH-07 part 3 of 3)
       ```
  </action>
  <verify>
    <automated>grep -c "^\s*mockito:" pubspec.yaml || echo "0"; flutter pub get 2>&amp;1 | tail -3; flutter test 2>&amp;1 | tail -5</automated>
  </verify>
  <acceptance_criteria>
    - Either `grep -c "^\s*mockito:" pubspec.yaml` returns 0 (removed) OR the line has a `# transitive:` comment explaining why it's kept
    - `flutter pub get` exits 0
    - `flutter test` exits 0
    - `flutter analyze` exits 0
    - `dart run scripts/coverage_gate.dart --files <12 source files comma-separated> --threshold 80 --lcov coverage/lcov_clean.info` exits 0
    - `git log --oneline -1` shows commit message starting with `chore(04-04): remove mockito dev_dep + close HIGH-07`
  </acceptance_criteria>
  <done>
    HIGH-07 fully closed: no `*.mocks.dart`, no `mockito` direct dev_dep (or kept with documented transitive justification), all tests GREEN, coverage gate exits 0.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| (n/a) | This plan modifies test infrastructure only. No production code path changes; no production trust boundaries are introduced or modified. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-04-04-01 | (n/a) | test infra | accept | STRIDE analysis: Mocktail migration changes test infrastructure only — no production code path change. No new auth surface, no new IPC boundary, no new persisted secret, no new external input. The migration drops Mockito codegen artifacts which had no security relevance (test-only files). No HIGH-severity threats. |
</threat_model>

<verification>
- 13 `*.mocks.dart` files deleted (14th deleted by Plan 04-03)
- 13 `_test.dart` files use inline `class _Mock<X> extends Mock implements X {}` and `import 'package:mocktail/mocktail.dart';` only
- `find test -name "*.mocks.dart"` returns 0 results
- `grep -rln "package:mockito" test/` returns 0 matches
- `grep -rln "@GenerateMocks" test/` returns 0 matches
- `flutter test` exits 0
- `flutter analyze` exits 0
- `mockito` removed from pubspec.yaml dev_dependencies (or kept with `# transitive:` comment)
- coverage_gate.dart exits 0 on the 12 source files covered by the migrated tests
</verification>

<success_criteria>
- HIGH-07 closed: zero `*.mocks.dart`, zero Mockito imports, zero `@GenerateMocks` annotations
- Mocktail-only test convention is now de-facto Phase 4+ standard
- Plan 04-03 cross-coordination preserved (RLS-test mock deleted by 04-03; 04-04 doesn't touch it)
- Plan 04-06 characterization tests already conform — no rework needed
- All 13 migrated tests pass GREEN
- coverage_gate.dart exits 0
</success_criteria>

<output>
After completion, create `.planning/phases/04-high-fixes/04-04-SUMMARY.md` documenting:
- The 13 migrated tests + their corresponding deleted mocks files
- The mockito removal status (removed vs kept with transitive justification)
- Confirmation `find test -name "*.mocks.dart"` returns 0
- Note that Plan 04-06 already follows the convention (no rework needed)
- Sample before/after diff from `shadow_book_service_test.dart` for future reference
</output>
