// Assumption A1 / D-B3 Option A behavior-preservation test (Phase 45 Plan 07).
//
// The registry/shell rewrite (Plan 02/04) DROPPED the direct
// `shadowBooksProvider` invalidate from `_refresh`. `familyInsightRefreshTargets`
// now returns ONLY `familyHappinessProvider`. Option A relies on the fact that
// `familyHappinessProvider` internally does
// `await ref.watch(shadowBooksProvider.future)` (state_happiness.dart:118), so
// invalidating `familyHappinessProvider` transitively re-reads the shadow books
// and re-invokes `GetFamilyHappinessUseCase.execute` — family cards still
// refresh under group mode.
//
// This test pumps the REAL `AnalyticsScreen` and triggers the REAL
// `RefreshIndicator → _refresh()` path (a widget fling, unlike Plan 05's
// synthetic-ctx enumeration). It does NOT override `familyHappinessProvider`
// directly — doing so would mask the transitive re-read. Instead it overrides
// the use case (`getFamilyHappinessUseCaseProvider`) + `shadowBooksProvider` so
// the real `familyHappinessProvider` builds and the use-case call count is the
// observable signal:
//   - GROUP mode: pull-to-refresh re-invokes `familyHappinessUseCase.execute`
//     (A1 confirmed — transitive re-read fires).
//   - SOLO mode: the family spec is hidden (`isVisible: ctx.isGroupMode`), so
//     `familyHappinessProvider` is never built/invalidated → `verifyNever`
//     (D-B4 — family specs hidden, not invalidated).
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_family_happiness_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    as accounting_providers;
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:home_pocket/features/analytics/domain/models/ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/domain/models/per_category_joy_breakdown.dart';
import 'package:home_pocket/features/analytics/domain/models/time_window.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart'
    as analytics_repositories;
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_time_window.dart';
import 'package:home_pocket/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/happiness_test_fixtures.dart';
import '../../../../../helpers/test_localizations.dart';

class _MockFamilyHappinessUseCase extends Mock
    implements GetFamilyHappinessUseCase {}

const _bookId = 'book_001';
final _windowStart = DateTime(2026, 5);
final _windowEnd = DateTime(2026, 5, 31, 23, 59, 59);

class _TestSelectedTimeWindow extends SelectedTimeWindow {
  _TestSelectedTimeWindow();

  static TimeWindow fixedWindow = TimeWindow.month(year: 2026, month: 5);

  @override
  TimeWindow build() => fixedWindow;
}

