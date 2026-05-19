---
phase: 11-statistics-surface-for
reviewed: 2026-05-03T16:23:13Z
depth: standard
files_reviewed: 43
files_reviewed_list:
  - lib/application/analytics/get_daily_joy_per_yen_use_case.dart
  - lib/application/analytics/get_expense_trend_use_case.dart
  - lib/application/analytics/get_largest_monthly_expense_use_case.dart
  - lib/data/daos/analytics_dao.dart
  - lib/data/repositories/analytics_repository_impl.dart
  - lib/features/analytics/domain/models/analytics_aggregate.dart
  - lib/features/analytics/domain/models/daily_joy_per_yen_point.dart
  - lib/features/analytics/domain/repositories/analytics_repository.dart
  - lib/features/analytics/presentation/providers/repository_providers.dart
  - lib/features/analytics/presentation/providers/state_analytics.dart
  - lib/features/analytics/presentation/providers/state_happiness.dart
  - lib/features/analytics/presentation/screens/analytics_screen.dart
  - lib/features/analytics/presentation/widgets/analytics_card_error_state.dart
  - lib/features/analytics/presentation/widgets/analytics_screen_section_header.dart
  - lib/features/analytics/presentation/widgets/best_joy_story_strip.dart
  - lib/features/analytics/presentation/widgets/category_spend_donut_chart.dart
  - lib/features/analytics/presentation/widgets/family_insight_card.dart
  - lib/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart
  - lib/features/analytics/presentation/widgets/joy_ledger_thin_sample_fallback.dart
  - lib/features/analytics/presentation/widgets/joy_trend_line_chart.dart
  - lib/features/analytics/presentation/widgets/kpi_mini_hero_strip.dart
  - lib/features/analytics/presentation/widgets/largest_expense_story_card.dart
  - lib/features/analytics/presentation/widgets/month_chip_picker.dart
  - lib/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart.dart
  - lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart
  - lib/features/analytics/presentation/widgets/total_spending_kpi_tile.dart
  - test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart
  - test/unit/application/analytics/get_expense_trend_use_case_test.dart
  - test/unit/application/analytics/get_largest_monthly_expense_use_case_test.dart
  - test/unit/data/daos/analytics_dao_daily_joy_test.dart
  - test/unit/data/daos/analytics_dao_largest_expense_test.dart
  - test/widget/features/analytics/presentation/screens/analytics_screen_test.dart
  - test/widget/features/analytics/presentation/widgets/best_joy_story_strip_test.dart
  - test/widget/features/analytics/presentation/widgets/category_spend_donut_chart_test.dart
  - test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart
  - test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart
  - test/widget/features/analytics/presentation/widgets/joy_trend_line_chart_test.dart
  - test/widget/features/analytics/presentation/widgets/kpi_mini_hero_strip_test.dart
  - test/widget/features/analytics/presentation/widgets/largest_expense_story_card_test.dart
  - test/widget/features/analytics/presentation/widgets/month_chip_picker_test.dart
  - test/widget/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart_test.dart
  - test/widget/features/analytics/presentation/widgets/satisfaction_distribution_histogram_test.dart
  - test/widget/features/analytics/presentation/widgets/total_spending_kpi_tile_test.dart
findings:
  critical: 2
  warning: 2
  info: 0
  total: 4
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-05-03T16:23:13Z
**Depth:** standard
**Files Reviewed:** 43
**Status:** issues_found

## Summary

Reviewed the Phase 11 analytics dashboard implementation, DAO/repository/use-case additions, providers, widget tests, and the UI/research/audit contracts used to scope the work. `flutter analyze` reports no static issues, but the implementation still contains runtime navigation failures and dashboard behavior gaps that should not ship.

## Critical Issues

### CR-01: BLOCKER - Dashboard actions call unregistered named routes

**File:** `lib/features/analytics/presentation/screens/analytics_screen.dart:334`

**Issue:** `_JoyTrendOrFallback`, `_LargestExpenseCard`, and `_BestJoyCard` call `Navigator.pushNamed('/transactions/add')` and `Navigator.pushNamed('/transactions/detail', ...)` at lines 334, 491-493, and 535-537. The app's `MaterialApp` is configured with `home` only and no `routes`/`onGenerateRoute`; existing navigation uses `MaterialPageRoute` directly. Tapping the thin-sample CTA or either story card will throw a route-generation exception instead of navigating.

**Fix:**
```dart
// Add-entry path should mirror MainShellScreen's FAB:
Navigator.of(context).push<void>(
  MaterialPageRoute<void>(
    builder: (_) => TransactionEntryScreen(bookId: bookId),
  ),
);

// For story cards, either implement/register a real transaction detail route
// or disable the tap until a TransactionDetailScreen exists. Do not call
// pushNamed unless MaterialApp registers the route.
```

### CR-02: BLOCKER - Month picker hides historical data older than the fallback window

**File:** `lib/features/analytics/presentation/screens/analytics_screen.dart:63`

**Issue:** `AnalyticsScreen` constructs `MonthChipPicker(locale: locale)` without passing `earliestMonth`, so `MonthChipPicker` falls back to `DateTime(latest.year, latest.month - 12)` at lines 85-89 of `month_chip_picker.dart`. The UI contract requires the picker range to run from the earliest transaction month through the current month. Any book with transactions older than the fallback window becomes impossible to inspect from the statistics screen even though the providers and DAOs can query those months.

**Fix:** Add a book-scoped provider/repository query for the earliest non-deleted transaction timestamp and pass it into the picker.
```dart
final earliestMonthAsync = ref.watch(earliestTransactionMonthProvider(bookId));

actions: [
  MonthChipPicker(
    locale: locale,
    earliestMonth: earliestMonthAsync.valueOrNull,
  ),
],
```

## Warnings

### WR-01: WARNING - Histogram annotation is not attached to bar 5

**File:** `lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart:103`

**Issue:** The hard-locked histogram contract says the bar-5 annotation must be permanently visible above bar 5, not only as a generic caption below the chart. The implementation renders `analyticsHistogramBarFiveAnnotation` in a centered `Text` below the `BarChart` at lines 103-105, so the visual no longer identifies the median/default-5 bar and the test only verifies text existence, not placement.

**Fix:** Render the annotation as part of the score-5 bar presentation, using the supported fl_chart label API if available or a `Stack` overlay aligned to the score-5 x-position. Strengthen the widget test to assert the annotation is associated with score 5, not just present somewhere in the widget tree.

### WR-02: WARNING - Section header hardcodes a light-theme color

**File:** `lib/features/analytics/presentation/widgets/analytics_screen_section_header.dart:21`

**Issue:** The section header uses `const Color(0xFF374151)` directly. Phase 11's theme contract forbids inline widget hex colors and requires theme-aware `context.wm*` or `AppColors.*` values; this hardcoded charcoal can lose contrast on dark theme and creates a second, untracked color source.

**Fix:**
```dart
style: AppTextStyles.caption.copyWith(
  fontWeight: FontWeight.w700,
  color: context.wmTextSecondary,
),
```

---

_Reviewed: 2026-05-03T16:23:13Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
