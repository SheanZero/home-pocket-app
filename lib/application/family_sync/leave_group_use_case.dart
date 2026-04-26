import 'shadow_book_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';

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
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository,
       _queueManager = queueManager,
       _shadowBookService = shadowBookService;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;
  final SyncQueueManager _queueManager;
  final ShadowBookService? _shadowBookService;

  Future<LeaveGroupResult> execute(String groupId) async {
    try {
      await _apiClient.leaveGroup(groupId);
      await _queueManager.clearQueue();
      await _shadowBookService?.cleanSyncData(groupId);
      await _groupRepository.deactivateGroup(groupId);
      return const LeaveGroupResult.success();
    } on RelayApiException catch (error) {
      return LeaveGroupResult.error(error.message);
    } catch (error) {
      return LeaveGroupResult.error(error.toString());
    }
  }
}
