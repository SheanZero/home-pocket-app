# Phase 11: AnalyticsScreen Unified Dashboard (Variant δ) — Pattern Map

**Mapped:** 2026-05-03
**Files analyzed:** 39 (1 audit + 14 new widgets + 1 screen rewrite + 4 domain/data extensions + 3 use cases + 2 provider extensions + 3 ARB extensions + 12 test files + 8 deletions)
**Analogs found:** 35 / 39 (3 are pure-deletion or planning artifacts; 1 has only partial precedent)

> Pattern map for the planner. Every "NEW" file lists a concrete analog (with file:line) the planner can paste from. The deleted v1.0 widgets remain valuable as `fl_chart` wiring precedent — Phase 11 widgets are clean rebuilds, but the wiring shape (`LineChart` / `BarChart` / `PieChart` constructor + `FlTitlesData` + `BarTouchData`) carries over.

---

## File Classification

### NEW files

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `.planning/phases/11-statistics-surface-for/11-AUDIT.md` | planning artifact | n/a | `.planning/phases/10-*/10-AUDIT.md` (if exists) or any phase footprint audit | meta — no code analog |
| `lib/application/analytics/get_daily_joy_per_yen_use_case.dart` | use case | request-response (per-day fold) | `lib/application/analytics/get_happiness_report_use_case.dart` | exact (same module, same fold pattern) |
| `lib/application/analytics/get_largest_monthly_expense_use_case.dart` | use case | request-response (single argmax) | `lib/application/analytics/get_best_joy_moment_use_case.dart` | exact (single-row argmax pattern) |
| `lib/features/analytics/domain/models/daily_joy_per_yen_point.dart` | domain model (Freezed) | immutable value | `lib/features/analytics/domain/models/best_joy_moment_row.dart` (plain class) or `happiness_report.dart` (Freezed) | role-match |
| `lib/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart` | widget (KPI tile) | sealed-MetricResult dispatch | `lib/features/home/presentation/widgets/home_hero_card.dart` lines 464-516 (`_legendSingle` with `MetricResult` switch + coverage caption) | exact (same sealed-MetricResult dispatch + coverage caption pattern) |
| `lib/features/analytics/presentation/widgets/total_spending_kpi_tile.dart` | widget (KPI tile) | nullable-aware MoM delta | `home_hero_card.dart` lines 105-153 (hero header amount + trend chip) | exact (amount + delta-chip pattern) |
| `lib/features/analytics/presentation/widgets/kpi_mini_hero_strip.dart` | widget (composer) | layout container | `home_hero_card.dart` lines 64-103 (Container + Column composition) | role-match |
| `lib/features/analytics/presentation/widgets/month_chip_picker.dart` | widget (AppBar action) | Riverpod notifier `setMonth(...)` | current `lib/features/analytics/presentation/screens/analytics_screen.dart` lines 238-274 (`_MonthSelector`) — **affordance differs** (chip + sheet vs row of chevrons) | partial (provider call same; UI affordance is new) |
| `lib/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart.dart` | widget (chart) | `BarChart` 6-month series with current-month highlight | `lib/features/analytics/presentation/widgets/expense_trend_chart.dart` (LineChart 6-month) + `daily_expense_chart.dart` (BarChart with `BarChartGroupData`) | role-match (must convert LineChart→BarChart, add current-month highlight) |
| `lib/features/analytics/presentation/widgets/joy_trend_line_chart.dart` | widget (chart) | `LineChart` MTD with **gap-vs-zero segmentation** | `expense_trend_chart.dart` lines 116-138 (multi-`LineChartBarData` pattern) | partial (multi-series shape carries; segmentation logic is NEW per D-06) |
| `lib/features/analytics/presentation/widgets/category_spend_donut_chart.dart` | widget (chart) | `PieChart` (donut) top-N + その他 | `lib/features/analytics/presentation/widgets/category_pie_chart.dart` lines 53-103 | exact (PieChart + Wrap legend; add `centerSpaceRadius` for donut + その他 bucket) |
| `lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart` | widget (chart) | `BarChart` 1-10 buckets + per-bar gradient + 5-bar permanent label | `daily_expense_chart.dart` lines 42-124 (BarChart + tooltip) | partial (BarChart wiring same; per-bar gradient + `BarChartRodData.label` for bar 5 are NEW) |
| `lib/features/analytics/presentation/widgets/largest_expense_story_card.dart` | widget (story strip) | sealed nullable-aware text composition | `home_hero_card.dart` lines 620-673 (`_bestJoyValue` text composition with `category · date · ¥amount`) | exact |
| `lib/features/analytics/presentation/widgets/best_joy_story_strip.dart` | widget (story strip) | sealed `MetricResult<BestJoyMomentRow>` dispatch | `home_hero_card.dart` lines 556-673 (`_buildBestJoyStrip` 3-arm switch — Empty / all-neutral / Value) | exact (carry verbatim; just relocate to analytics widget) |
| `lib/features/analytics/presentation/widgets/family_insight_card.dart` | widget (sentence card) | `FamilyHappiness` aggregate sentence form | `home_hero_card.dart` lines 425-462 (`_legendGroup` consuming `family.familyHighlightsSum` / `sharedJoyInsight` / `medianSatisfaction`) | role-match (D-13: rings → sentence; same source contract, different render) |
| `lib/features/analytics/presentation/widgets/joy_ledger_thin_sample_fallback.dart` | widget (empty state) | n<5 joint replacement of trend+histogram | `home_hero_card.dart` lines 577-618 (`_bestJoyEmpty` 3-line text + tag) — text-fallback structure | role-match (HAPPY-06 / D-07 fallback pattern) |
| `lib/features/analytics/presentation/widgets/analytics_card_error_state.dart` | widget (error shell) | wraps `error.toString()` with i18n string | current `analytics_screen.dart` lines 225-233 (inline error Card — **bad pattern**, REPLACE) | partial (existing site is anti-pattern; new widget is clean per RESEARCH security note) |
| `lib/features/analytics/presentation/widgets/analytics_screen_section_header.dart` | widget (header) | static `━ {label} ━` | none (NEW for Variant δ themed-group H3 rhythm) | no analog (12px caption-700 + ━ glyphs) |
| `lib/features/analytics/presentation/screens/analytics_screen.dart` | screen (rewrite) | parent `AsyncValue.when` over multiple providers | `lib/features/home/presentation/screens/home_screen.dart` lines 80-184 (multi-provider `.when` chain feeding `HomeHeroCard`) | exact |
| `lib/l10n/app_{ja,zh,en}.arb` (extend ~30 keys) | i18n | string table | existing `homeBestJoyAmountSat` / `homeBestJoyTagSingle` / etc. (lines 697-744 of app_ja.arb) | exact |

### MODIFIED files

