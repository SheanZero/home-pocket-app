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
          onPrevMonth: () {},
          onNextMonth: () {},
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
          onPrevMonth: () {},
          onNextMonth: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    expect(tapped, isTrue);
  });

  testWidgets('HomeHeader month label has no dropdown arrow', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 3,
          isGroupMode: false,
          onSettingsTap: () {},
          onPrevMonth: () {},
          onNextMonth: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
  });

  testWidgets('HomeHeader prev/next chevrons fire callbacks', (tester) async {
    var prev = false;
    var next = false;
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 3,
          isGroupMode: false,
          onSettingsTap: () {},
          onPrevMonth: () => prev = true,
          onNextMonth: () => next = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.tap(find.byIcon(Icons.chevron_right));
    expect(prev, isTrue);
    expect(next, isTrue);
  });

  testWidgets('HomeHeader shows family badge in group mode', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 3,
          isGroupMode: true,
          onSettingsTap: () {},
          onPrevMonth: () {},
          onNextMonth: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.people), findsOneWidget);
    expect(find.text('家族モード'), findsOneWidget);
  });

  testWidgets('HomeHeader shows personal badge in solo mode', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 3,
          isGroupMode: false,
          onSettingsTap: () {},
          onPrevMonth: () {},
          onNextMonth: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('個人モード'), findsOneWidget);
  });

  testWidgets('HomeHeader displays formatted month text', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 3,
          isGroupMode: false,
          onSettingsTap: () {},
          onPrevMonth: () {},
          onNextMonth: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Japanese locale: "2026年3月"
    expect(find.text('2026年3月'), findsOneWidget);
  });
}
