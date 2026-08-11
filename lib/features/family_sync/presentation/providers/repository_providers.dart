import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/accounting/repository_providers.dart'
    as app_accounting;
import '../../../../application/family_sync/apply_sync_operations_use_case.dart';
import '../../../../application/family_sync/check_group_use_case.dart';
import '../../../../application/family_sync/check_group_validity_use_case.dart';
import '../../../../application/family_sync/confirm_join_use_case.dart';
import '../../../../application/family_sync/confirm_member_use_case.dart';
import '../../../../application/family_sync/create_group_use_case.dart';
import '../../../../application/family_sync/deactivate_group_use_case.dart';
import '../../../../application/family_sync/drain_family_sync_outbox_use_case.dart';
import '../../../../application/family_sync/epoch_sync_recovery_use_case.dart';
import '../../../../application/family_sync/full_sync_use_case.dart';
import '../../../../application/family_sync/group_key_recovery_use_case.dart';
import '../../../../application/family_sync/handle_group_dissolved_use_case.dart';
import '../../../../application/family_sync/handle_member_left_use_case.dart';
import '../../../../application/family_sync/inbound_sync_recovery_use_case.dart';
import '../../../../application/family_sync/join_group_use_case.dart';
import '../../../../application/family_sync/join_request_lifecycle_use_cases.dart';
import '../../../../application/family_sync/leave_group_use_case.dart';
import '../../../../application/family_sync/manage_group_invite_use_case.dart';
import '../../../../application/family_sync/membership_rotation_coordinator.dart';
import '../../../../application/family_sync/pull_sync_use_case.dart';
import '../../../../application/family_sync/push_sync_use_case.dart';
import '../../../../application/family_sync/remove_member_use_case.dart';
import '../../../../application/family_sync/rotate_group_key_use_case.dart';
import '../../../../application/family_sync/rename_group_use_case.dart';
import '../../../../application/family_sync/repository_providers.dart'
    as app_family_sync;
import '../../../../application/family_sync/repository_providers.dart'
    show SyncQueueManager;
import '../../../../application/family_sync/shadow_book_service.dart';
import '../../../../application/family_sync/sync_avatar_use_case.dart';
import '../../../../application/family_sync/sync_queue_recovery_use_case.dart';
import '../../../../application/family_sync/transaction_withdrawal_acknowledger.dart';
import '../../../../application/profile/repository_providers.dart'
    as app_profile;
import '../../../../data/daos/group_dao.dart';
import '../../../../data/daos/group_member_dao.dart';
import '../../../../data/daos/family_sync_outbox_dao.dart';
import '../../../../data/daos/inbound_sync_operation_dao.dart';
import '../../../../data/daos/sync_queue_dao.dart';
import '../../../../data/daos/transaction_dao.dart';
import '../../../../data/repositories/group_repository_impl.dart';
import '../../../../data/repositories/family_sync_outbox_repository_impl.dart';
import '../../../../data/repositories/inbound_sync_operation_repository_impl.dart';
import '../../../../data/repositories/sync_repository_impl.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../features/accounting/domain/models/transaction_sync_mapper.dart';
import '../../../accounting/presentation/providers/repository_providers.dart'
    as accounting;
import '../../../profile/presentation/providers/repository_providers.dart'
    as profile;
import '../../../shopping_list/domain/models/shopping_item_sync_mapper.dart';
import '../../../shopping_list/domain/repositories/shopping_item_repository.dart';
import '../../../shopping_list/presentation/providers/repository_providers.dart'
    show shoppingItemRepositoryProvider;
import '../../domain/repositories/group_repository.dart';
import '../../domain/repositories/family_sync_outbox_repository.dart';
import '../../domain/repositories/inbound_sync_operation_repository.dart';
import '../../domain/repositories/sync_repository.dart';

part 'repository_providers.g.dart';

// ---------------------------------------------------------------------------
// Delegating providers — bridge from feature-side symbol names to
// application-layer app-prefixed providers (HIGH-02 compliance).
// Task 5 of Plan 04-02 will delete these once all consumers have migrated.
// ---------------------------------------------------------------------------

/// RelayApiClient — delegates to application-layer appRelayApiClientProvider.
final relayApiClientProvider = Provider(
  (ref) => ref.watch(app_family_sync.appRelayApiClientProvider),
);

/// E2EEService — delegates to application-layer appE2eeServiceProvider.
final e2eeServiceProvider = Provider(
  (ref) => ref.watch(app_family_sync.appE2eeServiceProvider),
);

/// KeyManager — delegates to application-layer appKeyManagerProvider.
final keyManagerProvider = Provider(
  (ref) => ref.watch(app_family_sync.appKeyManagerProvider),
);

