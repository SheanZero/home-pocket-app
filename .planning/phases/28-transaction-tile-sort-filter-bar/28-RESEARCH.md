# Phase 28: Transaction Tile + Sort/Filter Bar — Research

**Researched:** 2026-05-30
**Domain:** Flutter list UI — tile widgets, Dismissible swipe-delete, pinned chip bar, grouped-by-day SliverList, multi-select bottom sheet
**Confidence:** HIGH (all core claims verified against live codebase)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** `ListFilterState.categoryId: String?` → `Set<String> categoryIds`; update `ListFilter.setCategoryFilter` → `toggleCategory`/`setCategories` mutators; update `listTransactionsProvider` category AND-composition (`categoryId ∈ categoryIds` when set non-empty; empty = no filter). Requires `build_runner build --delete-conflicting-outputs` after Freezed field change.

**D-02:** Category sheet L1 (parent) selection cascades to all its L2 children; tristate when parent partially selected. L1 selection = all L2 leaf IDs added to set; filtering uses the L2 leaf set only.

**D-03:** Bar category filter state = single count chip "Categories (N)" (N = selected leaf count); chip opens sheet; global clear-all clears it. No individual per-category chips in bar.

**D-04:** Sort interaction = field menu + direction arrow. Sort chip → popup menu / sheet listing 3 fields (date / edit-time / amount) single-select; independent direction arrow toggles asc/desc. Wires to `ListFilter.setSort(ListSortConfig)`.

**D-05:** Sort chip label reflects current field (e.g. ja "日付"/"金額"); direction arrow shows asc/desc; open menu has checkmark on active field. All three active-state signals present simultaneously. **Planner/verifier: sort chip must NOT stay at a generic "Sort" label — SC#4 hard requirement.**

**D-06:** Search UI = search icon in bar, expands inline search field on tap; field collapses when empty and user dismisses. Wires to `ListFilter.setSearch`.

**D-07:** Clear-all = conditional "Clear" chip; appears only when any filter/search/day-filter is active; calls `ListFilter.clearAll()`. No permanent clear control.

**D-08:** Bar layout = single-row horizontally scrollable chip row, pinned below `CalendarHeaderWidget` (does not scroll with the list). Contains: sort chip + direction arrow + ledger chips (All/生存/魂) + categories count chip + search icon + conditional clear chip.

**D-09:** Grouped-by-day list: date section header (DateFormatter date) per day; rows show time only. SC#1 reconciliation: header-date satisfies "row displays date via DateFormatter." Fallback: if verifier requires per-row date, add compact date inline.

**D-10:** Day-filter active → single day group (one header + its rows), same render path as multi-day.

### Claude's Discretion

- Bar layout chip spacing/order/visual details per Wa-Modern theme
- Swipe-delete: left-swipe red trash background, `confirmDismiss` AlertDialog, right-swipe no-op; animation/threshold/SnackBar wording per readability
- Soul-ledger satisfaction icon on list tile: follow `HomeTransactionTile` precedent (optional, use `satisfactionIcon` param)
- Category filter sheet widget construction: model on `category_selection_screen.dart` but multi-select + tristate; place in `lib/features/list/presentation/widgets/`
- ARB keys: placeholder/English this phase; Phase 30 three-locale收口
- Empty-filter state: structural placeholder text sufficient; visual polish Phase 30
- Widget/provider test construction: `ProviderContainer.test()` + `waitForFirstValue<T>` + Mocktail

### Deferred (OUT OF SCOPE)

- FAM-01..04 (family member attribution/filter/"mine only") — Phase 29
- LIST-04 (pull-to-refresh) — Phase 29
- LIST-03 (ARB three-locale copy, empty-state illustration, golden baseline) — Phase 30
- Swipe-right-to-edit — deferred (research line 162); tap-to-edit sufficient
- Tristate L1→L2 cascade beyond basic L1-selects-all-L2 — later milestone
- Pagination/infinite scroll — v1.5
- Undo delete SnackBar / `RestoreTransactionUseCase` — post-v1.4
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LIST-01 | Transaction list rows: category emoji + name, ledger-color tag, date, amount (tabular figures) | `HomeTransactionTile` verified as pure-UI template; `AppColors.survival/soul` verified; `AppTextStyles.amountSmall` verified with `FontFeature.tabularFigures()` |
| ROW-01 | Tap row → `TransactionEditScreen` pre-populated; save closes + list reflects update without manual refresh | `TransactionEditScreen(transaction:tx)` → `Navigator.of(context).pop(true)` on save (line 64 verified); `ref.invalidate(listTransactionsProvider)` already wired in `main_shell_screen.dart:93,172` |
| ROW-02 | Swipe row → delete confirmation → `DeleteTransactionUseCase.execute(id)` (soft-delete, hash-chain valid); row disappears | `DeleteTransactionUseCase` verified: calls `_transactionRepo.softDelete(id)` + sync hooks; `deleteTransactionUseCaseProvider` at accounting `repository_providers.dart:160` |
| SORT-01 | Sort by transaction date | `SortField.timestamp` in `sort_config.dart`; `ListSortConfig(sortField, sortDirection)` Freezed VO; `listFilterProvider.setSort()` mutator live |
| SORT-02 | Sort by edit/created time (reference default) | `SortField.updatedAt` — default in `ListSortConfig`; already wired through use case to DAO |
| SORT-03 | Sort by amount | `SortField.amount` in enum; DAO handles ORDER BY |
| SORT-04 | Toggle asc/desc | `SortDirection.asc/desc`; `ListFilter.setSort(config.copyWith(sortDirection:...))` |
| FILTER-01 | Text search: category name, merchant, note | `listTransactionsProvider` step 6b uses `CategoryLocalizationService.resolveFromId` + merchant/note `??''` contains; already live (Phase 26) |
| FILTER-02 | Filter by ledger (Survival/Soul) | `listFilterProvider.setLedgerFilter(LedgerType?)` mutator live; SQL-filtered by use case |
| FILTER-03 | Filter by one or more categories | **D-01: expand `categoryId:String?` → `Set<String> categoryIds`**; update filter mutator + provider AND-composition; category sheet new widget |
| FILTER-04 | AND composition + single clear-all | Already AND-composed in provider; `clearAll()` on `ListFilter` notifier live; D-07 conditional chip wires to it |
</phase_requirements>

---

## Summary