| Modified File | Role | Data Flow | Closest Analog (in-file) | Match Quality |
|---------------|------|-----------|--------------------------|---------------|
| `lib/data/daos/analytics_dao.dart` (+ `getDailySoulRowsForPtvf`, + `getLargestMonthlyExpense`) | DAO | Drift parameterized SQL | same file, lines 371-398 (`getSoulRowsForPtvf`) and lines 335-366 (`getBestJoyMoment`) | exact |
| `lib/data/repositories/analytics_repository_impl.dart` (+2 forward methods) | repo impl | DAO forward | same file, lines 134-157 (existing forwards) | exact |
| `lib/features/analytics/domain/repositories/analytics_repository.dart` (+2 abstract methods) | repo interface | abstract Future signature | same file, lines 47-58 (existing signatures) | exact |
| `lib/features/analytics/domain/models/analytics_aggregate.dart` (+ `DailySoulRowSampleWithDay`, + `LargestMonthlyExpense` plain classes) | domain model | immutable value | same file, lines 47-52 (`SoulRowSample` plain class) | exact |
| `lib/features/analytics/presentation/providers/repository_providers.dart` (+2 use case providers) | provider wiring | `@riverpod` factory | same file, lines 56-78 (existing use case providers) | exact |
| `lib/features/analytics/presentation/providers/state_happiness.dart` (+3 async providers) | async provider | `@riverpod Future<...>` keyed by `(bookId, year, month, currencyCode)` | same file, lines 14-30 (`happinessReport`) | exact |

### DELETED files (8 widgets + 2 tests + 1 golden)

These widgets carry forward only as **wiring precedent** (fl_chart constructor shapes), not as code to import:

| Deleted File | Last-Use Pattern Worth Carrying |
|--------------|---------------------------------|
| `lib/features/analytics/presentation/widgets/summary_cards.dart` | DELETE — replaced by KPI mini-hero strip |
| `lib/features/analytics/presentation/widgets/category_pie_chart.dart` | DELETE — but `PieChart`/legend wiring ports to `category_spend_donut_chart.dart` |
| `lib/features/analytics/presentation/widgets/daily_expense_chart.dart` | DELETE — but `BarChart` + `FlTitlesData` + `BarTouchData` wiring ports to `monthly_spend_trend_bar_chart.dart` and `satisfaction_distribution_histogram.dart` |
| `lib/features/analytics/presentation/widgets/ledger_ratio_chart.dart` | DELETE — no replacement (D-15 SCOPE simplification) |
| `lib/features/analytics/presentation/widgets/budget_progress_list.dart` | DELETE — no replacement (deferred to v1.2 per CONTEXT Deferred Ideas) |
| `lib/features/analytics/presentation/widgets/expense_trend_chart.dart` | DELETE — but `LineChart` + multi-`LineChartBarData` wiring ports to `joy_trend_line_chart.dart` (gap segmentation) |
| `lib/features/analytics/presentation/widgets/category_breakdown_list.dart` | DELETE — collapsed into donut |
| `lib/features/analytics/presentation/widgets/month_comparison_card.dart` | DELETE — collapsed into KPI tile MoM sub-line |
| `test/widget/features/analytics/presentation/widgets/analytics_money_widgets_test.dart` | DELETE in same Wave 3 commit (RESEARCH Pitfall 1) |
| `test/widget/features/analytics/presentation/screens/analytics_screen_characterization_test.dart` (if exists) | DELETE in Wave 3 |
| `test/golden/summary_cards_golden_test.dart` (if exists per RESEARCH §Hidden imports) | DELETE in Wave 3 |

---

## Pattern Assignments

### `lib/data/daos/analytics_dao.dart` — extend with `getDailySoulRowsForPtvf` (D-05) + `getLargestMonthlyExpense`

**Analog:** same file, `getSoulRowsForPtvf` (lines 371-398) for the daily method; `getBestJoyMoment` (lines 335-366) for the largest-expense method.

**Imports pattern** (lines 1-5):
```dart
import 'package:drift/drift.dart';

import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/models/best_joy_moment_row.dart';
import '../app_database.dart';
```

**Soul-only filter constant — MANDATORY (lines 93-96):**
```dart
/// D-01 / HAPPY-05: ledger + lifecycle filter ONLY. NO satisfaction predicate.
/// Single source of truth: every soul aggregator MUST compose via interpolation.
static const String _soulExpenseFilter =
    "ledger_type = 'soul' AND type = 'expense' AND is_deleted = 0";
```

**Daily group-by + parameterized SQL pattern** (lines 173-204, `getDailyTotals` — adapt for soul-filtered daily Joy/¥ rows):
```dart
final results = await _db
    .customSelect(
      'SELECT DATE(timestamp, \'unixepoch\', \'localtime\') as day, SUM(amount) as total '
      'FROM transactions '
      'WHERE book_id = ? AND is_deleted = 0 AND type = ? '
      'AND timestamp >= ? AND timestamp <= ? '
      'GROUP BY day '
      'ORDER BY day ASC',
      variables: [
        Variable.withString(bookId),
        Variable.withString(type),
        Variable.withDateTime(startDate),
        Variable.withDateTime(endDate),
      ],
    )
    .get();
```

**Soul row-pull pattern (closest analog) — `getSoulRowsForPtvf` (lines 371-398):**
```dart
Future<List<SoulRowSample>> getSoulRowsForPtvf({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final results = await _db
      .customSelect(
        'SELECT amount, soul_satisfaction '
        'FROM transactions '
        'WHERE book_id = ? AND $_soulExpenseFilter '
        'AND timestamp >= ? AND timestamp <= ?',
        variables: [
          Variable.withString(bookId),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
        ],
      )
      .get();

  return results
      .map(
        (row) => SoulRowSample(
          amount: row.read<int>('amount'),
          soulSatisfaction: row.read<int>('soul_satisfaction'),
        ),
      )
      .toList();
}
```

**Composition for `getDailySoulRowsForPtvf` (D-05):** SELECT `DATE(timestamp,'unixepoch','localtime') AS day, amount, soul_satisfaction` FROM transactions WHERE `book_id = ? AND $_soulExpenseFilter AND timestamp BETWEEN ? AND ?` (no GROUP BY — fold happens in Dart). Map each row → new `DailySoulRowSampleWithDay(day, amount, soulSatisfaction)` plain class.

**Single-argmax pattern (closest analog) — `getBestJoyMoment` (lines 335-366):**
```dart
final results = await _db
    .customSelect(
      'SELECT id, amount, soul_satisfaction, category_id, timestamp '
      'FROM transactions '
      'WHERE book_id = ? AND $_soulExpenseFilter '
      'AND timestamp >= ? AND timestamp <= ? '
      'ORDER BY soul_satisfaction DESC, amount DESC, timestamp DESC '
      'LIMIT 1',
      variables: [...],
    )
    .get();

if (results.isEmpty) return null;

final row = results.first;
return BestJoyMomentRow(
  transactionId: row.read<String>('id'),
  amount: row.read<int>('amount'),
  ...
);
```

**Composition for `getLargestMonthlyExpense`:** same shape — SELECT `id, amount, category_id, timestamp` FROM transactions WHERE `book_id = ? AND is_deleted = 0 AND type = 'expense' AND timestamp BETWEEN ? AND ?` (note: NOT `_soulExpenseFilter` — total ledger, includes survival per D-15) ORDER BY `amount DESC, timestamp DESC` LIMIT 1.

---

### `lib/data/repositories/analytics_repository_impl.dart` — extend with 2 forwards

**Analog:** same file, lines 134-157 (`getSoulRowsForPtvf` + `getBestJoyMoment` thin forwards).

