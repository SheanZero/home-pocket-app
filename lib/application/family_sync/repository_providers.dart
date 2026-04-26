import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/family_sync/domain/repositories/sync_repository.dart';
import '../../infrastructure/crypto/providers.dart' as crypto;
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/apns_push_messaging_client.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/push_notification_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import '../../infrastructure/sync/websocket_service.dart';

part 'repository_providers.g.dart';

// All providers prefixed with `app` to eliminate symbol collision with feature-side
// definitions during Wave 2/3 coexistence (per Warning 7 fix). Plan 04-02 Task 5
// deletes the original (non-prefixed) feature-side definitions once consumers migrate.

/// APNS push messaging client (iOS push notification delivery).
@riverpod
ApnsPushMessagingClient appApnsPushMessagingClient(Ref ref) {
  return ApnsPushMessagingClient();
}

/// Application-layer re-export of [KeyManager] for feature consumption.
///
/// Avoids two-hop import in features; all feature files that need
/// [KeyManager] import application/family_sync/repository_providers.dart.
@riverpod
KeyManager appKeyManager(Ref ref) {
  return ref.watch(crypto.keyManagerProvider);
}

/// E2EE encryption service (ChaCha20-Poly1305).
@riverpod
E2EEService appE2eeService(Ref ref) {
  final keyManager = ref.watch(appKeyManagerProvider);
  return E2EEService(keyManager: keyManager);
}

/// Relay API client for communicating with the group relay server.
@riverpod
RelayApiClient appRelayApiClient(Ref ref) {
  final keyManager = ref.watch(appKeyManagerProvider);
  final signer = RequestSigner(keyManager: keyManager);
  return RelayApiClient(baseUrl: RelayApiClient.defaultBaseUrl, signer: signer);
}

/// Push notification service (wraps APNS/FCM + local notifications).
@riverpod
PushNotificationService appPushNotificationService(Ref ref) {
  final apiClient = ref.watch(appRelayApiClientProvider);
  final service = PushNotificationService(
    apiClient: apiClient,
    messagingClient: Platform.isIOS
        ? ApnsPushMessagingClient()
        : FirebasePushMessagingClient(),
    firebaseInitializer: Platform.isIOS ? null : Firebase.initializeApp,
    pushPlatform: Platform.isIOS ? 'apns' : 'fcm',
  );
  ref.onDispose(service.dispose);
  return service;
}

/// SyncRepository holder — expects to be overridden by feature presentation.
///
/// Feature-side override in Plan 04-02:
/// `appSyncRepositoryProvider.overrideWith((ref) => ref.watch(syncRepositoryProvider))`
///
/// Mirrors the [appDatabaseProvider] pattern from infrastructure/security/providers.dart.
final appSyncRepositoryProvider = Provider<SyncRepository>(
  (_) => throw StateError(
    'appSyncRepositoryProvider not overridden. '
    'The feature presentation layer must override this provider. '
    'See Plan 04-02 for the override wiring.',
  ),
  name: 'appSyncRepositoryProvider',
);

/// Sync queue manager for offline sync operations.
///
/// Depends on [appSyncRepositoryProvider] (overridden by feature side in Plan 04-02)
/// and [appRelayApiClientProvider] (defined in this application-layer file).
@riverpod
SyncQueueManager appSyncQueueManager(Ref ref) {
  final syncRepo = ref.watch(appSyncRepositoryProvider);
  final apiClient = ref.watch(appRelayApiClientProvider);
  return SyncQueueManager(syncRepository: syncRepo, apiClient: apiClient);
}

/// WebSocket service for realtime group status notifications.
@riverpod
WebSocketService appWebSocketService(Ref ref) {
  final service = WebSocketService(baseUrl: RelayApiClient.wsBaseUrl);
  ref.onDispose(service.dispose);
  return service;
}