/// Builds the real `AnalyticsScreen` with all NON-family providers overridden
/// directly (so the screen renders without hitting the repository), but the
/// family path left REAL: `familyHappinessProvider` is NOT overridden. Only its
/// dependencies — `getFamilyHappinessUseCaseProvider` (the [familyUseCase] mock)
/// and `shadowBooksProvider` — are overridden, so the real provider builds and
/// the transitive `shadowBooksProvider.future` re-read is exercised on refresh.
Widget _buildSubject({
  required bool groupMode,
  required GetFamilyHappinessUseCase familyUseCase,
  List<ShadowBookInfo> shadowBooks = const [],
}) {
  _TestSelectedTimeWindow.fixedWindow = TimeWindow.month(year: 2026, month: 5);

  return createLocalizedWidget(
    const AnalyticsScreen(bookId: _bookId),
    locale: const Locale('en'),
    overrides: [
      selectedTimeWindowProvider.overrideWith(_TestSelectedTimeWindow.new),
      locale_providers.currentLocaleProvider.overrideWith(
        (_) async => const Locale('en'),
      ),
      accounting_providers
          .bookByIdProvider(bookId: _bookId)
          .overrideWith((_) async => _book),
      monthlyReportProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
      ).overrideWith((_) async => _monthlyReport),
      happinessReportProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        currencyCode: 'JPY',
      ).overrideWith((_) async => fixtureHappinessReportRich()),
      bestJoyMomentProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
      ).overrideWith((_) async => fixtureBestJoyResultRich()),
      largestMonthlyExpenseProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
      ).overrideWith((_) async => _largestExpense),
      // NOTE: familyHappinessProvider is DELIBERATELY NOT overridden — the real
      // provider must build so its internal shadowBooksProvider.future re-read
      // (the A1 transitive path) is exercised. We override only its deps below.
      perCategoryJoyBreakdownProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => const Empty<PerCategoryJoyBreakdown>()),
      perCategoryJoyBreakdownFamilyProvider(
        startDate: _windowStart,
        endDate: _windowEnd,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => const Empty<PerCategoryJoyBreakdown>()),
      dailyVsJoySnapshotProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => const Empty<DailyVsJoySnapshot>()),
      dailyVsJoySnapshotFamilyProvider(
        startDate: _windowStart,
        endDate: _windowEnd,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => const Empty<DailyVsJoySnapshot>()),
      activeGroupProvider.overrideWith(
        (_) => Stream.value(groupMode ? _groupInfo : null),
      ),
      isGroupModeProvider.overrideWith((_) => groupMode),
      shadowBooksProvider.overrideWith((_) async => shadowBooks),
      // The real familyHappinessProvider resolves THIS use case after reading
      // shadowBooksProvider.future — the call count is our A1 signal.
      analytics_repositories.getFamilyHappinessUseCaseProvider.overrideWith(
        (_) => familyUseCase,
      ),
      analytics_repositories.analyticsRepositoryProvider.overrideWithValue(
        const _FakeAnalyticsRepository(distribution: _distribution),
      ),
      earliestTransactionMonthProvider(
        bookId: _bookId,
      ).overrideWith((_) async => DateTime(2024, 12)),
    ],
  );
}

Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _pullToRefresh(WidgetTester tester) async {
  await tester.fling(
    find.byType(SingleChildScrollView),
    const Offset(0, 320),
    1000,
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2000));
    registerFallbackValue(<String>[]);
  });

  late _MockFamilyHappinessUseCase familyHappinessUseCase;

  setUp(() {
    familyHappinessUseCase = _MockFamilyHappinessUseCase();
    when(
      () => familyHappinessUseCase.execute(
        groupBookIds: any(named: 'groupBookIds'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        entrySourceFilter: any(named: 'entrySourceFilter'),
      ),
    ).thenAnswer((_) async => fixtureFamilyHappinessRich());
  });

  group('AnalyticsScreen pull-to-refresh — Assumption A1 / D-B4', () {
    testWidgets(
      'group mode: refresh transitively re-fetches family data '
      '(familyHappinessUseCase invoked again) after dropping the direct '
      'shadowBooksProvider invalidate',
      (tester) async {
        await _pump(
          tester,
          _buildSubject(
            groupMode: true,
            familyUseCase: familyHappinessUseCase,
            shadowBooks: fixtureShadowBooksThree(),
          ),
        );

        // The initial build already resolved familyHappinessProvider once.
        verify(
          () => familyHappinessUseCase.execute(
            groupBookIds: any(named: 'groupBookIds'),
            startDate: _windowStart,
            endDate: _windowEnd,
            entrySourceFilter: any(named: 'entrySourceFilter'),
          ),
        ).called(greaterThanOrEqualTo(1));

        // Isolate the refresh signal from the initial build.
        clearInteractions(familyHappinessUseCase);

        await _pullToRefresh(tester);
        expect(tester.takeException(), isNull);

        // A1: invalidating familyHappinessProvider re-reads shadowBooksProvider
        // transitively, re-invoking the use case — proving Option A preserves
        // today's behavior even though _refresh no longer touches
        // shadowBooksProvider directly.
        verify(
          () => familyHappinessUseCase.execute(
            groupBookIds: any(named: 'groupBookIds'),
            startDate: _windowStart,
            endDate: _windowEnd,
            entrySourceFilter: any(named: 'entrySourceFilter'),
          ),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      'solo mode: refresh does NOT touch the family use case '
      '(family spec hidden, not invalidated — D-B4)',
      (tester) async {
        await _pump(
          tester,
          _buildSubject(
            groupMode: false,
            familyUseCase: familyHappinessUseCase,
          ),
        );

        // Family spec is invisible in solo mode, so it never built.
        verifyNever(
          () => familyHappinessUseCase.execute(
            groupBookIds: any(named: 'groupBookIds'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            entrySourceFilter: any(named: 'entrySourceFilter'),
          ),
        );

        clearInteractions(familyHappinessUseCase);

        await _pullToRefresh(tester);
        expect(tester.takeException(), isNull);

        // D-B4: where(isVisible) filters the family spec BEFORE
        // expand(refreshTargets), so familyHappinessProvider is never
        // invalidated in solo mode → use case untouched.
        verifyNever(
          () => familyHappinessUseCase.execute(
            groupBookIds: any(named: 'groupBookIds'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            entrySourceFilter: any(named: 'entrySourceFilter'),
          ),
        );
      },
    );
  });
}

final _book = Book(
  id: _bookId,
  name: 'Main Book',
  currency: 'JPY',
  deviceId: 'device_local',
  createdAt: DateTime.utc(2026, 1),
);

const _monthlyReport = MonthlyReport(
  year: 2026,
  month: 4,
  totalIncome: 300000,
  totalExpenses: 142800,
  savings: 157200,
  savingsRate: 52.4,
  dailyTotal: 102200,
  joyTotal: 40600,
  categoryBreakdowns: [
    CategoryBreakdown(
      categoryId: 'cat_food',
      categoryName: 'Food',
      icon: 'restaurant',
      color: '#E76F51',
      amount: 60000,
      percentage: 42,
      transactionCount: 12,
    ),
    CategoryBreakdown(
      categoryId: 'cat_coffee',
      categoryName: 'Coffee',
      icon: 'local_cafe',
      color: '#2A9D8F',
      amount: 40000,
      percentage: 28,
      transactionCount: 8,
    ),
  ],
  dailyExpenses: [],
);

final _largestExpense = LargestMonthlyExpense(
  transactionId: 'tx_largest',
  amount: 18000,
  categoryId: 'cat_food',
  timestamp: DateTime.utc(2026, 4, 10),
);

final _groupInfo = GroupInfo(
  groupId: 'group_test',
  status: GroupStatus.active,
  groupName: 'Test Group',
  role: 'owner',
  members: const [],
  createdAt: DateTime.utc(2026, 1),
);

const _distribution = [
  SatisfactionScoreBucket(score: 6, count: 2),
  SatisfactionScoreBucket(score: 8, count: 3),
  SatisfactionScoreBucket(score: 10, count: 1),
];

class _FakeAnalyticsRepository implements AnalyticsRepository {
  const _FakeAnalyticsRepository({required this.distribution});

  final List<SatisfactionScoreBucket> distribution;

  @override
  Future<List<SatisfactionScoreBucket>> getSatisfactionDistribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async => distribution;

  @override
  Future<BestJoyMomentRow?> getBestJoyMoment({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) => throw UnimplementedError();

  @override
  Future<List<CategoryTotal>> getCategoryTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
    EntrySource? entrySourceFilter,
  }) => throw UnimplementedError();

  @override
  Future<List<DailyTotal>> getDailyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
    EntrySource? entrySourceFilter,
  }) => throw UnimplementedError();

  @override
  Future<LargestMonthlyExpense?> getLargestMonthlyExpense({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) => throw UnimplementedError();

  @override
  Future<DateTime?> getEarliestTransactionTimestamp({
    required String bookId,
  }) => throw UnimplementedError();

  @override
  Future<List<LedgerTotal>> getLedgerTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) => throw UnimplementedError();

  @override
  Future<MonthlyTotals> getMonthlyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) => throw UnimplementedError();

  @override
  Future<SharedJoyCategoryAggregate?> getSharedJoyCategoryInsight({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) => throw UnimplementedError();

  @override
  Future<JoyFullnessOverview> getJoyFullnessOverview({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) => throw UnimplementedError();

  @override
  Future<List<JoyRowSample>> getJoyRowsForJoyContribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) => throw UnimplementedError();

  @override
  Future<List<PerCategoryJoyBreakdownItem>> getPerCategoryJoyBreakdown({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) => throw UnimplementedError();

  @override
  Future<List<PerCategoryJoyBreakdownItem>>
  getPerCategoryJoyBreakdownAcrossBooks({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) => throw UnimplementedError();

  @override
  Future<List<LedgerSnapshotRow>> getLedgerSnapshot({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) => throw UnimplementedError();

  @override
  Future<List<LedgerSnapshotRow>> getLedgerSnapshotAcrossBooks({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) => throw UnimplementedError();
}
