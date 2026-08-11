import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import 'shadow_book_service.dart';

enum LocalGroupCleanupMode { deactivate, delete }

/// Handles a realtime group_dissolved control event.
///
/// Cleans local sync data and permanently removes the dissolved group.
class HandleGroupDissolvedUseCase {
  HandleGroupDissolvedUseCase({
    required this._groupRepo,
    required this._queueManager,
    required this._shadowBookService,
  });

  final GroupRepository _groupRepo;
  final SyncQueueManager _queueManager;
  final ShadowBookService _shadowBookService;

  Future<void> execute({
    required String groupId,
    LocalGroupCleanupMode mode = LocalGroupCleanupMode.delete,
  }) async {
    final activeGroup = await _groupRepo.getActiveGroup();
    if (activeGroup == null || activeGroup.groupId != groupId) return;

    await _queueManager.clearQueue();
    await _shadowBookService.cleanSyncData(groupId);
    switch (mode) {
      case LocalGroupCleanupMode.deactivate:
        await _groupRepo.deactivateGroup(groupId);
      case LocalGroupCleanupMode.delete:
        await _groupRepo.deleteGroup(groupId);
    }
  }
}
