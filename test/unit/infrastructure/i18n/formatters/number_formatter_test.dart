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

      test('formats CNY with CN\u00a5 symbol and 2 decimals', () {
        final result = NumberFormatter.formatCurrency(1234.56, 'CNY', zh);
        expect(result, contains('CN\u00a5'));
        expect(result, contains('1,234.56'));
      });

      test('KRW returns \u20a9 with 0 decimals', () {
        final result = NumberFormatter.formatCurrency(1000, 'KRW', ja);
        expect(result, contains('\u20a9'));
        expect(result.contains('.00'), isFalse);
      });

      test('HKD returns HK\$', () {
        final result = NumberFormatter.formatCurrency(100.50, 'HKD', en);
        expect(result, contains('HK\$'));
      });

      test('AUD returns A\$', () {
        final result = NumberFormatter.formatCurrency(100.50, 'AUD', en);
        expect(result, contains('A\$'));
      });

      test('CAD returns C\$', () {
        final result = NumberFormatter.formatCurrency(100.50, 'CAD', en);
        expect(result, contains('C\$'));
      });

      test('TWD returns NT\$', () {
        final result = NumberFormatter.formatCurrency(100.50, 'TWD', en);
        expect(result, contains('NT\$'));
      });

      test('SGD returns S\$', () {
        final result = NumberFormatter.formatCurrency(100.50, 'SGD', en);
        expect(result, contains('S\$'));
      });

      test('unknown currency code falls back to ISO prefix', () {
        final result = NumberFormatter.formatCurrency(1000, 'XYZ', en);
        expect(result, contains('XYZ'));
      });

      group('long-tail currency real symbols (260613-ote)', () {
        test('THB returns ฿', () {
          final result = NumberFormatter.formatCurrency(100, 'THB', en);
          expect(result, contains('฿'));
          expect(result, isNot(contains('THB')));
        });

        test('INR returns ₹', () {
          final result = NumberFormatter.formatCurrency(100, 'INR', en);
          expect(result, contains('₹'));
          expect(result, isNot(contains('INR')));
        });

        test('IDR returns Rp', () {
          final result = NumberFormatter.formatCurrency(100, 'IDR', en);
          expect(result, contains('Rp'));
          expect(result, isNot(contains('IDR')));
        });

        test('MYR returns RM', () {
          final result = NumberFormatter.formatCurrency(100, 'MYR', en);
          expect(result, contains('RM'));
          expect(result, isNot(contains('MYR')));
        });

        test('PHP returns ₱', () {
          final result = NumberFormatter.formatCurrency(100, 'PHP', en);
          expect(result, contains('₱'));
          expect(result, isNot(contains('PHP')));
        });

        test('VND returns ₫', () {
          final result = NumberFormatter.formatCurrency(100, 'VND', en);
          expect(result, contains('₫'));
          expect(result, isNot(contains('VND')));
        });

        test('NZD returns NZ\$', () {
          final result = NumberFormatter.formatCurrency(100, 'NZD', en);
          expect(result, contains('NZ\$'));
          expect(result, isNot(contains('NZD')));
        });

        test('BRL returns R\$', () {
          final result = NumberFormatter.formatCurrency(100, 'BRL', en);
          expect(result, contains('R\$'));
          expect(result, isNot(contains('BRL')));
        });

        test('RUB returns ₽', () {
          final result = NumberFormatter.formatCurrency(100, 'RUB', en);
          expect(result, contains('₽'));
          expect(result, isNot(contains('RUB')));
        });

        test('ZAR returns R', () {
          final result = NumberFormatter.formatCurrency(100, 'ZAR', en);
          expect(result, contains('R'));
          expect(result, isNot(contains('ZAR')));
        });

        test('SEK returns kr', () {
          final result = NumberFormatter.formatCurrency(100, 'SEK', en);
          expect(result, contains('kr'));
          expect(result, isNot(contains('SEK')));
        });

        test('NOK returns kr', () {
          final result = NumberFormatter.formatCurrency(100, 'NOK', en);
          expect(result, contains('kr'));
          expect(result, isNot(contains('NOK')));
        });

        test('DKK returns kr', () {
          final result = NumberFormatter.formatCurrency(100, 'DKK', en);
          expect(result, contains('kr'));
          expect(result, isNot(contains('DKK')));
        });

        test('MXN returns MX\$', () {
          final result = NumberFormatter.formatCurrency(100, 'MXN', en);
          expect(result, contains('MX\$'));
          expect(result, isNot(contains('MXN')));
        });

        test('TRY returns ₺', () {
          final result = NumberFormatter.formatCurrency(100, 'TRY', en);
          expect(result, contains('₺'));
          expect(result, isNot(contains('TRY')));
        });

        test('PLN returns zł', () {
          final result = NumberFormatter.formatCurrency(100, 'PLN', en);
          expect(result, contains('zł'));
          expect(result, isNot(contains('PLN')));
        });
      });

      group('currencies without common glyph keep ISO code (260613-ote)', () {
        test('CHF falls back to ISO code', () {
          final result = NumberFormatter.formatCurrency(100, 'CHF', en);
          expect(result, contains('CHF'));
        });

        test('AED falls back to ISO code', () {
          final result = NumberFormatter.formatCurrency(100, 'AED', en);
          expect(result, contains('AED'));
        });

        test('SAR falls back to ISO code', () {
          final result = NumberFormatter.formatCurrency(100, 'SAR', en);
          expect(result, contains('SAR'));
        });
      });

      test('JPY still returns \u00a5 (regression guard)', () {
        final result = NumberFormatter.formatCurrency(1000, 'JPY', ja);
        expect(result, contains('\u00a5'));
        expect(result, isNot(contains('CN\u00a5')));
      });

      test('formats EUR with euro symbol', () {
        final result = NumberFormatter.formatCurrency(1234.56, 'EUR', en);
        expect(result, contains('\u20ac'));
      });

      test('formats GBP with pound symbol', () {
        final result = NumberFormatter.formatCurrency(1234.56, 'GBP', en);
        expect(result, contains('\u00a3'));
      });

      group('trimWholeFraction (260614-dx1)', () {
        test('whole USD drops ".00" but keeps symbol + grouping', () {
          final result = NumberFormatter.formatCurrency(
            12211,
            'USD',
            en,
            trimWholeFraction: true,
          );
          expect(result, '\$12,211');
          expect(result.contains('.'), isFalse);
        });

        test('fractional USD keeps its decimals when trimming enabled', () {
          final result = NumberFormatter.formatCurrency(
            12.50,
            'USD',
            en,
            trimWholeFraction: true,
          );
          expect(result, '\$12.50');
        });

        test('non-zero hundredths kept when trimming enabled', () {
          final result = NumberFormatter.formatCurrency(
            12.05,
            'USD',
            en,
            trimWholeFraction: true,
          );
          expect(result, '\$12.05');
        });

        test('whole SEK (kr) drops ".00" when trimming enabled', () {
          final result = NumberFormatter.formatCurrency(
            12,
            'SEK',
            en,
            trimWholeFraction: true,
          );
          expect(result, contains('kr'));
          expect(result.contains('.'), isFalse);
        });

        test('JPY whole amount unaffected by trimming (already 0 decimals)', () {
          final result = NumberFormatter.formatCurrency(
            1000,
            'JPY',
            ja,
            trimWholeFraction: true,
          );
          expect(result, contains('\u00a5'));
          expect(result.contains('.'), isFalse);
        });

        test('default (flag off) still renders ".00" for whole USD', () {
          final result = NumberFormatter.formatCurrency(12211, 'USD', en);
          expect(result, '\$12,211.00');
        });
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
          NumberFormatter.formatCompact(9999, ja),
          isNot(contains('\u4e07')),
        );
      });
    });
  });
}