Phase 28 is a pure-UI delivery phase. All data plumbing — providers, use cases, DAO, domain models — shipped in Phases 24–27 and is fully live in the codebase. This phase's job is threefold: (1) assemble the grouped-by-day transaction list using `listTransactionsProvider`'s existing `List<TaggedTransaction>`, (2) build the pinned sort/filter bar that calls existing `ListFilter` mutators, and (3) wire tap-to-edit and swipe-to-delete through already-existing screens and use cases.

The single state-model change needed is D-01: `ListFilterState.categoryId: String?` → `Set<String> categoryIds`. This requires modifying one Freezed field, updating `ListFilter.setCategoryFilter` to `setCategories`/`toggleCategory`, updating the provider's category AND-composition from `== id` to `categoryIds.contains(categoryId)`, and running `build_runner build --delete-conflicting-outputs`. Everything else is new widget code consuming stable, tested infrastructure.

**No new Dismissible usage exists in the codebase** — the project uses `AlertDialog`-based confirmation via `showDialog` (pattern in `data_management_section.dart`) but has never used `Dismissible`. The `confirmDismiss` → AlertDialog pattern must be implemented fresh with awareness of the "dismissed widget still in tree" assertion pitfall.

**Primary recommendation:** Write `ListTransactionTile` (wrapping `HomeTransactionTile` logic + `Dismissible`) + `ListSortFilterBar` (single-row chip `Row` in `SingleChildScrollView`) + `ListDayGroup` (day header + tiles) in isolation before assembling into `ListScreen`. Apply D-01 Freezed change first as Wave 0 to unblock the category filter bar.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Transaction row display (tile) | Presentation / Widget | — | Pure UI: consumes TaggedTransaction already fetched by provider |
| Tap-to-edit navigation | Presentation / Widget | — | Widget pushes `TransactionEditScreen`; data pre-loaded via constructor |
| Swipe-to-delete | Presentation / Widget | Application | Widget shows `Dismissible` + dialog; calls `deleteTransactionUseCaseProvider` |
| Sort/filter bar state | Presentation / Provider (listFilterProvider) | — | `listFilterProvider` (keepAlive) is the state; bar is stateless UI mutating it |
| Category multi-select logic | Presentation / Widget | Domain (ListFilterState) | Sheet computes L1→L2 cascade locally; writes `Set<String>` to provider |
| Category filter AND-composition | Presentation / Provider (listTransactionsProvider) | — | Already Dart-side in provider step 6; expand from single-id to set-membership check |
| Grouped-by-day assembly | Presentation / Widget | — | Group `List<TaggedTransaction>` by date in widget/helper; no new provider |
| Pinned bar layout (non-scrolling) | Presentation / Widget | — | `Column` in `ListScreen` + `Expanded(child: ListView)`; or SliverAppBar technique |

---

## Standard Stack

### Core (already in project — no new installs)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_riverpod` | `^3.x` (project-pinned) | State via `listFilterProvider` + `listTransactionsProvider` | Project-wide pattern [VERIFIED: codebase] |
| `riverpod_annotation` | `^4.x` (project-pinned) | `@riverpod` code gen for any new providers | Project-wide pattern [VERIFIED: codebase] |
| `freezed_annotation` | project-pinned | Freezed VO for `ListFilterState` field change | `@freezed` on domain models [VERIFIED: codebase] |
| `flutter/material.dart` | SDK | `Dismissible`, `AlertDialog`, `PopupMenuButton`, `SingleChildScrollView`, `Chip` | Flutter SDK [VERIFIED: codebase] |

### No New Packages

Phase 28 requires zero new package dependencies. All UI components (`Dismissible`, `PopupMenuButton`, `FilterChip`, `AnimatedContainer`) are Flutter SDK. All data formatters and colors are project infrastructure already in use.

**Installation:** none required.

---

## Package Legitimacy Audit

No external packages are added in this phase. Audit not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
ListScreen (Column)
├── CalendarHeaderWidget          ← Phase 27 (fixed, non-scrolling)
├── ListSortFilterBar             ← NEW (pinned chip row, non-scrolling)
│   ├── SortChip + DirectionArrow → listFilterProvider.setSort()
│   ├── Ledger chips (All/生存/魂) → listFilterProvider.setLedgerFilter()
│   ├── CategoryCountChip         → opens CategoryFilterSheet
│   │   └── CategoryFilterSheet  → listFilterProvider.setCategories(Set<String>)
│   ├── SearchIcon → inline TextField → listFilterProvider.setSearch()
│   └── ClearChip (conditional)  → listFilterProvider.clearAll()
└── Expanded(
      ListView.builder (grouped-by-day)
      └── [for each day group]
          ├── DayHeader (DateFormatter.formatDate)
          └── [for each tx in group]
              └── ListTransactionTile
                  ├── Dismissible (endToStart only)
                  │   ├── confirmDismiss → AlertDialog
                  │   └── onDismissed → deleteTransactionUseCaseProvider.execute(id)
                  │                    → ref.invalidate(listTransactionsProvider)
                  └── onTap → Navigator.push(TransactionEditScreen(tx))
                             → if result==true: ref.invalidate(listTransactionsProvider)
    )

Data flow:
listFilterProvider (keepAlive:true) ──watch──► listTransactionsProvider(bookId)
                                                └──► List<TaggedTransaction>
                                                     └──► group by date ──► ListView
```

### Recommended Project Structure (new files only)

```
lib/features/list/presentation/
├── widgets/
│   ├── list_transaction_tile.dart          ★ NEW — tile + Dismissible wrapper
│   ├── list_sort_filter_bar.dart           ★ NEW — pinned chip row
│   ├── list_day_group_header.dart          ★ NEW — date section header (or inline)
│   ├── list_category_filter_sheet.dart     ★ NEW — L1/L2 multi-select bottom sheet
│   └── list_empty_state.dart              ★ NEW — empty placeholder
└── screens/
    └── list_screen.dart                   MODIFY — replace Expanded(spinner) with list
```

Domain model change (Wave 0):
```
lib/features/list/domain/models/
└── list_filter_state.dart                 MODIFY — categoryId:String? → categoryIds:Set<String>
```

Provider change (Wave 0):
```
lib/features/list/presentation/providers/
├── state_list_filter.dart                 MODIFY — setCategoryFilter → setCategories/toggleCategory
└── state_list_transactions.dart           MODIFY — `filter.categoryId == id` → `filter.categoryIds.contains(id)` (or `.isEmpty` guard)
```

### Pattern 1: Grouped-by-Day ListView Assembly

**What:** Group `List<TaggedTransaction>` by date into a `List<_DayGroup>` (date + items), then render with `ListView.builder` using a sum of (1 header + N items) per group.

**When to use:** Always for D-09 grouped layout. Works for both full-month and single-day (D-10 produces one group).

```dart
// Source: ASSUMED (standard Flutter pattern, no library needed)

