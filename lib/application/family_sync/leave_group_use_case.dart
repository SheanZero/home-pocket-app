import 'shadow_book_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import 'membership_rotation_coordinator.dart';
import 'group_operation_error.dart';

sealed class LeaveGroupResult {
  const LeaveGroupResult();

  const factory LeaveGroupResult.success() = LeaveGroupSuccess;
  const factory LeaveGroupResult.error(
    String message, {
    GroupOperationErrorKind kind,
  }) = LeaveGroupError;
}

class LeaveGroupSuccess extends LeaveGroupResult {
  const LeaveGroupSuccess();
}

class LeaveGroupError extends LeaveGroupResult
    implements GroupOperationFailure {
  const LeaveGroupError(
    this.message, {
    this.kind = GroupOperationErrorKind.general,
  });

  @override
  final String message;
  @override
  final GroupOperationErrorKind kind;
}

class LeaveGroupUseCase {
  LeaveGroupUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
    required SyncQueueManager queueManager,
    ShadowBookService? shadowBookService,
    MembershipRotationCoordinator? membershipRotation,
  }) : _membershipRotation = membershipRotation;

  final MembershipRotationCoordinator? _membershipRotation;

  Future<LeaveGroupResult> execute(String groupId) async {
    try {
      final coordinator = _membershipRotation;
      if (coordinator == null) {
        throw StateError('Crash-safe membership rotation is unavailable');
      }
      final intent = await coordinator.submitSelfLeave(groupId);
      await coordinator.finalizeSelfLeave(intent);
      return const LeaveGroupResult.success();
    } catch (error) {
      final failure = groupOperationFailureFrom(
        error,
        fallbackMessage: 'Failed to leave group',
      );
      return LeaveGroupResult.error(failure.message, kind: failure.kind);
    }
  }
}
