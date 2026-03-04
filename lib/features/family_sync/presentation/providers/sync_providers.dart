import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/family_sync/full_sync_use_case.dart';
import '../../../../application/family_sync/pull_sync_use_case.dart';
import '../../../../application/family_sync/push_sync_use_case.dart';
import '../../../../infrastructure/crypto/providers.dart';
import '../../../../infrastructure/sync/sync_trigger_service.dart';
import '../../domain/models/sync_status.dart';
import 'repository_providers.dart';

part 'sync_providers.g.dart';

/// PushSyncUseCase provider.
@riverpod
PushSyncUseCase pushSyncUseCase(Ref ref) {
  return PushSyncUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
    groupRepo: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
  );
}

/// PullSyncUseCase provider.
@riverpod
PullSyncUseCase pullSyncUseCase(Ref ref) {
  return PullSyncUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
    groupRepo: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    keyManager: ref.watch(keyManagerProvider),
    applyOperations: (operations) async {
      // TODO: Wire up to CRDT apply logic when available
    },
  );
}

/// FullSyncUseCase provider.
@riverpod
FullSyncUseCase fullSyncUseCase(Ref ref) {
  return FullSyncUseCase(
    pushSync: ref.watch(pushSyncUseCaseProvider),
    fetchAllTransactions: (bookId) async {
      // TODO: Wire up to transaction repository when available
      return [];
    },
  );
}

/// SyncTriggerService provider.
///
/// Coordinates sync triggers from lifecycle, transaction changes,
/// and push notifications. Call `initialize()` once at app startup.
@riverpod
SyncTriggerService syncTriggerService(Ref ref) {
  final service = SyncTriggerService(
    groupRepo: ref.watch(groupRepositoryProvider),
    pullSync: ref.watch(pullSyncUseCaseProvider),
    pushSync: ref.watch(pushSyncUseCaseProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    keyManager: ref.watch(keyManagerProvider),
    relayApiClient: ref.watch(relayApiClientProvider),
    pushNotificationService: ref.watch(pushNotificationServiceProvider),
  );

  ref.onDispose(service.dispose);

  return service;
}

/// Current sync status state notifier.
@riverpod
class SyncStatusNotifier extends _$SyncStatusNotifier {
  @override
  SyncStatus build() => SyncStatus.unpaired;

  void updateStatus(SyncStatus status) {
    state = status;
  }
}
