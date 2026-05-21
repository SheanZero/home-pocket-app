# Phase 15: Custom Time Windows (HAPPY-V2-02) - Pattern Map

**Mapped:** 2026-05-19
**Files analyzed:** 18 new/modified
**Analogs found:** 17 / 18 (one new domain model has no direct analog — uses `metric_result.dart` for sealed pattern only)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/features/analytics/domain/models/time_window.dart` (NEW) | domain model (Freezed sealed) | value object | `lib/features/analytics/domain/models/metric_result.dart` (sealed pattern only) | partial — sealed but not Freezed |
| `lib/features/analytics/presentation/providers/state_time_window.dart` (NEW) | provider (session state) | event-driven | `SelectedMonth` in `lib/features/analytics/presentation/providers/state_analytics.dart` lines 11-27 | exact |
| `lib/features/analytics/presentation/widgets/time_window_chip.dart` (NEW, replaces `month_chip_picker.dart`) | presentation widget (AppBar action) | request-response (user tap → sheet) | `lib/features/analytics/presentation/widgets/month_chip_picker.dart` | exact |
| `lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart` (NEW) | presentation widget (modal bottom sheet) | request-response | `month_chip_picker.dart` `_openPicker` (lines 80-115) + Material `showDateRangePicker` | role-match (extends sheet; adds type-row + system picker) |
| `lib/application/analytics/get_monthly_report_use_case.dart` (MODIFY) | application use case | CRUD / aggregate | self (existing month-bound signature, lines 23-122) | exact (parameter expansion) |
| `lib/application/analytics/get_happiness_report_use_case.dart` (MODIFY) | application use case | CRUD / aggregate | self (lines 28-97) | exact |
| `lib/application/analytics/get_satisfaction_distribution_use_case.dart` (MODIFY) | application use case | CRUD / aggregate | self (lines 12-25) | exact |
| `lib/application/analytics/get_best_joy_moment_use_case.dart` (MODIFY) | application use case | CRUD / aggregate | self (lines 17-42) | exact |
| `lib/application/analytics/get_largest_monthly_expense_use_case.dart` (MODIFY) | application use case | CRUD / aggregate | self (lines 12-25) | exact |
| `lib/application/analytics/_time_window_validation.dart` (NEW, private helper) | application utility | validation guard | `lib/application/analytics/get_monthly_report_use_case.dart` `_getPreviousMonthComparison` (private helper pattern) | role-match (private helper convention) |
| `lib/features/analytics/presentation/providers/state_analytics.dart` (MODIFY) | provider family + notifier | request-response | self (re-key `monthlyReportProvider` lines 30-39, `satisfactionDistributionProvider` lines 69-78; remove `SelectedMonth` lines 11-27) | exact |
| `lib/features/analytics/presentation/providers/state_happiness.dart` (MODIFY) | provider family | request-response | self (re-key `happinessReportProvider` lines 16-30, `bestJoyMomentProvider` lines 33-42, `largestMonthlyExpenseProvider` lines 62-71, `familyHappinessProvider` lines 78-97) | exact |
| `lib/features/analytics/presentation/screens/analytics_screen.dart` (MODIFY) | screen / composition | request-response | self (lines 35-188 — chip swap, window derivation, `_refresh` re-key) | exact |
| `lib/infrastructure/i18n/formatters/date_formatter.dart` (MODIFY) | infrastructure formatter | transform | self (existing locale switch, lines 32-52) | exact |
| `lib/application/i18n/formatter_service.dart` (MODIFY) | application formatter wrapper | transform | self (existing wrapper, lines 25-44) | exact |
| `lib/l10n/app_en.arb` + `app_ja.arb` + `app_zh.arb` (MODIFY) | i18n strings | static | self (lines 1690-1716 for analytics keys + placeholder pattern) | exact |
| `test/widget/features/analytics/presentation/widgets/time_window_chip_test.dart` (NEW) | widget test | request-response | `test/widget/features/analytics/presentation/widgets/month_chip_picker_test.dart` | exact |
| `test/widget/features/analytics/presentation/widgets/time_window_picker_sheet_test.dart` (NEW) | widget test | request-response | `month_chip_picker_test.dart` | role-match (extended for type-row + error SnackBar) |
| `test/unit/features/analytics/domain/models/time_window_test.dart` (NEW) | unit test (calendar math) | pure function | `test/unit/application/analytics/get_satisfaction_distribution_use_case_test.dart` (basic structure only — no calendar math analog) | partial |
| `test/unit/features/analytics/presentation/providers/state_time_window_test.dart` (NEW) | unit test (notifier) | event-driven | (no direct provider-unit analog; `month_chip_picker_test.dart` test-double pattern reusable) | partial |
| `test/unit/application/analytics/get_*_use_case_test.dart` (5 MODIFY) | unit test | CRUD | self (`get_satisfaction_distribution_use_case_test.dart`) | exact |
| `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart` (MODIFY) | widget test | request-response | self (provider override fixture, lines 39-100) | exact |
| `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` (NEW) | widget test (isolation lock) | request-response | `analytics_screen_test.dart` provider-override fixture | role-match |

## Pattern Assignments

### `lib/features/analytics/domain/models/time_window.dart` (domain, value object)

**Analog (sealed convention only):** `lib/features/analytics/domain/models/metric_result.dart`

**Sealed convention** (lines 16-29):
```dart
sealed class MetricResult<T> {
  const MetricResult();
}

