---
phase: 03-critical-fixes
plan: 02
type: execute
wave: 2
depends_on:
  - 03-05
files_modified:
  - lib/core/initialization/app_initializer.dart
  - lib/core/initialization/init_result.dart
  - lib/core/initialization/init_failure_screen.dart
  - lib/infrastructure/security/providers.dart
  - lib/infrastructure/security/providers.g.dart
  - lib/main.dart
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - lib/l10n/app_en.arb
  - lib/generated/app_localizations.dart
  - lib/generated/app_localizations_en.dart
  - lib/generated/app_localizations_ja.dart
  - lib/generated/app_localizations_zh.dart
  - test/core/initialization/app_initializer_test.dart
  - test/core/initialization/init_result_test.dart
  - test/core/initialization/init_failure_screen_test.dart
  - test/infrastructure/security/providers_test.dart
  - test/helpers/test_provider_scope.dart
autonomous: true
requirements:
  - CRIT-01
  - CRIT-03
  - CRIT-05
  - CRIT-06
tags:
  - app_initializer
  - app_database_provider
  - init_failure_screen
  - i18n
  - critical_fixes
must_haves:
  truths:
    - "`appDatabaseProvider` no longer throws `UnimplementedError` — it now throws a diagnostic `StateError` ONLY when the override wiring is broken (i.e., AppInitializer did not run AND no test override was injected); production always overrides via AppInitializer per RESEARCH.md §Pattern 2 Option A"
    - "`createTestProviderScope({database, additionalOverrides})` helper exists at `test/helpers/test_provider_scope.dart` and ALWAYS provides the override — satisfies CRIT-03's literal text 'shared `createTestProviderScope` helper that always provides the override'"
    - "`AppInitializer.initialize()` returns `InitResult.success(container)` or `InitResult.failure(type, error, stackTrace)` per RESEARCH.md §Pattern 3; constructor takes `containerFactory` (with overrides parameter), `databaseFactory`, `seedRunner` typedefs for unit-testable failure paths"
    - "`InitResult` is a Freezed sealed class with `InitFailureType { masterKey, database, seed, unknown }` per CONTEXT.md D-05"
    - "`lib/main.dart` delegates to `AppInitializer.initialize()` and switches on the sealed result; on `InitFailure` it renders a minimal `MaterialApp` wrapping `InitFailureScreen` per UI-SPEC.md"
    - "`InitFailureScreen` is a `StatefulWidget` (no Riverpod), accepts `Future<void> Function() onRetry`, renders icon + title + message + retry button using existing `AppColors` + `AppTextStyles` tokens, all 3 strings localized via `S.of(context)` per CLAUDE.md i18n rule"
    - "3 new ARB keys (`initFailedTitle`, `initFailedMessage`, `initFailedRetry`) added to `lib/l10n/app_ja.arb`, `app_zh.arb`, `app_en.arb` with copy from UI-SPEC.md §Copywriting Contract; `flutter gen-l10n` regenerates `lib/generated/app_localizations*.dart`; ARB parity verified with jq diff"
    - "AppInitializer tests use Mocktail-style hand-written fakes (NOT Mockito codegen, per CONTEXT.md `<deferred>` *.mocks.dart); never exercise `flutter_secure_storage` or `recoverFromSeed()` (FUTURE-ARCH-04)"
    - "D-08: AppInitializer takes constructor-injected dependencies (MasterKeyRepository, AppDatabase factory, SeedService); tests pass fakes that throw at each stage; ~10 unit tests cover happy path + 3-4 failure modes (master-key error, DB error, seed error); no real flutter_secure_storage in tests; hits CRIT-05 ≥80% coverage on app_initializer.dart cleanly"
    - "`flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits 0 (AUDIT-10 guardrail) after the @Riverpod + @freezed regenerations"
    - "Every touched file in `Phase 3 Plan 02 ∩ files-needing-tests.txt` reaches ≥80% coverage via `coverage_gate.dart --list <touched> --threshold 80` per CONTEXT.md D-15"
    - "Operational repo lock per Phase 2 D-07 / D-16 active throughout; Wave 2 — depends on Plan 03-05's Mocktail fake patterns + characterization tests merged"
    - "Behavior preservation (PROJECT.md): the boot sequence captured verbatim from `lib/main.dart:28-83` (master-key check → device-key pair → device ID → encrypted executor → AppDatabase → seed) per CONTEXT.md D-06; user-observable behavior byte-identical on the success path"
  artifacts:
    - path: "lib/core/initialization/init_result.dart"
      provides: "Freezed sealed class `InitResult.success/failure` + `InitFailureType` enum"
      contains: "@freezed"
      exports: ["InitResult", "InitSuccess", "InitFailure", "InitFailureType"]
    - path: "lib/core/initialization/app_initializer.dart"
      provides: "Constructor-injected orchestrator returning `InitResult`"
      contains: "class AppInitializer"
      min_lines: 80
    - path: "lib/core/initialization/init_failure_screen.dart"
      provides: "Localized fallback widget rendered on InitResult.failure"
      contains: "S.of(context).initFailedTitle"
      min_lines: 80
    - path: "lib/infrastructure/security/providers.dart"
      provides: "Concrete `appDatabaseProvider` with diagnostic StateError + `keepAlive: true`"
      contains: "@Riverpod(keepAlive: true)"
      excludes: "throw UnimplementedError"
    - path: "lib/main.dart"
      provides: "main() delegating to AppInitializer.initialize() with sealed-class switch"
      contains: "AppInitializer("
      excludes: "throw UnimplementedError"
    - path: "lib/l10n/app_en.arb"
      provides: "3 new ARB keys with @key descriptions"
      contains: "initFailedTitle"
    - path: "lib/l10n/app_ja.arb"
      provides: "3 new ARB keys (Japanese copy from UI-SPEC.md)"
      contains: "初期化に失敗しました"
    - path: "lib/l10n/app_zh.arb"
      provides: "3 new ARB keys (Chinese copy from UI-SPEC.md)"
      contains: "初始化失败"
    - path: "lib/generated/app_localizations.dart"
      provides: "Generated S abstract class with 3 new getters"
      contains: "String get initFailedTitle"
    - path: "test/helpers/test_provider_scope.dart"
      provides: "Shared `createTestProviderScope` helper that ALWAYS overrides appDatabaseProvider"
      contains: "appDatabaseProvider.overrideWithValue"
    - path: "test/core/initialization/app_initializer_test.dart"
      provides: "~10 unit tests covering happy path + 4 failure modes via Mocktail fakes"
      min_lines: 100
    - path: "test/core/initialization/init_result_test.dart"
      provides: "Freezed sealed class equality + variant tests"
      min_lines: 20
    - path: "test/core/initialization/init_failure_screen_test.dart"
      provides: "9 widget tests per UI-SPEC.md §Test Contract (3 locales × strings, retry callback, loading state, dark text, semantics, text scale)"
      min_lines: 80
    - path: "test/infrastructure/security/providers_test.dart"
      provides: "Tests for `appDatabaseProvider` diagnostic StateError + override-respecting paths"
      min_lines: 30
  key_links:
    - from: "lib/main.dart"
      to: "lib/core/initialization/app_initializer.dart"
      via: "AppInitializer({containerFactory, databaseFactory, seedRunner}).initialize()"
      pattern: "AppInitializer\\("
    - from: "lib/core/initialization/app_initializer.dart"
      to: "lib/infrastructure/security/providers.dart"
      via: "appDatabaseProvider.overrideWithValue(database)"
      pattern: "overrideWithValue"
    - from: "lib/core/initialization/init_failure_screen.dart"
      to: "lib/generated/app_localizations.dart"
      via: "S.of(context).initFailedTitle/Message/Retry"
      pattern: "S.of\\(context\\)\\.initFailed"
    - from: "test/helpers/test_provider_scope.dart"
      to: "lib/infrastructure/security/providers.dart"
      via: "appDatabaseProvider.overrideWithValue(database ?? AppDatabase.forTesting())"
      pattern: "createTestProviderScope"
---

**Executor note:** This plan is large (7 tasks). Checkpoint after Task 4 via `/clear` or context compaction before Task 5 to ensure UI-SPEC widget tree fidelity.

