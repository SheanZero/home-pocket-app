import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/features/analytics/domain/models/within_month_cumulative_trend.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart';

import '../../../../../helpers/test_localizations.dart';

/// Anchor month used for annotation date labels (the chart builds
/// `DateTime(anchor.year, anchor.month, point.day)` for the 本月 endpoint, and
/// derives the whole-month X extent `daysInMonth(anchor)`). May 2026 = 31 days.
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

/// Count the endpoint annotation widgets rendered in the overlay.
Finder _endpointLabels() => find.byType(WithinMonthEndpointAnnotation);

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
    'Test 9: 本月 series shows an endpoint dot at the last spot only (no start '
    'dot — D-2)',
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
      // Last shows; the first (start) spot and interior spots do not (D-2).
      expect(check(spots.last, bar), isTrue);
      expect(check(spots.first, bar), isFalse);
      expect(check(spots[1], bar), isFalse);
    },
  );

  // ---- Round-2 corrections (kll) ----

  testWidgets(
    'Test 10 (whole-month X extent, D-1): maxX == daysInMonth(anchor) even when '
    'the current series ends before month end; minX stays 1',
    (tester) async {
      // Series ends at day 3 but anchor is May 2026 (31 days).
      await tester.pumpWidget(
        createLocalizedWidget(
          WithinMonthCumulativeLineChart(
            currentMonth: _series(const [100, 300, 600]),
            previousMonth: null,
            seriesColor: AppPalette.light.daily,
            anchor: _anchor,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_chart(tester).data.maxX, 31);
      expect(_chart(tester).data.minX, 1);
    },
  );

  testWidgets(
    'Test 11 (one endpoint label per drawn line, D-2/D-4): joy mode = 1 label; '
    'spend mode = 2 labels (本月 + 上月)',
    (tester) async {
      // Joy mode — single endpoint label, no 上月 label.
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
      expect(_endpointLabels(), findsOneWidget);

      // Spend mode — two endpoint labels (本月 + 上月).
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
      expect(_endpointLabels(), findsNWidgets(2));
    },
  );

  test(
    'Test 12 (above/below comparison, D-3): 本月 label is ABOVE when current '
    '>= prev, BELOW when current < prev',
    () {
      // 本月 >= 上月 ⇒ above.
      expect(
        WithinMonthCumulativeLineChart.labelAbove(
          currentEndAmount: 600,
          prevAtComparisonAmount: 500,
        ),
        isTrue,
      );
      expect(
        WithinMonthCumulativeLineChart.labelAbove(
          currentEndAmount: 500,
          prevAtComparisonAmount: 500,
        ),
        isTrue,
      );
      // 本月 < 上月 ⇒ below.
      expect(
        WithinMonthCumulativeLineChart.labelAbove(
          currentEndAmount: 400,
          prevAtComparisonAmount: 500,
        ),
        isFalse,
      );
    },
  );

  test(
    'Test 13b (round-3 X-axis markers): bottom-axis labels render only at '
    '6/12/18/24 — multiples of 6, dropping edges and the near-month-end mark '
    '(no 28日/30日)',
    () {
      // 30-day month (June): 6/12/18/24 show; 30 dropped; edges/non-multiples no.
      expect(WithinMonthCumulativeLineChart.showDayAxisLabel(6, 30), isTrue);
      expect(WithinMonthCumulativeLineChart.showDayAxisLabel(12, 30), isTrue);
      expect(WithinMonthCumulativeLineChart.showDayAxisLabel(18, 30), isTrue);
      expect(WithinMonthCumulativeLineChart.showDayAxisLabel(24, 30), isTrue);
      expect(WithinMonthCumulativeLineChart.showDayAxisLabel(30, 30), isFalse);
      expect(WithinMonthCumulativeLineChart.showDayAxisLabel(28, 30), isFalse);
      expect(WithinMonthCumulativeLineChart.showDayAxisLabel(1, 30), isFalse);
      expect(WithinMonthCumulativeLineChart.showDayAxisLabel(7, 30), isFalse);
      // 31-day month: 24 still shows, 30 dropped.
      expect(WithinMonthCumulativeLineChart.showDayAxisLabel(24, 31), isTrue);
      expect(WithinMonthCumulativeLineChart.showDayAxisLabel(30, 31), isFalse);
    },
  );

  testWidgets(
    'Test 13 (opposite placement, D-4): the 上月 label sits at the OPPOSITE '
    'position from the 本月 label',
    (tester) async {
      // 本月 (600) > 上月 (500) at the comparison day ⇒ 本月 above, 上月 below.
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

      final labels = tester
          .widgetList<WithinMonthEndpointAnnotation>(_endpointLabels())
          .toList();
      expect(labels.length, 2);
      final current = labels.firstWhere((l) => l.isCurrent);
      final previous = labels.firstWhere((l) => !l.isCurrent);
      // Current above ⇒ previous below (opposite).
      expect(current.above, isTrue);
      expect(previous.above, isFalse);
      expect(current.above, isNot(previous.above));
    },
  );

  testWidgets(
    'Part1② (260620-v2m, 参考图 #6): the 本月 endpoint label is FORCE-anchored '
    'ABOVE the marker even when 本月 < 上月 (no comparison-driven flip); the 上月 '
    'reference still takes the OPPOSITE side',
    (tester) async {
      // 本月 (400) < 上月 (500) at the comparison day. Under the OLD comparison
      // rule the 本月 label would drop BELOW; Part1② pins it ABOVE the endpoint
      // marker, so the 上月 reference goes below (opposite).
      await tester.pumpWidget(
        createLocalizedWidget(
          WithinMonthCumulativeLineChart(
            currentMonth: _series(const [100, 250, 400]),
            previousMonth: _series(const [120, 300, 500]),
            seriesColor: AppPalette.light.daily,
            anchor: _anchor,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final labels = tester
          .widgetList<WithinMonthEndpointAnnotation>(_endpointLabels())
          .toList();
      final current = labels.firstWhere((l) => l.isCurrent);
      final previous = labels.firstWhere((l) => !l.isCurrent);
      // 本月 ALWAYS above (Part1②); 上月 opposite.
      expect(current.above, isTrue, reason: '本月 force-above regardless of <');
      expect(previous.above, isFalse);
    },
  );

  testWidgets(
    'Part1①③ (260620-v2m): 本月 line is a softened CURVE with below-line '
    'gradient fill; 上月 reference is also curved with no fill',
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
      // 本月: curved + below-line gradient area visible.
      expect(bars[0].isCurved, isTrue);
      expect(bars[0].preventCurveOverShooting, isTrue);
      expect(bars[0].belowBarData.show, isTrue);
      expect(bars[0].belowBarData.gradient, isNotNull);
      // 上月: curved too (visual consistency), but no fill.
      expect(bars[1].isCurved, isTrue);
      expect(bars[1].belowBarData.show, isFalse);
    },
  );
}
