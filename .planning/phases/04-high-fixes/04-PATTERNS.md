# Phase 4: HIGH Fixes — Pattern Map

**Mapped:** 2026-04-26
**Files analyzed:** ~80 (categorized below)
**Analogs found:** 8/8 file roles have strong existing analogs in the repo

> All file paths are relative to `/Users/xinz/Development/home-pocket-app/` unless absolute.
> All line ranges are inclusive.
> "Analog" = the existing file the new/edited file should mirror in form, imports, and conventions.

---

## File Classification

Phase 4 produces / edits files across 8 distinct roles. Each row maps to a Plan (04-01..04-06).

| New / Edited File (or class) | Role | Data Flow | Closest Analog | Match Quality | Plan |
|------------------------------|------|-----------|----------------|---------------|------|
| `lib/application/<feature>/repository_providers.dart` (NEW per feature) | application-layer DI hub | request-response (DI graph) | `lib/application/dual_ledger/providers.dart` | exact | 04-01 |
| `lib/application/family_sync/<verb>_use_case.dart` (NEW sync wrappers) | application-layer use case | event-driven / request-response | `lib/application/family_sync/check_group_use_case.dart` | exact | 04-01 |
| `lib/application/ml/lookup_merchant_use_case.dart` (NEW) | application-layer use case | request-response | `lib/application/voice/parse_voice_input_use_case.dart` | exact | 04-01 |
| `lib/application/voice/start_speech_recognition_use_case.dart` (NEW) | application-layer use case | streaming (speech callbacks) | `lib/application/family_sync/check_group_use_case.dart` | role-match | 04-01 |
| `lib/application/i18n/formatter_service.dart` (NEW injectable wrapper) | application-layer service | pure function wrap | `lib/application/dual_ledger/classification_service.dart` (instance class), wraps `lib/infrastructure/i18n/formatters/{date,number}_formatter.dart` static facade | role-match | 04-01 |
| `lib/features/*/presentation/screens/*.dart` (~33 files) — **edit** | presentation refactor (replace `infrastructure/` import with `application/`) | request-response | `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` (already uses `categoryServiceProvider` correctly — template for the rest) | exact | 04-02 |
| `state_*.dart` rename targets (10+ files) — **rename + content split** | presentation provider (notifier/state) | event-driven / state | `lib/features/dual_ledger/presentation/providers/ledger_providers.dart` (clean Notifier-only file, no DI mixed in) | exact | 04-02 |
| `lib/features/*/presentation/providers/repository_providers.dart` (CONSOLIDATE existing) | presentation DI consolidation | request-response | `lib/features/accounting/presentation/providers/repository_providers.dart` (already canonical shape — keep, fold neighbours into it) | exact | 04-02 |
| `lib/features/*/presentation/import_guard.yaml` — **edit existing** (deny `infrastructure/**` strict) | architecture rule | static config | `lib/features/accounting/domain/import_guard.yaml` (parent-deny pattern with `inherit: true`) — current `presentation/import_guard.yaml` files are partial denies; tighten to full `infrastructure/**` deny per D-03 | role-match | 04-02 |
| `test/architecture/presentation_layer_rules_test.dart` (NEW) | architecture test | file-I/O parse YAML | `test/architecture/domain_import_rules_test.dart` (Phase 3 D-03 — same per-feature loop, same `loadYaml`+`expect(deny, containsAll(...))` shape) | exact | 04-02 |
| DELETE `lib/application/dual_ledger/resolve_ledger_type_service.dart` + 5 cascading sites | dead-code deletion | n/a | (no analog needed — delete-only; mirror Phase 3 D-09/D-10 6-commit pattern) | n/a | 04-03 |
| Mocktail inline fakes in 13 `*_test.dart` files (Mockito → Mocktail migration) | test fake migration | n/a | `test/core/initialization/app_initializer_test.dart` (Phase 3 D-15: `class _Fake<X> extends Mock implements X`) AND `test/unit/application/family_sync/create_group_use_case_test.dart` (Mocktail-only test, no `*.mocks.dart` companion) | exact | 04-04 |
| `test/architecture/provider_graph_hygiene_test.dart` (NEW) | architecture test | file-I/O parse `@riverpod` annotations | `test/architecture/domain_import_rules_test.dart` | role-match | 04-05 |
| Characterization tests (~30–50 new test files) | test (unit/widget) | n/a | `test/unit/application/family_sync/create_group_use_case_test.dart` (Mocktail-only template) | exact | 04-06 |

---

## Pattern Assignments

### 1. `lib/application/<feature>/repository_providers.dart` (NEW — Plan 04-01)

**Role:** application-layer DI hub that hoists infrastructure-touching providers (sync clients, crypto providers, push messaging, merchant DB, speech service) so feature `presentation/` no longer imports `infrastructure/`.

**Analog:** `lib/application/dual_ledger/providers.dart` (the only existing application-layer providers file; pattern Phase 4 generalizes).

**Imports + provider declaration pattern** (`lib/application/dual_ledger/providers.dart` lines 1–18):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'classification_service.dart';
import 'rule_engine.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
RuleEngine ruleEngine(Ref ref) {
  return RuleEngine();
}

