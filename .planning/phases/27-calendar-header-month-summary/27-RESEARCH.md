# Phase 27: Calendar Header + Month Summary — Research

**Researched:** 2026-05-30
**Domain:** Flutter / table_calendar 3.2.0 / Riverpod 3 / custom CalendarBuilders / provider isolation / Drift analytics DAO
**Confidence:** HIGH — all findings derived directly from codebase inspection (source files read), Context7 (STACK.md from 2026-05-29 milestone research), official pub.dev documentation, and the approved CONTEXT.md / UI-SPEC.md contracts.

---

## Summary

Phase 27 delivers a self-contained `CalendarHeaderWidget` — a `ConsumerWidget` sitting above the Phase 28/29 list, observable in isolation. All four requirements (CAL-01 month nav, CAL-02 per-day expense grid, CAL-03 day-tap filter, CAL-04 month summary) are driven by two new files: `state_calendar_totals.dart` (a `@riverpod` family provider) and `list_calendar_header.dart` (the widget). The heavy-lifting decisions are already locked in CONTEXT.md; this research documents the concrete API mechanics, verified code facts, and pitfall-prevention patterns the planner needs to produce executable task specs.

The most important technical risk is **DateTime key normalization**: `table_calendar` hands builder callbacks a `DateTime` that may carry a time component; a `Map<DateTime, int>` keyed on raw DateTimes will silently miss every lookup. Both the provider and the cell builder must use the same `DateTime(d.year, d.month, d.day)` normalization via a shared helper. This is the highest-probability silent failure mode for this phase.

The second critical risk is the **NumberFormatter method name mismatch**: the UI-SPEC uses shorthand (`NumberFormatter.compact(...)`, `NumberFormatter.format(...)`), but the actual class methods are `NumberFormatter.formatCompact(num, Locale)` and `NumberFormatter.formatCurrency(num, String, Locale)`. Using the wrong names produces a compile error.

**Primary recommendation:** Build `state_calendar_totals.dart` first (provider + unit tests), verify the Map normalization contract in isolation, then build `list_calendar_header.dart` consuming it. This sequence enables SC#1–SC#4 to be validated independently before the `ListScreen` integration step.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01** Each day cell: compact amount (no dot) via `NumberFormatter.formatCompact` + `AppTextStyles.micro`. No amount shown for zero-expense days.
**D-02** today/selected cell visual state: Claude's Discretion (see below). Direction: selected = `AppColors.accentPrimary` ring; today = `AppColors.accentPrimaryLight` fill + `AppColors.accentPrimaryBorder` 1dp border.
**D-03** Month navigation: prev/next chevron + native swipe. No month picker.
**D-04** Tap month label = jump to current real month (`DateTime.now()`).
**D-05** Calendar always full-month (`CalendarFormat.month`). No collapsible toggle.
**D-06** Summary row: month total always visible; day subline added (not replacing) when `activeDayFilter != null`.
**D-07** Day subline amount: reuses `calendarDailyTotalsProvider` map — no extra query.
**D-08** Summary label/copy + ARB keys: Claude's Discretion. Placeholder ARB keys; Phase 30 finalizes tri-lingual copy.
**D-09** `calendarDailyTotalsProvider(bookId, year, month)` is INDEPENDENT of `listTransactionsProvider`. Watches only `(bookId, month)`. Does NOT watch `listFilterProvider` filter state.
**D-10** Own-book only (`bookId` single value). Family multi-book deferred to Phase 29. Seam comment required.
**D-11** Month summary total = `map.values.fold(0, (a, b) => a + b)`. Single source of truth, same expense-only basis as day cells.

### Claude's Discretion

- today/selected cell visual detail (D-02) — approved direction per UI-SPEC: selected = `AppColors.accentPrimary` fill, today = `AppColors.accentPrimaryLight` fill + `AppColors.accentPrimaryBorder` 1dp border/6dp radius
- summary label/copy + ARB key names (D-08) — approved in UI-SPEC: `calMonthTotal` / `calDayTotal` / `calLoadError`
- `@riverpod` param shape for `calendarDailyTotals` — `(bookId, year, month)` named params
- `startingDayOfWeek` per locale — ja/zh: `StartingDayOfWeek.sunday`; en: `StartingDayOfWeek.monday`
- day-tap toggle logic location — widget `onDaySelected` callback using `isSameDay`
- widget test construction — `ProviderContainer.test()` + `waitForFirstValue<T>` + Mocktail mock of `AnalyticsRepository`

### Deferred Ideas (OUT OF SCOPE)

- Month picker (CAL-01 literal text)
- Family multi-book calendar totals (CAL-02 family mode) — Phase 29
- Collapsible week/month format toggle — v1.5
- ARB tri-lingual copy finalization — Phase 30
- per-day ledger-color split (survival/soul) — not in this phase

</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CAL-01 | User can switch the displayed month via prev/next arrows + swipe; calendar grid re-renders, month label updates | table_calendar `onPageChanged` + `selectMonth` mutator + `focusedDay` driven from `listFilterProvider`; nav-callback de-duplication pattern documented below |
| CAL-02 | Day cell shows expense-only total for days with transactions; no indicator for empty days; own-book only | `calendarDailyTotalsProvider` reads `AnalyticsRepository.getDailyTotals` (expense-only default); `CalendarBuilders.defaultBuilder` injects amount; day-key normalization contract prevents silent blanks |
| CAL-03 | Tap day → filter list + highlight; tap same day again → clear filter | `listFilterProvider.notifier.selectDay(DateTime?)` mutator already built (Phase 26); toggle logic uses `table_calendar`'s `isSameDay` helper; `selectedDayPredicate` drives visual highlight |
| CAL-04 | Month summary line shows expense-only total via `NumberFormatter` + `AppTextStyles.amountSmall` | `map.values.fold(0, ...)` derives total from same provider; `NumberFormatter.formatCurrency` + `AppTextStyles.amountSmall` confirmed in source |

