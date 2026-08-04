@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    as accounting_providers;
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/models/joy_category_amount.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/domain/models/per_day_joy_count.dart';
import 'package:home_pocket/features/analytics/domain/models/time_window.dart';
import 'package:home_pocket/features/analytics/domain/models/within_month_cumulative_trend.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_time_window.dart';
import 'package:home_pocket/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';

import '../helpers/happiness_test_fixtures.dart';

/// V16 first-viewport goldens for [AnalyticsScreen].
///
/// Covers the two approved entry states at a 390 × 844 phone viewport:
/// - personal: `支出 / ときめき`, with Joy selected by default;
/// - family: `家族の支出 / 私のときめき`, with Family Spending selected.
///
/// Wraps the PRODUCTION [AppTheme] so `context.palette` resolves the real
/// ADR-019 palette.

const _bookId = 'book_a';
final _windowStart = DateTime(2026, 5);
final _windowEnd = DateTime(2026, 5, 31, 23, 59, 59);
final _anchor = DateTime(2026, 5);

final _book = Book(
  id: _bookId,
  name: 'Main Book',
  currency: 'JPY',
  deviceId: 'device_local',
  createdAt: DateTime.utc(2026, 1),
);

class _FixedTimeWindow extends SelectedTimeWindow {
  _FixedTimeWindow();

  @override
  TimeWindow build() => TimeWindow.month(year: 2026, month: 5);
}

CumulativePoint _p(int day, int amount) =>
    CumulativePoint(day: day, cumulativeAmount: amount);

// Round-2 (kll) use-case OUTPUT shape: current series carry-forward day 1 (0)
// .. day 31 (May month-end); previous (April, 30 days) series day 1 (0) .. 30.
// 本月 (98000) > 上月-at-day-30 (90000) at the comparison day ⇒ ABOVE branch.
WithinMonthCumulativeTrend _trend() => WithinMonthCumulativeTrend(
  currentMonthTotal: [_p(1, 0), _p(15, 48000), _p(31, 98000)],
  currentMonthDaily: [_p(1, 0), _p(15, 34000), _p(31, 70000)],
  currentMonthJoy: [_p(1, 0), _p(15, 14000), _p(31, 28000)],
  previousMonthTotal: [_p(1, 0), _p(15, 44000), _p(30, 90000)],
  previousMonthDaily: [_p(1, 0), _p(15, 31000), _p(30, 66000)],
);

Category _cat(String id) => Category(
  id: id,
  name: id,
  icon: 'icon',
  color: '#000000',
  level: 1,
  createdAt: DateTime(2026),
);

CategoryBreakdown _bd(String id, int amount) => CategoryBreakdown(
  categoryId: id,
  categoryName: id,
  icon: 'icon',
  color: '#000000',
  amount: amount,
  percentage: 0,
  transactionCount: 1,
);

final _categoryMap = <String, Category>{
  'cat_food': _cat('cat_food'),
  'cat_transport': _cat('cat_transport'),
  'cat_hobbies': _cat('cat_hobbies'),
};

const _monthlyReport = MonthlyReport(
  year: 2026,
  month: 5,
  totalIncome: 0,
  totalExpenses: 98000,
  savings: 0,
  savingsRate: 0,
  dailyTotal: 70000,
  joyTotal: 28000,
  categoryBreakdowns: [],
  dailyExpenses: [],
);

MonthlyReport _report() => _monthlyReport.copyWith(
  categoryBreakdowns: [
    _bd('cat_food', 52000),
    _bd('cat_transport', 30000),
    _bd('cat_hobbies', 16000),
  ],
);

List<JoyCategoryAmount> _joyAmounts() => const [
  JoyCategoryAmount(categoryId: 'cat_hobbies', amount: 16000),
  JoyCategoryAmount(categoryId: 'cat_education', amount: 9000),
  JoyCategoryAmount(categoryId: 'cat_social', amount: 3000),
];

List<PerDayJoyCount> _joyCounts() => [
  PerDayJoyCount(date: DateTime(2026, 5, 4), count: 1),
  PerDayJoyCount(date: DateTime(2026, 5, 12), count: 2),
  PerDayJoyCount(date: DateTime(2026, 5, 21), count: 3),
  PerDayJoyCount(date: DateTime(2026, 5, 28), count: 1),
];

List<SatisfactionScoreBucket> _distribution() => const [
  SatisfactionScoreBucket(score: 6, count: 3),
  SatisfactionScoreBucket(score: 7, count: 5),
  SatisfactionScoreBucket(score: 8, count: 8),
  SatisfactionScoreBucket(score: 9, count: 4),
  SatisfactionScoreBucket(score: 10, count: 2),
];

Widget _wrap({required Locale locale, bool groupMode = false}) {
  return ProviderScope(
    overrides: [
      selectedTimeWindowProvider.overrideWith(_FixedTimeWindow.new),
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      accounting_providers
          .bookByIdProvider(bookId: _bookId)
          .overrideWith((_) async => _book),
      isGroupModeProvider.overrideWith((_) => groupMode),
      activeGroupProvider.overrideWith((_) => Stream.value(null)),
      shadowBooksProvider.overrideWith(
        (_) async => groupMode ? fixtureShadowBooksThree() : const [],
      ),
      earliestTransactionMonthProvider(
        bookId: _bookId,
      ).overrideWith((_) async => DateTime(2024, 12)),
      withinMonthCumulativeTrendProvider(
        bookId: _bookId,
        anchor: _anchor,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => _trend()),
      monthlyReportProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        joyMetricVariant: JoyMetricVariant.all,
        includeFamily: true,
      ).overrideWith((_) async => _report()),
      analyticsCategoriesMapProvider.overrideWith((_) async => _categoryMap),
      joyCategoryAmountsProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => _joyAmounts()),
      perDayJoyCountsProvider(
        bookId: _bookId,
        anchor: _anchor,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => _joyCounts()),
      happinessReportProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        currencyCode: 'JPY',
        joyMetricVariant: JoyMetricVariant.all,
        includeFamily: false,
      ).overrideWith((_) async => fixtureHappinessReportRich()),
      satisfactionDistributionProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        joyMetricVariant: JoyMetricVariant.all,
        includeFamily: false,
      ).overrideWith((_) async => _distribution()),
      familyHappinessProvider(
        primaryBookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => fixtureFamilyHappinessRich()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: const AnalyticsScreen(bookId: _bookId),
    ),
  );
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
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(
        File(
          '/Users/xinz/flutter/bin/cache/artifacts/material_fonts/'
          'MaterialIcons-Regular.otf',
        ).readAsBytes().then(
          (bytes) => ByteData.sublistView(Uint8List.fromList(bytes)),
        ),
      );
    await materialIcons.load();
  });

  group('AnalyticsScreen V16 primary tabs golden', () {
    Future<void> setPhoneViewport(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('personal Joy selected — light ja', (tester) async {
      await setPhoneViewport(tester);

      await tester.pumpWidget(_wrap(locale: const Locale('ja')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('analytics-primary-tab-joy')));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AnalyticsScreen),
        matchesGoldenFile('goldens/analytics_screen_scroll_smoke_light_ja.png'),
      );
    });

    testWidgets('family Spending selected — light ja', (tester) async {
      await setPhoneViewport(tester);

      await tester.pumpWidget(
        _wrap(locale: const Locale('ja'), groupMode: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('analytics-primary-tab-spending')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 600),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AnalyticsScreen),
        matchesGoldenFile(
          'goldens/analytics_screen_family_spending_light_ja.png',
        ),
      );
    });
  });
}
