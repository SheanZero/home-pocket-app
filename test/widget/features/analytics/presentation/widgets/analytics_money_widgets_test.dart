import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/i18n/formatter_service.dart';
import 'package:home_pocket/features/analytics/domain/models/budget_progress.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/budget_progress_list.dart';
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
