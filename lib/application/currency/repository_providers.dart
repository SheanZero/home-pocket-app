import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/daos/exchange_rate_dao.dart';
import '../../data/repositories/exchange_rate_repository_impl.dart';
import '../../features/currency/domain/repositories/exchange_rate_repository.dart';
import '../../infrastructure/exchange_rate/exchange_rate_api_client.dart';
import '../../infrastructure/exchange_rate/exchange_rate_cache_service.dart';
import '../../infrastructure/security/providers.dart' as security;
import 'get_exchange_rate_use_case.dart';

part 'repository_providers.g.dart';

/// Application-layer Riverpod provider for [ExchangeRateRepository].
///
/// Returns the [ExchangeRateRepository] interface (not the implementation) so
/// callers depend only on the domain contract (HIGH-02 compliance).
///
/// Wired with the shared [AppDatabase] from security providers following the
/// same `app` prefix convention as accounting/repository_providers.dart.
@riverpod
ExchangeRateRepository appExchangeRateRepository(Ref ref) {
  final db = ref.watch(security.appDatabaseProvider);
  final dao = ExchangeRateDao(db);
  return ExchangeRateRepositoryImpl(dao: dao);
}

/// Application-layer Riverpod provider for [ExchangeRateApiClient].
///
/// No dependencies — uses the default `http.Client()`. Application →
/// infrastructure direction only (no presentation imports).
@riverpod
ExchangeRateApiClient appExchangeRateApiClient(Ref ref) {
  return ExchangeRateApiClient();
}

/// Application-layer Riverpod provider for [ExchangeRateCacheService].
///
/// Composes the [ExchangeRateRepository] (Drift cache) and
/// [ExchangeRateApiClient] (three-source HTTP fallback) behind the cache-first
/// orchestrator. Connectivity is left at its default (`Connectivity()`).
@riverpod
ExchangeRateCacheService appExchangeRateCacheService(Ref ref) {
  return ExchangeRateCacheService(
    repository: ref.watch(appExchangeRateRepositoryProvider),
    apiClient: ref.watch(appExchangeRateApiClientProvider),
  );
}

/// Application-layer Riverpod provider for [GetExchangeRateUseCase].
///
/// Phase 42 form providers call `ref.watch(appGetExchangeRateUseCaseProvider)`
/// and invoke `execute(...)` to receive a [RateResultWithSignal].
@riverpod
GetExchangeRateUseCase appGetExchangeRateUseCase(Ref ref) {
  return GetExchangeRateUseCase(
    cacheService: ref.watch(appExchangeRateCacheServiceProvider),
    repository: ref.watch(appExchangeRateRepositoryProvider),
  );
}
