---
phase: 28-transaction-tile-sort-filter-bar
reviewed: 2026-05-30T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - lib/application/list/get_list_transactions_use_case.dart
  - lib/features/list/domain/models/list_filter_state.dart
  - lib/features/list/presentation/providers/state_list_filter.dart
  - lib/features/list/presentation/providers/state_list_transactions.dart
  - lib/features/list/presentation/screens/list_screen.dart
  - lib/features/list/presentation/widgets/list_category_filter_sheet.dart
  - lib/features/list/presentation/widgets/list_day_group_header.dart
  - lib/features/list/presentation/widgets/list_empty_state.dart
  - lib/features/list/presentation/widgets/list_sort_filter_bar.dart
  - lib/features/list/presentation/widgets/list_transaction_tile.dart
findings:
  critical: 1
  warning: 3
  info: 4
  total: 8
status: issues_found
---

# Phase 28: Code Review Report

**Reviewed:** 2026-05-30
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Phase 28 delivers the transaction tile, swipe-to-delete, tap-to-edit, sort/filter bar, and grouped-by-day list assembly. The architecture is sound: D-01 (`categoryIds: Set<String>`) is correctly implemented through all three files, Riverpod 3 conventions are followed, `AppTextStyles.amountSmall` is used for amounts, all user-facing strings go through `S.of(context)`, and `AppColors` constants are used for ledger tag colours with no hardcoded hex.

One correctness bug stands out: the swipe-to-delete path does not invalidate `calendarDailyTotalsProvider`, so the calendar header in `CalendarHeaderWidget` continues to show the deleted transaction's amount until the user navigates away or changes month. This is the only BLOCKER. The three warnings are a dead-code function that signals a design gap, an immutability violation on local widget state, and an async-body assigned to `VoidCallback` that silently discards exceptions. Four info items cover minor consistency and code quality issues.

---

## Critical Issues

### CR-01: swipe-delete does not invalidate `calendarDailyTotalsProvider` — stale calendar totals

**File:** `lib/features/list/presentation/widgets/list_transaction_tile.dart:106-118`

**Issue:** `onDismissed` invalidates `listTransactionsProvider` but omits `calendarDailyTotalsProvider`. After a swipe-delete the per-day totals in `CalendarHeaderWidget` retain the deleted amount until the user changes month or triggers an external rebuild. The tap-to-edit path in `list_screen.dart` (line 181-187) correctly invalidates both providers; the delete path does not.

`ListTransactionTile` currently has no access to `filter.selectedYear`/`selectedMonth` (no filter import, no calendar provider import), which is why it was not added. The fix requires either (a) watching `listFilterProvider` inside the tile to obtain the year/month, or (b) accepting an optional `onDeleted` callback from `ListScreen._buildTile` — the same pattern used for `onTap` — so the parent can perform both invalidations.

**Fix (option b — preferred, keeps tile thin):**

```dart
// list_transaction_tile.dart — add optional callback
class ListTransactionTile extends ConsumerWidget {
  const ListTransactionTile({
    ...
    this.onDeleted,   // add
  });

  final VoidCallback? onDeleted;   // add

  // in onDismissed:
  onDismissed: (_) {
    ScaffoldMessenger.of(context).showSnackBar(...);
    ref.read(deleteTransactionUseCaseProvider).execute(taggedTx.transaction.id);
    ref.invalidate(listTransactionsProvider(bookId: bookId));
    onDeleted?.call();   // parent supplies calendar invalidation
  },
}

// list_screen.dart — supply callback in _buildTile:
final tile = ListTransactionTile(
  ...
  onDeleted: () => ref.invalidate(
    calendarDailyTotalsProvider(
      bookId: bookId,
      year: filter.selectedYear,
      month: filter.selectedMonth,
    ),
  ),
);
```

---

## Warnings

### WR-01: `buildTileTapHandler` free function is dead code — and its tap behaviour differs from the live path

**File:** `lib/features/list/presentation/widgets/list_transaction_tile.dart:214-232`

**Issue:** `buildTileTapHandler` is documented as the "standard navigation callback" (`/// Usage in parent`) but `ListScreen._buildTile` never calls it — it defines its own local `Future<void> onTap()` closure instead. The exported function is therefore dead code. Worse, it is semantically incomplete: it only invalidates `listTransactionsProvider` on save (line 229) and does not invalidate `calendarDailyTotalsProvider` — so if it were ever used, it would introduce the same stale-calendar bug as CR-01.

**Fix:** Either delete `buildTileTapHandler` entirely and rely on the pattern demonstrated in `_buildTile`, or update it to match the full invalidation logic in `_buildTile` (including the calendar provider) and actually use it in `ListScreen._buildTile`. Either path eliminates the dead-export confusion.

---

### WR-02: `_localSelected` is directly mutated inside `setState` in `CategoryFilterSheet`

**File:** `lib/features/list/presentation/widgets/list_category_filter_sheet.dart:85-95, 99-105, 148`

**Issue:** `_toggleL1`, `_toggleL2`, and the "Clear" button all call `.add()`, `.remove()`, or `.clear()` on `_localSelected` directly. CLAUDE.md §"Immutability (CRITICAL)" requires new objects rather than in-place mutation. While the mutation is contained to local widget state and never escapes to Riverpod (the provider receives `Set<String>.unmodifiable(...)` only on Apply), this pattern (a) violates the project convention, and (b) makes accidental aliasing bugs possible if a future refactor passes `_localSelected` to a helper before calling `setState`.

