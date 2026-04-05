import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/relay_api_client.dart';

sealed class ConfirmJoinResult {
  const ConfirmJoinResult();

  const factory ConfirmJoinResult.success() = ConfirmJoinSuccess;

  const factory ConfirmJoinResult.error(String message) = ConfirmJoinError;
}

class ConfirmJoinSuccess extends ConfirmJoinResult {
  const ConfirmJoinSuccess();
}

class ConfirmJoinError extends ConfirmJoinResult {
  const ConfirmJoinError(this.message);

  final String message;
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
  }) async {
    try {
      final deviceId = await _keyManager.getDeviceId();
      if (deviceId == null) {
        return const ConfirmJoinResult.error('Device key not initialized');
      }

      await _apiClient.confirmJoin(
        groupId: groupId,
      );

      await _groupRepository.saveConfirmingGroup(
        groupId: groupId,
        groupName: groupName,
        members: const <GroupMember>[],
      );

      return const ConfirmJoinResult.success();
    } on RelayApiException catch (error) {
      return ConfirmJoinResult.error(error.message);
    } catch (error) {
      return ConfirmJoinResult.error('Failed to confirm join: $error');
    }
  }
}
