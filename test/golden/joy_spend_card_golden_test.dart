@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/analytics/domain/models/joy_category_amount.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/joy_spend_card.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';

/// Golden tests for [JoySpendCard] (悦己花在哪, round-5 B card #3, Plan 47-05).
///
/// Coverage (GUARD-04 / 47-UI-SPEC §Golden Visual-Contract Matrix):
/// - ja/zh/en × light/dark (6 value-state masters)
/// - + empty state (1 master)
///
/// Wraps the PRODUCTION [AppTheme] so `context.palette` resolves the real
/// ADR-019 sakura joy palette. The 悦己 header total count-up
/// (`TweenAnimationBuilder<int>`, ~480ms — D-D2 anchor #2) is settled via
/// `pumpAndSettle()` before capture (D-09), so the header lands on the true
/// total.

const _bookId = 'book_a';
final _startDate = DateTime(2026, 5, 1);
final _endDate = DateTime(2026, 5, 31, 23, 59, 59);

/// Deterministic joy-spend amounts (43-01 sample-data shape, largest→smallest).
List<JoyCategoryAmount> _fixtureRich() => const [
  JoyCategoryAmount(categoryId: 'cat_hobbies', amount: 12000),
  JoyCategoryAmount(categoryId: 'cat_education', amount: 8000),
  JoyCategoryAmount(categoryId: 'cat_social', amount: 5200),
];

Widget _wrap({
  required Locale locale,
  required List<JoyCategoryAmount> amounts,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      joyCategoryAmountsProvider(
        bookId: _bookId,
        startDate: _startDate,
        endDate: _endDate,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => amounts),
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
            height: 320,
            child: SingleChildScrollView(
              child: JoySpendCard(
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
  group('JoySpendCard golden', () {
    for (final locale in const [Locale('ja'), Locale('zh'), Locale('en')]) {
      final tag = locale.languageCode;
      testWidgets('value — light $tag', (tester) async {
        await tester.pumpWidget(
          _wrap(locale: locale, amounts: _fixtureRich()),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(JoySpendCard),
          matchesGoldenFile('goldens/joy_spend_card_light_$tag.png'),
        );
      });

      testWidgets('value — dark $tag', (tester) async {
        await tester.pumpWidget(
          _wrap(
            locale: locale,
            amounts: _fixtureRich(),
            themeMode: ThemeMode.dark,
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(JoySpendCard),
          matchesGoldenFile('goldens/joy_spend_card_dark_$tag.png'),
        );
      });
    }

    testWidgets('empty — light ja', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('ja'), amounts: const []),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(JoySpendCard),
        matchesGoldenFile('goldens/joy_spend_card_empty_light_ja.png'),
      );
    });
  });
}
