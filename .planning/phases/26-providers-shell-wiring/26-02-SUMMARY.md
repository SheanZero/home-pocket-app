---
phase: 26-providers-shell-wiring
plan: "02"
subsystem: list-providers
tags:
  - riverpod
  - keepAlive
  - notifier
  - filter-state
  - use-case-wiring
  - tdd
dependency_graph:
  requires:
    - "26-01 (TaggedTransaction + MemberTag VOs, Wave 0 test stubs)"
    - "25-domain-models-use-case (ListFilterState, GetListTransactionsUseCase)"
    - "24-data-layer-extension (TransactionRepository.findByBookIds/watchByBookIds)"
  provides:
    - "listFilterProvider (ListFilter keepAlive Notifier, 8 mutators)"
    - "getListTransactionsUseCaseProvider (use case wired to transactionRepositoryProvider)"
    - "Generated state_list_filter.g.dart + repository_providers.g.dart"
    - "20 real unit tests replacing Wave 0 stub"
  affects:
    - "26-03 (listTransactionsProvider reads listFilterProvider)"
    - "Phase 27 (calendar reads listFilterProvider.selectedYear/Month)"
    - "Phase 28 (sort/filter bar mutates listFilterProvider)"
tech_stack:
  added: []
  patterns:
    - "@Riverpod(keepAlive: true) Notifier pattern (from state_home.dart SelectedTabIndex)"
    - "show import for cross-feature repository provider (no duplicate)"
    - "ProviderContainer.test() for synchronous Notifier tests"
key_files:
  created:
    - lib/features/list/presentation/providers/state_list_filter.dart
    - lib/features/list/presentation/providers/state_list_filter.g.dart
    - lib/features/list/presentation/providers/repository_providers.dart
    - lib/features/list/presentation/providers/repository_providers.g.dart
  modified:
    - test/unit/features/list/presentation/providers/list_filter_notifier_test.dart
decisions:
  - "Notifier class named ListFilter (not ListFilterState) to avoid naming collision with domain VO; generates listFilterProvider"
  - "@Riverpod(keepAlive: true) annotation (not comment) per SC#2 hard requirement"
  - "repository_providers.dart imports transactionRepositoryProvider with show clause — no duplicate repository provider (T-26-02-DP mitigated)"
  - "clearAll() delegates to state.clearAll() from domain VO (FILTER-04)"
  - "All mutators use state = state.copyWith(...) — immutable pattern enforced"
metrics:
  duration_seconds: 207
  completed_date: "2026-05-30"
  tasks_completed: 2
  tasks_total: 2
  files_created: 4
  files_modified: 1
---

# Phase 26 Plan 02: ListFilter Notifier + Repository Providers Wiring Summary

**One-liner:** ListFilter keepAlive Notifier (8 mutators, @Riverpod(keepAlive: true) annotation) + getListTransactionsUseCaseProvider wired to accounting transactionRepositoryProvider via show import, with 20 unit tests verifying SC#1 + FILTER-04.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | ListFilter Notifier (keepAlive) + repository_providers wiring | b62522c | state_list_filter.dart, state_list_filter.g.dart, repository_providers.dart, repository_providers.g.dart |
| 2 | list_filter_notifier_test.dart — SC#1 + FILTER-04 unit tests | 4702081 | list_filter_notifier_test.dart (Wave 0 stub replaced) |

## What Was Built

### ListFilter Notifier (state_list_filter.dart)

`lib/features/list/presentation/providers/state_list_filter.dart` defines a Riverpod 3 Notifier:

- **Class name:** `ListFilter` (NOT `ListFilterState` — naming collision with domain VO per constraint)
- **Generated provider:** `listFilterProvider` (Riverpod 3 strips Notifier suffix rule; class without suffix generates same name)
- **Annotation:** `@Riverpod(keepAlive: true)` — uppercase R, keepAlive named arg, encoded in annotation per SC#2
- **build():** returns `ListFilterState.initial()` anchoring to current calendar month
- **8 mutators** (all using `state = state.copyWith(...)` — immutable):
  - `selectMonth(int year, int month)` — sets year/month AND resets activeDayFilter to null
  - `selectDay(DateTime? day)` — sets activeDayFilter (DateTime?, not int)
  - `setSort(ListSortConfig sort)` — updates sortConfig
  - `setLedgerFilter(LedgerType? type)` — updates ledgerType
  - `setCategoryFilter(String? id)` — updates categoryId
  - `setSearch(String q)` — updates searchQuery
  - `setMemberFilter(String? bookId)` — updates memberBookId
  - `clearAll()` — delegates to `state = state.clearAll()` from domain VO (FILTER-04)

### repository_providers.dart

`lib/features/list/presentation/providers/repository_providers.dart` has ONE `@riverpod` provider:

- **`getListTransactionsUseCaseProvider`** — wires `GetListTransactionsUseCase` to `transactionRepositoryProvider`
- Imports accounting `repository_providers.dart` with `show transactionRepositoryProvider` — no duplicate provider
- Mirrors analytics `repository_providers.dart` pattern lines 41-47

### Unit Tests (list_filter_notifier_test.dart)

Wave 0 stub replaced with 20 real unit tests:
- Initial state: 7 fields verified, equals `ListFilterState.initial()` (SC#1)
- All 8 mutators tested individually
- clearAll() FILTER-04: 6 explicit field assertions (searchQuery='', ledgerType=null, categoryId=null, activeDayFilter=null, memberBookId=null, full equality to ListFilterState.initial())
- selectMonth resets activeDayFilter to null verified
- Immutability: state objects are not identical after mutations

## Verification Results

```
grep -c 'keepAlive: true' state_list_filter.dart → 1
grep -c 'class ListFilter extends' state_list_filter.dart → 1
grep -c 'show transactionRepositoryProvider' repository_providers.dart → 1
flutter test test/unit/features/list/presentation/providers/list_filter_notifier_test.dart → 20 passed
flutter test test/unit/features/list/ → 28 passed, 1 skipped (list_transactions_provider Wave 0)
flutter analyze lib/features/list/presentation/providers/ → No issues found
grep -c 'skip:' list_filter_notifier_test.dart → 0 (Wave 0 stub replaced)
```

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None — all source files are fully implemented. The `list_transactions_provider_test.dart` Wave 0 skip stub is intentional and will be replaced by Plan 03.

## Threat Flags

None — no new network endpoints, auth paths, or file access patterns introduced.

- T-26-02-DP (duplicate provider): mitigated by `show transactionRepositoryProvider` import
- T-26-02-MU (mutation): mitigated by `state = state.copyWith(...)` in all 8 mutators

## Self-Check: PASSED

- [x] `lib/features/list/presentation/providers/state_list_filter.dart` — FOUND
- [x] `lib/features/list/presentation/providers/state_list_filter.g.dart` — FOUND (generated)
- [x] `lib/features/list/presentation/providers/repository_providers.dart` — FOUND
- [x] `lib/features/list/presentation/providers/repository_providers.g.dart` — FOUND (generated)
- [x] `test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` — FOUND (20 real tests)
- [x] Commit b62522c — verified
- [x] Commit 4702081 — verified
