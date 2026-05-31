# Phase 27: Calendar Header + Month Summary - Pattern Map

**Mapped:** 2026-05-30
**Files analyzed:** 7 (3 new source, 1 modified source, 2 new test, 1 modified config)
**Analogs found:** 6 / 7 (pubspec.yaml has no meaningful analog — plain dependency addition)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/features/list/presentation/providers/state_calendar_totals.dart` | provider | request-response (async family) | `lib/features/analytics/presentation/providers/state_analytics.dart` | exact |
| `lib/features/list/presentation/widgets/list_calendar_header.dart` | widget | event-driven + request-response | `lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart` | role-match |
| `lib/features/list/presentation/screens/list_screen.dart` (MODIFY) | screen integration | request-response | `lib/features/list/presentation/screens/list_screen.dart` (itself) | self |
| `pubspec.yaml` (MODIFY) | config | — | n/a | no analog |
| `test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart` | test (unit/provider) | request-response | `test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` | exact |
| `test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` | test (widget) | event-driven | `test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart` | role-match |

---

## Pattern Assignments

### `lib/features/list/presentation/providers/state_calendar_totals.dart` (provider, async family)

**Analog:** `lib/features/analytics/presentation/providers/state_analytics.dart`

**Imports pattern** (state_analytics.dart lines 1-9):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../accounting/domain/models/entry_source.dart';
import '../../domain/models/analytics_aggregate.dart';
import '../../domain/models/expense_trend.dart';
import '../../domain/models/monthly_report.dart';
import 'repository_providers.dart';
import 'state_joy_metric_variant.dart';

part 'state_analytics.g.dart';
```

For `state_calendar_totals.dart`, adapt the import pattern as:
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
import '../../../../shared/utils/date_boundaries.dart';

part 'state_calendar_totals.g.dart';
```

**Core `@riverpod` async family pattern** (state_analytics.dart lines 13-32 — `monthlyReport` provider as reference):
```dart
/// Monthly report for the selected window.
@riverpod
Future<MonthlyReport> monthlyReport(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  JoyMetricVariant joyMetricVariant = JoyMetricVariant.all,
}) async {
  final useCase = ref.watch(getMonthlyReportUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    entrySourceFilter: entrySourceFilter,
  );
}
```

For `calendarDailyTotals`, follow this exact shape but with `(bookId, year, month)` named params:
```dart
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
    // type defaults to 'expense' — expense-only basis (D-09, Pitfall 6)
  );
  return {for (final t in totals) _dayKey(t.date): t.totalAmount};
}
```

**DateTime key normalization helper** (file-scope, before the provider):
```dart
/// Normalizes a DateTime to date-only key (strips time-of-day).
/// Used by the provider when building map keys AND by the cell builder
/// when looking up a day's total. Both sides MUST use this function
/// to avoid silent lookup misses (Pitfall 1 — highest risk).
DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);
```

**`analyticsRepositoryProvider` import rule** (repository_providers.dart line 34):
```dart
// Plain Provider<AnalyticsRepository> — not @riverpod.
// Import with `show` clause to avoid namespace pollution.
// DO NOT re-declare in list feature's repository_providers.dart.
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(dao: ref.watch(analyticsDaoProvider));
});
```

**`DateBoundaries.monthRange` return shape** (date_boundaries.dart lines 30-35):
```dart
// Returns a record ({DateTime start, DateTime end}).
// start = DateTime(year, month)          // 00:00:00 local
// end   = DateTime(year, month+1, 0, 23, 59, 59)  // last day local
static ({DateTime start, DateTime end}) monthRange(int year, int month) {
  return (
    start: DateTime(year, month),
    end: DateTime(year, month + 1, 0, 23, 59, 59),
  );
}
```

---

### `lib/features/list/presentation/widgets/list_calendar_header.dart` (widget, event-driven + request-response)

**Analog:** `lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart`

**Widget class declaration + constructor pattern** (soul_vs_survival_card.dart lines 29-48):
```dart
class SoulVsSurvivalCard extends ConsumerWidget {
  const SoulVsSurvivalCard({
    super.key,
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.currencyCode,
    required this.locale,
    required this.isGroupMode,
    this.joyMetricVariant = JoyMetricVariant.all,
  });

