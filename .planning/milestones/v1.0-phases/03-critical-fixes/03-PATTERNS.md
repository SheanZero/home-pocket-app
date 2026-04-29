# Phase 3: critical-fixes — Pattern Map

**Mapped:** 2026-04-26
**Files analyzed:** 23 (new + modified)
**Analogs found:** 23 / 23 (one new convention — `test/architecture/` — has only an indirect analog from `test/scripts/`)

---

## File Classification

| New / Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------------|------|-----------|----------------|---------------|
| `lib/core/initialization/app_initializer.dart` (NEW) | service / orchestrator | request-response (boot sequence) | `lib/main.dart:28-83` (the verbatim source) + `lib/application/family_sync/sync_orchestrator.dart` (orchestration class) | exact-source + role-match |
| `lib/core/initialization/init_result.dart` (NEW) | model (Freezed sealed result) | transform | `lib/infrastructure/security/models/auth_result.dart` | exact (same `@freezed sealed class` pattern, same project, similar variants) |
| `lib/core/initialization/init_failure_screen.dart` (NEW) | component (localized fallback widget) | event-driven (user tap → callback) | `lib/features/profile/presentation/screens/profile_onboarding_screen.dart` | role-match (localized screen with button + state, no Riverpod required) |
| `lib/infrastructure/security/providers.dart` (MODIFIED — concrete `appDatabaseProvider`) | service (Riverpod provider) | request-response | Same file's existing `auditLogger` provider (lines 50-55) and `secureStorageService` provider (lines 39-43) | exact (same file, same `@riverpod` convention) |
| `lib/main.dart` (MODIFIED — delegate to AppInitializer) | controller (boot entry point) | request-response | Current `lib/main.dart:28-83` (refactor target itself) | exact-source |
| `lib/l10n/app_ja.arb`, `app_zh.arb`, `app_en.arb` (3 new keys × 3 locales) | config (i18n) | static | Existing keys: `retry`, `errorUnknown`, `errorEncryption`, `initializationError` (same files) | exact (same schema, same format) |
| `lib/features/family_sync/use_cases/check_group_use_case.dart` (MOVE → `lib/application/family_sync/check_group_use_case.dart`) | service (use case) | request-response | Existing siblings in destination dir: `pull_sync_use_case.dart`, `push_sync_use_case.dart`, `confirm_join_use_case.dart` | exact (same naming convention `*_use_case.dart`, same destination directory, same sealed-class result pattern) |
| `lib/features/family_sync/use_cases/deactivate_group_use_case.dart` (MOVE) | service | request-response | Same as above | exact |
| `lib/features/family_sync/use_cases/leave_group_use_case.dart` (MOVE) | service | request-response | Same as above | exact |
| `lib/features/family_sync/use_cases/regenerate_invite_use_case.dart` (MOVE) | service | request-response | Same as above | exact |
| `lib/features/family_sync/use_cases/remove_member_use_case.dart` (MOVE) | service | request-response | Same as above | exact |
| `lib/features/home/domain/models/ledger_row_data.dart` → `lib/features/home/presentation/models/ledger_row_data.dart` (MOVE) | model (presentation view-model) | static / transform | None within `lib/features/*/presentation/models/` (directory does not yet exist on any feature). Closest: existing presentation widgets that compose `dart:ui` types directly (e.g., color tokens in `lib/core/theme/app_text_styles.dart`) | role-match (no exact precedent — Phase 3 D-12 establishes the convention) |
| `lib/features/*/domain/import_guard.yaml` (REVISED — strip `allow`) (6 files) | config (lint rule) | static | Existing `lib/features/accounting/domain/import_guard.yaml` (same files, before-state) | exact-source (mutation of the file itself) |
| `lib/features/*/domain/models/import_guard.yaml` (NEW per-subdir) (~5 files) | config (lint rule) | static | `lib/features/accounting/domain/import_guard.yaml` (parent feature-level) | role-match (extends parent shape with subdir scope) |
| `lib/features/*/domain/repositories/import_guard.yaml` (NEW per-subdir) (~6 files) | config (lint rule) | static | Same as above | role-match |
| `test/architecture/domain_import_rules_test.dart` (NEW) | test (meta-test about codebase shape) | batch / transform | `test/scripts/coverage_gate_test.dart` (subprocess + file I/O); `test/scripts/lcov_parser_test.dart` (pure parsing); `scripts/merge_findings.dart` (yaml/json file enumeration) | role-match (no `package:yaml` precedent in `test/`; pattern derived from script analogs) |
| `test/core/initialization/app_initializer_test.dart` (NEW) | test (unit, constructor-injection fakes) | request-response | `test/application/family_sync/sync_engine_dedup_test.dart` (Mocktail-style hand-written fakes, constructor injection, `ProviderContainer` setup) | exact (same Mocktail style, same constructor-injection fake pattern, same project's preferred test convention per CONTEXT.md `<deferred>`) |
| `test/core/initialization/init_failure_screen_test.dart` (NEW) | test (widget) | event-driven | `test/infrastructure/security/audit_logger_test.dart` (Mocktail-style, `setUp`/`tearDown`); UI-SPEC §"Test Contract" lists exact 9 cases | role-match (no widget-test analog with localized strings + retry callback in repo; pattern derived from UI-SPEC + Mocktail convention) |
| `test/core/initialization/init_result_test.dart` (NEW) | test (unit, Freezed sealed class) | transform | `test/infrastructure/security/models/auth_result_test.dart` (same `@freezed sealed class` model, same test style) | exact |
| `test/application/family_sync/*_use_case_test.dart` (5 MOVE targets) | test (unit) | request-response | Existing tests in `test/unit/application/accounting/*_use_case_test.dart` (note: these use `mockito` codegen — Phase 3 keeps Mocktail per CONTEXT.md `<deferred>`) | role-match |
| `.github/workflows/audit.yml` (MODIFIED — flip `import_guard` to blocking) | config (CI) | static | Existing `audit.yml:40-42` (the line being mutated) | exact-source |

---

## Pattern Assignments

### `lib/core/initialization/app_initializer.dart` (NEW — orchestrator service)

**Primary analog:** `lib/main.dart:28-83` (CONTEXT.md D-06: "captures the full main.dart:28-83 sequence verbatim")
**Secondary analog:** `lib/application/family_sync/sync_orchestrator.dart` (orchestrator class with constructor-injected dependencies)

**Source-to-extract excerpt — `lib/main.dart:28-83`:**
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
  }

  final deviceId = await keyManager.getDeviceId();
  if (deviceId == null || deviceId.isEmpty) {
    throw StateError('Device ID is not available after key initialization.');
  }

  // 3. Create database
  final AppDatabase database;
  if (_useInMemoryDatabase) {
    database = AppDatabase(NativeDatabase.memory());
  } else {
    final executor = await createEncryptedExecutor(masterKeyRepo);
    database = AppDatabase(executor);
  }

  // 4. Dispose init container, create final container with database
  initContainer.dispose();
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
  );
}
```

**Constructor-injection / orchestration analog — `lib/application/family_sync/push_sync_use_case.dart:46-60`:**
```dart
class PushSyncUseCase {
  PushSyncUseCase({
    required RelayApiClient apiClient,
    required E2EEService e2eeService,
    required GroupRepository groupRepo,
    required SyncQueueManager queueManager,
  }) : _apiClient = apiClient,
       _e2eeService = e2eeService,
       _groupRepo = groupRepo,
       _queueManager = queueManager;

