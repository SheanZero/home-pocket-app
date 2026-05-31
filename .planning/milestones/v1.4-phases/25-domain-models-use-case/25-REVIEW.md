---
phase: 25-domain-models-use-case
reviewed: 2026-05-29T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - lib/application/list/get_list_transactions_use_case.dart
  - lib/features/list/domain/models/list_filter_state.dart
  - lib/features/list/domain/models/list_sort_config.dart
  - lib/features/list/domain/import_guard.yaml
  - lib/features/list/domain/models/import_guard.yaml
  - test/unit/application/list/get_list_transactions_use_case_test.dart
findings:
  critical: 0
  warning: 4
  info: 5
  total: 9
status: issues_found
---

# Phase 25: Code Review Report

**Reviewed:** 2026-05-29T00:00:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Reviewed two Freezed value objects (`ListFilterState`, `ListSortConfig`), the
application-layer `GetListTransactionsUseCase` + `GetListParams`, two
`import_guard.yaml` layer-boundary configs, and the Mocktail unit-test suite.

Architecture and layering are clean: the use case sits in `lib/application/`,
domain VOs sit in `lib/features/list/domain/models/`, the use case depends only
on the domain repository interface, and the import_guard configs match the
reference `accounting/domain` structure. Immutability is correctly delegated to
Freezed `copyWith`. No security-relevant surface exists in these files (no I/O,
no string-built SQL, no secrets) — `SortField`/`SortDirection` are compile-time
enums forwarded by value, so the ORDER BY injection vector is closed by design.

No blockers. The concerns are correctness-adjacent test gaps and robustness
issues: a non-deterministic test fixture, filter fields that are silently
dropped without a test proving forwarding, and an under-constrained set of
Mocktail stubs that would pass even if the use case forwarded the wrong
filter values.

## Warnings

### WR-01: Non-deterministic test fixture — `baseFilter` built from `DateTime.now()`

**File:** `test/unit/application/list/get_list_transactions_use_case_test.dart:17`
**Issue:** `final baseFilter = ListFilterState.initial();` is evaluated once at
suite-load time, and `ListFilterState.initial()`
(`list_filter_state.dart:36-39`) reads `DateTime.now().year` / `.month`. Every
`execute`/`watch` test therefore derives its `startDate`/`endDate` from the
wall-clock month at the moment the test process started. The tests pass today
only because `startDate`/`endDate` are matched with `any(named: ...)` — the
date range is never asserted. This is a latent flake: the day this suite is run
near a month boundary, or the day someone tightens the date matchers to a
concrete value, the fixture silently changes meaning. Domain-model tests should
not depend on the calendar.
**Fix:** Pin the anchor explicitly so the date range is deterministic:
```dart
final baseFilter = ListFilterState.initial().copyWith(
  selectedYear: 2026,
  selectedMonth: 5,
);
```
…and add at least one assertion that pins the derived range (see WR-02).

### WR-02: No test proves `startDate`/`endDate` are derived correctly

**File:** `test/unit/application/list/get_list_transactions_use_case_test.dart:51-233`
**Issue:** Every `when()`/`verify()` matches `startDate`/`endDate` with
`any(named: ...)`. The entire `_dateRange` logic
(`get_list_transactions_use_case.dart:92-103`) — the month-vs-day branch, the
`activeDayFilter` precedence, and the `DateBoundaries` call — is therefore
completely unverified. A regression that swaps `monthRange`/`dayRange`,
inverts the `activeDayFilter != null` condition, or passes the wrong year/month
would not fail any test. This is the use case's primary business logic and it
has zero behavioral coverage.
**Fix:** Add two assertions with concrete bounds. With a pinned filter
(WR-01) for the month path:
```dart
verify(() => mockRepo.findByBookIds(['b1'],
  startDate: DateTime(2026, 5, 1),
  endDate: DateTime(2026, 5, 31, 23, 59, 59),
  sortField: any(named: 'sortField'),
  sortDirection: any(named: 'sortDirection'),
)).called(1);
```
And one with `activeDayFilter` set, asserting the single-day closed interval.

### WR-03: Filter forwarding for `ledgerType`/`categoryId` is untested and stubs would not catch a drop

**File:** `test/unit/application/list/get_list_transactions_use_case_test.dart:69-95`
**Issue:** The use case forwards `ledgerType` and `categoryId` to the repo
(`get_list_transactions_use_case.dart:53-54, 78-79`), but no `when()` stub or
`verify()` in the suite mentions these named arguments. In Mocktail an omitted
named argument is treated as a `null` literal matcher, so the stubs only match
because `baseFilter` happens to carry `ledgerType: null` / `categoryId: null`.
Consequently: (a) there is no test that a non-null `ledgerType`/`categoryId` is
actually passed through, and (b) if someone changed the use case to stop
forwarding `categoryId`, the existing stubs would still match and the suite
would stay green. The use case's stated job (RESEARCH Pitfall 2 / D-05: forward
exactly the SQL-able filters) is asserted for sort fields but not for the
category/ledger filters.
**Fix:** Add a test exercising a non-null filter and verify forwarding:
```dart
final filter = baseFilter.copyWith(
  ledgerType: LedgerType.soul, categoryId: 'cat_hobby');
when(() => mockRepo.findByBookIds(['b1'],
  ledgerType: LedgerType.soul, categoryId: 'cat_hobby',
  startDate: any(named: 'startDate'), endDate: any(named: 'endDate'),
  sortField: any(named: 'sortField'),
  sortDirection: any(named: 'sortDirection'))).thenAnswer((_) async => []);
await useCase.execute(GetListParams(bookIds: ['b1'], filter: filter));
verify(() => mockRepo.findByBookIds(['b1'],
  ledgerType: LedgerType.soul, categoryId: 'cat_hobby',
  startDate: any(named: 'startDate'), endDate: any(named: 'endDate'),
  sortField: any(named: 'sortField'),
  sortDirection: any(named: 'sortDirection'))).called(1);
```

