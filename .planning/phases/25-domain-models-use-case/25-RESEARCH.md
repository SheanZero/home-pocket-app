# Phase 25: Domain Models + Use Case — Research

**Researched:** 2026-05-29
**Domain:** Pure-Dart domain layer — Freezed value objects + use case with Mocktail unit tests
**Confidence:** HIGH

## Summary

Phase 24 delivered all upstream assets exactly as CONTEXT.md claims. Every file cited in `canonical_refs` exists with the exact signatures described. The `SortField`/`SortDirection` enums, `findByBookIds`/`watchByBookIds` interface, `DateBoundaries` utility, and `Result<T>` are all in place and verified against the real source files.

Phase 25 adds three pure-Dart artefacts with zero Riverpod dependency:
1. Two Freezed value objects (`ListSortConfig`, `ListFilterState`) placed in a new `lib/features/list/domain/models/` directory
2. One use case (`GetListTransactionsUseCase` + `GetListParams`) placed in `lib/application/list/`
3. Unit tests verifying SC#3 (empty-bookIds → `Result.error`, repo forwarding) and SC#4 (`copyWith` immutability)

No new external packages are needed. No UI, no Riverpod providers, no DAO changes.

**Primary recommendation:** Follow the `GetTransactionsUseCase` template exactly — constructor injection, `if (params.bookIds.isEmpty) return Result.error(...)`, then forward to `repo.findByBookIds(...)`. Extend with `watch()` throwing `ArgumentError` on empty bookIds. Embed `ListSortConfig` inside `ListFilterState` per D-01.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** `ListFilterState` has exactly 7 fields: `selectedMonth`, `activeDayFilter?`, `sortConfig` (embedded `ListSortConfig`), `ledgerType?`, `categoryId?`, `searchQuery`, `memberBookId?`. Defines `clearAll()` that resets to initial state. Built in full to align with Phase 26 SC#1.
- **D-02:** `categoryId` is single-value `String?`. Aligns with existing repo interface. Multi-category (FILTER-03) deferred to Phase 28.
- **D-03:** Use case exposes both `execute(GetListParams) → Future<Result<List<Transaction>>>` and `watch(GetListParams) → Stream<List<Transaction>>`. `watch()` throws `ArgumentError` synchronously on empty `bookIds`.
- **D-04:** `GetListParams = { List<String> bookIds, ListFilterState filter }`. Use case derives `startDate`/`endDate` from `filter.selectedMonth`/`activeDayFilter` via `DateBoundaries`; takes `ledgerType`, `categoryId`, `sortField`, `sortDirection` from `filter`.
- **D-05:** `searchQuery` is a field in `ListFilterState` but use case does NOT consume it. Actual text matching belongs in Phase 26 provider (in-memory).
- **D-06:** Validation minimized — `execute()` returns `Result.error` only on empty `bookIds`. All other invariants guaranteed by Freezed/`DateBoundaries`.

### Claude's Discretion
- `ListSortConfig` default: `sortField = updatedAt`, `sortDirection = desc` (Phase 26 reference default for SORT-02)
- `ListFilterState` initial state: current month, no day filter, default `ListSortConfig`, other filters null/empty. `clearAll()` resets to this state.
- File placement: Freezed VOs → `lib/features/list/domain/models/`; use case + params → `lib/application/list/`
- SC#4 immutability test structure: `copyWith(sortField: amount)` → assert `!identical(original, copy)` and `original.sortField == timestamp`
- `MockTransactionRepository` construction: Mocktail, mock `findByBookIds`/`watchByBookIds`

