import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/hero_header.dart';

import '../../helpers/test_localizations.dart';

void main() {
  group('HeroHeader', () {
    testWidgets('displays year and month', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            body: HeroHeader(
              year: 2026,
              month: 2,
              onSettingsTap: () {},
              onDateTap: () {},
            ),
          ),
        ),
      );

      // ja locale: homeMonthFormat = "{year}年{month}月"
      expect(find.text('2026年2月'), findsOneWidget);
    });

    testWidgets('settings icon triggers callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            body: HeroHeader(
              year: 2026,
              month: 2,
              onSettingsTap: () => tapped = true,
              onDateTap: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.settings_outlined));
      expect(tapped, isTrue);
    });

    testWidgets('date tap triggers callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            body: HeroHeader(
              year: 2026,
              month: 2,
              onSettingsTap: () {},
              onDateTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('2026年2月'));
      expect(tapped, isTrue);
    });

    testWidgets('shows dropdown arrow icon', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            body: HeroHeader(
              year: 2026,
              month: 2,
              onSettingsTap: () {},
              onDateTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });
  });
}
