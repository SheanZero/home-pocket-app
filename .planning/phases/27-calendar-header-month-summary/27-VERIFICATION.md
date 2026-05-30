---
phase: 27-calendar-header-month-summary
verified: 2026-05-30T08:00:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
re_verification: false
---

# Phase 27: Calendar Header + Month Summary — Verification Report

**Phase Goal:** The calendar header is a complete, independently testable widget — month navigation, per-day expense totals, day-tap filter, and the month expense summary are all observable in isolation.
**Verified:** 2026-05-30T08:00:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can tap prev/next arrows to switch months; grid re-renders with correct label (e.g. "2026年5月" in ja) | VERIFIED | `_MonthNavBar` in `list_calendar_header.dart` wires `onPrevMonth`/`onNextMonth` callbacks to `listFilterProvider.notifier.selectMonth()`; `DateFormatter.formatMonthYear()` drives the label; SC#1 widget test passes (right-chevron advances `selectedMonth` by 1) |
| 2 | Each day cell shows total expense for that day (expense-only, own-book only); zero-expense days show no amount | VERIFIED | `_buildDayCell` in `list_calendar_header.dart:143,177-181` looks up `dailyMap[_dayKey(day)]` from `calendarDailyTotalsProvider`; renders `NumberFormatter.formatCompact` only when `dayTotal > 0 && !isOutside`; provider uses default expense type (D-09) — no income; 5 unit tests including expense-only and empty-month cases pass |
| 3 | User can tap a day cell to filter; tapped day is visually highlighted; tap same day again clears filter | VERIFIED | `_onDayTapped` in `list_calendar_header.dart:189-197` implements toggle: `isSameDay(current, selectedDay)` → `selectDay(null)`, else `selectDay(selectedDay)`; `selectedBuilder` drives `AppColors.accentPrimary` decoration for selected state; SC#3 widget test passes (tap day 5 sets filter, tap again clears it) |
| 4 | Month expense summary shows current-month total via `NumberFormatter` + `AppTextStyles.amountSmall`; excludes income | VERIFIED | `_SummaryRow` in `list_calendar_header.dart:271-370` folds `dailyMap.values` to get total; renders with `AppTextStyles.amountSmall` (line 331); `AnimatedSize` day subline appears/disappears on `activeDayFilter` toggle; SC#4 widget test passes (`¥12,345` found in widget tree for 12345 totalAmount) |
| 5 | `table_calendar: ^3.2.0` in pubspec; `flutter build ios --debug --no-codesign` passes; `intl: 0.20.2` pin intact | VERIFIED | `grep "table_calendar" pubspec.yaml` → line 38: `table_calendar: ^3.2.0`; `grep "intl:" pubspec.yaml` → line 17: `intl: 0.20.2`; 27-04-SUMMARY confirms iOS build exits 0 and was human-gated (approved) |

