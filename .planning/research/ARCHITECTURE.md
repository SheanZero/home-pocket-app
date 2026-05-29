# Architecture Research — v1.4 列表功能 (Transaction List Tab)

**Domain:** Local-first Flutter accounting app — adding a full-featured List tab to the existing 5-layer Clean Architecture
**Researched:** 2026-05-29
**Confidence:** HIGH (all claims verified against live `lib/` tree)

> **Scope note.** This file answers the integration questions for v1.4: feature placement, new Riverpod providers, new DAO methods, edit/delete reuse, family data sourcing, and build order. The 5-layer architecture and Thin Feature rule are established; this file builds on them rather than re-stating them.

---

## System Overview — Where v1.4 Components Land

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            PRESENTATION LAYER                                    │
│                                                                                  │
│  features/home/presentation/             features/list/presentation/  ★NEW       │
│  ┌──────────────────────────┐           ┌───────────────────────────────────┐   │
│  │ screens/                 │           │ screens/                          │   │
│  │   main_shell_screen.dart ◐           │   list_screen.dart  ★             │   │
│  │   (line 111: replace     │           │                                   │   │
│  │    placeholder with      │           │ widgets/                          │   │
│  │    ListScreen)           │           │   list_calendar_header.dart  ★    │   │
│  └──────────────────────────┘           │   list_month_summary.dart  ★      │   │
│                                         │   list_transaction_tile.dart  ★   │   │
│  features/accounting/presentation/      │   list_sort_filter_bar.dart  ★    │   │
│  ┌──────────────────────────┐           │   list_empty_state.dart  ★        │   │
│  │ transaction_edit_screen  │◄──tap────►│                                   │   │
│  │   (reused as-is)         │  to edit  │ providers/                        │   │
│  └──────────────────────────┘           │   repository_providers.dart  ★    │   │
│                                         │   state_list_filter.dart  ★       │   │
│                                         │   state_list_transactions.dart  ★ │   │
│                                         │   state_list_calendar.dart  ★     │   │
│                                         └───────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────┬───────────────────┘
                         │ ref.watch                          │
┌────────────────────────┴────────────────────────────────────┴───────────────────┐
│                         APPLICATION LAYER (GLOBAL)                               │
│                                                                                  │
│  lib/application/list/  ★NEW                                                     │
│    get_list_transactions_use_case.dart                                           │
│    list_use_case_models.dart   (GetListParams)                                   │
│                                                                                  │
│  lib/application/accounting/  (unchanged — DeleteTransactionUseCase reused)     │
└────────────────────────┬────────────────────────────────────────────────────────┘
                         │ uses (interface)
┌────────────────────────┴────────────────────────────────────────────────────────┐
│  DOMAIN LAYER                                                                    │
│                                                                                  │
│  features/list/domain/  ★NEW                                                     │
│    models/list_filter_state.dart   (Freezed)                                    │
│    models/list_sort_config.dart    (Freezed — refs SortField from shared/)      │
│    repositories/list_transaction_repository.dart   (interface)                  │
│                                                                                  │
│  features/accounting/domain/repositories/transaction_repository.dart  ◐         │
│    + findByBookIds() abstract method                                             │
│                                                                                  │
│  lib/shared/constants/sort_config.dart  ★NEW                                    │
│    SortField enum, SortDirection enum                                            │
└────────────────────────┬────────────────────────────────────────────────────────┘
                         │ implements
┌────────────────────────┴────────────────────────────────────────────────────────┐
│  DATA LAYER                                                                      │
│                                                                                  │
│  lib/data/daos/transaction_dao.dart  ◐                                           │
│    + findByBookIds() — multi-book date-range + sort query                        │
│                                                                                  │
│  lib/data/repositories/transaction_repository_impl.dart  ◐                      │
│    + findByBookIds() implementation                                              │
│                                                                                  │
│  lib/data/daos/analytics_dao.dart  (unchanged — getDailyTotals reused)           │
└─────────────────────────────────────────────────────────────────────────────────┘

