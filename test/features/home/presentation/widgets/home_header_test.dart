import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/hero_header.dart';
import 'package:home_pocket/generated/app_localizations.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(body: child),
    );
  }

  testWidgets('HomeHeader renders without blue background', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 3,
          isGroupMode: false,
          onSettingsTap: () {},
          onMonthTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HeroHeader), findsOneWidget);
  });

  testWidgets('HomeHeader shows settings icon that is tappable', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 3,
          isGroupMode: false,
          onSettingsTap: () => tapped = true,
          onMonthTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    expect(tapped, isTrue);
  });

  testWidgets('HomeHeader month label omits redundant down-chevron', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 3,
          isGroupMode: false,
          onSettingsTap: () {},
          onMonthTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
  });

  testWidgets('HomeHeader tapping the month label fires onMonthTap', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 3,
          isGroupMode: false,
          onSettingsTap: () {},
          onMonthTap: () => tapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026年3月'));
    expect(tapped, isTrue);
  });

  testWidgets('HomeHeader renders no prev/next chevrons', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 6,
          isGroupMode: false,
          onSettingsTap: () {},
          onMonthTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('HomeHeader shows family badge in group mode', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 3,
          isGroupMode: true,
          onSettingsTap: () {},
          onMonthTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.people), findsOneWidget);
    expect(find.text('家族'), findsOneWidget);
  });

  testWidgets('HomeHeader shows personal badge in solo mode', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 3,
          isGroupMode: false,
          onSettingsTap: () {},
          onMonthTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('個人'), findsOneWidget);
  });

  testWidgets('HomeHeader displays formatted month text', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 3,
          isGroupMode: false,
          onSettingsTap: () {},
          onMonthTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Japanese locale: "2026年3月"
    expect(find.text('2026年3月'), findsOneWidget);
  });
}
