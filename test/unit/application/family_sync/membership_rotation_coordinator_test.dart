import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/membership_rotation_coordinator.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockRelayApiClient extends Mock implements RelayApiClient {}

class _MockE2EEService extends Mock implements E2EEService {}

class _MockKeyManager extends Mock implements KeyManager {}

class _MemoryIntentStore implements MembershipRotationIntentStore {
  MembershipRotationIntent? intent;
  MembershipRotationIntent? completed;
  List<GroupMember>? completedMembers;
  final events = <String>[];

  @override
  Future<void> saveMembershipRotationIntent(
    MembershipRotationIntent value,
  ) async {
    events.add('saved');
    intent = value;
  }

  @override
  Future<MembershipRotationIntent?> getMembershipRotationIntent(
    String groupId,
  ) async => intent?.groupId == groupId ? intent : null;

  @override
  Future<void> clearMembershipRotationIntent(
    String groupId, {
    required String requestId,
  }) async {
    if (intent?.groupId == groupId && intent?.requestId == requestId) {
      intent = null;
    }
  }

  @override
  Future<void> completeMembershipRotationLocally({
    required MembershipRotationIntent intent,
    required List<GroupMember> members,
  }) async {
    events.add('completed');
    completed = intent;
    completedMembers = members;
    this.intent = null;
  }
}

const _owner = GroupMember(
  deviceId: 'owner-a',
  publicKey: 'pk-a',
  deviceName: 'Owner',
  role: 'owner',
  status: 'active',
  displayName: 'Owner',
  avatarEmoji: '🏠',
);

const _memberB = GroupMember(
  deviceId: 'member-b',
  publicKey: 'pk-b',
  deviceName: 'B',
  role: 'member',
  status: 'active',
  displayName: 'B',
  avatarEmoji: '🏠',
);

const _memberC = GroupMember(
  deviceId: 'member-c',
  publicKey: 'pk-c',
  deviceName: 'C',
  role: 'member',
  status: 'active',
  displayName: 'C',
  avatarEmoji: '🏠',
);

GroupInfo _group({String role = 'owner'}) => GroupInfo(
  groupId: 'group-1',
  status: GroupStatus.active,
  groupName: 'Family',
  role: role,
  groupKey: 'old-key',
  keyEpoch: 4,
  members: const [_owner, _memberB, _memberC],
  createdAt: DateTime(2026),
);

