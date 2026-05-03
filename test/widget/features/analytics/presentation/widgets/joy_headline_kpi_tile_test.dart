import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:home_pocket/features/analytics/domain/models/happiness_report.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart';

import '../../../../../helpers/test_localizations.dart';

HappinessReport _happinessReport({
  MetricResult<double> avgSatisfaction = const Value(7.83, 12),
  MetricResult<double> medianSatisfaction = const Value(8.0, 12),
  int totalSoulTx = 15,
}) {
  return HappinessReport(
    year: 2026,
    month: 5,
    bookId: 'book_001',
    totalSoulTx: totalSoulTx,
    avgSatisfaction: avgSatisfaction,
    medianSatisfaction: medianSatisfaction,
    joyPerYen: const Empty(),
    highlightsCount: const Empty(),
    topJoy: const Empty<BestJoyMomentRow>(),
  );
}

Widget _buildSubject(HappinessReport report) {
  return createLocalizedWidget(
    Scaffold(
      body: JoyHeadlineKpiTile(report: report, locale: const Locale('ja')),
    ),
    locale: const Locale('ja'),
  );
}

void main() {
  group('JoyHeadlineKpiTile', () {
    testWidgets('renders Empty state caption when avgSatisfaction is Empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(
          _happinessReport(
            avgSatisfaction: const Empty(),
            medianSatisfaction: const Empty(),
            totalSoulTx: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('データを集計中...'), findsOneWidget);
    });

    testWidgets('renders mean primary value to 1 decimal place when Value', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(_happinessReport()));
      await tester.pumpAndSettle();

      expect(find.text('7.8'), findsOneWidget);
    });

    testWidgets('renders sub-line median + n=k/N coverage', (tester) async {
      await tester.pumpWidget(_buildSubject(_happinessReport()));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(RegExp(r'中央値 8(\.0)? · n=12/15')),
        findsOneWidget,
      );
    });

    testWidgets('Semantic label reads label + value, not transaction details', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      await tester.pumpWidget(_buildSubject(_happinessReport()));
      await tester.pumpAndSettle();

      final semanticsWidget = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(JoyHeadlineKpiTile),
          matching: find.byType(Semantics),
        ),
      );

      expect(semanticsWidget.properties.label, contains('悦己'));
      expect(semanticsWidget.properties.label, contains('7.8'));
      expect(semanticsWidget.properties.label, isNot(contains('Starbucks')));
      expect(semanticsWidget.properties.label, isNot(contains('merchant')));
      expect(semanticsWidget.properties.label, isNot(contains('transaction')));
    });
  });
}
