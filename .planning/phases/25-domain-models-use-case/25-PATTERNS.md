# Phase 25: Domain Models + Use Case — Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 7 (5 source + 2 config)
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/features/list/domain/models/list_sort_config.dart` | model (Freezed VO) | transform | `lib/features/analytics/domain/models/best_joy_moment_row.dart` | exact — no-JSON Freezed VO, simple value object |
| `lib/features/list/domain/models/list_filter_state.dart` | model (Freezed VO) | transform | `lib/features/analytics/domain/models/time_window.dart` (custom extension method) + `best_joy_moment_row.dart` (base shape) | role-match — plain Freezed VO with a computed method; NOT sealed |
| `lib/application/list/get_list_transactions_use_case.dart` | use case | CRUD + streaming | `lib/application/accounting/get_transactions_use_case.dart` | exact — constructor injection + empty-id guard + Result + repo delegation |
| `lib/features/list/domain/import_guard.yaml` | config | — | `lib/features/accounting/domain/import_guard.yaml` | exact — identical deny block + inherit:true |
| `lib/features/list/domain/models/import_guard.yaml` | config | — | `lib/features/accounting/domain/models/import_guard.yaml` | role-match — same structure; allow list must include `sort_config.dart` and `transaction.dart` |
| `test/unit/application/list/get_list_transactions_use_case_test.dart` | test | request-response | `test/unit/application/accounting/get_transactions_use_case_test.dart` | exact — Mocktail mock, group/test structure, when/verify/verifyNever |

---

## Pattern Assignments

### `lib/features/list/domain/models/list_sort_config.dart` (model, transform)

**Analog:** `lib/features/analytics/domain/models/best_joy_moment_row.dart`

**Imports pattern** (analog lines 1–3):
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'best_joy_moment_row.freezed.dart';
// NO part '*.g.dart' — no JSON serialization needed
```

**Core Freezed VO pattern** (analog lines 7–16):
```dart
@freezed
abstract class BestJoyMomentRow with _$BestJoyMomentRow {
  const factory BestJoyMomentRow({
    required String transactionId,
    required int amount,
    // ... required fields
  }) = _BestJoyMomentRow;
}
```

**Adapt for `ListSortConfig`:** replace `BestJoyMomentRow` with `ListSortConfig`; add import for `sort_config.dart`; use `@Default` annotation for optional enum fields with defaults. Add `static const ListSortConfig initial = ListSortConfig()` as a named constant for easy construction with defaults.

**`@Default` on enum field — verified pattern** (from `lib/features/accounting/domain/models/transaction.dart` lines 39, 49):
```dart
@Default(false) bool isPrivate,
@Default(EntrySource.manual) EntrySource entrySource,
```
Same syntax applies to enum defaults: `@Default(SortField.updatedAt) SortField sortField`.

---

### `lib/features/list/domain/models/list_filter_state.dart` (model, transform)

**Primary analog:** `lib/features/analytics/domain/models/best_joy_moment_row.dart` (base Freezed shape)
**Secondary analog:** `lib/features/analytics/domain/models/time_window.dart` (custom method on Freezed class via `const MyClass._()` private constructor)

**No-JSON Freezed VO pattern** — same as `list_sort_config.dart` above. Only `.freezed.dart` part, no `.g.dart`.

**Private constructor for custom methods** (analog `time_window.dart` lines 11, 44–77 — TimeWindow uses `sealed`; ListFilterState uses plain `abstract class` but same trick):
```dart
// time_window.dart lines 11-12
sealed class TimeWindow with _$TimeWindow {
  const TimeWindow._();  // ← private constructor enables custom methods
```

For `ListFilterState` (simple value object, NOT sealed):
```dart
@freezed
abstract class ListFilterState with _$ListFilterState {
  const ListFilterState._();   // ← enables clearAll() instance method

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
```

**Named factory for initial state** — pattern from RESEARCH.md Code Examples (verified against project conventions for `factory ClassName.initial()`):
```dart
  factory ListFilterState.initial() => ListFilterState(
    selectedYear: DateTime.now().year,
    selectedMonth: DateTime.now().month,
  );
```

**Custom instance method via private constructor** — `clearAll()` delegates to the named factory:
```dart
  ListFilterState clearAll() => ListFilterState.initial();
```

**`selectedYear` rationale:** `DateBoundaries.monthRange(year, month)` signature requires both year and month (verified: `lib/shared/utils/date_boundaries.dart` line 30). Mirror of `TimeWindow.MonthWindow(year:, month:)` pattern.

---

### `lib/application/list/get_list_transactions_use_case.dart` (use case, CRUD + streaming)

**Analog:** `lib/application/accounting/get_transactions_use_case.dart` (all 52 lines)

**Imports pattern** (analog lines 1–3):
```dart
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../shared/utils/result.dart';
```

**Additional imports needed for `GetListTransactionsUseCase`:**
```dart
import '../../features/list/domain/models/list_filter_state.dart';
import '../../shared/utils/date_boundaries.dart';
```

