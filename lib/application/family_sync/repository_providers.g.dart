// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Application-layer re-export of [KeyManager] for feature consumption.
///
/// Avoids two-hop import in features; all feature files that need
/// [KeyManager] import application/family_sync/repository_providers.dart.

@ProviderFor(appKeyManager)
final appKeyManagerProvider = AppKeyManagerProvider._();

/// Application-layer re-export of [KeyManager] for feature consumption.
///
/// Avoids two-hop import in features; all feature files that need
/// [KeyManager] import application/family_sync/repository_providers.dart.

final class AppKeyManagerProvider
    extends $FunctionalProvider<KeyManager, KeyManager, KeyManager>
    with $Provider<KeyManager> {
  /// Application-layer re-export of [KeyManager] for feature consumption.
  ///
  /// Avoids two-hop import in features; all feature files that need
  /// [KeyManager] import application/family_sync/repository_providers.dart.
  AppKeyManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appKeyManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appKeyManagerHash();

  @$internal
  @override
  $ProviderElement<KeyManager> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KeyManager create(Ref ref) {
    return appKeyManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KeyManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KeyManager>(value),
    );
  }
}

String _$appKeyManagerHash() => r'7b966b214841d1660d895e3b0836417191a65671';

/// E2EE encryption service (ChaCha20-Poly1305).

@ProviderFor(appE2eeService)
final appE2eeServiceProvider = AppE2eeServiceProvider._();

/// E2EE encryption service (ChaCha20-Poly1305).

final class AppE2eeServiceProvider
    extends $FunctionalProvider<E2EEService, E2EEService, E2EEService>
    with $Provider<E2EEService> {
  /// E2EE encryption service (ChaCha20-Poly1305).
  AppE2eeServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appE2eeServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appE2eeServiceHash();

  @$internal
  @override
  $ProviderElement<E2EEService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  E2EEService create(Ref ref) {
    return appE2eeService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(E2EEService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<E2EEService>(value),
    );
  }
}

String _$appE2eeServiceHash() => r'9abe142d16442945a48d4eaf2255af5d751fe6b4';

/// Relay API client for communicating with the group relay server.

@ProviderFor(appRelayApiClient)
final appRelayApiClientProvider = AppRelayApiClientProvider._();

/// Relay API client for communicating with the group relay server.

final class AppRelayApiClientProvider
    extends $FunctionalProvider<RelayApiClient, RelayApiClient, RelayApiClient>
    with $Provider<RelayApiClient> {
  /// Relay API client for communicating with the group relay server.
  AppRelayApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRelayApiClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRelayApiClientHash();

  @$internal
  @override
  $ProviderElement<RelayApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RelayApiClient create(Ref ref) {
    return appRelayApiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RelayApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RelayApiClient>(value),
    );
  }
}

String _$appRelayApiClientHash() => r'83abf60e41473349c74dc45cffd7669f464667ac';

/// Sync queue manager for offline sync operations.
///
/// Depends on [appSyncRepositoryProvider] (overridden by feature side in Plan 04-02)
/// and [appRelayApiClientProvider] (defined in this application-layer file).

@ProviderFor(appSyncQueueManager)
final appSyncQueueManagerProvider = AppSyncQueueManagerProvider._();

/// Sync queue manager for offline sync operations.
///
/// Depends on [appSyncRepositoryProvider] (overridden by feature side in Plan 04-02)
/// and [appRelayApiClientProvider] (defined in this application-layer file).

final class AppSyncQueueManagerProvider
    extends
        $FunctionalProvider<
          SyncQueueManager,
          SyncQueueManager,
          SyncQueueManager
        >
    with $Provider<SyncQueueManager> {
  /// Sync queue manager for offline sync operations.
  ///
  /// Depends on [appSyncRepositoryProvider] (overridden by feature side in Plan 04-02)
  /// and [appRelayApiClientProvider] (defined in this application-layer file).
  AppSyncQueueManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSyncQueueManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSyncQueueManagerHash();

  @$internal
  @override
  $ProviderElement<SyncQueueManager> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncQueueManager create(Ref ref) {
    return appSyncQueueManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncQueueManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncQueueManager>(value),
    );
  }
}

String _$appSyncQueueManagerHash() =>
    r'2487f5c78c2485df2084322a148775a5086517ad';

/// WebSocket service for realtime group status notifications.

@ProviderFor(appWebSocketService)
final appWebSocketServiceProvider = AppWebSocketServiceProvider._();

/// WebSocket service for realtime group status notifications.

final class AppWebSocketServiceProvider
    extends
        $FunctionalProvider<
          WebSocketService,
          WebSocketService,
          WebSocketService
        >
    with $Provider<WebSocketService> {
  /// WebSocket service for realtime group status notifications.
  AppWebSocketServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appWebSocketServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appWebSocketServiceHash();

  @$internal
  @override
  $ProviderElement<WebSocketService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WebSocketService create(Ref ref) {
    return appWebSocketService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebSocketService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebSocketService>(value),
    );
  }
}

String _$appWebSocketServiceHash() =>
    r'7497bd82181071abffc7c4d5aa5c6d532a00e979';

/// NotifyMemberApprovalUseCase provider — wraps WebSocket management for the
/// member approval screen so it no longer imports infrastructure/ directly.

@ProviderFor(notifyMemberApprovalUseCase)
final notifyMemberApprovalUseCaseProvider =
    NotifyMemberApprovalUseCaseProvider._();

/// NotifyMemberApprovalUseCase provider — wraps WebSocket management for the
/// member approval screen so it no longer imports infrastructure/ directly.

final class NotifyMemberApprovalUseCaseProvider
    extends
        $FunctionalProvider<
          NotifyMemberApprovalUseCase,
          NotifyMemberApprovalUseCase,
          NotifyMemberApprovalUseCase
        >
    with $Provider<NotifyMemberApprovalUseCase> {
  /// NotifyMemberApprovalUseCase provider — wraps WebSocket management for the
  /// member approval screen so it no longer imports infrastructure/ directly.
  NotifyMemberApprovalUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notifyMemberApprovalUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notifyMemberApprovalUseCaseHash();

  @$internal
  @override
  $ProviderElement<NotifyMemberApprovalUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotifyMemberApprovalUseCase create(Ref ref) {
    return notifyMemberApprovalUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotifyMemberApprovalUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotifyMemberApprovalUseCase>(value),
    );
  }
}

String _$notifyMemberApprovalUseCaseHash() =>
    r'fb923c6de3d1d68551db66e764780a822d4adb21';
