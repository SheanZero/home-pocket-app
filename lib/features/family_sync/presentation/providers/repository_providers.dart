import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/daos/group_dao.dart';
import '../../../../data/daos/group_member_dao.dart';
import '../../../../data/daos/sync_queue_dao.dart';
import '../../../../data/repositories/group_repository_impl.dart';
import '../../../../data/repositories/sync_repository_impl.dart';
import '../../../../infrastructure/crypto/providers.dart';
import '../../../../infrastructure/security/providers.dart';
import '../../../../infrastructure/sync/apns_push_messaging_client.dart';
import '../../../../infrastructure/sync/e2ee_service.dart';
import '../../../../infrastructure/sync/push_notification_service.dart';
import '../../../../infrastructure/sync/relay_api_client.dart';
import '../../../../infrastructure/sync/sync_queue_manager.dart';
import '../../../../infrastructure/sync/websocket_service.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/repositories/sync_repository.dart';

part 'repository_providers.g.dart';

/// GroupMemberDao provider (for watch queries).
@riverpod
GroupMemberDao groupMemberDao(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return GroupMemberDao(database);
}

/// GroupRepository provider.
@riverpod
GroupRepository groupRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return GroupRepositoryImpl(
    groupDao: GroupDao(database),
    memberDao: GroupMemberDao(database),
  );
}

/// SyncRepository provider.
@riverpod
SyncRepository syncRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = SyncQueueDao(database);
  return SyncRepositoryImpl(dao: dao);
}

/// RequestSigner provider.
@riverpod
RequestSigner requestSigner(Ref ref) {
  final keyManager = ref.watch(keyManagerProvider);
  return RequestSigner(keyManager: keyManager);
}

/// RelayApiClient provider.
@riverpod
RelayApiClient relayApiClient(Ref ref) {
  final signer = ref.watch(requestSignerProvider);
  return RelayApiClient(baseUrl: RelayApiClient.defaultBaseUrl, signer: signer);
}

/// E2EEService provider.
@riverpod
E2EEService e2eeService(Ref ref) {
  final keyManager = ref.watch(keyManagerProvider);
  return E2EEService(keyManager: keyManager);
}

/// SyncQueueManager provider.
@riverpod
SyncQueueManager syncQueueManager(Ref ref) {
  final syncRepo = ref.watch(syncRepositoryProvider);
  final apiClient = ref.watch(relayApiClientProvider);
  return SyncQueueManager(syncRepository: syncRepo, apiClient: apiClient);
}

/// PushNotificationService provider.
@riverpod
PushNotificationService pushNotificationService(Ref ref) {
  final apiClient = ref.watch(relayApiClientProvider);
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

/// WebSocketService provider for realtime group status notifications.
///
/// Defined manually (not @riverpod) to support .overrideWithValue() in tests.
/// On-demand — screens connect/disconnect as needed.
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService(baseUrl: RelayApiClient.wsBaseUrl);
  ref.onDispose(service.dispose);
  return service;
});
