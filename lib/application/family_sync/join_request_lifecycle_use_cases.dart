import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import 'group_operation_error.dart';

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

class JoinRequestLifecycleError extends JoinRequestLifecycleResult
    implements GroupOperationFailure {
  const JoinRequestLifecycleError(
    this.message, {
    this.kind = GroupOperationErrorKind.general,
  });

  @override
  final String message;
  @override
  final GroupOperationErrorKind kind;
}

class GetJoinRequestStatusUseCase {
  const GetJoinRequestStatusUseCase({required this._apiClient});

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
    } catch (error) {
      final failure = groupOperationFailureFrom(
        error,
        fallbackMessage: 'Failed to check join request status',
      );
      return JoinRequestLifecycleError(failure.message, kind: failure.kind);
    }
  }
}

class RejectJoinRequestUseCase {
  const RejectJoinRequestUseCase({
    required this._apiClient,
    required this._groupRepository,
  });

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
    } catch (error) {
      final failure = groupOperationFailureFrom(
        error,
        fallbackMessage: 'Failed to reject join request',
      );
      return JoinRequestLifecycleError(failure.message, kind: failure.kind);
    }
  }
}

class CancelJoinRequestUseCase {
  const CancelJoinRequestUseCase({
    required this._apiClient,
    required this._groupRepository,
  });

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
    } catch (error) {
      final failure = groupOperationFailureFrom(
        error,
        fallbackMessage: 'Failed to cancel join request',
      );
      if (failure.kind == GroupOperationErrorKind.notFound) {
        try {
          // The relay is authoritative. A missing request row means there is
          // nothing left to cancel, so converge the stale local cache instead
          // of surfacing the transport detail to the user.
          await _groupRepository.deactivateGroup(groupId);
          return const JoinRequestLifecycleSuccess(JoinRequestStatus.cancelled);
        } catch (localError) {
          final localFailure = groupOperationFailureFrom(
            localError,
            fallbackMessage: 'Failed to clear cancelled join request',
          );
          return JoinRequestLifecycleError(
            localFailure.message,
            kind: localFailure.kind,
          );
        }
      }
      return JoinRequestLifecycleError(failure.message, kind: failure.kind);
    }
  }
}
