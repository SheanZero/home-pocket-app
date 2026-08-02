import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/join_request_lifecycle_use_cases.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockRelayApiClient apiClient;
  late MockGroupRepository groupRepository;

  setUp(() {
    apiClient = MockRelayApiClient();
    groupRepository = MockGroupRepository();
  });

  test('status maps the complete server lifecycle', () async {
    final useCase = GetJoinRequestStatusUseCase(apiClient: apiClient);
    for (final status in JoinRequestStatus.values) {
      when(
        () => apiClient.getJoinRequestStatus('group-1'),
      ).thenAnswer((_) async => {'status': status.name});

      final result = await useCase.execute(groupId: 'group-1');

      expect(result, isA<JoinRequestLifecycleSuccess>());
      expect((result as JoinRequestLifecycleSuccess).status, status);
    }
  });

  test(
    'reject removes only the pending applicant from local snapshot',
    () async {
      const applicant = GroupMember(
        deviceId: 'applicant',
        publicKey: 'pk-applicant',
        deviceName: 'Applicant phone',
        displayName: 'Applicant',
        avatarEmoji: '🏠',
        role: 'member',
        status: 'pending',
      );
      const owner = GroupMember(
        deviceId: 'owner',
        publicKey: 'pk-owner',
        deviceName: 'Owner phone',
        displayName: 'Owner',
        avatarEmoji: '🏠',
        role: 'owner',
        status: 'active',
      );
      final group = GroupInfo(
        groupId: 'group-1',
        groupName: 'Family',
        status: GroupStatus.active,
        role: 'owner',
        members: const [owner, applicant],
        createdAt: DateTime(2026),
      );
      when(
        () => apiClient.rejectJoinRequest(
          groupId: 'group-1',
          deviceId: 'applicant',
        ),
      ).thenAnswer((_) async => {'status': 'rejected'});
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => group);
      when(
        () => groupRepository.updateMembers('group-1', any()),
      ).thenAnswer((_) async {});

      final result = await RejectJoinRequestUseCase(
        apiClient: apiClient,
        groupRepository: groupRepository,
      ).execute(groupId: 'group-1', deviceId: 'applicant');

      expect(result, isA<JoinRequestLifecycleSuccess>());
      final captured =
          verify(
                () => groupRepository.updateMembers('group-1', captureAny()),
              ).captured.single
              as List<GroupMember>;
      expect(captured, [owner]);
    },
  );

  test(
    'cancel resolves remotely and deactivates confirming local group',
    () async {
      when(
        () => apiClient.cancelJoinRequest('group-1'),
      ).thenAnswer((_) async => {'status': 'cancelled'});
      when(
        () => groupRepository.deactivateGroup('group-1'),
      ).thenAnswer((_) async {});

      final result = await CancelJoinRequestUseCase(
        apiClient: apiClient,
        groupRepository: groupRepository,
      ).execute(groupId: 'group-1');

      expect(
        (result as JoinRequestLifecycleSuccess).status,
        JoinRequestStatus.cancelled,
      );
      verify(() => groupRepository.deactivateGroup('group-1')).called(1);
    },
  );

  test(
    'unknown status is rejected instead of silently polling forever',
    () async {
      when(
        () => apiClient.getJoinRequestStatus('group-1'),
      ).thenAnswer((_) async => {'status': 'mystery'});

      final result = await GetJoinRequestStatusUseCase(
        apiClient: apiClient,
      ).execute(groupId: 'group-1');

      expect(result, isA<JoinRequestLifecycleError>());
    },
  );
}
