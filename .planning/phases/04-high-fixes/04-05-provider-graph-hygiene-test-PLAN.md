---
phase: 04-high-fixes
plan: 05
type: execute
wave: 4
depends_on:
  - 04-02
files_modified:
  - test/architecture/provider_graph_hygiene_test.dart
  - lib/features/family_sync/presentation/providers/state_sync.dart
  - lib/features/dual_ledger/presentation/providers/state_ledger.dart
autonomous: true
requirements:
  - HIGH-04
  - HIGH-05
  - HIGH-06
must_haves:
  goals:
    - "`test/architecture/provider_graph_hygiene_test.dart` exists and passes GREEN, asserting (1) HIGH-04 structure: each feature's `presentation/providers/` contains exactly one `repository_providers.dart` plus only `state_*.dart` files, (2) HIGH-04 DI consolidation: every Repository/UseCase/Service-suffix provider lives in `repository_providers.dart`, (3) HIGH-04 global uniqueness: no two `@riverpod` provider names map to the same dependency identity, (4) HIGH-05 keepAlive hard list: all 6 named providers retain `@Riverpod(keepAlive: true)`, (5) HIGH-06 no UnimplementedError: zero `throw UnimplementedError` inside any provider body in `lib/`. Reconciliations: `ledgerProvider` → `ledgerViewProvider` (Phase 4 verifies exact name); `merchantDatabaseProvider` → `appMerchantDatabaseProvider` (per Plan 04-01 Task 2 `app` prefix decision); `activeGroupMembersProvider` (currently absent, exists as `groupMembers` without keepAlive — RECONCILE per D-07.4)"
  truths:
    - "Repo lock active throughout Phase 4 (CONTEXT.md D-19 + .planning/audit/REPO-LOCK-POLICY.md) — only Phase 4 cleanup PRs merge to main"
    - "coverage_gate.dart enforced per-plan only; CI integration deferred to Phase 6 (CONTEXT.md D-21)"
    - "import_guard remains BLOCKING (Phase 3 D-17 flip)"
    - "Wave 4 — depends on Plan 04-02 (Wave 3); this is the LAST plan of Phase 4 — its GREEN status is what closes Phase 4 per CONTEXT.md `<specifics>` 1st bullet"
    - "Plan 04-02 already preserved keepAlive on `transactionChangeTracker`, `syncEngine` (in `state_sync.dart`), `activeGroup` (in `state_active_group.dart`), `LedgerView` (in `state_ledger.dart`); Plan 04-01 hoisted `merchantDatabase` to `lib/application/ml/repository_providers.dart` as `appMerchantDatabaseProvider` (per Warning 7 `app` prefix decision); Plan 04-02 Task 5 deletes the original feature-side `merchantDatabaseProvider` once consumers migrate"
    - "Reconciliation REQUIRED for `activeGroupMembersProvider` per CONTEXT.md D-07.4: the closest match is `groupMembers` at `lib/features/family_sync/presentation/providers/state_sync.dart` (was `sync_providers.dart` line 161 pre-Plan-04-02). Decision: ADD `@Riverpod(keepAlive: true)` annotation + RENAME `groupMembers` to `activeGroupMembers` to match the hard list. The rename is justified because (a) the provider observes `activeGroupProvider` so its name should reflect the active group context, (b) `keepAlive` is appropriate because the stream is long-lived and recreating it on each tab switch would lose subscription state. Update all callers in the same commit"
    - "Reconciliation REQUIRED for `ledgerProvider` per CONTEXT.md D-07.4: the actual generated provider name from `class LedgerView extends _$LedgerView` is `ledgerViewProvider`. Decision: UPDATE the hard list in the architecture test to use `ledgerViewProvider` (not `ledgerProvider`) — the test is the source of truth and reflects current code. The HIGH-05 requirement document spec (`ledgerProvider`) was the human-readable reference; `ledgerViewProvider` is the literal symbol"
    - "Reconciliation for `merchantDatabaseProvider` per Plan 04-01 Task 2 `app` prefix decision: hard list entry is `appMerchantDatabaseProvider` (the `app`-prefixed application-layer name in `lib/application/ml/repository_providers.dart`). The original feature-side `merchantDatabaseProvider` is deleted by Plan 04-02 Task 5 once the voice_providers fold completes — no duplicate exists by Wave 4."
    - "Per CONTEXT.md `<specifics>` 5th bullet: this test extends `test/architecture/` as the project's structural alarm directory; future phases add MED-04 ARB-parity etc. here"
    - "The 6 keepAlive providers per HIGH-05 (post-Phase-4 names): `syncEngineProvider`, `transactionChangeTrackerProvider`, `appMerchantDatabaseProvider` (per `app` prefix), `activeGroupProvider`, `activeGroupMembersProvider` (after rename), `ledgerViewProvider` (literal name)"
  artifacts:
    - path: "test/architecture/provider_graph_hygiene_test.dart"
      provides: "Architecture test enforcing HIGH-04 + HIGH-05 + HIGH-06 invariants"
      contains: "_expectedKeepAliveProviders"
      min_lines: 120
    - path: "lib/features/family_sync/presentation/providers/state_sync.dart"
      provides: "EDITED — `groupMembers` provider RENAMED to `activeGroupMembers` + `@Riverpod(keepAlive: true)` annotation ADDED (HIGH-05 reconciliation per D-07.4)"
      contains: "@Riverpod(keepAlive: true)"
    - path: "lib/features/dual_ledger/presentation/providers/state_ledger.dart"
      provides: "VERIFIED (no edit) — confirms `LedgerView` class generates `ledgerViewProvider`; arch test hard list uses `ledgerViewProvider`"
  key_links:
    - from: "test/architecture/provider_graph_hygiene_test.dart"
      to: "lib/**/*.dart (all production providers)"
      via: "regex scan for @riverpod / @Riverpod(keepAlive: true) annotations and throw UnimplementedError"
      pattern: "@(R|r)iverpod"
    - from: "Phase 4 close"
      to: "this test passing GREEN"
      via: "CONTEXT.md `<specifics>` 1st bullet — Phase 4 close = provider_graph_hygiene_test.dart GREEN"
      pattern: "(success|passed)"
