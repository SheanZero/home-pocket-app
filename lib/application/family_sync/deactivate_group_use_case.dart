import 'shadow_book_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import 'group_operation_error.dart';

sealed class DeactivateGroupResult {
  const DeactivateGroupResult();

  const factory DeactivateGroupResult.success() = DeactivateGroupSuccess;
  const factory DeactivateGroupResult.error(
    String message, {
    GroupOperationErrorKind kind,
  }) = DeactivateGroupError;
}

class DeactivateGroupSuccess extends DeactivateGroupResult {
  const DeactivateGroupSuccess();
}

class DeactivateGroupError extends DeactivateGroupResult
    implements GroupOperationFailure {
  const DeactivateGroupError(
    this.message, {
    this.kind = GroupOperationErrorKind.general,
  });

  @override
  final String message;
  @override
  final GroupOperationErrorKind kind;
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
    } catch (error) {
      final failure = groupOperationFailureFrom(
        error,
        fallbackMessage: 'Failed to deactivate group',
      );
      return DeactivateGroupResult.error(failure.message, kind: failure.kind);
    }
  }
}