  final RelayApiClient _apiClient;
  final E2EEService _e2eeService;
  final GroupRepository _groupRepo;
  final SyncQueueManager _queueManager;
  // ...
  Future<PushSyncResult> execute({...}) async { ... }
}
```

**Required adaptation:**
- Wrap each of the four stages (master-key, device-key, database, seed) in its own `try/catch` and return a typed `InitResult.failure(type: ...)` instead of throwing. RESEARCH.md §"Pattern 3" gives the full skeleton.
- Constructor takes `containerFactory`, `databaseFactory` (typedef `AppDatabaseFactory`), and `seedRunner` (typedef `SeedRunner`) — see RESEARCH.md lines 493-509.
- Replace the inlined `dev.log` calls with the same calls (`dev.log('...', name: 'AppInit')`); keep the log message text byte-identical for behavior preservation.
- The `_useInMemoryDatabase` flag becomes irrelevant — the injected `databaseFactory` is the swap point; production passes a factory that calls `createEncryptedExecutor`, tests pass a factory that returns `AppDatabase.forTesting()`.

---

### `lib/core/initialization/init_result.dart` (NEW — Freezed sealed result)

**Primary analog:** `lib/infrastructure/security/models/auth_result.dart` (entire file, 30 lines)

**Full analog excerpt:**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_result.freezed.dart';

/// Authentication result union type.
///
/// Used by [BiometricService] to represent all possible
/// outcomes of an authentication attempt. Callers use `when`
/// to exhaustively handle every case.
@freezed
sealed class AuthResult with _$AuthResult {
  /// Authentication succeeded.
  const factory AuthResult.success() = AuthResultSuccess;

  /// Authentication failed. [failedAttempts] is the cumulative count.
  const factory AuthResult.failed({required int failedAttempts}) =
      AuthResultFailed;

  /// Biometric not available — fall back to PIN authentication.
  const factory AuthResult.fallbackToPIN() = AuthResultFallbackToPIN;

  /// An unexpected platform error occurred.
  const factory AuthResult.error({required String message}) = AuthResultError;
}
```

**Required adaptation (verbatim per RESEARCH.md §3 lines 444-477):**
- Variants are exactly two: `InitResult.success({required ProviderContainer container})` and `InitResult.failure({required InitFailureType type, required Object error, StackTrace? stackTrace})`.
- Add a top-level `enum InitFailureType { masterKey, database, seed, unknown }` in the same file (above `@freezed` block).
- Tagged-class names follow the same convention: `InitSuccess` / `InitFailure` (matches `AuthResultSuccess`, `AuthResultFailed`, etc.).
- Doc-comment style matches the analog: brief class-level + per-variant `///` lines.

**Consumer pattern (Dart 3 sealed-class exhaustive switch — used in `main.dart`):**
```dart
final result = await initializer.initialize();
switch (result) {
  case InitSuccess(:final container):
    runApp(UncontrolledProviderScope(container: container, child: const HomePocketApp()));
  case InitFailure(:final type, :final error, :final stackTrace):
    dev.log('Init failed: $type — $error', name: 'AppInit', error: error, stackTrace: stackTrace);
    runApp(InitFailureApp(retry: ...)); // minimal MaterialApp wrapping InitFailureScreen
}
```

---

### `lib/core/initialization/init_failure_screen.dart` (NEW — localized fallback widget)

**Primary analog:** `lib/features/profile/presentation/screens/profile_onboarding_screen.dart` (Stateful + localized screen with button + AppColors + AppTextStyles)

**Imports + `S.of(context)` pattern — `profile_onboarding_screen.dart:1-12, 76`:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
// ...

