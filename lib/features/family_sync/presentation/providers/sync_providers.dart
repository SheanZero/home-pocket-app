import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/family_sync/check_group_validity_use_case.dart';
import '../../../../application/family_sync/full_sync_use_case.dart';
import '../../../../application/family_sync/apply_sync_operations_use_case.dart';
import '../../../../application/family_sync/handle_group_dissolved_use_case.dart';
import '../../../../application/family_sync/handle_member_left_use_case.dart';
import '../../../../application/family_sync/shadow_book_service.dart';
import '../../../../application/family_sync/pull_sync_use_case.dart';
import '../../../../application/family_sync/push_sync_use_case.dart';
import '../../../../application/family_sync/sync_engine.dart';
import '../../../../application/family_sync/sync_orchestrator.dart';
import '../../../../features/accounting/domain/models/transaction_sync_mapper.dart';
import '../../../../features/profile/presentation/providers/user_profile_providers.dart'
    as profile;
import '../../../accounting/presentation/providers/repository_providers.dart'
    as accounting;
import '../../../../infrastructure/crypto/providers.dart';
import '../../../../infrastructure/sync/sync_trigger_service.dart';
import 'avatar_sync_providers.dart';
import '../../domain/models/group_info.dart';
import '../../domain/models/group_member.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/models/sync_status_model.dart' as model;
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

@riverpod
ShadowBookService shadowBookService(Ref ref) {
  return ShadowBookService(
    bookRepository: ref.watch(accounting.bookRepositoryProvider),
    transactionRepository: ref.watch(accounting.transactionRepositoryProvider),
  );
}

@riverpod
ApplySyncOperationsUseCase applySyncOperationsUseCase(Ref ref) {
  return ApplySyncOperationsUseCase(
    transactionRepository: ref.watch(accounting.transactionRepositoryProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    syncAvatarUseCase: ref.watch(syncAvatarUseCaseProvider),
  );
}

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
  final transactionRepo = ref.watch(accounting.transactionRepositoryProvider);
  final bookRepo = ref.watch(accounting.bookRepositoryProvider);

  return FullSyncUseCase(
    pushSync: ref.watch(pushSyncUseCaseProvider),
    fetchAllTransactions: () async {
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
    fullSync: ref.watch(fullSyncUseCaseProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
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

// --- New SyncEngine providers ---

/// SyncOrchestrator provider.
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
  );
}

/// SyncEngine provider — keepAlive because it manages timers and lifecycle.
@Riverpod(keepAlive: true)
SyncEngine syncEngine(Ref ref) {
  final engine = SyncEngine(
    orchestrator: ref.watch(syncOrchestratorProvider),
    groupRepo: ref.watch(groupRepositoryProvider),
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
@riverpod
Stream<List<GroupMember>> groupMembers(Ref ref) {
  final activeGroup = ref.watch(activeGroupProvider).valueOrNull;
  if (activeGroup == null) return Stream.value([]);
  final dao = ref.watch(groupMemberDaoProvider);
  return dao.watchByGroupId(activeGroup.groupId).map(
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
