import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import 'group_operation_error.dart';

sealed class ConfirmJoinResult {
  const ConfirmJoinResult();

  const factory ConfirmJoinResult.success() = ConfirmJoinSuccess;

  const factory ConfirmJoinResult.error(
    String message, {
    GroupOperationErrorKind kind,
  }) = ConfirmJoinError;
}

class ConfirmJoinSuccess extends ConfirmJoinResult {
  const ConfirmJoinSuccess();
}

class ConfirmJoinError extends ConfirmJoinResult
    implements GroupOperationFailure {
  const ConfirmJoinError(
    this.message, {
    this.kind = GroupOperationErrorKind.general,
  });

  @override
  final String message;
  @override
  final GroupOperationErrorKind kind;
}

/// Confirms a group join after the user previews group info.
///
/// Called after [JoinGroupUseCase] returns verified group info.
/// Sends confirmation to server and saves the confirming group
/// to local DB. Members are fetched later via group status polling.
class ConfirmJoinUseCase {
  ConfirmJoinUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
    required GroupRepository groupRepository,
  }) : _apiClient = apiClient,
       _keyManager = keyManager,
       _groupRepository = groupRepository;

  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final GroupRepository _groupRepository;

  Future<ConfirmJoinResult> execute({
    required String groupId,
    required String groupName,
    required String displayName,
    required String avatarEmoji,
    String? avatarImageHash,
  }) async {
    try {
      final deviceId = await _keyManager.getDeviceId();
      if (deviceId == null) {
        return const ConfirmJoinResult.error('Device key not initialized');
      }

      await _apiClient.confirmJoin(
        groupId: groupId,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
        avatarImageHash: avatarImageHash,
      );

      // Confirmation is the server-side commit point. Only now may a stale or
      // server-deleted owner-only local group be deactivated; previewing an
      // invite must remain side-effect free in case the user goes back.
      final localGroup = await _groupRepository.getCurrentGroup();
      if (localGroup != null && localGroup.groupId != groupId) {
        await _groupRepository.deactivateGroup(localGroup.groupId);
      }

      await _groupRepository.saveConfirmingGroup(
        groupId: groupId,
        groupName: groupName,
        members: const <GroupMember>[],
      );

      return const ConfirmJoinResult.success();
    } catch (error) {
      final failure = groupOperationFailureFrom(
        error,
        fallbackMessage: 'Failed to confirm join',
      );
      return ConfirmJoinResult.error(failure.message, kind: failure.kind);
    }
  }
}
