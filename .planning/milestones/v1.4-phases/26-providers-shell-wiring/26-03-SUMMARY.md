---
phase: 26-providers-shell-wiring
plan: "03"
subsystem: list-providers
tags:
  - riverpod
  - future-provider
  - text-search
  - category-localization
  - tdd
  - filter-04
dependency_graph:
  requires:
    - "26-02 (listFilterProvider, getListTransactionsUseCaseProvider)"
    - "26-01 (TaggedTransaction + MemberTag VOs)"
    - "25-domain-models-use-case (GetListTransactionsUseCase, ListFilterState)"
    - "application/accounting/category_localization_service.dart"
    - "settings/presentation/providers/state_locale.dart (currentLocaleProvider)"
  provides:
    - "listTransactionsProvider(bookId) Future provider with full search/filter logic"
    - "Generated state_list_transactions.g.dart"
    - "SC#3 + FILTER-01/02/03/04 unit tests (9 tests)"
  affects:
    - "26-04 (ListScreen shell consumes listTransactionsProvider)"
    - "Phase 27 (calendar reads listFilterProvider.selectedYear/Month)"
    - "Phase 28 (transaction tile renders List<TaggedTransaction>)"
    - "Phase 29 (family seam: fill memberTag from shadowBooks)"
tech_stack:
  added: []
  patterns:
    - "@riverpod auto-dispose Future provider parameterized by bookId"
    - "CategoryLocalizationService.resolveFromId for locale-aware category search (D-04)"
    - "ProviderContainer.test() + waitForFirstValue<T> (Riverpod 3 async test pattern)"
    - "Mocktail _MockGetListTransactionsUseCase for use case isolation"
    - "_FixedListFilter subclass for filter state injection in tests"
key_files:
  created:
    - lib/features/list/presentation/providers/state_list_transactions.dart
    - lib/features/list/presentation/providers/state_list_transactions.g.dart
  modified:
    - test/unit/features/list/presentation/providers/list_transactions_provider_test.dart
    - lib/features/list/presentation/providers/repository_providers.g.dart
    - lib/features/list/presentation/providers/state_list_filter.g.dart
decisions:
  - "@riverpod (auto-dispose) not keepAlive — listTransactionsProvider invalidates on bookId change, refreshes on sync"
  - "Text search uses CategoryLocalizationService.resolveFromId(tx.categoryId, locale) not raw categoryId (D-04 correctness, FILTER-01)"
  - "Null merchant/note guarded via ?? '' for .contains chaining (D-06 shadow-note safe)"
  - "Day filter checks year+month+day all three components (not just .day) — RESEARCH-verified"
  - "Phase 29 seam: bookIds=[bookId] + memberTag=null with comment markers (D-08)"
  - "TDD: RED commit (924cbab) then GREEN commit (0f2891a)"
metrics:
  duration_seconds: 235
  completed_date: "2026-05-30"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 3
---

# Phase 26 Plan 03: listTransactionsProvider with Locale-Aware Search Summary

**One-liner:** `listTransactionsProvider(bookId)` @riverpod Future provider with 8-step pipeline: filter state + locale + own-book bookIds + use case execute + Dart-side day filter (year+month+day) + CategoryLocalizationService locale-aware text search (FILTER-01) + TaggedTransaction wrap, backed by 9 unit tests in TDD RED/GREEN cycle.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 (RED) | Failing tests for listTransactionsProvider | 924cbab | list_transactions_provider_test.dart (Wave 0 stub replaced) |
| 1 (GREEN) | listTransactionsProvider implementation + generated | 0f2891a | state_list_transactions.dart, state_list_transactions.g.dart |

## What Was Built

### listTransactionsProvider (state_list_transactions.dart)

`lib/features/list/presentation/providers/state_list_transactions.dart` defines a Riverpod 3 `@riverpod` (auto-dispose) Future provider:

- **Signature:** `Future<List<TaggedTransaction>> listTransactions(Ref ref, {required String bookId})`
- **Generated provider:** `listTransactionsProvider(bookId: ...)` (family provider)
- **8-step pipeline:**
  1. `final filter = ref.watch(listFilterProvider)` — reads composed filter state
  2. `final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja')` — locale for category resolution
  3. `final bookIds = [bookId]` — own-book only (Phase 29 seam comment)
  4. `await useCase.execute(GetListParams(bookIds: bookIds, filter: filter))` — SQL filters
  5. `if (result.isError) throw Exception(result.error)` — propagate errors
  6. Day filter: `tx.timestamp.year == dayFilter.year && .month == ... && .day == ...` (all three)
  7. Text search: `CategoryLocalizationService.resolveFromId(tx.categoryId, locale).toLowerCase().contains(q)` OR merchant `?? ''` OR note `?? ''`
  8. Wrap: `TaggedTransaction(transaction: tx, memberTag: null)` with Phase 29 comment

