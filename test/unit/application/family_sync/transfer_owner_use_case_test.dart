import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/refresh_group_snapshot_use_case.dart';
import 'package:home_pocket/application/family_sync/transfer_owner_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockRelayApiClient extends Mock implements RelayApiClient {}

class _MockE2EEService extends Mock implements E2EEService {}

class _MockRefreshGroupSnapshotUseCase extends Mock
    implements RefreshGroupSnapshotUseCase {}

void main() {
  late _MockGroupRepository groupRepository;
  late _MockRelayApiClient apiClient;
  late _MockE2EEService e2eeService;
  late _MockRefreshGroupSnapshotUseCase refreshSnapshot;
  late GroupInfo group;

  setUp(() {
    groupRepository = _MockGroupRepository();
    apiClient = _MockRelayApiClient();
    e2eeService = _MockE2EEService();
    refreshSnapshot = _MockRefreshGroupSnapshotUseCase();
    group = GroupInfo(
      groupId: 'group-1',
      groupName: 'Family',
      status: GroupStatus.active,
      role: 'owner',
      groupKey: 'old-key',
      keyEpoch: 4,
      members: const [
        GroupMember(
          deviceId: 'owner-a',
          publicKey: 'pk-a',
          deviceName: 'Owner',
          displayName: 'Owner',
          avatarEmoji: '🏠',
          role: 'owner',
          status: 'active',
        ),
        GroupMember(
          deviceId: 'member-b',
          publicKey: 'pk-b',
          deviceName: 'Member',
          displayName: 'Member',
          avatarEmoji: '🏠',
          role: 'member',
          status: 'active',
        ),
        GroupMember(
          deviceId: 'pending-c',
          publicKey: 'pk-c',
          deviceName: 'Pending',
          displayName: 'Pending',
          avatarEmoji: '🏠',
          role: 'member',
          status: 'pending',
        ),
      ],
      createdAt: DateTime(2026),
    );
    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => group);
    when(() => e2eeService.generateGroupKey()).thenReturn('new-key');
    when(
      () => e2eeService.encryptGroupKeyForMember(
        groupKeyBase64: 'new-key',
        memberDeviceId: any(named: 'memberDeviceId'),
        memberPublicKey: any(named: 'memberPublicKey'),
        keyEpoch: 5,
        requestId: any(named: 'requestId'),
        purpose: OwnerTransferUseCase.envelopePurpose,
      ),
    ).thenAnswer((invocation) async {
      final target = invocation.namedArguments[#memberDeviceId] as String;
      final requestId = invocation.namedArguments[#requestId] as String;
      return '{"v":2,"t":"K","e":5,"toDeviceId":"$target",'
          '"requestId":"$requestId","purpose":"owner_transfer",'
          '"p":"sealed-$target"}';
    });
    when(
      () => groupRepository.storeGroupKeyForEpoch(
        'group-1',
        groupKeyBase64: 'new-key',
        keyEpoch: 5,
      ),
    ).thenAnswer((_) async {});
    when(() => refreshSnapshot.execute(groupId: 'group-1')).thenAnswer(
      (_) async => const RefreshGroupSnapshotApplied(groupName: 'Family'),
    );
  });

  OwnerTransferUseCase buildUseCase() => OwnerTransferUseCase(
    groupRepository: groupRepository,
    apiClient: apiClient,
    e2eeService: e2eeService,
    refreshGroupSnapshot: refreshSnapshot,
    onEpochCommitted: (groupId, keyEpoch) async {},
    requestIdFactory: () => '11111111-1111-4111-8111-111111111111',
  );

  test('seals the new epoch to the exact active recipient set', () async {
    late List<Map<String, dynamic>> sentEnvelopes;
    when(
      () => apiClient.transferOwner(
        groupId: 'group-1',
        requestId: any(named: 'requestId'),
        targetDeviceId: 'member-b',
        expectedKeyEpoch: 4,
        newKeyEpoch: 5,
        envelopes: any(named: 'envelopes'),
      ),
    ).thenAnswer((invocation) async {
      sentEnvelopes = List<Map<String, dynamic>>.from(
        invocation.namedArguments[#envelopes] as List,
      );
      return {
        'status': 'transferred',
        'requestId': '11111111-1111-4111-8111-111111111111',
        'newOwnerDeviceId': 'member-b',
        'keyEpoch': 5,
      };
    });

    final result = await buildUseCase().execute(
      groupId: 'group-1',
      targetDeviceId: 'member-b',
    );

    expect(result, isA<OwnerTransferSuccess>());
    expect(sentEnvelopes.map((item) => item['deviceId']).toSet(), {
      'owner-a',
      'member-b',
    });
    expect(sentEnvelopes.every((item) => item['payloadHash'] != null), isTrue);
    verify(
      () => groupRepository.storeGroupKeyForEpoch(
        'group-1',
        groupKeyBase64: 'new-key',
        keyEpoch: 5,
      ),
    ).called(1);
    verify(() => refreshSnapshot.execute(groupId: 'group-1')).called(1);
  });

  test(
    'runs epoch recovery only after local key and snapshot commit',
    () async {
      final events = <String>[];
      when(
        () => apiClient.transferOwner(
          groupId: 'group-1',
          requestId: any(named: 'requestId'),
          targetDeviceId: 'member-b',
          expectedKeyEpoch: 4,
          newKeyEpoch: 5,
          envelopes: any(named: 'envelopes'),
        ),
      ).thenAnswer(
        (_) async => {'newOwnerDeviceId': 'member-b', 'keyEpoch': 5},
      );
      when(
        () => groupRepository.storeGroupKeyForEpoch(
          'group-1',
          groupKeyBase64: 'new-key',
          keyEpoch: 5,
        ),
      ).thenAnswer((_) async => events.add('key-committed'));
      when(() => refreshSnapshot.execute(groupId: 'group-1')).thenAnswer((
        _,
      ) async {
        events.add('snapshot-committed');
        return const RefreshGroupSnapshotApplied(groupName: 'Family');
      });
      final useCase = OwnerTransferUseCase(
        groupRepository: groupRepository,
        apiClient: apiClient,
        e2eeService: e2eeService,
        refreshGroupSnapshot: refreshSnapshot,
        requestIdFactory: () => '11111111-1111-4111-8111-111111111111',
        onEpochCommitted: (groupId, keyEpoch) async {
          expect(groupId, 'group-1');
          expect(keyEpoch, 5);
          events.add('epoch-recovery');
        },
      );

      expect(
        await useCase.execute(groupId: 'group-1', targetDeviceId: 'member-b'),
        isA<OwnerTransferSuccess>(),
      );
      expect(events, ['key-committed', 'snapshot-committed', 'epoch-recovery']);
    },
  );

  test(
    'timeout retry reuses request id and identical prepared envelopes',
    () async {
      final calls =
          <({String requestId, List<Map<String, dynamic>> envelopes})>[];
      var attempt = 0;
      when(
        () => apiClient.transferOwner(
          groupId: 'group-1',
          requestId: any(named: 'requestId'),
          targetDeviceId: 'member-b',
          expectedKeyEpoch: 4,
          newKeyEpoch: 5,
          envelopes: any(named: 'envelopes'),
        ),
      ).thenAnswer((invocation) async {
        calls.add((
          requestId: invocation.namedArguments[#requestId] as String,
          envelopes: List<Map<String, dynamic>>.from(
            invocation.namedArguments[#envelopes] as List,
          ),
        ));
        if (attempt++ == 0) throw TimeoutException('lost response');
        return {'newOwnerDeviceId': 'member-b', 'keyEpoch': 5};
      });

      final result = await buildUseCase().execute(
        groupId: 'group-1',
        targetDeviceId: 'member-b',
      );

      expect(result, isA<OwnerTransferSuccess>());
      expect(calls, hasLength(2));
      expect(calls[1].requestId, calls[0].requestId);
      expect(calls[1].envelopes, calls[0].envelopes);
    },
  );

  test(
    'rejects pending, removed, self, and non-owner transfer attempts',
    () async {
      for (final target in ['pending-c', 'owner-a', 'missing']) {
        final result = await buildUseCase().execute(
          groupId: 'group-1',
          targetDeviceId: target,
        );
        expect(result, isA<OwnerTransferInvalidTarget>());
      }

      group = group.copyWith(role: 'member');
      final forbidden = await buildUseCase().execute(
        groupId: 'group-1',
        targetDeviceId: 'member-b',
      );
      expect(forbidden, isA<OwnerTransferForbidden>());
      verifyNever(
        () => apiClient.transferOwner(
          groupId: any(named: 'groupId'),
          requestId: any(named: 'requestId'),
          targetDeviceId: any(named: 'targetDeviceId'),
          expectedKeyEpoch: any(named: 'expectedKeyEpoch'),
          newKeyEpoch: any(named: 'newKeyEpoch'),
          envelopes: any(named: 'envelopes'),
        ),
      );
    },
  );
}