/// SyncQueueManager — built from local SyncRepository + application-layer relay client.
///
/// Uses local [syncRepositoryProvider] because the sync repository depends on
/// the local database (not hoisted to application layer in Plan 04-01).
@riverpod
SyncQueueManager syncQueueManager(Ref ref) {
  final syncRepo = ref.watch(syncRepositoryProvider);
  final apiClient = ref.watch(app_family_sync.appRelayApiClientProvider);
  final acknowledger = TransactionWithdrawalAcknowledger(
    transactionRepository: ref.watch(accounting.transactionRepositoryProvider),
  );
  return SyncQueueManager(
    syncRepository: syncRepo,
    apiClient: apiClient,
    onWithdrawalsDelivered: acknowledger.markDelivered,
  );
}

/// WebSocketService — delegates to application-layer appWebSocketServiceProvider.
final webSocketServiceProvider = Provider(
  (ref) => ref.watch(app_family_sync.appWebSocketServiceProvider),
);

// ---------------------------------------------------------------------------
// Data access providers
// ---------------------------------------------------------------------------

/// GroupMemberDao provider (for watch queries).
@riverpod
GroupMemberDao groupMemberDao(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  return GroupMemberDao(database);
}

/// GroupRepository provider.
@riverpod
GroupRepository groupRepository(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  return GroupRepositoryImpl(
    groupDao: GroupDao(database),
    memberDao: GroupMemberDao(database),
  );
}

/// SyncRepository provider.
@riverpod
SyncRepository syncRepository(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  final dao = SyncQueueDao(database);
  return SyncRepositoryImpl(dao: dao);
}

@riverpod
InboundSyncOperationRepository inboundSyncOperationRepository(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  return InboundSyncOperationRepositoryImpl(
    dao: InboundSyncOperationDao(database),
  );
}

@riverpod
FamilySyncOutboxRepository familySyncOutboxRepository(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  return FamilySyncOutboxRepositoryImpl(dao: FamilySyncOutboxDao(database));
}

/// Durable outbound queue recovery actions.
@riverpod
SyncQueueRecoveryUseCase syncQueueRecoveryUseCase(Ref ref) {
  return SyncQueueRecoveryUseCase(
    queueManager: ref.watch(syncQueueManagerProvider),
  );
}

/// Deterministic inbound quarantine recovery actions.
@riverpod
InboundSyncRecoveryUseCase inboundSyncRecoveryUseCase(Ref ref) {
  return InboundSyncRecoveryUseCase(
    repository: ref.watch(inboundSyncOperationRepositoryProvider),
    applyOperations: ref.watch(applySyncOperationsUseCaseProvider),
  );
}

// ---------------------------------------------------------------------------
// Sync DI providers (folded from sync_providers.dart DI section)
// ---------------------------------------------------------------------------

/// Production filesystem seam for pulled avatar blobs.
///
/// Tests can override this resolver with a temporary directory without
/// invoking a platform channel.
final appDirectoryResolverProvider = Provider<AppDirectoryResolver>((ref) {
  return () async => (await getApplicationDocumentsDirectory()).path;
});

/// ShadowBookService provider.
@riverpod
ShadowBookService shadowBookService(Ref ref) {
  return ShadowBookService(
    bookRepository: ref.watch(accounting.bookRepositoryProvider),
    transactionRepository: ref.watch(accounting.transactionRepositoryProvider),
  );
}

/// ApplySyncOperationsUseCase provider.
@riverpod
ApplySyncOperationsUseCase applySyncOperationsUseCase(Ref ref) {
  return ApplySyncOperationsUseCase(
    transactionRepository: ref.watch(accounting.transactionRepositoryProvider),
    shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    inboundRepository: ref.watch(inboundSyncOperationRepositoryProvider),
    categoryReferenceSyncService: ref.watch(
      accounting.categoryReferenceSyncServiceProvider,
    ),
    syncAvatarUseCase: ref.watch(syncAvatarUseCaseProvider),
    appDirectoryResolver: ref.watch(appDirectoryResolverProvider),
  );
}

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

