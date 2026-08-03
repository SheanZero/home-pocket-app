import '../../infrastructure/sync/relay_api_client.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import 'rotate_group_key_use_case.dart';
import 'membership_rotation_coordinator.dart';
import 'group_operation_error.dart';

sealed class RemoveMemberResult {
  const RemoveMemberResult();

  const factory RemoveMemberResult.success() = RemoveMemberSuccess;
  const factory RemoveMemberResult.error(
    String message, {
    GroupOperationErrorKind kind,
  }) = RemoveMemberError;
}

class RemoveMemberSuccess extends RemoveMemberResult {
  const RemoveMemberSuccess();
}

class RemoveMemberError extends RemoveMemberResult
    implements GroupOperationFailure {
  const RemoveMemberError(
    this.message, {
    this.kind = GroupOperationErrorKind.general,
  });

  @override
  final String message;
  @override
  final GroupOperationErrorKind kind;
}

class RemoveMemberUseCase {
  RemoveMemberUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
    required RotateGroupKeyUseCase rotateGroupKey,
    MembershipRotationCoordinator? membershipRotation,
  }) : _membershipRotation = membershipRotation;

  final MembershipRotationCoordinator? _membershipRotation;

  Future<RemoveMemberResult> execute({
    required String groupId,
    required String deviceId,
  }) async {
    try {
      final coordinator = _membershipRotation;
      if (coordinator == null) {
        throw StateError('Crash-safe membership rotation is unavailable');
      }
      await coordinator.removeMember(
        groupId: groupId,
        targetDeviceId: deviceId,
      );
      return const RemoveMemberResult.success();
    } catch (error) {
      final failure = groupOperationFailureFrom(
        error,
        fallbackMessage: 'Failed to remove member',
      );
      return RemoveMemberResult.error(failure.message, kind: failure.kind);
    }
  }
}
