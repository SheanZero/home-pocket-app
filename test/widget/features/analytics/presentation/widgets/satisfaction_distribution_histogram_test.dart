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

  testWidgets('renders permanent bar five annotation and color caption', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const SatisfactionDistributionHistogram(buckets: buckets),
        locale: const Locale('ja'),
      ),
    );

    expect(find.text('中央値・含未評価'), findsOneWidget);
    expect(find.text('色は ordinal 表現です'), findsOneWidget);
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
}
