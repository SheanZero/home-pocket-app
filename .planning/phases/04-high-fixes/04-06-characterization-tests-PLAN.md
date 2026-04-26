---
phase: 04-high-fixes
plan: 06
type: tdd
wave: 0
depends_on: []
files_modified:
  - test/unit/features/accounting/presentation/providers/voice_providers_characterization_test.dart
  - test/unit/features/accounting/presentation/providers/repository_providers_characterization_test.dart
  - test/unit/features/accounting/presentation/providers/use_case_providers_characterization_test.dart
  - test/unit/features/accounting/presentation/screens/transaction_confirm_screen_characterization_test.dart
  - test/unit/features/accounting/presentation/screens/transaction_entry_screen_characterization_test.dart
  - test/unit/features/accounting/presentation/screens/voice_input_screen_characterization_test.dart
  - test/unit/features/accounting/presentation/widgets/transaction_list_tile_characterization_test.dart
  - test/unit/features/analytics/presentation/providers/analytics_providers_characterization_test.dart
  - test/unit/features/analytics/presentation/providers/repository_providers_characterization_test.dart
  - test/unit/features/analytics/presentation/screens/analytics_screen_characterization_test.dart
  - test/unit/features/family_sync/presentation/providers/avatar_sync_providers_characterization_test.dart
  - test/unit/features/family_sync/presentation/providers/group_providers_characterization_test.dart
  - test/unit/features/family_sync/presentation/providers/repository_providers_characterization_test.dart
  - test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart
  - test/unit/features/family_sync/presentation/screens/create_group_screen_characterization_test.dart
  - test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart
  - test/unit/features/profile/presentation/providers/user_profile_providers_characterization_test.dart
  - test/unit/features/settings/presentation/providers/backup_providers_characterization_test.dart
  - test/unit/features/settings/presentation/widgets/appearance_section_characterization_test.dart
  - test/unit/application/dual_ledger/providers_characterization_test.dart
autonomous: true
requirements:
  - HIGH-08
tags:
  - characterization_tests
  - wave_0_test_infra
  - tdd
  - high_fixes
must_haves:
  goals:
    - "Every file in (Phase-4 touched-files ∩ files-needing-tests.txt) has a Mocktail-only characterization test that runs GREEN against the PRE-refactor codebase, capturing observable behavior so that the refactors landing in Plans 04-01..05 are provably non-regressing (CONTEXT.md D-17 strict)"
  truths:
    - "Repo lock active per .planning/audit/REPO-LOCK-POLICY.md — only Phase 4 cleanup PRs merge to main during this phase"
    - "import_guard remains BLOCKING (Phase 3 D-17 flip) — these test-only commits cannot weaken the gate"
    - "Mocktail-only test convention — NO `package:mockito/...` imports, NO `@GenerateMocks` annotations, NO `*.mocks.dart` companion files (Phase 4 D-08; Plan 04-04 deletes Mockito mocks immediately after this plan)"
    - "Scope is FROZEN at the 19-file intersection computed below — files already ≥80% pre-Phase-4 are exempted (CONTEXT.md D-17)"
    - "D-18 touched-files manifest scope confirmed: Phase 4 total touched-file estimate is 65–80 files (Plan 04-02 ~43, Plan 04-01 ~12-16, Plan 04-04 ~14, Plan 04-03 5); the (touched ∩ files-needing-tests) intersection this plan covers is the 20-file subset needing characterization. Coverage burden absorbed up front per CONTEXT.md D-18"
    - "Tests use inline `class _Mock<X> extends Mock implements X` per analog `test/unit/application/family_sync/create_group_use_case_test.dart` (Mocktail-only template)"
    - "Tests NEVER touch real `flutter_secure_storage` (FUTURE-ARCH-04 protection); use `AppDatabase.forTesting()` when DB is needed"
    - "Tests import from CURRENT (pre-refactor) file paths — Plans 04-01/02 will update test imports as part of their refactor commits"
    - "After this plan lands, `dart run scripts/coverage_gate.dart --files <19 files> --threshold 80 --lcov coverage/lcov_clean.info` exits 0"
  artifacts:
    - path: "test/unit/features/accounting/presentation/providers/voice_providers_characterization_test.dart"
      provides: "Locks merchantDatabaseProvider keepAlive + voiceTextParser/fuzzyCategoryMatcher/parseVoiceInputUseCase/voiceSatisfactionEstimator construction"
      min_lines: 40
    - path: "test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart"
      provides: "Locks transactionChangeTrackerProvider keepAlive + syncEngineProvider keepAlive + groupMembers stream behavior pre-split"
      min_lines: 60
    - path: "test/unit/features/family_sync/presentation/providers/repository_providers_characterization_test.dart"
      provides: "Locks 6 sync-client provider construction (apns_push, e2ee, push_notification, relay_api, sync_queue, websocket) pre-hoist"
      min_lines: 50
    - path: "test/unit/application/dual_ledger/providers_characterization_test.dart"
      provides: "Locks ruleEngineProvider keepAlive + classificationServiceProvider construction pre-rename (Plan 04-01 Task 3 step 7 RENAMES this file to repository_providers.dart — Blocker 3 fix per CONTEXT.md D-17 strict)"
      min_lines: 30
  key_links:
    - from: "test/unit/features/<f>/presentation/providers/<file>_characterization_test.dart"
      to: "lib/features/<f>/presentation/providers/<file>.dart (pre-refactor) AND post-refactor target"
      via: "Plans 04-01/02 update test imports as part of their refactor commits"
      pattern: "package:home_pocket/features/.*/presentation/providers/"