</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Per-day expense aggregation (CAL-02) | Data (DAO) | Application (provider folds List→Map) | SQL `GROUP BY day` already in `AnalyticsDao.getDailyTotals`; zero new DAO code |
| Calendar provider state | Presentation/providers (`state_calendar_totals.dart`) | — | `@riverpod` family, own-book only; isolated from `listTransactionsProvider` (Pitfall 3) |
| Month navigation state | Presentation/providers (`listFilterProvider`) | — | `selectMonth`/`selectDay` mutators already in `state_list_filter.dart`; calendar widget is a consumer |
| Calendar grid rendering (CAL-01/CAL-02/CAL-03) | Presentation/widgets (`list_calendar_header.dart`) | — | `CalendarBuilders.defaultBuilder` replaces entire cell; `onDaySelected`/`onPageChanged` wire to `listFilterProvider` |
| Month summary (CAL-04) | Presentation/widgets (SummaryRow in same file) | — | Derived from provider map values; no separate provider or query |
| Locale-aware month label (CAL-01) | Presentation/widgets | Infrastructure/i18n (`DateFormatter.formatMonthYear`) | `DateFormatter.formatMonthYear(DateTime, Locale)` already handles ja/zh/en |

---

## Standard Stack

### Core (this phase)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `table_calendar` | `^3.2.0` | Month grid with custom cell builder, swipe, day-selection | Only addition; `intl ^0.20.0` dep satisfies pinned `0.20.2`; no native code; no win32 |
| `flutter_riverpod` | `^3.1.0` (already installed) | `@riverpod` family provider for calendar totals | Project standard |
| `riverpod_annotation` | `^4.0.0` (already installed) | Code-gen for `calendarDailyTotalsProvider` | Project standard |

### Supporting (already installed, used in this phase)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `intl` | `0.20.2` (exact pin — DO NOT CHANGE) | `DateFormatter.formatMonthYear`, `DateFormatter.formatShortMonthDay`, `NumberFormatter.*` | All locale-aware formatting |
| `freezed_annotation` | `^3.0.0` | No new Freezed models in this phase | n/a |
| `mocktail` | already installed | Mocktail mock of `AnalyticsRepository` in provider tests | Provider unit tests |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `table_calendar` | Hand-rolled `GridView` calendar | ~350 lines of date arithmetic, locale-aware week-start logic, swipe detection, hit-test; not worth it |
| `CalendarBuilders.defaultBuilder` for all states | Separate `todayBuilder`/`selectedBuilder` | UI-SPEC and C-04 config share the same builder for all states, dispatching visual state inside the builder — fewer code paths, easier to maintain |

**Installation:**
```bash
# Add to pubspec.yaml under dependencies:
#   table_calendar: ^3.2.0

flutter pub get
# No build_runner needed for table_calendar itself.
# Run build_runner AFTER adding @riverpod annotated state_calendar_totals.dart:
flutter pub run build_runner build --delete-conflicting-outputs
```

**Version verification (confirmed via pub.dev 2026-05-30):** `table_calendar` latest is 3.2.0, published 16 months ago. Dependencies: `intl: ^0.20.0` (satisfies pinned `0.20.2`), `simple_gesture_detector: ^0.2.0` (pure Dart, no native code). [VERIFIED: pub.dev/packages/table_calendar]

---

## Package Legitimacy Audit

> `slopcheck` was not available in this environment. All packages below are tagged with their pub.dev verification status.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `table_calendar` | pub.dev | ~6 years | Very high (Flutter ecosystem staple) | github.com/aleksanderwozniak/table_calendar | [OK — well-established Flutter package, 16 months since last release at 3.2.0] | Approved [VERIFIED: pub.dev official package page] |
| `simple_gesture_detector` | pub.dev | Established | High | Transitive dep of table_calendar | [OK — pure Dart, no native] | Approved [VERIFIED: pub.dev via table_calendar dependency graph] |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
[table_calendar onPageChanged / chevron tap]
        │ selectMonth(year, month)
        ▼
[listFilterProvider (keepAlive:true)]
   selectedYear / selectedMonth / activeDayFilter
        │
        ├─ watched by ──► [calendarDailyTotalsProvider(bookId, year, month)]
        │                     │ getDailyTotals(bookId, start, end, type='expense')
        │                     ▼
        │              [AnalyticsRepository]
        │                     │ List<DailyTotal>
        │                     ▼
        │              [fold → Map<DateTime, int>]  ← normalized keys
        │
        └─ watched by ──► [listTransactionsProvider(bookId)]  ← SEPARATE, not watched by calendar
                              (Phase 28/29 list rendering)

[CalendarHeaderWidget (ConsumerWidget)]
   reads: listFilterProvider (selectedYear/Month, activeDayFilter)
   reads: calendarDailyTotalsProvider(bookId, year, month)
   calls: listFilterProvider.notifier.selectMonth / selectDay
         │
         ├── [Month Nav Bar] — chevrons + tappable month label
         ├── [TableCalendar] — CalendarBuilders.defaultBuilder → DayCell
         │       all builder states (default/today/selected/outside) → same _buildDayCell()
         └── [SummaryRow]
                 ├── month total (always visible)
                 └── day subline (AnimatedSize, visible when activeDayFilter != null)
```

### Recommended Project Structure

```
lib/features/list/presentation/
├── providers/
│   ├── state_calendar_totals.dart        [NEW] @riverpod family provider
│   └── state_calendar_totals.g.dart      [generated — run build_runner]
├── widgets/
│   └── list_calendar_header.dart         [NEW] CalendarHeaderWidget + DayCell + SummaryRow
└── screens/
    └── list_screen.dart                  [MODIFY] mount CalendarHeaderWidget at top
