import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/application/family_sync/remove_member_use_case.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockRelayApiClient apiClient;
  late MockGroupRepository groupRepository;
  late RemoveMemberUseCase useCase;

  setUp(() {
    apiClient = MockRelayApiClient();
    groupRepository = MockGroupRepository();
    useCase = RemoveMemberUseCase(
      apiClient: apiClient,
      groupRepository: groupRepository,
    );
  });

  test('removes a member from the local group after server success', () async {
    when(
      () => apiClient.removeMember(groupId: 'group-1', deviceId: 'member-1'),
    ).thenAnswer((_) async => {'status': 'ok'});
    when(() => groupRepository.getGroupById('group-1')).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        groupKey: 'group-key',
        members: const [
          GroupMember(
            deviceId: 'owner-1',
            publicKey: 'pk-owner',
            deviceName: 'Owner phone',
            role: 'owner',
            status: 'active',
            displayName: 'Owner',
            avatarEmoji: '🏠',
          ),
          GroupMember(
            deviceId: 'member-1',
            publicKey: 'pk-member',
            deviceName: 'Kitchen tablet',
            role: 'member',
            status: 'active',
            displayName: 'Member',
            avatarEmoji: '🏠',
          ),
        ],
        createdAt: DateTime(2026),
      ),
    );
    when(
      () => groupRepository.updateMembers(any(), any()),
    ).thenAnswer((_) async {});

    final result = await useCase.execute(
      groupId: 'group-1',
      deviceId: 'member-1',
    );

    expect(result, isA<RemoveMemberSuccess>());
    verify(
      () => groupRepository.updateMembers('group-1', [
        const GroupMember(
          deviceId: 'owner-1',
          publicKey: 'pk-owner',
          deviceName: 'Owner phone',
          role: 'owner',
          status: 'active',
          displayName: 'Owner',
          avatarEmoji: '🏠',
        ),
      ]),
    ).called(1);
  });
}
