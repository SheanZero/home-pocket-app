import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_display.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  testWidgets('v16 amount layout keeps currency left and amount right', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var currencyTapped = false;
    var cleared = false;
    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: AmountDisplay(
            amount: '3280',
            currencySymbol: '¥',
            currencyLabel: 'JPY',
            layout: AmountDisplayLayout.v16,
            onCurrencyTap: () => currencyTapped = true,
            onClear: () => cleared = true,
          ),
        ),
      ),
    );

    final amount = find.text('3,280');
    final symbol = find.text('¥');
    final currency = find.byKey(const ValueKey('amount_currency_badge'));
    final clear = find.byKey(const ValueKey('amount_clear_button'));
    expect(amount, findsOneWidget);
    expect(symbol, findsOneWidget);
    expect(currency, findsOneWidget);
    expect(clear, findsOneWidget);
    expect(
      tester.getTopLeft(currency).dx,
      lessThan(tester.getTopLeft(amount).dx),
    );
    expect(tester.getTopLeft(amount).dx, lessThan(tester.getTopLeft(clear).dx));
    expect(tester.getSize(find.byType(AmountDisplay)).height, 72);
    expect(tester.widget<Text>(symbol).style?.fontSize, 38);
    final currencyMaterial = tester.widget<Material>(currency);
    expect(currencyMaterial.shape, isA<StadiumBorder>());

    await tester.tap(currency);
    expect(currencyTapped, isTrue);
    await tester.tap(clear);
    expect(cleared, isTrue);
  });
}