### Deferred Ideas (OUT OF SCOPE)
- Multi-category filter (FILTER-03) — Phase 28
- `searchQuery` matching logic — Phase 26
- `memberBookId?` consumption / family filtering — Phase 29
- Pagination / infinite scroll — v1.5
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SORT-01 | User can sort by transaction date | `SortField.timestamp` in `sort_config.dart` [VERIFIED]; `findByBookIds(sortField:)` in repo [VERIFIED]; `ListSortConfig` wraps both enums |
| SORT-02 | User can sort by edit/created time (reference default) | `SortField.updatedAt` [VERIFIED]; default `ListSortConfig` uses `updatedAt` per Claude's Discretion |
| SORT-03 | User can sort by amount | `SortField.amount` [VERIFIED]; covered by same `ListSortConfig` → use case forwarding |
| SORT-04 | User can toggle asc/descending | `SortDirection.asc`/`desc` [VERIFIED]; `ListSortConfig.sortDirection` + `copyWith` covers toggling |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Sort/filter state description | Domain (features/list/domain) | — | Pure value objects, no I/O |
| Filter→query translation | Application (application/list) | — | Use case owns mapping logic; keeps domain lean |
| Data retrieval | Data (TransactionRepository) | — | Already declared in Phase 24; use case delegates |
| Text search matching | NOT this phase | Provider (Phase 26) | Requires locale + decryption, not SQL-able |
| Family book aggregation | NOT this phase | Provider/Screen (Phase 29) | `memberBookId?` field built here, consumed later |

---

## Verified Phase 24 Assets

All files cited in CONTEXT.md `canonical_refs` exist and match the claimed signatures. [VERIFIED: codebase grep]

### `lib/shared/constants/sort_config.dart`
```dart
enum SortField { timestamp, updatedAt, amount }
enum SortDirection { asc, desc }
```
Status: EXISTS, exact values match CONTEXT.md D-01. SC#1 satisfied already.

### `lib/features/accounting/domain/repositories/transaction_repository.dart`

`findByBookIds` signature (abstract — no default values on abstract interface):
```dart
Future<List<Transaction>> findByBookIds(
  List<String> bookIds, {
  LedgerType? ledgerType,
  String? categoryId,
  required DateTime startDate,
  required DateTime endDate,
  SortField sortField,
  SortDirection sortDirection,
});

Stream<List<Transaction>> watchByBookIds(
  List<String> bookIds, {
  LedgerType? ledgerType,
  String? categoryId,
  required DateTime startDate,
  required DateTime endDate,
  SortField sortField,
  SortDirection sortDirection,
});
```

**Important nuance:** The abstract interface has NO default values for `sortField`/`sortDirection`. The implementation (`transaction_repository_impl.dart`) defaults both to `SortField.timestamp, SortDirection.desc`. The use case MUST pass these explicitly when calling the repo — do not rely on defaults that only exist on the implementation.

### `lib/shared/utils/date_boundaries.dart`
```dart
abstract final class DateBoundaries {
  static ({DateTime start, DateTime end}) monthRange(int year, int month) { ... }
  static ({DateTime start, DateTime end}) dayRange(DateTime day) { ... }
}
```
Return type is a **record** `({DateTime start, DateTime end})` — access via `.start` / `.end`.

### `lib/shared/utils/result.dart`
```dart
class Result<T> {
  factory Result.success(T? data) => ...
  factory Result.error(String message) => ...
  bool get isSuccess;
  bool get isError;
  T? data;
  String? error;
}
```

### `lib/features/accounting/domain/models/transaction.dart`
`LedgerType` enum: `{ survival, soul }` — used for `ListFilterState.ledgerType?`

---

## Standard Stack

### Core (all already in pubspec.yaml)
| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `freezed_annotation` | ^3.0.0 | `@freezed` annotation on value objects | [VERIFIED: codebase] |
| `freezed` (dev) | ^3.0.0 | Code generator for `.freezed.dart` | [VERIFIED: codebase] |
| `build_runner` (dev) | ^2.4.14 | Runs code generation | [VERIFIED: codebase] |
| `mocktail` (dev) | ^1.0.4 | Mock generation for unit tests | [VERIFIED: codebase] |
| `flutter_test` (dev) | SDK | Test framework | [VERIFIED: codebase] |

**No new packages required for this phase.**

### Package Legitimacy Audit

> No new packages are installed in this phase. All packages above are existing project dependencies already in pubspec.yaml and verified functional in prior phases.