  final String bookId;
  final DateTime startDate;
  ...
```

For `CalendarHeaderWidget`:
```dart
class CalendarHeaderWidget extends ConsumerWidget {
  const CalendarHeaderWidget({
    super.key,
    required this.bookId,
    required this.currencyCode,  // pass from ListScreen; avoids bookByIdProvider import-guard risk
    required this.locale,
  });

  final String bookId;
  final String currencyCode;
  final Locale locale;
```

**`ref.watch` with async family provider** (soul_vs_survival_card.dart lines 50-58):
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final asyncSnapshot = ref.watch(
    soulVsSurvivalSnapshotProvider(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      joyMetricVariant: joyMetricVariant,
    ),
  );
```

For the calendar widget, read both the filter state and the async totals:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final filter = ref.watch(listFilterProvider);
  final calendarAsync = ref.watch(
    calendarDailyTotalsProvider(
      bookId: bookId,
      year: filter.selectedYear,
      month: filter.selectedMonth,
    ),
  );
```

**`asyncValue.when(...)` pattern** (soul_vs_survival_card.dart lines 90-123):
```dart
asyncSnapshot.when(
  loading: () => const SizedBox(height: 200),
  error: (_, _) => AnalyticsCardErrorState(
    onRetry: () => ref.invalidate(...),
  ),
  data: (result) => switch (result) {
    ...
  },
),
```

For the calendar widget's SummaryRow amount slot:
```dart
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
  error: (e, _) => Text(
    S.of(context).calLoadError,
    style: AppTextStyles.caption,
  ),
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

**`NumberFormatter` usage pattern** (number_formatter.dart lines 16-52):
```dart
// Day cell compact amount (D-01):
NumberFormatter.formatCompact(dayTotal, locale)
// Signature: static String formatCompact(num number, Locale locale)
// ja/zh: 10000+ → "1.2万"; en: NumberFormat.compact

// Summary month/day total (SC#4 / D-06):
NumberFormatter.formatCurrency(amount, currencyCode, locale)
// Signature: static String formatCurrency(num amount, String currencyCode, Locale locale)
// JPY: 0 decimals (¥12,345); USD/EUR/GBP: 2 decimals
```

**`DateFormatter` usage pattern** (date_formatter.dart lines 32-52):
```dart
// Month label (C-01):
DateFormatter.formatMonthYear(DateTime(year, month), locale)
// ja/zh → "yyyy年M月" (single-digit month, no zero-padding for M)
// en → "MMMM yyyy"

// Day subline date (D-06):
DateFormatter.formatShortMonthDay(activeDayFilter!, locale)
// ja/zh → "M月d日"
// en → "MMM d"
```

**`AppTextStyles` usage pattern** (app_text_styles.dart — verified values):
```dart
// CRITICAL: bodySmall bakes in color: AppColors.textSecondary (line 72-77)
// Day numeral needs textPrimary default and card (white) when selected:
AppTextStyles.bodySmall.copyWith(color: numeralColor)
// where numeralColor = isSelected ? AppColors.card : AppColors.textPrimary

// CRITICAL: micro bakes in color: AppColors.textPrimary (line 95-100)
// Day compact amount needs textSecondary:
AppTextStyles.micro.copyWith(color: amountColor)
// where amountColor = isSelected ? AppColors.card : AppColors.textSecondary

// Summary month total (SC#4 — tabular figures baked in):
AppTextStyles.amountSmall   // 15dp, w700, FontFeature.tabularFigures()

// Summary labels, day subline:
AppTextStyles.caption       // 12dp, w500, textSecondary
```

**`AppColors` tokens used** (app_colors.dart — verified hex):
```dart
AppColors.accentPrimary       // #E85A4F — selected day cell fill
AppColors.accentPrimaryLight  // #FEF5F4 — today cell background
AppColors.accentPrimaryBorder // #F5D5D2 — today cell 1dp border
AppColors.card                // #FFFFFF — selected day text (white on coral)
AppColors.textPrimary         // #1E2432 — day numeral default
AppColors.textSecondary       // #ABABAB — compact amount, summary labels
AppColors.textTertiary        // #C4C4C4 — chevron icons
AppColors.borderDivider       // #F5F4F2 — 1dp separator above summary row
AppColors.backgroundMuted     // #F5F4F2 — shimmer placeholder fill
AppColors.background          // #FCFBF9 — widget background
```

**`S.of(context)` i18n pattern** (soul_vs_survival_card.dart line 72):
```dart
final l10n = S.of(context);
// ARB keys for this phase (placeholder; Phase 30 finalizes copy):
// l10n.calMonthTotal   — "今月の支出" / "本月支出" / "Monthly Spend"
// l10n.calDayTotal     — "{date}の支出" / "{date}支出" / "{date} Spend"
// l10n.calLoadError    — "データを読み込めません" / "无法加载数据" / "Unable to load data"
```

---

### `lib/features/list/presentation/screens/list_screen.dart` (MODIFY — screen integration)

**Current file to be modified** (list_screen.dart lines 1-28 — full file):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/state_list_transactions.dart';

class ListScreen extends ConsumerWidget {
  const ListScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(
      listTransactionsProvider(bookId: bookId),
    );

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      // Phase 28: replace data branch with ListView of TaggedTransaction tiles
      data: (_) => const Center(child: CircularProgressIndicator()),
    );
  }
}
```

**Integration pattern:** Replace the `return transactionsAsync.when(...)` body with a `Column`/`CustomScrollView` that mounts `CalendarHeaderWidget` at top. The `bookId` parameter already exists; pass `currencyCode` resolved from a book provider or as a const default, and `locale` from `currentLocaleProvider`. Phase 28 will replace the placeholder `data` body with the real list.

```dart
// After modification sketch:
@override
Widget build(BuildContext context, WidgetRef ref) {
  final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja'); // Riverpod 3: .value (nullable), not .valueOrNull
  // currencyCode: resolve from bookByIdProvider or pass 'JPY' as Phase 27 placeholder
  const currencyCode = 'JPY'; // Phase 27 placeholder; Phase 29 reads from bookByIdProvider

  return Column(
    children: [
      CalendarHeaderWidget(
        bookId: bookId,
        currencyCode: currencyCode,
        locale: locale,
      ),
      // Phase 28: transaction list replaces this placeholder
      const Expanded(child: Center(child: CircularProgressIndicator())),
    ],
  );
}
```

---

### `pubspec.yaml` (MODIFY — dependency addition)

**No close analog — plain dependency add.** Pattern from existing dependencies in `pubspec.yaml`:
```yaml
dependencies:
  # ... existing deps ...
  table_calendar: ^3.2.0   # Add here, under existing deps alphabetically
