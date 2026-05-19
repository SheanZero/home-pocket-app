---
phase: 15-custom-time-windows-happy-v2-02
reviewed: 2026-05-19T13:59:28Z
depth: standard
files_reviewed: 57
files_reviewed_list:
  - lib/application/analytics/_time_window_validation.dart
  - lib/application/analytics/get_best_joy_moment_use_case.dart
  - lib/application/analytics/get_family_happiness_use_case.dart
  - lib/application/analytics/get_happiness_report_use_case.dart
  - lib/application/analytics/get_largest_monthly_expense_use_case.dart
  - lib/application/analytics/get_monthly_report_use_case.dart
  - lib/application/analytics/get_satisfaction_distribution_use_case.dart
  - lib/application/i18n/formatter_service.dart
  - lib/features/analytics/domain/models/family_happiness.dart
  - lib/features/analytics/domain/models/family_happiness.freezed.dart
  - lib/features/analytics/domain/models/happiness_report.dart
  - lib/features/analytics/domain/models/happiness_report.freezed.dart
  - lib/features/analytics/domain/models/monthly_report.dart
  - lib/features/analytics/domain/models/monthly_report.freezed.dart
  - lib/features/analytics/domain/models/time_window.dart
  - lib/features/analytics/domain/models/time_window.freezed.dart
  - lib/features/analytics/presentation/providers/state_analytics.dart
  - lib/features/analytics/presentation/providers/state_analytics.g.dart
  - lib/features/analytics/presentation/providers/state_happiness.dart
  - lib/features/analytics/presentation/providers/state_happiness.g.dart
  - lib/features/analytics/presentation/providers/state_time_window.dart
  - lib/features/analytics/presentation/providers/state_time_window.g.dart
  - lib/features/analytics/presentation/screens/analytics_screen.dart
  - lib/features/analytics/presentation/widgets/time_window_chip.dart
  - lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart
  - lib/features/analytics/presentation/widgets/total_spending_kpi_tile.dart
  - lib/features/home/presentation/providers/state_shadow_books.dart
  - lib/features/home/presentation/providers/state_shadow_books.g.dart
  - lib/features/home/presentation/screens/home_screen.dart
  - lib/features/home/presentation/screens/main_shell_screen.dart
  - lib/generated/app_localizations.dart
  - lib/generated/app_localizations_en.dart
  - lib/generated/app_localizations_ja.dart
  - lib/generated/app_localizations_zh.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - test/unit/application/analytics/get_best_joy_moment_use_case_test.dart
  - test/unit/application/analytics/get_family_happiness_use_case_test.dart
  - test/unit/application/analytics/get_happiness_report_use_case_test.dart
  - test/unit/application/analytics/get_largest_monthly_expense_use_case_test.dart
  - test/unit/application/analytics/get_monthly_report_use_case_test.dart
  - test/unit/application/analytics/get_satisfaction_distribution_use_case_test.dart
  - test/unit/application/analytics/time_window_validation_test.dart
  - test/unit/features/analytics/domain/models/time_window_test.dart
  - test/unit/features/analytics/presentation/providers/analytics_providers_characterization_test.dart
  - test/unit/features/analytics/presentation/providers/repository_providers_test.dart
  - test/unit/features/analytics/presentation/providers/state_time_window_test.dart
  - test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart
  - test/unit/infrastructure/i18n/formatters/date_formatter_test.dart
  - test/widget/features/analytics/presentation/screens/analytics_no_delta_ui_test.dart
  - test/widget/features/analytics/presentation/screens/analytics_screen_test.dart
  - test/widget/features/analytics/presentation/widgets/time_window_chip_test.dart
  - test/widget/features/analytics/presentation/widgets/time_window_picker_sheet_test.dart
  - test/widget/features/analytics/presentation/widgets/total_spending_kpi_tile_test.dart
  - test/widget/features/home/presentation/screens/home_screen_isolation_test.dart
  - test/widget/features/home/presentation/screens/home_screen_test.dart
findings:
  critical: 2
  warning: 3
  info: 0
  total: 5
status: issues_found
---

# Phase 15: Code Review Report

**Reviewed:** 2026-05-19T13:59:28Z
**Depth:** standard
**Files Reviewed:** 57
**Status:** issues_found

## Summary

Reviewed the listed analytics, home, i18n, generated, and test files at standard depth. Generated Riverpod/Freezed/l10n code appears consistent with the changed source signatures, and `flutter analyze` reports no issues. The implementation still has correctness defects around custom date ranges and non-month report data, plus reliability and polish issues that should be fixed before accepting the phase.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Custom ranges ending today are rejected after selection