@riverpod
DrainFamilySyncOutboxUseCase drainFamilySyncOutboxUseCase(Ref ref) {
  final avatarSync = ref.watch(syncAvatarUseCaseProvider);
  return DrainFamilySyncOutboxUseCase(
    outboxRepository: ref.watch(familySyncOutboxRepositoryProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    pushSync: ref.watch(pushSyncUseCaseProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    operationMaterializer: avatarSync.materializeOutboxOperation,
    onMaterializationFailure: (entry, error) async {
      final superseded = await avatarSync.recoverOutboxMaterializationFailure(
        entry,
        error,
      );
      return superseded
          ? FamilySyncOutboxFailureDisposition.superseded
          : FamilySyncOutboxFailureDisposition.retry;
    },
    onEntriesSettled: (_) => avatarSync.cleanupStagingAfterSettlement(),
  );
}

/// PullSyncUseCase provider.
@riverpod
PullSyncUseCase pullSyncUseCase(Ref ref) {
  final applyOps = ref.watch(applySyncOperationsUseCaseProvider);
  return PullSyncUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
    groupRepo: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    keyManager: ref.watch(keyManagerProvider),
    applyOperations: applyOps.execute,
    rejectOperationsBatch: applyOps.rejectOversizedBatch,
  );
}

/// CheckGroupValidityUseCase provider.
@riverpod
CheckGroupValidityUseCase checkGroupValidityUseCase(Ref ref) {
  return CheckGroupValidityUseCase(
    groupRepo: ref.watch(groupRepositoryProvider),
    apiClient: ref.watch(relayApiClientProvider),
    invalidationCleanup: ref.watch(handleGroupDissolvedUseCaseProvider),
  );
}

/// FullSyncUseCase provider.
@riverpod
FullSyncUseCase fullSyncUseCase(Ref ref) {
  return FullSyncUseCase(
    pushSync: ref.watch(pushSyncUseCaseProvider),
    fetchAllTransactions: () async {
      final transactionRepo = ref.read(
        accounting.transactionRepositoryProvider,
      );
      final transactionDao = TransactionDao(
        ref.read(app_accounting.appAppDatabaseProvider),
      );
      final bookRepo = ref.read(accounting.bookRepositoryProvider);
      final localBooks = await bookRepo.findAll(
        includeArchived: true,
        includeShadow: false,
      );
      final operations = <Map<String, dynamic>>[];
      for (final book in localBooks) {
        final rows = await transactionDao.findAllByBookIncludingDeleted(
          book.id,
        );
        final transactions = (await Future.wait(
          rows.map((row) => transactionRepo.findById(row.id)),
        )).whereType<Transaction>();
        for (final tx in transactions) {
          final operation = TransactionSyncMapper.toFullSyncOperation(
            tx,
            sourceBookId: book.id,
            sourceBookName: book.name,
            sourceBookType: 'remote_book:${book.id}',
          );
          if (operation == null) continue;
          if (operation['op'] == 'delete') {
            operations.add(operation);
            continue;
          }
          operations.add(
            await ref
                .read(accounting.categoryReferenceSyncServiceProvider)
                .attachToBillOperation(transaction: tx, operation: operation),
          );
        }
      }
      return operations;
    },
    fetchAllShoppingOps: () async {
      // W1 / SYNC-01: full sync reconciles every public shopping item.
      // Durable repositories include deleted rows so removals become
      // versioned tombstones; the use case re-applies the privacy gate.
      final shoppingRepo = ref.read(shoppingItemRepositoryProvider);
      final publicItems =
          shoppingRepo is DurableFamilySyncShoppingItemRepository
          ? await shoppingRepo.findPublicIncludingDeleted()
          : await shoppingRepo.watchByListType('public').first;
      return publicItems
          .map(ShoppingItemSyncMapper.toFullSyncOperation)
          .toList();
    },
    fetchAdditionalOperations: () => ref
        .read(syncAvatarUseCaseProvider)
        .buildCurrentProfileOperationsForFullSync(),
    onOperationsAccepted: (operations) async {
      final group = await ref.read(groupRepositoryProvider).getActiveGroup();
      if (group == null) return;
      await ref
          .read(familySyncOutboxRepositoryProvider)
          .settleCovered(groupId: group.groupId, operations: operations);
      await ref.read(syncAvatarUseCaseProvider).cleanupStagingAfterSettlement();
    },
  );
}

/// Serial post-key-epoch data-plane recovery shared by member removal and
/// owner transfer. It never treats local ciphertext persistence as relay ACK.
final epochSyncRecoveryUseCaseProvider = Provider<EpochSyncRecoveryUseCase>((
  ref,
) {
  return EpochSyncRecoveryUseCase(
    queueManager: ref.watch(syncQueueManagerProvider),
    outboxDrainer: ref.watch(drainFamilySyncOutboxUseCaseProvider),
    fullSync: ref.watch(fullSyncUseCaseProvider),
  );
});

/// HandleMemberLeftUseCase provider.
@Riverpod(keepAlive: true)
RotateGroupKeyUseCase rotateGroupKeyUseCase(Ref ref) {
  return RotateGroupKeyUseCase(
    groupRepository: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    apiClient: ref.watch(relayApiClientProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
    onKeyRotated: (groupId, keyEpoch) async {
      await ref
          .read(epochSyncRecoveryUseCaseProvider)
          .execute(groupId: groupId, currentKeyEpoch: keyEpoch);
    },
  );
}

/// HandleMemberLeftUseCase provider.
@riverpod
HandleMemberLeftUseCase handleMemberLeftUseCase(Ref ref) {
  return HandleMemberLeftUseCase(
    groupRepo: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
    keyManager: ref.watch(keyManagerProvider),
    rotateGroupKey: ref.watch(rotateGroupKeyUseCaseProvider),
  );
}

/// HandleGroupDissolvedUseCase provider.
@riverpod
HandleGroupDissolvedUseCase handleGroupDissolvedUseCase(Ref ref) {
  return HandleGroupDissolvedUseCase(
    groupRepo: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
  );
}

// ---------------------------------------------------------------------------
// Group DI providers (folded from group_providers.dart)
// ---------------------------------------------------------------------------

final createGroupUseCaseProvider = Provider<CreateGroupUseCase>((ref) {
  return CreateGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
    onDeviceRegistered: null,
  );
});

final joinGroupUseCaseProvider = Provider<JoinGroupUseCase>((ref) {
  return JoinGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
    onDeviceRegistered: null,
  );
});

