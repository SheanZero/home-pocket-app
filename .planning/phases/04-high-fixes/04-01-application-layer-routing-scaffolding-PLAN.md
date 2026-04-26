---
phase: 04-high-fixes
plan: 01
type: execute
wave: 2
depends_on:
  - 04-06
files_modified:
  - lib/application/family_sync/repository_providers.dart
  - lib/application/family_sync/repository_providers.g.dart
  - lib/application/accounting/repository_providers.dart
  - lib/application/accounting/repository_providers.g.dart
  - lib/application/analytics/repository_providers.dart
  - lib/application/analytics/repository_providers.g.dart
  - lib/application/profile/repository_providers.dart
  - lib/application/profile/repository_providers.g.dart
  - lib/application/settings/repository_providers.dart
  - lib/application/settings/repository_providers.g.dart
  - lib/application/dual_ledger/repository_providers.dart
  - lib/application/dual_ledger/repository_providers.g.dart
  - lib/application/home/repository_providers.dart
  - lib/application/home/repository_providers.g.dart
  - lib/application/ml/lookup_merchant_use_case.dart
  - lib/application/ml/repository_providers.dart
  - lib/application/ml/repository_providers.g.dart
  - lib/application/voice/start_speech_recognition_use_case.dart
  - lib/application/voice/repository_providers.dart
  - lib/application/voice/repository_providers.g.dart
  - lib/application/family_sync/notify_member_approval_use_case.dart
  - lib/application/family_sync/listen_to_push_notifications_use_case.dart
  - lib/application/i18n/formatter_service.dart
  - lib/application/i18n/formatter_service.g.dart
  - lib/application/i18n/locale_settings_view.dart
autonomous: true
requirements:
  - HIGH-02
tags:
  - application_layer_scaffolding
  - hoisting
  - high_fixes
