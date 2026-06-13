@Tags(['golden'])
library;

// Golden tests for [CurrencyLinkedEditFields] (Phase 42 UAT fix).
//
// Pins the 原币金额 (original amount) row's currency-symbol prefix — the edited
// value reads as "$112.90" so the foreign edit row presents the ORIGINAL
// currency, consistent with the entry screen. The applied-rate row and the
// read-only derived JPY row are also captured.
//
// USD 112.90 @ 160.2564 → 18,093 JPY (the UAT example).
//
// Run: flutter test test/golden/currency_linked_edit_fields_golden_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/currency_linked_edit_fields.dart';
import 'package:home_pocket/generated/app_localizations.dart';

Widget _wrap({required Locale locale, ThemeMode themeMode = ThemeMode.light}) {
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
      body: Center(
        child: SizedBox(
          width: 360,
          child: CurrencyLinkedEditFields(
            originalCurrency: 'USD',
            originalAmount: 11290, // 112.90 USD in minor units
            appliedRate: '160.2564',
            manualOverride: false,
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('CurrencyLinkedEditFields golden', () {
    testWidgets('USD original-amount row shows \$ prefix — locale en', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(locale: const Locale('en')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CurrencyLinkedEditFields),
        matchesGoldenFile('goldens/currency_linked_edit_fields_usd.png'),
      );
    });

    testWidgets('USD original-amount row shows \$ prefix — locale en dark', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('en'), themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CurrencyLinkedEditFields),
        matchesGoldenFile('goldens/currency_linked_edit_fields_usd_dark.png'),
      );
    });

    // Pins the symbol-prefix text regardless of pixels.
    testWidgets('original-amount field carries the currency symbol prefix', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(locale: const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.text(r'$'), findsOneWidget);
      expect(find.text('112.90'), findsOneWidget);
    });
  });
}
