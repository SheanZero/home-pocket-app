@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
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
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';

import '../helpers/happiness_test_fixtures.dart';

/// Full-page scroll-smoke golden for [AnalyticsScreen] (D-07, Plan 47-05).
///
/// Coverage (GUARD-04 / 47-UI-SPEC §Golden Visual-Contract Matrix):
/// - ja / light, full-page card-ORDER verification (1 master).
///
/// Overrides ALL providers the 5 always-visible cards watch with deterministic
/// fixtures so the whole page renders in one tall frame; the golden captures the
/// round-5 B card order: within_month_trend → category_donut → joy_spend →
/// joy_calendar → satisfaction_histogram (the registry lineup, D-07). Solo mode
/// (isGroupMode false) so the group-only family_insight card is absent.
///
/// Wraps the PRODUCTION [AppTheme] so `context.palette` resolves the real
/// ADR-019 palette.

const _bookId = 'book_a';
final _windowStart = DateTime(2026, 5);
final _windowEnd = DateTime(2026, 5, 31, 23, 59, 59);
final _anchor = DateTime(2026, 5);

class _FixedTimeWindow extends SelectedTimeWindow {
  _FixedTimeWindow();

  @override
  TimeWindow build() => TimeWindow.month(year: 2026, month: 5);
}

CumulativePoint _p(int day, int amount) =>
    CumulativePoint(day: day, cumulativeAmount: amount);

WithinMonthCumulativeTrend _trend() => WithinMonthCumulativeTrend(
  currentMonthTotal: [_p(1, 3000), _p(15, 48000), _p(31, 98000)],
  currentMonthDaily: [_p(1, 2000), _p(15, 34000), _p(31, 70000)],
  currentMonthJoy: [_p(1, 1000), _p(15, 14000), _p(31, 28000)],
  previousMonthTotal: [_p(1, 2500), _p(15, 44000), _p(31, 90000)],
  previousMonthDaily: [_p(1, 1800), _p(15, 31000), _p(31, 66000)],
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

Widget _wrap({required Locale locale}) {
  return ProviderScope(
    overrides: [
      selectedTimeWindowProvider.overrideWith(_FixedTimeWindow.new),
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      isGroupModeProvider.overrideWith((_) => false),
      activeGroupProvider.overrideWith((_) => Stream.value(null)),
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
      ).overrideWith((_) async => fixtureHappinessReportRich()),
      satisfactionDistributionProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => _distribution()),
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
  group('AnalyticsScreen scroll-smoke golden', () {
    testWidgets('full-page card order — light ja', (tester) async {
      // Tall surface so the whole 5-card lineup is captured in one frame (D-07).
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(locale: const Locale('ja')));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AnalyticsScreen),
        matchesGoldenFile('goldens/analytics_screen_scroll_smoke_light_ja.png'),
      );
    });
  });
}