**Forward pattern** (lines 134-144):
```dart
@override
Future<List<SoulRowSample>> getSoulRowsForPtvf({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) {
  return _dao.getSoulRowsForPtvf(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
  );
}
```

**Apply to:** `getDailySoulRowsForPtvf` (thin pass-through, return `List<DailySoulRowSampleWithDay>`) and `getLargestMonthlyExpense` (thin pass-through, return `LargestMonthlyExpense?`).

---

### `lib/features/analytics/domain/repositories/analytics_repository.dart` — extend with 2 abstract methods

**Analog:** same file, lines 47-58 (`getSoulRowsForPtvf` / `getBestJoyMoment` signatures).

**Signature pattern:**
```dart
/// HAPPY-02 / D-04 — row-wise (amount, sat) tuples for Dart-layer PTVF fold.
Future<List<SoulRowSample>> getSoulRowsForPtvf({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
});
```

**Apply to:** add 2 new methods with identical `(bookId, startDate, endDate)` named-parameter shape; return types `List<DailySoulRowSampleWithDay>` and `LargestMonthlyExpense?` respectively.

---

### `lib/features/analytics/domain/models/analytics_aggregate.dart` — extend with 2 plain classes

**Analog:** same file, `SoulRowSample` (lines 46-52) for value-type plain class convention.

**Plain immutable class pattern:**
```dart
/// HAPPY-02 row-wise PTVF input row.
class SoulRowSample {
  const SoulRowSample({required this.amount, required this.soulSatisfaction});

  final int amount;
  final int soulSatisfaction;
}
```

**Apply to:**
```dart
class DailySoulRowSampleWithDay {
  const DailySoulRowSampleWithDay({
    required this.day,
    required this.amount,
    required this.soulSatisfaction,
  });
  final DateTime day;
  final int amount;
  final int soulSatisfaction;
}

class LargestMonthlyExpense {
  const LargestMonthlyExpense({
    required this.transactionId,
    required this.amount,
    required this.categoryId,
    required this.timestamp,
  });
  final String transactionId;
  final int amount;
  final String categoryId;
  final DateTime timestamp;
}
```

**Note:** RESEARCH says `daily_joy_per_yen_point.dart` should be **Freezed** (use case OUTPUT, sealed-friendly). The two raw row classes above are plain (mirror existing `SoulRowSample` convention).

---

### `lib/features/analytics/domain/models/daily_joy_per_yen_point.dart` (NEW Freezed)

**Analog:** `lib/features/analytics/domain/models/happiness_report.dart` (Freezed convention) and `best_joy_moment_row.dart` (single-row plain class — partial fit).

**Recommended shape (Freezed):**
```dart
@freezed
class DailyJoyPerYenPoint with _$DailyJoyPerYenPoint {
  const factory DailyJoyPerYenPoint({
    required int day,        // day-of-month 1..31
    required double joyPerYen, // PTVF density for this day
    required int sampleSize,   // # of soul tx folded into this point
  }) = _DailyJoyPerYenPoint;
}
```

Run `flutter pub run build_runner build --delete-conflicting-outputs` after adding.

---

### `lib/application/analytics/get_daily_joy_per_yen_use_case.dart` (NEW)

**Analog:** `lib/application/analytics/get_happiness_report_use_case.dart` lines 16-146 (constructor injection + parallel-fetch + per-row PTVF fold).

**Imports pattern** (lines 1-8):
```dart
import 'dart:math' as math;

import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/models/best_joy_moment_row.dart';
import '../../features/analytics/domain/models/happiness_report.dart';
import '../../features/analytics/domain/models/metric_result.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../infrastructure/i18n/formatters/joy_density_formatter.dart';
```

**Constructor injection pattern (lines 16-26):**
```dart
class GetHappinessReportUseCase {
  GetHappinessReportUseCase({required AnalyticsRepository analyticsRepository})
    : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  /// D-04: Kahneman & Tversky 1979 PTVF empirical fit.
  static const double _ptvfAlpha = 0.88;
```

**PTVF fold pattern (lines 99-111) — MUST be reused for per-day fold:**
```dart
/// HAPPY-02 / D-04: density = Σ(sat × (amount/base)^α) / Σ(amount).
double _computePtvfDensity(List<SoulRowSample> rows, double base) {
  if (rows.isEmpty) return 0;
  var numerator = 0.0;
  var denominator = 0;
  for (final r in rows) {
    final scaled = math.pow(r.amount / base, _ptvfAlpha).toDouble();
    numerator += r.soulSatisfaction * scaled;
    denominator += r.amount;
  }
  if (denominator == 0) return 0;
  return numerator / denominator;
}
```

**Composition for `GetDailyJoyPerYenUseCase`:**
1. Fetch `List<DailySoulRowSampleWithDay>` from repo for `(bookId, startDate, endDate)`
2. `groupBy` day → `Map<int, List<SoulRowSample>>`
3. For each day: compute `_computePtvfDensity(rows, ptvfBaseFor(currencyCode))` (reuse exact formula)
4. Wrap in `MetricResult.Empty()` if total sample size < 5 (D-07 thin-sample fallback at top level), else `MetricResult.Value(List<DailyJoyPerYenPoint>, totalSampleSize)`

**Empty-shortcircuit pattern (lines 67-79):**
```dart
if (totalSoulTx == 0) {
  return HappinessReport(
    ...
    avgSatisfaction: const Empty(),
    joyPerYen: const Empty(),
    ...
  );
}
```

Apply same shape: return `MetricResult.Empty<List<DailyJoyPerYenPoint>>()` when row count is 0 or < threshold.

---

### `lib/application/analytics/get_largest_monthly_expense_use_case.dart` (NEW)

**Analog:** `lib/application/analytics/get_best_joy_moment_use_case.dart` (single-call, single-argmax pattern). Use case body is a single `_repo.getLargestMonthlyExpense(...)` await + null fallback.

Follow same constructor-injected `AnalyticsRepository` pattern; `execute({bookId, year, month})` computes `startDate / endDate` exactly as `get_happiness_report_use_case.dart` lines 34-35:
```dart
final startDate = DateTime(year, month, 1);
final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
```

Return type: `LargestMonthlyExpense?` (nullable for empty months — UI handles via empty-state copy `analyticsCardEmptyLargestExpense`).

---

### `lib/features/analytics/presentation/providers/repository_providers.dart` — extend with 2 use case providers

**Analog:** same file, lines 56-78 (`getHappinessReportUseCase` / `getBestJoyMomentUseCase` / `getFamilyHappinessUseCase`).

**`@riverpod` factory pattern** (lines 56-62):
```dart
/// HAPPY-01..04: GetHappinessReportUseCase provider.
@riverpod
GetHappinessReportUseCase getHappinessReportUseCase(Ref ref) {
  return GetHappinessReportUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}
```

**Apply to:**
```dart
@riverpod
GetDailyJoyPerYenUseCase getDailyJoyPerYenUseCase(Ref ref) {
  return GetDailyJoyPerYenUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

@riverpod
GetLargestMonthlyExpenseUseCase getLargestMonthlyExpenseUseCase(Ref ref) {
  return GetLargestMonthlyExpenseUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}
```