| Package | Registry | slopcheck | Disposition |
|---------|----------|-----------|-------------|
| freezed_annotation | pub.dev | N/A (existing) | Approved — already in use |
| freezed | pub.dev | N/A (existing) | Approved — already in use |
| mocktail | pub.dev | N/A (existing) | Approved — already in use |

---

## Architecture Patterns

### Established Freezed Pattern (domain models — no JSON serialization)

When a Freezed VO is a pure domain value object that is never serialized to JSON, omit `@JsonSerializable` and the `.g.dart` part declaration. The pattern used in this codebase:

```dart
// Source: lib/features/analytics/domain/models/ledger_snapshot.dart
//         lib/features/analytics/domain/models/time_window.dart (sealed)
//         lib/features/analytics/domain/models/best_joy_moment_row.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'list_sort_config.freezed.dart';
// NO part 'list_sort_config.g.dart'  ← only when @JsonSerializable is NOT needed

@freezed
abstract class ListSortConfig with _$ListSortConfig {
  const factory ListSortConfig({
    required SortField sortField,
    required SortDirection sortDirection,
  }) = _ListSortConfig;
}
```

When JSON serialization IS needed, the pattern adds the `.g.dart` part and `fromJson` factory:
```dart
// Source: lib/features/analytics/domain/models/daily_expense.dart
part 'daily_expense.g.dart';
factory DailyExpense.fromJson(Map<String, dynamic> json) => _$DailyExpenseFromJson(json);
```

**Decision for this phase:** `ListSortConfig` and `ListFilterState` are purely in-memory domain state — they are never persisted directly or sent over the wire. Use the no-JSON pattern (`.freezed.dart` only, no `.g.dart`).

### Use Case Construction Pattern

Direct template from `lib/application/accounting/get_transactions_use_case.dart`:

```dart
// Source: lib/application/accounting/get_transactions_use_case.dart
class GetTransactionsUseCase {
  GetTransactionsUseCase({required TransactionRepository transactionRepository})
    : _transactionRepo = transactionRepository;

  final TransactionRepository _transactionRepo;

  Future<Result<List<Transaction>>> execute(GetTransactionsParams params) async {
    if (params.bookId.isEmpty) {
      return Result.error('bookId must not be empty');
    }
    final transactions = await _transactionRepo.findByBookId(...);
    return Result.success(transactions);
  }
}
```

`GetListTransactionsUseCase` extends this pattern with:
1. `bookIds` (List) emptiness check instead of single bookId
2. `ListFilterState` → query param derivation via `DateBoundaries`
3. `watch()` method for Stream support
4. Both methods share a single `_buildQueryArgs(GetListParams)` private helper

### Mocktail Mock Pattern

```dart
// Source: test/unit/application/accounting/get_transactions_use_case_test.dart
import 'package:mocktail/mocktail.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

void main() {
  late _MockTransactionRepository mockRepo;
  late GetListTransactionsUseCase useCase;

  setUp(() {
    mockRepo = _MockTransactionRepository();
    useCase = GetListTransactionsUseCase(transactionRepository: mockRepo);
  });
  // ...
  test('returns error when bookIds is empty', () async {
    final result = await useCase.execute(GetListParams(
      bookIds: [],
      filter: ListFilterState.initial(),
    ));
    expect(result.isError, isTrue);
    verifyNever(() => mockRepo.findByBookIds(any()));
  });
}
```

**Key Mocktail API used in this codebase:**
- `when(() => mockRepo.findByBookIds(any(), startDate: any(named: 'startDate'), ...)).thenAnswer((_) async => [...])`
- `verify(() => mockRepo.findByBookIds(bookIds, ...)).called(1)`
- `verifyNever(() => mockRepo.findByBookIds(any()))`
- `any(named: 'paramName')` for named optional parameters

### Recommended Project Structure

