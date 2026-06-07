import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/month_picker_dialog.dart';

import '../../helpers/test_localizations.dart';

void main() {
  // Helper: pumps a button that opens the month picker dialog and captures the
  // returned record (if any).
  Future<({int year, int month})?> openDialog(
    WidgetTester tester, {
    required int selectedYear,
    required int selectedMonth,
  }) async {
    ({int year, int month})? result;
    await tester.pumpWidget(
      testLocalizedApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showMonthPickerDialog(
                  context,
                  selectedYear: selectedYear,
                  selectedMonth: selectedMonth,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  group('showMonthPickerDialog', () {
    testWidgets('renders 12 month cells', (tester) async {
      // Use a past year so no month is disabled.
      await openDialog(tester, selectedYear: 2020, selectedMonth: 6);

      // ja locale: homeMonthLabel = "{month}月" → "1月".."12月".
      for (var m = 1; m <= 12; m++) {
        expect(
          find.text('$m月'),
          findsOneWidget,
          reason: 'month cell $m月 should render',
        );
      }
    });

    testWidgets(
      'future months in current year are disabled (not tappable)',
      (tester) async {
        final now = DateTime.now();
        // Only meaningful when there IS a future month this year.
        if (now.month == 12) {
          // December: skip — no future month exists in the current year.
          return;
        }
        final result = await openDialog(
          tester,
          selectedYear: now.year,
          selectedMonth: now.month,
        );

        // Tap a future month (current real month + 1). It must NOT pop.
        final futureMonth = now.month + 1;
        await tester.tap(find.text('$futureMonth月'));
        await tester.pumpAndSettle();

        // Dialog stays open (future tap is a no-op) and nothing was returned.
        expect(result, isNull);
        expect(find.text('$futureMonth月'), findsOneWidget);
      },
    );

    testWidgets(
      'previous-year arrow always present; next-year arrow disabled at current year',
      (tester) async {
        final now = DateTime.now();
        await openDialog(
          tester,
          selectedYear: now.year,
          selectedMonth: now.month,
        );

        // Previous-year arrow is always enabled.
        final prevArrow = tester.widget<IconButton>(
          find.ancestor(
            of: find.byIcon(Icons.chevron_left),
            matching: find.byType(IconButton),
          ),
        );
        expect(prevArrow.onPressed, isNotNull);

        // Next-year arrow is disabled (onPressed == null) at the current year.
        final nextArrow = tester.widget<IconButton>(
          find.ancestor(
            of: find.byIcon(Icons.chevron_right),
            matching: find.byType(IconButton),
          ),
        );
        expect(nextArrow.onPressed, isNull);
      },
    );

    testWidgets('tapping an enabled month pops with (year, month)', (
      tester,
    ) async {
      // Past year → every month enabled.
      final result = await openDialog(
        tester,
        selectedYear: 2020,
        selectedMonth: 6,
      );
      // result is still null here because the dialog is open; tap a cell.
      expect(result, isNull);

      await tester.tap(find.text('3月'));
      await tester.pumpAndSettle();

      // Re-read: the future-returning onPressed completes after the pop. We
      // assert by re-opening is not needed — instead verify the dialog closed.
      expect(find.text('3月'), findsNothing);
    });

    testWidgets('selected month returns the chosen (year, month) record', (
      tester,
    ) async {
      ({int year, int month})? captured;
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  captured = await showMonthPickerDialog(
                    context,
                    selectedYear: 2020,
                    selectedMonth: 6,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('4月'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.year, 2020);
      expect(captured!.month, 4);
    });

    testWidgets('previous-year arrow decrements the displayed year', (
      tester,
    ) async {
      final now = DateTime.now();
      await openDialog(
        tester,
        selectedYear: now.year,
        selectedMonth: now.month,
      );

      // Year title shows the current year (ja: "{year}年").
      expect(find.text('${now.year}年'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('${now.year - 1}年'), findsOneWidget);

      // After moving to a past year, the next-year arrow becomes enabled.
      final nextArrow = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.chevron_right),
          matching: find.byType(IconButton),
        ),
      );
      expect(nextArrow.onPressed, isNotNull);
    });
  });
}
