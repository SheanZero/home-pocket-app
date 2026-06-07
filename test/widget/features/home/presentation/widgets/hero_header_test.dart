import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/hero_header.dart';

import '../../helpers/test_localizations.dart';

void main() {
  Widget buildTestWidget({
    required int year,
    required int month,
    required VoidCallback onSettingsTap,
    VoidCallback? onMonthTap,
    bool isGroupMode = false,
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
            onMonthTap: onMonthTap ?? () {},
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

    testWidgets('month label shows the down-chevron affordance', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          year: 2026,
          month: 2,
          onSettingsTap: () {},
        ),
      );

      // The down-arrow affordance signals the label is tappable.
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('tapping the month label fires onMonthTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          year: 2026,
          month: 2,
          onSettingsTap: () {},
          onMonthTap: () => tapped = true,
        ),
      );

      await tester.tap(find.text('2026年2月'));
      expect(tapped, isTrue);
    });

    testWidgets('no prev/next month chevrons are rendered', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          year: 2026,
          month: 2,
          onSettingsTap: () {},
        ),
      );

      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });
}
