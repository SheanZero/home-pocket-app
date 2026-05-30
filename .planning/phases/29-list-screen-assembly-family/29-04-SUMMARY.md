---
phase: 29-list-screen-assembly-family
plan: 04
subsystem: ui
tags: [flutter, riverpod, refresh-indicator, pull-to-refresh, family-filter, list-screen]

# Dependency graph
requires:
  - phase: 29-03
    provides: member attribution chip on tiles + family filter segment in bar + anyFilterActive bar fix
  - phase: 29-02
    provides: family-aware listTransactionsProvider + multi-book calendarDailyTotalsProvider + listMineOnly ARB key
provides:
  - RefreshIndicator pull-to-refresh on list screen (LIST-04)
  - onRefresh invalidates both list + calendar providers; honest spinner completion (D-05)
  - anyFilterActive 5-condition form in list_screen.dart mirroring the bar (Pitfall B consistency)
  - Phase 29 full-suite green gate (list feature 96/96 tests)
affects: [30-i18n-empty-states-golden-polish]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "RefreshIndicator wraps txsAsync.when(...); loading/error/empty branches all use SingleChildScrollView(AlwaysScrollableScrollPhysics) so pull gesture fires when content is short (Pitfall E)"
    - "onRefresh awaits provider.future.catchError to dismiss spinner honestly (Pitfall F)"

key-files:
  created: []
  modified:
    - lib/features/list/presentation/screens/list_screen.dart
    - lib/features/list/presentation/widgets/list_sort_filter_bar.dart
    - test/widget/features/list/list_screen_refresh_test.dart

key-decisions:
  - "Wrap empty-data ListEmptyState in SingleChildScrollView(AlwaysScrollableScrollPhysics) so pull-to-refresh works on empty months (full Pitfall E coverage, not just loading/error)"
  - "Refresh test drags on RefreshIndicator directly instead of fling on ListView — ListView is absent when list empty, and SingleChildScrollView.first matches the bar's horizontal chip scroller"

patterns-established:
  - "Pull-to-refresh: RefreshIndicator(color: AppColors.accentPrimary) + onRefresh invalidates list + calendar providers + awaits .future.catchError"
  - "anyFilterActive 5-condition form (activeDayFilter, ledgerType, categoryIds, searchQuery, memberBookId) identical in list_screen.dart + list_sort_filter_bar.dart"

requirements-completed: [LIST-04, FAM-01, FAM-02, FAM-03, FAM-04]

# Metrics
duration: ~35min
completed: 2026-05-31
---

# Phase 29 Plan 04: List Screen Assembly + Family — Final Integration Summary

**RefreshIndicator pull-to-refresh on the list screen with honest spinner completion, plus the 5th `anyFilterActive` condition (`memberBookId`) mirroring the Plan 03 bar fix — closing LIST-04 and the full-phase test gate.**

## Performance

- **Duration:** ~35 min (incl. checkpoint approval wait)
- **Started:** 2026-05-30T23:45:00Z (approx)
- **Completed:** 2026-05-31T00:30:00Z (approx)
- **Tasks:** 2 (Task 1 auto + Task 2 human-verify checkpoint — APPROVED)
- **Files modified:** 3

## Accomplishments

- `RefreshIndicator` wraps `_buildList`'s entire `txsAsync.when(...)` (color `AppColors.accentPrimary`, matching the loading indicator)
- `onRefresh` invalidates both `listTransactionsProvider(bookId)` and `calendarDailyTotalsProvider(bookId, year, month)` — mirroring the existing `invalidateAfterMutation()` pair — then awaits `.future.catchError((_) => <TaggedTransaction>[])` so the spinner dismisses honestly even on provider error (Pitfall F, T-29-04-01 DoS mitigation)
- All three non-data branches (loading, error, empty-data) wrapped in `SingleChildScrollView(physics: AlwaysScrollableScrollPhysics())` so pull gesture fires on short/empty content (Pitfall E)
- `ListView.builder` gets `physics: const AlwaysScrollableScrollPhysics()`
- `anyFilterActive` in `list_screen.dart` now has 5 conditions including `filter.memberBookId != null` (Pitfall B fix — identical to the Plan 03 bar form; ensures Clear chip + filtered-empty state behave correctly under member filter)
- Human checkpoint APPROVED: solo + family mode, pull-to-refresh spinner, member attribution chips, Mine-only chip, AND-composition (ledger + member), filtered-empty state all verified visually

## Task Commits

1. **Task 1: RefreshIndicator + anyFilterActive fix** - `63c745e0` (feat)
2. **Task 2: human-verify checkpoint** - APPROVED (no code commit; visual verification only)

**Plan metadata:** (this SUMMARY commit)

## Files Created/Modified

