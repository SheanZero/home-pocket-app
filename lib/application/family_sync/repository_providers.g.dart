// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appApnsPushMessagingClientHash() =>
    r'825d39f5bcdff697ec728703e04e3eee9be10f12';

/// APNS push messaging client (iOS push notification delivery).
///
/// Copied from [appApnsPushMessagingClient].
@ProviderFor(appApnsPushMessagingClient)
final appApnsPushMessagingClientProvider =
    AutoDisposeProvider<ApnsPushMessagingClient>.internal(
      appApnsPushMessagingClient,
      name: r'appApnsPushMessagingClientProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appApnsPushMessagingClientHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppApnsPushMessagingClientRef =
    AutoDisposeProviderRef<ApnsPushMessagingClient>;
String _$appKeyManagerHash() => r'7b966b214841d1660d895e3b0836417191a65671';

/// Application-layer re-export of [KeyManager] for feature consumption.
///
/// Avoids two-hop import in features; all feature files that need
/// [KeyManager] import application/family_sync/repository_providers.dart.
///
/// Copied from [appKeyManager].
@ProviderFor(appKeyManager)
final appKeyManagerProvider = AutoDisposeProvider<KeyManager>.internal(
  appKeyManager,
  name: r'appKeyManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appKeyManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppKeyManagerRef = AutoDisposeProviderRef<KeyManager>;
String _$appE2eeServiceHash() => r'9abe142d16442945a48d4eaf2255af5d751fe6b4';

/// E2EE encryption service (ChaCha20-Poly1305).
///
/// Copied from [appE2eeService].
@ProviderFor(appE2eeService)
final appE2eeServiceProvider = AutoDisposeProvider<E2EEService>.internal(
  appE2eeService,
  name: r'appE2eeServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appE2eeServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppE2eeServiceRef = AutoDisposeProviderRef<E2EEService>;
String _$appRelayApiClientHash() => r'83abf60e41473349c74dc45cffd7669f464667ac';

/// Relay API client for communicating with the group relay server.
///
/// Copied from [appRelayApiClient].
@ProviderFor(appRelayApiClient)
final appRelayApiClientProvider = AutoDisposeProvider<RelayApiClient>.internal(
  appRelayApiClient,
  name: r'appRelayApiClientProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appRelayApiClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppRelayApiClientRef = AutoDisposeProviderRef<RelayApiClient>;
String _$appPushNotificationServiceHash() =>
    r'8190c01e2726875d218a3700c202651a2cd14f4a';

/// Push notification service (wraps APNS/FCM + local notifications).
///
/// Copied from [appPushNotificationService].
@ProviderFor(appPushNotificationService)
final appPushNotificationServiceProvider =
    AutoDisposeProvider<PushNotificationService>.internal(
      appPushNotificationService,
      name: r'appPushNotificationServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appPushNotificationServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppPushNotificationServiceRef =
    AutoDisposeProviderRef<PushNotificationService>;
String _$appSyncQueueManagerHash() =>
    r'2487f5c78c2485df2084322a148775a5086517ad';

/// Sync queue manager for offline sync operations.
///
/// Depends on [appSyncRepositoryProvider] (overridden by feature side in Plan 04-02)
/// and [appRelayApiClientProvider] (defined in this application-layer file).
///
/// Copied from [appSyncQueueManager].
@ProviderFor(appSyncQueueManager)
final appSyncQueueManagerProvider =
    AutoDisposeProvider<SyncQueueManager>.internal(
      appSyncQueueManager,
      name: r'appSyncQueueManagerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appSyncQueueManagerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppSyncQueueManagerRef = AutoDisposeProviderRef<SyncQueueManager>;
String _$appWebSocketServiceHash() =>
    r'7497bd82181071abffc7c4d5aa5c6d532a00e979';

/// WebSocket service for realtime group status notifications.
///
/// Copied from [appWebSocketService].
@ProviderFor(appWebSocketService)
final appWebSocketServiceProvider =
    AutoDisposeProvider<WebSocketService>.internal(
      appWebSocketService,
      name: r'appWebSocketServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appWebSocketServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppWebSocketServiceRef = AutoDisposeProviderRef<WebSocketService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