---

<objective>
Plan 04-05 is the **last plan of Phase 4**. It adds `test/architecture/provider_graph_hygiene_test.dart` — the meta-test that is Phase 4's "alarm against future regression" for the provider graph (mirrors Phase 3 D-17's `import_guard` blocking flip role for layer rules).

The test asserts FIVE invariants (CONTEXT.md D-07):
1. **HIGH-04 structure**: each feature's `presentation/providers/` contains exactly `repository_providers.dart` + only `state_*.dart` files (no `*_providers.dart`, no `*_notifier.dart`, no `*_provider.dart`).
2. **HIGH-04 DI consolidation**: every provider returning a `*Repository`, `*UseCase`, or `*Service` type is defined inside `repository_providers.dart` (not in `state_*.dart`).
3. **HIGH-04 global uniqueness**: no two `@riverpod` provider names map to the same dependency identity (no duplicate provider definitions). Note: post Plan 04-02 Task 5 cleanup, the original (non-prefixed) feature-side `e2eeServiceProvider` etc. are deleted, so only the `app`-prefixed versions remain — uniqueness is preserved.
4. **HIGH-05 keepAlive hard list**: a hard-coded list of 6 provider names — `syncEngineProvider`, `transactionChangeTrackerProvider`, `appMerchantDatabaseProvider` (per Plan 04-01 `app` prefix), `activeGroupProvider`, `activeGroupMembersProvider` (after rename — see below), `ledgerViewProvider` (literal name; see below) — every one must have `@Riverpod(keepAlive: true)` somewhere in `lib/`.
5. **HIGH-06 no UnimplementedError**: zero `throw UnimplementedError` inside any `@riverpod` function body or `Provider<X>` constructor in `lib/`.

**Three reconciliations required per CONTEXT.md D-07.4 + Warning 7:**

A. `activeGroupMembersProvider` does not exist verbatim. The closest provider is `groupMembers` (currently in `lib/features/family_sync/presentation/providers/state_sync.dart` after Plan 04-02). Per D-07.4: "If a name is renamed during Phase 4 refactor, the test's hard-coded entry is updated in the same commit." **Decision:** rename `groupMembers` → `activeGroupMembers` AND add `@Riverpod(keepAlive: true)` annotation. The rename is semantically appropriate (the stream observes `activeGroupProvider`); the keepAlive is appropriate (long-lived stream that should not lose subscription state on tab switches). Update all callers in the same commit.

