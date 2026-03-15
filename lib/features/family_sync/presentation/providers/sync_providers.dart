import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/family_sync/full_sync_use_case.dart';
import '../../../../application/family_sync/pull_sync_use_case.dart';
import '../../../../application/family_sync/push_sync_use_case.dart';
import '../../../../infrastructure/crypto/providers.dart';
import '../../../../infrastructure/sync/sync_trigger_service.dart';
import '../../domain/models/group_info.dart';
import '../../domain/models/sync_status.dart';
import 'active_group_provider.dart';
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
    fetchAllTransactions: () async {
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
    pushNotificationService: ref.watch(pushNotificationServiceProvider),
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
  );

  ref.onDispose(service.dispose);

  return service;
}

/// Current sync status state notifier.
///
/// Uses [ref.container.listen] instead of [ref.watch] on [activeGroupProvider]
/// to avoid full rebuild on every stream emission, which would reset transient
/// states (syncing, offline, syncError) back to synced/unpaired. We only react
/// to membership transitions (null <-> non-null).
@riverpod
class SyncStatusNotifier extends _$SyncStatusNotifier {
  @override
  SyncStatus build() {
    final subscription = ref.container.listen<AsyncValue<GroupInfo?>>(
      activeGroupProvider,
      (previous, next) {
        final hadActiveGroup = previous?.valueOrNull != null;
        final hasActiveGroup = next.valueOrNull != null;
        if (hadActiveGroup == hasActiveGroup) {
          return;
        }

        state = hasActiveGroup ? SyncStatus.synced : SyncStatus.unpaired;
      },
    );
    ref.onDispose(subscription.close);

    final hasActiveGroup = ref.read(activeGroupProvider).valueOrNull != null;
    return hasActiveGroup ? SyncStatus.synced : SyncStatus.unpaired;
  }

  void updateStatus(SyncStatus status) {
    state = status;
  }
}