Run `build_runner` after.

---

### `lib/features/analytics/presentation/providers/state_happiness.dart` — extend with 3 async providers

**Analog:** same file, lines 14-42 (`happinessReport` and `bestJoyMoment`). Provider keying: `(bookId, year, month, currencyCode)` for currency-aware metrics, `(bookId, year, month)` otherwise.

**`@riverpod Future` provider pattern** (lines 14-30):
```dart
/// HAPPY-01..04 personal happiness report.
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

**Apply to (mirror exactly):**
```dart
/// STATSUI-01 / D-05 daily Joy/¥ trend (PTVF per-day fold).
@riverpod
Future<MetricResult<List<DailyJoyPerYenPoint>>> dailyJoyPerYen(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
  required String currencyCode,
}) async {
  final useCase = ref.watch(getDailyJoyPerYenUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    year: year,
    month: month,
    currencyCode: currencyCode,
  );
}

/// STATSUI-06 物語 group · 総 card — single largest monthly expense.
@riverpod
Future<LargestMonthlyExpense?> largestMonthlyExpense(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
}) async {
  final useCase = ref.watch(getLargestMonthlyExpenseUseCaseProvider);
  return useCase.execute(bookId: bookId, year: year, month: month);
}
```

For MoM delta KPI sub-line — RESEARCH Open Question 3: just consume `monthlyReport.previousMonthComparison?.expenseChange` directly inside `total_spending_kpi_tile.dart`; **no new provider needed**.

---

### `lib/features/analytics/presentation/screens/analytics_screen.dart` — full rewrite

**Analog:** `lib/features/home/presentation/screens/home_screen.dart` lines 80-184 (multi-provider `.when` chain feeding a single composite widget — except Phase 11 dispatches per-card, not single-composite).

**Currency resolution pattern (home_screen.dart lines 87-96):**
```dart
final bookAsync = ref.watch(
  bookByIdProvider(bookId: bookId),
);

// CLAUDE.md Pitfall #9 — fallback only when Book is missing.
// This is the SOLE legitimate JPY currency-code literal in
// the home feature; future grep audits verify no other site
// re-introduces it.
final currencyCode =
    bookAsync.valueOrNull?.currency ?? 'JPY';
```

**Provider chain composition pattern (home_screen.dart lines 98-135):**
```dart
final happinessAsync = ref.watch(
  happinessReportProvider(
    bookId: bookId,
    year: year,
    month: month,
    currencyCode: currencyCode,
  ),
);
final bestJoyAsync = ref.watch(
  bestJoyMomentProvider(bookId: bookId, year: year, month: month),
);

// Group-mode-only providers — short-circuit to AsyncData(null/[])
// when not in group mode so the .when() chain below resolves
// immediately without spinning on never-watched providers.
final familyAsync = isGroupMode
    ? ref
          .watch(familyHappinessProvider(year: year, month: month))
          .whenData<FamilyHappiness?>((value) => value)
    : const AsyncData<FamilyHappiness?>(null);
final shadowBooksAsync = isGroupMode
    ? ref
          .watch(shadowBooksProvider)
          .whenData<List<ShadowBookInfo>?>((value) => value)
    : const AsyncData<List<ShadowBookInfo>?>(null);
```

**Variant δ deviation (UI-SPEC interaction contract):** Empty/error states render **PER-CARD**, not via single nested `.when` chain. The screen does:
1. AppBar with title + `MonthChipPicker` action
2. `RefreshIndicator` → `SingleChildScrollView` → `Column`
3. Each card widget is a `Consumer` (or receives `AsyncValue<T>` and resolves locally) so that a single failing provider does NOT break adjacent cards (per UI-SPEC Interaction Contracts: "Empty/error states render PER-CARD").

**RefreshIndicator + invalidation pattern (current `analytics_screen.dart` lines 64-73):**
```dart
return Scaffold(
  ...
  body: RefreshIndicator(
    onRefresh: () async {
      ref.invalidate(monthlyReportProvider(bookId: bookId, year: year, month: month));
      ref.invalidate(happinessReportProvider(bookId: bookId, year: year, month: month, currencyCode: currencyCode));
      ref.invalidate(dailyJoyPerYenProvider(...));
      // ... invalidate all consumed providers
    },
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(...)
    ),
  ),
);
```

**Drop pattern (DO NOT carry):** `_generateDemoData` (lines 47-51 + 153-211 of current screen) — RESEARCH §Other landmines recommends drop; Variant δ AppBar is title + month chip only.

---

### `lib/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart` (NEW — 悦己平均 KPI)

**Analog:** `lib/features/home/presentation/widgets/home_hero_card.dart` lines 464-516 (`_legendSingle` — sealed `MetricResult` switch + coverage caption).

**Sealed `MetricResult` consumption pattern (lines 477-481):**
```dart
switch (happiness.joyPerYen) {
  Empty() => empty,
  Value(:final data) => formatJoyDensity(data, currencyCode),
},
```

**Coverage caption pattern (lines 500-509):**
```dart
if (happiness.totalSoulTx > 0) ...[
  const SizedBox(height: 6),
  Text(
    l10n.homeCoverageCaption(_rated(happiness), happiness.totalSoulTx),
    style: AppTextStyles.bodySmall.copyWith(
      color: context.wmTextSecondary,
    ),
  ),
],

