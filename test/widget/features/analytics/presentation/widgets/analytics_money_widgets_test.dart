import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/i18n/formatter_service.dart';
import 'package:home_pocket/features/analytics/domain/models/budget_progress.dart';
import 'package:home_pocket/features/analytics/domain/models/month_comparison.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/budget_progress_list.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/category_breakdown_list.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/ledger_ratio_chart.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/month_comparison_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/summary_cards.dart';
import 'package:home_pocket/generated/app_localizations.dart';

void main() {
  group('Analytics money widgets', () {
    testWidgets(
      'SummaryCards renders localized English labels, formatted yen, and tabular amount styles',
      (tester) async {
        const locale = Locale('en');

        await tester.pumpWidget(
          _localizedApp(
            locale: locale,
            child: const SummaryCards(report: _summaryReport),
          ),
        );

        expect(find.text('Income'), findsOneWidget);
        expect(find.text('Expenses'), findsOneWidget);
        expect(find.text('Savings'), findsOneWidget);
        expect(find.text('Savings Rate'), findsOneWidget);

        _expectMoneyText(
          tester,
          const FormatterService().formatCurrency(123456, 'JPY', locale),
        );
        _expectMoneyText(
          tester,
          const FormatterService().formatCurrency(50000, 'JPY', locale),
        );
        _expectMoneyText(
          tester,
          const FormatterService().formatCurrency(73456, 'JPY', locale),
        );
      },
    );

    testWidgets(
      'BudgetProgressList renders localized Japanese labels, formatted yen, and tabular amount styles',
      (tester) async {
        const locale = Locale('ja');

        await tester.pumpWidget(
          _localizedApp(
            locale: locale,
            child: const BudgetProgressList(progressList: [_budgetProgress]),
          ),
        );

        expect(find.text('予算の進捗'), findsOneWidget);
        expect(find.textContaining('食費'), findsOneWidget);

        _expectMoneyText(
          tester,
          '${const FormatterService().formatCurrency(25000, 'JPY', locale)} / '
          '${const FormatterService().formatCurrency(50000, 'JPY', locale)}',
        );
        _expectMoneyText(
          tester,
          '残り: ${const FormatterService().formatCurrency(25000, 'JPY', locale)}',
        );
      },
    );

    testWidgets(
      'CategoryBreakdownList renders localized English labels, formatted yen, and tabular amount styles',
      (tester) async {
        const locale = Locale('en');

        await tester.pumpWidget(
          _localizedApp(
            locale: locale,
            child: const CategoryBreakdownList(breakdowns: [_categoryFood]),
          ),
        );

        expect(find.text('Category Details'), findsOneWidget);
        expect(find.text('2 transactions'), findsOneWidget);
        expect(find.text('Food'), findsOneWidget);

        _expectMoneyText(
          tester,
          const FormatterService().formatCurrency(123456, 'JPY', locale),
        );
        _expectAllYenTextsUseTabularFigures(tester);
      },
    );

    testWidgets(
      'LedgerRatioChart renders localized Japanese labels, formatted yen, and tabular amount styles',
      (tester) async {
        const locale = Locale('ja');

        await tester.pumpWidget(
          _localizedApp(
            locale: locale,
            child: const LedgerRatioChart(
              survivalTotal: 50000,
              soulTotal: 25000,
            ),
          ),
        );

        expect(find.text('生存 vs 魂'), findsOneWidget);
        expect(find.text('生存帳簿'), findsOneWidget);
        expect(find.text('魂帳簿'), findsOneWidget);

        _expectMoneyText(
          tester,
          const FormatterService().formatCurrency(50000, 'JPY', locale),
        );
        _expectMoneyText(
          tester,
          const FormatterService().formatCurrency(25000, 'JPY', locale),
        );
        _expectAllYenTextsUseTabularFigures(tester);
      },
    );

    testWidgets('MonthComparisonCard renders localized Japanese labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        _localizedApp(
          locale: const Locale('ja'),
          child: const MonthComparisonCard(comparison: _monthComparison),
        ),
      );

      expect(find.text('収入'), findsOneWidget);
      expect(find.text('支出'), findsOneWidget);
      expect(find.text('12.5%'), findsOneWidget);
      expect(find.text('8.0%'), findsOneWidget);
    });
  });
}

Widget _localizedApp({required Locale locale, required Widget child}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

void _expectMoneyText(WidgetTester tester, String value) {
  final finder = find.text(value);
  expect(finder, findsOneWidget);

  final text = tester.widget<Text>(finder);
  expect(text.style?.fontFeatures, contains(FontFeature.tabularFigures()));
}

void _expectAllYenTextsUseTabularFigures(WidgetTester tester) {
  final yenTexts = tester.widgetList<Text>(find.textContaining('¥'));
  expect(yenTexts, isNotEmpty);

  for (final text in yenTexts) {
    expect(
      text.style?.fontFeatures,
      contains(FontFeature.tabularFigures()),
      reason: 'Money text "${text.data}" must use tabular figures.',
    );
  }
}

const _summaryReport = MonthlyReport(
  year: 2026,
  month: 4,
  totalIncome: 123456,
  totalExpenses: 50000,
  savings: 73456,
  savingsRate: 59.5,
  survivalTotal: 40000,
  soulTotal: 10000,
  categoryBreakdowns: [],
  dailyExpenses: [],
);

const _budgetProgress = BudgetProgress(
  categoryId: 'food',
  categoryName: '食費',
  icon: '🍱',
  color: '#E85A4F',
  budgetAmount: 50000,
  spentAmount: 25000,
  percentage: 50,
  status: BudgetStatus.safe,
  remainingAmount: 25000,
);

const _categoryFood = CategoryBreakdown(
  categoryId: 'food',
  categoryName: 'Food',
  icon: '🍱',
  color: '#E85A4F',
  amount: 123456,
  percentage: 42.5,
  transactionCount: 2,
);

const _monthComparison = MonthComparison(
  previousMonth: 3,
  previousYear: 2026,
  previousIncome: 120000,
  previousExpenses: 50000,
  incomeChange: 12.5,
  expenseChange: -8,
);