must_haves:
  goals:
    - "All Application-layer DI scaffolding required by HIGH-02 exists in `lib/application/<feature>/repository_providers.dart`, `lib/application/<feature>/<verb>_use_case.dart`, and `lib/application/i18n/formatter_service.dart` so that Plan 04-02 can replace 33 `lib/features/*/presentation/` direct `infrastructure/` imports with Application-layer imports (CONTEXT.md D-02, D-04, PATTERNS.md §1-§4). All hoisted providers use the `app` symbol prefix (e.g., `appE2eeServiceProvider`, `appMerchantDatabaseProvider`) to eliminate library-level Riverpod codegen symbol collisions with the original infrastructure providers during Wave 2/3 coexistence; Plan 04-02 final cleanup deletes the originals once consumers migrate"
  truths:
    - "Repo lock active throughout Phase 4 (CONTEXT.md D-19 + .planning/audit/REPO-LOCK-POLICY.md) — only Phase 4 cleanup PRs merge to main"
    - "coverage_gate.dart enforced per-plan only; CI integration deferred to Phase 6 (CONTEXT.md D-21)"
    - "import_guard remains BLOCKING (Phase 3 D-17 flip). Application layer is permitted to import Infrastructure (5-layer rule) so the new application files do NOT trigger violations"
    - "Six keepAlive providers per HIGH-05 hard list MUST retain `@Riverpod(keepAlive: true)` verbatim during hoisting: `syncEngineProvider`, `transactionChangeTrackerProvider`, `merchantDatabaseProvider` (becomes `appMerchantDatabaseProvider` in application layer per Task 2 prefix decision — Plan 04-05 hard list updated accordingly), `activeGroupProvider`, `activeGroupMembersProvider`, `ledgerProvider`. This plan moves `merchantDatabaseProvider` into application layer as `appMerchantDatabaseProvider`; Plan 04-02 will move/preserve the others. Copy keepAlive annotation verbatim per PATTERNS.md §1"
    - "Use case classes follow constructor-injection + sealed-result pattern per `lib/application/family_sync/check_group_use_case.dart` (PATTERNS.md §2 Analog) and `lib/application/voice/parse_voice_input_use_case.dart` (PATTERNS.md §3 Analog)"
    - "FormatterService is a `const` class with instance methods that delegate to existing static `DateFormatter` and `NumberFormatter` (PATTERNS.md §4). Implementation stays at `lib/infrastructure/i18n/formatters/`; only the public API surface moves to `lib/application/i18n/`. Per CONTEXT.md 'Claude's Discretion' item 3: const class with methods is the lightest correct shape (no instance state needed)"
    - "**Symbol naming — `app` prefix REQUIRED for all hoisted providers in this plan**: per Warning 7 fix, application-layer providers that mirror existing feature/presentation providers MUST use the `app` prefix (`appE2eeServiceProvider`, `appRelayApiClientProvider`, `appApnsPushMessagingClientProvider`, `appPushNotificationServiceProvider`, `appSyncQueueManagerProvider`, `appWebSocketServiceProvider`, `appMerchantDatabaseProvider`, `appAppDatabaseProvider`, `appKeyManagerProvider`, `appSpeechRecognitionServiceProvider`). Reason: Riverpod's `@riverpod` codegen creates provider symbols at LIBRARY level (not file scope); two libraries declaring the same `e2eeServiceProvider` would compile but produce TWO distinct Provider instances; if a test or scope imports both, runtime ambiguity occurs and `keepAlive: true` semantics could split between scopes. The `app` prefix guarantees the application-layer providers are distinct symbols. Plan 04-02 swaps consumers to `app`-prefixed names then deletes the original (non-prefixed) feature-side definitions in its Task 5 cleanup commit."
    - "Naming-collision is by-path not by-symbol — `lib/application/<feature>/repository_providers.dart` and `lib/features/<feature>/presentation/providers/repository_providers.dart` both exist as FILES; the SYMBOLS inside differ (application uses `app` prefix per above); imports must spell out the full path (CONTEXT.md `<specifics>` 3rd bullet, PATTERNS.md §1)"
    - "`lib/application/dual_ledger/providers.dart` already exists (the analog) — per CONTEXT.md 'Claude's Discretion' item 7: rename to `repository_providers.dart` (planner decision: standard name wins; one rename touches `providers.g.dart` regen — acceptable cost for naming consistency)"
    - "Wave 2 — depends on Plan 04-06 (Wave 0); Plan 04-02 (Wave 3) consumes this plan's scaffolding"
    - "After this plan, `lib/application/<feature>/repository_providers.dart` exists for {accounting, analytics, dual_ledger, family_sync, home, ml, profile, settings, voice}; new use cases exist for sync-client wrappers, ML merchant lookup, and speech-recognition start; FormatterService exists with const class + provider"
  artifacts:
    - path: "lib/application/family_sync/repository_providers.dart"
      provides: "Hoisted DI for sync clients (apns_push_messaging_client, e2ee_service, push_notification_service, relay_api_client, sync_queue_manager, websocket_service) using `app` prefix; also re-exports keyManagerProvider for feature consumption as `appKeyManagerProvider`"
      contains: "@riverpod"
      min_lines: 50
    - path: "lib/application/accounting/repository_providers.dart"
      provides: "Hoisted DI for crypto + security re-exports needed by accounting feature; specifically `appAppDatabaseProvider`, `appKeyManagerProvider`"
      contains: "@riverpod"
      min_lines: 30
    - path: "lib/application/analytics/repository_providers.dart"
      provides: "Hoisted DI for security providers needed by analytics feature (`app` prefix)"
      min_lines: 20
    - path: "lib/application/profile/repository_providers.dart"
      provides: "Hoisted DI for security providers needed by profile feature (`app` prefix)"
      min_lines: 20
    - path: "lib/application/dual_ledger/repository_providers.dart"
      provides: "Renamed from `providers.dart`; same content + extended"
      contains: "ruleEngineProvider"
      min_lines: 20
    - path: "lib/application/ml/lookup_merchant_use_case.dart"
      provides: "LookupMerchantUseCase wrapping MerchantDatabase.lookup() for screens"
      contains: "class LookupMerchantUseCase"
      min_lines: 30
    - path: "lib/application/ml/repository_providers.dart"
      provides: "Hoisted DI for `appMerchantDatabaseProvider` (keepAlive preserved per HIGH-05 — Plan 04-05 hard list updated to use the `app`-prefixed name)"
      contains: "@Riverpod(keepAlive: true)"
      min_lines: 15
    - path: "lib/application/voice/start_speech_recognition_use_case.dart"
      provides: "StartSpeechRecognitionUseCase wrapping SpeechRecognitionService stream API"
      contains: "class StartSpeechRecognitionUseCase"
      min_lines: 30
    - path: "lib/application/voice/repository_providers.dart"
      provides: "Hoisted DI for `appSpeechRecognitionServiceProvider`"
      min_lines: 15
    - path: "lib/application/family_sync/notify_member_approval_use_case.dart"
      provides: "Wraps RelayApiClient + WebSocketService used by member_approval_screen.dart"
      contains: "class NotifyMemberApprovalUseCase"
      min_lines: 30
    - path: "lib/application/family_sync/listen_to_push_notifications_use_case.dart"
      provides: "Wraps PushNotificationService stream used by family_sync_notification_route_listener and notification_navigation_provider"
      contains: "class ListenToPushNotificationsUseCase"
      min_lines: 30
    - path: "lib/application/i18n/formatter_service.dart"
      provides: "Const class wrapping DateFormatter + NumberFormatter static methods as instance methods"
      contains: "class FormatterService"
      min_lines: 50
    - path: "lib/application/i18n/locale_settings_view.dart"
      provides: "Re-export wrapper for LocaleSettings model so feature/presentation does not import infrastructure/"
      min_lines: 5
  key_links:
    - from: "lib/application/family_sync/repository_providers.dart"
      to: "lib/infrastructure/sync/* and lib/infrastructure/crypto/providers.dart"
      via: "Application is permitted Infrastructure access by 5-layer rule"
      pattern: "package:home_pocket/infrastructure/"
    - from: "lib/application/i18n/formatter_service.dart"
      to: "lib/infrastructure/i18n/formatters/{date,number}_formatter.dart"
      via: "delegation: const class methods call static functions"
      pattern: "DateFormatter\\.|NumberFormatter\\."
    - from: "Plan 04-02"
      to: "this plan's scaffolding"
      via: "Plan 04-02 imports `lib/application/<feature>/repository_providers.dart` from feature presentation files (replacing direct infrastructure/ imports) and references `app`-prefixed provider symbols"
      pattern: "import.*application/.*/repository_providers"
---

<objective>
Plan 04-01 scaffolds the Application-layer routing surface required by HIGH-02. It creates:

1. **Eight new `lib/application/<feature>/repository_providers.dart` files** that hoist infrastructure-touching providers (sync clients, crypto, security, merchant DB, speech) so feature presentation can import application/ instead of infrastructure/. The Application layer is permitted Infrastructure access (5-layer rule), so these new files never violate `import_guard`. **All hoisted providers use the `app` symbol prefix** (per Warning 7 fix) to prevent Riverpod library-level codegen symbol collisions with the existing infrastructure-side providers during Wave 2/3 coexistence.
2. **Four new use cases** wrapping business actions currently called directly from screens: `LookupMerchantUseCase` (ML), `StartSpeechRecognitionUseCase` (voice), `NotifyMemberApprovalUseCase` (family_sync), `ListenToPushNotificationsUseCase` (family_sync).
3. **One new `lib/application/i18n/formatter_service.dart` const class** wrapping the existing static `DateFormatter` and `NumberFormatter` so screens get an injectable `formatterServiceProvider` instead of static-call dependencies.
4. **One new `lib/application/i18n/locale_settings_view.dart` re-export** so `appearance_section.dart` and `locale_provider.dart` can import the model from application/ instead of infrastructure/.

Plus one rename (`lib/application/dual_ledger/providers.dart` → `lib/application/dual_ledger/repository_providers.dart`) per CONTEXT.md "Claude's Discretion" item 7 — standard name wins.

