# Phase 26: Providers + Shell Wiring — Pattern Map

**Mapped:** 2026-05-30
**Files analyzed:** 8 new/modified files
**Analogs found:** 8 / 8

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/features/list/domain/models/tagged_transaction.dart` | model (Freezed VO) | transform | `lib/features/list/domain/models/list_sort_config.dart` | exact |
| `lib/features/list/presentation/providers/state_list_filter.dart` | provider (Notifier, keepAlive) | request-response | `lib/features/home/presentation/providers/state_home.dart` | exact |
| `lib/features/list/presentation/providers/state_list_transactions.dart` | provider (Future family) | request-response | `lib/features/analytics/presentation/providers/state_analytics.dart` | exact |
| `lib/features/list/presentation/providers/repository_providers.dart` | provider (use-case wiring) | request-response | `lib/features/analytics/presentation/providers/repository_providers.dart` | exact |
| `lib/features/list/presentation/screens/list_screen.dart` | screen (ConsumerWidget) | request-response | `lib/features/analytics/presentation/screens/analytics_screen.dart` | role-match |
| `lib/features/home/presentation/screens/main_shell_screen.dart` (modify) | screen (shell) | event-driven | self (existing invalidate group at lines 57–88, 142–167) | exact |
| `test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` | test (unit) | request-response | `test/unit/features/family_sync/presentation/providers/active_group_provider_test.dart` | exact |
| `test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` | test (unit) | request-response | `test/unit/features/family_sync/presentation/providers/active_group_provider_test.dart` | exact |
| `lib/features/list/presentation/import_guard.yaml` | config | — | `lib/features/analytics/presentation/import_guard.yaml` | exact |

---

## Pattern Assignments

### `lib/features/list/domain/models/tagged_transaction.dart` (model, Freezed VO)

**Analog:** `lib/features/list/domain/models/list_sort_config.dart` (lines 1–20) and `lib/features/list/domain/models/list_filter_state.dart` (lines 1–45)

**Imports + part directive pattern** (`list_sort_config.dart` lines 1–4):
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/constants/sort_config.dart';  // ← swap for transaction.dart

part 'list_sort_config.freezed.dart';  // ← swap for tagged_transaction.freezed.dart
```

**Freezed abstract class with factory constructor** (`list_sort_config.dart` lines 12–19):
```dart
@freezed
abstract class ListSortConfig with _$ListSortConfig {
  const factory ListSortConfig({
    @Default(SortField.updatedAt) SortField sortField,
    @Default(SortDirection.desc) SortDirection sortDirection,
  }) = _ListSortConfig;
}
```

**Two Freezed classes in one file** — `tagged_transaction.dart` must declare `MemberTag` first, then `TaggedTransaction`. Both use `@freezed abstract class ... with _$...`. Only one `part` directive for `tagged_transaction.freezed.dart`. The `Transaction` import uses relative path `../../../accounting/domain/models/transaction.dart` (same cross-feature path already in `list_filter_state.dart` lines 2–3 and allowed by `lib/features/list/domain/models/import_guard.yaml`).

**`list_filter_state.dart` private constructor pattern** (line 21) — if custom methods are needed:
```dart
const ListFilterState._();  // enables non-factory methods on @freezed class
```
`TaggedTransaction` needs no custom methods, so omit `._()`.

**Import guard compliance:** `lib/features/list/domain/models/import_guard.yaml` (lines 4–8) already allows `freezed_annotation/**` and `../../../accounting/domain/models/transaction.dart`. No change needed for `tagged_transaction.dart` itself. The `list_filter_state.dart` pattern (importing `transaction.dart` for `LedgerType`) confirms the path.

---

### `lib/features/list/presentation/providers/state_list_filter.dart` (provider, Notifier, keepAlive)

**Analog:** `lib/features/home/presentation/providers/state_home.dart` (lines 1–17)

**Full file** (`state_home.dart` lines 1–17):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'state_home.g.dart';

/// ... doc comment ...
@Riverpod(keepAlive: true)          // ← SC#2: annotation, not comment
class SelectedTabIndex extends _$SelectedTabIndex {
  @override
  int build() => 0;

