import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    as accounting_providers;
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:home_pocket/features/analytics/domain/models/expense_trend.dart';
import 'package:home_pocket/features/analytics/domain/models/happiness_report.dart';
import 'package:home_pocket/features/analytics/domain/models/ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/domain/models/per_category_soul_breakdown.dart';
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
import 'package:home_pocket/features/analytics/presentation/widgets/analytics_card_error_state.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/analytics_screen_section_header.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/best_joy_story_strip.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/category_spend_donut_chart.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/family_insight_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/kpi_mini_hero_strip.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/largest_expense_story_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/time_window_chip.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;

import '../../../../../helpers/happiness_test_fixtures.dart';
import '../../../../../helpers/test_localizations.dart';

const _bookId = 'book_001';
final _windowStart = DateTime(2026, 5);
final _windowEnd = DateTime(2026, 5, 31, 23, 59, 59);
final _trendAnchor = DateTime(2026, 5);

class _TestSelectedTimeWindow extends SelectedTimeWindow {
  _TestSelectedTimeWindow();

  static TimeWindow fixedWindow = TimeWindow.month(year: 2026, month: 5);

  @override
  TimeWindow build() => fixedWindow;
}

Widget _buildSubject({
  HappinessReport? happinessReport,
  Object? distributionError,
  bool groupMode = false,
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
      expenseTrendProvider(
        bookId: _bookId,
        anchor: _trendAnchor,
      ).overrideWith((_) async => _expenseTrend),
      happinessReportProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        currencyCode: 'JPY',
      ).overrideWith(
        (_) async => happinessReport ?? fixtureHappinessReportRich(),
      ),
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
      familyHappinessProvider(
        startDate: _windowStart,
        endDate: _windowEnd,
      ).overrideWith((_) async => fixtureFamilyHappinessRich()),
      perCategorySoulBreakdownProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => const Empty<PerCategorySoulBreakdown>()),
      perCategorySoulBreakdownFamilyProvider(
        startDate: _windowStart,
        endDate: _windowEnd,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => const Empty<PerCategorySoulBreakdown>()),
      soulVsSurvivalSnapshotProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => const Empty<SoulVsSurvivalSnapshot>()),
      soulVsSurvivalSnapshotFamilyProvider(
        startDate: _windowStart,
        endDate: _windowEnd,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => const Empty<SoulVsSurvivalSnapshot>()),
      activeGroupProvider.overrideWith(
        (_) => Stream.value(groupMode ? _groupInfo : null),
      ),
      isGroupModeProvider.overrideWith((_) => groupMode),
      shadowBooksProvider.overrideWith((_) async => shadowBooks),
      analytics_repositories.analyticsRepositoryProvider.overrideWithValue(
        _FakeAnalyticsRepository(
          distribution: _distribution,
          distributionError: distributionError,
        ),
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

Future<void> _resetProviderScope(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  group('AnalyticsScreen Variant delta', () {
    testWidgets(
      'renders KPI mini-hero, AppBar time window chip, groups, and cards',
      (tester) async {
        await _pump(tester, _buildSubject());

        expect(find.byType(TimeWindowChip), findsOneWidget);
        expect(find.byType(KpiMiniHeroStrip), findsOneWidget);
        expect(find.byType(AnalyticsScreenSectionHeader), findsNWidgets(3));
        expect(find.byType(MonthlySpendTrendBarChart), findsOneWidget);
        expect(find.byType(CategorySpendDonutChart), findsOneWidget);
        expect(find.byType(SatisfactionDistributionHistogram), findsOneWidget);
        expect(find.byType(LargestExpenseStoryCard), findsOneWidget);
        expect(find.byType(BestJoyStoryStrip), findsOneWidget);
      },
    );

    testWidgets('per-card error isolation keeps six-month trend visible', (
      tester,
    ) async {
      await _pump(
        tester,
        _buildSubject(distributionError: StateError('distribution failed')),
      );

      expect(find.byType(MonthlySpendTrendBarChart), findsOneWidget);
      expect(find.byType(AnalyticsCardErrorState), findsOneWidget);
      expect(find.byType(SatisfactionDistributionHistogram), findsNothing);
    });

    testWidgets('thin-sample happiness hides histogram slot', (tester) async {
      await _pump(
        tester,
        _buildSubject(happinessReport: fixtureHappinessReportThin()),
      );

      expect(find.byType(SatisfactionDistributionHistogram), findsNothing);
    });

    testWidgets('story cards do not call unregistered detail routes', (
      tester,
    ) async {
      await _pump(tester, _buildSubject());

      await tester.ensureVisible(find.byType(LargestExpenseStoryCard));
      await tester.tap(find.byType(LargestExpenseStoryCard));
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.byType(BestJoyStoryStrip));
      await tester.tap(find.byType(BestJoyStoryStrip));
      expect(tester.takeException(), isNull);
    });

    testWidgets('time window sheet includes the earliest transaction month', (
      tester,
    ) async {
      await _pump(tester, _buildSubject());

      await tester.tap(find.byType(TimeWindowChip));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('December 2024'),
        500,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('December 2024'), findsOneWidget);
    });

    testWidgets('family insight is gated by group mode and shadow books', (
      tester,
    ) async {
      await _pump(tester, _buildSubject());
      expect(find.text('Family · Highlights Summary'), findsNothing);

      await _resetProviderScope(tester);
      await _pump(tester, _buildSubject(groupMode: true));
      expect(find.text('Family · Highlights Summary'), findsNothing);

      await _resetProviderScope(tester);
      await _pump(
        tester,
        _buildSubject(groupMode: true, shadowBooks: fixtureShadowBooksThree()),
      );
      expect(
        find.byType(FamilyInsightCard, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Family · Highlights Summary'), findsOneWidget);
    });

    testWidgets(
      'pull-to-refresh invalidates windowed providers in group mode',
      (tester) async {
        await _pump(
          tester,
          _buildSubject(
            groupMode: true,
            shadowBooks: fixtureShadowBooksThree(),
          ),
        );

        await tester.fling(
          find.byType(SingleChildScrollView),
          const Offset(0, 320),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(tester.takeException(), isNull);
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
  survivalTotal: 102200,
  soulTotal: 40600,
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

const _expenseTrend = ExpenseTrendData(
  months: [
    MonthlyTrend(
      year: 2025,
      month: 11,
      totalExpenses: 95000,
      totalIncome: 280000,
    ),
    MonthlyTrend(
      year: 2025,
      month: 12,
      totalExpenses: 105000,
      totalIncome: 280000,
    ),
    MonthlyTrend(
      year: 2026,
      month: 1,
      totalExpenses: 110000,
      totalIncome: 290000,
    ),
    MonthlyTrend(
      year: 2026,
      month: 2,
      totalExpenses: 118000,
      totalIncome: 290000,
    ),
    MonthlyTrend(
      year: 2026,
      month: 3,
      totalExpenses: 132000,
      totalIncome: 300000,
    ),
    MonthlyTrend(
      year: 2026,
      month: 4,
      totalExpenses: 142800,
      totalIncome: 300000,
    ),
  ],
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
  const _FakeAnalyticsRepository({
    required this.distribution,
    this.distributionError,
  });

  final List<SatisfactionScoreBucket> distribution;
  final Object? distributionError;

  @override
  Future<List<SatisfactionScoreBucket>> getSatisfactionDistribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    final error = distributionError;
    if (error != null) throw error;
    return distribution;
  }

  @override
  Future<BestJoyMomentRow?> getBestJoyMoment({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<CategoryTotal>> getCategoryTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<DailyTotal>> getDailyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LargestMonthlyExpense?> getLargestMonthlyExpense({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DateTime?> getEarliestTransactionTimestamp({required String bookId}) {
    throw UnimplementedError();
  }

  @override
  Future<List<LedgerTotal>> getLedgerTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<MonthlyTotals> getMonthlyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SharedJoyCategoryAggregate?> getSharedJoyCategoryInsight({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SoulSatisfactionOverview> getSoulSatisfactionOverview({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<SoulRowSample>> getSoulRowsForJoyContribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PerCategorySoulBreakdownItem>> getPerCategorySoulBreakdown({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PerCategorySoulBreakdownItem>>
  getPerCategorySoulBreakdownAcrossBooks({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<LedgerSnapshotRow>> getLedgerSnapshot({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<LedgerSnapshotRow>> getLedgerSnapshotAcrossBooks({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }
}