```
lib/features/list/
└── domain/
    └── models/
        ├── list_sort_config.dart          # @freezed: SortField + SortDirection
        ├── list_sort_config.freezed.dart  # generated
        ├── list_filter_state.dart         # @freezed: 7 fields + clearAll()
        └── list_filter_state.freezed.dart # generated

lib/application/list/
├── get_list_transactions_use_case.dart    # UseCase + GetListParams

test/unit/application/list/
└── get_list_transactions_use_case_test.dart  # SC#3 + SC#4 tests
```

### Anti-Patterns to Avoid
- **Duplicating repo interface in list feature domain:** `TransactionRepository` is already declared in `lib/features/accounting/domain/repositories/`. Do NOT create a new interface in `lib/features/list/domain/`. The use case imports the accounting repo interface directly (cross-feature import from application layer is permitted by `import_guard`).
- **Putting `GetListParams` or use case inside `lib/features/list/`:** Thin Feature rule — business logic lives in `lib/application/list/`, not inside the feature module.
- **Relying on default values from `TransactionRepository` abstract interface:** The abstract interface has no defaults for `sortField`/`sortDirection`. Pass them explicitly.
- **Adding `.g.dart` part for non-serialized VOs:** `ListSortConfig`/`ListFilterState` don't need JSON serialization; skip the `fromJson` factory and `.g.dart` part.
- **Using `watch()` with `Result<T>`:** Stream cannot carry `Result.error`; throw `ArgumentError` synchronously per D-03.

---

## Import Guard Analysis

### `lib/features/list/domain/models/` (new directory)

This directory will follow the same `import_guard` structure as `lib/features/accounting/domain/models/`:

```yaml
# lib/features/accounting/domain/import_guard.yaml (parent deny)
deny:
  - package:home_pocket/data/**
  - package:home_pocket/infrastructure/**
  - package:home_pocket/application/**
  - package:home_pocket/features/**/presentation/**
  - package:flutter/**
```

```yaml
# lib/features/accounting/domain/models/import_guard.yaml (per-subdir allow)
allow:
  - dart:core
  - package:freezed_annotation/**
  - package:json_annotation/**
  - package:meta/**
```

For `lib/features/list/domain/models/`, the allow list needs `sort_config.dart` explicitly:

```yaml
allow:
  - dart:core
  - package:freezed_annotation/**
  - package:home_pocket/shared/constants/sort_config.dart   # SortField/SortDirection
  - package:home_pocket/features/accounting/domain/models/transaction.dart  # LedgerType
```

`lib/shared/constants/sort_config.dart` is on the import_guard allow-list for domain (verified: the accounting `repositories/import_guard.yaml` pattern allows per-file whitelisting for cross-feature domain types).

### `lib/application/list/` (new directory)

Application layer may import domain + infrastructure, but NOT presentation or data tables/DAOs:

```yaml
# lib/application/import_guard.yaml (existing):
deny:
  - package:home_pocket/features/*/presentation/**
  - package:home_pocket/data/tables/**
  - package:home_pocket/data/daos/**
```

`GetListTransactionsUseCase` needs:
- `package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart` — allowed
- `package:home_pocket/features/accounting/domain/models/transaction.dart` — allowed
- `package:home_pocket/features/list/domain/models/list_filter_state.dart` — allowed (feature domain)
- `package:home_pocket/shared/utils/result.dart` — allowed
- `package:home_pocket/shared/utils/date_boundaries.dart` — allowed

All imports comply with existing application-layer rules.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Value object immutability + `copyWith` | Manual `copyWith` | `@freezed` | Freezed generates correct deep-copy, `==`, `hashCode`, `toString` |
| Month boundary arithmetic | Custom `DateTime` math | `DateBoundaries.monthRange()` | Already built in Phase 24; avoids month-end overflow bugs |
| Day boundary arithmetic | Custom `DateTime` math | `DateBoundaries.dayRange()` | Same utility; handles time stripping correctly |
| Mock repository for tests | Manual stub class | Mocktail `extends Mock implements Repo` | Project standard; all existing use case tests use this pattern |

---