@riverpod
ClassificationService classificationService(Ref ref) {
  final ruleEngine = ref.watch(ruleEngineProvider);
  return ClassificationService(ruleEngine: ruleEngine);
}
```

**Delta from analog (what's new):**
- The new file may import directly from `lib/infrastructure/...` (Application layer is permitted Infrastructure access by the 5-layer rule and `lib/application/import_guard.yaml`).
- Hoists what currently lives in `lib/features/family_sync/presentation/providers/repository_providers.dart` lines 14–19 (`apns_push_messaging_client`, `e2ee_service`, `push_notification_service`, `relay_api_client`, `sync_queue_manager`, `websocket_service`) into `lib/application/family_sync/repository_providers.dart`.
- Six providers must retain `@Riverpod(keepAlive: true)` (HIGH-05 hard list — see Shared Patterns §B): `syncEngineProvider`, `transactionChangeTrackerProvider`, `merchantDatabaseProvider`, `activeGroupProvider`, `activeGroupMembersProvider`, `ledgerProvider`. Of those, `syncEngineProvider` and `transactionChangeTrackerProvider` migrate from `lib/features/family_sync/presentation/providers/sync_providers.dart` lines 117–151 — copy the `@Riverpod(keepAlive: true)` annotation verbatim.
- Generated `.g.dart` is created by `flutter pub run build_runner build --delete-conflicting-outputs` (do NOT hand-write).

**Naming collision is by-path not by-symbol** (CONTEXT.md `<specifics>`): the application-side `lib/application/family_sync/repository_providers.dart` and feature-side `lib/features/family_sync/presentation/providers/repository_providers.dart` coexist; symbol names differ; imports must spell out the full path.

**Reconciliation per feature** (planner picks):
- `dual_ledger`: a `lib/application/dual_ledger/providers.dart` already exists (the analog above). Either rename to `repository_providers.dart` OR extend the existing file. Per D-04 the standard name is `repository_providers.dart`, but the rename touches generated code — planner decides at file-by-file granularity (CONTEXT.md `<decisions>` "Claude's Discretion" item 7).

---

### 2. `lib/application/family_sync/<verb>_use_case.dart` (NEW — Plan 04-01)

**Role:** application-layer use case that wraps a sync-client business action so screens stop calling `RelayApiClient` / `KeyManager` / `E2EEService` directly.

**Analog:** `lib/application/family_sync/check_group_use_case.dart` (one of 22 use cases; representative sealed-result + DI-by-constructor pattern).

**Sealed result class pattern** (`lib/application/family_sync/check_group_use_case.dart` lines 10–28):
```dart
sealed class CheckGroupResult {
  const CheckGroupResult();
}

class CheckGroupInGroup extends CheckGroupResult {
  const CheckGroupInGroup({required this.groupId});
  final String groupId;
}

class CheckGroupNotInGroup extends CheckGroupResult {
  const CheckGroupNotInGroup();
}

class CheckGroupError extends CheckGroupResult {
  const CheckGroupError(this.message);
  final String message;
}
```

**Use case class pattern (constructor injection + try/catch + execute)** (`lib/application/family_sync/check_group_use_case.dart` lines 30–47, 112–117):
```dart
class CheckGroupUseCase {
  CheckGroupUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
    required GroupRepository groupRepository,
  }) : _apiClient = apiClient,
       _keyManager = keyManager,
       _groupRepository = groupRepository;

  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final GroupRepository _groupRepository;

  Future<CheckGroupResult> execute() async {
    try {
      // ...business logic calling _apiClient / _keyManager / _groupRepository...
    } on RelayApiException catch (error) {
      return CheckGroupError(error.message);
    } catch (error) {
      return CheckGroupError('Failed to check group: $error');
    }
  }
}
```

**Imports pattern (note Application IS allowed to import Infrastructure)** (`lib/application/family_sync/check_group_use_case.dart` lines 1–8):
```dart
import 'dart:io';

import '../../infrastructure/crypto/models/device_key_pair.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
```

**New use case naming convention:** verb + noun + `UseCase` (existing convention across all 22 family_sync use cases). Per CONTEXT.md "Claude's Discretion" item 2: planner picks names like `LookupMerchantUseCase` vs `FindMerchantByVoiceUseCase` based on the in-screen call site verb.

---

### 3. `lib/application/ml/lookup_merchant_use_case.dart` (NEW — Plan 04-01)

**Role:** application-layer use case wrapping `MerchantDatabase.lookup()` for screens that currently call `infrastructure/ml/merchant_database.dart` directly.

**Analog:** `lib/application/voice/parse_voice_input_use_case.dart` (existing application-layer use case that ALREADY consumes `MerchantDatabase`; its DI pattern is the closest match).

**Constructor + execute pattern** (`lib/application/voice/parse_voice_input_use_case.dart` lines 14–30):
```dart
class ParseVoiceInputUseCase {
  final VoiceTextParser _textParser;
  final FuzzyCategoryMatcher _fuzzyCategoryMatcher;
  final MerchantDatabase _merchantDatabase;

  ParseVoiceInputUseCase({
    required VoiceTextParser textParser,
    required FuzzyCategoryMatcher fuzzyCategoryMatcher,
    required MerchantDatabase merchantDatabase,
  }) : _textParser = textParser,
       _fuzzyCategoryMatcher = fuzzyCategoryMatcher,
       _merchantDatabase = merchantDatabase;

  Future<Result<VoiceParseResult>> execute(String recognizedText) async {
    try {
      // ...
    } catch (e) {
      return Result.error('Voice parse failed: $e');
    }
  }
}
```

**Note on `MerchantDatabase` provider:** Currently lives at `lib/features/accounting/presentation/providers/voice_providers.dart` lines 16–19 with `@Riverpod(keepAlive: true)`. Per HIGH-05 it MUST retain keepAlive. After Plan 04-02 it moves to `lib/application/ml/repository_providers.dart` (or equivalent) keeping the keepAlive annotation verbatim.

---

### 4. `lib/application/i18n/formatter_service.dart` (NEW — Plan 04-01)

**Role:** Application-layer injectable wrapper around `infrastructure/i18n/formatters/{date,number}_formatter.dart` (which remain as static implementations — see CONTEXT.md `<specifics>` final bullet).

**Analog (instance-class shape):** `lib/application/dual_ledger/classification_service.dart` (an Application service class with a single constructor and `execute`-style method) — but the FormatterService is thinner because it just delegates to static functions.

**Static implementation it wraps** (`lib/infrastructure/i18n/formatters/date_formatter.dart` lines 1–18):
```dart
import 'dart:ui';
import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDate(DateTime date, Locale locale) {
    switch (locale.languageCode) {
      case 'ja':  return DateFormat('yyyy/MM/dd', locale.toString()).format(date);
      case 'zh':  return DateFormat('yyyy年MM月dd日', locale.toString()).format(date);
      case 'en':  default: return DateFormat('MM/dd/yyyy', locale.toString()).format(date);
    }
  }
  // ... formatDateTime, formatMonthYear, formatRelative
}
```

**And** `lib/infrastructure/i18n/formatters/number_formatter.dart` lines 1–25:
```dart
class NumberFormatter {
  NumberFormatter._();