```

No new `repository_providers.dart` entry — `calendarDailyTotalsProvider` imports `analyticsRepositoryProvider` from `lib/features/analytics/presentation/providers/repository_providers.dart` directly. (`provider_graph_hygiene_test` enforces ONE `repository_providers.dart` per feature.)

---

### Pattern 1: `@riverpod` family provider for calendar totals

**What:** `calendarDailyTotalsProvider` with named family params `(bookId, year, month)` → `AsyncValue<Map<DateTime, int>>`.

**Critical detail — DateTime key normalization:** `DailyTotal.date` returned from `AnalyticsRepositoryImpl` is parsed from the SQL `DATE(...)` string via `DateTime.parse(row.read<String>('day'))`, which returns a local-midnight `DateTime` (e.g., `2026-05-03 00:00:00.000`). However, `table_calendar` passes builder callbacks a `DateTime` that may have a non-zero time component depending on internal calendar logic. A map keyed on raw `DateTime` values will miss on equality comparison. The provider MUST normalize every key, and the cell/subline lookup must use the identical normalization.

**Verified pattern:**

```dart
// Source: codebase inspection — analytics_dao.dart:258-263, analytics_aggregate.dart:21-26
// + table_calendar FocusedDayBuilder typedef (pub.dev/documentation/table_calendar/latest)

// lib/features/list/presentation/providers/state_calendar_totals.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
import '../../../../shared/utils/date_boundaries.dart';

part 'state_calendar_totals.g.dart';

/// Normalizes a DateTime to date-only (strips time-of-day).
/// MUST be used by both the provider (when building keys)
/// and the cell/subline lookup (when indexing).
DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// Per-day expense totals for the calendar header.
///
/// Watches only (bookId, year, month) — isolated from listFilterProvider
/// filter state (D-09, Pitfall 3). Rebuilding on text search would
/// re-render 31 day cells on every keystroke.
///
/// Phase 29 seam: bookId is a single value (own-book only).
/// // Phase 29: combine shadow books for family per-day totals
@riverpod
Future<Map<DateTime, int>> calendarDailyTotals(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
}) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final range = DateBoundaries.monthRange(year, month);
  final totals = await repo.getDailyTotals(
    bookId: bookId,
    startDate: range.start,
    endDate: range.end,
    // type = 'expense' is the default — expense-only (D-09, Pitfall 6)
  );
  return {
    for (final t in totals) _dayKey(t.date): t.totalAmount,
  };
}
```

**Key facts:**
- `AnalyticsRepository.getDailyTotals` returns `List<DailyTotal>` where `DailyTotal.date` is a `DateTime` and `DailyTotal.totalAmount` is an `int` (minor units). [VERIFIED: analytics_aggregate.dart:21-26]
- `type = 'expense'` default is already set in the repository interface signature — no extra param needed. [VERIFIED: analytics_repository.dart:26-32]
- `DateBoundaries.monthRange(year, month)` returns a record `({DateTime start, DateTime end})` using local time. [VERIFIED: date_boundaries.dart:30-35]
- The `analyticsRepositoryProvider` is a plain `Provider<AnalyticsRepository>` (not `@riverpod`), defined in `lib/features/analytics/presentation/providers/repository_providers.dart:34`. Import with `show` clause to avoid namespace pollution. [VERIFIED: repository_providers.dart:34]

### Pattern 2: `CalendarBuilders.defaultBuilder` — single builder for all states

**What:** All four builder slots (`defaultBuilder`, `todayBuilder`, `selectedBuilder`, `outsideBuilder`) point to the same `_buildDayCell` function. The builder receives `(BuildContext context, DateTime day, DateTime focusedDay)` and dispatches visual state internally.

**Verified FocusedDayBuilder signature** (pub.dev official docs 2026-05-30):
```dart
typedef FocusedDayBuilder = Widget? Function(
  BuildContext context,
  DateTime day,
  DateTime focusedDay,
);
```

**Visual state dispatch logic (inside _buildDayCell):**
```dart
// [CITED: 27-UI-SPEC.md §C-02 DayCell states]
Widget? _buildDayCell(
  BuildContext context,
  DateTime day,
  DateTime focusedDay,
  Map<DateTime, int> dailyMap,
  DateTime? activeDayFilter,
  bool isOutside,
) {
  final key = _dayKey(day);
  final dayTotal = dailyMap[key] ?? 0;
  final isSelected = activeDayFilter != null && isSameDay(day, activeDayFilter);
  final isToday = isSameDay(day, DateTime.now());

  // Determine container decoration
  BoxDecoration? decoration;
  if (isSelected) {
    decoration = BoxDecoration(
      color: AppColors.accentPrimary,
      borderRadius: BorderRadius.circular(6),
    );
  } else if (isToday) {
    decoration = BoxDecoration(
      color: AppColors.accentPrimaryLight,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.accentPrimaryBorder, width: 1),
    );
  }

  // Determine text colors
  final numeralColor = isSelected ? AppColors.card : AppColors.textPrimary;
  final amountColor = isSelected ? AppColors.card : AppColors.textSecondary;

  return Container(
    decoration: decoration,
    child: Opacity(
      opacity: isOutside ? 0.35 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: AppTextStyles.bodySmall.copyWith(color: numeralColor),
          ),
          if (dayTotal > 0 && !isOutside)
            const SizedBox(height: 4),
          if (dayTotal > 0 && !isOutside)
            Text(
              NumberFormatter.formatCompact(dayTotal, locale),
              style: AppTextStyles.micro.copyWith(color: amountColor),
            ),
        ],
      ),
    ),
  );
}
```

**Critical executor notes:**
- `AppTextStyles.bodySmall` bakes in `color: AppColors.textSecondary` — must `.copyWith(color: numeralColor)` to get `textPrimary` for the day numeral. [VERIFIED: app_text_styles.dart:72-77]
- `AppTextStyles.micro` bakes in `color: AppColors.textPrimary` — must `.copyWith(color: amountColor)` to get `textSecondary` for the amount. [VERIFIED: app_text_styles.dart:95-100]
- `isSameDay` is exported from `table_calendar` — import it from there, not a custom implementation.

### Pattern 3: `focusedDay` driven from `listFilterProvider` (nav de-duplication)

**What:** `focusedDay` in `TableCalendar` is always `DateTime(selectedYear, selectedMonth)` read from `listFilterProvider`. This makes the provider the single source of truth. Both the chevron handlers and `onPageChanged` (swipe) call `selectMonth`; because the provider value already matches after a chevron tap, the `onPageChanged` that fires from the resulting `focusedDay` rebuild is a no-op (idempotent).

**Critical:** Do NOT call `_pageController.animateToPage` from chevron handlers. Let the rebuilt `focusedDay` move the page.

```dart
// [CITED: 27-UI-SPEC.md §C-04 nav-callback de-duplication]
TableCalendar(
  focusedDay: DateTime(filter.selectedYear, filter.selectedMonth),
  calendarFormat: CalendarFormat.month,
  availableCalendarFormats: const {CalendarFormat.month: ''},
  headerVisible: false,
  startingDayOfWeek: _startingDay(locale),
  locale: locale.toLanguageTag(),
  selectedDayPredicate: (day) => isSameDay(day, filter.activeDayFilter),
  onDaySelected: _onDayTapped,
  onPageChanged: (focusedDay) =>
      ref.read(listFilterProvider.notifier)
         .selectMonth(focusedDay.year, focusedDay.month),
  rowHeight: 52,
  daysOfWeekHeight: 20,
  calendarBuilders: CalendarBuilders(
    defaultBuilder: (ctx, day, fd) => _buildDayCell(ctx, day, fd, dailyMap, activeDayFilter, false),
    todayBuilder:   (ctx, day, fd) => _buildDayCell(ctx, day, fd, dailyMap, activeDayFilter, false),
    selectedBuilder:(ctx, day, fd) => _buildDayCell(ctx, day, fd, dailyMap, activeDayFilter, false),
    outsideBuilder: (ctx, day, fd) => _buildDayCell(ctx, day, fd, dailyMap, activeDayFilter, true),
  ),
)

