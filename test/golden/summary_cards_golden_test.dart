import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/summary_cards.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Fixed fixture — verbatim copy from
/// test/widget/features/analytics/presentation/widgets/analytics_money_widgets_test.dart
/// (lines 202-213). Keeping fixtures identical to the existing analog test
/// preserves the proven semantic match against MonthlyReport's constructor and
/// avoids hand-rolled field-set drift.
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

Widget _wrap({required Locale locale, required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: Scaffold(
      body: SizedBox(width: 600, height: 280, child: child),
    ),
  );
}

void main() {
  group('SummaryCards golden tests', () {
    testWidgets('Japanese (ja) — 収入/支出/貯蓄 with JPY formatting', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ja'),
          child: const SummaryCards(report: _summaryReport),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SummaryCards),
        matchesGoldenFile('goldens/summary_cards_ja.png'),
      );
    });

    testWidgets('English (en) — Income/Expenses/Savings with JPY formatting', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          child: const SummaryCards(report: _summaryReport),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SummaryCards),
        matchesGoldenFile('goldens/summary_cards_en.png'),
      );
    });
  });
}
