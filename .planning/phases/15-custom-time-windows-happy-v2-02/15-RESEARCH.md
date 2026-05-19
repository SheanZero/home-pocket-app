# Phase 15: Custom Time Windows (HAPPY-V2-02) - Research

**Researched:** 2026-05-19
**Domain:** AnalyticsScreen state model + use-case parameterization + i18n + Riverpod 3 session-scoped state
**Confidence:** HIGH (the codebase already exposes `(startDate, endDate)` through the DAO/repository surface; the change is concentrated in the application/presentation layers — no schema, no DAO, no new query patterns needed)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Selector Shape**
- **D-01:** Replace the AppBar month chip with a unified time-window chip. The current `MonthChipPicker` entry point should evolve into a chip that displays the active window label (current week, a month, a quarter, a year, or a custom date range).
- **D-02:** The bottom sheet first selects window type, then shows the type-specific chooser. Top of sheet exposes Week / Month / Quarter / Year / Custom; body changes to the matching list/picker.
- **D-03:** Custom range uses the system date-range picker. Do not build a custom in-sheet calendar/input control in Phase 15.
- **D-04:** Selection applies immediately. Week/month/quarter/year list selection applies and closes the sheet. Custom applies after the system date-range picker confirms a valid range.

**Date Boundary Semantics**
- **D-05:** Weeks start on Monday for all locales. Do not use locale-dependent week starts in Phase 15.
- **D-06:** Ranges are inclusive. The selected range means `startDate 00:00:00` through `endDate 23:59:59`, matching the current DAO/use-case style that includes `timestamp <= endDate`.
- **D-07:** Future dates are not selectable. Preset lists and custom ranges cap at today.
- **D-08:** Custom ranges longer than 12 months are rejected after selection with localized error copy. Do not silently crop. Do not rely on the date picker alone to enforce 12-month span — the locked behavior is that invalid ranges cannot apply and users receive a localized message.

**Metric Coverage**
- **D-09:** The selected window applies across the current AnalyticsScreen cards, with one explicit exception (D-10). Existing KPI, distribution, category, story, and family cards should use the active window once their providers/use cases are parameterized.
- **D-10:** The six-month trend card remains a rolling six-month trend. `TotalSixMonthCard` / `MonthlySpendTrendBarChart` does NOT become a window-granularity chart in Phase 15.
- **D-11:** FamilyInsightCard follows the active window, but remains aggregate-only. Must not add family-member rankings, member comparisons, family target semantics, or any other family-axis feature.
- **D-12:** HomeHero and Home tab prefetch/refresh do not follow the AnalyticsScreen window. HomeHero remains current-calendar-month anchored per ADR-016 §3 ring semantics.

### Claude's Discretion

- Exact widget/file naming (recommended direction: rename/replace `MonthChipPicker` only if it keeps tests clearer; avoid keeping misleading "month" names in new public APIs).
- Exact active-window state model (must be session-scoped Riverpod state analogous to `selectedMonthProvider`).
- Exact label text and ARB key names (subject to ja/zh/en parity and `DateFormatter`/`FormatterService` usage for date display).
- Exact retry/error placement for invalid custom ranges (must be localized and test-covered).
- Exact provider invalidation structure (provided HomeHero/Home tab providers are NOT coupled to the AnalyticsScreen window).

### Deferred Ideas (OUT OF SCOPE)

- Window-granularity trend chart (daily within week/custom, monthly within quarter/year). D-10 keeps the six-month trend card unchanged.
- Cross-period comparison labels such as "this quarter vs last quarter" — forbidden by ADR-012 §4.
- HomeHero awareness of the AnalyticsScreen selected window.
- Persisting the selected window across app restart — session-only in v1.2.
- Family member breakdowns, rankings, or family target semantics.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HAPPY-V2-02 | User can select custom time windows (week / month / quarter / year / arbitrary date range) for all Joy metrics, with the selection persisting per session. | The DAO/repository layer (`AnalyticsRepository`, `AnalyticsDao`) already exposes every aggregate as `(bookId, startDate, endDate)` — see § Standard Stack and § Architecture Patterns. The work is concentrated in (a) a new `TimeWindow` domain model + Riverpod provider, (b) parameter expansion of 5 application use cases from `(year, month)` to `(startDate, endDate)`, (c) provider re-keying, (d) chip + bottom sheet UI, (e) ARB additions for selector labels and invalid-range copy. HomeHero isolation is naturally enforced by the fact that `HomeScreen` builds with `DateTime.now()` and never reads `selectedMonthProvider`. |
</phase_requirements>

## Summary

Phase 15 is, at heart, a **parameter-expansion phase**. The Drift schema, the DAO query surface, and the `AnalyticsRepository` interface already speak `(startDate, endDate)` for every aggregate. What's still month-keyed is one layer up: five application use cases and their generated providers re-construct the date range internally from `(year, month)` parameters that the AnalyticsScreen passes in. Re-pointing the screen at a `TimeWindow` value object that resolves to `(startDate, endDate)` and threading those through the use cases — that's the bulk of the work.

The risky pieces are the three places where month-anchoring is *not* a pure parameter:
1. `MonthlyReport`, `HappinessReport`, `FamilyHappiness` (Freezed models) all bake `int year, int month` into their shape. Tests, fixtures, and downstream widgets read these fields. A `(start, end)` window doesn't fit cleanly. Recommended path: keep the `year/month` fields on these models populated from the *display anchor* (e.g., `endDate` for a custom range), or introduce parallel `*WindowReport` variants. The planner must decide; both options are real surgery that ripples into golden tests and ARB labels.
2. `expense_trend_use_case` is six-month rolling and stays month-anchored per D-10 — it follows the AnalyticsScreen's "anchor month", which today is `selectedMonthProvider`. After Phase 15, the trend card's anchor must be the *month containing* the active window's `endDate` (or a deliberate `selectedMonthProvider` survivor used only for the trend).
3. `analyticsKpiTotalLabel` literally reads "This month's spending" / "今月の支出" in three locales. When the window is a year or a custom range, this label is wrong. ARB updates are non-negotiable.

HomeHero isolation is already structurally correct: `HomeScreen` (`lib/features/home/presentation/screens/home_screen.dart` lines 49-52) reads `DateTime.now()` and passes `year, month` to `monthlyReportProvider`, `happinessReportProvider`, `bestJoyMomentProvider`, and `familyHappinessProvider` without ever reading `selectedMonthProvider`. The widget-test assertion is straightforward: pump HomeHero, change the AnalyticsScreen window state, assert HomeHero's providers were not invalidated/re-keyed.

The `>12 month` validation and `start <= end` validation belong in the use cases (HIGH-02 layering: the UI cannot reach the domain on its own) but the *user-facing rejection* (with localized error copy) must happen in presentation before the use case is even called — the use cases throw `ArgumentError` as a defense-in-depth.

