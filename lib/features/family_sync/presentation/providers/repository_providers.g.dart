// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SyncQueueManager — built from local SyncRepository + application-layer relay client.
///
/// Uses local [syncRepositoryProvider] because the sync repository depends on
/// the local database (not hoisted to application layer in Plan 04-01).

@ProviderFor(syncQueueManager)
final syncQueueManagerProvider = SyncQueueManagerProvider._();

/// SyncQueueManager — built from local SyncRepository + application-layer relay client.
///
/// Uses local [syncRepositoryProvider] because the sync repository depends on
/// the local database (not hoisted to application layer in Plan 04-01).

final class SyncQueueManagerProvider
    extends
        $FunctionalProvider<
          app_family_sync.SyncQueueManager,
          app_family_sync.SyncQueueManager,
          app_family_sync.SyncQueueManager
        >
    with $Provider<app_family_sync.SyncQueueManager> {
  /// SyncQueueManager — built from local SyncRepository + application-layer relay client.
  ///
  /// Uses local [syncRepositoryProvider] because the sync repository depends on
  /// the local database (not hoisted to application layer in Plan 04-01).
  SyncQueueManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncQueueManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncQueueManagerHash();

  @$internal
  @override
  $ProviderElement<app_family_sync.SyncQueueManager> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  app_family_sync.SyncQueueManager create(Ref ref) {
    return syncQueueManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(app_family_sync.SyncQueueManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<app_family_sync.SyncQueueManager>(
        value,
      ),
    );
  }
}

String _$syncQueueManagerHash() => r'11b36bb04566f9cf578bb344c8ed7d2e5d50bee7';

/// GroupMemberDao provider (for watch queries).

@ProviderFor(groupMemberDao)
final groupMemberDaoProvider = GroupMemberDaoProvider._();

/// GroupMemberDao provider (for watch queries).

final class GroupMemberDaoProvider
    extends $FunctionalProvider<GroupMemberDao, GroupMemberDao, GroupMemberDao>
    with $Provider<GroupMemberDao> {
  /// GroupMemberDao provider (for watch queries).
  GroupMemberDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupMemberDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupMemberDaoHash();

  @$internal
  @override
  $ProviderElement<GroupMemberDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GroupMemberDao create(Ref ref) {
    return groupMemberDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroupMemberDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroupMemberDao>(value),
    );
  }
}

String _$groupMemberDaoHash() => r'6989259a9bfda657d34856faf7005a3034085357';

/// GroupRepository provider.

@ProviderFor(groupRepository)
final groupRepositoryProvider = GroupRepositoryProvider._();

/// GroupRepository provider.

final class GroupRepositoryProvider
    extends
        $FunctionalProvider<GroupRepository, GroupRepository, GroupRepository>
    with $Provider<GroupRepository> {
  /// GroupRepository provider.
  GroupRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupRepositoryHash();

  @$internal
  @override
  $ProviderElement<GroupRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GroupRepository create(Ref ref) {
    return groupRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroupRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroupRepository>(value),
    );
  }
}

String _$groupRepositoryHash() => r'bc4b839f1664f4f6d7488befc92cbdb98796772c';

/// SyncRepository provider.

@ProviderFor(syncRepository)
final syncRepositoryProvider = SyncRepositoryProvider._();

/// SyncRepository provider.

final class SyncRepositoryProvider
    extends $FunctionalProvider<SyncRepository, SyncRepository, SyncRepository>
    with $Provider<SyncRepository> {
  /// SyncRepository provider.
  SyncRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncRepositoryHash();

  @$internal
  @override
  $ProviderElement<SyncRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncRepository create(Ref ref) {
    return syncRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncRepository>(value),
    );
  }
}

String _$syncRepositoryHash() => r'8e6fb815dcb2d21942af3d5b83169966d52f85ef';

/// ShadowBookService provider.

@ProviderFor(shadowBookService)
final shadowBookServiceProvider = ShadowBookServiceProvider._();

/// ShadowBookService provider.

final class ShadowBookServiceProvider
    extends
        $FunctionalProvider<
          ShadowBookService,
          ShadowBookService,
          ShadowBookService
        >
    with $Provider<ShadowBookService> {
  /// ShadowBookService provider.
  ShadowBookServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shadowBookServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shadowBookServiceHash();

  @$internal
  @override
  $ProviderElement<ShadowBookService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShadowBookService create(Ref ref) {
    return shadowBookService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShadowBookService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShadowBookService>(value),
    );
  }
}

String _$shadowBookServiceHash() => r'1005597152b5fd1c45b2443aed006e95f24ee3db';

/// ApplySyncOperationsUseCase provider.

@ProviderFor(applySyncOperationsUseCase)
final applySyncOperationsUseCaseProvider =
    ApplySyncOperationsUseCaseProvider._();

/// ApplySyncOperationsUseCase provider.

final class ApplySyncOperationsUseCaseProvider
    extends
        $FunctionalProvider<
          ApplySyncOperationsUseCase,
          ApplySyncOperationsUseCase,
          ApplySyncOperationsUseCase
        >
    with $Provider<ApplySyncOperationsUseCase> {
  /// ApplySyncOperationsUseCase provider.
  ApplySyncOperationsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'applySyncOperationsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$applySyncOperationsUseCaseHash();

  @$internal
  @override
  $ProviderElement<ApplySyncOperationsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ApplySyncOperationsUseCase create(Ref ref) {
    return applySyncOperationsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApplySyncOperationsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApplySyncOperationsUseCase>(value),
    );
  }
}

String _$applySyncOperationsUseCaseHash() =>
    r'0ceec58a183d481cf3d103b1f7986fb57da20daf';

/// PushSyncUseCase provider.