  void select(int index) {
    state = index;
  }
}
// Generated provider name: selectedTabIndexProvider
// Rule: class name stripped as-is → selectedTabIndexProvider
```

**Key points to copy:**
- `@Riverpod(keepAlive: true)` — capitalized `R`, named argument, at annotation level (SC#2 hard requirement)
- Class name does NOT end in `Notifier` — generator outputs `<camelClassName>Provider` (verified from `state_home.g.dart`)
- `class ListFilter extends _$ListFilter` → generates `listFilterProvider`
- `build()` returns the domain VO: `ListFilterState build() => ListFilterState.initial();`
- Import: `package:riverpod_annotation/riverpod_annotation.dart` + `part 'state_list_filter.g.dart';`
- Additional imports for domain types: `list_filter_state.dart`, `list_sort_config.dart`, `transaction.dart` (for `LedgerType`)

**Mutator pattern** (same `state_home.dart` `select` method structure):
```dart
void selectMonth(int year, int month) =>
    state = state.copyWith(selectedYear: year, selectedMonth: month, activeDayFilter: null);

void clearAll() => state = state.clearAll();
```
Each mutator assigns `state =` with `copyWith` — never mutates in place (coding-style.md CRITICAL rule).

**analytics analog for more mutators:** `lib/features/analytics/presentation/providers/state_time_window.dart` (lines 1–21) shows a Notifier with a domain VO as state and a single setter `setWindow`:
```dart
@riverpod
class SelectedTimeWindow extends _$SelectedTimeWindow {
  @override
  TimeWindow build() {
    final now = DateTime.now();
    return TimeWindow.month(year: now.year, month: now.month);
  }

  void setWindow(TimeWindow window) {
    state = window;
  }
}
```
Note: `state_time_window.dart` uses `@riverpod` (auto-dispose). `state_list_filter.dart` MUST use `@Riverpod(keepAlive: true)` (D-01).

---

### `lib/features/list/presentation/providers/state_list_transactions.dart` (provider, Future family)

**Analog:** `lib/features/analytics/presentation/providers/state_analytics.dart` (lines 1–32) and `lib/features/analytics/presentation/providers/state_ledger_snapshot.dart` (lines 1–38)

**Parameterized `@riverpod` Future provider pattern** (`state_analytics.dart` lines 13–32):
```dart
@riverpod
Future<MonthlyReport> monthlyReport(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getMonthlyReportUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    entrySourceFilter: entrySourceFilter,
  );
}
```

**Key points:**
- `@riverpod` (lowercase) for auto-dispose Future provider — NOT `@Riverpod(keepAlive: true)`
- Named parameters with `required` after `Ref ref`
- `ref.watch(useCaseProvider)` inside body — never instantiate use case manually
- `async` function returning `Future<T>`

**`currentLocaleProvider` async-value fallback pattern** (`home_screen.dart` lines 47–48):
```dart
final localeAsync = ref.watch(currentLocaleProvider);
final locale = localeAsync.value ?? const Locale('ja');
```
`currentLocaleProvider` is a `FutureProvider<Locale>` → `ref.watch` returns `AsyncValue<Locale>`. Use `.value ?? const Locale('ja')` (never `.value!`).

**Import for `currentLocaleProvider`** (`home_screen.dart` line 21, `analytics_screen.dart` line 8):
```dart
import '../../../settings/presentation/providers/state_locale.dart';
// or with alias:
import '../../../../features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
```
From `lib/features/list/presentation/providers/` the relative path is `../../../settings/presentation/providers/state_locale.dart`.

**Cross-feature import pattern** (`analytics_screen.dart` lines 4–6):
```dart
import '../../../../features/accounting/presentation/providers/repository_providers.dart'
    as accounting_providers;
```
Use `show` or `as` alias to import `transactionRepositoryProvider` from accounting without name-polluting the namespace.

**Additional imports this file needs:**
```dart
import 'dart:ui';  // Locale
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/tagged_transaction.dart';
import '../../../../application/accounting/category_localization_service.dart';
import '../../../../features/settings/presentation/providers/state_locale.dart';
import '../../../../application/list/get_list_transactions_use_case.dart';
import 'state_list_filter.dart';
import 'repository_providers.dart';

