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
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/application/family_sync/remove_member_use_case.dart';
import 'package:home_pocket/application/family_sync/membership_rotation_coordinator.dart';
import 'package:home_pocket/application/family_sync/rotate_group_key_use_case.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class _FakeRelayApiClient extends Mock implements RelayApiClient {}

class _FakeGroupRepository extends Mock implements GroupRepository {}

class _FakeRotateGroupKeyUseCase extends Mock
    implements RotateGroupKeyUseCase {}

class _FakeMembershipRotationCoordinator extends Mock
    implements MembershipRotationCoordinator {}

void main() {
  group('RemoveMemberUseCase characterization', () {
    late _FakeRelayApiClient fakeApiClient;
    late _FakeGroupRepository fakeGroupRepository;
    late _FakeRotateGroupKeyUseCase fakeRotateGroupKey;
    late _FakeMembershipRotationCoordinator membershipRotation;
    late RemoveMemberUseCase useCase;

    setUp(() {
      fakeApiClient = _FakeRelayApiClient();
      fakeGroupRepository = _FakeGroupRepository();
      fakeRotateGroupKey = _FakeRotateGroupKeyUseCase();
      membershipRotation = _FakeMembershipRotationCoordinator();

      when(
        () => fakeRotateGroupKey.execute(
          groupId: any(named: 'groupId'),
          authoritativeEpoch: any(named: 'authoritativeEpoch'),
          removedDeviceId: any(named: 'removedDeviceId'),
        ),
      ).thenAnswer((_) async {});

      useCase = RemoveMemberUseCase(
        apiClient: fakeApiClient,
        groupRepository: fakeGroupRepository,
        rotateGroupKey: fakeRotateGroupKey,
        membershipRotation: membershipRotation,
      );
    });

    test(
      'returns success when member removed from server and local repo updated',
      () async {
        when(
          () => membershipRotation.removeMember(
            groupId: 'group-1',
            targetDeviceId: 'member-1',
          ),
        ).thenAnswer((_) async => {'status': 'ok', 'keyEpoch': 2});

        final result = await useCase.execute(
          groupId: 'group-1',
          deviceId: 'member-1',
        );

        expect(result, isA<RemoveMemberSuccess>());
      },
    );

    test(
      'calls updateMembers with remaining members only (target member excluded)',
      () async {
        when(
          () => membershipRotation.removeMember(
            groupId: 'group-1',
            targetDeviceId: 'member-1',
          ),
        ).thenAnswer((_) async => {'status': 'ok', 'keyEpoch': 2});

        await useCase.execute(groupId: 'group-1', deviceId: 'member-1');

        verify(
          () => membershipRotation.removeMember(
            groupId: 'group-1',
            targetDeviceId: 'member-1',
          ),
        ).called(1);
      },
    );

    test('skips updateMembers when group not found in repository', () async {
      when(
        () => membershipRotation.removeMember(
          groupId: any(named: 'groupId'),
          targetDeviceId: any(named: 'targetDeviceId'),
        ),
      ).thenThrow(StateError('active family not found'));

      final result = await useCase.execute(
        groupId: 'group-1',
        deviceId: 'member-1',
      );

      expect(result, isA<RemoveMemberError>());
      verifyNever(() => fakeGroupRepository.updateMembers(any(), any()));
    });

    test('returns error when RelayApiException is thrown', () async {
      when(
        () => membershipRotation.removeMember(
          groupId: any(named: 'groupId'),
          targetDeviceId: any(named: 'targetDeviceId'),
        ),
      ).thenThrow(
        const RelayApiException(statusCode: 403, message: 'not authorized'),
      );

      final result = await useCase.execute(
        groupId: 'group-1',
        deviceId: 'member-1',
      );

      expect(result, isA<RemoveMemberError>());
      final error = result as RemoveMemberError;
      expect(error.message, equals('not authorized'));
    });

    test(
      'returns error with prefixed message when generic exception is thrown',
      () async {
        when(
          () => membershipRotation.removeMember(
            groupId: any(named: 'groupId'),
            targetDeviceId: any(named: 'targetDeviceId'),
          ),
        ).thenThrow(Exception('network timeout'));

        final result = await useCase.execute(
          groupId: 'group-1',
          deviceId: 'member-1',
        );

        expect(result, isA<RemoveMemberError>());
        final error = result as RemoveMemberError;
        expect(error.message, contains('Failed to remove member'));
      },
    );
  });
}