  static String formatNumber(num number, Locale locale, {int decimals = 2}) { ... }
  static String formatCurrency(num amount, String currencyCode, Locale locale) { ... }
  static String formatPercentage(double value, Locale locale, {int decimals = 2}) { ... }
  static String formatCompact(num number, Locale locale) { ... }
}
```

**FormatterService instance shape (planner derives — recommended):**
```dart
import 'dart:ui';
import '../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../infrastructure/i18n/formatters/number_formatter.dart';

class FormatterService {
  const FormatterService();

  String formatDate(DateTime date, Locale locale) =>
      DateFormatter.formatDate(date, locale);

  String formatCurrency(num amount, String currencyCode, Locale locale) =>
      NumberFormatter.formatCurrency(amount, currencyCode, locale);

  // ... mirror all static methods as instance methods
}
```

**Provider (planner adds — paired in `lib/application/i18n/repository_providers.dart` or this file's own `part 'formatter_service.g.dart'`):**
```dart
@riverpod
FormatterService formatterService(Ref ref) => const FormatterService();
```

**Per CONTEXT.md "Claude's Discretion" item 3:** planner decides class-with-methods vs Riverpod-provider-only "facade module" — instance state is NOT needed for formatters (all underlying functions are pure), so a const class with methods is the lightest correct shape.

**Also wraps** `lib/infrastructure/i18n/models/locale_settings.dart` (currently imported directly by `lib/features/settings/presentation/providers/locale_provider.dart` line 6 and `lib/features/settings/presentation/widgets/appearance_section.dart` line 5). Per CONTEXT.md `<decisions>` D-02 (c): `LocaleSettings` "routes via the same pattern" — re-export from application layer or wrap in a thin application-layer `LocaleSettings` model.

---

### 5. Presentation refactor — replace `infrastructure/` import with `application/` (Plan 04-02)

**Role:** edit each of the ~33 presentation files to call use cases / formatter service / hoisted DI providers instead of importing `infrastructure/...` directly.

**Analog (post-conversion shape):** `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` already uses `categoryServiceProvider` correctly via:
```dart
import '../../../../application/accounting/create_transaction_use_case.dart';
// ... no infrastructure import for category lookup
```
The screen DOES still illegally import `infrastructure/i18n/formatters/{date,number}_formatter.dart` (lines 11–12) — those are the lines Plan 04-02 replaces with the new `formatterService` provider.

**The 33 illegal infrastructure imports** (full list from `grep -rn "^import.*infrastructure" lib/features --include="*.dart"`):

| Sub-pattern | Files | Routing target |
|-------------|-------|----------------|
| **(a) i18n formatters** (`infrastructure/i18n/formatters/{date,number}_formatter.dart`) | `accounting/presentation/screens/{transaction_confirm,voice_input,transaction_entry}_screen.dart`, `accounting/presentation/widgets/transaction_list_tile.dart`, `analytics/presentation/screens/analytics_screen.dart` | `ref.watch(formatterServiceProvider).formatDate(...)` |
| **(a') locale_settings model** (`infrastructure/i18n/models/locale_settings.dart`) | `settings/presentation/providers/locale_provider.dart`, `settings/presentation/widgets/appearance_section.dart` | application-layer re-export of `LocaleSettings` |
| **(b) crypto/security/sync providers** (DI wiring) | `accounting/.../{repository,use_case,voice}_providers.dart`, `family_sync/.../{repository,sync,group}_providers.dart`, `family_sync/presentation/screens/{create_group,member_approval}_screen.dart`, `family_sync/presentation/widgets/family_sync_notification_route_listener.dart`, `family_sync/presentation/providers/notification_navigation_provider.dart`, `profile/presentation/providers/user_profile_providers.dart`, `analytics/presentation/providers/repository_providers.dart`, `analytics/presentation/screens/analytics_screen.dart` | hoisted `lib/application/<feature>/repository_providers.dart` (Plan 04-01) |
| **(c) direct service classes** (`infrastructure/category/category_service.dart`) | `accounting/presentation/screens/{category_selection,transaction_form}_screen.dart`, `accounting/presentation/utils/category_display_utils.dart`, `home/presentation/screens/home_screen.dart` | wrapped use case in `lib/application/dual_ledger/`/`lib/application/accounting/` (note: `lib/application/accounting/category_service.dart` already exists — these screens may simply switch to `categoryServiceProvider` from `use_case_providers.dart`) |
| **(d) sync clients in screens** (`infrastructure/sync/{relay_api_client,websocket_service,push_notification_service}.dart`) | `family_sync/presentation/screens/{create_group,member_approval}_screen.dart`, `family_sync/presentation/widgets/family_sync_notification_route_listener.dart`, `family_sync/presentation/providers/notification_navigation_provider.dart` | new `*_use_case.dart` (Plan 04-01 b) |
| **(e) speech service in screen** (`infrastructure/speech/speech_recognition_service.dart`) | `accounting/presentation/screens/voice_input_screen.dart` | new `start_speech_recognition_use_case.dart` (Plan 04-01) |

**Edit pattern (before / after):**
```dart
// BEFORE (transaction_confirm_screen.dart line 11)
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
// ... in build():
DateFormatter.formatDate(_date, locale)

// AFTER
import '../../../../application/i18n/formatter_service.dart';
// ... in build():
ref.watch(formatterServiceProvider).formatDate(_date, locale)
```

---

### 6. `state_*.dart` rename targets — restructure presentation/providers (Plan 04-02)

**Role:** `lib/features/<f>/presentation/providers/` should contain ONLY two file-name shapes after Plan 04-02 (per D-05):
- `repository_providers.dart` (single file per feature, all DI providers)
- `state_<concept>.dart` (N files per feature, one notifier/state provider concept each)

**Analog (clean Notifier-only file):** `lib/features/dual_ledger/presentation/providers/ledger_providers.dart` — after rename it becomes `state_ledger.dart`. Current shape (lines 1–20):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/accounting/domain/models/transaction.dart';

part 'ledger_providers.g.dart';

/// Current ledger tab selection.
@Riverpod(keepAlive: true)
class LedgerView extends _$LedgerView {
  @override
  LedgerType build() => LedgerType.survival;

  void switchTo(LedgerType type) => state = type;

  void toggle() {
    state = state == LedgerType.survival
        ? LedgerType.soul
        : LedgerType.survival;
  }
}
```
This is already the shape `state_*.dart` files take: single notifier, no DI providers mixed in. Note the `@Riverpod(keepAlive: true)` annotation must be preserved (HIGH-05 — `ledgerProvider` is on the hard list).

