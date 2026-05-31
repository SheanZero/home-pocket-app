# Phase 26: Providers + Shell Wiring — Research

**Researched:** 2026-05-30
**Domain:** Flutter + Riverpod 3 provider wiring, Freezed value objects, shell navigation integration
**Confidence:** HIGH (all findings from direct codebase inspection)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** `listFilterStateProvider` marked `@Riverpod(keepAlive: true)`, all 7 filter fields persistent across tab switches.

**D-02:** `selectedYear`/`selectedMonth` persist with all fields. `ListFilterState.initial()` is the initial value and `clearAll()` target.

**D-03:** Add `ref.invalidate(listTransactionsProvider(bookId: bookId))` to the `syncStatusStreamProvider` listener (lines 34–91) AND the FAB-return callback (line 125+) in `main_shell_screen.dart` — forward-wiring even though ListScreen is loading-only this phase.

**D-04:** Text search matches LOCALIZED category name (via `CategoryLocalizationService.resolveFromId(categoryId, locale)`) + merchant + note. NOT raw `categoryId`. Provider injects `CategoryLocalizationService` + `currentLocaleProvider`.

**D-05:** Case-insensitive substring match: `query.toLowerCase().trim()` against all three fields (OR within search), AND-composed with ledger/category filters.

**D-06:** Shadow-book note decryption returns `null` per Phase 24 contract. Search handles gracefully: `(t.note?.toLowerCase().contains(q) ?? false)`.

**D-07:** `TaggedTransaction { Transaction transaction; MemberTag? memberTag }` + `MemberTag { String emoji; String name }` — Freezed VOs, placed in `lib/features/list/domain/models/`. Own-book only this phase → `memberTag = null`.

**D-08:** `listTransactionsProvider` own-book only: `bookIds = [bookId]`, `memberTag = null`. No `isGroupModeProvider`/`shadowBooksProvider`. Leave `// Phase 29: merge shadow books → bookIds + memberTag` comment seam.

**D-09:** `ListScreen` = pure loading scaffold. `ConsumerWidget` consuming `listTransactionsProvider(bookId)`, `AsyncValue.when` showing loading indicator. Replaces `main_shell_screen.dart:111` placeholder.

**D-10:** `listCalendarProvider` deferred to Phase 27. Not built this phase.

### Claude's Discretion
- Notifier class name (naming collision — see Naming Collision section below)
- Mutator naming/granularity (must include `clearAll()`)
- Loading indicator style (`CircularProgressIndicator`)
- Test construction details

### Deferred Ideas (OUT OF SCOPE)
- Family multi-book wiring (`isGroupMode`, `shadowBooksProvider`, FAM-01..04) — Phase 29
- `listCalendarProvider` — Phase 27
- Multi-category filter (`Set<String>`) — Phase 28
- Sort/filter bar + transaction tile UI — Phase 28
- Calendar header UI — Phase 27
- Loading skeleton / undo-delete SnackBar — post-v1.4
- Pagination / infinite scroll — v1.5

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FILTER-01 | Text search by category name, merchant, and note | Provider post-processes via `CategoryLocalizationService.resolveFromId` + `note?.toLowerCase()` — verified against SC#3 |
| FILTER-02 | Filter by ledger (Survival / Soul) | `ListFilterState.ledgerType` forwarded to use case → SQL `WHERE ledgerType = ?`; AND-composed in provider |
| FILTER-03 | Filter by one category (single-value `String?`) | `ListFilterState.categoryId` forwarded to use case; multi-select deferred to Phase 28 |
| FILTER-04 | Active search + filters AND-composed; `clearAll()` resets all | `ListFilterState.clearAll()` (Phase 25, verified); filter AND-composition in provider post-process |

</phase_requirements>

---

## Summary

Phase 26 wires the list feature's Riverpod provider graph from the Phase 25 domain layer to the shell. The three deliverables — a `keepAlive: true` filter-state Notifier, a `listTransactionsProvider(bookId)` Future provider, and a `ListScreen` loading scaffold — are all straightforward given the Phase 25 outputs are fully built and verified. The main technical risks are (1) the Notifier class naming collision between the domain `ListFilterState` type and any Notifier named the same, and (2) the `CategoryLocalizationService` injection pattern for locale-aware category name search.

All upstream code has been verified by direct inspection. The `GetListTransactionsUseCase.execute()` and `watch()` signatures, `ListFilterState` fields, `transactionRepositoryProvider` location, `currentLocaleProvider` name, `waitForFirstValue<T>` helper signature, and `main_shell_screen.dart` invalidation pattern are all confirmed. No surprises were found; the locked decisions are structurally sound.

