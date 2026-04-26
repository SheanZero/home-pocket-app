import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../../../application/family_sync/full_sync_use_case.dart';
import '../../../../application/family_sync/handle_group_dissolved_use_case.dart';
import '../../../../application/family_sync/handle_member_left_use_case.dart';
import '../../../../application/family_sync/join_group_use_case.dart';
import '../../../../application/family_sync/leave_group_use_case.dart';
import '../../../../application/family_sync/pull_sync_use_case.dart';
import '../../../../application/family_sync/push_sync_use_case.dart';
import '../../../../application/family_sync/regenerate_invite_use_case.dart';
import '../../../../application/family_sync/remove_member_use_case.dart';
import '../../../../application/family_sync/rename_group_use_case.dart';
import '../../../../application/family_sync/repository_providers.dart'
    as app_family_sync;
import '../../../../application/family_sync/repository_providers.dart'
    show SyncQueueManager;
import '../../../../application/family_sync/shadow_book_service.dart';
import '../../../../application/family_sync/sync_avatar_use_case.dart';
import '../../../../data/daos/group_dao.dart';
import '../../../../data/daos/group_member_dao.dart';
import '../../../../data/daos/sync_queue_dao.dart';
import '../../../../data/repositories/group_repository_impl.dart';
import '../../../../data/repositories/sync_repository_impl.dart';
import '../../../../features/accounting/domain/models/transaction_sync_mapper.dart';
import '../../../accounting/presentation/providers/repository_providers.dart'
    as accounting;
import '../../../profile/presentation/providers/user_profile_providers.dart'
    as profile;
import '../../domain/repositories/group_repository.dart';
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
  return SyncQueueManager(syncRepository: syncRepo, apiClient: apiClient);
}

/// WebSocketService — delegates to application-layer appWebSocketServiceProvider.
final webSocketServiceProvider = Provider(
  (ref) => ref.watch(app_family_sync.appWebSocketServiceProvider),
);

/// PushNotificationService — delegates to application-layer appPushNotificationServiceProvider.
final pushNotificationServiceProvider = Provider(
  (ref) => ref.watch(app_family_sync.appPushNotificationServiceProvider),
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

// ---------------------------------------------------------------------------
// Sync DI providers (folded from sync_providers.dart DI section)
// ---------------------------------------------------------------------------

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
    shadowBookService: ref.watch(shadowBookServiceProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    syncAvatarUseCase: ref.watch(syncAvatarUseCaseProvider),
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
  );
}

/// CheckGroupValidityUseCase provider.
@riverpod
CheckGroupValidityUseCase checkGroupValidityUseCase(Ref ref) {
  return CheckGroupValidityUseCase(
    groupRepo: ref.watch(groupRepositoryProvider),
    apiClient: ref.watch(relayApiClientProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
  );
}

/// FullSyncUseCase provider.
@riverpod
FullSyncUseCase fullSyncUseCase(Ref ref) {
  return FullSyncUseCase(
    pushSync: ref.watch(pushSyncUseCaseProvider),
    fetchAllTransactions: () async {
      final transactionRepo = ref.read(accounting.transactionRepositoryProvider);
      final bookRepo = ref.read(accounting.bookRepositoryProvider);
      final localBooks = await bookRepo.findAll();
      final operations = <Map<String, dynamic>>[];
      for (final book in localBooks) {
        final transactions = await transactionRepo.findAllByBook(book.id);
        operations.addAll(
          transactions.map(
            (tx) => TransactionSyncMapper.toCreateOperation(
              tx,
              sourceBookId: book.id,
              sourceBookName: book.name,
              sourceBookType: 'remote_book:${book.id}',
            ),
          ),
        );
      }
      return operations;
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
  );
});

final joinGroupUseCaseProvider = Provider<JoinGroupUseCase>((ref) {
  return JoinGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
  );
});

final confirmJoinUseCaseProvider = Provider<ConfirmJoinUseCase>((ref) {
  return ConfirmJoinUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final renameGroupUseCaseProvider = Provider<RenameGroupUseCase>((ref) {
  return RenameGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final checkGroupUseCaseProvider = Provider<CheckGroupUseCase>((ref) {
  return CheckGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
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

final regenerateInviteUseCaseProvider = Provider<RegenerateInviteUseCase>((
  ref,
) {
  return RegenerateInviteUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final removeMemberUseCaseProvider = Provider<RemoveMemberUseCase>((ref) {
  return RemoveMemberUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

// ---------------------------------------------------------------------------
// Avatar sync DI (folded from avatar_sync_providers.dart)
// ---------------------------------------------------------------------------

final syncAvatarUseCaseProvider = Provider<SyncAvatarUseCase>((ref) {
  return SyncAvatarUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    userProfileRepository: ref.watch(profile.userProfileRepositoryProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
  );
});
