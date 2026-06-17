@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/models/happiness_report.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';

import '../helpers/happiness_test_fixtures.dart';

/// Golden tests for [SatisfactionHistogramCard] (悦己满足度分布, round-5 B card #5,
/// Plan 47-05).
///
/// Coverage (GUARD-04 / 47-UI-SPEC §Golden Visual-Contract Matrix):
/// - ja/zh/en × light/dark (6 value-state masters). The value state needs
///   `totalJoyTx >= 5` so the in-card self-hide (D-B5) does NOT collapse it.
/// - + empty/thin-sample state (1 master): a thin happiness report
///   (`totalJoyTx < 5`) → the card self-hides to `SizedBox.shrink()`.
///
/// Wraps the PRODUCTION [AppTheme] so `context.palette` resolves the real
/// ADR-019 palette.

const _bookId = 'book_a';
final _startDate = DateTime(2026, 5, 1);
final _endDate = DateTime(2026, 5, 31, 23, 59, 59);

/// Deterministic satisfaction distribution (score → count).
List<SatisfactionScoreBucket> _fixtureDistribution() => const [
  SatisfactionScoreBucket(score: 5, count: 2),
  SatisfactionScoreBucket(score: 6, count: 4),
  SatisfactionScoreBucket(score: 7, count: 6),
  SatisfactionScoreBucket(score: 8, count: 9),
  SatisfactionScoreBucket(score: 9, count: 5),
  SatisfactionScoreBucket(score: 10, count: 3),
];

Widget _wrap({
  required Locale locale,
  required HappinessReport happiness,
  required List<SatisfactionScoreBucket> distribution,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      happinessReportProvider(
        bookId: _bookId,
        startDate: _startDate,
        endDate: _endDate,
        currencyCode: 'JPY',
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => happiness),
      satisfactionDistributionProvider(
        bookId: _bookId,
        startDate: _startDate,
        endDate: _endDate,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => distribution),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            height: 380,
            child: SingleChildScrollView(
              child: SatisfactionHistogramCard(
                bookId: _bookId,
                startDate: _startDate,
                endDate: _endDate,
                joyMetricVariant: JoyMetricVariant.all,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SatisfactionHistogramCard golden', () {
    for (final locale in const [Locale('ja'), Locale('zh'), Locale('en')]) {
      final tag = locale.languageCode;
      testWidgets('value — light $tag', (tester) async {
        await tester.pumpWidget(
          _wrap(
            locale: locale,
            happiness: fixtureHappinessReportRich(),
            distribution: _fixtureDistribution(),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(SatisfactionHistogramCard),
          matchesGoldenFile('goldens/satisfaction_histogram_card_light_$tag.png'),
        );
      });

      testWidgets('value — dark $tag', (tester) async {
        await tester.pumpWidget(
          _wrap(
            locale: locale,
            happiness: fixtureHappinessReportRich(),
            distribution: _fixtureDistribution(),
            themeMode: ThemeMode.dark,
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(SatisfactionHistogramCard),
          matchesGoldenFile('goldens/satisfaction_histogram_card_dark_$tag.png'),
        );
      });
    }

    // Thin-sample (totalJoyTx < 5) → in-card self-hide to SizedBox.shrink.
    testWidgets('empty self-hide — light ja', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ja'),
          happiness: fixtureHappinessReportThin(),
          distribution: const [],
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SatisfactionHistogramCard),
        matchesGoldenFile(
          'goldens/satisfaction_histogram_card_empty_light_ja.png',
        ),
      );
    });
  });
}
