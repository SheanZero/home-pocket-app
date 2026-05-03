import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/category_spend_donut_chart.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  List<CategoryBreakdown> breakdowns() {
    return const [
      CategoryBreakdown(
        categoryId: 'food',
        categoryName: 'Food',
        icon: 'food',
        color: '',
        amount: 5000,
        percentage: 50,
        transactionCount: 5,
      ),
      CategoryBreakdown(
        categoryId: 'rent',
        categoryName: 'Rent',
        icon: 'home',
        color: '',
        amount: 2500,
        percentage: 25,
        transactionCount: 1,
      ),
      CategoryBreakdown(
        categoryId: 'train',
        categoryName: 'Train',
        icon: 'train',
        color: '',
        amount: 1500,
        percentage: 15,
        transactionCount: 3,
      ),
      CategoryBreakdown(
        categoryId: 'books',
        categoryName: 'Books',
        icon: 'book',
        color: '',
        amount: 600,
        percentage: 6,
        transactionCount: 2,
      ),
      CategoryBreakdown(
        categoryId: 'coffee',
        categoryName: 'Coffee',
        icon: 'coffee',
        color: '',
        amount: 400,
        percentage: 4,
        transactionCount: 4,
      ),
    ];
  }

  testWidgets('renders top categories plus Other as donut sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        CategorySpendDonutChart(breakdowns: breakdowns(), topCount: 3),
      ),
    );

    final chart = tester.widget<PieChart>(find.byType(PieChart));

    expect(chart.data.centerSpaceRadius, greaterThan(0));
    expect(chart.data.sections, hasLength(4));
    expect(chart.data.sections.last.value, 1000);
    expect(find.textContaining('Other'), findsOneWidget);
  });

  testWidgets('legend includes category names and percentages', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        CategorySpendDonutChart(breakdowns: breakdowns(), topCount: 3),
      ),
    );

    expect(find.textContaining('Food'), findsOneWidget);
    expect(find.textContaining('50%'), findsWidgets);
    expect(find.textContaining('Rent'), findsOneWidget);
    expect(find.textContaining('25%'), findsWidgets);
  });
}