**Fix:** Replace mutations with set copy-on-write:

```dart
void _toggleL1(String l1Id) {
  final children = _l2ByParent[l1Id] ?? [];
  final s = _l1State(l1Id);
  final next = Set<String>.from(_localSelected);
  if (s == _L1SelectState.all) {
    for (final c in children) next.remove(c.id);
  } else {
    for (final c in children) next.add(c.id);
  }
  setState(() => _localSelected = next);
}

void _toggleL2(String l2Id) {
  final next = Set<String>.from(_localSelected);
  if (next.contains(l2Id)) { next.remove(l2Id); } else { next.add(l2Id); }
  setState(() => _localSelected = next);
}

// Clear button:
TextButton(onPressed: () => setState(() => _localSelected = {}), ...)
```

---

### WR-03: `VoidCallback onTap` accepts an async body — exceptions from the navigation path are silently discarded

**File:** `lib/features/list/presentation/widgets/list_transaction_tile.dart:44`
**Also:** `lib/features/list/presentation/screens/list_screen.dart:172-189`

**Issue:** `ListTransactionTile.onTap` is typed `VoidCallback` (`void Function()`). `ListScreen._buildTile` assigns a local `Future<void> onTap() async { ... }` to this field. Dart allows this assignment because `Future<void>` is assignable to `void`, but the consequence is that any exception thrown inside the async body (e.g., from `Navigator.push` if navigation fails, or from `ref.invalidate` if the container is already disposed) becomes an unhandled `Future` error — no stack trace in the widget error handler, no way for the UI to show a recoverable error state.

**Fix:** Change the field type to `Future<void> Function()` and the GestureDetector callback accordingly:

```dart
// list_transaction_tile.dart
final Future<void> Function() onTap;  // was VoidCallback

// GestureDetector stays the same — Flutter accepts Future<void> Function() for onTap
GestureDetector(onTap: onTap, ...)
```

This makes the async contract explicit and allows the analyzer / linter to warn if a non-async function is incorrectly provided.

---

## Info

### IN-01: `currencyCode` constant at line 39 is not used for amount formatting at line 160

**File:** `lib/features/list/presentation/screens/list_screen.dart:39, 160`

**Issue:** Line 39 declares `const currencyCode = 'JPY'` with a Phase 29 TODO to derive it from `bookByIdProvider`. Line 160 calls `NumberFormatter.formatCurrency(transaction.amount, 'JPY', locale)` with a second independent hardcode. When Phase 29 changes `currencyCode`, the formatter call on line 160 will remain JPY — a silent inconsistency.

**Fix:** Use the constant: `NumberFormatter.formatCurrency(transaction.amount, currencyCode, locale)`.

---

### IN-02: `GetListTransactionsUseCase.watch()` method is never called

**File:** `lib/application/list/get_list_transactions_use_case.dart:70-88`

**Issue:** `state_list_transactions.dart` uses only `execute()` (FutureProvider pull model). The `watch()` method — which returns a reactive `Stream<List<Transaction>>` and throws `ArgumentError` on empty `bookIds` — is not referenced anywhere in the codebase. It is dead API surface that adds maintenance cost (e.g., any signature change to `_repo.watchByBookIds` must be kept in sync with this unused path).

**Fix:** Remove `watch()` unless a StreamProvider consumer is planned in a named upcoming phase. If deferred, add a `// TODO(Phase XX): used by reactive stream provider` comment to mark the intent.

---

### IN-03: Dart-side day filter in `state_list_transactions.dart` step 6a is redundant when `activeDayFilter` is set

**File:** `lib/features/list/presentation/providers/state_list_transactions.dart:62-72`

**Issue:** When `filter.activeDayFilter != null`, `GetListTransactionsUseCase.execute()` already passes a SQL `startDate`/`endDate` range spanning only that calendar day (via `DateBoundaries.dayRange`). The Dart-side step 6a then re-filters the already-constrained list by the same year/month/day predicate. The double-filter is correct (no false negatives, no false positives) but wastes an iteration over the result set on every day-filter change.

**Fix:** Either remove step 6a entirely (trusting the SQL boundary) or guard it to run only when the SQL layer does NOT already bound the result:

```dart
// Only needed if SQL layer did NOT apply day boundary (currently it always does)
// Safe to remove.
```

---

### IN-04: Category count chip border colour does not indicate active state (visual inconsistency vs ledger chips)

**File:** `lib/features/list/presentation/widgets/list_sort_filter_bar.dart:317-320`

**Issue:** The category chip `BorderSide` colour is `AppColors.borderDefault` for both `filter.categoryIds.isEmpty` and non-empty states — the two branches of the ternary resolve to the same value. The Survival and Soul ledger chips (lines 245-249, 278-282) correctly change their border colour to `AppColors.survival` / `AppColors.soul` when active, providing visual feedback. The category chip is visually indistinguishable in its active vs inactive state (differentiated only by `backgroundColor`, not border).

**Fix:** Apply a distinct border colour when the category filter is active, matching the design language of the ledger chips:

```dart
side: BorderSide(
  color: filter.categoryIds.isEmpty
      ? AppColors.borderDefault
      : AppColors.accentPrimary,   // active state
  width: 1,
),
```

---

_Reviewed: 2026-05-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
