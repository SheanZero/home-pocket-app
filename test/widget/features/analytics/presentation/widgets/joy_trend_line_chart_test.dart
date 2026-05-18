import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/daily_joy_per_yen_point.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/joy_trend_line_chart.dart';
import 'package:home_pocket/infrastructure/i18n/formatters/joy_density_formatter.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  const points = [
    DailyJoyPerYenPoint(day: 1, joyPerYen: 0.2, sampleSize: 1),
    DailyJoyPerYenPoint(day: 2, joyPerYen: 0.3, sampleSize: 1),
    DailyJoyPerYenPoint(day: 5, joyPerYen: 0.5, sampleSize: 2),
    DailyJoyPerYenPoint(day: 6, joyPerYen: 0.4, sampleSize: 1),
    DailyJoyPerYenPoint(day: 10, joyPerYen: 0.7, sampleSize: 1),
  ];

  testWidgets('renders Empty state when MetricResult is Empty', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const JoyTrendLineChart(
          result: Empty<List<DailyJoyPerYenPoint>>(),
          daysInMonth: 31,
          currencyCode: 'JPY',
          locale: Locale('ja'),
        ),
        locale: const Locale('ja'),
      ),
    );

    expect(find.byType(LineChart), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('baseline-anchored y-axis minY is 0', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const JoyTrendLineChart(
          result: Value<List<DailyJoyPerYenPoint>>(points, 6),
          daysInMonth: 31,
          currencyCode: 'JPY',
          locale: Locale('ja'),
        ),
        locale: const Locale('ja'),
      ),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));

    expect(chart.data.minY, 0);
  });

  testWidgets('gap-vs-zero segmentation renders multiple line bars', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const JoyTrendLineChart(
          result: Value<List<DailyJoyPerYenPoint>>(points, 6),
          daysInMonth: 31,
          currencyCode: 'JPY',
          locale: Locale('ja'),
        ),
        locale: const Locale('ja'),
      ),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));

    expect(chart.data.lineBarsData, hasLength(3));
    expect(chart.data.lineBarsData.map((bar) => bar.spots.length), [2, 2, 1]);
  });

  testWidgets('Y-axis labels use formatJoyDensity with currency code', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const JoyTrendLineChart(
          result: Value<List<DailyJoyPerYenPoint>>(points, 6),
          daysInMonth: 31,
          currencyCode: 'CNY',
          locale: Locale('zh'),
        ),
        locale: const Locale('zh'),
      ),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final leftTitle = chart.data.titlesData.leftTitles.sideTitles
        .getTitlesWidget(
          0.5,
          TitleMeta(
            min: 0,
            max: 1,
            parentAxisSize: 180,
            axisPosition: 0,
            appliedInterval: 0.25,
            sideTitles: const SideTitles(showTitles: true),
            formattedValue: '0.5',
            axisSide: AxisSide.left,
            rotationQuarterTurns: 0,
          ),
        );

    expect(leftTitle, isA<Text>());
    expect((leftTitle as Text).data, formatJoyDensity(0.5, 'CNY'));
  });

  testWidgets('semantic label per point reads neutral facts', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const JoyTrendLineChart(
          result: Value<List<DailyJoyPerYenPoint>>(points, 6),
          daysInMonth: 31,
          currencyCode: 'JPY',
          locale: Locale('ja'),
        ),
        locale: const Locale('ja'),
      ),
    );

    final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
    final labels = semantics
        .map((semantic) => semantic.properties.label)
        .whereType<String>()
        .join(' ');

    expect(labels, contains('day 1'));
    expect(labels, isNot(contains(RegExp('差|悪い|bad|不好|低'))));
  });
}