- `lib/features/list/presentation/screens/list_screen.dart` - RefreshIndicator wrapping; onRefresh dual-invalidate + honest await; loading/error/empty branches scrollable; ListView AlwaysScrollableScrollPhysics; anyFilterActive 5th condition
- `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` - removed pre-existing `// ignore: avoid_types_on_closure_parameters` (Plan 03 leftover); `error: (Object e, StackTrace s)` → `error: (e, s)`
- `test/widget/features/list/list_screen_refresh_test.dart` - fling on `ListView` → drag on `RefreshIndicator` (ListView absent when empty; `SingleChildScrollView.first` matches the bar's horizontal chip scroller, not the list area)

## Decisions Made

- **Full Pitfall E coverage:** The plan called for wrapping loading/error branches. I extended this to the empty-data branch (`ListEmptyState`) too, since pull-to-refresh on an empty month is an explicit checkpoint verification step (#3). Without it, the gesture would not fire when the list is empty.
- **Refresh test gesture target:** The Wave 0 test used `tester.fling(find.byType(ListView), ...)`, which fails because (a) `ListView` does not exist when the mock returns an empty list and (b) `find.byType(SingleChildScrollView).first` resolves to the `ListSortFilterBar`'s horizontal chip scroller, not the list body. Switched to `tester.drag(find.byType(RefreshIndicator), ...)` for a deterministic, state-independent gesture target.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Refresh test gesture targeted a non-existent / wrong widget**
- **Found during:** Task 1 (running `list_screen_refresh_test.dart`)
- **Issue:** Wave 0 test flung `find.byType(ListView)`; `ListView` is absent when the list is empty (data branch shows `ListEmptyState`), and `find.byType(SingleChildScrollView).first` resolves to the filter bar's horizontal scroller — so the refresh gesture either threw "no widget found" or fired on the wrong scrollable, leaving `getDailyTotals` called only once.
- **Fix:** Changed the two fling-based tests to `tester.drag(find.byType(RefreshIndicator), const Offset(0, 300))`, a deterministic target that routes the drag to `onRefresh` regardless of empty/non-empty state.
- **Files modified:** test/widget/features/list/list_screen_refresh_test.dart
- **Verification:** 3/3 refresh tests GREEN; full list suite 96/96 GREEN
- **Committed in:** `63c745e0`

**2. [Rule 2 - Missing Critical] Empty-data branch was not scrollable**
- **Found during:** Task 1 (Pitfall E implementation)
- **Issue:** The plan specified wrapping loading/error branches; the empty-data `ListEmptyState` return was left bare. Checkpoint step #3 requires pull-to-refresh to fire on an empty month — impossible without a scrollable child.
- **Fix:** Wrapped `ListEmptyState` in `SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics())` in the empty-data branch.
- **Files modified:** lib/features/list/presentation/screens/list_screen.dart
- **Verification:** Checkpoint step #3 confirmed visually (approved); `flutter analyze` 0 issues
- **Committed in:** `63c745e0`

**3. [Rule 3 - Blocking] Pre-existing stale-suppression test failure in list feature**
- **Found during:** Task 1 (full-suite gate)
- **Issue:** `test/architecture/stale_suppressions_scan_test.dart` failed on `list_sort_filter_bar.dart:489` — a Plan 03 leftover `// ignore: avoid_types_on_closure_parameters`. This blocked the Phase 29 full-suite green gate.
- **Fix:** Removed the typed closure params (`(Object e, StackTrace s)` → `(e, s)`) so Dart inference handles it and the ignore comment is no longer needed.
- **Files modified:** lib/features/list/presentation/widgets/list_sort_filter_bar.dart
- **Verification:** `stale_suppressions_scan_test.dart` now PASSES; `flutter analyze` 0 issues on the file
- **Committed in:** `63c745e0`

---

**Total deviations:** 3 auto-fixed (1 bug, 1 missing critical, 1 blocking)
**Impact on plan:** All three were necessary to reach the Phase 29 full-suite green gate and satisfy the checkpoint verification steps. No scope creep — all changes confined to the list feature.

## Issues Encountered

- **`getDailyTotals` called once instead of twice after refresh:** Initial fling-based test fired on the wrong scrollable so `onRefresh` was not invoked. Resolved by dragging directly on the `RefreshIndicator` (see Deviation #1).

## Pre-existing Failures (Out of Scope)

11 golden pixel-diff failures in `test/golden/home_hero_card_golden_test.dart` are **pre-existing and out of scope** for Phase 29:

- **Source:** quick task `260522-fj5` (悦己充盈卡片 UI 修复 — "28 golden diffs pending human re-baseline", per STATE.md)
- **Feature:** home (`HomeHeroCard`), not the list feature
- **Verification:** Confirmed pre-existing by stashing this plan's changes and re-running the golden + stale-suppression tests — the home_hero_card golden diffs were already failing with no Phase 29 changes present
- **Not a Phase 29 regression.** These require a human golden re-baseline of the home feature, tracked separately.

The `const currencyCode = 'JPY'` seam in `list_screen.dart:38–39` was left unchanged per RESEARCH.md §"currencyCode Seam" (explicitly out of Phase 29 scope).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- LIST-04, FAM-01–04 all delivered and visually verified. Phase 29 list-screen-assembly-family is functionally complete.
- Ready for Phase 30 (i18n + Empty States + Golden Polish, LIST-03): final three-language copy for `listMineOnly` + member chip / empty-state wording, and golden baselines for the list feature.
- Carry-forward: home_hero_card golden re-baseline (pre-existing, home feature) remains open.

## Self-Check: PASSED

- FOUND: `.planning/phases/29-list-screen-assembly-family/29-04-SUMMARY.md`
- FOUND: commit `63c745e0`
- FOUND: `lib/features/list/presentation/screens/list_screen.dart`

---
*Phase: 29-list-screen-assembly-family*
*Completed: 2026-05-31*
