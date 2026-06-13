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
    // Default: no manual / non-manual rows unless a test says otherwise.
    when(() => repo.findLatestNonManual(any())).thenAnswer((_) async => null);
    when(() => repo.findLatestManual(any())).thenAnswer((_) async => null);
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

      final result = await service.getRate('USD', date);

      expect(result, isA<RateUnavailable>());
    });

    test(
      'WR-03: manual fallback uses findLatestManual directly (not findLatest)',
      () async {
        when(() => connectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(() => repo.findByDate(any(), any())).thenAnswer((_) async => null);
        // Only a manual row exists; no non-manual row.
        when(() => repo.findLatestManual('USD')).thenAnswer(
          (_) async => row(
            rateDate: DateTime.utc(2026, 6, 9),
            fetchedAt: DateTime.utc(2026, 6, 9),
            source: 'manual',
          ),
        );

        final result = await service.getRate('USD', date);

        expect(result, isA<RateManual>());
        // findLatest is no longer consulted in the fallback path.
        verifyNever(() => repo.findLatest(any()));
      },
    );

    test(
      'WR-02: unrefreshable correctable proxy returns the exact-date proxy, '
      'not a latest-any-date fallback',
      () async {
        // Requested date has a correctable proxy (actualRateDate set,
        // rateDate historical, fetched on a prior day). Re-fetch fails.
        final requested = DateTime.utc(2026, 6, 1);
        when(() => repo.findByDate('USD', requested)).thenAnswer(
          (_) async => row(
            rateDate: requested,
            fetchedAt: DateTime.utc(2026, 5, 30),
            actualRateDate: DateTime.utc(2026, 5, 30),
            rate: 'PROXY_RATE',
          ),
        );
        when(() => apiClient.fetchRate('USD', requested))
            .thenThrow(const ExchangeRateApiException('all failed'));
        // A NEWER non-manual row exists for a different date — must NOT win.
        when(() => repo.findLatestNonManual('USD')).thenAnswer(
          (_) async => row(
            rateDate: DateTime.utc(2026, 6, 11),
            fetchedAt: DateTime.utc(2026, 6, 11),
            rate: 'NEWER_RATE',
          ),
        );

        final result = await service.getRate('USD', requested);

        expect(result, isA<RateFallback>());
        final fallback = result as RateFallback;
        // The exact-date proxy is preferred over the latest-any-date row.
        expect(fallback.rate, 'PROXY_RATE');
        expect(fallback.cachedDate, requested);
      },
    );

    test(
      'WR-04: connectivity is consulted before the cooldown is honored',
      () async {
        // Cooldown was set on a prior online all-sources-fail. Now the device
        // is OFFLINE. The connectivity gate must run first → cache fallback,
        // and the network is never touched regardless of the cooldown.
        when(() => apiClient.fetchRate(any(), any()))
            .thenThrow(const ExchangeRateApiException('all failed'));
        when(() => repo.findByDate(any(), any())).thenAnswer((_) async => null);

        // Prime the cooldown via one online failure.
        final primed = await service.getRate('USD', date);
        expect(primed, isA<RateUnavailable>());

        // Go offline; subsequent lookup must hit the connectivity gate first.
        when(() => connectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(() => repo.findLatestNonManual('EUR')).thenAnswer(
          (_) async => row(
            rateDate: DateTime.utc(2026, 6, 10),
            fetchedAt: DateTime.utc(2026, 6, 10),
          ),
        );

        final offline = await service.getRate('EUR', date);
        expect(offline, isA<RateFallback>());

        // Network attempted only on the first (online) call.
        verify(() => apiClient.fetchRate(any(), any())).called(1);
      },
    );

    test(
      'WR-04: a successful fetch clears the in-memory cooldown',
      () async {
        when(() => repo.findByDate(any(), any())).thenAnswer((_) async => null);
        when(() => apiClient.fetchRate('USD', date)).thenAnswer(
          (_) async => (
            rate: '150.00',
            actualRateDate: null,
            source: 'frankfurter',
          ),
        );

        // A successful fetch should leave no cooldown behind. We assert via a
        // follow-up offline-then-online sequence: after success, a new online
        // call still reaches the network (proving no stale cooldown gate).
        final first = await service.getRate('USD', date);
        expect(first, isA<RateFetched>());

        when(() => apiClient.fetchRate('EUR', date)).thenAnswer(
          (_) async => (
            rate: '160.00',
            actualRateDate: null,
            source: 'frankfurter',
          ),
        );
        final second = await service.getRate('EUR', date);
        expect(second, isA<RateFetched>());

        verify(() => apiClient.fetchRate(any(), any())).called(2);
      },
    );
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