**Params class pattern** (analog lines 6–24):
```dart
class GetTransactionsParams {
  final String bookId;
  // ...scalar fields...

  const GetTransactionsParams({
    required this.bookId,
    // ...
  });
}
```
Adapt: replace with `List<String> bookIds` + `ListFilterState filter` composite.

**Constructor injection pattern** (analog lines 27–30):
```dart
class GetTransactionsUseCase {
  GetTransactionsUseCase({required TransactionRepository transactionRepository})
    : _transactionRepo = transactionRepository;

  final TransactionRepository _transactionRepo;
```

**Empty-id guard + Result pattern** (analog lines 33–38):
```dart
  Future<Result<List<Transaction>>> execute(
    GetTransactionsParams params,
  ) async {
    if (params.bookId.isEmpty) {
      return Result.error('bookId must not be empty');
    }
```
Adapt: `params.bookIds.isEmpty` check; keep same error string style.

**Repo delegation + Result.success pattern** (analog lines 40–51):
```dart
    final transactions = await _transactionRepo.findByBookId(
      params.bookId,
      ledgerType: params.ledgerType,
      // ...
    );
    return Result.success(transactions);
```
Adapt: use `findByBookIds` (plural) with named params derived from `params.filter`.

**`watch()` method — no analog in accounting use case** (new pattern, from RESEARCH.md D-03):
- Return `Stream<List<Transaction>>` — NOT `Stream<Result<...>>`
- Throw `ArgumentError` synchronously if `bookIds.isEmpty`
- Delegate to `_repo.watchByBookIds(...)` with same named params

**Repo interface has NO defaults for `sortField`/`sortDirection`** (verified from `lib/features/accounting/domain/repositories/transaction_repository.dart`): always pass `sortField` and `sortDirection` explicitly when calling the repo.

**`_dateRange` private helper** — derive `startDate`/`endDate` from filter fields using `DateBoundaries` (verified: `lib/shared/utils/date_boundaries.dart` lines 30–52). Return a named record `({DateTime startDate, DateTime endDate})`:
```dart
({DateTime startDate, DateTime endDate}) _dateRange(ListFilterState filter) {
  if (filter.activeDayFilter != null) {
    final r = DateBoundaries.dayRange(filter.activeDayFilter!);
    return (startDate: r.start, endDate: r.end);
  }
  final r = DateBoundaries.monthRange(filter.selectedYear, filter.selectedMonth);
  return (startDate: r.start, endDate: r.end);
}
```

**`delete_transaction_use_case.dart` supplementary pattern** (lines 7–14 — multiple optional constructor params):
```dart
  DeleteTransactionUseCase({
    required TransactionRepository transactionRepository,
    SyncEngine? syncEngine,
    TransactionChangeTracker? changeTracker,
  }) : _transactionRepo = transactionRepository,
```
Confirms the named `required` parameter + field alias initializer style.

---

### `lib/features/list/domain/import_guard.yaml` (config)

**Analog:** `lib/features/accounting/domain/import_guard.yaml` (all 15 lines)

**Exact pattern to copy** (analog lines 1–15):
```yaml
# Domain layer — leafmost in the dependency graph (CRIT-04 territory).
# Per Phase 3 D-01 (corrected per 03-RESEARCH.md §"Pattern 1"):
# allow whitelist moved to per-subdirectory yamls because import_guard_custom_lint
# evaluates each config in the chain independently against its own allow whitelist
# (verified at ~/.pub-cache/hosted/pub.dev/import_guard_custom_lint-1.0.0/lib/src/import_guard_lint.dart:71-94).
# Parent owns deny only; children own the whitelist.
deny:
  - package:home_pocket/data/**
  - package:home_pocket/infrastructure/**
  - package:home_pocket/application/**
  - package:home_pocket/features/**/presentation/**
  - package:flutter/**

inherit: true
# NOTE: no `allow:` block — see models/import_guard.yaml and repositories/import_guard.yaml
```

Copy verbatim; update comment to reference `list` feature context.

---

### `lib/features/list/domain/models/import_guard.yaml` (config)

**Analog:** `lib/features/accounting/domain/models/import_guard.yaml` (all 11 lines)

**Analog pattern** (all 11 lines):
```yaml
# Per-subdirectory whitelist (Phase 3 D-01 corrected). Inherits parent feature-level deny.
allow:
  - dart:core
  - package:freezed_annotation/**
  - package:json_annotation/**
  - package:meta/**
  - transaction.dart                 # closes LV-001 (category_ledger_config.dart), ...
  - category.dart                    # closes LV-002 (category_reorder_state.dart)

inherit: true
```

**Adapt for `list/domain/models/`:** The allow list needs two cross-feature package imports instead of relative file names:
```yaml
allow:
  - dart:core
  - package:freezed_annotation/**
  - package:home_pocket/shared/constants/sort_config.dart   # SortField/SortDirection
  - package:home_pocket/features/accounting/domain/models/transaction.dart  # LedgerType

inherit: true
```

**Key difference from accounting analog:** accounting's allow list uses bare relative filenames (`transaction.dart`) for same-directory cross-references. For cross-feature package imports, use full `package:home_pocket/...` paths. See the `lib/features/analytics/domain/repositories/import_guard.yaml` precedent if additional verification is needed.

---

