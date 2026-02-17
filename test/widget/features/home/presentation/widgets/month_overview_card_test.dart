import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/month_overview_card.dart';

import '../../helpers/test_localizations.dart';

void main() {
  group('MonthOverviewCard', () {
    testWidgets('displays formatted total expense', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MonthOverviewCard(
                totalExpense: 142800,
                survivalExpense: 102200,
                soulExpense: 40600,
                previousMonthTotal: 155700,
                currentMonthNumber: 2,
                previousMonthNumber: 1,
                modeBadgeText: 'Personal',
              ),
            ),
          ),
        ),
      );

      // NumberFormat with yen symbol, no decimals
      // Total appears in both headline and comparison bar
      expect(find.text('\u00a5142,800'), findsWidgets);
    });

    testWidgets('displays mode badge', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MonthOverviewCard(
                totalExpense: 142800,
                survivalExpense: 102200,
                soulExpense: 40600,
                previousMonthTotal: 155700,
                currentMonthNumber: 2,
                previousMonthNumber: 1,
                modeBadgeText: 'Personal',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Personal'), findsOneWidget);
    });

    testWidgets('displays month labels correctly for January edge case', (
      tester,
    ) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MonthOverviewCard(
                totalExpense: 50000,
                survivalExpense: 30000,
                soulExpense: 20000,
                previousMonthTotal: 60000,
                currentMonthNumber: 1,
                previousMonthNumber: 12,
                modeBadgeText: 'Personal',
              ),
            ),
          ),
        ),
      );

      // ja locale: homeMonthLabel = "{month}月"
      expect(find.text('1月'), findsOneWidget);
      expect(find.text('12月'), findsOneWidget);
      expect(find.text('0月'), findsNothing);
    });

    testWidgets('shows survival and soul amounts', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MonthOverviewCard(
                totalExpense: 142800,
                survivalExpense: 102200,
                soulExpense: 40600,
                previousMonthTotal: 155700,
                currentMonthNumber: 2,
                previousMonthNumber: 1,
                modeBadgeText: 'Personal',
              ),
            ),
          ),
        ),
      );

      expect(find.text('\u00a5102,200'), findsOneWidget);
      expect(find.text('\u00a540,600'), findsOneWidget);
    });

    testWidgets('displays localized labels', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MonthOverviewCard(
                totalExpense: 142800,
                survivalExpense: 102200,
                soulExpense: 40600,
                previousMonthTotal: 155700,
                currentMonthNumber: 2,
                previousMonthNumber: 1,
                modeBadgeText: 'Personal',
              ),
            ),
          ),
        ),
      );

      // ja locale labels
      expect(find.text('今月の出費'), findsOneWidget);
      // 暮らしの支出 appears in metrics and legend
      expect(find.text('暮らしの支出'), findsWidgets);
      // ときめき支出 appears in metrics and legend
      expect(find.text('ときめき支出'), findsWidgets);
      expect(find.text('先月比'), findsOneWidget);
    });
  });
}