**Primary recommendation:** Build in wave order: (1) Freezed VOs `TaggedTransaction`/`MemberTag` + provider files, (2) filter-state Notifier with `@Riverpod(keepAlive: true)`, (3) `listTransactionsProvider` with full search logic, (4) `getListTransactionsUseCaseProvider`, (5) `ListScreen` + shell wiring. Run `build_runner` after each wave.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Filter + sort state | Presentation (Riverpod Notifier) | — | User-facing transient state lives at presentation layer; `keepAlive: true` keeps it cross-tab |
| Text search (category name resolution) | Presentation (provider) | Application (CategoryLocalizationService) | Locale-aware resolution is not SQL-able; provider post-processes after use case returns |
| Month-range + ledger + category SQL filtering | Application (use case → repo) | Data (DAO) | SQL-able filters pushed to DB; use case translates filter state to query params |
| Dart-side day filter + AND-composition | Presentation (provider) | — | Day filter and text search are in-memory operations on the already-fetched list |
| `TaggedTransaction` + `MemberTag` VOs | Domain (list feature models) | — | Value objects describing the provider's return type belong in feature domain |
| `getListTransactionsUseCaseProvider` | Presentation (list feature providers) | Application | Use case provider wires Application layer; lives in `lib/features/list/presentation/providers/` |
| `transactionRepositoryProvider` | Accounting feature presentation providers | — | Single source of truth; not duplicated in list feature |
| `ListScreen` loading scaffold | Presentation (list feature screens) | — | UI shell; consumes provider output |
| Shell invalidation (sync + FAB) | Presentation (`main_shell_screen.dart`) | — | Cross-feature side-effect trigger belongs in the shell |

---

## Standard Stack

### Core (all pre-installed, no new packages this phase)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_riverpod` | `^3.1.0` [VERIFIED: pubspec.yaml] | State management + provider graph | Project standard |
| `riverpod_annotation` | `^4.0.0` [VERIFIED: pubspec.yaml] | `@riverpod` / `@Riverpod(keepAlive:)` annotations | Code-gen approach |
| `riverpod_generator` | `^4.0.0+1` [VERIFIED: pubspec.yaml] | `build_runner` code generation | Paired with annotation |
| `freezed_annotation` | pinned [VERIFIED: pubspec.yaml] | `@freezed` for `TaggedTransaction`/`MemberTag` | Project standard for VOs |
| `mocktail` | `^1.0.4` [VERIFIED: pubspec.yaml] | Mock repo + use case in SC#3 tests | Project standard |

**No new packages required this phase.** [VERIFIED: pubspec.yaml — all dependencies present]

### New Files to Create

```
lib/features/list/
├── domain/
│   └── models/
│       ├── tagged_transaction.dart       (Freezed VO — TaggedTransaction + MemberTag)
│       └── tagged_transaction.freezed.dart  (generated)
└── presentation/
    ├── providers/
    │   ├── state_list_filter.dart         (ListFilter Notifier, keepAlive:true)
    │   ├── state_list_filter.g.dart       (generated)
    │   ├── state_list_transactions.dart   (listTransactionsProvider family)
    │   ├── state_list_transactions.g.dart (generated)
    │   ├── repository_providers.dart      (getListTransactionsUseCaseProvider ONLY)
    │   └── repository_providers.g.dart    (generated)
    └── screens/
        └── list_screen.dart               (ConsumerWidget loading scaffold)
```

**No install command** — zero new pubspec dependencies.

---

## Package Legitimacy Audit

> No new packages are installed this phase. All dependencies (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `freezed_annotation`, `mocktail`) are pre-existing in `pubspec.yaml` [VERIFIED: pubspec.yaml direct inspection].

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
ListFilterState (domain VO, Phase 25)
         │
         ▼
[listFilterProvider]  ← @Riverpod(keepAlive: true)  ← mutators: selectMonth/selectDay/...
         │ ref.watch
         ▼
[listTransactionsProvider(bookId)]  ← @riverpod (auto-dispose)
    │  1. reads filter state
    │  2. calls getListTransactionsUseCaseProvider.execute(GetListParams(bookIds:[bookId], filter))
    │     └─> SQL: ledgerType? + categoryId? + dateRange + ORDER BY  (use case handles)
    │  3. Dart-side post-process:
    │     a. activeDayFilter → .where(tx.timestamp matches day)
    │     b. searchQuery → CategoryLocalizationService.resolveFromId + merchant + note (OR)
    │     c. AND-compose with SQL results
    │  4. wrap as TaggedTransaction(transaction: tx, memberTag: null)  // Phase 29: fill memberTag
    │
    ▼
List<TaggedTransaction>
         │
         ▼
[ListScreen]  (ConsumerWidget, AsyncValue.when → CircularProgressIndicator)
         │
         ▼
main_shell_screen.dart:97 IndexedStack index 1

Invalidation hooks (D-03):
  syncStatusStreamProvider listener (lines 35–91) → ref.invalidate(listTransactionsProvider(bookId:bookId))
  FAB-return callback (lines 125–168)              → ref.invalidate(listTransactionsProvider(bookId:bookId))

Use case wiring:
[getListTransactionsUseCaseProvider]  ← lib/features/list/presentation/providers/repository_providers.dart
    └─> transactionRepositoryProvider (from lib/features/accounting/presentation/providers/repository_providers.dart)
```

### Recommended Project Structure

```
lib/features/list/
├── domain/
│   ├── import_guard.yaml                  (exists; deny data/infrastructure/application/presentation)
│   └── models/
│       ├── import_guard.yaml              (exists; allow freezed_annotation + transaction.dart + list_sort_config.dart)
│       ├── list_filter_state.dart         (Phase 25 — DO NOT TOUCH)
│       ├── list_filter_state.freezed.dart (Phase 25 — DO NOT TOUCH)
│       ├── list_sort_config.dart          (Phase 25 — DO NOT TOUCH)
│       ├── list_sort_config.freezed.dart  (Phase 25 — DO NOT TOUCH)
│       ├── tagged_transaction.dart        (NEW — this phase)
│       └── tagged_transaction.freezed.dart (NEW — generated)
└── presentation/                          (NEW DIRECTORY — this phase)
    ├── providers/
    │   ├── state_list_filter.dart
    │   ├── state_list_filter.g.dart
    │   ├── state_list_transactions.dart
    │   ├── state_list_transactions.g.dart
    │   ├── repository_providers.dart
    │   └── repository_providers.g.dart
    └── screens/
        └── list_screen.dart
