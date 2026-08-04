import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart'
    show LedgerType;
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    as accounting_providers;
import 'package:home_pocket/core/theme/app_text_styles.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:home_pocket/features/analytics/domain/models/happiness_report.dart';
import 'package:home_pocket/features/analytics/domain/models/ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/joy_category_amount.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/domain/models/per_category_joy_breakdown.dart';
import 'package:home_pocket/features/analytics/domain/models/per_day_joy_count.dart';
import 'package:home_pocket/features/analytics/domain/models/time_window.dart';
import 'package:home_pocket/features/analytics/domain/models/within_month_cumulative_trend.dart';
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
import 'package:home_pocket/features/analytics/presentation/widgets/analytics_section_header.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/category_donut_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/joy_calendar_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/joy_spend_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/within_month_trend_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/family_insight_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/joy_spend_drawer.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart';
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
// The shell derives trendAnchor = DateTime(endDate.year, endDate.month).
final _trendAnchor = DateTime(2026, 5);

const _emptyTrend = WithinMonthCumulativeTrend(
  currentMonthTotal: [],
  currentMonthDaily: [],
  currentMonthJoy: [],
  previousMonthTotal: [],
  previousMonthDaily: [],
);

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
  Locale locale = const Locale('en'),
}) {
  _TestSelectedTimeWindow.fixedWindow = TimeWindow.month(year: 2026, month: 5);

  return createLocalizedWidget(
    const AnalyticsScreen(bookId: _bookId),
    locale: locale,
    overrides: [
      selectedTimeWindowProvider.overrideWith(_TestSelectedTimeWindow.new),
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      accounting_providers
          .bookByIdProvider(bookId: _bookId)
          .overrideWith((_) async => _book),
      monthlyReportProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        includeFamily: true,
      ).overrideWith((_) async => _monthlyReport),
      happinessReportProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        currencyCode: 'JPY',
        includeFamily: false,
      ).overrideWith(
        (_) async => happinessReport ?? fixtureHappinessReportRich(),
      ),
      // Round-5 B card providers (within_month_trend / joy_spend / joy_calendar).
      withinMonthCumulativeTrendProvider(
        bookId: _bookId,
        anchor: _trendAnchor,
      ).overrideWith((_) async => _emptyTrend),
      joyCategoryAmountsProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
      ).overrideWith((_) async => const <JoyCategoryAmount>[]),
      perDayJoyCountsProvider(
        bookId: _bookId,
        anchor: _trendAnchor,
      ).overrideWith((_) async => const <PerDayJoyCount>[]),
      familyHappinessProvider(
        primaryBookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
      ).overrideWith((_) async => fixtureFamilyHappinessRich()),
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
  setUpAll(() async {
    final textFont = FontLoader('RobotoMonoNumerals')
      ..addFont(
        File('/System/Library/Fonts/Supplemental/Arial Unicode.ttf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(Uint8List.fromList(bytes))),
      );
    await textFont.load();
  });

  group('AnalyticsScreen — main header', () {
    testWidgets('matches the shared title and action geometry', (tester) async {
      await _pump(tester, _buildSubject());

      final header = find.byKey(const Key('analytics-main-header'));
      final title = find.byKey(const Key('analytics-main-title'));
      final calendar = find.byKey(const Key('analytics-month-picker-button'));
      final settings = find.byKey(const Key('analytics-settings-button'));
      final tabs = find.byKey(const Key('analytics-primary-tabs'));

      expect(find.byType(AppBar), findsNothing);
      expect(tester.getSize(header).height, 46);
      expect(tester.getTopLeft(header).dx, 20);
      expect(tester.getTopLeft(title).dx, 20);
      expect(
        tester.widget<Text>(title).style?.fontSize,
        AppTypography.pageTitle,
      );
      expect(
        tester.widget<Text>(title).style?.height,
        AppTypography.pageTitleLineHeight / AppTypography.pageTitle,
      );
      expect(tester.getSize(calendar), const Size(40, 40));
      expect(tester.getSize(settings), const Size(40, 40));
      expect(tester.getCenter(settings).dx - tester.getCenter(calendar).dx, 40);
      expect(tester.getTopLeft(tabs).dy - tester.getBottomLeft(header).dy, 13);
    });
  });

  group('AnalyticsScreen primary tabs', () {
    testWidgets(
      'personal mode defaults to Joy and separates the two card groups',
      (tester) async {
        await _pump(tester, _buildSubject());

        expect(find.text('May 2026'), findsOneWidget);
        expect(find.text('Spending'), findsOneWidget);
        expect(find.text('Joy'), findsOneWidget);
        expect(
          find.byKey(const Key('analytics-primary-tab-joy-bookmark')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('analytics-primary-tab-spending-bookmark')),
          findsNothing,
        );
        expect(
          find.byType(AnalyticsSectionHeader, skipOffstage: false),
          findsNWidgets(2),
        );
        expect(find.byType(WithinMonthTrendCard), findsNothing);
        expect(find.byType(CategoryDonutCard), findsNothing);
        expect(find.byType(JoyCalendarCard), findsOneWidget);
        expect(find.byType(SatisfactionDistributionHistogram), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('analytics-primary-tab-spending')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(WithinMonthTrendCard), findsOneWidget);
        expect(find.byType(CategoryDonutCard), findsOneWidget);
        expect(find.byType(JoyCalendarCard), findsNothing);
        expect(find.byType(SatisfactionDistributionHistogram), findsNothing);
        expect(
          find.byKey(const Key('analytics-primary-tab-spending-bookmark')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('analytics-primary-tab-joy-bookmark')),
          findsNothing,
        );
        expect(find.byType(JoySpendCard), findsNothing);
        expect(
          find.descendant(
            of: find.byType(CategoryDonutCard),
            matching: find.byType(JoySpendDrawer),
            skipOffstage: false,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'uses concise personal labels and owner-qualified family labels',
      (tester) async {
        await _pump(tester, _buildSubject(locale: const Locale('ja')));
        expect(find.text('支出'), findsOneWidget);
        expect(find.text('ときめき'), findsOneWidget);
        expect(find.text('私のときめき'), findsNothing);

        await _resetProviderScope(tester);
        await _pump(
          tester,
          _buildSubject(
            groupMode: true,
            shadowBooks: fixtureShadowBooksThree(),
            locale: const Locale('ja'),
          ),
        );
        expect(find.text('家族の支出'), findsOneWidget);
        expect(find.text('私のときめき'), findsOneWidget);
      },
    );

    testWidgets('family tab titles remain untruncated at 375 logical pixels', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await _pump(
        tester,
        _buildSubject(
          groupMode: true,
          shadowBooks: fixtureShadowBooksThree(),
          locale: const Locale('ja'),
        ),
      );

      final spending = tester.renderObject<RenderParagraph>(
        find.byKey(const Key('analytics-primary-tab-spending-title')),
      );
      final joy = tester.renderObject<RenderParagraph>(
        find.byKey(const Key('analytics-primary-tab-joy-title')),
      );
      expect(spending.didExceedMaxLines, isFalse);
      expect(joy.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('375px English hides decoration before truncating ownership', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await _pump(
        tester,
        _buildSubject(
          groupMode: true,
          shadowBooks: fixtureShadowBooksThree(),
          locale: const Locale('en'),
        ),
      );

      final spending = tester.renderObject<RenderParagraph>(
        find.byKey(const Key('analytics-primary-tab-spending-title')),
      );
      final joy = tester.renderObject<RenderParagraph>(
        find.byKey(const Key('analytics-primary-tab-joy-title')),
      );
      expect(spending.didExceedMaxLines, isFalse);
      expect(joy.didExceedMaxLines, isFalse);
      expect(
        find.byKey(const Key('analytics-primary-tab-spending-icon')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('family mode keeps family insight under spending only', (
      tester,
    ) async {
      await _pump(
        tester,
        _buildSubject(groupMode: true, shadowBooks: fixtureShadowBooksThree()),
      );

      expect(find.text('Family Spending'), findsOneWidget);
      expect(find.text('My Joy'), findsOneWidget);
      expect(find.byType(FamilyInsightCard), findsNothing);

      await tester.tap(find.byKey(const Key('analytics-primary-tab-spending')));
      await tester.pumpAndSettle();

      expect(find.byType(FamilyInsightCard), findsOneWidget);
      expect(find.byType(JoyCalendarCard), findsNothing);
    });

    testWidgets('per-card error isolation keeps the Joy calendar visible', (
      tester,
    ) async {
      await _pump(
        tester,
        _buildSubject(distributionError: StateError('distribution failed')),
      );

      // The satisfaction-distribution card surfaces its error in isolation
      // while its Joy-tab sibling stays rendered.
      expect(find.byType(JoyCalendarCard), findsOneWidget);
      expect(find.byType(AnalyticsCardErrorState), findsOneWidget);
      expect(find.byType(SatisfactionDistributionHistogram), findsNothing);
    });

    testWidgets(
      'thin-sample happiness still renders the histogram (no self-hide)',
      (tester) async {
        // round-5 r5b: the former `totalJoyTx < 5` self-hide is REMOVED — it left
        // an orphaned 「悦己满足度分布」section header (the header renders
        // unconditionally in the shell). The card now ALWAYS renders the
        // histogram, so a thin-sample report no longer collapses the slot.
        await _pump(
          tester,
          _buildSubject(happinessReport: fixtureHappinessReportThin()),
        );

        expect(find.byType(SatisfactionDistributionHistogram), findsOneWidget);
      },
    );

    testWidgets('joy cards render without throwing on the empty-data path', (
      tester,
    ) async {
      await _pump(tester, _buildSubject());

      // D-C1/D-C2: the Joy-tab cards keep local-only interactions and render
      // their empty paths without throwing.
      await tester.ensureVisible(find.byType(JoyCalendarCard));
      expect(tester.takeException(), isNull);
    });

    testWidgets('month picker opens from the header month button', (
      tester,
    ) async {
      await _pump(tester, _buildSubject());

      // v15 header (260714): tapping the calendar_month action opens the shared
      // month-grid picker dialog (the removed TimeWindowChip's granularity sheet
      // is gone). The dialog surfaces the year label + month cells.
      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('family insight is gated by group mode and shadow books', (
      tester,
    ) async {
      await _pump(tester, _buildSubject());
      await tester.tap(find.byKey(const Key('analytics-primary-tab-spending')));
      await tester.pumpAndSettle();
      expect(find.text('Family · Highlights Summary'), findsNothing);

      await _resetProviderScope(tester);
      await _pump(tester, _buildSubject(groupMode: true));
      await tester.tap(find.byKey(const Key('analytics-primary-tab-spending')));
      await tester.pumpAndSettle();
      expect(find.text('Family · Highlights Summary'), findsNothing);

      await _resetProviderScope(tester);
      await _pump(
        tester,
        _buildSubject(groupMode: true, shadowBooks: fixtureShadowBooksThree()),
      );
      await tester.tap(find.byKey(const Key('analytics-primary-tab-spending')));
      await tester.pumpAndSettle();
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
  Future<List<CategoryTotal>> getMemberCategoryTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    String? deviceId,
    EntrySource? entrySourceFilter,
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
    EntrySource? entrySourceFilter,
    LedgerType? ledgerType,
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
  Future<JoyFullnessOverview> getJoyFullnessOverview({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<JoyRowSample>> getJoyRowsForJoyContribution({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PerCategoryJoyBreakdownItem>> getPerCategoryJoyBreakdown({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PerCategoryJoyBreakdownItem>>
  getPerCategoryJoyBreakdownAcrossBooks({
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
