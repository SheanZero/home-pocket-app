import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/i18n/formatters/number_formatter.dart';
import 'package:home_pocket/shared/utils/transaction_display_amounts.dart';

void main() {
  group('formatTransactionDisplayAmounts', () {
    test('keeps JPY and absent original values annotation-free', () {
      for (final originalCurrencyCode in <String?>[null, 'JPY', 'jpy']) {
        final amounts = formatTransactionDisplayAmounts(
          amountMinorUnits: 7415,
          amountCurrencyCode: 'JPY',
          originalCurrencyCode: originalCurrencyCode,
          originalAmountMinorUnits: originalCurrencyCode == null ? null : 7415,
          locale: const Locale('ja'),
        );

        expect(amounts.primaryAmount, '¥7,415');
        expect(amounts.foreignAnnotation, isNull);
      }
    });

    test('uses the project formatter for each supported locale', () {
      for (final locale in <Locale>[
        const Locale('ja'),
        const Locale('zh'),
        const Locale('en'),
      ]) {
        final amounts = formatTransactionDisplayAmounts(
          amountMinorUnits: 7415,
          amountCurrencyCode: 'JPY',
          originalCurrencyCode: 'USD',
          originalAmountMinorUnits: 5050,
          locale: locale,
        );

        expect(
          amounts.primaryAmount,
          NumberFormatter.formatCurrency(7415, 'JPY', locale),
        );
        expect(
          amounts.foreignAnnotation,
          NumberFormatter.formatCurrency(
            50.5,
            'USD',
            locale,
            trimWholeFraction: true,
          ),
        );
      }
    });

    test('keeps non-zero minor-unit fractions for USD, CNY, EUR, and GBP', () {
      for (final currencyCode in <String>['USD', 'CNY', 'EUR', 'GBP']) {
        final amounts = formatTransactionDisplayAmounts(
          amountMinorUnits: 1,
          amountCurrencyCode: 'JPY',
          originalCurrencyCode: currencyCode,
          originalAmountMinorUnits: 5050,
          locale: const Locale('en'),
        );

        expect(
          amounts.foreignAnnotation,
          NumberFormatter.formatCurrency(
            50.5,
            currencyCode,
            const Locale('en'),
            trimWholeFraction: true,
          ),
        );
        expect(amounts.foreignAnnotation, contains('50.50'));
      }
    });

    test('trims only an all-zero foreign fraction', () {
      final amounts = formatTransactionDisplayAmounts(
        amountMinorUnits: 1,
        amountCurrencyCode: 'JPY',
        originalCurrencyCode: 'USD',
        originalAmountMinorUnits: 5000,
        locale: const Locale('en'),
      );

      expect(amounts.foreignAnnotation, r'$50');
    });
  });
}