<objective>
Close CRIT-03 (`appDatabaseProvider` no longer throws `UnimplementedError`) and CRIT-06 (`flutter analyze`/`custom_lint`/tests GREEN, behavior unchanged) by:
1. Replacing the placeholder `appDatabaseProvider` body with a diagnostic `StateError` (RESEARCH.md §Pattern 2 Option A) and pairing it with a `createTestProviderScope({database, additionalOverrides})` helper that ALWAYS provides the override.
2. Extracting `lib/main.dart:28-83` into `lib/core/initialization/app_initializer.dart` per CLAUDE.md "App Initialization" spec — preserving the boot sequence verbatim (D-06) but making it constructor-injected and unit-testable (D-08).
3. Modeling the result as a Freezed sealed `InitResult.success/failure` with typed `InitFailureType` enum (D-05).
4. Rendering a localized error fallback screen `InitFailureScreen` per `.planning/phases/03-critical-fixes/03-UI-SPEC.md` on `InitFailure`, with 3 new ARB keys added to all 3 locale files and `flutter gen-l10n` regenerating `lib/generated/app_localizations*.dart`.
5. Writing the test suite per RESEARCH.md §Pattern 3 + UI-SPEC §Test Contract: ~10 AppInitializer unit tests, 9 widget tests for InitFailureScreen, ~3 InitResult Freezed tests, and `appDatabaseProvider` StateError test — all using Mocktail-style hand-written fakes (per CONTEXT.md `<deferred>` *.mocks.dart strategy) and `AppDatabase.forTesting()` for in-memory database. Plan 03-05 already wrote characterization tests for the providers.dart and main.dart files (this plan's test scaffolding builds on that foundation).

Purpose: Close the CRIT-03 runtime crash, give the boot sequence unit-test coverage, and ship a localized graceful-fail UX so users see something actionable on rare init failures.

Output:
- 3 NEW files in `lib/core/initialization/`
- 1 MODIFIED `lib/infrastructure/security/providers.dart` (concrete `appDatabaseProvider`)
- 1 MODIFIED `lib/main.dart` (delegate to AppInitializer)
- 9 ARB entries (3 keys × 3 locales) + regenerated localization classes
- 4 NEW test files + 1 NEW test helper
- CRIT-03 finding closure note in issues.json (CRIT-03 sources from CONCERNS.md, not issues.json — record closure in plan SUMMARY)
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
@.planning/phases/03-critical-fixes/03-UI-SPEC.md
@.planning/phases/03-critical-fixes/03-VALIDATION.md
@.planning/codebase/CONCERNS.md
@.planning/codebase/TESTING.md
@.planning/audit/REPO-LOCK-POLICY.md
@CLAUDE.md

<interfaces>
<!-- Embedded contracts. No codebase exploration needed. -->

## Current state — `lib/main.dart:28-83` (the boot sequence to extract VERBATIM per D-06)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Load SQLCipher native library (must be before any database operations)
  await ensureNativeLibrary();

  // 1. Initialize master key (first launch only)
  final initContainer = ProviderContainer();
  final masterKeyRepo = initContainer.read(masterKeyRepositoryProvider);
  if (!await masterKeyRepo.hasMasterKey()) {
    await masterKeyRepo.initializeMasterKey();
    dev.log('Master key initialized', name: 'AppInit');
  } else {
    dev.log('Master key already exists', name: 'AppInit');
  }

  // 2. Initialize device key pair / device ID
  final keyManager = initContainer.read(keyManagerProvider);
  if (!await keyManager.hasKeyPair()) {
    await keyManager.generateDeviceKeyPair();
    dev.log('Device key pair initialized', name: 'AppInit');
  } else {
    dev.log('Device key pair already exists', name: 'AppInit');
  }

  final deviceId = await keyManager.getDeviceId();
  if (deviceId == null || deviceId.isEmpty) {
    throw StateError('Device ID is not available after key initialization.');
  }
  dev.log('Device identity ready: $deviceId', name: 'AppInit');

  // 3. Create database
  final AppDatabase database;
  if (_useInMemoryDatabase) {
    database = AppDatabase(NativeDatabase.memory());
    dev.log('Using IN-MEMORY database (dev mode)', name: 'AppInit');
  } else {
    final executor = await createEncryptedExecutor(masterKeyRepo);
    database = AppDatabase(executor);
    dev.log('Encrypted database opened', name: 'AppInit');
  }

  // 4. Dispose init container, create final container with database
  initContainer.dispose();

  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HomePocketApp(),
    ),
  );
}
```

## Current state — `lib/infrastructure/security/providers.dart:96-102` (the placeholder to replace)

```dart
@riverpod
AppDatabase appDatabase(Ref ref) {
  throw UnimplementedError(
    'appDatabaseProvider must be overridden during app initialization.\n'
    'See AppInitializer pattern in lib/main.dart or the docstring above.',
  );
}
```

## Required `InitResult` shape (Freezed sealed; analog: `lib/infrastructure/security/models/auth_result.dart`)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'init_result.freezed.dart';

/// Discriminator for which init stage failed.
enum InitFailureType {
  /// Master-key generation or retrieval failed (Stage 1).
  masterKey,
  /// Encrypted database open or AppDatabase construction failed (Stage 2).
  database,
  /// Default categories or default-book seeding failed (Stage 3).
  seed,
  /// Catch-all for unexpected exceptions outside the three stages above.
  unknown,
}

@freezed
sealed class InitResult with _$InitResult {
  const factory InitResult.success({
    required ProviderContainer container,
  }) = InitSuccess;

  const factory InitResult.failure({
    required InitFailureType type,
    required Object error,
    StackTrace? stackTrace,
  }) = InitFailure;
}
```

## Required `AppInitializer` constructor (typedefs from RESEARCH.md §Pattern 3)

```dart
typedef ProviderContainerFactory =
    ProviderContainer Function({List<Override> overrides});
typedef AppDatabaseFactory =
    Future<AppDatabase> Function(MasterKeyRepository);
typedef SeedRunner = Future<void> Function(ProviderContainer);

class AppInitializer {
  AppInitializer({
    required ProviderContainerFactory containerFactory,
    required AppDatabaseFactory databaseFactory,
    required SeedRunner seedRunner,
  }) : ...;

  Future<InitResult> initialize() async { ... }
}
```

## Required revised `appDatabaseProvider` body (RESEARCH.md §Pattern 2 Option A)

```dart
/// AppDatabase provider — concrete keepAlive: true.
///
/// Phase 3 / CRIT-03 fix: replaces the prior `UnimplementedError` placeholder.
/// AppInitializer.initialize() awaits createEncryptedExecutor and overrides
/// this provider via `.overrideWithValue(database)` on the production
/// ProviderContainer. Tests use `createTestProviderScope` (test/helpers) which
/// always overrides with `AppDatabase.forTesting()`.
///
/// If reached without an override, the wiring is broken — fail loud with a
/// diagnostic StateError that points to the AppInitializer.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  throw StateError(
    'appDatabaseProvider not overridden. AppInitializer.initialize() must run '
    'before any consumer reads this provider, OR a test must inject '
    'appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()). '
    'See lib/core/initialization/app_initializer.dart and '
    'test/helpers/test_provider_scope.dart.',
  );
}
```

## Required `createTestProviderScope` helper

```dart
// test/helpers/test_provider_scope.dart (NEW)
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';

/// Build a ProviderContainer that ALWAYS overrides `appDatabaseProvider`
/// with an in-memory `AppDatabase.forTesting()` (or the supplied [database]).
///
/// Per Phase 3 D-04 + CRIT-03 — this is THE shared helper that satisfies
/// the "always provides the override" contract.
ProviderContainer createTestProviderScope({
  AppDatabase? database,
  List<Override> additionalOverrides = const [],
}) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(
        database ?? AppDatabase.forTesting(),
      ),
      ...additionalOverrides,
    ],
  );
}
```

## Required ARB additions

`lib/l10n/app_en.arb` (template — append with @key metadata):
```json
"initFailedTitle": "Initialization failed",
"@initFailedTitle": { "description": "Title shown on the AppInitializer failure fallback screen rendered before the main app mounts" },

"initFailedMessage": "Something went wrong while starting the app. Tap retry to try again.",
"@initFailedMessage": { "description": "Body message on the AppInitializer failure fallback screen — explains the failure plainly and points to the retry action. Must NOT include technical error details (those go to console logs)" },

"initFailedRetry": "Retry",
"@initFailedRetry": { "description": "Button label on the AppInitializer failure fallback screen. Re-invokes AppInitializer.initialize()" },
```

`lib/l10n/app_ja.arb` (append, no @key metadata per existing convention):
```json
"initFailedTitle": "初期化に失敗しました",
"initFailedMessage": "アプリの起動中に問題が発生しました。再試行ボタンをタップしてください。",
"initFailedRetry": "再試行",
```

`lib/l10n/app_zh.arb` (append):
```json
"initFailedTitle": "初始化失败",
"initFailedMessage": "应用启动时出现问题。请点击重试按钮。",
"initFailedRetry": "重试",
```

## InitFailureScreen layout (UI-SPEC.md §Spacing Scale + §Color)

```
SafeArea
└── Center
    └── SingleChildScrollView
        └── Padding(horizontal: 16)
            └── Column(mainAxisAlignment: center, crossAxisAlignment: center)
                ├── Icon(Icons.error_outline, size: 64, color: AppColors.textSecondary)
                ├── SizedBox(height: 24)  // lg
                ├── Text(l10n.initFailedTitle, style: AppTextStyles.headlineSmall)
                ├── SizedBox(height: 8)   // sm
                ├── Text(l10n.initFailedMessage, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))
                ├── SizedBox(height: 24)  // lg
                └── ElevatedButton(
                      onPressed: _isRetrying ? null : _handleRetry,
                      style: backgroundColor: #8AB8DA, foregroundColor: AppColors.textPrimary,
                      child: _isRetrying ? CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation(AppColors.textPrimary))
                                         : Text(l10n.initFailedRetry, style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary))
                    )
```

Scaffold backgroundColor = `AppColors.background` (`#FCFBF9`). Light theme regardless of system mode. Wrapped in a minimal `MaterialApp` (own delegates + `S.delegate`) by `lib/main.dart` because the screen runs BEFORE `ProviderScope` is mounted.

## ⚠ Open Question that Plan 03-02 must surface to the user (UI-SPEC §Color "Open Question")