```

### Pattern 1: keepAlive Notifier (filter state)

```dart
// Source: CLAUDE.md §Riverpod 3 conventions + state_home.dart verified pattern
// File: lib/features/list/presentation/providers/state_list_filter.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:home_pocket/features/list/domain/models/list_filter_state.dart';
import 'package:home_pocket/features/list/domain/models/list_sort_config.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

part 'state_list_filter.g.dart';

/// Holds the complete filter + sort state for the transaction list.
///
/// keepAlive: true — filter state persists across IndexedStack tab switches.
/// Under IndexedStack, widgets are never unmounted, so subscriptions never drop;
/// keepAlive: true makes the intent explicit and guards against future changes.
/// D-01/D-02: all 7 fields persist; selectedMonth does NOT reset on tab switch.
@Riverpod(keepAlive: true)
class ListFilter extends _$ListFilter {
  @override
  ListFilterState build() => ListFilterState.initial();

  void selectMonth(int year, int month) =>
      state = state.copyWith(selectedYear: year, selectedMonth: month, activeDayFilter: null);

  void selectDay(DateTime? day) =>
      state = state.copyWith(activeDayFilter: day);

  void setSort(ListSortConfig sort) =>
      state = state.copyWith(sortConfig: sort);

  void setLedgerFilter(LedgerType? type) =>
      state = state.copyWith(ledgerType: type);

  void setCategoryFilter(String? id) =>
      state = state.copyWith(categoryId: id);

  void setSearch(String q) =>
      state = state.copyWith(searchQuery: q);

  void setMemberFilter(String? bookId) =>
      state = state.copyWith(memberBookId: bookId);

  void clearAll() => state = state.clearAll();
}
// Generated provider name: listFilterProvider (class ListFilter → strips no suffix, generates listFilterProvider)
```

**Critical naming note:** `class ListFilter` (not `class ListFilterState`) avoids colliding with the domain type `ListFilterState` imported from `lib/features/list/domain/models/list_filter_state.dart`. The generated provider name is `listFilterProvider`. [VERIFIED: Riverpod 3 naming confirmed via state_home.g.dart — `SelectedTabIndex` → `selectedTabIndexProvider`; `LocaleNotifier` → `localeProvider`]

### Pattern 2: listTransactionsProvider with CategoryLocalizationService

```dart
// Source: home_screen.dart lines 21,47 + category_localization_service.dart verified API
// File: lib/features/list/presentation/providers/state_list_transactions.dart

import 'dart:ui';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:home_pocket/features/list/domain/models/tagged_transaction.dart';
import 'package:home_pocket/application/accounting/category_localization_service.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart';
import 'package:home_pocket/application/list/get_list_transactions_use_case.dart';
import 'state_list_filter.dart';
import 'repository_providers.dart';

part 'state_list_transactions.g.dart';

@riverpod
Future<List<TaggedTransaction>> listTransactions(
  Ref ref, {
  required String bookId,
}) async {
  final filter = ref.watch(listFilterProvider);
  final localeAsync = ref.watch(currentLocaleProvider);
  final locale = localeAsync.value ?? const Locale('ja');  // matches home_screen.dart pattern

  // Phase 29: merge shadow books → bookIds = [bookId, ...shadowBooks.map((s) => s.book.id)]
  final bookIds = [bookId];

  final useCase = ref.watch(getListTransactionsUseCaseProvider);
  final result = await useCase.execute(
    GetListParams(bookIds: bookIds, filter: filter),
  );

  if (result.isError) throw Exception(result.error);
  var txs = result.data!;

  // Dart-side day filter (activeDayFilter is DateTime?, not int)
  final dayFilter = filter.activeDayFilter;
  if (dayFilter != null) {
    txs = txs.where((tx) =>
        tx.timestamp.year == dayFilter.year &&
        tx.timestamp.month == dayFilter.month &&
        tx.timestamp.day == dayFilter.day).toList();
  }

  // Dart-side text search (D-04/D-05)
  final q = filter.searchQuery.toLowerCase().trim();
  if (q.isNotEmpty) {
    txs = txs.where((tx) {
      final categoryName =
          CategoryLocalizationService.resolveFromId(tx.categoryId, locale).toLowerCase();
      final merchant = tx.merchant?.toLowerCase() ?? '';
      final note = tx.note?.toLowerCase() ?? '';  // D-06: shadow-note-safe via ?? ''
      return categoryName.contains(q) || merchant.contains(q) || note.contains(q);
    }).toList();
  }

  // Phase 29: fill memberTag from shadowBooks lookup
  return txs.map((tx) => TaggedTransaction(transaction: tx, memberTag: null)).toList();
}
```

### Pattern 3: TaggedTransaction + MemberTag Freezed VOs

```dart
// File: lib/features/list/domain/models/tagged_transaction.dart
// D-07: one-shot full build; own-book → memberTag null; Phase 29 fills it.
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../accounting/domain/models/transaction.dart';