StartingDayOfWeek _startingDay(Locale locale) {
  // ja/zh: Sunday-first (traditional calendar convention)
  // en: Monday-first (ISO 8601)
  return (locale.languageCode == 'en')
      ? StartingDayOfWeek.monday
      : StartingDayOfWeek.sunday;
}
```

**`availableCalendarFormats: const {CalendarFormat.month: ''}` explanation:** Passing a map with only one entry locks the format and removes the format toggle button. Passing `''` as the label suppresses the toggle button's display text while keeping the format locked. [ASSUMED — based on table_calendar docs behavior; confirmed via STACK.md research]

### Pattern 4: Day-tap toggle (CAL-03)

```dart
// [CITED: 27-CONTEXT.md D-06 / 27-UI-SPEC.md §C-02 interaction]
void _onDayTapped(DateTime selectedDay, DateTime focusedDay) {
  final notifier = ref.read(listFilterProvider.notifier);
  final current = ref.read(listFilterProvider).activeDayFilter;
  if (current != null && isSameDay(current, selectedDay)) {
    notifier.selectDay(null);  // toggle off
  } else {
    notifier.selectDay(selectedDay);
  }
}
```

`selectDay(null)` is the verified clear path. [VERIFIED: state_list_filter.dart:35]

### Pattern 5: `SummaryRow` — month total + conditional day subline

```dart
// [CITED: 27-UI-SPEC.md §C-03 SummaryRow]
// Month total (D-11): single fold over map values
final monthTotal = dailyMap.values.fold(0, (a, b) => a + b);

// Day subline: reuse map (D-07), no extra query
final dayAmount = activeDayFilter != null
    ? (dailyMap[_dayKey(activeDayFilter!)] ?? 0)
    : 0;
