---
phase: 27-calendar-header-month-summary
reviewed: 2026-05-30T06:47:54Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - lib/core/initialization/app_initializer.dart
  - lib/features/list/presentation/providers/state_calendar_totals.dart
  - lib/features/list/presentation/widgets/list_calendar_header.dart
  - lib/features/list/presentation/screens/list_screen.dart
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
status: issues_found
---

# Phase 27: Code Review Report

**Reviewed:** 2026-05-30T06:47:54Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Reviewed the four production source files for the Calendar Header + Month Summary
feature: the `initializeDateFormatting()` bootstrap addition, the
`calendarDailyTotalsProvider` async family provider, the ~371-line
`CalendarHeaderWidget`, and its mounting in `ListScreen`.

The core data path is sound. The `_dayKey` normalization contract (the spec's
"highest-risk failure mode") is correctly honored on both sides: the DAO emits
`DateTime.parse('YYYY-MM-DD')` (local-time midnight), the provider folds via
`_dayKey`, and the cell/subline both look up via the identical `_dayKey` — they
agree, so cells will not silently render blank. i18n routing (`S.of`,
`DateFormatter`, `NumberFormatter`), `AppTextStyles.amountSmall` for the month
total, `isSameDay` for day comparison, and the `selectMonth` year-boundary
rollover via `DateTime` are all implemented per contract.

No Critical defects. The notable issues are: an unbounded month-navigation path
that can drive `focusedDay` past `table_calendar`'s `firstDay`/`lastDay` bounds
(navigation breakage), a `dynamic`-typed widget field that discards type safety,
a per-build `DateTime.now()` "today" computation that won't refresh across
midnight, and an unimplemented future-month guard the spec called for as a seam.

## Warnings

### WR-01: Month navigation is unbounded — `focusedDay` can exceed TableCalendar's firstDay/lastDay, breaking the page controller

**File:** `lib/features/list/presentation/widgets/list_calendar_header.dart:60-72, 80-98`
**Issue:** Chevron handlers call `selectMonth(year, month ± 1)` with no clamp.
`TableCalendar` is configured `firstDay: DateTime(2020,1,1)`,
`lastDay: DateTime(2030,12,31)`, and `focusedDay` is driven from the filter
(`DateTime(filter.selectedYear, filter.selectedMonth)`). In `table_calendar` 3.2.0,
`calendar_core._getPageCount` clamps the **itemCount** to `[firstDay, lastDay]`,
but `table_calendar_base._calculateFocusedPage` → `_getMonthCount(first, last)`
does **not** clamp `focusedDay`:
```dart
int _getMonthCount(DateTime first, DateTime last) {
  final yearDif = last.year - first.year;
  final monthDif = last.month - first.month;
  return yearDif * 12 + monthDif;   // no clamp to itemCount
}
```
Repeatedly tapping the next chevron past Dec 2030 (or prev past Jan 2020) produces
a `focusedDay` whose computed page index is ≥ `itemCount`. `didUpdateWidget` then
calls `_pageController.jumpToPage`/`animateToPage` to a non-existent page, the
grid desyncs from the label, and the page-change callback can fight the driven
`focusedDay`. The user also has no feedback that navigation is bounded.
**Fix:** Clamp before mutating, or guard the chevrons. Example clamp:
```dart
onNextMonth: () {
  final next = DateTime(filter.selectedYear, filter.selectedMonth + 1);
  if (next.isAfter(DateTime(2030, 12))) return; // or disable button
  ref.read(listFilterProvider.notifier).selectMonth(next.year, next.month);
},
```
Define the 2020/2030 bounds as shared constants used by both the chevron guard
and the `TableCalendar(firstDay/lastDay)` config so they cannot drift.

### WR-02: `_MonthNavBar.filter` typed as `dynamic` discards all type safety

**File:** `lib/features/list/presentation/widgets/list_calendar_header.dart:210`
**Issue:** `final dynamic filter;` defeats static analysis on every access
(`filter.selectedYear`, `filter.selectedMonth`). A typo or a future rename of a
`ListFilterState` field becomes a runtime `NoSuchMethodError` instead of a compile
error, and the analyzer cannot help. The concrete type (`ListFilterState`) is
already imported transitively via `state_list_filter.dart` and is known at the
call site in `build()`.
**Fix:** Type the field explicitly:
```dart
import '../../domain/models/list_filter_state.dart';
// ...
final ListFilterState filter;
```

### WR-03: "Today" highlight is computed once per build from `DateTime.now()` and will not refresh across midnight