**Score: 5/5 truths verified**

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `pubspec.yaml` | `table_calendar: ^3.2.0`; `intl: 0.20.2` unchanged | VERIFIED | Both pins confirmed via grep |
| `lib/l10n/app_ja.arb` | Contains `calMonthTotal`, `calDayTotal`, `calLoadError` | VERIFIED | All three keys present (lines 2090-2104) |
| `lib/l10n/app_zh.arb` | Contains `calMonthTotal`, `calDayTotal`, `calLoadError` | VERIFIED | All three keys present (lines 2090-2104) |
| `lib/l10n/app_en.arb` | Contains `calMonthTotal`, `calDayTotal`, `calLoadError` | VERIFIED | All three keys present (lines 2090-2104) |
| `lib/core/initialization/app_initializer.dart` | Calls `initializeDateFormatting` | VERIFIED | Line 36: `await initializeDateFormatting();` |
| `lib/features/list/presentation/providers/state_calendar_totals.dart` | `@riverpod calendarDailyTotals` with `_dayKey` at file scope | VERIFIED | 40-line file; `_dayKey` defined at line 14; `@riverpod` function at line 24; `show analyticsRepositoryProvider` import; Phase 29 seam comment at line 30 |
| `lib/features/list/presentation/providers/state_calendar_totals.g.dart` | Generated; contains `calendarDailyTotalsProvider` | VERIFIED | 142-line generated file; `calendarDailyTotalsProvider` appears 5 times |
| `lib/features/list/presentation/widgets/list_calendar_header.dart` | `CalendarHeaderWidget extends ConsumerWidget`; min 150 lines | VERIFIED | 371 lines; `ConsumerWidget` confirmed; all four C-0x components present |
| `lib/features/list/presentation/screens/list_screen.dart` | Mounts `CalendarHeaderWidget` at top | VERIFIED | Line 25-29: `CalendarHeaderWidget(bookId: bookId, currencyCode: currencyCode, locale: locale)` as first Column child |
| `test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart` | 5 provider unit tests | VERIFIED | All 5 cases implemented: expense-only, `_dayKey` normalization, empty month, D-11 fold, error propagation |
| `test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` | 3 widget tests (SC#1/SC#3/SC#4) | VERIFIED | All 3 implemented: month nav, day tap toggle, summary amount |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `list_calendar_header.dart` | `state_calendar_totals.dart` | `ref.watch(calendarDailyTotalsProvider(bookId:, year:, month:))` | WIRED | Lines 44-50 in widget `build()` |
| `list_calendar_header.dart` | `state_list_filter.dart` | `ref.watch(listFilterProvider)` + `ref.read(...notifier).selectMonth/selectDay` | WIRED | Lines 43, 64-70, 96, 190-196 |
| `list_screen.dart` | `list_calendar_header.dart` | `CalendarHeaderWidget(bookId:, currencyCode:, locale:)` | WIRED | Lines 25-29 |
| `state_calendar_totals.dart` | `repository_providers.dart` | `show analyticsRepositoryProvider` import + `ref.watch(analyticsRepositoryProvider)` | WIRED | Lines 3-4 (import with `show`), line 31 (watch call) |
| `state_calendar_totals.dart` | `shared/utils/date_boundaries.dart` | `DateBoundaries.monthRange(year, month)` | WIRED | Line 5 (import), line 32 (call) |
| `state_calendar_totals.dart` | `listFilterProvider` | Must NOT be present (isolation contract D-09) | VERIFIED ABSENT | Only mention is in a comment (line 18); zero code references |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `list_calendar_header.dart` | `calendarAsync` / `dailyMap` | `calendarDailyTotalsProvider` → `analyticsRepositoryProvider.getDailyTotals()` | Yes — Drift DAO query via analytics repository; no hardcoded values; empty map only on zero-spend months | FLOWING |
| `list_calendar_header.dart` | `filter` (month/day state) | `listFilterProvider` (Riverpod notifier) | Yes — real user interaction state | FLOWING |
| `_SummaryRow` | month total | `dailyMap.values.fold(0, (a,b)=>a+b)` over real DAO data | Yes | FLOWING |

---

### Behavioral Spot-Checks

Step 7b: SKIPPED for automated command-line checks — this is a UI-only phase. Behavioral verification was performed via the human checkpoint in Plan 27-04 (approved by user).

---

### Probe Execution

Step 7c: No `scripts/*/tests/probe-*.sh` files declared or present for this phase. SKIPPED.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| CAL-01 | 27-01, 27-03 | User can switch displayed month (prev/next) | SATISFIED | `_MonthNavBar` with chevron buttons and `selectMonth` calls; SC#1 widget test |
| CAL-02 | 27-02, 27-03 | Month calendar grid shows each day's total expense | SATISFIED | `calendarDailyTotalsProvider` + `_buildDayCell` + `formatCompact`; 5 unit tests |
| CAL-03 | 27-03 | Tap day to filter; tap again to clear | SATISFIED | `_onDayTapped` toggle logic; `selectedDayPredicate`; SC#3 widget test |
| CAL-04 | 27-03 | Month expense summary on List tab | SATISFIED | `_SummaryRow` with `amountSmall` + `AnimatedSize` day subline; SC#4 widget test |

No orphaned requirements: REQUIREMENTS.md traceability table maps only CAL-01 through CAL-04 to Phase 27, and all four are covered.

---

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `list_screen.dart:31` | `Expanded(child: Center(child: CircularProgressIndicator()))` placeholder | Info | Intentional — Phase 28 seam; comment present; not a stub in Phase 27 scope |
| `list_calendar_header.dart:17` and `state_calendar_totals.dart:14` | `_dayKey` duplicated in two files (IN-01 from review) | Info | Both definitions are identical; no silent divergence risk at present; flagged for Phase 28+ extraction |
| `list_calendar_header.dart:210` | `final dynamic filter;` in `_MonthNavBar` (WR-02 from review) | Warning (quality) | Runtime typo risk; non-blocking per review; no phase goal impacted |
| `list_calendar_header.dart:60-72` | Month navigation unbounded past `firstDay`/`lastDay` (WR-01 from review) | Warning (quality) | Nav past 2020/2030 bounds can desync page controller; v1.4 scope unlikely to trigger; non-blocking per review classification |

No `TBD`, `FIXME`, or `XXX` markers found in any Phase 27 production files. No debt-marker blockers.

**Code review findings (from 27-REVIEW.md): 0 Critical, 4 Warning, 4 Info — all advisory, none map to an unmet must-have or roadmap success criterion. Classified as quality follow-ups for Phase 28 or later.**

---

### Human Verification

Human visual verification was performed and approved during Plan 27-04 (blocking `checkpoint:human-verify` gate). The user confirmed:

1. Calendar grid renders for the current month with correct month label (ja locale "2026年5月").
2. Right chevron advances month; month label updates.
3. Month label tap returns to current real month.
4. Day cells show compact amounts for days with expenses; empty days show no amount.
5. Tapping a day with expense highlights it and adds a day subline to the summary row.
6. Tapping the same day again removes the highlight and collapses the subline.
7. Summary row shows month total formatted as JPY with tabular figures.
8. Horizontal swipe changes month (same as chevron).
9. No overflow errors with 5+ digit JPY amounts.

Approval response: "approved" — recorded in Plan 27-04.

---

### Gaps Summary

No gaps found. All 5 roadmap success criteria are verified in the codebase with substantive, wired, and data-flowing implementations. All 4 CAL requirements are satisfied. Human approval was obtained for the visual/interactive behaviors that cannot be verified programmatically.

The four code review warnings (WR-01 through WR-04 in 27-REVIEW.md) are quality advisories that do not map to any unmet phase goal or success criterion. They are candidates for Phase 28 or a dedicated polish pass.

---

_Verified: 2026-05-30T08:00:00Z_
_Verifier: Claude (gsd-verifier)_