part 'tagged_transaction.freezed.dart';

@freezed
abstract class MemberTag with _$MemberTag {
  const factory MemberTag({
    required String emoji,
    required String name,
  }) = _MemberTag;
}

@freezed
abstract class TaggedTransaction with _$TaggedTransaction {
  const factory TaggedTransaction({
    required Transaction transaction,
    MemberTag? memberTag,
  }) = _TaggedTransaction;
}
```

**Import guard note:** `tagged_transaction.dart` lives in `lib/features/list/domain/models/` — same directory whose `import_guard.yaml` already allows `../../../accounting/domain/models/transaction.dart` and `freezed_annotation`. The new file must be added to the allow-list in `import_guard.yaml` for any file that imports it (presentation providers will reference it via `lib/features/list/domain/models/tagged_transaction.dart`).

### Pattern 4: getListTransactionsUseCaseProvider

```dart
// File: lib/features/list/presentation/providers/repository_providers.dart
// MUST NOT duplicate transactionRepositoryProvider — import from accounting feature.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:home_pocket/application/list/get_list_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show transactionRepositoryProvider;

part 'repository_providers.g.dart';

@riverpod
GetListTransactionsUseCase getListTransactionsUseCase(Ref ref) {
  return GetListTransactionsUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
}
```

### Pattern 5: main_shell_screen.dart invalidation wiring (D-03)

```dart
// Add to syncStatusStreamProvider listener (after line 89, inside wasSyncing && nowDone block):
ref.invalidate(listTransactionsProvider(bookId: bookId));

// Add to FAB-return callback (after line 167, before the closing brace):
ref.invalidate(listTransactionsProvider(bookId: bookId));

// Required import in main_shell_screen.dart:
import '../../../list/presentation/providers/state_list_transactions.dart';
```

### Pattern 6: ListScreen loading scaffold (D-09)

```dart
// File: lib/features/list/presentation/screens/list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/state_list_transactions.dart';

class ListScreen extends ConsumerWidget {
  const ListScreen({super.key, required this.bookId});
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(listTransactionsProvider(bookId: bookId));
    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (_) => const Center(child: CircularProgressIndicator()),
      // Phase 28: replace data branch with ListView of TaggedTransaction tiles
    );
  }
}
```

### Anti-Patterns to Avoid

- **Naming the Notifier class `ListFilterState`**: the domain Freezed type with that name is already imported in multiple files; Dart would require aliased imports everywhere. Use `ListFilter` (generates `listFilterProvider`). [VERIFIED: domain class exists at `lib/features/list/domain/models/list_filter_state.dart`]
- **Creating a second `repository_providers.dart` in the list feature for `transactionRepositoryProvider`**: `provider_graph_hygiene_test.dart` will fail and `flutter analyze` will flag the duplicate. Import from `accounting` feature with `show transactionRepositoryProvider`.
- **Watching `currentLocaleProvider` as `AsyncValue<Locale>` without null-safe fallback**: `currentLocaleProvider` returns `Future<Locale>` (async provider). Pattern confirmed from `home_screen.dart` line 47: `ref.watch(currentLocaleProvider)` returns `AsyncValue<Locale>`; use `.value ?? const Locale('ja')`.
- **Using `categoryId` directly in text search** (the ARCHITECTURE.md shortcut bug): `CategoryLocalizationService.resolveFromId('cat_food', locale)` returns `'食費'`; raw `'cat_food'.contains('食費')` returns false. Always resolve first.
- **Using bare `await container.read(provider.future)` in tests**: throws "Bad state: disposed during loading" on auto-dispose providers. Always use `waitForFirstValue<T>(container, provider)` from `test/helpers/test_provider_scope.dart`. [VERIFIED: helper exists and confirmed signature]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Category ID → locale display name | Custom lookup map | `CategoryLocalizationService.resolveFromId(categoryId, locale)` | Existing façade over `CategoryLocaleService`; handles `cat_` prefix strip, pass-through for user categories |
| Month + day boundary arithmetic | Inline `DateTime(y, m+1, 0, 23,59,59)` | `DateBoundaries.monthRange(year, month)` / `DateBoundaries.dayRange(day)` | Phase 24 utility in `lib/shared/utils/date_boundaries.dart`; canonical idiom verified |
| Transaction repository instantiation | New `TransactionRepositoryImpl(...)` in list providers | `transactionRepositoryProvider` from `lib/features/accounting/presentation/providers/repository_providers.dart` | Single source of truth; duplicating breaks `provider_graph_hygiene_test.dart` |
| Async provider test pattern | `await container.read(provider.future)` | `waitForFirstValue<T>(container, provider)` | Riverpod 3 auto-dispose causes "disposed during loading" on bare `.future` read |
| Use case injection | Manual constructor call in provider body | `ref.watch(getListTransactionsUseCaseProvider)` | Keeps provider thin; makes mocking easy in tests |

---

## Verified Code Signatures

### `ListFilterState` (Phase 25 output — `lib/features/list/domain/models/list_filter_state.dart`)

[VERIFIED: direct file read]

```dart
@freezed
abstract class ListFilterState with _$ListFilterState {
  const factory ListFilterState({
    required int selectedYear,
    required int selectedMonth,
    DateTime? activeDayFilter,          // DateTime?, not int!
    @Default(ListSortConfig()) ListSortConfig sortConfig,
    LedgerType? ledgerType,
    String? categoryId,
    @Default('') String searchQuery,
    String? memberBookId,
  }) = _ListFilterState;

