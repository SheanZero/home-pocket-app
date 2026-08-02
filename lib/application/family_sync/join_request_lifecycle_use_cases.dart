import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/relay_api_client.dart';

enum JoinRequestStatus { pending, approved, rejected, cancelled, expired }

extension JoinRequestStatusX on JoinRequestStatus {
  bool get isTerminal => switch (this) {
    JoinRequestStatus.rejected ||
    JoinRequestStatus.cancelled ||
    JoinRequestStatus.expired => true,
    JoinRequestStatus.pending || JoinRequestStatus.approved => false,
  };

  static JoinRequestStatus? parse(Object? value) => switch (value) {
    'pending' => JoinRequestStatus.pending,
    'approved' => JoinRequestStatus.approved,
    'rejected' => JoinRequestStatus.rejected,
    'cancelled' => JoinRequestStatus.cancelled,
    'expired' => JoinRequestStatus.expired,
    _ => null,
  };
}

sealed class JoinRequestLifecycleResult {
  const JoinRequestLifecycleResult();
}

class JoinRequestLifecycleSuccess extends JoinRequestLifecycleResult {
  const JoinRequestLifecycleSuccess(this.status);

  final JoinRequestStatus status;
}

class JoinRequestLifecycleError extends JoinRequestLifecycleResult {
  const JoinRequestLifecycleError(this.message);

  final String message;
}

class GetJoinRequestStatusUseCase {
  const GetJoinRequestStatusUseCase({required RelayApiClient apiClient})
    : _apiClient = apiClient;

  final RelayApiClient _apiClient;

  Future<JoinRequestLifecycleResult> execute({required String groupId}) async {
    try {
      final response = await _apiClient.getJoinRequestStatus(groupId);
      final status = JoinRequestStatusX.parse(response['status']);
      if (status == null) {
        return const JoinRequestLifecycleError(
          'Server returned an unknown join request status',
        );
      }
      return JoinRequestLifecycleSuccess(status);
    } on RelayApiException catch (error) {
      return JoinRequestLifecycleError(error.message);
    } catch (error) {
      return JoinRequestLifecycleError(
        'Failed to check join request status: $error',
      );
    }
  }
}

class RejectJoinRequestUseCase {
  const RejectJoinRequestUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;

  Future<JoinRequestLifecycleResult> execute({
    required String groupId,
    required String deviceId,
  }) async {
    try {
      final response = await _apiClient.rejectJoinRequest(
        groupId: groupId,
        deviceId: deviceId,
      );
      final status = JoinRequestStatusX.parse(response['status']);
      if (status != JoinRequestStatus.rejected &&
          status != JoinRequestStatus.expired) {
        return const JoinRequestLifecycleError(
          'Server did not resolve the join request',
        );
      }

      final group = await _groupRepository.getGroupById(groupId);
      if (group != null) {
        await _groupRepository.updateMembers(
          groupId,
          group.members.where((member) => member.deviceId != deviceId).toList(),
        );
      }
      return JoinRequestLifecycleSuccess(status!);
    } on RelayApiException catch (error) {
      return JoinRequestLifecycleError(error.message);
    } catch (error) {
      return JoinRequestLifecycleError('Failed to reject join request: $error');
    }
  }
}

class CancelJoinRequestUseCase {
  const CancelJoinRequestUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;

  Future<JoinRequestLifecycleResult> execute({required String groupId}) async {
    try {
      final response = await _apiClient.cancelJoinRequest(groupId);
      final status = JoinRequestStatusX.parse(response['status']);
      if (status != JoinRequestStatus.cancelled &&
          status != JoinRequestStatus.expired) {
        return const JoinRequestLifecycleError(
          'Server did not cancel the join request',
        );
      }
      await _groupRepository.deactivateGroup(groupId);
      return JoinRequestLifecycleSuccess(status!);
    } on RelayApiException catch (error) {
      return JoinRequestLifecycleError(error.message);
    } catch (error) {
      return JoinRequestLifecycleError('Failed to cancel join request: $error');
    }
  }
}