// Step 1: group in a pure function (call in widget build or a helper)
List<_DayGroup> _groupByDay(List<TaggedTransaction> txs) {
  final map = <DateTime, List<TaggedTransaction>>{};
  for (final t in txs) {
    final key = DateTime(
      t.transaction.timestamp.year,
      t.transaction.timestamp.month,
      t.transaction.timestamp.day,
    );
    map.putIfAbsent(key, () => []).add(t);
  }
  // Sort keys descending (newest day first) — mirrors ListSortConfig.desc default
  final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final k in sortedKeys) _DayGroup(date: k, items: map[k]!)];
}

// Step 2: flatten into indexed item model for ListView.builder
// Use a sealed item type (header vs row) to avoid index arithmetic bugs
sealed class _ListItem {}
class _HeaderItem extends _ListItem { final DateTime date; _HeaderItem(this.date); }
class _RowItem extends _ListItem { final TaggedTransaction tx; _RowItem(this.tx); }

List<_ListItem> _flattenGroups(List<_DayGroup> groups) => [
  for (final g in groups) ...[
    _HeaderItem(g.date),
    for (final tx in g.items) _RowItem(tx),
  ]
];
```

**Note on sort direction:** The grouping function sorts day keys desc. Within each day, the order comes from `listTransactionsProvider` (SQL ORDER BY via `ListSortConfig`). The sort direction toggle affects within-day ordering and also reverses day key order — simplest: re-sort keys according to `filter.sortConfig.sortDirection`.

### Pattern 2: `Dismissible` + `confirmDismiss` Safe Pattern

**What:** Left-swipe reveals red background; `confirmDismiss` shows `AlertDialog` and returns `bool`; if confirmed, `onDismissed` calls the use case. Returns `false` from `confirmDismiss` to abort the dismiss (tile stays in list).

**Critical pitfall:** If you call `setState`/`ref.invalidate` inside `onDismissed` AND the widget is already removed from the tree by Dismissible, Flutter throws "Looking up a deactivated widget's ancestor". The safe pattern: in `onDismissed`, call the use case synchronously (no await for the invalidate), then invalidate AFTER the frame via `WidgetsBinding.instance.addPostFrameCallback` — OR simply use `if (mounted)` guard if the tile is a `ConsumerStatefulWidget`.

**Simpler approach verified by existing pattern:** Since `listTransactionsProvider` is a `FutureProvider` already set to `keepAlive: true` on `listFilterProvider`, invalidating it causes an async rebuild that naturally removes the tile from the list. The tile itself is removed from the `Dismissible` regardless (Flutter handles this). The assertion is avoided by not accessing `context` after the widget is dismissed.

```dart
// Source: ASSUMED (Flutter Dismissible cookbook pattern adapted for confirmDismiss)
Dismissible(
  key: ValueKey(tx.transaction.id),
  direction: DismissDirection.endToStart,   // left-swipe only (D-08 right-swipe = no-op)
  background: Container(
    color: Colors.red,
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 16),
    child: const Icon(Icons.delete, color: Colors.white),
  ),
  confirmDismiss: (_) async {
    // CRITICAL: use showDialog, await the bool result, return it.
    // Returning null or false aborts the swipe; Dismissible restores tile.
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除しますか？'),       // Phase 30: ARB key
        content: const Text('この記録を削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  },
  onDismissed: (_) {
    // Widget is being removed from tree — do NOT access context after this frame.
    // Use ref.read (not ref.watch) for one-shot side effects.
    ref.read(deleteTransactionUseCaseProvider).execute(tx.transaction.id);
    ref.invalidate(listTransactionsProvider(bookId: bookId));
    // SC#3: SnackBar (no undo in v1.4 — STATE.md confirms undo deferred)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('削除しました')),  // Phase 30: ARB key
    );
  },
)
```

**Why `confirmDismiss` returns `Future<bool?>` not `Future<bool>`:** `showDialog<bool>` returns `bool?` (null if dismissed by back button). Dismissible treats `null` as `false` (cancels dismiss) — safe default.

### Pattern 3: D-01 Freezed Field Change (`categoryId` → `categoryIds`)

**What:** Expand `ListFilterState.categoryId: String?` to `categoryIds: Set<String>` with `@Default({})`.

**Exact change to `list_filter_state.dart`:**

```dart
// BEFORE (current live code):
String? categoryId,

