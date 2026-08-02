import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/handle_group_dissolved_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockSyncQueueManager extends Mock implements SyncQueueManager {}

class _MockShadowBookService extends Mock implements ShadowBookService {}

void main() {
  test(
    'clears queue and shadow data before deactivating the local group',
    () async {
      final groupRepository = _MockGroupRepository();
      final queueManager = _MockSyncQueueManager();
      final shadowBookService = _MockShadowBookService();
      final useCase = HandleGroupDissolvedUseCase(
        groupRepo: groupRepository,
        queueManager: queueManager,
        shadowBookService: shadowBookService,
      );
      final activeGroup = GroupInfo(
        groupId: 'group-1',
        status: GroupStatus.active,
        groupName: 'Family',
        role: 'member',
        groupKey: 'secret-group-key',
        members: const [],
        createdAt: DateTime(2026),
      );

      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => activeGroup);
      when(() => queueManager.clearQueue()).thenAnswer((_) async {});
      when(
        () => shadowBookService.cleanSyncData(any()),
      ).thenAnswer((_) async {});
      when(
        () => groupRepository.deactivateGroup(any()),
      ).thenAnswer((_) async {});

      await useCase.execute(groupId: 'group-1');

      verifyInOrder([
        () => queueManager.clearQueue(),
        () => shadowBookService.cleanSyncData('group-1'),
        () => groupRepository.deactivateGroup('group-1'),
      ]);
    },
  );
}
