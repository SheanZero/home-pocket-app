// Characterization test: locks RemoveMemberUseCase behavior pre-Plan-03-03 move.
//
// Per Phase 3 D-15 (CONTEXT.md): tests written BEFORE refactor lands.
// Plan 03-03 Task 5 will move the production file from
//   lib/features/family_sync/use_cases/remove_member_use_case.dart
// to
//   lib/application/family_sync/remove_member_use_case.dart
// and this test's import line gets rewritten as part of that PR.
//
// The test asserts the CURRENT observable behavior. Post-move it must
// still pass — proving the move was a pure refactor (PROJECT.md
// behavior preservation).

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/application/family_sync/remove_member_use_case.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class _FakeRelayApiClient extends Mock implements RelayApiClient {}

class _FakeGroupRepository extends Mock implements GroupRepository {}

const _owner = GroupMember(
  deviceId: 'owner-1',
  publicKey: 'pk-owner',
  deviceName: 'Owner Phone',
  role: 'owner',
  status: 'active',
  displayName: 'Owner',
  avatarEmoji: '🏠',
);

const _memberToRemove = GroupMember(
  deviceId: 'member-1',
  publicKey: 'pk-member',
  deviceName: 'Member Tablet',
  role: 'member',
  status: 'active',
  displayName: 'Member',
  avatarEmoji: '👤',
);

GroupInfo _buildGroupInfo({List<GroupMember>? members}) => GroupInfo(
      groupId: 'group-1',
      groupName: 'Test Family',
      status: GroupStatus.active,
      role: 'owner',
      members: members ?? const [_owner, _memberToRemove],
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('RemoveMemberUseCase characterization', () {
    late _FakeRelayApiClient fakeApiClient;
    late _FakeGroupRepository fakeGroupRepository;
    late RemoveMemberUseCase useCase;

    setUp(() {
      fakeApiClient = _FakeRelayApiClient();
      fakeGroupRepository = _FakeGroupRepository();

      useCase = RemoveMemberUseCase(
        apiClient: fakeApiClient,
        groupRepository: fakeGroupRepository,
      );
    });

    test('returns success when member removed from server and local repo updated', () async {
      when(
        () => fakeApiClient.removeMember(groupId: 'group-1', deviceId: 'member-1'),
      ).thenAnswer((_) async => {'status': 'ok'});
      when(() => fakeGroupRepository.getGroupById('group-1')).thenAnswer(
        (_) async => _buildGroupInfo(),
      );
      when(() => fakeGroupRepository.updateMembers(any(), any())).thenAnswer((_) async {});

      final result = await useCase.execute(groupId: 'group-1', deviceId: 'member-1');

      expect(result, isA<RemoveMemberSuccess>());
    });

    test('calls updateMembers with remaining members only (target member excluded)', () async {
      when(
        () => fakeApiClient.removeMember(groupId: 'group-1', deviceId: 'member-1'),
      ).thenAnswer((_) async => {'status': 'ok'});
      when(() => fakeGroupRepository.getGroupById('group-1')).thenAnswer(
        (_) async => _buildGroupInfo(),
      );
      when(() => fakeGroupRepository.updateMembers(any(), any())).thenAnswer((_) async {});

      await useCase.execute(groupId: 'group-1', deviceId: 'member-1');

      verify(
        () => fakeGroupRepository.updateMembers('group-1', [_owner]),
      ).called(1);
    });

    test('skips updateMembers when group not found in repository', () async {
      when(
        () => fakeApiClient.removeMember(groupId: any(named: 'groupId'), deviceId: any(named: 'deviceId')),
      ).thenAnswer((_) async => {'status': 'ok'});
      when(() => fakeGroupRepository.getGroupById(any())).thenAnswer(
        (_) async => null,
      );

      final result = await useCase.execute(groupId: 'group-1', deviceId: 'member-1');

      // Still succeeds — API call succeeded; null group means local state doesn't need updating
      expect(result, isA<RemoveMemberSuccess>());
      verifyNever(() => fakeGroupRepository.updateMembers(any(), any()));
    });

    test('returns error when RelayApiException is thrown', () async {
      when(
        () => fakeApiClient.removeMember(groupId: any(named: 'groupId'), deviceId: any(named: 'deviceId')),
      ).thenThrow(
        const RelayApiException(statusCode: 403, message: 'not authorized'),
      );

      final result = await useCase.execute(groupId: 'group-1', deviceId: 'member-1');

      expect(result, isA<RemoveMemberError>());
      final error = result as RemoveMemberError;
      expect(error.message, equals('not authorized'));
    });

    test('returns error with prefixed message when generic exception is thrown', () async {
      when(
        () => fakeApiClient.removeMember(groupId: any(named: 'groupId'), deviceId: any(named: 'deviceId')),
      ).thenThrow(Exception('network timeout'));

      final result = await useCase.execute(groupId: 'group-1', deviceId: 'member-1');

      expect(result, isA<RemoveMemberError>());
      final error = result as RemoveMemberError;
      expect(error.message, contains('Failed to remove member'));
    });
  });
}