```

**Constraint:** `intl: 0.20.2` pin must remain unchanged. `table_calendar ^3.2.0` requires `intl: ^0.20.0`; the exact pin `0.20.2` satisfies `^0.20.0`. Do not alter the `intl` version line. Do not touch `file_picker`, `package_info_plus`, or `share_plus`.

After adding: run `flutter pub get`. Then run `flutter pub run build_runner build --delete-conflicting-outputs` after writing the `@riverpod`-annotated provider. Then run `flutter build ios --debug --no-codesign` as SC#5 gate.

---

### `test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart` (test, provider unit)

**Analog:** `test/unit/features/list/presentation/providers/list_transactions_provider_test.dart`

**Test file structure** (list_transactions_provider_test.dart lines 1-65):
```dart
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_transactions.dart';
// ... imports ...
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_provider_scope.dart';

class _MockGetListTransactionsUseCase extends Mock
    implements GetListTransactionsUseCase {}
```

For `calendar_totals_provider_test.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
import 'package:home_pocket/features/list/presentation/providers/state_calendar_totals.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_provider_scope.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}
```

**`ProviderContainer.test()` pattern** (list_transactions_provider_test.dart lines 52-65):
```dart
ProviderContainer _makeContainer(
  _MockGetListTransactionsUseCase mockUseCase, {
  ListFilterState? filterState,
}) {
  return ProviderContainer.test(
    overrides: [
      getListTransactionsUseCaseProvider.overrideWithValue(mockUseCase),
      currentLocaleProvider.overrideWith((ref) async => const Locale('ja')),
      if (filterState != null)
        listFilterProvider.overrideWith(
          () => _FixedListFilter(filterState),
        ),
    ],
  );
}
```

For calendar totals provider test:
```dart
ProviderContainer _makeContainer(_MockAnalyticsRepository mockRepo) {
  return ProviderContainer.test(
    overrides: [
      analyticsRepositoryProvider.overrideWithValue(mockRepo),
    ],
  );
}
```

**`waitForFirstValue<T>` async test pattern** (list_transactions_provider_test.dart lines 96-107):
```dart
final container = _makeContainer(mock);
final result = await waitForFirstValue<List<TaggedTransaction>>(
  container,
  listTransactionsProvider(bookId: 'book1'),
);

