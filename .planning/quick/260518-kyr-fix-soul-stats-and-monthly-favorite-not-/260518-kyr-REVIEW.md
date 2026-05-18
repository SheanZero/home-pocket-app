---
phase: quick-260518-kyr
reviewed: 2026-05-18T00:00:00Z
depth: quick
files_reviewed: 1
files_reviewed_list:
  - lib/features/home/presentation/screens/main_shell_screen.dart
findings:
  critical: 0
  warning: 1
  info: 1
  total: 2
status: issues_found
---

# Quick Task 260518-kyr: Code Review Report

**Reviewed:** 2026-05-18
**Depth:** quick
**Files Reviewed:** 1
**Status:** issues_found

## Summary

The fix correctly adds `happinessReportProvider` and `bestJoyMomentProvider` invalidations to both the sync listener (lines 62–72) and the FAB callback (lines 124–136). The core logic is sound. One WARNING-level correctness risk and one INFO item found.

## Warnings

### WR-01: `ref.read(bookByIdProvider)` during sync completion may be in loading state — invalidation silently targets wrong family key

**File:** `lib/features/home/presentation/screens/main_shell_screen.dart:60-61` and `:124-125`

**Issue:** `bookByIdProvider` is a `FutureProvider` (`Future<Book?>`). At both call sites the code does:

```dart
final book = ref.read(bookByIdProvider(bookId: bookId)).value;
final currencyCode = book?.currency ?? 'JPY';
```

`AsyncValue.value` is `null` when the provider is still loading **or** when it has errored — not just when the `Book` record is absent. If `bookByIdProvider` hasn't settled yet (cold start, app resumed from background just before sync completes, or the provider was itself invalidated by a prior sync), `book` is `null`, `currencyCode` falls back to `'JPY'`, and the invalidation call targets a different family key than the one `HomeScreen` is actually watching (e.g., `currencyCode: 'CNY'`). The cache entry for the real key is never invalidated — the bug this fix is trying to cure silently reappears for non-JPY books.

`HomeScreen` uses `ref.watch(bookByIdProvider(...))` (reactive), so by the time the widgets render `currencyCode` has resolved. `MainShellScreen` uses `ref.read` (one-shot) at event time, which is a materially different timing guarantee.

**Fix:** Check `AsyncValue.isLoading` before consuming; fall back only when the book is confirmed absent (not loading):

```dart
final bookAsync = ref.read(bookByIdProvider(bookId: bookId));
// Only fall back to 'JPY' if book is confirmed missing, not if still loading.
// If still loading, skip soul-stats invalidation — they'll refresh on next
// interaction once the book resolves.
if (!bookAsync.isLoading) {
  final currencyCode = bookAsync.value?.currency ?? 'JPY';
  ref.invalidate(
    happinessReportProvider(
      bookId: bookId,
      year: now.year,
      month: now.month,
      currencyCode: currencyCode,
    ),
  );
  ref.invalidate(
    bestJoyMomentProvider(bookId: bookId, year: now.year, month: now.month),
  );
}
```

Apply identically at both sites (line 60 in the sync listener and line 124 in the FAB callback).

## Info

### IN-01: `DateTime.now()` captured at different times in sync listener vs. provider creation — potential cross-midnight edge case

**File:** `lib/features/home/presentation/screens/main_shell_screen.dart:47` and `:115`

**Issue:** Both sites call `DateTime.now()` fresh at invalidation time. `HomeScreen` also calls `DateTime.now()` at widget build time (home_screen.dart:44). If the user leaves the app open across midnight (e.g., sync completes at 00:00:01 January 1), `MainShellScreen` invalidates the January provider while `HomeScreen`'s cached `year`/`month` variables still hold December values. The invalidated key misses.

This is a pre-existing edge case not introduced by this fix, affects `monthlyReportProvider` equally, and is low-probability. No immediate action required, but worth tracking.

**Fix (optional):** Expose `year`/`month` from `HomeScreen` via a provider so all invalidation sites share one source of truth for the display month.

---

_Reviewed: 2026-05-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: quick_
