@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/family_insight_data_card.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../helpers/happiness_test_fixtures.dart';

/// Golden tests for [FamilyInsightDataCard] (group-only Stories aggregate card,
/// Plan 47-05).
///
/// Coverage (GUARD-04 / 47-UI-SPEC §Golden Visual-Contract Matrix):
/// - group-mode state (D-08③): `isGroupMode: true` + non-empty shadow books +
///   a rich `familyHappinessProvider`. ja/zh/en × light/dark (6 masters).
///
/// The card self-hides (`SizedBox.shrink`) unless BOTH `isGroupMode` is true and
/// `shadowBooks` is non-empty — so every golden here is the populated group face.
///
/// Wraps the PRODUCTION [AppTheme] so `context.palette` resolves the real
/// ADR-019 palette.

final _startDate = DateTime(2026, 5, 1);
final _endDate = DateTime(2026, 5, 31, 23, 59, 59);

Widget _wrap({required Locale locale, ThemeMode themeMode = ThemeMode.light}) {
  final shadowBooks = fixtureShadowBooksThree().cast<Object>();
  return ProviderScope(
    overrides: [
      familyHappinessProvider(
        startDate: _startDate,
        endDate: _endDate,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => fixtureFamilyHappinessRich()),
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
            height: 260,
            child: SingleChildScrollView(
              child: FamilyInsightDataCard(
                startDate: _startDate,
                endDate: _endDate,
                isGroupMode: true,
                shadowBooksAsync: AsyncValue.data(shadowBooks),
                locale: locale,
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
  group('FamilyInsightDataCard golden', () {
    for (final locale in const [Locale('ja'), Locale('zh'), Locale('en')]) {
      final tag = locale.languageCode;
      testWidgets('group — light $tag', (tester) async {
        await tester.pumpWidget(_wrap(locale: locale));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(FamilyInsightDataCard),
          matchesGoldenFile('goldens/family_insight_data_card_group_light_$tag.png'),
        );
      });

      testWidgets('group — dark $tag', (tester) async {
        await tester.pumpWidget(
          _wrap(locale: locale, themeMode: ThemeMode.dark),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(FamilyInsightDataCard),
          matchesGoldenFile('goldens/family_insight_data_card_group_dark_$tag.png'),
        );
      });
    }
  });
}
