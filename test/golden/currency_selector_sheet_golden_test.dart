@Tags(['golden'])
library;

// Golden tests for [CurrencySelectorSheet] (Phase 42-06, CURR-01/02/03 D-01/D-02).
//
// Covers: 3 locales (ja, zh, en) x 2 themes (light, dark) = 6 cases.
//
// Flag cell is MASKED (showFlags: false) so the host-font-dependent flag emoji
// glyph does not couple to the baseline (RESEARCH Q2). The row layout, symbol,
// ISO code, localized name, "more" affordance, and search field are all still
// verified — only the emoji pixels are isolated.
//
// currentLocaleProvider is overridden to prevent async retry timers.
//
// Run: flutter test test/golden/currency_selector_sheet_golden_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/currency_selector_sheet.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';

Widget _wrap({
  required Locale locale,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [
      // Prevents async retry timers from currentLocaleProvider.
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
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
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 600,
          child: CurrencySelectorSheet(
            selectedCode: 'JPY',
            showFlags: false,
            onSelect: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('CurrencySelectorSheet golden', () {
    testWidgets('locale ja', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('ja')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CurrencySelectorSheet),
        matchesGoldenFile('goldens/currency_selector_sheet_ja.png'),
      );
    });

    testWidgets('locale ja dark', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('ja'), themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CurrencySelectorSheet),
        matchesGoldenFile('goldens/currency_selector_sheet_dark_ja.png'),
      );
    });

    testWidgets('locale zh', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('zh')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CurrencySelectorSheet),
        matchesGoldenFile('goldens/currency_selector_sheet_zh.png'),
      );
    });

    testWidgets('locale zh dark', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('zh'), themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CurrencySelectorSheet),
        matchesGoldenFile('goldens/currency_selector_sheet_dark_zh.png'),
      );
    });

    testWidgets('locale en', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('en')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CurrencySelectorSheet),
        matchesGoldenFile('goldens/currency_selector_sheet_en.png'),
      );
    });

    testWidgets('locale en dark', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('en'), themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CurrencySelectorSheet),
        matchesGoldenFile('goldens/currency_selector_sheet_dark_en.png'),
      );
    });
  });
}
