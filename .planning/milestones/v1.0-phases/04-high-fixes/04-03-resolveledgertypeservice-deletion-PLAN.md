---
phase: 04-high-fixes
plan: 03
type: execute
wave: 1
depends_on:
  - 04-06
files_modified:
  - lib/application/dual_ledger/resolve_ledger_type_service.dart
  - lib/application/dual_ledger/resolve_ledger_type_service.g.dart
  - lib/features/accounting/presentation/providers/use_case_providers.dart
  - lib/features/accounting/presentation/providers/use_case_providers.g.dart
  - test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart
  - test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart
  - .planning/audit/issues.json
autonomous: true
requirements:
  - HIGH-03
tags:
  - dead_code_deletion
  - high_fixes
  - six_atomic_commits
must_haves:
  goals:
    - "ResolveLedgerTypeService is fully erased from the codebase: no source class, no provider, no generated provider line, no test, no mocks (per HIGH-03 + CONTEXT.md D-12, D-13)"
  truths:
    - "Repo lock active throughout Phase 4 (CONTEXT.md D-19 + .planning/audit/REPO-LOCK-POLICY.md) — only Phase 4 cleanup PRs merge to main"
    - "coverage_gate.dart enforced per-plan only; CI integration deferred to Phase 6 (CONTEXT.md D-21)"
    - "import_guard remains BLOCKING (Phase 3 D-17 flip) — every commit must pass import_guard cleanly"
    - "ResolveLedgerTypeService is `@Deprecated('Use CategoryService instead')` and delegates to CategoryService internally — zero production read sites confirmed by CONTEXT.md D-12 (transaction_confirm_screen.dart already uses categoryServiceProvider directly)"
    - "Six atomic commits per CONTEXT.md D-13 (mirrors Phase 3 D-09/D-10 use_cases migration pattern); each commit independently passes `flutter analyze` 0 and `flutter test` GREEN. **Task numbers in this plan match commit numbers (Task N == Commit N)** — chronological order of execution, NOT the original plan order"
    - "Wave 1 — depends on Plan 04-06 (Wave 0). Per CONTEXT.md D-17 strict: Plan 04-06's characterization tests for `lib/features/accounting/presentation/providers/use_case_providers.dart` MUST land BEFORE this plan's edits to that file so coverage_gate.dart can pass at this plan's exit gate. Plan 04-03 is parallel to Plan 04-04 within Wave 1"
    - "After commit 4 (chronological), `test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart` is GONE — Plan 04-04 (Wave 1, parallel) explicitly excludes this file from its 13-fixture migration list per CONTEXT.md D-14"
    - "After commit 6, `grep -rn 'ResolveLedgerTypeService' lib/ test/` returns 0 matches and `grep -rn 'resolveLedgerTypeService' lib/ test/` returns 0 matches"
    - "use_case_providers.dart import on line 13 (`// ignore: deprecated_member_use_from_same_package`) and line 14 (`import '../../../../application/dual_ledger/resolve_ledger_type_service.dart';`) are removed in commit 1"
    - "Generated file regeneration (commit 2) drops `_$resolveLedgerTypeServiceHash`, the internal `Provider<ResolveLedgerTypeService>`, and `ResolveLedgerTypeServiceRef` typedef from `use_case_providers.g.dart`"
    - "use_case_providers.dart shrinks but is NOT renamed/deleted in this plan — Plan 04-02 absorbs it later (folds remaining use-case providers into repository_providers.dart per CONTEXT.md D-13 commit 2 note)"
  artifacts:
    - path: "lib/application/dual_ledger/resolve_ledger_type_service.dart"
      provides: "DELETED — file MUST NOT exist after commit 3 (chronological)"
    - path: "lib/features/accounting/presentation/providers/use_case_providers.dart"
      provides: "EDITED — `resolveLedgerTypeService` provider entry removed (lines 66-74); deprecated import on lines 13-14 removed (commit 1)"
      excludes: "ResolveLedgerTypeService"
    - path: "test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart"
      provides: "DELETED — file MUST NOT exist after commit 4 (chronological)"
    - path: "test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart"
      provides: "DELETED — file MUST NOT exist after commit 5 (and Plan 04-04 must NOT include this in its migration scope per D-14)"
  key_links:
    - from: "Plan 04-04 (Wave 1, parallel)"
      to: "Plan 04-03 commit 5 (chronological)"
      via: "D-14 cross-coordination — Plan 04-04 excludes resolve_ledger_type_service_test.mocks.dart from its 13-fixture migration list"
      pattern: "resolve_ledger_type_service_test\\.mocks\\.dart"
    - from: "Plan 04-06 (Wave 0)"
      to: "Plan 04-03 prereq"
      via: "Plan 04-06's use_case_providers_characterization_test.dart locks current use_case_providers behavior BEFORE Plan 04-03 edits the file (CONTEXT.md D-17 strict)"
      pattern: "use_case_providers_characterization_test\\.dart"
