---
phase: quick-260518-kyr
plan: "01"
subsystem: home/presentation
tags: [bug-fix, riverpod, provider-invalidation, soul-ledger]
dependency_graph:
  requires: []
  provides: [fix-soul-stats-refresh, fix-monthly-favorite-refresh, fix-sync-listener-parity]
  affects: [HomeScreen, MainShellScreen, happinessReportProvider, bestJoyMomentProvider]
tech_stack:
  added: []
  patterns: [riverpod-ref.invalidate, bookByIdProvider-currency-resolve]
key_files:
  created: []
  modified:
    - lib/features/home/presentation/screens/main_shell_screen.dart
decisions:
  - Use ref.read(bookByIdProvider).value?.currency ?? 'JPY' for currencyCode resolution to match home_screen.dart:95-96 pattern exactly, ensuring the invalidation targets the live cached family instance
  - Use ref.invalidate (not ref.refresh) — invalidate is lazy (clears cache for next reader), ref.refresh is eager (re-runs immediately even with no current listener)
metrics:
  duration: "~5 minutes"
  completed: "2026-05-18"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 1
---

# Quick Fix 260518-kyr: Soul Stats + Monthly Favorite Refresh Fix Summary

**One-liner:** Added `happinessReportProvider` and `bestJoyMomentProvider` invalidation to both the FAB `onFabTap` callback and the sync-completion listener in `MainShellScreen`, using `bookByIdProvider` currency resolution matching `home_screen.dart:95–96`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add missing provider invalidations to FAB callback and sync listener | 2cb534f | `lib/features/home/presentation/screens/main_shell_screen.dart` |
| 2 | Full-project analyze and verify | (no code change) | — |

## What Was Changed

**File:** `lib/features/home/presentation/screens/main_shell_screen.dart`

### Imports added (lines 6 and 9):
```dart
import '../../../accounting/presentation/providers/repository_providers.dart';
import '../../../analytics/presentation/providers/state_happiness.dart';
```

### Site 1 — FAB `onFabTap` callback (lines 124–136, after existing 2 invalidations):
```dart
final book = ref.read(bookByIdProvider(bookId: bookId)).value;
final currencyCode = book?.currency ?? 'JPY';
ref.invalidate(
  happinessReportProvider(
    bookId: bookId, year: now.year, month: now.month,
    currencyCode: currencyCode,
  ),
);
ref.invalidate(
  bestJoyMomentProvider(bookId: bookId, year: now.year, month: now.month),
);
```

### Site 2 — Sync listener `wasSyncing && nowDone` block (lines 60–72, after existing 4 invalidations):
Identical pattern as Site 1, using the `now` variable already declared at line 47.

## Root Cause

All three home-screen aggregate widgets (総支出 / 悦己统计 / 本月最爱) use one-shot `FutureProvider` patterns backed by Drift `customSelect` queries. They are **not** reactive Drift streams — they only re-execute when their cached result is explicitly cleared via `ref.invalidate()`.

Before this fix, the FAB `onFabTap` callback invalidated only 2 of the 4 home-screen providers:
- `monthlyReportProvider` — invalidated (drives 総支出)
- `todayTransactionsProvider` — invalidated
- `happinessReportProvider` — **NOT invalidated** (drives 悦己统计 ring)
- `bestJoyMomentProvider` — **NOT invalidated** (drives 本月最爱 strip)

The sync completion listener in `ref.listen(syncStatusStreamProvider, ...)` had the identical omission — it invalidated `todayTransactions`, `monthlyReport`, `shadowBooks`, and `shadowAggregate` but missed the two happiness providers.

`happinessReportProvider` is a 4-argument family keyed on `(bookId, year, month, currencyCode)`. The `currencyCode` must match the value used by `HomeScreen` when it originally built the provider family instance. `HomeScreen` resolves it as `ref.read(bookByIdProvider(bookId: bookId)).value?.currency ?? 'JPY'` (home_screen.dart:95–96). The fix uses that exact same read pattern inside `MainShellScreen` at invalidation time, ensuring the family key matches the live cached instance and invalidation is not a no-op.

## Verification Results

### flutter analyze (file-level)
```
Analyzing main_shell_screen.dart...
No issues found! (ran in 1.5s)
```

### flutter analyze (full project — CLAUDE.md hard rule)
```
Analyzing home-pocket-app...
No issues found! (ran in 2.1s)
```

### Grep verification
```
$ grep -n "happinessReport\|bestJoyMoment" lib/features/home/presentation/screens/main_shell_screen.dart
63:          happinessReportProvider(
71:          bestJoyMomentProvider(bookId: bookId, year: now.year, month: now.month),
127:                    happinessReportProvider(
135:                    bestJoyMomentProvider(bookId: bookId, year: now.year, month: now.month),
```
4 lines returned — 2 from sync block (lines 63, 71), 2 from FAB block (lines 127, 135). Requirement: ≥4.

```
$ grep -c "ref\.invalidate" main_shell_screen.dart
10
```
10 total `ref.invalidate` calls (was 6 before fix — 2 in FAB, 4 in sync). Now 4 in FAB, 6 in sync = 10. Requirement: ≥8. Pass.

## Deviations from Plan

None — plan executed exactly as written.

## Related Risk

Analytics screen (`analytics_screen.dart`) also watches `happinessReportProvider` and `bestJoyMomentProvider`. It has pull-to-refresh that manually invalidates them, but if a transaction is entered from the analytics tab FAB, those providers are NOT auto-invalidated on return. The user must swipe-to-refresh to see updated soul stats on the analytics screen. This is a latent UX inconsistency — out of scope for this fix per CONTEXT.md.

## Manual Test Steps

1. Launch app on simulator or device.
2. Navigate to home screen — note current 悦己统计 ring values and 本月最爱 merchant name.
3. Tap FAB → create a new soul-ledger (Soul / 灵魂账本) transaction with a category.
4. Confirm the transaction — app returns to home screen automatically.
5. WITHOUT pull-to-refresh: verify 悦己统计 ring percentages or amounts update.
6. WITHOUT pull-to-refresh: verify 本月最爱 merchant name or amount updates.
7. If no visible change: create a second soul transaction with a higher amount for a different merchant — best joy changes when a higher-ranked entry exists.

**Sync path (if family sync configured):**
1. On a second family device, create a soul-ledger transaction.
2. After sync status goes idle on the first device, confirm home 悦己统计 + 本月最爱 update without swipe-to-refresh.

## Self-Check: PASSED

- `lib/features/home/presentation/screens/main_shell_screen.dart` — modified and committed at `2cb534f`
- `flutter analyze` returned "No issues found!" project-wide
- Grep confirms 4 occurrences of happinessReport/bestJoyMoment in the file (2 per site)
- No build_runner run required (no @riverpod/@freezed annotations added)
