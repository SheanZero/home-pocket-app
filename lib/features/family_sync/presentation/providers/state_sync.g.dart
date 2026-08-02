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

String _$syncOrchestratorHash() => r'9a0a605de4c9224511fa06b030e3495e718c48c9';

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

String _$syncEngineHash() => r'7c532f4563a96b5b29c777f16308f1cfc64fd2af';

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

@ProviderFor(syncQueueSummary)
final syncQueueSummaryProvider = SyncQueueSummaryProvider._();

final class SyncQueueSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<SyncQueueSummary>,
          SyncQueueSummary,
          Stream<SyncQueueSummary>
        >
    with $FutureModifier<SyncQueueSummary>, $StreamProvider<SyncQueueSummary> {
  SyncQueueSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncQueueSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncQueueSummaryHash();

  @$internal
  @override
  $StreamProviderElement<SyncQueueSummary> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SyncQueueSummary> create(Ref ref) {
    return syncQueueSummary(ref);
  }
}

String _$syncQueueSummaryHash() => r'1fbe0be5c3cd7eb208c8ebb99569e5c821cd51fa';

@ProviderFor(inboundSyncSummary)
final inboundSyncSummaryProvider = InboundSyncSummaryProvider._();

final class InboundSyncSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<InboundSyncSummary>,
          InboundSyncSummary,
          Stream<InboundSyncSummary>
        >
    with
        $FutureModifier<InboundSyncSummary>,
        $StreamProvider<InboundSyncSummary> {
  InboundSyncSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboundSyncSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboundSyncSummaryHash();

  @$internal
  @override
  $StreamProviderElement<InboundSyncSummary> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<InboundSyncSummary> create(Ref ref) {
    return inboundSyncSummary(ref);
  }
}

String _$inboundSyncSummaryHash() =>
    r'aa7ff141bf221c384dbda4b6b1fa6942bb59ad54';

@ProviderFor(inboundSyncQuarantined)
final inboundSyncQuarantinedProvider = InboundSyncQuarantinedProvider._();

final class InboundSyncQuarantinedProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InboundSyncQuarantineEntry>>,
          List<InboundSyncQuarantineEntry>,
          Stream<List<InboundSyncQuarantineEntry>>
        >
    with
        $FutureModifier<List<InboundSyncQuarantineEntry>>,
        $StreamProvider<List<InboundSyncQuarantineEntry>> {
  InboundSyncQuarantinedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboundSyncQuarantinedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboundSyncQuarantinedHash();

  @$internal
  @override
  $StreamProviderElement<List<InboundSyncQuarantineEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<InboundSyncQuarantineEntry>> create(Ref ref) {
    return inboundSyncQuarantined(ref);
  }
}

String _$inboundSyncQuarantinedHash() =>
    r'35b5e78a88ac318891e3ee7c696c4cca7c272f6f';

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