```

**NumberFormatter method names (CRITICAL):**
The UI-SPEC uses shorthand. Actual method signatures are:

| UI-SPEC shorthand | Actual method | Signature |
|-------------------|---------------|-----------|
| `NumberFormatter.compact(...)` | `NumberFormatter.formatCompact` | `static String formatCompact(num number, Locale locale)` |
| `NumberFormatter.format(...)` | `NumberFormatter.formatCurrency` | `static String formatCurrency(num amount, String currencyCode, Locale locale)` |

[VERIFIED: number_formatter.dart:16,38]

**Currency code source:** `bookByIdProvider(bookId: bookId).value?.currency ?? 'JPY'` — same pattern as `home_screen.dart:59`. [VERIFIED: home_screen.dart:58-59]

**DateFormatter methods actually used:**
- Month label: `DateFormatter.formatMonthYear(DateTime(year, month), locale)` → ja: `2026年5月`, zh: `2026年5月` (note: existing code uses `M月` not `MM月`), en: `May 2026`. [VERIFIED: date_formatter.dart:32-40]
- Day subline: `DateFormatter.formatShortMonthDay(activeDayFilter, locale)` → ja/zh: `M月d日`, en: `May 3`. [VERIFIED: date_formatter.dart:43-52]

**zh month label discrepancy:** The UI-SPEC says zh format is `yyyy年MM月`, but `DateFormatter.formatMonthYear` uses `DateFormat('yyyy年M月', ...)` for both ja and zh (no zero-padding for month). Use `DateFormatter.formatMonthYear` as-is — it's the project standard; the UI-SPEC's `MM` notation is a typo/aspirational. Do not hand-roll a custom format.

### Pattern 6: Loading state — shimmer placeholder

```dart
// [CITED: 27-UI-SPEC.md §States and Loading Skeleton]
// In SummaryRow amount slot:
calendarAsync.when(
  loading: () => SizedBox(
    width: 60,
    height: 15,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.backgroundMuted,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  ),
  error: (e, _) => Text(S.of(context).calLoadError,
      style: AppTextStyles.caption),
  data: (dailyMap) => Text(
    NumberFormatter.formatCurrency(
      dailyMap.values.fold(0, (a, b) => a + b),
      currencyCode,
      locale,
    ),
    style: AppTextStyles.amountSmall,
  ),
)
```

### Anti-Patterns to Avoid

- **`calendarDailyTotalsProvider` watching `listFilterProvider`:** If the calendar provider watches `listFilterProvider`, every text search keystroke (Phase 28+) triggers a DAO re-fetch + 31-cell rebuild. (Pitfall 3 — hard prohibition per D-09.)
- **Using `==` on raw `DateTime` for map lookup:** `DateTime(2026, 5, 3)` vs `DateTime(2026, 5, 3, 0, 0, 0, 500)` are NOT equal. Always use `_dayKey(d)` normalization. (Highest-risk silent failure.)
- **Using wrong method names:** `NumberFormatter.compact(...)` — does not exist. Use `NumberFormatter.formatCompact(...)`.
- **Calling `animateToPage` from chevron handlers:** Fights the `focusedDay` rebuild path; causes double navigation.
- **Using `>=` with raw `DateTime ==` in `selectedDayPredicate`:** Use `isSameDay` from `table_calendar`.
- **Duplicating `analyticsRepositoryProvider` in list feature:** `provider_graph_hygiene_test` will fail. Import from analytics feature with `show analyticsRepositoryProvider`.
- **Adding `table_calendar` without running `flutter build ios --debug --no-codesign`:** SC#5 is a required gate; do not skip.
- **Using `NumberFormatter.formatCurrency` for the day-cell compact amount:** Day cells need `formatCompact` (e.g., `1.2万`), not full currency format (e.g., `¥12,345`). Wrong format overflows the ~40dp cell.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Month grid with swipe + locale-aware week-start | Custom `GridView` + gesture detection | `table_calendar: ^3.2.0` | 350+ lines of date arithmetic, DST edge cases, RTL safety, hit-test |
| Per-day expense totals | New DAO query | `AnalyticsRepository.getDailyTotals` (already exists) | `DATE(timestamp,'unixepoch','localtime') GROUP BY day`, expense-only, localtime boundaries — zero new SQL |
| Month boundaries | Custom `DateTime` arithmetic | `DateBoundaries.monthRange(year, month)` (already exists) | Unit-tested, canonical localtime idiom |
| Month total | New aggregate query | `map.values.fold(0, (a, b) => a + b)` from provider | Same expense-only basis as cells; single source of truth (D-11) |
| Currency formatting | `intl.NumberFormat` directly | `NumberFormatter.formatCurrency` / `NumberFormatter.formatCompact` | Project formatter handles JPY/USD/CNY decimals, ja/zh compact idiom |
| Date formatting | `DateFormat(...)` directly | `DateFormatter.formatMonthYear` / `DateFormatter.formatShortMonthDay` | Project formatter handles ja/zh/en locale switching |
| Day-key normalization | Ad-hoc per-site | Private `_dayKey(DateTime d)` helper in `state_calendar_totals.dart` | Both provider and cell must use identical normalization; shared helper is the contract |

---

## Common Pitfalls

### Pitfall 1: DateTime Key Normalization Mismatch (HIGHEST RISK)

**What goes wrong:** `table_calendar` passes builder callbacks a `DateTime` that may carry a non-zero time component (e.g., `2026-05-03 12:00:00.000` in some internal calendar representations). The provider builds `Map<DateTime, int>` from `DailyTotal.date` which is parsed from a SQL `DATE(...)` string — likely `2026-05-03 00:00:00.000`. Dart `DateTime` equality is exact; `DateTime(2026,5,3) != DateTime(2026,5,3,12,0)`. Every cell lookup silently returns `null`, every cell renders blank. No compile error or runtime exception.

**Why it happens:** Developers assume the `DateTime` from the provider and from the builder callback will be equal without normalization.

**How to avoid:** Define `DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day)` at file scope in `state_calendar_totals.dart`. Use it in the provider's fold (`_dayKey(t.date)`) and in every cell/subline lookup (`dailyMap[_dayKey(day)]`). The UI-SPEC's `## Data Normalization` section makes this the explicit contract.

**Warning signs:** All day cells show no amount even when the test fixture has transactions. Map has entries but cell lookup always returns null.

### Pitfall 2: NumberFormatter Method Name Confusion

**What goes wrong:** The UI-SPEC uses shorthand `NumberFormatter.compact(...)` and `NumberFormatter.format(...)`. These method names do not exist. Actual names are `NumberFormatter.formatCompact(num, Locale)` and `NumberFormatter.formatCurrency(num, String, Locale)`. Using wrong names produces a compile error, but the mismatch might be missed if tests aren't run before UI verification.

**How to avoid:** Always check `lib/infrastructure/i18n/formatters/number_formatter.dart` for exact method names. Use:
- Day cell compact: `NumberFormatter.formatCompact(dayTotal, locale)`
- Summary month total: `NumberFormatter.formatCurrency(monthTotal, currencyCode, locale)`
- Summary day subline: `NumberFormatter.formatCurrency(dayAmount, currencyCode, locale)`

### Pitfall 3: Calendar Provider Isolation (Pitfall 3 from PITFALLS.md)

**What goes wrong:** If `calendarDailyTotalsProvider` is derived from `listTransactionsProvider` or watches `listFilterProvider` directly, every search keystroke in Phase 28+ triggers a full calendar re-fetch + 31-cell rebuild with loading flash.

**How to avoid:** `calendarDailyTotalsProvider(bookId, year, month)` must watch ONLY `analyticsRepositoryProvider` and call `getDailyTotals` with the month range. It must NOT `ref.watch(listFilterProvider)`. The `(bookId, year, month)` params come from the widget calling the provider — not from watching the filter provider inside the provider body.