part 'state_list_transactions.g.dart';
```

---

### `lib/features/list/presentation/providers/repository_providers.dart` (provider, use-case wiring)

**Analog:** `lib/features/analytics/presentation/providers/repository_providers.dart` (lines 41–47, single use-case provider pattern)

**Single use-case provider** (`analytics/repository_providers.dart` lines 41–47):
```dart
/// GetMonthlyReportUseCase provider.
@riverpod
GetMonthlyReportUseCase getMonthlyReportUseCase(Ref ref) {
  return GetMonthlyReportUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}
```

**Cross-feature `transactionRepositoryProvider` import** (`analytics/repository_providers.dart` lines 21–22):
```dart
import '../../../../features/accounting/presentation/providers/repository_providers.dart';
```
For `list/presentation/providers/repository_providers.dart` the path is:
```dart
import '../../../accounting/presentation/providers/repository_providers.dart'
    show transactionRepositoryProvider;
```
Use `show transactionRepositoryProvider` to avoid re-exporting the full accounting providers namespace — critical for `provider_graph_hygiene_test.dart` compliance (CLAUDE.md Pitfall #10).

**File header pattern** (`analytics/repository_providers.dart` lines 1–24):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// ... specific imports ...
part 'repository_providers.g.dart';
```
Note: `flutter_riverpod` is needed alongside `riverpod_annotation` in this file because analytics uses the manual `final ... = Provider<T>((ref) {...})` syntax. The list feature's `repository_providers.dart` only needs `@riverpod` annotation syntax, so `flutter_riverpod` import may be omitted if only `Ref` is needed (from `riverpod_annotation`).

---

### `lib/features/list/presentation/screens/list_screen.dart` (screen, ConsumerWidget)

**Analog:** `lib/features/analytics/presentation/screens/analytics_screen.dart` (lines 1–58) — specifically the `ConsumerWidget` structure and `AsyncValue.when` pattern

**ConsumerWidget scaffold** (`analytics_screen.dart` lines 36–60):
```dart
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(selectedTimeWindowProvider);
    // ...
    final locale =
        ref.watch(locale_providers.currentLocaleProvider).value ??
        Localizations.localeOf(context);
    // ...
  }
}
```

**`AsyncValue.when` pattern** — the analytics screen uses per-card `.when` rather than a top-level `.when`. For `ListScreen` (loading-only), a simpler top-level pattern is correct:
```dart
final transactionsAsync = ref.watch(listTransactionsProvider(bookId: bookId));
return transactionsAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => Center(child: Text(e.toString())),
  data: (_) => const Center(child: CircularProgressIndicator()),
  // Phase 28: replace data branch with ListView of TaggedTransaction tiles
);
```

