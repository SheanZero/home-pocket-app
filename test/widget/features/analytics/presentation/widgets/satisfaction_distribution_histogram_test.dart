import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/analytics_category_palette.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  // score 1 → 2, score 4 → 3, score 10 → 5; all other scores normalize to 0.
  // total = 10; weighted median (cumulative first ≥ 5) lands on score 4.
  const buckets = [
    SatisfactionScoreBucket(score: 1, count: 2),
    SatisfactionScoreBucket(score: 4, count: 3),
    SatisfactionScoreBucket(score: 10, count: 5),
  ];

  /// All gradient bars (non-zero columns) in render order.
  List<Container> gradientBars(WidgetTester tester) {
    return tester.widgetList<Container>(find.byType(Container)).where((c) {
      final decoration = c.decoration;
      return decoration is BoxDecoration && decoration.gradient != null;
    }).toList();
  }

  testWidgets('renders 10 score labels (1..10) and no fl_chart', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const SatisfactionDistributionHistogram(buckets: buckets),
      ),
    );

    for (var score = 1; score <= 10; score += 1) {
      expect(
        find.text('$score'),
        findsWidgets,
        reason: 'score label $score should render',
      );
    }
    // fl_chart is gone — no BarChart in the tree.
    expect(find.byType(Container), findsWidgets);
  });

  testWidgets('non-zero buckets render a count label; zero buckets do not', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const SatisfactionDistributionHistogram(buckets: buckets),
      ),
    );

    // Count labels for the three non-zero buckets (2, 3, 5).
    expect(find.text('2'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('5'), findsWidgets);

    // Exactly three gradient bars (one per non-zero bucket). The seven zero
    // buckets render a muted stub WITHOUT a gradient.
    expect(gradientBars(tester), hasLength(3));
  });

  testWidgets('uniform pink gradient is identical across all non-zero bars', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const SatisfactionDistributionHistogram(buckets: buckets),
      ),
    );

    final bars = gradientBars(tester);
    expect(bars, hasLength(3));

    final gradients = bars
        .map(
          (c) => (c.decoration! as BoxDecoration).gradient! as LinearGradient,
        )
        .toList();

    // All bars share ONE gradient (not a per-score color ramp).
    final first = gradients.first;
    for (final gradient in gradients) {
      expect(gradient.colors, equals(first.colors));
    }
    // Gradient bottom color is the histogram-specific token.
    expect(first.colors.last, AnalyticsCategoryPalette.histoBarBottom);
  });

  testWidgets('median bucket (data-derived, not literal 7) gets an outline', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const SatisfactionDistributionHistogram(buckets: buckets),
      ),
    );

    // The weighted median of this fixture is score 4, NOT the mock's literal 7.
    // The median bar is wrapped in a bordered Container (outline). Exactly one
    // such bordered wrapper exists.
    final borderedWrappers = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) {
          final decoration = c.decoration;
          return decoration is BoxDecoration &&
              decoration.border != null &&
              decoration.gradient == null;
        })
        .toList();
    expect(borderedWrappers, hasLength(1));
  });

  testWidgets('footer count + median pill render', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const SatisfactionDistributionHistogram(buckets: buckets),
        locale: const Locale('en'),
      ),
    );

    // Count footer (total = 10).
    expect(find.textContaining('10'), findsWidgets);
    // Median pill text (median = 4).
    expect(find.textContaining('Median satisfaction 4'), findsOneWidget);
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

  testWidgets('empty/zero buckets render without throw and no median pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const SatisfactionDistributionHistogram(buckets: []),
      ),
    );

    expect(tester.takeException(), isNull);
    // No data → no gradient bars, no median pill.
    expect(gradientBars(tester), isEmpty);
    expect(find.textContaining('Median satisfaction'), findsNothing);
  });
}