### WR-04: Repository interface defaults are absent, so "no reliance on repo defaults" is a comment, not a guarantee

**File:** `lib/features/accounting/domain/repositories/transaction_repository.dart:38-39`
**Issue:** `findByBookIds`/`watchByBookIds` declare `SortField sortField` and
`SortDirection sortDirection` as named parameters **with no default value**. In
Dart a named parameter without `required` and without a default is implicitly
nullable-or-defaulted only for nullable types; for a non-nullable enum type
with no default, this is a compile-time contract that every caller MUST pass
the argument (it is effectively `required` in practice but not marked so). The
use case does pass them, so it compiles. However, the doc comment on the use
case (lines 25-26) claims it avoids "reliance on repo default values" — yet the
interface defines none, so any second caller that omits these args will fail to
compile rather than silently pick a default. This is acceptable but the intent
would be clearer and safer if the interface marked them `required`, making the
contract explicit and self-documenting rather than depending on every
implementer to remember.
**Fix:** Mark the sort parameters `required` on both interface methods:
```dart
required SortField sortField,
required SortDirection sortDirection,
```
This turns the implicit "you must pass these" into an enforced contract and
removes ambiguity about whether a default exists.

## Info

### IN-01: `clearAll()` re-anchors to the current month, discarding the user's selected month

**File:** `lib/features/list/domain/models/list_filter_state.dart:41-44`
**Issue:** `clearAll()` returns `ListFilterState.initial()`, which resets
`selectedYear`/`selectedMonth` to `DateTime.now()`. The doc comment states this
is intentional ("re-anchoring to the current calendar month"), but "clear
filters" UIs commonly preserve the currently-viewed month and only clear the
secondary filters (ledger, category, search, day). If product intent is
"clear filters but stay on the month I'm looking at", this implementation
silently navigates the user back to today's month. Flagging for product
confirmation, not as a defect.
**Fix:** If month should be preserved, implement explicitly:
```dart
ListFilterState clearAll() => ListFilterState(
  selectedYear: selectedYear, selectedMonth: selectedMonth);
```

### IN-02: Two parallel "default sort config" definitions invite drift

**File:** `lib/features/list/domain/models/list_sort_config.dart:13-19`
**Issue:** The default sort is declared twice: once as Freezed `@Default(...)`
field defaults (lines 14-15) and once as the `static const initial`
(line 19), and a third implicit time via `@Default(ListSortConfig())` in
`ListFilterState` (line 27). All three currently agree (updatedAt/desc), but
there is no single source of truth — a future change to the reference default
must be made in lock-step in two enum defaults plus verified against
`initial`. SC#4's immutability test (test lines 186-194) does not cover that
these stay consistent.
**Fix:** Keep the field `@Default`s as the single source and have callers use
`const ListSortConfig()` directly, or document that `initial` must mirror the
field defaults. Optionally add an assertion `expect(ListSortConfig.initial,
const ListSortConfig())`.

### IN-03: `GetListParams.bookIds` is a mutable `List`, weakening the "value object" guarantee

**File:** `lib/application/list/get_list_transactions_use_case.dart:13, 16`
**Issue:** `final List<String> bookIds` is `const`-constructable but the list
itself is still mutable by any holder of the reference (the field is `final`,
the contents are not). The class is documented as a "value object" but does not
defend its invariants — a caller can mutate the passed list after construction,
and `findByBookIds` would observe the mutation. This violates the project's
CRITICAL immutability convention (CLAUDE.md / coding-style.md) for hand-written
value classes.
**Fix:** Defensively copy to an unmodifiable view, or document the caller
contract:
```dart
GetListParams({required List<String> bookIds, required this.filter})
    : bookIds = List.unmodifiable(bookIds);
```

### IN-04: `GetListParams` lacks value equality

**File:** `lib/application/list/get_list_transactions_use_case.dart:12-17`
**Issue:** `GetListParams` is a plain class with no `==`/`hashCode`. The doc
says it "mirrors `GetTransactionsParams` as a plain const class", which is a
deliberate choice, but Phase 26 plans to feed this through Riverpod providers
where identity-based equality causes redundant rebuilds/refetches when an
equal-but-not-identical params object is constructed. Worth confirming the
provider keys on `filter` (a Freezed value with structural equality) rather
than on `GetListParams` itself.
**Fix:** Either add structural equality (or make it Freezed), or ensure the
Phase 26 provider family keys on the Freezed `filter`/`bookIds` rather than the
wrapper object.

### IN-05: `import_guard` deny-list does not block `package:flutter_riverpod/**`

**File:** `lib/features/list/domain/import_guard.yaml:8-13`
**Issue:** The domain deny-list blocks `package:flutter/**` but a Riverpod
`@riverpod` annotation or provider import would come from
`package:flutter_riverpod/**` or `package:riverpod/**`, which are not in the
deny list and not in the models allow-list. The allow-list approach in
`models/import_guard.yaml` does close this for the models subdir (anything not
whitelisted is denied), but the parent `domain/import_guard.yaml` itself has no
allow-list and the `domain/` directory root (if files are ever added directly
there, e.g. repository interfaces) would only be constrained by the deny list,
which omits riverpod. This matches the accounting reference exactly, so it is a
consistency note, not a regression.
**Fix:** If domain-root files are anticipated, add a `domain/import_guard.yaml`
allow-list mirroring the models one, or add
`package:flutter_riverpod/**` and `package:riverpod/**` to the deny list for
defense in depth.

---

_Reviewed: 2026-05-29T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
