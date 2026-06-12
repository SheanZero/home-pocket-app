// GREEN tests for ExchangeRateApiClient (Phase 41, plan 41-03).
//
// Subject under test: lib/infrastructure/exchange_rate/exchange_rate_api_client.dart
// Fixes the behavioral contract for RATE-01, RATE-05, and SC-5 (URL privacy).
//
// ApiClient surface (RESEARCH.md Pattern 1):
//   class ExchangeRateApiClient {
//     ExchangeRateApiClient({http.Client? httpClient});
//     Future<({String rate, DateTime? actualRateDate, String source})>
//         fetchRate(String currency, DateTime date);
//   }
//   - Frankfurter primary: GET https://api.frankfurter.dev/v1/{YYYY-MM-DD}?from=JPY&to={C}
//   - fawazahmed0 jsDelivr: GET https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@{date}/v1/currencies/jpy.min.json
//   - fawazahmed0 Cloudflare: GET https://{date}.currency-api.pages.dev/v1/currencies/jpy.min.json

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/exchange_rate/exchange_rate_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

/// Mock for the injectable http.Client (PATTERNS.md §Test: http.Response stubbing).
class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://api.frankfurter.dev/v1/'));
  });

  late MockHttpClient httpClient;
  late ExchangeRateApiClient apiClient;

  setUp(() {
    httpClient = MockHttpClient();
    apiClient = ExchangeRateApiClient(httpClient: httpClient);
  });

  // Helper: stub the Frankfurter primary endpoint.
  void stubFrankfurter(String dateStr, String currency, http.Response resp) {
    when(
      () => httpClient.get(
        Uri.parse(
          'https://api.frankfurter.dev/v1/$dateStr?from=JPY&to=$currency',
        ),
      ),
    ).thenAnswer((_) async => resp);
  }

  group('RATE-01: Frankfurter primary source', () {
    test(
      '200 response with business day → returns rate string and null actualRateDate',
      () async {
        stubFrankfurter(
          '2026-06-11',
          'USD',
          http.Response(
            '{"amount":1.0,"base":"JPY","date":"2026-06-11","rates":{"USD":0.00623}}',
            200,
          ),
        );

        final result = await apiClient.fetchRate('USD', DateTime.utc(2026, 6, 11));

        expect(result.rate, (1.0 / 0.00623).toStringAsPrecision(7));
        expect(result.actualRateDate, isNull);
        expect(result.source, 'frankfurter');
      },
    );

    test(
      'RATE-05: 200 with weekend (response date != requested date) → non-null actualRateDate',
      () async {
        // Requested Saturday 2026-06-13, Frankfurter returns Friday 2026-06-12.
        stubFrankfurter(
          '2026-06-13',
          'USD',
          http.Response(
            '{"amount":1.0,"base":"JPY","date":"2026-06-12","rates":{"USD":0.00623}}',
            200,
          ),
        );

        final result = await apiClient.fetchRate('USD', DateTime.utc(2026, 6, 13));

        expect(result.actualRateDate, DateTime.parse('2026-06-12'));
        expect(result.source, 'frankfurter');
      },
    );
  });

  group('RATE-01: fawazahmed0 fallback routing', () {
    test(
      'Frankfurter 404 → falls through to fawazahmed0 jsDelivr and returns rate (TWD)',
      () async {
        // Frankfurter 404 for TWD (not in source).
        stubFrankfurter('2026-06-12', 'TWD', http.Response('Not Found', 404));
        // jsDelivr returns the twd key.
        when(
          () => httpClient.get(
            Uri.parse(
              'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@2026-06-12/v1/currencies/jpy.min.json',
            ),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            '{"date":"2026-06-12","jpy":{"twd":0.0304}}',
            200,
          ),
        );

        final result = await apiClient.fetchRate('TWD', DateTime.utc(2026, 6, 12));

        expect(result.rate, (1.0 / 0.0304).toStringAsPrecision(7));
        expect(result.actualRateDate, isNull);
        expect(result.source, 'fawazahmed0');
      },
    );

    test(
      'jsDelivr error → falls through to Cloudflare fallback and returns rate',
      () async {
        stubFrankfurter('2026-06-12', 'TWD', http.Response('Not Found', 404));
        // jsDelivr times out.
        when(
          () => httpClient.get(
            Uri.parse(
              'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@2026-06-12/v1/currencies/jpy.min.json',
            ),
          ),
        ).thenThrow(TimeoutException('jsDelivr slow'));
        // Cloudflare returns the twd key.
        when(
          () => httpClient.get(
            Uri.parse(
              'https://2026-06-12.currency-api.pages.dev/v1/currencies/jpy.min.json',
            ),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            '{"date":"2026-06-12","jpy":{"twd":0.0304}}',
            200,
          ),
        );

        final result = await apiClient.fetchRate('TWD', DateTime.utc(2026, 6, 12));

        expect(result.rate, (1.0 / 0.0304).toStringAsPrecision(7));
        expect(result.source, 'fawazahmed0');
      },
    );
  });

  group('All-sources-fail behavior', () {
    test(
      'every source fails → throws ExchangeRateApiException',
      () async {
        // All three sources return non-200 → chain exhausts.
        when(() => httpClient.get(any())).thenAnswer(
          (_) async => http.Response('Not Found', 404),
        );

        expect(
          () => apiClient.fetchRate('TWD', DateTime.utc(2026, 6, 12)),
          throwsA(isA<ExchangeRateApiException>()),
        );
      },
    );
  });

  group('SC-5: URL privacy (no user data in constructed URLs)', () {
    test(
      'constructed URLs contain only YYYY-MM-DD date and ISO currency code',
      () async {
        final capturedUrls = <Uri>[];
        when(() => httpClient.get(any())).thenAnswer((invocation) async {
          capturedUrls.add(invocation.positionalArguments.first as Uri);
          // Force the full chain so all three URL shapes are captured:
          // Frankfurter 404 → jsDelivr 404 → Cloudflare 200.
          final url = invocation.positionalArguments.first.toString();
          if (url.contains('pages.dev')) {
            return http.Response(
              '{"date":"2026-06-12","jpy":{"twd":0.0304}}',
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        await apiClient.fetchRate('TWD', DateTime.utc(2026, 6, 12));

        expect(capturedUrls, isNotEmpty);
        final pattern = RegExp(
          r'^https://(api\.frankfurter\.dev|cdn\.jsdelivr\.net|[0-9-]+\.currency-api\.pages\.dev)',
        );
        for (final uri in capturedUrls) {
          final s = uri.toString();
          expect(pattern.hasMatch(s), isTrue, reason: 'URL host not allowed: $s');
          // No user-derived data leaks into the URL.
          for (final forbidden in [
            'userId',
            'bookId',
            'amount',
            'deviceId',
          ]) {
            expect(
              s.contains(forbidden),
              isFalse,
              reason: 'URL contains forbidden token "$forbidden": $s',
            );
          }
        }
      },
    );
  });
}
