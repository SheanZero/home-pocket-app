import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/i18n/formatters/joy_density_formatter.dart';

void main() {
  group('JoyDensityFormatter', () {
    group('ptvfBaseFor', () {
      test('returns JPY PTVF base', () {
        expect(ptvfBaseFor('JPY'), 500.0);
      });

      test('returns CNY PTVF base', () {
        expect(ptvfBaseFor('CNY'), 25.0);
      });

      test('returns USD PTVF base', () {
        expect(ptvfBaseFor('USD'), 5.0);
      });

      test('falls back to JPY base for EUR', () {
        expect(ptvfBaseFor('EUR'), 500.0);
      });

      test('falls back to JPY base for GBP', () {
        expect(ptvfBaseFor('GBP'), 500.0);
      });

      test('matches currency codes case-sensitively', () {
        // Currency codes are matched case-sensitively. If Book.currency is ever
        // normalized to lowercase upstream, the fallback path engages - track
        // via this test.
        expect(ptvfBaseFor('jpy'), 500.0);
      });
    });

    group('formatJoyDensity', () {
      test('formats JPY raw density using per-yen-thousand display unit', () {
        final result = formatJoyDensity(0.005, 'JPY');

        expect(result, contains('5.0'));
        expect(result, contains('/ \u00a51k'));
        expect(result, '5.0 / \u00a51k');
      });

      test('formats CNY raw density using per-yen-hundred display unit', () {
        final result = formatJoyDensity(0.5, 'CNY');

        expect(result, contains('50.0'));
        expect(result, contains('/ \u00a5100'));
        expect(result, '50.0 / \u00a5100');
      });

      test('formats USD raw density using per-dollar display unit', () {
        final result = formatJoyDensity(0.1, 'USD');

        expect(result, contains('0.1'));
        expect(result, contains(r'/ $1'));
        expect(result, r'0.1 / $1');
      });

      test('formats zero density without crashing', () {
        expect(formatJoyDensity(0.0, 'JPY'), '0.0 / \u00a51k');
      });
    });
  });
}