## Common Pitfalls

### Pitfall 1: Missing import_guard.yaml for new list domain directory
**What goes wrong:** `flutter analyze` or CI `import_guard` lint runs and finds missing config — or worse, missing config allows imports that violate layer rules silently.
**Why it happens:** New directory without parent `import_guard.yaml` inheriting deny rules.
**How to avoid:** Create `lib/features/list/domain/import_guard.yaml` (deny block) + `lib/features/list/domain/models/import_guard.yaml` (allow block) following the exact pattern from `lib/features/accounting/domain/`.

### Pitfall 2: Abstract interface missing default values for sortField/sortDirection
**What goes wrong:** Use case calls `repo.findByBookIds(bookIds, startDate: ..., endDate: ...)` omitting `sortField`/`sortDirection` — compile error because abstract interface has no defaults.
**Why it happens:** Looking at the implementation (`transaction_repository_impl.dart`) which HAS defaults, not the abstract interface.
**How to avoid:** Always pass `sortField` and `sortDirection` explicitly in the use case. Derive them from `params.filter.sortConfig`.

### Pitfall 3: watch() returning Result or trying to handle empty-bookIds via Stream.error
**What goes wrong:** `Stream.error(...)` propagates as an async error event, not a synchronous validation failure — provider in Phase 26 would need `StreamController` error handling, breaking the thin-provider contract.
**Why it happens:** Copying `execute()` pattern to `watch()` without accounting for Stream type.
**How to avoid:** Per D-03: `watch()` throws `ArgumentError` synchronously before returning the Stream if `bookIds.isEmpty`.

### Pitfall 4: Forgetting to run build_runner after adding Freezed files
**What goes wrong:** `flutter analyze` reports `Target of URI doesn't exist: 'list_sort_config.freezed.dart'`.
**Why it happens:** `.freezed.dart` is generated, not hand-written.
**How to avoid:** Run `flutter pub run build_runner build --delete-conflicting-outputs` after creating `list_sort_config.dart` and `list_filter_state.dart`.

### Pitfall 5: Using `@freezed` sealed class when simple value object is needed
**What goes wrong:** Unnecessary complexity; sealed unions need exhaustive `when`/`map` at call sites.
**Why it happens:** Copying `TimeWindow` (sealed) instead of `DailyExpense` (simple value object).
**How to avoid:** `ListSortConfig` and `ListFilterState` are simple value objects — use `@freezed abstract class ... { const factory ... = _...; }` without `sealed`. Only `TimeWindow` uses `sealed` because it has multiple variants.

### Pitfall 6: Placing list domain models in accounting feature
**What goes wrong:** `ListFilterState` ends up in `lib/features/accounting/domain/models/` — creates coupling between accounting and list features, violates feature boundary.
**How to avoid:** Create the new `lib/features/list/` module as instructed. Mirror the `features/analytics/` directory structure.

---

## Code Examples

### ListSortConfig (no JSON serialization)
```dart
// Target file: lib/features/list/domain/models/list_sort_config.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:home_pocket/shared/constants/sort_config.dart';

part 'list_sort_config.freezed.dart';

@freezed
abstract class ListSortConfig with _$ListSortConfig {
  const factory ListSortConfig({
    @Default(SortField.updatedAt) SortField sortField,
    @Default(SortDirection.desc) SortDirection sortDirection,
  }) = _ListSortConfig;

  static const ListSortConfig initial = ListSortConfig();
}
```

### ListFilterState (7 fields, no JSON serialization)
```dart
// Target file: lib/features/list/domain/models/list_filter_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
// imports for ListSortConfig, LedgerType...

part 'list_filter_state.freezed.dart';

@freezed
abstract class ListFilterState with _$ListFilterState {
  const ListFilterState._();

  const factory ListFilterState({
    required int selectedYear,
    required int selectedMonth,
    DateTime? activeDayFilter,
    @Default(ListSortConfig()) ListSortConfig sortConfig,
    LedgerType? ledgerType,
    String? categoryId,
    @Default('') String searchQuery,
    String? memberBookId,
  }) = _ListFilterState;

  factory ListFilterState.initial() => ListFilterState(
    selectedYear: DateTime.now().year,
    selectedMonth: DateTime.now().month,
  );

  ListFilterState clearAll() => ListFilterState.initial();
}
```

