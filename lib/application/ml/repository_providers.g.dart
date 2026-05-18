// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Application-layer MerchantDatabase provider.
///
/// CRITICAL: `keepAlive: true` is REQUIRED — this provider is on the HIGH-05
/// hard list (`merchantDatabaseProvider`). The `app` prefix is used because:
///   - The original `merchantDatabaseProvider` (in voice_providers.dart) remains
///     during Wave 2/3 coexistence until Plan 04-02 Task 5 deletes it.
///   - Plan 04-05's hard list is updated to reference `appMerchantDatabaseProvider`.
///   - Riverpod codegen creates symbols at library level; `app` prefix guarantees
///     no collision between the two definitions.
///
/// MerchantDatabase is kept alive because it holds an in-memory seed dataset
/// that should be instantiated once per app session.

@ProviderFor(appMerchantDatabase)
final appMerchantDatabaseProvider = AppMerchantDatabaseProvider._();

/// Application-layer MerchantDatabase provider.
///
/// CRITICAL: `keepAlive: true` is REQUIRED — this provider is on the HIGH-05
/// hard list (`merchantDatabaseProvider`). The `app` prefix is used because:
///   - The original `merchantDatabaseProvider` (in voice_providers.dart) remains
///     during Wave 2/3 coexistence until Plan 04-02 Task 5 deletes it.
///   - Plan 04-05's hard list is updated to reference `appMerchantDatabaseProvider`.
///   - Riverpod codegen creates symbols at library level; `app` prefix guarantees
///     no collision between the two definitions.
///
/// MerchantDatabase is kept alive because it holds an in-memory seed dataset
/// that should be instantiated once per app session.

final class AppMerchantDatabaseProvider
    extends
        $FunctionalProvider<
          MerchantDatabase,
          MerchantDatabase,
          MerchantDatabase
        >
    with $Provider<MerchantDatabase> {
  /// Application-layer MerchantDatabase provider.
  ///
  /// CRITICAL: `keepAlive: true` is REQUIRED — this provider is on the HIGH-05
  /// hard list (`merchantDatabaseProvider`). The `app` prefix is used because:
  ///   - The original `merchantDatabaseProvider` (in voice_providers.dart) remains
  ///     during Wave 2/3 coexistence until Plan 04-02 Task 5 deletes it.
  ///   - Plan 04-05's hard list is updated to reference `appMerchantDatabaseProvider`.
  ///   - Riverpod codegen creates symbols at library level; `app` prefix guarantees
  ///     no collision between the two definitions.
  ///
  /// MerchantDatabase is kept alive because it holds an in-memory seed dataset
  /// that should be instantiated once per app session.
  AppMerchantDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appMerchantDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appMerchantDatabaseHash();

  @$internal
  @override
  $ProviderElement<MerchantDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MerchantDatabase create(Ref ref) {
    return appMerchantDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MerchantDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MerchantDatabase>(value),
    );
  }
}

String _$appMerchantDatabaseHash() =>
    r'd1b349675d38b20c037f30db9ff6a12c11ab92d9';

/// Application-layer LookupMerchantUseCase provider.

@ProviderFor(lookupMerchantUseCase)
final lookupMerchantUseCaseProvider = LookupMerchantUseCaseProvider._();

/// Application-layer LookupMerchantUseCase provider.

final class LookupMerchantUseCaseProvider
    extends
        $FunctionalProvider<
          LookupMerchantUseCase,
          LookupMerchantUseCase,
          LookupMerchantUseCase
        >
    with $Provider<LookupMerchantUseCase> {
  /// Application-layer LookupMerchantUseCase provider.
  LookupMerchantUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lookupMerchantUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lookupMerchantUseCaseHash();

  @$internal
  @override
  $ProviderElement<LookupMerchantUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LookupMerchantUseCase create(Ref ref) {
    return lookupMerchantUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LookupMerchantUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LookupMerchantUseCase>(value),
    );
  }
}

String _$lookupMerchantUseCaseHash() =>
    r'58f7fdc8a54ee739874c80b76aeb14738250f299';