### `test/unit/application/list/get_list_transactions_use_case_test.dart` (test, request-response)

**Analog:** `test/unit/application/accounting/get_transactions_use_case_test.dart` (all 98 lines)

**Imports pattern** (analog lines 1–5):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/get_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:mocktail/mocktail.dart';
```
Adapt: swap `accounting` paths to `list` paths; add `list_sort_config.dart` and `list_filter_state.dart` imports.

**Mock class pattern** (analog lines 7–8):
```dart
class _MockTransactionRepository extends Mock
    implements TransactionRepository {}
```
Copy verbatim — same repo interface.

**Test fixture pattern** (analog lines 10–17):
```dart
void main() {
  late _MockTransactionRepository mockRepo;
  late GetTransactionsUseCase useCase;

  setUp(() {
    mockRepo = _MockTransactionRepository();
    useCase = GetTransactionsUseCase(transactionRepository: mockRepo);
  });
```

**`makeTransaction` helper** (analog lines 19–32): copy and adapt (same `Transaction` model fields).

**`group(...)` wrapper pattern** (analog line 34): wrap tests in a named `group('GetListTransactionsUseCase', ...)`.

**`when` / `thenAnswer` pattern** (analog lines 37–43):
```dart
when(
  () => mockRepo.findByBookId(
    'book_001',
    limit: any(named: 'limit'),
    offset: any(named: 'offset'),
  ),
).thenAnswer((_) async => txList);
```
Adapt: use `findByBookIds` (list variant); use `any(named: 'startDate')`, `any(named: 'endDate')`, `any(named: 'sortField')`, `any(named: 'sortDirection')` for named optional params.

**`verifyNever` pattern for empty-id guard** (analog lines 91–96):
```dart
test('returns error when bookId is empty', () async {
  final result = await useCase.execute(GetTransactionsParams(bookId: ''));

  expect(result.isError, isTrue);
  verifyNever(() => mockRepo.findByBookId(any()));
});
```

**SC#4 `copyWith` immutability test** — no analog in existing use case test; use `identical()` check:
```dart
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
```

---

## Shared Patterns

### Freezed No-JSON Value Object (apply to both `ListSortConfig` and `ListFilterState`)
**Source:** `lib/features/analytics/domain/models/best_joy_moment_row.dart` (full file, 16 lines)
**Pattern:**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_name.freezed.dart';
// NO part 'class_name.g.dart'  ← omit when no JSON serialization

@freezed
abstract class ClassName with _$ClassName {
  const factory ClassName({
    required FieldType field,
  }) = _ClassName;
}
```

### `@Default` on Enum Fields (apply to `ListSortConfig` and `ListFilterState`)
**Source:** `lib/features/accounting/domain/models/transaction.dart` lines 39–49
```dart
@Default(EntrySource.manual) EntrySource entrySource,
@Default(false) bool isPrivate,
```
Same syntax: `@Default(SortField.updatedAt) SortField sortField`.

### Private Constructor for Custom Instance Methods (apply to `ListFilterState`)
**Source:** `lib/features/analytics/domain/models/time_window.dart` line 11
```dart
const TimeWindow._();
```
Enables declaring instance methods (`clearAll()`, `get range`) on a Freezed class. Must be declared **before** the `const factory` constructor line.

### Use Case Constructor Injection + `Result<T>` Pattern
**Source:** `lib/application/accounting/get_transactions_use_case.dart` lines 27–51
```dart
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

### Mocktail Test Boilerplate
**Source:** `test/unit/application/accounting/get_transactions_use_case_test.dart` lines 1–17
```dart
import 'package:mocktail/mocktail.dart';
class _MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late _MockTransactionRepository mockRepo;
  late GetTransactionsUseCase useCase;
  setUp(() {
    mockRepo = _MockTransactionRepository();
    useCase = GetTransactionsUseCase(transactionRepository: mockRepo);
  });
```

### `import_guard.yaml` Deny-Only Parent / Allow-List Child Pair
**Source parent:** `lib/features/accounting/domain/import_guard.yaml` (15 lines)
**Source child:** `lib/features/accounting/domain/models/import_guard.yaml` (11 lines)

Key structural rule: parent has `deny:` only (no `allow:`); child subdirectory has `allow:` only; both have `inherit: true`.

---

## No Analog Found

All files have analogs. The only truly new pattern element is the `watch()` method on the use case — no existing use case in the codebase exposes a `Stream` variant. The pattern (synchronous `ArgumentError` throw on bad input + direct `_repo.watchByBookIds(...)` delegation) is derived from D-03 in CONTEXT.md and the verified `watchByBookIds` repo interface signature.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/application/list/` (directory) | — | — | Entire `lib/application/list/` directory is new; no existing `lib/application/list/*.dart` files. Structure mirrors `lib/application/accounting/`. |

---

## Metadata

**Analog search scope:** `lib/application/accounting/`, `lib/features/accounting/domain/`, `lib/features/analytics/domain/models/`, `lib/shared/utils/`, `lib/shared/constants/`, `test/unit/application/accounting/`
**Files scanned:** 13 source files + 5 config files
**Pattern extraction date:** 2026-05-29