**Rename mapping (per CONTEXT.md D-06):**

| Current file | After rename | Action | Notes |
|--------------|--------------|--------|-------|
| `accounting/.../voice_providers.dart` | `state_voice.dart` | rename + DI fold (DI part: `merchantDatabaseProvider` keepAlive moves to repository_providers.dart) | DI providers (`merchantDatabaseProvider` lines 16–19, `voiceTextParser`, `fuzzyCategoryMatcher`, `parseVoiceInputUseCase`, `voiceSatisfactionEstimator`) fold into `repository_providers.dart`. State portion is a notifier (none currently — file may be deleted post-fold). |
| `accounting/.../use_case_providers.dart` | DELETE (fold into repository_providers.dart) | fold | Per D-06: "fold contents into repository_providers.dart; delete file". 8 providers move. |
| `accounting/.../category_reorder_notifier.dart` | `state_category_reorder.dart` | pure rename | Already clean Notifier (`CategoryReorderNotifier extends _$CategoryReorderNotifier`); zero DI — straight rename. |
| `family_sync/.../active_group_provider.dart` | `state_active_group.dart` | pure rename | `activeGroupProvider` is on the HIGH-05 keepAlive hard list — preserve `@Riverpod(keepAlive: true)` (lines 13, 22 of analog). |
| `family_sync/.../notification_navigation_provider.dart` | `state_notification_navigation.dart` | pure rename + import-replace | StateNotifierProvider; the `infrastructure/sync/push_notification_service` import (line 5) routes through new use case (Plan 04-01). |
| `family_sync/.../sync_providers.dart` | split: DI → `repository_providers.dart`, state → `state_sync.dart` | split | `pushSyncUseCase`, `pullSyncUseCase`, `shadowBookService`, `applySyncOperationsUseCase`, `checkGroupValidityUseCase`, `fullSyncUseCase`, `syncOrchestrator`, `handleMemberLeftUseCase`, `handleGroupDissolvedUseCase` are DI → fold into `repository_providers.dart`. `transactionChangeTrackerProvider` (line 118 keepAlive — HIGH-05), `syncEngineProvider` (line 141 keepAlive — HIGH-05), `syncStatusStream`, `groupMembers` are state/stream → `state_sync.dart`. |
| `family_sync/.../group_providers.dart` | split: DI → `repository_providers.dart`, state → `state_group.dart` | split | All 9 providers in current file are use-case providers (DI) → fold to `repository_providers.dart`. No state notifier — `state_group.dart` may not exist if all are DI. |
| `family_sync/.../avatar_sync_providers.dart` | split per same rule | split | `syncAvatarUseCaseProvider` is DI → fold. |
| `dual_ledger/.../ledger_providers.dart` | `state_ledger.dart` | pure rename | `LedgerView` is notifier; preserve `@Riverpod(keepAlive: true)` (line 8 — HIGH-05 hard list). |
| `home/.../today_transactions_provider.dart` | `state_today_transactions.dart` | rename | `Future<List<Transaction>> todayTransactions` is async data — categorize as state. |
| `home/.../home_providers.dart` | `state_home.dart` (or `state_selected_tab.dart`) | rename | `SelectedTabIndex` notifier with `@Riverpod(keepAlive: true)` — single concept; planner picks more specific name. |
| `home/.../shadow_books_provider.dart` | `state_shadow_books.dart` | rename | Async providers (`shadowBooks`, `shadowAggregate`) — state. |
| `profile/.../user_profile_providers.dart` | split: DI → `repository_providers.dart`, state → `state_user_profile.dart` | split | `userProfileDao`, `userProfileRepository`, `getUserProfileUseCase`, `saveUserProfileUseCase` are DI → fold. `userProfile` (`Future<UserProfile?>`) is state → `state_user_profile.dart`. |
| `settings/.../locale_provider.dart` | `state_locale.dart` | rename + import-replace | `LocaleNotifier` is the Notifier; `infrastructure/i18n/models/locale_settings` import (line 6) routes through application-layer wrapper (Plan 04-01). |
| `settings/.../settings_providers.dart` | split | split | `appSettings` (Future) and `voiceLocaleId` are state → `state_settings.dart`. `voiceLocaleIdFromLanguageCode` is a public top-level function — leaves the providers tree, can stay where it is or move to `lib/shared/`. |
| `settings/.../backup_providers.dart` | DI fold | fold | All 3 providers (`exportBackupUseCase`, `importBackupUseCase`, `clearAllDataUseCase`) are DI → `repository_providers.dart`. |
| `analytics/.../analytics_providers.dart` | split per same rule | split (planner reads file) | (file not read here — planner inspects during plan-write). |

**Per CONTEXT.md "Claude's Discretion" item 1:** the exact split point for `sync_providers.dart` / `group_providers.dart` / `avatar_sync_providers.dart` / `home_providers.dart` between DI fold and `state_*.dart` rename — planner determines per provider after reading each file.

---

### 7. `lib/features/<f>/presentation/repository_providers.dart` (CONSOLIDATE existing — Plan 04-02)

**Role:** the SINGLE feature-side DI hub per feature. Existing files already follow the canonical shape; Plan 04-02 folds neighbouring DI providers into them and deletes the now-empty source files.

**Analog (canonical shape):** `lib/features/accounting/presentation/providers/repository_providers.dart` (already exists, 93 lines, pure DI).

**Imports + DI provider declaration pattern** (`lib/features/accounting/presentation/providers/repository_providers.dart` lines 1–35):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/daos/book_dao.dart';
// ... data DAO imports
import '../../../../data/repositories/book_repository_impl.dart';
// ... data repository impl imports
import '../../../../infrastructure/crypto/providers.dart';     // <-- Plan 04-02 REMOVES
import '../../../../infrastructure/security/providers.dart';   // <-- Plan 04-02 REMOVES (replaced with application-layer hoisted equiv)
import '../../domain/repositories/book_repository.dart';
// ... domain repo interface imports

