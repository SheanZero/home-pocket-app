// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appMerchantDatabaseHash() =>
    r'd1b349675d38b20c037f30db9ff6a12c11ab92d9';

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
///
/// Copied from [appMerchantDatabase].
@ProviderFor(appMerchantDatabase)
final appMerchantDatabaseProvider = Provider<MerchantDatabase>.internal(
  appMerchantDatabase,
  name: r'appMerchantDatabaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appMerchantDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppMerchantDatabaseRef = ProviderRef<MerchantDatabase>;
String _$lookupMerchantUseCaseHash() =>
    r'58f7fdc8a54ee739874c80b76aeb14738250f299';

/// Application-layer LookupMerchantUseCase provider.
///
/// Copied from [lookupMerchantUseCase].
@ProviderFor(lookupMerchantUseCase)
final lookupMerchantUseCaseProvider =
    AutoDisposeProvider<LookupMerchantUseCase>.internal(
      lookupMerchantUseCase,
      name: r'lookupMerchantUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$lookupMerchantUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LookupMerchantUseCaseRef =
    AutoDisposeProviderRef<LookupMerchantUseCase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