**File:** `lib/features/list/presentation/widgets/list_calendar_header.dart:142`
**Issue:** `final isToday = isSameDay(day, DateTime.now());` is evaluated inside
the cell builder during `build()`. If the calendar is left mounted across a
midnight boundary (the app is foregrounded overnight on the List tab), the
"today" cell decoration stays on yesterday until some unrelated state change
triggers a rebuild. There is no timer/date-change listener. This is a
correctness/freshness defect for a calendar surface, though low-frequency.
**Fix:** At minimum hoist `today` to a single value computed once at the top of
`build()` (avoids 35+ `DateTime.now()` calls per frame). For correctness across
midnight, drive "today" from a date-aware source (e.g. a provider that exposes
the current date and invalidates on a midnight `Timer`/lifecycle resume) so the
calendar rebuilds when the day rolls over.

### WR-04: Spec's future-month disabled-chevron guard ("seam should exist") is not implemented

**File:** `lib/features/list/presentation/widgets/list_calendar_header.dart:201-269`
**Issue:** UI-SPEC Color table specifies a "Disabled chevron" state
(`AppColors.textTertiary` at 0.38 opacity) as a "Future-month guard hook (do not
navigate past current month + 1) … not required in v1.4 but seam should exist."
Both chevrons are always enabled at full `textTertiary`; there is no disabled
state, no opacity variant, and no guard. Combined with WR-01, the nav bar has no
boundary affordance at all. This is a deviation from the approved design contract.
**Fix:** Add the disabled visual + guard seam, e.g. compute
`canGoNext = !nextMonth.isAfter(maxMonth)` and pass a nullable `onNextMonth`
(null `onPressed` renders IconButton disabled) plus the 0.38-opacity color when
disabled. Even a no-op seam matching the spec is preferable to silent unbounded nav.

## Info

### IN-01: `_dayKey` is duplicated verbatim in two files

**File:** `lib/features/list/presentation/widgets/list_calendar_header.dart:17` and
`lib/features/list/presentation/providers/state_calendar_totals.dart:14`
**Issue:** The normalization helper `DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);`
is defined independently in both files. The spec explicitly warns that if the two
sides diverge, "all cells silently render blank." Duplication is the exact
mechanism by which that divergence happens — a future edit to one copy (e.g.
switching to `DateTime.utc`) would not be caught by the compiler.
**Fix:** Extract a single shared helper (e.g. in `shared/utils/date_boundaries.dart`
or a small `date_key.dart`) and import it in both files so there is one source of
truth.

### IN-02: Error state and empty-month state are visually indistinguishable in day cells

**File:** `lib/features/list/presentation/widgets/list_calendar_header.dart:52-53`
**Issue:** `final dailyMap = calendarAsync.value ?? {}` means on `AsyncError` the
cells render exactly like a zero-spend month (no amounts). The summary row does
surface `calLoadError`, so this is acceptable per the spec's "silent degradation"
choice — noting it so the behavior is a recorded decision rather than an oversight.
**Fix:** None required by spec. Optionally, when polish allows, distinguish a true
error from an empty month (e.g. a subtle indicator) so users do not read stale-empty
as accurate.

### IN-03: Builder passes `false` for the today/selected flags, relying on internal recomputation

**File:** `lib/features/list/presentation/widgets/list_calendar_header.dart:99-108`
**Issue:** `todayBuilder`, `selectedBuilder`, and `defaultBuilder` all call
`_buildDayCell(day, dailyMap, filter.activeDayFilter, false)` with the same args;
`_buildDayCell` re-derives `isSelected`/`isToday` itself via `isSameDay`. This is
functionally correct (and the selection-wins ordering matches the spec table), but
the four near-identical builder closures plus internal re-derivation is mildly
redundant. Not a bug.
**Fix:** Optional — a single shared builder reference would reduce duplication.

### IN-04: `app_initializer` adds `initializeDateFormatting()` outside the error-handling structure

**File:** `lib/core/initialization/app_initializer.dart:36`
**Issue:** `await initializeDateFormatting();` runs before the `try` block. If it
throws (asset/data load failure), it escapes `AppInitializer.initialize()` as an
unstructured exception rather than returning a typed `InitResult.failure(...)` like
every other stage. In practice `initializeDateFormatting()` loads bundled symbol
data and rarely throws, so severity is low — but it is the one initialization step
not wrapped in the established failure-classification pattern.
**Fix:** Move it inside the outer `try` (its `catch (e, st)` already maps to
`InitFailureType.unknown`), or give it a dedicated `InitFailureType` so a date-data
failure surfaces the standard error fallback screen instead of an uncaught throw.

---

_Reviewed: 2026-05-30T06:47:54Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