part 'repository_providers.g.dart';

/// BookRepository provider.
@riverpod
BookRepository bookRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = BookDao(database);
  return BookRepositoryImpl(dao: dao);
}
```

**Deltas Plan 04-02 applies:**
- Remove `infrastructure/` imports (lines 17–18 of analog).
- Replace `ref.watch(appDatabaseProvider)` and `ref.watch(keyManagerProvider)` etc. with the same providers re-exported from `lib/application/<feature>/repository_providers.dart` (Plan 04-01 may re-export them or split out a separate `application/data_providers.dart`).
- **Note:** `appDatabaseProvider` and `keyManagerProvider` currently live in `infrastructure/security/providers.dart` and `infrastructure/crypto/providers.dart` — they are infrastructure concerns. Per the 5-layer rule the FEATURE side cannot import these directly; the application-layer `repository_providers.dart` (Plan 04-01) imports them and re-exports / wraps them.
- Fold use-case providers from sibling files (`use_case_providers.dart`, `voice_providers.dart` DI portion, etc.) into THIS file.

---

### 8. `lib/features/<f>/presentation/import_guard.yaml` (EDIT existing — Plan 04-02)

**Role:** tighten the existing per-feature presentation `import_guard.yaml` to deny ALL of `infrastructure/**` (current denies are partial: only specific subpackages).

**Analog (current state of all 6 files — all identical, e.g.,** `lib/features/accounting/presentation/import_guard.yaml`):
```yaml
# Presentation layer — uses Application + Domain + Infrastructure (indirect via app uses cases).
# MUST NOT reach Infrastructure directly (HIGH-02 territory per .planning/codebase/CONCERNS.md).
deny:
  - package:home_pocket/data/tables/**
  - package:home_pocket/data/daos/**
  - package:home_pocket/infrastructure/crypto/services/**
  - package:home_pocket/infrastructure/sync/**
  - package:home_pocket/infrastructure/security/secure_storage_service.dart
  - package:home_pocket/infrastructure/crypto/repositories/**

inherit: true
```

**Reference deny-pattern (full strict deny):** `lib/features/accounting/domain/import_guard.yaml` lines 7–14:
```yaml
deny:
  - package:home_pocket/data/**
  - package:home_pocket/infrastructure/**
  - package:home_pocket/application/**
  - package:home_pocket/features/**/presentation/**
  - package:flutter/**

inherit: true
```

**Plan 04-02 edit (per D-03):** broaden each `presentation/import_guard.yaml` deny to `package:home_pocket/infrastructure/**` (single line replaces all 4 partial entries). Optionally add an `allow:` allowlist (per D-03: `application/**`, `<self-feature>/domain/**`, `<self-feature>/presentation/**`, `core/**`, `shared/**`, `l10n/**`, `generated/**`, `dart:**`, `package:flutter/**`, `package:flutter_riverpod/**`, `package:riverpod_annotation/**`, `package:freezed_annotation/**`, `package:go_router/**`, `package:intl/**` for screens that format inline, etc.). Per CONTEXT.md "Claude's Discretion" item 5: planner derives the exact allowlist from the compiled list of legitimate imports across the post-refactor codebase.

**Reference for allow-block placement** (parent owns deny, children own whitelist) — `lib/features/accounting/domain/import_guard.yaml` line 14 (`# NOTE: no allow: block — see models/import_guard.yaml and repositories/import_guard.yaml`). Plan 04-02 may apply the same split: `presentation/import_guard.yaml` denies, `presentation/screens/import_guard.yaml` (if needed) allows screen-specific deps.

**Critical sequencing per D-20:** the new yaml lands in the SAME commit as the resolved violations, never standalone. Each Plan 04-02 sub-commit resolves a feature's presentation→infrastructure violations, then in the same commit tightens that feature's `presentation/import_guard.yaml`. CI never sees a broken state because `import_guard` is already blocking (Phase 3 D-17).

---

### 9. `test/architecture/presentation_layer_rules_test.dart` (NEW — Plan 04-02)

**Role:** architecture meta-test that enforces the presentation `import_guard.yaml` rules cannot be weakened.

**Analog:** `test/architecture/domain_import_rules_test.dart` (Phase 3 D-03 — same per-feature loop, same assertion shape).

**Imports + per-feature loop pattern** (`test/architecture/domain_import_rules_test.dart` lines 14–55):
```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Domain layer import_guard rules', () {
    const features = [
      'accounting', 'analytics', 'family_sync', 'home', 'profile', 'settings',
    ];
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
          expect(deny, containsAll(requiredDeny),
              reason: 'Feature $feature: deny list weakened');
          expect(yaml['allow'], isNull, reason: '...');
          expect(yaml['inherit'], isTrue);
        });
        // ... models/ and repositories/ subdir tests
      });
    }
  });
}
```

**Plan 04-02 delta:** identical test scaffold but pointed at `lib/features/$feature/presentation/import_guard.yaml` and asserting the new `requiredDeny`:
```dart
const requiredDeny = [
  'package:home_pocket/infrastructure/**',
  // (whatever else is locked — per D-03)
];
```
Plus a `dual_ledger` feature entry (the existing test omits dual_ledger because it has no `domain/` subdir — but it does have `presentation/`).

---

### 10. `lib/application/dual_ledger/resolve_ledger_type_service.dart` DELETE (Plan 04-03)

**Role:** delete pure dead code (6-commit cascade per D-13).

**Analog (the file to delete):** `lib/application/dual_ledger/resolve_ledger_type_service.dart` (33 lines — read in full above):
```dart
@Deprecated('Use CategoryService instead')
class ResolveLedgerTypeService {
  ResolveLedgerTypeService({
    required CategoryRepository categoryRepository,
    required CategoryLedgerConfigRepository ledgerConfigRepository,
  }) : _delegate = CategoryService(...);

  final CategoryService _delegate;

  Future<LedgerType?> resolve(String categoryId) async => _delegate.resolveLedgerType(categoryId);
  Future<String?> resolveL1(String categoryId) async => _delegate.resolveL1(categoryId);
}
```

**Cascading 6 sites to delete** (per D-13):
1. `lib/application/dual_ledger/resolve_ledger_type_service.dart` (source — 33 lines)
2. `lib/features/accounting/presentation/providers/use_case_providers.dart` lines 13–14 (deprecated import) and lines 66–74 (`resolveLedgerTypeService` provider definition):
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
3. `lib/features/accounting/presentation/providers/use_case_providers.g.dart` (regenerate — drops `_$resolveLedgerTypeServiceHash`, `Provider<ResolveLedgerTypeService>`, `ResolveLedgerTypeServiceRef` typedef)
4. `test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart` (delete file)
5. `test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart` (delete file — also de-overlap with Plan 04-04 per D-14)
6. Verification commit (`flutter analyze` 0, `flutter test` GREEN, no orphan imports)

**Note for D-14 coordination:** Plan 04-04 ("13 fixtures") explicitly excludes the RLS-test mock because Plan 04-03 deletes it.

---

### 11. Mocktail inline fakes — Plan 04-04

**Role:** big-bang Mockito → Mocktail migration of 13 `*_test.dart` files (excluding `resolve_ledger_type_service_test.dart` deleted by 04-03).

**Analog A (hand-written fake style — Phase 3 D-15):** `test/core/initialization/app_initializer_test.dart` lines 13–15 + 48–66 + 99–112:
```dart
import 'package:mocktail/mocktail.dart';

class _FakeMasterKeyRepository extends Mock implements MasterKeyRepository {}

class _FakeKeyRepository extends Mock implements KeyRepository {}

void main() {
  late _FakeMasterKeyRepository fakeMasterKeyRepo;
  late _FakeKeyRepository fakeKeyRepo;

  setUp(() {
    fakeMasterKeyRepo = _FakeMasterKeyRepository();
    fakeKeyRepo = _FakeKeyRepository();

    // Happy-path defaults
    when(() => fakeMasterKeyRepo.hasMasterKey()).thenAnswer((_) async => true);
    when(() => fakeMasterKeyRepo.initializeMasterKey()).thenAnswer((_) async {});
    when(() => fakeKeyRepo.hasKeyPair()).thenAnswer((_) async => true);
    when(() => fakeKeyRepo.getDeviceId()).thenAnswer((_) async => 'device-1');
    // ...
  });

  test('does NOT call initializeMasterKey when key already exists', () async {
    when(() => fakeMasterKeyRepo.hasMasterKey()).thenAnswer((_) async => true);
    final result = await _makeInitializer().initialize();
    (result as InitSuccess).container.dispose();

    verifyNever(() => fakeMasterKeyRepo.initializeMasterKey());
  });

  test('calls initializeMasterKey when no key exists', () async {
    when(() => fakeMasterKeyRepo.hasMasterKey()).thenAnswer((_) async => false);
    // ...
    verify(() => fakeMasterKeyRepo.initializeMasterKey()).called(1);
  });
}
```

**Analog B (Mocktail-only test, no `*.mocks.dart` companion):** `test/unit/application/family_sync/create_group_use_case_test.dart` lines 1–50:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/create_group_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/models/device_key_pair.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}
class MockKeyManager extends Mock implements KeyManager {}
class MockGroupRepository extends Mock implements GroupRepository {}
class MockE2EEService extends Mock implements E2EEService {}

void main() {
  late MockRelayApiClient apiClient;
  late MockKeyManager keyManager;
  late MockGroupRepository groupRepository;
  late MockE2EEService e2eeService;
  late CreateGroupUseCase useCase;

  setUp(() {
    apiClient = MockRelayApiClient();
    // ...
    useCase = CreateGroupUseCase(
      apiClient: apiClient,
      keyManager: keyManager,
      groupRepository: groupRepository,
      e2eeService: e2eeService,
    );

    when(() => apiClient.registerDevice(
      deviceId: any(named: 'deviceId'),
      publicKey: any(named: 'publicKey'),
      deviceName: any(named: 'deviceName'),
      platform: any(named: 'platform'),
    )).thenAnswer((_) async => <String, dynamic>{});
    // ...
  });
}
```

**The 13 files to migrate** (current `*.mocks.dart` companions):
| Test source | Current Mockito mock | Plan 04-04 action |
|-------------|----------------------|-------------------|
| `test/integration/sync/bill_sync_round_trip_test.dart` | `bill_sync_round_trip_test.mocks.dart` | inline `class _Mock<X>` + delete `.mocks.dart` + remove `@GenerateMocks` |
| `test/unit/application/accounting/{create,delete,ensure_default_book,get_transactions,seed_categories}_*_test.dart` | 5 `.mocks.dart` files | same |
| `test/unit/application/voice/{fuzzy_category_matcher,parse_voice_input_use_case,record_category_correction_use_case}_test.dart` | 3 `.mocks.dart` files | same |
| `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart` | `.mocks.dart` | same |
| `test/unit/application/family_sync/shadow_book_service_test.dart` | `.mocks.dart` | same — current source uses Mockito-style `when(mockEncryption.encryptField(any))` (line 26), Plan 04-04 converts to `when(() => mockEncryption.encryptField(any())).thenAnswer(...)` |
| `test/unit/data/repositories/transaction_repository_impl_test.dart` | `.mocks.dart` | same |
| `test/unit/features/home/presentation/providers/today_transactions_provider_test.dart` | `.mocks.dart` | same |
| `test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart` | `.mocks.dart` | **EXCLUDED — deleted by Plan 04-03 per D-14** |

**Migration delta (current Mockito → target Mocktail):**
```dart
// BEFORE (shadow_book_service_test.dart lines 9–13)
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FieldEncryptionService])
import 'shadow_book_service_test.mocks.dart';

// AFTER
import 'package:mocktail/mocktail.dart';

class _MockFieldEncryptionService extends Mock implements FieldEncryptionService {}
```

```dart
// BEFORE (Mockito calling style with positional args)
when(mockEncryption.encryptField(any)).thenAnswer(
  (invocation) async => invocation.positionalArguments.first as String,
);

// AFTER (Mocktail closure-wrapped style)
when(() => mockEncryption.encryptField(any())).thenAnswer(
  (invocation) async => invocation.positionalArguments.first as String,
);
```

**Per CONTEXT.md D-10:** Fakes are inline in each test file. No new `test/_fakes/` directory. If a fake is needed by multiple tests in Phase 4+, this phase duplicates it (acceptable cost).

**Per CONTEXT.md `<integration_points>`:** Plan 04-04 also edits `pubspec.yaml` to remove `mockito` from `dev_dependencies` if no transitive consumer remains; otherwise removal moves to a follow-up plan / Phase 6 (per CONTEXT.md "Claude's Discretion" item 4).

---

### 12. `test/architecture/provider_graph_hygiene_test.dart` (NEW — Plan 04-05)

**Role:** architecture meta-test asserting HIGH-04 (single repo_providers per feature) + HIGH-04 DI consolidation + HIGH-04 global uniqueness + HIGH-05 keepAlive hard list + HIGH-06 no UnimplementedError.

**Analog:** `test/architecture/domain_import_rules_test.dart` (file-I/O scan + per-feature loop pattern).

**Per-feature scan pattern** (analog lines 21–28, 38–55):
```dart
const features = [
  'accounting', 'analytics', 'family_sync', 'home', 'profile', 'settings',
];
// (Plan 04-05 adds 'dual_ledger' — present in lib/features/dual_ledger/presentation/)

for (final feature in features) {
  group('feature: $feature', () {
    test('exactly one repository_providers.dart per feature', () {
      final dir = Directory('lib/features/$feature/presentation/providers');
      final files = dir.listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => !n.endsWith('.g.dart'))
          .toList();
      expect(files.where((n) => n == 'repository_providers.dart'), hasLength(1));
      // also: no other file name except state_*.dart
      final nonRepo = files.where((n) => n != 'repository_providers.dart');
      for (final n in nonRepo) {
        expect(n.startsWith('state_'), isTrue,
            reason: 'feature $feature: $n is not a state_*.dart');
      }
    });
  });
}
```

**HIGH-05 keepAlive hard list (per D-07.4 — verbatim)**:
```dart
const _expectedKeepAliveProviders = [
  'syncEngineProvider',
  'transactionChangeTrackerProvider',
  'merchantDatabaseProvider',
  'activeGroupProvider',
  'activeGroupMembersProvider',
  'ledgerProvider',
];

test('all 6 named keepAlive providers retain @Riverpod(keepAlive: true)', () {
  // grep `lib/**/*.dart` for `@Riverpod(keepAlive: true)` and adjacent identifier
  // assert each entry in _expectedKeepAliveProviders is found.
});
```

