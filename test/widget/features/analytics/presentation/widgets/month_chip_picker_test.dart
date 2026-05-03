import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/month_chip_picker.dart';

import '../../../../../helpers/test_localizations.dart';

class TestSelectedMonth extends SelectedMonth {
  TestSelectedMonth(this.initialMonth);

  final DateTime initialMonth;
  DateTime? lastSetMonth;
  int setMonthCalls = 0;

  @override
  DateTime build() => initialMonth;

  @override
  void setMonth(DateTime month) {
    setMonthCalls += 1;
    lastSetMonth = month;
    super.setMonth(month);
  }
}

Widget _buildSubject(TestSelectedMonth notifier) {
  return createLocalizedWidget(
    Scaffold(
      appBar: AppBar(
        actions: [
          MonthChipPicker(
            locale: Locale('ja'),
            earliestMonth: DateTime(2026, 3),
            currentMonth: DateTime(2026, 5),
          ),
        ],
      ),
    ),
    locale: const Locale('ja'),
    overrides: [selectedMonthProvider.overrideWith(() => notifier)],
  );
}

void main() {
  group('MonthChipPicker', () {
    testWidgets('renders chip with current month label + ▼ glyph', (
      tester,
    ) async {
      final notifier = TestSelectedMonth(DateTime(2026, 5));

      await tester.pumpWidget(_buildSubject(notifier));
      await tester.pumpAndSettle();

      expect(find.textContaining('2026年5月'), findsOneWidget);
      expect(find.text('▼'), findsOneWidget);
    });

    testWidgets('tap opens bottom sheet', (tester) async {
      final notifier = TestSelectedMonth(DateTime(2026, 5));

      await tester.pumpWidget(_buildSubject(notifier));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MonthChipPicker));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('2026年4月'), findsOneWidget);
    });

    testWidgets('selecting a month invokes setMonth', (tester) async {
      final notifier = TestSelectedMonth(DateTime(2026, 5));

      await tester.pumpWidget(_buildSubject(notifier));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MonthChipPicker));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026年4月'));
      await tester.pumpAndSettle();

      expect(notifier.setMonthCalls, 1);
      expect(notifier.lastSetMonth, DateTime(2026, 4));
    });

    testWidgets('tap target is at least 44px', (tester) async {
      final notifier = TestSelectedMonth(DateTime(2026, 5));

      await tester.pumpWidget(_buildSubject(notifier));
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(InkWell));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });
}
