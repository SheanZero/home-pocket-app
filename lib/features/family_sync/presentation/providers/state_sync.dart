import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/family_sync/sync_engine.dart';
import '../../../../application/family_sync/sync_orchestrator.dart';
import '../../../../application/family_sync/transaction_change_tracker.dart';
import '../../domain/models/group_member.dart';
import '../../domain/models/sync_status_model.dart' as model;
import '../../../profile/presentation/providers/repository_providers.dart'
    as profile;
import 'state_active_group.dart';
import 'repository_providers.dart';

part 'state_sync.g.dart';

/// TransactionChangeTracker provider — keepAlive so tracker persists across screens.
@Riverpod(keepAlive: true)
TransactionChangeTracker transactionChangeTracker(Ref ref) {
  return TransactionChangeTracker();
}

/// SyncOrchestrator provider.
///
/// Placed in state_sync.dart rather than repository_providers.dart to avoid
/// circular dependency: syncOrchestrator needs transactionChangeTrackerProvider
/// (defined here) while syncEngine (also here) needs syncOrchestratorProvider.
@riverpod
SyncOrchestrator syncOrchestrator(Ref ref) {
  return SyncOrchestrator(
    pullSync: ref.watch(pullSyncUseCaseProvider),
    pushSync: ref.watch(pushSyncUseCaseProvider),
    fullSync: ref.watch(fullSyncUseCaseProvider),
    avatarSync: ref.watch(syncAvatarUseCaseProvider),
    checkValidity: ref.watch(checkGroupValidityUseCaseProvider),
    groupRepo: ref.watch(groupRepositoryProvider),
    profileRepo: ref.watch(profile.userProfileRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    keyManager: ref.watch(keyManagerProvider),
    changeTracker: ref.watch(transactionChangeTrackerProvider),
  );
}

/// SyncEngine provider — keepAlive because it manages timers and lifecycle.
@Riverpod(keepAlive: true)
SyncEngine syncEngine(Ref ref) {
  final engine = SyncEngine(
    orchestrator: ref.watch(syncOrchestratorProvider),
    groupRepo: ref.watch(groupRepositoryProvider),
    webSocketService: ref.watch(webSocketServiceProvider),
    keyManager: ref.watch(keyManagerProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
}

/// Reactive sync status stream from SyncEngine.
@riverpod
Stream<model.SyncStatus> syncStatusStream(Ref ref) {
  return ref.watch(syncEngineProvider).statusStream;
}

/// GroupMembers stream via Drift watch query, mapped to domain model.
///
/// Kept alive because this stream is long-lived and must not lose subscription
/// state on tab switches. The name reflects that this stream observes
/// [activeGroupProvider] (only members of the currently active group).
@Riverpod(keepAlive: true)
Stream<List<GroupMember>> activeGroupMembers(Ref ref) {
  final activeGroup = ref.watch(activeGroupProvider).valueOrNull;
  if (activeGroup == null) return Stream.value([]);
  final dao = ref.watch(groupMemberDaoProvider);
  return dao
      .watchByGroupId(activeGroup.groupId)
      .map(
        (rows) => rows
            .map(
              (row) => GroupMember(
                deviceId: row.deviceId,
                publicKey: row.publicKey,
                deviceName: row.deviceName,
                role: row.role,
                status: row.status,
                displayName: row.displayName,
                avatarEmoji: row.avatarEmoji,
                avatarImagePath: row.avatarImagePath,
                avatarImageHash: row.avatarImageHash,
              ),
            )
            .toList(),
      );
}
