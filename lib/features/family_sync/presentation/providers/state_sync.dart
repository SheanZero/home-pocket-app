import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/family_sync/shopping_item_change_tracker.dart';
import '../../../../application/family_sync/complete_member_activation_use_case.dart';
import '../../../../application/family_sync/control_plane_reconciliation_use_case.dart';
import '../../../../application/family_sync/refresh_group_snapshot_use_case.dart';
import '../../../../application/family_sync/transfer_owner_use_case.dart';
import '../../../../application/family_sync/sync_engine.dart';
import '../../../../application/family_sync/sync_orchestrator.dart';
import '../../../../application/family_sync/transaction_change_tracker.dart';
import '../../domain/models/group_member.dart';
import '../../domain/models/sync_status_model.dart' as model;
import '../../domain/repositories/sync_repository.dart';
import '../../domain/repositories/inbound_sync_operation_repository.dart';
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

/// ShoppingItemChangeTracker provider — keepAlive so tracker persists across screens.
///
/// Mirrors [transactionChangeTrackerProvider]. Used by [SyncOrchestrator] to flush
/// pending shopping item operations during incrementalPush (SC-3, SYNC-01).
@Riverpod(keepAlive: true)
ShoppingItemChangeTracker shoppingItemChangeTracker(Ref ref) {
  return ShoppingItemChangeTracker();
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
    shoppingChangeTracker: ref.watch(shoppingItemChangeTrackerProvider),
    outboxDrainer: ref.watch(drainFamilySyncOutboxUseCaseProvider),
  );
}

/// Confirmation bootstrap coordinator shared by push handling and the waiting
/// screen's authoritative polling fallback.
final completeMemberActivationUseCaseProvider =
    Provider<CompleteMemberActivationUseCase>((ref) {
      return CompleteMemberActivationUseCase(
        checkGroup: ref.watch(checkGroupUseCaseProvider),
        pullSync: ref.watch(pullSyncUseCaseProvider),
        groupRepository: ref.watch(groupRepositoryProvider),
        orchestrator: ref.watch(syncOrchestratorProvider),
        keyRecovery: ref.watch(groupKeyRecoveryCoordinatorProvider),
      );
    });

final refreshGroupSnapshotUseCaseProvider =
    Provider<RefreshGroupSnapshotUseCase>((ref) {
      return RefreshGroupSnapshotUseCase(
        apiClient: ref.watch(relayApiClientProvider),
        groupRepository: ref.watch(groupRepositoryProvider),
        keyManager: ref.watch(keyManagerProvider),
        membershipRotation: ref.watch(membershipRotationCoordinatorProvider),
      );
    });

final controlPlaneReconciliationUseCaseProvider =
    Provider<ControlPlaneReconciliationUseCase>((ref) {
      return ControlPlaneReconciliationUseCase(
        apiClient: ref.watch(relayApiClientProvider),
        groupRepository: ref.watch(groupRepositoryProvider),
        refreshSnapshot: ref.watch(refreshGroupSnapshotUseCaseProvider),
        checkValidity: ref.watch(checkGroupValidityUseCaseProvider),
      );
    });

final ownerTransferUseCaseProvider = Provider<OwnerTransferUseCase>((ref) {
  return OwnerTransferUseCase(
    groupRepository: ref.watch(groupRepositoryProvider),
    apiClient: ref.watch(relayApiClientProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
    refreshGroupSnapshot: ref.watch(refreshGroupSnapshotUseCaseProvider),
    onEpochCommitted: (groupId, keyEpoch) async {
      await ref
          .read(epochSyncRecoveryUseCaseProvider)
          .execute(groupId: groupId, currentKeyEpoch: keyEpoch);
    },
  );
});

/// SyncEngine provider — keepAlive because it manages timers and lifecycle.
@Riverpod(keepAlive: true)
SyncEngine syncEngine(Ref ref) {
  final engine = SyncEngine(
    orchestrator: ref.watch(syncOrchestratorProvider),
    groupRepo: ref.watch(groupRepositoryProvider),
    webSocketService: ref.watch(webSocketServiceProvider),
    keyManager: ref.watch(keyManagerProvider),
    memberActivation: ref.watch(completeMemberActivationUseCaseProvider),
    groupSnapshotRefresh: ref.watch(refreshGroupSnapshotUseCaseProvider),
    groupKeyRecovery: ref.watch(groupKeyRecoveryCoordinatorProvider),
    controlPlaneReconciliation: ref.watch(
      controlPlaneReconciliationUseCaseProvider,
    ),
    recoverDurableOutbox: ref
        .watch(syncOrchestratorProvider)
        .recoverDurableOutbox,
    maintainInboundQuarantine: () async {
      final group = await ref.read(groupRepositoryProvider).getActiveGroup();
      if (group == null) return;
      await ref
          .read(inboundSyncOperationRepositoryProvider)
          .maintainQuarantine(groupId: group.groupId);
    },
    maintainAvatarStaging: () =>
        ref.read(syncAvatarUseCaseProvider).cleanupStagingAfterSettlement(),
  );
  ref.onDispose(engine.dispose);
  return engine;
}

/// Reactive sync status stream from SyncEngine.
@riverpod
Stream<model.SyncStatus> syncStatusStream(Ref ref) {
  return ref.watch(syncEngineProvider).statusStream;
}

@riverpod
Stream<SyncQueueSummary> syncQueueSummary(Ref ref) {
  return ref.watch(syncQueueRecoveryUseCaseProvider).watchSummary();
}

@riverpod
Stream<InboundSyncSummary> inboundSyncSummary(Ref ref) {
  final groupId = ref.watch(activeGroupProvider).value?.groupId;
  if (groupId == null) return Stream.value(const InboundSyncSummary());
  return ref
      .watch(inboundSyncRecoveryUseCaseProvider)
      .watchSummary(groupId: groupId);
}

@riverpod
Stream<List<InboundSyncQuarantineEntry>> inboundSyncQuarantined(Ref ref) {
  final groupId = ref.watch(activeGroupProvider).value?.groupId;
  if (groupId == null) {
    return Stream.value(const <InboundSyncQuarantineEntry>[]);
  }
  return ref
      .watch(inboundSyncRecoveryUseCaseProvider)
      .watchQuarantined(groupId: groupId);
}

/// GroupMembers stream via Drift watch query, mapped to domain model.
///
/// Kept alive because this stream is long-lived and must not lose subscription
/// state on tab switches. The name reflects that this stream observes
/// [activeGroupProvider] (only members of the currently active group).
@Riverpod(keepAlive: true)
Stream<List<GroupMember>> activeGroupMembers(Ref ref) {
  final activeGroup = ref.watch(activeGroupProvider).value;
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