★ = NEW file/symbol     ◐ = MODIFIED existing file     (no mark) = unchanged
```

---

## Feature Placement Decision

**Decision: new `lib/features/list/` feature module**, not folded into `features/accounting/`.

Rationale:
- `features/accounting/` owns the _entry_ domain: manual/voice/edit/OCR screens, category management, transaction CRUD forms. The List tab is a _read-biased query/display_ domain with distinct domain models (`ListFilterState`, `SortConfig`) not shared with the entry domain.
- Precedent: `features/analytics/` is a separate read-biased domain alongside `features/accounting/`. Same split applies here.
- `main_shell_screen.dart:111` already has a placeholder at IndexedStack index 1 (`Center(child: Text(S.of(context).listTab))`).
- Thin Feature rule: `features/list/` will contain only `domain/` (models + repo interface) and `presentation/` (screens/widgets/providers). NO `application/`, `infrastructure/`, `data/tables/`, `data/daos/`.

---

## Component Map — New vs Modified

### NEW (create)

```
lib/features/list/
  domain/
    models/
      list_filter_state.dart          # Freezed: selectedMonth, activeDayFilter, sortConfig,
                                      #   ledgerType?, categoryId?, searchQuery, memberBookId?
      list_sort_config.dart           # Freezed: SortField (from shared) + SortDirection
    repositories/
      list_transaction_repository.dart  # interface — findByBookIds with filter params

  presentation/
    providers/
      repository_providers.dart       # ONE file per feature rule:
                                      #   listTransactionRepositoryProvider (wraps existing transactionRepositoryProvider)
                                      #   getListTransactionsUseCaseProvider
      state_list_filter.dart          # @riverpod Notifier<ListFilter>
      state_list_transactions.dart    # @riverpod Future<List<TaggedTransaction>>
      state_list_calendar.dart        # @riverpod Future<List<DailyTotal>>({bookId, month})

    screens/
      list_screen.dart                # Root screen replacing placeholder in main_shell_screen

    widgets/
      list_calendar_header.dart       # Month-nav + calendar grid + per-day totals + tap-to-filter
      list_month_summary.dart         # Month total expense (expense-only basis)
      list_transaction_tile.dart      # category emoji, ledger tag, date, amount, optional member tag
      list_sort_filter_bar.dart       # sort chip + ledger/category filter chips + search field
      list_empty_state.dart           # empty state (filtered vs unfiltered messages)

lib/application/list/
  get_list_transactions_use_case.dart # multi-book query: wraps TransactionRepository.findByBookIds
  list_use_case_models.dart           # GetListParams(bookIds, startDate, endDate, ledgerType,
                                      #   categoryId, sortField, sortAscending)

lib/shared/constants/sort_config.dart # SortField enum + SortDirection enum (shared to avoid
                                      # cross-feature domain import from list/domain)
```

### MODIFIED (extend existing)

```
lib/data/daos/transaction_dao.dart
  + findByBookIds(List<String> bookIds, {startDate, endDate, ledgerType?, categoryId?,
                  sortField, sortAscending, limit=500})
    → Future<List<TransactionRow>>

lib/features/accounting/domain/repositories/transaction_repository.dart
  + findByBookIds(List<String> bookIds, {same params})
    → Future<List<Transaction>>   (abstract)

lib/data/repositories/transaction_repository_impl.dart
  + findByBookIds(...)   → delegates to extended DAO; applies _toModel per-row

lib/features/home/presentation/screens/main_shell_screen.dart
  Line 111: replace placeholder Center(...) with ListScreen(bookId: bookId)
```

### UNCHANGED (reuse as-is)

```
lib/features/accounting/presentation/screens/transaction_edit_screen.dart
  — tap-to-edit entry point; push with Transaction, pop(true) triggers list invalidate

lib/features/accounting/presentation/providers/repository_providers.dart
  — deleteTransactionUseCaseProvider (swipe-to-delete)
  — updateTransactionUseCaseProvider (used transitively by TransactionEditScreen)

lib/features/analytics/domain/repositories/analytics_repository.dart
  getDailyTotals() — calendar per-day rollup; called via analyticsRepositoryProvider

lib/features/analytics/presentation/providers/repository_providers.dart
  analyticsRepositoryProvider — watches in state_list_calendar.dart

lib/features/family_sync/presentation/providers/state_active_group.dart
  activeGroupProvider (keepAlive) + isGroupModeProvider — guards family branch in list provider

lib/features/home/presentation/providers/state_shadow_books.dart
  shadowBooksProvider — supplies shadow bookIds + member display names

lib/features/accounting/domain/models/transaction.dart
  Transaction domain model — no field additions needed

lib/infrastructure/i18n/ formatters (DateFormatter, NumberFormatter)
  — same pattern as HomeScreen via currentLocaleProvider
