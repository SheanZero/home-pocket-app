import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/screens/category_drill_down_screen.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/category_donut_card.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;

import '../../../../../../helpers/test_localizations.dart';

const _bookId = 'book_001';
final _start = DateTime(2026, 5);
final _end = DateTime(2026, 5, 31, 23, 59, 59);

Category _cat(String id, {String? parent, required int level}) => Category(
  id: id,
  name: id,
  icon: 'icon',
  color: '#000000',
  parentId: parent,
  level: level,
  createdAt: DateTime(2026),
);

final _categoryMap = <String, Category>{
  'cat_food': _cat('cat_food', level: 1),
  'cat_food_lunch': _cat('cat_food_lunch', parent: 'cat_food', level: 2),
  'cat_transport': _cat('cat_transport', level: 1),
  'cat_hobbies': _cat('cat_hobbies', level: 1),
};

CategoryBreakdown _bd(String id, String name, int amount, double pct) =>
    CategoryBreakdown(
      categoryId: id,
      categoryName: name,
      icon: 'icon',
      color: '#000000',
      amount: amount,
      percentage: pct,
      transactionCount: 1,
    );

MonthlyReport _report(List<CategoryBreakdown> breakdowns) => MonthlyReport(
  year: 2026,
  month: 5,
  totalIncome: 0,
  totalExpenses: 30000,
  savings: 0,
  savingsRate: 0,
  dailyTotal: 20000,
  joyTotal: 10000,
  categoryBreakdowns: breakdowns,
  dailyExpenses: const [],
);

final _breakdowns = [
  _bd('cat_food_lunch', 'Lunch', 18000, 60),
  _bd('cat_transport', 'Transport', 9000, 30),
  _bd('cat_hobbies', 'Hobbies', 3000, 10),
];

Widget _subject({List<CategoryBreakdown>? breakdowns}) {
  return createLocalizedWidget(
    CategoryDonutCard(
      bookId: _bookId,
      startDate: _start,
      endDate: _end,
      joyMetricVariant: JoyMetricVariant.all,
    ),
    locale: const Locale('en'),
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith(
        (_) async => const Locale('en'),
      ),
      monthlyReportProvider(
        bookId: _bookId,
        startDate: _start,
        endDate: _end,
      ).overrideWith((_) async => _report(breakdowns ?? _breakdowns)),
      analyticsCategoriesMapProvider.overrideWith((_) async => _categoryMap),
    ],
  );
}

Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders L1-rollup legend rows amount-descending', (
    tester,
  ) async {
    await _pump(tester, _subject());

    // 3 L1 rows: food (18000), transport (9000), hobbies (3000).
    expect(find.byKey(const ValueKey('donut_legend_row_cat_food')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('donut_legend_row_cat_transport')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('donut_legend_row_cat_hobbies')),
      findsOneWidget,
    );
  });

  testWidgets('D-B1: tapping a legend ROW pushes the drill screen with the '
      'correct l1CategoryId', (tester) async {
    await _pump(tester, _subject());

    await tester.tap(find.byKey(const ValueKey('donut_legend_row_cat_food')));
    await tester.pumpAndSettle();

    final screen = tester.widget<CategoryDrillDownScreen>(
      find.byType(CategoryDrillDownScreen),
    );
    expect(screen.l1CategoryId, 'cat_food');
    expect(screen.bookId, _bookId);
  });

  testWidgets('D-D2: center total uses a TweenAnimationBuilder count-up', (
    tester,
  ) async {
    await tester.pumpWidget(_subject());
    await tester.pump();

    expect(find.byType(TweenAnimationBuilder<int>), findsOneWidget);

    // Lands on the true total after the animation settles (¥30,000).
    await tester.pumpAndSettle();
    expect(find.textContaining('30,000'), findsWidgets);
  });

  testWidgets('rolls up L2 into its L1 parent (single source, D-11)', (
    tester,
  ) async {
    // Two L2 children of cat_food should aggregate into ONE cat_food row.
    await _pump(
      tester,
      _subject(
        breakdowns: [
          _bd('cat_food_lunch', 'Lunch', 10000, 50),
          _bd('cat_food', 'Food', 6000, 30),
          _bd('cat_transport', 'Transport', 4000, 20),
        ],
      ),
    );

    expect(find.byKey(const ValueKey('donut_legend_row_cat_food')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('donut_legend_row_cat_transport')),
      findsOneWidget,
    );
    // No separate row for the L2 child.
    expect(
      find.byKey(const ValueKey('donut_legend_row_cat_food_lunch')),
      findsNothing,
    );
  });
}
