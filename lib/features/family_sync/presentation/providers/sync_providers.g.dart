// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pushSyncUseCaseHash() => r'c3687aa735b9f850948af61f5615365e2832041d';

/// PushSyncUseCase provider.
///
/// Copied from [pushSyncUseCase].
@ProviderFor(pushSyncUseCase)
final pushSyncUseCaseProvider = AutoDisposeProvider<PushSyncUseCase>.internal(
  pushSyncUseCase,
  name: r'pushSyncUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pushSyncUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PushSyncUseCaseRef = AutoDisposeProviderRef<PushSyncUseCase>;
String _$pullSyncUseCaseHash() => r'340b68e055287df5a271a943bb2d722077e76769';

/// PullSyncUseCase provider.
///
/// Copied from [pullSyncUseCase].
@ProviderFor(pullSyncUseCase)
final pullSyncUseCaseProvider = AutoDisposeProvider<PullSyncUseCase>.internal(
  pullSyncUseCase,
  name: r'pullSyncUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pullSyncUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PullSyncUseCaseRef = AutoDisposeProviderRef<PullSyncUseCase>;
String _$shadowBookServiceHash() => r'1005597152b5fd1c45b2443aed006e95f24ee3db';

/// See also [shadowBookService].
@ProviderFor(shadowBookService)
final shadowBookServiceProvider =
    AutoDisposeProvider<ShadowBookService>.internal(
      shadowBookService,
      name: r'shadowBookServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$shadowBookServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShadowBookServiceRef = AutoDisposeProviderRef<ShadowBookService>;
String _$applySyncOperationsUseCaseHash() =>
    r'c61325a3aa42d96bd201567629d381bdec8df779';

/// See also [applySyncOperationsUseCase].
@ProviderFor(applySyncOperationsUseCase)
final applySyncOperationsUseCaseProvider =
    AutoDisposeProvider<ApplySyncOperationsUseCase>.internal(
      applySyncOperationsUseCase,
      name: r'applySyncOperationsUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$applySyncOperationsUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ApplySyncOperationsUseCaseRef =
    AutoDisposeProviderRef<ApplySyncOperationsUseCase>;
String _$checkGroupValidityUseCaseHash() =>
    r'32e79f4bdac976f47d84c288953ae3d3e2f145df';

/// See also [checkGroupValidityUseCase].
@ProviderFor(checkGroupValidityUseCase)
final checkGroupValidityUseCaseProvider =
    AutoDisposeProvider<CheckGroupValidityUseCase>.internal(
      checkGroupValidityUseCase,
      name: r'checkGroupValidityUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$checkGroupValidityUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CheckGroupValidityUseCaseRef =
    AutoDisposeProviderRef<CheckGroupValidityUseCase>;
String _$fullSyncUseCaseHash() => r'ed156bd13ad45bcaddbcc586a60f12ca1555d13a';

/// FullSyncUseCase provider.
///
/// Copied from [fullSyncUseCase].
@ProviderFor(fullSyncUseCase)
final fullSyncUseCaseProvider = AutoDisposeProvider<FullSyncUseCase>.internal(
  fullSyncUseCase,
  name: r'fullSyncUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fullSyncUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FullSyncUseCaseRef = AutoDisposeProviderRef<FullSyncUseCase>;
String _$syncTriggerServiceHash() =>
    r'bf36a16f7ee9020257c6895165630b9819c0edf2';

/// SyncTriggerService provider.
///
/// Coordinates sync triggers from lifecycle, transaction changes,
/// and push notifications. Call `initialize()` once at app startup.
///
/// Copied from [syncTriggerService].
@ProviderFor(syncTriggerService)
final syncTriggerServiceProvider =
    AutoDisposeProvider<SyncTriggerService>.internal(
      syncTriggerService,
      name: r'syncTriggerServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$syncTriggerServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncTriggerServiceRef = AutoDisposeProviderRef<SyncTriggerService>;
String _$syncStatusNotifierHash() =>
    r'c29fe5885a9a8544c419b3fc63bb1df78b75c08d';

/// Current sync status state notifier.
///
/// Uses [ref.container.listen] instead of [ref.watch] on [activeGroupProvider]
/// to avoid full rebuild on every stream emission, which would reset transient
/// states (syncing, offline, syncError) back to synced/unpaired. We only react
/// to membership transitions (null <-> non-null).
///
/// Copied from [SyncStatusNotifier].
@ProviderFor(SyncStatusNotifier)
final syncStatusNotifierProvider =
    AutoDisposeNotifierProvider<SyncStatusNotifier, SyncStatus>.internal(
      SyncStatusNotifier.new,
      name: r'syncStatusNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$syncStatusNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SyncStatusNotifier = AutoDisposeNotifier<SyncStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
