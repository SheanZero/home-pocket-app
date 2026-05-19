import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/time_window.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_time_window.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/time_window_chip.dart';

import '../../../../../helpers/test_localizations.dart';

class _TestSelectedTimeWindow extends SelectedTimeWindow {
  _TestSelectedTimeWindow();

  static TimeWindow fixedWindow = const TimeWindow.month(year: 2026, month: 5);

  @override
  TimeWindow build() => fixedWindow;
}

Widget _buildSubject({Locale locale = const Locale('en')}) {
  return createLocalizedWidget(
    Scaffold(
      appBar: AppBar(
        actions: [
          TimeWindowChip(locale: locale, earliestData: DateTime(2026, 3, 1)),
        ],
      ),
    ),
    locale: locale,
    overrides: [
      selectedTimeWindowProvider.overrideWith(_TestSelectedTimeWindow.new),
    ],
  );
}

void main() {
  group('TimeWindowChip', () {
    testWidgets('renders month variant label in English', (tester) async {
      _TestSelectedTimeWindow.fixedWindow = const TimeWindow.month(
        year: 2026,
        month: 5,
      );

      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('May 2026'), findsOneWidget);
    });

    testWidgets('renders year variant label in English', (tester) async {
      _TestSelectedTimeWindow.fixedWindow = const TimeWindow.year(year: 2026);

      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('2026'), findsOneWidget);
    });

    testWidgets('renders year variant label in Japanese', (tester) async {
      _TestSelectedTimeWindow.fixedWindow = const TimeWindow.year(year: 2026);

      await tester.pumpWidget(_buildSubject(locale: const Locale('ja')));
      await tester.pumpAndSettle();

      expect(find.text('2026年'), findsOneWidget);
    });

    testWidgets('renders quarter variant label in English', (tester) async {
      _TestSelectedTimeWindow.fixedWindow = const TimeWindow.quarter(
        year: 2026,
        quarter: 2,
      );

      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Q2 2026'), findsOneWidget);
    });

    testWidgets('renders week variant label in English', (tester) async {
      _TestSelectedTimeWindow.fixedWindow = TimeWindow.week(
        mondayStart: DateTime(2026, 5, 11),
      );

      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Week of May 11'), findsOneWidget);
    });

    testWidgets('renders custom variant label in English', (tester) async {
      _TestSelectedTimeWindow.fixedWindow = TimeWindow.custom(
        startDate: DateTime(2026, 3, 15),
        endDate: DateTime(2026, 7, 20),
      );

      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      expect(find.textContaining('Mar 15'), findsOneWidget);
      expect(find.textContaining('Jul 20'), findsOneWidget);
    });

    testWidgets('tap target is at least 44px', (tester) async {
      _TestSelectedTimeWindow.fixedWindow = const TimeWindow.month(
        year: 2026,
        month: 5,
      );

      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(constrainedBox.constraints.minWidth, greaterThanOrEqualTo(44));
      expect(constrainedBox.constraints.minHeight, greaterThanOrEqualTo(44));
    });

    testWidgets('has a hittable non-null tap handler', (tester) async {
      _TestSelectedTimeWindow.fixedWindow = const TimeWindow.month(
        year: 2026,
        month: 5,
      );

      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNotNull);
      expect(find.byType(InkWell).hitTestable(), findsOneWidget);
    });
  });
}