B. `ledgerProvider` does not exist verbatim. The `LedgerView` class with `@Riverpod(keepAlive: true)` generates `ledgerViewProvider`. **Decision:** the test's hard list uses `ledgerViewProvider` (literal generated name). The HIGH-05 requirement document spec (`ledgerProvider`) is the human-readable name — the test is the operational source of truth.

C. `merchantDatabaseProvider` is renamed to `appMerchantDatabaseProvider` per Plan 04-01 Task 2 `app` prefix decision (Warning 7 fix). The original feature-side `merchantDatabaseProvider` is deleted by Plan 04-02 Task 5 once the voice_providers fold completes. **Decision:** the test's hard list uses `appMerchantDatabaseProvider` (the surviving application-layer name). The HIGH-05 requirement document spec (`merchantDatabaseProvider`) is the human-readable name — the test reflects the post-refactor codebase.

Per CONTEXT.md `<specifics>` 1st bullet: **Phase 4 close = `provider_graph_hygiene_test.dart` GREEN.**

Output: 1 architecture test added; 1 source provider rename + keepAlive addition; HIGH-04 + HIGH-05 + HIGH-06 closed; Phase 4 closed.
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

<!-- Phase 3 architecture test analog (template) -->
@test/architecture/domain_import_rules_test.dart
@test/architecture/presentation_layer_rules_test.dart

<!-- Files containing the keepAlive providers — verify post-Plan-04-02 paths -->
@lib/features/family_sync/presentation/providers/state_sync.dart
@lib/features/family_sync/presentation/providers/state_active_group.dart
@lib/features/dual_ledger/presentation/providers/state_ledger.dart
@lib/application/ml/repository_providers.dart

<interfaces>
<!-- Architecture test scaffold (mirrors PATTERNS.md §12) -->

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

const _features = [
  'accounting', 'analytics', 'dual_ledger', 'family_sync', 'home', 'profile', 'settings',
];

const _expectedKeepAliveProviders = [
  'syncEngineProvider',
  'transactionChangeTrackerProvider',
  'appMerchantDatabaseProvider',  // `app` prefix per Plan 04-01 Task 2 (Warning 7)
  'activeGroupProvider',
  'activeGroupMembersProvider',  // renamed from `groupMembers` (Task 1 reconciliation)
  'ledgerViewProvider',  // literal generated name from class LedgerView
];