**Note on the hard list:** per `grep "keepAlive: true" lib --include="*.dart"` (excluding `.g.dart`), the current ground truth is:
- `lib/features/accounting/presentation/providers/voice_providers.dart:16` — `merchantDatabaseProvider` ✓
- `lib/features/home/presentation/providers/home_providers.dart:9` — `selectedTabIndexProvider` (NOT on hard list — extra, allowed per D-07.4 "Adding new keepAlive providers is allowed")
- `lib/features/family_sync/presentation/providers/active_group_provider.dart:13` — `activeGroupProvider` ✓
- `lib/features/family_sync/presentation/providers/active_group_provider.dart:22` — `isGroupModeProvider` (extra)
- `lib/features/family_sync/presentation/providers/sync_providers.dart:118` — `transactionChangeTrackerProvider` ✓
- `lib/features/family_sync/presentation/providers/sync_providers.dart:141` — `syncEngineProvider` ✓
- `lib/features/dual_ledger/presentation/providers/ledger_providers.dart:8` — `ledgerViewProvider` (i.e. `ledgerProvider`?) — planner verifies the exact name matches the hard list during 04-05
- `lib/application/dual_ledger/providers.dart:9` — `ruleEngineProvider` (extra)
- `lib/infrastructure/security/providers.dart:26, 106` — service + `appDatabaseProvider`

