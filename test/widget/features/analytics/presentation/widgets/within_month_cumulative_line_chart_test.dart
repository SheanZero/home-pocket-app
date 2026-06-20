import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/features/analytics/domain/models/within_month_cumulative_trend.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart';

import '../../../../../helpers/test_localizations.dart';

/// Anchor month used for annotation date labels (the chart builds
/// `DateTime(anchor.year, anchor.month, point.day)` for the 本月 endpoints).
final _anchor = DateTime(2026, 5);

List<CumulativePoint> _series(List<int> cumulative) => [
  for (var i = 0; i < cumulative.length; i++)
    CumulativePoint(day: i + 1, cumulativeAmount: cumulative[i]),
];

/// Pull the single [LineChart] from the tree.
LineChart _chart(WidgetTester tester) =>
    tester.widget<LineChart>(find.byType(LineChart));

/// Pull the single [LineChart] from the tree and read its bar data.
List<LineChartBarData> _bars(WidgetTester tester) =>
    _chart(tester).data.lineBarsData;

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
            anchor: _anchor,
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
            anchor: _anchor,
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
          anchor: _anchor,
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
          anchor: _anchor,
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
            anchor: _anchor,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_bars(tester).length, 1);
    },
  );

  testWidgets(
    'Test 6: grid is ON with horizontal lines only (no vertical gridlines)',
    (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          WithinMonthCumulativeLineChart(
            currentMonth: _series(const [100, 300, 600]),
            previousMonth: _series(const [120, 250, 500]),
            seriesColor: AppPalette.light.daily,
            anchor: _anchor,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final grid = _chart(tester).data.gridData;
      expect(grid.show, isTrue);
      expect(grid.drawVerticalLine, isFalse);
    },
  );

  testWidgets(
    'Test 7: left + bottom axis titles are shown; top + right are hidden',
    (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          WithinMonthCumulativeLineChart(
            currentMonth: _series(const [100, 300, 600]),
            previousMonth: null,
            seriesColor: AppPalette.light.joy,
            anchor: _anchor,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titles = _chart(tester).data.titlesData;
      expect(titles.show, isTrue);
      expect(titles.leftTitles.sideTitles.showTitles, isTrue);
      expect(titles.bottomTitles.sideTitles.showTitles, isTrue);
      expect(titles.topTitles.sideTitles.showTitles, isFalse);
      expect(titles.rightTitles.sideTitles.showTitles, isFalse);
    },
  );

  testWidgets('Test 8: minY stays 0 — never a negative tick', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        WithinMonthCumulativeLineChart(
          currentMonth: _series(const [100, 300, 600]),
          previousMonth: _series(const [120, 250, 500]),
          seriesColor: AppPalette.light.daily,
          anchor: _anchor,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_chart(tester).data.minY, 0);
  });

  testWidgets(
    'Test 9: 本月 series shows endpoint dots only at the first + last spots',
    (tester) async {
      final current = _series(const [100, 300, 600, 900]);
      await tester.pumpWidget(
        createLocalizedWidget(
          WithinMonthCumulativeLineChart(
            currentMonth: current,
            previousMonth: null,
            seriesColor: AppPalette.light.joy,
            anchor: _anchor,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bar = _bars(tester).first;
      expect(bar.dotData.show, isTrue);

      final spots = bar.spots;
      final check = bar.dotData.checkToShowDot;
      // First + last show; an interior spot does not.
      expect(check(spots.first, bar), isTrue);
      expect(check(spots.last, bar), isTrue);
      expect(check(spots[1], bar), isFalse);
    },
  );
}