  factory ListFilterState.initial() => ...;  // anchors to DateTime.now().year/month
  ListFilterState clearAll() => ListFilterState.initial();
}
```

**Key finding:** `activeDayFilter` is `DateTime?` (not `int?`). The day-filter matching in the provider must compare `tx.timestamp.year == dayFilter.year && tx.timestamp.month == dayFilter.month && tx.timestamp.day == dayFilter.day`.

### `GetListTransactionsUseCase` (Phase 25 output — `lib/application/list/get_list_transactions_use_case.dart`)

[VERIFIED: direct file read]

```dart
class GetListParams {
  final List<String> bookIds;
  final ListFilterState filter;       // composed VO, not flat params
  const GetListParams({required this.bookIds, required this.filter});
}

class GetListTransactionsUseCase {
  GetListTransactionsUseCase({required TransactionRepository transactionRepository});

  Future<Result<List<Transaction>>> execute(GetListParams params) async { ... }
  Stream<List<Transaction>> watch(GetListParams params) { ... }  // throws ArgumentError on empty bookIds
}
```

**Key finding:** The use case takes `GetListParams` (composed VO), not flat parameters. The provider must build `GetListParams(bookIds: [bookId], filter: filter)`.

### `CategoryLocalizationService` (`lib/application/accounting/category_localization_service.dart`)

[VERIFIED: direct file read]

```dart
abstract final class CategoryLocalizationService {
  static String resolve(String nameKey, Locale locale) => ...;
  static String resolveFromId(String categoryId, Locale locale) => ...;
}
```

`resolveFromId` strips `cat_` prefix, constructs `category_{suffix}` key, then looks up locale name. Non-system IDs (user-created categories) pass through unchanged. Used via `CategoryLocalizationService.resolveFromId(tx.categoryId, locale)`.

### `currentLocaleProvider` (`lib/features/settings/presentation/providers/state_locale.dart`)

[VERIFIED: state_locale.g.dart + home_screen.dart]

```dart
@riverpod
Future<Locale> currentLocale(Ref ref) async { ... }
// Generated: currentLocaleProvider (AsyncNotifierProvider<Locale>)
// Pattern: ref.watch(currentLocaleProvider) → AsyncValue<Locale>
// Null-safe fallback: localeAsync.value ?? const Locale('ja')
```

### `transactionRepositoryProvider` (`lib/features/accounting/presentation/providers/repository_providers.dart`)

[VERIFIED: direct file read, line 87]

```dart
@riverpod
TransactionRepository transactionRepository(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  final dao = TransactionDao(database);
  final encryptionService = ref.watch(app_accounting.appFieldEncryptionServiceProvider);
  return TransactionRepositoryImpl(dao: dao, encryptionService: encryptionService);
}
// Generated: transactionRepositoryProvider
```

### `waitForFirstValue<T>` helper (`test/helpers/test_provider_scope.dart`)

[VERIFIED: direct file read]

```dart
Future<AsyncValue<T>> waitForFirstValue<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider,
) { ... }
```

Returns `Future<AsyncValue<T>>`. The caller must unwrap: `final result = await waitForFirstValue<List<TaggedTransaction>>(container, listTransactionsProvider(bookId: 'book1')); expect(result.hasValue, isTrue);`.

### `main_shell_screen.dart` wiring points

[VERIFIED: direct file read]

- **Line 97**: `IndexedStack(index: currentIndex, children: [...])`
- **Line 111**: `Center(child: Text(S.of(context).listTab))` — REPLACE with `ListScreen(bookId: bookId)`
- **Lines 35–91**: `ref.listen(syncStatusStreamProvider, ...)` — add `ref.invalidate(listTransactionsProvider(bookId: bookId))` inside the `wasSyncing && nowDone` block (after line 89)
- **Lines 125–168**: FAB `onFabTap` callback — add `ref.invalidate(listTransactionsProvider(bookId: bookId))` after existing invalidations (before the closing brace at line 168)

### `ShadowBookInfo` fields (Phase 29 seam reference — `lib/features/home/presentation/providers/state_shadow_books.dart`)

[VERIFIED: direct file read]

```dart
class ShadowBookInfo {
  final String memberDisplayName;
  final String memberAvatarEmoji;
  // Phase 29: MemberTag(emoji: info.memberAvatarEmoji, name: info.memberDisplayName)
}
```

### `SelectedTabIndex` naming pattern confirmation

[VERIFIED: state_home.g.dart]

`class SelectedTabIndex` (no Notifier suffix) → generated `selectedTabIndexProvider`. **Therefore `class ListFilter` → generates `listFilterProvider`**.

---

## Naming Collision Analysis

**The collision:** `ListFilterState` is a Freezed data class in `lib/features/list/domain/models/list_filter_state.dart`. If the Riverpod Notifier were also named `ListFilterState`, Riverpod 3's code generation would produce `listFilterStateProvider` but the generated `_$ListFilterState` mixin and the domain Freezed class `_$ListFilterState` would collide — or at minimum require awkward aliased imports everywhere the Notifier is used.

**Resolution:** Name the Notifier class `ListFilter`. Riverpod 3 generator strips no suffix (since there is no `Notifier` suffix), yielding `listFilterProvider`. This avoids any import conflict: the domain type continues to be imported as `ListFilterState`, and the provider is `listFilterProvider`.

| Class name | Generated provider name | Import collision? |
|-----------|------------------------|-------------------|
| `ListFilterState` (AVOID) | `listFilterStateProvider` | Yes — same `_$` mixin stem as Freezed |
| `ListFilter` (RECOMMENDED) | `listFilterProvider` | No |
| `ListFilterController` (alternative) | `listFilterControllerProvider` | No, but longer |

**Recommendation:** Use `class ListFilter` → `listFilterProvider`. This is the least-surprise name and aligns with how `SelectedTabIndex` (not `SelectedTabIndexNotifier`) generates `selectedTabIndexProvider`. [CONFIDENCE: HIGH — verified from Riverpod 3 code generation behavior in state_home.g.dart]

---

## Common Pitfalls

### Pitfall 1: `categoryId` used raw in text search (the ARCHITECTURE.md shortcut bug)

**What goes wrong:** `t.categoryId.toLowerCase().contains(q)` — user searches `'食費'` but `categoryId` is `'cat_food'`. Zero matches.

**Why it happens:** The research ARCHITECTURE.md draft used the raw `categoryId` shortcut. D-04 explicitly corrects this but it's easy to copy the draft.

**How to avoid:** Always call `CategoryLocalizationService.resolveFromId(tx.categoryId, locale)` first, then `.toLowerCase().contains(q)`.

**Warning signs:** Searching by a Japanese category name like `食費` returns zero results in a test where transactions with `categoryId = 'cat_food'` exist.

### Pitfall 2: `activeDayFilter` is `DateTime?`, not `int?`

**What goes wrong:** The ARCHITECTURE.md research draft used `activeDayFilter: int?` (day number). The actual `ListFilterState` uses `DateTime?`. Day-matching code that accesses `.day` directly would fail or give wrong results if treated as `int`.

**Why it happens:** ARCHITECTURE.md was written before Phase 25 locked the field type. The CONTEXT.md summary refers to it correctly but the research draft is inconsistent.

**How to avoid:** The provider's day filter must compare all three date components: `tx.timestamp.year == dayFilter.year && tx.timestamp.month == dayFilter.month && tx.timestamp.day == dayFilter.day`. Do not compare only `.day` (cross-month collision).

**Warning signs:** Day filter shows transactions from the wrong month.

### Pitfall 3: Naming the Notifier class the same as the domain Freezed type

**What goes wrong:** `class ListFilterState` Notifier + `ListFilterState` Freezed type both in scope → Riverpod's generator produces `_$ListFilterState` mixin which collides with Freezed's `_$ListFilterState`; import aliasing required everywhere; `build_runner` may error.

**How to avoid:** Use `class ListFilter` (see Naming Collision Analysis above).

### Pitfall 4: Duplicating `transactionRepositoryProvider` in list feature

**What goes wrong:** `provider_graph_hygiene_test.dart` (CLAUDE.md §Common Pitfalls #10) enforces one `transactionRepositoryProvider`. Adding a second one in `lib/features/list/presentation/providers/repository_providers.dart` breaks the test.

**How to avoid:** Import with `show transactionRepositoryProvider` from the accounting feature providers.

### Pitfall 5: `ref.watch(currentLocaleProvider)` without fallback

**What goes wrong:** `currentLocaleProvider` is an async provider returning `Future<Locale>`. `ref.watch` returns `AsyncValue<Locale>`. Calling `.value!` (throwing getter) panics when still loading. In a `FutureProvider`, this causes the outer provider to stay in loading state longer than necessary.

**How to avoid:** `final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');` — same pattern as `home_screen.dart` line 48.

