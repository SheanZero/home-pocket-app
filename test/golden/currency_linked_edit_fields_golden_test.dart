@Tags(['golden'])
library;

// Golden tests for [CurrencyLinkedEditFields] (quick 260613-mgc).
//
// As of quick 260613-mgc the card no longer carries an in-card original-amount
// input row: that editing moved to the screen's top headline keypad. The card
// now renders TWO rows — an editable applied-rate field (160.2564) and a
// READ-ONLY derived JPY row (18,093). The original amount is injected via the
// `originalAmount` prop and only drives the derived JPY.
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
            originalAmount: 11290, // 112.90 USD in minor units (injected)
            appliedRate: '160.2564',
            manualOverride: false,
            rateDate: DateTime(2026, 6, 13),
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('CurrencyLinkedEditFields golden', () {
    testWidgets('rate + derived JPY card — locale en', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('en')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CurrencyLinkedEditFields),
        matchesGoldenFile('goldens/currency_linked_edit_fields_usd.png'),
      );
    });

    testWidgets('rate + derived JPY card — locale en dark', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('en'), themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CurrencyLinkedEditFields),
        matchesGoldenFile('goldens/currency_linked_edit_fields_usd_dark.png'),
      );
    });

    // Pins the two-row card contract regardless of pixels: the original-amount
    // input is gone; the rate field and derived JPY row remain.
    testWidgets('card shows the rate + derived JPY, no original-amount input', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('edit_original_amount_field')),
        findsNothing,
        reason: 'in-card original-amount input was removed (260613-mgc)',
      );
      expect(find.byKey(const Key('edit_rate_field')), findsOneWidget);
      expect(find.text('160.2564'), findsOneWidget);
      expect(find.textContaining('18,093'), findsOneWidget);

      // Quick 260613-n5c: the date-change trigger now shows the formatted
      // rateDate (en `06/13/2026`), pinning the new label contract.
      expect(find.text('06/13/2026'), findsOneWidget);
    });
  });
}
