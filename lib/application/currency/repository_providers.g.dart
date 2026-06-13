// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Application-layer Riverpod provider for [ExchangeRateRepository].
///
/// Returns the [ExchangeRateRepository] interface (not the implementation) so
/// callers depend only on the domain contract (HIGH-02 compliance).
///
/// Wired with the shared [AppDatabase] from security providers following the
/// same `app` prefix convention as accounting/repository_providers.dart.

@ProviderFor(appExchangeRateRepository)
final appExchangeRateRepositoryProvider = AppExchangeRateRepositoryProvider._();

/// Application-layer Riverpod provider for [ExchangeRateRepository].
///
/// Returns the [ExchangeRateRepository] interface (not the implementation) so
/// callers depend only on the domain contract (HIGH-02 compliance).
///
/// Wired with the shared [AppDatabase] from security providers following the
/// same `app` prefix convention as accounting/repository_providers.dart.

final class AppExchangeRateRepositoryProvider
    extends
        $FunctionalProvider<
          ExchangeRateRepository,
          ExchangeRateRepository,
          ExchangeRateRepository
        >
    with $Provider<ExchangeRateRepository> {
  /// Application-layer Riverpod provider for [ExchangeRateRepository].
  ///
  /// Returns the [ExchangeRateRepository] interface (not the implementation) so
  /// callers depend only on the domain contract (HIGH-02 compliance).
  ///
  /// Wired with the shared [AppDatabase] from security providers following the
  /// same `app` prefix convention as accounting/repository_providers.dart.
  AppExchangeRateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appExchangeRateRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appExchangeRateRepositoryHash();

  @$internal
  @override
  $ProviderElement<ExchangeRateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExchangeRateRepository create(Ref ref) {
    return appExchangeRateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExchangeRateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExchangeRateRepository>(value),
    );
  }
}

String _$appExchangeRateRepositoryHash() =>
    r'84f7d915b43aa711ba4bf87816bd7ad675f12b01';

/// Application-layer Riverpod provider for [ExchangeRateApiClient].
///
/// No dependencies — uses the default `http.Client()`. Application →
/// infrastructure direction only (no presentation imports).

@ProviderFor(appExchangeRateApiClient)
final appExchangeRateApiClientProvider = AppExchangeRateApiClientProvider._();

/// Application-layer Riverpod provider for [ExchangeRateApiClient].
///
/// No dependencies — uses the default `http.Client()`. Application →
/// infrastructure direction only (no presentation imports).

final class AppExchangeRateApiClientProvider
    extends
        $FunctionalProvider<
          ExchangeRateApiClient,
          ExchangeRateApiClient,
          ExchangeRateApiClient
        >
    with $Provider<ExchangeRateApiClient> {
  /// Application-layer Riverpod provider for [ExchangeRateApiClient].
  ///
  /// No dependencies — uses the default `http.Client()`. Application →
  /// infrastructure direction only (no presentation imports).
  AppExchangeRateApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appExchangeRateApiClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appExchangeRateApiClientHash();

  @$internal
  @override
  $ProviderElement<ExchangeRateApiClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExchangeRateApiClient create(Ref ref) {
    return appExchangeRateApiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExchangeRateApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExchangeRateApiClient>(value),
    );
  }
}

String _$appExchangeRateApiClientHash() =>
    r'3d032b1e31cc487c24a5a7f2b6b3245ff3089202';

/// Application-layer Riverpod provider for [ExchangeRateCacheService].
///
/// Composes the [ExchangeRateRepository] (Drift cache) and
/// [ExchangeRateApiClient] (three-source HTTP fallback) behind the cache-first
/// orchestrator. Connectivity is left at its default (`Connectivity()`).

@ProviderFor(appExchangeRateCacheService)
final appExchangeRateCacheServiceProvider =
    AppExchangeRateCacheServiceProvider._();

/// Application-layer Riverpod provider for [ExchangeRateCacheService].
///
/// Composes the [ExchangeRateRepository] (Drift cache) and
/// [ExchangeRateApiClient] (three-source HTTP fallback) behind the cache-first
/// orchestrator. Connectivity is left at its default (`Connectivity()`).

final class AppExchangeRateCacheServiceProvider
    extends
        $FunctionalProvider<
          ExchangeRateCacheService,
          ExchangeRateCacheService,
          ExchangeRateCacheService
        >
    with $Provider<ExchangeRateCacheService> {
  /// Application-layer Riverpod provider for [ExchangeRateCacheService].
  ///
  /// Composes the [ExchangeRateRepository] (Drift cache) and
  /// [ExchangeRateApiClient] (three-source HTTP fallback) behind the cache-first
  /// orchestrator. Connectivity is left at its default (`Connectivity()`).
  AppExchangeRateCacheServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appExchangeRateCacheServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appExchangeRateCacheServiceHash();

  @$internal
  @override
  $ProviderElement<ExchangeRateCacheService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExchangeRateCacheService create(Ref ref) {
    return appExchangeRateCacheService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExchangeRateCacheService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExchangeRateCacheService>(value),
    );
  }
}

String _$appExchangeRateCacheServiceHash() =>
    r'7edfb8b831cfdd54f663da24549f292084ff78e8';

/// Application-layer Riverpod provider for [GetExchangeRateUseCase].
///
/// Phase 42 form providers call `ref.watch(appGetExchangeRateUseCaseProvider)`
/// and invoke `execute(...)` to receive a [RateResultWithSignal].

@ProviderFor(appGetExchangeRateUseCase)
final appGetExchangeRateUseCaseProvider = AppGetExchangeRateUseCaseProvider._();

/// Application-layer Riverpod provider for [GetExchangeRateUseCase].
///
/// Phase 42 form providers call `ref.watch(appGetExchangeRateUseCaseProvider)`
/// and invoke `execute(...)` to receive a [RateResultWithSignal].

final class AppGetExchangeRateUseCaseProvider
    extends
        $FunctionalProvider<
          GetExchangeRateUseCase,
          GetExchangeRateUseCase,
          GetExchangeRateUseCase
        >
    with $Provider<GetExchangeRateUseCase> {
  /// Application-layer Riverpod provider for [GetExchangeRateUseCase].
  ///
  /// Phase 42 form providers call `ref.watch(appGetExchangeRateUseCaseProvider)`
  /// and invoke `execute(...)` to receive a [RateResultWithSignal].
  AppGetExchangeRateUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appGetExchangeRateUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appGetExchangeRateUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetExchangeRateUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetExchangeRateUseCase create(Ref ref) {
    return appGetExchangeRateUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetExchangeRateUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetExchangeRateUseCase>(value),
    );
  }
}

String _$appGetExchangeRateUseCaseHash() =>
    r'383684e74def627d45aad5b96404135047c98d88';
