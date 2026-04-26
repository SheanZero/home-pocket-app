// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$syncQueueManagerHash() => r'11b36bb04566f9cf578bb344c8ed7d2e5d50bee7';

/// SyncQueueManager — built from local SyncRepository + application-layer relay client.
///
/// Uses local [syncRepositoryProvider] because the sync repository depends on
/// the local database (not hoisted to application layer in Plan 04-01).
///
/// Copied from [syncQueueManager].
@ProviderFor(syncQueueManager)
final syncQueueManagerProvider = AutoDisposeProvider<SyncQueueManager>.internal(
  syncQueueManager,
  name: r'syncQueueManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncQueueManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncQueueManagerRef = AutoDisposeProviderRef<SyncQueueManager>;
String _$groupMemberDaoHash() => r'6989259a9bfda657d34856faf7005a3034085357';

/// GroupMemberDao provider (for watch queries).
///
/// Copied from [groupMemberDao].
@ProviderFor(groupMemberDao)
final groupMemberDaoProvider = AutoDisposeProvider<GroupMemberDao>.internal(
  groupMemberDao,
  name: r'groupMemberDaoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupMemberDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GroupMemberDaoRef = AutoDisposeProviderRef<GroupMemberDao>;
String _$groupRepositoryHash() => r'bc4b839f1664f4f6d7488befc92cbdb98796772c';

/// GroupRepository provider.
///
/// Copied from [groupRepository].
@ProviderFor(groupRepository)
final groupRepositoryProvider = AutoDisposeProvider<GroupRepository>.internal(
  groupRepository,
  name: r'groupRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GroupRepositoryRef = AutoDisposeProviderRef<GroupRepository>;
String _$syncRepositoryHash() => r'8e6fb815dcb2d21942af3d5b83169966d52f85ef';

/// SyncRepository provider.
///
/// Copied from [syncRepository].
@ProviderFor(syncRepository)
final syncRepositoryProvider = AutoDisposeProvider<SyncRepository>.internal(
  syncRepository,
  name: r'syncRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncRepositoryRef = AutoDisposeProviderRef<SyncRepository>;
String _$shadowBookServiceHash() => r'1005597152b5fd1c45b2443aed006e95f24ee3db';

/// ShadowBookService provider.
///
/// Copied from [shadowBookService].
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
    r'29da0bc6a10c3bd6960c4eec6769cd0058052e57';

/// ApplySyncOperationsUseCase provider.
///
/// Copied from [applySyncOperationsUseCase].
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
String _$checkGroupValidityUseCaseHash() =>
    r'32e79f4bdac976f47d84c288953ae3d3e2f145df';

/// CheckGroupValidityUseCase provider.
///
/// Copied from [checkGroupValidityUseCase].
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
String _$fullSyncUseCaseHash() => r'803e3bb92b8f6fe43e2f5ed791771a7bb74d5613';

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
String _$handleMemberLeftUseCaseHash() =>
    r'f505f07a7e915fbac6cbabe178b71e7527147c58';

/// HandleMemberLeftUseCase provider.
///
/// Copied from [handleMemberLeftUseCase].
@ProviderFor(handleMemberLeftUseCase)
final handleMemberLeftUseCaseProvider =
    AutoDisposeProvider<HandleMemberLeftUseCase>.internal(
      handleMemberLeftUseCase,
      name: r'handleMemberLeftUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$handleMemberLeftUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HandleMemberLeftUseCaseRef =
    AutoDisposeProviderRef<HandleMemberLeftUseCase>;
String _$handleGroupDissolvedUseCaseHash() =>
    r'7e9bf7d7954934cd0d7949c1ec48c0fea232e627';

/// HandleGroupDissolvedUseCase provider.
///
/// Copied from [handleGroupDissolvedUseCase].
@ProviderFor(handleGroupDissolvedUseCase)
final handleGroupDissolvedUseCaseProvider =
    AutoDisposeProvider<HandleGroupDissolvedUseCase>.internal(
      handleGroupDissolvedUseCase,
      name: r'handleGroupDissolvedUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$handleGroupDissolvedUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HandleGroupDissolvedUseCaseRef =
    AutoDisposeProviderRef<HandleGroupDissolvedUseCase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