### Pitfall 6: `ProviderContainer()` without `.test()` in unit tests

**What goes wrong:** Auto-dispose providers are garbage-collected during loading; bare `await container.read(provider.future)` throws `Bad state: disposed during loading`.

**How to avoid:** `ProviderContainer.test(overrides: [...])` + `waitForFirstValue<T>(container, provider)`. [VERIFIED: active_group_provider_test.dart + test_provider_scope.dart]

### Pitfall 7: Pre-existing `flutter analyze` issues are baseline

**What it means:** `flutter analyze` currently reports 4 issues [VERIFIED: direct run]. All 4 are in `firebase_messaging` build artifacts and `category_selection_screen.dart` (pre-existing `deprecated_member_use`). SC#4 "zero issues" means zero NEW issues introduced by Phase 26 — the pre-existing 4 are acceptable baseline. Do not suppress or touch the existing issues.

---

## Runtime State Inventory

Phase 26 is a greenfield provider + screen addition within an existing app. No rename, refactor, or migration.

**Nothing found in any category** — this phase adds new files only and modifies one existing file (`main_shell_screen.dart`). No stored data, live service config, OS-registered state, secrets/env vars, or build artifacts carry state that needs migration.

---

## Environment Availability

All tools are pre-existing; verified from prior phases.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `flutter` CLI | `flutter analyze`, `build_runner`, `flutter test` | ✓ | (project runs) | — |
| `dart` / `build_runner` | Code generation after `@riverpod`/`@freezed` annotations | ✓ | (project runs) | — |
| `mocktail` | SC#3 provider unit tests | ✓ | `^1.0.4` | — |

**No missing dependencies.**

---

## Validation Architecture

