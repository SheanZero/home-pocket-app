import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/check_group_validity_use_case.dart';
import 'package:home_pocket/application/family_sync/full_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/pull_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/shopping_item_change_tracker.dart';
import 'package:home_pocket/application/family_sync/sync_avatar_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/application/family_sync/transaction_change_tracker.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/group_dao.dart';
import 'package:home_pocket/data/daos/group_member_dao.dart';
import 'package:home_pocket/data/repositories/group_repository_impl.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

class _MockPullSyncUseCase extends Mock implements PullSyncUseCase {}

class _MockPushSyncUseCase extends Mock implements PushSyncUseCase {}

class _MockFullSyncUseCase extends Mock implements FullSyncUseCase {}

class _MockSyncAvatarUseCase extends Mock implements SyncAvatarUseCase {}

class _MockCheckGroupValidityUseCase extends Mock
    implements CheckGroupValidityUseCase {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockSyncQueueManager extends Mock implements SyncQueueManager {}

class _MockKeyManager extends Mock implements KeyManager {}

void main() {
  test(
    'persisted successful pull time survives service reconstruction',
    () async {
      final database = AppDatabase.forTesting();
      addTearDown(database.close);
      final firstRepository = GroupRepositoryImpl(
        groupDao: GroupDao(database),
        memberDao: GroupMemberDao(database),
      );
      await firstRepository.restoreActiveGroup(
        groupId: 'group-1',
        role: 'owner',
        groupKey: 'group-key',
        members: const [],
      );
      expect(
        await firstRepository.updateLastSyncTime(
          DateTime.now().toUtc(),
          expectedGroupId: 'group-1',
        ),
        isTrue,
      );

      // Recreate repository and orchestrator as app startup does. The threshold
      // must use the database value rather than process-local state.
      final restartedRepository = GroupRepositoryImpl(
        groupDao: GroupDao(database),
        memberDao: GroupMemberDao(database),
      );
      final restartedOrchestrator = SyncOrchestrator(
        pullSync: _MockPullSyncUseCase(),
        pushSync: _MockPushSyncUseCase(),
        fullSync: _MockFullSyncUseCase(),
        avatarSync: _MockSyncAvatarUseCase(),
        checkValidity: _MockCheckGroupValidityUseCase(),
        groupRepo: restartedRepository,
        profileRepo: _MockUserProfileRepository(),
        queueManager: _MockSyncQueueManager(),
        keyManager: _MockKeyManager(),
        changeTracker: TransactionChangeTracker(),
        shoppingChangeTracker: ShoppingItemChangeTracker(),
      );

      expect(
        (await restartedRepository.getActiveGroup())?.lastSyncAt,
        isNotNull,
      );
      expect(await restartedOrchestrator.needsFullPull(), isFalse);
    },
  );

  test('a completed pull cannot stamp a different active group', () async {
    final database = AppDatabase.forTesting();
    addTearDown(database.close);
    final repository = GroupRepositoryImpl(
      groupDao: GroupDao(database),
      memberDao: GroupMemberDao(database),
    );
    await repository.restoreActiveGroup(
      groupId: 'new-group',
      role: 'owner',
      groupKey: 'group-key',
      members: const [],
    );

    expect(
      await repository.updateLastSyncTime(
        DateTime.now().toUtc(),
        expectedGroupId: 'old-group',
      ),
      isFalse,
    );

    expect((await repository.getActiveGroup())?.lastSyncAt, isNull);
  });
}
