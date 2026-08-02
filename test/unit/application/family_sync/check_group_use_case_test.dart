import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/application/family_sync/check_group_use_case.dart';
import 'package:home_pocket/application/family_sync/group_operation_error.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockKeyManager extends Mock implements KeyManager {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockRelayApiClient apiClient;
  late MockKeyManager keyManager;
  late MockGroupRepository groupRepository;
  late CheckGroupUseCase useCase;

  setUp(() {
    apiClient = MockRelayApiClient();
    keyManager = MockKeyManager();
    groupRepository = MockGroupRepository();
    useCase = CheckGroupUseCase(
      apiClient: apiClient,
      keyManager: keyManager,
      groupRepository: groupRepository,
    );

    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
    when(() => keyManager.getPublicKey()).thenAnswer((_) async => 'public-key');
    when(
      () => apiClient.registerDevice(
        deviceId: any(named: 'deviceId'),
        publicKey: any(named: 'publicKey'),
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{});
    when(
      () => groupRepository.updateMembers(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => groupRepository.updateGroupName(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => groupRepository.confirmLocalGroup(any()),
    ).thenAnswer((_) async {});
    when(
      () => groupRepository.markGroupConfirming(any()),
    ).thenAnswer((_) async {});
    when(() => groupRepository.getPendingGroup()).thenAnswer((_) async => null);
    when(
      () => groupRepository.updateInviteCode(any(), any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => groupRepository.restoreActiveGroup(
        groupId: any(named: 'groupId'),
        role: any(named: 'role'),
        inviteCode: any(named: 'inviteCode'),
        inviteExpiresAt: any(named: 'inviteExpiresAt'),
        groupKey: any(named: 'groupKey'),
        members: any(named: 'members'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => groupRepository.saveConfirmingGroup(
        groupId: any(named: 'groupId'),
        groupName: any(named: 'groupName'),
        members: any(named: 'members'),
        role: any(named: 'role'),
        keyEpoch: any(named: 'keyEpoch'),
      ),
    ).thenAnswer((_) async {});
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

  test('returns not in group when server reports no active group', () async {
    when(
      () => apiClient.checkGroup(),
    ).thenAnswer((_) async => {'groupExisted': false});

    final result = await useCase.execute();

    expect(result, isA<CheckGroupNotInGroup>());
    verify(() => apiClient.checkGroup()).called(1);
    verifyNever(() => apiClient.getGroupStatus(any()));
  });

  test(
    'keeps a locally confirming member pending when group check is not active',
    () async {
      when(
        () => apiClient.checkGroup(),
      ).thenAnswer((_) async => {'groupExisted': false});
      when(() => groupRepository.getPendingGroup()).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-123',
          groupName: 'Test Family',
          status: GroupStatus.confirming,
          role: 'member',
          members: const [],
          createdAt: DateTime(2026, 3, 14),
        ),
      );

      final result = await useCase.execute();

      expect(result, isA<CheckGroupPendingApproval>());
      expect((result as CheckGroupPendingApproval).groupId, 'group-123');
      verifyNever(() => apiClient.getGroupStatus(any()));
      verifyNever(() => groupRepository.confirmLocalGroup(any()));
    },
  );

  test(
    'keeps a recovered active membership awaiting its missing group key',
    () async {
      when(
        () => apiClient.checkGroup(),
      ).thenAnswer((_) async => {'groupExisted': true, 'groupId': 'group-123'});
      when(() => apiClient.getGroupStatus('group-123')).thenAnswer(
        (_) async => {
          'groupId': 'group-123',
          'status': 'active',
          'groupName': 'Test Family',
          'inviteCode': '123456',
          'inviteExpiresAt': 1709654400,
          'members': [
            {
              'deviceId': 'device-1',
              'publicKey': 'key-1',
              'deviceName': 'My Phone',
              'role': 'owner',
              'status': 'active',
              'displayName': 'Owner',
              'avatarEmoji': '🏠',
            },
            {
              'deviceId': 'device-2',
              'publicKey': 'key-2',
              'deviceName': 'Partner Phone',
              'role': 'member',
              'status': 'active',
              'displayName': 'Partner',
              'avatarEmoji': '🏠',
            },
          ],
        },
      );
      when(
        () => groupRepository.getGroupById('group-123'),
      ).thenAnswer((_) async => null);

      final result = await useCase.execute();

      expect(result, isA<CheckGroupAwaitingKey>());
      expect((result as CheckGroupAwaitingKey).groupId, 'group-123');
      verify(
        () => groupRepository.saveConfirmingGroup(
          groupId: 'group-123',
          groupName: 'Test Family',
          role: 'owner',
          keyEpoch: 1,
          members: const [
            GroupMember(
              deviceId: 'device-1',
              publicKey: 'key-1',
              deviceName: 'My Phone',
              role: 'owner',
              status: 'active',
              displayName: 'Owner',
              avatarEmoji: '🏠',
            ),
            GroupMember(
              deviceId: 'device-2',
              publicKey: 'key-2',
              deviceName: 'Partner Phone',
              role: 'member',
              status: 'active',
              displayName: 'Partner',
              avatarEmoji: '🏠',
            ),
          ],
        ),
      ).called(1);
      verifyNever(
        () => groupRepository.restoreActiveGroup(
          groupId: any(named: 'groupId'),
          role: any(named: 'role'),
          inviteCode: any(named: 'inviteCode'),
          inviteExpiresAt: any(named: 'inviteExpiresAt'),
          groupKey: any(named: 'groupKey'),
          members: any(named: 'members'),
        ),
      );
      verifyNever(() => groupRepository.confirmLocalGroup(any()));
    },
  );

  test(
    'demotes a legacy active snapshot when its group key is missing',
    () async {
      when(
        () => apiClient.checkGroup(),
      ).thenAnswer((_) async => {'groupExisted': true, 'groupId': 'group-123'});
      when(() => apiClient.getGroupStatus('group-123')).thenAnswer(
        (_) async => {
          'groupId': 'group-123',
          'status': 'active',
          'groupName': 'Test Family',
          'members': [
            {
              'deviceId': 'device-1',
              'publicKey': 'key-1',
              'deviceName': 'My Phone',
              'role': 'member',
              'status': 'active',
              'displayName': 'Me',
              'avatarEmoji': '🏠',
            },
          ],
        },
      );
      when(() => groupRepository.getGroupById('group-123')).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-123',
          groupName: 'Test Family',
          status: GroupStatus.active,
          role: 'member',
          members: const [],
          createdAt: DateTime(2026, 3, 14),
        ),
      );

      final result = await useCase.execute();

      expect(result, isA<CheckGroupAwaitingKey>());
      verify(() => groupRepository.markGroupConfirming('group-123')).called(1);
      verifyNever(() => groupRepository.confirmLocalGroup(any()));
    },
  );

  test(
    'does not activate when the current server member is still pending',
    () async {
      when(
        () => apiClient.checkGroup(),
      ).thenAnswer((_) async => {'groupExisted': true, 'groupId': 'group-123'});
      when(() => apiClient.getGroupStatus('group-123')).thenAnswer(
        (_) async => {
          'groupId': 'group-123',
          'status': 'active',
          'groupName': 'Test Family',
          'members': [
            {
              'deviceId': 'device-1',
              'publicKey': 'key-1',
              'deviceName': 'My Phone',
              'role': 'member',
              'status': 'pending',
              'displayName': 'Me',
              'avatarEmoji': '🏠',
            },
            {
              'deviceId': 'device-2',
              'publicKey': 'key-2',
              'deviceName': 'Owner Phone',
              'role': 'owner',
              'status': 'active',
              'displayName': 'Owner',
              'avatarEmoji': '🏠',
            },
          ],
        },
      );
      when(() => groupRepository.getGroupById('group-123')).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-123',
          groupName: 'Test Family',
          status: GroupStatus.active,
          role: 'member',
          groupKey: 'old-group-key',
          members: const [],
          createdAt: DateTime(2026, 3, 14),
        ),
      );

      final result = await useCase.execute();

      expect(result, isA<CheckGroupPendingApproval>());
      verify(() => groupRepository.updateMembers('group-123', any())).called(1);
      verify(() => groupRepository.markGroupConfirming('group-123')).called(1);
      verifyNever(() => groupRepository.confirmLocalGroup(any()));
      verifyNever(
        () => groupRepository.restoreActiveGroup(
          groupId: any(named: 'groupId'),
          role: any(named: 'role'),
          inviteCode: any(named: 'inviteCode'),
          inviteExpiresAt: any(named: 'inviteExpiresAt'),
          groupKey: any(named: 'groupKey'),
          members: any(named: 'members'),
        ),
      );
    },
  );

  test(
    'confirms and refreshes an existing local group when server reports it active',
    () async {
      when(
        () => apiClient.checkGroup(),
      ).thenAnswer((_) async => {'groupExisted': true, 'groupId': 'group-123'});
      when(() => apiClient.getGroupStatus('group-123')).thenAnswer(
        (_) async => {
          'groupId': 'group-123',
          'status': 'active',
          'groupName': 'Renamed family',
          'keyEpoch': 1,
          'inviteCode': '654321',
          'inviteExpiresAt': 1709654400,
          'members': [
            {
              'deviceId': 'device-1',
              'publicKey': 'key-1',
              'deviceName': 'My Phone',
              'role': 'member',
              'status': 'active',
              'displayName': 'Me',
              'avatarEmoji': '🏠',
            },
            {
              'deviceId': 'device-2',
              'publicKey': 'key-2',
              'deviceName': 'Owner Phone',
              'role': 'owner',
              'status': 'active',
              'displayName': 'Owner',
              'avatarEmoji': '🏠',
            },
          ],
        },
      );
      when(() => groupRepository.getGroupById('group-123')).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-123',
          groupName: 'Test Family',
          status: GroupStatus.confirming,
          role: 'member',
          groupKey: 'group-key',
          members: const [
            GroupMember(
              deviceId: 'device-1',
              publicKey: 'key-1',
              deviceName: 'My Phone',
              role: 'member',
              status: 'pending',
              displayName: 'Me',
              avatarEmoji: '🏠',
            ),
          ],
          createdAt: DateTime(2026, 3, 14),
        ),
      );

      final result = await useCase.execute();

      expect(result, isA<CheckGroupInGroup>());
      verify(() => groupRepository.confirmLocalGroup('group-123')).called(1);
      verify(
        () => groupRepository.updateGroupName('group-123', 'Renamed family'),
      ).called(1);
      verify(
        () => groupRepository.updateMembers('group-123', const [
          GroupMember(
            deviceId: 'device-1',
            publicKey: 'key-1',
            deviceName: 'My Phone',
            role: 'member',
            status: 'active',
            displayName: 'Me',
            avatarEmoji: '🏠',
          ),
          GroupMember(
            deviceId: 'device-2',
            publicKey: 'key-2',
            deviceName: 'Owner Phone',
            role: 'owner',
            status: 'active',
            displayName: 'Owner',
            avatarEmoji: '🏠',
          ),
        ]),
      ).called(1);
      verify(
        () => groupRepository.updateInviteCode(
          'group-123',
          '654321',
          DateTime.fromMillisecondsSinceEpoch(1709654400 * 1000),
        ),
      ).called(1);
    },
  );

  test(
    'applies a missed owner transfer epoch and waits for the rotated key',
    () async {
      when(
        () => apiClient.checkGroup(),
      ).thenAnswer((_) async => {'groupExisted': true, 'groupId': 'group-123'});
      when(() => apiClient.getGroupStatus('group-123')).thenAnswer(
        (_) async => {
          'groupId': 'group-123',
          'status': 'active',
          'groupName': 'Test Family',
          'keyEpoch': 4,
          'members': [
            {
              'deviceId': 'device-1',
              'publicKey': 'key-1',
              'deviceName': 'My Phone',
              'role': 'owner',
              'status': 'active',
              'displayName': 'Me',
              'avatarEmoji': '🏠',
            },
          ],
        },
      );
      when(() => groupRepository.getGroupById('group-123')).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-123',
          groupName: 'Test Family',
          status: GroupStatus.active,
          role: 'member',
          groupKey: 'retired-key',
          keyEpoch: 3,
          members: const [],
          createdAt: DateTime(2026, 3, 14),
        ),
      );

      final result = await useCase.execute();

      expect(result, isA<CheckGroupAwaitingKey>());
      verify(
        () => groupRepository.applyAuthoritativeSnapshot(
          groupId: 'group-123',
          groupName: 'Test Family',
          role: 'owner',
          keyEpoch: 4,
          members: any(named: 'members'),
        ),
      ).called(1);
      verify(() => groupRepository.markGroupConfirming('group-123')).called(1);
    },
  );

  test('returns API failures as an error result', () async {
    when(() => apiClient.checkGroup()).thenThrow(
      const RelayApiException(statusCode: 500, message: 'Server error'),
    );

    final result = await useCase.execute();

    expect(result, isA<CheckGroupError>());
    expect((result as CheckGroupError).message, 'Server error');
  });

  test(
    'classifies transport failures without exposing the request URI',
    () async {
      when(
        () => apiClient.registerDevice(
          deviceId: any(named: 'deviceId'),
          publicKey: any(named: 'publicKey'),
          deviceName: any(named: 'deviceName'),
          platform: any(named: 'platform'),
        ),
      ).thenThrow(
        http.ClientException(
          'Failed host lookup: sync.happypocket.app',
          Uri.parse('https://sync.happypocket.app/api/v1/device/register'),
        ),
      );

      final result = await useCase.execute();

      expect(result, isA<CheckGroupError>());
      final error = result as CheckGroupError;
      expect(error.kind, GroupOperationErrorKind.networkUnavailable);
      expect(error.message, 'Network unavailable');
      expect(error.message, isNot(contains('happypocket.app')));
    },
  );
}
