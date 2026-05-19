import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:home_pocket/features/analytics/domain/models/happiness_report.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/kpi_mini_hero_strip.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/total_spending_kpi_tile.dart';

import '../../../../../helpers/test_localizations.dart';

const _monthlyReport = MonthlyReport(
  year: 2026,
  month: 5,
  totalIncome: 0,
  totalExpenses: 41200,
  savings: 0,
  savingsRate: 0,
  survivalTotal: 30000,
  soulTotal: 11200,
  categoryBreakdowns: [],
  dailyExpenses: [],
);

const _happinessReport = HappinessReport(
  year: 2026,
  month: 5,
  bookId: 'book_001',
  totalSoulTx: 15,
  avgSatisfaction: Value(7.83, 12),
  medianSatisfaction: Value(8.0, 12),
  joyContribution: Empty(),
  highlightsCount: Empty(),
  topJoy: Empty<BestJoyMomentRow>(),
);

Widget _buildSubject() {
  return createLocalizedWidget(
    const Scaffold(
      body: SizedBox(
        height: 120,
        child: KpiMiniHeroStrip(
          monthlyReport: _monthlyReport,
          happinessReport: _happinessReport,
          currencyCode: 'JPY',
          locale: Locale('ja'),
        ),
      ),
    ),
    locale: const Locale('ja'),
  );
}

void main() {
  group('KpiMiniHeroStrip', () {
    testWidgets('renders 総 tile then 悦己 tile in horizontal Row', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.mainAxisAlignment, MainAxisAlignment.start);
      expect(row.children[0], isA<Expanded>());
      expect((row.children[0] as Expanded).child, isA<TotalSpendingKpiTile>());
      expect(row.children[2], isA<Expanded>());
      expect((row.children[2] as Expanded).child, isA<JoyHeadlineKpiTile>());
    });

    testWidgets('tiles are equally weighted with Expanded wrappers', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      final expanded = tester.widgetList<Expanded>(find.byType(Expanded));
      expect(expanded, hasLength(2));
      expect(expanded.every((widget) => widget.flex == 1), isTrue);
    });
  });
}
