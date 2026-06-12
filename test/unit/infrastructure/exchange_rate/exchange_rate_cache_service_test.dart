// Wave 0 RED scaffold — ExchangeRateCacheService (Phase 41).
//
// Subject under test: lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart
// (NOT YET CREATED — built in plan 41-04). Fixes the behavioral contract for
// RATE-02, RATE-03 (D-06 cooldown), and D-09 TTL pruning BEFORE production code
// lands.
//
// The ExchangeRateRepository import IS valid (plan 41-01 extended it with
// findLatestNonManual / deleteOlderThan / findAll), so the repository mock is
// live. The ExchangeRateApiClient + ExchangeRateCacheService imports stay
// commented until plan 41-04 creates them.
//
// Expected CacheService surface (RESEARCH.md Pattern 3):
//   class ExchangeRateCacheService {
//     ExchangeRateCacheService({
//       required ExchangeRateRepository repository,
//       required ExchangeRateApiClient apiClient,
//       Connectivity? connectivity,
//     });
//     Future<RateResult> getRate(String currency, DateTime date);
//   }
//   - cache-first: findByDate hit (not correctable, TTL valid) → RateCached, zero API calls
//   - miss → API fetch → upsert (which prunes D-09) → RateFetched
//   - D-03 correctable proxy guard: actualRateDate != null && rateDate < today && fetchedAt < today
//   - D-06 cooldown: all sources fail while online → ~1 min cooldown, skip network within window

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/currency/domain/models/exchange_rate.dart';
import 'package:home_pocket/features/currency/domain/repositories/exchange_rate_repository.dart';
import 'package:mocktail/mocktail.dart';

// import 'package:home_pocket/infrastructure/exchange_rate/exchange_rate_api_client.dart';
// import 'package:home_pocket/infrastructure/exchange_rate/exchange_rate_cache_service.dart';

/// Mock for the plan-41-01 repository interface (findLatestNonManual / deleteOlderThan / findAll live).
class MockExchangeRateRepository extends Mock implements ExchangeRateRepository {}

class _FakeExchangeRate extends Fake implements ExchangeRate {}

const _redScaffold = 'Wave 0 RED — ExchangeRateCacheService not yet created (plan 41-04)';

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeExchangeRate());
    registerFallbackValue(DateTime.utc(2026, 6, 12));
  });

  group('RATE-02: cache-first orchestration', () {
    test(
      'Cache HIT (exact date+currency in repo, not correctable) → RateCached, zero API calls',
      () {
        // GIVEN repository.findByDate('USD', date) returns a non-proxy, in-TTL row
        // WHEN cacheService.getRate('USD', date)
        // THEN result is RateCached AND apiClient.fetchRate is never called
      },
      skip: _redScaffold,
    );

    test(
      'Cache MISS → calls API, upserts result, returns RateFetched',
      () {
        // GIVEN findByDate returns null
        //   AND apiClient.fetchRate returns a rate
        // WHEN cacheService.getRate('USD', date)
        // THEN repository.upsert is called with the fetched row AND result is RateFetched
      },
      skip: _redScaffold,
    );

    test(
      'Historical rate is permanent (fetchedAt before today, actualRateDate == null → no re-fetch)',
      () {
        // GIVEN a cached historical row with actualRateDate == null
        // WHEN getRate for that historical date
        // THEN no API call (historical rates are permanent, D-01)
      },
      skip: _redScaffold,
    );

    test(
      'D-03: correctable proxy (actualRateDate != null AND rateDate < today AND fetchedAt < today) → re-fetch',
      () {
        // GIVEN a cached proxy row (actualRateDate != null) whose rateDate is now
        //   historical and whose fetchedAt is before today
        // WHEN getRate for that date
        // THEN apiClient.fetchRate IS called once (one-shot correction)
      },
      skip: _redScaffold,
    );

    test(
      'D-03: after re-fetch today (fetchedAt == today), no infinite re-fetch loop',
      () {
        // GIVEN a proxy row re-fetched today (fetchedAt == today midnight)
        // WHEN getRate for that date again
        // THEN no further API call — fetchedAt-today guard prevents the loop (Pitfall 4)
      },
      skip: _redScaffold,
    );
  });

  group('RATE-03: offline + all-sources-fail handling', () {
    test(
      'D-06: all API sources fail while online → sets cooldown; second call within window skips network',
      () {
        // GIVEN all three sources fail for the first getRate while online
        // WHEN a second getRate is issued within ~1 min (any currency, Pitfall 5 global cooldown)
        // THEN the second call performs zero network attempts and goes straight to cache
      },
      skip: _redScaffold,
    );
  });

  group('D-09: 2-year TTL pruning on upsert', () {
    test(
      'upsert triggers deleteOlderThan with cutoff = today - 2 years',
      () {
        // GIVEN a successful fetch leading to repository.upsert
        // WHEN the upsert path runs
        // THEN repository.deleteOlderThan is called with a cutoff ≈ today - 2 years
      },
      skip: _redScaffold,
    );
  });
}
