import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/features/analytics/domain/models/within_month_cumulative_trend.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart';

import '../../../../../helpers/test_localizations.dart';

List<CumulativePoint> _series(List<int> cumulative) => [
  for (var i = 0; i < cumulative.length; i++)
    CumulativePoint(day: i + 1, cumulativeAmount: cumulative[i]),
];

/// Pull the single [LineChart] from the tree and read its bar data.
List<LineChartBarData> _bars(WidgetTester tester) {
  final chart = tester.widget<LineChart>(find.byType(LineChart));
  return chart.data.lineBarsData;
}

void main() {
  testWidgets(
    'Test 1: spend mode (current + previous) builds 2 series — 本月 solid, '
    '上月 dashed',
    (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          WithinMonthCumulativeLineChart(
            currentMonth: _series(const [100, 300, 600]),
            previousMonth: _series(const [120, 250, 500]),
            seriesColor: AppPalette.light.daily,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bars = _bars(tester);
      expect(bars.length, 2, reason: 'spend mode draws 本月 + 上月');

      // First series (本月) is solid (no dashArray) and stroke-cap round.
      expect(bars[0].dashArray, isNull);
      expect(bars[0].isStrokeCapRound, isTrue);

      // Second series (上月) is dashed.
      expect(bars[1].dashArray, isNotNull);
      expect(bars[1].dashArray, isNotEmpty);
    },
  );

  testWidgets(
    'Test 2: joy mode (current only, no previousMonth) builds exactly 1 series '
    '— the cross-period guard at the widget layer (D-E1, Pitfall 2)',
    (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          WithinMonthCumulativeLineChart(
            currentMonth: _series(const [50, 90, 140]),
            previousMonth: null,
            seriesColor: AppPalette.light.joy,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bars = _bars(tester);
      expect(bars.length, 1, reason: 'joy mode is single-line, zero cross-period');
      expect(bars[0].dashArray, isNull);
    },
  );

  testWidgets('Test 3: series color comes from the passed palette color (ADR-019)', (
    tester,
  ) async {
    final color = AppPalette.light.joy;
    await tester.pumpWidget(
      createLocalizedWidget(
        WithinMonthCumulativeLineChart(
          currentMonth: _series(const [10, 20]),
          previousMonth: null,
          seriesColor: color,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bars = _bars(tester);
    expect(bars[0].color, color);
  });

  testWidgets('Test 4: empty current series renders a placeholder, no throw', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        WithinMonthCumulativeLineChart(
          currentMonth: const [],
          previousMonth: null,
          seriesColor: AppPalette.light.daily,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Test 5: an empty previousMonth list is treated as joy/no-reference — '
    'still a single series (structural guard)',
    (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          WithinMonthCumulativeLineChart(
            currentMonth: _series(const [10, 20, 30]),
            previousMonth: const [],
            seriesColor: AppPalette.light.daily,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_bars(tester).length, 1);
    },
  );
}
