import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_colors.dart';
import 'package:home_pocket/features/home/presentation/widgets/month_overview_card.dart';

void main() {
  group('MonthOverviewCard', () {
    testWidgets('displays formatted total expense', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonthOverviewCard(
              totalExpense: 248500,
              previousMonthTotal: 282300,
            ),
          ),
        ),
      );

      expect(find.textContaining('248,500'), findsOneWidget);
    });

    testWidgets('shows negative trend percentage when spending decreased', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonthOverviewCard(
              totalExpense: 248500,
              previousMonthTotal: 282300,
            ),
          ),
        ),
      );

      // (248500-282300)/282300*100 ≈ -11.98 → rounds to -12%
      expect(find.textContaining('-12%'), findsOneWidget);
    });

    testWidgets('shows positive trend percentage when spending increased', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonthOverviewCard(
              totalExpense: 300000,
              previousMonthTotal: 250000,
            ),
          ),
        ),
      );

      // (300000-250000)/250000*100 = 20%
      expect(find.textContaining('+20%'), findsOneWidget);
    });

    testWidgets('shows 0% trend when previous month total is zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonthOverviewCard(
              totalExpense: 100000,
              previousMonthTotal: 0,
            ),
          ),
        ),
      );

      expect(find.textContaining('0%'), findsOneWidget);
    });

    testWidgets('shows last month formatted amount', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonthOverviewCard(
              totalExpense: 248500,
              previousMonthTotal: 282300,
            ),
          ),
        ),
      );

      expect(find.textContaining('282,300'), findsOneWidget);
    });

    testWidgets('has no box shadow in decoration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonthOverviewCard(
              totalExpense: 100000,
              previousMonthTotal: 100000,
            ),
          ),
        ),
      );

      // Find the outermost Container (the card container)
      final containers = tester.widgetList<Container>(find.byType(Container));
      for (final container in containers) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration && decoration.boxShadow != null) {
          fail('MonthOverviewCard should not have any box shadow');
        }
      }
    });

    testWidgets('uses border with borderDefault color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonthOverviewCard(
              totalExpense: 100000,
              previousMonthTotal: 100000,
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasCorrectBorder = containers.any((container) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration && decoration.border != null) {
          final border = decoration.border;
          if (border is Border) {
            return border.top.color == AppColors.borderDefault;
          }
        }
        return false;
      });
      expect(hasCorrectBorder, isTrue);
    });

    testWidgets('shows trending_down icon when trend is negative', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonthOverviewCard(
              totalExpense: 200000,
              previousMonthTotal: 300000,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.trending_down), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsNothing);
    });

    testWidgets('shows trending_up icon when trend is positive', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonthOverviewCard(
              totalExpense: 300000,
              previousMonthTotal: 200000,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsNothing);
    });

    testWidgets('invokes onLastMonthTap when bottom row is tapped', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthOverviewCard(
              totalExpense: 248500,
              previousMonthTotal: 282300,
              onLastMonthTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Tap the chevron_right icon area (bottom row)
      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(tapped, isTrue);
    });

    testWidgets('shows calendar icon in bottom row', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonthOverviewCard(
              totalExpense: 248500,
              previousMonthTotal: 282300,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });
  });
}
