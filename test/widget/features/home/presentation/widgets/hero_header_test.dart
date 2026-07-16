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
        buildTestWidget(year: 2026, month: 2, onSettingsTap: () {}),
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

    testWidgets('month label has no redundant down-chevron', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(year: 2026, month: 2, onSettingsTap: () {}),
      );

      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
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
        buildTestWidget(year: 2026, month: 2, onSettingsTap: () {}),
      );

      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('uses compact personal label and 40px action hit areas', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(year: 2026, month: 2, onSettingsTap: () {}),
      );

      expect(find.text('個人'), findsOneWidget);
      expect(find.text('個人モード'), findsNothing);
      expect(
        tester.getSize(
          find.ancestor(
            of: find.byIcon(Icons.calendar_month_outlined),
            matching: find.byKey(const Key('home-calendar-hit-area')),
          ),
        ),
        const Size(40, 40),
      );
      expect(
        tester.getSize(
          find.ancestor(
            of: find.byIcon(Icons.settings_outlined),
            matching: find.byKey(const Key('home-settings-hit-area')),
          ),
        ),
        const Size(40, 40),
      );
    });
  });
}
