// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionChangeTrackerHash() =>
    r'bb8c0d635d1ac2f56fb060cfe714b679d99b00dd';

/// TransactionChangeTracker provider — keepAlive so tracker persists across screens.
///
/// Copied from [transactionChangeTracker].
@ProviderFor(transactionChangeTracker)
final transactionChangeTrackerProvider =
    Provider<TransactionChangeTracker>.internal(
      transactionChangeTracker,
      name: r'transactionChangeTrackerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$transactionChangeTrackerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TransactionChangeTrackerRef = ProviderRef<TransactionChangeTracker>;
String _$syncOrchestratorHash() => r'756a454762bc84c10e125588156461d195c462a6';

/// SyncOrchestrator provider.
///
/// Placed in state_sync.dart rather than repository_providers.dart to avoid
/// circular dependency: syncOrchestrator needs transactionChangeTrackerProvider
/// (defined here) while syncEngine (also here) needs syncOrchestratorProvider.
///
/// Copied from [syncOrchestrator].
@ProviderFor(syncOrchestrator)
final syncOrchestratorProvider = AutoDisposeProvider<SyncOrchestrator>.internal(
  syncOrchestrator,
  name: r'syncOrchestratorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncOrchestratorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncOrchestratorRef = AutoDisposeProviderRef<SyncOrchestrator>;
String _$syncEngineHash() => r'78d7b9c1ee757d6bf61b8cd98725b8de6185b1de';

/// SyncEngine provider — keepAlive because it manages timers and lifecycle.
///
/// Copied from [syncEngine].
@ProviderFor(syncEngine)
final syncEngineProvider = Provider<SyncEngine>.internal(
  syncEngine,
  name: r'syncEngineProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncEngineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncEngineRef = ProviderRef<SyncEngine>;
String _$syncStatusStreamHash() => r'945e9929ecb8b7ec953a4d79382645a9b8a19e4a';

/// Reactive sync status stream from SyncEngine.
///
/// Copied from [syncStatusStream].
@ProviderFor(syncStatusStream)
final syncStatusStreamProvider =
    AutoDisposeStreamProvider<model.SyncStatus>.internal(
      syncStatusStream,
      name: r'syncStatusStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$syncStatusStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncStatusStreamRef = AutoDisposeStreamProviderRef<model.SyncStatus>;
String _$activeGroupMembersHash() =>
    r'9079bb910adb2d30851248cf7846507d6b39b5be';

/// GroupMembers stream via Drift watch query, mapped to domain model.
///
/// Kept alive because this stream is long-lived and must not lose subscription
/// state on tab switches. The name reflects that this stream observes
/// [activeGroupProvider] (only members of the currently active group).
///
/// Copied from [activeGroupMembers].
@ProviderFor(activeGroupMembers)
final activeGroupMembersProvider = StreamProvider<List<GroupMember>>.internal(
  activeGroupMembers,
  name: r'activeGroupMembersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeGroupMembersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveGroupMembersRef = StreamProviderRef<List<GroupMember>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
