import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/use_cases/check_group_use_case.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
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
      () => groupRepository.confirmLocalGroup(any()),
    ).thenAnswer((_) async {});
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
    'restores local active group when server group exists but local data is missing',
    () async {
      when(
        () => apiClient.checkGroup(),
      ).thenAnswer((_) async => {'groupExisted': true, 'groupId': 'group-123'});
      when(() => apiClient.getGroupStatus('group-123')).thenAnswer(
        (_) async => {
          'groupId': 'group-123',
          'status': 'active',
          'inviteCode': '123456',
          'inviteExpiresAt': 1709654400,
          'members': [
            {
              'deviceId': 'device-1',
              'publicKey': 'key-1',
              'deviceName': 'My Phone',
              'role': 'owner',
              'status': 'active',
            },
            {
              'deviceId': 'device-2',
              'publicKey': 'key-2',
              'deviceName': 'Partner Phone',
              'role': 'member',
              'status': 'active',
            },
          ],
        },
      );
      when(
        () => groupRepository.getGroupById('group-123'),
      ).thenAnswer((_) async => null);

      final result = await useCase.execute();

      expect(result, isA<CheckGroupInGroup>());
      expect((result as CheckGroupInGroup).groupId, 'group-123');
      verify(
        () => groupRepository.restoreActiveGroup(
          groupId: 'group-123',
          role: 'owner',
          inviteCode: '123456',
          inviteExpiresAt: DateTime.fromMillisecondsSinceEpoch(
            1709654400 * 1000,
          ),
          groupKey: null,
          members: const [
            GroupMember(
              deviceId: 'device-1',
              publicKey: 'key-1',
              deviceName: 'My Phone',
              role: 'owner',
              status: 'active',
            ),
            GroupMember(
              deviceId: 'device-2',
              publicKey: 'key-2',
              deviceName: 'Partner Phone',
              role: 'member',
              status: 'active',
            ),
          ],
        ),
      ).called(1);
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
          'inviteCode': '654321',
          'inviteExpiresAt': 1709654400,
          'members': [
            {
              'deviceId': 'device-1',
              'publicKey': 'key-1',
              'deviceName': 'My Phone',
              'role': 'member',
              'status': 'active',
            },
            {
              'deviceId': 'device-2',
              'publicKey': 'key-2',
              'deviceName': 'Owner Phone',
              'role': 'owner',
              'status': 'active',
            },
          ],
        },
      );
      when(() => groupRepository.getGroupById('group-123')).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-123',
          status: GroupStatus.confirming,
          role: 'member',
          members: const [
            GroupMember(
              deviceId: 'device-1',
              publicKey: 'key-1',
              deviceName: 'My Phone',
              role: 'member',
              status: 'pending',
            ),
          ],
          createdAt: DateTime(2026, 3, 14),
        ),
      );

      final result = await useCase.execute();

      expect(result, isA<CheckGroupInGroup>());
      verify(() => groupRepository.confirmLocalGroup('group-123')).called(1);
      verify(
        () => groupRepository.updateMembers('group-123', const [
          GroupMember(
            deviceId: 'device-1',
            publicKey: 'key-1',
            deviceName: 'My Phone',
            role: 'member',
            status: 'active',
          ),
          GroupMember(
            deviceId: 'device-2',
            publicKey: 'key-2',
            deviceName: 'Owner Phone',
            role: 'owner',
            status: 'active',
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

  test('returns API failures as an error result', () async {
    when(() => apiClient.checkGroup()).thenThrow(
      const RelayApiException(statusCode: 500, message: 'Server error'),
    );

    final result = await useCase.execute();

    expect(result, isA<CheckGroupError>());
    expect((result as CheckGroupError).message, 'Server error');
  });
}