void main() {
  late _MockGroupRepository groupRepository;
  late _MockRelayApiClient apiClient;
  late _MockE2EEService e2eeService;
  late _MockKeyManager keyManager;
  late _MemoryIntentStore store;

  setUp(() {
    groupRepository = _MockGroupRepository();
    apiClient = _MockRelayApiClient();
    e2eeService = _MockE2EEService();
    keyManager = _MockKeyManager();
    store = _MemoryIntentStore();
    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => _group());
    when(() => e2eeService.generateGroupKey()).thenReturn('next-key');
    when(
      () => e2eeService.encryptGroupKeyForMember(
        groupKeyBase64: 'next-key',
        memberDeviceId: any(named: 'memberDeviceId'),
        memberPublicKey: any(named: 'memberPublicKey'),
        keyEpoch: 5,
        requestId: any(named: 'requestId'),
        purpose: any(named: 'purpose'),
      ),
    ).thenAnswer((invocation) async {
      final target = invocation.namedArguments[#memberDeviceId] as String;
      final requestId = invocation.namedArguments[#requestId] as String;
      final purpose = invocation.namedArguments[#purpose] as String;
      return '{"v":2,"t":"K","e":5,"toDeviceId":"$target",'
          '"requestId":"$requestId","purpose":"$purpose","p":"sealed"}';
    });
  });

  MembershipRotationCoordinator coordinator({
    MembershipEpochCommittedCallback? onEpochCommitted,
  }) => MembershipRotationCoordinator(
    groupRepository: groupRepository,
    apiClient: apiClient,
    e2eeService: e2eeService,
    keyManager: keyManager,
    intentStore: store,
    requestIdFactory: () => '11111111-1111-4111-8111-111111111111',
    onEpochCommitted: onEpochCommitted,
  );

  test(
    'persists key and exact remaining envelopes before owner removal',
    () async {
      when(
        () => apiClient.removeMemberWithPreparedRotation(
          groupId: 'group-1',
          deviceId: 'member-b',
          requestId: any(named: 'requestId'),
          expectedKeyEpoch: 4,
          newKeyEpoch: 5,
          envelopes: any(named: 'envelopes'),
        ),
      ).thenAnswer((invocation) async {
        expect(store.events, ['saved']);
        final envelopes = invocation.namedArguments[#envelopes] as List;
        expect(envelopes.map((item) => (item as Map)['deviceId']).toSet(), {
          'owner-a',
          'member-c',
        });
        return {
          'requestId': '11111111-1111-4111-8111-111111111111',
          'keyEpoch': 5,
        };
      });

      await coordinator(
        onEpochCommitted: (groupId, keyEpoch) async {
          expect(groupId, 'group-1');
          expect(keyEpoch, 5);
          store.events.add('epoch-recovery');
        },
      ).removeMember(groupId: 'group-1', targetDeviceId: 'member-b');

      expect(store.events, ['saved', 'completed', 'epoch-recovery']);
      expect(store.completed?.groupKey, 'next-key');
      expect(store.completedMembers?.map((member) => member.deviceId), [
        'owner-a',
        'member-c',
      ]);
    },
  );

  test(
    'response loss keeps intent and retry reuses identical request',
    () async {
      final calls = <List<Map<String, dynamic>>>[];
      var attempt = 0;
      when(
        () => apiClient.removeMemberWithPreparedRotation(
          groupId: 'group-1',
          deviceId: 'member-b',
          requestId: any(named: 'requestId'),
          expectedKeyEpoch: 4,
          newKeyEpoch: 5,
          envelopes: any(named: 'envelopes'),
        ),
      ).thenAnswer((invocation) async {
        calls.add(
          List<Map<String, dynamic>>.from(
            invocation.namedArguments[#envelopes] as List,
          ),
        );
        if (attempt++ == 0) throw TimeoutException('response lost');
        return {
          'requestId': '11111111-1111-4111-8111-111111111111',
          'keyEpoch': 5,
        };
      });

      await expectLater(
        coordinator().removeMember(
          groupId: 'group-1',
          targetDeviceId: 'member-b',
        ),
        throwsA(isA<TimeoutException>()),
      );
      final stableIntent = store.intent;
      expect(stableIntent, isNotNull);

      await coordinator().removeMember(
        groupId: 'group-1',
        targetDeviceId: 'member-b',
      );
      expect(calls, hasLength(2));
      expect(calls[1], calls[0]);
      expect(store.completed?.requestId, stableIntent?.requestId);
      verify(() => e2eeService.generateGroupKey()).called(1);
    },
  );

  test('owner completes a pending self-leave from snapshot', () async {
    when(
      () => apiClient.completeMembershipRotation(
        groupId: 'group-1',
        requestId: 'leave-request',
        expectedKeyEpoch: 4,
        newKeyEpoch: 5,
        envelopes: any(named: 'envelopes'),
      ),
    ).thenAnswer((_) async => {'requestId': 'leave-request', 'keyEpoch': 5});

    final changed = await coordinator().recoverFromSnapshot({
      'groupId': 'group-1',
      'status': 'active',
      'keyEpoch': 4,
      'rotationRequired': true,
      'rotationRequestId': 'leave-request',
      'pendingKeyEpoch': 5,
      'rotationRemovedDeviceId': 'member-b',
      'members': [_owner.toJson(), _memberC.toJson()],
    });

    expect(changed, isTrue);
    expect(store.completed?.requestId, 'leave-request');
    expect(store.completed?.envelopes.map((item) => item['deviceId']).toSet(), {
      'owner-a',
      'member-c',
    });
  });

  test(
    'cold start replays a response-lost self-leave and deactivates',
    () async {
      final memberGroup = _group(role: 'member');
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => memberGroup);
      when(
        () => groupRepository.getCurrentGroup(),
      ).thenAnswer((_) async => memberGroup);
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'member-b');
      when(
        () => groupRepository.deactivateGroup('group-1'),
      ).thenAnswer((_) async {});
      var attempts = 0;
      final requestIds = <String>[];
      when(
        () => apiClient.leaveGroupWithRotation(
          'group-1',
          requestId: any(named: 'requestId'),
          expectedKeyEpoch: 4,
        ),
      ).thenAnswer((invocation) async {
        final requestId = invocation.namedArguments[#requestId] as String;
        requestIds.add(requestId);
        if (attempts++ == 0) throw TimeoutException('response lost');
        return {
          'requestId': requestId,
          'keyEpoch': 4,
          'pendingKeyEpoch': 5,
          'rotationRequired': true,
        };
      });

      await expectLater(
        coordinator().submitSelfLeave('group-1'),
        throwsA(isA<TimeoutException>()),
      );
      expect(
        store.intent?.operation,
        MembershipRotationCoordinator.leaveOperation,
      );

      expect(await coordinator().resumeSelfLeaveIfPending(), isTrue);
      expect(requestIds, hasLength(2));
      expect(requestIds[1], requestIds[0]);
      expect(store.intent, isNull);
      verify(() => groupRepository.deactivateGroup('group-1')).called(1);
    },
  );
}
