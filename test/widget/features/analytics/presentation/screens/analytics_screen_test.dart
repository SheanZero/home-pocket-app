import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    as accounting_providers;
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:home_pocket/features/analytics/domain/models/expense_trend.dart';
import 'package:home_pocket/features/analytics/domain/models/happiness_report.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart'
    as analytics_repositories;
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/analytics_card_error_state.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/analytics_screen_section_header.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/best_joy_story_strip.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/category_spend_donut_chart.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/family_insight_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/kpi_mini_hero_strip.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/largest_expense_story_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/month_chip_picker.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;

import '../../../../../helpers/happiness_test_fixtures.dart';
import '../../../../../helpers/test_localizations.dart';

const _bookId = 'book_001';
final _selectedMonth = DateTime(2026, 4);

class _TestSelectedMonth extends SelectedMonth {
  @override
  DateTime build() => _selectedMonth;
}

Widget _buildSubject({
  HappinessReport? happinessReport,
  Object? distributionError,
  bool groupMode = false,
  List<ShadowBookInfo> shadowBooks = const [],
}) {
  return createLocalizedWidget(
    const AnalyticsScreen(bookId: _bookId),
    locale: const Locale('en'),
    overrides: [
      selectedMonthProvider.overrideWith(_TestSelectedMonth.new),
      locale_providers.currentLocaleProvider.overrideWith(
        (_) async => const Locale('en'),
      ),
      accounting_providers
          .bookByIdProvider(bookId: _bookId)
          .overrideWith((_) async => _book),
      monthlyReportProvider(
        bookId: _bookId,
        year: 2026,
        month: 4,
      ).overrideWith((_) async => _monthlyReport),
      expenseTrendProvider(
        bookId: _bookId,
        anchor: _selectedMonth,
      ).overrideWith((_) async => _expenseTrend),
      happinessReportProvider(
        bookId: _bookId,
        year: 2026,
        month: 4,
        currencyCode: 'JPY',
      ).overrideWith(
        (_) async => happinessReport ?? fixtureHappinessReportRich(),
      ),
      bestJoyMomentProvider(
        bookId: _bookId,
        year: 2026,
        month: 4,
      ).overrideWith((_) async => fixtureBestJoyResultRich()),
      largestMonthlyExpenseProvider(
        bookId: _bookId,
        year: 2026,
        month: 4,
      ).overrideWith((_) async => _largestExpense),
      familyHappinessProvider(
        year: 2026,
        month: 4,
      ).overrideWith((_) async => fixtureFamilyHappinessRich()),
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
      'renders KPI mini-hero, AppBar month picker, groups, and cards',
      (tester) async {
        await _pump(tester, _buildSubject());

        expect(find.byType(MonthChipPicker), findsOneWidget);
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

    testWidgets('month picker includes the earliest transaction month', (
      tester,
    ) async {
      await _pump(tester, _buildSubject());

      await tester.tap(find.byType(MonthChipPicker));
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<CategoryTotal>> getCategoryTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<DailyTotal>> getDailyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LargestMonthlyExpense?> getLargestMonthlyExpense({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<MonthlyTotals> getMonthlyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SharedJoyCategoryAggregate?> getSharedJoyCategoryInsight({
    required List<String> bookIds,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SoulSatisfactionOverview> getSoulSatisfactionOverview({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<SoulRowSample>> getSoulRowsForJoyContribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    throw UnimplementedError();
  }
}