expect(result.hasValue, isTrue);
final list = result.value!;
```

For calendar totals:
```dart
final result = await waitForFirstValue<Map<DateTime, int>>(
  container,
  calendarDailyTotalsProvider(bookId: 'book1', year: 2026, month: 5),
);

expect(result.hasValue, isTrue);
final map = result.requireValue;
// Normalized key lookup:
expect(map[DateTime(2026, 5, 3)], equals(1200));
// Month total via fold (D-11):
expect(map.values.fold(0, (a, b) => a + b), equals(1200));
```

**Mocktail `when/thenAnswer` pattern** (list_transactions_provider_test.dart lines 93-95):
```dart
when(() => mock.execute(any())).thenAnswer(
  (_) async => Result.success([tx]),
);
```

For calendar totals:
```dart
when(() => mockRepo.getDailyTotals(
  bookId: any(named: 'bookId'),
  startDate: any(named: 'startDate'),
  endDate: any(named: 'endDate'),
)).thenAnswer((_) async => [
  DailyTotal(date: DateTime(2026, 5, 3), totalAmount: 1200),
]);
```

**Required test cases** (map to SCs):
- `calendarDailyTotals expense-only: income excluded` — stub returns expense entry; assert map contains entry
- `_dayKey normalization: map lookup succeeds regardless of time component` — assert `map[DateTime(2026,5,3)]` returns correct value even when provider is given `DailyTotal(date: DateTime(2026,5,3,12,0))` from the DAO stub
- `empty month: map is empty` — stub returns `[]`; assert map is empty and `fold` yields 0
- `month total equals sum of per-day values (D-11)` — multiple days; assert fold matches manual sum
- `ProviderException wraps repo error` (from `package:flutter_riverpod/misc.dart`): when getDailyTotals throws, assert `throwsA(isA<ProviderException>().having(...))`

---

### `test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` (test, widget)

**Analog:** `test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart`

**Widget test boilerplate** (manual_one_step_screen_test.dart lines 1-26):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_riverpod/misc.dart';
import 'package:home_pocket/features/accounting/presentation/screens/manual_one_step_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';
```

For `list_calendar_header_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_calendar_header.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_provider_scope.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}
```

**`UncontrolledProviderScope` widget test pump pattern** (from CONTEXT.md canonical pattern):
```dart
Future<void> _pumpCalendarHeader(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: CalendarHeaderWidget(
            bookId: 'book1',
            currencyCode: 'JPY',
            locale: const Locale('ja'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
```

