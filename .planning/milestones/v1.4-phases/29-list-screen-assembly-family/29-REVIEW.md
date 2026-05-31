---
phase: 29-list-screen-assembly-family
reviewed: 2026-05-31T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - lib/features/list/presentation/providers/state_list_transactions.dart
  - lib/features/list/presentation/providers/state_calendar_totals.dart
  - lib/features/list/presentation/screens/list_screen.dart
  - lib/features/list/presentation/widgets/list_sort_filter_bar.dart
  - lib/features/list/presentation/widgets/list_transaction_tile.dart
  - test/unit/features/list/presentation/providers/list_transactions_provider_test.dart
  - test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart
  - test/widget/features/list/list_screen_refresh_test.dart
  - test/widget/features/list/list_sort_filter_bar_member_test.dart
  - test/widget/features/list/list_transaction_tile_test.dart
findings:
  critical: 2
  warning: 5
  info: 3
  total: 10
status: issues_found
---

# Phase 29: Code Review Report

**Reviewed:** 2026-05-31
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Phase 29 adds family-aware list/calendar providers, a member attribution chip, a
family filter segment, and pull-to-refresh. The happy-path logic is sound and well
covered by the provided tests (member fan-out, memberTag fill, calendar isolation
from filter state, `_dayKey` normalization). The adversarial concerns are
concentrated in (1) lifecycle handling of the persisted `memberBookId` filter when
mode changes, and (2) the swipe-delete path optimistically lying to the user while
discarding a `Result.error`. Both can leave the screen in an incorrect state with no
clear cause. Several i18n/quality violations against `CLAUDE.md` are also present.

There are no structural findings provided for this phase.

## Critical Issues

### CR-01: Stale `memberBookId` after leaving group mode yields a permanent error screen with own data hidden

**File:** `lib/features/list/presentation/providers/state_list_transactions.dart:58-72`

`ListFilter` is declared `@Riverpod(keepAlive: true)` (`state_list_filter.dart:16`),
so `memberBookId` survives tab switches AND survives a transition from group mode
back to solo mode. In solo mode `isGroupMode` is false, so:

```dart
final bookIds = [bookId];                       // own book only (no shadows)
final memberBookId = filter.memberBookId;        // stale shadow id, e.g. 'shadow-1'
final effectiveBookIds = memberBookId != null
    ? (bookIds.contains(memberBookId) ? [memberBookId] : const <String>[])
    : bookIds;                                   // → const <String>[]
```

`effectiveBookIds` collapses to `[]`. `GetListTransactionsUseCase.execute` returns
`Result.error('bookIds must not be empty')` (use case lines 44-46), which the
provider re-throws as an `Exception` (line 70-72). The screen then renders the error
state (`list_screen.dart:88`) instead of the user's own transactions — indefinitely,
because in solo mode the family segment (and thus the member chips that would let the
user deselect) is not rendered (`list_sort_filter_bar.dart:427`). The user sees a
generic error with no actionable cause. This is a correctness/data-availability
defect, not a cosmetic one.

The same trap exists if a member is removed from the group while their `memberBookId`
is the active filter: the id disappears from `bookIds` and the list silently breaks.

**Fix:** Treat a `memberBookId` that is not present in the current `bookIds` as "no
member filter" rather than collapsing to an empty book list:

```dart
final memberBookId = filter.memberBookId;
final effectiveBookIds = (memberBookId != null && bookIds.contains(memberBookId))
    ? [memberBookId]
    : bookIds; // stale/absent member id → fall back to full set, never empty
```

Optionally also reconcile the filter when leaving group mode (clear `memberBookId`
in `setMemberFilter`/group-exit) so the chip state and data stay consistent.

### CR-02: Swipe-delete shows a success snackbar and removes the row while discarding the delete `Result` (silent failure → UI/DB divergence)

**File:** `lib/features/list/presentation/widgets/list_transaction_tile.dart:112-125`