// Helper for rated-count extraction:
int _rated(HappinessReport h) => switch (h.avgSatisfaction) {
  Empty() => 0,
  Value(sampleSize: final n) => n,
};
```

**Apply to KPI tile:**
- Mean primary line: `switch (report.avgSatisfaction) { Empty() => l10n.analyticsKpiJoyEmptyCaption, Value(:final data) => data.toStringAsFixed(1) }` rendered with `AppTextStyles.amountLarge`
- Sub-line: median + `n=k/N` via `analyticsKpiJoySubMedianCoverage` ARB key with `(median, k, N)` placeholders
- Tile background: `AppColors.soulLight` (or `context.wmSoulTagBg` for theme-aware) per UI-SPEC color section (悦己 fill #F0F8F4)
- Title color tint: `AppColors.soul`

---

### `lib/features/analytics/presentation/widgets/total_spending_kpi_tile.dart` (NEW — 総支出 KPI)

**Analog:** `home_hero_card.dart` lines 105-153 (`_hero` — total amount + trend chip + previous-month sub-line).

**Amount formatting pattern (lines 122-138):**
```dart
Text(
  _fmt.formatCurrency(total, currencyCode, locale),
  style: AppTextStyles.amountLarge.copyWith(
    color: context.wmTextPrimary,
  ),
),
```

**Trend delta chip pattern (lines 155-182):**
```dart
Widget _trendChip(int trend) {
  final text = trend <= 0 ? '$trend%' : '+$trend%';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.oliveLight,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          trend <= 0 ? Icons.trending_down : Icons.trending_up,
          size: 14,
          color: AppColors.olive,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.olive,
          ),
        ),
      ],
    ),
  );
}
```

**Apply to total spending KPI tile:**
- Background fill: `AppColors.survivalLight` (#E8F0F8 — close to UI-SPEC #F0F6FB; planner may add `survivalTint` token if exact match required, but milestone-start "不动色调" lock suggests reusing existing token)
- Title color tint: `AppColors.survival`
- Sub-line: `report.previousMonthComparison?.expenseChange` → choose `analyticsKpiTotalDeltaIncreased` / `analyticsKpiTotalDeltaDecreased` ARB key based on sign; omit sub-line if null
- **Forbidden copy:** "vs last month: +X%" framing — use `↓ -{pct}% MoM` / `↑ +{pct}% MoM` neutral framing per UI-SPEC

---

### `lib/features/analytics/presentation/widgets/joy_trend_line_chart.dart` (NEW — Joy/¥ MTD with gap-vs-zero)

**Analog:** `lib/features/analytics/presentation/widgets/expense_trend_chart.dart` lines 39-146 (LineChart wiring), but with a NEW segmentation step (D-06).

**`fl_chart` LineChart wiring pattern (expense_trend_chart.dart lines 63-139):**
```dart
SizedBox(
  height: 200,
  child: LineChart(
    LineChartData(
      maxY: maxY,
      minY: 0,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= trendData.months.length) {
                return const SizedBox.shrink();
              }
              final m = trendData.months[idx];
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.analyticsMonthNumberLabel(m.month),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: maxY / 4,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const SizedBox.shrink();
              return Text(
                formatter.formatCompact(value, locale),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: expenseSpots,
          isCurved: true,
          color: Colors.red,            // ← REPLACE with AppColors.soul (Phase 11)
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.red.withValues(alpha: 0.1),  // ← REPLACE
          ),
        ),
        // ... 2nd LineChartBarData for income — Phase 11 will use this
        //     same multi-series shape for SEGMENTED lines instead.
      ],
    ),
  ),
),
```

**NEW for Phase 11 — gap-vs-zero segmentation (D-06, RESEARCH Pattern 4):**
```dart
// Split List<DailyJoyPerYenPoint> into List<List<DailyJoyPerYenPoint>>
// where each inner list is a contiguous run of days with data.
List<List<DailyJoyPerYenPoint>> _splitIntoContiguousSegments(
  List<DailyJoyPerYenPoint> points,
  int monthDays,
) {
  // Walk day 1..monthDays; whenever a day has no point, close current segment.
  final segments = <List<DailyJoyPerYenPoint>>[];
  List<DailyJoyPerYenPoint> current = [];
  final byDay = {for (final p in points) p.day: p};
  for (var d = 1; d <= monthDays; d++) {
    final point = byDay[d];
    if (point != null) {
      current.add(point);
    } else if (current.isNotEmpty) {
      segments.add(current);
      current = [];
    }
  }
  if (current.isNotEmpty) segments.add(current);
  return segments;
}