**Note:** `selectedMonth` alone is insufficient — the use case also needs the year to call `DateBoundaries.monthRange(year, month)`. The `ListFilterState` must carry `selectedYear` as well, or encode month as `DateTime` (year+month). The most explicit approach is separate `selectedYear` + `selectedMonth` int fields.

### GetListParams + use case skeleton
```dart
// Target file: lib/application/list/get_list_transactions_use_case.dart
class GetListParams {
  const GetListParams({required this.bookIds, required this.filter});
  final List<String> bookIds;
  final ListFilterState filter;
}

class GetListTransactionsUseCase {
  GetListTransactionsUseCase({required TransactionRepository transactionRepository})
    : _repo = transactionRepository;

  final TransactionRepository _repo;

  Future<Result<List<Transaction>>> execute(GetListParams params) async {
    if (params.bookIds.isEmpty) {
      return Result.error('bookIds must not be empty');
    }
    final (startDate: start, endDate: end) = _dateRange(params.filter);
    final txs = await _repo.findByBookIds(
      params.bookIds,
      ledgerType: params.filter.ledgerType,
      categoryId: params.filter.categoryId,
      startDate: start,
      endDate: end,
      sortField: params.filter.sortConfig.sortField,
      sortDirection: params.filter.sortConfig.sortDirection,
    );
    return Result.success(txs);
  }

  Stream<List<Transaction>> watch(GetListParams params) {
    if (params.bookIds.isEmpty) {
      throw ArgumentError('bookIds must not be empty');
    }
    final (startDate: start, endDate: end) = _dateRange(params.filter);
    return _repo.watchByBookIds(
      params.bookIds,
      ledgerType: params.filter.ledgerType,
      categoryId: params.filter.categoryId,
      startDate: start,
      endDate: end,
      sortField: params.filter.sortConfig.sortField,
      sortDirection: params.filter.sortConfig.sortDirection,
    );
  }

  ({DateTime startDate, DateTime endDate}) _dateRange(ListFilterState filter) {
    if (filter.activeDayFilter != null) {
      final r = DateBoundaries.dayRange(filter.activeDayFilter!);
      return (startDate: r.start, endDate: r.end);
    }
    final r = DateBoundaries.monthRange(filter.selectedYear, filter.selectedMonth);
    return (startDate: r.start, endDate: r.end);
  }
}
```

