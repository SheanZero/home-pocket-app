import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/i18n/formatters/number_formatter.dart';

void main() {
  group('NumberFormatter', () {
    const ja = Locale('ja');
    const en = Locale('en');
    const zh = Locale('zh');

    group('formatNumber', () {
      test('formats number with comma separators', () {
        expect(NumberFormatter.formatNumber(1234.56, en), '1,234.56');
      });

      test('formats with custom decimal places', () {
        expect(NumberFormatter.formatNumber(1234.5, en, decimals: 0), '1,235');
      });
    });

    group('formatCurrency', () {
      test('formats JPY with yen symbol and 0 decimals', () {
        final result = NumberFormatter.formatCurrency(1235, 'JPY', ja);
        expect(result, contains('\u00a5'));
        expect(result, contains('1,235'));
        expect(result.contains('.'), isFalse);
      });

      test('formats USD with dollar symbol and 2 decimals', () {
        final result = NumberFormatter.formatCurrency(1234.56, 'USD', en);
        expect(result, contains('\$'));
        expect(result, contains('1,234.56'));
      });

      test('formats CNY with yen symbol and 2 decimals', () {
        final result = NumberFormatter.formatCurrency(1234.56, 'CNY', zh);
        expect(result, contains('\u00a5'));
        expect(result, contains('1,234.56'));
      });

      test('formats EUR with euro symbol', () {
        final result = NumberFormatter.formatCurrency(1234.56, 'EUR', en);
        expect(result, contains('\u20ac'));
      });

      test('formats GBP with pound symbol', () {
        final result = NumberFormatter.formatCurrency(1234.56, 'GBP', en);
        expect(result, contains('\u00a3'));
      });
    });

    group('formatPercentage', () {
      test('formats decimal as percentage', () {
        expect(NumberFormatter.formatPercentage(0.156, en), '15.60%');
      });

      test('formats with custom decimals', () {
        expect(NumberFormatter.formatPercentage(0.156, en, decimals: 0), '16%');
      });

      test('formats zero percent', () {
        expect(NumberFormatter.formatPercentage(0.0, en), '0.00%');
      });

      test('respects locale decimal separator', () {
        const de = Locale('de');
        final result = NumberFormatter.formatPercentage(0.156, de);
        // German uses comma as decimal separator
        expect(result, contains(','));
        expect(result, '15,60%');
      });
    });

    group('formatCompact', () {
      test('formats Japanese numbers with wan for 10000+', () {
        expect(NumberFormatter.formatCompact(12345, ja), contains('\u4e07'));
      });

      test('formats Chinese numbers with wan for 10000+', () {
        expect(NumberFormatter.formatCompact(12345, zh), contains('\u4e07'));
      });

      test('formats English with K for 1000+', () {
        final result = NumberFormatter.formatCompact(12345, en);
        expect(result, contains('K'));
      });

      test('does not use wan below 10000 for Japanese', () {
        expect(
            NumberFormatter.formatCompact(9999, ja), isNot(contains('\u4e07')));
      });
    });
  });
}