**Primary recommendation:** Introduce a Freezed sealed `TimeWindow` (`Week`, `Month`, `Quarter`, `Year`, `Custom`) with a `range(now)` extension that returns `(DateTime startDate, DateTime endDate)`. Replace `selectedMonthProvider` with `selectedTimeWindowProvider` (session-scoped `@riverpod class`). Add an `(startDate, endDate)` overload to each of the 5 month-bound use cases. Convert the `MonthChipPicker` into a `TimeWindowChip` (or extend it) that opens a bottom sheet with type-then-chooser navigation per D-02. The trend card retains the legacy `anchor` pattern but derives its anchor from `window.endDate`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Time-window state (session-only) | Application/Presentation Riverpod provider | — | Session-scoped state lives in the presentation provider graph (analogous to existing `selectedMonthProvider`). Not persisted, so no Settings/Database involvement. |
| `TimeWindow` value object | Domain (`lib/features/analytics/domain/models/`) | — | Pure value type with `(start, end)` resolution. No infrastructure dependency. Follows Thin Feature rule (domain models are allowed in features). |
| `(startDate, endDate)` resolution from type + reference date | Domain (extension or method on `TimeWindow`) | — | Calendar math (ISO week, quarter boundary) is pure logic. Belongs next to the value object. |
| Range validation (`start <= end`, `≤ 12 months`, `≤ today`) | Application use case (`ArgumentError`) | Presentation (pre-invocation guard with localized error) | UI shows localized error; use case defends against bad input that bypasses UI (D-08). |
| Use-case parameterization `(year, month)` → `(startDate, endDate)` | Application (`lib/application/analytics/`) | — | The 5 use cases own the date-range fan-out into repository calls. |
| Aggregate queries `(bookId, startDate, endDate)` | Data (DAO + repository) | — | Already in place. Composite index `(bookId, timestamp)` exists. Zero changes needed. |
| Time-window chip + bottom sheet | Presentation widget | — | Replace/extend `MonthChipPicker`. |
| System date-range picker | Material framework (`showDateRangePicker`) | Presentation widget | `showDateRangePicker` is built into Flutter Material; `GlobalMaterialLocalizations` is already wired in `lib/main.dart` line 154. |
| Invalid-range localized error | Presentation (SnackBar/dialog) + ARB strings | — | i18n + UX combined. |
| Refresh invalidation | Presentation (AnalyticsScreen `_refresh`) | — | Must NOT invalidate HomeHero providers (different key set — different `year, month` than AnalyticsScreen's window). |
| HomeHero isolation guarantee | Presentation (HomeScreen uses `DateTime.now()`, not `selectedMonthProvider`) | — | Already structurally enforced; widget test must lock it. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_riverpod` | `^3.1.0` | Session-scoped `TimeWindow` state via `@riverpod class` with codegen. | `[VERIFIED: pubspec.yaml line 20]` Matches existing analytics provider style (`SelectedMonth` in `state_analytics.dart` line 11-27). |
| `riverpod_annotation` | `^4.0.0` | `@riverpod` annotation for code generation. | `[VERIFIED: pubspec.yaml line 21]` Used throughout the analytics module. |
| `riverpod_generator` | `^4.0.0+1` | Generates `.g.dart` provider boilerplate. | `[VERIFIED: pubspec.yaml line 83]` Build-runner output already exists for analytics. |
| `freezed` | `^3.0.0` | Sealed `TimeWindow` value object (with `Week`, `Month`, `Quarter`, `Year`, `Custom` variants). | `[VERIFIED: pubspec.yaml line 81]` Pattern matches existing `MetricResult<T>` sealed approach (`lib/features/analytics/domain/models/metric_result.dart` lines 16-29). Freezed gives copyWith + pattern matching + equality for free. |
| `intl` | `0.20.2` (EXACT PIN) | `DateFormat` for week/quarter/year labels. | `[VERIFIED: pubspec.yaml line 17, CLAUDE.md Pitfall #5]` Pinned by `flutter_localizations`; do NOT change. Supports `QQQ`/`QQQQ` quarter skeletons. `[CITED: pub.dev/documentation/intl/latest/intl/DateFormat-class.html]` |
| Material `showDateRangePicker` | Flutter SDK | Custom-range D-03 system picker. | `[VERIFIED: lib/main.dart lines 152-157]` `GlobalMaterialLocalizations.delegate` is already wired — `showDateRangePicker` will render localized for ja/zh/en out of the box. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `mocktail` | (existing) | Mock `AnalyticsRepository` in use-case tests. | Use-case unit tests for the new `(startDate, endDate)` signatures. Pattern: `class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}` per `test/unit/application/analytics/get_satisfaction_distribution_use_case_test.dart` lines 7. |
| `flutter_test` | Flutter SDK | Widget tests for the new selector + AnalyticsScreen invalidation. | Pattern follows `test/widget/features/analytics/presentation/widgets/month_chip_picker_test.dart`. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Freezed sealed `TimeWindow` | Plain sealed Dart class (like `MetricResult`) | Plain sealed is lighter (no codegen) but loses `copyWith` and `==`/`hashCode` for `Custom(start, end)` — for a presentation-state value compared via Riverpod equality, free `==` is worth the codegen cost. **Recommend Freezed.** |
| `@riverpod class TimeWindowNotifier` | `StateProvider<TimeWindow>` (legacy import) | `StateProvider` is in `flutter_riverpod/legacy.dart` per CLAUDE.md; the project's Riverpod 3 convention is `@riverpod class` (matches existing `SelectedMonth` notifier exactly). **Recommend `@riverpod class`.** |
| `showDateRangePicker` (Material) | `syncfusion_flutter_datepicker` / `omni_datetime_picker` | D-03 locks in the system picker. Material gives free i18n via `GlobalMaterialLocalizations` (already wired). **Recommend Material.** |
| Replacing `selectedMonthProvider` outright | Keeping `selectedMonthProvider` for the trend card, adding a new `selectedTimeWindowProvider` for everything else | The trend card (D-10) is *month-anchored* and uses `anchor: DateTime` today. If you delete `selectedMonthProvider`, the trend's anchor must be derived from `window.endDate`. Either works; the planner picks based on test fallout. **Recommend: delete `selectedMonthProvider`; trend reads `selectedTimeWindowProvider` and derives anchor = month containing `window.endDate`.** Cleaner provider graph. |

**Installation:** Nothing new to install. All packages are already in `pubspec.yaml`.

**Version verification:** `[VERIFIED: pubspec.yaml]`
- `flutter_riverpod: ^3.1.0` (line 20)
- `riverpod_annotation: ^4.0.0` (line 21)
- `freezed: ^3.0.0` (line 81)
- `riverpod_generator: ^4.0.0+1` (line 83)
- `intl: 0.20.2` (line 17, EXACT PIN per CLAUDE.md Pitfall #5)

## Package Legitimacy Audit

> Phase 15 introduces **zero** new external packages. All work uses libraries already in `pubspec.yaml` and Flutter SDK built-ins. Slopcheck not applicable.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| (none) | — | — | — | — | — | No new packages |

## Architecture Patterns

### System Architecture Diagram

```
                       ┌─────────────────────────────────┐
                       │   User taps time-window chip    │
                       └──────────────┬──────────────────┘
                                      │
                                      ▼
                       ┌─────────────────────────────────┐
                       │  Bottom Sheet (D-02)            │
                       │  ┌───────────────────────────┐  │
                       │  │ Type row: W / M / Q / Y / │  │
                       │  │           Custom          │  │
                       │  └───────────┬───────────────┘  │
                       │              │                  │
                       │   ┌──────────┼──────────┐       │
                       │   ▼          ▼          ▼       │
                       │  Week     Month      Custom →   │  showDateRangePicker
                       │  list     list       …          │  (Material, localized)
                       └───────┬─────────────────────────┘
                               │ user picks (D-04 immediate apply)
                               ▼
                       ┌─────────────────────────────────┐
                       │  Validate                       │
                       │  (a) start ≤ end                │
                       │  (b) end ≤ today (D-07)         │
                       │  (c) span ≤ 12 months (D-08)    │
                       └───┬─────────────────────────┬───┘
                           │ valid                   │ invalid
                           ▼                         ▼
                ┌──────────────────────────┐  ┌────────────────────────┐
                │ selectedTimeWindow       │  │ Localized error        │
                │   .setWindow(window)     │  │ (SnackBar / dialog)    │
                └───────────┬──────────────┘  │ — sheet stays open or  │
                            │                 │   reopens on tap       │
                            ▼                 └────────────────────────┘
            ┌─────────────────────────────────────────────────────┐
            │ Window key change cascades into Riverpod providers   │
            │ keyed on (bookId, startDate, endDate, currencyCode?) │
            └─────────────────────────────────────────────────────┘
                            │
                            ▼
       ┌──────────────────────────────────────────────────────────┐
       │ Use cases (5 of them):                                    │
       │  • GetMonthlyReportUseCase        ── (start, end) ──→     │
       │  • GetHappinessReportUseCase      ── (start, end) ──→     │
       │  • GetSatisfactionDistribution    ── (start, end) ──→     │
       │  • GetBestJoyMomentUseCase        ── (start, end) ──→     │
       │  • GetLargestMonthlyExpenseUseCase ─ (start, end) ──→     │
       │  • GetFamilyHappinessUseCase      ── (start, end) ──→ D-11│
       │                                                           │
       │  GetExpenseTrendUseCase           ── month anchor ──→ D-10│
       └──────────────────────────────────────────────────────────┘
                            │
                            ▼
       ┌──────────────────────────────────────────────────────────┐
       │ AnalyticsRepository (unchanged surface)                   │
       │   getMonthlyTotals(bookId, startDate, endDate)            │
       │   getCategoryTotals(...) / getDailyTotals(...)            │
       │   getLedgerTotals(...) / getSoulSatisfactionOverview(...) │
       │   getSatisfactionDistribution(...) / getBestJoyMoment(...)│
       │   getSoulRowsForJoyContribution(...)                      │
       │   getSharedJoyCategoryInsight(...)                        │
       │   getLargestMonthlyExpense(...)                           │
       └──────────────────────────────────────────────────────────┘
                            │
                            ▼
       ┌──────────────────────────────────────────────────────────┐
       │ AnalyticsDao (Drift) — already (startDate, endDate)       │
       │   `WHERE timestamp >= ? AND timestamp <= ?`               │
       │   Composite index (book_id, timestamp) handles year scans │
       └──────────────────────────────────────────────────────────┘

       ▲ Boundary ▲
       │
       │ HomeScreen (lib/features/home/presentation/screens/home_screen.dart):
       │   uses DateTime.now() year/month, NOT selectedTimeWindow.
       │   HomeHero ring stays month-anchored per ADR-016 §3.
       │
```

### Component Responsibilities

| File (recommended) | Layer | Responsibility |
|--------------------|-------|----------------|
| `lib/features/analytics/domain/models/time_window.dart` | Domain | `TimeWindow` Freezed sealed (`Week`, `Month`, `Quarter`, `Year`, `Custom`). Pure value type. |
| `lib/features/analytics/domain/models/time_window.dart` (extension) | Domain | `TimeWindow.range(DateTime reference)` → `(DateTime startDate, DateTime endDate)`. ISO-week-Monday calendar math. |
| `lib/features/analytics/presentation/providers/state_time_window.dart` | Presentation | `@riverpod class SelectedTimeWindow extends _$SelectedTimeWindow` — session-scoped, default = `TimeWindow.month(DateTime.now())`. Replaces `selectedMonthProvider`. |
| `lib/features/analytics/presentation/widgets/time_window_chip.dart` | Presentation | Chip widget (replaces or extends `MonthChipPicker`). Reads `selectedTimeWindowProvider`, displays formatted label, opens the type-then-chooser bottom sheet. |
| `lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart` | Presentation | The bottom-sheet content with type row + body chooser (D-02). Calls `showDateRangePicker` for Custom (D-03). |
| `lib/application/analytics/get_*_use_case.dart` (5 files) | Application | Add `(startDate, endDate)` overload alongside the existing `(year, month)` signature, OR replace the signature (planner decides — see Pitfall #1 below). |
| `lib/features/analytics/presentation/providers/state_analytics.dart` + `state_happiness.dart` | Presentation | Re-key providers from `(year, month)` to `(startDate, endDate)`. Family + monthly + satisfaction + best-joy + largest-expense — five providers re-keyed. `expenseTrendProvider` keeps the `anchor` pattern (D-10). |
| `lib/features/analytics/presentation/screens/analytics_screen.dart` | Presentation | Read `selectedTimeWindowProvider`, derive `(startDate, endDate)`, pass to all cards, derive `anchor` for the trend card from the window's endDate-month. Update `_refresh` to invalidate windowed providers. |
| `lib/l10n/app_{en,ja,zh}.arb` | i18n | New keys: window-type labels, selector tooltip, range labels for chip/sheet, invalid-range error, week-range / quarter / year display copy. Update `analyticsKpiTotalLabel` away from "This month's spending". |

### Recommended Project Structure
```
lib/
├── application/
│   └── analytics/
│       ├── get_monthly_report_use_case.dart        # updated: (startDate, endDate)
│       ├── get_happiness_report_use_case.dart      # updated
│       ├── get_satisfaction_distribution_use_case.dart  # updated
│       ├── get_best_joy_moment_use_case.dart       # updated
│       ├── get_largest_monthly_expense_use_case.dart  # updated
│       ├── get_family_happiness_use_case.dart      # updated (D-11 aggregate-only)
│       └── get_expense_trend_use_case.dart         # UNCHANGED (D-10)
├── features/
│   └── analytics/
│       ├── domain/
│       │   └── models/
│       │       └── time_window.dart                # NEW Freezed sealed
│       └── presentation/
│           ├── providers/
│           │   ├── state_analytics.dart            # selectedMonthProvider → selectedTimeWindowProvider
│           │   ├── state_happiness.dart            # re-keyed providers
│           │   └── state_time_window.dart          # NEW (or merge into state_analytics)
│           ├── widgets/
│           │   ├── time_window_chip.dart           # NEW (or rename month_chip_picker.dart)
│           │   └── time_window_picker_sheet.dart   # NEW
│           └── screens/
│               └── analytics_screen.dart           # updated: window-driven
└── l10n/
    ├── app_en.arb                                  # +window labels, error, updated KPI label
    ├── app_ja.arb                                  # parity
    └── app_zh.arb                                  # parity
```

### Pattern 1: Freezed sealed value object with `(start, end)` resolution

**What:** `TimeWindow` is the abstract value type the UI selects. A pure-function method resolves it to a concrete `(startDate, endDate)` pair against a reference date (typically `DateTime.now()` for "this week / this month / this quarter / this year" and `endDate` for `Custom`).

**When to use:** Anywhere the AnalyticsScreen surface needs to express the active window without hardcoding which kind it is.

**Example (illustrative — not generated code):**
```dart
// Source: pattern matches lib/features/analytics/domain/models/metric_result.dart
// and CLAUDE.md Riverpod 3 conventions (Freezed @freezed sealed).
import 'package:freezed_annotation/freezed_annotation.dart';
part 'time_window.freezed.dart';

@freezed
sealed class TimeWindow with _$TimeWindow {
  /// ISO week starting Monday (D-05).
  const factory TimeWindow.week({required DateTime mondayStart}) = WeekWindow;
  /// Calendar month.
  const factory TimeWindow.month({required int year, required int month}) = MonthWindow;
  /// Calendar quarter (1..4).
  const factory TimeWindow.quarter({required int year, required int quarter}) = QuarterWindow;
  /// Calendar year.
  const factory TimeWindow.year({required int year}) = YearWindow;
  /// User-picked arbitrary range; both dates date-only.
  const factory TimeWindow.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) = CustomWindow;
}

extension TimeWindowRange on TimeWindow {
  /// D-06 inclusive: (start 00:00:00, end 23:59:59).
  ({DateTime start, DateTime end}) get range => switch (this) {
        WeekWindow(:final mondayStart) => (
            start: DateTime(mondayStart.year, mondayStart.month, mondayStart.day),
            end:   DateTime(mondayStart.year, mondayStart.month,
                            mondayStart.day + 6, 23, 59, 59),
          ),
        MonthWindow(:final year, :final month) => (
            start: DateTime(year, month, 1),
            end:   DateTime(year, month + 1, 0, 23, 59, 59),
          ),
        QuarterWindow(:final year, :final quarter) => (
            start: DateTime(year, (quarter - 1) * 3 + 1, 1),
            end:   DateTime(year, quarter * 3 + 1, 0, 23, 59, 59),
          ),
        YearWindow(:final year) => (
            start: DateTime(year, 1, 1),
            end:   DateTime(year, 12, 31, 23, 59, 59),
          ),
        CustomWindow(:final startDate, :final endDate) => (
            start: DateTime(startDate.year, startDate.month, startDate.day),
            end:   DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
          ),
      };
}
```

**Note:** Use `Duration(days: N)` cautiously around DST — Japan/China don't observe DST and the project supports ja/zh/en; the math above sidesteps DST entirely by reconstructing `DateTime` from components. `[ASSUMED]` — verify with tests against the three supported locales.

### Pattern 2: Session-scoped Riverpod 3 notifier (matches `SelectedMonth`)

**What:** A `@riverpod class` whose `build()` returns the default window. The notifier exposes `setWindow(TimeWindow w)` (and optionally `setMonth/setWeek/etc.` convenience setters). NOT `keepAlive: true` — auto-dispose is fine; session-only persistence is "the app process stays alive", and the AnalyticsScreen keeps the provider alive while it's mounted.

**When to use:** This is the canonical pattern for session-only UI state in this codebase.

**Example:**
```dart
// Source: matches lib/features/analytics/presentation/providers/state_analytics.dart
// lines 11-27 (SelectedMonth) exactly.
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

**Pitfall (per CLAUDE.md):** `@riverpod class SelectedTimeWindow` generates `selectedTimeWindowProvider` (the `Notifier` suffix is NOT stripped here — there's no `Notifier` suffix on this class name). Compare: `LocaleNotifier` → `localeProvider` (suffix stripped). Naming the class `SelectedTimeWindow` (not `SelectedTimeWindowNotifier`) keeps the generated provider name predictable.

### Pattern 3: Use-case `(year, month)` → `(startDate, endDate)` migration

**What:** Replace the input parameters of the five month-bound use cases. Inside the use case, the same date-range math already exists — just lift the inputs.

**When to use:** Five files in `lib/application/analytics/`.

**Example (before / after, illustrative):**
```dart
// BEFORE — lib/application/analytics/get_satisfaction_distribution_use_case.dart
Future<List<SatisfactionScoreBucket>> execute({
  required String bookId,
  required int year,
  required int month,
}) {
  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
  return _repo.getSatisfactionDistribution(
    bookId: bookId, startDate: startDate, endDate: endDate);
}

// AFTER
Future<List<SatisfactionScoreBucket>> execute({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) {
  _validateWindow(startDate, endDate);
  return _repo.getSatisfactionDistribution(
    bookId: bookId, startDate: startDate, endDate: endDate);
}

void _validateWindow(DateTime start, DateTime end) {
  if (start.isAfter(end)) {
    throw ArgumentError.value(
        (start, end), 'window', 'startDate must be <= endDate');
  }
  final spanDays = end.difference(start).inDays;
  if (spanDays > 366) {  // 12 months ≤ 366 days (leap year)
    throw ArgumentError.value(
        (start, end), 'window', 'window must not exceed 12 months');
  }
}
```

**Validation duplication note:** The same `_validateWindow` lives in five use cases. Extract to a shared helper (e.g., `lib/application/analytics/_time_window_validation.dart`, private to the analytics application module) so the contract is single-sourced. Don't put it in domain — Domain shouldn't throw `ArgumentError`.

### Pattern 4: Per-card `AsyncValue.when` isolation (preserved)

**What:** Existing AnalyticsScreen pattern. One failing windowed provider must not blank the page.

**When to use:** All re-keyed providers retain this pattern (see `analytics_screen.dart` lines 220-249 for `_KpiHero`'s nested `.when`).

**Preserve:** Each card's error retry callback must invalidate the *windowed* provider key, not a stale month-keyed one. This is mechanical but easy to forget.

### Anti-Patterns to Avoid

- **Don't widen `selectedMonthProvider` semantically.** Keep its name accurate or replace it entirely. A `selectedMonthProvider` that secretly carries a year-wide window misleads every future reader. **Recommended: delete and replace with `selectedTimeWindowProvider`.**
- **Don't put validation only in the UI.** D-08 is a contract, not a UX nicety; if the use case is invoked from somewhere else (e.g., a test, a future deep link, a debug action), the contract must hold. Use case throws `ArgumentError`; UI shows localized SnackBar.
- **Don't add cross-period comparison surfaces.** ADR-012 §4 + ADR-016 §3 forbid them. No "vs last quarter" labels, no delta arrows in chip copy, no "compared to" widgets. Phase 15 success criterion #5 makes this a widget-test invariant.
- **Don't conflate the trend anchor with the analytics window.** D-10 keeps the trend on a six-month rolling anchor. Resist the urge to "naturally" extend the trend to span the window — that's the deferred work mentioned in CONTEXT.md.
- **Don't change `MonthlyReport.year`/`MonthlyReport.month` semantics silently.** When the window is a year, what value goes into `MonthlyReport.year/month`? Either keep them as "display anchor" (endDate-month) and document it, or introduce a separate `WindowReport`. Pick deliberately; surface in PLAN.md.
- **Don't reach into `lib/infrastructure/` directly from a feature widget.** Use `FormatterService` (which delegates to `DateFormatter`) — see `lib/application/i18n/formatter_service.dart`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| ISO week boundary math | A custom "compute Monday of week" function from scratch | `intl 0.20.2` `DateFormat('w', locale)` for week-of-year display + simple `DateTime` subtraction `now - Duration(days: (weekday - 1) % 7)` for Monday | Custom implementations break around year boundaries and ISO-week-53 edge cases. `intl` handles the formatting; the Monday calc is one line. |
| Date-range UI picker | A custom in-sheet calendar grid | `showDateRangePicker` (Material) | D-03 locks the system picker. Material's localization auto-flows via `GlobalMaterialLocalizations` (already wired). Building a calendar is weeks of work for zero value. |
| Quarter label formatting | String literal `'Q${quarter}'` | `DateFormat.QQQ(locale.toString()).format(DateTime(year, (q-1)*3 + 1))` | `DateFormat` supports `QQQ` (abbreviated) and `QQQQ` (full quarter) skeletons. `[CITED: pub.dev/documentation/intl/latest/intl/DateFormat-class.html]` Auto-localizes. |
| 12-month span check | `endDate.difference(startDate).inDays > 365` (BUG — leap years) | `endDate.difference(startDate).inDays > 366` OR explicit calendar math: `(end.year - start.year) * 12 + (end.month - start.month) > 12` | The `inDays` route is off-by-one across leap years. The calendar-month route is exact. Recommend calendar-month. |
| Riverpod state model | `StateProvider<TimeWindow>` (legacy) | `@riverpod class` (codegen) | CLAUDE.md Riverpod 3 convention — codegen is the standard pattern in this codebase. |
| Time-window value object | `Map<String, dynamic>` or tuple `(String type, DateTime, DateTime)` | Freezed sealed class | Freezed gives `==`/`hashCode` automatically — critical for Riverpod cache keys. Tuples don't provide pattern-match exhaustiveness. |

**Key insight:** Phase 15's surface area is *parameter expansion*, not new capability. Every "domain" listed above already has a battle-tested solution in the codebase or Flutter SDK.

## Runtime State Inventory

> Phase 15 is a feature addition (not a rename/refactor/migration). This section is **SKIPPED**: no stored data, no live service config, no OS-registered state changes. The selected window is session-only by D-04/D-12, and explicitly does NOT persist (no Settings row, no Drift table). Nothing in the build artifact or secrets domain.

## Common Pitfalls

### Pitfall 1: `year`/`month` baked into `MonthlyReport` / `HappinessReport` / `FamilyHappiness`
**What goes wrong:** When the active window is "this year" or a custom range, these models still carry `int year, int month` as required Freezed fields. Tests, fixtures, and widgets that read `report.year`, `report.month` will silently take a stale value (or a fudged one) when the window is broader than a month.

**Why it happens:** Phases 9-14 evolved these models incrementally under a month-only assumption. They're contractually `(year, month)` aggregates, not window aggregates.

**How to avoid:** The planner must decide (and lock in PLAN.md):
- **Option A — Display-anchor convention:** `report.year, report.month` is the month containing `endDate`. Document in dartdoc. Update fixtures. Tag stale uses with TODO. *Lower risk; existing widget tests mostly survive.*
- **Option B — Parallel `*WindowReport` types:** Introduce `WindowReport`, `WindowHappinessReport`, `WindowFamilyHappiness` Freezed variants without `year/month`. Use cases return new types when called with a window; old `(year, month)` path stays for HomeHero. *Cleaner but doubles the surface; many widget tests/goldens need update.*

**Warning signs:** Widget tests blow up when fixtures pass `year: 2026, month: 6` but the window is `TimeWindow.year(2026)`. A "today's spending" label shows `今月` ("this month") for a yearly window.

### Pitfall 2: AnalyticsScreen `_refresh` invalidates wrong keys after re-keying
**What goes wrong:** `_refresh` in `analytics_screen.dart` (lines 150-188) currently invalidates providers keyed by `(bookId, year, month)`. After re-keying to `(bookId, startDate, endDate)`, the old keys are dead. Worse, `monthlyReportProvider(bookId: ..., year: ..., month: ...)` (if kept as a back-compat overload) would silently coexist with the new windowed key, and a pull-to-refresh would invalidate the wrong one.

**Why it happens:** Provider family keys are part of the `==` identity — change the arg shape, you change the key.

**How to avoid:** Make the provider rename atomic with the use-case rename. Update `_refresh` in the same commit. Add a widget test that asserts `_refresh` invalidates the *windowed* provider (e.g., via a mock that records `read` calls before and after).

### Pitfall 3: HomeHero accidentally couples to `selectedTimeWindowProvider`
**What goes wrong:** Someone refactors `home_screen.dart` to "deduplicate" the `year, month` derivation and reaches for `selectedTimeWindowProvider`. HomeHero now follows the AnalyticsScreen window. D-12 / ADR-016 §3 violated.

**Why it happens:** Tempting deduplication. Both screens use month-bound providers.

**How to avoid:** Locking test (success criterion #3):
```dart
// pseudocode
testWidgets('HomeHero ring stays current-calendar-month after analytics window change', (t) async {
  // arrange: pump app with mock providers, current month = 2026-05.
  // act: change selectedTimeWindowProvider → TimeWindow.year(2024).
  // assert: HomeHero's monthlyReport / happinessReport providers were read
  //         with year=2026, month=05 — NOT with the 2024 window.
});
```
Add a static-grep guard or an `import_guard` rule: HomeScreen MUST NOT import `state_time_window.dart`.

### Pitfall 4: `intl` 0.20.2 ISO week behavior
**What goes wrong:** `intl 0.20.2` does support `'w'` (week of year) and `'W'` (week of month) skeletons but its week-numbering rules are locale-dependent in the underlying CLDR data. D-05 forces Monday-anchored weeks across all locales, but `DateFormat('w').format(...)` may still return locale-dependent week numbers.

**Why it happens:** ISO 8601 weeks always start Monday; CLDR localized weeks may start Sunday/Saturday by locale.

**How to avoid:** For *labels*, prefer `"Week of ${shortDate(monday)}"` (date-anchored, unambiguous, follows D-05) instead of a week number. Use `DateFormatter.formatShortMonthDay` (already in `lib/infrastructure/i18n/formatters/date_formatter.dart` line 43) to render the Monday-of-week, then build the label via ARB placeholder.

**Open question:** Should the chip read `2026 Week of 5/13` (Monday-anchored) or `Week 20, 2026` (numeric)? Date-anchored is unambiguous and CLDR-independent. The planner picks. `[ASSUMED]` — verify with three-locale designs.

### Pitfall 5: 12-month span check off-by-one
**What goes wrong:** `endDate.difference(startDate).inDays > 365` rejects a range that's exactly 12 months across a non-leap year — but accepts 13 months minus one day. `> 366` flips the other way. Calendar-month math is the only exact route.

**How to avoid:**
```dart
bool exceedsTwelveMonths(DateTime start, DateTime end) {
  final months = (end.year - start.year) * 12 + (end.month - start.month);
  if (months > 12) return true;
  if (months == 12 && end.day > start.day) return true;
  return false;
}
```
Unit-test against 12-month edge cases (Jan 1 → Dec 31, Jan 1 → Jan 1 next year, Feb 29 → Feb 28, etc.).

### Pitfall 6: `analyticsKpiTotalLabel` localized as "this month"
**What goes wrong:** The TotalSpendingKpiTile reads `l10n.analyticsKpiTotalLabel` which is `'This month's spending'` / `'今月の支出'` / `'本月支出'`. For yearly/custom windows, the label is wrong.

**How to avoid:** Either (a) generalize the key to `analyticsKpiTotalLabelGeneric` ("Total spending" / "支出合計" / "支出合计") and adopt it screen-wide, or (b) introduce window-aware copy via a placeholder. The simpler path is (a). ARB ja/zh/en parity required.

### Pitfall 7: `expense_trend` rolling-six-month anchor when the window is yearly
**What goes wrong:** Today, `expenseTrendProvider(bookId, anchor: selectedMonth)` uses `selectedMonthProvider`'s value as the anchor. After Phase 15 removes `selectedMonthProvider`, the trend has no anchor.

**How to avoid:** Derive the anchor from `window.endDate`'s month: `DateTime(window.endDate.year, window.endDate.month)`. Document this in the trend card's caption ARB string (or accept that yearly window → trend shows the last six months ending at year-end-month). The trend card caption currently says "BarChart · current month highlighted" — verify the highlight logic still does what's expected; tests cover this in `monthly_spend_trend_bar_chart_test.dart`.

### Pitfall 8: Drift query performance on year-wide windows
**What goes wrong:** A yearly window scans 12× more rows than a monthly window. UI jank if the scan isn't index-served.

**Reality check:** The composite index `idx_tx_book_timestamp` on `(book_id, timestamp)` already exists (`lib/data/tables/transactions_table.dart` line 50). All windowed queries use `WHERE book_id = ? AND timestamp >= ? AND timestamp <= ?`, which is an index range scan — O(log n + result). Typical per-month soul-tx count is 10-100 per `get_happiness_report_use_case.dart` comment (line 376-377), so yearly is 120-1200 rows. Negligible.

**How to avoid:** No action required. Add a perf-budget test if paranoid (run a year-wide aggregate against a seeded 10k-tx database, assert < 200ms on simulator).

### Pitfall 9: `intl 0.20.2` pin must be respected
**What goes wrong:** Tempting to bump `intl` to get cleaner `QQQQ` formatting or newer skeleton support. Breaks `flutter_localizations`. `pub get` fails or runtime errors appear.

**How to avoid:** Per CLAUDE.md Pitfall #5 and `pubspec.yaml` line 17: `intl` is **exact-pinned at 0.20.2**. Do not change. All needed formats (`QQQ`, `QQQQ`, `MMMM yyyy`, `yyyy年M月`) exist in 0.20.2.

### Pitfall 10: Provider rename = generated file regen
**What goes wrong:** Rename `SelectedMonth` to `SelectedTimeWindow`, forget to run `build_runner`. `selectedTimeWindowProvider` doesn't exist; old `selectedMonthProvider` still in `.g.dart`. Compile error or stale runtime.

**How to avoid:** Per CLAUDE.md Pitfall #3 + #13: `flutter pub run build_runner build --delete-conflicting-outputs` after any provider rename. CI guardrail AUDIT-10 catches stale generated files. Plan a single "build_runner" task in PLAN.md immediately after each round of `@riverpod`/`@freezed` annotations land.

## Code Examples

Verified patterns from existing code.

### Existing canonical session-scoped provider (template to follow)
```dart
// Source: lib/features/analytics/presentation/providers/state_analytics.dart
// lines 11-27 (SelectedMonth) — current month-anchored implementation that
// the new SelectedTimeWindow notifier should mirror in shape.
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

### Existing AnalyticsScreen window-derivation pattern (to be replaced)
```dart
// Source: lib/features/analytics/presentation/screens/analytics_screen.dart
// lines 37-39 — month derivation that the new code replaces with TimeWindow.range.
final selected = ref.watch(selectedMonthProvider);
final year = selected.year;
final month = selected.month;
```

### Existing month-bound use case (to be parameter-expanded)
```dart
// Source: lib/application/analytics/get_satisfaction_distribution_use_case.dart
// lines 12-25 — the entire body becomes (startDate, endDate) with validation.
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

### Existing use-case test pattern (template for new windowed tests)
```dart
// Source: test/unit/application/analytics/get_satisfaction_distribution_use_case_test.dart
class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late _MockAnalyticsRepository repository;
  late GetSatisfactionDistributionUseCase useCase;

  final startDate = DateTime(2026, 5);
  final endDate = DateTime(2026, 5, 31, 23, 59, 59);

  setUp(() {
    repository = _MockAnalyticsRepository();
    useCase = GetSatisfactionDistributionUseCase(analyticsRepository: repository);
  });

  test('uses selected month boundaries', () async {
    when(() => repository.getSatisfactionDistribution(
        bookId: 'book-1', startDate: startDate, endDate: endDate))
        .thenAnswer((_) async => const []);
    await useCase.execute(bookId: 'book-1', year: 2026, month: 5);
    verify(() => repository.getSatisfactionDistribution(
        bookId: 'book-1', startDate: startDate, endDate: endDate)).called(1);
  });
}
```

### Existing AnalyticsScreen `_refresh` (to be re-keyed)
```dart
// Source: lib/features/analytics/presentation/screens/analytics_screen.dart
// lines 150-188 — every `invalidate` call's key changes from (year, month)
// to (startDate, endDate) after the use-case migration.
void _refresh(WidgetRef ref, {required DateTime selected, ...}) {
  final year = selected.year;
  final month = selected.month;
  ref.invalidate(monthlyReportProvider(bookId: bookId, year: year, month: month));
  ref.invalidate(expenseTrendProvider(bookId: bookId, anchor: selected));
  // ... 5 more invalidate calls keyed on (year, month)
}
```

### MonthChipPicker bottom-sheet pattern (template for the new sheet)
```dart
// Source: lib/features/analytics/presentation/widgets/month_chip_picker.dart
// lines 80-115 — the bottom-sheet flow already follows D-04 immediate-apply.
Future<void> _openPicker(BuildContext context, WidgetRef ref, DateTime selected) async {
  final picked = await showModalBottomSheet<DateTime>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final month in months.reversed)
            ListTile(
              title: Text(const FormatterService().formatMonthYear(month, locale)),
              selected: _sameMonth(month, selected),
              onTap: () => Navigator.of(sheetContext).pop(month),
            ),
        ],
      ),
    ),
  );
  if (picked != null) {
    ref.read(selectedMonthProvider.notifier).setMonth(picked);
  }
}
```

### `DateFormatter` extension pattern (for new week / quarter / year labels)
```dart
// Source: lib/infrastructure/i18n/formatters/date_formatter.dart lines 32-52
// Existing locale-switching pattern. New methods to add: formatWeekRange,
// formatQuarter, formatYear (or wire via FormatterService).
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

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Riverpod 2 `StateNotifier` + `StateNotifierProvider` | Riverpod 3 `@riverpod class` + codegen | Project migrated to Riverpod 3.1 with the v1.2 milestone | All new providers in this phase use `@riverpod`. Do NOT import from `flutter_riverpod/legacy.dart`. |
| Density (Joy/¥) as Analytics primary KPI | `Σ joy_contribution` (cumulative absolute) | Phase 13/14 (ADR-016) | Phase 15 inherits the cumulative metric — windowed cumulative is meaningful (a year shows full-year cumulative). |
| AnalyticsScreen Variant δ (2-region) | AnalyticsScreen Variant ε (Time / Distribution / Stories sections + KPI mini-hero) | Phase 14 | Phase 15 keeps Variant ε layout; only the chip + data fan-out change. |
| `MonthChipPicker` with hardcoded "Pick a month" tooltip | TBD — `TimeWindowChip` with window-aware label and tooltip | Phase 15 | This phase. |

**Deprecated/outdated:**
- `selectedMonthProvider` (in `state_analytics.dart`): if the recommended approach is taken, this provider is removed. The trend card derives its anchor from `selectedTimeWindowProvider`.
- `analyticsKpiTotalLabel` = "This month's spending": rename or generalize.
- `analyticsMonthChipPickerTooltip` = "Pick a month": rename to `analyticsTimeWindowChipTooltip` and update copy.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ISO week labels should be date-anchored ("Week of May 13") not numeric ("Week 20") — based on D-05 + i18n unambiguity. | Pitfall #4, Pattern 1 | If user expectation is numeric week numbers, the chip label is unidiomatic in certain locales. Mitigation: surface in plan-phase as an ARB-copy question. |
| A2 | Quarter labels use `intl` `QQQ`/`QQQQ` skeletons; ja/zh formats may look odd ("第1四半期" / "第一季度"). | Don't Hand-Roll, Pattern 1 | Quarter labels may need ARB overrides rather than raw CLDR. Mitigation: render a sample in all 3 locales during plan-phase. |
| A3 | The 12-month span limit should use calendar-month math (D-08), not `Duration(days: 366)`, to avoid leap-year off-by-one. | Pitfall #5, Don't Hand-Roll | Off-by-one accepts/rejects boundary ranges incorrectly. Mitigation: explicit unit tests on boundary days. |
| A4 | Replacing `selectedMonthProvider` entirely (vs. keeping it for the trend card) is cleaner and aligns with the "Don't widen semantically" anti-pattern. | Standard Stack §Alternatives, Pitfall #7 | Existing widget tests / fixtures keyed on `selectedMonthProvider` need rewrite. Mitigation: the planner can decide; both approaches are workable. |
| A5 | `MonthlyReport.year / MonthlyReport.month` for non-month windows should be the "display anchor" = month containing `endDate`. | Pitfall #1 | If goldens / story-card formatters consume these fields literally ("for May 2026"), the label is wrong for yearly windows. Mitigation: planner picks Option A vs B explicitly. |
| A6 | `showDateRangePicker` (Material) is the correct system picker for D-03 — it is bundled with Flutter SDK, no package install needed, and is already i18n-wired via `GlobalMaterialLocalizations` in `lib/main.dart` line 154. | Standard Stack | If `showDateRangePicker` has UX issues in any of ja/zh/en that fail design review, fallback is `showDatePicker` ×2. Mitigation: spike in plan-phase, render on simulator in all three locales. |
| A7 | The selected window persists across `Navigator.push` (e.g., tapping into a story card and returning) because the provider stays alive while the AnalyticsScreen is in the widget tree. NOT `keepAlive: true`. | Pattern 2, "session persistence" interpretation | If "session" means "across tab switches in MainShellScreen" and the tab swap disposes AnalyticsScreen, the window resets. Mitigation: depends on how MainShellScreen routes — if `IndexedStack` (keep alive) it's fine; if `PageView` with discard, you need `@Riverpod(keepAlive: true)`. The planner must check. |
| A8 | "Best Joy" widget tests can absorb the new `(startDate, endDate)` provider key without golden changes — the card displays merchant/category/satisfaction, not the date window itself. | Component Responsibilities | If any widget test exercises `find.text('May 2026')` for a date in the story card, it breaks. Mitigation: grep test files for hardcoded month names. |

## Open Questions (RESOLVED)

1. **`MonthlyReport.year`/`MonthlyReport.month` — Option A or Option B?**
   - What we know: Both fields are required in the Freezed model. Pitfall #1 lays out the trade-offs.
   - What's unclear: Whether downstream widgets (KPI tile, donut, daily expenses) consume `report.year/month` for display vs. just for cache keys.
   - Recommendation: Plan-phase grep for `report.year`, `report.month`, `monthly.year`, `monthly.month`. If only cache-key uses, pick **Option A (display-anchor)**. If any text/label uses, pick **Option B (parallel WindowReport)** — clean separation worth the cost.
   - **RESOLVED:** Option A (display-anchor). MonthlyReport.year/month = month containing `endDate`. Locked in Plan 03 Task 1 (use-case rewrite) + Plan 04 Task 2 (`_emptyFamilyHappiness` uses display-anchor consistently).

2. **Should we replace `selectedMonthProvider` entirely, or keep it for the trend card only?**
   - What we know: D-10 keeps the trend card month-anchored. D-12 keeps HomeHero month-anchored (but HomeHero uses `DateTime.now()`, not `selectedMonthProvider`).
   - What's unclear: After replacement, does the trend card derive anchor from `selectedTimeWindowProvider`? Or do we keep `selectedMonthProvider` as a separate orthogonal state?
   - Recommendation: **Replace `selectedMonthProvider` entirely.** Trend card derives anchor from `window.endDate.year/month`. One source of truth.
   - **RESOLVED:** Replace entirely. `selectedMonthProvider` deleted in Plan 04 Task 1; trend card derives `trendAnchor = DateTime(endDate.year, endDate.month)` in Plan 06 Task 1 from the active `selectedTimeWindowProvider`.

3. **Week label format — date-anchored or numeric?**
   - What we know: D-05 forces Monday-start, but says nothing about display.
   - What's unclear: User expectation for week display in ja/zh.
   - Recommendation: Default to date-anchored ("Week of 5/13" / "5月13日の週" / "5月13日的一周") for CLDR-independent unambiguity. Surface in discuss-phase-15 retrospective or absorb as planner discretion per CONTEXT.md.
   - **RESOLVED:** Date-anchored via ARB key `analyticsTimeWindowChipLabelWeek({monday})` where the placeholder is composed from `FormatterService.formatShortMonthDay(mondayStart, locale)`. Locked in Plan 01 (ARB key definitions) + Plan 05 Task 2 (TimeWindowChip switch arm for WeekWindow).

4. **Tab-switch behavior — does the window survive AnalyticsScreen unmount?**
   - What we know: HomeScreen, AnalyticsScreen, etc. are tabs in `MainShellScreen`.
   - What's unclear: Whether the shell keeps all tabs alive (IndexedStack) or rebuilds (PageView with discard).
   - Recommendation: Grep `MainShellScreen` for `IndexedStack` vs `PageView`. If the latter, add `@Riverpod(keepAlive: true)` to `SelectedTimeWindow` so the window survives a quick "Home → Stats → Home → Stats" round-trip. *Either way, the window MUST NOT persist across app restart.*
   - **RESOLVED:** `MainShellScreen` uses `IndexedStack` (line 85, verified during planning). `SelectedTimeWindow` uses default auto-dispose — NO `@Riverpod(keepAlive: true)` annotation. Locked in Plan 04 Task 1 acceptance criteria.

5. **Custom-range error UX — SnackBar, dialog, or in-sheet?**
   - What we know: D-08 demands localized error copy, planner discretion on placement.
   - What's unclear: Which surface is least disruptive.
   - Recommendation: SnackBar with "OK" action that reopens the sheet. Lighter than a dialog. Test coverage straightforward.
   - **RESOLVED:** SnackBar via `ScaffoldMessenger.of(sheetContext).showSnackBar(...)`, ARB-keyed copy (`analyticsTimeWindowErrorInverted` / `analyticsTimeWindowErrorTooLong` / `analyticsTimeWindowErrorFutureEnd`). Sheet stays open after error so user can pick again. Locked in Plan 05 Task 3.

6. **Earliest-data awareness for preset lists.**
   - What we know: `earliestTransactionMonthProvider` already exists for the month chip. CONTEXT.md notes "The selector needs earliest-data awareness for preset lists, while still capping future dates at today."
   - What's unclear: How week / quarter / year preset lists should cap on the lower end. Show all years back to the earliest tx year? Show 12 quarters?
   - Recommendation: Cap each preset list at the earliest year/quarter/week that contains data. The earliest-data query returns a single timestamp; derive the earliest year/quarter/week from it.
   - **RESOLVED:** Preset lists derive lower bound from `earliestTransactionMonthProvider`. Year list: currentYear..earliestYear. Quarter list: enumerate quarters back to (earliestYear, earliestQuarter). Week list: Mondays back to the Monday of the earliest data week. Future dates always capped at `DateTime.now()` (D-07). Locked in Plan 05 Task 3 preset-list bounds derivation.
## Environment Availability

> Phase 15 has no new external dependencies. All code changes use already-installed packages and Flutter SDK built-ins. **SKIPPED.**

## Validation Architecture

> `workflow.nyquist_validation` is `true` in `.planning/config.json` (line 19). This section is **REQUIRED**.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (Flutter SDK) + `mocktail` (already in dev_dependencies) |
| Config file | None — Flutter convention; tests live under `test/` |
| Quick run command | `flutter test test/unit/application/analytics/ test/widget/features/analytics/` |
| Full suite command | `flutter test --coverage` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HAPPY-V2-02 (SC-1) | Time-window chip with W/M/Q/Y/Custom options; selection persists within session. | widget | `flutter test test/widget/features/analytics/presentation/widgets/time_window_chip_test.dart` | ❌ Wave 0 |
| HAPPY-V2-02 (SC-1) | Bottom sheet flow: type-row → type-specific chooser (D-02); immediate apply (D-04). | widget | `flutter test test/widget/features/analytics/presentation/widgets/time_window_picker_sheet_test.dart` | ❌ Wave 0 |
| HAPPY-V2-02 (SC-1) | `SelectedTimeWindow` notifier — default to current month; `setWindow` updates state. | unit | `flutter test test/unit/features/analytics/presentation/providers/state_time_window_test.dart` | ❌ Wave 0 |
| HAPPY-V2-02 (SC-2) | All AnalyticsScreen cards re-query against the active window. | widget | `flutter test test/widget/features/analytics/presentation/screens/analytics_screen_test.dart` (extend existing) | ✅ |
| HAPPY-V2-02 (SC-2) | `(startDate, endDate)` parameter acceptance per use case. | unit | `flutter test test/unit/application/analytics/get_*_use_case_test.dart` (rewrite 5 files) | ✅ (existing) |
| HAPPY-V2-02 (SC-2) | `start > end` rejected with `ArgumentError`. | unit | Same files — `expect(() => useCase.execute(start, end), throwsArgumentError)` | ✅ (extend) |
| HAPPY-V2-02 (SC-2) | `span > 12 months` rejected with `ArgumentError`. | unit | Same files | ✅ (extend) |
| HAPPY-V2-02 (SC-2) | UI surfaces localized error when user tries to apply a >12-month custom range. | widget | `time_window_picker_sheet_test.dart` | ❌ Wave 0 |
| HAPPY-V2-02 (SC-2) | `TimeWindow.range` math correctness (week-Monday, quarter boundaries, year, custom). | unit | `flutter test test/unit/features/analytics/domain/models/time_window_test.dart` | ❌ Wave 0 |
| HAPPY-V2-02 (SC-3) | HomeHero ring stays month-anchored when AnalyticsScreen window changes. | widget | `flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart` (or screen-level) — assert HomeHero's providers are read with `DateTime.now()` year/month regardless of `selectedTimeWindowProvider` state | ❌ Wave 0 (new test or extension) |
| HAPPY-V2-02 (SC-4) | All selector and metric labels respect ja/zh/en parity; no hardcoded date strings. | static + unit | `dart run scripts/check_arb_parity.dart` (if present) + `flutter test test/widget/features/analytics/` running with three locales | ✅ (existing parity check; widget tests in en + ja sample) |
| HAPPY-V2-02 (SC-4) | `DateFormatter` (via `FormatterService`) used for all date display in chip + sheet. | static | Grep `lib/features/analytics/presentation/` for raw `DateFormat(`/`.toString()` on `DateTime` outside `DateFormatter`/`FormatterService`. | ✅ (manual grep gate) |
| HAPPY-V2-02 (SC-5) | No cross-period delta widget present in AnalyticsScreen widget tree. | widget | `analytics_screen_test.dart` — `expect(find.byKey(Key('crossPeriodDelta')), findsNothing)` + grep for forbidden substrings: `vs`, `delta`, `compare` in ARB files for analytics-prefixed keys (allowing the existing month-MoM delta in `analyticsKpiTotalDelta*` per D-11/D-12 — note that this WILL need re-examination since these keys are month-anchored, and removing them is in scope if planner agrees). | ✅ (extend) |

### Sampling Rate
- **Per task commit:** `flutter test test/unit/application/analytics/ test/unit/features/analytics/ test/widget/features/analytics/`
- **Per wave merge:** `flutter test --coverage` (full suite, plus coverage gate ≥70% per-file on changed files per CI guardrail)
- **Phase gate:** Full suite green + `flutter analyze` 0 issues + `dart format` clean + `flutter gen-l10n` succeeds without warnings (per Cross-Phase Constraints) before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `test/unit/features/analytics/domain/models/time_window_test.dart` — covers TimeWindow.range math for all 5 variants (HAPPY-V2-02 SC-1, SC-2).
- [ ] `test/unit/features/analytics/presentation/providers/state_time_window_test.dart` — covers SelectedTimeWindow notifier default + setWindow (SC-1).
- [ ] `test/widget/features/analytics/presentation/widgets/time_window_chip_test.dart` — covers chip rendering for all 5 window types in en + ja (SC-1, SC-4).
- [ ] `test/widget/features/analytics/presentation/widgets/time_window_picker_sheet_test.dart` — covers type-row navigation, immediate-apply, invalid-range error surface (SC-1, SC-2, SC-4).
- [ ] `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` — locks HomeHero to current-month, assert `selectedTimeWindowProvider` changes don't reach HomeHero providers (SC-3).
- [ ] Extend `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart` — assert no cross-period delta widget; assert all card providers re-query on window change (SC-2, SC-5).
- [ ] Extend all 5 existing use-case unit tests for new `(startDate, endDate)` signatures + validation (`ArgumentError`) cases (SC-2).
- [ ] No framework install needed — `flutter_test` + `mocktail` already wired.

## Security Domain

> `security_enforcement` not explicitly set in `.planning/config.json` — defaulting to enabled. Reviewed below.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 15 is purely client-side UI/state. No auth surface. |
| V3 Session Management | no | The "session" here is Flutter app process lifetime, not a security session. |
| V4 Access Control | no | No new RBAC or data-visibility boundaries. The selector reads aggregate counts from the user's own book. |
| V5 Input Validation | **yes** | Custom date range is user-supplied. Validation: `start ≤ end`, `end ≤ today` (D-07), `span ≤ 12 months` (D-08). Enforced at use-case boundary (`ArgumentError`) + presentation (localized error). Standard control: explicit guard helper in `lib/application/analytics/_time_window_validation.dart`. |
| V6 Cryptography | no | No crypto operations. |

### Known Threat Patterns for `{Flutter + Drift + SQLCipher}`

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via date inputs | Tampering | Drift `customSelect` uses `Variable.withDateTime(startDate)` — parameter binding, not string interpolation. `[VERIFIED: lib/data/daos/analytics_dao.dart lines 117-121]`. Phase 15 introduces no raw SQL; the existing parameterized pattern is preserved. |
| Resource exhaustion via maximum range | Denial of service | 12-month cap (D-08) bounds query scope. Even uncapped, a single-book year-wide query is ~1200 soul transactions per `get_happiness_report_use_case.dart` line 376-377 — negligible. Index `(book_id, timestamp)` already in place. |
| Localized error copy leaking system info | Information disclosure | Validation errors return localized user-facing strings (e.g., "Range cannot exceed 12 months"), NOT exception toString(). Use ARB keys; never display `ArgumentError.message` verbatim. |
| Future-date selection sidestepping data integrity | Tampering (light) | D-07 caps at today. Enforced in UI (preset lists end at today; date picker max = today) AND use case (`endDate.isAfter(DateTime.now())` rejection — or accept silently and let aggregates return zero, since no future tx exist; planner picks). |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/15-custom-time-windows-happy-v2-02/15-CONTEXT.md` — locked decisions D-01 through D-12, planner discretion areas, deferred items.
- `.planning/phases/15-custom-time-windows-happy-v2-02/15-DISCUSSION-LOG.md` — alternatives considered for selector shape and date semantics.
- `.planning/REQUIREMENTS.md` lines 26 + 96-117 — HAPPY-V2-02 requirement, Phase 15 mapping, cross-phase constraints.
- `.planning/ROADMAP.md` lines 90-101 — Phase 15 goal + success criteria.
- `.planning/STATE.md` — milestone status, Phase 14 completion.
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` §3 + §6 — HomeHero monthly ring semantics, dual-screen consistency.
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` §"Forbidden Features" line 105 — Cross-period delta on home tile prohibition.
- `lib/features/analytics/presentation/screens/analytics_screen.dart` — Variant ε layout, current month derivation, refresh invalidation.
- `lib/features/analytics/presentation/providers/state_analytics.dart` + `state_happiness.dart` — current provider keying.
- `lib/application/analytics/get_*_use_case.dart` (5 files) — current `(year, month)` → `(startDate, endDate)` internal derivation.
- `lib/features/analytics/domain/repositories/analytics_repository.dart` — repository surface already `(startDate, endDate)`.
- `lib/data/daos/analytics_dao.dart` — DAO already `(startDate, endDate)` with composite index `(book_id, timestamp)`.
- `lib/features/home/presentation/screens/home_screen.dart` lines 49-52 + 90-220 — HomeHero uses `DateTime.now()`, NOT `selectedMonthProvider` (isolation confirmed structurally).
- `lib/features/analytics/presentation/widgets/month_chip_picker.dart` — existing chip + bottom-sheet pattern to evolve.
- `lib/infrastructure/i18n/formatters/date_formatter.dart` — locale-switching formatter pattern.
- `lib/application/i18n/formatter_service.dart` — application-layer wrapper used by widgets.
- `lib/l10n/app_{en,ja,zh}.arb` — current analytics-prefixed ARB keys (56 keys).
- `lib/data/tables/transactions_table.dart` line 50 — composite index `(book_id, timestamp)` (perf safety).
- `pubspec.yaml` lines 17, 20-21, 81, 83 — version pins.
- `lib/main.dart` lines 152-157 — `GlobalMaterialLocalizations` wired (enables `showDateRangePicker`).
- `test/widget/features/analytics/presentation/widgets/month_chip_picker_test.dart` + `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart` + `test/unit/application/analytics/get_satisfaction_distribution_use_case_test.dart` — test patterns to follow.
- `test/helpers/test_localizations.dart` + `test/helpers/test_provider_scope.dart` — shared test helpers.

### Secondary (MEDIUM confidence)
- `CLAUDE.md` (project root) — Riverpod 3 conventions, intl 0.20.2 pin, Thin Feature rule, build_runner workflow.
- `.planning/STATE.md` lines 33-46 — v1.2 milestone phase plan + cross-phase constraints.

### Tertiary (LOW confidence — needs validation)
- `pub.dev/documentation/intl/latest/intl/DateFormat-class.html` — accessed via WebSearch; verifies `QQQ`/`QQQQ` quarter skeleton support but does not pin to 0.20.2 specifically. Verify with a small Dart playground spike if planner is uncertain.

## Project Constraints (from CLAUDE.md)

Treating CLAUDE.md directives with same authority as locked decisions:

- **Thin Feature rule** — `lib/features/analytics/` MUST NOT contain `application/`, `infrastructure/`, `data/tables/`, or `data/daos/` subdirectories. Use cases live in `lib/application/analytics/`. *Phase 15 compliant: no new app/infra/data inside features.*
- **Placement rule** — `TimeWindow` value object is a domain model → `lib/features/analytics/domain/models/`. `SelectedTimeWindow` provider is presentation state → `lib/features/analytics/presentation/providers/`. Use case parameter changes → `lib/application/analytics/`. ARB → `lib/l10n/`.
- **Riverpod 3 conventions** — Use `package:flutter_riverpod/flutter_riverpod.dart` for `@riverpod` / `Notifier` / `AsyncValue` / `Ref`. Do NOT use `flutter_riverpod/legacy.dart` (e.g., `StateProvider`). Provider names strip `Notifier` suffix per CLAUDE.md (`LocaleNotifier` → `localeProvider`). Class `SelectedTimeWindow` (no suffix) → `selectedTimeWindowProvider`.
- **Freezed/Drift codegen** — Run `flutter pub run build_runner build --delete-conflicting-outputs` after any `@freezed` or `@riverpod` change. CI guardrail AUDIT-10 catches stale generated files.
- **intl 0.20.2 pin** — Do not bump.
- **`sqlcipher_flutter_libs` only** — Phase 15 doesn't touch native code; this rule is upstream.
- **i18n parity** — All UI text via `S.of(context)`; never hardcode strings. Update ALL 3 ARB files; run `flutter gen-l10n`.
- **Dates via `DateFormatter`** — Direct `DateFormat(...)` in feature widgets is forbidden; route through `FormatterService` (which delegates to `DateFormatter`).
- **Amounts via `AppTextStyles.amount*`** — Not directly relevant to Phase 15 (no new amount displays), but the chip's label may include a date — use the right styles.
- **CI guardrails (permanent)** — `flutter analyze` 0 issues; `custom_lint` 0 errors; `import_guard` + `riverpod_lint` 0 violations; per-file coverage ≥70%; global ≥70%; build_runner clean-diff. Per `.planning/REQUIREMENTS.md` Cross-Phase Constraints.

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — all packages already pinned in `pubspec.yaml` and used in adjacent code.
- Architecture: **HIGH** — repository/DAO surface already speaks `(startDate, endDate)`; the pattern is parameter expansion, not new design.
- HomeHero isolation: **HIGH** — verified by reading `home_screen.dart` lines 49-52 (uses `DateTime.now()` directly, never reads `selectedMonthProvider`).
- Pitfalls: **HIGH** for #1-3 + #5-10 (verified in code); **MEDIUM** for #4 (intl ISO week behavior — open question on label format).
- Test infra: **HIGH** — existing patterns are clean and replicable.
- i18n: **HIGH** for the technology (`DateFormatter`/`FormatterService`/`intl` 0.20.2 all in place); **MEDIUM** for the specific copy decisions (covered in Assumptions Log A1, A2).

**Research date:** 2026-05-19
**Valid until:** 2026-06-19 (30 days — stack is stable, but if Riverpod 4.x lands within this window, re-verify provider patterns).

---

Sources (web):
- [DateFormat class - intl library - Dart API](https://pub.dev/documentation/intl/latest/intl/DateFormat-class.html)