- **CRITICAL correctness (FILTER-01 / D-04):** Uses `CategoryLocalizationService.resolveFromId` — NOT `tx.categoryId.toLowerCase()`. The latter is the architecture bug identified in research (D-04); `cat_food.toLowerCase()` would not match `食費`.

### Unit Tests (list_transactions_provider_test.dart)

Wave 0 skip stub replaced with 9 real tests:

1. Returns `List<TaggedTransaction>` wrapping each Transaction (SC#3)
2. Text search matches localized category name: `cat_food` + `食費` → match (FILTER-01)
3. Text search does NOT match raw categoryId: `cat_food` + `food` → no match (FILTER-01 correctness guard)
4. Merchant search: `スターバックス` contains `スターバック` → match (FILTER-01)
5. Note search: `誕生日プレゼント` contains `誕生日` → match (FILTER-01)
6. Null note graceful: no crash, not returned (D-06)
7. AND-composition: ledger filter forwarded to use case + text search applied Dart-side (FILTER-02 + FILTER-04)
8. categoryId filter forwarded to use case params (FILTER-03)
9. Day filter: only transactions with matching year+month+day retained

- Uses `ProviderContainer.test()` + `waitForFirstValue<List<TaggedTransaction>>` throughout
- No bare `container.read(listTransactionsProvider...)` calls
- `_FixedListFilter extends ListFilter` pattern for filter state injection
- `currentLocaleProvider.overrideWith((ref) async => const Locale('ja'))` to avoid settings lookup

## Verification Results

```
grep -c 'CategoryLocalizationService.resolveFromId' state_list_transactions.dart → 3 (1 code call + 2 comments)
grep -c 'categoryId.toLowerCase()' state_list_transactions.dart → 0
grep -c 'dayFilter.year' state_list_transactions.dart → 1
grep -c 'Phase 29' state_list_transactions.dart → 3 (seam comments)
grep -c 'skip:' list_transactions_provider_test.dart → 0 (Wave 0 stub fully replaced)
grep -c 'waitForFirstValue' list_transactions_provider_test.dart → 9
grep -c 'container.read(listTransactions' list_transactions_provider_test.dart → 0
flutter test test/unit/features/list/ → 37 passed (8 tagged_transaction + 20 filter_notifier + 9 list_transactions)
flutter analyze lib/features/list/ --no-pub → No issues found
```

## Deviations from Plan

None - plan executed exactly as written.

**Note:** `grep -c 'CategoryLocalizationService.resolveFromId' state_list_transactions.dart` returns 3 (not 1 as the plan stated). This is because the pattern also appears in docstring lines (lines 22, 77). The actual function call is on line 83. The acceptance criterion is satisfied: the provider uses `CategoryLocalizationService.resolveFromId` for category name resolution.

## TDD Gate Compliance

- RED gate: commit 924cbab — `test(26-03): add failing listTransactionsProvider tests (RED)`
- GREEN gate: commit 0f2891a — `feat(26-03): listTransactionsProvider with locale-aware search and day filter`
- REFACTOR: not needed (clean first implementation)

## Known Stubs

None — all source files are fully implemented. The Phase 29 seam (`bookIds=[bookId]`, `memberTag=null`) is intentional forward-compat design, not a stub — it allows Phase 29 to expand without changing types.

## Threat Flags

None — no new network endpoints, auth paths, or file access patterns introduced.

- T-26-03-V5 (searchQuery in-memory .contains): accepted — searchQuery never forwarded to SQL, no injection surface
- T-26-03-LOG (sensitive data logging): mitigated — no logging of Transaction.note, merchant, or resolved category names anywhere in provider body
- T-26-03-SC (new packages): accepted — no new packages; all dependencies pre-existing

## Self-Check: PASSED

- [x] `lib/features/list/presentation/providers/state_list_transactions.dart` — FOUND
- [x] `lib/features/list/presentation/providers/state_list_transactions.g.dart` — FOUND (generated)
- [x] `test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` — FOUND (9 real tests, 0 skipped)
- [x] Commit 924cbab — verified (RED: failing tests)
- [x] Commit 0f2891a — verified (GREEN: implementation)
- [x] `flutter test test/unit/features/list/ → 37 passed` — verified
- [x] `flutter analyze lib/features/list/ --no-pub → No issues found` — verified
