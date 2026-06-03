import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/hero_header.dart';

import '../../helpers/test_localizations.dart';

void main() {
  Widget buildTestWidget({
    required int year,
    required int month,
    required VoidCallback onSettingsTap,
    VoidCallback? onPrevMonth,
    VoidCallback? onNextMonth,
    bool isGroupMode = false,
    bool showNextChevron = true,
  }) {
    return testLocalizedApp(
      child: Theme(
        data: ThemeData(splashFactory: NoSplash.splashFactory),
        child: Scaffold(
          body: HeroHeader(
            year: year,
            month: month,
            isGroupMode: isGroupMode,
            onSettingsTap: onSettingsTap,
            onPrevMonth: onPrevMonth ?? () {},
            onNextMonth: onNextMonth ?? () {},
            showNextChevron: showNextChevron,
          ),
        ),
      ),
    );
  }

  group('HeroHeader', () {
    testWidgets('displays year and month', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          year: 2026,
          month: 2,
          onSettingsTap: () {},
        ),
      );

      // ja locale: homeMonthFormat = "{year}年{month}月"
      expect(find.text('2026年2月'), findsOneWidget);
    });

    testWidgets('settings icon triggers callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          year: 2026,
          month: 2,
          onSettingsTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.settings_outlined));
      expect(tapped, isTrue);
    });

    testWidgets('month label is not tappable (no dropdown arrow)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          year: 2026,
          month: 2,
          onSettingsTap: () {},
        ),
      );

      // The down-arrow affordance was removed; the month label is static.
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    });

    testWidgets('prev/next chevrons switch months', (tester) async {
      var prev = false;
      var next = false;
      await tester.pumpWidget(
        buildTestWidget(
          year: 2026,
          month: 2,
          onSettingsTap: () {},
          onPrevMonth: () => prev = true,
          onNextMonth: () => next = true,
          showNextChevron: true,
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(prev, isTrue);
      expect(next, isTrue);
    });

    testWidgets('right chevron absent when showNextChevron is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          year: 2026,
          month: 6,
          onSettingsTap: () {},
          showNextChevron: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });
}
