import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/refresh_group_snapshot_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class _MockRelayApiClient extends Mock implements RelayApiClient {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockKeyManager extends Mock implements KeyManager {}

void main() {
  late _MockRelayApiClient apiClient;
  late _MockGroupRepository groupRepository;
  late _MockKeyManager keyManager;
  late RefreshGroupSnapshotUseCase useCase;

  const localMember = GroupMember(
    deviceId: 'device-1',
    publicKey: 'pk-1',
    deviceName: 'Phone',
    displayName: 'Me',
    avatarEmoji: '🏠',
    role: 'member',
    status: 'active',
  );
  final activeGroup = GroupInfo(
    groupId: 'group-1',
    groupName: 'Old name',
    status: GroupStatus.active,
    role: 'member',
    members: const [localMember],
    createdAt: DateTime(2026, 8, 1),
  );

  Map<String, dynamic> snapshot(String name) => {
    'groupId': 'group-1',
    'status': 'active',
    'groupName': name,
    'keyEpoch': 1,
    'members': [localMember.toJson()],
  };

  setUp(() {
    apiClient = _MockRelayApiClient();
    groupRepository = _MockGroupRepository();
    keyManager = _MockKeyManager();
    useCase = RefreshGroupSnapshotUseCase(
      apiClient: apiClient,
      groupRepository: groupRepository,
      keyManager: keyManager,
    );

    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => activeGroup);
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
    when(
      () => groupRepository.applyAuthoritativeSnapshot(
        groupId: any(named: 'groupId'),
        groupName: any(named: 'groupName'),
        role: any(named: 'role'),
        keyEpoch: any(named: 'keyEpoch'),
        members: any(named: 'members'),
      ),
    ).thenAnswer((_) async => true);
  });

  test('applies authoritative name for the current active member', () async {
    when(
      () => apiClient.getGroupStatus('group-1'),
    ).thenAnswer((_) async => snapshot('New name'));

    final result = await useCase.execute(groupId: 'group-1');

    expect(result, const RefreshGroupSnapshotApplied(groupName: 'New name'));
    verify(
      () => groupRepository.applyAuthoritativeSnapshot(
        groupId: 'group-1',
        groupName: 'New name',
        role: 'member',
        keyEpoch: 1,
        members: const [localMember],
      ),
    ).called(1);
  });

  test(
    'ignores an event for a non-current group without network I/O',
    () async {
      final result = await useCase.execute(groupId: 'group-other');

      expect(result, isA<RefreshGroupSnapshotIgnored>());
      verifyNever(() => apiClient.getGroupStatus(any()));
      verifyNever(
        () => groupRepository.applyAuthoritativeSnapshot(
          groupId: any(named: 'groupId'),
          groupName: any(named: 'groupName'),
          role: any(named: 'role'),
          keyEpoch: any(named: 'keyEpoch'),
          members: any(named: 'members'),
        ),
      );
    },
  );

  test('does not apply a snapshot unless the local device is active', () async {
    when(() => apiClient.getGroupStatus('group-1')).thenAnswer(
      (_) async => {
        ...snapshot('Untrusted name'),
        'members': [
          {...localMember.toJson(), 'status': 'removed'},
        ],
      },
    );

    final result = await useCase.execute(groupId: 'group-1');

    expect(result, isA<RefreshGroupSnapshotMembershipInvalid>());
    verifyNever(
      () => groupRepository.applyAuthoritativeSnapshot(
        groupId: any(named: 'groupId'),
        groupName: any(named: 'groupName'),
        role: any(named: 'role'),
        keyEpoch: any(named: 'keyEpoch'),
        members: any(named: 'members'),
      ),
    );
  });

  test('classifies authenticated 404 as membership invalid', () async {
    when(() => apiClient.getGroupStatus('group-1')).thenThrow(
      const RelayApiException(statusCode: 404, message: 'group gone'),
    );

    final result = await useCase.execute(groupId: 'group-1');

    expect(
      result,
      isA<RefreshGroupSnapshotMembershipInvalid>().having(
        (value) => value.statusCode,
        'statusCode',
        404,
      ),
    );
  });

  test('classifies 5xx as non-destructive refresh failure', () async {
    when(() => apiClient.getGroupStatus('group-1')).thenThrow(
      const RelayApiException(statusCode: 503, message: 'unavailable'),
    );

    final result = await useCase.execute(groupId: 'group-1');

    expect(
      result,
      isA<RefreshGroupSnapshotFailed>().having(
        (value) => value.statusCode,
        'statusCode',
        503,
      ),
    );
  });

  test(
    'does not update a group that stopped being active during GET',
    () async {
      var reads = 0;
      when(() => groupRepository.getActiveGroup()).thenAnswer((_) async {
        reads++;
        return reads == 1 ? activeGroup : null;
      });
      when(
        () => apiClient.getGroupStatus('group-1'),
      ).thenAnswer((_) async => snapshot('New name'));

      final result = await useCase.execute(groupId: 'group-1');

      expect(result, isA<RefreshGroupSnapshotIgnored>());
      verifyNever(
        () => groupRepository.applyAuthoritativeSnapshot(
          groupId: any(named: 'groupId'),
          groupName: any(named: 'groupName'),
          role: any(named: 'role'),
          keyEpoch: any(named: 'keyEpoch'),
          members: any(named: 'members'),
        ),
      );
    },
  );

  test('a later invalidation supersedes an older in-flight response', () async {
    final first = Completer<Map<String, dynamic>>();
    final second = Completer<Map<String, dynamic>>();
    var requestCount = 0;
    when(() => apiClient.getGroupStatus('group-1')).thenAnswer((_) {
      requestCount++;
      return requestCount == 1 ? first.future : second.future;
    });

    final firstRefresh = useCase.execute(groupId: 'group-1');
    await Future<void>.delayed(Duration.zero);
    final secondRefresh = useCase.execute(groupId: 'group-1');
    await Future<void>.delayed(Duration.zero);

    second.complete(snapshot('Newest name'));
    expect(
      await secondRefresh,
      const RefreshGroupSnapshotApplied(groupName: 'Newest name'),
    );
    first.complete(snapshot('Stale name'));
    expect(await firstRefresh, isA<RefreshGroupSnapshotIgnored>());

    verify(
      () => groupRepository.applyAuthoritativeSnapshot(
        groupId: 'group-1',
        groupName: 'Newest name',
        role: 'member',
        keyEpoch: 1,
        members: const [localMember],
      ),
    ).called(1);
    verifyNever(
      () => groupRepository.applyAuthoritativeSnapshot(
        groupId: 'group-1',
        groupName: 'Stale name',
        role: 'member',
        keyEpoch: 1,
        members: const [localMember],
      ),
    );
  });
}
