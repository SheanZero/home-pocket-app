import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/within_month_cumulative_trend.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/analytics_card_error_state.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/within_month_trend_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;

import '../../../../../../helpers/test_localizations.dart';

const _bookId = 'book_001';
final _start = DateTime(2026, 5);
final _end = DateTime(2026, 5, 31, 23, 59, 59);
final _anchor = DateTime(2026, 5);

List<CumulativePoint> _series(List<int> cumulative) => [
  for (var i = 0; i < cumulative.length; i++)
    CumulativePoint(day: i + 1, cumulativeAmount: cumulative[i]),
];

WithinMonthCumulativeTrend _trend() => WithinMonthCumulativeTrend(
  currentMonthTotal: _series(const [100, 300, 600]),
  currentMonthDaily: _series(const [80, 200, 400]),
  currentMonthJoy: _series(const [20, 100, 200]),
  previousMonthTotal: _series(const [120, 280, 520]),
  previousMonthDaily: _series(const [100, 230, 430]),
);

Widget _subject({AsyncValue<WithinMonthCumulativeTrend>? override}) {
  final value = override ?? AsyncValue.data(_trend());
  return createLocalizedWidget(
    WithinMonthTrendCard(
      bookId: _bookId,
      startDate: _start,
      endDate: _end,
      joyMetricVariant: JoyMetricVariant.all,
    ),
    locale: const Locale('zh'),
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith(
        (_) async => const Locale('zh'),
      ),
      withinMonthCumulativeTrendProvider(
        bookId: _bookId,
        anchor: _anchor,
      ).overrideWith(
        (_) => value.when(
          data: (d) async => d,
          // Never completes → stays in the loading state with no pending timer.
          loading: () => Completer<WithinMonthCumulativeTrend>().future,
          // Throw synchronously inside the provider build → error state.
          error: (e, _) async => throw StateError(e.toString()),
        ),
      ),
    ],
  );
}

LineChartBarData _firstBar(WidgetTester tester) {
  final chart = tester.widget<LineChart>(find.byType(LineChart));
  return chart.data.lineBarsData.first;
}

int _seriesCount(WidgetTester tester) {
  final chart = tester.widget<LineChart>(find.byType(LineChart));
  return chart.data.lineBarsData.length;
}

void main() {
  testWidgets('Test 1: on data renders the trend LineChart (default 总支出 tab, '
      'dual line)', (tester) async {
    await tester.pumpWidget(_subject());
    await tester.pumpAndSettle();

    expect(find.byType(WithinMonthCumulativeLineChart), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('支出合计'), findsNothing);
    expect(
      tester
          .widget<WithinMonthCumulativeLineChart>(
            find.byType(WithinMonthCumulativeLineChart),
          )
          .height,
      WithinMonthCumulativeLineChart.defaultHeight,
    );
    // Default tab = 总支出 → spend side → 2 series (本月 + 上月).
    expect(_seriesCount(tester), 2);
  });

  testWidgets('Test 2: pill tabs — 日常 shows dual line; 悦己 shows the SINGLE '
      'joy line (no 上月, cross-period guard)', (tester) async {
    await tester.pumpWidget(_subject());
    await tester.pumpAndSettle();

    // Switch to 日常 (daily) → still spend side → 2 series.
    await tester.tap(find.byKey(const ValueKey('trend_tab_daily')));
    await tester.pumpAndSettle();
    expect(_seriesCount(tester), 2);

    // Switch to 悦己 (joy) → single line, NO previous-month reference.
    await tester.tap(find.byKey(const ValueKey('trend_tab_joy')));
    await tester.pumpAndSettle();
    expect(_seriesCount(tester), 1);
    expect(_firstBar(tester).dashArray, isNull);
  });

  testWidgets('Test 2b: the 悦己 tab subtree carries ZERO 上月 reference series '
      '(D-E1, GUARD-02 readiness)', (tester) async {
    await tester.pumpWidget(_subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('trend_tab_joy')));
    await tester.pumpAndSettle();

    // The joy chart must be structurally single-line: the widget receives a
    // null previousMonth, so no dashed reference exists.
    final widget = tester.widget<WithinMonthCumulativeLineChart>(
      find.byType(WithinMonthCumulativeLineChart),
    );
    expect(widget.previousMonth, anyOf(isNull, isEmpty));
  });

  testWidgets('Test 3: loading keeps the readable card height stable', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(override: const AsyncValue.loading()));
    await tester.pump(); // do not settle — keep it loading

    expect(find.byType(LineChart), findsNothing);
    final box = tester.widget<SizedBox>(
      find
          .descendant(
            of: find.byType(WithinMonthTrendCard),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(box.height, WithinMonthTrendCard.loadingHeight);
  });

  testWidgets('Test 3b: error → AnalyticsCardErrorState with a retry button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _subject(override: AsyncValue.error('boom', StackTrace.empty)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AnalyticsCardErrorState), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });
}
