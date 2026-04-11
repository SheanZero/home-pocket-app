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
          onDateTap: () {},
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
          onDateTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    expect(tapped, isTrue);
  });

  testWidgets('HomeHeader shows chevron down for date picker', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 3,
          isGroupMode: false,
          onSettingsTap: () {},
          onDateTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
  });

  testWidgets('HomeHeader date tap fires callback', (tester) async {
    var dateTapped = false;
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 3,
          isGroupMode: false,
          onSettingsTap: () {},
          onDateTap: () => dateTapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Tap on the month text area (which includes the chevron)
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    expect(dateTapped, isTrue);
  });

  testWidgets('HomeHeader shows family badge in group mode', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        HeroHeader(
          year: 2026,
          month: 3,
          isGroupMode: true,
          onSettingsTap: () {},
          onDateTap: () {},
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
          onDateTap: () {},
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
          onDateTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Japanese locale: "2026年3月"
    expect(find.text('2026年3月'), findsOneWidget);
  });
}