nyquist_validation is enabled (config.json `workflow.nyquist_validation: true`).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (built-in) + `mocktail ^1.0.4` |
| Config file | `analysis_options.yaml` (project-level) |
| Quick run command | `flutter test test/unit/features/list/ -x` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FILTER-01 | Text search matches localized category name, merchant, note | unit | `flutter test test/unit/features/list/presentation/providers/list_transactions_provider_test.dart -x` | ❌ Wave 0 |
| FILTER-02 | Ledger filter forwarded to use case; AND-composed | unit | `flutter test test/unit/features/list/presentation/providers/list_transactions_provider_test.dart -x` | ❌ Wave 0 |
| FILTER-03 | categoryId single-value filter forwarded | unit | `flutter test test/unit/features/list/presentation/providers/list_transactions_provider_test.dart -x` | ❌ Wave 0 |
| FILTER-04 | AND-composition + clearAll() resets all fields | unit | `flutter test test/unit/features/list/presentation/providers/list_filter_notifier_test.dart -x` | ❌ Wave 0 |
| SC#1 | listFilterProvider holds all 7 fields in single VO | unit | `flutter test test/unit/features/list/presentation/providers/list_filter_notifier_test.dart -x` | ❌ Wave 0 |
| SC#2 | keepAlive: true in annotation (code, not comment) | static / analyzer | `flutter analyze` | ❌ Wave 0 (check annotation) |
| SC#3 | listTransactionsProvider returns List<TaggedTransaction> with AND-compose | unit | `flutter test test/unit/features/list/presentation/providers/list_transactions_provider_test.dart -x` | ❌ Wave 0 |
| SC#4 | ListScreen reachable, flutter analyze 0 new issues, build_runner clean | build | `flutter analyze && flutter pub run build_runner build --delete-conflicting-outputs` | ❌ Wave 0 |

### SC#3 Test Pattern (mandatory)

```dart
// test/unit/features/list/presentation/providers/list_transactions_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_transactions.dart';
import 'package:home_pocket/application/list/get_list_transactions_use_case.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../../helpers/test_provider_scope.dart';

class _MockGetListTransactionsUseCase extends Mock
    implements GetListTransactionsUseCase {}

void main() {
  test('filters by localized category name', () async {
    final mockUseCase = _MockGetListTransactionsUseCase();
    // stub execute() to return test transactions...
    
    final container = ProviderContainer.test(
      overrides: [
        getListTransactionsUseCaseProvider.overrideWithValue(mockUseCase),
      ],
    );

    final result = await waitForFirstValue<List<TaggedTransaction>>(
      container,
      listTransactionsProvider(bookId: 'book1'),
    );
    expect(result.hasValue, isTrue);
    // assert filtered/unfiltered count
  });
}
```

**Do NOT use** `await container.read(listTransactionsProvider(bookId: 'book1').future)` — Riverpod 3 disposes the orphan read. [VERIFIED: test_provider_scope.dart docstring + active_group_provider_test.dart pattern]