**`activeGroupMembersProvider` does NOT currently exist with `@Riverpod(keepAlive: true)`** — the closest is `groupMembers` at `sync_providers.dart` line 161 (no keepAlive). Plan 04-05 must reconcile: either add the keepAlive annotation to `groupMembers` (renaming if needed) OR remove `activeGroupMembersProvider` from the hard list. CONTEXT.md D-07.4 is explicit: "If a name is renamed during Phase 4 refactor, the test's hard-coded entry is updated in the same commit."

**HIGH-06 no UnimplementedError** (`grep "throw UnimplementedError"` across `lib/` returned ZERO at audit — Phase 3 D-02 already closed CRIT-03). Plan 04-05 codifies the empty result as a regression alarm:
```dart
test('no UnimplementedError in any production provider', () {
  final hits = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final src = entity.readAsStringSync();
      if (RegExp(r'@riverpod[\s\S]{0,500}throw\s+UnimplementedError').hasMatch(src) ||
          RegExp(r'Provider<\w+>\(\([^)]*\)\s*=>\s*throw\s+UnimplementedError').hasMatch(src)) {
        hits.add(entity.path);
      }
    }
  }
  expect(hits, isEmpty, reason: 'UnimplementedError providers found: $hits');
});
```

---

### 13. Characterization tests (~30–50 NEW test files — Plan 04-06)

**Role:** Phase 3 D-15 strict interpretation continues. Every Phase-4 touched file in `Phase-4 touched-files ∩ files-needing-tests.txt` gets ≥80% coverage written BEFORE its refactor commit.

**Analog (template for new test files):** `test/unit/application/family_sync/create_group_use_case_test.dart` (Mocktail-only — see §11 Analog B above).

**Why this analog:** Plan 04-04 deletes all `*.mocks.dart` files. Plan 04-06 cannot use Mockito-style mocks (they would be deleted by 04-04 immediately after). Per CONTEXT.md `<specifics>` 4th bullet: "Plan 04-06 cannot use Mockito mocks (those would be deleted by 04-04 immediately after)."

**Test directory mirrors source** (project convention from CONTEXT.md `<code_context>` "Established Patterns"):
- Source `lib/application/family_sync/<verb>_use_case.dart` → Test `test/unit/application/family_sync/<verb>_use_case_test.dart`
- Source `lib/features/accounting/presentation/providers/state_voice.dart` → Test `test/unit/features/accounting/presentation/providers/state_voice_test.dart`

