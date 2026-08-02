import '../../infrastructure/sync/relay_api_client.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import 'rotate_group_key_use_case.dart';
import 'membership_rotation_coordinator.dart';

sealed class RemoveMemberResult {
  const RemoveMemberResult();

  const factory RemoveMemberResult.success() = RemoveMemberSuccess;
  const factory RemoveMemberResult.error(String message) = RemoveMemberError;
}

class RemoveMemberSuccess extends RemoveMemberResult {
  const RemoveMemberSuccess();
}

class RemoveMemberError extends RemoveMemberResult {
  const RemoveMemberError(this.message);

  final String message;
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
    } on RelayApiException catch (error) {
      return RemoveMemberResult.error(error.message);
    } catch (error) {
      return RemoveMemberResult.error('Failed to remove member: $error');
    }
  }
}