void main() {
  group('Provider graph hygiene', () {
    test('HIGH-04 structure: each feature has exactly one repository_providers.dart and only state_*.dart siblings', () {
      for (final feature in _features) {
        final dir = Directory('lib/features/$feature/presentation/providers');
        if (!dir.existsSync()) continue;  // some features may not have providers/
        final files = dir.listSync()
            .whereType<File>()
            .map((f) => f.uri.pathSegments.last)
            .where((n) => !n.endsWith('.g.dart'))
            .toList();
        final repos = files.where((n) => n == 'repository_providers.dart');
        expect(repos.length, lessThanOrEqualTo(1),
            reason: 'feature $feature: expected at most 1 repository_providers.dart, found ${repos.length}');
        for (final n in files.where((n) => n != 'repository_providers.dart')) {
          expect(n.startsWith('state_'), isTrue,
              reason: 'feature $feature: $n is not a state_*.dart (HIGH-04 violation)');
        }
      }
    });

    test('HIGH-04 DI consolidation: Repository/UseCase/Service-suffix providers live only in repository_providers.dart', () {
      final violations = <String>[];
      for (final feature in _features) {
        final dir = Directory('lib/features/$feature/presentation/providers');
        if (!dir.existsSync()) continue;
        for (final f in dir.listSync().whereType<File>()) {
          final name = f.uri.pathSegments.last;
          if (name == 'repository_providers.dart' || name.endsWith('.g.dart')) continue;
          final src = f.readAsStringSync();
          final diMatches = RegExp(r'@riverpod[\s\S]{0,200}\b(\w+)(Repository|UseCase|Service)\b\s+\w+\(').allMatches(src);
          for (final m in diMatches) {
            violations.add('${f.path}: ${m.group(0)}');
          }
        }
      }
      expect(violations, isEmpty,
          reason: 'DI providers found outside repository_providers.dart:\n${violations.join("\n")}');
    });

    test('HIGH-04 global uniqueness: no duplicate @riverpod function names', () {
      final names = <String, List<String>>{};
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart') && !entity.path.endsWith('.g.dart')) {
          final src = entity.readAsStringSync();
          // Match: @riverpod\n[type] funcName(Ref ref) — captures funcName
          final matches = RegExp(r'@(?:R|r)iverpod(?:\([^)]*\))?\s*(?://[^\n]*\n)*\s*\w[\w<>?, ]*\s+(\w+)\s*\(\s*Ref\b').allMatches(src);
          for (final m in matches) {
            final name = m.group(1)!;
            names.putIfAbsent(name, () => []).add(entity.path);
          }
        }
      }
      final dupes = Map.fromEntries(names.entries.where((e) => e.value.length > 1));
      expect(dupes, isEmpty,
          reason: 'Duplicate @riverpod provider names found:\n${dupes.entries.map((e) => "${e.key}: ${e.value}").join("\n")}');
    });

    test('HIGH-05 keepAlive hard list: all 6 named providers retain @Riverpod(keepAlive: true)', () {
      final found = <String, String>{};  // providerName → file path
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart') && !entity.path.endsWith('.g.dart')) {
          final src = entity.readAsStringSync();
          // Match function-style: @Riverpod(keepAlive: true)\n[type] funcName(Ref ref)
          final fnMatches = RegExp(r'@Riverpod\(keepAlive:\s*true\)\s*(?://[^\n]*\n)*\s*\w[\w<>?, ]*\s+(\w+)\s*\(\s*Ref\b').allMatches(src);
          for (final m in fnMatches) {
            found[m.group(1)! + 'Provider'] = entity.path;
          }
          // Match class-style: @Riverpod(keepAlive: true)\nclass ClassName extends _$ClassName
          final classMatches = RegExp(r'@Riverpod\(keepAlive:\s*true\)\s*(?://[^\n]*\n)*\s*class\s+(\w+)\s+extends\s+_\$\1').allMatches(src);
          for (final m in classMatches) {
            // ClassName → classNameProvider
            final cn = m.group(1)!;
            final providerName = cn[0].toLowerCase() + cn.substring(1) + 'Provider';
            found[providerName] = entity.path;
          }
        }
      }
      final missing = _expectedKeepAliveProviders.where((p) => !found.containsKey(p)).toList();
      expect(missing, isEmpty,
          reason: 'HIGH-05 keepAlive providers missing @Riverpod(keepAlive: true): $missing\nFound: ${found.keys.toList()}');
    });

    test('HIGH-06 no UnimplementedError in production providers', () {
      final hits = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart') && !entity.path.endsWith('.g.dart')) {
          final src = entity.readAsStringSync();
          if (RegExp(r'@(?:R|r)iverpod[\s\S]{0,500}throw\s+UnimplementedError').hasMatch(src) ||
              RegExp(r'Provider<\w+>\(\([^)]*\)\s*=>\s*throw\s+UnimplementedError').hasMatch(src)) {
            hits.add(entity.path);
          }
        }
      }
      expect(hits, isEmpty,
          reason: 'UnimplementedError providers found in production code: $hits');
    });
  });
}
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Reconcile activeGroupMembersProvider — rename `groupMembers` → `activeGroupMembers` + add @Riverpod(keepAlive: true) in state_sync.dart</name>
  <files>lib/features/family_sync/presentation/providers/state_sync.dart, lib/features/family_sync/presentation/providers/state_sync.g.dart</files>
  <read_first>
    - lib/features/family_sync/presentation/providers/state_sync.dart (post-Plan-04-02 — verify `groupMembers` provider exists and currently has NO keepAlive annotation)
    - lib/features/family_sync/presentation/providers/state_active_group.dart (verify `activeGroupProvider` is keepAlive)
    - PATTERNS.md §12 last paragraph (`activeGroupMembersProvider` reconciliation note)
    - All callers across `lib/` and `test/` (find via `grep -rn "groupMembersProvider" lib/ test/`)
  </read_first>
  <behavior>
    - Test 1: `lib/features/family_sync/presentation/providers/state_sync.dart` defines a provider named `activeGroupMembers` with `@Riverpod(keepAlive: true)` annotation
    - Test 2: `lib/features/family_sync/presentation/providers/state_sync.dart` does NOT define `groupMembers` (renamed)
    - Test 3: All callers updated — `grep -rn "groupMembersProvider" lib/ test/` returns 0 matches; `grep -rn "activeGroupMembersProvider" lib/ test/` returns ≥2 matches (definition + at least one caller)
    - Test 4: Behavior preserved — the renamed provider still streams `List<GroupMember>` from `activeGroupProvider` + `groupMemberDaoProvider`
    - Test 5: Plan 04-06 characterization tests still pass (provider name change requires test update)
  </behavior>
  <action>
    1. Open `lib/features/family_sync/presentation/providers/state_sync.dart` and locate the `groupMembers` provider (was at line 161 of original `sync_providers.dart`; post-Plan-04-02 it lives in `state_sync.dart`).

    2. Rename the function from `groupMembers` to `activeGroupMembers`:
       ```dart
       // BEFORE:
       @riverpod
       Stream<List<GroupMember>> groupMembers(Ref ref) { ... }

       // AFTER:
       @Riverpod(keepAlive: true)
       Stream<List<GroupMember>> activeGroupMembers(Ref ref) { ... }
       ```

    3. Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate `state_sync.g.dart` (the generated provider name becomes `activeGroupMembersProvider`).

    4. Find all callers via `grep -rn "groupMembersProvider" lib/ test/` and update each to `activeGroupMembersProvider`. Update any imports if needed.

    5. Update Plan 04-06 characterization tests if they reference `groupMembersProvider` directly (the test should be updated to match the new name).

    6. Run `flutter analyze` — must exit 0.
    7. Run `flutter test test/unit/features/family_sync/` — must pass GREEN.

    Then commit:
    ```
    refactor(04-05): rename groupMembers → activeGroupMembers + add keepAlive (HIGH-05 reconciliation per D-07.4)
    ```
  </action>
  <verify>
    <automated>grep -c "activeGroupMembers" lib/features/family_sync/presentation/providers/state_sync.dart; grep -c "groupMembersProvider" lib/ test/ -rln 2>/dev/null | wc -l; grep -B1 "Stream<List<GroupMember>> activeGroupMembers" lib/features/family_sync/presentation/providers/state_sync.dart</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "activeGroupMembers" lib/features/family_sync/presentation/providers/state_sync.dart` returns ≥1
    - `grep -B1 "Stream<List<GroupMember>> activeGroupMembers" lib/features/family_sync/presentation/providers/state_sync.dart | grep "@Riverpod(keepAlive: true)"` returns at least 1 match (annotation directly above the provider)
    - `grep -rln "groupMembersProvider" lib/ test/` returns 0 matches (all callers updated)
    - `grep -rln "activeGroupMembersProvider" lib/ test/` returns ≥2 matches (definition + at least 1 caller)
    - `flutter analyze` exits 0
    - `flutter test test/unit/features/family_sync/` exits 0
    - `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits 0
  </acceptance_criteria>
  <done>activeGroupMembersProvider exists with keepAlive; all callers updated; HIGH-05 hard list reconciled.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Add `test/architecture/provider_graph_hygiene_test.dart` covering all 5 invariants — final Phase 4 close gate</name>
  <files>test/architecture/provider_graph_hygiene_test.dart</files>
  <read_first>
    - test/architecture/domain_import_rules_test.dart (Phase 3 D-03 analog)
    - test/architecture/presentation_layer_rules_test.dart (Plan 04-02 sibling)
    - All `lib/features/*/presentation/providers/` directory listings (verify post-Plan-04-02 structure)
    - lib/features/family_sync/presentation/providers/state_sync.dart (post-Task-1: verify `activeGroupMembers` with keepAlive)
    - lib/features/dual_ledger/presentation/providers/state_ledger.dart (verify `LedgerView` class generates `ledgerViewProvider`)
    - lib/application/ml/repository_providers.dart (verify `appMerchantDatabaseProvider` exists with keepAlive — Plan 04-01 Task 2)
    - PATTERNS.md §12 (full architecture test template)
  </read_first>
  <behavior>
    - Test 1 (HIGH-04 structure): for each of 7 features, `lib/features/<f>/presentation/providers/` contains AT MOST 1 `repository_providers.dart` and only `state_*.dart` siblings (no `*_providers.dart`, no `*_notifier.dart`, no `*_provider.dart` not prefixed with `state_`)
    - Test 2 (HIGH-04 DI consolidation): no `state_*.dart` file contains `@riverpod` providers returning a `*Repository`, `*UseCase`, or `*Service` type
    - Test 3 (HIGH-04 global uniqueness): scan all `@riverpod` function declarations across `lib/`; the same function name does NOT appear in two files (no `fooProvider` defined twice). Note: Plan 04-02 Task 5 deletes the original feature-side `e2eeService` etc. duplicates so only the `app`-prefixed versions remain — uniqueness is preserved.
    - Test 4 (HIGH-05 keepAlive hard list): all 6 expected providers are found with `@Riverpod(keepAlive: true)` in `lib/`: `syncEngineProvider`, `transactionChangeTrackerProvider`, `appMerchantDatabaseProvider`, `activeGroupProvider`, `activeGroupMembersProvider`, `ledgerViewProvider`
    - Test 5 (HIGH-06 no UnimplementedError): regex scan finds 0 instances of `throw UnimplementedError` inside `@riverpod` bodies or `Provider<X>(...)` constructors across `lib/`
  </behavior>
  <action>
    1. Create `test/architecture/provider_graph_hygiene_test.dart` per the `<interfaces>` template above. Use the EXACT scaffold provided — it covers all 5 invariants in 5 separate `test(...)` blocks within a single `group('Provider graph hygiene', ...)`. The hard list MUST contain `appMerchantDatabaseProvider` (per Warning 7 reconciliation).

    2. Verify the regex patterns work against the post-refactor codebase:
       - HIGH-04 DI consolidation regex `@riverpod[\s\S]{0,200}\b(\w+)(Repository|UseCase|Service)\b\s+\w+\(` correctly identifies provider functions whose return type ends in Repository/UseCase/Service
       - HIGH-04 global uniqueness regex captures function-style `@riverpod` providers with `Ref ref` parameter
       - HIGH-05 keepAlive function-style regex captures `@Riverpod(keepAlive: true)\n<Type> funcName(Ref ref)` patterns
       - HIGH-05 keepAlive class-style regex captures `@Riverpod(keepAlive: true)\nclass ClassName extends _$ClassName` patterns and converts ClassName→classNameProvider
       - HIGH-06 regex `@(?:R|r)iverpod[\s\S]{0,500}throw\s+UnimplementedError` correctly catches UnimplementedError throws

    3. Run `flutter test test/architecture/provider_graph_hygiene_test.dart` — MUST pass GREEN. If any test fails:
       - HIGH-04 structure failure → file rename in Plan 04-02 was incomplete; trace and fix
       - HIGH-04 DI consolidation failure → DI provider in `state_*.dart`; move to `repository_providers.dart`
       - HIGH-04 global uniqueness failure → duplicate provider definition (likely Plan 04-02 Task 5 cleanup incomplete); finish the cleanup
       - HIGH-05 keepAlive failure → check Task 1 reconciliation; verify all 6 names present with annotation; verify Plan 04-01 hoisted `appMerchantDatabaseProvider` with keepAlive
       - HIGH-06 UnimplementedError failure → likely test infra leak; replace with proper concrete provider

    4. Run `flutter test` (full suite) — must exit 0.
    5. Run `flutter analyze` — must exit 0.
    6. Run `dart run custom_lint` — must exit 0.

    7. Run final coverage gate:
       ```bash
       dart run scripts/coverage_gate.dart \
         --files lib/features/family_sync/presentation/providers/state_sync.dart \
         --threshold 80 \
         --lcov coverage/lcov_clean.info
       ```
       MUST exit 0.

    Then commit:
    ```
    test(04-05): add provider_graph_hygiene architecture test — close Phase 4 (HIGH-04, HIGH-05, HIGH-06)
    ```

    8. Update `.planning/STATE.md` to mark Phase 4 complete:
       ```bash
       gsd-sdk query state.update --phase 4 --status complete --note "Phase 4 closed: provider_graph_hygiene_test.dart GREEN; HIGH-01..08 closed"
       ```
       (Or manually edit STATE.md if SDK command unavailable.)

    9. Update `.planning/ROADMAP.md` Phase 4 row: `[ ]` → `[x]` and add completion date.

    10. Final Phase 4 close commit:
       ```
       chore(04): mark Phase 4 complete in STATE.md + ROADMAP.md (HIGH-01..08 all closed)
       ```
  </action>
  <verify>
    <automated>flutter test test/architecture/provider_graph_hygiene_test.dart 2>&amp;1 | tail -10; flutter test 2>&amp;1 | tail -5; dart run custom_lint 2>&amp;1 | tail -5</automated>
  </verify>
  <acceptance_criteria>
    - `test/architecture/provider_graph_hygiene_test.dart` exists with 5 tests inside `group('Provider graph hygiene', ...)`
    - `grep -c "_expectedKeepAliveProviders" test/architecture/provider_graph_hygiene_test.dart` returns ≥1
    - `grep -c "syncEngineProvider\|transactionChangeTrackerProvider\|appMerchantDatabaseProvider\|activeGroupProvider\|activeGroupMembersProvider\|ledgerViewProvider" test/architecture/provider_graph_hygiene_test.dart` returns ≥6 (all 6 hard-list names present including `app`-prefixed merchant db)
    - `flutter test test/architecture/provider_graph_hygiene_test.dart` exits 0
    - `flutter test` (full suite) exits 0
    - `flutter analyze` exits 0
    - `dart run custom_lint` exits 0
    - `dart run scripts/coverage_gate.dart --files lib/features/family_sync/presentation/providers/state_sync.dart --threshold 80 --lcov coverage/lcov_clean.info` exits 0
    - `wc -l test/architecture/provider_graph_hygiene_test.dart` reports ≥120 lines
  </acceptance_criteria>
  <done>provider_graph_hygiene_test.dart GREEN; Phase 4 closed; all HIGH-04/05/06 invariants enforced as regression alarms.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Architecture test → CI | This plan adds a new test that runs in CI on every PR. If any future PR weakens the provider-graph invariants (removes keepAlive, adds duplicate provider, leaks UnimplementedError into production), the test fails and blocks merge. Mirrors Phase 3 D-17 `import_guard` blocking flip's role for layer rules. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-04-05-01 | T (Tampering) | provider graph | mitigate | `provider_graph_hygiene_test.dart` blocks any future PR that introduces duplicate providers, removes keepAlive from the 6 named providers, leaks UnimplementedError into production code, or restructures `lib/features/<f>/presentation/providers/` outside the `repository_providers.dart` + `state_*.dart` convention. CI failure blocks merge. |