// In build():
return LineChart(LineChartData(
  minX: 1,
  maxX: monthDays.toDouble(),
  minY: 0,                       // baseline-anchored y-axis (D-06)
  maxY: maxObservedJoy * 1.2,
  lineBarsData: [
    for (final seg in segments)
      LineChartBarData(
        spots: seg.map((p) => FlSpot(p.day.toDouble(), p.joyPerYen)).toList(),
        color: AppColors.soul,
        barWidth: 3,
        isCurved: false,         // straight segments preserve "gap" semantics
        dotData: const FlDotData(show: true),
      ),
  ],
));
```

**Currency-aware Y-axis label (RESEARCH Pitfall 4):**
```dart
// REPLACE formatter.formatCompact(...) with:
formatJoyDensity(value, currencyCode)  // from joy_density_formatter.dart
```

---

### `lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart` (NEW — 1-10 BarChart with bar-5 annotation)

**Analog:** `lib/features/analytics/presentation/widgets/daily_expense_chart.dart` lines 42-124 (BarChart + tooltip + axis titles).

**BarChart constructor pattern (daily_expense_chart.dart lines 42-124):**
```dart
BarChart(
  BarChartData(
    maxY: maxY,
    barGroups: dailyExpenses.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.amount.toDouble(),
            color: Colors.red.shade400,
            width: dailyExpenses.length > 28 ? 6 : 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
        ],
      );
    }).toList(),
    gridData: FlGridData(...),
    titlesData: FlTitlesData(...),
    borderData: FlBorderData(show: false),
    barTouchData: BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final day = group.x + 1;
          return BarTooltipItem(
            '${l10n.analyticsDayNumberLabel(day)}\n'
            '${formatter.formatCurrency(rod.toY, 'JPY', locale)}',  // ← FIX: avoid 'JPY' literal in Phase 11
            AppTextStyles.amountSmall.copyWith(...),
          );
        },
      ),
    ),
  ),
),
```

**NEW for Phase 11 — per-bar gradient (UI-SPEC Color section, D-10):**
- Pre-compute the 10 colors via `Color.lerp` between `AppColors.survival` (1) → `AppColors.soul` (5) → `AppColors.olive` (intermediate 6-7) → `AppColors.accentPrimary` (10) per the UI-SPEC table.
- Each `BarChartRodData.color` is `gradientColors[score - 1]`.
- **Always render all 10 bars** (RESEARCH Pitfall 5 — zero-fill missing scores with `toY: 0` 1px stub).

**NEW for Phase 11 — bar-5 permanent label (RESEARCH Pattern 3 + Assumption A1):**
```dart
// fl_chart 0.69 BarChartRodData supports rodStackItems[*].label and a top-level
// label is via BarChartRodLabel attached on the rod. Verify exact API name in
// Wave 1 stub call. Fallback: render as Stack overlay above the chart Container.
BarChartRodData(
  toY: count.toDouble(),
  color: gradientColors[4],  // bar 5 = soul green
  // label: BarChartRodLabel(
  //   show: true,
  //   text: l10n.analyticsHistogramBarFiveAnnotation,  // 「中央値・含未評価」
  //   style: AppTextStyles.caption.copyWith(color: AppColors.soul),
  //   offset: const Offset(0, -8),
  // ),
)
```

**Persistent ADR-014 guard caption (UI-SPEC Color section + Pitfall 7):**
```dart
// Below the BarChart, render:
Text(
  l10n.analyticsHistogramColorCaption,  // "色は ordinal 表現です"
  style: AppTextStyles.caption.copyWith(color: context.wmTextSecondary),
)
```

**Forbidden:** any `accessibilityLabel` text containing 「差/悪い/bad/不好/低/不满」 — Pitfall 7. Use only "satisfaction value + count + total" via `Semantics(label: ...)`.

---

### `lib/features/analytics/presentation/widgets/category_spend_donut_chart.dart` (NEW — top-N + その他 PieChart)

**Analog:** `lib/features/analytics/presentation/widgets/category_pie_chart.dart` lines 53-103 (PieChart + legend Wrap).

**PieChart construction pattern (category_pie_chart.dart lines 53-74):**
```dart
PieChart(
  PieChartData(
    sections: top.asMap().entries.map((entry) {
      final i = entry.key;
      final b = entry.value;
      return PieChartSectionData(
        value: b.amount.toDouble(),
        title: '${b.percentage.toStringAsFixed(0)}%',
        color: _chartColors[i % _chartColors.length],
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList(),
    sectionsSpace: 2,
    centerSpaceRadius: 35,    // ← This is what makes it a "donut" — Phase 11 keeps
  ),
),
```

**Legend pattern (lines 76-98):**
```dart
Wrap(
  spacing: 16,
  runSpacing: 4,
  children: top.asMap().entries.map((entry) {
    final i = entry.key;
    final b = entry.value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _chartColors[i % _chartColors.length],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(b.categoryName, style: const TextStyle(fontSize: 12)),
      ],
    );
  }).toList(),
),
```

**Phase 11 deltas:**
- Replace inline hex `_chartColors` palette with project tokens (UI-SPEC Color forbidden list rule — no `Color(0xFF...)`). Use `AppColors.survival` as anchor + cycled tints.
- **Top-N + その他 bucket logic** (Don't Hand-Roll — RESEARCH §Don't Hand-Roll): take first N=6 from `categoryBreakdowns` (already sorted DESC by SQL — `getCategoryTotals` line 151), sum the rest into a synthetic "その他" entry. Use `S.of(context).analyticsCardCaptionCategoryDonut` for caption with "Donut/PieChart · top-N + その他".

---

### `lib/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart.dart` (NEW — 6か月 BarChart)

**Analog:** combine `expense_trend_chart.dart` (6-month series shape) + `daily_expense_chart.dart` (BarChart wiring).

**Composition:** consume `ExpenseTrendData` from `expenseTrendProvider` (existing), but RESEARCH §Other landmines flags that current `expenseTrendProvider` is NOT keyed by selected month — for Variant δ where the user picks a month, the planner should change `GetExpenseTrendUseCase.execute` signature to accept an `anchor` DateTime so the 6-month window trails the selected month, not `DateTime.now()`. **Reference signature change site:** `lib/application/analytics/get_expense_trend_use_case.dart` (planner verifies before commit).

**Current-month highlight delta:** for the bar matching `(report.year, report.month) == (selected.year, selected.month)`, set `BarChartRodData.borderSide = BorderSide(color: AppColors.survival, width: 2)` and stronger fill. Other bars: regular `AppColors.survivalLight` fill + `AppColors.survival` thin stroke.

---

### `lib/features/analytics/presentation/widgets/largest_expense_story_card.dart` (NEW — 物語 group · 総 card)

**Analog:** `home_hero_card.dart` lines 620-673 (`_bestJoyValue` — `category · date · ¥amount` text composition).

**Carry verbatim (lines 626-635):**
```dart
final category = CategoryLocalizationService.resolveFromId(
  row.categoryId,
  locale,
);
final dateLabel = DateFormatter.formatShortMonthDay(row.timestamp, locale);
final amountText = _fmt.formatCurrency(row.amount, currencyCode, locale);
```

**Empty state pattern (lines 577-618 of home_hero_card.dart `_bestJoyEmpty`):** 3-line tag/big/small text composition. Phase 11 uses `analyticsCardEmptyLargestExpense` ARB key for the body string when `LargestMonthlyExpense?` is null.

**Card decoration:** `BoxDecoration(color: AppColors.survivalLight, border: Border.all(color: AppColors.survival.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(14))` per UI-SPEC D-17.

**Tap navigation (UI-SPEC Interaction Contracts):** `Navigator.push(... TransactionDetailScreen(transactionId))`. Verify TransactionDetailScreen exists and accepts `transactionId` in plan.

---

### `lib/features/analytics/presentation/widgets/best_joy_story_strip.dart` (NEW — 物語 group · 悦己 card)

**Analog:** `home_hero_card.dart` lines 556-673 (`_buildBestJoyStrip` 3-arm switch — Empty / all-neutral (sat ≤ 2) / Value).

**Carry the 3-arm switch verbatim:**
```dart
return switch (bestJoy) {
  Empty() => _bestJoyEmpty(context, ...),
  Value(:final data) when data.soulSatisfaction <= 2 => _bestJoyEmpty(...),
  Value(:final data) => _bestJoyValue(context, l10n, tagText, data),
};
```

**Phase 11 ARB keys (from UI-SPEC Copywriting):**
- `analyticsCardTitleBestJoy` → "悦己 · 今月のベスト ジョイ"
- `analyticsCardSmallBestJoy` → "{amount} · 満足 {sat}/10 ✨" (placeholder for `amount` String + `sat` int — same shape as existing `homeBestJoyAmountSat`)
- `analyticsCardEmptyBestJoy` → "今月の最大ハイライトはまだ見つからない"

**Card decoration:** soul-tinted (`AppColors.soulLight` fill + `AppColors.soul` border accent).

**D-14 binding:** Phase 11 best-joy widget is a **separate widget instance** — DO NOT extract a shared base widget with `home_hero_card.dart`. The two contracts are different (hero-level vs analytics-card-level).

---

### `lib/features/analytics/presentation/widgets/family_insight_card.dart` (NEW — group mode only, ochre card)

**Analog:** `home_hero_card.dart` lines 425-462 (`_legendGroup` — sealed dispatch on `family.familyHighlightsSum` / `sharedJoyInsight` / `medianSatisfaction`).

**Source contract dispatch pattern (lines 432-459):**
```dart
_legendRow(
  context,
  AppColors.shared,
  l10n.homeFamilyHighlightsLegend,
  switch (f?.familyHighlightsSum) {
    null || Empty() => empty,
    Value(:final data) => '$data',
  },
),
const SizedBox(height: 6),
_legendRow(
  context,
  AppColors.accentPrimary,
  l10n.homeSharedJoyLegend,
  switch (f?.sharedJoyInsight) {
    null || Empty() => empty,
    Value() => '✓',
  },
),
const SizedBox(height: 6),
_legendRow(
  context,
  AppColors.olive,
  l10n.homeMedianSatisfactionLegend,
  switch (f?.medianSatisfaction) {
    null || Empty() => empty,
    Value(:final data) => data.toStringAsFixed(1),
  },
),
```

**D-13 binding:** Phase 11 transforms this from **rings/legend-row form** → **sentence form**:
- `familyHighlightsSum` → `analyticsFamilyHighlightsSentence` ("今月、家族の小確幸 {N}回")
- `sharedJoyInsight` → `analyticsFamilySharedJoySentence` ("みんなで [{categoryName}] が好きみたい (n={count}, 平均{avg}/10)")
- empty → `analyticsFamilyEmpty`

**MUST consume only:** `family.familyHighlightsSum` (int), `family.sharedJoyInsight` (`MetricResult<SharedJoyInsight>`). MUST NOT consume any per-member fields. Compile-time enforcement via Phase 9 D-08.

**Card decoration (UI-SPEC D-17):** ochre fill (`#FFF7E6`) + ochre stroke (`#F0E0BC`) + title color `AppColors.olive` (closest project token to ochre `#A8842A`). If exact match required, planner adds `AppColors.familyTint` (or planner uses `AppColors.sharedLight` `#FFF0E0` which is the closest existing token).

**Render gate (RESEARCH Pitfall 6):**
```dart
final showFamily = isGroupMode && (shadowBooks?.isNotEmpty ?? false);
if (!showFamily) return const SizedBox.shrink();
```

Same shape as `home_hero_card.dart` line 66.

---

### `lib/features/analytics/presentation/widgets/joy_ledger_thin_sample_fallback.dart` (NEW — D-07 joint fallback)

**Analog:** `home_hero_card.dart` lines 577-618 (`_bestJoyEmpty` — tag + big + small + CTA-style text composition).

**Composition:** when `dailyJoyPerYen.totalSampleSize < 5` (HAPPY-06 / D-07), the screen REPLACES both the 時間-group 悦己 card AND the 分布-group 悦己 card with this single fallback card. Inputs: `int totalSoulTx`, `VoidCallback onAddEntryTap`. Strings: `analyticsThinSampleFallbackHeading` + `analyticsThinSampleFallbackBody` + `analyticsThinSampleFallbackCta` + navigate to transaction add screen.

---

### `lib/features/analytics/presentation/widgets/analytics_card_error_state.dart` (NEW — per-card error shell)

**Analog (REPLACE the bad inline pattern in current screen lines 225-233):**
```dart
// ❌ CURRENT — leaks raw error to UI
error: (error, _) => Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Text(
      'Error: $error',
      style: const TextStyle(color: Colors.red),
    ),
  ),
),
```

**Apply (RESEARCH §Security Domain):**
```dart
class AnalyticsCardErrorState extends StatelessWidget {
  const AnalyticsCardErrorState({
    super.key,
    required this.onRetry,
  });
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.analyticsCardErrorHeading, style: AppTextStyles.titleLarge),
            const SizedBox(height: 4),
            Text(l10n.analyticsCardErrorBody, style: AppTextStyles.bodyMedium.copyWith(color: context.wmTextSecondary)),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: Text(l10n.analyticsCardErrorRetry)),
          ],
        ),
      ),
    );
  }
}
```

**MUST NOT** call `error.toString()` — never leak SQL exceptions to UI.

---

### `lib/features/analytics/presentation/widgets/month_chip_picker.dart` (NEW — AppBar trailing chip)

**Analog (provider call):** current `analytics_screen.dart` lines 238-274 (`_MonthSelector` — uses `selectedMonthProvider.notifier.previousMonth()` / `nextMonth()`).

**Provider call shape (preserve):**
```dart
ref.read(selectedMonthProvider.notifier).setMonth(picked);
```

**Affordance change (RESEARCH Pitfall 2):** Variant δ replaces row-of-chevrons with a **chip → bottom sheet** flow:
1. Render a compact chip in `AppBar.actions` slot showing current month + ▼ glyph (use `FormatterService.formatMonthYear(...)` for label).
2. Tap → `showModalBottomSheet` with month picker UI (months from earliest tx month to current — use `transactions` MIN(timestamp) to compute).
3. On selection: `ref.read(selectedMonthProvider.notifier).setMonth(picked)`.
4. **Tap target:** outer `Padding` ≥ 44×44px around the chip glyph (UI-SPEC Accessibility).

**DO NOT remove `previousMonth()` / `nextMonth()` from notifier** (Pitfall 2) — characterization tests reference them, and they remain as part of the public API even if the new picker doesn't use them.

---

### `lib/features/analytics/presentation/widgets/analytics_screen_section_header.dart` (NEW)

**Analog:** none. Pure new widget — render `━ {label} ━` (literal U+2501 box-drawing chars) in `AppTextStyles.caption.copyWith(color: const Color(0xFF374151), fontWeight: FontWeight.w700)` per UI-SPEC § Themed group headers.

UI-SPEC explicitly bans replacing the `━` glyphs with `Divider` widgets — they are part of the visual rhythm.

---

### `lib/l10n/app_{ja,zh,en}.arb` — extend ~30 keys (HARD-LOCKED bar-5 + ~28 dashboard keys)

**Analog:** `lib/l10n/app_ja.arb` lines 705-744 (`homeBestJoyAmountSat` with placeholder block) for placeholder-bearing key shape.

**Placeholder key shape (existing — exact pattern to mirror):**
```json
"homeBestJoyAmountSat": "{amount}・満足 {sat}/10 ✨",
"@homeBestJoyAmountSat": {
  "description": "Best Joy strip small line composing amount and satisfaction (D-04)",
  "placeholders": {
    "amount": {
      "type": "String"
    },
    "sat": {
      "type": "int"
    }
  }
}
```

**HARD-LOCKED bar-5 trilingual annotation (STATSUI-02 — must be added in Wave 1):**
```json
// app_ja.arb
"analyticsHistogramBarFiveAnnotation": "中央値・含未評価",
"@analyticsHistogramBarFiveAnnotation": {
  "description": "Permanent annotation above bar 5 of satisfaction histogram acknowledging default-5 cluster + East-Asian central-tendency clustering (STATSUI-02 HARD-LOCKED)"
}

// app_zh.arb
"analyticsHistogramBarFiveAnnotation": "中位数·含未评分",

// app_en.arb
"analyticsHistogramBarFiveAnnotation": "Median + unrated",
```

**~28 additional keys** — see RESEARCH §i18n Workflow lines 683-734 for the full proposed list under namespace `analytics*` (sub-prefixes `analyticsKpi*` / `analyticsTime*` / `analyticsDistribution*` / `analyticsStory*` / `analyticsFamily*`).

**ARB-parity rule (Pitfall 6):** add to all 3 files in the **same commit** + run `flutter gen-l10n` immediately. CI guardrail will block PR otherwise.

---

### Test files

**Analog for unit DAO test:** `test/unit/data/daos/analytics_dao_happiness_test.dart` lines 1-106 — `AppDatabase.forTesting()` + `setUp` / `tearDown` + `seedTx` helper + `_soulOnly` filter coverage.

**Pattern to copy verbatim (lines 13-21):**
```dart
late AppDatabase db;
late AnalyticsDao dao;

final windowStart = DateTime(2026, 5);
final windowEnd = DateTime(2026, 5, 31, 23, 59, 59);

setUp(() {
  db = AppDatabase.forTesting();
  dao = AnalyticsDao(db);
});

tearDown(() async {
  await db.close();
});
```

**Apply to:**
- `test/unit/data/daos/analytics_dao_daily_joy_test.dart` (Wave 1) — covers `getDailySoulRowsForPtvf`
- `test/unit/data/daos/analytics_dao_largest_expense_test.dart` (or extend daily_joy file) — covers `getLargestMonthlyExpense`

**Analog for unit use-case test:** `test/unit/application/analytics/get_happiness_report_use_case_test.dart` lines 1-117 — `mocktail` `Mock implements AnalyticsRepository` + `stubReportInputs(...)` helper.

**Mocktail pattern (lines 12-60):**
```dart
class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

setUp(() {
  repository = _MockAnalyticsRepository();
  useCase = GetHappinessReportUseCase(analyticsRepository: repository);
});

void stubReportInputs({...}) {
  when(
    () => repository.getSoulSatisfactionOverview(...),
  ).thenAnswer((_) async => overview);
  // ...
}
```

**Analog for widget test:** `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` lines 1-104 (Pure-StatelessWidget testing without provider scope) and `test/helpers/test_localizations.dart` (`testLocalizedApp` wrapper).

**Localized-app wrapper (test_localizations.dart):**
```dart
Widget testLocalizedApp({
  required Widget child,
  Locale locale = const Locale('ja'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: child,
  );
}
```

**Fixture pattern:** `test/helpers/happiness_test_fixtures.dart` — extend with new fixtures (`fixtureDailyJoyPointsRich()`, `fixtureLargestExpense()`, `fixtureDailyJoyEmpty()`, etc.). Pure functions, no `DateTime.now()`.

---

## Shared Patterns

### Sealed `MetricResult<T>` switch dispatch (Phase 9 D-13)

**Source:** `lib/features/analytics/domain/models/metric_result.dart` lines 16-29.
**Apply to:** every Phase 11 widget consuming a `MetricResult<T>` field of `HappinessReport` / `dailyJoyPerYen` / `bestJoyMoment`.

```dart
switch (result) {
  case Empty():
    return _emptyState(...);
  case Value(:final data, :final sampleSize):
    return _valueState(data, sampleSize);
}
```

**Forbidden:** `result is Value<T>` runtime checks instead of pattern matching (loses sample-size extraction).

---

### Drift parameterized SQL with `_soulExpenseFilter` interpolation

**Source:** `lib/data/daos/analytics_dao.dart` lines 95-96 (the constant) and lines 242-265 (`getSoulSatisfactionOverview` showing interpolation usage).
**Apply to:** `getDailySoulRowsForPtvf` (Soul-only — uses `_soulExpenseFilter`); `getLargestMonthlyExpense` (NOT soul-only — uses `is_deleted = 0 AND type = 'expense'` directly per D-15: total ledger).

**SQL injection prevention (Security):** ALL user-derived values bind via `Variable.withString(...)` / `Variable.withDateTime(...)`. NEVER string-concat (RESEARCH §Security V5).

---

### Currency-code resolution (CLAUDE.md Pitfall #9)

**Source:** `lib/features/home/presentation/screens/home_screen.dart` lines 87-96 — the only legitimate `'JPY'` literal in the home feature.

**Apply to:** every chart widget receiving currency. Constructor-inject `currencyCode` from screen-level `bookByIdProvider(bookId).valueOrNull?.currency ?? 'JPY'` resolution. Y-axis labels use `formatJoyDensity(value, currencyCode)` (joy_density_formatter.dart). Tooltip amounts use `FormatterService().formatCurrency(amount, currencyCode, locale)`.

**Forbidden:** any `'JPY'` literal inside Phase 11 widget files.

---

### Amount text style (CLAUDE.md Amount Display Style)

**Source:** `lib/core/theme/app_text_styles.dart` lines 145-168 (`amountLarge` / `amountMedium` / `amountSmall` with `_tabularFigures` `FontFeatures`).

**Apply to:** every monetary value (`¥{amount}`) and KPI primary value rendered:
- KPI mini-hero values → `amountLarge`
- Best Joy strip ¥ amount, chart tooltip values → `amountMedium`
- Y-axis numeric labels → `amountSmall`

**Reference consumer:** `home_hero_card.dart` lines 132-138, 261-262, 322-326, 743-748.

**Forbidden:** generic `TextStyle(...)` literals for monetary values; `headlineLarge` / `headlineMedium` / `headlineSmall` (Phase 10 hero territory; Variant δ uses `titleLarge` for cards).

---

### Theme-aware color resolution

**Source:** `lib/core/theme/app_theme_colors.dart` (`context.wm*` extensions) + `lib/core/theme/app_colors.dart` (`AppColors.soul` / `AppColors.survival` / `AppColors.olive` / `AppColors.accentPrimary`).

**Apply to:** every widget background / border / divider color. Theme-dependent → `context.wmCard` / `context.wmBorderDefault` / `context.wmTextPrimary` / `context.wmTextSecondary`. Theme-stable accents → `AppColors.soul` / `AppColors.survival` / `AppColors.olive`.

**Reference consumer:** `home_hero_card.dart` lines 73-75, 124-126, 257.

**Forbidden (UI-SPEC Color section):**
- `Color(0xFF...)` literals in widget code (caption tint `#374151` is the sole exception — section-header chrome)
- New tokens added to `app_colors.dart` ("不动色调" milestone-start lock)

---

### Family-mode render gate (D-13 + Phase 10 D-08 minimum)

**Source:** `lib/features/home/presentation/widgets/home_hero_card.dart` line 66:
```dart
final showMembers = isGroupMode && (shadowBooks?.isNotEmpty ?? false);
```

**Apply to:** `family_insight_card.dart` (only widget conditioned on group mode in Phase 11). Same expression. Render `SizedBox.shrink()` otherwise.

---

### `@riverpod` Future provider keying

**Source:** `lib/features/analytics/presentation/providers/state_happiness.dart` lines 14-30.

**Apply to:** all 3 new providers in `state_happiness.dart`. Keying:
- Currency-aware metrics → key by `(bookId, year, month, currencyCode)`
- Currency-agnostic → key by `(bookId, year, month)`

This ensures chart provider auto-invalidates when `selectedMonthProvider` notifies.

**Forbidden:** providers keyed only by `bookId` (current `expenseTrendProvider` is — RESEARCH §Other landmines flags this as a planner decision; recommend changing signature to accept anchor month).

---

### i18n string consumption

**Source:** every screen — `S.of(context).<key>` pattern.

**Apply to:** every user-visible string. NEVER hardcode UI text in widget code.

**Reference consumer:** `home_hero_card.dart` line 65 (`final l10n = S.of(context);`) + lines 117-118 (`l10n.homeHeroCardLabelGroup`).

**Forbidden:** hardcoded UI strings like `'No expense data'` (current `category_pie_chart.dart` line 30 — bad pattern, do NOT carry).

---

## No Analog Found

Files with no close existing match — planner uses RESEARCH.md patterns + UI-SPEC contract instead:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.planning/phases/11-statistics-surface-for/11-AUDIT.md` | meta (planning) | n/a | Planning artifact (STATSUI-04 footprint audit). No code analog needed. |
| `lib/features/analytics/presentation/widgets/analytics_screen_section_header.dart` | UI chrome | static text rendering | Themed-group H3 with `━` glyphs is new for Variant δ. No existing widget with this rhythm. |
| The **gap-vs-zero segmented LineChart** logic inside `joy_trend_line_chart.dart` | chart algorithm | day-walk grouping | NEW for Phase 11 per D-06. No existing widget segments by data presence. |
| The **per-bar gradient + bar-5 permanent label** logic inside `satisfaction_distribution_histogram.dart` | chart algorithm | per-rod styling | NEW per D-09/D-10. RESEARCH Pattern 3 + Assumption A1 cover the API surface. |

---

## Metadata

**Analog search scope:** `lib/features/{analytics,home,family_sync,accounting}/`, `lib/data/daos/`, `lib/data/repositories/`, `lib/application/analytics/`, `lib/core/theme/`, `lib/infrastructure/i18n/formatters/`, `lib/l10n/`, `test/unit/data/daos/`, `test/unit/application/analytics/`, `test/widget/features/{analytics,home}/`, `test/helpers/`.

**Files scanned:** 18 source files Read end-to-end (or targeted ranges), 6 directories `ls`-enumerated, ARB key conventions sampled.

**Pattern extraction date:** 2026-05-03

---

## PATTERN MAPPING COMPLETE