---

<objective>
Plan 04-06 is the **Wave 0 test-infrastructure plan** for Phase 4. It writes characterization tests for every file in `Phase-4 touched-files ∩ .planning/audit/files-needing-tests.txt` BEFORE the refactor commits land in Plans 04-01..05. Per CONTEXT.md D-17 strict: characterization tests written first; refactors second.

The intersection is **20 source files** (originally 19; +1 added per Blocker 3 fix to cover `lib/application/dual_ledger/providers.dart` which Plan 04-01 Task 3 step 7 renames to `repository_providers.dart` — pure renames count as touched per CONTEXT.md D-17 strict) (computed via `comm -12 <sorted-touched> <sorted-needing-tests>` — see `<interfaces>` below). For each source file the plan ships a focused characterization test that:
- locks current observable behavior (provider construction, key state transitions, stream output shape)
- uses Mocktail-style hand-written fakes inline (CONTEXT.md D-08, D-10)
- never touches real `flutter_secure_storage` (FUTURE-ARCH-04 protection)
- uses `AppDatabase.forTesting()` when a database is needed; never SQLCipher
- imports from the CURRENT pre-refactor file paths (Plans 04-01/02 update test imports as part of their refactor commits)

Files NOT in the intersection (e.g., `category_reorder_notifier.dart`, `home_providers.dart`, `today_transactions_provider.dart`, `home_screen.dart`) are already ≥80% covered pre-Phase-4 — their existing tests must continue to pass through the refactors per CONTEXT.md D-17.

Purpose: Provide the safety net so that Plans 04-01..04 can refactor 65–80 files without behavioral regression. Without these tests, coverage_gate.dart will fail at every per-plan exit gate.

Output: 20 new test files, each Mocktail-only, each ≥40 lines, all GREEN against the pre-refactor codebase.
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
@.planning/audit/files-needing-tests.txt
@CLAUDE.md

<!-- Mocktail-only template: read in full -->
@test/unit/application/family_sync/create_group_use_case_test.dart

<!-- Phase 3 hand-written fake pattern: read in full -->
@test/core/initialization/app_initializer_test.dart