```

---

## Family Data Sourcing (Critical Question Answered)

**The family sync model stores each member's transactions in a local shadow book — NOT a separate in-memory merge.**

Evidence from codebase inspection:
- `ShadowBookService` (`lib/application/family_sync/shadow_book_service.dart`) creates a `Book` row with `isShadow = true`, `groupId`, `ownerDeviceId` for each remote member.
- `ApplySyncOperationsUseCase` writes inbound transaction payloads into the shadow book's `bookId` in the local SQLite DB.
- `shadowBooksProvider` (`lib/features/home/presentation/providers/state_shadow_books.dart`) already returns `List<ShadowBookInfo>` (each contains `book.id` + `memberDisplayName` + `memberAvatarEmoji`) by querying `bookRepository.findShadowBooksByGroupId(group.groupId)`.

Therefore the List feature only needs to:
1. Watch `isGroupModeProvider` → if true, watch `shadowBooksProvider`
2. Collect `[myBookId, ...shadowBooks.map((s) => s.book.id)]`
3. Pass the list to `TransactionDao.findByBookIds([...])`

**No additional merge, no schema change, no new sync logic.** All data is already in the local encrypted DB under different `book_id` values.

**Member attribution:** `Transaction.bookId` identifies which shadow book (which member) owns a row. The provider maintains a `Map<String, String> bookIdToMemberLabel` from `ShadowBookInfo` and attaches the label at display time via a `TaggedTransaction` wrapper:

```dart
class TaggedTransaction {
  final Transaction transaction;
  final String? memberLabel;  // null = own transaction; non-null = family member name
}
```

**Note decryption on shadow books:** `FieldEncryptionService.decryptField()` will fail for shadow book rows (note was encrypted with the originating device's key). `TransactionRepositoryImpl._toModel()` currently calls decryptField and the result goes to `decryptedNote`. If decryption fails (expected on shadow notes), the impl should catch the exception and return `note: null` — the List tile renders notes as empty. This is pre-existing behavior to verify/confirm in Phase A.

---

## Provider Dependency Graph

```
isGroupModeProvider (keepAlive: true, existing)
shadowBooksProvider (existing)
    │
    ▼
listFilterStateProvider  ──(Notifier, auto-dispose)
  holds: selectedMonth, activeDayFilter, sortConfig,
         ledgerType?, categoryId?, searchQuery, memberBookId?
    │
    ▼
listTransactionsProvider({bookId})  ─────(FutureProvider, auto-dispose)
  1. reads listFilterStateProvider
  2. reads shadowBooksProvider (if isGroupMode)
  3. calls getListTransactionsUseCase.execute(GetListParams)
     → TransactionRepository.findByBookIds (SQL: bookIds, dateRange, ledger?, category?, ORDER BY)
  4. Dart-side post-process:
       if activeDayFilter != null  → .where(tx.timestamp.day == day)
       if searchQuery != ''        → .where(note|merchant|categoryName contains query)
       if memberBookId != null     → .where(tx.bookId == memberBookId)
     (returns List<TaggedTransaction>)
    │
    ▼
ListScreen

analyticsRepositoryProvider (existing)
    │
    ▼
listCalendarProvider({bookId, month})  ──(FutureProvider, auto-dispose)
  calls analyticsRepository.getDailyTotals(bookId: myBookId, ...)
  (own-book only; family calendar aggregation is out-of-scope v1.4)
    │
    ▼
ListCalendarHeader (rebuilds on month change only)
```

---

## Tap-to-Edit Flow

```
ListTransactionTile.onTap(tx)
    │
    ▼
Navigator.push(MaterialPageRoute(builder: (_) =>
    TransactionEditScreen(transaction: tx)))
    │
    ▼ pop(true)
ref.invalidate(listTransactionsProvider(bookId: bookId))
ref.invalidate(listCalendarProvider(bookId: bookId, month: selectedMonth))
// also invalidate home screen providers per main_shell_screen.dart pattern:
ref.invalidate(todayTransactionsProvider(bookId: bookId))
ref.invalidate(monthlyReportProvider(bookId: ..., startDate: ..., endDate: ...))
```

Note: `TransactionEditScreen` does NOT support delete (per its Phase 18 design, `D-11/D-17`). Delete is swipe-to-delete from the list tile only.

---

## Swipe-to-Delete Flow

```
Dismissible(
  key: ValueKey(tx.id),
  direction: DismissDirection.endToStart,
  confirmDismiss: (_) async => showDialog(confirm?)
)
    │ confirmed
    ▼