final confirmJoinUseCaseProvider = Provider<ConfirmJoinUseCase>((ref) {
  return ConfirmJoinUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final getJoinRequestStatusUseCaseProvider =
    Provider<GetJoinRequestStatusUseCase>((ref) {
      return GetJoinRequestStatusUseCase(
        apiClient: ref.watch(relayApiClientProvider),
      );
    });

final rejectJoinRequestUseCaseProvider = Provider<RejectJoinRequestUseCase>((
  ref,
) {
  return RejectJoinRequestUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final cancelJoinRequestUseCaseProvider = Provider<CancelJoinRequestUseCase>((
  ref,
) {
  return CancelJoinRequestUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final renameGroupUseCaseProvider = Provider<RenameGroupUseCase>((ref) {
  return RenameGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final manageGroupInviteUseCaseProvider = Provider<ManageGroupInviteUseCase>((
  ref,
) {
  return ManageGroupInviteUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final membershipRotationCoordinatorProvider =
    Provider<MembershipRotationCoordinator>((ref) {
      return MembershipRotationCoordinator(
        groupRepository: ref.watch(groupRepositoryProvider),
        apiClient: ref.watch(relayApiClientProvider),
        e2eeService: ref.watch(e2eeServiceProvider),
        keyManager: ref.watch(keyManagerProvider),
        queueManager: ref.watch(syncQueueManagerProvider),
        shadowBookService: ref.watch(shadowBookServiceProvider),
        onEpochCommitted: (groupId, keyEpoch) async {
          await ref
              .read(epochSyncRecoveryUseCaseProvider)
              .execute(groupId: groupId, currentKeyEpoch: keyEpoch);
        },
      );
    });

final checkGroupUseCaseProvider = Provider<CheckGroupUseCase>((ref) {
  return CheckGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    membershipRotation: ref.watch(membershipRotationCoordinatorProvider),
    onDeviceRegistered: null,
  );
});

final groupKeyRecoveryCoordinatorProvider =
    Provider<GroupKeyRecoveryCoordinator>((ref) {
      final coordinator = GroupKeyRecoveryCoordinator(
        apiClient: ref.watch(relayApiClientProvider),
        groupRepository: ref.watch(groupRepositoryProvider),
        keyManager: ref.watch(keyManagerProvider),
        e2eeService: ref.watch(e2eeServiceProvider),
      );
      ref.onDispose(coordinator.dispose);
      return coordinator;
    });

final confirmMemberUseCaseProvider = Provider<ConfirmMemberUseCase>((ref) {
  return ConfirmMemberUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
    fullSync: ref.watch(fullSyncUseCaseProvider),
    syncAvatar: ref.watch(syncAvatarUseCaseProvider),
  );
});

final leaveGroupUseCaseProvider = Provider<LeaveGroupUseCase>((ref) {
  return LeaveGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
    membershipRotation: ref.watch(membershipRotationCoordinatorProvider),
  );
});

final deactivateGroupUseCaseProvider = Provider<DeactivateGroupUseCase>((ref) {
  return DeactivateGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
  );
});

final removeMemberUseCaseProvider = Provider<RemoveMemberUseCase>((ref) {
  return RemoveMemberUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    rotateGroupKey: ref.watch(rotateGroupKeyUseCaseProvider),
    membershipRotation: ref.watch(membershipRotationCoordinatorProvider),
  );
});

// ---------------------------------------------------------------------------
// Avatar sync DI (folded from avatar_sync_providers.dart)
// ---------------------------------------------------------------------------

final syncAvatarUseCaseProvider = Provider<SyncAvatarUseCase>((ref) {
  return SyncAvatarUseCase(
    pushSync: ref.watch(pushSyncUseCaseProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    userProfileRepository: ref.watch(profile.userProfileRepositoryProvider),
    keyManager: ref.watch(keyManagerProvider),
    stagingStore: ref.watch(app_profile.appAvatarSemanticStagingStoreProvider),
  );
});