<!-- Source files to characterize (read each before writing the matching test) -->
@lib/features/accounting/presentation/providers/voice_providers.dart
@lib/features/accounting/presentation/providers/repository_providers.dart
@lib/features/accounting/presentation/providers/use_case_providers.dart
@lib/features/accounting/presentation/screens/transaction_confirm_screen.dart
@lib/features/accounting/presentation/screens/transaction_entry_screen.dart
@lib/features/accounting/presentation/screens/voice_input_screen.dart
@lib/features/accounting/presentation/widgets/transaction_list_tile.dart
@lib/features/analytics/presentation/providers/analytics_providers.dart
@lib/features/analytics/presentation/providers/repository_providers.dart
@lib/features/analytics/presentation/screens/analytics_screen.dart
@lib/features/family_sync/presentation/providers/avatar_sync_providers.dart
@lib/features/family_sync/presentation/providers/group_providers.dart
@lib/features/family_sync/presentation/providers/repository_providers.dart
@lib/features/family_sync/presentation/providers/sync_providers.dart
@lib/features/family_sync/presentation/screens/create_group_screen.dart
@lib/features/home/presentation/providers/shadow_books_provider.dart
@lib/features/profile/presentation/providers/user_profile_providers.dart
@lib/features/settings/presentation/providers/backup_providers.dart
@lib/features/settings/presentation/widgets/appearance_section.dart

<interfaces>
<!-- The 19-file intersection (Phase 4 touched ∩ files-needing-tests.txt) -->
<!-- Computed via: comm -12 <sort phase4_touched> <sort files-needing-tests.txt> -->

DI providers (4 files): repository_providers (accounting, analytics, family_sync), use_case_providers (accounting), voice_providers (accounting)
Notifier/state providers (5 files): analytics_providers, avatar_sync_providers, group_providers, sync_providers, backup_providers
Async data providers (3 files): shadow_books_provider, user_profile_providers, settings backup_providers
Screens (5 files): transaction_confirm_screen, transaction_entry_screen, voice_input_screen, analytics_screen, create_group_screen
Widgets (2 files): transaction_list_tile, appearance_section

<!-- Mocktail template signatures (from create_group_use_case_test.dart, app_initializer_test.dart) -->
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class _MockSomeService extends Mock implements SomeService {}