ref.read(deleteTransactionUseCaseProvider).execute(tx.id)
    │
    ▼
ref.invalidate(listTransactionsProvider(...))
ref.invalidate(listCalendarProvider(...))
ref.invalidate(todayTransactionsProvider(bookId: bookId))  // home screen refresh
ref.invalidate(monthlyReportProvider(...))                 // home screen refresh
```

---

## New DAO Method Required

**Location:** `lib/data/daos/transaction_dao.dart`

```dart
/// Multi-book date-range query for the List tab.
///
/// ORDER BY is SQL-level (timestamp|updatedAt|amount, asc/desc).
/// Text search and member filter are Dart-side post-process.
/// Soft-deleted rows excluded. Own-book + shadow books in one query.
Future<List<TransactionRow>> findByBookIds(
  List<String> bookIds, {
  required DateTime startDate,
  required DateTime endDate,
  String? ledgerType,
  String? categoryId,
  SortField sortField = SortField.timestamp,
  bool sortAscending = false,
  int limit = 500,
}) async {
  // Uses Drift typesafe DSL or customSelect with IN (?) expansion
  // ORDER BY: timestamp/updatedAt/amount DESC (or ASC) + id DESC as tiebreaker
}
```

The existing `AnalyticsDao.getDailyTotals()` already handles calendar per-day rollups — no new DAO method needed there.

---

## New Application Use Case

**Location:** `lib/application/list/get_list_transactions_use_case.dart`

Constructor receives `TransactionRepository` (injected, no Riverpod).

`execute(GetListParams)` → `Result<List<Transaction>>`:
- Validates `bookIds` non-empty, `startDate` before `endDate`
- Calls `transactionRepository.findByBookIds(...)`
- Returns `Result.success(transactions)`

Dart-side sort/filter (day, text search, member) is applied in the **provider** (`state_list_transactions.dart`), not in the use case. The use case is only responsible for the DB roundtrip. This keeps the use case testable without filter-state dependencies.

---

## Riverpod Provider Design

All new providers in `lib/features/list/presentation/providers/`.

### `state_list_filter.dart`

```dart
@riverpod
class ListFilterState extends _$ListFilterState {
  @override
  ListFilter build() => ListFilter.initial(DateTime.now());

  void selectMonth(DateTime month) =>
    state = state.copyWith(selectedMonth: month, activeDayFilter: null);
  void selectDay(int? day) => state = state.copyWith(activeDayFilter: day);
  void setSort(ListSortConfig sort) => state = state.copyWith(sort: sort);
  void setLedgerFilter(LedgerType? type) =>
    state = state.copyWith(ledgerType: type, activeDayFilter: null);
  void setCategoryFilter(String? id) => state = state.copyWith(categoryId: id);
  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void setMemberFilter(String? bookId) => state = state.copyWith(memberBookId: bookId);
}
```

Note: `keepAlive: false` (default) — state auto-disposes when List tab is not visible in IndexedStack. Month resets to current month on next tab open. If persistence-across-tab-switches is needed, add `keepAlive: true`.

### `state_list_transactions.dart`

```dart
@riverpod
Future<List<TaggedTransaction>> listTransactions(
  Ref ref, {required String bookId}
) async {
  final filter = ref.watch(listFilterStateProvider);
  final isGroup = ref.watch(isGroupModeProvider);
  final shadowBooks = isGroup
      ? await ref.watch(shadowBooksProvider.future)
      : <ShadowBookInfo>[];

  final bookIds = [bookId, ...shadowBooks.map((s) => s.book.id)];
  final bookIdToLabel = {
    for (final s in shadowBooks) s.book.id: s.memberDisplayName,
  };

  final monthStart = DateTime(filter.selectedMonth.year, filter.selectedMonth.month, 1);
  final monthEnd = DateTime(filter.selectedMonth.year, filter.selectedMonth.month + 1, 0, 23, 59, 59);

  final useCase = ref.watch(getListTransactionsUseCaseProvider);
  final result = await useCase.execute(GetListParams(
    bookIds: bookIds,
    startDate: monthStart,
    endDate: monthEnd,
    ledgerType: filter.ledgerType,
    categoryId: filter.categoryId,
    sortField: filter.sort.field,
    sortAscending: filter.sort.ascending,
  ));

  if (result.isError) throw Exception(result.error);
  var txs = result.data!;

  // Dart-side post-process (note: text search on encrypted notes is unavailable
  // for shadow books — only merchant/category fields are searchable cross-member)
  if (filter.activeDayFilter != null) {
    txs = txs.where((t) => t.timestamp.day == filter.activeDayFilter).toList();
  }
  final q = filter.searchQuery.toLowerCase().trim();
  if (q.isNotEmpty) {
    txs = txs.where((t) =>
      (t.note?.toLowerCase().contains(q) ?? false) ||
      (t.merchant?.toLowerCase().contains(q) ?? false) ||
      t.categoryId.toLowerCase().contains(q)
    ).toList();
  }
  if (filter.memberBookId != null) {
    txs = txs.where((t) => t.bookId == filter.memberBookId).toList();
  }

  return txs.map((t) => TaggedTransaction(
    transaction: t,
    memberLabel: bookIdToLabel[t.bookId],
  )).toList();
}
```

### `state_list_calendar.dart`

```dart
@riverpod
Future<List<DailyTotal>> listCalendar(
  Ref ref, {required String bookId, required DateTime month}
) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getDailyTotals(
    bookId: bookId,
    startDate: DateTime(month.year, month.month, 1),
    endDate: DateTime(month.year, month.month + 1, 0, 23, 59, 59),
  );
}
```

### `repository_providers.dart` (ONE file per feature)

```dart
// Reuses existing transactionRepository — no second impl needed
@riverpod
ListTransactionRepository listTransactionRepository(Ref ref) {
  // ListTransactionRepositoryImpl wraps TransactionRepositoryImpl
  // OR: simply cast/delegate to the existing provider
  return ref.watch(transactionRepositoryProvider) as ListTransactionRepository;
  // TransactionRepositoryImpl implements both interfaces after findByBookIds is added
}