| T-04-05-02 | (n/a) | refactor | accept | The `groupMembers` → `activeGroupMembers` rename + keepAlive addition is a behavior-preserving change (same Drift watch query, same domain model output; keepAlive merely prevents the stream from being torn down on tab switches — strictly equal-or-better behavior than current "recreate on dispose"). No new attack surface. No HIGH-severity threats. |
</threat_model>

<verification>
- `test/architecture/provider_graph_hygiene_test.dart` exists and is GREEN
- All 6 HIGH-05 keepAlive providers found in `lib/` with annotation (including `appMerchantDatabaseProvider` per Plan 04-01 `app` prefix)
- `groupMembers` renamed to `activeGroupMembers` with keepAlive added
- `flutter analyze` exits 0
- `dart run custom_lint` exits 0
- `flutter test` (full suite) exits 0
- coverage_gate.dart exits 0
- STATE.md and ROADMAP.md updated to mark Phase 4 complete
</verification>

<success_criteria>
- HIGH-04 structure invariant enforced (test 1 GREEN)
- HIGH-04 DI consolidation invariant enforced (test 2 GREEN)
- HIGH-04 global uniqueness invariant enforced (test 3 GREEN)
- HIGH-05 keepAlive hard list enforced (test 4 GREEN; all 6 providers verified including `appMerchantDatabaseProvider`)
- HIGH-06 no UnimplementedError invariant enforced (test 5 GREEN)
- Phase 4 closed; ready for Phase 5 (MEDIUM Fixes)
</success_criteria>

<output>
After completion, create `.planning/phases/04-high-fixes/04-05-SUMMARY.md` documenting:
- The 5 invariants enforced and their PASSING evidence
- The reconciliation actions taken (groupMembers→activeGroupMembers rename + keepAlive add; ledgerProvider→ledgerViewProvider name acknowledgment; merchantDatabaseProvider→appMerchantDatabaseProvider per `app` prefix)
- The final HIGH-05 hard list as it appears in the test
- Phase 4 close attestation: HIGH-01..08 all closed; provider_graph_hygiene_test.dart GREEN
- Reference for Phase 5 planner — `test/architecture/` is now established as the project's structural alarm directory; future MED/LOW invariants may extend it
</output>
</content>
</invoke>