void main() {
  late _MockSomeService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = _MockSomeService();
    container = ProviderContainer(overrides: [
      someServiceProvider.overrideWithValue(mockService),
    ]);
    when(() => mockService.someMethod(any())).thenAnswer((_) async => 'result');
  });

  tearDown(() => container.dispose());

  test('describes observable behavior', () async {
    final result = await container.read(someProviderProvider.future);
    expect(result, 'result');
  });
}
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write characterization tests for the 4 DI provider files + 1 application-layer dual_ledger providers file (accounting/voice, accounting/repository, accounting/use_case, family_sync/repository, application/dual_ledger/providers)</name>
  <files>
    test/unit/features/accounting/presentation/providers/voice_providers_characterization_test.dart,
    test/unit/features/accounting/presentation/providers/repository_providers_characterization_test.dart,
    test/unit/features/accounting/presentation/providers/use_case_providers_characterization_test.dart,
    test/unit/features/family_sync/presentation/providers/repository_providers_characterization_test.dart,
    test/unit/application/dual_ledger/providers_characterization_test.dart
  </files>
  <read_first>
    - lib/features/accounting/presentation/providers/voice_providers.dart (full file — 4 providers including merchantDatabaseProvider keepAlive at line 16)
    - lib/features/accounting/presentation/providers/repository_providers.dart (full file — 8 repository providers)
    - lib/features/accounting/presentation/providers/use_case_providers.dart (full file — includes resolveLedgerTypeService at lines 66-74 which Plan 04-03 deletes)
    - lib/features/family_sync/presentation/providers/repository_providers.dart (full file — 6 sync-client providers)
    - lib/application/dual_ledger/providers.dart (full file — `ruleEngineProvider` keepAlive at line 9, `classificationServiceProvider` at line 14; Plan 04-01 Task 3 step 7 RENAMES this file to `repository_providers.dart` — pure rename counts as touched per CONTEXT.md D-17 strict)
    - test/unit/application/family_sync/create_group_use_case_test.dart (Mocktail-only template)
    - test/core/initialization/app_initializer_test.dart (hand-written fake pattern)
  </read_first>
  <action>
    For each of the 4 DI provider files, create a Mocktail-only characterization test in `test/unit/features/<f>/presentation/providers/<file>_characterization_test.dart` that:

    1. Imports `package:flutter_test/flutter_test.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `package:mocktail/mocktail.dart` ONLY (NEVER `package:mockito/...`).
    2. For each `@riverpod`/`@Riverpod(keepAlive: true)` function in the source file, declares an inline `class _Mock<DepType> extends Mock implements DepType {}` for each constructor dependency.
    3. Builds a `ProviderContainer` with `overrides: [...]` for every infrastructure-touching dependency.
    4. Stubs default behavior with `when(() => mock.method(any())).thenAnswer(...)`.
    5. For each provider, asserts `container.read(<providerName>Provider)` returns a non-null instance of the expected type.
    6. For each `@Riverpod(keepAlive: true)` provider, asserts the keepAlive behavior — read provider once, dispose all auto-dispose dependencies, read again, assert SAME instance returned (proves keepAlive). Specifically: `voice_providers_characterization_test.dart` MUST verify `merchantDatabaseProvider` returns same instance across two reads.
    7. NEVER call real `flutter_secure_storage`; if a provider depends on `KeyManager` / `MasterKeyRepository`, override with `_MockKeyManager`/`_MockMasterKeyRepository` and stub method returns.
    8. NEVER use `@GenerateMocks` annotation.
    9. Test file MUST end with `_test.dart` and live at the path mirroring the source file (project convention).

    Specifically for `use_case_providers_characterization_test.dart`: include a test that `resolveLedgerTypeServiceProvider` currently constructs without throwing — this is the PRE-deletion behavior; Plan 04-03 deletes the provider entirely; this test must be DELETED in Plan 04-03 commit 4 (this is acceptable churn).

    Specifically for `dual_ledger/providers_characterization_test.dart` (added per Blocker 3 fix): exercises `ruleEngineProvider` (keepAlive — verify same instance across two reads) and `classificationServiceProvider` construction. Plan 04-01 Task 3 step 7 RENAMES `lib/application/dual_ledger/providers.dart` → `repository_providers.dart`; this characterization test locks the pre-rename behavior. Plan 04-01 Task 3 step 7 must update this test\'s import path from `package:home_pocket_app/application/dual_ledger/providers.dart` → `package:home_pocket_app/application/dual_ledger/repository_providers.dart` as part of the rename commit (existing test rewrite pattern).
  </action>
  <verify>
    <automated>flutter test test/unit/features/accounting/presentation/providers/ test/unit/features/family_sync/presentation/providers/repository_providers_characterization_test.dart test/unit/application/dual_ledger/providers_characterization_test.dart 2>&amp;1 | grep -E "(All tests passed|failed)"</automated>
  </verify>
  <acceptance_criteria>
    - `flutter test test/unit/features/accounting/presentation/providers/voice_providers_characterization_test.dart` exits 0
    - `flutter test test/unit/features/accounting/presentation/providers/repository_providers_characterization_test.dart` exits 0
    - `flutter test test/unit/features/accounting/presentation/providers/use_case_providers_characterization_test.dart` exits 0
    - `flutter test test/unit/features/family_sync/presentation/providers/repository_providers_characterization_test.dart` exits 0
    - `flutter test test/unit/application/dual_ledger/providers_characterization_test.dart` exits 0 (Blocker 3 fix — locks rename target behavior)
    - `grep -l "package:mockito" test/unit/features/accounting/presentation/providers/*_characterization_test.dart test/unit/features/family_sync/presentation/providers/repository_providers_characterization_test.dart` returns no matches
    - `grep -l "@GenerateMocks" test/unit/features/accounting/presentation/providers/*_characterization_test.dart test/unit/features/family_sync/presentation/providers/repository_providers_characterization_test.dart` returns no matches
    - `grep "extends Mock implements" test/unit/features/accounting/presentation/providers/voice_providers_characterization_test.dart` returns at least 1 match
    - `wc -l test/unit/features/accounting/presentation/providers/voice_providers_characterization_test.dart` reports ≥40 lines
  </acceptance_criteria>
  <done>
    5 DI-provider characterization test files exist (4 feature-side + 1 application/dual_ledger/providers.dart per Blocker 3), each Mocktail-only, each ≥40 lines, all GREEN against current codebase.
  </done>
</task>

<task type="auto">
  <name>Task 2: Write characterization tests for the 5 notifier/state provider files (analytics_providers, avatar_sync_providers, group_providers, sync_providers, backup_providers) + 3 async-data providers (shadow_books_provider, user_profile_providers, settings_providers via backup_providers covered above; add user_profile_providers as separate file; shadow_books_provider as separate)</name>
  <files>
    test/unit/features/analytics/presentation/providers/analytics_providers_characterization_test.dart,
    test/unit/features/analytics/presentation/providers/repository_providers_characterization_test.dart,
    test/unit/features/family_sync/presentation/providers/avatar_sync_providers_characterization_test.dart,
    test/unit/features/family_sync/presentation/providers/group_providers_characterization_test.dart,
    test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart,
    test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart,
    test/unit/features/profile/presentation/providers/user_profile_providers_characterization_test.dart,
    test/unit/features/settings/presentation/providers/backup_providers_characterization_test.dart
  </files>
  <read_first>
    - lib/features/analytics/presentation/providers/analytics_providers.dart (full file)
    - lib/features/analytics/presentation/providers/repository_providers.dart (full file)
    - lib/features/family_sync/presentation/providers/sync_providers.dart (full file — verify `transactionChangeTracker` line 118 keepAlive, `syncEngine` line 141 keepAlive, `groupMembers` line 161 stream)
    - lib/features/family_sync/presentation/providers/avatar_sync_providers.dart (full file)
    - lib/features/family_sync/presentation/providers/group_providers.dart (full file)
    - lib/features/home/presentation/providers/shadow_books_provider.dart (full file)
    - lib/features/profile/presentation/providers/user_profile_providers.dart (full file)
    - lib/features/settings/presentation/providers/backup_providers.dart (full file)
    - test/unit/application/family_sync/create_group_use_case_test.dart (Mocktail-only template)
  </read_first>
  <action>
    For each of the 8 provider files above, create a Mocktail-only characterization test mirroring Task 1's pattern. Specifics:

    - `sync_providers_characterization_test.dart`: MUST verify `transactionChangeTrackerProvider` returns same instance across two reads (HIGH-05 keepAlive locked); MUST verify `syncEngineProvider` returns same instance across two reads (HIGH-05 keepAlive locked); MUST verify `groupMembersProvider` returns `Stream.value([])` when `activeGroupProvider` returns null.
    - `avatar_sync_providers_characterization_test.dart`: verify `syncAvatarUseCaseProvider` constructs without error using mocked dependencies.
    - `group_providers_characterization_test.dart`: for each use-case provider in the file, verify construction with mocked dependencies.
    - `analytics_providers_characterization_test.dart`: verify each notifier's initial state and key transitions.
    - `analytics/repository_providers_characterization_test.dart`: verify each repository provider constructs.
    - `shadow_books_provider_characterization_test.dart`: verify `shadowBooksProvider` and `shadowAggregateProvider` Future resolution.
    - `user_profile_providers_characterization_test.dart`: verify `userProfileProvider` Future resolution + `userProfileRepositoryProvider`/`getUserProfileUseCaseProvider`/`saveUserProfileUseCaseProvider` construction.
    - `backup_providers_characterization_test.dart`: verify `exportBackupUseCaseProvider`/`importBackupUseCaseProvider`/`clearAllDataUseCaseProvider` construction.

    All tests use inline `class _Mock<X> extends Mock implements X {}` — NO Mockito, NO `@GenerateMocks`. All mocks of `KeyManager`/`AppDatabase`/`flutter_secure_storage`-touching repos use `_Mock<X>` with stubbed methods.
  </action>
  <verify>
    <automated>flutter test test/unit/features/analytics/presentation/providers/ test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart test/unit/features/family_sync/presentation/providers/avatar_sync_providers_characterization_test.dart test/unit/features/family_sync/presentation/providers/group_providers_characterization_test.dart test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart test/unit/features/profile/presentation/providers/user_profile_providers_characterization_test.dart test/unit/features/settings/presentation/providers/backup_providers_characterization_test.dart 2>&amp;1 | grep -E "(All tests passed|failed)"</automated>
  </verify>
  <acceptance_criteria>
    - All 8 test files exit 0 individually
    - `grep -l "package:mockito" test/unit/features/family_sync/presentation/providers/*.dart test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart test/unit/features/profile/presentation/providers/user_profile_providers_characterization_test.dart` returns no matches
    - `grep "transactionChangeTrackerProvider" test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart` returns at least 2 matches (read twice for keepAlive verification)
    - `grep "syncEngineProvider" test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart` returns at least 2 matches
    - `wc -l test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart` reports ≥60 lines
  </acceptance_criteria>
  <done>
    8 notifier/state/async-data provider characterization test files exist, all GREEN, sync_providers test verifies keepAlive on `transactionChangeTracker` and `syncEngine`.
  </done>
</task>

<task type="auto">
  <name>Task 3: Write characterization tests for the 5 screens + 2 widgets (transaction_confirm_screen, transaction_entry_screen, voice_input_screen, analytics_screen, create_group_screen, transaction_list_tile, appearance_section)</name>
  <files>
    test/unit/features/accounting/presentation/screens/transaction_confirm_screen_characterization_test.dart,
    test/unit/features/accounting/presentation/screens/transaction_entry_screen_characterization_test.dart,
    test/unit/features/accounting/presentation/screens/voice_input_screen_characterization_test.dart,
    test/unit/features/accounting/presentation/widgets/transaction_list_tile_characterization_test.dart,
    test/unit/features/analytics/presentation/screens/analytics_screen_characterization_test.dart,
    test/unit/features/family_sync/presentation/screens/create_group_screen_characterization_test.dart,
    test/unit/features/settings/presentation/widgets/appearance_section_characterization_test.dart
  </files>
  <read_first>
    - lib/features/accounting/presentation/screens/transaction_confirm_screen.dart (full file — note imports of DateFormatter line 11, NumberFormatter line 12)
    - lib/features/accounting/presentation/screens/transaction_entry_screen.dart (full file — note import of DateFormatter line 7)
    - lib/features/accounting/presentation/screens/voice_input_screen.dart (full file — note imports of DateFormatter line 11, NumberFormatter line 12, SpeechRecognitionService line 13)
    - lib/features/accounting/presentation/widgets/transaction_list_tile.dart (full file — note import of DateFormatter line 4)
    - lib/features/analytics/presentation/screens/analytics_screen.dart (full file — note imports of DateFormatter line 7, providers.dart line 8)
    - lib/features/family_sync/presentation/screens/create_group_screen.dart (full file — note imports of crypto/providers line 13, websocket_service line 14)
    - lib/features/settings/presentation/widgets/appearance_section.dart (full file — note import of locale_settings line 5)
    - test/unit/application/family_sync/create_group_use_case_test.dart (Mocktail-only template)
  </read_first>
  <action>
    For each of the 7 screen/widget files, create a Mocktail-only `testWidgets` characterization test in `test/unit/features/<f>/presentation/screens/<file>_characterization_test.dart` (or `widgets/`) that:

    1. Imports `package:flutter_test/flutter_test.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `package:mocktail/mocktail.dart`, `package:home_pocket/...` for the screen/widget.
    2. Wraps the widget in `MaterialApp` + `ProviderScope(overrides: [...])`. Use the `S.delegate` from `lib/generated/...` so locale-dependent text renders.
    3. Mocks every infrastructure-touching provider via `_MockX extends Mock implements X` + `provider.overrideWithValue(mock)`.
    4. For each screen, render with `await tester.pumpWidget(...)` then `await tester.pumpAndSettle()`.
    5. Assert at least one observable element renders: a `Scaffold` exists, an `AppBar` exists, expected text labels via `find.text(...)` are visible. For widgets without a `Scaffold` (e.g., `transaction_list_tile`, `appearance_section`), assert key `find.byType(...)` matches.
    6. For screens that format dates/numbers (transaction_confirm, voice_input, analytics, transaction_entry, transaction_list_tile): assert at least one formatted text appears (e.g., `find.textContaining('/')` for date or `find.textContaining('¥')` for currency). This locks the formatter call sites BEFORE Plan 04-02 routes them through `formatterServiceProvider`.
    7. For `create_group_screen`: mock `relayApiClientProvider`, `keyManagerProvider`, `webSocketServiceProvider`, `e2eeServiceProvider` and assert the screen renders without crashing.
    8. For `appearance_section`: mock `localeProvider` and assert language picker UI renders.
    9. NEVER use Mockito; NEVER use `@GenerateMocks`; NEVER touch real `flutter_secure_storage`.
  </action>
  <verify>
    <automated>flutter test test/unit/features/accounting/presentation/screens/ test/unit/features/accounting/presentation/widgets/transaction_list_tile_characterization_test.dart test/unit/features/analytics/presentation/screens/analytics_screen_characterization_test.dart test/unit/features/family_sync/presentation/screens/create_group_screen_characterization_test.dart test/unit/features/settings/presentation/widgets/appearance_section_characterization_test.dart 2>&amp;1 | grep -E "(All tests passed|failed)"</automated>
  </verify>
  <acceptance_criteria>
    - All 7 test files exit 0 individually
    - `grep -l "package:mockito" test/unit/features/accounting/presentation/screens/*_characterization_test.dart test/unit/features/accounting/presentation/widgets/transaction_list_tile_characterization_test.dart test/unit/features/analytics/presentation/screens/analytics_screen_characterization_test.dart test/unit/features/family_sync/presentation/screens/create_group_screen_characterization_test.dart test/unit/features/settings/presentation/widgets/appearance_section_characterization_test.dart` returns no matches
    - `grep "testWidgets" test/unit/features/accounting/presentation/screens/transaction_confirm_screen_characterization_test.dart` returns at least 1 match
    - `wc -l test/unit/features/accounting/presentation/screens/voice_input_screen_characterization_test.dart` reports ≥40 lines
  </acceptance_criteria>
  <done>
    7 screen/widget characterization test files exist, all GREEN, each renders the widget without crashing using mocked infrastructure providers.
  </done>
</task>

<task type="auto">
  <name>Task 4: Run full Phase-4 characterization test suite + per-file coverage gate</name>
  <files>(no files modified — verification only)</files>
  <read_first>
    - scripts/coverage_gate.dart (per-plan exit gate signature)
    - All 20 test files created in Tasks 1-3
  </read_first>
  <action>
    Run the full characterization test suite and verify per-file coverage on the 20 source files.

    1. Run `flutter test --coverage test/unit/features/ test/unit/application/dual_ledger/` to generate `coverage/lcov.info`.
    2. Run the lcov filter to produce `coverage/lcov_clean.info` (strip `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `lib/generated/**`). Use the project's existing filter command from Phase 2 (likely `dart run scripts/lcov_filter.dart` or coverde-based filter — check `.github/workflows/audit.yml` coverage job for the exact command).
    3. Run `dart run scripts/coverage_gate.dart --files lib/features/accounting/presentation/providers/voice_providers.dart,lib/features/accounting/presentation/providers/repository_providers.dart,lib/features/accounting/presentation/providers/use_case_providers.dart,lib/features/accounting/presentation/screens/transaction_confirm_screen.dart,lib/features/accounting/presentation/screens/transaction_entry_screen.dart,lib/features/accounting/presentation/screens/voice_input_screen.dart,lib/features/accounting/presentation/widgets/transaction_list_tile.dart,lib/features/analytics/presentation/providers/analytics_providers.dart,lib/features/analytics/presentation/providers/repository_providers.dart,lib/features/analytics/presentation/screens/analytics_screen.dart,lib/features/family_sync/presentation/providers/avatar_sync_providers.dart,lib/features/family_sync/presentation/providers/group_providers.dart,lib/features/family_sync/presentation/providers/repository_providers.dart,lib/features/family_sync/presentation/providers/sync_providers.dart,lib/features/family_sync/presentation/screens/create_group_screen.dart,lib/features/home/presentation/providers/shadow_books_provider.dart,lib/features/profile/presentation/providers/user_profile_providers.dart,lib/features/settings/presentation/providers/backup_providers.dart,lib/features/settings/presentation/widgets/appearance_section.dart,lib/application/dual_ledger/providers.dart --threshold 80 --lcov coverage/lcov_clean.info`. Must exit 0.
    4. If coverage_gate exits non-zero for any file, return to Tasks 1-3 and add coverage for the failing file(s) before proceeding.

    Commit message format (do not skip git commit step):
    `test(04-06): characterization tests for Phase-4 touched-files ∩ files-needing-tests.txt (HIGH-08 prereq)`

    Then commit. After commit, this plan is COMPLETE — Plans 04-01..05 may proceed.
  </action>
  <verify>
    <automated>dart run scripts/coverage_gate.dart --files lib/features/accounting/presentation/providers/voice_providers.dart,lib/features/family_sync/presentation/providers/sync_providers.dart --threshold 80 --lcov coverage/lcov_clean.info; echo "exit=$?"</automated>
  </verify>
  <acceptance_criteria>
    - `flutter test test/unit/features/ test/unit/application/dual_ledger/` exits 0 (all 20 new tests + existing tests GREEN)
    - `coverage/lcov_clean.info` exists and contains entries for all 20 source files (`grep -c "^SF:" coverage/lcov_clean.info` returns ≥20)
    - `dart run scripts/coverage_gate.dart --files <20 files comma-separated> --threshold 80 --lcov coverage/lcov_clean.info` exits 0
    - `flutter analyze` exits 0
    - `git log --oneline -1` shows commit message starting with `test(04-06):`
  </acceptance_criteria>
  <done>
    All 20 characterization tests GREEN; coverage_gate.dart exits 0 against the 20-file list (including dual_ledger/providers.dart per Blocker 3); commit landed; Plans 04-01..05 unblocked.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| (n/a) | This plan adds test code only. No production trust boundaries are introduced or modified. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-04-06-01 | I (Information disclosure) | test files | accept | STRIDE analysis: no new auth surface, no new IPC boundary, no new persisted secret, no new external input. Tests use Mocktail mocks only — they never touch real `flutter_secure_storage` (FUTURE-ARCH-04 protection enforced). No HIGH-severity threats introduced by Plan 04-06. |
</threat_model>

<verification>
- `flutter test test/unit/features/` exits 0
- `flutter analyze` exits 0
- `grep -rl "package:mockito" test/unit/features/` returns no matches in newly created files
- `find test/unit/features test/unit/application/dual_ledger -name "*_characterization_test.dart" -newer .planning/phases/04-high-fixes/04-CONTEXT.md | wc -l` returns ≥20
- coverage_gate.dart exits 0 against the 20 source files at threshold 80
</verification>

<success_criteria>
- 20 new `_characterization_test.dart` files exist at the paths declared in `files_modified`
- Every test is Mocktail-only (no `package:mockito`, no `@GenerateMocks`, no `*.mocks.dart`)
- All tests run GREEN against current pre-refactor codebase
- coverage_gate.dart at threshold 80 exits 0 on all 20 source files
- Commit landed with message `test(04-06): ...`
- Plans 04-01..05 may now reference these tests and run their refactors against a verified safety net
</success_criteria>

<output>
After completion, create `.planning/phases/04-high-fixes/04-06-SUMMARY.md` documenting:
- The 20 tests created and the source files they cover (including the +1 added for `lib/application/dual_ledger/providers.dart` rename target per Blocker 3)
- Confirmation that all 20 are Mocktail-only with inline fakes
- coverage_gate.dart exit 0 evidence
- Note any tests that required `AppDatabase.forTesting()` or special locale setup so Plans 04-01..05 know what infrastructure is already verified
</output>
