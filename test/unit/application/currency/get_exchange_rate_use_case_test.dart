// GREEN (plan 41-04) — GetExchangeRateUseCase ADR-022 signal logic.
//
// Subject under test: lib/application/currency/get_exchange_rate_use_case.dart
// Contract: RATE-03 never-throws, RATE-04 manual override (source='manual'),
// D-07 manual fallback priority (delegated to the cache service), RATE-06
// ADR-022 D-02 dialog signal / D-03 toast signal / no-signal under threshold.

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/currency/get_exchange_rate_use_case.dart';
import 'package:home_pocket/application/currency/rate_result.dart';
import 'package:home_pocket/features/currency/domain/models/exchange_rate.dart';
import 'package:home_pocket/features/currency/domain/repositories/exchange_rate_repository.dart';
import 'package:home_pocket/infrastructure/exchange_rate/exchange_rate_cache_service.dart';
import 'package:mocktail/mocktail.dart';

class MockExchangeRateCacheService extends Mock
    implements ExchangeRateCacheService {}

class MockExchangeRateRepository extends Mock
    implements ExchangeRateRepository {}

class _FakeExchangeRate extends Fake implements ExchangeRate {}

void main() {
  late MockExchangeRateCacheService cacheService;
  late MockExchangeRateRepository repo;
  late GetExchangeRateUseCase useCase;

  final date = DateTime.utc(2026, 6, 12);

  setUpAll(() {
    registerFallbackValue(_FakeExchangeRate());
    registerFallbackValue(DateTime.utc(2026, 6, 12));
  });

  setUp(() {
    cacheService = MockExchangeRateCacheService();
    repo = MockExchangeRateRepository();
    useCase = GetExchangeRateUseCase(
      cacheService: cacheService,
      repository: repo,
    );
    when(() => repo.upsert(any())).thenAnswer((_) async {});
  });

  RateCached cached(String rate, {String source = 'frankfurter'}) => RateCached(
        rate: rate,
        currency: 'USD',
        cachedDate: date,
        source: source,
      );

  group('RATE-03: use case never throws', () {
    test('cache service raises → returns RateUnavailable, never throws',
        () async {
      when(() => cacheService.getRate(any(), any()))
          .thenThrow(Exception('DB crash'));

      final result = await useCase.execute(
        GetExchangeRateParams(currency: 'USD', date: date),
      );

      expect(result.result, isA<RateUnavailable>());
      expect(result.signal, isNull);
    });
  });

  group('RATE-04: manual override', () {
    test("manual override → upserted via repository with source='manual'",
        () async {
      final result = await useCase.execute(
        GetExchangeRateParams(
          currency: 'USD',
          date: date,
          manualOverrideRate: '150.5',
        ),
      );

      final captured =
          verify(() => repo.upsert(captureAny())).captured.single
              as ExchangeRate;
      expect(captured.source, 'manual');
      expect(captured.rate, '150.5');
      expect(result.result, isA<RateCached>());
      expect((result.result as RateCached).isManualOverride, true);
      verifyNever(() => cacheService.getRate(any(), any()));
    });

    test('invalid manual override → RateUnavailable, no upsert', () async {
      final result = await useCase.execute(
        GetExchangeRateParams(
          currency: 'USD',
          date: date,
          manualOverrideRate: '-3',
        ),
      );

      expect(result.result, isA<RateUnavailable>());
      verifyNever(() => repo.upsert(any()));
    });

    test('D-07: manual fallback priority is delegated to the cache service',
        () async {
      // The use case does not re-implement D-07 priority — it trusts the cache
      // service to return RateFallback (API-cached) over RateManual. Here we
      // assert the use case forwards the cache result unchanged when no signal
      // logic applies.
      when(() => cacheService.getRate('USD', date)).thenAnswer(
        (_) async => RateFallback(
          rate: '149.0',
          currency: 'USD',
          cachedDate: date,
        ),
      );

      final result = await useCase.execute(
        GetExchangeRateParams(currency: 'USD', date: date),
      );

      expect(result.result, isA<RateFallback>());
      expect(result.signal, isNull);
    });
  });

  group('RATE-06: ADR-022 date-change signals', () {
    test(
      'wasManualOverride=true AND previousRate present → emits dialog signal (D-02)',
      () async {
        when(() => cacheService.getRate('USD', date))
            .thenAnswer((_) async => cached('160.0'));

        final result = await useCase.execute(
          GetExchangeRateParams(
            currency: 'USD',
            date: date,
            previousRate: '150.0',
            wasManualOverride: true,
          ),
        );

        expect(result.signal, isA<RateSignalDialog>());
        final dialog = result.signal as RateSignalDialog;
        expect(dialog.oldRate, '150.0');
        expect(dialog.newRate, '160.0');
      },
    );

    test(
      'wasManualOverride=false, >1% delta → emits toast signal (D-03)',
      () async {
        when(() => cacheService.getRate('USD', date))
            .thenAnswer((_) async => cached('160.0'));

        final result = await useCase.execute(
          GetExchangeRateParams(
            currency: 'USD',
            date: date,
            previousRate: '150.0', // ~6.7% change
          ),
        );

        expect(result.signal, isA<RateSignalToast>());
      },
    );

    test('wasManualOverride=false, <=1% delta → no signal', () async {
      when(() => cacheService.getRate('USD', date))
          .thenAnswer((_) async => cached('150.5'));

      final result = await useCase.execute(
        GetExchangeRateParams(
          currency: 'USD',
          date: date,
          previousRate: '150.0', // ~0.33% change
        ),
      );

      expect(result.signal, isNull);
    });

    test('no previousRate → no signal', () async {
      when(() => cacheService.getRate('USD', date))
          .thenAnswer((_) async => cached('150.0'));

      final result = await useCase.execute(
        GetExchangeRateParams(currency: 'USD', date: date),
      );

      expect(result.signal, isNull);
    });
  });
}
