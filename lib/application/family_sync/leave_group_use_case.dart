import 'shadow_book_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import 'membership_rotation_coordinator.dart';

sealed class LeaveGroupResult {
  const LeaveGroupResult();

  const factory LeaveGroupResult.success() = LeaveGroupSuccess;
  const factory LeaveGroupResult.error(String message) = LeaveGroupError;
}

class LeaveGroupSuccess extends LeaveGroupResult {
  const LeaveGroupSuccess();
}

class LeaveGroupError extends LeaveGroupResult {
  const LeaveGroupError(this.message);

  final String message;
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
    } on RelayApiException catch (error) {
      return LeaveGroupResult.error(error.message);
    } catch (error) {
      return LeaveGroupResult.error(error.toString());
    }
  }
}
