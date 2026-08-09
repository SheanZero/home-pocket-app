import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import 'shadow_book_service.dart';

/// Handles group_dissolved push notification.
///
/// Cleans local sync data and deactivates the group.
class HandleGroupDissolvedUseCase {
  HandleGroupDissolvedUseCase({
    required this._groupRepo,
    required this._queueManager,
    required this._shadowBookService,
  });

  final GroupRepository _groupRepo;
  final SyncQueueManager _queueManager;
  final ShadowBookService _shadowBookService;

  Future<void> execute({required String groupId}) async {
    final activeGroup = await _groupRepo.getActiveGroup();
    if (activeGroup == null || activeGroup.groupId != groupId) return;

    await _queueManager.clearQueue();
    await _shadowBookService.cleanSyncData(groupId);
    await _groupRepo.deactivateGroup(groupId);
  }
}