**SC#1 (month navigation) test skeleton:**
```dart
testWidgets('SC#1: chevron tap updates focusedDay to next month', (tester) async {
  final mockRepo = _MockAnalyticsRepository();
  when(() => mockRepo.getDailyTotals(
    bookId: any(named: 'bookId'),
    startDate: any(named: 'startDate'),
    endDate: any(named: 'endDate'),
  )).thenAnswer((_) async => []);

  final container = ProviderContainer.test(overrides: [
    analyticsRepositoryProvider.overrideWithValue(mockRepo),
  ]);

  await _pumpCalendarHeader(tester, container);

  // Tap right chevron
  await tester.tap(find.byIcon(Icons.chevron_right));
  await tester.pumpAndSettle();

  final filter = container.read(listFilterProvider);
  // Month should have advanced
  expect(filter.selectedMonth, isNot(equals(DateTime.now().month)));
});
```

**SC#3 (day tap toggle) test skeleton:**
```dart
testWidgets('SC#3: tap day selects it; tap again clears filter', (tester) async {
  final mockRepo = _MockAnalyticsRepository();
  when(() => mockRepo.getDailyTotals(
    bookId: any(named: 'bookId'),
    startDate: any(named: 'startDate'),
    endDate: any(named: 'endDate'),
  )).thenAnswer((_) async => []);

  final container = ProviderContainer.test(overrides: [
    analyticsRepositoryProvider.overrideWithValue(mockRepo),
  ]);

  await _pumpCalendarHeader(tester, container);

  // First tap: select a visible day
  await tester.tap(find.text('5'));
  await tester.pump();
  expect(
    container.read(listFilterProvider).activeDayFilter?.day,
    equals(5),
  );

  // Second tap: same day → clear
  await tester.tap(find.text('5'));
  await tester.pump();
  expect(container.read(listFilterProvider).activeDayFilter, isNull);
});
```

**SC#4 (summary row) test skeleton:**
```dart
testWidgets('SC#4: summary row shows month total via amountSmall', (tester) async {
  final mockRepo = _MockAnalyticsRepository();
  when(() => mockRepo.getDailyTotals(
    bookId: any(named: 'bookId'),
    startDate: any(named: 'startDate'),
    endDate: any(named: 'endDate'),
  )).thenAnswer((_) async => [
    DailyTotal(date: DateTime(2026, 5, 3), totalAmount: 12345),
  ]);

  final container = ProviderContainer.test(overrides: [
    analyticsRepositoryProvider.overrideWithValue(mockRepo),
  ]);

  await _pumpCalendarHeader(tester, container);

  // JPY formatted: ¥12,345
  expect(find.text('¥12,345'), findsOneWidget);
});
```

---

## Shared Patterns

### Riverpod 3 `@riverpod` provider (all provider files)

**Source:** `lib/features/analytics/presentation/providers/state_analytics.dart` and `lib/features/list/presentation/providers/state_list_filter.dart`

**Apply to:** `state_calendar_totals.dart`

```dart
// Provider function (not class) for async family:
@riverpod
Future<T> myProvider(
  Ref ref, {
  required String param1,
  required int param2,
}) async { ... }

// Generated name: myProviderProvider (NOT myProviderNotifierProvider — Riverpod 3 strips suffix)
// Call site: ref.watch(myProviderProvider(param1: ..., param2: ...))
```

### `ProviderContainer.test()` + `waitForFirstValue<T>` (all test files)

**Source:** `test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` lines 52-65 + `test/helpers/test_provider_scope.dart`

**Apply to:** Both new test files

```dart
// ALWAYS use ProviderContainer.test() — auto-disposes on teardown (no addTearDown needed)
final container = ProviderContainer.test(overrides: [...]);

// ALWAYS use waitForFirstValue for async providers — bare container.read(provider.future)
// throws "disposed during loading" on Riverpod 3 auto-dispose providers
final result = await waitForFirstValue<T>(container, someAsyncProvider(...));
expect(result.hasValue, isTrue);
final value = result.requireValue; // throws if hasError
```

