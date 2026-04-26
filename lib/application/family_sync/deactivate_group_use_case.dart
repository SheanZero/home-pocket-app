import 'shadow_book_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';

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
    ShadowBookService? shadowBookService,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository,
       _queueManager = queueManager,
       _shadowBookService = shadowBookService;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;
  final SyncQueueManager _queueManager;
  final ShadowBookService? _shadowBookService;

  Future<DeactivateGroupResult> execute(String groupId) async {
    try {
      await _apiClient.deactivateGroup(groupId);
      await _queueManager.clearQueue();
      await _shadowBookService?.cleanSyncData(groupId);
      await _groupRepository.deactivateGroup(groupId);
      return const DeactivateGroupResult.success();
    } on RelayApiException catch (error) {
      return DeactivateGroupResult.error(error.message);
    } catch (error) {
      return DeactivateGroupResult.error(error.toString());
    }
  }
}
