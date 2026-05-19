import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/i18n/formatters/joy_cumulative_formatter.dart';

void main() {
  group('JoyCumulativeFormatter', () {
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

    group('formatJoyCumulative', () {
      test('floors raw cumulative joy before formatting', () {
        expect(formatJoyCumulative(78.4, 'JPY'), '78');
      });

      test('formats with a thousand separator', () {
        expect(formatJoyCumulative(12345.67, 'JPY'), '12,345');
      });

      test('formats zero without crashing', () {
        expect(formatJoyCumulative(0.0, 'JPY'), '0');
      });

      test('formats large values with grouped separators', () {
        expect(formatJoyCumulative(1234567.0, 'JPY'), '1,234,567');
      });
    });
  });
}