@ProviderFor(pushSyncUseCase)
final pushSyncUseCaseProvider = PushSyncUseCaseProvider._();

/// PushSyncUseCase provider.

final class PushSyncUseCaseProvider
    extends
        $FunctionalProvider<PushSyncUseCase, PushSyncUseCase, PushSyncUseCase>
    with $Provider<PushSyncUseCase> {
  /// PushSyncUseCase provider.
  PushSyncUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushSyncUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushSyncUseCaseHash();

  @$internal
  @override
  $ProviderElement<PushSyncUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PushSyncUseCase create(Ref ref) {
    return pushSyncUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushSyncUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushSyncUseCase>(value),
    );
  }
}

String _$pushSyncUseCaseHash() => r'c3687aa735b9f850948af61f5615365e2832041d';

/// PullSyncUseCase provider.

@ProviderFor(pullSyncUseCase)
final pullSyncUseCaseProvider = PullSyncUseCaseProvider._();

/// PullSyncUseCase provider.

final class PullSyncUseCaseProvider
    extends
        $FunctionalProvider<PullSyncUseCase, PullSyncUseCase, PullSyncUseCase>
    with $Provider<PullSyncUseCase> {
  /// PullSyncUseCase provider.
  PullSyncUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pullSyncUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pullSyncUseCaseHash();

  @$internal
  @override
  $ProviderElement<PullSyncUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PullSyncUseCase create(Ref ref) {
    return pullSyncUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PullSyncUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PullSyncUseCase>(value),
    );
  }
}

String _$pullSyncUseCaseHash() => r'340b68e055287df5a271a943bb2d722077e76769';

/// CheckGroupValidityUseCase provider.

@ProviderFor(checkGroupValidityUseCase)
final checkGroupValidityUseCaseProvider = CheckGroupValidityUseCaseProvider._();

/// CheckGroupValidityUseCase provider.

final class CheckGroupValidityUseCaseProvider
    extends
        $FunctionalProvider<
          CheckGroupValidityUseCase,
          CheckGroupValidityUseCase,
          CheckGroupValidityUseCase
        >
    with $Provider<CheckGroupValidityUseCase> {
  /// CheckGroupValidityUseCase provider.
  CheckGroupValidityUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkGroupValidityUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkGroupValidityUseCaseHash();

  @$internal
  @override
  $ProviderElement<CheckGroupValidityUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CheckGroupValidityUseCase create(Ref ref) {
    return checkGroupValidityUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckGroupValidityUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckGroupValidityUseCase>(value),
    );
  }
}

String _$checkGroupValidityUseCaseHash() =>
    r'32e79f4bdac976f47d84c288953ae3d3e2f145df';

/// FullSyncUseCase provider.

@ProviderFor(fullSyncUseCase)
final fullSyncUseCaseProvider = FullSyncUseCaseProvider._();

/// FullSyncUseCase provider.

final class FullSyncUseCaseProvider
    extends
        $FunctionalProvider<FullSyncUseCase, FullSyncUseCase, FullSyncUseCase>
    with $Provider<FullSyncUseCase> {
  /// FullSyncUseCase provider.
  FullSyncUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fullSyncUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fullSyncUseCaseHash();

  @$internal
  @override
  $ProviderElement<FullSyncUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FullSyncUseCase create(Ref ref) {
    return fullSyncUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FullSyncUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FullSyncUseCase>(value),
    );
  }
}

String _$fullSyncUseCaseHash() => r'5f7eb3a8f9f4badb4148f5902f4b4b03184ab22c';

/// HandleMemberLeftUseCase provider.

@ProviderFor(handleMemberLeftUseCase)
final handleMemberLeftUseCaseProvider = HandleMemberLeftUseCaseProvider._();

/// HandleMemberLeftUseCase provider.

final class HandleMemberLeftUseCaseProvider
    extends
        $FunctionalProvider<
          HandleMemberLeftUseCase,
          HandleMemberLeftUseCase,
          HandleMemberLeftUseCase
        >
    with $Provider<HandleMemberLeftUseCase> {
  /// HandleMemberLeftUseCase provider.
  HandleMemberLeftUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'handleMemberLeftUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$handleMemberLeftUseCaseHash();

  @$internal
  @override
  $ProviderElement<HandleMemberLeftUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HandleMemberLeftUseCase create(Ref ref) {
    return handleMemberLeftUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HandleMemberLeftUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HandleMemberLeftUseCase>(value),
    );
  }
}

String _$handleMemberLeftUseCaseHash() =>
    r'f505f07a7e915fbac6cbabe178b71e7527147c58';

/// HandleGroupDissolvedUseCase provider.

@ProviderFor(handleGroupDissolvedUseCase)
final handleGroupDissolvedUseCaseProvider =
    HandleGroupDissolvedUseCaseProvider._();

/// HandleGroupDissolvedUseCase provider.

final class HandleGroupDissolvedUseCaseProvider
    extends
        $FunctionalProvider<
          HandleGroupDissolvedUseCase,
          HandleGroupDissolvedUseCase,
          HandleGroupDissolvedUseCase
        >
    with $Provider<HandleGroupDissolvedUseCase> {
  /// HandleGroupDissolvedUseCase provider.
  HandleGroupDissolvedUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'handleGroupDissolvedUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$handleGroupDissolvedUseCaseHash();

  @$internal
  @override
  $ProviderElement<HandleGroupDissolvedUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HandleGroupDissolvedUseCase create(Ref ref) {
    return handleGroupDissolvedUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HandleGroupDissolvedUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HandleGroupDissolvedUseCase>(value),
    );
  }
}

String _$handleGroupDissolvedUseCaseHash() =>
    r'7e9bf7d7954934cd0d7949c1ec48c0fea232e627';