**File:** `lib/application/analytics/_time_window_validation.dart:31`
**Issue:** The custom picker validates the raw `DateTimeRange.end` date at midnight, so selecting a custom range that ends today is accepted in `time_window_picker_sheet.dart:236`. After that, `TimeWindow.custom.range` expands the same date to `23:59:59` in `time_window.dart:69`, and every analytics use case calls `TimeWindowValidation.assertValid`. For most custom ranges ending today, `endDate.isAfter(DateTime.now())` is true, and `_isCurrentCalendarWindow` returns false unless the custom range exactly matches the current week/month/quarter/year. Result: a valid user selection like May 1 through May 19, 2026 opens an error state across the dashboard.
**Fix:**
```dart
final now = DateTime.now();
final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
if (endDate.isAfter(todayEnd) &&
    !_isCurrentCalendarWindow(startDate, endDate, now)) {
  throw ArgumentError.value(
    (startDate, endDate),
    'window',
    'endDate must not be in the future',
  );
}
```
Add a regression test for `TimeWindowValidation.assertValid(start, DateTime(now.year, now.month, now.day, 23, 59, 59))` where `start` is not a preset calendar boundary.

### CR-02: Daily expense series is wrong for quarter, year, and custom windows

**File:** `lib/application/analytics/get_monthly_report_use_case.dart:83`
**Issue:** `getDailyTotals` is queried for the entire selected window, but `_buildDailyExpenses` then generates only the end-date anchor month (`anchorYear`/`anchorMonth`) and keys totals only by `dt.date.day` at line 157. For a custom January-April range, January 10 and April 10 collide, earlier months disappear, and the returned `MonthlyReport.dailyExpenses` no longer matches the queried window. This is a data contract bug even if the current AnalyticsScreen does not surface the field.
**Fix:**
```dart
final dailyExpenses = _buildDailyExpensesForRange(
  dailyTotals: dailyTotals,
  startDate: startDate,
  endDate: endDate,
);

List<DailyExpense> _buildDailyExpensesForRange({
  required List<DailyTotal> dailyTotals,
  required DateTime startDate,
  required DateTime endDate,
}) {
  final dailyMap = {
    for (final dt in dailyTotals)
      DateTime(dt.date.year, dt.date.month, dt.date.day): dt.totalAmount,
  };
  final first = DateTime(startDate.year, startDate.month, startDate.day);
  final last = DateTime(endDate.year, endDate.month, endDate.day);
  return [
    for (var day = first; !day.isAfter(last); day = day.add(const Duration(days: 1)))
      DailyExpense(date: day, amount: dailyMap[day] ?? 0),
  ];
}
```
Add a test with transactions on the same day number in different months inside one custom range.

## Warnings

### WR-01: Period-specific strings still say "this month" under non-month windows

**File:** `lib/l10n/app_en.arb:1879`
**Issue:** The AnalyticsScreen now supports week, quarter, year, and custom ranges, but visible strings such as `analyticsCardTitleLargestExpense` and `analyticsCardTitleBestJoy` still say "this month" in English, Japanese, and Chinese. The queried data follows the selected range, so these labels become misleading as soon as a user selects a non-month window.
**Fix:** Use period-neutral copy such as "Largest expense" and "Best Joy moment" in all three ARB files, then run `flutter gen-l10n` so `lib/generated/app_localizations*.dart` stays in sync.

### WR-02: Shadow-book provider tests use fixed sleeps instead of provider synchronization

**File:** `test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart:59`
**Issue:** The tests wait with `Future.delayed(const Duration(milliseconds: 100))` and `150` before reading provider futures. That makes the tests scheduler-speed dependent and can be flaky on loaded CI, especially with Riverpod auto-dispose async providers.
**Fix:** Replace the sleeps with the project helper pattern from `test/helpers/test_provider_scope.dart`, e.g. `waitForFirstValue(container, shadowBooksProvider)`, or await `container.read(provider.future)` while keeping the provider listened for the duration of the assertion.

### WR-03: TimeWindow constructors accept invalid values and silently normalize dates

**File:** `lib/features/analytics/domain/models/time_window.dart:14`
**Issue:** The comments require Monday starts, month `1..12`, and quarter `1..4`, but the Freezed factories do not enforce those invariants. Dart normalizes invalid dates, so `TimeWindow.quarter(year: 2026, quarter: 0)` becomes a valid-looking previous-year range instead of failing fast. That bypasses the defensive validation intent at use-case boundaries because the malformed value has already been converted into a plausible date range.
**Fix:** Add assertions to the value object factories and tests for invalid construction:
```dart
@Assert('mondayStart.weekday == DateTime.monday')
const factory TimeWindow.week({required DateTime mondayStart}) = WeekWindow;

@Assert('month >= 1 && month <= 12')
const factory TimeWindow.month({required int year, required int month}) =
    MonthWindow;

@Assert('quarter >= 1 && quarter <= 4')
const factory TimeWindow.quarter({
  required int year,
  required int quarter,
}) = QuarterWindow;
```
Regenerate `time_window.freezed.dart` after updating the model.

---

_Reviewed: 2026-05-19T13:59:28Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