// Inside build / handler:
final l10n = S.of(context);
// then use:
l10n.profileSetup, l10n.profileSetupSubtitle, l10n.profileStart, ...
```

**`AppColors` + Stateful + button + `_isSaving` flag pattern — `profile_onboarding_screen.dart:30-45, 71-107`:**
```dart
class _ProfileOnboardingScreenState extends ConsumerState<ProfileOnboardingScreen> {
  bool _isSaving = false;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final l10n = S.of(context);
    setState(() => _isSaving = true);
    final result = await ref.read(...).execute(...);
    if (!mounted) return;
    if (result.isSuccess) { ... return; }
    setState(() => _isSaving = false);
    final message = _messageForError(l10n, result.error);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
```

**Required adaptation (per UI-SPEC §"Interaction States" + §"Color"):**
- Use `StatefulWidget` (NOT `ConsumerStatefulWidget`) — UI-SPEC §"Interaction States" mandates Riverpod-free; the screen runs **before** `ProviderScope` is mounted, so `ref` is unavailable.
- Replace `_isSaving` with `_isRetrying`; replace `_submit` with `_handleRetry` that calls the injected `Future<void> Function() onRetry` callback.
- Use `AppColors.background` (`#FCFBF9`) for `Scaffold.backgroundColor`, NOT the dark-mode override. UI-SPEC §"Color" locks the screen to light theme regardless of system mode.
- Button background: `#8AB8DA` (sky blue per CLAUDE.md "App Color Scheme — Primary"). Button label color: `AppColors.textPrimary` `#1E2432` (NOT `Colors.white` — UI-SPEC §"Color" locks this for WCAG AAA).
- Three texts use `AppTextStyles.headlineSmall` (title), `AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)` (message — override default secondary tint per UI-SPEC §"Accessibility"), `AppTextStyles.titleSmall` (button label).
- Icon: `Icon(Icons.error_outline, size: 64, color: AppColors.textSecondary)`.
- Layout: `SafeArea > Center > SingleChildScrollView > Padding(horizontal: 16) > Column(mainAxisAlignment: center)` per UI-SPEC §"Spacing Scale".
- The retry callback is constructor-injected (`required Future<void> Function() onRetry`) — NOT looked up via Riverpod.
- Loading state: when `_isRetrying == true`, replace button child with `CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation(AppColors.textPrimary))` and set `onPressed: null`.

---

### `lib/infrastructure/security/providers.dart` (MODIFIED — concrete `appDatabaseProvider`)

**Analog:** Same file, lines 39-55 (existing `secureStorageService` and `auditLogger` providers).

**Existing provider pattern — `lib/infrastructure/security/providers.dart:39-55`:**
```dart
/// Secure storage service — iOS Keychain / Android Keystore wrapper.
@riverpod
SecureStorageService secureStorageService(Ref ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return SecureStorageService(storage: storage);
}

/// Audit logger — depends on AppDatabase and SecureStorageService.
@riverpod
AuditLogger auditLogger(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  return AuditLogger(database: database, storageService: storageService);
}
```

**Codegen consumer side — `lib/infrastructure/security/providers.g.dart:9-26`:**
```dart
String _$biometricServiceHash() => r'18210c094d1a72ed9598598ff121847f2a12ad88';

/// Biometric authentication service. ...
@ProviderFor(biometricService)
final biometricServiceProvider = Provider<BiometricService>.internal(
  biometricService,
  name: r'biometricServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$biometricServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
```

**Required adaptation (per RESEARCH.md §"Pattern 2 Option A" — preferred):**
- Replace lines 96-102 (`@riverpod AppDatabase appDatabase(Ref ref) { throw UnimplementedError(...); }`) with a more diagnostic `StateError` that documents the override-required contract:
  ```dart
  @Riverpod(keepAlive: true)
  AppDatabase appDatabase(Ref ref) {
    throw StateError(
      'appDatabaseProvider not overridden. AppInitializer.initialize() must run '
      'before any consumer reads this provider, OR a test must inject '
      'appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()). '
      'See lib/core/initialization/app_initializer.dart.',
    );
  }
  ```
- Note: this is **technically** still a throwing provider, but CRIT-03's literal success criterion ("verified by a test that constructs a `ProviderScope` without an explicit override and does not crash") is satisfied by adding a `createTestProviderScope()` helper (RESEARCH.md §"Pattern 2" lines 419-432). The placeholder is replaced by the injected override every code path that should reach it.
- Add `keepAlive: true` (matches `biometricService` precedent at line 26 of the same file) so the database singleton survives provider invalidations.
- After build_runner: regenerate `providers.g.dart` (the existing `auditLogger` consumer that does `ref.watch(appDatabaseProvider)` continues to work because the return type stays `AppDatabase` — sync, not Future).

**14 known consumers to spot-verify post-build_runner** (from RESEARCH.md §"Pattern 2"): `lib/features/accounting/presentation/providers/repository_providers.dart` (6 sites), `lib/features/profile/.../user_profile_providers.dart` (1 site), `lib/features/family_sync/.../repository_providers.dart` (3 sites), `lib/features/analytics/.../*` (2 sites), `lib/main.dart:74` (override site — keep as-is), `lib/infrastructure/security/providers.dart:52` (auditLogger). All read `AppDatabase` synchronously; no consumer changes needed.

---

### `lib/main.dart` (MODIFIED — delegate to AppInitializer)

**Analog:** Itself (lines 28-83), refactored.

**Required adaptation (per CONTEXT.md D-06 + UI-SPEC §"Surface Scope" Render path):**
- Lines 28-83 are extracted to `AppInitializer.initialize()`; `main()` becomes:
  ```dart
  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await ensureNativeLibrary();
    final initializer = AppInitializer(
      containerFactory: ({overrides = const []}) => ProviderContainer(overrides: overrides),
      databaseFactory: (masterKeyRepo) async {
        final executor = await createEncryptedExecutor(masterKeyRepo);
        return AppDatabase(executor);
      },
      seedRunner: (container) async { /* ... existing _initialize() seed steps ... */ },
    );
    final result = await initializer.initialize();
    switch (result) {
      case InitSuccess(:final container):
        runApp(UncontrolledProviderScope(container: container, child: const HomePocketApp()));
      case InitFailure(:final type, :final error, :final stackTrace):
        dev.log('Init failed: $type', name: 'AppInit', error: error, stackTrace: stackTrace);
        runApp(_InitFailureApp(retry: () async {
          // Re-invoke main() OR re-invoke initializer.initialize() and re-runApp
        }));
    }
  }
  ```
- The retry callback's exact mechanic is the planner's call — recommend re-invoking `main()` cleanly after `WidgetsBinding.instance.scheduleAttachRootWidget` teardown, OR a simpler "rebuild a single rooted `MaterialApp` of `InitFailureScreen` whose retry pumps a state machine" — UI-SPEC §"Interaction States" Re-success row covers the contract.
- The `_useInMemoryDatabase` flag and its branching disappear from `main.dart` — replaced by the `databaseFactory` choice at the call site.

---

### `lib/l10n/app_{ja,zh,en}.arb` (3 new keys × 3 locales)

**Analog:** Existing keys in the same files — `retry`, `errorUnknown`, `errorEncryption`.

**Existing schema — `lib/l10n/app_en.arb` (excerpt):**
```json
"retry": "Retry",
"@retry": { "description": "Retry action" },

"errorUnknown": "An unknown error occurred",
"@errorUnknown": { "description": "Unknown error" },

"errorEncryption": "Encryption error",
"@errorEncryption": { "description": "Encryption error" },

"initializationError": "Initialization failed: {error}",
"@initializationError": { "description": "Error message when app initialization fails" },
```

**`app_ja.arb` (excerpt):**
```json
"retry": "再試行",
"errorUnknown": "不明なエラーが発生しました",
"initializationError": "初期化に失敗しました: {error}",
```

**`app_zh.arb` (excerpt):**
```json
"retry": "重试",
```

**Required adaptation (per UI-SPEC §"Copywriting Contract" — 3 keys × 3 locales = 9 entries):**

`app_en.arb` — append:
```json
"initFailedTitle": "Initialization failed",
"@initFailedTitle": { "description": "Title shown on the AppInitializer failure fallback screen rendered before the main app mounts" },

"initFailedMessage": "Something went wrong while starting the app. Tap retry to try again.",
"@initFailedMessage": { "description": "Body message on the AppInitializer failure fallback screen — explains the failure plainly and points to the retry action. Must NOT include technical error details (those go to console logs)" },

"initFailedRetry": "Retry",
"@initFailedRetry": { "description": "Button label on the AppInitializer failure fallback screen. Re-invokes AppInitializer.initialize()" },
```

`app_ja.arb` — append (no `@key` metadata in non-default ARB files per existing project pattern; only `app_en.arb` is the template carrier):
```json
"initFailedTitle": "初期化に失敗しました",
"initFailedMessage": "アプリの起動中に問題が発生しました。再試行ボタンをタップしてください。",
"initFailedRetry": "再試行",
```

`app_zh.arb` — append:
```json
"initFailedTitle": "初始化失败",
"initFailedMessage": "应用启动时出现问题。请点击重试按钮。",
"initFailedRetry": "重试",
```

- After ARB edits: `flutter gen-l10n` (per CLAUDE.md §"Essential Commands"). Generated `lib/generated/app_localizations*.dart` is checked in.
- Consumption pattern: `S.of(context).initFailedTitle`, `.initFailedMessage`, `.initFailedRetry` — exactly as `S.of(context).retry`, `.errorUnknown`, `.initializationError` work today.

---

### `lib/features/family_sync/use_cases/*.dart` → `lib/application/family_sync/*.dart` (5 file moves)

**Analog (destination siblings):** `lib/application/family_sync/push_sync_use_case.dart`, `pull_sync_use_case.dart`, `confirm_join_use_case.dart`, `confirm_member_use_case.dart`, `create_group_use_case.dart`, etc. — 17 existing siblings.

**Naming convention confirmed:** All use the `_use_case.dart` suffix. The 5 incoming files (`check_group_use_case.dart`, `deactivate_group_use_case.dart`, `leave_group_use_case.dart`, `regenerate_invite_use_case.dart`, `remove_member_use_case.dart`) **already follow the convention** — no rename needed during `git mv`.

**File header + sealed-class result + class structure analog — `lib/application/family_sync/push_sync_use_case.dart:1-37`:**
```dart
import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';

/// Result of pushing sync data.
sealed class PushSyncResult {
  const PushSyncResult();

  const factory PushSyncResult.success(int operationCount) = PushSyncSuccess;
  const factory PushSyncResult.queued(int operationCount) = PushSyncQueued;
  const factory PushSyncResult.noPair() = PushSyncNoPair;
  const factory PushSyncResult.error(String message) = PushSyncError;
}

class PushSyncSuccess extends PushSyncResult {
  const PushSyncSuccess(this.operationCount);
  final int operationCount;
}
// ... (variant subclasses) ...

class PushSyncUseCase {
  PushSyncUseCase({
    required RelayApiClient apiClient,
    // ...
  }) : _apiClient = apiClient, /* ... */;
  // ...
}
```

**Required adaptation per file:**
- `git mv` preserves history; the 5 source files already use the same sealed-class result + constructor-injection pattern (verified via reads of `check_group_use_case.dart`, `leave_group_use_case.dart`, `regenerate_invite_use_case.dart`).
- **Import-path rewrites** are required because the file moves up the tree by ~2 levels:
  - Old: `import '../../../infrastructure/sync/relay_api_client.dart';` (3 ups from `lib/features/family_sync/use_cases/`)
  - New: `import '../../infrastructure/sync/relay_api_client.dart';` (2 ups from `lib/application/family_sync/`)
  - Old: `import '../domain/models/group_member.dart';` (relative-to-feature)
  - New: `import '../../features/family_sync/domain/models/group_member.dart';` (cross-feature absolute-style)
- **No barrel re-export** — `lib/application/family_sync/` does not have a barrel file (verified by directory listing — 17 .dart files, all leaf use cases / services). Each consumer imports the leaf file directly.
- Test moves follow the same import-path rewrite (Plan 03-03 D-09: tests move alongside).

---

### `lib/features/home/domain/models/ledger_row_data.dart` → `lib/features/home/presentation/models/ledger_row_data.dart` (MOVE)

**Analog:** **No exact precedent.** `lib/features/home/presentation/models/` does not yet exist on any feature. CONTEXT.md D-12 explicitly establishes this convention.

**Indirect analog (Freezed model pattern):** The existing source file itself.

**Source file (entire) — `lib/features/home/domain/models/ledger_row_data.dart`:**
```dart
import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'ledger_row_data.freezed.dart';

@freezed
abstract class LedgerRowData with _$LedgerRowData {
  const factory LedgerRowData({
    required String tagText,
    required Color tagBgColor,
    required Color tagTextColor,
    required String title,
    required Color titleColor,
    required String subtitle,
    required String formattedAmount,
    required Color amountColor,
    required Color chevronColor,
    Color? borderColor,
  }) = _LedgerRowData;
}
```

**Required adaptation:**
- Pure file move (`git mv`) — no code changes inside the file; the `@freezed` declaration, the `dart:ui` import, the 10 `Color` fields all stay byte-identical.
- After move: regenerate `ledger_row_data.freezed.dart` via `flutter pub run build_runner build --delete-conflicting-outputs` (the `part` directive resolves relative to the new location automatically).
- 2 source callers + 1 test caller (per RESEARCH.md): `home_screen.dart` and `ledger_comparison_section.dart` — both already in `lib/features/home/presentation/`, so their imports change from `../../domain/models/ledger_row_data.dart` to `../../models/ledger_row_data.dart` (or whatever relative path lands; planner picks).
- This is the **convention-establishing move** — Phase 7 (per D-12) will document the convention in CLAUDE.md.

---

### `lib/features/*/domain/import_guard.yaml` (REVISED — 6 files, strip `allow`)

**Analog (current state):** `lib/features/accounting/domain/import_guard.yaml` (entire file).

**Current state — `lib/features/accounting/domain/import_guard.yaml`:**
```yaml
# Domain layer — leafmost in the dependency graph (CRIT-04 territory).
# Whitelist mode: deny everything except dart:core + the immutability/serialization annotations.
deny:
  - package:home_pocket/data/**
  - package:home_pocket/infrastructure/**
  - package:home_pocket/application/**
  - package:home_pocket/features/**/presentation/**
  - package:flutter/**

allow:
  - dart:core
  - package:freezed_annotation/**
  - package:json_annotation/**
  - package:meta/**

inherit: true
```

**Required adaptation (per RESEARCH.md §"Pattern 1" CORRECTED D-01):**
Strip the `allow:` block. The file becomes deny-only:
```yaml
# Domain layer — leafmost in the dependency graph (CRIT-04 territory).
# Per Phase 3 D-01 (corrected): allow whitelist moved to per-subdirectory yamls
# because import_guard_custom_lint evaluates each config in the chain
# independently against its own allow whitelist.
deny:
  - package:home_pocket/data/**
  - package:home_pocket/infrastructure/**
  - package:home_pocket/application/**
  - package:home_pocket/features/**/presentation/**
  - package:flutter/**

inherit: true
# NOTE: no `allow:` block — children own the whitelist (see models/, repositories/ subdirs)
```

Apply to all 6 feature-level files: `accounting/`, `analytics/`, `family_sync/`, `home/`, `profile/`, `settings/`.

---

### `lib/features/*/domain/{models,repositories}/import_guard.yaml` (NEW — ~11 per-subdir files)

**Analog:** RESEARCH.md §"Pattern 1" lines 295-326 (concrete templates for `accounting/`).

**`models/` subdir template:**
```yaml
allow:
  - dart:core
  - package:freezed_annotation/**
  - package:json_annotation/**
  - package:meta/**
  - transaction.dart                 # LV-001, LV-003, LV-004 (relative pattern)
  - category.dart                    # LV-002 (relative pattern)
  # Add only the leaves THIS subdirectory composes; nothing else.

inherit: true
```

**`repositories/` subdir template:**
```yaml
allow:
  - dart:core
  - package:freezed_annotation/**
  - package:json_annotation/**
  - package:meta/**
  - ../models/book.dart              # LV-005
  - ../models/category_keyword_preference.dart  # LV-006
  - ../models/category.dart          # LV-008
  - ../models/transaction.dart       # LV-010

inherit: true
```

**Required adaptation per feature** (RESEARCH.md "Per-feature inventory" table lines 332-339 lists all leaves):
- `accounting/`: `models/` allows `transaction.dart` + `category.dart`; `repositories/` allows the 6 model paths LV-005..LV-010.
- `analytics/`: `models/` allows `daily_expense.dart` + `month_comparison.dart`; `repositories/` allows `analytics_aggregate.dart`.
- `family_sync/`: `models/` allows `group_member.dart`; `repositories/` allows `group_info.dart` + `group_member.dart`.
- `home/`: NO new yaml needed (`ledger_row_data.dart` MOVES out per Plan 03-04).
- `profile/`: only `repositories/` yaml needed; allows `user_profile.dart`.
- `settings/`: only `repositories/` yaml needed; allows `app_settings.dart`.

Total: ~11 new yaml files (5 `models/` + 6 `repositories/`, less or more depending on which features have models with violations).

---

### `test/architecture/domain_import_rules_test.dart` (NEW)

**Analog:** **No exact precedent in `test/`.** The closest existing pattern is `test/scripts/coverage_gate_test.dart` (subprocess + file I/O on `coverage/lcov_clean.info`). For YAML parsing, the closest pattern is `scripts/merge_findings.dart` (which uses `dart:io` + `dart:convert` for JSON; YAML is similar). RESEARCH.md §"Pattern 4" provides the full skeleton.

**`File()` + iterate-features pattern (from `scripts/merge_findings.dart:22-40`):**
```dart
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final shards = <Finding>[];
  for (final dir in const ['shards', 'agent-shards']) {
    final shardDir = Directory('.planning/audit/$dir');
    if (!shardDir.existsSync()) continue;
    final files = shardDir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      if (!f.path.endsWith('.json')) continue;
      final raw = await f.readAsString();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (e) { /* ... */ }
    }
  }
}
```

**`flutter_test` group + assertion structure analog — `test/scripts/coverage_gate_test.dart:66-87`:**
```dart
void main() {
  group('coverage_gate.dart (subprocess)', () {
    late Directory tmp;
    setUp(() { tmp = _setupTempProject(); });
    tearDown(() { try { tmp.deleteSync(recursive: true); } catch (_) {} });

    test('exits 0 when all positional files meet threshold', () async {
      _writeLcov(tmp, {'lib/a.dart': (10, 10), 'lib/b.dart': (9, 10)});
      final r = await _runGate(tmp, ['lib/a.dart', 'lib/b.dart']);
      expect(r.exitCode, equals(0), reason: r.stderr.toString());
      expect(r.stdout.toString(), contains('PASS'));
    });
  });
}
```

**Required adaptation (full skeleton per RESEARCH.md lines 657-704):**
```dart
// test/architecture/domain_import_rules_test.dart (NEW)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Domain layer import_guard rules', () {
    const features = ['accounting', 'analytics', 'family_sync', 'home',
                      'profile', 'settings'];
    const requiredDeny = [
      'package:home_pocket/data/**',
      'package:home_pocket/infrastructure/**',
      'package:home_pocket/application/**',
      'package:home_pocket/features/**/presentation/**',
      'package:flutter/**',
    ];

    for (final feature in features) {
      group('feature: $feature', () {
        test('feature-level domain yaml has full deny set + no allow', () {
          final path = 'lib/features/$feature/domain/import_guard.yaml';
          final yaml = loadYaml(File(path).readAsStringSync()) as YamlMap;
          final deny = (yaml['deny'] as YamlList).map((e) => e.toString()).toList();
          expect(deny, containsAll(requiredDeny));
          expect(yaml['allow'], isNull,
            reason: 'Phase 3 D-01: feature-level allow moved to per-subdirectory yamls');
          expect(yaml['inherit'], isTrue);
        });

        test('models/ subdir yaml allow is intra-domain only', () {
          final path = 'lib/features/$feature/domain/models/import_guard.yaml';
          if (!File(path).existsSync()) return;
          final yaml = loadYaml(File(path).readAsStringSync()) as YamlMap;
          final allow = (yaml['allow'] as YamlList).map((e) => e.toString()).toList();
          for (final entry in allow) {
            final isAnnotation = entry == 'dart:core'
                || entry.startsWith('package:freezed_annotation')
                || entry.startsWith('package:json_annotation')
                || entry.startsWith('package:meta');
            final isIntraDomain = !entry.contains('/')
                || entry.startsWith('../models/');
            expect(isAnnotation || isIntraDomain, isTrue,
              reason: 'Allow leaf "$entry" is neither an annotation nor an intra-domain leaf');
          }
        });
      });
    }
  });
}
```

- `package:yaml` is already a transitive dependency (used by `import_guard_custom_lint`'s `ConfigCache` per RESEARCH.md). No new pubspec entry needed.
- The test must NOT spawn subprocesses — it's a pure file-read + YAML-parse + assertion test. Faster than `coverage_gate_test.dart`.
- Establishes the `test/architecture/` directory as Phase 3 D-03 mandates; future Phase-4 `provider_graph_hygiene_test.dart` joins this directory.

---

### `test/core/initialization/app_initializer_test.dart` (NEW — Mocktail unit test)

**Analog:** `test/application/family_sync/sync_engine_dedup_test.dart` (Mocktail-style hand-written fakes, constructor-injection, no `@GenerateMocks` codegen).

**Mocktail fake-class + setUp + ProviderContainer analog — `test/application/family_sync/sync_engine_dedup_test.dart:1-100`:**
```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncOrchestrator extends Mock implements SyncOrchestrator {}
class MockGroupRepository extends Mock implements GroupRepository {}
class MockKeyManager extends Mock implements KeyManager {}

void main() {
  setUpAll(() {
    registerFallbackValue(SyncMode.initialSync);
  });

  group('SyncEngine deduplication', () {
    late SyncEngine engine;
    late MockSyncOrchestrator orchestrator;
    late MockGroupRepository groupRepo;
    late MockKeyManager keyManager;

    setUp(() {
      orchestrator = MockSyncOrchestrator();
      groupRepo = MockGroupRepository();
      keyManager = MockKeyManager();
      when(() => orchestrator.needsFullPull()).thenAnswer((_) async => false);
      when(() => groupRepo.getActiveGroup()).thenAnswer((_) async => activeGroup);
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');

      engine = SyncEngine(
        orchestrator: orchestrator,
        groupRepo: groupRepo,
        // ...
      );
    });
    // ... tests ...
  });
}
```

**Drift in-memory database analog — `test/infrastructure/security/audit_logger_test.dart:1-27`:**
```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    // ...
  });

  tearDown(() async {
    await db.close();
  });
}
```

**Required adaptation (full skeleton per RESEARCH.md §"Pattern 3" lines 578-645):**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/initialization/app_initializer.dart';
import 'package:home_pocket/core/initialization/init_result.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:mocktail/mocktail.dart';

class _FakeMasterKeyRepo extends Mock implements MasterKeyRepository {}

void main() {
  group('AppInitializer', () {
    late _FakeMasterKeyRepo fakeRepo;

    setUp(() {
      fakeRepo = _FakeMasterKeyRepo();
      when(() => fakeRepo.hasMasterKey()).thenAnswer((_) async => true);
    });

    test('returns success when all stages succeed', () async {
      final initializer = AppInitializer(
        containerFactory: ({overrides = const []}) => ProviderContainer(overrides: [
          masterKeyRepositoryProvider.overrideWithValue(fakeRepo),
          ...overrides,
        ]),
        databaseFactory: (_) async => AppDatabase.forTesting(),
        seedRunner: (_) async {},
      );

      final result = await initializer.initialize();
      expect(result, isA<InitSuccess>());
      (result as InitSuccess).container.dispose();
    });

    test('returns failure(masterKey) when master key init throws', () async {
      when(() => fakeRepo.hasMasterKey()).thenThrow(StateError('keychain'));
      // ... build initializer, call initialize(), assert failure type ...
      expect((result as InitFailure).type, InitFailureType.masterKey);
    });

    test('returns failure(database) when databaseFactory throws', () async { /* ... */ });
    test('returns failure(seed) when seedRunner throws', () async { /* ... */ });
    // ~10 tests total per CONTEXT.md D-08
  });
}
```

- **Mocktail (NOT Mockito codegen)** per CONTEXT.md `<deferred>`: "Phase 3 keeps existing committed mockito artifacts as-is; tests for new files use Mocktail-style hand-written fakes." Existing `test/application/family_sync/sync_engine_dedup_test.dart` is the pattern carrier.
- Reuse `AppDatabase.forTesting()` (in-memory) per CONTEXT.md `<code_context>` "Reusable Assets" — do NOT spin up a real `flutter_secure_storage`.
- 10 tests total: success path + 4 failure modes + 5 edge cases (RESEARCH.md lines 638-644 enumerates).

---

### `test/core/initialization/init_failure_screen_test.dart` (NEW — widget test)

**Analog:** No widget-test analog with localized strings + retry callback exists. Closest pattern: UI-SPEC §"Test Contract" enumerates the 9 cases. The Mocktail style and `setUp`/`tearDown` follow `test/infrastructure/security/audit_logger_test.dart`.

**Required structure (per UI-SPEC §"Test Contract"):**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/initialization/init_failure_screen.dart';
import 'package:home_pocket/core/theme/app_colors.dart';
import 'package:home_pocket/generated/app_localizations.dart';

Future<void> _pumpScreen(WidgetTester tester, {
  Locale locale = const Locale('en'),
  required Future<void> Function() onRetry,
}) async {
  await tester.pumpWidget(MaterialApp(
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
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders all three localized strings (en)', (tester) async {
    await _pumpScreen(tester, onRetry: () async {});
    expect(find.text('Initialization failed'), findsOneWidget);
    expect(find.text('Something went wrong while starting the app. Tap retry to try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping retry button invokes injected callback', (tester) async {
    var retried = false;
    await _pumpScreen(tester, onRetry: () async { retried = true; });
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(retried, isTrue);
  });

  // 7 more tests: ja+zh strings, icon presence, loading state, dark text on button, ...
}
```

- 9 widget tests per UI-SPEC §"Test Contract" → projects to ≥85% line coverage (UI-SPEC §"Coverage projection").
- The `MaterialApp` wrapper test harness is necessary because the screen lives inside its own minimal `MaterialApp` in production (UI-SPEC §"Surface Scope" Render path).

---

### `test/core/initialization/init_result_test.dart` (NEW — Freezed sealed test)

**Analog:** `test/infrastructure/security/models/auth_result_test.dart` (same Freezed sealed-class style + same "exhaustive switch" assertion convention).

**Required adaptation:** Mirror auth_result_test.dart structure: a few constructor tests + exhaustive switch coverage on `InitResult.success` / `InitResult.failure` variants. Small file (~30 lines).

---

### `test/application/family_sync/*_use_case_test.dart` (5 MOVE targets)

**Analog (existing, but uses `mockito` codegen — DO NOT replicate that aspect):** `test/unit/application/accounting/seed_categories_use_case_test.dart`.

**Existing mockito-based pattern — `test/unit/application/accounting/seed_categories_use_case_test.dart:1-30`:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/seed_categories_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([CategoryRepository, CategoryLedgerConfigRepository])
import 'seed_categories_use_case_test.mocks.dart';

void main() {
  late MockCategoryRepository mockCategoryRepo;

  setUp(() {
    mockCategoryRepo = MockCategoryRepository();
    useCase = SeedCategoriesUseCase(categoryRepository: mockCategoryRepo, /* ... */);
  });
}
```

**Required adaptation per Phase 3 D-09:**
- The 5 test files **already exist** under `test/features/family_sync/use_cases/<name>_test.dart` (per CONTEXT.md `<canonical_refs>` line 145). Plan 03-03 `git mv`s them to `test/application/family_sync/<name>_test.dart`.
- **Do not modify the test bodies.** If they currently use `mockito` codegen (`*.mocks.dart`), keep them as-is — CONTEXT.md `<deferred>` explicitly says "Phase 3 keeps existing committed mockito artifacts as-is." The `*.mocks.dart` strategy decision is Phase 4 (HIGH-07) territory.
- Update the `import 'package:home_pocket/features/family_sync/use_cases/<name>.dart';` line to `import 'package:home_pocket/application/family_sync/<name>.dart';` — single line change per file.
- Test moves bundle into the same per-file PR as the source move (D-09).

---

### `.github/workflows/audit.yml` (MODIFIED — flip `import_guard` to blocking)

**Analog:** Same file, lines 40-42.

**Current state — `.github/workflows/audit.yml:40-42`:**
```yaml
      - name: dart run custom_lint
        continue-on-error: true   # Phase 4 exit gate flips this blocking (D-04)
        run: dart run custom_lint
```

**Required adaptation (per Phase 1 D-04 + Phase 3 D-17):**
- Remove the `continue-on-error: true` line; preserve the comment as a historical note (or replace with `# Made blocking at Phase 3 close per D-17`).
- This is the **last commit of the last Phase 3 plan** (per D-17). A pre-flip CI dry-run confirms the post-fix codebase passes the now-blocking gate before the flip is committed.
- Note: lines 38 (`flutter analyze`) and 44 (audit scanners) keep `continue-on-error: true` until their respective phases (Phase 6 + 4) close.

---

## Shared Patterns

### Mocktail-style hand-written fakes (NOT Mockito codegen)

**Source:** `test/application/family_sync/sync_engine_dedup_test.dart:13-18`
**Apply to:** All NEW test files in Phase 3 (`app_initializer_test.dart`, `init_failure_screen_test.dart`, `init_result_test.dart`)
**Authority:** CONTEXT.md `<deferred>` — "Tests for new files use Mocktail-style hand-written fakes."

```dart
class MockSyncOrchestrator extends Mock implements SyncOrchestrator {}
class MockGroupRepository extends Mock implements GroupRepository {}

setUp(() {
  orchestrator = MockSyncOrchestrator();
  when(() => orchestrator.needsFullPull()).thenAnswer((_) async => false);
});
```

### `AppDatabase.forTesting()` for unit tests

**Source:** `test/infrastructure/security/audit_logger_test.dart:16-27`
**Apply to:** Any Phase 3 test that touches `AppDatabase` (`app_initializer_test.dart` happy-path test; characterization tests in Plan 03-05)
**Authority:** CONTEXT.md `<code_context>` "Reusable Assets"

```dart
import 'package:drift/native.dart';

setUp(() { db = AppDatabase(NativeDatabase.memory()); });
tearDown(() async { await db.close(); });
```

### `S.of(context)` localization access

**Source:** `lib/features/profile/presentation/screens/profile_onboarding_screen.dart:1-7, 76, 111`
**Apply to:** `init_failure_screen.dart`, the `init_failure_screen_test.dart` widget pump harness
**Authority:** CLAUDE.md §"i18n Rules" — "All UI text via `S.of(context)` — never hardcode strings."

```dart
import '../../generated/app_localizations.dart';

@override
Widget build(BuildContext context) {
  final l10n = S.of(context);
  return Text(l10n.initFailedTitle);
}
```

### `@riverpod` provider declaration

**Source:** `lib/infrastructure/security/providers.dart:39-55` (existing precedent in the same file being modified)
**Apply to:** `appDatabaseProvider` revised body
**Authority:** CLAUDE.md §"Riverpod Provider Rules" — `@riverpod` code-gen mandatory.

```dart
@Riverpod(keepAlive: true)
ReturnType providerName(Ref ref) { /* body */ }
```

After source change: `flutter pub run build_runner build --delete-conflicting-outputs` regenerates `providers.g.dart`.

### `coverage_gate.dart` invocation

**Source:** `scripts/coverage_gate.dart:7-12, 75-94` (CLI shape) + `test/scripts/coverage_gate_test.dart:96-107` (`--list <path>` usage example)
**Apply to:** Each Phase 3 plan's exit-gate check (per CONTEXT.md `<canonical_refs>` line 108)
**Authority:** CONTEXT.md `<canonical_refs>` line 108 + Phase 2 D-09 (touched-files gating contract).

**Per-plan invocation:**
```bash
dart run scripts/coverage_gate.dart \
  --list <path-to-plan-touched-files.txt> \
  --threshold 80 \
  --lcov coverage/lcov_clean.info
```

**Touched-files-list format (one path per line, newline-delimited):**
```
lib/core/initialization/app_initializer.dart
lib/core/initialization/init_result.dart
lib/core/initialization/init_failure_screen.dart
lib/infrastructure/security/providers.dart
lib/main.dart
```

Exit codes per `scripts/coverage_gate.dart:13-16`:
- 0 — all files pass
- 1 — at least one file below threshold (gate failure)
- 2 — invocation error (missing lcov, no files supplied)

LCOV path default: `coverage/lcov_clean.info` (filtered by `coverde` per `.github/workflows/audit.yml`).

### Sealed-class result types in use cases

**Source:** `lib/application/family_sync/push_sync_use_case.dart:11-37` and `lib/features/family_sync/use_cases/regenerate_invite_use_case.dart:1-30` (manually-coded sealed class — note: NOT Freezed, simpler sealed pattern with `extends` subclasses)
**Apply to:** Sanity-check during the 5 use_case migrations — confirm each file's sealed-class result follows the pattern.
**Note:** `InitResult` (Plan 03-02) uses the **Freezed** sealed pattern (analog: `auth_result.dart`), NOT the manual-extends pattern from `push_sync_use_case.dart`. Freezed is preferred for new sealed classes per CLAUDE.md §"Key Patterns" (immutability via copyWith).

---

## No Analog Found

Files where the codebase has no existing precedent — the planner uses RESEARCH.md and UI-SPEC.md as the source of truth instead.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/features/home/presentation/models/ledger_row_data.dart` | model (presentation view-model) | static | The `lib/features/*/presentation/models/` directory does not exist on any feature today. Phase 3 D-12 establishes this as a new project convention. The existing source file IS the only reference; pure file move with import-path fixups suffices. |
| `test/architecture/domain_import_rules_test.dart` | test (meta-test about codebase shape) | batch | The `test/architecture/` directory is new (Phase 3 D-03 establishes it). No `package:yaml`-using test exists in `test/`. The script-side analog (`scripts/merge_findings.dart`) shows the file-enumeration pattern; the YAML parsing comes from RESEARCH.md §"Pattern 4" (which is itself derived from `import_guard_custom_lint`'s own ConfigCache code). |
| `lib/core/initialization/init_failure_screen.dart` | component (pre-`ProviderScope` localized fallback) | event-driven | No existing widget runs *before* the main `ProviderScope` is mounted. `profile_onboarding_screen.dart` is the closest localized + button + state widget but it lives inside the full app shell. The screen's "minimal MaterialApp wrapper, light theme regardless of system, no Riverpod" requirements come from UI-SPEC §"Surface Scope" + §"Color". |

---

## Metadata

**Analog search scope:** `lib/`, `test/`, `scripts/`, `.github/workflows/`, `lib/l10n/`
**Files scanned:** ~40 (focused targeted reads; no whole-directory loads)
**Pattern extraction date:** 2026-04-26
**Decisions consulted:** CONTEXT.md D-01..D-17 (all locked); RESEARCH.md §"Pattern 1..4"; UI-SPEC.md §"Surface Scope" / §"Color" / §"Test Contract" / §"Interaction States"

---

## PATTERN MAPPING COMPLETE

**Phase:** 3 — critical-fixes
**Files classified:** 23
**Analogs found:** 23 / 23 (3 with role-match only — no exact precedent for `presentation/models/`, `test/architecture/`, or pre-`ProviderScope` widget; pattern derived from RESEARCH.md + UI-SPEC.md)

### Coverage
- Files with exact analog: 16 (use_case moves × 5, ARB key additions, `auth_result.dart` analog for `init_result.dart`, `audit.yml` flip, in-place `import_guard.yaml` strips, etc.)
- Files with role-match analog: 7 (per-subdir yamls, `init_failure_screen.dart`, `app_initializer.dart` orchestrator, widget test, `domain_import_rules_test.dart`, `ledger_row_data.dart` move, `app_initializer_test.dart`)
- Files with no analog: 0 (3 are role-match-only and rely on RESEARCH.md/UI-SPEC.md for non-codebase guidance)

### Key Patterns Identified
- **Constructor-injection orchestration with Freezed sealed result** — `AppInitializer` follows `lib/application/family_sync/sync_orchestrator.dart` (constructor-injected deps) + `lib/infrastructure/security/models/auth_result.dart` (`@freezed sealed class` with `success`/`failure` variants); consumers use Dart 3 sealed-class exhaustive switch.
- **`@riverpod` keepAlive providers in `lib/infrastructure/security/providers.dart`** — concrete `appDatabaseProvider` extends the same `@Riverpod(keepAlive: true)` convention already used by `biometricService`; codegen produces `providers.g.dart`.
- **Mocktail hand-written fakes for new tests** — established by `test/application/family_sync/sync_engine_dedup_test.dart`; CONTEXT.md `<deferred>` locks Phase 3 to this style (Mockito codegen is Phase 4 territory).
- **Per-subdirectory `import_guard.yaml` with parent-strip-allow strategy** — RESEARCH.md correction to D-01: parent feature-level yaml becomes deny-only; subdirs own the allow whitelist with relative-path patterns (`transaction.dart`, `../models/book.dart`).
- **`coverage_gate.dart --list` for per-plan touched-files gating** — invocation pattern verified against `scripts/coverage_gate.dart:60-93` and `test/scripts/coverage_gate_test.dart:96-107`; LCOV path defaults to `coverage/lcov_clean.info` produced by `coverde` filter.
- **`S.of(context)` for all UI text + per-locale ARB additions** — `app_en.arb` is the metadata-carrier ARB (with `@key` description blocks); `app_ja.arb` and `app_zh.arb` carry only key-value pairs; `flutter gen-l10n` regenerates `lib/generated/app_localizations*.dart`.

### File Created
`/Users/xinz/Development/home-pocket-app/.planning/phases/03-critical-fixes/03-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can now reference analog patterns in PLAN.md files for each of Plans 03-01 through 03-05.
