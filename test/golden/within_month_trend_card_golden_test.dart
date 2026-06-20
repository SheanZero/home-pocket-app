@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/analytics/domain/models/within_month_cumulative_trend.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/within_month_trend_card.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Golden tests for [WithinMonthTrendCard] (round-5 B card #1, Plan 47-05).
///
/// Coverage (GUARD-04 / 47-UI-SPEC §Golden Visual-Contract Matrix):
/// - ja/zh/en × light/dark (6 value-state masters)
/// - + empty state (D-08④, 1 master)
///
/// Wraps the PRODUCTION [AppTheme] (NOT bare `ThemeData.light()/dark()`) so
/// `context.palette` resolves the real ADR-019 `AppPalette.light/.dark` — the
/// goldens are palette-regression detectors, not just layout snapshots.

const _bookId = 'book_a';
final _startDate = DateTime(2026, 5, 1);
final _endDate = DateTime(2026, 5, 31, 23, 59, 59);
// The card derives anchor = DateTime(endDate.year, endDate.month).
final _anchor = DateTime(2026, 5);

CumulativePoint _p(int day, int amount) =>
    CumulativePoint(day: day, cumulativeAmount: amount);

/// Deterministic within-month cumulative trend in the round-2 (kll) use-case
/// OUTPUT shape so the masters show the corrected look:
///  - every current-month series carry-forwards day 1 (cumulative 0) .. day 31
///    (May is a COMPLETE past month, so the right edge is month-end).
///  - every previous-month (April, 30 days) series spans day 1 (0) .. day 30.
///  - at the comparison day (31) 本月 (98000) > 上月-at-day-30 (90000) on the
///    total tab, exercising the ABOVE branch (本月 above / 上月 below, D-3/D-4)
///    so both endpoint labels are visible without collision.
WithinMonthCumulativeTrend _fixtureRich() => WithinMonthCumulativeTrend(
  currentMonthTotal: [_p(1, 0), _p(10, 24000), _p(20, 61000), _p(31, 98000)],
  currentMonthDaily: [_p(1, 0), _p(10, 18000), _p(20, 44000), _p(31, 70000)],
  currentMonthJoy: [_p(1, 0), _p(10, 6000), _p(20, 17000), _p(31, 28000)],
  previousMonthTotal: [_p(1, 0), _p(10, 21000), _p(20, 55000), _p(30, 90000)],
  previousMonthDaily: [_p(1, 0), _p(10, 16000), _p(20, 40000), _p(30, 66000)],
);

const _fixtureEmpty = WithinMonthCumulativeTrend(
  currentMonthTotal: [],
  currentMonthDaily: [],
  currentMonthJoy: [],
  previousMonthTotal: [],
  previousMonthDaily: [],
);

Widget _wrap({
  required Locale locale,
  required WithinMonthCumulativeTrend trend,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [
      withinMonthCumulativeTrendProvider(
        bookId: _bookId,
        anchor: _anchor,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => trend),
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
      themeMode: themeMode,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            height: 460,
            child: SingleChildScrollView(
              child: WithinMonthTrendCard(
                bookId: _bookId,
                startDate: _startDate,
                endDate: _endDate,
                joyMetricVariant: JoyMetricVariant.all,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('WithinMonthTrendCard golden', () {
    for (final locale in const [Locale('ja'), Locale('zh'), Locale('en')]) {
      final tag = locale.languageCode;
      testWidgets('value — light $tag', (tester) async {
        await tester.pumpWidget(
          _wrap(locale: locale, trend: _fixtureRich()),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(WithinMonthTrendCard),
          matchesGoldenFile('goldens/within_month_trend_card_light_$tag.png'),
        );
      });

      testWidgets('value — dark $tag', (tester) async {
        await tester.pumpWidget(
          _wrap(
            locale: locale,
            trend: _fixtureRich(),
            themeMode: ThemeMode.dark,
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(WithinMonthTrendCard),
          matchesGoldenFile('goldens/within_month_trend_card_dark_$tag.png'),
        );
      });
    }

    testWidgets('empty — light ja', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('ja'), trend: _fixtureEmpty),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(WithinMonthTrendCard),
        matchesGoldenFile('goldens/within_month_trend_card_empty_light_ja.png'),
      );
    });
  });
}
