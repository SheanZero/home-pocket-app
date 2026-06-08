// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// TransactionChangeTracker provider — keepAlive so tracker persists across screens.

@ProviderFor(transactionChangeTracker)
final transactionChangeTrackerProvider = TransactionChangeTrackerProvider._();

/// TransactionChangeTracker provider — keepAlive so tracker persists across screens.

final class TransactionChangeTrackerProvider
    extends
        $FunctionalProvider<
          TransactionChangeTracker,
          TransactionChangeTracker,
          TransactionChangeTracker
        >
    with $Provider<TransactionChangeTracker> {
  /// TransactionChangeTracker provider — keepAlive so tracker persists across screens.
  TransactionChangeTrackerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionChangeTrackerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionChangeTrackerHash();

  @$internal
  @override
  $ProviderElement<TransactionChangeTracker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransactionChangeTracker create(Ref ref) {
    return transactionChangeTracker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionChangeTracker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionChangeTracker>(value),
    );
  }
}

String _$transactionChangeTrackerHash() =>
    r'bb8c0d635d1ac2f56fb060cfe714b679d99b00dd';

/// ShoppingItemChangeTracker provider — keepAlive so tracker persists across screens.
///
/// Mirrors [transactionChangeTrackerProvider]. Used by [SyncOrchestrator] to flush
/// pending shopping item operations during incrementalPush (SC-3, SYNC-01).

@ProviderFor(shoppingItemChangeTracker)
final shoppingItemChangeTrackerProvider = ShoppingItemChangeTrackerProvider._();

/// ShoppingItemChangeTracker provider — keepAlive so tracker persists across screens.
///
/// Mirrors [transactionChangeTrackerProvider]. Used by [SyncOrchestrator] to flush
/// pending shopping item operations during incrementalPush (SC-3, SYNC-01).

final class ShoppingItemChangeTrackerProvider
    extends
        $FunctionalProvider<
          ShoppingItemChangeTracker,
          ShoppingItemChangeTracker,
          ShoppingItemChangeTracker
        >
    with $Provider<ShoppingItemChangeTracker> {
  /// ShoppingItemChangeTracker provider — keepAlive so tracker persists across screens.
  ///
  /// Mirrors [transactionChangeTrackerProvider]. Used by [SyncOrchestrator] to flush
  /// pending shopping item operations during incrementalPush (SC-3, SYNC-01).
  ShoppingItemChangeTrackerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingItemChangeTrackerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingItemChangeTrackerHash();

  @$internal
  @override
  $ProviderElement<ShoppingItemChangeTracker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShoppingItemChangeTracker create(Ref ref) {
    return shoppingItemChangeTracker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingItemChangeTracker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingItemChangeTracker>(value),
    );
  }
}

String _$shoppingItemChangeTrackerHash() =>
    r'776c3905408ac2d3426733710420881b221be1c2';

/// SyncOrchestrator provider.
///
/// Placed in state_sync.dart rather than repository_providers.dart to avoid
/// circular dependency: syncOrchestrator needs transactionChangeTrackerProvider
/// (defined here) while syncEngine (also here) needs syncOrchestratorProvider.

@ProviderFor(syncOrchestrator)
final syncOrchestratorProvider = SyncOrchestratorProvider._();

/// SyncOrchestrator provider.
///
/// Placed in state_sync.dart rather than repository_providers.dart to avoid
/// circular dependency: syncOrchestrator needs transactionChangeTrackerProvider
/// (defined here) while syncEngine (also here) needs syncOrchestratorProvider.

final class SyncOrchestratorProvider
    extends
        $FunctionalProvider<
          SyncOrchestrator,
          SyncOrchestrator,
          SyncOrchestrator
        >
    with $Provider<SyncOrchestrator> {
  /// SyncOrchestrator provider.
  ///
  /// Placed in state_sync.dart rather than repository_providers.dart to avoid
  /// circular dependency: syncOrchestrator needs transactionChangeTrackerProvider
  /// (defined here) while syncEngine (also here) needs syncOrchestratorProvider.
  SyncOrchestratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncOrchestratorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncOrchestratorHash();

  @$internal
  @override
  $ProviderElement<SyncOrchestrator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncOrchestrator create(Ref ref) {
    return syncOrchestrator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncOrchestrator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncOrchestrator>(value),
    );
  }
}

String _$syncOrchestratorHash() => r'724e1396b840476444bb9d90ca9d6e2375216931';

/// SyncEngine provider — keepAlive because it manages timers and lifecycle.

@ProviderFor(syncEngine)
final syncEngineProvider = SyncEngineProvider._();

/// SyncEngine provider — keepAlive because it manages timers and lifecycle.

final class SyncEngineProvider
    extends $FunctionalProvider<SyncEngine, SyncEngine, SyncEngine>
    with $Provider<SyncEngine> {
  /// SyncEngine provider — keepAlive because it manages timers and lifecycle.
  SyncEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncEngineHash();

  @$internal
  @override
  $ProviderElement<SyncEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncEngine create(Ref ref) {
    return syncEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncEngine>(value),
    );
  }
}

String _$syncEngineHash() => r'78d7b9c1ee757d6bf61b8cd98725b8de6185b1de';

/// Reactive sync status stream from SyncEngine.

@ProviderFor(syncStatusStream)
final syncStatusStreamProvider = SyncStatusStreamProvider._();

/// Reactive sync status stream from SyncEngine.

final class SyncStatusStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<model.SyncStatus>,
          model.SyncStatus,
          Stream<model.SyncStatus>
        >
    with $FutureModifier<model.SyncStatus>, $StreamProvider<model.SyncStatus> {
  /// Reactive sync status stream from SyncEngine.
  SyncStatusStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncStatusStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncStatusStreamHash();

  @$internal
  @override
  $StreamProviderElement<model.SyncStatus> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<model.SyncStatus> create(Ref ref) {
    return syncStatusStream(ref);
  }
}

String _$syncStatusStreamHash() => r'945e9929ecb8b7ec953a4d79382645a9b8a19e4a';

/// GroupMembers stream via Drift watch query, mapped to domain model.
///
/// Kept alive because this stream is long-lived and must not lose subscription
/// state on tab switches. The name reflects that this stream observes
/// [activeGroupProvider] (only members of the currently active group).

@ProviderFor(activeGroupMembers)
final activeGroupMembersProvider = ActiveGroupMembersProvider._();

/// GroupMembers stream via Drift watch query, mapped to domain model.
///
/// Kept alive because this stream is long-lived and must not lose subscription
/// state on tab switches. The name reflects that this stream observes
/// [activeGroupProvider] (only members of the currently active group).

final class ActiveGroupMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupMember>>,
          List<GroupMember>,
          Stream<List<GroupMember>>
        >
    with
        $FutureModifier<List<GroupMember>>,
        $StreamProvider<List<GroupMember>> {
  /// GroupMembers stream via Drift watch query, mapped to domain model.
  ///
  /// Kept alive because this stream is long-lived and must not lose subscription
  /// state on tab switches. The name reflects that this stream observes
  /// [activeGroupProvider] (only members of the currently active group).
  ActiveGroupMembersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeGroupMembersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeGroupMembersHash();

  @$internal
  @override
  $StreamProviderElement<List<GroupMember>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GroupMember>> create(Ref ref) {
    return activeGroupMembers(ref);
  }
}

String _$activeGroupMembersHash() =>
    r'44311113efa0297fa7f48963ec955e4618fb9568';
