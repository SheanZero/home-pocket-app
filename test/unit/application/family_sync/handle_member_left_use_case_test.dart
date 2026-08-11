import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/handle_member_left_use_case.dart';
import 'package:home_pocket/application/family_sync/rotate_group_key_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

class MockShadowBookService extends Mock implements ShadowBookService {}

class MockKeyManager extends Mock implements KeyManager {}

class MockRotateGroupKeyUseCase extends Mock implements RotateGroupKeyUseCase {}

void main() {
  late MockGroupRepository groupRepository;
  late MockSyncQueueManager queueManager;
  late MockShadowBookService shadowBookService;
  late MockKeyManager keyManager;
  late MockRotateGroupKeyUseCase rotateGroupKey;
  late HandleMemberLeftUseCase useCase;

  setUp(() {
    groupRepository = MockGroupRepository();
    queueManager = MockSyncQueueManager();
    shadowBookService = MockShadowBookService();
    keyManager = MockKeyManager();
    rotateGroupKey = MockRotateGroupKeyUseCase();
    useCase = HandleMemberLeftUseCase(
      groupRepo: groupRepository,
      queueManager: queueManager,
      shadowBookService: shadowBookService,
      keyManager: keyManager,
      rotateGroupKey: rotateGroupKey,
    );
  });

  test(
    'removed local device clears queue, shadow data, and group key',
    () async {
      when(
        () => keyManager.getDeviceId(),
      ).thenAnswer((_) async => 'local-device');
      when(() => groupRepository.getActiveGroup()).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-1',
          status: GroupStatus.active,
          groupName: 'Family',
          role: 'member',
          groupKey: 'secret-key',
          keyEpoch: 2,
          members: const [],
          createdAt: DateTime(2026),
        ),
      );
      when(() => queueManager.clearQueue()).thenAnswer((_) async {});
      when(
        () => shadowBookService.cleanSyncData('group-1'),
      ).thenAnswer((_) async {});
      when(
        () => groupRepository.deactivateGroup('group-1'),
      ).thenAnswer((_) async {});

      await useCase.execute(
        groupId: 'group-1',
        deviceId: 'local-device',
        reason: 'removed',
        keyEpoch: 3,
      );

      verify(() => queueManager.clearQueue()).called(1);
      verify(() => shadowBookService.cleanSyncData('group-1')).called(1);
      verify(() => groupRepository.deactivateGroup('group-1')).called(1);
      verifyNever(
        () => rotateGroupKey.execute(
          groupId: any(named: 'groupId'),
          authoritativeEpoch: any(named: 'authoritativeEpoch'),
          removedDeviceId: any(named: 'removedDeviceId'),
        ),
      );
    },
  );
}
