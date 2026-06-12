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
