// Wave 0 RED scaffold — GetExchangeRateUseCase (Phase 41).
//
// Subject under test: lib/application/currency/get_exchange_rate_use_case.dart
// and lib/application/currency/rate_result.dart (NEITHER YET CREATED — built in
// plan 41-05). Fixes the behavioral contract for RATE-03, RATE-04, RATE-06
// (ADR-022 D-02 dialog signal / D-03 toast signal) BEFORE production code lands.
//
// The ExchangeRateRepository import IS valid (plan 41-01). The
// GetExchangeRateUseCase + RateResult + ExchangeRateCacheService imports stay
// commented until plan 41-05 creates them.
//
// Expected use-case surface (RESEARCH.md Pattern 4 + PATTERNS.md):
//   class GetExchangeRateParams {
//     final String currency;
//     final DateTime date;
//     final String? previousRate;
//     final bool wasManualOverride;
//   }
//   class GetExchangeRateUseCase {
//     GetExchangeRateUseCase({required ExchangeRateCacheService cacheService});
//     Future<RateResult> execute(GetExchangeRateParams params);  // NEVER throws
//   }
//
// Expected RateResult sealed variants (RESEARCH.md Pattern 2):
//   sealed class RateResult { const RateResult(); }
//   final class RateFetched / RateCached / RateFallback / RateManual / RateUnavailable

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/currency/domain/models/exchange_rate.dart';
import 'package:home_pocket/features/currency/domain/repositories/exchange_rate_repository.dart';
import 'package:mocktail/mocktail.dart';

// import 'package:home_pocket/application/currency/get_exchange_rate_use_case.dart';
// import 'package:home_pocket/application/currency/rate_result.dart';
// import 'package:home_pocket/infrastructure/exchange_rate/exchange_rate_cache_service.dart';

/// Mock for the plan-41-01 repository interface.
class MockExchangeRateRepository extends Mock implements ExchangeRateRepository {}

class _FakeExchangeRate extends Fake implements ExchangeRate {}

const _redScaffold = 'Wave 0 RED — GetExchangeRateUseCase / RateResult not yet created (plan 41-05)';

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeExchangeRate());
  });

  group('RATE-03: use case never throws', () {
    test(
      'all errors wrapped → returns RateFallback or RateUnavailable, never throws',
      () {
        // GIVEN the cache service raises (DB crash / connectivity error)
        // WHEN useCase.execute(params)
        // THEN execute completes with a RateResult variant (RateFallback /
        //      RateUnavailable) — it never propagates the exception to the caller
        //      (offline-first never-block-save invariant)
      },
      skip: _redScaffold,
    );
  });

  group('RATE-04: manual override', () {
    test(
      'manual override → upserted via repository with source=\'manual\'',
      () {
        // GIVEN the user supplies a manual rate
        // WHEN the override path runs
        // THEN repository.upsert is called with an ExchangeRate whose source == 'manual'
      },
      skip: _redScaffold,
    );

    test(
      'D-07: manual fallback only used when no API-cached row exists',
      () {
        // GIVEN both an API-cached row and a manual row exist for the currency
        // WHEN offline fallback resolves
        // THEN the API-cached row wins (findLatestNonManual); RateManual is only
        //      returned when findLatestNonManual is null (D-07 lowest priority)
      },
      skip: _redScaffold,
    );
  });

  group('RATE-06: ADR-022 date-change signals', () {
    test(
      'wasManualOverride=true AND date changed → use case emits dialog signal (ADR-022 D-02)',
      () {
        // GIVEN params.wasManualOverride == true and the date changed
        // WHEN execute runs
        // THEN the result carries the ADR-022 D-02 overrideConflict dialog signal
      },
      skip: _redScaffold,
    );

    test(
      'wasManualOverride=false, date changed, >1% JPY delta → use case emits toast signal (ADR-022 D-03)',
      () {
        // GIVEN no override, date changed, and |newJpy - oldJpy| / oldJpy > 0.01
        // WHEN execute runs
        // THEN the result carries the ADR-022 D-03 jpyAmountChanged toast signal
      },
      skip: _redScaffold,
    );

    test(
      'wasManualOverride=false, date changed, <=1% JPY delta → no signal',
      () {
        // GIVEN no override, date changed, and the JPY delta is within 1%
        // WHEN execute runs
        // THEN no signal is attached to the result
      },
      skip: _redScaffold,
    );
  });
}