Per CONTEXT.md D-04: naming collision is by-path. The application-side `lib/application/family_sync/repository_providers.dart` and feature-side `lib/features/family_sync/presentation/providers/repository_providers.dart` coexist with different symbols inside (application uses `app` prefix per above).

Per CONTEXT.md D-02: this is "scaffolding only." This plan does NOT touch any feature/ file. Plan 04-02 (Wave 3) consumes this scaffolding to replace 33 illegal infrastructure imports and (Task 5) deletes the original (non-prefixed) feature-side duplicates once consumers migrate.

Output: ~13 new files + 1 rename; `flutter analyze` 0; `flutter test` GREEN; coverage_gate.dart exits 0 on every new file.
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

@lib/application/dual_ledger/providers.dart
@lib/application/family_sync/check_group_use_case.dart
@lib/application/voice/parse_voice_input_use_case.dart
@lib/infrastructure/i18n/formatters/date_formatter.dart
@lib/infrastructure/i18n/formatters/number_formatter.dart
@lib/infrastructure/i18n/models/locale_settings.dart
@lib/features/family_sync/presentation/providers/repository_providers.dart
@lib/features/family_sync/presentation/providers/sync_providers.dart
@lib/features/accounting/presentation/providers/voice_providers.dart
@lib/application/import_guard.yaml

<interfaces>
<!-- Templates the executor uses verbatim — note `app` prefix on all hoisted symbols -->

`lib/application/family_sync/repository_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../infrastructure/crypto/providers.dart' as crypto;
import '../../infrastructure/sync/apns_push_messaging_client.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/push_notification_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import '../../infrastructure/sync/websocket_service.dart';

part 'repository_providers.g.dart';

// All providers prefixed with `app` to eliminate symbol collision with feature-side
// definitions during Wave 2/3 coexistence (per Warning 7 fix). Plan 04-02 Task 5
// deletes the original (non-prefixed) feature-side definitions once consumers
// migrate.

@riverpod
ApnsPushMessagingClient appApnsPushMessagingClient(Ref ref) => ApnsPushMessagingClient(...);

@riverpod
E2EEService appE2eeService(Ref ref) => E2EEService(keyManager: ref.watch(crypto.keyManagerProvider));

@riverpod
PushNotificationService appPushNotificationService(Ref ref) => PushNotificationService(...);

@riverpod
RelayApiClient appRelayApiClient(Ref ref) => RelayApiClient(...);

@riverpod
SyncQueueManager appSyncQueueManager(Ref ref) => SyncQueueManager(...);

@riverpod
WebSocketService appWebSocketService(Ref ref) => WebSocketService(...);

// Re-export keyManagerProvider for feature consumption as `appKeyManagerProvider`
// (avoids two-hop import in features)
@riverpod
KeyManager appKeyManager(Ref ref) => ref.watch(crypto.keyManagerProvider);
```

`lib/application/i18n/formatter_service.dart`:
```dart
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../infrastructure/i18n/formatters/number_formatter.dart';

part 'formatter_service.g.dart';

class FormatterService {
  const FormatterService();
  String formatDate(DateTime date, Locale locale) => DateFormatter.formatDate(date, locale);
  String formatDateTime(DateTime dt, Locale locale) => DateFormatter.formatDateTime(dt, locale);
  String formatMonthYear(DateTime date, Locale locale) => DateFormatter.formatMonthYear(date, locale);
  String formatRelativeDate(DateTime date, Locale locale) => DateFormatter.formatRelativeDate(date, locale);
  String formatNumber(num n, Locale locale, {int decimals = 2}) => NumberFormatter.formatNumber(n, locale, decimals: decimals);
  String formatCurrency(num amount, String code, Locale locale) => NumberFormatter.formatCurrency(amount, code, locale);
  String formatPercentage(double v, Locale locale, {int decimals = 2}) => NumberFormatter.formatPercentage(v, locale, decimals: decimals);
  String formatCompact(num n, Locale locale) => NumberFormatter.formatCompact(n, locale);
}

// FormatterService has no infrastructure-side analog provider (it's new),
// so no prefix needed — single canonical name.
@riverpod
FormatterService formatterService(Ref ref) => const FormatterService();
```

`lib/application/ml/lookup_merchant_use_case.dart`:
```dart
import '../../infrastructure/ml/merchant_database.dart';

class LookupMerchantUseCase {
  LookupMerchantUseCase({required MerchantDatabase database}) : _database = database;
  final MerchantDatabase _database;

  Future<MerchantInfo?> execute(String text) async {
    try {
      return await _database.lookup(text);
    } catch (e) {
      return null;
    }
  }
}
```

`lib/application/voice/start_speech_recognition_use_case.dart`:
```dart
import '../../infrastructure/speech/speech_recognition_service.dart';

class StartSpeechRecognitionUseCase {
  StartSpeechRecognitionUseCase({required SpeechRecognitionService service}) : _service = service;
  final SpeechRecognitionService _service;

  Stream<String> execute({required String localeId}) => _service.startListening(localeId: localeId);
  Future<void> stop() => _service.stopListening();
}
```

