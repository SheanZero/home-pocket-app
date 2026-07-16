import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_display.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  testWidgets('v16 amount layout keeps amount left and currency action right', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var currencyTapped = false;
    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: AmountDisplay(
            amount: '3280',
            currencySymbol: '¥',
            currencyLabel: 'JPY',
            layout: AmountDisplayLayout.v16,
            onCurrencyTap: () => currencyTapped = true,
          ),
        ),
      ),
    );

    final amount = find.text('3,280');
    final symbol = find.text('¥');
    final currency = find.byKey(const ValueKey('amount_currency_badge'));
    expect(amount, findsOneWidget);
    expect(symbol, findsOneWidget);
    expect(currency, findsOneWidget);
    expect(
      tester.getTopLeft(amount).dx,
      lessThan(tester.getTopLeft(currency).dx),
    );
    expect(tester.getSize(find.byType(AmountDisplay)).height, 88);
    expect(tester.widget<Text>(symbol).style?.fontSize, 44);
    final currencyMaterial = tester.widget<Material>(currency);
    expect(currencyMaterial.shape, isA<StadiumBorder>());

    await tester.tap(currency);
    expect(currencyTapped, isTrue);
  });
}
