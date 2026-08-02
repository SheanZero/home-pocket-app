import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/rotate_group_key_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockE2EEService extends Mock implements E2EEService {}

const owner = GroupMember(
  deviceId: 'owner-device',
  publicKey: 'owner-public-key',
  deviceName: 'Owner phone',
  role: 'owner',
  status: 'active',
  displayName: 'Owner',
  avatarEmoji: '🏠',
);

const remaining = GroupMember(
  deviceId: 'remaining-device',
  publicKey: 'remaining-public-key',
  deviceName: 'Tablet',
  role: 'member',
  status: 'active',
  displayName: 'Remaining',
  avatarEmoji: '🏠',
);

const removed = GroupMember(
  deviceId: 'removed-device',
  publicKey: 'removed-public-key',
  deviceName: 'Old phone',
  role: 'member',
  status: 'active',
  displayName: 'Removed',
  avatarEmoji: '🏠',
);

GroupInfo group({required String role, String? key = 'old-key'}) => GroupInfo(
  groupId: 'group-1',
  status: GroupStatus.active,
  groupName: 'Family',
  role: role,
  groupKey: key,
  keyEpoch: 2,
  members: const [owner, remaining, removed],
  createdAt: DateTime(2026),
);

void main() {
  late MockGroupRepository groupRepository;
  late MockSyncQueueManager queueManager;
  late MockRelayApiClient apiClient;
  late MockE2EEService e2eeService;
  late int fullSyncCount;
  late RotateGroupKeyUseCase useCase;

  setUp(() {
    groupRepository = MockGroupRepository();
    queueManager = MockSyncQueueManager();
    apiClient = MockRelayApiClient();
    e2eeService = MockE2EEService();
    fullSyncCount = 0;
    useCase = RotateGroupKeyUseCase(
      groupRepository: groupRepository,
      queueManager: queueManager,
      apiClient: apiClient,
      e2eeService: e2eeService,
      onKeyRotated: (groupId, keyEpoch) async {
        expect(groupId, 'group-1');
        expect(keyEpoch, 3);
        fullSyncCount++;
      },
    );
    when(
      () => queueManager.discardRetiredEpochCiphertext(
        groupId: 'group-1',
        currentKeyEpoch: 3,
      ),
    ).thenAnswer((_) async => 1);
  });

  test(
    'owner rotates to the authoritative epoch and excludes removed device',
    () async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => group(role: 'owner'));
      when(() => e2eeService.generateGroupKey()).thenReturn('new-key');
      when(
        () => groupRepository.storeGroupKeyForEpoch(
          'group-1',
          groupKeyBase64: 'new-key',
          keyEpoch: 3,
        ),
      ).thenAnswer((_) async {});
      when(
        () => e2eeService.encryptGroupKeyForMember(
          groupKeyBase64: 'new-key',
          keyEpoch: 3,
          memberDeviceId: 'remaining-device',
          memberPublicKey: 'remaining-public-key',
        ),
      ).thenAnswer((_) async => 'sealed-new-key');
      when(
        () => apiClient.pushSync(
          groupId: 'group-1',
          syncId: any(named: 'syncId'),
          payload: 'sealed-new-key',
          vectorClock: const {},
          operationCount: 0,
          keyEpoch: 3,
        ),
      ).thenAnswer((_) async => {'recipientCount': 1});

      await useCase.execute(
        groupId: 'group-1',
        authoritativeEpoch: 3,
        removedDeviceId: 'removed-device',
      );

      verify(
        () => queueManager.discardRetiredEpochCiphertext(
          groupId: 'group-1',
          currentKeyEpoch: 3,
        ),
      ).called(1);
      verify(
        () => groupRepository.storeGroupKeyForEpoch(
          'group-1',
          groupKeyBase64: 'new-key',
          keyEpoch: 3,
        ),
      ).called(1);
      verifyNever(
        () => e2eeService.encryptGroupKeyForMember(
          groupKeyBase64: any(named: 'groupKeyBase64'),
          keyEpoch: any(named: 'keyEpoch'),
          memberDeviceId: 'removed-device',
          memberPublicKey: any(named: 'memberPublicKey'),
        ),
      );
      expect(fullSyncCount, 1);
    },
  );

  test(
    'remaining member discards old key and queue while awaiting new epoch key',
    () async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => group(role: 'member'));
      when(
        () => groupRepository.clearGroupKeyForEpoch('group-1', keyEpoch: 3),
      ).thenAnswer((_) async {});

      await useCase.execute(
        groupId: 'group-1',
        authoritativeEpoch: 3,
        removedDeviceId: 'removed-device',
      );

      verify(
        () => queueManager.discardRetiredEpochCiphertext(
          groupId: 'group-1',
          currentKeyEpoch: 3,
        ),
      ).called(1);
      verify(
        () => groupRepository.clearGroupKeyForEpoch('group-1', keyEpoch: 3),
      ).called(1);
      verifyNever(() => e2eeService.generateGroupKey());
      expect(fullSyncCount, 0);
    },
  );

  test('duplicate epoch event is idempotent', () async {
    when(() => groupRepository.getGroupById('group-1')).thenAnswer(
      (_) async =>
          group(role: 'owner').copyWith(keyEpoch: 3, groupKey: 'new-key'),
    );

    await useCase.execute(
      groupId: 'group-1',
      authoritativeEpoch: 3,
      removedDeviceId: 'removed-device',
    );

    verifyNever(
      () => queueManager.discardRetiredEpochCiphertext(
        groupId: any(named: 'groupId'),
        currentKeyEpoch: any(named: 'currentKeyEpoch'),
      ),
    );
    verifyNever(() => e2eeService.generateGroupKey());
  });

  test('concurrent duplicate epoch events share one rotation', () async {
    final lookupGate = Completer<void>();
    when(() => groupRepository.getGroupById('group-1')).thenAnswer((_) async {
      await lookupGate.future;
      return group(role: 'member');
    });
    when(
      () => groupRepository.clearGroupKeyForEpoch('group-1', keyEpoch: 3),
    ).thenAnswer((_) async {});

    final first = useCase.execute(
      groupId: 'group-1',
      authoritativeEpoch: 3,
      removedDeviceId: 'removed-device',
    );
    final duplicate = useCase.execute(
      groupId: 'group-1',
      authoritativeEpoch: 3,
      removedDeviceId: 'removed-device',
    );
    lookupGate.complete();

    await Future.wait([first, duplicate]);

    verify(() => groupRepository.getGroupById('group-1')).called(1);
    verify(
      () => queueManager.discardRetiredEpochCiphertext(
        groupId: 'group-1',
        currentKeyEpoch: 3,
      ),
    ).called(1);
    verify(
      () => groupRepository.clearGroupKeyForEpoch('group-1', keyEpoch: 3),
    ).called(1);
  });
}