### SC#3 + SC#4 Test Pattern
```dart
// Target file: test/unit/application/list/get_list_transactions_use_case_test.dart
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

void main() {
  late _MockTransactionRepository mockRepo;
  late GetListTransactionsUseCase useCase;
  final baseFilter = ListFilterState.initial();

  setUp(() {
    mockRepo = _MockTransactionRepository();
    useCase = GetListTransactionsUseCase(transactionRepository: mockRepo);
  });

  // SC#3: empty bookIds → Result.error, repo never called
  test('execute returns error when bookIds is empty', () async {
    final result = await useCase.execute(
      GetListParams(bookIds: [], filter: baseFilter),
    );
    expect(result.isError, isTrue);
    verifyNever(() => mockRepo.findByBookIds(any()));
  });

  // SC#3: valid params forwarded to repo
  test('execute forwards validated params to repository', () async {
    when(() => mockRepo.findByBookIds(
      ['book_1'],
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
      sortField: any(named: 'sortField'),
      sortDirection: any(named: 'sortDirection'),
    )).thenAnswer((_) async => []);

    final result = await useCase.execute(
      GetListParams(bookIds: ['book_1'], filter: baseFilter),
    );
    expect(result.isSuccess, isTrue);
    verify(() => mockRepo.findByBookIds(['book_1'],
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
      sortField: SortField.updatedAt,
      sortDirection: SortDirection.desc,
    )).called(1);
  });

  // SC#4: Freezed copyWith immutability
  test('copyWith produces new immutable instance without mutating original', () {
    final original = ListSortConfig(
      sortField: SortField.timestamp,
      sortDirection: SortDirection.desc,
    );
    final copy = original.copyWith(sortField: SortField.amount);

    expect(identical(original, copy), isFalse);
    expect(original.sortField, SortField.timestamp);  // original unchanged
    expect(copy.sortField, SortField.amount);
  });
}
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Single `bookId` in use case | `List<String> bookIds` (multi-book) | Phase 24 already delivers this; use case extends it |
| Flat scalar params | `GetListParams` composite VO | Cleaner use case API; all filter state in one object |
| No `watch()` in accounting use case | `watch()` for reactive list | LIST-02 reactive stream; Phase 26 provider uses it |

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK) + mocktail ^1.0.4 |
| Config file | pubspec.yaml `flutter.test` — no separate config |
| Quick run command | `flutter test test/unit/application/list/ --no-pub` |
| Full suite command | `flutter test --no-pub` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SORT-01 | `SortField.timestamp` forwarded to repo | unit | `flutter test test/unit/application/list/get_list_transactions_use_case_test.dart` | ❌ Wave 0 |
| SORT-02 | Default sort is `updatedAt` + `desc` | unit | same file | ❌ Wave 0 |
| SORT-03 | `SortField.amount` forwarded to repo | unit | same file | ❌ Wave 0 |
| SORT-04 | `SortDirection.asc`/`desc` toggle via `copyWith` | unit (SC#4) | same file | ❌ Wave 0 |
| SC#3 | Empty `bookIds` → `Result.error`, repo not called | unit | same file | ❌ Wave 0 |
| SC#3 | Valid params forwarded to `findByBookIds` | unit | same file | ❌ Wave 0 |
| SC#4 | `copyWith` produces new instance, original unchanged | unit | same file | ❌ Wave 0 |
| SC#2 | `build_runner` produces `.freezed.dart` without errors | build (manual) | `flutter pub run build_runner build --delete-conflicting-outputs` | N/A |
| SC#2 | `flutter analyze` 0 issues on new files | static analysis | `flutter analyze lib/features/list/ lib/application/list/` | N/A |

### Sampling Rate
- **Per task commit:** `flutter test test/unit/application/list/ --no-pub`
- **Per wave merge:** `flutter test --no-pub && flutter analyze`
- **Phase gate:** Full suite + `flutter analyze` 0 issues before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/unit/application/list/get_list_transactions_use_case_test.dart` — covers SC#3, SC#4, SORT-01..04 forwarding
- [ ] `lib/features/list/domain/models/list_sort_config.dart` + `.freezed.dart` (generated)
- [ ] `lib/features/list/domain/models/list_filter_state.dart` + `.freezed.dart` (generated)
- [ ] `lib/application/list/get_list_transactions_use_case.dart`
- [ ] `lib/features/list/domain/import_guard.yaml` + `models/import_guard.yaml`
- [ ] `lib/application/list/` directory (new — no existing files)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | partial | Empty `bookIds` validated in use case; Freezed enforces required fields |
| V6 Cryptography | no | — (encrypted fields decrypted by repo layer, not this phase) |

This is a pure domain / application layer phase with no crypto operations, no user-facing input, and no direct data access. Security surface is minimal.

---

## Environment Availability

> This phase is purely code/config changes — new Dart files, no external services or CLIs beyond the standard Flutter toolchain.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All build/test commands | ✓ | (project already running) | — |
| build_runner | Code generation | ✓ | ^2.4.14 (in pubspec) | — |
| mocktail | Unit tests | ✓ | ^1.0.4 (in pubspec) | — |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `ListFilterState` should carry `selectedYear` as a separate int field alongside `selectedMonth` (since `DateBoundaries.monthRange` requires both) | Code Examples | If year is derived from app context instead, the field design changes — but carrying year is safer and consistent with analytics `TimeWindow.MonthWindow(year:, month:)` |
| A2 | `ListSortConfig` can use `@Default(SortField.updatedAt)` inside a `const factory` Freezed constructor | Code Examples | Freezed ^3.0 supports `@Default` on enum values — verified on existing Transaction model `@Default(EntrySource.manual)` [VERIFIED: codebase] |