final class Empty<T> extends MetricResult<T> {
  const Empty();
}

final class Value<T> extends MetricResult<T> {
  const Value(this.data, this.sampleSize);

  final T data;
  final int sampleSize;
}
```

**Differences from analog:** RESEARCH.md Pattern 1 (15-RESEARCH.md lines 262-316) prescribes **Freezed sealed** instead of plain-sealed, because `TimeWindow` value objects must support `==`/`hashCode` (Riverpod cache key equality) — Freezed gives those for free, whereas `MetricResult` carries opaque generics and is intentionally plain. New `TimeWindow` file follows the Freezed pattern; see `lib/data/tables/*` and the project-wide `@freezed` convention in CLAUDE.md.

**Shape to copy** (from 15-RESEARCH.md lines 274-288):
```dart
@freezed
sealed class TimeWindow with _$TimeWindow {
  const factory TimeWindow.week({required DateTime mondayStart}) = WeekWindow;
  const factory TimeWindow.month({required int year, required int month}) = MonthWindow;
  const factory TimeWindow.quarter({required int year, required int quarter}) = QuarterWindow;
  const factory TimeWindow.year({required int year}) = YearWindow;
  const factory TimeWindow.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) = CustomWindow;
}
```

The `range` extension delivering `(DateTime start, DateTime end)` lives in the same file; see 15-RESEARCH.md lines 290-315 for full body.

---

### `lib/features/analytics/presentation/providers/state_time_window.dart` (presentation, session state)

**Analog:** `lib/features/analytics/presentation/providers/state_analytics.dart` lines 11-27 (`SelectedMonth`)

**Imports pattern** (line 1):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/time_window.dart';

part 'state_time_window.g.dart';
```

**Notifier pattern** (lines 11-27 of analog, mirrored 1:1):
```dart
/// Currently selected month for analytics view.
@riverpod
class SelectedMonth extends _$SelectedMonth {
  @override
  DateTime build() => DateTime.now();

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }
}
```

**Apply to new file** (per 15-RESEARCH.md lines 330-341):
```dart
@riverpod
class SelectedTimeWindow extends _$SelectedTimeWindow {
  @override
  TimeWindow build() {
    final now = DateTime.now();
    return TimeWindow.month(year: now.year, month: now.month);
  }

  void setWindow(TimeWindow window) {
    state = window;
  }
}
```

**Generated provider name:** `selectedTimeWindowProvider` (no `Notifier` suffix on class → no suffix to strip; see CLAUDE.md Riverpod 3 conventions table).

**Open Question A7 (15-RESEARCH.md line 679):** If `MainShellScreen` uses `PageView`-with-discard rather than `IndexedStack`, the planner must annotate `@Riverpod(keepAlive: true)` to survive tab-swap. Default = auto-dispose.

---

### `lib/features/analytics/presentation/widgets/time_window_chip.dart` (presentation widget)

**Analog:** `lib/features/analytics/presentation/widgets/month_chip_picker.dart` (entire file, 135 lines)

**Imports pattern** (lines 1-8):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../providers/state_analytics.dart';
```

For the new chip, swap `state_analytics.dart` → `state_time_window.dart`; keep all other imports.

**Tooltip + InkWell + DecoratedBox decoration pattern** (lines 36-77 — copy verbatim, change only the watched provider and label-derivation):
```dart
return Tooltip(
  message: l10n.analyticsMonthChipPickerTooltip,           // → analyticsTimeWindowChipTooltip
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _openPicker(context, ref, selectedMonth),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.wmCard,
            border: Border.all(color: context.wmBorderDefault),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.wmTextPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '▼',
                  style: AppTextStyles.caption.copyWith(
                    color: context.wmTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
```

**Label derivation pattern (replace `formatMonthYear` with a switch on `TimeWindow` variant):**
- Current (line 31-34):
  ```dart
  final label = const FormatterService().formatMonthYear(
    selectedMonth,
    locale,
  );
  ```
- New: `switch (window) { case WeekWindow(:final mondayStart): ... }` — each branch composes via `FormatterService.formatShortMonthDay` / `formatMonthYear` / new helpers per 15-UI-SPEC.md Copywriting Contract. **Never** call `DateFormat(...)` directly in this widget (forbidden by CLAUDE.md i18n rule + 15-UI-SPEC.md Forbidden copy patterns).

**Touch-target guarantee:** preserve `minWidth: 44, minHeight: 44` (line 44 of analog). Test in `month_chip_picker_test.dart` lines 84-93 already asserts this — replicate in `time_window_chip_test.dart`.

---

### `lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart` (presentation widget)

**Analog:** `month_chip_picker.dart` `_openPicker` (lines 80-115) + Material `showDateRangePicker`

**Bottom-sheet open pattern** (lines 91-110, copy `showModalBottomSheet<T>` shape):
```dart
final picked = await showModalBottomSheet<DateTime>(
  context: context,
  builder: (sheetContext) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final month in months.reversed)
            ListTile(
              title: Text(
                const FormatterService().formatMonthYear(month, locale),
              ),
              selected: _sameMonth(month, selectedMonth),
              onTap: () => Navigator.of(sheetContext).pop(month),
            ),
        ],
      ),
    );
  },
);

if (picked != null) {
  ref.read(selectedMonthProvider.notifier).setMonth(picked);
}
```

**Apply to new sheet:**
- Change return type to `Future<TimeWindow?>`.
- Body becomes a two-region layout: **type-row** (W/M/Q/Y/Custom horizontal chips) + **chooser body** (per-type list, or "Pick a date range" affordance for Custom).
- For Custom, after type-row tap → call `showDateRangePicker(context: ..., firstDate: ..., lastDate: DateTime.now())` (per 15-UI-SPEC.md §Interaction Contract — Custom-range tap, steps 1-7).
- Validation calls happen on the picker result; on failure, surface SnackBar via `ScaffoldMessenger.of(context).showSnackBar(...)` with localized message from new ARB keys (`analyticsTimeWindowErrorTooLong`, `analyticsTimeWindowErrorInverted`, `analyticsTimeWindowErrorFutureEnd`).
- On valid selection: `ref.read(selectedTimeWindowProvider.notifier).setWindow(window)` then `Navigator.of(sheetContext).pop(window)`.

**Type-row + body internal widget convention:** per 15-UI-SPEC.md §Component Inventory, `TimeWindowTypeRow` is a private widget inside the sheet file (matches the project pattern of co-locating private widgets — see `_KpiHero`, `_TotalSixMonthCard`, `_CategoryDonutCard`, `_BestJoyCard` in `analytics_screen.dart` lines 191-501).

---

### `lib/application/analytics/get_satisfaction_distribution_use_case.dart` (application use case, MODIFY)

**Analog (self, before parameter expansion):** lines 12-25

**Imports pattern** (lines 1-2):
```dart
import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
```

**Current month-bound signature** (lines 12-24):
```dart
Future<List<SatisfactionScoreBucket>> execute({
  required String bookId,
  required int year,
  required int month,
}) {
  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
  return _repo.getSatisfactionDistribution(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
  );
}
```

**Target shape** (per 15-RESEARCH.md Pattern 3, lines 367-388):
```dart
Future<List<SatisfactionScoreBucket>> execute({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) {
  TimeWindowValidation.assertValid(startDate, endDate);
  return _repo.getSatisfactionDistribution(
    bookId: bookId, startDate: startDate, endDate: endDate);
}
```

**Validation pattern** (extracted to shared helper to avoid duplication across 5 files — see `_time_window_validation.dart` below). Use case throws `ArgumentError` defensively; presentation layer shows localized SnackBar before calling.

**Repository surface (unchanged):** All `_repo.get*` methods already accept `(startDate, endDate)` — `lib/features/analytics/domain/repositories/analytics_repository.dart` lines 10-73 confirm 9 methods with this signature. No DAO change needed.

---

### `lib/application/analytics/get_monthly_report_use_case.dart` (application use case, MODIFY)

**Analog (self):** lines 23-122

**Critical pitfall (15-RESEARCH.md Pitfall #1, lines 428-437):** This use case returns `MonthlyReport` (Freezed model) which has required `int year, int month` fields. The planner MUST decide between:
- **Option A** — keep `year/month` as "display anchor" (month containing `endDate`). Adjust line 109-121 to derive `year/month` from `endDate`.
- **Option B** — introduce parallel `WindowReport` Freezed type without `year/month`.

This decision is locked in PLAN.md (per 15-UI-SPEC.md §Open Decisions for Planner #1). Without it, the use case rewrite has no valid shape.

**Imports pattern** (lines 1-7) — copy verbatim, no change.

**Parallel `Future.wait` aggregate pattern** (lines 32-54) — copy verbatim; only the input parameters of `_analyticsRepository.get*` calls change from `(startDate, endDate)` derived from `(year, month)` to `(startDate, endDate)` passed in directly.

**Previous-month comparison** (lines 100-107, 167-214) — **HAZARD per ADR-012 §4 cross-period delta forbidden.** Per 15-UI-SPEC.md §Open Decisions for Planner #2, this is **subject to retirement** in Phase 15 alongside `analyticsKpiTotalDeltaIncreased/Decreased` ARB keys. Default recommendation: drop the previous-month comparison computation entirely; remove `MonthComparison? previousMonthComparison` from `MonthlyReport`.

---

### `lib/application/analytics/get_happiness_report_use_case.dart` (application use case, MODIFY)

**Analog (self):** lines 28-97

**Same pitfall as `MonthlyReport`** — `HappinessReport` carries required `year, month` fields (lines 69-78, 86-96). Apply the same Option A/B decision.

**Parallel `Future.wait`** (lines 37-58) — repository calls already take `(startDate, endDate)`. Replace internal derivation (lines 34-35) with passed-in parameters; no inner code change.

**Empty-report short-circuit** (lines 67-79): change `year: year, month: month` to whatever display-anchor convention the planner locks (Option A) or drop those fields (Option B).

---

### `lib/application/analytics/get_best_joy_moment_use_case.dart` (application use case, MODIFY)

**Analog (self):** lines 17-42 — same pattern. Two repository calls (`getSoulSatisfactionOverview` then `getBestJoyMoment`), both already `(startDate, endDate)`. Simplest of the five to refactor: zero data-model entanglement (returns `MetricResult<BestJoyMomentRow>`, no `year/month` field).

---

### `lib/application/analytics/get_largest_monthly_expense_use_case.dart` (application use case, MODIFY)

**Analog (self):** lines 12-25 — same pattern as `get_satisfaction_distribution_use_case.dart`. `LargestMonthlyExpense?` return value has no `year/month` field, so this is also clean.

---

### `lib/application/analytics/_time_window_validation.dart` (application utility, NEW)

**Analog:** No exact analog — this is a new private helper. Closest convention is private helpers co-located with use cases (e.g., `_getPreviousMonthComparison` in `get_monthly_report_use_case.dart` lines 167-214; private methods inside use case classes).

**Shape** (per 15-RESEARCH.md lines 377-387 + Pitfall #5 calendar-month math at lines 472-485):
```dart
class TimeWindowValidation {
  TimeWindowValidation._();

  /// D-06 inclusive: assumes startDate <= endDate semantically.
  /// D-08: 12-month cap by calendar-month math (not Duration.inDays).
  static void assertValid(DateTime startDate, DateTime endDate) {
    if (startDate.isAfter(endDate)) {
      throw ArgumentError.value(
        (startDate, endDate),
        'window',
        'startDate must be <= endDate',
      );
    }
    final months =
        (endDate.year - startDate.year) * 12 + (endDate.month - startDate.month);
    if (months > 12 || (months == 12 && endDate.day > startDate.day)) {
      throw ArgumentError.value(
        (startDate, endDate),
        'window',
        'window must not exceed 12 months',
      );
    }
    if (endDate.isAfter(DateTime.now())) {
      throw ArgumentError.value(
        (startDate, endDate),
        'window',
        'endDate must not be in the future',
      );
    }
  }
}
```

**Why a class with `_()` constructor:** matches the `DateFormatter` pattern in `lib/infrastructure/i18n/formatters/date_formatter.dart` line 6 — utility class with private constructor.

**Why not in domain layer:** per 15-RESEARCH.md line 390, `ArgumentError` belongs in application, not domain. Domain models are pure data.

---

### `lib/features/analytics/presentation/providers/state_analytics.dart` (provider, MODIFY)

**Analog (self):** lines 11-78

**Remove `SelectedMonth` notifier** (lines 11-27) — replaced by `SelectedTimeWindow` in `state_time_window.dart` (per 15-RESEARCH.md A4 / Open Q2; recommended path is "delete and replace").

**Re-key family providers:**
- `monthlyReportProvider` (lines 30-39): `(bookId, year, month)` → `(bookId, startDate, endDate)` matching the new use-case signature.
- `satisfactionDistributionProvider` (lines 69-78): same re-keying.
- `expenseTrendProvider` (lines 42-50): **unchanged** (D-10 — trend stays month-anchored; anchor derived from `window.endDate` in the consumer screen, not in the provider).
- `earliestTransactionMonthProvider` (lines 53-66): **unchanged** (still month-precision; consumer renders preset lists per Open Q6).

**Imports pattern** (lines 1-8): no change except remove unused imports if `SelectedMonth` moves out.

---

### `lib/features/analytics/presentation/providers/state_happiness.dart` (provider, MODIFY)

**Analog (self):** lines 16-97

**Re-key four providers:**
- `happinessReportProvider` (lines 16-30): `(bookId, year, month, currencyCode)` → `(bookId, startDate, endDate, currencyCode)`.
- `bestJoyMomentProvider` (lines 33-42): `(bookId, year, month)` → `(bookId, startDate, endDate)`.
- `largestMonthlyExpenseProvider` (lines 62-71): same re-keying.
- `familyHappinessProvider` (lines 78-97): `(year, month)` → `(startDate, endDate)`; `_emptyFamilyHappiness` helper at lines 99-108 needs the Option A/B decision (FamilyHappiness model carries `year, month`).

**Provider pattern (lines 16-30)** — copy verbatim, replace parameter shape:
```dart
@riverpod
Future<HappinessReport> happinessReport(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
  required String currencyCode,
}) async {
  final useCase = ref.watch(getHappinessReportUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    year: year,
    month: month,
    currencyCode: currencyCode,
  );
}
```

**HomeHero isolation (15-RESEARCH.md Pitfall #3, lines 446-461):** `home_screen.dart` line 16 imports `state_analytics.dart` for `monthlyReportProvider`/`happinessReportProvider` *families* but reads `DateTime.now()` at line 49 (not `selectedMonthProvider`). After re-keying, HomeScreen will call the new `(bookId, startDate, endDate)`-keyed family with the current month's range. **This requires HomeScreen edits** to construct `startDate = DateTime(now.year, now.month, 1)` / `endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59)` and pass those instead of `year/month`. Locking test ensures HomeHero stays month-anchored regardless of `selectedTimeWindowProvider` state.

---

### `lib/features/analytics/presentation/screens/analytics_screen.dart` (screen, MODIFY)

**Analog (self):** lines 35-188

**Window derivation pattern (replace lines 37-39):**
- Before:
  ```dart
  final selected = ref.watch(selectedMonthProvider);
  final year = selected.year;
  final month = selected.month;
  ```
- After:
  ```dart
  final window = ref.watch(selectedTimeWindowProvider);
  final range = window.range;       // (start, end) tuple from TimeWindow extension
  final startDate = range.start;
  final endDate = range.end;
  // Trend anchor stays month-anchored per D-10:
  final trendAnchor = DateTime(endDate.year, endDate.month);
  ```

**AppBar chip swap (line 63):**
- Before: `MonthChipPicker(locale: locale, earliestMonth: earliestMonthAsync.value)`
- After: `TimeWindowChip(locale: locale, earliestData: earliestMonthAsync.value)`

**Card invocation pattern (lines 82-141):** every `_KpiHero`, `_CategoryDonutCard`, `_SatisfactionHistogramOrFallback`, `_LargestExpenseCard`, `_BestJoyCard`, `_FamilyCard` widget takes `year: year, month: month` — change to `startDate: startDate, endDate: endDate`. `_TotalSixMonthCard` (lines 94-98) keeps `anchor: trendAnchor` per D-10.

**`_refresh` re-key pattern (lines 150-188)** — copy structure, change every `invalidate(Provider(bookId: ..., year: ..., month: ...))` call to the windowed key:
```dart
void _refresh(
  WidgetRef ref, {
  required DateTime startDate,
  required DateTime endDate,
  required DateTime trendAnchor,
  required String currencyCode,
  required bool isGroupMode,
}) {
  ref.invalidate(
    monthlyReportProvider(bookId: bookId, startDate: startDate, endDate: endDate),
  );
  ref.invalidate(expenseTrendProvider(bookId: bookId, anchor: trendAnchor));
  ref.invalidate(earliestTransactionMonthProvider(bookId: bookId));
  ref.invalidate(
    happinessReportProvider(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      currencyCode: currencyCode,
    ),
  );
  // ... 4 more invalidations re-keyed
  // CRITICAL: do NOT invalidate any home/* provider (D-12 + Pitfall #3)
}
```

**Per-card `AsyncValue.when` isolation pattern (lines 220-249, 269-287, 306-319, 353-388, 411-429, 451-465, 487-499)** — preserved unchanged. Each card's `error: (...) => AnalyticsCardErrorState(onRetry: () => ref.invalidate(<windowed-key>))` continues to work; only the key shape changes.

**Open question A8 (15-RESEARCH.md line 680):** Some widget tests may exercise `find.text('May 2026')` against story cards. Grep before refactor.

---

### `lib/infrastructure/i18n/formatters/date_formatter.dart` (formatter, MODIFY)

**Analog (self):** lines 32-52 (`formatMonthYear`, `formatShortMonthDay`)

**Locale switch pattern** (lines 32-41):
```dart
static String formatMonthYear(DateTime date, Locale locale) {
  switch (locale.languageCode) {
    case 'ja':
    case 'zh':
      return DateFormat('yyyy年M月', locale.toString()).format(date);
    case 'en':
    default:
      return DateFormat('MMMM yyyy', locale.toString()).format(date);
  }
}
```

**New methods to add (per 15-UI-SPEC.md Copywriting Contract):** the new chip labels mostly compose existing helpers (`formatMonthYear` for Month, `formatShortMonthDay` for Week and Custom endpoints). **For Year and Quarter labels**, add:
- `formatYear(DateTime date, Locale locale)` — locale switch returning `'2026'` (en), `'2026年'` (ja/zh).
- `formatQuarter(int year, int quarter, Locale locale)` — locale switch (15-RESEARCH.md Pitfall A2 line 674 cautions against raw CLDR `QQQ`; prefer literal placeholders per 15-UI-SPEC.md table line 112).

**Forbidden:** ad-hoc `DateFormat(...)` calls in widget files. All date display routes through `FormatterService` → `DateFormatter` (CLAUDE.md i18n rule).

---

### `lib/application/i18n/formatter_service.dart` (formatter wrapper, MODIFY)

**Analog (self):** lines 25-44

**Delegate method pattern** (lines 25-44):
```dart
/// Format a [date] to a locale-appropriate date string.
String formatDate(DateTime date, Locale locale) =>
    DateFormatter.formatDate(date, locale);

String formatMonthYear(DateTime date, Locale locale) =>
    DateFormatter.formatMonthYear(date, locale);
```

**Add corresponding delegates** for `formatYear`, `formatQuarter`, and any other new formatters. Pattern is one-liner pass-through; no logic.

---

### `lib/l10n/app_en.arb` + `app_ja.arb` + `app_zh.arb` (i18n, MODIFY)

**Analog (self):** `app_en.arb` lines 1690-1716 — existing analytics keys with placeholder pattern.

**Existing placeholder pattern** (lines 1690-1707):
```json
"analyticsKpiTotalDeltaIncreased": "↑ +{pct}% MoM",
"@analyticsKpiTotalDeltaIncreased": {
  "description": "Total spending KPI month-over-month increase",
  "placeholders": {
    "pct": {
      "type": "String"
    }
  }
}
```

**New keys to add (per 15-UI-SPEC.md Copywriting Contract table, lines 109-128):**
| New ARB Key | en | ja | zh |
|---|---|---|---|
| `analyticsTimeWindowChipTooltip` (REPLACES `analyticsMonthChipPickerTooltip`) | Pick a time window | 期間を選ぶ | 选择时间范围 |
| `analyticsTimeWindowChipLabelWeek` (placeholder `{monday}`) | Week of {monday} | {monday}の週 | {monday}的一周 |
| `analyticsTimeWindowChipLabelQuarter` (placeholders `{q, year}`) | Q{q} {year} | {year}年 第{q}四半期 | {year}年 第{q}季度 |
| `analyticsTimeWindowChipLabelYear` (placeholder `{year}`) | {year} | {year}年 | {year}年 |
| `analyticsTimeWindowChipLabelCustom` (placeholders `{start, end}`) | {start} – {end} | {start} 〜 {end} | {start} 至 {end} |
| `analyticsTimeWindowSheetTitle` | Time window | 期間 | 时间范围 |
| `analyticsTimeWindowTypeWeek` | Week | 週 | 周 |
| `analyticsTimeWindowTypeMonth` | Month | 月 | 月 |
| `analyticsTimeWindowTypeQuarter` | Quarter | 四半期 | 季度 |
| `analyticsTimeWindowTypeYear` | Year | 年 | 年 |
| `analyticsTimeWindowTypeCustom` | Custom | カスタム | 自定义 |
| `analyticsTimeWindowCustomCta` | Pick a date range | 日付範囲を選ぶ | 选择日期范围 |
| `analyticsTimeWindowErrorTooLong` | Range cannot exceed 12 months. Pick a shorter range. | 期間は12ヶ月を超えられません。短い期間を選んでください。 | 时间范围不能超过 12 个月。请选择较短的范围。 |
| `analyticsTimeWindowErrorInverted` | Start date must be before end date. | 開始日は終了日より前にしてください。 | 开始日期必须早于结束日期。 |
| `analyticsTimeWindowErrorFutureEnd` | End date cannot be in the future. | 終了日に未来の日付は選べません。 | 结束日期不能晚于今天。 |
| `analyticsTimeWindowEmptyPreset` | No data yet for this view. Add a transaction to begin. | このビュー用のデータがありません。取引を追加してください。 | 此视图暂无数据。请先添加一笔交易。 |

**Existing keys to retire/rename** (per 15-UI-SPEC.md table line 109, 126-128):
- `analyticsMonthChipPickerTooltip` → renamed to `analyticsTimeWindowChipTooltip` (deletion + new key).
- `analyticsKpiTotalLabel` → reword from "This month's spending" → "Total spending" (per 15-RESEARCH.md Pitfall #6, 15-UI-SPEC.md line 126). Same key name; copy only changes.
- `analyticsKpiTotalDeltaIncreased` / `analyticsKpiTotalDeltaDecreased` (lines 1699-1716) → **subject to retirement** per 15-UI-SPEC.md Open Decisions for Planner #2. ADR-012 §4 may force removal.

**Parity rule (CLAUDE.md):** every change must land in all three ARB files in the same commit; `flutter gen-l10n` must succeed without warnings.

---

## Shared Patterns

### Authentication / Authorization
**Not applicable.** Phase 15 is purely client-side UI/state per 15-RESEARCH.md §Security Domain (V2/V3/V4 = no). No new auth surface.

### Input Validation
**Source:** `lib/application/analytics/_time_window_validation.dart` (NEW, per pattern shown above)

**Apply to:** All 5 modified use case files (`get_monthly_report_use_case.dart`, `get_happiness_report_use_case.dart`, `get_satisfaction_distribution_use_case.dart`, `get_best_joy_moment_use_case.dart`, `get_largest_monthly_expense_use_case.dart`).

**Pattern:** First line of each `execute(...)` body — `TimeWindowValidation.assertValid(startDate, endDate);`. Throws `ArgumentError` (per 15-RESEARCH.md HIGH-02 layering / Pitfall #5 calendar-month math). Defense-in-depth — UI shows localized SnackBar before calling.

### Error Handling (UI)
**Source:** `analytics_screen.dart` per-card `AsyncValue.when` (e.g., lines 232-241):
```dart
error: (_, _) => AnalyticsCardErrorState(
  onRetry: () => ref.invalidate(
    happinessReportProvider(
      bookId: bookId,
      year: year,
      month: month,
      currencyCode: currencyCode,
    ),
  ),
),
```

**Apply to:** All re-keyed providers retain the same per-card error isolation; only the invalidation key shape changes from `(year, month)` to `(startDate, endDate)`.

**Snackbar error pattern for invalid custom range:** new — use `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.analyticsTimeWindowErrorTooLong)))`. No project-wide precedent for analytics SnackBars; closest analog is the home-screen's `datePickerComingSoon` toast at `home_screen.dart:73-79`:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(S.of(context).datePickerComingSoon),
    duration: const Duration(seconds: 1),
  ),
);
```

### Date Formatting
**Source:** `lib/infrastructure/i18n/formatters/date_formatter.dart` (locale switch on `locale.languageCode`)

**Apply to:** Every date display in the new chip, sheet, and any new use-case-driven label. Wrapper: `FormatterService` (`lib/application/i18n/formatter_service.dart`) — widget code must NEVER import `DateFormatter` directly (CLAUDE.md i18n rule + 15-UI-SPEC.md Forbidden copy patterns).

### Provider Family Keying (Riverpod 3)
**Source:** `state_analytics.dart` lines 30-39 (`monthlyReportProvider` family on `(bookId, year, month)`)

**Apply to:** Re-key all 5 month-bound providers to `(bookId, startDate, endDate, ...)`. `DateTime` has stable `==`/`hashCode` (Riverpod cache-correct).

**Pitfall:** see 15-RESEARCH.md Pitfall #2 (line 439) — the rename of provider family keys must be atomic with `_refresh` invalidation updates. Otherwise stale keys silently coexist.

### Testing — provider override pattern
**Source:** `test/widget/features/analytics/presentation/widgets/month_chip_picker_test.dart` lines 8-42

**Pattern** (lines 8-23):
```dart
class TestSelectedMonth extends SelectedMonth {
  TestSelectedMonth(this.initialMonth);

  final DateTime initialMonth;
  DateTime? lastSetMonth;
  int setMonthCalls = 0;

  @override
  DateTime build() => initialMonth;

  @override
  void setMonth(DateTime month) {
    setMonthCalls += 1;
    lastSetMonth = month;
    super.setMonth(month);
  }
}
```

**Apply to:** `time_window_chip_test.dart` + `time_window_picker_sheet_test.dart` — subclass `SelectedTimeWindow`, override `build()` to return a fixed `TimeWindow.month(...)`, track `setWindow` calls.

**Apply to:** `analytics_screen_test.dart` (modification) — replace `_TestSelectedMonth` (line 39) with `_TestSelectedTimeWindow`; update every `monthlyReportProvider(bookId: ..., year: ..., month: ...).overrideWith(...)` at lines 61-91 to the windowed key shape.

### Testing — use-case mock pattern
**Source:** `test/unit/application/analytics/get_satisfaction_distribution_use_case_test.dart`

**Mocktail pattern** (lines 7, 16-21):
```dart
class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

late _MockAnalyticsRepository repository;
late GetSatisfactionDistributionUseCase useCase;

final startDate = DateTime(2026, 5);
final endDate = DateTime(2026, 5, 31, 23, 59, 59);

setUp(() {
  repository = _MockAnalyticsRepository();
  useCase = GetSatisfactionDistributionUseCase(
    analyticsRepository: repository,
  );
});
```

**Verify pattern** (lines 49-61):
```dart
test('uses selected month boundaries', () async {
  stubDistribution(const []);
  await execute();
  verify(
    () => repository.getSatisfactionDistribution(
      bookId: 'book-1',
      startDate: startDate,
      endDate: endDate,
    ),
  ).called(1);
});
```

**Apply to:** All 5 use-case test files — rewrite `execute()` helper to call `useCase.execute(bookId: 'book-1', startDate: startDate, endDate: endDate)` instead of `(year: 2026, month: 5)`. Add new tests:
- `start > end → throwsArgumentError`
- `(end - start) > 12 months → throwsArgumentError`
- `end in future → throwsArgumentError`

### Testing — HomeHero isolation lock (NEW test file)
**Source:** No direct analog. Closest: `analytics_screen_test.dart` provider-override fixture (lines 39-100).

**Pattern for new file `home_screen_isolation_test.dart`:**
1. Override `selectedTimeWindowProvider` to return `TimeWindow.year(year: 2024)`.
2. Override `monthlyReportProvider(bookId: ..., startDate: <current month 1st>, endDate: <current month last>)` to return a fixture.
3. Pump `HomeScreen`.
4. Assert HomeHero renders the current-month fixture (i.e., HomeScreen never read the 2024 window).
5. Verify with mocktail — `verifyNever(() => useCase.execute(... year=2024 ...))` or equivalent provider read assertion.

This is success criterion **SC-3** in 15-RESEARCH.md line 743. It locks Pitfall #3 (line 446) structurally.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/features/analytics/domain/models/time_window.dart` (Freezed sealed class) | domain value object | value type | No existing Freezed-sealed-with-multiple-factory-variants in the analytics feature. `MetricResult<T>` is sealed but plain-Dart (not `@freezed`). 15-RESEARCH.md Pattern 1 (lines 262-316) prescribes the Freezed shape; no in-codebase example to copy verbatim. Likely closest project-wide Freezed examples: `lib/data/repositories/*` (data model freezed types) — but those are single-factory, not sealed-multi-variant. |
| `test/unit/features/analytics/domain/models/time_window_test.dart` | calendar-math unit test | pure function | No existing test exercises ISO-week-Monday calendar math or quarter boundary edge cases. Closest pattern is `test/unit/application/analytics/get_*_use_case_test.dart` shape — but those don't test calendar math. Tests must cover (a) all 5 variants resolve to expected `(start, end)`, (b) Monday-of-week regardless of input day, (c) quarter-boundary correctness (Q1=Jan-Mar, Q2=Apr-Jun, etc.), (d) leap-year Feb in custom range, (e) calendar-month span check (15-RESEARCH.md Pitfall #5 lines 472-485). |

## Metadata

**Analog search scope:**
- `lib/features/analytics/presentation/widgets/`
- `lib/features/analytics/presentation/providers/`
- `lib/features/analytics/presentation/screens/`
- `lib/features/analytics/domain/`
- `lib/application/analytics/`
- `lib/application/i18n/`
- `lib/infrastructure/i18n/`
- `lib/features/home/presentation/screens/` (isolation verification only)
- `lib/l10n/app_{en,ja,zh}.arb`
- `test/widget/features/analytics/`
- `test/unit/application/analytics/`
- `test/helpers/`

**Files scanned:** 22 source/test files + 3 ARB files + 3 .planning input files
**Pattern extraction date:** 2026-05-19