### Pitfall 4: Duplicate `analyticsRepositoryProvider` in List Feature

**What goes wrong:** `provider_graph_hygiene_test.dart` (Phase 26 deliverable) fails CI if `analyticsRepositoryProvider` is re-declared in the list feature's `repository_providers.dart`.

**How to avoid:** Import `analyticsRepositoryProvider` from `lib/features/analytics/presentation/providers/repository_providers.dart` using a `show` clause:
```dart
import '../../../../features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
```

### Pitfall 5: Missing `flutter build ios --debug --no-codesign` after `table_calendar` add

**What goes wrong:** `table_calendar` has no native code, but `flutter pub get` may pull a new transitive dep version. SC#5 requires the iOS build to pass. Skipping this verification allows a subtle intl conflict or CocoaPods issue to surface in CI.

**How to avoid:** After `flutter pub get`, run `flutter build ios --debug --no-codesign` and verify zero errors. This is an SC#5 gate and must appear as a task.

### Pitfall 6: Expense-only contamination (from PITFALLS.md Pitfall 6)

**What goes wrong:** If `type` param to `getDailyTotals` is omitted or overridden to `null`, income transactions inflate the totals.

**How to avoid:** The repository interface defaults `type = 'expense'` in `getDailyTotals`. Do not pass a different value. Verify with a test: insert one income + one expense; assert calendar map contains only the expense amount.

### Pitfall 7: `ProviderException` wrapping in tests (from PITFALLS.md Pitfall 5)

**What goes wrong:** Provider errors are wrapped in `ProviderException`. Tests asserting `throwsA(isA<StateError>())` silently fail or pass the wrong type.

**How to avoid:** Use `throwsA(isA<ProviderException>().having((e) => e.exception, 'exception', isA<StateError>()))`. Import `ProviderException` from `package:flutter_riverpod/misc.dart`. Use `ProviderContainer.test()` everywhere, and `waitForFirstValue<T>` (already in `test/helpers/test_provider_scope.dart`) for async providers.

---

## Code Examples

### calendarDailyTotalsProvider full implementation template

```dart
// Source: codebase patterns (date_boundaries.dart, analytics_dao.dart,
//         analytics_repository.dart) + CONTEXT.md D-09/D-10/D-11
// lib/features/list/presentation/providers/state_calendar_totals.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
import '../../../../shared/utils/date_boundaries.dart';

part 'state_calendar_totals.g.dart';

/// Normalizes a [DateTime] to date-only key (strips time-of-day).
/// Used by the provider when building map keys AND by the cell builder
/// when looking up a day's total. Both sides MUST use this function
/// to avoid silent lookup misses.
DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// Per-day expense totals for the calendar header.
///
/// Isolated from [listFilterProvider] — watches only (bookId, year, month).
/// Rebuilding on ledger/text-search filter changes would cause 31 day cells
/// to flash loading on every keystroke (Pitfall 3, D-09).
///
/// Phase 29 seam: bookId is a single value (own-book only).
/// // Phase 29: combine shadow books for family per-day totals
@riverpod
Future<Map<DateTime, int>> calendarDailyTotals(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
}) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final range = DateBoundaries.monthRange(year, month);
  final totals = await repo.getDailyTotals(
    bookId: bookId,
    startDate: range.start,
    endDate: range.end,
    // type defaults to 'expense' — expense-only basis (D-09, Pitfall 6)
  );
  return {for (final t in totals) _dayKey(t.date): t.totalAmount};
}
```

### Provider unit test skeleton

```dart
// Source: test/helpers/test_provider_scope.dart (waitForFirstValue verified)
// + CONTEXT.md §Claude's Discretion + PITFALLS.md Pitfall 5

test('calendarDailyTotals expense-only: income excluded', () async {
  final container = ProviderContainer.test(overrides: [
    analyticsRepositoryProvider.overrideWithValue(
      MockAnalyticsRepository(), // Mocktail mock
    ),
  ]);

  // Arrange: stub getDailyTotals to return one expense entry
  when(() => mockRepo.getDailyTotals(
    bookId: any(named: 'bookId'),
    startDate: any(named: 'startDate'),
    endDate: any(named: 'endDate'),
  )).thenAnswer((_) async => [
    DailyTotal(date: DateTime(2026, 5, 3), totalAmount: 1200),
  ]);

  final result = await waitForFirstValue(
    container,
    calendarDailyTotalsProvider(bookId: 'book1', year: 2026, month: 5),
  );

  expect(result.hasValue, isTrue);
  final map = result.requireValue;
  // Normalized key lookup must work
  expect(map[DateTime(2026, 5, 3)], equals(1200));
  // Month total via fold (D-11)
  expect(map.values.fold(0, (a, b) => a + b), equals(1200));
});
```

### Widget test skeleton for CalendarHeaderWidget