// AFTER (D-01):
@Default(<String>{}) Set<String> categoryIds,
```

**Cascading changes required:**
1. `list_filter_state.dart` — field rename + type change
2. `list_sort_config.dart` — no change
3. `state_list_filter.dart` — replace `setCategoryFilter(String? id)` with:
   ```dart
   void setCategories(Set<String> ids) {
     state = state.copyWith(categoryIds: ids);
   }
   void toggleCategory(String id) {
     final current = Set<String>.from(state.categoryIds);
     if (current.contains(id)) {
       current.remove(id);
     } else {
       current.add(id);
     }
     state = state.copyWith(categoryIds: current);
   }
   ```
4. `state_list_transactions.dart` — replace category filter from:
   ```dart
   // BEFORE: passed as categoryId: filter.categoryId to use case
   // (SQL-side single-value filter in Phase 26 / GetListParams)
   ```
   to Dart-side post-filter (because the use case's `GetListParams.filter.categoryId` was single-valued; with a Set it may be simpler to pass `null` to the SQL layer and filter in Dart):
   ```dart
   // After SQL fetch (step 5.5, between day-filter and text-search):
   if (filter.categoryIds.isNotEmpty) {
     txs = txs.where((tx) => filter.categoryIds.contains(tx.transaction.categoryId)).toList();
   }
   ```
   **Important:** Also update `GetListParams` / use case if `categoryId: String?` is passed from `ListFilterState` — verify `get_list_transactions_use_case.dart` and `GetListParams`. Pass `null` for categoryId when `categoryIds` is used, and do category filtering Dart-side.
5. Run `flutter pub run build_runner build --delete-conflicting-outputs`
6. Run `flutter analyze` — must be 0 issues before any other work

### Pattern 4: Pinned Sort/Filter Bar (D-08)

**What:** Bar that does not scroll away with the list, placed between `CalendarHeaderWidget` and the list.

**Layout approach:** `Column` with three children: `CalendarHeaderWidget` (fixed height), `ListSortFilterBar` (fixed height, wraps chip row in `SingleChildScrollView(scrollDirection: Axis.horizontal)`), `Expanded(child: ListView.builder(...))`.

This is simpler and more reliable than `SliverPersistentHeader` for a fixed-height bar:

```dart
// Source: ASSUMED (standard Flutter Column + Expanded pattern)
@override
Widget build(BuildContext context, WidgetRef ref) {
  return Column(
    children: [
      CalendarHeaderWidget(bookId: bookId, currencyCode: currencyCode, locale: locale),
      const ListSortFilterBar(),   // fixed height, does NOT scroll
      Expanded(
        child: _buildGroupedList(context, ref),
      ),
    ],
  );
}
```

**Alternative (if CalendarHeader + bar should pin together when list scrolls):** Already using `Column` in Phase 27's `ListScreen` — the `Column` wraps both, making both non-scrolling by default. No `SliverPersistentHeader` needed.

### Pattern 5: Category Multi-Select Sheet (D-02)

**What:** Bottom sheet (or full screen) adapted from `CategorySelectionScreen` for multi-select + tristate.

**Key derivation from existing code:**

```dart
// CategorySelectionScreen._loadCategories() already does:
final l1 = <Category>[];
final Map<String, List<Category>> l2ByParent = {};
for (final cat in all) {
  if (cat.level == 1) l1.add(cat);
  else if (cat.level == 2 && cat.parentId != null)
    l2ByParent.putIfAbsent(cat.parentId!, () => []).add(cat);
}
// Reuse this exact pattern in the filter sheet.
```

**Tristate logic:**

```dart
// Source: ASSUMED (derived from D-02 specification)
enum _L1SelectState { none, partial, all }

_L1SelectState _l1State(String l1Id, Set<String> selectedIds, Map<String, List<Category>> l2Map) {
  final children = l2Map[l1Id] ?? [];
  if (children.isEmpty) return _L1SelectState.none;
  final selectedCount = children.where((c) => selectedIds.contains(c.id)).length;
  if (selectedCount == 0) return _L1SelectState.none;
  if (selectedCount == children.length) return _L1SelectState.all;
  return _L1SelectState.partial;
}

void _toggleL1(String l1Id, Set<String> current, Map<String, List<Category>> l2Map) {
  final children = l2Map[l1Id] ?? [];
  final l1State = _l1State(l1Id, current, l2Map);
  if (l1State == _L1SelectState.all) {
    // Deselect all children
    for (final c in children) current.remove(c.id);
  } else {
    // Select all children (handles both none and partial)
    for (final c in children) current.add(c.id);
  }
}
```

**Sheet behavior:** On "Apply" / close, call `ref.read(listFilterProvider.notifier).setCategories(selectedIds)`. Pre-populate from current `filter.categoryIds`.

### Pattern 6: Search Icon Expands Inline (D-06)

**What:** `AnimatedContainer` expands from icon width to full `TextField` width on tap.

```dart
// Source: ASSUMED (standard Flutter AnimatedContainer expand pattern)
bool _searchExpanded = false;

