import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:home_pocket/features/analytics/domain/models/family_happiness.dart';
import 'package:home_pocket/features/analytics/domain/models/happiness_report.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_hero_card.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../helpers/happiness_test_fixtures.dart';

/// Golden tests for `HomeHeroCard` (Plan 10-10).
///
/// Single-file fixed-size wrap pattern matches
/// `test/golden/summary_cards_golden_test.dart`. The hero card consumes data
/// via constructor (pure StatelessWidget per UI-SPEC line 277) so no
/// ProviderScope is required.
class _FixtureSnapshot {
  const _FixtureSnapshot({
    required this.monthlyReport,
    required this.happiness,
    required this.bestJoy,
    this.family,
    this.shadowBooks,
    this.shadowAggregate,
  });

  final MonthlyReport monthlyReport;
  final HappinessReport happiness;
  final MetricResult<BestJoyMomentRow> bestJoy;
  final FamilyHappiness? family;
  final List<ShadowBookInfo>? shadowBooks;
  final ShadowAggregate? shadowAggregate;
}

_FixtureSnapshot _singleRich() => _FixtureSnapshot(
      monthlyReport: fixtureMonthlyReportRich(),
      happiness: fixtureHappinessReportRich(),
      bestJoy: fixtureBestJoyResultRich(),
    );

_FixtureSnapshot _singleThin() => _FixtureSnapshot(
      monthlyReport: fixtureMonthlyReportRich(),
      happiness: fixtureHappinessReportThin(),
      bestJoy: fixtureBestJoyResultThin(),
    );

_FixtureSnapshot _singleAllNeutral() => _FixtureSnapshot(
      monthlyReport: fixtureMonthlyReportRich(),
      happiness: fixtureHappinessReportRich(),
      bestJoy: fixtureBestJoyResultAllNeutral(),
    );

_FixtureSnapshot _groupRich() => _FixtureSnapshot(
      monthlyReport: fixtureMonthlyReportRich(),
      happiness: fixtureHappinessReportRich(),
      bestJoy: fixtureBestJoyResultRich(),
      family: fixtureFamilyHappinessRich(),
      shadowBooks: fixtureShadowBooksThree(),
      shadowAggregate: fixtureShadowAggregateThree(),
    );

Widget _wrap({
  required Locale locale,
  required _FixtureSnapshot snapshot,
  ThemeMode themeMode = ThemeMode.light,
  bool isGroupMode = false,
  String currencyCode = 'JPY',
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
      body: SizedBox(
        width: width,
        height: height,
        child: SingleChildScrollView(
          child: HomeHeroCard(
            report: snapshot.monthlyReport,
            happiness: snapshot.happiness,
            bestJoy: snapshot.bestJoy,
            family: snapshot.family,
            shadowBooks: snapshot.shadowBooks,
            shadowAggregate: snapshot.shadowAggregate,
            currencyCode: currencyCode,
            locale: locale,
            isGroupMode: isGroupMode,
            onTap: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('HomeHeroCard golden', () {
    testWidgets('single mode light ja', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('ja'), snapshot: _singleRich()),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(HomeHeroCard),
        matchesGoldenFile('goldens/home_hero_card_single_light_ja.png'),
      );
    });

    testWidgets('family mode light ja', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ja'),
          snapshot: _groupRich(),
          isGroupMode: true,
          height: 920,
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(HomeHeroCard),
        matchesGoldenFile('goldens/home_hero_card_family_light_ja.png'),
      );
    });

    testWidgets('family mode dark ja', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ja'),
          snapshot: _groupRich(),
          isGroupMode: true,
          themeMode: ThemeMode.dark,
          height: 920,
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(HomeHeroCard),
        matchesGoldenFile('goldens/home_hero_card_family_dark_ja.png'),
      );
    });

    testWidgets('thin sample (n<5) light ja', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('ja'), snapshot: _singleThin()),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(HomeHeroCard),
        matchesGoldenFile('goldens/home_hero_card_thin_sample_ja.png'),
      );
    });

    testWidgets('all-neutral CTA light ja', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('ja'), snapshot: _singleAllNeutral()),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(HomeHeroCard),
        matchesGoldenFile('goldens/home_hero_card_all_neutral_cta_ja.png'),
      );
    });
  });
}