```dart
// Source: CONTEXT.md §Claude's Discretion, CLAUDE.md Riverpod 3 conventions
testWidgets('SC#3: tap day highlights it; tap again clears filter', (tester) async {
  final container = ProviderContainer.test(overrides: [
    analyticsRepositoryProvider.overrideWithValue(mockRepo),
    // bookByIdProvider override for currency
  ]);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CalendarHeaderWidget(bookId: 'book1'),
      ),
    ),
  );

  // First tap: select day 5
  await tester.tap(find.text('5'));
  await tester.pump();
  expect(
    container.read(listFilterProvider).activeDayFilter?.day,
    equals(5),
  );

  // Second tap: same day → clear
  await tester.tap(find.text('5'));
  await tester.pump();
  expect(
    container.read(listFilterProvider).activeDayFilter,
    isNull,
  );
});
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `AsyncValue.valueOrNull` (Riverpod 2.x) | `AsyncValue.value` (nullable, Riverpod 3) | Riverpod 3 migration | Using old name causes compile error |
| `ProviderContainer()` in tests | `ProviderContainer.test()` | Riverpod 3 | Old form needs manual `addTearDown(container.dispose)` |
| `class FooNotifier` → generates `fooNotifierProvider` | `class FooNotifier` → generates `fooProvider` (strip suffix) | Riverpod 3 code-gen 4.x | Provider name is `calendarDailyTotalsProvider`, not `calendarDailyTotalsNotifierProvider` |
| `await container.read(provider.future)` | `waitForFirstValue<T>(container, provider)` | Riverpod 3 auto-dispose | Bare read throws "disposed during loading" on auto-dispose providers |

**Deprecated/outdated in this phase context:**
- `CalendarFormat.twoWeeks` — not applicable (D-05 always full month)
- `calendarBuilders.markerBuilder` — not needed; per-day totals are in `defaultBuilder` cell, not event markers

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `availableCalendarFormats: const {CalendarFormat.month: ''}` locks the format and hides the toggle button | Pattern 3 | Format toggle might still appear; workaround: pass the same map but investigate if a different API is needed |
| A2 | `table_calendar` passes builder callbacks a `DateTime` that may carry a non-zero time component | Pitfall 1 | If table_calendar always passes midnight, the `_dayKey` normalization is defensive but harmless overhead |
| A3 | `startingDayOfWeek` locale convention: ja/zh → Sunday, en → Monday | Pattern 3 | If user/locale preference differs, the calendar week header won't match expectation; but this matches Japanese calendar convention |
| A4 | `table_calendar` version 3.2.0 is still the current stable (16 months old, no 3.3.x available) | Standard Stack | If a newer version exists and has breaking changes, pin `3.2.0` explicitly |

**If this table is empty:** All claims were verified or cited — no user confirmation needed. (It is not empty — A1–A4 are based on training knowledge + milestone research, not verified by running code.)

---

## Open Questions (RESOLVED)

1. **Does `table_calendar` require `initializeDateFormatting`?**
   - What we know: `table_calendar` uses `intl` for locale-aware day names. Some `intl` use cases require `initializeDateFormatting(locale)` before formatting.
   - What's unclear: Whether the project's existing `AppInitializer` already calls this, or whether `table_calendar` handles it internally.
   - Recommendation: Check `AppInitializer.initialize()` for `initializeDateFormatting` calls. If absent, the Wave 0 task should add it (or confirm table_calendar doesn't require it). Failure mode: day-of-week headers display incorrectly in non-en locales.
   - **RESOLVED:** Plan 27-01 Task 2 verifies `lib/core/initialization/app_initializer.dart` for `initializeDateFormatting` and adds it if absent.

2. **Does `widgets/` directory exist in `lib/features/list/presentation/`?**
   - What we know: The file layout contract (UI-SPEC §File Layout Contract) places `list_calendar_header.dart` in `lib/features/list/presentation/widgets/`. That directory does not currently exist (Phase 26 only created `providers/` and `screens/`).
   - What's unclear: Whether `import_guard.yaml` for the list presentation layer restricts widget files.
   - Recommendation: Wave 0 task creates `lib/features/list/presentation/widgets/` directory and places the new widget there.
   - **RESOLVED:** Plan 27-01 Task 2 creates `lib/features/list/presentation/widgets/` and confirms no `import_guard.yaml` violation.

3. **`bookByIdProvider` availability in `ListScreen` context**
   - What we know: `CalendarHeaderWidget` needs `currencyCode` from the book. `home_screen.dart` uses `bookByIdProvider(bookId: bookId)`. This provider is in the accounting/home feature.
   - What's unclear: Whether the list feature's `import_guard.yaml` allows importing `bookByIdProvider` from the accounting/home feature presentation layer, or whether `bookId`'s currency should be passed as a constructor param.
   - Recommendation: Pass `currencyCode` as a constructor param to `CalendarHeaderWidget` (resolved by `ListScreen` which already has `bookId`), rather than reading `bookByIdProvider` inside the widget — avoids potential import-guard violation.
   - **RESOLVED:** Plan 27-03 Tasks 1 & 2 pass `currencyCode`/`locale` into `CalendarHeaderWidget` as constructor params (Phase 27 placeholder `'JPY'` with a Phase 29 seam comment); the widget does not import `bookByIdProvider`.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `flutter` SDK | All Flutter compilation | ✓ | Present (project active) | — |
| `intl: 0.20.2` | `table_calendar`, formatters | ✓ (pinned in pubspec.yaml) | 0.20.2 | — |
| `table_calendar: ^3.2.0` | CAL-01/02/03 | ✗ (not yet in pubspec.yaml) | — | Must add |
| `flutter build ios --debug --no-codesign` | SC#5 | Environment-dependent | — | Human UAT if simulator unavailable |

**Missing dependencies:**
- `table_calendar: ^3.2.0` — must be added to `pubspec.yaml` before any calendar code compiles. First wave task.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (already configured) |
| Config file | `pubspec.yaml` `dev_dependencies` |
| Quick run command | `flutter test test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| SC | Behavior | Test Type | Automated Command | File Exists? |
|----|----------|-----------|-------------------|-------------|
| SC#1 | Month navigation: selectMonth updates focusedDay; grid re-renders with correct month label | Widget test | `flutter test test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` | ❌ Wave 0 |
| SC#2 | Day cell shows expense total; empty days show nothing; expense-only (no income) | Provider unit test | `flutter test test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart` | ❌ Wave 0 |
| SC#3 | Tap day → `activeDayFilter` set; tap same day → cleared | Widget test (provider state assertion) | `flutter test test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` | ❌ Wave 0 |
| SC#4 | Month summary = sum of expense-only totals; formatted via NumberFormatter + amountSmall | Widget test (text-finder on formatted amount) | `flutter test test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` | ❌ Wave 0 |
| SC#5 | `table_calendar: ^3.2.0` added; iOS build passes; intl 0.20.2 unbroken | Build command | `flutter build ios --debug --no-codesign` | ❌ Wave 0 (pubspec.yaml edit) |