AnimatedContainer(
  duration: const Duration(milliseconds: 200),
  width: _searchExpanded ? 200 : 36,
  child: _searchExpanded
    ? TextField(
        autofocus: true,
        onChanged: (v) => ref.read(listFilterProvider.notifier).setSearch(v),
        onSubmitted: (_) => setState(() => _searchExpanded = false),
        decoration: const InputDecoration(
          hintText: 'Search...',
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      )
    : IconButton(
        icon: const Icon(Icons.search, size: 20),
        onPressed: () => setState(() => _searchExpanded = true),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
)
```

**Note:** The bar must be `StatefulWidget` or `ConsumerStatefulWidget` for `_searchExpanded` local state. The filter state (searchQuery) lives in `listFilterProvider`.

### Pattern 7: Sort Chip with Active Field Name (D-05)

**What:** `FilterChip` or `ActionChip` whose label reflects the current `SortField` value.

```dart
// Source: ASSUMED
String _sortFieldLabel(SortField field, Locale locale) {
  switch (field) {
    case SortField.timestamp:
      return locale.languageCode == 'ja' ? '日付' : (locale.languageCode == 'zh' ? '日期' : 'Date');
    case SortField.updatedAt:
      return locale.languageCode == 'ja' ? '更新日時' : (locale.languageCode == 'zh' ? '更新时间' : 'Edit time');
    case SortField.amount:
      return locale.languageCode == 'ja' ? '金額' : (locale.languageCode == 'zh' ? '金额' : 'Amount');
  }
}

// In bar build:
final sortConfig = filter.sortConfig;
ActionChip(
  avatar: const Icon(Icons.sort, size: 16),
  label: Text(_sortFieldLabel(sortConfig.sortField, locale)),
  onPressed: () => _showSortMenu(context, ref, sortConfig),
),
IconButton(
  icon: Icon(sortConfig.sortDirection == SortDirection.desc
    ? Icons.arrow_downward
    : Icons.arrow_upward, size: 18),
  onPressed: () => ref.read(listFilterProvider.notifier).setSort(
    sortConfig.copyWith(sortDirection: sortConfig.sortDirection == SortDirection.desc
      ? SortDirection.asc
      : SortDirection.desc),
  ),
),
```

### Anti-Patterns to Avoid

- **Duplicate `repository_providers.dart`:** Phase 28 must NOT create a new `repository_providers.dart` in the list feature. Use the existing `deleteTransactionUseCaseProvider` imported from `lib/features/accounting/presentation/providers/repository_providers.dart`. The existing list `repository_providers.dart` already imports `transactionRepositoryProvider` with `show` to avoid duplication — follow the same pattern. [VERIFIED: codebase `lib/features/list/presentation/providers/repository_providers.dart:5`]

- **`ref.watch` for delete SnackBar side effect:** SnackBar display after delete must NOT trigger from `ref.watch`. The `onDismissed` callback is a one-time event; call `ScaffoldMessenger` directly inside `onDismissed` using a `if (mounted)` guard (or omit it — SnackBar call on a deactivated context is typically safe if the Scaffold is still alive).

- **Hard-coding hex colors for ledger tags:** Use `AppColors.survival` and `AppColors.soul` exclusively. [VERIFIED: `AppColors.survival = Color(0xFF5A9CC8)`, `AppColors.soul = Color(0xFF47B88A)` at `app_colors.dart:40,44`]

- **Raw `await container.read(provider.future)` in tests:** Use `waitForFirstValue<T>(container, provider)` from `test/helpers/test_provider_scope.dart`. [VERIFIED: helper exists at `test/helpers/test_provider_scope.dart:34`]

- **Naming conflict on Notifier class:** The domain model is `ListFilterState` (Freezed); the Notifier is `ListFilter` (generates `listFilterProvider`). Do not create a second class called `ListFilterState` in the providers directory. [VERIFIED: `state_list_filter.dart:17` uses `class ListFilter`]

- **Dismissible key must be `ValueKey`:** Using `Key(tx.id)` without `ValueKey` wrapping causes assertion failures when the list rebuilds. Always `key: ValueKey(tx.transaction.id)` [ASSUMED — Flutter best practice].

- **Passing `Transaction.note` through route params:** Pass only the `Transaction` object (already decrypted in memory) to `TransactionEditScreen`. The constructor accepts `required Transaction transaction` [VERIFIED: `transaction_edit_screen.dart:28`]. Do not extract note text and pass it as a string param — that would expose decrypted data in the navigation history.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tabular figure amount alignment | Custom monospace amount widget | `AppTextStyles.amountSmall` (has `FontFeature.tabularFigures()`) | Already handles alignment across all amount sizes |
| Locale-aware category name | Custom string mapping | `CategoryLocalizationService.resolveFromId(categoryId, locale)` | 700+ line static locale map already built [VERIFIED: codebase] |
| Amount formatting (JPY 0 decimals, etc.) | `'¥${amount}'` string interpolation | `NumberFormatter.formatCurrency(amount, 'JPY', locale)` | Handles JPY/CNY/USD/EUR/GBP correctly [VERIFIED: `number_formatter.dart`] |
| Date formatting (day header) | `DateFormat('MM/dd')` directly | `DateFormatter.formatDate(date, locale)` | Handles ja/zh/en formats [VERIFIED: `date_formatter.dart:8`] |
| Time formatting (row time) | `DateFormat('HH:mm')` directly | `DateFormatter.formatDateTime` or local `DateFormat('HH:mm')` | `formatDateTime` includes date; for time-only, use `DateFormat('HH:mm', locale.toString()).format(tx.timestamp)` directly |
| Swipe confirmation dialog | Custom overlay / gesture detector | `Dismissible` + `confirmDismiss` + `showDialog<bool>` | Flutter SDK covers the full swipe-then-confirm pattern |
| L1/L2 category tree loading | New DAO call | `categoryRepositoryProvider.findActive()` (already in accounting feature) | Pattern verified in `category_selection_screen.dart:48-64` |
| Delete use case | Direct DAO delete | `deleteTransactionUseCaseProvider.execute(id)` | Only safe path: soft-delete + hash-chain + sync hooks [VERIFIED: `delete_transaction_use_case.dart`] |

**Key insight:** The codebase is rich with exactly the right primitives for list UI. The danger is in bypassing them — especially `deleteTransactionUseCaseProvider` (bypassing breaks the hash chain) and `AppTextStyles.amountSmall` (bypassing breaks tabular alignment).

---

## Common Pitfalls

### Pitfall 1: Dismissible "Looking up deactivated widget" assertion

**What goes wrong:** Inside `onDismissed`, you call `ref.invalidate` which triggers a rebuild. If the tile's widget is already removed from the tree (Dismissible removed it), any `context`-dependent operation like `ScaffoldMessenger.of(context)` or accessing `ref` in a `ConsumerStatefulWidget` that's been disposed throws `Looking up a deactivated widget's ancestor`.

**Why it happens:** Dismissible removes the child widget from the tree synchronously when `onDismissed` fires, before the callback returns.

**How to avoid:** In `onDismissed`:
1. Use `ref.read` (synchronous, does not need `context`)
2. Call `ScaffoldMessenger.of(context)` BEFORE any await — the `context` is still valid when `onDismissed` first fires (the Scaffold is still alive, just the tile widget is removed)
3. Do NOT `await` inside `onDismissed` — the use case call should be fire-and-forget via `.execute(id)` without awaiting the `Result`
4. `ref.invalidate(listTransactionsProvider(bookId: bookId))` is safe — it just marks the provider for rebuild, doesn't access widget tree

**Warning signs:** Flutter assertion error mentioning "deactivated widget" or "null check operator used on null value" in the navigator after swipe.

### Pitfall 2: D-01 Freezed field change breaks generated code silently

**What goes wrong:** Changing `categoryId: String?` to `categoryIds: Set<String>` in `list_filter_state.dart` invalidates the generated `.freezed.dart` file. If `build_runner` is not run, the generated code still references `categoryId` and the analyzer reports 0 errors on the *old* generated file but the new source file is inconsistent.

**Why it happens:** Build runner output is committed; old generated file persists until explicitly rebuilt.

**How to avoid:** D-01 Freezed change is Wave 0. Run `flutter pub run build_runner build --delete-conflicting-outputs` immediately after making the change. Then run `flutter analyze` and verify 0 issues before writing any widget code. [VERIFIED pitfall: CLAUDE.md Common Pitfall #3 and #13]

**Warning signs:** Generated `.freezed.dart` still has `copyWith(categoryId:)` in its signature after the change.

### Pitfall 3: `listTransactionsProvider` category filter still uses single-value `categoryId` after D-01

**What goes wrong:** `state_list_transactions.dart` currently passes `filter.categoryId` (from `GetListParams` → SQL) to filter at the DB layer. After D-01 changes the field to `Set<String> categoryIds`, the provider must be updated to use Dart-side category filtering (`filter.categoryIds.contains(tx.transaction.categoryId)`) and pass `null` for the SQL-layer `categoryId` param — otherwise the SQL query uses the old single-value path (which returns nothing or everything, depending on the nil handling).

**How to avoid:** In `state_list_transactions.dart`, after D-01:
- Pass `categoryId: null` to `GetListParams` (or update `GetListParams` to accept `Set<String>`)
- Add Dart-side filter step: `if (filter.categoryIds.isNotEmpty) { txs = txs.where((t) => filter.categoryIds.contains(t.transaction.categoryId)).toList(); }`

### Pitfall 4: Sort direction mismatch between day-group ordering and within-group ordering

**What goes wrong:** The grouped-by-day code sorts day keys by date descending (newest day first). But when `sortConfig.sortDirection == SortDirection.asc` (oldest first), the day groups should also appear ascending. If the grouping code hard-codes descending day order, toggling to ascending gives ascending within-day order but still descending day groups.

**How to avoid:** Pass `filter.sortConfig.sortDirection` into the grouping helper and sort keys accordingly:
```dart
sortedKeys.sort((a, b) => filter.sortConfig.sortDirection == SortDirection.desc
  ? b.compareTo(a)   // newest day first
  : a.compareTo(b)); // oldest day first
```

### Pitfall 5: `ProviderException` wrapping in tests

**What goes wrong:** Tests asserting `throwsA(isA<Exception>())` on a provider error miss the `ProviderException` wrapper introduced in Riverpod 3. [VERIFIED: CLAUDE.md Riverpod 3 conventions]

**How to avoid:**
```dart
// WRONG:
expect(() => ..., throwsA(isA<Exception>()));

// CORRECT:
expect(() => ..., throwsA(isA<ProviderException>()
  .having((e) => e.exception, 'exception', isA<Exception>())));
// Import: package:flutter_riverpod/misc.dart
```

### Pitfall 6: ROW-02 hash-chain test construction

**What:** SC#3 requires a unit test asserting `isDeleted=true` AND `HashChainService.verifyChain()` returns valid after soft-delete.

**What goes wrong:** Test constructs `HashChainService` but doesn't pass the transactions in the correct format — `verifyChain` takes `List<Map<String, dynamic>>` representing the raw row data (not the domain `Transaction` model).

**Verified signature:**
```dart
// hash_chain_service.dart:45
ChainVerificationResult verifyChain(List<Map<String, dynamic>> transactions)
```

The test must:
1. Insert 3 transactions via the repository (so the chain is established)
2. Soft-delete the middle one via `DeleteTransactionUseCase.execute(id)`
3. Fetch remaining non-deleted rows as raw maps (via DAO or repository)
4. Call `hashChainService.verifyChain(remainingMaps)` and assert `result.isValid`
5. Assert the deleted row's `isDeleted` flag is `true`

Use `ProviderContainer.test()` with the in-memory test database from `test/helpers/test_provider_scope.dart` (uses `AppDatabase.forTesting()`).

---

## Code Examples

### Verified: deleteTransactionUseCaseProvider location and signature

```dart
// Source: lib/features/accounting/presentation/providers/repository_providers.dart:159
@riverpod
DeleteTransactionUseCase deleteTransactionUseCase(Ref ref) {
  return DeleteTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    syncEngine: ref.watch(syncEngineProvider),
    changeTracker: ref.watch(transactionChangeTrackerProvider),
  );
}
// Generates: deleteTransactionUseCaseProvider
```

### Verified: listFilterProvider mutator signatures (live code)

```dart
// Source: lib/features/list/presentation/providers/state_list_filter.dart
@Riverpod(keepAlive: true)
class ListFilter extends _$ListFilter {
  void selectMonth(int year, int month) { ... }   // resets activeDayFilter
  void selectDay(DateTime? day) { ... }
  void setSort(ListSortConfig sort) { ... }
  void setLedgerFilter(LedgerType? type) { ... }
  void setCategoryFilter(String? id) { ... }      // D-01: replace with setCategories(Set<String>)
  void setSearch(String q) { ... }
  void setMemberFilter(String? bookId) { ... }
  void clearAll() { ... }                         // resets to ListFilterState.initial()
}
// Generates: listFilterProvider
```

### Verified: TransactionEditScreen constructor and pop pattern

```dart
// Source: lib/features/accounting/presentation/screens/transaction_edit_screen.dart:26-64
class TransactionEditScreen extends ConsumerStatefulWidget {
  const TransactionEditScreen({super.key, required this.transaction});
  final Transaction transaction;
}
// On save: Navigator.of(context).pop(true);   // line 64

// Usage from list tile:
final result = await Navigator.push<bool>(
  context,
  MaterialPageRoute(
    builder: (_) => TransactionEditScreen(transaction: tx.transaction),
  ),
);
if (result == true) {
  ref.invalidate(listTransactionsProvider(bookId: bookId));
  // Also invalidate calendar totals if Phase 27 provider is parameterized by month:
  // ref.invalidate(calendarDailyTotalsProvider(bookId: bookId, year: ..., month: ...));
}
```

### Verified: HomeTransactionTile constructor signature (tile template)

```dart
// Source: lib/features/home/presentation/widgets/home_transaction_tile.dart:12-55
class HomeTransactionTile extends StatelessWidget {
  const HomeTransactionTile({
    super.key,
    required this.tagText,        // ledger type short label e.g. "生存"/"魂"
    required this.tagBgColor,     // AppColors.survivalLight / AppColors.soulLight
    required this.tagTextColor,   // AppColors.survival / AppColors.soul
    required this.merchant,
    required this.category,
    required this.categoryColor,
    required this.formattedAmount,
    required this.amountColor,
    this.satisfactionIcon,        // optional, soul rows only
    this.onTap,
  });
}
// Layout: tag | [merchant, category+satisfactionIcon] | amount
// Amount style: AppTextStyles.amountSmall (has FontFeature.tabularFigures)
```

### Verified: AppColors constants

```dart
// Source: lib/core/theme/app_colors.dart:40,44
static const survival = Color(0xFF5A9CC8);     // blue — ledger tag
static const survivalLight = Color(0xFFE8F0F8); // tag background
static const soul = Color(0xFF47B88A);          // green — ledger tag
static const soulLight = Color(0xFFE5F5ED);     // tag background
```

### Verified: listTransactionsProvider invalidation already wired in MainShellScreen

```dart
// Source: lib/features/home/presentation/screens/main_shell_screen.dart:93,172
// Sync listener (line 93):
ref.invalidate(listTransactionsProvider(bookId: bookId));
// FAB return (line 172):
ref.invalidate(listTransactionsProvider(bookId: bookId));
// SC#2 "list reflects update without manual refresh" is therefore already satisfied
// for FAB entry and sync. Tile onTap return must also invalidate (see ROW-01 pattern above).
```

### Verified: waitForFirstValue helper

```dart
// Source: test/helpers/test_provider_scope.dart:34
Future<AsyncValue<T>> waitForFirstValue<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider,
) { ... }
// MUST use this instead of: await container.read(provider.future)
// (Riverpod 3 disposes orphan reads before build settles — CLAUDE.md convention)
```

### Verified: CategorySelectionScreen L1/L2 loading pattern (template for filter sheet)

```dart
// Source: lib/features/accounting/presentation/screens/category_selection_screen.dart:46-88
// Pattern: load categories → split by level → sort → auto-expand parent of selected
Future<void> _loadCategories() async {
  final repo = ref.read(categoryRepositoryProvider);
  final all = await repo.findActive();
  final l1 = <Category>[];
  final l2Map = <String, List<Category>>{};
  for (final cat in all) {
    if (cat.level == 1) l1.add(cat);
    else if (cat.level == 2 && cat.parentId != null)
      l2Map.putIfAbsent(cat.parentId!, () => []).add(cat);
  }
  // Sort by sortOrder in each level
  // ...
}
// Re-use this exact load pattern; replace single-select with multi-select + tristate UI
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ListFilterState.categoryId: String?` (Phase 25 D-02) | `categoryIds: Set<String>` (Phase 28 D-01) | This phase | Enables multi-select filter; requires Freezed regen |
| Generic "Sort" chip label | Sort chip shows active field name (D-05) | This phase | SC#4 compliance: active field visible in bar without opening menu |
| Single-select category filter (deferred from Phase 25) | Multi-select with L1→L2 cascade + tristate (D-02) | This phase | SC#5 "one or more categories" compliance |
| `ListScreen` shows `CircularProgressIndicator` (Phase 27) | Grouped-by-day list + pinned sort/filter bar | This phase | First user-observable delivery of LIST-01, ROW-01, ROW-02, SORT-01..04, FILTER-01..04 |

**Deprecated/outdated:**
- `ListFilter.setCategoryFilter(String? id)` — replaced by `setCategories(Set<String>)` + `toggleCategory(String)` in D-01
- Research/ARCHITECTURE `state_list_filter.dart` draft using `setCategoryFilter(String? id)` — superseded by Phase 26's live code + D-01 expansion

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Dismissible` `onDismissed` fires synchronously after tile removal; `ScaffoldMessenger.of(context)` is still valid at that instant | Pattern 2 (Dismissible) | SnackBar might throw; add `if (context.mounted)` guard around SnackBar call |
| A2 | `AnimatedContainer` expand pattern for search field is preferred over `AnimatedCrossFade` / `AnimatedSwitcher` | Pattern 6 (Search expand) | Visual polish only; either works; choose per implementation |
| A3 | Passing `categoryId: null` to `GetListParams` + Dart-side category filter is the cleanest D-01 migration path vs. updating `GetListParams` to accept `Set<String>` | Pattern 3 (D-01 change) | If `GetListParams` is updated to accept `Set`, SQL `IN (...)` query is more efficient for large sets; for single-month loads (<500 rows) Dart-side is equivalent |
| A4 | Day-group keys should mirror `listTransactionsProvider`'s sort direction (newest day first for desc, oldest for asc) | Pattern 1 (grouping) | UX mismatch: within-day sort desc but day groups sorted asc would be confusing |
| A5 | `ProviderContainer.test()` is available as a static constructor in Riverpod 3 for unit tests | Testing | If API changed, fall back to `ProviderContainer() + addTearDown(container.dispose)` |

---

## Open Questions

1. **Does `GetListParams` need updating for `Set<String>` categories?**
   - What we know: `GetListParams` currently takes `ListFilterState filter` (Phase 25 D-04); the use case reads `filter.categoryId` (single value) and passes to the DAO.
   - What's unclear: After D-01, should `GetListParams` be updated to pass `categoryIds: Set<String>` to DAO (SQL `IN (...)`), or should category filtering stay Dart-side only?
   - Recommendation: For Phase 28, Dart-side filtering is sufficient (single-month, <500 rows). Pass `null` for the SQL `categoryId` param. A future optimization could push `IN (...)` to SQL. The planner should choose whichever path results in fewer modified files.

2. **Should `calendarDailyTotalsProvider` be invalidated after edit/delete?**
   - What we know: `CalendarHeaderWidget` watches `calendarDailyTotalsProvider(bookId, year, month)`; editing or deleting a transaction changes the per-day total.
   - What's unclear: The provider is parameterized — invalidating it requires knowing the current `year` and `month` from `filter`.
   - Recommendation: Yes, invalidate on edit/delete return. Read `filter.selectedYear/selectedMonth` from `listFilterProvider` to construct the invalidation key.

---

## Environment Availability

This phase is code/widget only — no new external tools, CLIs, services, or runtimes are needed. Build environment verified via previous phases.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `flutter pub run build_runner` | D-01 Freezed regen | ✓ | project-pinned | — |
| `flutter analyze` | CI gate (0 issues) | ✓ | SDK | — |
| `flutter test` | ROW-02 hash-chain unit test | ✓ | SDK | — |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Flutter test (`flutter_test` SDK) + Mocktail |
| Config file | none (standard `flutter test`) |
| Quick run command | `flutter test test/unit/features/list/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ROW-02 | `DeleteTransactionUseCase.execute(id)` → `isDeleted=true` | unit | `flutter test test/unit/application/accounting/delete_transaction_use_case_test.dart` | ❌ Wave 0 |
| ROW-02 | After soft-delete, `HashChainService.verifyChain()` returns valid | unit | `flutter test test/unit/features/list/delete_hash_chain_integrity_test.dart` | ❌ Wave 0 |
| D-01 | `ListFilterState.categoryIds` Set field: `copyWith` immutability | unit | `flutter test test/unit/features/list/list_filter_state_test.dart` | ❌ Wave 0 |
| FILTER-03 | `ListFilter.setCategories` + `toggleCategory` mutators | unit | `flutter test test/unit/features/list/list_filter_notifier_test.dart` | ❌ Wave 0 |
| LIST-01 + SORT-01..04 + FILTER-01..04 | Bar chip taps → correct `listFilterProvider` state mutations | widget | `flutter test test/widget/features/list/list_sort_filter_bar_test.dart` | ❌ Wave 0 |
| ROW-01 | Tile tap → push `TransactionEditScreen`; pop(true) → list provider invalidated | widget | `flutter test test/widget/features/list/list_transaction_tile_test.dart` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter analyze && flutter test test/unit/features/list/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green + `flutter analyze` 0 issues before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/unit/features/list/list_filter_state_test.dart` — covers D-01 `categoryIds` field + `copyWith` immutability
- [ ] `test/unit/features/list/list_filter_notifier_test.dart` — covers `setCategories`, `toggleCategory`, `clearAll`
- [ ] `test/unit/features/list/delete_hash_chain_integrity_test.dart` — covers ROW-02 soft-delete + `verifyChain()` valid (SC#3)
- [ ] `test/widget/features/list/list_transaction_tile_test.dart` — covers ROW-01 tap navigation + ROW-02 swipe + confirm dialog
- [ ] `test/widget/features/list/list_sort_filter_bar_test.dart` — covers SORT-01..04 + FILTER-01..04 chip interactions

---

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes (search query) | In-memory `.contains()` — no injection vector; no SQL path for text search |
| V6 Cryptography | no | Crypto handled by infrastructure layer (no new crypto in this phase) |

### Known Threat Patterns for List UI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Financial data logging during search/filter | Information disclosure | CLAUDE.md: "NEVER log sensitive data" — never log `note`, `merchant`, or `formattedAmount` values |
| Note/merchant exposed via route params to edit screen | Information disclosure | Pass `Transaction` object (decrypted in memory) to `TransactionEditScreen(transaction: tx)` — never serialize to route query params |
| Raw `TransactionRow.note` (ciphertext) shown in tile | Information disclosure | Use `TaggedTransaction.transaction.note` (domain model, already decrypted by `TransactionRepositoryImpl._toModel()`) |

---

## Project Constraints (from CLAUDE.md)

- **Amount style:** Always `AppTextStyles.amountSmall/Medium/Large` (tabular figures) — never generic `TextStyle` for monetary values
- **Widget parameter pattern:** Nullable param + provider fallback: `final effectiveBookId = bookId ?? ref.watch(currentBookIdProvider).value`
- **Riverpod 3 conventions:** `AsyncValue.value` is nullable (not throwing); `ref.listen` for side effects; `ProviderContainer.test()`; `waitForFirstValue<T>`; ONE `repository_providers.dart` per feature
- **i18n rules:** `S.of(context)` for all UI text; `DateFormatter`; `NumberFormatter`; `currentLocaleProvider`; Phase 30 for ARB three-locale finalization
- **Common Pitfalls #2:** Domain must not import Data layer
- **Common Pitfalls #8:** `flutter analyze` must be 0 issues before commit
- **Common Pitfalls #10:** No duplicate repository provider definitions — provider_graph_hygiene_test will fail
- **Common Pitfalls #13:** Run `build_runner build` after modifying `@riverpod`, `@freezed` annotated classes
- **Crypto rules:** All delete operations MUST use `DeleteTransactionUseCase` — never direct DAO delete

---

## Sources

### Primary (HIGH confidence)

- `lib/features/list/domain/models/list_filter_state.dart` — live Freezed VO: `categoryId: String?` confirmed at line 29; exact field to change per D-01
- `lib/features/list/presentation/providers/state_list_filter.dart` — live Notifier `ListFilter`; `setCategoryFilter(String? id)` at line 49
- `lib/features/list/presentation/providers/state_list_transactions.dart` — live provider; text search pipeline steps 6a/6b verified
- `lib/features/list/presentation/screens/list_screen.dart` — Phase 27 deliverable; `CalendarHeaderWidget + Expanded(spinner)` confirmed
- `lib/features/list/domain/models/tagged_transaction.dart` — `TaggedTransaction` + `MemberTag` Freezed VO verified
- `lib/features/home/presentation/widgets/home_transaction_tile.dart` — tile template constructor + layout verified
- `lib/core/theme/app_colors.dart` — `AppColors.survival/soul` exact hex values verified
- `lib/core/theme/app_text_styles.dart` — `amountSmall` with `FontFeature.tabularFigures()` at line 162
- `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` — `pop(true)` at line 64 verified
- `lib/features/accounting/presentation/providers/repository_providers.dart` — `deleteTransactionUseCaseProvider` at line 160
- `lib/features/home/presentation/screens/main_shell_screen.dart` — `ref.invalidate(listTransactionsProvider)` wired at lines 93 and 172
- `lib/features/accounting/presentation/screens/category_selection_screen.dart` — L1/L2 load pattern verified; template for filter sheet
- `lib/application/accounting/delete_transaction_use_case.dart` — `softDelete` path verified; no hash re-linking
- `lib/infrastructure/crypto/services/hash_chain_service.dart` — `verifyChain(List<Map<String,dynamic>>)` signature at line 45
- `lib/infrastructure/i18n/formatters/number_formatter.dart` — `formatCurrency` API verified
- `lib/infrastructure/i18n/formatters/date_formatter.dart` — `formatDate/formatDateTime` API verified
- `test/helpers/test_provider_scope.dart` — `waitForFirstValue<T>` helper at line 34
- `lib/shared/constants/sort_config.dart` — `SortField`/`SortDirection` enums verified
- `.planning/phases/28-transaction-tile-sort-filter-bar/28-CONTEXT.md` — locked decisions D-01..D-10
- `.planning/research/PITFALLS.md` — swipe-delete / hash chain / Dismissible pitfalls; ProviderException wrapping
- `CLAUDE.md` — Riverpod 3 conventions, amount display, widget parameter pattern, common pitfalls

### Secondary (MEDIUM confidence)

- `.planning/research/ARCHITECTURE.md` — provider dependency graph; tap-to-edit and swipe-to-delete flow patterns
- `.planning/research/FEATURES.md` — Dismissible + confirmDismiss spec; sort/filter bar feature descriptions
- `.planning/phases/26-providers-shell-wiring/26-CONTEXT.md` — provider naming (ListFilter vs ListFilterState); D-04 category name search; D-07 TaggedTransaction/MemberTag

### Tertiary (LOW confidence — flagged above as ASSUMED)

- Flutter SDK Dismissible `confirmDismiss` safe pattern (A1) — Flutter cookbook documented but assertion behavior with context access is version-dependent
- AnimatedContainer expand pattern for search field (A2) — standard Flutter pattern, verified conceptually
- Dart-side category `Set` filtering as migration path for D-01 (A3) — design decision, not a factual claim

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages are existing project dependencies, no new installs
- Architecture: HIGH — all integration points verified against live code files
- Pitfalls: HIGH — derived from live code (Dismissible pattern, hash chain, Riverpod 3 conventions all codebase-verified)
- D-01 change: HIGH — live file confirmed `categoryId: String?` at line 29; change scope bounded

**Research date:** 2026-05-30
**Valid until:** 2026-06-30 (stable Flutter + Riverpod 3 APIs)
