import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/application/family_sync/remove_member_use_case.dart';
import 'package:home_pocket/application/family_sync/membership_rotation_coordinator.dart';
import 'package:home_pocket/application/family_sync/rotate_group_key_use_case.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockRotateGroupKeyUseCase extends Mock implements RotateGroupKeyUseCase {}

class MockMembershipRotationCoordinator extends Mock
    implements MembershipRotationCoordinator {}

void main() {
  late MockRelayApiClient apiClient;
  late MockGroupRepository groupRepository;
  late MockRotateGroupKeyUseCase rotateGroupKey;
  late MockMembershipRotationCoordinator membershipRotation;
  late RemoveMemberUseCase useCase;

  setUp(() {
    apiClient = MockRelayApiClient();
    groupRepository = MockGroupRepository();
    rotateGroupKey = MockRotateGroupKeyUseCase();
    membershipRotation = MockMembershipRotationCoordinator();
    useCase = RemoveMemberUseCase(
      apiClient: apiClient,
      groupRepository: groupRepository,
      rotateGroupKey: rotateGroupKey,
      membershipRotation: membershipRotation,
    );
  });

  test('removes a member from the local group after server success', () async {
    when(
      () => membershipRotation.removeMember(
        groupId: 'group-1',
        targetDeviceId: 'member-1',
      ),
    ).thenAnswer((_) async => {'status': 'removed', 'keyEpoch': 2});

    final result = await useCase.execute(
      groupId: 'group-1',
      deviceId: 'member-1',
    );

    expect(result, isA<RemoveMemberSuccess>());
    verify(
      () => membershipRotation.removeMember(
        groupId: 'group-1',
        targetDeviceId: 'member-1',
      ),
    ).called(1);
  });
}