### Sampling Rate
- **Per task commit:** `flutter test test/unit/features/list/ -x`
- **Per wave merge:** `flutter test`
- **Phase gate:** `flutter analyze` (0 new issues) + `flutter pub run build_runner build --delete-conflicting-outputs` (clean diff) before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` — covers SC#1, FILTER-04 (`clearAll`, mutators)
- [ ] `test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` — covers SC#3, FILTER-01/02/03 (AND-compose, text search, category name resolution)
- [ ] `test/unit/features/list/domain/models/tagged_transaction_test.dart` — covers `TaggedTransaction`/`MemberTag` Freezed immutability

No new framework install needed — `flutter_test` and `mocktail` already in `pubspec.yaml`.

---

## Security Domain

No new authentication, session management, access control, or cryptography in this phase. The provider reads existing decrypted `Transaction` domain objects (decryption happens in `TransactionRepositoryImpl._toModel()`, upstream of this phase). Search operates on already-decrypted data in memory.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | Marginal | `searchQuery` is user-controlled text; used only for in-memory `.contains()` — no SQL injection surface (query construction is in the use case, which does not receive `searchQuery`). No sanitization needed beyond `.trim()`. |
| V6 Cryptography | No | No new crypto operations |

**One security note:** Do not log `Transaction.note` or any search results to device logs. CLAUDE.md: "NEVER log sensitive data." The loading spinner in `ListScreen` shows no financial data — no risk there.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `listFilterStateProvider` using `autoDispose` (ARCHITECTURE.md draft) | `keepAlive: true` (D-01) | Phase 26 context | Filter state persists under IndexedStack — no unexpected reset |
| `t.categoryId.toLowerCase().contains(q)` for text search (ARCHITECTURE.md draft) | `CategoryLocalizationService.resolveFromId(categoryId, locale)` (D-04) | Phase 26 context | Correct locale-aware category matching |
| `memberLabel: String?` in TaggedTransaction (ARCHITECTURE.md draft) | `memberTag: MemberTag?` with `{emoji, name}` (D-07) | Phase 26 context | Phase 28 tile needs both emoji + name; VO avoids Phase 29 field split |
| `activeDayFilter: int?` (ARCHITECTURE.md draft) | `activeDayFilter: DateTime?` (Phase 25 actual code) | Phase 25 implementation | Day filter comparison must use all 3 date components |

**Deprecated/outdated:**
- ARCHITECTURE.md `state_list_filter.dart` draft code: uses `activeDayFilter: int`, `@riverpod` (no keepAlive), `class ListFilterState` Notifier name, raw `t.categoryId` search — all superseded by CONTEXT.md decisions + Phase 25 actual output. Do not copy from the draft.

---

## Assumptions Log

> All claims in this research were verified by direct codebase inspection (file reads, grep, build_runner output). No `[ASSUMED]` tags were assigned.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | (empty) | — | — |

**All claims are `[VERIFIED]` from direct file reads or `[CITED]` from CONTEXT.md locked decisions.**

---

## Open Questions (RESOLVED)

> Both questions are resolved by planning (Plan 26-01 T1 creates `lib/features/list/presentation/import_guard.yaml`; PATTERNS.md confirms the presentation import_guard permits domain-model imports). Retained for traceability.

1. **`import_guard.yaml` for `lib/features/list/domain/models/` — update needed for `tagged_transaction.dart`** — RESOLVED: presentation import_guard (analytics analog) denies only `infrastructure/`, `data/daos/`, `data/tables/`; domain-model imports are permitted. No deny-rule conflict.
   - What we know: the current allow-list at `lib/features/list/domain/models/import_guard.yaml` allows `../../../accounting/domain/models/transaction.dart` and `freezed_annotation/**`
   - What's unclear: whether `tagged_transaction.dart` itself needs to be added to the allow-list of `state_list_transactions.dart` in the presentation layer, or if the presentation-layer `import_guard.yaml` (inherited from analytics) already permits domain model imports
   - Recommendation: The presentation layer's `import_guard.yaml` (mirrors analytics) denies `data/daos/**` and `data/tables/**` and `infrastructure/**` but permits domain models. The planner should verify that importing `lib/features/list/domain/models/tagged_transaction.dart` from `lib/features/list/presentation/providers/` does not trigger a deny rule. Based on the analytics presentation layer's `import_guard.yaml` (denies infrastructure/data/daos only), this import should be fine. Low risk.

2. **`list/presentation/import_guard.yaml` — does it need creating?** — RESOLVED: yes. Plan 26-01 T1 creates `lib/features/list/presentation/import_guard.yaml` mirroring analytics (deny `infrastructure/**`, `data/daos/**`, `data/tables/**`, inherit: true).

---

## Sources

### Primary (HIGH confidence — direct file reads)

- `/Users/xinz/Development/home-pocket-app/lib/features/list/domain/models/list_filter_state.dart` — `ListFilterState` 7 fields verified; `activeDayFilter: DateTime?`; `clearAll()`
- `/Users/xinz/Development/home-pocket-app/lib/features/list/domain/models/list_sort_config.dart` — `ListSortConfig` default `updatedAt/desc`
- `/Users/xinz/Development/home-pocket-app/lib/application/list/get_list_transactions_use_case.dart` — `GetListParams` + `execute()`/`watch()` signatures
- `/Users/xinz/Development/home-pocket-app/lib/application/accounting/category_localization_service.dart` — `resolveFromId(categoryId, locale)` static method
- `/Users/xinz/Development/home-pocket-app/lib/features/accounting/presentation/providers/repository_providers.dart` — `transactionRepositoryProvider` at line 87
- `/Users/xinz/Development/home-pocket-app/lib/features/home/presentation/screens/main_shell_screen.dart` — IndexedStack line 97, list placeholder line 111, sync listener lines 35–91, FAB callback lines 125–168
- `/Users/xinz/Development/home-pocket-app/lib/features/home/presentation/screens/home_screen.dart` — `currentLocaleProvider` usage pattern (lines 21, 47)
- `/Users/xinz/Development/home-pocket-app/test/helpers/test_provider_scope.dart` — `waitForFirstValue<T>` signature
- `/Users/xinz/Development/home-pocket-app/lib/features/home/presentation/providers/state_home.g.dart` — `SelectedTabIndex` → `selectedTabIndexProvider` naming convention
- `/Users/xinz/Development/home-pocket-app/lib/features/settings/presentation/providers/state_locale.g.dart` — `currentLocaleProvider` generated name
- `/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/repositories/transaction_repository.dart` — `findByBookIds`/`watchByBookIds` signatures
- `flutter analyze` — 4 pre-existing issues confirmed (firebase_messaging + category_selection_screen); not from Phase 26

### Secondary (MEDIUM confidence — CONTEXT.md locked decisions)

- `.planning/phases/26-providers-shell-wiring/26-CONTEXT.md` — D-01..D-10 decisions
- `.planning/phases/25-domain-models-use-case/25-CONTEXT.md` — D-01..D-06 upstream decisions
- `.planning/research/PITFALLS.md` — Pitfall 2 (IndexedStack + keepAlive), Pitfall 5 (ProviderException), Anti-Patterns table

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages verified in pubspec.yaml; no new packages needed
- Architecture patterns: HIGH — all signatures verified by direct file reads; naming collision confirmed and resolved
- Pitfalls: HIGH — verified from actual code inspection + CONTEXT.md locked decisions
- Test patterns: HIGH — `waitForFirstValue` helper verified; `ProviderContainer.test()` pattern verified from active_group_provider_test.dart

**Research date:** 2026-05-30
**Valid until:** 2026-06-30 (stable Flutter/Riverpod 3 ecosystem; no expiry risk within milestone)