**Coverage gate invocation** (per CONTEXT.md `<canonical_refs>` "scripts/coverage_gate.dart"):
```bash
dart run scripts/coverage_gate.dart \
  --files <touched-files> \
  --threshold 80 \
  --lcov coverage/lcov_clean.info
```

---

## Shared Patterns

### A. Authentication / Auth Guard
**Not applicable to this phase.** Phase 4 is structural/architectural cleanup; no auth flows are added or modified. Existing `KeyManager` / `flutter_secure_storage` paths remain via constructor injection (Phase 3 pattern).

### B. HIGH-05 keepAlive list (locked, applies to ALL Plan 04-01 / 04-02 work)
**Source:** `.planning/REQUIREMENTS.md §HIGH-05` + CONTEXT.md D-07.4.

Six provider names that MUST retain `@Riverpod(keepAlive: true)` after every Phase 4 commit:
```
syncEngineProvider
transactionChangeTrackerProvider
merchantDatabaseProvider
activeGroupProvider
activeGroupMembersProvider          # <-- may need rename reconciliation per D-07.4
ledgerProvider                       # <-- currently `ledgerViewProvider`; planner verifies
```

**Apply to:** every Plan 04-01 / 04-02 commit that touches one of these providers — copy the `@Riverpod(keepAlive: true)` annotation verbatim. Failure mode: the Plan 04-05 architecture test alarms in the next CI run.

### C. Constructor injection (Phase 3 pattern, generalized in Phase 4)
**Source:** `lib/core/initialization/app_initializer.dart` (Phase 3 D-08); `lib/application/family_sync/check_group_use_case.dart`.
**Apply to:** every new use case class in Plan 04-01.
```dart
class XxxUseCase {
  XxxUseCase({required Dep1 dep1, required Dep2 dep2})
    : _dep1 = dep1, _dep2 = dep2;

  final Dep1 _dep1;
  final Dep2 _dep2;

  Future<XxxResult> execute(XxxParams params) async { ... }
}
```

### D. Riverpod `@riverpod` code-gen (project convention)
**Source:** `.planning/codebase/CONVENTIONS.md`; existing 100+ providers across `lib/`.
**Apply to:** every new Riverpod provider in Plan 04-01 and Plan 04-02 fold targets.
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'this_file.g.dart';

@riverpod                            // auto-dispose by default
XxxService xxxService(Ref ref) { ... }

@Riverpod(keepAlive: true)           // for HIGH-05 list members
YyyService yyyService(Ref ref) { ... }
```
After every annotation change: `flutter pub run build_runner build --delete-conflicting-outputs`.

### E. Sealed result class for use case outcomes
**Source:** `lib/application/family_sync/check_group_use_case.dart` lines 10–28.
**Apply to:** every new use case in Plan 04-01 that has multi-branch outcomes (success, error, etc.). Single-result use cases may use `Result<T>` from `lib/shared/utils/result.dart` (the pattern in `lib/application/voice/parse_voice_input_use_case.dart`).

### F. Mocktail-only test convention
**Source:** `test/core/initialization/app_initializer_test.dart`; `test/unit/application/family_sync/create_group_use_case_test.dart`.
**Apply to:** every test file in Plan 04-04 (migration) and Plan 04-06 (new characterization tests).
- Inline `class _MockX extends Mock implements X` (private to file).
- `import 'package:mocktail/mocktail.dart';` only — no `package:mockito/...` imports.
- Closure-wrapped stubs: `when(() => mock.method(any())).thenAnswer(...)`.
- No `@GenerateMocks` annotations. No `*.mocks.dart` companion files.

### G. Repo lock + import_guard sequencing (Phase 2 D-07 + Phase 3 D-17)
**Source:** `.planning/audit/REPO-LOCK-POLICY.md`; CONTEXT.md D-19 / D-20.
**Apply to:** every Plan 04-02 sub-commit. The new yaml lands in the SAME commit as the resolved violations, never standalone — `import_guard` is already blocking.

---

## No Analog Found

| File | Role | Reason / Mitigation |
|------|------|---------------------|
| `lib/application/i18n/formatter_service.dart` (NEW) | application-layer pure-function wrapper | No existing application-layer file purely wraps an infrastructure static class. Closest is `lib/application/dual_ledger/classification_service.dart` (instance class with `RuleEngine` dependency); the new file is thinner (no deps, just delegation). Planner derives shape from §4 above. |
| `lib/application/voice/start_speech_recognition_use_case.dart` (NEW) | streaming use case | No existing application-layer use case wraps a stream-style infrastructure service. `parse_voice_input_use_case.dart` is request-response, not streaming. Planner mirrors `check_group_use_case.dart` structurally and adds a `Stream<TranscriptEvent>` return shape per the underlying `SpeechRecognitionService` API. |
| `test/architecture/provider_graph_hygiene_test.dart` (NEW) | architecture test scanning `@riverpod` annotations | `domain_import_rules_test.dart` uses YAML parsing, not source-code regex scanning. The provider-hygiene test must regex `lib/**/*.dart` for annotations and `keepAlive: true`. Planner builds the regex scaffold from scratch (sample skeleton in §12). |

---

## Metadata

**Analog search scope:**
- `lib/application/{accounting,dual_ledger,family_sync,voice,profile,settings,analytics}/`
- `lib/features/{accounting,dual_ledger,family_sync,home,profile,settings,analytics}/presentation/`
- `lib/infrastructure/{i18n,crypto,security,sync,ml,speech,category}/`
- `test/architecture/`
- `test/unit/application/family_sync/`, `test/unit/application/voice/`, `test/unit/application/accounting/`, `test/unit/application/dual_ledger/`
- `test/core/initialization/`
- `test/integration/sync/`

**Files scanned (read in full or grepped):** ~30 source files, 6 import_guard.yaml files, 2 test files, plus full `grep` enumeration of all `^import.*infrastructure` lines and all `keepAlive: true` declarations in `lib/`.

**Pattern extraction date:** 2026-04-26
