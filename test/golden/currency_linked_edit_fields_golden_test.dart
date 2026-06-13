@Tags(['golden'])
library;

// Golden tests for [CurrencyLinkedEditFields] (quick 260613-mgc, generalized
// into the shared two-screen card quick 260613-ufn).
//
// As of quick 260613-mgc the card no longer carries an in-card original-amount
// input row: that editing moved to the screen's top headline keypad. As of
// quick 260613-ufn the trailing clickable date-change TextButton is REMOVED and
// replaced by a NON-CLICKABLE labeled 汇率日期 row (key `edit_rate_date`, D-3)
// showing the actual effective rate date; an optional warning-amber staleness
// line (key `edit_rate_staleness`, D-2) renders below it. The card now renders
// THREE rows — editable 汇率 (160.2564), read-only derived 日元 (18,093), and the
// non-clickable 汇率日期 row — plus the staleness line in the staleness golden.
//
// USD 112.90 @ 160.2564 → 18,093 JPY (the UAT example).
//
// Run: flutter test test/golden/currency_linked_edit_fields_golden_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/currency_linked_edit_fields.dart';
import 'package:home_pocket/generated/app_localizations.dart';

Widget _wrap({
  required Locale locale,
  ThemeMode themeMode = ThemeMode.light,
  DateTime? actualRateDate,
  String? stalenessNote,
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
      body: Center(
        child: SizedBox(
          width: 360,
          child: CurrencyLinkedEditFields(
            originalCurrency: 'USD',
            originalAmount: 11290, // 112.90 USD in minor units (injected)
            appliedRate: '160.2564',
            manualOverride: false,
            rateDate: DateTime(2026, 6, 13),
            actualRateDate: actualRateDate,
            stalenessNote: stalenessNote,
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

    testWidgets('card with weekend staleness note — locale en', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          actualRateDate: DateTime(2026, 6, 12),
          stalenessNote: '06/12/2026 (most recent business day)',
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CurrencyLinkedEditFields),
        matchesGoldenFile(
          'goldens/currency_linked_edit_fields_usd_staleness.png',
        ),
      );
    });

    // Pins the card contract regardless of pixels: the original-amount input is
    // gone; the editable rate field, the read-only derived JPY row, and the
    // NON-CLICKABLE 汇率日期 row remain. The clickable trigger is removed (ufn D-3).
    testWidgets('card shows rate + derived JPY + non-clickable 汇率日期 row', (
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

      // Quick 260613-ufn (D-3): the clickable date-change trigger is removed;
      // a non-clickable labeled 汇率日期 row shows the formatted date.
      expect(
        find.byKey(const Key('edit_date_change_trigger')),
        findsNothing,
      );
      expect(find.byKey(const Key('edit_rate_date')), findsOneWidget);
      expect(find.text('06/13/2026'), findsOneWidget);
    });
  });
}