`lib/application/i18n/locale_settings_view.dart`:
```dart
// Re-export wrapper so feature/presentation imports application/ instead of infrastructure/
export '../../infrastructure/i18n/models/locale_settings.dart';
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Create FormatterService + LocaleSettings re-export + tests</name>
  <files>lib/application/i18n/formatter_service.dart, lib/application/i18n/formatter_service.g.dart, lib/application/i18n/locale_settings_view.dart, test/unit/application/i18n/formatter_service_test.dart</files>
  <read_first>
    - lib/infrastructure/i18n/formatters/date_formatter.dart (full file — list all static methods to mirror)
    - lib/infrastructure/i18n/formatters/number_formatter.dart (full file — list all static methods to mirror)
    - lib/infrastructure/i18n/models/locale_settings.dart (full file — confirm exported symbols)
    - lib/application/dual_ledger/classification_service.dart (analog: instance class shape)
    - lib/application/import_guard.yaml (verify it allows infrastructure/**)
    - test/unit/application/family_sync/create_group_use_case_test.dart (Mocktail template; FormatterService has no mockable deps so tests directly exercise instance methods)
  </read_first>
  <behavior>
    - Test 1: `const FormatterService().formatDate(DateTime(2026, 4, 26), const Locale('ja'))` returns `'2026/04/26'`
    - Test 2: `const FormatterService().formatCurrency(1234, 'JPY', const Locale('ja'))` returns `'¥1,234'` (no decimals for JPY per project NumberFormatter spec)
    - Test 3: `const FormatterService().formatCurrency(1234.5, 'USD', const Locale('en'))` returns `'$1,234.50'` (2 decimals)
    - Test 4: `ProviderContainer().read(formatterServiceProvider)` returns a `FormatterService` instance; reading twice returns the SAME instance (const)
    - Test 5: `formatRelativeDate`, `formatMonthYear`, `formatPercentage`, `formatCompact`, `formatNumber`, `formatDateTime` each delegate correctly (one assertion per method)
  </behavior>
  <action>
    1. Create `lib/application/i18n/formatter_service.dart` per the `<interfaces>` template above. Mirror EVERY static method on `DateFormatter` (read step 1) and `NumberFormatter` (read step 2) as an instance method that delegates. Use `const FormatterService()` constructor. Add `@riverpod FormatterService formatterService(Ref ref) => const FormatterService();` at the bottom (no `app` prefix needed — FormatterService has no infrastructure analog).
    2. Run `flutter pub run build_runner build --delete-conflicting-outputs` to generate `formatter_service.g.dart`.
    3. Create `lib/application/i18n/locale_settings_view.dart` with the re-export line above. If `import_guard` rejects this re-export against the application allowlist (unlikely — Application IS allowed Infrastructure), replace with a thin Freezed model and a converter function.
    4. Create `test/unit/application/i18n/formatter_service_test.dart` per the Mocktail-only convention. Tests in `<behavior>` are direct instance method calls (no mocking — FormatterService has no constructor deps).
    5. Run `flutter test test/unit/application/i18n/formatter_service_test.dart` — must pass GREEN.

    Then commit:
    ```
    feat(04-01): add FormatterService + LocaleSettings re-export (HIGH-02 prep)
    ```
  </action>
  <verify>
    <automated>flutter test test/unit/application/i18n/formatter_service_test.dart 2>&amp;1 | tail -5</automated>
  </verify>
  <acceptance_criteria>
    - `lib/application/i18n/formatter_service.dart` exists with `class FormatterService` and `@riverpod FormatterService formatterService(Ref ref)`
    - `lib/application/i18n/formatter_service.g.dart` exists (generated)
    - `lib/application/i18n/locale_settings_view.dart` exists with `export '../../infrastructure/i18n/models/locale_settings.dart';`
    - `grep -c "String format" lib/application/i18n/formatter_service.dart` returns ≥8 (one per delegated static method)
    - `grep -c "const FormatterService" lib/application/i18n/formatter_service.dart` returns ≥1
    - `flutter test test/unit/application/i18n/formatter_service_test.dart` exits 0
    - `flutter analyze` exits 0
  </acceptance_criteria>
  <done>FormatterService scaffolding ready; tests GREEN; Plan 04-02 can route formatters through `formatterServiceProvider`.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Hoist sync-client + crypto + security DI providers into Application layer with `app` prefix (5 features)</name>
  <files>lib/application/family_sync/repository_providers.dart, lib/application/family_sync/repository_providers.g.dart, lib/application/accounting/repository_providers.dart, lib/application/accounting/repository_providers.g.dart, lib/application/analytics/repository_providers.dart, lib/application/analytics/repository_providers.g.dart, lib/application/profile/repository_providers.dart, lib/application/profile/repository_providers.g.dart, lib/application/settings/repository_providers.dart, lib/application/settings/repository_providers.g.dart, test/unit/application/family_sync/repository_providers_test.dart, test/unit/application/accounting/repository_providers_test.dart</files>
  <read_first>
    - lib/features/family_sync/presentation/providers/repository_providers.dart (full file — providers at lines 14-19 are the hoist targets: apnsPushMessagingClient, e2eeService, pushNotificationService, relayApiClient, syncQueueManager, webSocketService)
    - lib/features/accounting/presentation/providers/repository_providers.dart (full file — note infrastructure imports at lines 17-18)
    - lib/features/analytics/presentation/providers/repository_providers.dart (full file)
    - lib/features/profile/presentation/providers/user_profile_providers.dart (full file — note infrastructure/security/providers import at line 8)
    - lib/features/settings/presentation/providers/backup_providers.dart (full file)
    - lib/infrastructure/crypto/providers.dart (verify provider names: keyManagerProvider, etc.)
    - lib/infrastructure/security/providers.dart (verify provider names: appDatabaseProvider, etc.)
    - lib/application/family_sync/check_group_use_case.dart (analog for application-layer file shape — imports infrastructure freely)
  </read_first>
  <behavior>
    - Test 1: `ProviderContainer(overrides: [crypto.keyManagerProvider.overrideWithValue(_MockKeyManager())]).read(appRelayApiClientProvider)` returns a non-null `RelayApiClient`
    - Test 2: Similar for `appE2eeServiceProvider`, `appApnsPushMessagingClientProvider`, `appPushNotificationServiceProvider`, `appSyncQueueManagerProvider`, `appWebSocketServiceProvider`
    - Test 3: `ProviderContainer().read(appKeyManagerProvider)` (the application-layer re-export) returns the same instance as the overridden underlying crypto.keyManagerProvider
    - Test 4: Original (non-prefixed) feature-side providers remain functional during Wave 2/3 coexistence — `ProviderContainer().read(e2eeServiceProvider)` (the feature-side definition) still resolves correctly. Plan 04-02 Task 5 deletes the originals once consumers migrate to `app`-prefixed names.
  </behavior>
  <action>
    For EACH of 5 features (family_sync, accounting, analytics, profile, settings), create `lib/application/<feature>/repository_providers.dart` that hoists infrastructure-touching DI providers currently in the feature-side `repository_providers.dart` (or sibling files like `voice_providers.dart`).

    **Symbol naming convention — `app` prefix REQUIRED on all hoisted providers:** Per the Warning 7 fix, every provider hoisted in this task MUST use the `app` prefix in its function name (which generates an `app<Name>Provider` symbol via Riverpod codegen). This eliminates the library-level Riverpod symbol collision risk during Wave 2/3 coexistence (the original infrastructure-side definitions remain in feature/presentation files until Plan 04-02 Task 5 deletes them).

    **family_sync (largest hoist):** Create the 6 `app`-prefixed provider DEFINITIONS in `lib/application/family_sync/repository_providers.dart` — DO NOT delete the feature-side originals here (Plan 04-02 handles deletion after swapping callers):
    - `appApnsPushMessagingClientProvider` (function name: `appApnsPushMessagingClient`)
    - `appE2eeServiceProvider` (function name: `appE2eeService`)
    - `appPushNotificationServiceProvider` (function name: `appPushNotificationService`)
    - `appRelayApiClientProvider` (function name: `appRelayApiClient`)
    - `appSyncQueueManagerProvider` (function name: `appSyncQueueManager`)
    - `appWebSocketServiceProvider` (function name: `appWebSocketService`)

    Plus an `appKeyManager` re-export provider:
    ```dart
    @riverpod
    KeyManager appKeyManager(Ref ref) => ref.watch(crypto.keyManagerProvider);
    ```

    **accounting:** Hoist `appAppDatabase` re-export (function name `appAppDatabase`, symbol `appAppDatabaseProvider`) and `appKeyManager` re-export (function name `appKeyManager`, symbol `appKeyManagerProvider`). Both used by feature `repository_providers.dart` lines 17-18 — feature side still imports infrastructure for the originals during Wave 2/3 coexistence.

    **analytics:** Hoist `appAppDatabase` re-export.

    **profile:** Hoist `appAppDatabase` re-export and `appKeyManager` re-export.

    **settings:** Hoist `appAppDatabase` re-export.

    For each, run `flutter pub run build_runner build --delete-conflicting-outputs` to generate `.g.dart`.

    Write 2 representative tests:
    - `test/unit/application/family_sync/repository_providers_test.dart` — exercises all 6 hoisted `app`-prefixed providers via `ProviderContainer` with `_MockKeyManager` override; verifies each returns a non-null instance.
    - `test/unit/application/accounting/repository_providers_test.dart` — exercises the 1-2 hoisted `app`-prefixed re-exports.

    For analytics, profile, settings: covered via Plan 04-06 characterization tests + Plan 04-02 integration tests; coverage_gate.dart will verify ≥80%.

    Then commit (one feature per commit preferred for bisect):
    ```
    feat(04-01): hoist sync-client + crypto + security DI to lib/application/family_sync/repository_providers.dart with `app` prefix (HIGH-02 prep)
    feat(04-01): hoist app database + key manager re-exports to lib/application/accounting/repository_providers.dart with `app` prefix (HIGH-02 prep)
    feat(04-01): hoist app database re-export to lib/application/analytics/repository_providers.dart with `app` prefix (HIGH-02 prep)
    feat(04-01): hoist app database + key manager re-exports to lib/application/profile/repository_providers.dart with `app` prefix (HIGH-02 prep)
    feat(04-01): hoist app database re-export to lib/application/settings/repository_providers.dart with `app` prefix (HIGH-02 prep)
    ```

    NOTE: This task does NOT remove providers from the feature-side files. Plan 04-02 Task 5 handles the cleanup (delete from feature side after consumers swap to `app`-prefixed names). Until Plan 04-02 lands, both definitions coexist safely because the `app` prefix guarantees distinct Riverpod symbols at library level — no runtime collision possible.
  </action>
  <verify>
    <automated>flutter test test/unit/application/family_sync/repository_providers_test.dart test/unit/application/accounting/repository_providers_test.dart 2>&amp;1 | tail -10; flutter analyze 2>&amp;1 | tail -3; grep -c "^@riverpod" lib/application/family_sync/repository_providers.dart</automated>
  </verify>
  <acceptance_criteria>
    - `lib/application/family_sync/repository_providers.dart` exists with at least 6 `@riverpod` declarations all using `app`-prefixed function names (`appApnsPushMessagingClient`, `appE2eeService`, `appPushNotificationService`, `appRelayApiClient`, `appSyncQueueManager`, `appWebSocketService`) plus the `appKeyManager` re-export
    - `grep -c "appE2eeService\|appRelayApiClient\|appWebSocketService\|appPushNotificationService\|appApnsPushMessagingClient\|appSyncQueueManager" lib/application/family_sync/repository_providers.dart` returns ≥6
    - `lib/application/accounting/repository_providers.dart` exists with `app`-prefixed `@riverpod` re-exports
    - `lib/application/analytics/repository_providers.dart`, `lib/application/profile/repository_providers.dart`, `lib/application/settings/repository_providers.dart` all exist with at least 1 `app`-prefixed `@riverpod` declaration each
    - All 5 `.g.dart` files exist (generated)
    - `grep -c "infrastructure/" lib/application/family_sync/repository_providers.dart` returns ≥6 (Application is permitted Infrastructure)
    - `flutter analyze` exits 0
    - `flutter test test/unit/application/family_sync/repository_providers_test.dart test/unit/application/accounting/repository_providers_test.dart` exits 0
  </acceptance_criteria>
  <done>5 new application-layer repository_providers.dart files exist with `app`-prefixed providers; all .g.dart generated; tests GREEN; Plan 04-02 can swap feature-side imports to `app`-prefixed names then Task 5 deletes the originals.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: ML + voice + dual_ledger + home repository_providers.dart + 4 new use cases + dual_ledger rename (all hoisted providers use `app` prefix)</name>
  <files>lib/application/ml/lookup_merchant_use_case.dart, lib/application/ml/repository_providers.dart, lib/application/ml/repository_providers.g.dart, lib/application/voice/start_speech_recognition_use_case.dart, lib/application/voice/repository_providers.dart, lib/application/voice/repository_providers.g.dart, lib/application/family_sync/notify_member_approval_use_case.dart, lib/application/family_sync/listen_to_push_notifications_use_case.dart, lib/application/dual_ledger/repository_providers.dart, lib/application/dual_ledger/repository_providers.g.dart, lib/application/dual_ledger/providers.dart, lib/application/dual_ledger/providers.g.dart, lib/application/home/repository_providers.dart, lib/application/home/repository_providers.g.dart, test/unit/application/ml/lookup_merchant_use_case_test.dart, test/unit/application/voice/start_speech_recognition_use_case_test.dart, test/unit/application/family_sync/notify_member_approval_use_case_test.dart, test/unit/application/family_sync/listen_to_push_notifications_use_case_test.dart</files>
  <read_first>
    - lib/application/dual_ledger/providers.dart (full file — the rename source; note `ruleEngineProvider` keepAlive at line 9, `classificationServiceProvider` at line 14)
    - lib/infrastructure/ml/merchant_database.dart (read class signature for `lookup()` method)
    - lib/infrastructure/speech/speech_recognition_service.dart (read class signature for stream API)
    - lib/infrastructure/sync/relay_api_client.dart (read methods used by member_approval_screen)
    - lib/infrastructure/sync/websocket_service.dart (read methods used by member_approval_screen)
    - lib/infrastructure/sync/push_notification_service.dart (read stream API used by family_sync_notification_route_listener)
    - lib/features/family_sync/presentation/screens/member_approval_screen.dart (call sites for member-approval business action)
    - lib/features/family_sync/presentation/widgets/family_sync_notification_route_listener.dart (call sites for push notification listener)
    - lib/features/family_sync/presentation/providers/notification_navigation_provider.dart (call sites)
    - lib/features/accounting/presentation/providers/voice_providers.dart (note merchantDatabaseProvider keepAlive at lines 16-19 — preserve verbatim during hoist; rename to `appMerchantDatabase` per `app` prefix convention)
    - lib/features/home/presentation/providers/home_providers.dart, shadow_books_provider.dart, today_transactions_provider.dart (identify any infrastructure-touching providers to hoist)
    - lib/application/family_sync/check_group_use_case.dart (constructor injection + sealed result analog)
    - lib/application/voice/parse_voice_input_use_case.dart (analog wrapping MerchantDatabase)
  </read_first>
  <behavior>
    - Test 1 (LookupMerchantUseCase): given `_MockMerchantDatabase` returning `MerchantInfo(...)`, `useCase.execute('スターバックス')` returns the same instance
    - Test 2 (LookupMerchantUseCase): given `_MockMerchantDatabase` throwing, `useCase.execute(...)` returns null (graceful failure per parse_voice_input_use_case convention)
    - Test 3 (StartSpeechRecognitionUseCase): given `_MockSpeechRecognitionService` returning `Stream.fromIterable(['hello'])`, `useCase.execute(localeId: 'ja-JP')` emits `'hello'`
    - Test 4 (NotifyMemberApprovalUseCase): given mocked `RelayApiClient`+`WebSocketService`, `useCase.execute(memberId: '...')` calls each correctly (verify with mocktail `verify`)
    - Test 5 (ListenToPushNotificationsUseCase): given mocked `PushNotificationService` with stream, `useCase.execute()` returns the stream
    - Test 6 (`appMerchantDatabaseProvider` in ml/repository_providers.dart): `ProviderContainer().read(appMerchantDatabaseProvider)` returns same instance across two reads (keepAlive verification — Plan 04-05 hard list uses `appMerchantDatabaseProvider`)
    - Test 7 (dual_ledger repository_providers rename): `ruleEngineProvider` and `classificationServiceProvider` resolvable; same instance across reads where keepAlive applies
  </behavior>
  <action>
    1. **LookupMerchantUseCase** (`lib/application/ml/lookup_merchant_use_case.dart`): Use the `<interfaces>` template. Constructor takes `MerchantDatabase`. `execute(String text)` returns `Future<MerchantInfo?>`. Wrap in try/catch returning null on failure (per `parse_voice_input_use_case.dart` convention).

    2. **ml/repository_providers.dart**: hoist `merchantDatabaseProvider` from `lib/features/accounting/presentation/providers/voice_providers.dart` lines 16-19 with `app` prefix. **CRITICAL**: copy the `@Riverpod(keepAlive: true)` annotation verbatim — `merchantDatabaseProvider` is on the HIGH-05 hard list. The application-layer function is named `appMerchantDatabase` (generated symbol `appMerchantDatabaseProvider`). Plan 04-05's HIGH-05 hard list uses `appMerchantDatabaseProvider` (the original `merchantDatabaseProvider` is deleted by Plan 04-02 Task 5 once voice_providers.dart fold completes). Also add `@riverpod LookupMerchantUseCase lookupMerchantUseCase(Ref ref) => LookupMerchantUseCase(database: ref.watch(appMerchantDatabaseProvider));`.

    3. **StartSpeechRecognitionUseCase** (`lib/application/voice/start_speech_recognition_use_case.dart`): Use the `<interfaces>` template. Constructor takes `SpeechRecognitionService`. `execute({required String localeId})` returns `Stream<String>`. `stop()` returns `Future<void>`.

    4. **voice/repository_providers.dart**: hoist `speechRecognitionServiceProvider` (currently lives at `lib/features/accounting/presentation/screens/voice_input_screen.dart` line 13's import — actual provider definition may live in infrastructure or be inline; create a new `@riverpod SpeechRecognitionService appSpeechRecognitionService(Ref ref) => SpeechRecognitionService();`). Plus `@riverpod StartSpeechRecognitionUseCase startSpeechRecognitionUseCase(Ref ref) => StartSpeechRecognitionUseCase(service: ref.watch(appSpeechRecognitionServiceProvider));`.

    5. **NotifyMemberApprovalUseCase** (`lib/application/family_sync/notify_member_approval_use_case.dart`): Wraps the business action in `member_approval_screen.dart`. Read the screen first to identify the exact `RelayApiClient.approveMember(...)` + `WebSocketService.send(...)` calls. Constructor takes `RelayApiClient` and `WebSocketService`. `execute({required String memberId})` returns sealed result (see `check_group_use_case.dart` for pattern). Add provider entry in `lib/application/family_sync/repository_providers.dart` (extending Task 2's file): `@riverpod NotifyMemberApprovalUseCase notifyMemberApprovalUseCase(Ref ref) => NotifyMemberApprovalUseCase(apiClient: ref.watch(appRelayApiClientProvider), wsService: ref.watch(appWebSocketServiceProvider));`.

    6. **ListenToPushNotificationsUseCase** (`lib/application/family_sync/listen_to_push_notifications_use_case.dart`): Wraps the `PushNotificationService.notifications` stream API. Constructor takes `PushNotificationService`. `execute()` returns `Stream<PushNotification>`. Add provider entry in `lib/application/family_sync/repository_providers.dart`: `@riverpod ListenToPushNotificationsUseCase listenToPushNotificationsUseCase(Ref ref) => ListenToPushNotificationsUseCase(service: ref.watch(appPushNotificationServiceProvider));`.

    7. **dual_ledger rename** (`lib/application/dual_ledger/providers.dart` → `lib/application/dual_ledger/repository_providers.dart`):
       ```bash
       git mv lib/application/dual_ledger/providers.dart lib/application/dual_ledger/repository_providers.dart
       git mv lib/application/dual_ledger/providers.g.dart lib/application/dual_ledger/repository_providers.g.dart 2>/dev/null || true
       ```
       Edit the renamed file to update `part 'providers.g.dart';` → `part 'repository_providers.g.dart';`. Run `flutter pub run build_runner build --delete-conflicting-outputs`. Search for any imports of the old filename across `lib/` and `test/` and update them: `grep -rln "application/dual_ledger/providers.dart" lib/ test/` — update each match. Provider symbols inside (`ruleEngineProvider`, `classificationServiceProvider`) keep their original names — they are not duplicated in feature/presentation so no `app` prefix is needed (they were already application-layer pre-refactor).

    8. **home/repository_providers.dart**: minimal scaffold — read `lib/features/home/presentation/providers/home_providers.dart`, `shadow_books_provider.dart`, `today_transactions_provider.dart` to identify any infrastructure-touching providers. Hoist them with `app` prefix. If no infrastructure-touching providers exist (these home providers may bind to data/repository providers via feature-side `accounting/repository_providers.dart`), create the file with a comment explaining the intent and a single re-export of `appAppDatabaseProvider` if needed by `today_transactions_provider`.

    9. Run `flutter pub run build_runner build --delete-conflicting-outputs` once at the end to regenerate all `.g.dart` files cleanly.

    10. Write the 4 use case tests per `<behavior>` using Mocktail-only convention (no Mockito). Each test ≥30 lines, verifies happy path + 1 error/edge case minimum.

    11. Commit (one logical chunk per commit):
        ```
        feat(04-01): add LookupMerchantUseCase + ml/repository_providers.dart with appMerchantDatabaseProvider keepAlive (HIGH-02 prep, HIGH-05 preserve)
        feat(04-01): add StartSpeechRecognitionUseCase + voice/repository_providers.dart with `app` prefix (HIGH-02 prep)
        feat(04-01): add NotifyMemberApprovalUseCase + ListenToPushNotificationsUseCase (HIGH-02 prep)
        refactor(04-01): rename application/dual_ledger/providers.dart to repository_providers.dart (HIGH-04 naming consistency)
        feat(04-01): add home/repository_providers.dart with `app` prefix (HIGH-02 prep)
        ```
  </action>
  <verify>
    <automated>flutter test test/unit/application/ml/lookup_merchant_use_case_test.dart test/unit/application/voice/start_speech_recognition_use_case_test.dart test/unit/application/family_sync/notify_member_approval_use_case_test.dart test/unit/application/family_sync/listen_to_push_notifications_use_case_test.dart 2>&amp;1 | tail -10; grep -c "@Riverpod(keepAlive: true)" lib/application/ml/repository_providers.dart; grep -c "appMerchantDatabase" lib/application/ml/repository_providers.dart</automated>
  </verify>
  <acceptance_criteria>
    - `lib/application/ml/lookup_merchant_use_case.dart` exists with `class LookupMerchantUseCase`
    - `lib/application/ml/repository_providers.dart` exists; `grep "@Riverpod(keepAlive: true)" lib/application/ml/repository_providers.dart` returns ≥1 (appMerchantDatabaseProvider keepAlive preserved)
    - `grep "appMerchantDatabase" lib/application/ml/repository_providers.dart` returns ≥1 (function name uses `app` prefix)
    - `lib/application/voice/start_speech_recognition_use_case.dart` exists with `class StartSpeechRecognitionUseCase`
    - `lib/application/voice/repository_providers.dart` exists with `appSpeechRecognitionService` provider
    - `lib/application/family_sync/notify_member_approval_use_case.dart` exists
    - `lib/application/family_sync/listen_to_push_notifications_use_case.dart` exists
    - `lib/application/dual_ledger/providers.dart` does NOT exist on disk (renamed)
    - `lib/application/dual_ledger/repository_providers.dart` exists with `ruleEngineProvider` and `classificationServiceProvider` (no `app` prefix needed — these were already application-layer pre-refactor)
    - `lib/application/home/repository_providers.dart` exists
    - `grep -rln "application/dual_ledger/providers.dart" lib/ test/` returns 0 matches (all callers updated)
    - `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits 0 (clean diff)
    - `flutter test test/unit/application/ml/lookup_merchant_use_case_test.dart test/unit/application/voice/start_speech_recognition_use_case_test.dart test/unit/application/family_sync/notify_member_approval_use_case_test.dart test/unit/application/family_sync/listen_to_push_notifications_use_case_test.dart` exits 0
    - `flutter analyze` exits 0
  </acceptance_criteria>
  <done>4 new use cases + 4 new repository_providers.dart files + dual_ledger rename complete; all tests GREEN; appMerchantDatabaseProvider keepAlive preserved (Plan 04-05 hard list updated to `appMerchantDatabaseProvider`).</done>