@riverpod
GetListTransactionsUseCase getListTransactionsUseCase(Ref ref) {
  return GetListTransactionsUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
}
```

---

## Recommended Project Structure (v1.4 additions)

```
lib/
├── application/list/                                    ★ NEW
│   ├── get_list_transactions_use_case.dart
│   └── list_use_case_models.dart
│
├── data/
│   ├── daos/
│   │   └── transaction_dao.dart                         ◐ + findByBookIds
│   └── repositories/
│       └── transaction_repository_impl.dart              ◐ + findByBookIds impl
│
├── features/accounting/domain/repositories/
│   └── transaction_repository.dart                       ◐ + findByBookIds abstract
│
├── features/home/presentation/screens/
│   └── main_shell_screen.dart                            ◐ line 111: ListScreen
│
├── features/list/                                        ★ NEW feature module
│   ├── domain/
│   │   ├── models/
│   │   │   ├── list_filter_state.dart                   ★ (Freezed)
│   │   │   ├── list_filter_state.freezed.dart           generated
│   │   │   ├── list_filter_state.g.dart                 generated
│   │   │   ├── list_sort_config.dart                    ★ (Freezed)
│   │   │   ├── list_sort_config.freezed.dart            generated
│   │   │   └── list_sort_config.g.dart                  generated
│   │   └── repositories/
│   │       └── list_transaction_repository.dart         ★ interface
│   └── presentation/
│       ├── providers/
│       │   ├── repository_providers.dart                ★
│       │   ├── repository_providers.g.dart              generated
│       │   ├── state_list_filter.dart                   ★
│       │   ├── state_list_filter.g.dart                 generated
│       │   ├── state_list_transactions.dart             ★
│       │   ├── state_list_transactions.g.dart           generated
│       │   ├── state_list_calendar.dart                 ★
│       │   └── state_list_calendar.g.dart               generated
│       ├── screens/
│       │   └── list_screen.dart                         ★
│       └── widgets/
│           ├── list_calendar_header.dart                ★
│           ├── list_month_summary.dart                  ★
│           ├── list_transaction_tile.dart               ★
│           ├── list_sort_filter_bar.dart                ★
│           └── list_empty_state.dart                    ★
│
├── shared/constants/
│   └── sort_config.dart                                  ★ SortField + SortDirection enums
│
└── l10n/
    ├── intl_ja.arb                                       ◐ new keys for list UI
    ├── intl_zh.arb                                       ◐
    └── intl_en.arb                                       ◐
