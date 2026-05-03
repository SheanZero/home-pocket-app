// ignore_for_file: unused_import, unused_element

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/generated/app_localizations.dart';

// TODO(plan-10-08): import HomeHeroCard once it exists.
// import 'package:home_pocket/features/home/presentation/widgets/home_hero_card.dart';

import '../helpers/happiness_test_fixtures.dart';

/// Skeleton golden tests for `HomeHeroCard`.
///
/// All tests are skipped pending Plan 10-08. The single-file fixed-size
/// wrap pattern matches `test/golden/soul_fullness_card_golden_test.dart` and
/// `test/golden/summary_cards_golden_test.dart` for consistency.
Widget _wrap({
  required Locale locale,
  required Widget child,
  ThemeMode themeMode = ThemeMode.light,
  double width = 600,
  double height = 720,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: themeMode,
    home: Scaffold(
      body: SizedBox(width: width, height: height, child: child),
    ),
  );
}

void main() {
  group('HomeHeroCard golden', () {
    testWidgets('single mode light ja', (tester) async {
      // TODO(plan-10-08): pumpWidget HomeHeroCard with fixtureHappinessReportRich + fixtureMonthlyReportRich
      // await expectLater(find.byType(HomeHeroCard), matchesGoldenFile('goldens/home_hero_card_single_light_ja.png'));
      expect(true, isTrue);
    }, skip: true /* skip: 'pending Phase 10 implementation' */);

    testWidgets('family mode light ja', (tester) async {
      expect(true, isTrue);
    }, skip: true /* skip: 'pending Phase 10 implementation' */);

    testWidgets('family mode dark ja', (tester) async {
      expect(true, isTrue);
    }, skip: true /* skip: 'pending Phase 10 implementation' */);

    testWidgets('thin sample (n<5) light ja', (tester) async {
      expect(true, isTrue);
    }, skip: true /* skip: 'pending Phase 10 implementation' */);

    testWidgets('all-neutral CTA light ja', (tester) async {
      expect(true, isTrue);
    }, skip: true /* skip: 'pending Phase 10 implementation' */);
  });
}
