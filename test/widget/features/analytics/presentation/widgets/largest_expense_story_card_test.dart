import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/largest_expense_story_card.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  const locale = Locale('ja');

  testWidgets('renders title, category, amount, and date when expense exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        LargestExpenseStoryCard(
          expense: _largestExpense,
          currencyCode: 'JPY',
          locale: locale,
        ),
        locale: locale,
      ),
    );

    expect(find.text('総 · 今月の最大支出'), findsOneWidget);
    expect(find.textContaining('食費'), findsOneWidget);
    expect(find.textContaining('¥25,000'), findsOneWidget);
    expect(find.textContaining('5月20日'), findsOneWidget);
  });

  testWidgets('renders empty state when expense is null', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const LargestExpenseStoryCard(
          expense: null,
          currencyCode: 'JPY',
          locale: locale,
        ),
        locale: locale,
      ),
    );

    expect(find.text('データなし — 今月はまだ記録がありません'), findsOneWidget);
  });

  testWidgets('tap invokes callback when expense is present', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      createLocalizedWidget(
        LargestExpenseStoryCard(
          expense: _largestExpense,
          currencyCode: 'JPY',
          locale: locale,
          onTap: () => tapped = true,
        ),
        locale: locale,
      ),
    );

    await tester.tap(find.byType(LargestExpenseStoryCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('semantics label reads category amount and date only', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        LargestExpenseStoryCard(
          expense: _largestExpense,
          currencyCode: 'JPY',
          locale: locale,
        ),
        locale: locale,
      ),
    );

    final semantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label ?? '').contains('¥25,000'),
      ),
    );
    final label = semantics.properties.label;

    expect(label, contains('食費'));
    expect(label, contains('¥25,000'));
    expect(label, contains('5月20日'));
    expect(label, isNot(contains('merchant')));
    expect(label, isNot(contains('description')));
  });
}

final _largestExpense = LargestMonthlyExpense(
  transactionId: 't1',
  amount: 25000,
  categoryId: 'cat_food',
  timestamp: DateTime(2026, 5, 20),
);
