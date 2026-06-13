// GREEN (plan 41-04) — ExchangeRateCacheService cache-first orchestration.
//
// Subject under test: lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart
// Contract: RATE-02 (cache HIT zero API calls), cache MISS → fetch + upsert,
// D-03 correctable proxy one-shot re-fetch + no infinite loop, D-06 cooldown,
// D-09 TTL prune on upsert.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/currency/rate_result.dart';
import 'package:home_pocket/features/currency/domain/models/exchange_rate.dart';
import 'package:home_pocket/features/currency/domain/repositories/exchange_rate_repository.dart';
import 'package:home_pocket/infrastructure/exchange_rate/exchange_rate_api_client.dart';
import 'package:home_pocket/infrastructure/exchange_rate/exchange_rate_cache_service.dart';
import 'package:mocktail/mocktail.dart';

class MockExchangeRateRepository extends Mock
    implements ExchangeRateRepository {}

class MockExchangeRateApiClient extends Mock
    implements ExchangeRateApiClient {}

class MockConnectivity extends Mock implements Connectivity {}

class _FakeExchangeRate extends Fake implements ExchangeRate {}

void main() {
  late MockExchangeRateRepository repo;
  late MockExchangeRateApiClient apiClient;
  late MockConnectivity connectivity;
  late ExchangeRateCacheService service;

  final date = DateTime.utc(2026, 6, 12);

  setUpAll(() {
    registerFallbackValue(_FakeExchangeRate());
    registerFallbackValue(DateTime.utc(2026, 6, 12));
  });

  setUp(() {
    repo = MockExchangeRateRepository();
    apiClient = MockExchangeRateApiClient();
    connectivity = MockConnectivity();
    service = ExchangeRateCacheService(
      repository: repo,
      apiClient: apiClient,
      connectivity: connectivity,
    );
    // Default online.
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(() => repo.upsert(any())).thenAnswer((_) async {});
    when(() => repo.deleteOlderThan(any())).thenAnswer((_) async {});
  });

  ExchangeRate row({
    required DateTime rateDate,
    required DateTime fetchedAt,
    DateTime? actualRateDate,
    String source = 'frankfurter',
    String rate = '157.34',
  }) =>
      ExchangeRate(
        currency: 'USD',
        rateDate: rateDate,
        rate: rate,
        fetchedAt: fetchedAt,
        source: source,
        actualRateDate: actualRateDate,
      );

  group('RATE-02: cache-first orchestration', () {
    test(
      'Cache HIT (exact date+currency, not correctable) → RateCached, zero API calls',
      () async {
        when(() => repo.findByDate('USD', date)).thenAnswer(
          (_) async => row(rateDate: date, fetchedAt: DateTime.now()),
        );

        final result = await service.getRate('USD', date);

        expect(result, isA<RateCached>());
        expect((result as RateCached).rate, '157.34');
        verifyNever(() => apiClient.fetchRate(any(), any()));
      },
    );

    test('Cache MISS → calls API, upserts result, returns RateFetched',
        () async {
      when(() => repo.findByDate('USD', date)).thenAnswer((_) async => null);
      when(() => apiClient.fetchRate('USD', date)).thenAnswer(
        (_) async => (
          rate: '150.00',
          actualRateDate: null,
          source: 'frankfurter',
        ),
      );

      final result = await service.getRate('USD', date);

      expect(result, isA<RateFetched>());
      expect((result as RateFetched).rate, '150.00');
      verify(() => repo.upsert(any())).called(1);
    });

    test(
      'Historical rate is permanent (actualRateDate == null → not correctable → no re-fetch)',
      () async {
        when(() => repo.findByDate('USD', date)).thenAnswer(
          (_) async => row(
            rateDate: date,
            fetchedAt: DateTime.utc(2026, 6, 12),
            actualRateDate: null,
          ),
        );

        final result = await service.getRate('USD', date);

        expect(result, isA<RateCached>());
        verifyNever(() => apiClient.fetchRate(any(), any()));
      },
    );

    test(
      'D-03: correctable proxy (actualRateDate != null, rateDate < today, fetchedAt < today) → re-fetch',
      () async {
        final old = DateTime.utc(2026, 6, 1);
        when(() => repo.findByDate('USD', old)).thenAnswer(
          (_) async => row(
            rateDate: old,
            fetchedAt: old,
            actualRateDate: DateTime.utc(2026, 5, 30),
          ),
        );
        when(() => apiClient.fetchRate('USD', old)).thenAnswer(
          (_) async => (
            rate: '155.00',
            actualRateDate: null,
            source: 'frankfurter',
          ),
        );

        final result = await service.getRate('USD', old);

        expect(result, isA<RateFetched>());
        verify(() => apiClient.fetchRate('USD', old)).called(1);
      },
    );

    test(
      'D-03: after re-fetch today (fetchedAt == today), no infinite re-fetch loop',
      () async {
        final old = DateTime.utc(2026, 6, 1);
        // fetchedAt is today → NOT correctable → cache HIT, no API call.
        when(() => repo.findByDate('USD', old)).thenAnswer(
          (_) async => row(
            rateDate: old,
            fetchedAt: DateTime.now(),
            actualRateDate: DateTime.utc(2026, 5, 30),
          ),
        );

        final result = await service.getRate('USD', old);

        expect(result, isA<RateCached>());
        verifyNever(() => apiClient.fetchRate(any(), any()));
      },
    );
  });

  group('RATE-03: offline + all-sources-fail handling', () {
    test(
      'D-06: all sources fail while online → cooldown; second call skips network',
      () async {
        when(() => repo.findByDate(any(), any())).thenAnswer((_) async => null);
        when(() => apiClient.fetchRate(any(), any()))
            .thenThrow(const ExchangeRateApiException('all failed'));
        when(() => repo.findLatestNonManual(any()))
            .thenAnswer((_) async => null);
        when(() => repo.findLatest(any())).thenAnswer((_) async => null);

        final first = await service.getRate('USD', date);
        expect(first, isA<RateUnavailable>());

        // Second call (any currency) within cooldown window: no network.
        final second = await service.getRate('EUR', date);
        expect(second, isA<RateUnavailable>());

        // fetchRate called only once (first call); cooldown blocked the second.
        verify(() => apiClient.fetchRate(any(), any())).called(1);
      },
    );

    test('D-07: offline fallback prefers API-cached row over manual', () async {
      when(() => connectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      when(() => repo.findByDate(any(), any())).thenAnswer((_) async => null);
      when(() => repo.findLatestNonManual('USD')).thenAnswer(
        (_) async => row(
          rateDate: DateTime.utc(2026, 6, 10),
          fetchedAt: DateTime.utc(2026, 6, 10),
          source: 'frankfurter',
        ),
      );

      final result = await service.getRate('USD', date);

      expect(result, isA<RateFallback>());
      verifyNever(() => apiClient.fetchRate(any(), any()));
    });

    test('D-08: nothing cached → RateUnavailable', () async {
      when(() => connectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      when(() => repo.findByDate(any(), any())).thenAnswer((_) async => null);
      when(() => repo.findLatestNonManual(any())).thenAnswer((_) async => null);
      when(() => repo.findLatest(any())).thenAnswer((_) async => null);

      final result = await service.getRate('USD', date);

      expect(result, isA<RateUnavailable>());
    });
  });

  group('D-09: 2-year TTL pruning on upsert', () {
    test('upsert triggers deleteOlderThan with cutoff ≈ today - 2 years',
        () async {
      when(() => repo.findByDate('USD', date)).thenAnswer((_) async => null);
      when(() => apiClient.fetchRate('USD', date)).thenAnswer(
        (_) async => (
          rate: '150.00',
          actualRateDate: null,
          source: 'frankfurter',
        ),
      );

      await service.getRate('USD', date);
      // _pruneStaleCache is fire-and-forget — let the microtask settle.
      await Future<void>.delayed(Duration.zero);

      final captured =
          verify(() => repo.deleteOlderThan(captureAny())).captured.single
              as DateTime;
      final expected = DateTime.utc(
        DateTime.now().year - 2,
        DateTime.now().month,
        DateTime.now().day,
      );
      expect(captured.year, expected.year);
      expect(captured.month, expected.month);
      expect(captured.day, expected.day);
    });
  });
}