**Imports:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/state_list_transactions.dart';
```
`ConsumerWidget` and `WidgetRef` come from `flutter_riverpod/flutter_riverpod.dart` (CLAUDE.md Riverpod 3 import table — row 1).

---

### `lib/features/home/presentation/screens/main_shell_screen.dart` (modify — shell invalidation)

**Self-analog:** The file itself at lines 57–90 (sync listener invalidate group) and lines 142–167 (FAB callback invalidate group).

**Sync listener wiring point** (lines 35–91 — existing `ref.listen` block):
```dart
ref.listen(syncStatusStreamProvider, (prev, next) {
  // ... existing state checks ...
  if (wasSyncing && nowDone) {
    // existing invalidations at lines 57–88:
    ref.invalidate(todayTransactionsProvider(bookId: bookId));
    ref.invalidate(monthlyReportProvider(...));
    ref.invalidate(shadowBooksProvider);
    // ...
    // ADD HERE (after line 89, before closing brace at 91):
    ref.invalidate(listTransactionsProvider(bookId: bookId));
  }
});
```

**FAB callback wiring point** (lines 125–168 — `onFabTap` callback):
```dart
onFabTap: () async {
  await Navigator.of(context).push<void>(...);
  // existing invalidations at lines 142–167:
  ref.invalidate(monthlyReportProvider(...));
  ref.invalidate(todayTransactionsProvider(bookId: bookId));
  // ...
  // ADD HERE (before closing brace at 168):
  ref.invalidate(listTransactionsProvider(bookId: bookId));
},
```

**List placeholder replacement** (line 111):
```dart
// BEFORE (line 111):
Center(child: Text(S.of(context).listTab)),
// AFTER:
ListScreen(bookId: bookId),
```

**New import to add** (after line 19, mirroring the analytics import on line 10):
```dart
import '../../../list/presentation/screens/list_screen.dart';
import '../../../list/presentation/providers/state_list_transactions.dart';
```

**Existing import pattern to mirror** (lines 8–13):
```dart
import '../../../accounting/presentation/providers/repository_providers.dart';
import '../../../analytics/presentation/providers/state_analytics.dart';
import '../../../analytics/presentation/providers/state_happiness.dart';
```

---

### `test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` (test, unit)

**Analog:** `test/unit/features/family_sync/presentation/providers/active_group_provider_test.dart` (lines 1–57)

**Full test file structure** (`active_group_provider_test.dart`):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_provider_scope.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockGroupRepository repo;

  setUp(() {
    repo = MockGroupRepository();
  });

  group('activeGroupProvider', () {
    test('isGroupMode is false when no active group exists', () async {
      when(() => repo.watchActiveGroup()).thenAnswer((_) => Stream.value(null));

      final container = ProviderContainer.test(
        overrides: [groupRepositoryProvider.overrideWithValue(repo)],
      );

      await waitForFirstValue<GroupInfo?>(container, activeGroupProvider);
      expect(container.read(isGroupModeProvider), isFalse);
    });
  });
}
```

**Key test patterns:**
- `ProviderContainer.test(overrides: [...])` — NOT `ProviderContainer()` (CLAUDE.md Riverpod 3 async test pattern)
- `await waitForFirstValue<T>(container, provider)` — NOT `await container.read(provider.future)` (CLAUDE.md anti-pattern)
- Helper import: `import '../../../../../helpers/test_provider_scope.dart';`
- Mock class: `class MockXxx extends Mock implements XxxInterface {}`
- Mocktail stub: `when(() => mock.method()).thenReturn(value)` or `.thenAnswer((_) => ...)`

**`listFilterNotifier` test specifics:**
- `listFilterProvider` is a synchronous Notifier (not async) — use `container.read(listFilterProvider)` directly (no `waitForFirstValue` needed for the initial state read)
- To test mutators: `container.read(listFilterProvider.notifier).selectMonth(2026, 3)` then `expect(container.read(listFilterProvider).selectedMonth, 3)`
- For `clearAll()`: set some state, call `clearAll()`, verify `container.read(listFilterProvider) == ListFilterState.initial()`

---

### `test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` (test, unit)

**Analog:** `test/unit/features/family_sync/presentation/providers/active_group_provider_test.dart` (same structure)

**Mock for use case** (same pattern as `MockGroupRepository`):
```dart
class MockGetListTransactionsUseCase extends Mock
    implements GetListTransactionsUseCase {}
```

**`waitForFirstValue` with async provider** (`active_group_provider_test.dart` lines 27–29):
```dart
final container = ProviderContainer.test(
  overrides: [getListTransactionsUseCaseProvider.overrideWithValue(mockUseCase)],
);
final result = await waitForFirstValue<List<TaggedTransaction>>(
  container,
  listTransactionsProvider(bookId: 'book1'),
);
expect(result.hasValue, isTrue);
```

**`waitForFirstValue` returns `AsyncValue<T>`** (`test_provider_scope.dart` line 34–45):
```dart
Future<AsyncValue<T>> waitForFirstValue<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider,
)
```
The caller must call `result.hasValue` or `result.value!` to extract the list.

**Additional overrides needed** — `listTransactionsProvider` also watches `listFilterProvider` and `currentLocaleProvider`. Override them too:
```dart
final container = ProviderContainer.test(
  overrides: [
    getListTransactionsUseCaseProvider.overrideWithValue(mockUseCase),
    // listFilterProvider has a synchronous build() — no override needed for default state
    // currentLocaleProvider returns Future<Locale> — override to avoid real settings lookup:
    currentLocaleProvider.overrideWith((ref) async => const Locale('ja')),
  ],
);
```

