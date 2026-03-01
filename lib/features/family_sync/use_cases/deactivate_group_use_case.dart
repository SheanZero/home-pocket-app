import '../../../infrastructure/sync/relay_api_client.dart';
import '../../../infrastructure/sync/sync_queue_manager.dart';
import '../domain/repositories/group_repository.dart';

sealed class DeactivateGroupResult {
  const DeactivateGroupResult();

  const factory DeactivateGroupResult.success() = DeactivateGroupSuccess;
  const factory DeactivateGroupResult.error(String message) =
      DeactivateGroupError;
}

class DeactivateGroupSuccess extends DeactivateGroupResult {
  const DeactivateGroupSuccess();
}

class DeactivateGroupError extends DeactivateGroupResult {
  const DeactivateGroupError(this.message);

  final String message;
}

class DeactivateGroupUseCase {
  DeactivateGroupUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
    required SyncQueueManager queueManager,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository,
       _queueManager = queueManager;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;
  final SyncQueueManager _queueManager;

  Future<DeactivateGroupResult> execute(String groupId) async {
    try {
      await _apiClient.deactivateGroup(groupId);
      await _queueManager.clearQueue();
      await _groupRepository.deactivateGroup(groupId);
      return const DeactivateGroupResult.success();
    } on RelayApiException catch (error) {
      return DeactivateGroupResult.error(error.message);
    } catch (error) {
      return DeactivateGroupResult.error(error.toString());
    }
  }
}