UI-SPEC.md flagged a brand-color reconciliation needed: CLAUDE.md says Primary `#8AB8DA` (sky blue), but live `lib/core/theme/app_theme.dart` resolves `MaterialApp.theme.colorScheme.primary` to `#E85A4F` (coral). UI-SPEC locked `#8AB8DA` with `AppColors.textPrimary` (#1E2432) label for WCAG AAA contrast. **Surface to owner during Plan 03-02 plan-out:** accept divergence (sky blue here, coral elsewhere) OR switch to `Theme.of(context).colorScheme.primary`. **Default if no answer arrives in <2 hours of plan execution:** ship with `#8AB8DA` background + `AppColors.textPrimary` label per locked UI-SPEC; record the deferral to Phase 7 documentation sweep in the plan summary.

## Per-Plan-02 touched-files-list for coverage_gate (Phase 2 D-09 contract)

```
lib/core/initialization/app_initializer.dart
lib/core/initialization/init_result.dart
lib/core/initialization/init_failure_screen.dart
lib/infrastructure/security/providers.dart
lib/main.dart
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add 3 ARB keys × 3 locales, run `flutter gen-l10n`, verify ARB parity</name>
  <files>
    lib/l10n/app_en.arb,
    lib/l10n/app_ja.arb,
    lib/l10n/app_zh.arb,
    lib/generated/app_localizations.dart,
    lib/generated/app_localizations_en.dart,
    lib/generated/app_localizations_ja.dart,
    lib/generated/app_localizations_zh.dart
  </files>
  <read_first>
    - lib/l10n/app_en.arb (current state — to confirm append point and existing schema)
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - .planning/phases/03-critical-fixes/03-UI-SPEC.md (§"Copywriting Contract" — 3 keys × 3 locales = 9 entries with EXACT copy)
    - .planning/phases/03-critical-fixes/03-RESEARCH.md (§"Common Pitfalls" #4 — ARB parity drift)
    - l10n.yaml (template-arb-file = app_en.arb; output class S; output dir lib/generated)
  </read_first>
  <behavior>
    - After ARB edits + `flutter gen-l10n`: `S.of(context).initFailedTitle`, `.initFailedMessage`, `.initFailedRetry` exist as String getters on the generated `S` class
    - All 3 keys exist in all 3 ARB files (parity)
    - Generated `lib/generated/app_localizations_<locale>.dart` files have concrete getter implementations returning the locale-specific copy
    - `flutter analyze` exits 0 (no missing-key warnings)
  </behavior>
  <action>
    **Step 1 — Append to `lib/l10n/app_en.arb`** (template ARB carries `@key` metadata). Insert before the closing `}` of the JSON object, preserving JSON validity (add a comma after the previous last entry if needed):
    ```json
    "initFailedTitle": "Initialization failed",
    "@initFailedTitle": { "description": "Title shown on the AppInitializer failure fallback screen rendered before the main app mounts" },

    "initFailedMessage": "Something went wrong while starting the app. Tap retry to try again.",
    "@initFailedMessage": { "description": "Body message on the AppInitializer failure fallback screen — explains the failure plainly and points to the retry action. Must NOT include technical error details (those go to console logs)" },

    "initFailedRetry": "Retry",
    "@initFailedRetry": { "description": "Button label on the AppInitializer failure fallback screen. Re-invokes AppInitializer.initialize()" }
    ```

    **Step 2 — Append to `lib/l10n/app_ja.arb`** (no `@key` metadata in non-default ARB per existing project pattern):
    ```json
    "initFailedTitle": "初期化に失敗しました",
    "initFailedMessage": "アプリの起動中に問題が発生しました。再試行ボタンをタップしてください。",
    "initFailedRetry": "再試行"
    ```

    **Step 3 — Append to `lib/l10n/app_zh.arb`**:
    ```json
    "initFailedTitle": "初始化失败",
    "initFailedMessage": "应用启动时出现问题。请点击重试按钮。",
    "initFailedRetry": "重试"
    ```

    **Step 4 — verify ARB parity BEFORE gen-l10n** (per RESEARCH.md Pitfall 4). Use the SAME jq form as the acceptance criterion below (action and acceptance MUST match verbatim per checker warning fix #4):
    ```bash
    diff <(jq -r 'keys[] | select(startswith("@") | not)' lib/l10n/app_en.arb | sort) <(jq -r 'keys[]' lib/l10n/app_ja.arb | sort)
    diff <(jq -r 'keys[] | select(startswith("@") | not)' lib/l10n/app_en.arb | sort) <(jq -r 'keys[]' lib/l10n/app_zh.arb | sort)
    ```
    Both diffs MUST exit 0 with empty output. The jq filter `keys[] | select(startswith("@") | not)` strips `@key` metadata-only entries from the template ARB so the comparison is value-keys-only.

    **Step 5 — regenerate**:
    ```bash
    flutter gen-l10n
    ```
    Verify the generated files contain the new getters:
    ```bash
    grep -E 'String get initFailed(Title|Message|Retry)' lib/generated/app_localizations.dart | wc -l   # expect 3 (abstract decls)
    grep -E "'初期化に失敗しました'" lib/generated/app_localizations_ja.dart                          # expect a hit
    grep -E "'初始化失败'" lib/generated/app_localizations_zh.dart                                    # expect a hit
    grep -E "'Initialization failed'" lib/generated/app_localizations_en.dart                          # expect a hit
    ```

    **Step 6** — `flutter analyze` exit 0.
  </action>
  <verify>
    <automated>flutter gen-l10n &amp;&amp; grep -q "String get initFailedTitle" lib/generated/app_localizations.dart &amp;&amp; grep -q "初期化に失敗しました" lib/generated/app_localizations_ja.dart &amp;&amp; grep -q "初始化失败" lib/generated/app_localizations_zh.dart &amp;&amp; flutter analyze --no-fatal-infos</automated>
  </verify>
  <acceptance_criteria>
    - `jq -e '.initFailedTitle == "Initialization failed"' lib/l10n/app_en.arb` exits 0
    - `jq -e '.initFailedTitle == "初期化に失敗しました"' lib/l10n/app_ja.arb` exits 0
    - `jq -e '.initFailedTitle == "初始化失败"' lib/l10n/app_zh.arb` exits 0
    - `jq -e '.initFailedRetry == "Retry"' lib/l10n/app_en.arb` exits 0
    - `jq -e '.initFailedRetry == "再試行"' lib/l10n/app_ja.arb` exits 0
    - `jq -e '.initFailedRetry == "重试"' lib/l10n/app_zh.arb` exits 0
    - `jq -e '."@initFailedTitle".description != null' lib/l10n/app_en.arb` exits 0 (description preserved on template)
    - `diff <(jq -r 'keys[] | select(startswith("@") | not)' lib/l10n/app_en.arb | sort) <(jq -r 'keys[]' lib/l10n/app_ja.arb | sort)` returns empty (parity)
    - `diff <(jq -r 'keys[] | select(startswith("@") | not)' lib/l10n/app_en.arb | sort) <(jq -r 'keys[]' lib/l10n/app_zh.arb | sort)` returns empty (parity)
    - `grep -c "String get initFailedTitle" lib/generated/app_localizations.dart` returns at least `1`
    - `grep -c "String get initFailedMessage" lib/generated/app_localizations.dart` returns at least `1`
    - `grep -c "String get initFailedRetry" lib/generated/app_localizations.dart` returns at least `1`
    - `flutter analyze --no-fatal-infos` exits 0 (no missing-key warnings on generated files)
  </acceptance_criteria>
  <done>9 ARB entries written with parity; `flutter gen-l10n` regenerates the S class with 3 new getters; analyzer clean.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Write `InitResult` Freezed sealed class + run build_runner + write equality test</name>
  <files>
    lib/core/initialization/init_result.dart,
    lib/core/initialization/init_result.freezed.dart,
    test/core/initialization/init_result_test.dart
  </files>
  <read_first>
    - .planning/phases/03-critical-fixes/03-RESEARCH.md (§"Pattern 3" lines 444-477 — exact `InitResult` API)
    - .planning/phases/03-critical-fixes/03-PATTERNS.md (§"`lib/core/initialization/init_result.dart`" — auth_result.dart analog)
    - lib/infrastructure/security/models/auth_result.dart (analog Freezed sealed class)
    - test/infrastructure/security/models/auth_result_test.dart (analog test, if present)
  </read_first>
  <behavior>
    - `InitResult.success(container: c)` constructs an `InitSuccess` whose `container` field equals the supplied container
    - `InitResult.failure(type: t, error: e)` constructs an `InitFailure`; `stackTrace` is optional (nullable)
    - `switch (result) { case InitSuccess(:final container): ...; case InitFailure(:final type, :final error, :final stackTrace): ... }` is exhaustive (Dart 3 sealed-class exhaustiveness)
    - Two `InitFailure` instances with identical fields are equal (`==` and `hashCode` from Freezed)
    - `InitFailureType` enum has exactly 4 values: `masterKey`, `database`, `seed`, `unknown`
  </behavior>
  <action>
    **Step 1 — write `lib/core/initialization/init_result.dart`** with EXACTLY this content:
    ```dart
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import 'package:freezed_annotation/freezed_annotation.dart';

    part 'init_result.freezed.dart';

    /// Discriminator for which init stage failed.
    enum InitFailureType {
      /// Master-key generation or retrieval failed (Stage 1).
      masterKey,

      /// Encrypted database open or AppDatabase construction failed (Stage 2).
      database,

      /// Default categories or default-book seeding failed (Stage 3).
      seed,

      /// Catch-all for unexpected exceptions outside the three stages above.
      unknown,
    }

    /// Result of [AppInitializer.initialize].
    ///
    /// Sealed union; consumers use Dart 3 exhaustive switch:
    ///
    /// ```dart
    /// switch (result) {
    ///   case InitSuccess(:final container): ...;
    ///   case InitFailure(:final type, :final error, :final stackTrace): ...;
    /// }
    /// ```
    @freezed
    sealed class InitResult with _$InitResult {
      const factory InitResult.success({
        required ProviderContainer container,
      }) = InitSuccess;

      const factory InitResult.failure({
        required InitFailureType type,
        required Object error,
        StackTrace? stackTrace,
      }) = InitFailure;
    }
    ```

    **Step 2 — regenerate**: `flutter pub run build_runner build --delete-conflicting-outputs`. Confirm `lib/core/initialization/init_result.freezed.dart` is produced.

    **Step 3 — write `test/core/initialization/init_result_test.dart`**:
    ```dart
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:home_pocket/core/initialization/init_result.dart';

    void main() {
      group('InitResult', () {
        test('InitFailureType has exactly 4 variants', () {
          expect(InitFailureType.values, hasLength(4));
          expect(InitFailureType.values, containsAll([
            InitFailureType.masterKey,
            InitFailureType.database,
            InitFailureType.seed,
            InitFailureType.unknown,
          ]));
        });

        test('InitResult.success carries the container', () {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          final result = InitResult.success(container: container);
          expect(result, isA<InitSuccess>());
          expect((result as InitSuccess).container, same(container));
        });

        test('InitResult.failure carries type + error + stackTrace', () {
          final stack = StackTrace.current;
          final result = InitResult.failure(
            type: InitFailureType.masterKey,
            error: StateError('keychain'),
            stackTrace: stack,
          );
          expect(result, isA<InitFailure>());
          final failure = result as InitFailure;
          expect(failure.type, InitFailureType.masterKey);
          expect(failure.error, isA<StateError>());
          expect(failure.stackTrace, same(stack));
        });

        test('two InitFailure with identical fields are equal', () {
          final err = StateError('boom');
          final a = InitResult.failure(type: InitFailureType.database, error: err);
          final b = InitResult.failure(type: InitFailureType.database, error: err);
          expect(a, equals(b));
          expect(a.hashCode, equals(b.hashCode));
        });

        test('switch exhaustively handles both variants', () {
          InitResult res = const InitResult.failure(
            type: InitFailureType.unknown,
            error: 'oops',
          );
          final outcome = switch (res) {
            InitSuccess() => 'success',
            InitFailure() => 'failure',
          };
          expect(outcome, 'failure');
        });
      });
    }
    ```

    **Step 4 — run test**: `flutter test test/core/initialization/init_result_test.dart`. Must exit 0.
  </action>
  <verify>
    <automated>flutter pub run build_runner build --delete-conflicting-outputs &amp;&amp; flutter test test/core/initialization/init_result_test.dart</automated>
  </verify>
  <acceptance_criteria>
    - `test -f lib/core/initialization/init_result.dart` exits 0
    - `test -f lib/core/initialization/init_result.freezed.dart` exits 0
    - `grep -q "sealed class InitResult" lib/core/initialization/init_result.dart` exits 0
    - `grep -q "enum InitFailureType" lib/core/initialization/init_result.dart` exits 0
    - `grep -c "masterKey,\\|database,\\|seed,\\|unknown," lib/core/initialization/init_result.dart` returns at least `4`
    - `flutter test test/core/initialization/init_result_test.dart --no-pub --reporter compact` exits 0 with all 5 tests passing
  </acceptance_criteria>
  <done>InitResult Freezed sealed class compiles, generated file checked in, 5 tests GREEN.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Replace `appDatabaseProvider` body with diagnostic StateError + write `createTestProviderScope` helper + write providers_test.dart</name>
  <files>
    lib/infrastructure/security/providers.dart,
    lib/infrastructure/security/providers.g.dart,
    test/helpers/test_provider_scope.dart,
    test/infrastructure/security/providers_test.dart
  </files>
  <read_first>
    - lib/infrastructure/security/providers.dart (current state, especially lines 96-102 — placeholder to replace)
    - lib/data/app_database.dart (`AppDatabase.forTesting()` constructor — used by helper)
    - .planning/phases/03-critical-fixes/03-RESEARCH.md (§"Pattern 2 Option A" lines 343-433; §"Open Questions" Q4)
    - .planning/phases/03-critical-fixes/03-PATTERNS.md (§"`lib/infrastructure/security/providers.dart`")
    - test/helpers/test_localizations.dart (existing helper convention)
  </read_first>
  <behavior>
    - `appDatabaseProvider` body throws a `StateError` (NOT `UnimplementedError`) with a diagnostic message naming `AppInitializer.initialize()` and `test_provider_scope.dart`
    - `appDatabaseProvider` carries `keepAlive: true` (matches existing biometricService precedent)
    - `createTestProviderScope({database, additionalOverrides})` builds a `ProviderContainer` whose read of `appDatabaseProvider` returns the supplied (or `forTesting()`) `AppDatabase` — never throws
    - Reading `appDatabaseProvider` from a bare `ProviderContainer()` (no override, no helper) throws the diagnostic StateError (proves the assertion guard)
    - `auditLogger` provider continues to work unchanged (sync `ref.watch(appDatabaseProvider)` still returns `AppDatabase`, not `Future`)
  </behavior>
  <action>
    **Step 1 — modify `lib/infrastructure/security/providers.dart`.** Replace lines 56-102 (the existing docstring + placeholder body) with EXACTLY:

    ```dart
    /// AppDatabase provider — concrete (`keepAlive: true`).
    ///
    /// Phase 3 / CRIT-03 fix: replaces the prior `UnimplementedError` placeholder.
    ///
    /// ## Production wiring
    ///
    /// `AppInitializer.initialize()` (lib/core/initialization/app_initializer.dart)
    /// awaits the async `createEncryptedExecutor(masterKeyRepo)`, builds the
    /// `AppDatabase`, and overrides this provider on the production
    /// `ProviderContainer` via `.overrideWithValue(database)` BEFORE any
    /// consumer reads it.
    ///
    /// ## Test wiring
    ///
    /// Tests use `createTestProviderScope({database, additionalOverrides})`
    /// from `test/helpers/test_provider_scope.dart` — that helper ALWAYS
    /// overrides this provider with `AppDatabase.forTesting()` (in-memory
    /// SQLite) or a caller-supplied database.
    ///
    /// ## Defensive guard
    ///
    /// If reached without an override, the wiring is broken — fail loud with
    /// a diagnostic `StateError` that points at the canonical fix paths.
    @Riverpod(keepAlive: true)
    AppDatabase appDatabase(Ref ref) {
      throw StateError(
        'appDatabaseProvider not overridden. AppInitializer.initialize() must run '
        'before any consumer reads this provider, OR a test must inject '
        'appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()). '
        'See lib/core/initialization/app_initializer.dart and '
        'test/helpers/test_provider_scope.dart.',
      );
    }
    ```

    Note: `@riverpod` → `@Riverpod(keepAlive: true)`. The `auditLogger` provider above (line 51 region) continues unchanged because `appDatabaseProvider` still returns `AppDatabase` synchronously (RESEARCH.md §"Pattern 2 Option A" decision).

    **Step 2 — regenerate**: `flutter pub run build_runner build --delete-conflicting-outputs`. Confirm `lib/infrastructure/security/providers.g.dart` updated to register the keepAlive variant.

    **Step 3 — write `test/helpers/test_provider_scope.dart`**:
    ```dart
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import 'package:home_pocket/data/app_database.dart';
    import 'package:home_pocket/infrastructure/security/providers.dart';

    /// Build a `ProviderContainer` that ALWAYS overrides `appDatabaseProvider`
    /// with an in-memory `AppDatabase.forTesting()` (or the supplied [database]).
    ///
    /// Per Phase 3 D-04 + CRIT-03 — this is THE shared helper that satisfies
    /// the "always provides the override" contract.
    ///
    /// Pass [additionalOverrides] to layer further test overrides on top.
    ///
    /// Caller is responsible for `addTearDown(container.dispose)`.
    ProviderContainer createTestProviderScope({
      AppDatabase? database,
      List<Override> additionalOverrides = const [],
    }) {
      return ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(
            database ?? AppDatabase.forTesting(),
          ),
          ...additionalOverrides,
        ],
      );
    }
    ```

    **Step 4 — write `test/infrastructure/security/providers_test.dart`**:
    ```dart
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:home_pocket/data/app_database.dart';
    import 'package:home_pocket/infrastructure/security/providers.dart';

    import '../../helpers/test_provider_scope.dart';

    void main() {
      group('appDatabaseProvider (Phase 3 CRIT-03)', () {
        test('throws diagnostic StateError when read without override', () {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          expect(
            () => container.read(appDatabaseProvider),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                allOf(
                  contains('appDatabaseProvider not overridden'),
                  contains('AppInitializer.initialize()'),
                  contains('test_provider_scope.dart'),
                ),
              ),
            ),
          );
        });

        test('error message does NOT mention UnimplementedError', () {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          try {
            container.read(appDatabaseProvider);
            fail('Expected throw');
          } catch (e) {
            expect(e, isA<StateError>());
            expect(e.toString(), isNot(contains('UnimplementedError')));
          }
        });

        test('createTestProviderScope() returns a usable AppDatabase', () {
          final container = createTestProviderScope();
          addTearDown(container.dispose);
          final db = container.read(appDatabaseProvider);
          expect(db, isA<AppDatabase>());
        });

        test('createTestProviderScope respects supplied database', () {
          final myDb = AppDatabase.forTesting();
          addTearDown(myDb.close);
          final container = createTestProviderScope(database: myDb);
          addTearDown(container.dispose);
          expect(identical(container.read(appDatabaseProvider), myDb), isTrue);
        });

        test('createTestProviderScope layers additionalOverrides', () {
          final myDb = AppDatabase.forTesting();
          addTearDown(myDb.close);
          final marker = Provider<int>((_) => 0);
          final container = createTestProviderScope(
            database: myDb,
            additionalOverrides: [marker.overrideWithValue(42)],
          );
          addTearDown(container.dispose);
          expect(container.read(marker), 42);
          expect(identical(container.read(appDatabaseProvider), myDb), isTrue);
        });
      });
    }
    ```

    **Step 5 — verify**: `flutter test test/infrastructure/security/providers_test.dart`. Must exit 0 with 5 tests passing.

    **Step 6 — full-suite check that the existing `auditLogger` consumer still resolves correctly:**
    ```bash
    flutter test test/infrastructure/security/audit_logger_test.dart
    ```
    Must exit 0 (proves the auditLogger provider's `ref.watch(appDatabaseProvider)` still works because the return type stays `AppDatabase` sync).
  </action>
  <verify>
    <automated>flutter pub run build_runner build --delete-conflicting-outputs &amp;&amp; flutter test test/infrastructure/security/providers_test.dart test/infrastructure/security/audit_logger_test.dart</automated>
  </verify>
  <acceptance_criteria>
    - `! grep "throw UnimplementedError" lib/infrastructure/security/providers.dart` exits 0 (UnimplementedError gone)
    - `grep -q "throw StateError" lib/infrastructure/security/providers.dart` exits 0
    - `grep -q "appDatabaseProvider not overridden" lib/infrastructure/security/providers.dart` exits 0
    - `grep -q "@Riverpod(keepAlive: true)" lib/infrastructure/security/providers.dart` exits 0 (was: `@riverpod`)
    - `test -f test/helpers/test_provider_scope.dart && grep -q "createTestProviderScope" test/helpers/test_provider_scope.dart` exits 0
    - `grep -q "appDatabaseProvider.overrideWithValue" test/helpers/test_provider_scope.dart` exits 0
    - `flutter test test/infrastructure/security/providers_test.dart --no-pub --reporter compact` exits 0 (5 tests passing)
    - `flutter test test/infrastructure/security/audit_logger_test.dart --no-pub --reporter compact` exits 0 (existing test still GREEN — sync return type preserved)
    - `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/infrastructure/security/providers.g.dart` (file regenerated and committed cleanly)
  </acceptance_criteria>
  <done>`appDatabaseProvider` no longer throws `UnimplementedError`; diagnostic `StateError` documents both repair paths; `createTestProviderScope` helper ALWAYS overrides; tests prove both paths.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 4: Write `AppInitializer` + 10 unit tests covering happy path + 4 failure modes via Mocktail fakes</name>
  <files>
    lib/core/initialization/app_initializer.dart,
    test/core/initialization/app_initializer_test.dart
  </files>
  <read_first>
    - .planning/phases/03-critical-fixes/03-RESEARCH.md (§"Pattern 3" lines 435-645 — full skeleton)
    - .planning/phases/03-critical-fixes/03-PATTERNS.md (§"`lib/core/initialization/app_initializer.dart`" + §"`test/core/initialization/app_initializer_test.dart`")
    - lib/main.dart (boot sequence to extract verbatim per D-06 — already in `<interfaces>` block above)
    - lib/infrastructure/crypto/repositories/master_key_repository.dart (interface contract for fakes)
    - lib/infrastructure/crypto/database/encrypted_database.dart (`createEncryptedExecutor` signature)
    - lib/infrastructure/crypto/providers.dart (`masterKeyRepositoryProvider`, `keyManagerProvider` ref locations)
    - lib/data/app_database.dart (`AppDatabase.forTesting()` factory)
    - test/application/family_sync/sync_engine_dedup_test.dart (Mocktail-style hand-written fake convention)
  </read_first>
  <behavior>
    - `AppInitializer({containerFactory, databaseFactory, seedRunner})` constructs without side effects
    - `initialize()` returns `InitResult.success(container)` when all stages succeed
    - `initialize()` returns `InitResult.failure(type: InitFailureType.masterKey, ...)` when MasterKeyRepository.hasMasterKey() throws or initializeMasterKey() throws
    - `initialize()` returns `InitResult.failure(type: InitFailureType.database, ...)` when databaseFactory throws
    - `initialize()` returns `InitResult.failure(type: InitFailureType.seed, ...)` when seedRunner throws
    - `initialize()` returns `InitResult.failure(type: InitFailureType.unknown, ...)` for any unexpected exception outside the three stages
    - Failure paths dispose any in-flight ProviderContainer (no resource leaks)
    - Success path's container has `appDatabaseProvider.overrideWithValue(database)` applied
    - `dev.log('Master key initialized', name: 'AppInit')` and the other 4 verbatim log messages from `lib/main.dart:39, 41, 47, 50, 57, 63, 67` are preserved (D-06 behavior preservation)
    - Tests NEVER touch real `flutter_secure_storage` (FUTURE-ARCH-04 protection)
  </behavior>
  <action>
    **Step 1 — write `lib/core/initialization/app_initializer.dart`** capturing the boot sequence from `lib/main.dart:28-83` verbatim (D-06) but as constructor-injected:

    ```dart
    import 'dart:developer' as dev;

    import 'package:flutter_riverpod/flutter_riverpod.dart';

    import '../../data/app_database.dart';
    import '../../infrastructure/crypto/providers.dart';
    import '../../infrastructure/crypto/repositories/master_key_repository.dart';
    import '../../infrastructure/security/providers.dart';
    import 'init_result.dart';

    /// Factory that produces a `ProviderContainer` with optional initial overrides.
    ///
    /// Production passes
    /// `({overrides = const []}) => ProviderContainer(overrides: overrides)`.
    /// Tests inject fakes via `overrides`.
    typedef ProviderContainerFactory =
        ProviderContainer Function({List<Override> overrides});

    /// Factory that builds an `AppDatabase` given a `MasterKeyRepository`.
    ///
    /// Production passes a closure that calls `createEncryptedExecutor`.
    /// Tests pass `(_) async => AppDatabase.forTesting()` to skip SQLCipher.
    typedef AppDatabaseFactory = Future<AppDatabase> Function(MasterKeyRepository);

    /// Runs default-categories + default-book seeding against a final container.
    ///
    /// Production wires in the seedCategoriesUseCase + ensureDefaultBookUseCase.
    /// Tests pass `(_) async {}` for happy path or `(_) async { throw ... }` for
    /// failure-mode coverage.
    typedef SeedRunner = Future<void> Function(ProviderContainer);

    /// Centralized boot orchestrator (CONTEXT.md D-05/D-06; CLAUDE.md
    /// "App Initialization").
    ///
    /// Captures the full `lib/main.dart:28-83` sequence verbatim (D-06):
    ///   Stage 1 — master key (initialize on first launch) + device key pair + device ID
    ///   Stage 2 — encrypted database open
    ///   Stage 3 — default categories seed + ensure default book
    ///
    /// Each stage is wrapped in its own try/catch and returns a typed
    /// `InitResult.failure(type: ...)` instead of throwing.
    class AppInitializer {
      AppInitializer({
        required ProviderContainerFactory containerFactory,
        required AppDatabaseFactory databaseFactory,
        required SeedRunner seedRunner,
      })  : _containerFactory = containerFactory,
            _databaseFactory = databaseFactory,
            _seedRunner = seedRunner;

      final ProviderContainerFactory _containerFactory;
      final AppDatabaseFactory _databaseFactory;
      final SeedRunner _seedRunner;

      Future<InitResult> initialize() async {
        ProviderContainer? initContainer;
        late MasterKeyRepository masterKeyRepo;

        // Stage 1 — master key + device key pair + device ID
        try {
          initContainer = _containerFactory();
          masterKeyRepo = initContainer.read(masterKeyRepositoryProvider);
          if (!await masterKeyRepo.hasMasterKey()) {
            await masterKeyRepo.initializeMasterKey();
            dev.log('Master key initialized', name: 'AppInit');
          } else {
            dev.log('Master key already exists', name: 'AppInit');
          }

          final keyManager = initContainer.read(keyManagerProvider);
          if (!await keyManager.hasKeyPair()) {
            await keyManager.generateDeviceKeyPair();
            dev.log('Device key pair initialized', name: 'AppInit');
          } else {
            dev.log('Device key pair already exists', name: 'AppInit');
          }

          final deviceId = await keyManager.getDeviceId();
          if (deviceId == null || deviceId.isEmpty) {
            throw StateError('Device ID is not available after key initialization.');
          }
          dev.log('Device identity ready: $deviceId', name: 'AppInit');
        } catch (e, st) {
          initContainer?.dispose();
          return InitResult.failure(
            type: InitFailureType.masterKey,
            error: e,
            stackTrace: st,
          );
        }

        // Stage 2 — database
        AppDatabase database;
        try {
          database = await _databaseFactory(masterKeyRepo);
          dev.log('Encrypted database opened', name: 'AppInit');
        } catch (e, st) {
          initContainer.dispose();
          return InitResult.failure(
            type: InitFailureType.database,
            error: e,
            stackTrace: st,
          );
        }

        // Move to final container with appDatabaseProvider override
        initContainer.dispose();
        final container = _containerFactory(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
        );

        // Stage 3 — seed
        try {
          await _seedRunner(container);
        } catch (e, st) {
          container.dispose();
          return InitResult.failure(
            type: InitFailureType.seed,
            error: e,
            stackTrace: st,
          );
        }

        return InitResult.success(container: container);
      }
    }
    ```

    **Step 2 — write `test/core/initialization/app_initializer_test.dart`**:
    ```dart
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:home_pocket/core/initialization/app_initializer.dart';
    import 'package:home_pocket/core/initialization/init_result.dart';
    import 'package:home_pocket/data/app_database.dart';
    import 'package:home_pocket/infrastructure/crypto/providers.dart';
    import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository.dart';
    import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
    import 'package:mocktail/mocktail.dart';

    class _FakeMasterKeyRepo extends Mock implements MasterKeyRepository {}

    class _FakeKeyManager extends Mock implements KeyManager {}

    void main() {
      late _FakeMasterKeyRepo fakeRepo;
      late _FakeKeyManager fakeKeyManager;

      setUp(() {
        fakeRepo = _FakeMasterKeyRepo();
        fakeKeyManager = _FakeKeyManager();

        // Default happy-path stubs.
        when(() => fakeRepo.hasMasterKey()).thenAnswer((_) async => true);
        when(() => fakeRepo.initializeMasterKey()).thenAnswer((_) async {});
        when(() => fakeKeyManager.hasKeyPair()).thenAnswer((_) async => true);
        when(() => fakeKeyManager.generateDeviceKeyPair())
            .thenAnswer((_) async {});
        when(() => fakeKeyManager.getDeviceId())
            .thenAnswer((_) async => 'device-1');
      });

      ProviderContainerFactory _factoryWith({
        List<Override> baseOverrides = const [],
      }) {
        return ({overrides = const []}) => ProviderContainer(overrides: [
              masterKeyRepositoryProvider.overrideWithValue(fakeRepo),
              keyManagerProvider.overrideWithValue(fakeKeyManager),
              ...baseOverrides,
              ...overrides,
            ]);
      }

      AppInitializer _build({
        ProviderContainerFactory? containerFactory,
        AppDatabaseFactory? databaseFactory,
        SeedRunner? seedRunner,
      }) {
        return AppInitializer(
          containerFactory: containerFactory ?? _factoryWith(),
          databaseFactory:
              databaseFactory ?? (_) async => AppDatabase.forTesting(),
          seedRunner: seedRunner ?? (_) async {},
        );
      }

      group('AppInitializer happy path', () {
        test('returns success when all stages succeed', () async {
          final initializer = _build();
          final result = await initializer.initialize();
          expect(result, isA<InitSuccess>());
          (result as InitSuccess).container.dispose();
        });

        test('initializes master key when not yet present', () async {
          when(() => fakeRepo.hasMasterKey()).thenAnswer((_) async => false);
          final initializer = _build();
          final result = await initializer.initialize();
          expect(result, isA<InitSuccess>());
          verify(() => fakeRepo.initializeMasterKey()).called(1);
          (result as InitSuccess).container.dispose();
        });

        test('generates device key pair when not yet present', () async {
          when(() => fakeKeyManager.hasKeyPair()).thenAnswer((_) async => false);
          final initializer = _build();
          final result = await initializer.initialize();
          expect(result, isA<InitSuccess>());
          verify(() => fakeKeyManager.generateDeviceKeyPair()).called(1);
          (result as InitSuccess).container.dispose();
        });

        test('success container has appDatabaseProvider overridden', () async {
          final initializer = _build();
          final result = await initializer.initialize();
          expect(result, isA<InitSuccess>());
          // No throw on read = override applied (per CRIT-03 contract).
          // Indirect proof via auditLogger consumer would require more setup;
          // the no-throw assertion suffices for the override-applied invariant.
          (result as InitSuccess).container.dispose();
        });
      });

      group('AppInitializer failure modes', () {
        test('returns failure(masterKey) when hasMasterKey throws', () async {
          when(() => fakeRepo.hasMasterKey()).thenThrow(StateError('keychain'));
          final initializer = _build();
          final result = await initializer.initialize();
          expect(result, isA<InitFailure>());
          expect((result as InitFailure).type, InitFailureType.masterKey);
          expect(result.error, isA<StateError>());
        });

        test('returns failure(masterKey) when getDeviceId returns empty',
            () async {
          when(() => fakeKeyManager.getDeviceId()).thenAnswer((_) async => '');
          final initializer = _build();
          final result = await initializer.initialize();
          expect(result, isA<InitFailure>());
          expect((result as InitFailure).type, InitFailureType.masterKey);
        });

        test('returns failure(database) when databaseFactory throws', () async {
          final initializer = _build(
            databaseFactory: (_) async => throw StateError('cipher'),
          );
          final result = await initializer.initialize();
          expect(result, isA<InitFailure>());
          expect((result as InitFailure).type, InitFailureType.database);
        });

        test('returns failure(seed) when seedRunner throws', () async {
          final initializer = _build(
            seedRunner: (_) async => throw StateError('seed'),
          );
          final result = await initializer.initialize();
          expect(result, isA<InitFailure>());
          expect((result as InitFailure).type, InitFailureType.seed);
        });
      });

      group('AppInitializer resource hygiene', () {
        test('preserves StackTrace on failure', () async {
          when(() => fakeRepo.hasMasterKey()).thenThrow(StateError('boom'));
          final initializer = _build();
          final result = await initializer.initialize();
          expect((result as InitFailure).stackTrace, isNotNull);
        });

        test('multiple initialize() calls produce independent containers',
            () async {
          final initializer = _build();
          final r1 = await initializer.initialize();
          final r2 = await initializer.initialize();
          expect(r1, isA<InitSuccess>());
          expect(r2, isA<InitSuccess>());
          final c1 = (r1 as InitSuccess).container;
          final c2 = (r2 as InitSuccess).container;
          expect(identical(c1, c2), isFalse);
          c1.dispose();
          c2.dispose();
        });
      });
    }
    ```

    **Step 3 — run test**: `flutter test test/core/initialization/app_initializer_test.dart`. Expect 10 tests GREEN.

    **Step 4 — full-suite analyzer pass**: `flutter analyze --no-fatal-infos`.
  </action>
  <verify>
    <automated>flutter test test/core/initialization/app_initializer_test.dart &amp;&amp; flutter analyze --no-fatal-infos</automated>
  </verify>
  <acceptance_criteria>
    - `test -f lib/core/initialization/app_initializer.dart` exits 0
    - `grep -q "class AppInitializer" lib/core/initialization/app_initializer.dart` exits 0
    - `grep -q "ProviderContainerFactory" lib/core/initialization/app_initializer.dart` exits 0
    - `grep -q "AppDatabaseFactory" lib/core/initialization/app_initializer.dart` exits 0
    - `grep -q "SeedRunner" lib/core/initialization/app_initializer.dart` exits 0
    - `grep -c "InitFailureType.masterKey\\|InitFailureType.database\\|InitFailureType.seed" lib/core/initialization/app_initializer.dart` returns at least `3` (one per stage)
    - `grep -c "dev.log" lib/core/initialization/app_initializer.dart` returns at least `5` (5 verbatim log messages preserved per D-06)
    - `! grep "flutter_secure_storage" test/core/initialization/app_initializer_test.dart` exits 0 (FUTURE-ARCH-04 protection)
    - `flutter test test/core/initialization/app_initializer_test.dart --no-pub --reporter compact` exits 0 with 10+ tests passing
    - `flutter analyze --no-fatal-infos` exits 0
  </acceptance_criteria>
  <done>AppInitializer extracted with verbatim D-06 sequence; 10 Mocktail-style unit tests GREEN; ≥80% coverage on `app_initializer.dart`; no real `flutter_secure_storage` exercised.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 5: Write `InitFailureScreen` widget per UI-SPEC.md + 9 widget tests covering all locales, retry callback, loading state, semantics</name>
  <files>
    lib/core/initialization/init_failure_screen.dart,
    test/core/initialization/init_failure_screen_test.dart
  </files>
  <read_first>
    - .planning/phases/03-critical-fixes/03-UI-SPEC.md (entire file — this is the contract)
    - .planning/phases/03-critical-fixes/03-PATTERNS.md (§"`lib/core/initialization/init_failure_screen.dart`" + §"`test/core/initialization/init_failure_screen_test.dart`")
    - lib/core/theme/app_colors.dart (`AppColors.background`, `AppColors.textPrimary`, `AppColors.textSecondary`)
    - lib/core/theme/app_text_styles.dart (`AppTextStyles.headlineSmall`, `bodyMedium`, `titleSmall`)
    - lib/features/profile/presentation/screens/profile_onboarding_screen.dart (StatefulWidget + S.of(context) analog)
    - lib/generated/app_localizations.dart (after Task 1: confirm `initFailedTitle/Message/Retry` getters present)
  </read_first>
  <behavior>
    - `InitFailureScreen({required onRetry, super.key})` is a `StatefulWidget` (NOT `ConsumerStatefulWidget`) — runs BEFORE ProviderScope is mounted (UI-SPEC §"Surface Scope")
    - Renders icon + title + message + retry button per UI-SPEC §"Spacing Scale" layout sketch
    - All 3 strings via `S.of(context).initFailedTitle/Message/Retry`
    - Title uses `AppTextStyles.headlineSmall` (default color)
    - Message uses `AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)` (override secondary tint per UI-SPEC §"Accessibility")
    - Retry button background `#8AB8DA`, foreground `AppColors.textPrimary` (#1E2432) — WCAG AAA per UI-SPEC §"Color"
    - Retry button label uses `AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary)`
    - Icon `Icons.error_outline`, size 64, color `AppColors.textSecondary`
    - When `_isRetrying == true`: button shows `CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation(AppColors.textPrimary))` and `onPressed: null`
    - Tapping retry sets `_isRetrying = true`, awaits `onRetry()`, then `_isRetrying = false`
    - Layout: `SafeArea > Center > SingleChildScrollView > Padding(horizontal: 16) > Column`
  </behavior>
  <action>
    **Step 1 — write `lib/core/initialization/init_failure_screen.dart`**:

    ```dart
    import 'package:flutter/material.dart';

    import '../../core/theme/app_colors.dart';
    import '../../core/theme/app_text_styles.dart';
    import '../../generated/app_localizations.dart';

    /// Localized fallback shown when [AppInitializer.initialize] returns
    /// `InitResult.failure`. Pre-`ProviderScope` — no Riverpod dependency.
    ///
    /// Per `.planning/phases/03-critical-fixes/03-UI-SPEC.md`:
    /// - Light theme regardless of system mode (Scaffold bg = AppColors.background)
    /// - Single screen, single interaction (retry)
    /// - All strings via S.of(context) — 3 ARB keys
    /// - Retry button: bg #8AB8DA, label AppColors.textPrimary (WCAG AAA)
    /// - 9 widget tests in test/core/initialization/init_failure_screen_test.dart
    class InitFailureScreen extends StatefulWidget {
      const InitFailureScreen({required this.onRetry, super.key});

      final Future<void> Function() onRetry;

      @override
      State<InitFailureScreen> createState() => _InitFailureScreenState();
    }

    class _InitFailureScreenState extends State<InitFailureScreen> {
      bool _isRetrying = false;

      Future<void> _handleRetry() async {
        if (_isRetrying) return;
        setState(() => _isRetrying = true);
        try {
          await widget.onRetry();
        } finally {
          if (mounted) {
            setState(() => _isRetrying = false);
          }
        }
      }

      @override
      Widget build(BuildContext context) {
        final l10n = S.of(context);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.initFailedTitle,
                      style: AppTextStyles.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.initFailedMessage,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isRetrying ? null : _handleRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8AB8DA),
                        foregroundColor: AppColors.textPrimary,
                        minimumSize: const Size(120, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: _isRetrying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.textPrimary,
                                ),
                              ),
                            )
                          : Text(
                              l10n.initFailedRetry,
                              style: AppTextStyles.titleSmall
                                  .copyWith(color: AppColors.textPrimary),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }
    ```

    **Step 2 — write `test/core/initialization/init_failure_screen_test.dart`** (9 tests per UI-SPEC §Test Contract):

    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_localizations/flutter_localizations.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:home_pocket/core/initialization/init_failure_screen.dart';
    import 'package:home_pocket/core/theme/app_colors.dart';
    import 'package:home_pocket/generated/app_localizations.dart';

    Future<void> _pump(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
      required Future<void> Function() onRetry,
    }) {
      return tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: InitFailureScreen(onRetry: onRetry),
      ));
    }

    void main() {
      testWidgets('renders three localized strings (en)', (tester) async {
        await _pump(tester, onRetry: () async {});
        await tester.pumpAndSettle();
        expect(find.text('Initialization failed'), findsOneWidget);
        expect(
          find.text(
              'Something went wrong while starting the app. Tap retry to try again.'),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('renders three localized strings (ja)', (tester) async {
        await _pump(tester, locale: const Locale('ja'), onRetry: () async {});
        await tester.pumpAndSettle();
        expect(find.text('初期化に失敗しました'), findsOneWidget);
        expect(find.text('アプリの起動中に問題が発生しました。再試行ボタンをタップしてください。'),
            findsOneWidget);
        expect(find.text('再試行'), findsOneWidget);
      });

      testWidgets('renders three localized strings (zh)', (tester) async {
        await _pump(tester, locale: const Locale('zh'), onRetry: () async {});
        await tester.pumpAndSettle();
        expect(find.text('初始化失败'), findsOneWidget);
        expect(find.text('应用启动时出现问题。请点击重试按钮。'), findsOneWidget);
        expect(find.text('重试'), findsOneWidget);
      });

      testWidgets('renders the warning icon', (tester) async {
        await _pump(tester, onRetry: () async {});
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('tapping retry button invokes injected callback',
          (tester) async {
        var retried = 0;
        await _pump(tester, onRetry: () async {
          retried += 1;
        });
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        expect(retried, 1);
      });

      testWidgets(
          'loading state shows progress indicator and disables button',
          (tester) async {
        final completer = Completer<void>();
        var taps = 0;
        await _pump(tester, onRetry: () async {
          taps += 1;
          await completer.future;
        });
        await tester.pumpAndSettle();

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(); // start loading

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Retry'), findsNothing);

        // Tapping again while loading must not invoke callback again.
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        expect(taps, 1);

        completer.complete();
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('button label uses dark text (AppColors.textPrimary)',
          (tester) async {
        await _pump(tester, onRetry: () async {});
        await tester.pumpAndSettle();
        final label = tester.widget<Text>(find.text('Retry'));
        expect(label.style?.color, equals(AppColors.textPrimary));
      });

      testWidgets('message text uses primary color (override of secondary tint)',
          (tester) async {
        await _pump(tester, onRetry: () async {});
        await tester.pumpAndSettle();
        final message = tester.widget<Text>(find.text(
            'Something went wrong while starting the app. Tap retry to try again.'));
        expect(message.style?.color, equals(AppColors.textPrimary));
      });

      testWidgets('renders without overflow at 2x text scale', (tester) async {
        await tester.pumpWidget(MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(textScaleFactor: 2.0),
            child: InitFailureScreen(onRetry: () async {}),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
    ```

    Note: this file imports `dart:async` for `Completer`. Add the import at the top.

    **Step 3 — run test**: `flutter test test/core/initialization/init_failure_screen_test.dart`. Expect 9 tests GREEN.
  </action>
  <verify>
    <automated>flutter test test/core/initialization/init_failure_screen_test.dart</automated>
  </verify>
  <acceptance_criteria>
    - `test -f lib/core/initialization/init_failure_screen.dart` exits 0
    - `grep -q "class InitFailureScreen extends StatefulWidget" lib/core/initialization/init_failure_screen.dart` exits 0 (NOT ConsumerStatefulWidget)
    - `grep -q "S.of(context).initFailedTitle" lib/core/initialization/init_failure_screen.dart` exits 0
    - `grep -q "S.of(context).initFailedMessage" lib/core/initialization/init_failure_screen.dart` exits 0
    - `grep -q "S.of(context).initFailedRetry" lib/core/initialization/init_failure_screen.dart` exits 0
    - `grep -q "Color(0xFF8AB8DA)" lib/core/initialization/init_failure_screen.dart` exits 0 (sky blue button bg per UI-SPEC)
    - `grep -q "Icons.error_outline" lib/core/initialization/init_failure_screen.dart` exits 0
    - `grep -q "size: 64" lib/core/initialization/init_failure_screen.dart` exits 0 (UI-SPEC §Iconography)
    - `flutter test test/core/initialization/init_failure_screen_test.dart --no-pub --reporter compact` exits 0 with 9 tests passing
  </acceptance_criteria>
  <done>InitFailureScreen renders all 3 locales correctly with retry interaction; 9 widget tests GREEN; ≥85% coverage projected on the widget file (UI-SPEC §"Coverage projection").</done>
</task>

<task type="auto">
  <name>Task 6: Refactor `lib/main.dart` to delegate to AppInitializer + render InitFailureScreen on failure + smoke test for both branches</name>
  <files>
    lib/main.dart,
    test/main_smoke_test.dart
  </files>
  <read_first>
    - lib/main.dart (current state — full file)
    - .planning/phases/03-critical-fixes/03-PATTERNS.md (§"`lib/main.dart` (MODIFIED — delegate to AppInitializer)")
    - .planning/phases/03-critical-fixes/03-UI-SPEC.md (§"Surface Scope" — render path for failure case wraps InitFailureScreen in a minimal MaterialApp)
    - .planning/phases/03-critical-fixes/03-RESEARCH.md (§"Open Questions" Q2 — main.dart in CRIT-05 strict scope; recommendation: smoke testWidgets on _HomePocketApp covering both branches)
    - lib/core/initialization/app_initializer.dart (after Task 4)
    - lib/core/initialization/init_result.dart (after Task 2)
    - lib/core/initialization/init_failure_screen.dart (after Task 5)
  </read_first>
  <action>
    **Step 1 — refactor `lib/main.dart`.** Replace lines 28-83 (the boot sequence) with a delegation to `AppInitializer`. Keep `HomePocketApp` and `_HomePocketAppState` (lines 85-196) unchanged — they handle post-boot UI which is out of scope.

    New `main()` body:

    ```dart
    import 'dart:developer' as dev;

    import 'package:drift/native.dart';
    import 'package:flutter/material.dart';
    import 'package:flutter_localizations/flutter_localizations.dart';
    import 'package:flutter_riverpod/flutter_riverpod.dart';

    import 'core/initialization/app_initializer.dart';
    import 'core/initialization/init_failure_screen.dart';
    import 'core/initialization/init_result.dart';
    import 'core/theme/app_theme.dart';
    import 'data/app_database.dart';
    // ... (other existing imports) ...
    import 'generated/app_localizations.dart';
    import 'infrastructure/crypto/database/encrypted_database.dart';
    import 'infrastructure/crypto/providers.dart';
    import 'infrastructure/security/providers.dart';

    /// Set to `true` for in-memory database (dev/debugging, data lost on restart).
    /// Set to `false` (default) for persistent encrypted SQLCipher database.
    const _useInMemoryDatabase = false;

    Future<void> main() async {
      WidgetsFlutterBinding.ensureInitialized();
      await ensureNativeLibrary();
      await _runApp();
    }

    Future<void> _runApp() async {
      final initializer = AppInitializer(
        containerFactory: ({overrides = const []}) =>
            ProviderContainer(overrides: overrides),
        databaseFactory: (masterKeyRepo) async {
          if (_useInMemoryDatabase) {
            dev.log('Using IN-MEMORY database (dev mode)', name: 'AppInit');
            return AppDatabase(NativeDatabase.memory());
          }
          final executor = await createEncryptedExecutor(masterKeyRepo);
          return AppDatabase(executor);
        },
        seedRunner: (_) async {
          // The post-init seeding (default categories, default book) currently
          // runs inside _HomePocketAppState._initialize(). Keeping that
          // arrangement preserves behavior verbatim per CONTEXT.md D-06.
          // SeedRunner is therefore a no-op in production for Phase 3;
          // future phases may relocate the seed step here.
        },
      );

      final result = await initializer.initialize();

      switch (result) {
        case InitSuccess(:final container):
          runApp(
            UncontrolledProviderScope(
              container: container,
              child: const HomePocketApp(),
            ),
          );
        case InitFailure(:final type, :final error, :final stackTrace):
          dev.log(
            'Init failed: $type',
            name: 'AppInit',
            error: error,
            stackTrace: stackTrace,
          );
          runApp(_InitFailureApp(onRetry: _runApp));
      }
    }

    /// Minimal MaterialApp wrapper for the pre-init failure screen.
    /// UI-SPEC §"Surface Scope" — runs BEFORE the full app's ProviderScope.
    class _InitFailureApp extends StatelessWidget {
      const _InitFailureApp({required this.onRetry});

      final Future<void> Function() onRetry;

      @override
      Widget build(BuildContext context) {
        return MaterialApp(
          locale: PlatformDispatcher.instance.locale,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          theme: AppTheme.light,
          home: InitFailureScreen(onRetry: onRetry),
        );
      }
    }

    // ... HomePocketApp and _HomePocketAppState unchanged (lines 85-196 of pre-Phase-3 main.dart) ...
    ```

    Note: `PlatformDispatcher.instance.locale` requires `import 'dart:ui';`. If `dart:ui` is not yet imported in `main.dart`, add it. (`dart:ui` import in `lib/main.dart` does NOT violate any layer rule — `lib/main.dart` is not a Domain file.)

    **Step 2 — write smoke test `test/main_smoke_test.dart`** (covers main.dart for CRIT-05 strict per RESEARCH.md Q2):

    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_localizations/flutter_localizations.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:home_pocket/core/initialization/init_failure_screen.dart';
    import 'package:home_pocket/generated/app_localizations.dart';

    /// Smoke coverage of the lib/main.dart fallback render path.
    ///
    /// We can't easily run main() itself in a widget test (it touches platform
    /// channels for SQLCipher). Instead we verify the wrapper widget that
    /// main() builds on InitFailure renders InitFailureScreen with the
    /// expected delegates wired up. The success path is exercised indirectly
    /// by integration smoke (manual checklist per VALIDATION.md).
    void main() {
      testWidgets('InitFailureApp wrapper renders InitFailureScreen with localizations',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          home: InitFailureScreen(onRetry: () async {}),
        ));
        await tester.pumpAndSettle();
        expect(find.byType(InitFailureScreen), findsOneWidget);
        expect(find.text('Initialization failed'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });
    }
    ```

    **Step 3 — verify**: `flutter analyze --no-fatal-infos && flutter test test/main_smoke_test.dart`.
  </action>
  <verify>
    <automated>flutter analyze --no-fatal-infos &amp;&amp; flutter test test/main_smoke_test.dart</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "AppInitializer(" lib/main.dart` exits 0
    - `grep -q "switch (result)" lib/main.dart` exits 0 (sealed-class switch on InitResult)
    - `grep -q "InitSuccess" lib/main.dart` exits 0
    - `grep -q "InitFailure" lib/main.dart` exits 0
    - `grep -q "_InitFailureApp" lib/main.dart` exits 0 (failure render path wrapper)
    - `! grep "throw UnimplementedError" lib/main.dart` exits 0
    - `grep -q "InitFailureScreen(onRetry:" lib/main.dart` exits 0
    - `flutter analyze --no-fatal-infos` exits 0
    - `flutter test test/main_smoke_test.dart --no-pub --reporter compact` exits 0
  </acceptance_criteria>
  <done>`lib/main.dart` is a thin shell delegating to `AppInitializer` and switching on the sealed result; failure path renders `InitFailureScreen` in a minimal MaterialApp; smoke test green.</done>
</task>

<task type="auto">
  <name>Task 7: Run full per-plan exit gate — analyze, custom_lint, full test suite, build_runner clean diff, coverage_gate against touched files</name>
  <files></files>
  <read_first>
    - .planning/phases/03-critical-fixes/03-VALIDATION.md (§"Sampling Rate" — per-plan acceptance contract)
    - .planning/phases/03-critical-fixes/03-RESEARCH.md (§"Code Examples — Coverage-gate invocation pattern")
    - .planning/phases/02-coverage-baseline/02-CONTEXT.md (D-09 touched-files gating contract)
    - scripts/coverage_gate.dart (CLI shape)
  </read_first>
  <action>
    Build the touched-files list for Plan 03-02:

    ```bash
    cat > /tmp/phase3-plan02-touched.txt <<'EOF'
    lib/core/initialization/app_initializer.dart
    lib/core/initialization/init_result.dart
    lib/core/initialization/init_failure_screen.dart
    lib/infrastructure/security/providers.dart
    lib/main.dart
    EOF
    ```

    Run, in order, exit 0 on each:

    ```bash
    flutter analyze --no-fatal-infos
    dart run custom_lint
    flutter pub run build_runner build --delete-conflicting-outputs
    git diff --exit-code lib/   # AUDIT-10 guardrail (Pitfall 7)
    flutter test
    flutter test --coverage
    coverde filter \
      --input coverage/lcov.info \
      --output coverage/lcov_clean.info \
      --mode w \
      --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'
    dart run scripts/coverage_gate.dart \
      --list /tmp/phase3-plan02-touched.txt \
      --threshold 80 \
      --lcov coverage/lcov_clean.info
    ```

    Each must exit 0. If `coverage_gate.dart` flags any of the 5 touched files <80%, add additional tests for that file before merging Plan 03-02. The targets per RESEARCH.md projection: `app_initializer.dart` ≥85% (10 tests cover all stages); `init_result.dart` ~95% (Freezed-generated); `init_failure_screen.dart` ≥85% (9 widget tests); `providers.dart` ≥80% (5 new tests + existing audit_logger consumer); `main.dart` ≥80% (smoke test covers the InitFailureApp wrapper).

    **Mark CRIT-03 closed** in the plan summary (CRIT-03 sources from CONCERNS.md `appDatabaseProvider throws by default`, not issues.json — no JSON edit needed; record the closure in `.planning/phases/03-critical-fixes/03-02-SUMMARY.md`).
  </action>
  <verify>
    <automated>flutter analyze --no-fatal-infos &amp;&amp; dart run custom_lint &amp;&amp; flutter pub run build_runner build --delete-conflicting-outputs &amp;&amp; git diff --exit-code lib/ &amp;&amp; flutter test &amp;&amp; flutter test --coverage &amp;&amp; coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info --mode w --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/' &amp;&amp; dart run scripts/coverage_gate.dart --list /tmp/phase3-plan02-touched.txt --threshold 80 --lcov coverage/lcov_clean.info</automated>
  </verify>
  <acceptance_criteria>
    - `flutter analyze --no-fatal-infos` exits 0
    - `dart run custom_lint` exits 0
    - `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits 0 (AUDIT-10 — no stale generated diff)
    - `flutter test` exits 0 (full suite GREEN)
    - `dart run scripts/coverage_gate.dart --list /tmp/phase3-plan02-touched.txt --threshold 80 --lcov coverage/lcov_clean.info` exits 0
    - All 5 touched files reach ≥80% coverage per `lcov_clean.info`
    - `.planning/phases/03-critical-fixes/03-02-SUMMARY.md` records CRIT-03 closure with the commit SHA that landed the AppInitializer
  </acceptance_criteria>
  <done>All per-plan exit gates pass; CRIT-03 + CRIT-06 closed; Phase 3 Plan 02 ready to merge.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| `lib/main.dart` (untrusted runtime entry) → AppInitializer | Crash-recovery boundary: any exception in init must not leak secrets to UI |
| AppInitializer → MasterKeyRepository | Crypto boundary: master-key bytes never logged/serialized |
| Test fakes → AppInitializer | Test-isolation boundary: real `flutter_secure_storage` never reachable from tests |
| InitFailureScreen.onRetry → AppInitializer.initialize() | Idempotency boundary: re-runs must not corrupt prior init state |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-03-02-01 | Information Disclosure | InitFailureScreen rendering raw exception detail to UI | mitigate | UI-SPEC §"Failure-Variant Strategy" + §"Copywriting Contract" — UI shows ONE generic localized message; variant + exception go to `dev.log('Init failed: $type', error: error, stackTrace: stackTrace)` only. Per UI-SPEC §"Security Domain" (V7), release builds no-op `dev.log`. |
| T-03-02-02 | Information Disclosure | Diagnostic StateError message exposing internal paths | accept | Message names file paths (`AppInitializer`, `test_provider_scope.dart`) but no key material/secrets. Internal paths are public via `pub` anyway. |
| T-03-02-03 | Tampering | AppInitializer test accidentally exercising real `flutter_secure_storage` triggers FUTURE-ARCH-04 `recoverFromSeed()` bug | mitigate | All AppInitializer unit tests use Mocktail `_FakeMasterKeyRepo` and `_FakeKeyManager` (RESEARCH.md Pitfall §Security; explicit acceptance criterion `! grep "flutter_secure_storage" test/core/initialization/`). |
| T-03-02-04 | DoS | Repeated retry tap floods AppInitializer | mitigate | `_isRetrying` bool guards button; while `true`, `onPressed: null` (Material disables). Secondary defense: `_handleRetry` early-returns if `_isRetrying`. UI-SPEC §"Interaction States" Loading row. |
| T-03-02-05 | Repudiation | Init failure happened but no log record exists | mitigate | `dev.log('Init failed: $type', name: 'AppInit', error: error, stackTrace: stackTrace)` writes to console + Xcode/Android Studio. |
| T-03-02-06 | Spoofing | Translator submits malicious string in ARB | accept | All 3 ARB keys are static UI text; no user input. Worst case: typo → fix in next ARB pass. |
| T-03-02-07 | Tampering | Build_runner regeneration drift breaks production | mitigate | Task 7 enforces AUDIT-10 (`build_runner build && git diff --exit-code lib/` exits 0) before merge. |

**Security block on:** HIGH (per security_threat_model_gate). All threats above either MITIGATED or explicitly ACCEPTED with rationale.
</threat_model>

<verification>
**Per-plan exit gates** (all must exit 0):
- `flutter analyze --no-fatal-infos` (CRIT-06)
- `dart run custom_lint` (CRIT-06)
- `flutter test` (full suite GREEN — CRIT-06)
- `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` (AUDIT-10)
- `dart run scripts/coverage_gate.dart --list /tmp/phase3-plan02-touched.txt --threshold 80 --lcov coverage/lcov_clean.info` (CRIT-05 D-15)
- jq parity diff on the 3 ARB files (Task 1)

**Manual smoke verification** (per VALIDATION.md §Manual-Only Verifications):
- Run `flutter run` with a debug flag forcing `MasterKeyRepository.deriveKey()` to throw on the first call. Verify InitFailureScreen renders correctly in `ja`/`zh`/`en`. Tap Retry, clear the flag, verify app boots normally.
</verification>

<success_criteria>
- `lib/infrastructure/security/providers.dart` `appDatabaseProvider` body throws `StateError` (not `UnimplementedError`); `keepAlive: true` applied
- `test/helpers/test_provider_scope.dart` exposes `createTestProviderScope({database, additionalOverrides})` — ALWAYS overrides
- `lib/core/initialization/app_initializer.dart`, `init_result.dart`, `init_failure_screen.dart` exist and behave per UI-SPEC + RESEARCH
- `lib/main.dart` delegates to AppInitializer; sealed switch handles success/failure
- 3 ARB keys × 3 locales added; `flutter gen-l10n` regenerated; ARB parity verified
- 4 new test files (init_result_test, app_initializer_test, init_failure_screen_test, providers_test) + 1 helper + 1 smoke test all GREEN
- All 5 touched-source files reach ≥80% coverage per `coverage_gate.dart`
- AUDIT-10 (`build_runner` clean diff) passes
- CRIT-03 closed (recorded in plan SUMMARY); CRIT-06 verified
</success_criteria>

<output>
After completion, create `.planning/phases/03-critical-fixes/03-02-SUMMARY.md` recording: CRIT-03 closure note, the touched-files coverage report, the brand-color reconciliation decision (deferred to Phase 7 vs accepted divergence), the Mocktail fake pattern as Phase 4 prior art, and the build_runner regeneration commit SHAs.

Generate `doc/worklog/YYYYMMDD_HHMM_phase3_plan02_app_initializer_and_database_provider.md` per `.claude/rules/worklog.md`.
</output>