---

<objective>
Plan 04-03 deletes `ResolveLedgerTypeService` and all its cascading sites in **six atomic commits** per CONTEXT.md D-13 (mirroring Phase 3 D-09/D-10's 6-commit use_cases migration pattern). The service is `@Deprecated('Use CategoryService instead')` and is pure dead code — zero production read sites exist (`transaction_confirm_screen.dart` already uses `categoryServiceProvider` directly).

**Task numbering matches chronological commit order (per Warning 4 fix):** Task N landing == Commit N landing. The "leaf-first" safe deletion order (commit 1 = remove provider entry, commit 2 = regenerate .g.dart, commit 3 = delete source file, commit 4 = delete test file, commit 5 = delete mocks file, commit 6 = verify + close) ensures `flutter analyze` exits 0 at every commit boundary.

Per CONTEXT.md D-14: Plan 04-03 runs in **Wave 1, parallel to Plan 04-04** (Mocktail big-bang). To avoid a Wave 1 internal sequencing dependency, Plan 04-04 explicitly excludes `resolve_ledger_type_service_test.mocks.dart` from its 13-fixture migration list — that file is deleted by THIS plan's commit 5.

**depends_on includes Plan 04-06 (Wave 0):** Per CONTEXT.md D-17 strict, Plan 04-06's characterization test for `lib/features/accounting/presentation/providers/use_case_providers.dart` MUST land before this plan's first commit so coverage_gate.dart passes at every per-commit boundary (the file is in `.planning/audit/files-needing-tests.txt`).

Output: HIGH-03 closed; `grep -rn 'ResolveLedgerTypeService' lib/ test/` returns 0 matches; `flutter analyze` 0; `flutter test` GREEN; coverage_gate.dart exits 0 on the 1 surviving touched file (use_case_providers.dart).
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

<!-- Files this plan deletes/edits — read each before touching -->
@lib/application/dual_ledger/resolve_ledger_type_service.dart
@lib/features/accounting/presentation/providers/use_case_providers.dart
@test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart
</context>

<tasks>

<task type="auto">
  <name>Task 1: Commit 1 — Remove `resolveLedgerTypeService` provider entry and deprecated import from `use_case_providers.dart`</name>
  <files>lib/features/accounting/presentation/providers/use_case_providers.dart</files>
  <read_first>
    - lib/features/accounting/presentation/providers/use_case_providers.dart (full file — note line 13 `// ignore: deprecated_member_use_from_same_package`, line 14 `import '../../../../application/dual_ledger/resolve_ledger_type_service.dart';`, lines 66-74 the `resolveLedgerTypeService` provider definition)
    - test/unit/features/accounting/presentation/providers/use_case_providers_characterization_test.dart (Plan 04-06 — verify this characterization test exists; it locks the pre-deletion behavior — this Task 1 commit is the FIRST modification of use_case_providers.dart since Plan 04-06 landed)
  </read_first>
  <action>
    Edit `lib/features/accounting/presentation/providers/use_case_providers.dart` and remove three regions:

    1. Line 13: `// ignore: deprecated_member_use_from_same_package`
    2. Line 14: `import '../../../../application/dual_ledger/resolve_ledger_type_service.dart';`
    3. Lines 66-74 (provider definition):
       ```dart
       // ignore: deprecated_member_use_from_same_package
       @riverpod
       ResolveLedgerTypeService resolveLedgerTypeService(Ref ref) {
         return ResolveLedgerTypeService(
           categoryRepository: ref.watch(categoryRepositoryProvider),
           ledgerConfigRepository: ref.watch(categoryLedgerConfigRepositoryProvider),
         );
       }
       ```

    Do NOT delete the entire file — `use_case_providers.dart` still contains other use-case providers; Plan 04-02 will fold what remains into `repository_providers.dart` later.

    Per Phase 3 D-10 precedent: bundle the source `.dart` edit AND the generated `.g.dart` regeneration into the SAME commit so CI never sees a stale generated file. Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate `use_case_providers.g.dart` BEFORE committing. Verify the generated file no longer contains `_$resolveLedgerTypeServiceHash`, `resolveLedgerTypeServiceProvider`, or `ResolveLedgerTypeServiceRef`. Stage both files together. (If the developer prefers the source/generated split, Task 2 lands the regen as its own commit — but the bundled approach is cleaner.)

    NOTE: After this commit, the resolveLedgerTypeService import is gone from use_case_providers.dart, but the source file `lib/application/dual_ledger/resolve_ledger_type_service.dart` STILL EXISTS. `flutter analyze` exits 0 because nothing now imports the deprecated symbol from outside its own file. Task 3 (chronological commit 3) deletes the source file — at that point also no internal references exist.

    Then commit:
    ```
    refactor(04-03): remove resolveLedgerTypeService provider entry (HIGH-03 commit 1 of 6)
    ```
  </action>
  <verify>
    <automated>flutter analyze 2>&amp;1 | tail -5; grep -c "resolveLedgerTypeService" lib/features/accounting/presentation/providers/use_case_providers.dart || true</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "ResolveLedgerTypeService" lib/features/accounting/presentation/providers/use_case_providers.dart` returns 0
    - `grep -c "resolveLedgerTypeService" lib/features/accounting/presentation/providers/use_case_providers.dart` returns 0
    - `grep -c "deprecated_member_use_from_same_package" lib/features/accounting/presentation/providers/use_case_providers.dart` returns 0
    - `flutter analyze` exits 0
    - `git log --oneline -1` shows commit message starting with `refactor(04-03): remove resolveLedgerTypeService provider entry (HIGH-03 commit 1 of 6)`
  </acceptance_criteria>
  <done>
    Provider entry removed; deprecated import removed; flutter analyze GREEN. Task numbering matches chronological commit order per Warning 4 fix.
  </done>
</task>

<task type="auto">
  <name>Task 2: Commit 2 — Regenerate use_case_providers.g.dart cleanly (separate commit ONLY if Task 1 did not bundle the regen)</name>
  <files>lib/features/accounting/presentation/providers/use_case_providers.g.dart</files>
  <read_first>
    - lib/features/accounting/presentation/providers/use_case_providers.g.dart (current state — verify `_$resolveLedgerTypeServiceHash`, `resolveLedgerTypeServiceProvider`, `ResolveLedgerTypeServiceRef` are absent if Task 1 bundled regen)
  </read_first>
  <action>
    NOTE: Task 1 (commit 1) recommends bundling the `.g.dart` regen with the source edit to keep CI green at each commit boundary (Phase 3 D-10 precedent). If that bundle happened, **this task is a no-op** — assert the bundling worked (the .g.dart already lacks the resolveLedgerTypeService symbols), skip the commit, and proceed to Task 3.

    If for some reason Task 1 committed only the source `.dart` edit without the regenerated `.g.dart`:

    1. Run `flutter pub run build_runner build --delete-conflicting-outputs`. This regenerates `use_case_providers.g.dart` to drop the references to the removed `resolveLedgerTypeService` provider.
    2. Verify the diff is clean (only deletions of the 3 symbols listed in `read_first`; no other changes).
    3. Commit:
       ```
       chore(04-03): regenerate use_case_providers.g.dart after RLS removal (HIGH-03 commit 2 of 6)
       ```

    Recommended (and default): bundle the `.g.dart` regeneration with Task 1 commit. This task is then a verification step only.
  </action>
  <verify>
    <automated>grep -c "resolveLedgerTypeService\|ResolveLedgerTypeService" lib/features/accounting/presentation/providers/use_case_providers.g.dart 2>/dev/null || echo "0"; flutter analyze 2>&amp;1 | tail -5</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "resolveLedgerTypeService" lib/features/accounting/presentation/providers/use_case_providers.g.dart` returns 0
    - `grep -c "ResolveLedgerTypeServiceRef" lib/features/accounting/presentation/providers/use_case_providers.g.dart` returns 0
    - `grep -c "_\$resolveLedgerTypeServiceHash" lib/features/accounting/presentation/providers/use_case_providers.g.dart` returns 0
    - `flutter analyze` exits 0
    - `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits 0 (no stale generated file diff)
  </acceptance_criteria>
  <done>
    Generated file is clean; no orphan references to RLS remain; CI guardrail (Phase 1 AUDIT-10) passes. If Task 1 bundled regen, this is a no-op verification step.
  </done>
</task>

<task type="auto">
  <name>Task 3: Commit 3 — Delete the source file `lib/application/dual_ledger/resolve_ledger_type_service.dart`</name>
  <files>lib/application/dual_ledger/resolve_ledger_type_service.dart</files>
  <read_first>
    - lib/application/dual_ledger/resolve_ledger_type_service.dart (full file — confirm 33 lines, `@Deprecated('Use CategoryService instead')`, delegates to `CategoryService._delegate`)
    - .planning/phases/04-high-fixes/04-CONTEXT.md §D-13 (six-commit cascade)
  </read_first>
  <action>
    At this point, Tasks 1-2 have already removed the provider entry from `use_case_providers.dart` AND regenerated the .g.dart. No external code now imports `ResolveLedgerTypeService`. It is safe to delete the source file:

    ```bash
    git rm lib/application/dual_ledger/resolve_ledger_type_service.dart
    ```

    Also delete the generated companion if present:
    ```bash
    git rm -f lib/application/dual_ledger/resolve_ledger_type_service.g.dart 2>/dev/null || true
    ```

    Then commit:
    ```
    refactor(04-03): delete deprecated ResolveLedgerTypeService source (HIGH-03 commit 3 of 6)
    ```

    Verify `flutter analyze` exits 0 immediately after this commit — no orphan imports remain because Task 1 already cleaned the call site.

    NOTE: After this commit the test file `test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart` (and its `.mocks.dart`) are now BROKEN because they import the deleted source. `flutter test` would fail. Tasks 4-5 (chronological commits 4-5) MUST land back-to-back to restore CI green.
  </action>
  <verify>
    <automated>test ! -f lib/application/dual_ledger/resolve_ledger_type_service.dart &amp;&amp; flutter analyze 2>&amp;1 | tail -5</automated>
  </verify>
  <acceptance_criteria>
    - `lib/application/dual_ledger/resolve_ledger_type_service.dart` does NOT exist on disk
    - `lib/application/dual_ledger/resolve_ledger_type_service.g.dart` does NOT exist on disk
    - `flutter analyze` exits 0
    - `git log --oneline -1` shows commit message starting with `refactor(04-03): delete deprecated ResolveLedgerTypeService source (HIGH-03 commit 3 of 6)`
  </acceptance_criteria>
  <done>
    Source file removed; flutter analyze GREEN. Proceed immediately to Task 4 to remove the now-broken test file.
  </done>
</task>

<task type="auto">
  <name>Task 4: Commit 4 — Delete the test file `test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart`</name>
  <files>test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart</files>
  <read_first>
    - test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart (full file — confirm it imports `ResolveLedgerTypeService` and `resolve_ledger_type_service_test.mocks.dart`)
  </read_first>
  <action>
    Delete the test file (now orphan after Task 3 deleted the source):
    ```bash
    git rm test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart
    ```

    NOTE: At this point `flutter analyze` may emit a warning about the orphan `resolve_ledger_type_service_test.mocks.dart` (its imports of the deleted source class will fail). The mocks file is deleted in Task 5 — these two commits MUST land back-to-back to keep CI green within the same PR.

    Then commit:
    ```
    test(04-03): delete resolve_ledger_type_service_test (HIGH-03 commit 4 of 6)
    ```
  </action>
  <verify>
    <automated>test ! -f test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart &amp;&amp; ls test/unit/application/dual_ledger/</automated>
  </verify>
  <acceptance_criteria>
    - `test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart` does NOT exist on disk
    - `git log --oneline -1` shows commit message starting with `test(04-03): delete resolve_ledger_type_service_test (HIGH-03 commit 4 of 6)`
  </acceptance_criteria>
  <done>
    Test file deleted; immediately proceed to Task 5 to delete the orphan mocks file.
  </done>
</task>

<task type="auto">
  <name>Task 5: Commit 5 — Delete the mocks file `test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart`</name>
  <files>test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart</files>
  <read_first>
    - test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart (existence check)
  </read_first>
  <action>
    Delete the orphan mocks file:
    ```bash
    git rm test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart
    ```

    Then commit:
    ```
    test(04-03): delete resolve_ledger_type_service_test.mocks.dart (HIGH-03 commit 5 of 6 — D-14 coordination with Plan 04-04)
    ```

    Per CONTEXT.md D-14: Plan 04-04 explicitly excludes this file from its 13-fixture Mocktail migration. After this commit, Plan 04-04 has 13 (not 14) `*.mocks.dart` files to migrate.
  </action>
  <verify>
    <automated>test ! -f test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart &amp;&amp; flutter analyze 2>&amp;1 | tail -5</automated>
  </verify>
  <acceptance_criteria>
    - `test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart` does NOT exist on disk
    - `flutter analyze` exits 0 (no orphan import errors)
    - `flutter test` exits 0 (no broken test references)
  </acceptance_criteria>
  <done>
    Mocks file deleted; CI is GREEN; Plan 04-04 cross-coordination preserved.
  </done>
</task>

<task type="auto">
  <name>Task 6: Commit 6 — Verification + issues.json update + close HIGH-03</name>
  <files>.planning/audit/issues.json</files>
  <read_first>
    - .planning/audit/issues.json (search for any entry referencing `ResolveLedgerTypeService` — likely none since CONTEXT.md says zero HIGH entries exist)
  </read_first>
  <action>
    Final verification + bookkeeping:

    1. Run `flutter analyze` — must exit 0.
    2. Run `flutter test` — all tests must pass GREEN.
    3. Run `grep -rn "ResolveLedgerTypeService" lib/ test/` — must return 0 matches.
    4. Run `grep -rn "resolveLedgerTypeService" lib/ test/` — must return 0 matches.
    5. Run `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` — must exit 0 (no stale generated files).
    6. Update `.planning/audit/issues.json`: if any entry references `ResolveLedgerTypeService` (search by `file_path` and `description`), set `"status": "closed"` and `"closed_in_phase": 4`. If no such entry exists (CONTEXT.md says zero HIGH entries — likely none reference RLS), append a closing note in the audit log convention. Per CONTEXT.md `<domain>` "issues.json currently has zero HIGH entries — Phase 4 closes the requirements; the audit catalogue is updated as a side effect."
    7. Run `dart run scripts/coverage_gate.dart --files lib/features/accounting/presentation/providers/use_case_providers.dart --threshold 80 --lcov coverage/lcov_clean.info` — must exit 0 (use_case_providers.dart is the only surviving file in this plan that needs coverage gating; deleted files are exempt). NOTE: this gate succeeds because Plan 04-06's characterization test for use_case_providers.dart landed in Wave 0 BEFORE this plan touched the file.

    Then commit:
    ```
    chore(04-03): verify HIGH-03 close; coverage gate green (HIGH-03 commit 6 of 6)
    ```
  </action>
  <verify>
    <automated>grep -rn "ResolveLedgerTypeService\|resolveLedgerTypeService" lib/ test/ 2>/dev/null; echo "exit_grep=$?"; flutter analyze 2>&amp;1 | tail -3</automated>
  </verify>
  <acceptance_criteria>
    - `grep -rn "ResolveLedgerTypeService" lib/ test/` returns 0 matches
    - `grep -rn "resolveLedgerTypeService" lib/ test/` returns 0 matches
    - `flutter analyze` exits 0
    - `flutter test` exits 0
    - `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits 0
    - `dart run scripts/coverage_gate.dart --files lib/features/accounting/presentation/providers/use_case_providers.dart --threshold 80 --lcov coverage/lcov_clean.info` exits 0
    - `git log --oneline -6 | grep "04-03"` returns 6 commits with `(HIGH-03 commit N of 6)` markers in chronological order
  </acceptance_criteria>
  <done>
    HIGH-03 fully closed; ResolveLedgerTypeService is erased from the codebase; six atomic commits landed in chronological order (Task N == Commit N); CI GREEN; coverage_gate exits 0.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| (n/a) | This plan deletes deprecated dead code; it does not introduce or modify any trust boundary. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-04-03-01 | (n/a) | deletion | accept | STRIDE analysis: no new auth surface, no new IPC boundary, no new persisted secret, no new external input. Deletion of deprecated `@Deprecated('Use CategoryService instead')` service that already delegates to CategoryService preserves behavior — production callers already use `categoryServiceProvider` directly per CONTEXT.md D-12. No HIGH-severity threats. |
</threat_model>

<verification>
- 6 commits landed with `(HIGH-03 commit N of 6)` markers in chronological order (Task N == Commit N)
- `grep -rn "ResolveLedgerTypeService\|resolveLedgerTypeService" lib/ test/` returns 0
- `flutter analyze` exits 0 after each commit
- `flutter test` exits 0 after each commit
- coverage_gate.dart exits 0 against `use_case_providers.dart` (Plan 04-06 characterization test landed in Wave 0 makes this possible)
</verification>

<success_criteria>
- HIGH-03 closed: source file, provider entry, generated `.g.dart` line, test, and `*.mocks.dart` are all GONE
- `flutter analyze` 0 + `flutter test` GREEN at every commit boundary
- `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits 0
- coverage_gate.dart exits 0 on the 1 surviving touched file (use_case_providers.dart)
- Plan 04-04 cross-coordination preserved (RLS-test mock NOT in 04-04's migration scope)
- Plan 04-06 dependency satisfied — characterization test for use_case_providers.dart landed in Wave 0 before this plan modified the file
</success_criteria>

<output>
After completion, create `.planning/phases/04-high-fixes/04-03-SUMMARY.md` documenting:
- The 6 commit SHAs and messages (in chronological order matching task order)
- Confirmation `grep` returns 0 matches for both class and provider names
- Confirmation Plan 04-04 must skip `resolve_ledger_type_service_test.mocks.dart`
- Reference to issues.json update (or note that no HIGH entry referenced RLS)
</output>
</content>
</invoke>