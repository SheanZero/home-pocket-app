import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/time_window.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_time_window.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/time_window_chip.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/time_window_picker_sheet.dart';

import '../../../../../helpers/test_localizations.dart';

class _TestSelectedTimeWindow extends SelectedTimeWindow {
  _TestSelectedTimeWindow();

  static TimeWindow fixedWindow = const TimeWindow.month(year: 2026, month: 5);
  static TimeWindow? lastSetWindow;
  static int setWindowCalls = 0;

  static void reset([TimeWindow? window]) {
    fixedWindow = window ?? const TimeWindow.month(year: 2026, month: 5);
    lastSetWindow = null;
    setWindowCalls = 0;
  }

  @override
  TimeWindow build() => fixedWindow;

  @override
  void setWindow(TimeWindow window) {
    setWindowCalls += 1;
    lastSetWindow = window;
    super.setWindow(window);
  }
}

class _InvertedDateTimeRange extends DateTimeRange {
  _InvertedDateTimeRange()
    : super(start: DateTime(2026, 4, 1), end: DateTime(2026, 4, 2));

  @override
  DateTime get start => DateTime(2026, 5, 1);
}

Widget _buildSheetHost({
  Locale locale = const Locale('en'),
  TimeWindow? initialWindow,
  DateTime? earliestData,
  Future<DateTimeRange?> Function(BuildContext, DateTime, DateTime)?
  pickRangeOverride,
}) {
  _TestSelectedTimeWindow.reset(initialWindow);
  return createLocalizedWidget(
    Consumer(
      builder: (context, ref, _) {
        return Scaffold(
          body: ElevatedButton(
            key: const Key('openSheet'),
            onPressed: () => TimeWindowPickerSheet.show(
              context,
              ref,
              earliestData: earliestData,
              pickRangeOverride: pickRangeOverride,
            ),
            child: const Text('open'),
          ),
        );
      },
    ),
    locale: locale,
    overrides: [
      selectedTimeWindowProvider.overrideWith(_TestSelectedTimeWindow.new),
    ],
  );
}

Widget _buildChipHost() {
  _TestSelectedTimeWindow.reset(const TimeWindow.month(year: 2026, month: 5));
  return createLocalizedWidget(
    Scaffold(
      appBar: AppBar(
        actions: [
          TimeWindowChip(
            locale: const Locale('en'),
            earliestData: DateTime(2025, 1, 1),
          ),
        ],
      ),
    ),
    overrides: [
      selectedTimeWindowProvider.overrideWith(_TestSelectedTimeWindow.new),
    ],
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('openSheet')));
  await tester.pumpAndSettle();
}

void main() {
  group('TimeWindowPickerSheet', () {
    testWidgets('opens from chip with Month preselected', (tester) async {
      await tester.pumpWidget(_buildChipHost());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TimeWindowChip));
      await tester.pumpAndSettle();

      expect(find.text('Time window'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Month'), findsOneWidget);
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Month'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('type-row swap to Year shows year list', (tester) async {
      await tester.pumpWidget(
        _buildSheetHost(earliestData: DateTime(2024, 1, 1)),
      );
      await _openSheet(tester);

      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();

      expect(find.text(DateTime.now().year.toString()), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
    });

    testWidgets('list-row tap commits a year and closes', (tester) async {
      await tester.pumpWidget(
        _buildSheetHost(earliestData: DateTime(2024, 1, 1)),
      );
      await _openSheet(tester);
      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('2025'));
      await tester.pumpAndSettle();

      expect(_TestSelectedTimeWindow.setWindowCalls, 1);
      expect(
        _TestSelectedTimeWindow.lastSetWindow,
        const TimeWindow.year(year: 2025),
      );
      expect(find.text('Time window'), findsNothing);
    });

    testWidgets('Quarter list renders English labels', (tester) async {
      await tester.pumpWidget(
        _buildSheetHost(earliestData: DateTime(2026, 1, 1)),
      );
      await _openSheet(tester);

      await tester.tap(find.text('Quarter'));
      await tester.pumpAndSettle();

      expect(find.text('Q2 2026'), findsOneWidget);
    });

    testWidgets('Quarter list renders Japanese labels', (tester) async {
      await tester.pumpWidget(
        _buildSheetHost(
          locale: const Locale('ja'),
          earliestData: DateTime(2026, 1, 1),
        ),
      );
      await _openSheet(tester);

      await tester.tap(find.text('四半期'));
      await tester.pumpAndSettle();

      expect(find.textContaining('第2四半期'), findsOneWidget);
    });

    testWidgets('Week list renders Monday-anchored rows', (tester) async {
      await tester.pumpWidget(
        _buildSheetHost(earliestData: DateTime(2026, 5, 1)),
      );
      await _openSheet(tester);

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Week of'), findsWidgets);
    });

    testWidgets('Custom invokes pick range override', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _buildSheetHost(
          pickRangeOverride: (context, firstDate, lastDate) async {
            called = true;
            return null;
          },
        ),
      );
      await _openSheet(tester);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick a date range'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('Custom valid range commits and closes', (tester) async {
      final end = DateTime.now().subtract(const Duration(days: 1));
      final start = DateTime(end.year, end.month - 2, end.day);
      await tester.pumpWidget(
        _buildSheetHost(
          pickRangeOverride: (context, firstDate, lastDate) async {
            return DateTimeRange(start: start, end: end);
          },
        ),
      );
      await _openSheet(tester);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick a date range'));
      await tester.pumpAndSettle();

      expect(_TestSelectedTimeWindow.setWindowCalls, 1);
      expect(
        _TestSelectedTimeWindow.lastSetWindow,
        TimeWindow.custom(startDate: start, endDate: end),
      );
      expect(find.text('Time window'), findsNothing);
    });

    testWidgets('Custom inverted range shows localized error', (tester) async {
      await tester.pumpWidget(
        _buildSheetHost(
          pickRangeOverride: (context, firstDate, lastDate) async {
            return _InvertedDateTimeRange();
          },
        ),
      );
      await _openSheet(tester);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick a date range'));
      await tester.pump();

      expect(find.text('Start date must be before end date.'), findsOneWidget);
      expect(_TestSelectedTimeWindow.setWindowCalls, 0);
    });

    testWidgets('Custom longer than 12 months shows localized error', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSheetHost(
          pickRangeOverride: (context, firstDate, lastDate) async {
            return DateTimeRange(
              start: DateTime(2024, 1, 1),
              end: DateTime(2025, 2, 1),
            );
          },
        ),
      );
      await _openSheet(tester);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick a date range'));
      await tester.pump();

      expect(
        find.text('Range cannot exceed 12 months. Pick a shorter range.'),
        findsOneWidget,
      );
      expect(_TestSelectedTimeWindow.setWindowCalls, 0);
    });

    testWidgets('Custom future end shows localized error', (tester) async {
      await tester.pumpWidget(
        _buildSheetHost(
          pickRangeOverride: (context, firstDate, lastDate) async {
            return DateTimeRange(
              start: DateTime.now(),
              end: DateTime.now().add(const Duration(days: 30)),
            );
          },
        ),
      );
      await _openSheet(tester);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick a date range'));
      await tester.pump();

      expect(find.text('End date cannot be in the future.'), findsOneWidget);
      expect(_TestSelectedTimeWindow.setWindowCalls, 0);
    });

    testWidgets('cancel via backdrop dismisses without commit', (tester) async {
      await tester.pumpWidget(_buildSheetHost());
      await _openSheet(tester);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Time window'), findsNothing);
      expect(_TestSelectedTimeWindow.setWindowCalls, 0);
    });
  });
}