`onDismissed` unconditionally shows the "deleted" snackbar, then fires the delete use
case fire-and-forget and ignores its return value:

```dart
ref.read(deleteTransactionUseCaseProvider)
   .execute(taggedTx.transaction.id); // Future<Result<void>> discarded
onDeleted();
```

`DeleteTransactionUseCase.execute` can return `Result.error` (`transactionId` empty,
`'Transaction not found'`) and can *throw* if `findById`/`softDelete` hit a DB/crypto
error (delete use case lines 20-35). In every failure case the row is already
dismissed from the UI and a success snackbar has been shown, but the row still exists
in the database. After the next `invalidateAfterMutation()` / pull-to-refresh the row
reappears, contradicting the "deleted" message — and a thrown error becomes an
unhandled async exception (the global `CLAUDE.md` rule "never silently swallow
errors" is violated). This is data-integrity/UX-correctness sensitive because the app
is a financial ledger.

**Fix:** Capture the result and surface failures (re-add the row / show an error
snackbar). Because `onDismissed` cannot itself block, do the work and react:

```dart
onDismissed: (_) async {
  final messenger = ScaffoldMessenger.of(context);
  onDeleted(); // optimistic invalidate
  try {
    final result =
        await ref.read(deleteTransactionUseCaseProvider).execute(taggedTx.transaction.id);
    if (result.isError) {
      messenger.showSnackBar(SnackBar(content: Text(S.of(context).listDeleteFailed)));
      onDeleted(); // re-fetch restores the row
    } else {
      messenger.showSnackBar(SnackBar(content: Text(S.of(context).listDeletedSnackBar)));
    }
  } catch (e, st) {
    FlutterError.reportError(FlutterErrorDetails(exception: e, stack: st));
    messenger.showSnackBar(SnackBar(content: Text(S.of(context).listDeleteFailed)));
    onDeleted();
  }
},
```

(Capture `ScaffoldMessenger` before the await; the `Dismissible` is already detached
from the tree once dismissed.)

## Warnings

### WR-01: Hardcoded user-facing error string violates i18n contract

**File:** `lib/features/list/presentation/screens/list_screen.dart:101`

```dart
Text('[data load error]', ...)
```

`CLAUDE.md` (i18n Rules) mandates "All UI text via `S.of(context)` — never hardcode
strings." This placeholder-looking literal is shipped to all three locales and reads
as an unfinished string to users.

**Fix:** Add a localized key (e.g. `listLoadError`) to all three ARB files, run
`flutter gen-l10n`, and use `S.of(context).listLoadError`.

### WR-02: `currencyCode` hardcoded to `'JPY'` in two places — multi-currency books show wrong symbol

**File:** `lib/features/list/presentation/screens/list_screen.dart:39` and `:185-189`

```dart
const currencyCode = 'JPY';                       // line 39, comment admits TODO
...
NumberFormatter.formatCurrency(transaction.amount, 'JPY', locale); // line 187
```

The companion `CalendarHeaderWidget` already accepts a `currencyCode` parameter meant
to be "resolve[d] from bookByIdProvider" (per its doc), but the screen feeds it a
constant. A book whose `currency` is USD/CNY/EUR/GBP will render amounts with the yen
formatting/symbol — a correctness issue for the non-JPY books the data model
explicitly supports (`Book.currency`). The `'JPY'` literal at line 187 is also a magic
value duplicated from line 39.

**Fix:** Resolve the active book's currency once (e.g. via `bookByIdProvider`) and
thread it through both the header and `formatCurrency`. At minimum, replace the line
187 literal with the `currencyCode` variable so there is a single source.

### WR-03: `selectMonth` resets `activeDayFilter` but stale `memberBookId` is never reconciled when group membership changes

**File:** `lib/features/list/presentation/providers/state_list_filter.dart:72-74`

`setMemberFilter` stores whatever `bookId` it is given with no validation that the id
still belongs to the active group. Combined with `keepAlive: true`, this is the root
cause feeding CR-01. Even after CR-01's provider-side guard, the chip-selection UI can
show a member as "selected" whose book no longer exists, because the filter state is
never cleaned up.

**Fix:** Clear `memberBookId` on group exit (or when the selected book is no longer in
`shadowBooksProvider`), e.g. add a reconciliation step in the group-mode listener or
validate in `setMemberFilter`.

### WR-04: `RefreshIndicator.onRefresh` awaits the list future but not the calendar future — spinner can dismiss before calendar settles

**File:** `lib/features/list/presentation/screens/list_screen.dart:64-77`

`onRefresh` invalidates both `listTransactionsProvider` and
`calendarDailyTotalsProvider`, but only awaits the list provider's `.future`. The
spinner therefore reports "done" while the calendar totals may still be reloading. The
stated intent ("Await re-settlement so spinner dismisses honestly — Pitfall F") is only
half met.

**Fix:** Await both futures (e.g. `Future.wait([...])`), each with a `catchError`, so
the spinner reflects both reloads:

```dart
await Future.wait([
  ref.read(listTransactionsProvider(bookId: bookId).future)
     .catchError((_) => <TaggedTransaction>[]),
  ref.read(calendarDailyTotalsProvider(bookId: bookId,
      year: filter.selectedYear, month: filter.selectedMonth).future)
     .catchError((_) => <DateTime, int>{}),
]);
```

### WR-05: Search `TextEditingController` can desync from filter state (no listener), leaving stale text in the field

**File:** `lib/features/list/presentation/widgets/list_sort_filter_bar.dart:35,345-352`

The search field is driven by a local `_searchController` whose text is only
reconciled with `listFilterProvider` inside this widget's own handlers (Clear chip,
suffix clear). `searchQuery` lives in a `keepAlive` provider, so on returning to the
List tab (the widget rebuilds with `_searchExpanded = false` reset but state preserved)
or on any external mutation of `searchQuery`, the controller and the provider can hold
different values. There is no `ref.listen(listFilterProvider, ...)` syncing the
controller. Result: the field may show empty while the filter is active, or vice
versa.