</task>

<task type="auto">
  <name>Task 4: Run full test suite + per-plan coverage gate (Plan 04-01 exit gate)</name>
  <files>(no files modified — verification only)</files>
  <read_first>
    - All files declared in this plan's `files_modified` frontmatter
    - scripts/coverage_gate.dart (verify CLI signature)
  </read_first>
  <action>
    Comprehensive verification pass:

    1. Run `flutter test` — entire suite must pass GREEN.
    2. Run `flutter analyze` — must exit 0.
    3. Run `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` — must exit 0 (no stale generated files; AUDIT-10 CI guardrail).
    4. Run coverage gate against ALL files in `files_modified` (excluding `.g.dart` which is auto-stripped by lcov filter):
       ```bash
       dart run scripts/coverage_gate.dart \
         --files lib/application/family_sync/repository_providers.dart,lib/application/accounting/repository_providers.dart,lib/application/analytics/repository_providers.dart,lib/application/profile/repository_providers.dart,lib/application/settings/repository_providers.dart,lib/application/dual_ledger/repository_providers.dart,lib/application/home/repository_providers.dart,lib/application/ml/lookup_merchant_use_case.dart,lib/application/ml/repository_providers.dart,lib/application/voice/start_speech_recognition_use_case.dart,lib/application/voice/repository_providers.dart,lib/application/family_sync/notify_member_approval_use_case.dart,lib/application/family_sync/listen_to_push_notifications_use_case.dart,lib/application/i18n/formatter_service.dart,lib/application/i18n/locale_settings_view.dart \
         --threshold 80 \
         --lcov coverage/lcov_clean.info
       ```
       MUST exit 0.

    5. If coverage_gate fails for any file, return to Tasks 1-3 and add coverage for the failing file(s) before this plan closes.

    No commit needed for this task — it's verification only.
  </action>
  <verify>
    <automated>flutter test 2>&amp;1 | tail -5; dart run scripts/coverage_gate.dart --files lib/application/i18n/formatter_service.dart,lib/application/ml/lookup_merchant_use_case.dart --threshold 80 --lcov coverage/lcov_clean.info 2>&amp;1 | tail -5</automated>
  </verify>
  <acceptance_criteria>
    - `flutter test` exits 0
    - `flutter analyze` exits 0
    - `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits 0
    - `dart run scripts/coverage_gate.dart --files <15 source files comma-separated> --threshold 80 --lcov coverage/lcov_clean.info` exits 0
  </acceptance_criteria>
  <done>Plan 04-01 exit gate satisfied; coverage_gate exits 0; Plan 04-02 (Wave 3) unblocked.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Application → Infrastructure | New application-layer files import infrastructure directly (5-layer rule permits). No NEW external trust boundary; this plan moves existing infrastructure DI from feature/ to application/ — same trust posture, different file location. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-04-01-01 | (n/a) | refactor | accept | STRIDE analysis: no new auth surface, no new IPC boundary, no new persisted secret, no new external input. Hoisting infrastructure DI from feature/ to application/ preserves existing trust boundaries (the providers wrap the same infrastructure services with the same signatures). FormatterService is pure delegation to existing static functions — no new attack surface. New use cases (LookupMerchant, StartSpeechRecognition, NotifyMemberApproval, ListenToPushNotifications) wrap existing infrastructure APIs with no behavior change. No HIGH-severity threats. |
</threat_model>

<verification>
- 13 new application-layer files + 1 rename committed
- All hoisted providers use `app` symbol prefix per Warning 7 fix (verifiable: `grep -c "appE2eeService\|appRelayApiClient\|appWebSocketService\|appPushNotificationService\|appApnsPushMessagingClient\|appSyncQueueManager\|appMerchantDatabase\|appAppDatabase\|appKeyManager\|appSpeechRecognitionService" lib/application/` returns ≥10)
- `flutter analyze` exits 0
- `flutter test` exits 0
- `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits 0
- coverage_gate.dart exits 0 against the 15 source files
- `appMerchantDatabaseProvider` retains `@Riverpod(keepAlive: true)` in `lib/application/ml/repository_providers.dart`
- `lib/application/dual_ledger/providers.dart` does NOT exist (renamed); no orphan imports remain
</verification>

<success_criteria>
- Application-layer scaffolding complete and consumable by Plan 04-02 (with `app`-prefixed symbols)
- Six HIGH-05 keepAlive providers — `appMerchantDatabaseProvider` preserved here (Plan 04-05 hard list updated); the other 5 preserved by Plan 04-02 during their feature-side moves
- All new use cases follow constructor-injection + sealed-result pattern
- FormatterService delegates correctly with const class instance + injectable provider
- coverage_gate.dart exits 0 on all new files
</success_criteria>

<output>
After completion, create `.planning/phases/04-high-fixes/04-01-SUMMARY.md` documenting:
- The 13 new files + 1 rename
- Mapping of which feature-side providers moved to which application-layer file (table format), including the `app`-prefix renaming (`e2eeServiceProvider` → `appE2eeServiceProvider`, etc.)
- Confirmation `appMerchantDatabaseProvider` keepAlive preserved verbatim (Plan 04-05 hard list updated to use this name)
- FormatterService method coverage (which static methods got delegated)
- Reference for Plan 04-02 to consume (file paths + `app`-prefixed provider names available)
</output>
</content>
</invoke>