---

## Open Questions (RESOLVED)

1. **`selectedYear` in `ListFilterState`** — RESOLVED (locked in plan 25-01 Task 2)
   - What we know: `DateBoundaries.monthRange(year, month)` requires both year and month
   - What was unclear: Whether the intent is `selectedYear + selectedMonth` as separate ints, or a `DateTime` month anchor (year/month only), or a `(year, month)` record
   - **Resolution:** Use `selectedYear: int` + `selectedMonth: int` (separate ints) — mirrors `TimeWindow.MonthWindow(year:, month:)` in analytics and avoids DateTime confusion. Plan 25-01 Task 2 action specifies `required int selectedYear, required int selectedMonth`.

2. **`clearAll()` — should `selectedYear`/`selectedMonth` reset to current date?** — RESOLVED (locked in plan 25-01 Task 2)
   - What we know: CONTEXT.md says `clearAll()` resets to initial state; initial = current month
   - What was unclear: Whether "current month" is captured at construction time or re-evaluated on `clearAll()`
   - **Resolution:** `clearAll()` returns `ListFilterState.initial()`, which re-evaluates `DateTime.now()` — conservative and consistent with UX (clears back to "today's month"). Plan 25-01 Task 2 action specifies `factory ListFilterState.initial() => ... DateTime.now().year / DateTime.now().month`.

---

## Sources

### Primary (HIGH confidence)
- `/Users/xinz/Development/home-pocket-app/lib/shared/constants/sort_config.dart` — SortField, SortDirection enums [VERIFIED: direct read]
- `/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/repositories/transaction_repository.dart` — findByBookIds/watchByBookIds signatures [VERIFIED: direct read]
- `/Users/xinz/Development/home-pocket-app/lib/application/accounting/get_transactions_use_case.dart` — use case template [VERIFIED: direct read]
- `/Users/xinz/Development/home-pocket-app/lib/shared/utils/result.dart` — Result<T> API [VERIFIED: direct read]
- `/Users/xinz/Development/home-pocket-app/lib/shared/utils/date_boundaries.dart` — DateBoundaries API [VERIFIED: direct read]
- `/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/models/transaction.dart` — Transaction + LedgerType [VERIFIED: direct read]
- `/Users/xinz/Development/home-pocket-app/lib/data/repositories/transaction_repository_impl.dart` — default sortField/sortDirection on impl [VERIFIED: direct read]
- `/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/import_guard.yaml` — domain layer deny rules [VERIFIED: direct read]
- `/Users/xinz/Development/home-pocket-app/lib/features/accounting/domain/models/import_guard.yaml` — domain models allow rules [VERIFIED: direct read]
- `/Users/xinz/Development/home-pocket-app/lib/application/import_guard.yaml` — application layer deny rules [VERIFIED: direct read]
- `/Users/xinz/Development/home-pocket-app/test/unit/application/accounting/get_transactions_use_case_test.dart` — Mocktail test pattern [VERIFIED: direct read]

### Secondary (MEDIUM confidence)
- Analytics Freezed models (BestJoyMomentRow, LedgerSnapshot, TimeWindow) — no-JSON pattern confirmed [VERIFIED: codebase grep + direct read]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages already installed and in use
- Architecture: HIGH — all upstream assets verified in real files; patterns confirmed from 3+ examples
- Pitfalls: HIGH — derived from real import_guard configs and actual interface signatures
- Test strategy: HIGH — mirrors existing test pattern exactly

**Research date:** 2026-05-29
**Valid until:** 2026-06-28 (stable domain; Freezed 3.x API unlikely to change)