```

---

## Build Order (Phase Sequence)

Each phase is independently testable. Ordered by dependency (data → application → domain → providers → widgets → screen → i18n).

### Phase A — Data Layer Extension

**Deliverables:**
- `lib/shared/constants/sort_config.dart` — `SortField` + `SortDirection` enums
- `lib/data/daos/transaction_dao.dart` — `findByBookIds()`
- `lib/features/accounting/domain/repositories/transaction_repository.dart` — abstract `findByBookIds()`
- `lib/data/repositories/transaction_repository_impl.dart` — impl

**Tests:** `test/data/daos/transaction_dao_multi_book_test.dart` — multi-book, date-range, ledger filter, sort variants, deleted-excluded, 0-rows

No migration (query-only extension). No UI, no providers.

**Unblocks:** Phase B.

---

### Phase B — Application Use Case

**Deliverables:**
- `lib/application/list/list_use_case_models.dart` — `GetListParams`
- `lib/application/list/get_list_transactions_use_case.dart`

**Tests:** unit test with `MockTransactionRepository` — verify params forwarded, `Result.error` on empty bookIds

**Unblocks:** Phase C.

---

### Phase C — Domain Models + Repository Interface

**Deliverables:**
- `lib/features/list/domain/models/list_filter_state.dart` (Freezed)
- `lib/features/list/domain/models/list_sort_config.dart` (Freezed)
- `lib/features/list/domain/repositories/list_transaction_repository.dart`
- Run `build_runner` after Freezed additions

**Unblocks:** Phase D.

---

### Phase D — Riverpod Providers + Shell Wiring

**Deliverables:**
- `lib/features/list/presentation/providers/repository_providers.dart`
- `lib/features/list/presentation/providers/state_list_filter.dart`
- `lib/features/list/presentation/providers/state_list_transactions.dart`
- `lib/features/list/presentation/providers/state_list_calendar.dart`
- `lib/features/home/presentation/screens/main_shell_screen.dart` — replace placeholder with `ListScreen(bookId: bookId)` (minimal: just make it compile)
- Run `build_runner`

**Tests:** provider unit tests with `ProviderContainer.test()` + `waitForFirstValue`:
- solo mode: returns only own-book rows
- group mode: returns own + shadow-book rows merged
- day filter: Dart-side narrowing
- text search: matches merchant

**Unblocks:** Phase E, F.

---

### Phase E — Calendar Header Widget

**Deliverables:**
- `lib/features/list/presentation/widgets/list_calendar_header.dart` — month-nav arrows + calendar grid + per-day amount dots/labels + tap-day dispatches `listFilterStateProvider.selectDay()`
- `lib/features/list/presentation/widgets/list_month_summary.dart` — month total expense label

**Tests:** widget tests — day tap → `activeDayFilter` mutation; month nav → `selectedMonth` mutation; golden baselines ja/zh/en × light/dark

**Unblocks:** Phase G.

---

### Phase F — Transaction Tile + Sort/Filter Bar

**Deliverables:**
- `lib/features/list/presentation/widgets/list_transaction_tile.dart` — category emoji, ledger color tag, date, amount, optional member tag; `onTap` → edit, `Dismissible` → delete
- `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` — sort chip, ledger chips, category chip, search `TextField`
- `lib/features/list/presentation/widgets/list_empty_state.dart`

**Tests:**
- Tile: tap navigates to `TransactionEditScreen`, swipe triggers confirm dialog, confirmed delete calls `deleteTransactionUseCaseProvider`
- Sort/filter bar: chip taps mutate filter state; search field change mutates `searchQuery`

**Unblocks:** Phase G.

---

### Phase G — List Screen Assembly + Full Integration

**Deliverables:**
- `lib/features/list/presentation/screens/list_screen.dart`
  - `CustomScrollView` with `SliverToBoxAdapter` (calendar header) + `SliverToBoxAdapter` (sort/filter bar) + `SliverList` (tiles) + pull-to-refresh
  - On edit-return(true) and post-delete: `ref.invalidate` of list + calendar + home providers
  - Connects `listCalendarProvider(bookId: bookId, month: filter.selectedMonth)` to header

**Tests:** integration test — month switch → calendar rebuilds, day tap → list filters, search → list narrows, delete → tile removed

---

### Phase H — ARB + i18n Completion

**Deliverables:** All new keys added to `intl_ja.arb`, `intl_zh.arb`, `intl_en.arb`; `flutter gen-l10n` clean.

Estimated new ARB keys:
- Sort labels: `sortByDate`, `sortByEditTime`, `sortByAmount`, `sortAscending`, `sortDescending`
- Filter labels: `filterByLedger`, `filterByCategory`, `filterByMember`, `filterAllLedgers`, `filterAllCategories`
- Search: `searchHint`
- Calendar: `calendarMonthTitle` (e.g. "YYYY年MM月")
- Summary: `monthTotalExpense`
- Empty states: `listEmptyNoTransactions`, `listEmptyFiltered`
- Delete: `deleteTransactionConfirmTitle`, `deleteTransactionConfirmBody`, `deleteTransactionConfirmOk`, `deleteTransactionConfirmCancel`
- Member: `memberLabel` (e.g. "by {name}")

ARB key parity must be locked across all 3 locales before Phase G golden tests are finalized.

---

## Integration Points Summary

| Point | Existing File | Action |
|-------|--------------|--------|
| Shell tab placeholder | `main_shell_screen.dart:111` | Replace `Center(child: Text(...))` with `ListScreen(bookId: bookId)` |
| Edit from list | `transaction_edit_screen.dart` | Reuse as-is; push with `Transaction`, pop(true) triggers invalidate |
| Delete from list | `deleteTransactionUseCaseProvider` (accounting) | `ref.watch(...)` in list tile, same as edit path used by home screen |
| Shadow book IDs | `shadowBooksProvider` (home) | Watch in `state_list_transactions.dart` for family branch |
| Group mode guard | `isGroupModeProvider` (family_sync) | Gate family branch in list provider |
| Calendar daily data | `analyticsRepositoryProvider.getDailyTotals()` | Watch in `state_list_calendar.dart`; no new DAO method |
| Amount formatting | `NumberFormatter` + `currentLocaleProvider` | Same pattern as `HomeScreen` (`FormatterService`) |
| Date formatting | `DateFormatter` + `currentLocaleProvider` | Same pattern as `HomeScreen` |
| Ledger colors | `AppColors.survival`, `AppColors.soul` | `lib/core/theme/app_colors.dart` — unchanged |
| Ledger tag color | `AppThemeColors.wmCard`, etc. | Same theming surface as `HomeTransactionTile` |
| Amount text style | `AppTextStyles.amountSmall` | `lib/core/theme/app_text_styles.dart` — tabular figures alignment |
| Transaction tile shell | `HomeTransactionTile` (home/widgets) | Do NOT reuse directly — List tile needs date column + member tag. Create `ListTransactionTile` composing same color/style constants. |
| Home refresh after edit/delete | `main_shell_screen.dart` post-FAB pattern | Mirror the `ref.invalidate(todayTransactionsProvider, monthlyReportProvider, ...)` block |

---

## Key Constraints

1. **No Drift migration required.** The `transactions` table (schema v17) already has all required columns. `findByBookIds` is a query-only extension.

2. **`note` decryption on shadow books.** Shadow books' notes were encrypted with the originating device's key — local device cannot decrypt them. `TransactionRepositoryImpl._toModel()` calls `decryptField()` and the caller should handle `null` note gracefully. List tile renders note as empty/omitted. No user-visible error.

3. **`note` field is not text-searchable for shadow books.** The List search only matches `merchant` and `categoryId` for shadow rows; own-book rows allow `note` search. This is acceptable behavior for v1.4.

4. **`import_guard` compliance.** `lib/features/list/` follows Thin Feature rule. `lib/application/list/` follows Application layer rules (no Presentation imports, no DAO/table imports). `SortField` in `lib/shared/constants/` avoids cross-feature domain imports.

5. **Performance.** Monthly query with `limit=500` rows through the decrypt loop in `_toModel()` via `Future.wait` is acceptable (async parallel). If profiling reveals >200ms, the optimization path is lazy `note` decryption (decode only when edit screen opens, not during list load).

6. **`activeGroupProvider` is `keepAlive: true`** — safe to watch in `listTransactionsProvider`.

7. **`TransactionRepositoryImpl` satisfies `ListTransactionRepository` interface** after `findByBookIds` is added — no second repository implementation class. The list feature's `repository_providers.dart` simply delegates to the existing `transactionRepositoryProvider`.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Putting filter/sort logic in the DAO or use case
Text search, day filter, and member filter belong Dart-side in the provider. The DAO handles: `bookIds IN (...)`, date range, `ledger_type`, `category_id`, and `ORDER BY`. Pushing text search into SQL requires `LIKE '%q%'` which cannot search the ChaCha20-Poly1305-encrypted `note` field. Keep search Dart-side.

### Anti-Pattern 2: Creating a second TransactionRepository implementation
`TransactionRepositoryImpl` will implement both `TransactionRepository` and `ListTransactionRepository` after `findByBookIds` is added. No second impl class — that would duplicate the field encryption logic.

### Anti-Pattern 3: Assembling bookIds inside the use case
Family data sourcing (shadow bookId enumeration) is a provider-level concern. The use case receives `bookIds: List<String>` as a plain parameter, making it testable without Riverpod or shadow book state.

### Anti-Pattern 4: Reusing `HomeTransactionTile` directly
The home tile assumes merchant+category+ledger-tag layout without a date column or member attribution tag. Create `ListTransactionTile`. Both tiles share `AppColors`, `AppTextStyles.amountSmall`, and `AppThemeColors` — but their layout signatures differ enough to warrant separate widgets.

### Anti-Pattern 5: Calendar per-day rollup spanning shadow books
Calendar shows own-book-only daily totals (`bookId = myBookId`). Summing all members' spending per day requires a different analytics query and is out of scope v1.4. Implementing it would require a new DAO variant in `AnalyticsDao` — flag as a future extension point.

---

## Confidence Assessment

| Area | Confidence | Basis |
|------|------------|-------|
| Feature placement (new `features/list/`) | HIGH | Direct inspection of `features/accounting/` scope; `main_shell_screen.dart:111` placeholder verified |
| Family data sourcing (shadow books in local DB) | HIGH | `ShadowBookService`, `shadowBooksProvider`, `state_shadow_books.dart` read in full |
| DAO extension (additive, no migration) | HIGH | `transactions_table.dart` schema v17 verified; `transaction_dao.dart` read in full |
| Analytics DAO reuse for calendar | HIGH | `analytics_dao.dart` `getDailyTotals` verified; already called via `AnalyticsRepository` interface |
| Edit-from-list path (reuse `TransactionEditScreen`) | HIGH | `transaction_edit_screen.dart` read in full; `pop(true)` pattern confirmed |
| Delete path (reuse `deleteTransactionUseCaseProvider`) | HIGH | `delete_transaction_use_case.dart` read in full |
| Provider dependency graph | HIGH | `isGroupModeProvider`, `shadowBooksProvider`, `activeGroupProvider` all verified |
| Shadow `note` decryption behavior | MEDIUM | `TransactionRepositoryImpl._toModel()` calls `decryptField()` — exception handling not explicitly verified; confirm in Phase A |
| ARB key count estimate (~20 new keys) | MEDIUM | Based on feature list; exact count emerges during Phase H widget design |

---

## Sources

- `.planning/PROJECT.md` (v1.4 milestone scope, target features, out-of-scope)
- `CLAUDE.md` (Thin Feature rule, Placement Decision Rule, Riverpod 3 conventions, Drift syntax)
- `lib/features/home/presentation/screens/main_shell_screen.dart` (line 111 placeholder confirmed)
- `lib/data/daos/transaction_dao.dart` (read in full — query surface, existing methods)
- `lib/data/repositories/transaction_repository_impl.dart` (read in full — `_toModel`, `findByBookIds` gap)
- `lib/features/accounting/domain/repositories/transaction_repository.dart` (read in full — interface to extend)
- `lib/features/accounting/domain/models/transaction.dart` (schema: `bookId`, `timestamp`, `ledgerType`, fields)
- `lib/data/tables/transactions_table.dart` (schema v17, indices confirmed)
- `lib/application/family_sync/shadow_book_service.dart` (read in full — shadow book creation/lifecycle)
- `lib/features/home/presentation/providers/state_shadow_books.dart` (read in full — family data pattern)
- `lib/features/family_sync/presentation/providers/state_active_group.dart` (keepAlive confirmed)
- `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` (read in full — pop(true) pattern)
- `lib/application/accounting/delete_transaction_use_case.dart` (read in full)
- `lib/features/analytics/domain/repositories/analytics_repository.dart` (getDailyTotals interface)
- `lib/data/daos/analytics_dao.dart` (getDailyTotals query pattern)
- `lib/features/home/presentation/widgets/home_transaction_tile.dart` (read in full — NOT reusable for list)
- `lib/features/home/presentation/widgets/transaction_list_card.dart` (read in full — card shell, reusable)
- `lib/features/accounting/presentation/providers/repository_providers.dart` (provider patterns, delete/update)
- Live directory inspection of all feature modules and application sub-domains

---

*Architecture research for: v1.4 列表功能 — Home Pocket transaction list tab*
*Researched: 2026-05-29*
