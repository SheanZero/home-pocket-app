import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_display.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Wraps a widget for golden tests with a fixed-size SizedBox so that
/// PNG goldens are stable across screen sizes.
Widget _wrap({required Locale locale, required Widget child}) {
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
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 360, height: 80, child: child),
      ),
    ),
  );
}

void main() {
  group('AmountDisplay golden tests', () {
    testWidgets('JPY ¥1,235 — locale ja', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ja'),
          child: const AmountDisplay(
            amount: '1235',
            currencySymbol: '¥',
            currencyLabel: 'JPY',
          ),
        ),
      );
      await expectLater(
        find.byType(AmountDisplay),
        matchesGoldenFile('goldens/amount_display_jpy.png'),
      );
    });

    testWidgets(r'USD $1,235.00 — locale en', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          child: const AmountDisplay(
            amount: '123500',
            currencySymbol: r'$',
            currencyLabel: 'USD',
          ),
        ),
      );
      await expectLater(
        find.byType(AmountDisplay),
        matchesGoldenFile('goldens/amount_display_usd.png'),
      );
    });

    testWidgets('CNY ¥1,235.00 — locale zh', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('zh'),
          child: const AmountDisplay(
            amount: '123500',
            currencySymbol: '¥',
            currencyLabel: 'CNY',
          ),
        ),
      );
      await expectLater(
        find.byType(AmountDisplay),
        matchesGoldenFile('goldens/amount_display_cny.png'),
      );
    });
  });
}