### `show` import for cross-feature provider (all files importing `analyticsRepositoryProvider`)

**Source:** `lib/features/analytics/presentation/providers/repository_providers.dart` line 34

**Apply to:** `state_calendar_totals.dart`

```dart
// CORRECT — prevents duplicate provider definition (provider_graph_hygiene_test enforces this):
import '../../../../features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;

// WRONG — re-declaring analyticsRepositoryProvider in list feature's repository_providers.dart
// will cause provider_graph_hygiene_test.dart to fail CI
```

### `ConsumerWidget` + `ref.watch(listFilterProvider)` (widget that reads filter state)

**Source:** `lib/features/list/presentation/providers/state_list_filter.dart` lines 16-68

**Apply to:** `list_calendar_header.dart`

```dart
// Read filter state (no param — keepAlive:true singleton):
final filter = ref.watch(listFilterProvider);
// filter.selectedYear, filter.selectedMonth, filter.activeDayFilter

// Mutate filter via notifier:
ref.read(listFilterProvider.notifier).selectMonth(year, month);
ref.read(listFilterProvider.notifier).selectDay(day);      // day or null
ref.read(listFilterProvider.notifier).selectDay(null);     // clear day filter
```

### ARB localization access

**Source:** `lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart` line 72

**Apply to:** `list_calendar_header.dart`

```dart
// Always retrieve at top of build():
final l10n = S.of(context);
// Then: l10n.calMonthTotal / l10n.calDayTotal / l10n.calLoadError
// Import: import '../../../../generated/app_localizations.dart';
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `pubspec.yaml` (table_calendar add) | config | — | No pubspec pattern to copy; plain `table_calendar: ^3.2.0` line addition. Constraint: do not alter `intl: 0.20.2`, do not touch `file_picker/package_info_plus/share_plus`. |

---

## Critical Executor Notes (extracted from RESEARCH.md pitfalls)

These are not patterns to copy — they are hard constraints the planner must encode as task-level checks:

1. **`_dayKey` normalization must be used in BOTH the provider (when building map keys) AND in every cell/subline lookup.** Missing this causes all cells to silently render blank — no compile error. (Pitfall 1)

2. **`NumberFormatter` method names:** Use `NumberFormatter.formatCompact(num, Locale)` for day cell compact amounts. Use `NumberFormatter.formatCurrency(num, String, Locale)` for summary totals. The UI-SPEC shorthand `compact(...)` and `format(...)` do not exist. (Pitfall 2)

3. **`calendarDailyTotalsProvider` must NOT watch `listFilterProvider` inside its body.** The `(bookId, year, month)` params come from the widget calling the provider — not from `ref.watch(listFilterProvider)` inside the provider. (D-09 / Pitfall 3)

4. **`DateFormatter.formatMonthYear` for ja/zh uses `M月` (single digit), not `MM月`.** Use `DateFormatter.formatMonthYear` as-is — do not hand-roll a custom `DateFormat`. (RESEARCH.md §Pattern 5 note)

5. **After adding `state_calendar_totals.dart` with `@riverpod` annotation, run `flutter pub run build_runner build --delete-conflicting-outputs` to generate `state_calendar_totals.g.dart`.** (CLAUDE.md Pitfall #13)

6. **`flutter build ios --debug --no-codesign` must pass as SC#5 gate.** Run after `flutter pub get`.

---

## Metadata

**Analog search scope:** `lib/features/analytics/`, `lib/features/list/`, `lib/shared/utils/`, `lib/core/theme/`, `lib/infrastructure/i18n/`, `test/unit/features/list/`, `test/widget/features/accounting/`, `test/helpers/`
**Files scanned:** 14 source files read directly
**Pattern extraction date:** 2026-05-30
