import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/daos/group_dao.dart';
import '../../../../data/daos/group_member_dao.dart';
import '../../../../data/daos/paired_device_dao.dart';
import '../../../../data/daos/sync_queue_dao.dart';
import '../../../../data/repositories/group_repository_impl.dart';
import '../../../../data/repositories/pair_repository_impl.dart';
import '../../../../data/repositories/sync_repository_impl.dart';
import '../../../../infrastructure/crypto/providers.dart';
import '../../../../infrastructure/security/providers.dart';
import '../../../../infrastructure/sync/e2ee_service.dart';
import '../../../../infrastructure/sync/push_notification_service.dart';
import '../../../../infrastructure/sync/relay_api_client.dart';
import '../../../../infrastructure/sync/sync_queue_manager.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/repositories/pair_repository.dart';
import '../../domain/repositories/sync_repository.dart';

part 'repository_providers.g.dart';

/// PairRepository provider.
@riverpod
PairRepository pairRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = PairedDeviceDao(database);
  return PairRepositoryImpl(dao: dao);
}

/// GroupRepository provider.
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return GroupRepositoryImpl(
    groupDao: GroupDao(database),
    memberDao: GroupMemberDao(database),
  );
});

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
  return PushNotificationService(apiClient: apiClient);
}