### Sampling Rate

- **Per task commit:** `flutter test test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart -x`
- **Per wave merge:** `flutter test` (full suite)
- **Phase gate:** Full suite green + `flutter build ios --debug --no-codesign` before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart` — covers SC#2 (expense-only, income excluded, _dayKey normalization, month total fold)
- [ ] `test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` — covers SC#1 (month nav state), SC#3 (day tap toggle), SC#4 (summary row amount text)
- [ ] `lib/features/list/presentation/widgets/` directory — must exist before `list_calendar_header.dart` can be placed there
- [ ] `pubspec.yaml` — add `table_calendar: ^3.2.0` (Wave 1, task 1)

---

## Security Domain

> This phase has no authentication, session management, access control, cryptographic operations, or user input flowing to persistence. The calendar data is read-only analytics derived from already-stored transactions. ASVS categories V2/V3/V4/V6 do not apply.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a |
| V3 Session Management | no | n/a |
| V4 Access Control | no | n/a |
| V5 Input Validation | no (no user text input in this widget) | n/a |
| V6 Cryptography | no | n/a |

**Known Threat Patterns for this phase's stack:** None beyond the project's existing security posture. Calendar totals are expense amounts already decrypted by the repository layer — the widget never handles encrypted data directly.

---

## Sources

### Primary (HIGH confidence)

- `lib/data/daos/analytics_dao.dart:226-263` — `getDailyTotals` signature, SQL pattern, `DailyTotalResult` shape, expense-only default [VERIFIED: direct file read]
- `lib/features/analytics/domain/repositories/analytics_repository.dart:26-32` — `getDailyTotals` interface, `type = 'expense'` default [VERIFIED: direct file read]
- `lib/features/analytics/domain/models/analytics_aggregate.dart:21-26` — `DailyTotal` model: `date: DateTime`, `totalAmount: int` [VERIFIED: direct file read]
- `lib/features/list/presentation/providers/state_list_filter.dart:17-68` — `ListFilter` Notifier, `selectMonth`, `selectDay`, mutator signatures [VERIFIED: direct file read]
- `lib/features/list/domain/models/list_filter_state.dart` — `ListFilterState` 7 fields, `activeDayFilter: DateTime?` [VERIFIED: direct file read]
- `lib/shared/utils/date_boundaries.dart` — `monthRange(year, month)`, `dayRange(day)`, localtime contract [VERIFIED: direct file read]
- `lib/infrastructure/i18n/formatters/number_formatter.dart` — exact method names `formatCompact`, `formatCurrency` [VERIFIED: direct file read]
- `lib/infrastructure/i18n/formatters/date_formatter.dart` — `formatMonthYear`, `formatShortMonthDay` with locale dispatch [VERIFIED: direct file read]
- `lib/core/theme/app_text_styles.dart` — `amountSmall`, `micro`, `bodySmall`, `caption` with exact sizes/weights/colors [VERIFIED: direct file read]
- `lib/core/theme/app_colors.dart` — `accentPrimary`, `accentPrimaryLight`, `accentPrimaryBorder`, `textPrimary`, `textSecondary`, `card`, `backgroundMuted`, `borderDivider`, `textTertiary` [VERIFIED: direct file read]
- `test/helpers/test_provider_scope.dart` — `waitForFirstValue<T>` implementation [VERIFIED: direct file read]
- `lib/features/analytics/presentation/providers/repository_providers.dart:34` — `analyticsRepositoryProvider` as plain `Provider<AnalyticsRepository>` [VERIFIED: direct file read]
- `.planning/phases/27-calendar-header-month-summary/27-CONTEXT.md` — all locked decisions D-01..D-11 [VERIFIED: canonical authority]
- `.planning/phases/27-calendar-header-month-summary/27-UI-SPEC.md` — approved component inventory, data normalization contract, color/typography tokens [VERIFIED: canonical authority]

### Secondary (MEDIUM confidence)

- `pub.dev/packages/table_calendar` — version 3.2.0, dependencies (`intl: ^0.20.0`, `simple_gesture_detector: ^0.2.0`) [VERIFIED: WebFetch 2026-05-30]
- `pub.dev/documentation/table_calendar/latest/table_calendar/FocusedDayBuilder.html` — `FocusedDayBuilder` typedef: `Widget? Function(BuildContext, DateTime day, DateTime focusedDay)` [VERIFIED: WebFetch 2026-05-30]
- `pub.dev/documentation/table_calendar/latest/table_calendar/StartingDayOfWeek.html` — enum values include `sunday`, `monday` [VERIFIED: WebFetch 2026-05-30]
- `.planning/research/STACK.md` — table_calendar capability 1 (CalendarBuilders pattern, provider shape, intl compatibility verdict) [HIGH — milestone research 2026-05-29]
- `.planning/research/PITFALLS.md` — Pitfall 3 (provider isolation), Pitfall 4 (date boundaries), Pitfall 5 (ProviderException), Pitfall 6 (expense-only) [HIGH — milestone research 2026-05-29]

### Tertiary (LOW confidence / [ASSUMED])

- `availableCalendarFormats: const {CalendarFormat.month: ''}` hides the format toggle — [ASSUMED] based on table_calendar documented behavior; not verified by running code
- `table_calendar` may or may not require `initializeDateFormatting` separately — [ASSUMED: requires checking `AppInitializer`]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions verified against pub.dev; package legitimacy confirmed
- Architecture: HIGH — provider patterns verified against existing Phase 26 code; CalendarBuilders API verified against official docs
- Pitfalls: HIGH — derived from actual codebase inspection + milestone research; two pitfalls ([Pitfall 1 key normalization, Pitfall 2 method names]) are directly verifiable from source

**Research date:** 2026-05-30
**Valid until:** 2026-06-30 (table_calendar 3.2.0 is stable; Riverpod 3.1.0 stable; no fast-moving deps in this phase)