---

### `lib/features/list/presentation/import_guard.yaml` (config)

**Analog:** `lib/features/analytics/presentation/import_guard.yaml` (lines 1–8) — exact copy

```yaml
# Presentation layer — uses Application + Domain only. MUST NOT reach Infrastructure.
# data/repositories/** access remains permitted in Phase 4 (Phase 5+ MED scope).
deny:
  - package:home_pocket/infrastructure/**
  - package:home_pocket/data/daos/**
  - package:home_pocket/data/tables/**

inherit: true
```

No change needed — this is the standard pattern for all presentation-layer `import_guard.yaml` files. The deny rules allow domain imports (`lib/features/list/domain/models/tagged_transaction.dart`) and cross-feature presentation imports (`lib/features/accounting/presentation/providers/repository_providers.dart`) which are correct for Phase 26 list presentation providers.

---

## Shared Patterns

### `@Riverpod(keepAlive: true)` Notifier
**Source:** `lib/features/home/presentation/providers/state_home.dart` lines 9–17
**Apply to:** `state_list_filter.dart` only (all other new providers use auto-dispose `@riverpod`)
```dart
@Riverpod(keepAlive: true)
class SelectedTabIndex extends _$SelectedTabIndex {
  @override
  int build() => 0;
  void select(int index) { state = index; }
}
```
SC#2 hard requirement: `keepAlive: true` must appear in the annotation, not as a comment.

### `@riverpod` auto-dispose Future provider (family/parameterized)
**Source:** `lib/features/analytics/presentation/providers/state_analytics.dart` lines 13–32
**Apply to:** `state_list_transactions.dart`
```dart
@riverpod
Future<ReturnType> providerName(Ref ref, {required String bookId, ...}) async {
  final useCase = ref.watch(someUseCaseProvider);
  return useCase.execute(...);
}
```

### `currentLocaleProvider` null-safe read
**Source:** `lib/features/home/presentation/screens/home_screen.dart` lines 47–48
**Apply to:** `state_list_transactions.dart`, `list_screen.dart` (if i18n needed)
```dart
final localeAsync = ref.watch(currentLocaleProvider);
final locale = localeAsync.value ?? const Locale('ja');
```

### `ref.invalidate(familyProvider(namedArg: value))` pattern
**Source:** `lib/features/home/presentation/screens/main_shell_screen.dart` lines 57–89
**Apply to:** `main_shell_screen.dart` modifications (D-03)
```dart
ref.invalidate(todayTransactionsProvider(bookId: bookId));
ref.invalidate(monthlyReportProvider(bookId: bookId, startDate: ..., endDate: ...));
```
`listTransactionsProvider` uses `bookId:` named parameter — `ref.invalidate(listTransactionsProvider(bookId: bookId))` follows exact same form.

### `ProviderContainer.test()` + `waitForFirstValue<T>` test skeleton
**Source:** `test/unit/features/family_sync/presentation/providers/active_group_provider_test.dart` lines 13–44 + `test/helpers/test_provider_scope.dart` lines 34–45
**Apply to:** all list provider unit tests
```dart
final container = ProviderContainer.test(overrides: [...]);
final result = await waitForFirstValue<T>(container, provider);
expect(result.hasValue, isTrue);
```

### Freezed VO with `@Default` and cross-feature domain import
**Source:** `lib/features/list/domain/models/list_filter_state.dart` lines 19–45
**Apply to:** `tagged_transaction.dart`
```dart
@freezed
abstract class Foo with _$Foo {
  const factory Foo({
    required Type field,
    OtherType? optionalField,
  }) = _Foo;
}
```

---

## No Analog Found

None — all 8 files have close analogs in the codebase.

---

## Metadata

**Analog search scope:** `lib/features/analytics/`, `lib/features/home/`, `lib/features/list/`, `lib/features/family_sync/`, `test/unit/features/family_sync/`, `test/helpers/`
**Files read:** 14 source files + 2 config files
**Pattern extraction date:** 2026-05-30
