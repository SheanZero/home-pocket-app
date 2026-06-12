// Wave 0 RED scaffold — ExchangeRateApiClient (Phase 41).
//
// Subject under test: lib/infrastructure/exchange_rate/exchange_rate_api_client.dart
// (NOT YET CREATED — built in plan 41-04). This file fixes the behavioral
// contract for RATE-01, RATE-05, and SC-5 (URL privacy) BEFORE production code
// lands, per TDD discipline.
//
// Why the production import is commented out: Dart resolves imports at compile
// time and cannot skip a `part`/`import` of a non-existent file. To keep this
// scaffold compiling (so the test IDs register in discovery and `flutter test`
// reports them as skipped rather than as a hard compilation failure), the import
// of `exchange_rate_api_client.dart` stays commented until plan 41-04 creates it.
// At that point: uncomment the import + the mock, and unfold each documented
// `test(..., skip: ...)` into a live assertion.
//
// Expected ApiClient surface (RESEARCH.md Pattern 1):
//   class ExchangeRateApiClient {
//     ExchangeRateApiClient({http.Client? httpClient});
//     Future<({String rate, DateTime? actualRateDate, String source})>
//         fetchRate(String currency, DateTime date);
//   }
//   - Frankfurter primary: GET https://api.frankfurter.dev/v1/{YYYY-MM-DD}?from=JPY&to={C}
//   - fawazahmed0 jsDelivr: GET https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@{date}/v1/currencies/jpy.min.json
//   - fawazahmed0 Cloudflare: GET https://{date}.currency-api.pages.dev/v1/currencies/jpy.min.json

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

// import 'package:home_pocket/infrastructure/exchange_rate/exchange_rate_api_client.dart';

/// Mock for the injectable http.Client (PATTERNS.md §Test: http.Response stubbing).
class MockHttpClient extends Mock implements http.Client {}

const _redScaffold = 'Wave 0 RED — ExchangeRateApiClient not yet created (plan 41-04)';

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://api.frankfurter.dev/v1/'));
  });

  group('RATE-01: Frankfurter primary source', () {
    test(
      '200 response with business day → returns rate string and null actualRateDate',
      () {
        // GIVEN Frankfurter returns 200 for the requested business day:
        //   body '{"amount":1.0,"base":"JPY","date":"2026-06-11","rates":{"USD":0.00623}}'
        // WHEN apiClient.fetchRate('USD', DateTime.utc(2026, 6, 11))
        // THEN result.rate is the inverted JPY-per-unit string (1/0.00623 ≈ 160.5)
        //      result.actualRateDate is null (response date == requested date)
        //      result.source == 'frankfurter'
      },
      skip: _redScaffold,
    );

    test(
      'RATE-05: 200 with weekend (response date != requested date) → non-null actualRateDate',
      () {
        // GIVEN requested date is a Saturday (2026-06-13) but Frankfurter returns
        //   body '{"amount":1.0,"base":"JPY","date":"2026-06-12","rates":{"USD":0.00623}}'
        // WHEN apiClient.fetchRate('USD', DateTime.utc(2026, 6, 13))
        // THEN result.actualRateDate == DateTime.utc(2026, 6, 12) (RATE-05 weekend surfacing)
      },
      skip: _redScaffold,
    );
  });

  group('RATE-01: fawazahmed0 fallback routing', () {
    test(
      'Frankfurter 404 → falls through to fawazahmed0 jsDelivr and returns rate (TWD)',
      () {
        // GIVEN Frankfurter returns 404 for TWD (currency not in source)
        //   AND jsDelivr returns 200 body '{"date":"2026-06-12","jpy":{"twd":0.0304}}'
        // WHEN apiClient.fetchRate('TWD', DateTime.utc(2026, 6, 12))
        // THEN result.rate is the inverted JPY-per-TWD string, source == 'fawazahmed0'
        //      (404 routes onward; it is NOT a fallback-to-cache trigger)
      },
      skip: _redScaffold,
    );

    test(
      'jsDelivr error → falls through to Cloudflare fallback and returns rate',
      () {
        // GIVEN Frankfurter 404, jsDelivr throws/times out,
        //   AND Cloudflare ({date}.currency-api.pages.dev) returns 200 with twd key
        // WHEN apiClient.fetchRate('TWD', DateTime.utc(2026, 6, 12))
        // THEN result.rate is returned from the Cloudflare source
      },
      skip: _redScaffold,
    );
  });

  group('SC-5: URL privacy (no user data in constructed URLs)', () {
    test(
      'constructed URLs contain only YYYY-MM-DD date and ISO currency code',
      () {
        // WHEN fetchRate is invoked, capture the Uri passed to httpClient.get
        // THEN the URL contains only the YYYY-MM-DD date and the ISO 4217
        //      currency code — no amount, no userId, no bookId, no device data.
        //      Frankfurter: /v1/{date}?from=JPY&to={C}
        //      fawazahmed0: @{date}/v1/currencies/jpy.min.json
      },
      skip: _redScaffold,
    );
  });
}
