import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  const buckets = [
    SatisfactionScoreBucket(score: 1, count: 2),
    SatisfactionScoreBucket(score: 4, count: 3),
    SatisfactionScoreBucket(score: 10, count: 5),
  ];

  BarChartRodData bar5Rod(WidgetTester tester) {
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    // bar group for score 5 is at index 4 (scores 1..10).
    return chart.data.barGroups[4].barRods.single;
  }

  testWidgets('normalizes missing scores into all 10 bars', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const SatisfactionDistributionHistogram(buckets: buckets),
      ),
    );

    final chart = tester.widget<BarChart>(find.byType(BarChart));

    expect(chart.data.barGroups, hasLength(10));
    expect(chart.data.barGroups[4].barRods.single.toY, 1);
  });

  testWidgets('REDES-02: no Stack/Align/DecoratedBox annotation overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const SatisfactionDistributionHistogram(buckets: buckets),
        locale: const Locale('ja'),
      ),
    );

    // The "5" annotation hack used a Stack wrapping the BarChart with an
    // Align/DecoratedBox overlay. After REDES-02 the histogram renders the
    // BarChart directly (no Stack ancestor for the chart) and there is no
    // DecoratedBox-based annotation pill.
    expect(
      find.ancestor(of: find.byType(BarChart), matching: find.byType(Stack)),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('analytics_histogram_bar_5_annotation')),
      findsNothing,
    );
  });

  testWidgets('bar-5 annotation moves onto the native BarChartRodData.label', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const SatisfactionDistributionHistogram(buckets: buckets),
        locale: const Locale('ja'),
      ),
    );

    final rod = bar5Rod(tester);
    // Native fl_chart 1.2.0 per-rod label carries the annotation string.
    expect(rod.label.show, isTrue);
    expect(rod.label.text, '中央値・含未評価');

    // The color caption survives.
    expect(find.text('色は ordinal 表現です'), findsOneWidget);
  });

  testWidgets('only the bar-5 rod carries a visible label', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const SatisfactionDistributionHistogram(buckets: buckets),
      ),
    );

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    for (var i = 0; i < chart.data.barGroups.length; i++) {
      final rod = chart.data.barGroups[i].barRods.single;
      expect(rod.label.show, i == 4, reason: 'rod index $i label.show');
    }
  });

  testWidgets('bucket coloring and normalization are unchanged', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const SatisfactionDistributionHistogram(buckets: buckets),
      ),
    );

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    // score 1 (index 0) and score 10 (index 9) get distinct colors from the
    // ordinal lerp — a regression guard that _colorForScore is intact.
    final color1 = chart.data.barGroups[0].barRods.single.color;
    final color10 = chart.data.barGroups[9].barRods.single.color;
    expect(color1, isNotNull);
    expect(color10, isNotNull);
    expect(color1, isNot(color10));
    // Empty buckets render with a floor toY of 1 (normalization intact).
    expect(chart.data.barGroups[1].barRods.single.toY, 1);
  });

  testWidgets('semantic label is neutral and factual', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const SatisfactionDistributionHistogram(buckets: buckets),
      ),
    );

    final labels = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .map((semantic) => semantic.properties.label)
        .whereType<String>()
        .join(' ');

    expect(labels, contains('score 1 of 10, 2 entries of 10'));
    expect(labels, isNot(contains(RegExp('差|悪い|bad|不好|低|不満|sad'))));
  });

  testWidgets('empty/zero buckets render without throw', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const SatisfactionDistributionHistogram(buckets: []),
      ),
    );

    expect(find.byType(BarChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
