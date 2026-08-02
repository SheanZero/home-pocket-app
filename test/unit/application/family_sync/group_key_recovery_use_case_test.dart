import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/group_key_recovery_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class _MockRelayApiClient extends Mock implements RelayApiClient {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockKeyManager extends Mock implements KeyManager {}

class _MockE2EEService extends Mock implements E2EEService {}

void main() {
  late _MockRelayApiClient api;
  late _MockGroupRepository groups;
  late _MockKeyManager keys;
  late _MockE2EEService e2ee;
  late DateTime now;
  late GroupKeyRecoveryCoordinator coordinator;

  const owner = GroupMember(
    deviceId: 'owner',
    publicKey: 'owner-pk',
    deviceName: 'Owner',
    role: 'owner',
    status: 'active',
    displayName: 'Owner',
    avatarEmoji: '🏠',
  );
  const member = GroupMember(
    deviceId: 'member',
    publicKey: 'member-pk',
    deviceName: 'Member',
    role: 'member',
    status: 'active',
    displayName: 'Member',
    avatarEmoji: '🌿',
  );

  GroupInfo group({String? key, String role = 'member'}) => GroupInfo(
    groupId: 'group-1',
    groupName: 'Family',
    status: key == null ? GroupStatus.confirming : GroupStatus.active,
    role: role,
    groupKey: key,
    keyEpoch: 4,
    members: const [owner, member],
    createdAt: DateTime(2026),
  );

  setUp(() {
    api = _MockRelayApiClient();
    groups = _MockGroupRepository();
    keys = _MockKeyManager();
    e2ee = _MockE2EEService();
    now = DateTime.utc(2026, 8, 1, 1);
    coordinator = GroupKeyRecoveryCoordinator(
      apiClient: api,
      groupRepository: groups,
      keyManager: keys,
      e2eeService: e2ee,
      clock: () => now,
    );
    when(() => keys.getDeviceId()).thenAnswer((_) async => 'member');
  });

  test('active member missing current key creates a bounded request', () async {
    when(() => groups.getGroupById('group-1')).thenAnswer((_) async => group());
    when(
      () => api.requestGroupKey(
        groupId: 'group-1',
        keyEpoch: 0,
        forceNotify: false,
      ),
    ).thenAnswer(
      (_) async => {
        'requestId': 'request-1',
        'keyEpoch': 4,
        'expiresAt': '2026-08-01T01:10:00Z',
        'created': true,
      },
    );

    final result = await coordinator.requestKey(groupId: 'group-1');

    expect(result.phase, GroupKeyRecoveryPhase.waitingForPeer);
    expect(result.requestId, 'request-1');
    expect(result.nextAutomaticAttemptAt, isNotNull);
  });

  test('active owner can recover from another active member', () async {
    when(() => keys.getDeviceId()).thenAnswer((_) async => 'owner');
    when(
      () => groups.getGroupById('group-1'),
    ).thenAnswer((_) async => group(role: 'owner'));
    when(
      () => api.requestGroupKey(
        groupId: 'group-1',
        keyEpoch: 0,
        forceNotify: false,
      ),
    ).thenAnswer(
      (_) async => {
        'requestId': 'owner-request',
        'keyEpoch': 4,
        'expiresAt': '2026-08-01T01:10:00Z',
      },
    );

    final result = await coordinator.requestKey(groupId: 'group-1');

    expect(result.phase, GroupKeyRecoveryPhase.waitingForPeer);
    expect(result.requestId, 'owner-request');
  });

  test('automatic duplicate is suppressed until backoff elapses', () async {
    when(() => groups.getGroupById('group-1')).thenAnswer((_) async => group());
    when(
      () => api.requestGroupKey(
        groupId: any(named: 'groupId'),
        keyEpoch: any(named: 'keyEpoch'),
        forceNotify: any(named: 'forceNotify'),
      ),
    ).thenAnswer(
      (_) async => {
        'requestId': 'request-1',
        'keyEpoch': 4,
        'expiresAt': '2026-08-01T01:10:00Z',
      },
    );
    await coordinator.requestKey(groupId: 'group-1');
    await coordinator.requestKey(groupId: 'group-1');
    verify(
      () => api.requestGroupKey(
        groupId: 'group-1',
        keyEpoch: 0,
        forceNotify: false,
      ),
    ).called(1);
  });

  test('expired unanswered request becomes explicitly unrecoverable', () async {
    when(() => groups.getGroupById('group-1')).thenAnswer((_) async => group());
    when(
      () => api.requestGroupKey(
        groupId: any(named: 'groupId'),
        keyEpoch: any(named: 'keyEpoch'),
        forceNotify: any(named: 'forceNotify'),
      ),
    ).thenAnswer(
      (_) async => {
        'requestId': 'request-1',
        'keyEpoch': 4,
        'expiresAt': '2026-08-01T01:10:00Z',
      },
    );
    await coordinator.requestKey(groupId: 'group-1');

    now = DateTime.utc(2026, 8, 1, 1, 11);
    final result = await coordinator.requestKey(groupId: 'group-1');

    expect(result.phase, GroupKeyRecoveryPhase.unrecoverable);
    verify(
      () => api.requestGroupKey(
        groupId: 'group-1',
        keyEpoch: 0,
        forceNotify: false,
      ),
    ).called(1);
  });

  test(
    'manual retry bypasses local backoff and asks server to notify',
    () async {
      when(
        () => groups.getGroupById('group-1'),
      ).thenAnswer((_) async => group());
      when(
        () => api.requestGroupKey(
          groupId: any(named: 'groupId'),
          keyEpoch: any(named: 'keyEpoch'),
          forceNotify: any(named: 'forceNotify'),
        ),
      ).thenAnswer(
        (_) async => {
          'requestId': 'request-1',
          'keyEpoch': 4,
          'expiresAt': '2026-08-01T01:10:00Z',
        },
      );
      await coordinator.requestKey(groupId: 'group-1');
      await coordinator.requestKey(groupId: 'group-1', manual: true);
      verify(
        () => api.requestGroupKey(
          groupId: 'group-1',
          keyEpoch: 0,
          forceNotify: true,
        ),
      ).called(1);
    },
  );

  test(
    'active peer validates snapshot then seals and targets requester',
    () async {
      when(() => keys.getDeviceId()).thenAnswer((_) async => 'owner');
      when(
        () => groups.getGroupById('group-1'),
      ).thenAnswer((_) async => group(key: 'key-4', role: 'owner'));
      when(() => api.getGroupStatus('group-1')).thenAnswer(
        (_) async => {
          'groupId': 'group-1',
          'status': 'active',
          'keyEpoch': 4,
          'members': [owner.toJson(), member.toJson()],
        },
      );
      when(() => api.getPendingGroupKeyRequests('group-1')).thenAnswer(
        (_) async => {
          'requests': [
            {
              'requestId': 'request-1',
              'groupId': 'group-1',
              'requesterDeviceId': 'member',
              'requesterPublicKey': 'member-pk',
              'keyEpoch': 4,
              'expiresAt': '2026-08-01T01:10:00Z',
            },
          ],
        },
      );
      when(
        () => e2ee.encryptGroupKeyForMember(
          groupKeyBase64: 'key-4',
          memberDeviceId: 'member',
          memberPublicKey: 'member-pk',
          keyEpoch: 4,
          requestId: 'request-1',
        ),
      ).thenAnswer((_) async => 'sealed');
      when(
        () => api.pushGroupKeyResponse(
          groupId: 'group-1',
          requestId: 'request-1',
          targetDeviceId: 'member',
          payload: 'sealed',
          keyEpoch: 4,
          syncId: any(named: 'syncId'),
        ),
      ).thenAnswer((_) async => {'recipientCount': 1});

      expect(await coordinator.respondToPending(groupId: 'group-1'), 1);
    },
  );

  test('removed requester is rejected before sealing', () async {
    when(() => keys.getDeviceId()).thenAnswer((_) async => 'owner');
    when(
      () => groups.getGroupById('group-1'),
    ).thenAnswer((_) async => group(key: 'key-4', role: 'owner'));
    when(() => api.getGroupStatus('group-1')).thenAnswer(
      (_) async => {
        'groupId': 'group-1',
        'status': 'active',
        'keyEpoch': 4,
        'members': [
          owner.toJson(),
          member.copyWith(status: 'removed').toJson(),
        ],
      },
    );
    when(() => api.getPendingGroupKeyRequests('group-1')).thenAnswer(
      (_) async => {
        'requests': [
          {
            'requestId': 'request-1',
            'groupId': 'group-1',
            'requesterDeviceId': 'member',
            'requesterPublicKey': 'member-pk',
            'keyEpoch': 4,
            'expiresAt': '2026-08-01T01:10:00Z',
          },
        ],
      },
    );

    expect(await coordinator.respondToPending(groupId: 'group-1'), 0);
    verifyNever(
      () => e2ee.encryptGroupKeyForMember(
        groupKeyBase64: any(named: 'groupKeyBase64'),
        memberDeviceId: any(named: 'memberDeviceId'),
        memberPublicKey: any(named: 'memberPublicKey'),
        keyEpoch: any(named: 'keyEpoch'),
        requestId: any(named: 'requestId'),
      ),
    );
  });
}