**Fix:** Seed/sync the controller from state — e.g. initialize
`_searchController.text` from `listFilterProvider`'s `searchQuery` and `ref.listen`
for external changes, or derive `_searchExpanded` from `searchQuery.isNotEmpty`.

## Info

### IN-01: `bookId` field on `ListSortFilterBar` is documented as "for future invalidation" but is used for the Mine-only filter

**File:** `lib/features/list/presentation/widgets/list_sort_filter_bar.dart:26-27`

The doc comment ("passed for future invalidation on local chip actions") is now stale —
`widget.bookId` is actively used as the Mine-only `memberBookId` (lines 434, 449, 451).
Update the comment to reflect current usage to avoid misleading future maintainers.

### IN-02: Member/Mine-only chips lack `Semantics(selected:)` unlike the ledger chips

**File:** `lib/features/list/presentation/widgets/list_sort_filter_bar.dart:430-490`

The ledger chips set `selected:` in their `Semantics` wrappers (lines 211, 239, 272),
but the Mine-only and per-member chips are bare `ActionChip`s with no `Semantics`
selection state. Accessibility tooling cannot announce which member filter is active.
Add `Semantics(selected: filter.memberBookId == <id>, ...)` for consistency.

### IN-03: Duplicate `anyFilterActive` predicate maintained in two files (drift risk)

**File:** `lib/features/list/presentation/screens/list_screen.dart:111-115` and
`lib/features/list/presentation/widgets/list_sort_filter_bar.dart:134-138`

The exact 5-term `anyFilterActive` expression (including the FAM-03 `memberBookId`
term) is duplicated. Both copies happen to agree now, but a future change to one (e.g.
adding a new filter field) will silently desync the empty-state hint from the Clear
chip visibility. Extract a single derived getter on `ListFilterState`
(e.g. `bool get hasActiveFilters`) and use it in both places.

---

_Reviewed: 2026-05-31_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
